<#
============================================================
build.ps1 —— Io 教程统一验证入口（PowerShell 版，等价于 run-all.sh）

  pwsh -ExecutionPolicy Bypass -File build.ps1                 跑全部示例，只打印摘要
  pwsh -ExecutionPolicy Bypass -File build.ps1 -Verbose        附带每个示例的完整区间输出
  pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 09 13  只跑指定编号
  pwsh -ExecutionPolicy Bypass -File build.ps1 -NoRerun        跳过「重跑稳定」检查
  pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean          清掉 build 目录后退出

通道：同一个 VM 的两个二进制
  io          动态链接版（依赖安装前缀里的 libiovmall.dylib）
  io_static   静态单文件版（不依赖任何外部文件）
两个二进制由同一份源码编译，因此「跨通道逐字节一致」在这里不是
检验两种语义，而是检验示例**没有偷偷依赖动态库加载 / 安装前缀**。

判定标准（每条通道都要过，与 run-all.sh 逐条一致）：
  1. 退出码为 0
  2. stderr 为空
  3. stdout 里同时出现 "==== NN 开始 ====" 与 "==== NN 结束 ===="
  4. 两个标记之间的区间非空，且不含 \r 或 ESC（TAB / LF / CR 除外）
  5. 区间里没有未捕获异常横幅（"  Exception: …" 紧邻一行纯 '-'）
另有两条跨运行判定：
  6. 两条通道抽出的区间逐字节一致
  7. 同一条通道连跑两次，区间逐字节一致

为什么必须有「结束标记」这一条：Io 的**未捕获异常会中断脚本、却仍然退出 0**，
只判退出码会放过「跑到一半就死了」的假阳性。见 examples/13_exceptions/
observe_13_uncaught.io（专门把这个行为做成可验证的观察项）。

工具链一律探测、不硬编码路径；找不到的通道自动跳过。
所有比较都在**字节**层面做（把文件按 Latin-1 一字节一字符读完再比），
免得 PowerShell 的文本编码转换把差异吃掉。
============================================================
#>
[CmdletBinding()]
param(
    [switch]$All,
    [switch]$Clean,
    [switch]$NoRerun,
    [string[]]$Example = @(),
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest = @()
)

$ErrorActionPreference = 'Continue'
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}

$ProjectRoot = $PSScriptRoot
if (-not $ProjectRoot) { $ProjectRoot = (Get-Location).Path }
Set-Location $ProjectRoot
$BuildDir    = Join-Path $ProjectRoot 'build'
$ExamplesDir = Join-Path $ProjectRoot 'examples'

$Select  = @()
if ($Example) { $Select += $Example }
if ($Rest)    { $Select += $Rest }
$Select = @($Select | Where-Object { $_ -ne '' })

$Rerun = -not $NoRerun

if ($Clean) {
    if (Test-Path $BuildDir) { Remove-Item -Recurse -Force $BuildDir }
    Write-Output "已清掉 $BuildDir"
    exit 0
}

# ------------------------------------------------------------
# 工具探测：Find-Tool <名字> [候选绝对路径...]
# ------------------------------------------------------------
function Find-Tool {
    param([string]$Name, [string[]]$Candidates)
    $hit = Get-Command $Name -ErrorAction SilentlyContinue
    if ($hit) { return $hit.Source }
    foreach ($c in $Candidates) {
        if ($c -and (Test-Path -LiteralPath $c)) { return $c }
    }
    return $null
}

$Timeout = Find-Tool -Name 'gtimeout' -Candidates @('/opt/local/bin/gtimeout', '/usr/local/bin/gtimeout')
if (-not $Timeout) {
    $Timeout = Find-Tool -Name 'timeout' -Candidates @('/usr/bin/timeout')
}
$ProbeLimit = 20          # 单个示例的墙钟上限（秒）
$ProbeLimitMs = $ProbeLimit * 1000

# ------------------------------------------------------------
# 字节级小工具
#   全部比较都走 Latin-1（一字节一字符）→ 不进任何 Unicode 编码转换，
#   这样 cmp/diff 的语义才能被原样搬过来。
# ------------------------------------------------------------
$Latin1 = [System.Text.Encoding]::Latin1

function Read-BytesAsLatin1 {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return '' }
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    if ($bytes.Length -eq 0) { return '' }
    return $Latin1.GetString($bytes)
}

function Write-Latin1 {
    param([string]$Path, [string]$Text)
    [System.IO.File]::WriteAllBytes($Path, $Latin1.GetBytes($Text))
}

# 把一条「正常的 PowerShell 字符串」转成它在 Latin-1 视图里的样子。
# 标记、期望痕迹里都有中文，而 Latin-1 视图是一字节一字符的，
# 直接 Contains 一定不中——必须先把待查串也按 UTF-8 编成字节、再取 Latin-1 视图，
# 两边才落在同一个坐标系里。
function ConvertTo-Latin1View {
    param([string]$Text)
    return $Latin1.GetString([System.Text.Encoding]::UTF8.GetBytes($Text))
}

function Test-SameBytes {
    param([string]$A, [string]$B)
    $ba = [System.IO.File]::ReadAllBytes($A)
    $bb = [System.IO.File]::ReadAllBytes($B)
    if ($ba.Length -ne $bb.Length) { return $false }
    for ($i = 0; $i -lt $ba.Length; $i++) {
        if ($ba[$i] -ne $bb[$i]) { return $false }
    }
    return $true
}

# ------------------------------------------------------------
# 判定原语（与 run-all.sh 一一对应）
# ------------------------------------------------------------
$script:Pass = 0
$script:Fail = 0
$script:FailedList = @()

function Write-Ok  { param([string]$Tag) $script:Pass++; Write-Output ("  [OK]   " + $Tag) }
function Write-Bad {
    param([string]$Tag, [string]$Why)
    $script:Fail++
    $script:FailedList += ("${Tag}: $Why")
    Write-Output ("  [!]    " + $Tag + "  (" + $Why + ")")
}

function Test-Marker {
    param([string]$Path, [string]$Marker)
    $text = Read-BytesAsLatin1 -Path $Path
    return $text.Contains((ConvertTo-Latin1View $Marker))
}

function Test-ControlChars {
    param([string]$Path)
    # 去掉 TAB(9) / LF(10) / CR(13) 之后还有剩余控制字节 → 有控制字符
    foreach ($b in [System.IO.File]::ReadAllBytes($Path)) {
        if ($b -eq 9 -or $b -eq 10 -or $b -eq 13) { continue }
        if ($b -lt 32 -or $b -eq 127) { return $true }
    }
    return $false
}

function Test-Trace {
    param([string]$Path)
    # 溃逃痕迹 = **未捕获异常横幅**，不是「区间里提到了异常」。
    # 合法示例会主动把异常消息打出来做演示（try(...) 的 error），也会打印表格
    # 分隔线（一长串 '-'），所以任何单独一行的判据都会误报。横幅的关键是那两行
    # **连在一起**：
    #     （空行）
    #       Exception: <消息>
    #       ---------          ← 紧跟其上，且是纯 '-' 的分隔线
    # 判据：出现 "  Exception: " 行，且紧邻的下一行是纯 '-' 分隔线。
    # 宁可**细**一点：脚本真崩了会缺结束标记，那个判据兜得住。
    $text = Read-BytesAsLatin1 -Path $Path
    if ($text -eq '') { return $false }
    $lines = $text -split "`n"
    for ($i = 0; $i -lt $lines.Length - 1; $i++) {
        if ($lines[$i] -match '^[ \t]*Exception:[ \t]') {
            if ($lines[$i + 1] -match '^[ \t]*-{3,}[ \t]*\r?$') { return $true }
        }
    }
    return $false
}

# ------------------------------------------------------------
# 跑一条通道：run_channel <通道> <脚本> <前缀>
#   真实退出码写进 "<前缀>.exit"
# ------------------------------------------------------------
function Get-BinFor {
    param([string]$Channel)
    switch ($Channel) {
        'dyn'    { return $script:IoDyn }
        'static' { return $script:IoSta }
    }
    return $null
}

function Invoke-Channel {
    param([string]$Channel, [string]$File, [string]$Prefix)

    $bin = Get-BinFor -Channel $Channel
    $outPath = "$Prefix.out"
    $errPath = "$Prefix.err"
    $exitPath = "$Prefix.exit"

    $env:IO_BIN = $bin
    $env:IO_CHANNEL = $Channel

    $timedOut = $false
    if ($Timeout) {
        # 有 gtimeout/timeout 就用它，行为和 run-all.sh 完全一致
        $proc = Start-Process -FilePath $Timeout `
            -ArgumentList @("$ProbeLimit", $bin, $File) `
            -PassThru -NoNewWindow `
            -RedirectStandardOutput $outPath -RedirectStandardError $errPath
        $proc.WaitForExit()
        $rc = $proc.ExitCode
    } else {
        # 没有就用内部计时器：超时按 124 记（timeout(1) 的约定）
        $proc = Start-Process -FilePath $bin `
            -ArgumentList @($File) `
            -PassThru -NoNewWindow `
            -RedirectStandardOutput $outPath -RedirectStandardError $errPath
        if (-not $proc.WaitForExit($ProbeLimitMs)) {
            try { $proc.Kill($true) } catch {}
            $proc.WaitForExit()
            $timedOut = $true
        }
        $rc = if ($timedOut) { 124 } else { $proc.ExitCode }
    }

    Set-Content -LiteralPath $exitPath -Value $rc -NoNewline -Encoding ascii
}

function Get-ExitCode {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return 1 }
    $t = (Get-Content -LiteralPath $Path -Raw -ErrorAction SilentlyContinue)
    if ($null -eq $t) { return 1 }
    $t = $t.Trim()
    if ($t -eq '') { return 1 }
    return [int]$t
}

function Get-Section {
    param([string]$Prefix, [string]$Begin, [string]$End, [string]$OutPath)
    # sed -n "/b/,/e/p" 的等价物：取 begin 行到 end 行之间，并删掉标记行本身
    $text = Read-BytesAsLatin1 -Path $OutPath
    $lines = $text -split "`n"
    $beginL = ConvertTo-Latin1View $Begin
    $endL   = ConvertTo-Latin1View $End
    $startIdx = -1; $endIdx = -1
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $l = $lines[$i].TrimEnd("`r")
        if ($startIdx -lt 0 -and $l.Contains($beginL)) { $startIdx = $i; continue }
        if ($startIdx -ge 0 -and $l.Contains($endL))   { $endIdx = $i; break }
    }
    if ($startIdx -lt 0 -or $endIdx -lt 0 -or $endIdx -le $startIdx) {
        Write-Latin1 -Path "$Prefix.sec" -Text ''
        return
    }
    $body = $lines[($startIdx + 1)..($endIdx - 1)] -join "`n"
    if ($body -ne '') { $body += "`n" }   # sed 会给每行补一个换行，最后一行也有
    Write-Latin1 -Path "$Prefix.sec" -Text $body
}

function Show-Tail {
    param([string]$Why, [string]$Prefix)
    if (Test-Path -LiteralPath "$Prefix.err") {
        $e = [System.IO.File]::ReadAllBytes("$Prefix.err")
        if ($e.Length -gt 0) {
            Write-Output "        stderr 前 6 行："
            Get-Content -LiteralPath "$Prefix.err" -TotalCount 6 -Encoding utf8 -ErrorAction SilentlyContinue |
                ForEach-Object { Write-Output ("          " + ($_ -replace "`0", '')) }
        }
    }
    Write-Output "        stdout 最后 6 行："
    $tail = Get-Content -LiteralPath "$Prefix.out" -Tail 6 -Encoding utf8 -ErrorAction SilentlyContinue
    if ($tail) {
        foreach ($l in $tail) { Write-Output ("          " + ($l -replace "`0", '')) }
    }
}

# judge <标签> <前缀> <开始标记> <结束标记>
function Invoke-Judge {
    param([string]$Tag, [string]$Prefix, [string]$Begin, [string]$End)

    $why = @()
    Get-Section -Prefix $Prefix -Begin $Begin -End $End -OutPath "$Prefix.out"

    $rc = Get-ExitCode -Path "$Prefix.exit"
    if ($rc -ne 0) { $why += "退出码 $rc" }

    $errLen = 0
    if (Test-Path -LiteralPath "$Prefix.err") {
        $errLen = ([System.IO.File]::ReadAllBytes("$Prefix.err")).Length
    }
    if ($errLen -ne 0) { $why += "stderr 非空" }

    if (-not (Test-Marker -Path "$Prefix.out" -Marker $Begin)) { $why += "缺开始标记" }
    if (-not (Test-Marker -Path "$Prefix.out" -Marker $End))   { $why += "缺结束标记" }

    $secLen = 0
    if (Test-Path -LiteralPath "$Prefix.sec") {
        $secLen = ([System.IO.File]::ReadAllBytes("$Prefix.sec")).Length
    }
    if ($secLen -eq 0) { $why += "区间为空" }

    if ($secLen -gt 0 -and (Test-ControlChars -Path "$Prefix.sec")) { $why += "区间含控制字符" }
    if ($secLen -gt 0 -and (Test-Trace -Path "$Prefix.sec"))        { $why += "区间含溃逃痕迹" }

    if ($why.Count -eq 0) {
        Write-Ok -Tag $Tag
    } else {
        Write-Bad -Tag $Tag -Why (($why -join '；') + '；')
        Show-Tail -Why $why -Prefix $Prefix
    }
    if ($VerbosePreference -ne 'SilentlyContinue' -and $secLen -gt 0) {
        Get-Content -LiteralPath "$Prefix.sec" -Encoding utf8 -ErrorAction SilentlyContinue |
            ForEach-Object { Write-Output ("        | " + ($_ -replace "`0", '')) }
    }
}

# ------------------------------------------------------------
# 通道探测：候选二进制必须先自证是 Io（机器上可能有个同名但无关的 io）
#   用临时脚本文件而不是 -e："IO-PROBE" 这种带引号的表达式在
#   Start-Process -ArgumentList 里过一遍会碎，写文件最稳。
# ------------------------------------------------------------
function Test-IsIo {
    param([string]$Bin)
    if (-not (Test-Path -LiteralPath $Bin)) { return $false }
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) 'io_tut_probe.io'
    [System.IO.File]::WriteAllText($tmp, "`"IO-PROBE`" println`n", [System.Text.Encoding]::ASCII)
    try {
        $o = & $Bin $tmp 2>$null
        return (($o -join "`n").Trim() -eq 'IO-PROBE')
    } catch {
        return $false
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}

function Select-Io {
    param([string]$Name, [string[]]$Candidates)
    $hit = Find-Tool -Name $Name -Candidates $Candidates
    if ($hit -and (Test-IsIo -Bin $hit)) { return $hit }
    return $null
}

$home_ = $env:HOME
$script:IoDyn = Select-Io -Name 'io' -Candidates @(
    '/opt/local/bin/io', '/usr/local/bin/io',
    "$home_/.workbuddy/binaries/io/bin/io",
    '/opt/local/libexec/io/bin/io')
$script:IoSta = Select-Io -Name 'io_static' -Candidates @(
    '/opt/local/bin/io_static', '/usr/local/bin/io_static',
    "$home_/.workbuddy/binaries/io/bin/io_static",
    '/opt/local/libexec/io/bin/io_static')

$Channels = @()
if ($script:IoDyn) { $Channels += 'dyn' }
if ($script:IoSta) { $Channels += 'static' }

if ($Channels.Count -eq 0) {
    Write-Error @'
未找到 Io 解释器。任一通道都行：
  · MacPorts：      sudo port install Io        （装出 /opt/local/bin/io）
  · 源码构建：
      git clone https://github.com/IoLanguage/io.git
      git -C io fetch --depth 1 origin tag 2026.04.20-native-final
      git -C io checkout native-final
      git -C io submodule update --init --depth 1 deps/parson
      mkdir -p io/build && cd io/build
      cmake -DCMAKE_INSTALL_PREFIX=$HOME/.workbuddy/binaries/io .. && make -j8 all && make install
也可以用 IO=/path/to/io_static 指定二进制后再跑。
'@
    exit 1
}

function Get-IoVersion {
    param([string]$Bin)
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) 'io_tut_ver.io'
    [System.IO.File]::WriteAllText($tmp, "System version println`n", [System.Text.Encoding]::ASCII)
    try { return ((& $Bin $tmp 2>$null) -join '').Trim() } catch { return '?' }
    finally { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
}

Write-Output ("Io 教程回归（" + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + "）")
Write-Output ("工作目录 : " + $ProjectRoot)
if ($script:IoDyn) { Write-Output ("通道 io      : " + $script:IoDyn + " (" + (Get-IoVersion $script:IoDyn) + ")") }
if ($script:IoSta) { Write-Output ("通道 io_static: " + $script:IoSta + " (" + (Get-IoVersion $script:IoSta) + ")") }
if ($Timeout) { Write-Output ("超时守卫 : " + $Timeout + " " + $ProbeLimit) }
Write-Output ''

New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

function Test-Selected {
    param([string]$Name, [string]$Num)
    if ($Select.Count -eq 0) { return $true }
    foreach ($s in $Select) {
        if ($s -eq $Name -or $s -eq $Num) { return $true }
    }
    return $false
}

$TotalExamples = 0
$dirs = Get-ChildItem -LiteralPath $ExamplesDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d' } |
        Sort-Object Name

foreach ($d in $dirs) {
    $name = $d.Name
    $num = ($name -split '_')[0]
    $file = Join-Path $d.FullName "$name.io"
    if (-not (Test-Path -LiteralPath $file)) { continue }
    if (-not (Test-Selected -Name $name -Num $num)) { continue }

    $TotalExamples++
    Write-Output ("==== " + $name + " ====")
    $begin = "==== $num 开始 ===="
    $end   = "==== $num 结束 ===="

    foreach ($ch in $Channels) {
        $prefix = Join-Path $BuildDir "$name.$ch"
        Invoke-Channel -Channel $ch -File $file -Prefix $prefix
        $tag = "{0,-6} {1}" -f $ch, $name
        Invoke-Judge -Tag $tag -Prefix $prefix -Begin $begin -End $end
    }

    # 跨通道一致
    if ($Channels.Count -ge 2) {
        $a = Join-Path $BuildDir "$name.dyn.sec"
        $b = Join-Path $BuildDir "$name.static.sec"
        if (Test-SameBytes -A $a -B $b) {
            Write-Ok -Tag ("cross  " + $name)
        } else {
            Write-Bad -Tag ("cross  " + $name) -Why "两份区间不一致"
        }
    }

    # 重跑稳定（同通道跑第二遍）
    if ($Rerun) {
        $ch = $Channels[$Channels.Count - 1]
        $prefix = Join-Path $BuildDir "$name.rerun"
        Invoke-Channel -Channel $ch -File $file -Prefix $prefix
        Get-Section -Prefix $prefix -Begin $begin -End $end -OutPath "$prefix.out"
        $a = Join-Path $BuildDir "$name.$ch.sec"
        $b = "$prefix.sec"
        if (Test-SameBytes -A $a -B $b) {
            Write-Ok -Tag ("rerun  " + $name)
        } else {
            Write-Bad -Tag ("rerun  " + $name) -Why "两份区间不一致"
        }
    }
}

# ------------------------------------------------------------
# 观察项：故意不合规的示例，只在它们自己的观察标记上判定
#   观察项的判定与普通示例**不同**：它恰恰要求「脚本中断 + 退出码仍是 0」。
#   期望表：名称|期望出现的痕迹|必须缺席的字符串
# ------------------------------------------------------------
$Observations = @(
    @{ Name = 'observe_13_uncaught'; Want = "Exception: Object does not respond to 'boom'"; MustNot = '==== 13 观察 之后 ====' },
    @{ Name = 'observe_15_relpath';  Want = '判 3：两次的 launchPath 都是绝对路径 = true';   MustNot = '' }
)

function Invoke-Observations {
    $ch = $Channels[$Channels.Count - 1]
    $bin = Get-BinFor -Channel $ch

    foreach ($spec in $Observations) {
        $script = Get-ChildItem -LiteralPath $ExamplesDir -Recurse -Filter ($spec.Name + '.io') -ErrorAction SilentlyContinue |
                  Select-Object -First 1
        if (-not $script) {
            Write-Bad -Tag ("observe " + $spec.Name) -Why "找不到观察脚本"
            continue
        }
        $prefix = Join-Path $BuildDir $spec.Name
        Invoke-Channel -Channel $ch -File $script.FullName -Prefix $prefix

        $num = ($script.Directory.Name -split '_')[0]
        $why = @()
        $rc = Get-ExitCode -Path "$prefix.exit"
        if ($rc -ne 0) { $why += "退出码 $rc" }
        $errLen = 0
        if (Test-Path -LiteralPath "$prefix.err") {
            $errLen = ([System.IO.File]::ReadAllBytes("$prefix.err")).Length
        }
        if ($errLen -ne 0) { $why += "stderr 非空" }
        if (-not (Test-Marker -Path "$prefix.out" -Marker "==== $num 观察 开始 ====")) { $why += "缺观察开始标记" }
        if (-not (Test-Marker -Path "$prefix.out" -Marker "==== $num 观察 结束 ====")) { $why += "缺观察结束标记" }
        if (-not (Test-Marker -Path "$prefix.out" -Marker $spec.Want)) { $why += "未见预期痕迹：$($spec.Want)" }
        if ($spec.MustNot -ne '' -and (Test-Marker -Path "$prefix.out" -Marker $spec.MustNot)) {
            $why += "出现了必须缺席的：$($spec.MustNot)"
        }

        if ($why.Count -eq 0) {
            Write-Ok -Tag ("observe " + $spec.Name)
        } else {
            Write-Bad -Tag ("observe " + $spec.Name) -Why (($why -join '；') + '；')
            Get-Content -LiteralPath "$prefix.out" -TotalCount 8 -Encoding utf8 -ErrorAction SilentlyContinue |
                ForEach-Object { Write-Output ("          " + $_) }
        }
    }
}

Write-Output ''
Write-Output '==== 观察文件（不参与逐字节比对）===='
Invoke-Observations

Write-Output ''
Write-Output '---------------------------------------------'
if ($Rerun) {
    Write-Output ("通过 $script:Pass   失败 $script:Fail   （示例 $TotalExamples 个，通道 $($Channels.Count) 条）")
} else {
    Write-Output ("通过 $script:Pass   失败 $script:Fail   （示例 $TotalExamples 个，通道 $($Channels.Count) 条，未跑重跑稳定）")
}

if ($script:Fail -eq 0) {
    Write-Output '全部通过'
    exit 0
} else {
    Write-Output '失败项：'
    foreach ($t in $script:FailedList) { Write-Output ("  - " + $t) }
    exit 1
}
