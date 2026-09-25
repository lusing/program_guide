#Requires -Version 7
<#
    Coq-HoTT 教程验证脚本（PowerShell 版）。

    用法:
      pwsh -NoProfile -Command '& ./build.ps1 -All'
      pwsh -NoProfile -Command '& ./build.ps1 -File 03_dependent_types.v'
      pwsh -NoProfile -Command '& ./build.ps1 -Clean'

    判定标准与 run-all.sh 逐项一致:
      1. coqc 退出码 0
      2. stderr 为空（0 字节）
      3. sec_NN_BEGIN / sec_NN_END 各恰好出现一次（整行严格相等）
      4. 区间非空
      5. 区间无控制字符
      6. 连跑两遍，区间逐字节一致
      7. 目标数 > 0（通过 0 视为失败）

    注意（macOS 上的实测坑）:
      - pwsh 7 下 `pwsh -File x.ps1` 会报 procargs errno 5，必须用 -Command '& ./x.ps1'。
      - 写 .out/.err 必须用 [IO.File]::WriteAllText：WriteAllLines 写空串会留下 1 字节换行，
        会让「stderr 为空」这条判据恒为假。
      - 目录筛选不能用 -Filter '[0-9]*'（FileSystem provider 下匹配不到任何目录），
        用 Where-Object { $_.Name -match '^\d\d_' }。
#>
param(
    [switch]$All,
    [string]$File,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$HottSrc = if ($env:HOTT_SRC) { $env:HOTT_SRC } else { '/Volumes/mac004/lang/Coq-HoTT' }
$examplesDir = Join-Path $projectRoot 'examples'
$buildDir    = Join-Path $projectRoot 'build'
$run1        = Join-Path $buildDir 'run1'
$run2        = Join-Path $buildDir 'run2'
$outDir      = Join-Path $buildDir 'out-ps'
$TimeoutMs   = 120000

# ---------- 清理 ----------
if ($Clean) {
    foreach ($d in @($run1, $run2, $outDir)) {
        if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force }
    }
    Write-Host '[Clean] 已清理 PowerShell 验证产物。' -ForegroundColor Yellow
    exit 0
}

# ---------- 工具探测 ----------
function Find-Tool {
    param([string]$Name)
    if ($env:COQBIN) {
        $cand = Join-Path $env:COQBIN $Name
        if (Test-Path -LiteralPath $cand) { return $cand }
    }
    foreach ($dir in @('/opt/local/bin', '/usr/local/bin', '/usr/bin')) {
        $cand = Join-Path $dir $Name
        if (Test-Path -LiteralPath $cand) { return $cand }
    }
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

$script:Coqc = Find-Tool 'coqc'
if (-not $script:Coqc) { throw '找不到 coqc，请用 $env:COQBIN 指定所在目录。' }

if (-not (Test-Path -LiteralPath (Join-Path $HottSrc 'theories/HoTT.vo'))) {
    throw "HoTT 库尚未构建（缺少 $HottSrc/theories/HoTT.vo），请先运行 ./build-hott.sh"
}

# ---------- 目标收集 ----------
if (-not (Test-Path -LiteralPath $examplesDir)) { throw "找不到 examples 目录：$examplesDir" }

if ($File) {
    $targets = @(Get-ChildItem -Path $examplesDir -File | Where-Object { $_.Name -eq $File })
} else {
    # 注意：不能用 -Filter '[0-9]*'，FileSystem provider 下它匹配不到任何文件。
    $targets = @(Get-ChildItem -Path $examplesDir -File |
                 Where-Object { $_.Name -match '^\d\d_.*\.v$' } |
                 Sort-Object Name)
}

if ($targets.Count -eq 0) {
    throw '没有找到任何示例文件（目标数 0）——不要把它当成「通过」。'
}

Write-Host "[Info] 待验证示例 : $($targets.Count) 个"
Write-Host "[Info] coqc       : $script:Coqc"

foreach ($d in @($run1, $run2, $outDir)) {
    if (Test-Path -LiteralPath $d) { Remove-Item -LiteralPath $d -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $d | Out-Null
}

# ---------- 执行 coqc（带看门狗） ----------
function Invoke-Coqc {
    param([string]$WorkDir, [string]$Source)

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $script:Coqc
    foreach ($a in @('-q', '-noinit', '-indices-matter', '-R', (Join-Path $HottSrc 'theories'), 'HoTT', $Source)) {
        $psi.ArgumentList.Add($a)
    }
    $psi.WorkingDirectory = $WorkDir
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false

    $p = [System.Diagnostics.Process]::Start($psi)
    $out = $p.StandardOutput.ReadToEnd()
    $err = $p.StandardError.ReadToEnd()
    if (-not $p.WaitForExit($TimeoutMs)) {
        $p.Kill()
        $rc = 137          # 与 shell 版 timeout -s KILL 对齐
    } else {
        $rc = $p.ExitCode
    }
    return @{ Rc = $rc; Out = $out; Err = $err }
}

function Write-TextFile {
    param([string]$Path, [string]$Content)
    # 必须原样写：WriteAllLines 写空字符串会留下 1 个字节的换行。
    [System.IO.File]::WriteAllText($Path, $Content)
}

$pass = 0
$fail = 0
$failedList = @()

foreach ($src in $targets) {
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($src.Name)
    $nn   = ($stem -split '_')[0]
    $ex   = "ex_$($src.Name)"
    $bmark = "sec_${nn}_BEGIN"
    $emark = "sec_${nn}_END"

    Copy-Item -LiteralPath $src.FullName -Destination (Join-Path $run1 $ex) -Force
    Copy-Item -LiteralPath $src.FullName -Destination (Join-Path $run2 $ex) -Force

    $r1 = Invoke-Coqc -WorkDir $run1 -Source $ex
    $r2 = Invoke-Coqc -WorkDir $run2 -Source $ex

    $o1 = Join-Path $outDir "$nn.run1.out"; $e1 = Join-Path $outDir "$nn.run1.err"
    $o2 = Join-Path $outDir "$nn.run2.out"; $e2 = Join-Path $outDir "$nn.run2.err"
    Write-TextFile $o1 $r1.Out; Write-TextFile $e1 $r1.Err
    Write-TextFile $o2 $r2.Out; Write-TextFile $e2 $r2.Err

    $err1Bytes = (Get-Item -LiteralPath $e1).Length
    $err2Bytes = (Get-Item -LiteralPath $e2).Length

    # 整行严格匹配计数 + 抽取区间
    $lines1 = [System.IO.File]::ReadAllLines($o1)
    $bc = @($lines1 | Where-Object { $_ -eq $bmark }).Count
    $ec = @($lines1 | Where-Object { $_ -eq $emark }).Count

    $sec1 = @(); $inSec = $false
    foreach ($line in $lines1) {
        if ($line -eq $bmark) { $inSec = $true; continue }
        if ($line -eq $emark) { $inSec = $false; continue }
        if ($inSec) { $sec1 += $line }
    }
    $sec2 = @(); $inSec = $false
    foreach ($line in [System.IO.File]::ReadAllLines($o2)) {
        if ($line -eq $bmark) { $inSec = $true; continue }
        if ($line -eq $emark) { $inSec = $false; continue }
        if ($inSec) { $sec2 += $line }
    }

    $s1Path = Join-Path $outDir "$nn.sec1"
    $s2Path = Join-Path $outDir "$nn.sec2"
    Write-TextFile $s1Path (($sec1 -join "`n") + "`n")
    Write-TextFile $s2Path (($sec2 -join "`n") + "`n")

    $hasCtrl = ($sec1 | Where-Object { $_ -match '[\x00-\x08\x0B\x0C\x0E-\x1F]' }).Count -gt 0
    $same = ($sec1 -join "`n") -ceq ($sec2 -join "`n")

    $why = ''
    if ($r1.Rc -ne 0)        { $why += " 退出码(run1)=$($r1.Rc);" }
    if ($r2.Rc -ne 0)        { $why += " 退出码(run2)=$($r2.Rc);" }
    if ($err1Bytes -ne 0)    { $why += " stderr(run1)非空=${err1Bytes}B;" }
    if ($err2Bytes -ne 0)    { $why += " stderr(run2)非空=${err2Bytes}B;" }
    if ($bc -ne 1)           { $why += " BEGIN标记出现${bc}次(应为1);" }
    if ($ec -ne 1)           { $why += " END标记出现${ec}次(应为1);" }
    if ($sec1.Count -eq 0)   { $why += ' 区间为空;' }
    if ($hasCtrl)            { $why += ' 区间含控制字符;' }
    if (-not $same)          { $why += ' 两遍区间不一致;' }

    if ($why -eq '') {
        Write-Host ("  通过  {0,-28} 区间 {1,4} 行" -f $stem, $sec1.Count)
        $pass++
    } else {
        Write-Host ("  失败  {0,-28} {1}" -f $stem, $why) -ForegroundColor Red
        $fail++
        $failedList += $stem
    }
}

Write-Host '------------------------------------------------------------'
Write-Host "通过 $pass 个，失败 $fail 个"
if ($pass -eq 0) { throw '一个都没通过（通过 0）——检查脚本或环境，不要当成干净。' }
if ($fail -ne 0) { throw "失败列表：$($failedList -join ', ')" }
Write-Host '全部示例验证通过。' -ForegroundColor Green
