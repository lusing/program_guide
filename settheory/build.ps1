#Requires -Version 7
<#
    集合论教程验证脚本：七通道 lean / isabelle / coq / agda / julia / python / prolog。

    用法:
      pwsh -NoProfile -Command '& ./build.ps1 -All'          全量验证
      pwsh -NoProfile -Command '& ./build.ps1 -Chapter 02'    只验一章（章号或目录名）
      pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'     只验一种语言
      pwsh -NoProfile -Command '& ./build.ps1 -List'          列出全部验证单元
      pwsh -NoProfile -Command '& ./build.ps1 -Clean'         清理产物

    通道判定:
      lean     : examples/lean 单一 lake 工程（mathlib 路径依赖
                 F:/github/mathlib4 钉版 commit，lean-toolchain 对齐
                 v4.21.0-rc3），`lake build` 退出码 0 且
                 输出无 error:/warning:。整工程一次构建，
                 报告时把 Settheory/ChNN*.lean 逐章点亮。
      isabelle : 每章一个会话（examples/isabelle/ROOT 里
                 session STNN in "STNN"），ZF object-logic；经 Isabelle2026
                 （E:\lang\Isabelle2026）自带 Cygwin bash -lc 调
                 `isabelle build -d <dir> STNN`；
                 退出码 0 且输出无 failed/Failed/FAILED。
      coq      : Rocq 9.1（E:\lang\Rocq-Platform~9.1~2026.01）
                 `coqc -Q examples/coq Settheory NN_*.v` 逐文件，退出码 0。
      agda     : Agda 2.8.0.2 win64（E:\lang\Agda-v2.8.0.2-win64\agda.exe）
                 + stdlib（E:\github\agda\std-lib\src）
                 `agda -i <stdlib> -i examples/agda <文件>` 逐文件，退出码 0。
      julia    : `julia --startup-file=no NN_*.jl`，退出码 0 且
                 stdout 含 "==== NN" 与 "END ====" 标记。
      python   : `python -I NN_*.py`（python313 + scipy），
                 退出码 0 且标记齐全（PYTHONIOENCODING=utf-8）。
      prolog   : 本机 SWI-Prolog（swipl -q -f 文件 -g main -t halt），
                 退出码 0 且 stdout 含 "END ===="；WSL gprolog 抽查（-ExtraProlog）。
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
$isaHome = 'E:\lang\Isabelle2026'
$isaBash = Join-Path $isaHome 'contrib\cygwin\bin\bash.exe'
$isaCygBin = '/cygdrive/e/lang/Isabelle2026/bin/isabelle'
$coqc = 'E:\lang\Rocq-Platform~9.1~2026.01\bin\coqc.exe'
$pyExe = 'D:\scoop\apps\python313\current\python.exe'

# ---------- 清理 ----------
if ($Clean) {
    if (Test-Path $buildDir) { Remove-Item -Recurse -Force $buildDir }
    if (Test-Path (Join-Path $examples 'lean\.lake')) {
        Remove-Item -Recurse -Force (Join-Path $examples 'lean\.lake')
    }
    Write-Host '[Clean] 已清理 build/ 与 lean/.lake。'
    exit 0
}

# ---------- 发现验证单元 ----------
# lean：整工程 + 逐章文件点亮
$leanDir = Join-Path $examples 'lean'
$leanChapters = Get-ChildItem (Join-Path $leanDir 'Settheory') -Filter 'Ch*.lean' -ErrorAction SilentlyContinue |
    ForEach-Object { ($_.BaseName -replace '^Ch(\d+).*$', '$1') }

# isabelle：解析 ROOT 得会话（会话名 STNN <-> 章 NN）
$isaRoot = Join-Path $examples 'isabelle\ROOT'
$isaSessions = @()
if (Test-Path $isaRoot) {
    $dir = Split-Path $isaRoot
    Get-Content $isaRoot | ForEach-Object {
        if ($_ -match '^session\s+(ST\d+)\s+in\s+"([^"]+)"') {
            $isaSessions += [pscustomobject]@{
                Session = $Matches[1]
                Dir     = Join-Path $dir $Matches[2]
                Chapter = $Matches[1] -replace '^ST', ''
            }
        }
    }
}

# coq / agda / julia / python / prolog：按文件名前缀发现
function Find-ChannelUnits($sub, $pattern) {
    $d = Join-Path $examples $sub
    if (-not (Test-Path $d)) { return @() }
    Get-ChildItem $d -Filter $pattern -File | ForEach-Object {
        # NN_*.jl / NN_*.py / NN_*.pl 用完整十进制章号前缀；
        # ChNN_*.v / ChNN_*.agda（模块名不能数字开头）用 Ch 前缀。
        $ch = if ($_.BaseName -match '^Ch(\d+)') { $Matches[1] }
              else { ($_.BaseName -replace '^(\d+).*$', '$1') }
        [pscustomobject]@{ Chapter = $ch; Path = $_.FullName }
    }
}
$coqUnits = Find-ChannelUnits 'coq' 'Ch*.v'
$agdaUnits = Find-ChannelUnits 'agda' 'Ch*.agda'
$juliaUnits = Find-ChannelUnits 'julia' '*.jl' | Where-Object { $_.Path -notmatch 'run-all' }
$pyUnits = Find-ChannelUnits 'python' '*.py'
$plUnits = Find-ChannelUnits 'prolog' '*.pl'

$allChapters = (@($leanChapters) + @($isaSessions.Chapter) + $coqUnits.Chapter + $agdaUnits.Chapter +
    $juliaUnits.Chapter + $pyUnits.Chapter + $plUnits.Chapter) | Sort-Object -Unique

# ---------- 过滤 ----------
$wantChapters = if ($Chapter.Count -gt 0) { $Chapter | ForEach-Object { $_ -replace '^(\d+)$', '{0:D2}' -f [int]$_ } } else { @() }
$wantLangs = if ($Lang) { @($Lang.ToLower()) } else { @('lean', 'isabelle', 'coq', 'agda', 'julia', 'python', 'prolog') }

function Test-ChapterWanted($ch) {
    if ($wantChapters.Count -eq 0) { return $true }
    return ($wantChapters -contains $ch)
}

# ---------- List ----------
if ($List) {
    Write-Host '章 | lean | isa | coq | agda | julia | python | prolog'
    foreach ($ch in $allChapters) {
        $row = [ordered]@{}
        $row.lean = if ($leanChapters -contains $ch) { 'x' } else { '' }
        $row.isa = if ($isaSessions.Chapter -contains $ch) { 'x' } else { '' }
        $row.coq = if ($coqUnits.Chapter -contains $ch) { 'x' } else { '' }
        $row.agda = if ($agdaUnits.Chapter -contains $ch) { 'x' } else { '' }
        $row.julia = if ($juliaUnits.Chapter -contains $ch) { 'x' } else { '' }
        $row.python = if ($pyUnits.Chapter -contains $ch) { 'x' } else { '' }
        $row.prolog = if ($plUnits.Chapter -contains $ch) { 'x' } else { '' }
        Write-Host ('{0} | {1} | {2} | {3} | {4} | {5} | {6} | {7}' -f
            $ch, $row.lean, $row.isa, $row.coq, $row.agda, $row.julia, $row.python, $row.prolog)
    }
    exit 0
}

# ---------- 执行 ----------
$results = [System.Collections.Generic.List[object]]::new()
$fail = 0

function Add-Result($ch, $lang, $desc, $ok, $detail) {
    $script:results.Add([pscustomobject]@{
        Chapter = $ch; Lang = $lang; Desc = $desc
        Status = if ($ok) { 'PASS' } else { 'FAIL' }; Detail = $detail
    })
    if (-not $ok) { $script:fail++ }
}

# --- lean：整工程一次构建 ---
$leanBuilt = $false
if ($wantLangs -contains 'lean' -and $leanChapters.Count -gt 0) {
    Write-Host '[lean] lake build（mathlib 钉版 F:/github/mathlib4，v4.21.0-rc3）...'
    Push-Location $leanDir
    try {
        $out = & lake build 2>&1 | Out-String
        $code = $LASTEXITCODE
        $leanBuilt = ($code -eq 0 -and $out -notmatch '(?m)^(error|warning)[: ]')
        Add-Result 'lean' 'lean' 'lake build 整工程' $leanBuilt ($out -split "`n" | Select-Object -Last 5)
        if (-not $leanBuilt) { Write-Host $out }
        # 逐章点亮（文件存在即视为该章有 lean 单元；构建失败已在上面记账）
        foreach ($ch in $leanChapters | Sort-Object -Unique) {
            if (Test-ChapterWanted $ch) {
                Add-Result $ch 'lean' "Settheory/Ch$ch*.lean" $leanBuilt ''
            }
        }
    } finally { Pop-Location }
}

# --- isabelle：逐会话 ---
if ($wantLangs -contains 'isabelle') {
    foreach ($s in $isaSessions | Sort-Object Chapter) {
        if (-not (Test-ChapterWanted $s.Chapter)) { continue }
        $isaDirW = (Join-Path $examples 'isabelle') -replace '\\', '/'
        $isaCygDir = '/cygdrive/' + $isaDirW.Substring(0, 1).ToLower() + $isaDirW.Substring(2)
        Write-Host "[isabelle] build $($s.Session)..."
        $out = & pwsh -NoProfile -Command "& '$isaBash' -lc '$isaCygBin build -d $isaCygDir $($s.Session)'" 2>&1 | Out-String
        $code = $LASTEXITCODE
        $ok = ($code -eq 0 -and $out -notmatch '(?i)failed')
        Add-Result $s.Chapter 'isabelle' $s.Session $ok ($out -split "`n" | Select-Object -Last 5)
        if (-not $ok) { Write-Host $out }
    }
}

# --- coq：逐文件 ---
if ($wantLangs -contains 'coq') {
    # coqc 9.1 需要自身 bin 在 PATH 上（否则工作进程 DLL 解析失败）
    $env:PATH = (Split-Path $coqc) + ';' + $env:PATH
    $coqDir = Join-Path $examples 'coq'
    foreach ($u in $coqUnits | Sort-Object Chapter, Path) {
        if (-not (Test-ChapterWanted $u.Chapter)) { continue }
        Write-Host "[coq] $($u.Path)"
        $out = & $coqc -Q $coqDir Settheory $u.Path 2>&1 | Out-String
        $ok = ($LASTEXITCODE -eq 0)
        Add-Result $u.Chapter 'coq' (Split-Path -Leaf $u.Path) $ok ($out -split "`n" | Select-Object -Last 5)
        if (-not $ok) { Write-Host $out }
    }
}

# --- agda：逐文件 ---
if ($wantLangs -contains 'agda') {
    $agdaExe = 'E:\lang\Agda-v2.8.0.2-win64\agda.exe'
    $agdaStdlib = 'E:\github\agda\std-lib\src'
    $agdaDir = Join-Path $examples 'agda'
    foreach ($u in $agdaUnits | Sort-Object Chapter, Path) {
        if (-not (Test-ChapterWanted $u.Chapter)) { continue }
        Write-Host "[agda] $($u.Path)"
        $out = & $agdaExe -i $agdaStdlib -i $agdaDir $u.Path 2>&1 | Out-String
        $ok = ($LASTEXITCODE -eq 0)
        Add-Result $u.Chapter 'agda' (Split-Path -Leaf $u.Path) $ok ($out -split "`n" | Select-Object -Last 5)
        if (-not $ok) { Write-Host $out }
    }
}

# --- julia：逐文件 ---
if ($wantLangs -contains 'julia') {
    foreach ($u in $juliaUnits | Sort-Object Chapter, Path) {
        if (-not (Test-ChapterWanted $u.Chapter)) { continue }
        Write-Host "[julia] $($u.Path)"
        $out = & julia --startup-file=no $u.Path 2>&1 | Out-String
        $ok = ($LASTEXITCODE -eq 0 -and $out -match "(?m)^==== $($u.Chapter)(?![0-9])" -and $out -match 'END ====')
        Add-Result $u.Chapter 'julia' (Split-Path -Leaf $u.Path) $ok ($out -split "`n" | Select-Object -Last 5)
        if (-not $ok) { Write-Host $out }
    }
}

# --- python：逐文件 ---
if ($wantLangs -contains 'python') {
    $env:PYTHONIOENCODING = 'utf-8'
    foreach ($u in $pyUnits | Sort-Object Chapter, Path) {
        if (-not (Test-ChapterWanted $u.Chapter)) { continue }
        Write-Host "[python] $($u.Path)"
        $out = & $pyExe -I $u.Path 2>&1 | Out-String
        $ok = ($LASTEXITCODE -eq 0 -and $out -match "(?m)^==== $($u.Chapter)(?![0-9])" -and $out -match 'END ====')
        Add-Result $u.Chapter 'python' (Split-Path -Leaf $u.Path) $ok ($out -split "`n" | Select-Object -Last 5)
        if (-not $ok) { Write-Host $out }
    }
}

# --- prolog：逐文件（SWI 主） ---
if ($wantLangs -contains 'prolog') {
    foreach ($u in $plUnits | Sort-Object Chapter, Path) {
        if (-not (Test-ChapterWanted $u.Chapter)) { continue }
        Write-Host "[prolog] $($u.Path)"
        $out = & swipl -q -f $u.Path -g main -t halt 2>&1 | Out-String
        $ok = ($LASTEXITCODE -eq 0 -and $out -match 'END ====')
        Add-Result $u.Chapter 'prolog' (Split-Path -Leaf $u.Path) $ok ($out -split "`n" | Select-Object -Last 5)
        if (-not $ok) { Write-Host $out }
    }
}

# ---------- 报告 ----------
Write-Host ''
Write-Host '================ 对账报告 ================'
$results | Format-Table Chapter, Lang, Status, Desc -AutoSize
$total = $results.Count
$pass = ($results | Where-Object Status -eq 'PASS').Count
Write-Host "总计 $total 单元：PASS $pass / FAIL $($total - $pass)"
if ($fail -gt 0) { exit 1 } else { Write-Host '全绿。'; exit 0 }
