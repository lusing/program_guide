# ============================================================
# build.ps1 —— Erlang/OTP 教程四层验证入口（pwsh 7）
#
#   pwsh ./build.ps1 -All                     验证 examples/ 下全部示例
#   pwsh ./build.ps1 -Example 02_hello        验证单个示例
#   pwsh ./build.ps1 -Clean                   清理 build 目录
#   pwsh ./build.ps1 -All -TimeoutSec 120     调整每进程超时上限
#
# 四层验证（对齐 go/zig 教程的分层标准，Erlang 等价物）：
#   1. 编译   erlc -Wall -Werror（警告即错误，相当于 fmt+vet）
#   2. 测试   eunit:test('NN_topic_tests')（相当于 go test）
#   3. 运行   erl -noshell -run 'NN_topic' main —— 四条判定：
#              退出码 0 / stderr 为空 / stdout 无控制字符(TAB/LF/CR 外)
#              / 含结束标记 "==== NN 结束 ===="
#              （Erlang 里 main 崩了而没人 link 时退出码仍可能是 0，
#                结束标记是"从头跑到尾"的唯一铁证）
#   4. 确定性 同一份 BEAM 用 +S 1:1（单调度器）再跑一遍，两通道 stdout
#             必须逐字节一致（相当于 go test -race 的地位）——
#             抓 map 迭代顺序、ETS 顺序、pid/ref/时间戳、内存数字等
#             依赖调度与环境的输出。
# ============================================================
param(
    [switch]$All,
    [string]$Example,
    [switch]$Clean,
    [int]$TimeoutSec = 60
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# 工具链：固定 scoop 路径，回退 PATH（对齐 go/zig 的 build.ps1 做法）
$erlBin = "G:\scoop\apps\erlang\current\bin\erl.exe"
$erlcBin = "G:\scoop\apps\erlang\current\bin\erlc.exe"
if (-not (Test-Path -LiteralPath $erlBin))  { $erlBin  = (Get-Command erl  -ErrorAction SilentlyContinue).Source }
if (-not (Test-Path -LiteralPath $erlcBin)) { $erlcBin = (Get-Command erlc -ErrorAction SilentlyContinue).Source }
if (-not $erlBin)  { throw "未找到 erl.exe（可装 Erlang/OTP 后重试）" }
if (-not $erlcBin) { throw "未找到 erlc.exe" }

# Erlang 输出是 UTF-8；pwsh 7 本来就是 UTF-8，设置一下对旧宿主也无害
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch { }

$buildDir    = Join-Path $projectRoot "build"
$examplesDir = Join-Path $projectRoot "examples"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    } else {
        Write-Host "[Clean] build 目录不存在，无需清理。" -ForegroundColor Yellow
    }
    exit 0
}

if (-not (Test-Path -LiteralPath $examplesDir)) { throw "找不到 examples 目录: $examplesDir" }

# erlc 崩溃 / 示例故意触发的崩溃都会写 crash dump，指到系统空设备免得污染仓库
$devNull = if ($IsWindows -or $env:OS -eq "Windows_NT") { "nul" } else { "/dev/null" }
$env:ERL_CRASH_DUMP = $devNull

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

$otpRelease = & $erlBin -noshell -eval 'io:format("~s", [erlang:system_info(otp_release)]), halt(0).' 2>$null
Write-Host ("erl      : {0} (OTP {1})" -f $erlBin, $otpRelease)
Write-Host ("超时上限 : {0}s" -f $TimeoutSec)

# ---------------------------------------------------------------
# 读文件：判定一律走**字节**，不走 .NET 的默认编码解码。
# GetString 遇非法字节变 U+FFFD 而不是中断 —— 匹配标记不会误报。
# ---------------------------------------------------------------
function Read-TextFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($null -eq $bytes -or $bytes.Length -eq 0) { return "" }
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

# stdout 里是否混进「不该出现」的控制字符（TAB/LF/CR 除外）——按字节扫
function Test-HasCtrl {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    foreach ($b in [System.IO.File]::ReadAllBytes($Path)) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

function Test-ByteEqual {
    param([string]$PathA, [string]$PathB)
    $a = [System.IO.File]::ReadAllBytes($PathA)
    $b = [System.IO.File]::ReadAllBytes($PathB)
    if ($a.Length -ne $b.Length) { return $false }
    for ($i = 0; $i -lt $a.Length; $i++) { if ($a[$i] -ne $b[$i]) { return $false } }
    return $true
}

# ---------------------------------------------------------------
# 进程启动助手：按**字节**捕获 stdout/stderr 到文件，带超时兜底。
#
# 刻意绕开 Start-Process -RedirectStandardOutput，实测它有两个坑：
#   1. 吞空行（"A\n\nB\n" 变 "A\nB\n"）——本教程示例的空行排版会全丢；
#   2. 吃掉参数里的内层双引号（-eval 'io:format("A")' 变 io:format(A)）。
# 改用 System.Diagnostics.Process 手拼 Arguments、直读 BaseStream，
# 全程不碰 .NET 的文本解码：输出是什么字节，文件里就是什么字节。
# ---------------------------------------------------------------
function Invoke-Proc {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [string[]]$Arguments = @(),
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$ErrFile,
        [string]$WorkingDir = $projectRoot,
        [int]$TimeoutMs = 60000
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $Exe
    $psi.UseShellExecute        = $false
    $psi.WorkingDirectory       = $WorkingDir
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    # 只给**含空白**的参数加引号（-eval 的字符串、带空格的路径）
    $psi.Arguments = (($Arguments | ForEach-Object {
        if ($_ -match '\s') { '"' + $_ + '"' } else { $_ }
    }) -join ' ')

    $proc = [System.Diagnostics.Process]::Start($psi)

    $outFs = [System.IO.File]::Open($OutFile, [System.IO.FileMode]::Create,
                                    [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
    $errFs = [System.IO.File]::Open($ErrFile, [System.IO.FileMode]::Create,
                                    [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
    # 先起异步拷贝再 WaitForExit：管道写满而没人读会死锁
    $outTask = $proc.StandardOutput.BaseStream.CopyToAsync($outFs)
    $errTask = $proc.StandardError.BaseStream.CopyToAsync($errFs)

    $timedOut = $false
    if (-not $proc.WaitForExit($TimeoutMs)) {
        $timedOut = $true
        try { $proc.Kill() } catch { }
        $proc.WaitForExit(5000) | Out-Null
    }

    try { $outTask.GetAwaiter().GetResult() | Out-Null } catch { }
    try { $errTask.GetAwaiter().GetResult() | Out-Null } catch { }
    $outFs.Dispose()
    $errFs.Dispose()

    if ($timedOut) { return @{ ExitCode = 124; TimedOut = $true } }
    return @{ ExitCode = $proc.ExitCode; TimedOut = $false }
}

# ---------------------------------------------------------------
# 运行层四条判定（通道 A/B 共用）。通过返回 $true。
# ---------------------------------------------------------------
function Test-RunResult {
    param([string]$Tag, [string]$OutPath, [string]$ErrPath,
           [int]$ExitCode, [string]$Marker, [switch]$TimedOut)

    $reasons = @()

    if ($TimedOut) { $reasons += "超时 ${TimeoutSec}s 被杀" }
    elseif ($ExitCode -ne 0) { $reasons += "退出码 $ExitCode" }

    $errText = Read-TextFile $ErrPath
    if ($errText.Trim() -ne "") {
        $first = ($errText -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1)
        $reasons += "stderr 非空：$($first.Trim())"
    }

    $outText = Read-TextFile $OutPath
    if (Test-HasCtrl $OutPath) { $reasons += "输出含控制字符" }

    # 找标记前先剔控制字符（含 NUL），免得二进制内容干扰匹配
    $clean = [regex]::Replace($outText, '[\x00-\x08\x0B\x0C\x0E-\x1F]', '')
    if (-not $clean.Contains($Marker)) { $reasons += "缺少结束标记 $Marker" }

    if ($reasons.Count -eq 0) {
        Write-Host ("  [OK]   {0}" -f $Tag) -ForegroundColor Green
        return $true
    }

    Write-Host ("  [FAIL] {0} —— {1}" -f $Tag, ($reasons -join "；")) -ForegroundColor Red
    if ($outText.Trim() -ne "") {
        Write-Host "         输出末尾：" -ForegroundColor Red
        ($outText -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -Last 6) |
            ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
    }
    return $false
}

# ---------------------------------------------------------------
# 单个示例的四层验证
# ---------------------------------------------------------------
function Test-One {
    param([string]$Dir)

    $name = Split-Path -Leaf $Dir
    $num  = $name.Substring(0, 2)
    $marker = "==== $num 结束 ===="
    $ebin = Join-Path $buildDir $name
    New-Item -ItemType Directory -Force -Path $ebin | Out-Null

    $workDir = Join-Path $buildDir $name
    $outA = Join-Path $workDir "stdout.txt";  $errA = Join-Path $workDir "stderr.txt"
    $outB = Join-Path $workDir "stdout.s1.txt"; $errB = Join-Path $workDir "stderr.s1.txt"
    $logOut = Join-Path $workDir "compile.out"; $logErr = Join-Path $workDir "compile.err"
    $tstOut = Join-Path $workDir "eunit.out";   $tstErr = Join-Path $workDir "eunit.err"

    Write-Host "`n[Example] $name" -ForegroundColor Cyan

    # ---- 第 1 层：编译（-Wall -Werror，警告即错误）----
    $srcs = @(Get-ChildItem -LiteralPath $Dir -Filter "*.erl" | Sort-Object Name |
              ForEach-Object { $_.FullName })
    if ($srcs.Count -eq 0) { throw "$name 下没有 .erl 源文件" }
    Remove-Item -LiteralPath $logOut, $logErr -Force -ErrorAction SilentlyContinue
    $r = Invoke-Proc -Exe $erlcBin -Arguments (@("+debug_info", "-Werror", "-Wall", "-o", $ebin) + $srcs) `
                     -OutFile $logOut -ErrFile $logErr -TimeoutMs 120000
    $msg = (Read-TextFile $logOut) + (Read-TextFile $logErr)
    if ($r.ExitCode -ne 0 -or $msg.Trim() -ne "") {
        Write-Host "  [FAIL] 编译（-Wall -Werror）" -ForegroundColor Red
        if ($msg.Trim() -ne "") {
            ($msg -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 10) |
                ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
        } else {
            Write-Host ("         erlc 退出码 {0}" -f $r.ExitCode) -ForegroundColor Red
        }
        throw "编译失败: $name"
    }
    Write-Host "  [OK]   编译（零警告）" -ForegroundColor Green

    # .app 是资源文件（file:consult 读的数据），erlc 不认，手工拷进代码路径
    Get-ChildItem -LiteralPath $Dir -Filter "*.app" -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $ebin $_.Name) -Force
    }

    # 某些示例需要额外的 erl 启动参数：25_distributed 要 -sname（本节点是
    # 活节点）才能用 peer 起对端节点——EUnit 层与运行层都要带上
    $extraErlFlags = @()
    switch ($name) {
        "25_distributed" { $extraErlFlags = @("-sname", "ex25_a") }
    }

    # ---- 第 2 层：EUnit ----
    Remove-Item -LiteralPath $tstOut, $tstErr -Force -ErrorAction SilentlyContinue
    $eval = "case eunit:test('${name}_tests') of ok -> halt(0); _ -> halt(1) end."
    $r = Invoke-Proc -Exe $erlBin -Arguments (@("-noshell") + $extraErlFlags + @("-pa", $ebin, "-eval", $eval)) `
                     -OutFile $tstOut -ErrFile $tstErr -TimeoutMs ($TimeoutSec * 1000)
    $ok = ($r.ExitCode -eq 0) -and ((Read-TextFile $tstErr).Trim() -eq "")
    if (-not $ok) {
        Write-Host ("  [FAIL] EUnit —— 退出码 {0}" -f $r.ExitCode) -ForegroundColor Red
        foreach ($p in @($tstOut, $tstErr)) {
            $t = Read-TextFile $p
            if ($t.Trim() -ne "") {
                ($t -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -Last 8) |
                    ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
            }
        }
        throw "EUnit 失败: $name"
    }
    Write-Host "  [OK]   EUnit（'${name}_tests'）" -ForegroundColor Green

    # ---- 第 3、4 层：运行通道 A（默认）+ 通道 B（+S 1:1）----
    # 24_minigrep 吃命令行参数（pattern dir）；其余示例 main/0
    $runArgs = @()
    $runCwd = $projectRoot
    switch ($name) {
        "24_minigrep" { $runArgs = @("spawn", "corpus"); $runCwd = $Dir }
    }

    $baseArgs = (@("-noshell") + $extraErlFlags + @("-pa", $ebin, "-run", $name, "main")) + $runArgs + @("-s", "init", "stop")
    Remove-Item -LiteralPath $outA, $errA, $outB, $errB -Force -ErrorAction SilentlyContinue

    $rA = Invoke-Proc -Exe $erlBin -Arguments $baseArgs -OutFile $outA -ErrFile $errA `
                      -WorkingDir $runCwd -TimeoutMs ($TimeoutSec * 1000)
    $passA = Test-RunResult -Tag "$name (A 默认)" -OutPath $outA -ErrPath $errA `
                            -ExitCode $rA.ExitCode -Marker $marker -TimedOut:$rA.TimedOut

    $rB = Invoke-Proc -Exe $erlBin -Arguments (@("-noshell", "+S", "1:1") + $baseArgs[1..($baseArgs.Count-1)]) `
                      -OutFile $outB -ErrFile $errB `
                      -WorkingDir $runCwd -TimeoutMs ($TimeoutSec * 1000)
    $passB = Test-RunResult -Tag "$name (B +S 1:1)" -OutPath $outB -ErrPath $errB `
                            -ExitCode $rB.ExitCode -Marker $marker -TimedOut:$rB.TimedOut

    if (-not ($passA -and $passB)) { throw "运行判定失败: $name" }

    # 两通道输出必须逐字节一致
    if (Test-ByteEqual $outA $outB) {
        Write-Host "  [same] 两通道输出逐字节一致" -ForegroundColor DarkGray
    } else {
        Write-Host "  [DIFF] 两通道输出不一致（输出依赖调度/环境，见 build/$name/）" -ForegroundColor Red
        $ta = (Read-TextFile $outA) -split "`n"
        $tb = (Read-TextFile $outB) -split "`n"
        $n = [Math]::Min($ta.Count, $tb.Count)
        $shown = 0
        for ($i = 0; $i -lt $n -and $shown -lt 6; $i++) {
            if ($ta[$i] -cne $tb[$i]) {
                Write-Host ("         行 {0}: A: {1} / B: {2}" -f ($i + 1), $ta[$i], $tb[$i]) -ForegroundColor Red
                $shown++
            }
        }
        throw "两通道输出不一致: $name"
    }
}

# ---------------------------------------------------------------
# 选择要验证的示例
# ---------------------------------------------------------------
$dirs = @(Get-ChildItem -LiteralPath $examplesDir -Directory |
          Where-Object { $_.Name -match '^\d\d_' } | Sort-Object Name)

if ($Example) {
    $dir = Join-Path $examplesDir $Example
    if (-not (Test-Path -LiteralPath $dir)) { throw "找不到示例目录: $dir（名字形如 02_hello）" }
    Test-One $dir
    Write-Host "`n[Done] $Example 四层验证通过。" -ForegroundColor Green
    exit 0
}

if ($All) {
    foreach ($d in $dirs) { Test-One $d.FullName }
    Write-Host "`n[Done] 全部 $($dirs.Count) 个示例四层验证通过。" -ForegroundColor Green
    exit 0
}

Write-Host "用法:" -ForegroundColor Yellow
Write-Host "  pwsh ./build.ps1 -All                验证 examples 下全部示例（四层）"
Write-Host "  pwsh ./build.ps1 -Example 02_hello   验证单个示例"
Write-Host "  pwsh ./build.ps1 -Clean              清理 build 目录"
Write-Host ""
Write-Host "四层：erlc -Wall -Werror → EUnit → 运行四条判定 → +S 1:1 双通道逐字节一致"
