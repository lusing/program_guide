param(
    [switch]$All,
    [string]$File,
    [switch]$Gui,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# Windows 上 fpc 产出 name.exe，macOS/Linux 上产出无扩展名的 name，
# 所以扩展名必须由平台决定，不能写死。
# 注意 pwsh 6+ 全平台都有只读的 $IsWindows（PowerShell 变量名不区分大小写，
# 不能再定义同名变量），Windows PowerShell 5.1 上没有这个变量，只能退回 $env:OS。
$onWindows = if (Test-Path Variable:\IsWindows) { [bool]$IsWindows } else { $env:OS -eq 'Windows_NT' }
$exeExt    = if ($onWindows) { '.exe' } else { '' }

$examplesDir = Join-Path $projectRoot "examples"
$buildDir    = Join-Path $projectRoot "build"

# ------------------------------------------------------------
# 工具链定位：环境变量 FPC / LAZBUILD 优先，其次 PATH，最后是各平台的常见安装路径。
# 原来这里写死 G:\scoop\...\i386-win32\fpc.exe，换平台（或换 scoop 前缀）就直接抛异常。
# ------------------------------------------------------------
function Resolve-Tool {
    param(
        [string]$EnvVar,
        [string[]]$Names,
        [string[]]$FixedPaths
    )

    $fromEnv = [Environment]::GetEnvironmentVariable($EnvVar)
    if ($fromEnv -and (Test-Path -LiteralPath $fromEnv)) { return $fromEnv }

    foreach ($n in $Names) {
        $cmd = Get-Command $n -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }

    foreach ($p in $FixedPaths) {
        if (Test-Path -LiteralPath $p) { return $p }
    }

    return $null
}

$compiler = Resolve-Tool -EnvVar 'FPC' -Names @('fpc') -FixedPaths @(
    'G:\scoop\apps\freepascal\current\bin\i386-win32\fpc.exe',
    'C:\lazarus\fpc\3.2.2\bin\i386-win32\fpc.exe',
    '/opt/local/bin/fpc',
    '/usr/local/bin/fpc'
)

$lazbuild = Resolve-Tool -EnvVar 'LAZBUILD' -Names @('lazbuild') -FixedPaths @(
    'G:\scoop\apps\lazarus\current\lazbuild.exe',
    'C:\lazarus\lazbuild.exe',
    '/opt/local/bin/lazbuild',
    '/usr/local/bin/lazbuild',
    '/Applications/Lazarus/lazbuild'
)

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    } else {
        Write-Host "[Clean] build 目录不存在，无需清理。" -ForegroundColor Yellow
    }
    exit 0
}

if (-not $compiler) {
    throw "未找到 Free Pascal 编译器。可设环境变量 FPC=/path/to/fpc，或把 fpc 加入 PATH。"
}

# ------------------------------------------------------------
# 判定标准（与 run-all.sh 一致）：
#   退出码 0 + stderr 为空 + 输出里没有多余控制字符 + 输出里有 "==== NN 结束 ===="
# 最后一条目前按「stdout 非空」降级：本目录示例还没打印结束标记，补上后自动收紧。
# ------------------------------------------------------------
$script:pass = 0
$script:fail = 0
$script:diffWarn = 0
$script:noMarker = 0
$script:failedList = @()

function Read-TextSafe([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return '' }
    if ((Get-Item -LiteralPath $path).Length -eq 0) { return '' }
    $raw = Get-Content -Raw -LiteralPath $path
    if ($null -eq $raw) { return '' }      # Get-Content -Raw 读空文件返回 $null
    return ($raw -replace '\x00', '')      # 先剔掉 NUL 再匹配，免得二进制内容干扰
}

function Test-ControlChar([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return $false }
    foreach ($b in [System.IO.File]::ReadAllBytes($path)) {
        # TAB(9) / LF(10) / CR(13) 之外，0..31 都算多余控制字符
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

function Invoke-Tool {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$StdoutFile,
        [string]$StderrFile,
        [string]$WorkingDirectory
    )
    $p = Start-Process -FilePath $FilePath -ArgumentList $Arguments `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $StdoutFile -RedirectStandardError $StderrFile `
        -WorkingDirectory $WorkingDirectory
    if ($null -eq $p.ExitCode) { return 1 }
    return $p.ExitCode
}

function Show-Result {
    param(
        [string]$Tag,
        [int]$ExitCode,
        [string]$OutFile,
        [string]$ErrFile,
        [string]$BuildLog,
        [string]$Marker
    )

    $ok = $true
    $why = @()

    if ($ExitCode -ne 0) { $ok = $false; $why += "退出码 $ExitCode" }
    if ((Get-Item -LiteralPath $ErrFile -ErrorAction SilentlyContinue).Length -gt 0) {
        $ok = $false; $why += "stderr 非空"
    }
    if (Test-ControlChar $OutFile) { $ok = $false; $why += "输出含控制字符" }

    $text = Read-TextSafe $OutFile
    if ($text.Contains($Marker)) {
        # 严格匹配
    } elseif ($text.Length -gt 0) {
        $script:noMarker += 1
    } else {
        $ok = $false; $why += "stdout 为空"
    }

    if ($ok) {
        $script:pass += 1
        Write-Host "  [OK] $Tag" -ForegroundColor Green
    } else {
        $script:fail += 1
        $script:failedList += $Tag
        Write-Host "  [FAIL] $Tag —— $(($why -join '；'))" -ForegroundColor Red
        $errText = Read-TextSafe $ErrFile
        if ($errText) { ($errText -split "`n" | Select-Object -First 5) | ForEach-Object { Write-Host "        stderr: $_" } }
        if (Test-Path -LiteralPath $BuildLog) {
            Write-Host "        编译输出："
            (Get-Content -LiteralPath $BuildLog | Select-Object -Last 8) | ForEach-Object { Write-Host "        $_" }
        }
    }
}

# 编译并运行一个示例（一个语言模式一个通道）
function Invoke-FreePascalExample {
    param(
        [Parameter(Mandatory = $true)][string]$SourcePath,
        [string]$Channel = 'objfpc',
        [string]$Mode = '-MObjFPC'
    )

    $name    = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    $num     = ($name -split '[-_]')[0]
    $marker  = "==== $num 结束 ===="
    $outDir  = Join-Path $buildDir $Channel
    $exePath = Join-Path $outDir ($name + $exeExt)

    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    if (Test-Path -LiteralPath $exePath) { Remove-Item -LiteralPath $exePath -Force }

    $outFile  = Join-Path $outDir ($name + '.out')
    $errFile  = Join-Path $outDir ($name + '.err')
    $buildLog = Join-Path $outDir ($name + '.build.log')

    Write-Host "[Compile] $Channel $name" -ForegroundColor Cyan
    # -o/-FE/-FU 一律给绝对路径：fpc 会把相对路径按「源文件所在目录」解析，
    # 否则 .o 和可执行文件会落进 examples/。给全路径后两个平台行为一致，
    # 也不用再靠「猜扩展名 + 清理源目录」来收尾。
    $rc = Invoke-Tool -FilePath $compiler `
        -Arguments @($Mode, '-Sc', '-O2', "-FE$outDir", "-FU$outDir", "-o$exePath", $SourcePath) `
        -StdoutFile $buildLog -StderrFile (Join-Path $outDir ($name + '.build.err')) `
        -WorkingDirectory $outDir

    if (($rc -ne 0) -or (-not (Test-Path -LiteralPath $exePath))) {
        Set-Content -LiteralPath $errFile -Value "编译失败: $SourcePath"
        Show-Result -Tag "$Channel $name" -ExitCode 1 -OutFile $outFile -ErrFile $errFile -BuildLog $buildLog -Marker $marker
        return
    }

    Write-Host "[Run] $Channel $name" -ForegroundColor DarkCyan
    $runRc = Invoke-Tool -FilePath $exePath -Arguments @() `
        -StdoutFile $outFile -StderrFile $errFile -WorkingDirectory $outDir

    Show-Result -Tag "$Channel $name" -ExitCode $runRc -OutFile $outFile -ErrFile $errFile -BuildLog $buildLog -Marker $marker
}

# 同一份源码在 objfpc / delphi 两种语言模式下输出应逐字节一致
function Compare-Channels {
    param([string]$Name)

    $a = Join-Path (Join-Path $buildDir 'objfpc') ($Name + '.out')
    $b = Join-Path (Join-Path $buildDir 'delphi') ($Name + '.out')
    if (-not ((Test-Path -LiteralPath $a) -and (Test-Path -LiteralPath $b))) { return }
    if ((Get-Item -LiteralPath $a).Length -eq 0 -or (Get-Item -LiteralPath $b).Length -eq 0) { return }

    $ha = (Get-FileHash -Algorithm SHA256 -LiteralPath $a).Hash
    $hb = (Get-FileHash -Algorithm SHA256 -LiteralPath $b).Hash
    if ($ha -eq $hb) {
        Write-Host "  [same] 两模式输出逐字节一致" -ForegroundColor Gray
    } else {
        $script:diffWarn += 1
        Write-Host "  [DIFF] 两模式输出不一致（意外差异，见 build/*/$Name.out）" -ForegroundColor Yellow
        Compare-Object (Get-Content -LiteralPath $a) (Get-Content -LiteralPath $b) |
            Select-Object -First 10 | ForEach-Object { Write-Host "        $($_.SideIndicator) $($_.InputObject)" }
    }
}

function Invoke-ExamplePair {
    param([string]$SourcePath)
    $name = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    Write-Host "==== $name ===="
    Invoke-FreePascalExample -SourcePath $SourcePath -Channel 'objfpc' -Mode '-MObjFPC'
    Invoke-FreePascalExample -SourcePath $SourcePath -Channel 'delphi' -Mode '-MDelphi'
    Compare-Channels -Name $name
}

# ------------------------------------------------------------
# Lazarus GUI 工程：只验证能被 lazbuild 编译。
# 控件集不显式指定 —— lazbuild 在 Windows 上默认 win32、macOS 上默认 cocoa、
# Linux 上默认 gtk2，写死 cocoa 反而会让 Windows 编不过。
# 工程目录内的相对路径必须用 Join-Path 逐段拼，"13_lazarus_gui\LazarusGuiDemo.lpi"
# 这种内嵌反斜杠的写法在 macOS/Linux 上不会被转换。
# ------------------------------------------------------------
$guiProjects = @(
    [pscustomobject]@{ Dir = '13_lazarus_gui';            Lpi = 'LazarusGuiDemo.lpi' },
    [pscustomobject]@{ Dir = '14_lazarus_advanced_controls'; Lpi = 'AdvancedControlsDemo.lpi' },
    [pscustomobject]@{ Dir = '15_lazarus_menus_dialogs';  Lpi = 'LazarusMenusDemo.lpi' }
)

function Invoke-GuiProject {
    param([pscustomobject]$Project)

    $projectPath = Join-Path (Join-Path $examplesDir $Project.Dir) $Project.Lpi
    $projectName = $Project.Lpi

    Write-Host "==== $projectName ====" -ForegroundColor Cyan
    if (-not (Test-Path -LiteralPath $projectPath)) {
        Write-Host "  [FAIL] 找不到工程文件 $projectPath" -ForegroundColor Red
        $script:fail += 1; $script:failedList += "lazbuild $projectName"
        return
    }
    if (-not $lazbuild) {
        Write-Host "  [SKIP] lazbuild 未安装（可设环境变量 LAZBUILD=/path/to/lazbuild）" -ForegroundColor Yellow
        return
    }

    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
    $logFile = Join-Path $buildDir ($projectName + '.build.log')
    $rc = Invoke-Tool -FilePath $lazbuild -Arguments @($projectPath) `
        -StdoutFile $logFile -StderrFile ($logFile + '.err') -WorkingDirectory $projectRoot

    if ($rc -eq 0) {
        $script:pass += 1
        Write-Host "  [OK] lazbuild $projectName" -ForegroundColor Green
    } else {
        $script:fail += 1
        $script:failedList += "lazbuild $projectName"
        Write-Host "  [FAIL] lazbuild $projectName" -ForegroundColor Red
        (Get-Content -LiteralPath $logFile -ErrorAction SilentlyContinue | Select-Object -Last 8) |
            ForEach-Object { Write-Host "        $_" }
    }
}

function Resolve-SourceByName([string]$requested) {
    # 支持 08_arrays.pas / 08_arrays / 08 三种写法
    $candidate = Join-Path $examplesDir $requested
    if ((Test-Path -LiteralPath $candidate) -and ((Get-Item -LiteralPath $candidate).PSIsContainer -eq $false)) {
        return $candidate
    }
    $withExt = Join-Path $examplesDir ($requested + '.pas')
    if (Test-Path -LiteralPath $withExt) { return $withExt }

    $stem = $requested -replace '\.pas$', ''
    if ($stem -match '^\d+$') {
        $prefixed = Get-ChildItem -LiteralPath $examplesDir -Filter ($stem + '_*.pas') -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($prefixed) { return $prefixed.FullName }
    }
    return $null
}

function Write-Summary {
    Write-Host ""
    Write-Host "通过 $($script:pass)   失败 $($script:fail)   输出差异 $($script:diffWarn)" -ForegroundColor White
    if ($script:noMarker -gt 0) {
        Write-Host "提示：$($script:noMarker) 项没有结束标记，按「stdout 非空」降级判定（示例补上 ==== NN 结束 ==== 后自动收紧）" -ForegroundColor DarkYellow
    }
    if ($script:fail -eq 0) {
        Write-Host "[Done] 全部验证通过。" -ForegroundColor Green
        if ($script:diffWarn -gt 0) {
            Write-Host "（有 $($script:diffWarn) 项跨模式输出不同，请人工确认是否可接受）" -ForegroundColor Yellow
        }
        exit 0
    }
    Write-Host "失败项：" -ForegroundColor Red
    $script:failedList | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

if ($Gui) {
    foreach ($proj in $guiProjects) { Invoke-GuiProject -Project $proj }
    Write-Summary
}

if ($All) {
    $files = Get-ChildItem -LiteralPath $examplesDir -Filter "*.pas" | Sort-Object Name
    if ($files.Count -eq 0) {
        throw "examples 目录下没有 .pas 示例文件。"
    }
    foreach ($f in $files) { Invoke-ExamplePair -SourcePath $f.FullName }
    foreach ($proj in $guiProjects) { Invoke-GuiProject -Project $proj }
    Write-Summary
}

if ($File) {
    $guiHit = $guiProjects | Where-Object { $_.Dir -eq ($File -replace '[/\\]$', '') }
    if ($guiHit) {
        Invoke-GuiProject -Project $guiHit
        Write-Summary
    }

    $sourcePath = Resolve-SourceByName $File
    if (-not $sourcePath) {
        throw "找不到示例: $File（支持 08_arrays.pas / 08_arrays / 08 / GUI 目录名）"
    }
    Invoke-ExamplePair -SourcePath $sourcePath
    Write-Summary
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All           编译并运行 examples 下全部示例（两种语言模式），再编译 Lazarus 工程"
Write-Host "  .\build.ps1 -File <name>   验证单个示例（如 08_arrays.pas / 08 / 13_lazarus_gui）"
Write-Host "  .\build.ps1 -Gui           只编译 3 个 Lazarus GUI 工程"
Write-Host "  .\build.ps1 -Clean         清理 build 目录"
Write-Host ""
Write-Host "工具链：fpc=$compiler" -ForegroundColor DarkGray
Write-Host "       lazbuild=$(if ($lazbuild) { $lazbuild } else { '<未找到>' })" -ForegroundColor DarkGray
