param(
    [switch]$All,
    [switch]$Clean,
    [string]$File,
    [switch]$Verbose
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

# ---------------------------------------------------------------
# Windows 分支：SML 工具链（smlnj / polyml / mlton）装在 WSL 里。
# 本地 PATH 上没有 sml 时，把整件事委托给 wsl + run-all.sh——
# 那是与本脚本等价的三通道验证实现（判定五条完全一致）。
# wsl.exe 的 NAT 提示噪音（"wsl: 检测到 localhost 代理..."）
# 会混进 stdout，按行过滤掉，退出码原样透传。
# ---------------------------------------------------------------
if ($env:OS -eq "Windows_NT" -and ($All -or $File) -and
    -not (Get-Command sml -ErrorAction SilentlyContinue)) {

    function Convert-ToLinuxPath {
        param([Parameter(Mandatory = $true)][string]$WinPath)
        $full = [System.IO.Path]::GetFullPath($WinPath)
        if ($full -match '^([A-Za-z]):[\\/](.*)$') {
            return ("/mnt/{0}/{1}" -f $Matches[1].ToLower(), ($Matches[2] -replace '\\', '/'))
        }
        throw "无法把路径翻译成 WSL 路径: $WinPath"
    }

    # -File 收编号或文件名，都归一成编号（run-all.sh 只认编号）
    if ($File) {
        if ($File -match '^([0-9]+)') { $sel = $Matches[1] }
        else { throw "无法从 -File '$File' 里解析出示例编号。" }
    } else { $sel = "" }

    $shArgs = @()
    if ($Verbose) { $shArgs += "-v" }
    if ($sel) { $shArgs += $sel }

    $linuxRoot = Convert-ToLinuxPath $projectRoot
    $cmd = "cd '{0}' && bash run-all.sh {1}" -f $linuxRoot, ($shArgs -join " ")

    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
    $env:WSL_UTF8 = "1"
    & wsl -e bash -lc $cmd 2>&1 |
        Where-Object { "$_" -notmatch '^wsl:' } |
        ForEach-Object { Write-Host "$_" }
    exit $LASTEXITCODE
}

# ===============================================================
# StandardML 教程 —— 三通道全量验证（PowerShell 版，与 run-all.sh 等价）
#
#  在 Windows 上没有本地 SML 工具链时自动委托 wsl 跑 run-all.sh
#  （见文件开头的「Windows 分支」）；WSL/Linux/macOS 上原生执行。
#
#  通道1 ★ SML/NJ 110.99.9   （解释执行；先构建一个「静音堆」）
#  通道2   Poly/ML 5.9.2     （poly -q --script）
#  通道3   MLton 20241230    （整体优化编译器，标准符合性最严；可选）
#
#  判定标准（五条，缺一不可）：
#    1) 退出码为 0
#    2) stderr 为空
#       —— MLton 的编译错误走 stderr；SML/NJ / Poly/ML 的走 stdout，
#          所以这条主要拦 MLton，第 5 条拦另外两个。
#    3) stdout 里没有多余控制字符（字节 0..31，TAB/LF/CR 除外）
#    4) stdout 里有结束标记 "==== NN 结束 ===="
#       —— 这条最关键：SML/NJ 用了静音堆之后编译错误被静音、退出码恒为 0，
#          只有「跑没跑到最后一行」能证明它真的成功了。
#    5) stdout 里不出现编译器诊断（Error / Warning / Static Errors / unhandled）
#
#  另外三通道输出逐字节比对；确实不可能一致的列入「已知差异」表。
# ===============================================================

# ---------------------------------------------------------------
# 工具链定位：环境变量优先，其次 MacPorts / 托管目录，最后退回 PATH
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

# MLton 官方二进制装在托管目录下，路径带版本号，要通配找
#   注意：macOS 上 $env:USERPROFILE 是空的，一定要退回 $env:HOME；
#   而且 $pattern 为空时绝不能调 Get-ChildItem —— -Path 收到 $null
#   会被当成「没给」而退化成列当前目录，结果可能把别的文件当工具链。
function Resolve-MLton {
    $fromEnv = [Environment]::GetEnvironmentVariable("MLTON")
    if ($fromEnv -and (Test-Path -LiteralPath $fromEnv)) { return $fromEnv }

    $homeDir = $env:USERPROFILE
    if (-not $homeDir) { $homeDir = $env:HOME }

    if ($homeDir) {
        $pattern = Join-Path $homeDir ".workbuddy/binaries/mlton/*/bin/mlton"
        if ($pattern) {
            $hits = @(Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue |
                      Where-Object { -not $_.PSIsContainer })
            if ($hits.Count -gt 0) { return $hits[0].FullName }
        }
    }

    $cmd = Get-Command mlton -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return ""
}

$sml   = Resolve-Tool "SML"    @("/opt/local/bin/sml", "sml")
$poly  = Resolve-Tool "POLY"   @("/opt/local/bin/poly", "poly")
$mlton = Resolve-MLton

# MLton 需要 GMP：MacPorts 的头文件和库都在 /opt/local 下，显式指路
$mltonOpts = @()
if ($mlton -and (Test-Path -LiteralPath "/opt/local/include/gmp.h")) {
    $mltonOpts = @("-cc-opt", "-I/opt/local/include", "-link-opt", "-L/opt/local/lib")
}

$examplesDir = Join-Path $projectRoot "examples"
$buildDir    = Join-Path $projectRoot "build"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "[Clean] 已清理 build 目录。" -ForegroundColor Yellow
    } else {
        Write-Host "[Clean] build 目录不存在，无需清理。" -ForegroundColor Yellow
    }
    exit 0
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

if (-not $sml)  { Write-Host "未找到 sml（SML/NJ），可设 SML=/path/to/sml" -ForegroundColor Yellow }
if (-not $poly) { Write-Host "未找到 poly（Poly/ML），可设 POLY=/path/to/poly" -ForegroundColor Yellow }
if (-not $sml -or -not $poly) { throw "SML/NJ 与 Poly/ML 是必备的两条通道，缺一不可。" }
if (-not $mlton) { Write-Host "未找到 mlton，跳过第三条通道（只跑前两条）" -ForegroundColor Yellow }

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

# ---------------------------------------------------------------
# 已知的跨实现差异（原因写清楚，免得后人以为是回归）
# ---------------------------------------------------------------
function Get-DiffReason {
    param([string]$Base)
    switch ($Base) {
        "02-types"    { return "MLton 默认的 int 是 32 位，SML/NJ 与 Poly/ML 是 63 位" }
        "18-numeric"  { return "第 10 节刻意打印实数格式化的分叉点：Real.toString/GEN 对整值实数、FIX 0 的 .5 进位、FIX 17 的末位（详见 README）" }
        default       { return "" }
    }
}

# ---------------------------------------------------------------
# 通用小工具
# ---------------------------------------------------------------

# Get-Content -Raw 读空文件会返回 $null，必须兜底
function Read-TextFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $text = [string](Get-Content -Raw -LiteralPath $Path -ErrorAction SilentlyContinue)
    if ($null -eq $text) { $text = "" }
    return $text
}

function Write-TextFile {
    param([string]$Path, [string]$Text)
    [System.IO.File]::WriteAllText($Path, $Text, (New-Object System.Text.UTF8Encoding($false)))
}

# 按行拆。千万别写 -split "[char]10"：
# 那会被当成正则的字符类（匹配 [ c h a r 1 0 里任意一个字符），
# 结果把所有元音和数字都拆开了。用 [char]10 求值出来的换行才安全。
function Split-Lines {
    param([string]$Text)
    if ($null -eq $Text -or $Text -eq "") { return @() }
    return ($Text -split ([string][char]10))
}

# 逐字节比较两个文件。不用字符串比较：编码转换可能把差异吃掉
function Test-SameBytes {
    param([string]$A, [string]$B)
    if (-not (Test-Path -LiteralPath $A) -or -not (Test-Path -LiteralPath $B)) { return $false }
    $ba = [System.IO.File]::ReadAllBytes($A)
    $bb = [System.IO.File]::ReadAllBytes($B)
    if ($ba.Length -ne $bb.Length) { return $false }
    for ($i = 0; $i -lt $ba.Length; $i++) {
        if ($ba[$i] -ne $bb[$i]) { return $false }
    }
    return $true
}

# 输出里是否混进了不该出现的控制字符（TAB/LF/CR 除外）
function Test-HasCtrl {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    foreach ($b in [System.IO.File]::ReadAllBytes($Path)) {
        if ($b -lt 32 -and $b -ne 9 -and $b -ne 10 -and $b -ne 13) { return $true }
    }
    return $false
}

# stdout 里是否漏进了编译器诊断
#   注意别用反引号转义控制字符，一律写 \xNN；
#   另外这里的模式是 ASCII，字符串里的中文文案不会误命中。
function Test-HasDiag {
    param([string]$Text)
    return $Text -match '(Error:|error:|Warning:|warning:|Static Errors|unhandled exception|Exception- |Matches are not exhaustive)'
}

# ---------------------------------------------------------------
# 进程启动助手：重定向三个流，并带超时兜底
#   -StdIn 可给一个文件；SML/NJ 需要从 stdin 读 use "..." 指令
# ---------------------------------------------------------------
function Invoke-Proc {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [string[]]$Args = @(),
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$ErrFile,
        [string]$StdInFile = "",
        [string]$WorkDir = $projectRoot,
        [int]$TimeoutMs = 120000
    )

    # -ArgumentList 不能传空数组，会直接报错，得分情况调
    $common = @{
        FilePath               = $Exe
        WorkingDirectory       = $WorkDir
        RedirectStandardOutput = $OutFile
        RedirectStandardError  = $ErrFile
        NoNewWindow            = $true
        PassThru               = $true
    }
    if ($StdInFile) { $common.RedirectStandardInput = $StdInFile }
    if ($Args.Count -gt 0) { $common.ArgumentList = $Args }

    $proc = Start-Process @common
    if (-not $proc.WaitForExit($TimeoutMs)) {
        $proc.Kill()
        $proc.WaitForExit(5000) | Out-Null
        return @{ ExitCode = 124; TimedOut = $true }
    }
    return @{ ExitCode = $proc.ExitCode; TimedOut = $false }
}

# ---------------------------------------------------------------
# 判定标准（三通道共用）：见文件头的五条
# ---------------------------------------------------------------
function Test-Result {
    param(
        [Parameter(Mandatory = $true)][string]$Tag,
        [Parameter(Mandatory = $true)][string]$Marker,
        [Parameter(Mandatory = $true)][string]$OutPath,
        [Parameter(Mandatory = $true)][string]$ErrPath,
        [Parameter(Mandatory = $true)][int]$ExitCode,
        [string]$BuildLog = "",
        [switch]$TimedOut
    )

    $errText = Read-TextFile $ErrPath
    $outText = Read-TextFile $OutPath

    $reasons = @()
    if ($TimedOut) { $reasons += "超过 120 秒未结束（多半是死循环）" }
    if ($ExitCode -ne 0) { $reasons += "退出码 $ExitCode" }
    if ($errText.Trim() -ne "") { $reasons += "stderr 非空" }
    if (Test-HasCtrl $OutPath) { $reasons += "stdout 含控制字符" }
    # 找标记前先把控制字符去掉，免得二进制内容干扰匹配
    $clean = [regex]::Replace($outText, '[\x00-\x08\x0B\x0C\x0E-\x1F]', '')
    if (-not $clean.Contains($Marker)) { $reasons += "缺少结束标记 $Marker" }
    if (Test-HasDiag $outText) { $reasons += "stdout 里有编译器诊断" }
    if ($BuildLog -and (Read-TextFile $BuildLog).Trim() -ne "") { $reasons += "编译输出非空" }

    if ($reasons.Count -eq 0) {
        Write-Host ("  {0,-8} {1}" -f "[OK]", $Tag) -ForegroundColor Green
        return $true
    }

    Write-Host ("  {0,-8} {1}  —— {2}" -f "[FAIL]", $Tag, ($reasons -join "、")) -ForegroundColor Red
    if ($errText.Trim() -ne "") {
        Write-Host "        stderr 前几行："
        (Split-Lines $errText | Where-Object { $_.Trim() -ne "" } | Select-Object -First 5) |
            ForEach-Object { Write-Host "          $_" }
    }
    if ($outText.Trim() -ne "" -and -not $Verbose) {
        Write-Host "        stdout 最后 3 行："
        (Split-Lines $outText | Where-Object { $_.Trim() -ne "" } | Select-Object -Last 3) |
            ForEach-Object { Write-Host "          $_" }
    }
    return $false
}

# ---------------------------------------------------------------
# SML/NJ 的「静音堆」
#   Control.Print.out 是 SML/NJ 编译器消息与顶层回显的输出流。
#   换成空操作之后，顶层 val/fun/structure 的回显全部消失，
#   stdout 里就只剩程序自己 print 的内容 —— 逐字节比对的前提。
#   注意：exportML 之后的语句在堆被加载时会继续执行，它必须是最后一句。
# ---------------------------------------------------------------
$quietHeap = ""
$quietScript = Join-Path $buildDir "quiet.sml"

function Build-QuietHeap {
    $suffixOut = Join-Path $buildDir "_suffix.txt"
    $suffixErr = Join-Path $buildDir "_suffix.err"
    Invoke-Proc -Exe $sml -Args @("@SMLsuffix") -OutFile $suffixOut -ErrFile $suffixErr `
                -WorkDir $buildDir -TimeoutMs 30000 | Out-Null
    $suffix = (Read-TextFile $suffixOut) -replace '\s', ''
    if (-not $suffix) { $suffix = "heap" }

    $script:quietHeap = Join-Path $buildDir "quiet.$suffix"
    if (Test-Path -LiteralPath $script:quietHeap) { return $true }

    $heapSrc = 'val _ = Control.Print.out := { say = fn (_ : string) => (), flush = fn () => () }' + [char]10 +
               'val _ = SMLofNJ.exportML "quiet"' + [char]10
    Write-TextFile $quietScript $heapSrc

    $empty = Join-Path $buildDir "_empty.stdin"
    Write-TextFile $empty ""
    $bOut = Join-Path $buildDir "quiet.build.log"
    $bErr = Join-Path $buildDir "quiet.build.err"
    Invoke-Proc -Exe $sml -Args @("@SMLquiet") -OutFile $bOut -ErrFile $bErr `
                -StdInFile $empty -WorkDir $buildDir -TimeoutMs 60000 | Out-Null

    return (Test-Path -LiteralPath $script:quietHeap)
}

# ---------------------------------------------------------------
# 三通道各自的运行函数。工作目录统一切到 build/，
# 示例里写相对路径产生的临时文件就都落在 build/ 下。
# ---------------------------------------------------------------

# $SrcRel = 相对 build/ 的 .sml 路径（形如 ../examples/01-basics.sml）
function Invoke-Smlnj {
    param([string]$SrcRel, [string]$OutFile, [string]$ErrFile, [string]$Base)

    $stdinPath = Join-Path $buildDir "$Base.smlnj.stdin"
    Write-TextFile $stdinPath ('use "' + $SrcRel + '";' + [char]10)

    $a = @("@SMLquiet", "@SMLload=$script:quietHeap")
    Invoke-Proc -Exe $sml -Args $a -OutFile $OutFile -ErrFile $ErrFile `
                -StdInFile $stdinPath -WorkDir $buildDir -TimeoutMs 120000
}

function Invoke-Poly {
    param([string]$SrcRel, [string]$OutFile, [string]$ErrFile)

    $empty = Join-Path $buildDir "_empty.stdin"
    if (-not (Test-Path -LiteralPath $empty)) { Write-TextFile $empty "" }

    Invoke-Proc -Exe $poly -Args @("-q", "--script", $SrcRel) -OutFile $OutFile -ErrFile $ErrFile `
                -StdInFile $empty -WorkDir $buildDir -TimeoutMs 120000
}

function Invoke-Mlton {
    param([string]$SrcRel, [string]$OutFile, [string]$ErrFile, [string]$Base)

    $bin        = Join-Path $buildDir "$Base.mlton.bin"
    $compileOut = Join-Path $buildDir "$Base.mlton.compile.out.log"
    $compileErr = Join-Path $buildDir "$Base.mlton.compile.err.log"

    $a = @()
    if ($mltonOpts.Count -gt 0) { $a += $mltonOpts }
    $a += @("-output", $bin, $SrcRel)

    # MLton 把诊断写 stderr，ld 的版本警告也走 stderr，所以两个流都要收；
    # 不能给 -RedirectStandardOutput 和 -RedirectStandardError 同一个文件，会报占用。
    $c = Invoke-Proc -Exe $mlton -Args $a -OutFile $compileOut -ErrFile $compileErr `
                     -WorkDir $buildDir -TimeoutMs 120000

    if ($c.ExitCode -ne 0) {
        # 编译失败：把真实诊断交给 stderr，好让判定统一处理
        $diag = @(Split-Lines ((Read-TextFile $compileOut) + (Read-TextFile $compileErr)) |
                  Where-Object { $_ -notmatch 'was built for newer macOS' -and $_.Trim() -ne "" })
        Write-TextFile $ErrFile ($diag -join ([string][char]10))
        Write-TextFile $OutFile ""
        return @{ ExitCode = 1; TimedOut = $false }
    }
    # 编译成功就不留日志：本机 MLton 是给 macOS 13 编的，
    # 每次链接都刷几十 KB 的 ld 版本警告，留着只会撑大 build/
    if (-not $Verbose) {
        Remove-Item -LiteralPath $compileOut -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $compileErr -Force -ErrorAction SilentlyContinue
    }

    return (Invoke-Proc -Exe $bin -Args @() -OutFile $OutFile -ErrFile $ErrFile `
                        -WorkDir $buildDir -TimeoutMs 120000)
}

# ---------------------------------------------------------------
# 跑一个示例的三个通道 + 逐字节比对
# ---------------------------------------------------------------
function Invoke-Example {
    param([Parameter(Mandatory = $true)][System.IO.FileInfo]$FileInfo)

    $base      = [System.IO.Path]::GetFileNameWithoutExtension($FileInfo.Name)
    $num       = ($base -split "-")[0]
    $srcRel    = "../examples/$base.sml"
    # 结束标记里的「结束」用十进制转义拼出来，避免源文件里出现非 ASCII
    $marker    = "==== $num " + [char]0x7ED3 + [char]0x675F + " ===="

    Write-Host "[$num] $base" -ForegroundColor Cyan
    $allOk = $true
    $chanOk = @{}

    $o1 = Join-Path $buildDir "$base.smlnj.out";  $e1 = Join-Path $buildDir "$base.smlnj.err"
    $o2 = Join-Path $buildDir "$base.poly.out";   $e2 = Join-Path $buildDir "$base.poly.err"
    $o3 = Join-Path $buildDir "$base.mlton.out";  $e3 = Join-Path $buildDir "$base.mlton.err"

    # ---- 通道1：SML/NJ ----
    $r1 = Invoke-Smlnj -SrcRel $srcRel -OutFile $o1 -ErrFile $e1 -Base $base
    if (-not (Test-Result -Tag "smlnj" -Marker $marker -OutPath $o1 -ErrPath $e1 `
                -ExitCode $r1.ExitCode -TimedOut:$r1.TimedOut)) {
        $allOk = $false; $chanOk["smlnj"] = $false
    } else { $chanOk["smlnj"] = $true }

    # ---- 通道2：Poly/ML ----
    $r2 = Invoke-Poly -SrcRel $srcRel -OutFile $o2 -ErrFile $e2
    if (-not (Test-Result -Tag "poly" -Marker $marker -OutPath $o2 -ErrPath $e2 `
                -ExitCode $r2.ExitCode -TimedOut:$r2.TimedOut)) {
        $allOk = $false; $chanOk["poly"] = $false
    } else { $chanOk["poly"] = $true }

    # ---- 通道3：MLton ----
    if ($mlton) {
        $r3 = Invoke-Mlton -SrcRel $srcRel -OutFile $o3 -ErrFile $e3 -Base $base
        if (-not (Test-Result -Tag "mlton" -Marker $marker -OutPath $o3 -ErrPath $e3 `
                    -ExitCode $r3.ExitCode -TimedOut:$r3.TimedOut)) {
            $allOk = $false; $chanOk["mlton"] = $false
        } else { $chanOk["mlton"] = $true }
    }

    # ---- 三通道逐字节比对 ----
    if ($chanOk["smlnj"] -and $chanOk["poly"] -and (-not $mlton -or $chanOk["mlton"])) {
        $same = (Test-SameBytes $o1 $o2)
        if ($mlton) { $same = $same -and (Test-SameBytes $o2 $o3) }

        if ($same) {
            Write-Host "  [same]   三通道输出逐字节一致" -ForegroundColor DarkGray
        } else {
            $reason = Get-DiffReason $base
            if ($reason -ne "") {
                Write-Host ("  {0,-8} 已知差异：{1}" -f "[diff]", $reason) -ForegroundColor DarkYellow
            } else {
                Write-Host "  [DIFF]   三通道输出不一致，需要人工确认" -ForegroundColor Red
                Write-Host "           （对比 build/$base.*.out）"
                $allOk = $false
            }
        }
    }

    if ($Verbose -and (Test-Path -LiteralPath $o1)) {
        Split-Lines (Read-TextFile $o1) | ForEach-Object { Write-Host "          $_" }
    }

    return $allOk
}

# ---------------------------------------------------------------
# 前置检查：字符串字面量必须是纯 ASCII
#   Poly/ML 与 MLton 都拒绝字符串里的原始 UTF-8 字节，SML/NJ 却接受；
#   中文一旦误进字面量，只有后两条通道会挂，报的还是
#   "unprintable character \231 found in string" 这种不好定位的信息。
# ---------------------------------------------------------------
$py = Get-Command python3 -ErrorAction SilentlyContinue
if ($py) {
    $checker = Join-Path $projectRoot "check-literals.py"
    $srcs = @(Get-ChildItem -LiteralPath $examplesDir -Filter "*.sml" | Sort-Object Name |
              ForEach-Object { $_.FullName })
    & $py.Source $checker @srcs
    if ($LASTEXITCODE -ne 0) { throw "字面量预检查未通过，先改好再编译。" }
} else {
    Write-Host "  （没找到 python3，跳过字面量预检查）" -ForegroundColor Yellow
}

# ---------------------------------------------------------------
# 主流程
# ---------------------------------------------------------------
Write-Host "StandardML 教程 —— 三通道全量验证（PowerShell）"
Write-Host "------------------------------------------------------------"
Write-Host ("  SML/NJ  : {0}" -f $sml)
Write-Host ("  Poly/ML : {0}" -f $poly)
if ($mlton) {
    Write-Host ("  MLton   : {0}" -f $mlton)
    if ($mltonOpts.Count -gt 0) { Write-Host "            （已挂钩 /opt/local 的 GMP）" }
} else {
    Write-Host "  MLton   : 未找到，跳过该通道（只跑前两条）"
}
Write-Host ("  示例目录: {0}" -f $examplesDir)
Write-Host "------------------------------------------------------------"

if (-not (Build-QuietHeap)) {
    throw "SML/NJ 静音堆构建失败，见 build/quiet.build.log"
}
Write-Host ("  静音堆  : {0}" -f $quietHeap)
Write-Host "------------------------------------------------------------"

# ---- 收集要跑的示例 ----
if ($File) {
    # 支持两种写法：完整文件名（12-structures.sml / 12-structures）或只给编号（12）。
    # 只给编号时按 NN- 前缀去找，和 run-all.sh 的用法保持一致。
    $one = $null
    if ($File -match '^[0-9]+$') {
        $num = "{0:D2}" -f [int]$File
        $hit = @(Get-ChildItem -LiteralPath $examplesDir |
                     Where-Object { $_.Name -like "$num-*.sml" })
        if ($hit.Count -eq 0) { throw "找不到编号为 $num 的示例" }
        if ($hit.Count -gt 1) { throw "编号 $num 对应多个示例文件: $($hit.Name -join ', ')" }
        $one = $hit[0].FullName
    } else {
        $name = $File
        if (-not $name.EndsWith(".sml")) { $name += ".sml" }
        $one = Join-Path $examplesDir $name
    }
    if (-not (Test-Path -LiteralPath $one)) { throw "找不到示例文件: $one" }
    if (-not (Invoke-Example -FileInfo (Get-Item -LiteralPath $one))) {
        Write-Host ("[Done] 验证失败: {0}" -f (Split-Path -Leaf $one)) -ForegroundColor Red
        exit 1
    }
    Write-Host ("[Done] 验证通过: {0}" -f (Split-Path -Leaf $one)) -ForegroundColor Green
    exit 0
}

if (-not $All) {
    Write-Host "用法:" -ForegroundColor Yellow
    Write-Host "  .\build.ps1 -All                    编译并运行 examples 下全部示例（三条通道）"
    Write-Host "  .\build.ps1 -File 12-structures.sml 只跑单个示例（也可以只写编号 12）"
    Write-Host "  .\build.ps1 -All -Verbose           附带打印每个示例的运行输出"
    Write-Host "  .\build.ps1 -Clean                  清理 build 目录"
    Write-Host ""
    Write-Host "三条通道：SML/NJ 110.99.9（主） / Poly/ML 5.9.2（对照） / MLton 20241230（最严）"
    Write-Host "判定标准：退出码 0 + stderr 为空 + 无控制字符 + 有 '==== NN 结束 ===='"
    Write-Host "          + stdout 里没有编译器诊断（SML/NJ 的回显靠静音堆压掉）"
    Write-Host "提示：也可直接用 ./run-all.sh 做同样的事（含 -v 与按编号筛选）。"
    exit 0
}

$files = @(Get-ChildItem -LiteralPath $examplesDir -Filter "*.sml" | Sort-Object Name)
if ($files.Count -eq 0) { throw "examples 目录下没有 .sml 示例文件。" }

$pass = 0
$fail = 0
$failedList = @()
foreach ($f in $files) {
    if (Invoke-Example -FileInfo $f) { $pass++ } else { $fail++; $failedList += $f.Name }
    Write-Host ""
}

Write-Host "============================================================" -ForegroundColor DarkGray
$chanCount = if ($mlton) { 3 } else { 2 }
Write-Host ("示例 {0} 个 × 通道 {1} 条" -f $files.Count, $chanCount)
Write-Host ("通过 {0}   失败 {1}" -f $pass, $fail) -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })
if ($fail -ne 0) {
    Write-Host "失败项：" -ForegroundColor Red
    $failedList | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}
Write-Host "[Done] 全部示例在三通道下验证通过。" -ForegroundColor Green
exit 0
