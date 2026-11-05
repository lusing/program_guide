#Requires -Version 7
<#
    Evans 偏微分方程教程验证脚本：五通道 lean / julia / python / prolog / fortran。

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
                 报告时把 Evanspde/ChNN*.lean 逐章点亮。
      julia    : `julia --startup-file=no NN_xxx.jl`，退出码 0 且
                 stdout 含 "==== NN" 与 "END ====" 标记。
      python   : python313（scoop current 3.15 的 numpy 坏——measuretheory 前科，
                 直接用 G:\scoop\apps\python313\current），`python -I NN_xxx.py`，
                 退出码 0 且标记齐全（PYTHONIOENCODING=utf-8 防控制台代码页坑；
                 -I 模式下实际不吃该变量，故 Python 文件输出保持纯 ASCII）。
      prolog   : 本机 SWI-Prolog（swipl -q -f 文件 -g main -t halt），
                 退出码 0 且 stdout 含 "END ===="。
      fortran  : LLVM flang 编译 NN_*.f90 → build/fortran/NN_*.exe 再运行
                 （Windows 上 flang 链接须补 compiler-rt builtins——fortran/
                 教程前科），退出码 0 且标记齐全。
#>
param(
    [switch]$All,
    [string[]]$Chapter = @(),
    [string]$Lang = "",
    [switch]$List,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$examples = Join-Path $root 'examples'
$buildDir = Join-Path $root 'build'

# 工具定位
$python313 = 'G:\scoop\apps\python313\current\python.exe'
$flang = (Get-Command flang -ErrorAction SilentlyContinue).Source
# Windows 上 LLVM 版 flang 的运行时库引用了 128 位转换例程（__floattidf 等），
# 链接时必须补上 compiler-rt builtins（fortran/ 教程前科）。
$flangRtLib = ""
if ($flang) {
    $flangDir = Split-Path -Parent $flang
    $hit = Get-ChildItem -Path (Join-Path $flangDir "..\lib\clang\*\lib\windows\clang_rt.builtins-x86_64.lib") `
                        -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { $flangRtLib = $hit.FullName }
}

# ---------- 清理 ----------
if ($Clean) {
    if (Test-Path $buildDir) { Remove-Item -Recurse -Force $buildDir }
    Write-Host '[Clean] 已清理 build/。'
    exit 0
}

# ---------- 发现验证单元 ----------
# lean：整工程 + 逐章文件点亮
$leanDir = Join-Path $examples 'lean'
$leanChapters = Get-ChildItem (Join-Path $leanDir 'Evanspde') -Filter 'Ch*.lean' -ErrorAction SilentlyContinue |
    ForEach-Object { ($_.BaseName -replace '^Ch(\d\d).*$', '$1') }

# julia / python / prolog / fortran：按文件名前缀发现
function Find-ChannelUnits($sub, $pattern) {
    $d = Join-Path $examples $sub
    if (-not (Test-Path $d)) { return @() }
    Get-ChildItem $d -Filter $pattern -File | ForEach-Object {
        [pscustomobject]@{ Chapter = ($_.BaseName -replace '^(\d\d).*$', '$1'); Path = $_.FullName }
    }
}
$juliaUnits = Find-ChannelUnits 'julia' '*.jl'
$pyUnits = Find-ChannelUnits 'python' '*.py'
$plUnits = Find-ChannelUnits 'prolog' '*.pl'
$ftUnits = Find-ChannelUnits 'fortran' '*.f90'

$allChapters = (@($leanChapters) + $juliaUnits.Chapter + $pyUnits.Chapter + $plUnits.Chapter + $ftUnits.Chapter) |
    Sort-Object -Unique

# ---------- 过滤 ----------
# 坑（measuretheory 前科）：① 参数模式 `-Chapter 01,02` 的逗号数组元素走表达式解析，
# 01 被规整成整数 1 丢零，必须补零；② `-replace` 与 `-f` 同行且不加括号时为 no-op，禁用。
$wantChapters = if ($Chapter.Count -gt 0) {
    @($Chapter | ForEach-Object { if ($_ -match '^\d+$') { '{0:D2}' -f [int]$_ } else { $_ } })
} else { @() }
$wantLangs = if ($Lang) { @($Lang.ToLower()) } else { @('lean', 'julia', 'python', 'prolog', 'fortran') }

function Test-ChapterWanted($ch) {
    if ($wantChapters.Count -eq 0) { return $true }
    return ($wantChapters -contains $ch)
}

# ---------- 列出 ----------
if ($List) {
    Write-Host '章 × 通道矩阵（文件存在即预期验证）：'
    foreach ($ch in ($allChapters | Where-Object { Test-ChapterWanted $_ })) {
        $row = [ordered]@{ 章 = $ch }
        $row.lean = if ($leanChapters -contains $ch) { 'x' } else { '' }
        $row.julia = if ($juliaUnits.Chapter -contains $ch) { 'x' } else { '' }
        $row.python = if ($pyUnits.Chapter -contains $ch) { 'x' } else { '' }
        $row.prolog = if ($plUnits.Chapter -contains $ch) { 'x' } else { '' }
        $row.fortran = if ($ftUnits.Chapter -contains $ch) { 'x' } else { '' }
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

# --- julia / python / prolog：逐文件 ---
function Invoke-ScriptUnit($units, $langName, $invoker) {
    # 空通道目录时 Find-ChannelUnits 返回空，$null 管进 Where-Object 会
    # 透出一个 null 单元（measuretheory B0 实测前科），先守卫
    if (-not $units) { return }
    foreach ($u in @($units) | Where-Object { $_ -and (Test-ChapterWanted $_.Chapter) }) {
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
    Invoke-ScriptUnit $pyUnits 'python' { param($p) & $python313 -I $p }
}
if ($wantLangs -contains 'prolog') {
    Invoke-ScriptUnit $plUnits 'prolog' { param($p) & swipl -q -f $p -g main -t halt }
}

# --- fortran：编译 + 运行 ---
if ($wantLangs -contains 'fortran' -and $flang) {
    $ftBuild = Join-Path $buildDir 'fortran'
    New-Item -ItemType Directory -Force $ftBuild | Out-Null
    foreach ($u in @($ftUnits) | Where-Object { $_ -and (Test-ChapterWanted $_.Chapter) }) {
        $name = [IO.Path]::GetFileNameWithoutExtension($u.Path)
        $exe = Join-Path $ftBuild "$name.exe"
        Write-Host "`n[fortran] $name.f90"
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $args = @($u.Path, '-o', $exe)
        if ($flangRtLib) { $args += $flangRtLib }
        $cout = & flang @args 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0) {
            Add-Result $u.Chapter 'fortran' $false "编译失败：$cout"
            Write-Host "[fortran] FAIL 编译失败" -ForegroundColor Red
            Write-Host $cout.Substring(0, [Math]::Min(2000, $cout.Length)) -ForegroundColor Red
            continue
        }
        $out = & $exe 2>&1 | Out-String
        $code = $LASTEXITCODE
        $ch2 = $u.Chapter
        $ok = ($code -eq 0) -and ($out -match "==== $ch2") -and ($out -match 'END ====')
        Add-Result $u.Chapter 'fortran' $ok $out
        Write-Host ("[fortran] {0}（{1:N1}s）" -f $(if ($ok) { 'PASS' } else { 'FAIL' }), $sw.Elapsed.TotalSeconds)
        if (-not $ok) { Write-Host $out.Substring(0, [Math]::Min(3000, $out.Length)) -ForegroundColor Red }
    }
}

# ---------- 汇总 ----------
$swOverall.Stop()
Write-Host "`n========== 验证报告 =========="
if ($results.Count -gt 0) {
    # 透视成 章 × 通道 矩阵
    $matrix = $results | Group-Object 章 | Sort-Object Name | ForEach-Object {
        $row = [ordered]@{ 章 = $_.Name }
        foreach ($l in 'lean', 'julia', 'python', 'prolog', 'fortran') {
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

