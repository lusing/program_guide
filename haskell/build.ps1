param(
    [switch]$All,
    [string]$Example,
    [string]$Ghc,
    [switch]$Clean,
    [switch]$ShowOutput
)

# ============================================================
# build.ps1 —— 用 GHC 跑遍所有示例（PowerShell 版，等价于 run-all.sh）
#
#   pwsh ./build.ps1 -All                 全部示例（运行层 + 测试层）
#   pwsh ./build.ps1 -Example 09_lists    单个示例
#   pwsh ./build.ps1 -All -ShowOutput     附带每个示例的完整输出
#   pwsh ./build.ps1 -Clean               清理 build 目录
#
# 每个示例目录的结构（Haskell 无 include 机制，采用"库 + 双 Main"）：
#   ChNN.hs      库模块：本章全部纯函数
#   main.hs      演示入口：module Main，导入 ChNN，打印演示与自检
#   runtests.hs  测试入口：module Main，导入 ChNN，断言套件（失败 exitFailure）
#
# 判定标准（六条，与 run-all.sh 逐条一致）：
#   1. 编译退出码为 0（编译错误/警告都算失败——示例代码必须零警告）
#   2. 运行退出码为 0
#   3. stderr 为空（GHC 的警告/错误都走 stderr，等价于「零告警」）
#   4. stdout 非空（防「进程没执行到业务代码」的假阳性）
#   5. stdout 里没有多余控制字符（TAB/LF/CR 除外）
#   6. stdout 里有结束标记 "==== NN 结束 ====" 且无 GHC 诊断字样
#
# 工具链定位不硬编码任何一台机器的路径：
#   -Ghc 参数 → 环境变量 GHC → PATH 上的 ghc → 常见安装位置
#
# 特判：
#   02_hello        运行层带演示参数
#   22_concurrency  编译加 -threaded -rtsopts "-with-rtsopts=-N4"
#   20/24           stack 工程：stack build + stack test（仅查退出码与标记），
#                   再 stack exec 跑 exe（宽松判定：stack 自身进度信息走 stderr）
# ============================================================

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$buildDir    = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

# ------------------------------------------------------------
# 工具链定位
# ------------------------------------------------------------
$Candidates = @()
if ($Ghc) { $Candidates += $Ghc }
if ($env:GHC) { $Candidates += $env:GHC }
$Candidates += 'ghc'
if ($env:SCOOP)   { $Candidates += "$env:SCOOP\apps\haskell\current\bin\ghc.exe" }
if ($env:USERPROFILE) { $Candidates += "$env:USERPROFILE\scoop\apps\haskell\current\bin\ghc.exe" }

$ghcExe = $null
foreach ($c in $Candidates) {
    if (-not $c) { continue }
    $cmd = Get-Command $c -ErrorAction SilentlyContinue
    if ($cmd) { $ghcExe = $cmd.Source; break }
}
if (-not $ghcExe) { throw "未找到 ghc（可传 -Ghc 路径或设环境变量 GHC）" }

[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) { Remove-Item -LiteralPath $buildDir -Recurse -Force }
    Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    exit 0
}

if (-not (Test-Path -LiteralPath $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }

Write-Host "ghc     : $ghcExe"
& $ghcExe --version | Write-Host
Write-Host ""

# ------------------------------------------------------------
# 判定函数
# ------------------------------------------------------------

# 控制字符按「字节」判（<32 且非 TAB/LF/CR）——中文 UTF-8 多字节序列的每个字节都 >=128，不会误伤
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

# 返回失败原因列表；空列表 = 通过。$Relaxed 时跳过 stderr 检查（stack 包装的进程其进度信息走 stderr）
function Test-Output {
    param([string]$OutPath, [string]$ErrPath, [int]$ExitCode, [string]$Marker, [switch]$Relaxed)
    $why = @()
    if ($ExitCode -ne 0) { $why += "退出码 $ExitCode" }
    $errText = Get-Text $ErrPath
    if (-not $Relaxed -and $errText.Trim().Length -gt 0) { $why += "stderr 非空" }
    $outText = Get-Text $OutPath
    if ($outText.Trim().Length -eq 0) { $why += "stdout 为空" }
    if (Test-HasCtrl $OutPath) { $why += "输出含控制字符" }
    if ($outText -match 'Warning:|error:|rror:|Exception|Prelude undefined') {
        $why += "输出含 GHC 诊断字样"
    }
    if (-not $outText.Contains($Marker)) { $why += "缺少结束标记" }
    return $why
}

# 用 .NET 直接起进程：Start-Process 会吃掉内层引号、又会吞掉空行，两个坑都躲开。
function Invoke-Proc {
    param([string]$FileName, [string[]]$ArgList, [string]$OutPath, [string]$ErrPath,
          [string]$WorkDir = $projectRoot, [switch]$Quiet)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $FileName
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
    if ($Quiet) { return $p.ExitCode }
    [System.IO.File]::WriteAllText($OutPath, $out)
    [System.IO.File]::WriteAllText($ErrPath, $err)
    return $p.ExitCode
}

$script:Pass = 0
$script:Fail = 0
$script:FailedList = @()

function Invoke-Check {
    param([string]$Tag, [string]$OutPath, [string]$ErrPath, [int]$ExitCode, [string]$Marker,
          [switch]$Relaxed)
    $why = Test-Output -OutPath $OutPath -ErrPath $ErrPath -ExitCode $ExitCode -Marker $Marker -Relaxed:$Relaxed
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
# 编译 + 运行一个 Main（main.hs 或 runtests.hs）
# ------------------------------------------------------------
function Invoke-GhcMain {
    param([string]$Dir, [string]$Source, [string]$ExeName, [string[]]$ExtraFlags, [string]$Tag)
    $name = Split-Path -Leaf $Dir
    $objDir = Join-Path $buildDir "$name.$ExeName.obj"
    $exe    = Join-Path $buildDir "$name.$ExeName.exe"
    $src    = Join-Path $Dir $Source
    # -v0 关掉 GHC 自己的进度输出；-O0 编译快（验证不测性能，19 章正文另讲 -O2）
    $args = @("-v0", "-O0", "--make", "-i$Dir", "-outputdir", $objDir, $src, "-o", $exe) + $ExtraFlags
    $rc = Invoke-Proc -FileName $ghcExe -ArgList $args `
                      -OutPath (Join-Path $buildDir "$name.$ExeName.c.out") `
                      -ErrPath (Join-Path $buildDir "$name.$ExeName.c.err")
    if ($rc -ne 0) {
        $script:Fail++
        $script:FailedList += "$Tag $name 编译"
        Write-Host "  [FAIL] $Tag $name 编译 —— 退出码 $rc" -ForegroundColor Red
        Write-Host "        stderr：" -ForegroundColor DarkGray
        (Get-Text (Join-Path $buildDir "$name.$ExeName.c.err")) -split "`n" |
            Select-Object -First 12 | ForEach-Object { Write-Host "        $_" }
        return $false
    }
    return $exe
}

function Test-One {
    param([string]$Dir)
    $name = Split-Path -Leaf $Dir
    $num  = ($name -split "_")[0]
    $marker = "==== $num 结束 ===="
    Write-Host "==== $name ====" -ForegroundColor Cyan

    # ---- stack 工程（20/24）：build + test + exec，不走 ghc 直编 ----
    if ($name -eq "20_stackenv" -or $name -eq "24_capstone") {
        # 兜底：PATH 上的 strip 若是坏 shim（指向已卸载目录），Cabal 的 copy 阶段会静默失败。
        # 探测一个能真跑起来的 strip 目录前置到 PATH。
        foreach ($d in ($env:PATH -split ';' | Where-Object { $_ })) {
            $stripExe = Join-Path $d "strip.exe"
            if (Test-Path -LiteralPath $stripExe) {
                $null = & $stripExe --version 2>$null
                if ($LASTEXITCODE -eq 0) { $env:PATH = "$d;$env:PATH"; break }
            }
        }
        $rc = Invoke-Proc -FileName "stack" -ArgList @("build") `
                          -OutPath (Join-Path $buildDir "$name.build.out") `
                          -ErrPath (Join-Path $buildDir "$name.build.err") -WorkDir $Dir
        if ($rc -ne 0) {
            $script:Fail++
            $script:FailedList += "$name stack build"
            Write-Host "  [FAIL] $name stack build —— 退出码 $rc" -ForegroundColor Red
            (Get-Text (Join-Path $buildDir "$name.build.err")) -split "`n" |
                Select-Object -First 12 | ForEach-Object { Write-Host "        $_" }
            return
        }
        $rc = Invoke-Proc -FileName "stack" -ArgList @("test") `
                          -OutPath (Join-Path $buildDir "$name.test.out") `
                          -ErrPath (Join-Path $buildDir "$name.test.err") -WorkDir $Dir
        Invoke-Check -Tag "test     $name (stack test)" -OutPath (Join-Path $buildDir "$name.test.out") `
                     -ErrPath (Join-Path $buildDir "$name.test.err") -ExitCode $rc -Marker $marker -Relaxed
        $exeName = if ($name -eq "20_stackenv") { "stackenv" } else { "minilang" }
        $runArgs = if ($name -eq "24_capstone") { @("exec", $exeName, "--", "demo") } else { @("exec", $exeName) }
        $rc = Invoke-Proc -FileName "stack" -ArgList $runArgs `
                          -OutPath (Join-Path $buildDir "$name.run.out") `
                          -ErrPath (Join-Path $buildDir "$name.run.err") -WorkDir $Dir
        Invoke-Check -Tag "run      $name (stack exec)" -OutPath (Join-Path $buildDir "$name.run.out") `
                     -ErrPath (Join-Path $buildDir "$name.run.err") -ExitCode $rc -Marker $marker -Relaxed
        return
    }

    # ---- 普通示例：编译 + 运行 ----
    $extra = @()
    if ($name -eq "22_concurrency") { $extra = @("-threaded", "-rtsopts", "-with-rtsopts=-N4") }

    $exe = Invoke-GhcMain -Dir $Dir -Source "main.hs" -ExeName "run" -ExtraFlags $extra -Tag "run"
    if (-not $exe) { return }
    $mainArgs = @()
    if ($name -eq "02_hello") { $mainArgs = @("Haskell", "9.12") }
    $rc = Invoke-Proc -FileName $exe -ArgList $mainArgs `
                      -OutPath (Join-Path $buildDir "$name.run.out") `
                      -ErrPath (Join-Path $buildDir "$name.run.err") -WorkDir $Dir
    Invoke-Check -Tag "run      $name" -OutPath (Join-Path $buildDir "$name.run.out") `
                 -ErrPath (Join-Path $buildDir "$name.run.err") -ExitCode $rc -Marker $marker

    $exe = Invoke-GhcMain -Dir $Dir -Source "runtests.hs" -ExeName "test" -ExtraFlags $extra -Tag "test"
    if (-not $exe) { return }
    $rc = Invoke-Proc -FileName $exe -ArgList @() `
                      -OutPath (Join-Path $buildDir "$name.test.out") `
                      -ErrPath (Join-Path $buildDir "$name.test.err") -WorkDir $Dir
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
    Write-Host "  pwsh ./build.ps1 -Example 09_lists    验证单个示例"
    Write-Host "  pwsh ./build.ps1 -Ghc /path/to/ghc    指定 ghc 可执行文件"
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
