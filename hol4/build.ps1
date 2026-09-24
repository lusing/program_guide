#Requires -Version 7
<#
.SYNOPSIS
    HOL4 教程示例验证脚本（PowerShell 版）。

.DESCRIPTION
    与 run-all.sh 逐项等价的第二条验证入口。判定项目必须保持一一对应：
      每条通道各自过 1-5，跨通道再过 6-7，每章 5 项，24 章共 120 项。
        1. 退出码 0
        2. stderr 为空
        3. 开始 / 结束两个标记各恰好出现一次（整行严格相等）
        4. 标记区间非空，且不含控制字符
        5. 区间无溃逃痕迹（组合判据，见 Test-EscapeTrace）
        6. run1 与 run2 的区间逐字节一致（运行间确定性）
        7. run1 与 hm   的区间逐字节一致（两条独立入口一致）

    通道：
      run1 / run2  ——  `hol run TutNNScript.sml` 两条独立进程
      hm           ——  `Holmake TutNNTheory.uo`，输出从 .hol/logs/TutNNTheory 取

    不要用 REPL 管道模式（`hol < f.sml`）验证：它遇到未捕获异常会打印后继续，
    退出码仍是 0 —— 看起来跑完了，其实中间死在某一行。

.EXAMPLE
    pwsh -NoProfile -Command '& ./build.ps1 -All'
    pwsh -NoProfile -Command '& ./build.ps1 -Only 13'
    pwsh -NoProfile -Command '& ./build.ps1 -Clean'
    $env:HOLBIN='/path/to/hol'; pwsh -NoProfile -Command '& ./build.ps1 -All'

.NOTES
    调用方式：必须用 `pwsh -NoProfile -Command '& ./build.ps1 ...'`。
    本机（pwsh 7.6.6 / MacPorts）`pwsh -File x.ps1` 会报
    "Call to 'procargs' failed with errno 5" 直接崩。
#>
param(
    [switch]$All,
    [string]$Only = '',
    [switch]$Clean,
    [int]$Tmo = 120
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Root

$Examples = Join-Path $Root 'examples'
$Out = Join-Path $Root 'build'

# --- 工具发现：不硬编码，缺工具直接报错退出 ------------------------------
$HOL = $null
if ($env:HOLBIN) { $HOL = $env:HOLBIN }
else {
    $candidates = @(
        '/Volumes/mac004/lang/hol4-build/bin/hol',
        '/Volumes/mac004/lang/hol/bin/hol',
        (Join-Path $HOME 'hol/bin/hol'),
        '/usr/local/bin/hol'
    )
    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c -PathType Leaf)) { $HOL = $c; break }
    }
    if (-not $HOL) {
        $cmd = Get-Command hol -ErrorAction SilentlyContinue
        if ($cmd) { $HOL = $cmd.Source }
    }
}
if (-not $HOL -or -not (Test-Path -LiteralPath $HOL -PathType Leaf)) {
    Write-Error "未找到 hol 可执行文件：请先构建 HOL4，或设 `$env:HOLBIN=/path/to/hol"
    exit 1
}
$HOLMAKE = Join-Path (Split-Path -Parent $HOL) 'Holmake'
if (-not (Test-Path -LiteralPath $HOLMAKE -PathType Leaf)) {
    Write-Error "未找到 Holmake（期望在 $(Split-Path -Parent $HOL)）"
    exit 1
}

# 目录筛选用正则，不用 -Filter '[0-9]*'：FileSystem provider 的 -Filter 不吃
# 这种字符类（实测返回空，于是整轮被跳过、报"通过 0，失败 0"—— 又是假绿）。
function Get-ChapterDirs([string]$Path) {
    Get-ChildItem -LiteralPath $Path -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d\d_' } |
        Sort-Object Name
}

if ($Clean) {
    foreach ($d in Get-ChapterDirs $Out) {
        Remove-Item -LiteralPath $d.FullName -Recurse -Force
    }
    Write-Output "已清理 $Out/ 下各章子目录"
    exit 0
}

if (-not (Test-Path -LiteralPath $Out)) { New-Item -ItemType Directory -Path $Out | Out-Null }

# --- 区间抽取 ------------------------------------------------------------
# 匹配必须**整行严格相等**，不能写 -like '*...*' 子串匹配。
# 理由（第 23 章实测）：教程正文会把标记原样印出来讲解，子串匹配会把
# "讲解"当成真的结束标记，区间被提前截断 —— 而"区间非空""两条通道一致"
# 这些判据照样全绿，丢掉的半章没人发现。
function Get-Region([string[]]$Lines, [string]$Begin, [string]$End) {
    $res = [System.Collections.Generic.List[string]]::new()
    $inside = $false
    foreach ($l in $Lines) {
        if ($l -ceq $End) { break }
        if ($inside) { $res.Add($l) }
        if ($l -ceq $Begin) { $inside = $true }
    }
    return $res
}

# --- 溃逃痕迹：组合判据，不是关键字列表 ----------------------------------
# 所有单行判据都锚定行首（^），并尽量带上"只有真错误才有"的上下文。
# 这是第 23 章实测踩出来的：那一章正文把 `Static Errors` / `Uncaught exception`
# / `: error:` 原样印进了输出，裸的子串匹配把"讲解"当成了"痕迹"。
# 真实错误行的形状是
#     bad.sml:4: error: Pattern and expression have incompatible types.
#     Uncaught exception at ./basis/FinalPolyML.sml:492: Fail "Static Errors"
# 注意 `Exception raised at ...` **不算**痕迹：19.3 / 22.4 / 23.2 是故意
# handle 住异常打印出来做演示的，它们是预期输出。
function Test-EscapeTrace([string[]]$Lines) {
    $inpf = $false
    foreach ($l in $Lines) {
        if ($l -match '^Uncaught exception')                  { return $true }
        if ($l -match '^Static Errors')                       { return $true }
        if ($l -match '^poly:.*error')                        { return $true }
        if ($l -match '^error in quse')                       { return $true }
        if ($l -match '^[^\s]+\.sml:\d+.*: error:')           { return $true }
        if ($l -match '^Proof of\s*$')                        { $inpf = $true }
        if ($inpf -and ($l -match '^failed\.\s*$'))           { return $true }
    }
    return $false
}

# 逐行写（与 run-all.sh 里 awk 的 print 等价：每行后面补一个换行）。
# 只用于 .sec —— 比对是在本脚本自己的三条通道之间做的，不需要跟 shell 版
# 的字节流一致，但语义上保持一致更省心。
function Write-Utf8([string]$Path, [string[]]$Lines) {
    $enc = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllLines($Path, $Lines, $enc)
}

# 原样写（**不加**换行）。.out / .err 必须是进程输出的原样字节：
# 用 WriteAllLines 写空字符串会留下 1 个字节的换行，于是"stderr 为空"
# 这条判据恒为假 —— 三条通道一起误报。
function Write-Utf8Raw([string]$Path, [string]$Text) {
    $enc = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Text, $enc)
}

$script:Pass = 0
$script:Fail = 0
$script:Failed = [System.Collections.Generic.List[string]]::new()

function Invoke-Judge([string]$Label, [string]$Pfx, [string]$Num) {
    $ok = $true
    $why = [System.Collections.Generic.List[string]]::new()

    $rcPath = "$Pfx.exit"
    $rc = if (Test-Path -LiteralPath $rcPath) { (Get-Content -LiteralPath $rcPath -Raw).Trim() } else { '1' }
    if ($rc -ne '0') { $ok = $false; $why.Add("退出码 $rc") }

    $errPath = "$Pfx.err"
    if ((Test-Path -LiteralPath $errPath) -and ((Get-Item -LiteralPath $errPath).Length -gt 0)) {
        $ok = $false; $why.Add('stderr 非空')
    }

    $outPath = "$Pfx.out"
    $outLines = @()
    if (Test-Path -LiteralPath $outPath) {
        $outLines = [System.IO.File]::ReadAllLines((Resolve-Path -LiteralPath $outPath), [System.Text.UTF8Encoding]::new($false))
    }
    # 标记必须各**恰好出现一次**（整行严格相等）。只判"存在"不够：
    # 多打一次标记会让区间抽取停错地方，而"区间非空"照样通过。
    $begin = "==== $Num 开始 ===="
    $end = "==== $Num 结束 ===="
    $nb = @($outLines | Where-Object { $_ -ceq $begin }).Count
    $ne = @($outLines | Where-Object { $_ -ceq $end }).Count
    if ($nb -ne 1) { $ok = $false; $why.Add("开始标记出现 $nb 次（应为 1）") }
    if ($ne -ne 1) { $ok = $false; $why.Add("结束标记出现 $ne 次（应为 1）") }

    $region = Get-Region $outLines $begin $end
    Write-Utf8 "$Pfx.sec" $region

    if ($region.Count -eq 0) { $ok = $false; $why.Add('区间为空') }
    $ctrl = $false
    foreach ($l in $region) {
        foreach ($ch in $l.ToCharArray()) {
            if ([char]::IsControl($ch) -and $ch -ne "`t") { $ctrl = $true; break }
        }
        if ($ctrl) { break }
    }
    if ($ctrl) { $ok = $false; $why.Add('区间含控制字符') }
    if (Test-EscapeTrace $region) { $ok = $false; $why.Add('区间含溃逃痕迹') }

    if ($ok) {
        $script:Pass++
        Write-Output "    [OK]   $Label"
    } else {
        $script:Fail++
        $script:Failed.Add("$Label ($($why -join '; '))")
        Write-Output "    [!]    $Label  ($($why -join '; '))"
    }
}

function Invoke-Compare([string]$A, [string]$B, [string]$Label) {
    $ba = if (Test-Path -LiteralPath $A) { [System.IO.File]::ReadAllBytes($A) } else { @() }
    $bb = if (Test-Path -LiteralPath $B) { [System.IO.File]::ReadAllBytes($B) } else { @() }
    $same = ($ba.Length -eq $bb.Length)
    if ($same) {
        for ($i = 0; $i -lt $ba.Length; $i++) {
            if ($ba[$i] -ne $bb[$i]) { $same = $false; break }
        }
    }
    if ($same) {
        $script:Pass++
        Write-Output "    [OK]   $Label"
    } else {
        $script:Fail++
        $script:Failed.Add("$Label (区间不一致)")
        Write-Output "    [!]    $Label  (区间不一致)"
    }
}

# --- 看门狗：带超时地跑一条命令 ------------------------------------------
# `metis_tac` / `rw` 被喂进方向不对称的定理时可能**不终止**，这时退出码判据
# 完全失效 —— 进程还在跑，只是永远跑不完。看门狗把它变成可诊断的失败。
function Invoke-Watched([string]$Exe, [string[]]$ArgList, [string]$WorkDir,
                        [string]$Stdout, [string]$Stderr) {
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $Exe
    foreach ($a in $ArgList) { $psi.ArgumentList.Add($a) }
    $psi.WorkingDirectory = $WorkDir
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $stdoutTask = $p.StandardOutput.ReadToEndAsync()
    $stderrTask = $p.StandardError.ReadToEndAsync()
    $finished = $p.WaitForExit($Tmo * 1000)
    if (-not $finished) {
        $p.Kill()
        $p.WaitForExit()
        $rc = 137          # 137 = 被 KILL，即看门狗触发（真崩是 1）
    } else {
        $rc = $p.ExitCode
    }
    $so = $stdoutTask.GetAwaiter().GetResult()
    $se = $stderrTask.GetAwaiter().GetResult()
    if ($rc -eq 137) {
        $se = $se + "（看门狗：${Tmo}s 内没跑完，多半是某个 tactic 不终止）`n"
    }
    Write-Utf8Raw $Stdout $so
    Write-Utf8Raw $Stderr $se
    return $rc
}

Write-Output "hol     = $HOL"
Write-Output "Holmake = $HOLMAKE"
Write-Output ''

$chapterDirs = Get-ChapterDirs $Examples
if ($chapterDirs.Count -eq 0) {
    Write-Error "examples/ 下没有 NN_topic/ 形式的示例目录（拒绝「通过 0」的假绿）"
    exit 1
}

foreach ($dir in $chapterDirs) {
    $dname = $dir.Name
    $num = ($dname -split '_')[0]
    $src = Join-Path $dir.FullName "$dname.sml"
    if (-not (Test-Path -LiteralPath $src)) {
        Write-Output "[skip] ${dname}：缺少 $dname.sml"
        continue
    }
    if ($Only -and ($Only -ne $num) -and ($Only -ne $dname)) { continue }
    Write-Output "== [$num] $dname"

    $base = Join-Path $Out $dname
    if (-not (Test-Path -LiteralPath $base)) { New-Item -ItemType Directory -Path $base | Out-Null }
    foreach ($ch in @('run1', 'run2', 'hm')) {
        $d = Join-Path $base $ch
        if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force }
        New-Item -ItemType Directory -Path $d | Out-Null
        Copy-Item -LiteralPath $src -Destination (Join-Path $d "Tut${num}Script.sml")
    }

    foreach ($ch in @('run1', 'run2')) {
        $d = Join-Path $base $ch
        $rc = Invoke-Watched $HOL @('run', "Tut${num}Script.sml") $d `
                              (Join-Path $base "$ch.out") (Join-Path $base "$ch.err")
        Set-Content -LiteralPath (Join-Path $base "$ch.exit") -Value "$rc" -Encoding utf8
    }

    $d = Join-Path $base 'hm'
    $rc = Invoke-Watched $HOLMAKE @("Tut${num}Theory.uo") $d `
                          (Join-Path $base 'hm.out') (Join-Path $base 'hm.err')
    Set-Content -LiteralPath (Join-Path $base 'hm.exit') -Value "$rc" -Encoding utf8
    $log = Join-Path $d ".hol/logs/Tut${num}Theory"
    if (Test-Path -LiteralPath $log) {
        Copy-Item -LiteralPath $log -Destination (Join-Path $base 'hm.out') -Force
    } else {
        Write-Utf8Raw (Join-Path $base 'hm.out') ''
    }

    foreach ($ch in @('run1', 'run2', 'hm')) {
        Invoke-Judge "$ch  $dname" (Join-Path $base $ch) $num
    }
    Invoke-Compare (Join-Path $base 'run1.sec') (Join-Path $base 'run2.sec') "run1==run2  ${dname}（运行间确定性）"
    Invoke-Compare (Join-Path $base 'run1.sec') (Join-Path $base 'hm.sec')   "run1==hm    ${dname}（两条入口一致）"
    Write-Output ''
}

Write-Output '----------------------------------------'
Write-Output "通过 $($script:Pass)，失败 $($script:Fail)"
if ($script:Fail -gt 0) {
    Write-Output '失败项：'
    foreach ($f in $script:Failed) { Write-Output "  - $f" }
    exit 1
}
exit 0
