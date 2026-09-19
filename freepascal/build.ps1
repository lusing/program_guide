# FreePascal/Lazarus 教程统一验证脚本（pwsh 7；无 BOM，须用 pwsh 而非 Windows PowerShell 5.1）
#
# CLI 示例（examples/NN_topic/NN_topic.pas）双通道验证：
#   check   通道：-MObjFPC -Cr -Co -Ci -Sa -B（范围/溢出/IO 检查 + 断言 + 强制重编）
#   release 通道：-MObjFPC -O2（发布形态）
#   每通道四条判定：exit 0 / stderr 空 / stdout 无控制字符 / 含 ==== NN 结束 ====
#   两通道 stdout SHA256 须一致（不一致 → warn + diff 预览，不算 fail）。
#
# GUI 示例（examples/NN_topic/NN_topic.lpi）：
#   lazbuild 编译 → 运行 exe --selftest（cwd=示例目录）→ selftest.log 四条判定
#   （标记 ==== NN selftest OK ====`）。
#
# 编码纪律：源码 UTF-8 无 BOM + {$codepage utf8}；本脚本运行前把控制台切到 65001
# （FPC 的文本输出跟随活动控制台代码页——GBK 控制台下会把 UTF-8 串转成 GBK 字节，
#  双通道/管道验证必须先统一到 65001，见 docs/02-hello.md 实测记录）。

param(
    [switch]$All,
    [string]$Example,
    [switch]$Gui,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$onWindows = if (Test-Path Variable:\IsWindows) { [bool]$IsWindows } else { $env:OS -eq 'Windows_NT' }
$exeExt    = if ($onWindows) { '.exe' } else { '' }

$examplesDir = Join-Path $projectRoot 'examples'
$buildDir    = Join-Path $projectRoot 'build'

if ($onWindows) {
    # 控制台代码页统一切 65001；重定向下 FPC 仍按它决定 WriteLn 输出字节
    & "$env:SystemRoot\System32\chcp.com" 65001 | Out-Null
}
# pwsh 自身的中文输出经管道/重定向时按 [Console]::OutputEncoding 编码，显式设为 UTF-8
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch { }

# ------------------------------------------------------------
# 工具链定位：环境变量 FPC / LAZBUILD → 固定路径 → PATH。
# 固定路径排在 PATH 前：scoop 的 fpc shim 是 i386-win32 独立包（32 位），
# 主线是 Lazarus 自带的 x86_64-win64 FPC——否则会静默编出 32 位 exe。
# ------------------------------------------------------------
function Resolve-Tool {
    param([string]$EnvVar, [string[]]$Names, [string[]]$FixedPaths)

    $fromEnv = [Environment]::GetEnvironmentVariable($EnvVar)
    if ($fromEnv -and (Test-Path -LiteralPath $fromEnv)) { return $fromEnv }

    foreach ($p in $FixedPaths) {
        if (Test-Path -LiteralPath $p) { return $p }
    }
    foreach ($n in $Names) {
        $cmd = Get-Command $n -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

# 主线是 Lazarus 自带的 x86_64-win64 FPC（与 lazbuild 同一套 RTL/LCL）；
# scoop 独立 freepascal 包只有 i386-win32 目标，仅作后备。
$compiler = Resolve-Tool -EnvVar 'FPC' -Names @('fpc') -FixedPaths @(
    'G:\scoop\apps\lazarus\current\fpc\3.2.2\bin\x86_64-win64\fpc.exe',
    'G:\scoop\apps\freepascal\current\bin\i386-win32\fpc.exe',
    'C:\lazarus\fpc\3.2.2\bin\x86_64-win64\fpc.exe',
    '/usr/bin/fpc', '/usr/local/bin/fpc', '/opt/local/bin/fpc'
)

$lazbuild = Resolve-Tool -EnvVar 'LAZBUILD' -Names @('lazbuild') -FixedPaths @(
    'G:\scoop\apps\lazarus\current\lazbuild.exe',
    'C:\lazarus\lazbuild.exe',
    '/usr/bin/lazbuild', '/usr/local/bin/lazbuild', '/opt/local/bin/lazbuild',
    '/Applications/Lazarus/lazarus.app/Contents/MacOS/lazbuild'
)

# ------------------------------------------------------------
# 清理：build/、各示例的 selftest.log 与 lib/ 产物目录
# ------------------------------------------------------------
if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
    if (Test-Path -LiteralPath $examplesDir) {
        Get-ChildItem -LiteralPath $examplesDir -Directory | ForEach-Object {
            $log = Join-Path $_.FullName 'selftest.log'
            if (Test-Path -LiteralPath $log) { Remove-Item -LiteralPath $log -Force }
            $lib = Join-Path $_.FullName 'lib'
            if (Test-Path -LiteralPath $lib) { Remove-Item -LiteralPath $lib -Recurse -Force }
        }
    }
    Write-Host '[Clean] 已清理 build/、examples/*/selftest.log、examples/*/lib/' -ForegroundColor Yellow
    exit 0
}

if (-not $compiler) {
    throw '未找到 Free Pascal 编译器。可设环境变量 FPC=/path/to/fpc，或把 fpc 加入 PATH。'
}

# ------------------------------------------------------------
# 示例清单：examples/NN_topic/ 目录，
#   含同名 .pas → CLI；含 *.lpi → GUI（lazbuild 只认 .lpi，不认 .lpr）
# ------------------------------------------------------------
function Get-ExampleDirs {
    Get-ChildItem -LiteralPath $examplesDir -Directory |
        Where-Object { $_.Name -match '^\d' } |
        Sort-Object Name
}

function Test-IsCliExample([string]$dir) {
    Test-Path -LiteralPath (Join-Path $dir ((Split-Path -Leaf $dir) + '.pas'))
}

function Test-IsGuiExample([string]$dir) {
    [bool](Get-ChildItem -LiteralPath $dir -Filter '*.lpi' -ErrorAction SilentlyContinue)
}

function Get-Number([string]$dirName) { ($dirName -split '[-_]')[0] }

# ------------------------------------------------------------
# 判定与输出采集（四条判定 + 统计）
# ------------------------------------------------------------
$script:pass = 0
$script:fail = 0
$script:diffWarn = 0
$script:failedList = @()

function Read-TextSafe([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return '' }
    if ((Get-Item -LiteralPath $path).Length -eq 0) { return '' }
    $raw = Get-Content -Raw -LiteralPath $path
    if ($null -eq $raw) { return '' }
    return ($raw -replace "`0", '')
}

function Test-ControlChar([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) { return $false }
    foreach ($b in [System.IO.File]::ReadAllBytes($path)) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

function Invoke-Tool {
    param(
        [string]$FilePath, [string[]]$Arguments,
        [string]$StdoutFile, [string]$StderrFile, [string]$WorkingDirectory
    )
    $p = Start-Process -FilePath $FilePath -ArgumentList $Arguments `
        -NoNewWindow -Wait -PassThru `
        -RedirectStandardOutput $StdoutFile -RedirectStandardError $StderrFile `
        -WorkingDirectory $WorkingDirectory
    if ($null -eq $p.ExitCode) { return 1 }
    return $p.ExitCode
}

function Show-Result {
    param([string]$Tag, [int]$ExitCode, [string]$OutFile, [string]$ErrFile,
          [string]$BuildLog, [string]$Marker)

    $ok = $true; $why = @()
    if ($ExitCode -ne 0) { $ok = $false; $why += "退出码 $ExitCode" }
    if ((Get-Item -LiteralPath $ErrFile -ErrorAction SilentlyContinue).Length -gt 0) {
        $ok = $false; $why += 'stderr 非空'
    }
    if (Test-ControlChar $OutFile) { $ok = $false; $why += '输出含控制字符' }

    $text = Read-TextSafe $OutFile
    if (-not $text.Contains($Marker)) { $ok = $false; $why += "缺结束标记 $Marker" }

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
            Write-Host '        编译输出：'
            (Get-Content -LiteralPath $BuildLog | Select-Object -Last 8) | ForEach-Object { Write-Host "        $_" }
        }
    }
}

# CLI：一个语言模式一个通道；-o/-FE/-FU 一律绝对路径（fpc 把相对路径按源文件目录解析）
function Invoke-CliExample {
    param([string]$Dir)

    $name   = Split-Path -Leaf $Dir
    $num    = Get-Number $name
    $marker = "==== $num 结束 ===="
    $src    = Join-Path $Dir ($name + '.pas')

    foreach ($channel in @(
        [pscustomobject]@{ Name = 'check';   Flags = @('-MObjFPC', '-Cr', '-Co', '-Ci', '-Sa', '-B') },
        [pscustomobject]@{ Name = 'release'; Flags = @('-MObjFPC', '-O2') }
    )) {
        $outDir = Join-Path $buildDir $channel.Name
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        $exePath = Join-Path $outDir ($name + $exeExt)
        if (Test-Path -LiteralPath $exePath) { Remove-Item -LiteralPath $exePath -Force }

        $outFile  = Join-Path $outDir ($name + '.out')
        $errFile  = Join-Path $outDir ($name + '.err')
        $buildLog = Join-Path $outDir ($name + '.build.log')

        Write-Host "[Compile] $($channel.Name) $name" -ForegroundColor Cyan
        $rc = Invoke-Tool -FilePath $compiler `
            -Arguments ($channel.Flags + @("-FE$outDir", "-FU$outDir", "-Fu$Dir", "-o$exePath", $src)) `
            -StdoutFile $buildLog -StderrFile ($buildLog + '.err') -WorkingDirectory $outDir

        if (($rc -ne 0) -or (-not (Test-Path -LiteralPath $exePath))) {
            $errFile2 = Join-Path $outDir ($name + '.err')
            Set-Content -LiteralPath $errFile2 -Value "编译失败: $src"
            Show-Result -Tag "$($channel.Name) $name" -ExitCode 1 -OutFile $outFile -ErrFile $errFile2 `
                -BuildLog $buildLog -Marker $marker
            continue
        }

        Write-Host "[Run] $($channel.Name) $name" -ForegroundColor DarkCyan
        $runRc = Invoke-Tool -FilePath $exePath -Arguments @() `
            -StdoutFile $outFile -StderrFile $errFile -WorkingDirectory $outDir
        Show-Result -Tag "$($channel.Name) $name" -ExitCode $runRc -OutFile $outFile -ErrFile $errFile `
            -BuildLog $buildLog -Marker $marker
    }

    # 双通道输出一致性（SHA256）
    $a = Join-Path (Join-Path $buildDir 'check') ($name + '.out')
    $b = Join-Path (Join-Path $buildDir 'release') ($name + '.out')
    if ((Test-Path -LiteralPath $a) -and (Test-Path -LiteralPath $b)) {
        if ((Get-FileHash -Algorithm SHA256 -LiteralPath $a).Hash -eq
            (Get-FileHash -Algorithm SHA256 -LiteralPath $b).Hash) {
            Write-Host '  [same] 双通道输出逐字节一致' -ForegroundColor Gray
        } else {
            $script:diffWarn += 1
            Write-Host "  [DIFF] 双通道输出不一致（见 build/{check,release}/$name.out）" -ForegroundColor Yellow
            Compare-Object (Get-Content -LiteralPath $a) (Get-Content -LiteralPath $b) |
                Select-Object -First 10 | ForEach-Object { Write-Host "        $($_.SideIndicator) $($_.InputObject)" }
        }
    }
}

# GUI：lazbuild 编译 + --selftest 无头自检
function Invoke-GuiExample {
    param([string]$Dir)

    $name   = Split-Path -Leaf $Dir
    $num    = Get-Number $name
    $marker = "==== $num selftest OK ===="
    $lpi    = (Get-ChildItem -LiteralPath $Dir -Filter '*.lpi' | Select-Object -First 1).FullName

    Write-Host "==== $name ====" -ForegroundColor Cyan
    if (-not $lazbuild) {
        Write-Host '  [SKIP] lazbuild 未安装（可设环境变量 LAZBUILD=/path/to/lazbuild）' -ForegroundColor Yellow
        return
    }

    New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
    $buildLog = Join-Path $buildDir ($name + '.build.log')
    $errFile  = Join-Path $buildDir ($name + '.build.err')

    Write-Host "[lazbuild] $name" -ForegroundColor Cyan
    $rc = Invoke-Tool -FilePath $lazbuild -Arguments @($lpi) `
        -StdoutFile $buildLog -StderrFile $errFile -WorkingDirectory $projectRoot

    # exe 落在工程自己的 lib/<CPU>-<OS>/ 下
    $exePath = Get-ChildItem -LiteralPath (Join-Path $Dir 'lib') -Recurse -Filter ($name + $exeExt) `
        -ErrorAction SilentlyContinue | Select-Object -First 1
    if (($rc -ne 0) -or (-not $exePath)) {
        $script:fail += 1; $script:failedList += "lazbuild $name"
        Write-Host "  [FAIL] lazbuild $name（exit $rc）" -ForegroundColor Red
        (Get-Content -LiteralPath $buildLog -ErrorAction SilentlyContinue | Select-Object -Last 8) |
            ForEach-Object { Write-Host "        $_" }
        return
    }
    Write-Host "  [OK] lazbuild $name" -ForegroundColor Green
    $script:pass += 1

    # --selftest：日志写在示例目录（工程内相对路径），判定四条
    $selfLog = Join-Path $Dir 'selftest.log'
    if (Test-Path -LiteralPath $selfLog) { Remove-Item -LiteralPath $selfLog -Force }
    $outFile = Join-Path $buildDir ($name + '.selftest.out')
    $errFile = Join-Path $buildDir ($name + '.selftest.err')

    Write-Host "[selftest] $name" -ForegroundColor DarkCyan
    # 60 秒超时：GUI 程序未捕获异常会弹 LCL 消息框，无头环境 = 永久挂死——必须带击杀
    $p = Start-Process -FilePath $exePath.FullName -ArgumentList @('--selftest') `
        -NoNewWindow -PassThru `
        -RedirectStandardOutput $outFile -RedirectStandardError $errFile -WorkingDirectory $Dir
    if (-not $p.WaitForExit(60000)) {
        $p.Kill()
        Write-Host '  [FAIL] selftest 超时（60s）——多半是未捕获异常弹了 LCL 对话框' -ForegroundColor Red
    }
    $runRc = if ($null -eq $p.ExitCode) { 1 } else { $p.ExitCode }
    Show-Result -Tag "selftest $name" -ExitCode $runRc -OutFile $selfLog -ErrFile $errFile `
        -BuildLog $outFile -Marker $marker
}

function Resolve-ExampleDir([string]$requested) {
    $direct = Join-Path $examplesDir $requested
    if (Test-Path -LiteralPath $direct) { return $direct }

    $stem = $requested -replace '\.pas$', ''
    $withExt = Join-Path $examplesDir ($stem + '.pas')
    if (Test-Path -LiteralPath $withExt) { return (Split-Path -Parent $withExt) }

    if ($stem -match '^\d+$') {
        $hit = Get-ExampleDirs | Where-Object { $_.Name -like ($stem + '_*') } | Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

function Write-Summary {
    Write-Host ''
    Write-Host "通过 $($script:pass)   失败 $($script:fail)   输出差异 $($script:diffWarn)" -ForegroundColor White
    if ($script:fail -eq 0) {
        Write-Host '[Done] 全部验证通过。' -ForegroundColor Green
        if ($script:diffWarn -gt 0) {
            Write-Host "（有 $($script:diffWarn) 项双通道输出不同，请人工确认是否可接受）" -ForegroundColor Yellow
        }
        exit 0
    }
    Write-Host '失败项：' -ForegroundColor Red
    $script:failedList | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

if (-not (Test-Path -LiteralPath $examplesDir)) { throw "找不到 examples 目录: $examplesDir" }
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

if ($Example) {
    $dir = Resolve-ExampleDir $Example
    if (-not $dir) {
        throw "找不到示例: $Example（支持 02_hello / 02_hello.pas / 02）"
    }
    if (Test-IsCliExample $dir) { Invoke-CliExample -Dir $dir }
    elseif (Test-IsGuiExample $dir) { Invoke-GuiExample -Dir $dir }
    else { throw "$dir 里既没有同名 .pas 也没有 .lpi" }
    Write-Summary
}

if ($Gui -or $All) {
    foreach ($d in (Get-ExampleDirs)) {
        if (Test-IsGuiExample $d.FullName) { Invoke-GuiExample -Dir $d.FullName }
    }
    if ($Gui) { Write-Summary }
}

if ($All) {
    foreach ($d in (Get-ExampleDirs)) {
        if (Test-IsCliExample $d.FullName) {
            Write-Host "==== $($d.Name) ===="
            Invoke-CliExample -Dir $d.FullName
        }
    }
    Write-Summary
}

Write-Host '用法:' -ForegroundColor Yellow
Write-Host '  pwsh -File build.ps1 -All              # CLI 双通道 + GUI selftest 全量验证'
Write-Host '  pwsh -File build.ps1 -Example 02_hello # 单个示例（02_hello / 02_hello.pas / 02）'
Write-Host '  pwsh -File build.ps1 -Gui              # 只验证 GUI 工程（lazbuild + --selftest）'
Write-Host '  pwsh -File build.ps1 -Clean            # 清理 build/ 与各示例 selftest.log、lib/'
Write-Host ''
Write-Host "工具链：fpc=$compiler" -ForegroundColor DarkGray
Write-Host "       lazbuild=$(if ($lazbuild) { $lazbuild } else { '<未找到>' })" -ForegroundColor DarkGray
