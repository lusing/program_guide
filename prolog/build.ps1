param(
    [switch]$All,
    [string[]]$Example = @(),
    [switch]$Clean,
    [switch]$Verbose,
    [switch]$Help
)

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

if ($Help) {
    Write-Host "用法:"
    Write-Host "  .\build.ps1                            运行并验证 examples 下全部示例（三条通道）"
    Write-Host "  .\build.ps1 -All                       同上（显式写法）"
    Write-Host "  .\build.ps1 -Example 07,24             只跑指定编号"
    Write-Host "  .\build.ps1 -Example 21_constraints    也接受目录名"
    Write-Host "  .\build.ps1 -Verbose                   附带打印每个通道抽出的输出区间"
    Write-Host "  .\build.ps1 -Clean                     清理 build\ 目录"
    Write-Host ""
    Write-Host "三条通道：swipl（解释） / gprolog（解释） / gplc（编译成本地可执行文件）"
    Write-Host "六条判定：退出码 / stderr 空 / 两条标记 / 区间非空无控制字符 / 无溃逃痕迹 / 通道间逐字节一致"
    Write-Host "提示：也可直接用 ./run-all.sh 做同样的事（含 -v 与按编号筛选）。"
    exit 0
}

# Windows 下把控制台输出统一成 UTF-8，避免中文摘要乱码；
# macOS / Linux 本来就是 UTF-8，等价无操作。
try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false) } catch { }

# =============================================================================
# build.ps1 —— Prolog 教程三通道验证入口（PowerShell 版，判定与 run-all.sh 一致）
#
#   .\build.ps1                     跑全部示例，只打印摘要
#   .\build.ps1 -All                同上（显式写法）
#   .\build.ps1 -Verbose            跑全部并显示每个通道抽出的输出区间
#   .\build.ps1 -Example 07,24      只跑指定编号
#   .\build.ps1 -Example 21_constraints   也接受目录名
#   .\build.ps1 -Clean              清理 build\ 目录
#
# 三条通道（缺哪个跳哪个）：
#   1. swipl    —— SWI-Prolog 解释执行
#   2. gprolog  —— GNU Prolog 解释执行
#   3. gplc     —— GNU Prolog 编译成本地可执行文件后运行
#
# 六条判定（全部满足才算通过）：
#   1. 退出码为 0
#   2. stderr 为空（连警告都不许有）
#   3. stdout 里同时出现「==== NN 开始 ====」与「==== NN 结束 ====」
#   4. 两条标记之间（下称「输出区间」）非空，且不含 CR / ESC 等控制字符
#   5. 区间内不出现异常/失败痕迹
#   6. 三条通道抽出的输出区间【逐字节相同】
#
# 第 6 条为什么这么设计：GNU Prolog 启动时把 banner 与编译信息打进 stdout，
# SWI 与 GNU 的变量编号、浮点打印位数、错误项形状又各不相同。所以本教程
# 约定示例只打印「两套引擎必然一致」的内容，并用 开始/结束 标记把这段
# 内容圈起来；脚本抽区间再逐字节比对，banner 这类噪声自然被排除在外。
# =============================================================================

# ---------------------------------------------------------------
# 写文件一律「UTF-8 无 BOM」。
# 这不是洁癖：通道 3 要把 build\_entry.pl 与示例源码拼成一个文件再交给 gplc，
# 而 Windows PowerShell 的 Set-Content -Encoding UTF8 会写 BOM，那个 BOM 会
# 正好落在拼接结果的第一行之前，gplc 解析首行 `:- initialization(main).` 就会炸。
# ---------------------------------------------------------------
$Utf8NoBom = [System.Text.UTF8Encoding]::new($false)

function Write-TextNoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [AllowEmptyString()][string]$Text = ""
    )
    [System.IO.File]::WriteAllText($Path, $Text, $Utf8NoBom)
}

function Read-TextFile {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return "" }
    $text = [string]([System.IO.File]::ReadAllText($Path, $Utf8NoBom))
    if ($null -eq $text) { return "" }
    return $text
}

# ---------------------------------------------------------------
# 工具链定位：环境变量优先，其次 macports 路径，最后退回 PATH
#   SWIPL / GPROLOG / GPLC
# 找不到返回空串（对应 shell 版里被跳过的通道）。
# ---------------------------------------------------------------
function Resolve-Tool {
    param([string]$EnvVar, [string]$DefaultPath, [string]$Name)

    if ($EnvVar) {
        $candidate = [Environment]::GetEnvironmentVariable($EnvVar)
        if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate }
    }
    if (Test-Path -LiteralPath $DefaultPath) { return $DefaultPath }

    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return ""
}

$swipl   = Resolve-Tool "SWIPL"   "/opt/local/bin/swipl"   "swipl"
$gprolog = Resolve-Tool "GPROLOG" "/opt/local/bin/gprolog" "gprolog"
$gplc    = Resolve-Tool "GPLC"    "/opt/local/bin/gplc"    "gplc"

$haveSwipl   = ($swipl   -ne "")
$haveGprolog = ($gprolog -ne "")
$haveGplc    = ($gplc    -ne "")

$examplesDir = Join-Path $projectRoot "examples"
$buildDir    = Join-Path $projectRoot "build"

if ($Clean) {
    if (Test-Path -LiteralPath $buildDir) {
        Remove-Item -LiteralPath $buildDir -Recurse -Force
        Write-Host "已清理 build\" -ForegroundColor Yellow
    } else {
        Write-Host "build\ 不存在，无需清理。" -ForegroundColor Yellow
    }
    exit 0
}

Write-Host "=== 工具链 ==="
if ($haveSwipl)   { Write-Host "  swipl    : $swipl" }   else { Write-Host "  swipl    : 未找到（跳过该通道）" }
if ($haveGprolog) { Write-Host "  gprolog  : $gprolog" } else { Write-Host "  gprolog  : 未找到（跳过该通道）" }
if ($haveGplc)    { Write-Host "  gplc     : $gplc" }    else { Write-Host "  gplc     : 未找到（跳过该通道）" }

if (-not $haveSwipl -and -not $haveGprolog) {
    Write-Host "两个解释器都没有，无法验证。" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -LiteralPath $examplesDir)) {
    throw "找不到 examples 目录: $examplesDir"
}

New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

# gplc 需要显式入口：拼文件时把这一行放在最前面
Write-TextNoBom -Path (Join-Path $buildDir "_entry.pl") -Text ":- initialization(main).`n"

# ---------------------------------------------------------------
# 进程启动助手
#
#   1) 必须重定向 stdin，否则 gprolog 跑完会停在 toplevel 等键盘输入，
#      整个脚本就挂死了（shell 版里是 </dev/null 起的作用）。
#   2) 必须带超时兜底：示例里万一写了无限递归，不至于把 CI 卡死。
#   3) -ArgumentList 不能传空数组，会直接报错，得分两种情况调。
# ---------------------------------------------------------------
$stdinFile = Join-Path $buildDir "_empty.stdin"
if (-not (Test-Path -LiteralPath $stdinFile)) {
    Write-TextNoBom -Path $stdinFile -Text ""
}

function Invoke-Run {
    param(
        [Parameter(Mandatory = $true)][string]$Exe,
        [string[]]$ArgList = @(),
        [Parameter(Mandatory = $true)][string]$OutFile,
        [Parameter(Mandatory = $true)][string]$ErrFile,
        [int]$TimeoutMs = 60000
    )

    if ($ArgList.Count -gt 0) {
        $proc = Start-Process -FilePath $Exe -ArgumentList $ArgList `
                              -RedirectStandardInput $stdinFile `
                              -RedirectStandardOutput $OutFile `
                              -RedirectStandardError $ErrFile `
                              -NoNewWindow -PassThru
    } else {
        $proc = Start-Process -FilePath $Exe `
                              -RedirectStandardInput $stdinFile `
                              -RedirectStandardOutput $OutFile `
                              -RedirectStandardError $ErrFile `
                              -NoNewWindow -PassThru
    }

    if (-not $proc.WaitForExit($TimeoutMs)) {
        try { $proc.Kill() } catch { }
        $proc.WaitForExit(5000) | Out-Null
        return @{ ExitCode = 124; TimedOut = $true }
    }
    return @{ ExitCode = $proc.ExitCode; TimedOut = $false }
}

# ---------------------------------------------------------------
# 抽输出区间：在 stdout 里找「开始标记 → 结束标记」之间的原文。
# 用 IndexOf 而不是逐行切分，是为了把 \r 原样保留下来，
# 好让第 4 条判定真的能抓到「含 CR」。
# ---------------------------------------------------------------
function Get-Section {
    param([string]$Text, [string]$Begin, [string]$End)

    $bi = $Text.IndexOf($Begin)
    if ($bi -lt 0) { return $null }
    $ei = $Text.IndexOf($End, $bi + $Begin.Length)
    if ($ei -lt 0) { return $null }
    if ($ei -le $bi + $Begin.Length) { return "" }

    $sec = $Text.Substring($bi + $Begin.Length, $ei - ($bi + $Begin.Length))
    if ($sec.StartsWith("`r`n"))     { $sec = $sec.Substring(2) }
    elseif ($sec.StartsWith("`n"))   { $sec = $sec.Substring(1) }
    if ($sec.EndsWith("`r`n"))       { $sec = $sec.Substring(0, $sec.Length - 2) }
    elseif ($sec.EndsWith("`n"))     { $sec = $sec.Substring(0, $sec.Length - 1) }
    return $sec
}

# ---------------------------------------------------------------
# 判定核心（六条）。通过则写出一份规范化区间文件供第 6 条比对。
# $script:Pass / $script:Fail / $script:Failed 是全局计数。
# ---------------------------------------------------------------
function Test-Channel {
    param(
        [Parameter(Mandatory = $true)][string]$Tag,
        [Parameter(Mandatory = $true)][int]$ExitCode,
        [Parameter(Mandatory = $true)][string]$OutPath,
        [Parameter(Mandatory = $true)][string]$ErrPath,
        [Parameter(Mandatory = $true)][string]$Begin,
        [Parameter(Mandatory = $true)][string]$End,
        [Parameter(Mandatory = $true)][string]$SecPath,
        [switch]$TimedOut
    )

    $reasons = @()
    if ($TimedOut) { $reasons += "超时未结束" }
    if ($ExitCode -ne 0) { $reasons += "退出码=$ExitCode" }

    $errText = Read-TextFile $ErrPath
    $outText = Read-TextFile $OutPath
    $hasBegin = $outText.Contains($Begin)
    $hasEnd   = $outText.Contains($End)

    if ($errText.Trim() -ne "") { $reasons += "stderr 非空" }
    if (-not $hasBegin) { $reasons += "缺开始标记" }
    if (-not $hasEnd)   { $reasons += "缺结束标记" }

    $sec = $null
    if ($hasBegin -and $hasEnd) { $sec = Get-Section -Text $outText -Begin $Begin -End $End }

    $secNorm = ""
    if ($null -ne $sec) {
        # 第 4 条：非空 + 无控制字符
        if ($sec.Trim() -eq "") { $reasons += "输出区间为空" }
        if ($sec.Contains("`r")) { $reasons += "含 CR" }
        if ($sec.Contains([string][char]27)) { $reasons += "含 ESC" }

        $secNorm = ($sec -split "`r`n|`n|`r") -join "`n"

        # 第 5 条：区间内不许有溃逃痕迹
        if ($secNorm -match 'uncaught|command-line goal|异常:|运行失败') {
            $reasons += "区间内有溃逃痕迹"
        }
    } else {
        $reasons += "输出区间为空"
    }

    Write-TextNoBom -Path $SecPath -Text ($secNorm + "`n")

    if ($reasons.Count -eq 0) {
        Write-Host ("    [OK]   {0}" -f $Tag) -ForegroundColor Green
        $script:Pass++
        return $true
    }

    Write-Host ("    [FAIL] {0}  ({1})" -f $Tag, ($reasons -join "; ")) -ForegroundColor Red
    if ($errText.Trim() -ne "") {
        ($errText -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 4) |
            ForEach-Object { Write-Host "           stderr: $($_.Trim())" -ForegroundColor DarkGray }
    }
    if ($outText -ne "" -and -not $hasEnd) {
        Write-Host "           stdout 末 4 行：" -ForegroundColor DarkGray
        ($outText -split "`r`n|`n|`r" | Where-Object { $_ -ne "" } | Select-Object -Last 4) |
            ForEach-Object { Write-Host "           $_" -ForegroundColor DarkGray }
    }
    $script:Fail++
    $script:Failed += $Tag
    return $false
}

# ---------------------------------------------------------------
# 单通道执行：返回 @{ ExitCode = N; TimedOut = $bool }
# ---------------------------------------------------------------
function Invoke-Channel {
    param(
        [Parameter(Mandatory = $true)][string]$Channel,
        [Parameter(Mandatory = $true)][string]$Src,
        [Parameter(Mandatory = $true)][string]$Prefix
    )

    $out = "$Prefix.out"
    $err = "$Prefix.err"

    switch ($Channel) {
        "swipl" {
            # -Dencoding=utf8：Windows 上 swipl 默认按 ANSI 代码页解码源文件，UTF-8 中文
            #   示例会报 "Illegal multibyte Sequence"；set_stream 再保证重定向的
            #   stdout/stderr 也按 UTF-8 输出。macOS/Linux 上两者等价无操作，
            #   因此不必区分平台，保持单一代码路径。
            $goal = "set_stream(user_output,encoding(utf8)),set_stream(user_error,encoding(utf8)),main"
            return Invoke-Run -Exe $swipl -ArgList @("-Dencoding=utf8", "-q", "-f", $Src, "-g", $goal, "-t", "halt") `
                              -OutFile $out -ErrFile $err
        }
        "gprolog" {
            return Invoke-Run -Exe $gprolog -ArgList @("--consult-file", $Src, "--entry-goal", "main") `
                              -OutFile $out -ErrFile $err
        }
        "gplc" {
            # gplc 把「源码里字面出现的谓词调用」全部静态链接，所以必须先拼入口再整体编译。
            $combined = "$Prefix.pl"
            $bin      = "$Prefix.bin"
            $buildLog = "$Prefix.build"
            $buildErr = "$Prefix.builderr"

            $text = (Read-TextFile (Join-Path $buildDir "_entry.pl")) + (Read-TextFile $Src)
            Write-TextNoBom -Path $combined -Text $text

            # gplc 只在当前目录可靠工作，所以切到 build\ 里编
            Push-Location $buildDir
            try {
                $bp = Invoke-Run -Exe $gplc -ArgList @((Split-Path -Leaf $combined), "-o", (Split-Path -Leaf $bin)) `
                                 -OutFile $buildLog -ErrFile $buildErr -TimeoutMs 120000
            } finally {
                Pop-Location
            }

            if ($bp.ExitCode -ne 0) {
                Write-TextNoBom -Path $out -Text ""
                Write-TextNoBom -Path $err -Text ((Read-TextFile $buildLog) + (Read-TextFile $buildErr))
                return @{ ExitCode = 1; TimedOut = $false }
            }
            return Invoke-Run -Exe $bin -OutFile $out -ErrFile $err
        }
    }

    return @{ ExitCode = 1; TimedOut = $false }
}

# ---------------------------------------------------------------
# 跑一个示例目录：三通道 + 通道间逐字节比对 + observe_* 观察通道
# ---------------------------------------------------------------
$script:Pass = 0
$script:Fail = 0
$script:Failed = @()

function Invoke-Example {
    param([Parameter(Mandatory = $true)][System.IO.DirectoryInfo]$DirInfo)

    $dname = $DirInfo.Name
    $num   = ($dname -split "_")[0]
    $src   = Join-Path $DirInfo.FullName "$dname.pl"

    if (-not (Test-Path -LiteralPath $src)) { return }

    Write-Host "==== 示例 $dname ====" -ForegroundColor Cyan
    $begin = "==== $num 开始 ===="
    $end   = "==== $num 结束 ===="

    $secs = @()
    $seen = @()

    foreach ($ch in @("swipl", "gprolog", "gplc")) {
        if ($ch -eq "swipl"   -and -not $haveSwipl)   { continue }
        if ($ch -eq "gprolog" -and -not $haveGprolog) { continue }
        if ($ch -eq "gplc"    -and -not $haveGplc)    { continue }

        $pfx = Join-Path $buildDir "$dname.$ch"
        $r   = Invoke-Channel -Channel $ch -Src $src -Prefix $pfx
        $tag = "{0,-8} {1}" -f $ch, $dname

        if (Test-Channel -Tag $tag -ExitCode $r.ExitCode -OutPath "$pfx.out" -ErrPath "$pfx.err" `
                         -Begin $begin -End $end -SecPath "$pfx.sec" -TimedOut:$r.TimedOut) {
            $secs += "$pfx.sec"
            $seen += $ch
        }

        if ($Verbose) {
            $t = Read-TextFile "$pfx.sec"
            if ($t -ne "") {
                # 注意参数类型：TrimEnd 收的是 char[]，写 "`n" 靠隐式转换容易踩坑，
                # 直接给字符码 10（LF）最稳。
                ($t.TrimEnd([char]10) -split "`n") | ForEach-Object { Write-Host "           $_" -ForegroundColor DarkGray }
            }
        }
    }

    # 判定第 6 条：通道间逐字节一致
    if ($secs.Count -ge 2) {
        $refBytes = [System.IO.File]::ReadAllBytes($secs[0])
        for ($i = 1; $i -lt $secs.Count; $i++) {
            $curBytes = [System.IO.File]::ReadAllBytes($secs[$i])
            $same = ($refBytes.Length -eq $curBytes.Length)
            if ($same) {
                for ($k = 0; $k -lt $refBytes.Length; $k++) {
                    if ($refBytes[$k] -ne $curBytes[$k]) { $same = $false; break }
                }
            }
            if ($same) {
                Write-Host ("    [OK]   区间一致  {0} = {1}" -f $seen[0], $seen[$i]) -ForegroundColor Green
                $script:Pass++
            } else {
                Write-Host ("    [FAIL] 区间不一致  {0} vs {1}" -f $seen[0], $seen[$i]) -ForegroundColor Red
                # 行级 diff 给个方向（逐字节比对已经判过了，这里只做提示）
                # Read-TextFile 的返回值必须先加括号再 -split，否则 -split 会被
                # 当成 Read-TextFile 的参数名，报「找不到参数 split」。
                $a = @((Read-TextFile $secs[0]) -split "`n")
                $b = @((Read-TextFile $secs[$i]) -split "`n")
                $n = [Math]::Min($a.Count, $b.Count)
                $shown = 0
                for ($k = 0; $k -lt $n -and $shown -lt 10; $k++) {
                    if ($a[$k] -cne $b[$k]) {
                        Write-Host ("           - {0}" -f $a[$k]) -ForegroundColor DarkGray
                        Write-Host ("           + {0}" -f $b[$k]) -ForegroundColor DarkGray
                        $shown++
                    }
                }
                $script:Fail++
                $script:Failed += "$dname/$($seen[$i])#diff"
            }
        }
    }

    # 观察通道 observe_*.pl：只要求「跑到底」，不参与逐字节比对。
    # 文件名后缀可指定只在某个引擎上跑：
    #   observe_xxx_swi.pl  → 只在 SWI 上跑（如原生模块、library(clpfd)）
    #   observe_xxx_gnu.pl  → 只在 GNU 上跑（如内建 fd 约束）
    #   observe_xxx.pl      → 两个引擎都跑
    Get-ChildItem -Path $DirInfo.FullName -Filter "observe_*.pl" -File | Sort-Object Name | ForEach-Object {
        $obs   = $_.FullName
        $obase = $_.BaseName
        foreach ($ch in @("swipl", "gprolog")) {
            if ($ch -eq "swipl"   -and -not $haveSwipl)   { continue }
            if ($ch -eq "gprolog" -and -not $haveGprolog) { continue }
            if ($obase.EndsWith("_swi") -and $ch -ne "swipl")   { continue }
            if ($obase.EndsWith("_gnu") -and $ch -ne "gprolog") { continue }

            $opfx = Join-Path $buildDir "$dname.$obase.$ch"
            $r    = Invoke-Channel -Channel $ch -Src $obs -Prefix $opfx
            $tag  = "{0,-8} {1}(观察)" -f $ch, $obase
            Test-Channel -Tag $tag -ExitCode $r.ExitCode -OutPath "$opfx.out" -ErrPath "$opfx.err" `
                         -Begin "==== $num 观察 开始 ====" -End "==== $num 观察 结束 ====" `
                         -SecPath "$opfx.sec" -TimedOut:$r.TimedOut | Out-Null
        }
    }
}

# ---------------------------------------------------------------
# 主循环
# ---------------------------------------------------------------
$dirs = @(Get-ChildItem -LiteralPath $examplesDir -Directory |
          Where-Object { $_.Name -match '^\d' } | Sort-Object Name)

if ($dirs.Count -eq 0) { throw "examples 目录下没有 NN_topic 形式的示例目录。" }

$selected = @()
foreach ($d in $dirs) {
    if ($Example.Count -gt 0) {
        $num = ($d.Name -split "_")[0]
        $hit = $false
        foreach ($s in $Example) {
            if ($s -eq $num -or $s -eq $d.Name) { $hit = $true; break }
        }
        if (-not $hit) { continue }
    }
    $selected += $d
}

if ($selected.Count -eq 0) {
    Write-Host "没有匹配的示例。用 -Example 07,24 指定编号，或省略该参数跑全部。" -ForegroundColor Yellow
    exit 1
}

foreach ($d in $selected) { Invoke-Example -DirInfo $d }

Write-Host ""
Write-Host "================================"
$color = if ($script:Fail -eq 0) { "Green" } else { "Red" }
Write-Host ("通过 {0}    失败 {1}" -f $script:Pass, $script:Fail) -ForegroundColor $color
if ($script:Fail -eq 0) {
    Write-Host "全部通过" -ForegroundColor Green
    exit 0
}
Write-Host "失败项：" -ForegroundColor Red
$script:Failed | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
exit 1
