param(
    [switch]$All,
    [string]$Example,
    [string]$Julia,
    [switch]$Clean,
    [switch]$ShowOutput
)

# ============================================================
# build.ps1 —— 用 Julia 跑遍所有示例（PowerShell 版，等价于 run-all.sh）
#
#   pwsh ./build.ps1 -All                 全部示例（运行层 + 测试层）
#   pwsh ./build.ps1 -Example 09_arrays   单个示例
#   pwsh ./build.ps1 -All -ShowOutput     附带每个示例的完整输出
#   pwsh ./build.ps1 -Clean               清理 build 目录
#
# 判定标准（六条，与 run-all.sh 逐条一致）：
#   1. 退出码为 0
#   2. stderr 为空（Julia 的警告/错误都走 stderr，所以这一条等价于「零告警」）
#      示例若**故意**触发诊断（如 14_macros 的世界年龄警告），由示例自己用
#      redirect_stderr(devnull) 把那段圈起来 —— 判定标准不为任何示例放宽。
#   3. stdout 非空（只判退出码会漏掉「进程根本没执行到业务代码」的假阳性）
#   4. stdout 里没有多余控制字符（TAB/LF/CR 除外）
#   5. stdout 里有结束标记 "==== NN 结束 ===="
#   6. stdout 里没有 Julia 的诊断字样（WARNING/ERROR/MethodError…）
#
# 工具链定位不硬编码任何一台机器的路径：
#   -Julia 参数 → 环境变量 JULIA → PATH 上的 julia → 常见安装位置
# ============================================================

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$onWindows = if (Test-Path Variable:\IsWindows) { [bool]$IsWindows } else { $env:OS -eq 'Windows_NT' }

# ------------------------------------------------------------
# 工具链定位
# ------------------------------------------------------------
$Candidates = @()
if ($Julia) { $Candidates += $Julia }
if ($env:JULIA) { $Candidates += $env:JULIA }
$Candidates += 'julia'
if ($onWindows) {
    $Candidates += "$env:USERPROFILE\.juliaup\bin\julia.exe"
    $Candidates += "$env:LOCALAPPDATA\Programs\Julia*\bin\julia.exe"
} else {
    $Candidates += '/opt/local/bin/julia'        # MacPorts（本机）
    $Candidates += '/opt/homebrew/bin/julia'     # Homebrew
    $Candidates += '/usr/local/bin/julia'
    if ($env:HOME) { $Candidates += "$env:HOME/.juliaup/bin/julia" }
}

$juliaExe = $null
foreach ($c in $Candidates) {
    if (-not $c) { continue }
    $cmd = Get-Command $c -ErrorAction SilentlyContinue
    if ($cmd) { $juliaExe = $cmd.Source; break }
}
if (-not $juliaExe -and $Example) { throw "未找到 julia（可传 -Julia 路径或设环境变量 JULIA）" }
if (-not $juliaExe) { throw "未找到 julia（可设环境变量 JULIA，或确认它在 PATH 上）" }

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Pkg 一律离线：本教程的依赖只有本地路径包（[sources]）和标准库，不需要联网。
# 不设这一条时，Pkg 首次运行会先去下载并解压 General registry（240MB / 4 万个小文件），
# 在没有 registry 的机器上表现为「instantiate 卡住十几分钟」——看上去像死锁。
$env:JULIA_PKG_OFFLINE = "true"

$buildDir   = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
    Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path -LiteralPath $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }

Write-Host "julia    : $juliaExe"
Write-Host "JULIA_PKG_OFFLINE = $env:JULIA_PKG_OFFLINE"
Write-Host ""

# ------------------------------------------------------------
# 判定函数
# ------------------------------------------------------------

# 控制字符按「字节」判，不碰正则（PowerShell 的 "`0-`10" 会被拆成 \x00、1、0，
# 字符类范围变成 \x00-\x31，结束标记永远匹配不到 → 全部误报失败）
function Test-HasCtrl([string]$Path) {
    foreach ($b in [System.IO.File]::ReadAllBytes($Path)) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

function Get-Text([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    return [System.IO.File]::ReadAllText($Path)
}

# 返回：通过 = $true；失败时 $script:Why 里是具体原因
function Test-Output {
    param([string]$OutPath, [string]$ErrPath, [int]$ExitCode, [string]$Marker)
    $why = @()
    if ($ExitCode -ne 0) { $why += "退出码 $ExitCode" }
    $errText = Get-Text $ErrPath
    if ($errText.Trim().Length -gt 0) { $why += "stderr 非空" }
    $outText = Get-Text $OutPath
    if ($outText.Trim().Length -eq 0) { $why += "stdout 为空" }
    if (Test-HasCtrl $OutPath) { $why += "输出含控制字符" }
    if ($outText -match 'WARNING:|ERROR:|MethodError|UndefVarError|Stacktrace') {
        $why += "输出含 Julia 诊断字样"
    }
    if (-not $outText.Contains($Marker)) { $why += "缺少结束标记" }
    return $why
}

# 用 .NET 直接起进程：Start-Process 会吃掉内层引号、又会吞掉空行，两个坑都躲开。
# stdout / stderr 分两个文件落盘，判定才能分开看。
function Invoke-Julia {
    param([string[]]$ArgList, [string]$OutPath, [string]$ErrPath, [string]$WorkDir = $projectRoot, [switch]$Quiet)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $juliaExe
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.WorkingDirectory = $WorkDir
    foreach ($a in $ArgList) { $psi.ArgumentList.Add($a) }
    $p = [System.Diagnostics.Process]::Start($psi)
    $outTask = $p.StandardOutput.ReadToEndAsync()
    $errTask = $p.StandardError.ReadToEndAsync()
    $p.WaitForExit() | Out-Null
    $out = $outTask.GetAwaiter().GetResult()
    $err = $errTask.GetAwaiter().GetResult()
    if ($Quiet) { return $p.ExitCode }      # 预热：输出直接丢掉，build/ 里不留文件
    [System.IO.File]::WriteAllText($OutPath, $out)
    [System.IO.File]::WriteAllText($ErrPath, $err)
    return $p.ExitCode
}

$script:Pass = 0
$script:Fail = 0
$script:FailedList = @()

function Invoke-Check {
    param([string]$Tag, [string]$OutPath, [string]$ErrPath, [int]$ExitCode, [string]$Marker)
    $why = Test-Output -OutPath $OutPath -ErrPath $ErrPath -ExitCode $ExitCode -Marker $Marker
    if ($why.Count -eq 0) {
        $script:Pass++
        Write-Host "  [OK] $Tag" -ForegroundColor Green
    } else {
        $script:Fail++
        $script:FailedList += $Tag
        Write-Host "  [FAIL] $Tag —— $($why -join '；')" -ForegroundColor Red
        $errText = Get-Text $ErrPath
        if ($errText.Trim().Length -gt 0) {
            Write-Host "        stderr 前 8 行：" -ForegroundColor DarkGray
            ($errText -split "`n" | Select-Object -First 8) | ForEach-Object { Write-Host "        $_" }
        }
        $outText = Get-Text $OutPath
        Write-Host "        stdout 最后 8 行：" -ForegroundColor DarkGray
        ($outText -split "`n" | Select-Object -Last 8) | ForEach-Object { Write-Host "        $_" }
    }
    if ($ShowOutput) {
        (Get-Text $OutPath) -split "`n" | ForEach-Object { Write-Host "        $_" }
    }
}

# ------------------------------------------------------------
# 每个示例：运行层 + 测试层（17/24 走 Pkg 工程流程，20 加 -t 4）
# ------------------------------------------------------------
function Test-One {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    $num  = ($name -split "_")[0]
    $marker = "==== $num 结束 ===="
    Write-Host "==== $name ====" -ForegroundColor Cyan

    $runFlags  = @("--startup-file=no", "--history-file=no", "--check-bounds=yes")
    $testFlags = @("--startup-file=no", "--history-file=no", "--check-bounds=yes")
    $mainArgs  = @()

    switch ($name) {
        "02_hello"       { $mainArgs = @("Julia", "1.13") }        # 演示 ARGS 与 Base.@main
        "20_concurrency" { $runFlags += @("-t", "4"); $testFlags += @("-t", "4") }
    }

    if ($name -eq "17_pkgenv" -or $name -eq "24_miniode") {
        $envDir = Join-Path $Dir "env"
        if (-not (Test-Path -LiteralPath (Join-Path $envDir "Project.toml"))) {
            throw "缺少环境: $envDir/Project.toml"
        }
        $runFlags  += "--project=$envDir"
        $testFlags += "--project=$envDir"
        # env/Manifest.toml 是本仓库入库的文件（版本已锁死），依赖只有 [sources] 路径包
        # 和 stdlib —— 直接跑即可，**不需要** Pkg.instantiate()。
        # 反过来，在没有 registry 的 depot 上强行 instantiate 会让 Julia 去下载并解压
        # General registry（7.5MB → 240MB、约 4 万个小文件），慢得像死锁（macOS 实测）。
        # 所以：只有 Manifest 真缺了（首次从零解析）才 instantiate。
        if (-not (Test-Path -LiteralPath (Join-Path $envDir "Manifest.toml"))) {
            Write-Host "  [info] $name 缺 env/Manifest.toml —— 首次解析环境"
            $rc = Invoke-Julia -ArgList @("--startup-file=no", "--history-file=no", "--project=$envDir",
                                          "-e", 'using Pkg; Pkg.instantiate()') `
                               -OutPath (Join-Path $buildDir "$name.instantiate.out") `
                               -ErrPath (Join-Path $buildDir "$name.instantiate.err")
            # instantiate 只看退出码：Pkg 的「Precompiling…」进度本来就走 stderr，
            # 拿「stderr 为空」去判它必然误报失败。
            if ($rc -ne 0) {
                $script:Fail++
                $script:FailedList += "$name instantiate"
                Write-Host "  [FAIL] $name instantiate —— Pkg.instantiate 失败（退出码 $rc）" -ForegroundColor Red
                Write-Host "        $(Get-Text (Join-Path $buildDir "$name.instantiate.err"))"
                return
            }
        }
        # 预热：首次运行会触发本地包预编译，Pkg 的「Precompiling…」进度走 stderr，
        # 那不是告警。先把预编译跑掉（输出丢弃），判定层再跑就是干净的一次。
        Invoke-Julia -ArgList ($runFlags + @((Join-Path $Dir "main.jl")) + $mainArgs) -Quiet | Out-Null
    }

    # ---- 运行层 ----
    $runArgs = $runFlags + @((Join-Path $Dir "main.jl")) + $mainArgs
    $rc = Invoke-Julia -ArgList $runArgs `
                       -OutPath (Join-Path $buildDir "$name.run.out") `
                       -ErrPath (Join-Path $buildDir "$name.run.err")
    Invoke-Check -Tag "run      $name" -OutPath (Join-Path $buildDir "$name.run.out") `
                 -ErrPath (Join-Path $buildDir "$name.run.err") -ExitCode $rc -Marker $marker

    # ---- 测试层（@testset 失败会让进程 exit 1；它 include 了 main.jl，标记同样要在）----
    $tArgs = $testFlags + @((Join-Path $Dir "runtests.jl"))
    $rc = Invoke-Julia -ArgList $tArgs `
                       -OutPath (Join-Path $buildDir "$name.test.out") `
                       -ErrPath (Join-Path $buildDir "$name.test.err")
    Invoke-Check -Tag "test     $name" -OutPath (Join-Path $buildDir "$name.test.out") `
                 -ErrPath (Join-Path $buildDir "$name.test.err") -ExitCode $rc -Marker $marker
}

if ($Example) {
    $dir = Join-Path $examplesDir $Example
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例目录: $dir" }
    Test-One $dir
} elseif ($All) {
    $dirs = Get-ChildItem -LiteralPath $examplesDir -Directory | Sort-Object Name
    if ($dirs.Count -eq 0) { throw "examples 目录下没有示例目录。" }
    foreach ($d in $dirs) { Test-One $d.FullName }
} else {
    Write-Host "用法:" -ForegroundColor Yellow
    Write-Host "  pwsh ./build.ps1 -All                 验证 examples 下全部示例（运行层+测试层）"
    Write-Host "  pwsh ./build.ps1 -Example 09_arrays   验证单个示例"
    Write-Host "  pwsh ./build.ps1 -Julia /path/to/julia  指定 julia 可执行文件"
    Write-Host "  pwsh ./build.ps1 -Clean               清理 build 目录"
    exit 0
}

Write-Host ""
Write-Host "通过 $script:Pass   失败 $script:Fail"
if ($script:Fail -eq 0) {
    Write-Host "全部通过" -ForegroundColor Green
    exit 0
} else {
    Write-Host "失败项："
    foreach ($t in $script:FailedList) { Write-Host "  - $t" }
    exit 1
}
