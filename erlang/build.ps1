# ============================================================
# build.ps1 —— 编译并运行 examples/ 下全部 Erlang 示例（PowerShell 版）
#
#   pwsh ./build.ps1 -All            编译 + 运行 + 四条判定（两条通道）
#   pwsh ./build.ps1 -All -ShowOutput   额外打印每个示例的完整输出
#   pwsh ./build.ps1 01 13           只跑指定编号（位置参数，与 run-all.sh 一致）
#   pwsh ./build.ps1 -Example 24-ets.erl
#   pwsh ./build.ps1 -Clean          清理 build 目录
#
# 两个通道（同一份 BEAM，只换运行时配置）：
#   A  默认（多调度器）
#   B  +S 1:1（单调度器）
#   两通道都要过四条判定，并且两通道输出必须**逐字节一致**。
#
# 本机只有一套 Erlang 实现（erts 17.0.3 / OTP 29），没法照搬 sml/fortran 的
# 「多实现比对」，所以改成对比两种调度器配置：这条对并发/容器类示例同样是
# 真约束 —— map 迭代顺序每次启动都随机（原子哈希随机种子），ETS set 的
# 顺序未定义，打了 pid / ref / 时间戳的输出都会在这里露出来。
#
# 判定标准（四条，缺一不可，与 run-all.sh 一致）：
#   1. 退出码 0
#   2. stderr 为空
#   3. stdout 里除 TAB/LF/CR 外没有 0..31 的控制字符
#   4. stdout 里有结束标记 "==== NN 结束 ===="
#
# 注意：不要和 run-all.sh 并行跑，两者共用 build/<示例名>/ 下的输出文件。
# ============================================================

# PositionalBinding=$false 必须配合下面的 ValueFromRemainingArguments：
# 关掉位置绑定之后，`./build.ps1 24` 里的 24 不会被绑给 $Example（当成文件名
# 去找 examples/24），而是落到 $Rest 上当编号用。
[CmdletBinding(PositionalBinding = $false)]
param(
    [switch]$All,
    [switch]$Clean,
    [string]$Example,
    [switch]$ShowOutput,
    [int]$TimeoutSec = 60,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$Rest
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# Erlang 的输出是 UTF-8。Windows PowerShell 5.1 的控制台编码默认是本地代码页，
# Start-Process -RedirectStandardOutput 会用它解码子进程输出、再用它编码写文件，
# 中文会变成问号。这里强制成 UTF-8（pwsh 7 本来就是，设置了也无害）。
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

# ---------------------------------------------------------------
# 跨平台判断：pwsh 全平台都有只读自动变量 $IsWindows，**不能**自己去定义
# 同名（变量名不区分大小写）变量，否则报错。所以是「先判断存不存在，再取值」。
# ---------------------------------------------------------------
function Test-OnWindows {
    if (Test-Path Variable:\IsWindows) { return [bool]$IsWindows }
    return ($env:OS -eq "Windows_NT")
}

$devNull = if (Test-OnWindows) { "nul" } else { "/dev/null" }

# ---------------------------------------------------------------
# 工具链定位：环境变量 ERL / ERLC 优先，其次常见安装路径，最后退回 PATH
# ---------------------------------------------------------------
function Resolve-Tool {
    param([string]$EnvVar, [string[]]$Candidates)

    $candidate = ""
    if ($EnvVar) { $candidate = [Environment]::GetEnvironmentVariable($EnvVar) }
    if ($candidate -and -not (Test-Path -LiteralPath $candidate)) { $candidate = "" }

    if (-not $candidate) {
        foreach ($c in $Candidates) {
            if (Test-Path -LiteralPath $c) { $candidate = $c; break }
        }
    }
    if (-not $candidate) {
        foreach ($c in $Candidates) {
            $cmd = Get-Command $c -ErrorAction SilentlyContinue
            if ($cmd) { $candidate = $cmd.Source; break }
        }
    }
    return $candidate
}

$erl = Resolve-Tool "ERL" @(
    "/opt/local/bin/erl", "/usr/local/bin/erl", "/opt/homebrew/bin/erl",
    "C:\Program Files\Erlang OTP\bin\erl.exe",
    "C:\scoop\apps\erlang\current\bin\erl.exe",
    "erl"
)
$erlc = Resolve-Tool "ERLC" @(
    "/opt/local/bin/erlc", "/usr/local/bin/erlc", "/opt/homebrew/bin/erlc",
    "C:\Program Files\Erlang OTP\bin\erlc.exe",
    "C:\scoop\apps\erlang\current\bin\erlc.exe",
    "erlc"
)

$examplesDir = Join-Path $projectRoot "examples"
$buildDir    = Join-Path $projectRoot "build"
$ebinDir     = Join-Path $buildDir "ebin"
$kvAppDir    = Join-Path $examplesDir "kvapp"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    }
    else {
        Write-Host "[Clean] build 目录不存在，无需清理。" -ForegroundColor Yellow
    }
    exit 0
}

if (-not $erl)  { throw "未找到 erl （可设环境变量 ERL 指向它）" }
if (-not $erlc) { throw "未找到 erlc（可设环境变量 ERLC 指向它）" }
if (-not (Test-Path -LiteralPath $examplesDir)) { throw "找不到 examples 目录: $examplesDir" }

# erlc 崩溃 / 示例故意触发的崩溃都会往这里写 dump，指到系统空设备免得污染仓库
$env:ERL_CRASH_DUMP = $devNull

# ---------------------------------------------------------------
# 必须给 Erlang 一个 UTF-8 locale。
#
# 实测坑：locale 是 C/POSIX 时，Erlang 把 standard_io 的设备编码定成 latin1，
# 于是示例里的中文（包括 `==== NN 结束 ====` 这行字面量）会被写成
# `\x{7ED3}\x{675F}` 这种转义形式 —— 结束标记那条判定必然失败；而且 erlc
# 读源码也会按 latin1 解码，字符串字面量的字节全错。
#
# **绝对不要**在这里粗暴地设 $env:LC_ALL = "C"。
# 判定自己读文件走的是字节，不受 locale 影响，所以 locale 只需要照顾 Erlang。
# ---------------------------------------------------------------
function Ensure-Utf8Locale {
    foreach ($v in @($env:LC_ALL, $env:LC_CTYPE, $env:LANG)) {
        if ($v -and ($v -match '(?i)utf-?8')) { return }
    }
    $localeCmd = Get-Command locale -ErrorAction SilentlyContinue
    if (-not $localeCmd) { return }   # Windows 没有 locale 命令，跳过

    foreach ($cand in @("en_US.UTF-8", "zh_CN.UTF-8", "C.UTF-8", "en_US.utf8")) {
        $prev = $env:LC_ALL
        $env:LC_ALL = $cand
        $charmap = (& locale charmap 2>$null)
        if ($charmap -eq "UTF-8") {
            $env:LANG = $cand
            return
        }
        $env:LC_ALL = $prev
    }
    Write-Host "警告：当前 locale 不是 UTF-8，也没找到可用的 UTF-8 locale。" -ForegroundColor Yellow
    Write-Host "      Erlang 会把中文输出成 \x{...} 转义形式，结束标记会匹配失败。" -ForegroundColor Yellow
}
Ensure-Utf8Locale

New-Item -ItemType Directory -Force -Path $ebinDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $buildDir "compile") | Out-Null

$otpRelease = (& $erl -noshell -eval 'io:format("~s", [erlang:system_info(otp_release)]), halt(0).' 2>$null)
Write-Host ("erl      : {0} (OTP {1})" -f $erl, $otpRelease)
Write-Host ("erlc     : {0}" -f $erlc)
Write-Host ("超时上限 : {0}s" -f $TimeoutSec)
Write-Host ""

# ---------------------------------------------------------------
# 读文件：判定一律走**字节**，不走 .NET 的默认编码解码。
# Get-Content -Raw 读空文件会返回 $null，必须兜底。
# ---------------------------------------------------------------
function Read-TextFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($null -eq $bytes -or $bytes.Length -eq 0) { return "" }
    # 这里刻意用 GetString（非法字节 → U+FFFD），等价于 run-all.sh 里的
    # `tr -d '\000' | grep -qF` —— 不会因为非法字节中断匹配。
    return [System.Text.Encoding]::UTF8.GetString($bytes)
}

function Get-FileSizeSafe {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return 0 }
    return (Get-Item -LiteralPath $Path).Length
}

# ---------------------------------------------------------------
# 进程启动助手：按**字节**捕获 stdout/stderr 到文件，并带超时兜底
#
# ⚠ 这里刻意绕开 Start-Process -RedirectStandardOutput，因为它有两个坑：
#
#   1. **吞空行**。实测：子进程输出 "A\n\nB\n"（5 字节），重定向出来的文件
#      只有 "A\nB\n"（4 字节）。Start-Process 内部按行读再拼回去，空行就没了。
#      本仓库的示例用 `io:format("~n== N) 标题 ==~n")` 排版，每个章节标题前
#      都有一个空行 —— 于是 PowerShell 版的输出比 shell 版少了一批空行。
#      四条判定根本发现不了这件事（结束标记还在、也没有控制字符），
#      只有把两个入口产生的 build/<示例>/stdout.txt 拿来逐字节比才看得出来。
#
#   2. **吃掉参数里的内层双引号**。实测 -eval 'io:format("A"),halt(0).'
#      真到 erl 手里变成了 io:format(A)。
#
#   改用 System.Diagnostics.Process：自己拼 Arguments，自己读 BaseStream，
#   全程不碰 .NET 的文本解码 —— 输出是什么字节，文件里就是什么字节。
# ---------------------------------------------------------------
function Invoke-Proc {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [string[]]$Arguments = @(),
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$ErrFile,
        [int]$TimeoutMs = 60000
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName               = $Exe
    $psi.UseShellExecute        = $false
    $psi.WorkingDirectory       = $projectRoot
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    # 只给**含空白**的参数加引号：路径里可能有空格（比如 Windows 上把仓库
    # clone 到 "My Documents"），而 erlc 的开关、模块名都不含空格。
    $psi.Arguments = (($Arguments | ForEach-Object {
        if ($_ -match '\s') { '"' + $_ + '"' } else { $_ }
    }) -join ' ')

    $proc = [System.Diagnostics.Process]::Start($psi)

    $outFs = [System.IO.File]::Open($OutFile, [System.IO.FileMode]::Create,
                                    [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
    $errFs = [System.IO.File]::Open($ErrFile, [System.IO.FileMode]::Create,
                                    [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
    # 先起了异步拷贝再 WaitForExit：管道缓冲写满而没人读会死锁
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
# 输出里是否混进了「不该出现」的控制字符（TAB / LF / CR 除外）
# 直接按字节扫，不受 locale 影响。
# ---------------------------------------------------------------
function Test-HasCtrl {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    foreach ($b in [System.IO.File]::ReadAllBytes($Path)) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

# 两个文件是否逐字节一致（按字节比，不受编码影响）
function Test-ByteEqual {
    param([string]$PathA, [string]$PathB)
    if (-not (Test-Path -LiteralPath $PathA)) { return $false }
    if (-not (Test-Path -LiteralPath $PathB)) { return $false }
    $a = [System.IO.File]::ReadAllBytes($PathA)
    $b = [System.IO.File]::ReadAllBytes($PathB)
    if ($a.Length -ne $b.Length) { return $false }
    for ($i = 0; $i -lt $a.Length; $i++) {
        if ($a[$i] -ne $b[$i]) { return $false }
    }
    return $true
}

# ---------------------------------------------------------------
# 四条判定
# ---------------------------------------------------------------
function Test-Result {
    param(
        [Parameter(Mandatory = $true)][string]$Tag,
        [Parameter(Mandatory = $true)][string]$OutPath,
        [Parameter(Mandatory = $true)][string]$ErrPath,
        [Parameter(Mandatory = $true)][int]$ExitCode,
        [Parameter(Mandatory = $true)][string]$Marker,
        [Parameter(Mandatory = $true)][string]$BuildLog,
        [switch]$TimedOut
    )

    $reasons = @()

    if ($TimedOut) { $reasons += "超时 ${TimeoutSec}s 被杀" }
    elseif ($ExitCode -ne 0) { $reasons += "退出码 $ExitCode" }

    $errText = Read-TextFile $ErrPath
    if ($errText.Trim() -ne "") {
        $first = ($errText -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1)
        $reasons += "stderr 非空：$($first.Trim())"
    }

    if (Test-HasCtrl $OutPath) { $reasons += "输出含控制字符" }

    # 找结束标记前先去掉控制字符（含 NUL），免得二进制内容干扰匹配。
    # 正则里的控制字符一律写 \xNN —— PowerShell 的反引号转义 "`10" 会被拆成
    # "1"+"0"，拼出来的字符类会把等号一起吃掉，标记就永远找不到了。
    $outText = Read-TextFile $OutPath
    $clean   = [regex]::Replace($outText, '[\x00-\x08\x0B\x0C\x0E-\x1F]', '')
    if (-not $clean.Contains($Marker)) { $reasons += "缺少结束标记 $Marker" }

    if ($reasons.Count -eq 0) {
        Write-Host ("  [OK]   {0}" -f $Tag) -ForegroundColor Green
        return $true
    }

    Write-Host ("  [FAIL] {0} —— {1}" -f $Tag, ($reasons -join "；")) -ForegroundColor Red

    $logText = Read-TextFile $BuildLog
    if ($logText.Trim() -ne "") {
        Write-Host "         编译输出：" -ForegroundColor Red
        ($logText -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -Last 8) |
            ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
    }
    if ($outText.Trim() -ne "") {
        Write-Host "         输出末尾：" -ForegroundColor Red
        ($outText -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -Last 6) |
            ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
    }
    return $false
}

# ---------------------------------------------------------------
# 编译：examples/*.erl（顶层示例）与 examples/kvapp/*.erl（最小 OTP 应用）
# 一次编一个文件，失败时能指出是哪个文件。
# ---------------------------------------------------------------
$script:CompileFailed = 0

function Invoke-Compile {
    param([string]$Src)
    # Start-Process 不允许 -RedirectStandardOutput 和 -RedirectStandardError
    # 指向同一个文件（会直接报错），所以编译日志必须拆成两个文件。
    # erlc 的诊断信息走 stderr，但与波特率编译成功时也可能有提示，两个都看。
    $base = [System.IO.Path]::GetFileNameWithoutExtension($Src)
    $logOut = Join-Path (Join-Path $buildDir "compile") "$base.out"
    $logErr = Join-Path (Join-Path $buildDir "compile") "$base.err"
    Remove-Item -LiteralPath $logOut, $logErr -Force -ErrorAction SilentlyContinue
    $r = Invoke-Proc -Exe $erlc `
                     -Arguments @("-Werror", "-Wall", "-o", $ebinDir, $Src) `
                     -OutFile $logOut -ErrFile $logErr -TimeoutMs 120000
    $msg = (Read-TextFile $logOut) + (Read-TextFile $logErr)
    if ($r.ExitCode -eq 0 -and $msg.Trim() -eq "") {
        Remove-Item -LiteralPath $logOut, $logErr -Force -ErrorAction SilentlyContinue
        return $true
    }
    $script:CompileFailed++
    Write-Host "  [FAIL] 编译 $Src" -ForegroundColor Red
    if ($r.TimedOut) {
        Write-Host "         编译超时" -ForegroundColor Red
    }
    elseif ($msg.Trim() -ne "") {
        ($msg -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 10) |
            ForEach-Object { Write-Host "         $_" -ForegroundColor Red }
    }
    else {
        Write-Host ("         erlc 退出码 {0}" -f $r.ExitCode) -ForegroundColor Red
    }
    return $false
}

# ---------------------------------------------------------------
# 收集源文件
# ---------------------------------------------------------------
$sources = @(Get-ChildItem -LiteralPath $examplesDir -Filter "*.erl" |
                Where-Object { $_.Name -match '^\d\d-' } |
                Sort-Object Name)

$kvSources = @()
if (Test-Path -LiteralPath $kvAppDir) {
    $kvSources = @(Get-ChildItem -LiteralPath $kvAppDir -Filter "*.erl" | Sort-Object Name)
}

if ($sources.Count -eq 0) { throw "examples/ 下没有 NN-*.erl 示例文件。" }

Write-Host "== 编译 =="
foreach ($f in $kvSources) { Invoke-Compile -Src $f.FullName | Out-Null }
foreach ($f in $sources)   { Invoke-Compile -Src $f.FullName | Out-Null }

# kvapp.app 是**资源文件**（file:consult 读的数据），erlc 不认。
# 必须手工拷到代码路径上 —— application:load(kvapp) 就是去代码路径里找
# build/ebin/kvapp.app。忘了拷会得到 {error, {"no such file or directory", ...}}。
foreach ($appf in @(Get-ChildItem -LiteralPath $kvAppDir -Filter "*.app" -ErrorAction SilentlyContinue)) {
    Copy-Item -LiteralPath $appf.FullName -Destination (Join-Path $ebinDir $appf.Name) -Force
}

if ($script:CompileFailed -ne 0) {
    Write-Host ""
    Write-Host "有 $script:CompileFailed 个文件编译失败（-Wall -Werror：警告即错误），停止运行。" -ForegroundColor Red
    exit 1
}
Write-Host ("  全部 {0} 个示例编译通过（源码 + kvapp/ 辅助模块，零警告）" -f $sources.Count)
Write-Host ""

# ---------------------------------------------------------------
# 运行：每个示例跑两个通道
# ---------------------------------------------------------------
$script:pass = 0
$script:fail = 0
$script:diffW = 0
$script:failedTags = @()

function Invoke-Example {
    param([System.IO.FileInfo]$FileInfo)

    $base   = [System.IO.Path]::GetFileNameWithoutExtension($FileInfo.Name)
    $num    = ($base -split "-")[0]
    $marker = "==== $num 结束 ===="

    $outdir = Join-Path $buildDir $base
    New-Item -ItemType Directory -Force -Path $outdir | Out-Null
    $buildLog = Join-Path (Join-Path $buildDir "compile") "$base.err"

    Write-Host "==== $base ====" -ForegroundColor Cyan

    $outA = Join-Path $outdir "stdout.txt"
    $errA = Join-Path $outdir "stderr.txt"
    $outB = Join-Path $outdir "stdout.s1.txt"
    $errB = Join-Path $outdir "stderr.s1.txt"

    # 先删掉旧文件，免得上一轮失败的输出被当成这一轮的结果
    foreach ($p in @($outA, $errA, $outB, $errB)) {
        Remove-Item -LiteralPath $p -Force -ErrorAction SilentlyContinue
    }

    $timeoutMs = $TimeoutSec * 1000

    # 通道 A：默认调度器
    $rA = Invoke-Proc -Exe $erl `
                      -Arguments @("-noshell", "-pa", $ebinDir, "-run", $base, "main", "-s", "init", "stop") `
                      -OutFile $outA -ErrFile $errA -TimeoutMs $timeoutMs
    if (Test-Result -Tag ("{0} (A 默认)" -f $base) -OutPath $outA -ErrPath $errA `
                    -ExitCode $rA.ExitCode -Marker $marker -BuildLog $buildLog -TimedOut:$rA.TimedOut) {
        $script:pass++
    }
    else {
        $script:fail++
        $script:failedTags += "$base (A 默认)"
    }

    # 通道 B：单调度器
    $rB = Invoke-Proc -Exe $erl `
                      -Arguments @("-noshell", "+S", "1:1", "-pa", $ebinDir, "-run", $base, "main", "-s", "init", "stop") `
                      -OutFile $outB -ErrFile $errB -TimeoutMs $timeoutMs
    if (Test-Result -Tag ("{0} (B +S 1:1)" -f $base) -OutPath $outB -ErrPath $errB `
                    -ExitCode $rB.ExitCode -Marker $marker -BuildLog $buildLog -TimedOut:$rB.TimedOut) {
        $script:pass++
    }
    else {
        $script:fail++
        $script:failedTags += "$base (B +S 1:1)"
    }

    # 附加检查：两个通道输出必须逐字节一致
    if ((Get-FileSizeSafe $outA) -gt 0 -and (Get-FileSizeSafe $outB) -gt 0) {
        if (Test-ByteEqual $outA $outB) {
            Write-Host "  [same] 两通道输出逐字节一致" -ForegroundColor DarkGray
        }
        else {
            $script:diffW++
            Write-Host ("  [DIFF] 两通道输出不一致（不可重复输出，见 build/{0}/）" -f $base) -ForegroundColor DarkYellow
            $ta = (Read-TextFile $outA) -split "`n"
            $tb = (Read-TextFile $outB) -split "`n"
            $n = [Math]::Min($ta.Count, $tb.Count)
            $shown = 0
            for ($i = 0; $i -lt $n -and $shown -lt 6; $i++) {
                if ($ta[$i] -cne $tb[$i]) {
                    Write-Host ("         行 {0}:" -f ($i + 1)) -ForegroundColor DarkYellow
                    Write-Host ("           A: {0}" -f $ta[$i]) -ForegroundColor DarkYellow
                    Write-Host ("           B: {0}" -f $tb[$i]) -ForegroundColor DarkYellow
                    $shown++
                }
            }
        }
    }

    if ($ShowOutput) {
        Get-Content -LiteralPath $outA -Encoding UTF8 -ErrorAction SilentlyContinue |
            ForEach-Object { Write-Host "         $_" }
    }
}

Write-Host "== 运行 =="

# 选择：-Example 指定文件名 / 位置参数指定编号（如 01 13）/ -All 全跑
$selected = @()
if ($Example) {
    $p = Join-Path $examplesDir $Example
    if (-not (Test-Path -LiteralPath $p)) { throw "找不到示例文件: $p" }
    $selected = @(Get-Item -LiteralPath $p)
}
elseif ($Rest -and $Rest.Count -gt 0) {
    $nums = @($Rest | Where-Object { $_ -notmatch '^-' })
    $selected = @($sources | Where-Object {
        $n = ($_.Name -replace '\.erl$', '') -split "-"
        $nums -contains $n[0]
    })
    if ($selected.Count -eq 0) { throw "没有匹配到编号： $($nums -join ' ')" }
}
elseif ($All) {
    $selected = $sources
}
else {
    Write-Host "用法:" -ForegroundColor Yellow
    Write-Host "  pwsh ./build.ps1 -All             编译并运行 examples 下全部示例（两条通道）"
    Write-Host "  pwsh ./build.ps1 01 13            只跑指定编号"
    Write-Host "  pwsh ./build.ps1 -Example 24-ets.erl"
    Write-Host "  pwsh ./build.ps1 -All -ShowOutput    附带打印每个示例的运行输出"
    Write-Host "  pwsh ./build.ps1 -Clean           清理 build 目录"
    Write-Host ""
    Write-Host "两条通道：A 默认调度器 / B +S 1:1 单调度器"
    Write-Host "判定标准：退出码 0 + stderr 为空 + 输出无多余控制字符 + 有 '==== NN 结束 ===='"
    Write-Host "提示：也可直接用 ./run-all.sh 做同样的事（含 -v 与按编号筛选）。"
    exit 0
}

foreach ($s in $selected) { Invoke-Example -FileInfo $s }

Write-Host ""
Write-Host "通过 $script:pass   失败 $script:fail   不可重复 $script:diffW"
Write-Host "（通道 A 默认 + 通道 B +S 1:1，每个示例各算一项；共 $($sources.Count) 个示例）"

if ($script:fail -eq 0 -and $script:diffW -eq 0) {
    Write-Host "全部通过：四条判定全过，且两通道输出逐字节一致。" -ForegroundColor Green
    exit 0
}
if ($script:fail -ne 0) {
    Write-Host "失败项：" -ForegroundColor Red
    $script:failedTags | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}
exit 1
