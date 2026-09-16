param(
    [switch]$All,
    [string]$Project,
    [switch]$Clean,
    [string]$Dotnet
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# ── 平台判定 ────────────────────────────────────────────────
# $IsWindows 是 pwsh 全平台的只读自动变量，不能自己定义同名（小写）变量
$onWindows = if (Test-Path Variable:\IsWindows) { [bool]$IsWindows } else { $env:OS -eq 'Windows_NT' }

# ── 解析 dotnet：显式参数 → 环境变量 → 常见安装位置 → PATH ──
function Resolve-Dotnet {
    param([string]$Explicit)

    if ($Explicit) {
        if (-not (Test-Path -LiteralPath $Explicit)) { throw "指定的 dotnet 不存在: $Explicit" }
        return (Resolve-Path -LiteralPath $Explicit).Path
    }
    if ($env:FSHARP_DOTNET -and (Test-Path -LiteralPath $env:FSHARP_DOTNET)) {
        return (Resolve-Path -LiteralPath $env:FSHARP_DOTNET).Path
    }
    if ($env:DOTNET_ROOT) {
        foreach ($cand in @("$env:DOTNET_ROOT\dotnet.exe", "$env:DOTNET_ROOT/dotnet")) {
            if (Test-Path -LiteralPath $cand) { return (Resolve-Path -LiteralPath $cand).Path }
        }
    }
    # Windows 上的常见安装位置
    foreach ($cand in @(
        'G:\scoop\apps\dotnet-sdk\current\dotnet.exe',
        "$env:ProgramFiles\dotnet\dotnet.exe",
        "$env:LOCALAPPDATA\Microsoft\dotnet\dotnet.exe"
    )) {
        if ($cand -and (Test-Path -LiteralPath $cand)) { return (Resolve-Path -LiteralPath $cand).Path }
    }
    # macOS / Linux 上的常见安装位置（MacPorts、Homebrew、系统包）
    foreach ($cand in @(
        '/opt/local/bin/dotnet',
        '/opt/homebrew/bin/dotnet',
        '/usr/local/bin/dotnet',
        '/usr/share/dotnet/dotnet',
        '/usr/lib/dotnet/dotnet'
    )) {
        if (Test-Path -LiteralPath $cand) { return $cand }
    }
    $cmd = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

$dotnet = Resolve-Dotnet -Explicit $Dotnet
if (-not $dotnet) {
    throw @"
未找到 dotnet。请安装 .NET 10 SDK，或任选一种方式指定：
  pwsh build.ps1 -All -Dotnet /path/to/dotnet
  `$env:FSHARP_DOTNET = '/path/to/dotnet'
"@
}

# ── 目录 ────────────────────────────────────────────────────
$examplesDir = Join-Path $projectRoot "examples"
$buildDir = Join-Path $projectRoot "build"
$logDir = Join-Path $buildDir "log"

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

# ── MSBuild 属性用的路径：一律正斜杠 ──────────────────────────
# 反斜杠在 Unix 上不会被 MSBuild 当分隔符，只会拼出带 \ 的怪目录名；
# 而 Windows 完全接受 / ，所以统一用 / 是最省事的跨平台写法。
$outPath = (($buildDir -replace '\\', '/').TrimEnd('/')) + "/bin/"
$objPath = (($buildDir -replace '\\', '/').TrimEnd('/')) + "/obj/"

# 清扫 examples 下游离的 obj/bin（读者直接 dotnet run 会在示例目录生成默认产物，
# 与本脚本的集中重定向路径冲突，导致重复生成特性等错误）
$strayDirs = Get-ChildItem -LiteralPath $examplesDir -Recurse -Directory -Include obj, bin |
    Where-Object { $_.FullName -notlike "$buildDir*" }
foreach ($stray in $strayDirs) {
    Remove-Item -LiteralPath $stray.FullName -Recurse -Force
}

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    } else {
        Write-Host "[Clean] build 目录不存在，无需清理。" -ForegroundColor Yellow
    }
    exit 0
}

$projects = Get-ChildItem -LiteralPath $examplesDir -Recurse -Filter "*.fsproj" | Sort-Object FullName
if ($projects.Count -eq 0) {
    throw "examples 目录下没有示例工程。"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null
New-Item -ItemType Directory -Force -Path $logDir | Out-Null
# 日志用截断清空而不是 Remove-Item：删文件在受限环境（沙箱 / CI 的删除保护）
# 里可能被拦且不报错，结果就是一轮轮往上堆 —— 看着"有输出"，其实混了好几轮的。
function Reset-Log {
    param([string]$Path)
    if (Test-Path -LiteralPath $Path) { Clear-Content -LiteralPath $Path -ErrorAction SilentlyContinue }
}

# 关掉首次运行体验与遥测：
#   - 遥测会往 ~/.dotnet/TelemetryStorageService 写临时文件，在 CI 容器、只读 HOME、
#     受限沙箱里这步失败会让子进程直接被杀（退出码 131），看起来像"示例崩了"；
#   - 首次体验横幅会污染 stdout，干扰日志比对。
$env:DOTNET_CLI_TELEMETRY_OPTOUT = '1'
$env:DOTNET_NOLOGO = '1'
$env:DOTNET_SKIP_FIRST_TIME_EXPERIENCE = '1'

Write-Host "[Info] dotnet = $dotnet" -ForegroundColor DarkGray
Write-Host "[Info] 平台   = $(if ($onWindows) { 'Windows' } else { 'Unix (macOS/Linux)' })" -ForegroundColor DarkGray
& $dotnet --version | ForEach-Object { Write-Host "[Info] SDK    = $_" -ForegroundColor DarkGray }

$script:failures = @()

function Invoke-Project {
    param([Parameter(Mandatory = $true)][System.IO.FileInfo]$Fsproj)

    $name = $Fsproj.BaseName
    $raw = Get-Content -LiteralPath $Fsproj.FullName -Raw
    $isGui = $raw -match 'net\d+\.\d+-windows'
    $isTest = $raw -match 'Microsoft\.NET\.Test\.Sdk'

    # 测试工程不经重定向构建：BaseIntermediateOutputPath 等全局属性会传播到
    # ProjectReference 引用的工程，两边 restore 会互相覆盖 assets 文件；
    # 直接 dotnet test（自建默认 obj/bin，下次脚本运行时被清扫回收）
    if ($isTest) {
        Write-Host "[Test] $name" -ForegroundColor Magenta
        & $dotnet test $Fsproj.FullName --nologo -v minimal -c Release
        if ($LASTEXITCODE -ne 0) {
            $script:failures += "测试未通过: $name"
            Write-Host "[FAIL] $name" -ForegroundColor Red
        }
        return
    }

    Write-Host "[Build] $name" -ForegroundColor Cyan
    $buildArgs = @(
        'build', $Fsproj.FullName, '--nologo', '-v', 'minimal', '-c', 'Release',
        "-p:BaseOutputPath=$outPath",
        "-p:BaseIntermediateOutputPath=$objPath$name/"
    )
    # 非 Windows 上构建 netX.0-windows 工程需要显式开启（GUI 章只构建、不运行）
    if ($isGui -and -not $onWindows) {
        $buildArgs += '-p:EnableWindowsTargeting=true'
    }
    & $dotnet @buildArgs
    if ($LASTEXITCODE -ne 0) {
        $script:failures += "编译失败: $name"
        Write-Host "[FAIL] $name" -ForegroundColor Red
        return
    }

    if ($isGui) {
        Write-Host "[BuildOnly] $name（GUI 工程，跳过运行）" -ForegroundColor DarkCyan
        return
    }

    # ── 找产物 ───────────────────────────────────────────────
    # Windows 上直接跑 X.exe。非 Windows 上刻意用 `dotnet X.dll` 而不是 apphost
    # （那个同名无扩展名的原生启动器）：apphost 只在固定位置找运行时——
    # /usr/local/share/dotnet、DOTNET_ROOT、注册位置——而 MacPorts 装在 /opt/local、
    # Homebrew 装在 /opt/homebrew 时它一概找不到，报
    #   You must install .NET to run this application.
    # 并以退出码 131 收场：看着像示例崩了，其实是"运行时装在不常规的位置"。
    # `dotnet X.dll` 复用脚本已解析出的那个 dotnet，不受安装位置影响。
    $releaseDir = Join-Path $buildDir "bin/Release"
    $tfmDir = Get-ChildItem -LiteralPath $releaseDir -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name | Select-Object -First 1
    if (-not $tfmDir) {
        $script:failures += "未找到输出目录: $name"
        Write-Host "[FAIL] $name（没找到 $releaseDir）" -ForegroundColor Red
        return
    }

    $winExe = Join-Path $tfmDir.FullName "$name.exe"     # Windows
    $dll = Join-Path $tfmDir.FullName "$name.dll"

    $toRun = $null
    $useDotnet = $false
    if ($onWindows -and (Test-Path -LiteralPath $winExe)) {
        $toRun = $winExe
    } elseif (Test-Path -LiteralPath $dll) {
        $toRun = $dll
        $useDotnet = $true
    } else {
        $script:failures += "未找到生成的可执行文件: $name"
        Write-Host "[FAIL] $name（产物缺失）" -ForegroundColor Red
        return
    }

    $stdoutLog = Join-Path $logDir "$name.out"
    $stderrLog = Join-Path $logDir "$name.err"
    # 每轮先截断，避免和上一轮的输出混在一起
    Reset-Log $stdoutLog
    Reset-Log $stderrLog

    if ($name -eq 'Todo') {
        $demoSequence = @(
            @('reset'),
            @('add', 'learn F#'),
            @('add', 'write tutorial'),
            @('show'),
            @('done', '2'),
            @('show'),
            @('remove', '1'),
            @('show')
        )
        $bad = $false
        foreach ($args_ in $demoSequence) {
            Write-Host "[Run] Todo $($args_ -join ' ')" -ForegroundColor DarkCyan
            # dll 必须经 dotnet 启动：直接 & 一个 .dll，macOS 会拿 LaunchServices
            # 当文档去"打开"，打印 No application knows how to open 之后照样返回 0 —— 假阳性
            if ($useDotnet) {
                $out = & $dotnet $toRun @args_ 2>$stderrLog
            } else {
                $out = & $toRun @args_ 2>$stderrLog
            }
            $code = $LASTEXITCODE
            Add-Content -LiteralPath $stdoutLog -Value $out
            if ($code -ne 0) {
                $script:failures += "运行失败: Todo $($args_ -join ' ')（退出码 $code）"
                $bad = $true
            }
            # 兜底断言：本示例每一步都有输出。空输出说明进程根本没执行到业务代码
            if (-not $out -or @($out).Count -eq 0) {
                $script:failures += "无输出: Todo $($args_ -join ' ')（进程可能没真正启动）"
                $bad = $true
            }
            if ((Get-Item -LiteralPath $stderrLog -ErrorAction SilentlyContinue).Length -gt 0) {
                $script:failures += "stderr 非空: Todo $($args_ -join ' ')"
                $bad = $true
            }
        }
        if ($bad) { Write-Host "[FAIL] Todo" -ForegroundColor Red }
        return
    }

    Write-Host "[Run] $name" -ForegroundColor DarkCyan
    if ($useDotnet) {
        & $dotnet $toRun 2>$stderrLog | Tee-Object -Variable out
    } else {
        & $toRun 2>$stderrLog | Tee-Object -Variable out
    }
    $code = $LASTEXITCODE
    Add-Content -LiteralPath $stdoutLog -Value $out
    if ($code -ne 0) {
        $script:failures += "运行失败: $name（退出码 $code）"
        Write-Host "[FAIL] $name" -ForegroundColor Red
        return
    }
    # stderr 非空视为失败：dotnet 的构建/运行警告都走 stderr，静默放过去会掩盖问题
    $errText = if (Test-Path -LiteralPath $stderrLog) { (Get-Item -LiteralPath $stderrLog).Length } else { 0 }
    if ($errText -gt 0) {
        $script:failures += "stderr 非空: $name"
        Write-Host "[FAIL] $name（stderr 有输出）" -ForegroundColor Red
        return
    }
    # 兜底断言：每个示例都打印内容。空输出说明进程根本没执行到业务代码
    # （比如 dll 被当成文档"打开"时退出码仍是 0，只有这条能抓到）
    if (-not $out -or @($out).Count -eq 0) {
        $script:failures += "无输出: $name（进程可能没真正启动）"
        Write-Host "[FAIL] $name（stdout 为空）" -ForegroundColor Red
    }
}

if ($All) {
    foreach ($entry in $projects) {
        Invoke-Project -Fsproj $entry
    }
    if ($script:failures.Count -gt 0) {
        Write-Host ""
        Write-Host "[FAILED] 共 $($script:failures.Count) 项：" -ForegroundColor Red
        $script:failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        exit 1
    }
    Write-Host "[Done] examples 目录全部验证通过。" -ForegroundColor Green
    exit 0
}

if ($Project) {
    $projectDir = Join-Path $examplesDir $Project
    if (-not (Test-Path -LiteralPath $projectDir)) {
        throw "找不到示例工程: $projectDir"
    }
    $fsprojs = Get-ChildItem -LiteralPath $projectDir -Recurse -Filter "*.fsproj" | Sort-Object FullName
    if ($fsprojs.Count -eq 0) {
        throw "示例工程缺少 fsproj: $projectDir"
    }
    foreach ($p in $fsprojs) {
        Invoke-Project -Fsproj $p
    }
    if ($script:failures.Count -gt 0) {
        Write-Host ""
        Write-Host "[FAILED] 共 $($script:failures.Count) 项：" -ForegroundColor Red
        $script:failures | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        exit 1
    }
    Write-Host "[Done] 验证通过: $Project" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  .\build.ps1 -All                  编译并验证 examples 下全部示例工程（GUI 仅构建，测试工程跑 dotnet test）"
Write-Host "  .\build.ps1 -Project <name>       编译并验证单个示例目录（例如 06_collections；嵌套目录构建其下全部 fsproj）"
Write-Host "  .\build.ps1 -Clean                清理 build 目录"
Write-Host "  .\build.ps1 -All -Dotnet <path>   指定 dotnet 路径（也可设环境变量 FSHARP_DOTNET）"
