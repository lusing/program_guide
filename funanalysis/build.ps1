#Requires -Version 7
<#
    泛函分析教程验证脚本：五通道 lean / isabelle / julia / python / prolog。

    用法:
      pwsh -NoProfile -Command '& ./build.ps1 -All'          全量验证
      pwsh -NoProfile -Command '& ./build.ps1 -Chapter 02'    只验一章（章号或目录名）
      pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'     只验一种语言
      pwsh -NoProfile -Command '& ./build.ps1 -List'          列出全部验证单元
      pwsh -NoProfile -Command '& ./build.ps1 -Clean'         清理产物

    通道判定:
      lean     : examples/lean 单一 lake 工程（mathlib 路径依赖
                 H:/Lang/lean4/mathlib4-4.33.1 钉版发布），`lake build` 退出码 0 且
                 输出无 error:/warning:。整工程一次构建，
                 报告时把 Funanalysis/ChNN*.lean 逐章点亮。
      isabelle : 每章一个会话（examples/isabelle/ROOT 里
                 session FANN in "FANN"），经 Isabelle2025-2 自带
                 Cygwin bash -lc 调 `isabelle build -d <dir> FANN`；
                 退出码 0 且输出无 failed/Failed/FAILED。
      julia    : `julia --startup-file=no NN_xxx.jl`，退出码 0 且
                 stdout 含 "==== NN" 与 "END ====" 标记。
      python   : `python -I NN_xxx.py`，退出码 0 且标记齐全
                 （PYTHONIOENCODING=utf-8 防控制台代码页坑）。
      prolog   : 本机 SWI-Prolog（swipl -q -f 文件 -g main -t halt），
                 退出码 0 且 stdout 含 "END ===="；
                 WSL gprolog 为跨引擎抽查通道（-ExtraProlog 才跑）。
#>
param(
    [switch]$All,
    [string[]]$Chapter = @(),
    [string]$Lang = "",
    [switch]$List,
    [switch]$Clean,
    [switch]$ExtraProlog
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$examples = Join-Path $root 'examples'
$buildDir = Join-Path $root 'build'

# 工具定位
$isaHome = 'G:\xulun3\isabelle\Isabelle2025-2'
$isaBash = Join-Path $isaHome 'contrib\cygwin\bin\bash.exe'

# ---------- 清理 ----------
if ($Clean) {
    if (Test-Path $buildDir) { Remove-Item -Recurse -Force $buildDir }
    Write-Host '[Clean] 已清理 build/。'
    exit 0
}

# ---------- 发现验证单元 ----------
# lean：整工程 + 逐章文件点亮
$leanDir = Join-Path $examples 'lean'
$leanChapters = Get-ChildItem (Join-Path $leanDir 'Funanalysis') -Filter 'Ch*.lean' -ErrorAction SilentlyContinue |
    ForEach-Object { ($_.BaseName -replace '^Ch(\d\d).*$', '$1') }

# isabelle：解析 ROOT 得会话（会话名 FANN <-> 章 NN）
$isaRoot = Join-Path $examples 'isabelle\ROOT'
$isaSessions = @()
if (Test-Path $isaRoot) {
    $dir = Split-Path $isaRoot
    Get-Content $isaRoot | ForEach-Object {
        if ($_ -match '^session\s+(FA\d+)\s+in\s+"([^"]+)"') {
            $isaSessions += [pscustomobject]@{
                Session = $Matches[1]
                Dir     = Join-Path $dir $Matches[2]
                Chapter = $Matches[1] -replace '^FA', ''
            }
        }
    }
}

# julia / python / prolog：按文件名前缀发现
function Find-ChannelUnits($sub, $pattern) {
    $d = Join-Path $examples $sub
    if (-not (Test-Path $d)) { return @() }
    Get-ChildItem $d -Filter $pattern -File | ForEach-Object {
        [pscustomobject]@{ Chapter = ($_.BaseName -replace '^(\d\d).*$', '$1'); Path = $_.FullName }
    }
}
$juliaUnits = Find-ChannelUnits 'julia' '*.jl' | Where-Object { $_.Path -notmatch 'run-all' }
$pyUnits = Find-ChannelUnits 'python' '*.py'
$plUnits = Find-ChannelUnits 'prolog' '*.pl'

$allChapters = (@($leanChapters) + @($isaSessions.Chapter) + $juliaUnits.Chapter + $pyUnits.Chapter + $plUnits.Chapter) |
    Sort-Object -Unique

# ---------- 过滤 ----------
$wantChapters = if ($Chapter.Count -gt 0) { $Chapter | ForEach-Object { $_ -replace '^(\d+)$', '{0:D2}' -f [int]$_ } } else { @() }
$wantLangs = if ($Lang) { @($Lang.ToLower()) } else { @('lean', 'isabelle', 'julia', 'python', 'prolog') }

function Test-ChapterWanted($ch) {
    if ($wantChapters.Count -eq 0) { return $true }
    return ($wantChapters -contains $ch)
}

# ---------- 列出 ----------
if ($List) {
    Write-Host '章 × 通道矩阵（文件存在即预期验证）：'
    foreach ($ch in $allChapters) {
        $row = [ordered]@{ 章 = $ch }
        $row.lean = if ($leanChapters -contains $ch) { 'x' } else { '' }
        $row.isabelle = if ($isaSessions.Chapter -contains $ch) { 'x' } else { '' }
        $row.julia = if ($juliaUnits.Chapter -contains $ch) { 'x' } else { '' }
        $row.python = if ($pyUnits.Chapter -contains $ch) { 'x' } else { '' }
        $row.prolog = if ($plUnits.Chapter -contains $ch) { 'x' } else { '' }
        [pscustomobject]$row | Format-Table -AutoSize | Out-String -Stream | Where-Object { $_ }
    }
    exit 0
}

# ---------- 通道执行 ----------
$results = [System.Collections.Generic.List[object]]::new()
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Result($ch, $lang, $ok, $detail = '') {
    $script:results.Add([pscustomobject]@{
        章 = $ch; 通道 = $lang; 结果 = if ($ok) { 'PASS' } else { 'FAIL' }
    })
    if (-not $ok) { $script:failures.Add("[$lang/$ch] $detail") }
}

$swOverall = [System.Diagnostics.Stopwatch]::StartNew()

# --- lean：一次构建整工程 ---
if ($wantLangs -contains 'lean') {
    $chaptersHere = @($leanChapters | Where-Object { Test-ChapterWanted $_ })
    if ($chaptersHere.Count -gt 0) {
        Write-Host "`n[lean] lake build（整工程，增量）..."
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        Push-Location $leanDir
        try {
            $out = & lake build 2>&1 | Out-String
            $code = $LASTEXITCODE
        } finally { Pop-Location }
        $ok = ($code -eq 0) -and -not ($out -match '(?m)error:|warning:')
        foreach ($ch in $chaptersHere) {
            Add-Result $ch 'lean' ($ok -and $true) $(if (-not $ok) { $out.Substring(0, [Math]::Min(1500, $out.Length)) })
        }
        Write-Host ("[lean] {0}（{1:N1}s）" -f ($(if ($ok) { 'PASS' } else { 'FAIL' })), $sw.Elapsed.TotalSeconds)
        if (-not $ok) { Write-Host $out.Substring(0, [Math]::Min(3000, $out.Length)) -ForegroundColor Red }
    }
}

# --- isabelle：每章一会话 ---
if ($wantLangs -contains 'isabelle') {
    foreach ($s in $isaSessions | Where-Object { Test-ChapterWanted $_.Chapter }) {
        Write-Host "`n[isabelle] build $($s.Session)..."
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $isaDir = Join-Path $examples 'isabelle'
        $exCyg = '/cygdrive/' + $isaDir.Substring(0, 1).ToLower() + ($isaDir.Substring(2) -replace '\\', '/')
        $cygCmd = "/cygdrive/g/xulun3/isabelle/Isabelle2025-2/bin/isabelle build -d $exCyg $($s.Session)"
        $out = & $isaBash -lc $cygCmd 2>&1 | Out-String
        $ok = ($LASTEXITCODE -eq 0) -and -not ($out -match '(?i)failed|error')
        Add-Result $s.Chapter 'isabelle' $ok $out
        Write-Host ("[isabelle] {0} {1}（{2:N1}s）" -f $s.Session, $(if ($ok) { 'PASS' } else { 'FAIL' }), $sw.Elapsed.TotalSeconds)
        if (-not $ok) { Write-Host $out.Substring(0, [Math]::Min(3000, $out.Length)) -ForegroundColor Red }
    }
}

# --- julia / python / prolog：逐文件 ---
function Invoke-ScriptUnit($units, $langName, $invoker) {
    foreach ($u in $units | Where-Object { Test-ChapterWanted $_.Chapter }) {
        Write-Host "`n[$langName] $(Split-Path -Leaf $u.Path)"
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $out = & $invoker $u.Path 2>&1 | Out-String
        $code = $LASTEXITCODE
        $ch2 = $u.Chapter
        $ok = ($code -eq 0) -and ($out -match "==== $ch2") -and ($out -match 'END ====')
        Add-Result $u.Chapter $langName $ok $out
        Write-Host ("[{0}] {1}（{2:N1}s）" -f $langName, $(if ($ok) { 'PASS' } else { 'FAIL' }), $sw.Elapsed.TotalSeconds)
        if (-not $ok) { Write-Host $out.Substring(0, [Math]::Min(3000, $out.Length)) -ForegroundColor Red }
    }
}

if ($wantLangs -contains 'julia') {
    Invoke-ScriptUnit $juliaUnits 'julia' { param($p) & julia --startup-file=no $p }
}
if ($wantLangs -contains 'python') {
    $env:PYTHONIOENCODING = 'utf-8'
    # 解释器自愈：scoop current 可能指向无 numpy 的新 Python（实测 3.15），
    # 优先用带 numpy/scipy 的解释器
    if (-not (& python -I -c "import numpy, scipy" *> $null)) {
        $pyFallback = 'G:\scoop\apps\python313\current'
        if (Test-Path (Join-Path $pyFallback 'python.exe')) {
            Write-Host "[python] 默认 python 缺 numpy/scipy，改用 $pyFallback"
            $env:PATH = "$pyFallback;$env:PATH"
        }
    }
    Invoke-ScriptUnit $pyUnits 'python' { param($p) & python -I $p }
}
if ($wantLangs -contains 'prolog') {
    Invoke-ScriptUnit $plUnits 'prolog' { param($p) & swipl -q -f $p -g main -t halt }
}

# --- gprolog 跨引擎抽查（可选） ---
if ($ExtraProlog) {
    foreach ($u in $plUnits | Where-Object { Test-ChapterWanted $_.Chapter }) {
        $wslPath = '/mnt/' + $u.Path.Substring(0, 1).ToLower() + ($u.Path.Substring(2) -replace '\\', '/')
        $out = & wsl -d Ubuntu-26.04 -e gprolog --consult-file $wslPath --query-goal main 2>&1 |
            Out-String
        $ok = ($LASTEXITCODE -eq 0) -and ($out -match 'END ====')
        Add-Result $u.Chapter 'gprolog' $ok $out
    }
}

# ---------- 汇总 ----------
$swOverall.Stop()
Write-Host "`n========== 验证报告 =========="
if ($results.Count -gt 0) {
    # 透视成 章 × 通道 矩阵
    $matrix = $results | Group-Object 章 | Sort-Object Name | ForEach-Object {
        $row = [ordered]@{ 章 = $_.Name }
        foreach ($l in 'lean', 'isabelle', 'julia', 'python', 'prolog', 'gprolog') {
            $hit = $_.Group | Where-Object 通道 -eq $l
            $row[$l] = if ($hit) { $hit[0].结果 } else { '' }
        }
        [pscustomobject]$row
    }
    $matrix | Format-Table -AutoSize
    $pass = ($results | Where-Object 结果 -eq 'PASS').Count
    $fail = ($results | Where-Object 结果 -eq 'FAIL').Count
    Write-Host ("合计 {0} 单元：PASS {1}，FAIL {2}（{3:N1}s）" -f $results.Count, $pass, $fail, $swOverall.TotalSeconds)
} else {
    Write-Host '没有匹配的验证单元（检查 -Chapter/-Lang 过滤条件）。'
}
if ($failures.Count -gt 0) {
    Write-Host "`n失败明细：" -ForegroundColor Red
    $failures | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    exit 1
}
exit 0
