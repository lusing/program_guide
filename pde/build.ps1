#Requires -Version 7
<#
    偏微分方程三部合一教程验证脚本：五通道 lean / julia / python / prolog / fortran。

    三篇并存：
      理论篇（Evans）：  docs/          + examples/t-*
      数值篇（陆金甫）： docs-numeric/  + examples/n-*
      习题篇（沙马耶夫）：docs-problems/ + examples/p-*

    用法:
      pwsh -NoProfile -Command '& ./build.ps1 -All'
      pwsh -NoProfile -Command '& ./build.ps1 -Part theory|numeric|problems'
      pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'
      pwsh -NoProfile -Command '& ./build.ps1 -List' / -Clean

    通道判定:
      lean     : examples/lean 单一 lake 工程（Evanspde + Pdenum 双命名空间），
                 `lake build` 退出码 0 且无 error:/warning:；逐章点亮两个目录。
      julia    : examples/{t,n,p}-julia 下 `julia --startup-file=no <file>`，
                 退出码 0 且 stdout 含 "==== NN" 与 "END ===="。
      python   : python313 `-I`，纯 ASCII 输出，标记齐全。
      prolog   : swipl -q -f <file> -g main -t halt，stdout 含 "END ===="。
      fortran  : flang 编译 → build/fortran/<相对路径>.exe（builtins 链接补丁）。
#>
param(
    [switch]$All,
    [string[]]$Chapter = @(),
    [string]$Lang = "",
    [string]$Part = "",
    [switch]$List,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$examples = Join-Path $root 'examples'
$buildDir = Join-Path $root 'build'

$python313 = 'G:\scoop\apps\python313\current\python.exe'
$flang = (Get-Command flang -ErrorAction SilentlyContinue).Source
$flangRtLib = ""
if ($flang) {
    $flangDir = Split-Path -Parent $flang
    $hit = Get-ChildItem -Path (Join-Path $flangDir "..\lib\clang\*\lib\windows\clang_rt.builtins-x86_64.lib") `
                        -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { $flangRtLib = $hit.FullName }
}

if ($Clean) {
    if (Test-Path $buildDir) { Remove-Item -Recurse -Force $buildDir }
    Write-Host '[Clean] 已清理 build/。'
    exit 0
}

# ---------- 发现验证单元 ----------
$leanDir = Join-Path $examples 'lean'
$leanChapters = @()
foreach ($ns in 'Evanspde', 'Pdenum') {
    Get-ChildItem (Join-Path $leanDir $ns) -Filter 'Ch*.lean' -ErrorAction SilentlyContinue | ForEach-Object {
        $leanChapters += [pscustomobject]@{
            Id   = "$ns/$($_.BaseName)"
            Part = if ($ns -eq 'Evanspde') { 'theory' } else { 'numeric' }
        }
    }
}

function Find-ChannelUnits($sub) {
    $d = Join-Path $examples $sub
    if (-not (Test-Path $d)) { return @() }
    Get-ChildItem $d -Filter '*.jl' -File -ErrorAction SilentlyContinue | ForEach-Object {
        [pscustomobject]@{ Id = "$sub/$($_.Name)"; Part = ($sub.Substring(0,1) -replace 't','theory' -replace 'n','numeric' -replace 'p','problems') }
    }
}
# 通用扫描（按扩展名）
function Find-Units($ext, $runner) {
    Get-ChildItem $examples -Directory | Where-Object { $_.Name -match '^[tnp]-(julia|python|prolog|fortran)$' -and $_.Name.EndsWith($runner) } | ForEach-Object {
        $sub = $_.Name
        Get-ChildItem $_.FullName -Filter "*$ext" -File | ForEach-Object {
            [pscustomobject]@{
                Id = "$sub/$($_.Name)"
                Part = @{ 't' = 'theory'; 'n' = 'numeric'; 'p' = 'problems' }[$sub.Substring(0,1)]
            }
        }
    }
}

$juliaUnits = Find-Units '.jl' 'julia'
$pyUnits = Find-Units '.py' 'python'
$plUnits = Find-Units '.pl' 'prolog'
$ftUnits = Find-Units '.f90' 'fortran'

$wantLangs = if ($Lang) { @($Lang.ToLower()) } else { @('lean', 'julia', 'python', 'prolog', 'fortran') }
$wantParts = if ($Part) { @($Part.ToLower()) } else { @('theory', 'numeric', 'problems') }

# ---------- 列出 ----------
if ($List) {
    Write-Host '篇 × 通道矩阵：'
    $all = @($leanChapters) + $juliaUnits + $pyUnits + $plUnits + $ftUnits
    $all | Group-Object Part | ForEach-Object {
        Write-Host ("== {0}: {1} 单元" -f $_.Name, $_.Count)
        $_.Group | ForEach-Object { Write-Host "   $($_.Id)" }
    }
    exit 0
}

# ---------- 通道执行 ----------
$results = [System.Collections.Generic.List[object]]::new()
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Result($part, $lang, $ok, $detail = '') {
    $script:results.Add([pscustomobject]@{
        篇 = $part; 通道 = $lang; 结果 = if ($ok) { 'PASS' } else { 'FAIL' }
        单元 = $detail
    })
    if (-not $ok) { $script:failures.Add("[$part/$lang] $detail") }
}

# lean（整工程一次构建，按章点亮）
if ($wantLangs -contains 'lean') {
    Push-Location $leanDir
    $out = lake build 2>&1 | Out-String
    $code = $LASTEXITCODE
    Pop-Location
    $leanOk = ($code -eq 0) -and ($out -notmatch 'error:') -and ($out -notmatch 'warning:')
    foreach ($ch in $leanChapters | Where-Object { $wantParts -contains $_.Part }) {
        Add-Result $_.Part 'lean' $leanOk $_.Id
    }
    if (-not $leanOk) { Write-Host $out.Substring(0, [Math]::Min(3000, $out.Length)) }
}

function Invoke-ScriptUnits($units, $lang, $invoke) {
    foreach ($u in $units | Where-Object { $wantParts -contains $_.Part }) {
        $path = Join-Path $examples $u.Id
        $out = & $invoke $path 2>&1 | Out-String
        $code = $LASTEXITCODE
        $ok = ($code -eq 0) -and ($out -match 'END ====')
        Add-Result $u.Part $lang $ok $u.Id
        if (-not $ok) {
            Write-Host "--- FAIL $($u.Id) ---"
            Write-Host $out.Substring(0, [Math]::Min(1500, $out.Length))
        }
    }
}

if ($wantLangs -contains 'julia') {
    Invoke-ScriptUnits $juliaUnits 'julia' { param($p) julia --startup-file=no $p }
}
if ($wantLangs -contains 'python') {
    Invoke-ScriptUnits $pyUnits 'python' { param($p) & $python313 -I $p }
}
if ($wantLangs -contains 'prolog') {
    Invoke-ScriptUnits $plUnits 'prolog' { param($p) swipl -q -f $p -g main -t halt }
}
if ($wantLangs -contains 'fortran') {
    foreach ($u in $ftUnits | Where-Object { $wantParts -contains $_.Part }) {
        $src = Join-Path $examples $u.Id
        $exe = Join-Path $buildDir ("fortran/" + ($u.Id -replace '/', '_') + ".exe")
        New-Item -ItemType Directory -Force (Split-Path $exe) | Out-Null
        $args_ = @($src, '-o', $exe)
        if ($flangRtLib) { $args_ += $flangRtLib }
        & flang @args_ 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $exe)) {
            Add-Result $u.Part 'fortran' $false $u.Id
            continue
        }
        $out = & $exe 2>&1 | Out-String
        $ok = ($LASTEXITCODE -eq 0) -and ($out -match 'END ====')
        Add-Result $u.Part 'fortran' $ok $u.Id
        if (-not $ok) { Write-Host "--- FAIL $($u.Id) ---"; Write-Host $out }
    }
}

# ---------- 报告 ----------
Write-Host ''
Write-Host '========== 验证报告 =========='
$byPart = $results | Group-Object 篇 | Sort-Object Name
foreach ($g in $byPart) {
    Write-Host ("—— {0}（{1} 单元）" -f $g.Name, $g.Count)
    $g.Group | Group-Object 通道 | ForEach-Object {
        $pass = ($_.Group | Where-Object 结果 -eq 'PASS').Count
        Write-Host ("   {0}: {1}/{2}" -f $_.Name, $pass, $_.Count)
    }
}
$total = $results.Count
$passN = ($results | Where-Object 结果 -eq 'PASS').Count
Write-Host ''
if ($failures.Count -gt 0) {
    Write-Host ("合计 $total 单元：PASS $passN，FAIL $($total - $passN)")
    $failures | ForEach-Object { Write-Host "  FAIL: $_" }
    exit 1
} else {
    Write-Host ("合计 $total 单元：PASS $passN，FAIL 0")
}
