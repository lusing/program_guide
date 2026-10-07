#Requires -Version 7
<#
    mathlogic 教程验证脚本：七通道 Coq / HoTT / Agda / Lean / Isabelle / HOL4 / Prolog。

    用法:
      pwsh -NoProfile -Command '& ./build.ps1 -All'          全量验证
      pwsh -NoProfile -Command '& ./build.ps1 -Chapter 01'    只验一章（章号或目录名）
      pwsh -NoProfile -Command '& ./build.ps1 -Lang coq'      只验一种语言
      pwsh -NoProfile -Command '& ./build.ps1 -File <path>'   只验一个文件
      pwsh -NoProfile -Command '& ./build.ps1 -List'          列出全部验证单元
      pwsh -NoProfile -Command '& ./build.ps1 -Clean'         清理产物

    通道判定:
      coq      : Rocq Platform 9.1（G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe，
                 原 scoop coqc 8.20 已弃用）拷贝到 build/coq/ex_*.v 后 `coqc -q`
                 （数字开头模块名不收，故加 ex_ 前缀），退出码 0 且无 Error；
                 deprecated 类 Warning 容忍。
      hott     : Rocq Platform 9.1 coqc，旗标 -q -noinit -indices-matter
                 -R G:\github\misc\Coq-HoTT\theories HoTT（依赖后台全量构建的 .vo）；
                 退出码 0 且无 Error。库未构建时整通道 SKIP。
      agda     : WSL Ubuntu-26.04 `agda -i stdlib -i .`，退出码 0 且无 error/warning。
      lean     : `lean 文件`，退出码 0 且无 error:/warning:。
      isabelle : 每章一个会话（examples/ROOT 里 session MLNN in "NN_dir"），
                 经 G:\xulun3\Isabelle2025-2 自带 Cygwin 调
                 `isabelle build -d <examples> MLNN`；退出码 0 且无 Failed。
      hol4     : WSL Ubuntu-26.04 `~/hol4-src/bin/hol run 文件`（timeout 120 看门狗），
                 退出码 0 且输出含 [OK] 标记、无 uncaught exception。
                 HOL4 未构建时整通道 SKIP。
      prolog   : 本机 SWI-Prolog 10（G:\scoop\apps\swipl\current），
                 `swipl -q -f 文件 -g main -t halt`；退出码 0 且 stdout 含
                 「END ====」ASCII 标记（源文件须首行 :- encoding(utf8)，
                 运行期输出纯 ASCII——Windows 下 SWI 默认 GBK 读源/控制台
                 代码页写出的双重坑；单引擎简化协议，WSL gprolog 留作
                 跨引擎抽查，不进 CI）。

    SKIP 不是失败：等 tools/build-hol4.sh / tools/build-hott.ps1 完成后自动纳入。
#>
param(
    [switch]$All,
    [string]$Chapter,
    [string]$Lang,
    [string]$File,
    [switch]$List,
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$examples = Join-Path $root 'examples'
$buildDir = Join-Path $root 'build'

# 各通道工具与常量
$coqBuild = Join-Path $buildDir 'coq'
$hottBuild = Join-Path $buildDir 'hott'
$wslDistro = 'Ubuntu-26.04'
$agdaStdlib = '/usr/share/agda-stdlib/src'
$hottTheories = 'G:\github\misc\Coq-HoTT\theories'
$isaHome = 'G:\xulun3\Isabelle2025-2'
$isaBash = Join-Path $isaHome 'contrib\cygwin\bin\bash.exe'
$hol4Bin = '~/hol4-src/bin/hol'

# ---------- 清理 ----------
if ($Clean) {
    if (Test-Path $buildDir) { Remove-Item -Recurse -Force $buildDir }
    Get-ChildItem $examples -Recurse -Include *.agdai,*.vo,*.vok,*.vos,*.glob,*.aux -File -ErrorAction SilentlyContinue |
        Remove-Item -Force
    Write-Host '[Clean] 已清理 build/ 与散落的编译产物。' -ForegroundColor Yellow
    exit 0
}

# ---------- 收集验证单元 ----------
$units = Get-ChildItem $examples -Directory | Sort-Object Name | ForEach-Object {
    $dir = $_
    Get-ChildItem $dir.FullName -File | Where-Object {
        $_.Extension -in '.v', '.agda', '.lean', '.thy', '.sml', '.pl'
    } | ForEach-Object {
        $f = $_
        $tool = if ($f.Name -like '*_hott.v') { 'hott' }
                elseif ($f.Extension -eq '.v') { 'coq' }
                elseif ($f.Extension -eq '.agda') { 'agda' }
                elseif ($f.Extension -eq '.lean') { 'lean' }
                elseif ($f.Extension -eq '.thy') { 'isabelle' }
                elseif ($f.Extension -eq '.sml') { 'hol4' }
                elseif ($f.Extension -eq '.pl') { 'prolog' }
        [PSCustomObject]@{
            Chapter = $dir.Name
            Tool    = $tool
            Path    = $f.FullName
            Name    = $f.Name
        }
    }
}

if ($File) {
    $units = @($units | Where-Object { $_.Path -like "*$File*" })
}
if ($Chapter) {
    $units = @($units | Where-Object { $_.Chapter -eq $Chapter -or $_.Chapter.StartsWith($Chapter) })
}
if ($Lang) {
    $units = @($units | Where-Object { $_.Tool -eq $Lang.ToLower() })
}

if ($List) {
    $units | Format-Table Chapter, Tool, Name -AutoSize
    exit 0
}
if (-not $units -or $units.Count -eq 0) {
    throw '没有匹配的验证单元。'
}

# ---------- 通道可用性探测（一次） ----------
$hottReady = Test-Path (Join-Path $hottTheories 'HoTT.vo')
if (-not $hottReady) { Write-Host '[SKIP] HoTT 库尚未构建完（tools/build-hott.ps1），hott 通道本轮跳过。' -ForegroundColor Yellow }
$hol4Ready = $true
$probe = & wsl -d $wslDistro bash -lc "test -x $hol4Bin && echo YES || echo NO" 2>&1 | Out-String
if ($probe -notmatch 'YES') {
    $hol4Ready = $false
    Write-Host '[SKIP] HOL4 尚未构建完（tools/build-hol4.sh），hol4 通道本轮跳过。' -ForegroundColor Yellow
}

New-Item -ItemType Directory -Force -Path $coqBuild, $hottBuild | Out-Null
$fail = 0; $skip = 0
$i = 0
foreach ($u in $units) {
    $i++
    $tag = "[$i/$($units.Count)] $($u.Chapter)/$($u.Name)"
    $ok = $false; $skipped = $false
    $detail = ''; $out = ''
    try {
        switch ($u.Tool) {
            'coq' {
                $target = Join-Path $coqBuild ('ex_' + $u.Name)
                Copy-Item -LiteralPath $u.Path -Destination $target -Force
                $out = & 'G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe' -q $target 2>&1 | Out-String
                $ok = ($LASTEXITCODE -eq 0) -and -not ($out -match '(?m)^Error')
                if (-not $ok) { $detail = $out }
            }
            'hott' {
                if (-not $hottReady) { $skipped = $true; break }
                $target = Join-Path $hottBuild ('ex_' + $u.Name)
                Copy-Item -LiteralPath $u.Path -Destination $target -Force
                $isa = ($hottTheories -replace '\\', '/')
                $out = & 'G:\rocq\Rocq-Platform~9.1~2026.01\bin\coqc.exe' -q -noinit -indices-matter -R $isa HoTT $target 2>&1 | Out-String
                $ok = ($LASTEXITCODE -eq 0) -and -not ($out -match '(?m)^Error')
                if (-not $ok) { $detail = $out }
            }
            'lean' {
                $out = & lean $u.Path 2>&1 | Out-String
                $ok = ($LASTEXITCODE -eq 0) -and -not ($out -match 'error:|warning:')
                if (-not $ok) { $detail = $out }
            }
            'agda' {
                $dir = (Split-Path -Parent $u.Path) -replace '\\', '/'
                $wslDir = '/mnt/' + $dir.Substring(0, 1).ToLower() + $dir.Substring(2)
                $cmd = "cd '$wslDir' && agda -i $agdaStdlib -i . '$($u.Name)'"
                $out = & wsl -d $wslDistro bash -lc $cmd 2>&1 | Out-String
                $ok = ($LASTEXITCODE -eq 0) -and -not ($out -match 'error|warning')
                if (-not $ok) { $detail = $out }
            }
            'isabelle' {
                $sess = 'ML' + ($u.Chapter.Substring(0, 2))
                $exWin = ($examples -replace '\\', '/')
                $exCyg = '/cygdrive/' + $exWin.Substring(0, 1).ToLower() + $exWin.Substring(2)
                $isaWin = ($isaHome -replace '\\', '/')
                $isaCyg = '/cygdrive/' + $isaWin.Substring(0, 1).ToLower() + $isaWin.Substring(2)
                $cygCmd = "$isaCyg/bin/isabelle build -d $exCyg $sess"
                $out = & $isaBash -lc $cygCmd 2>&1 | Out-String
                $ok = ($LASTEXITCODE -eq 0) -and -not ($out -match '(?m)^.*failed')
                if (-not $ok) { $detail = $out }
            }
            'hol4' {
                if (-not $hol4Ready) { $skipped = $true; break }
                $hol4Build = Join-Path $buildDir 'hol4'
                New-Item -ItemType Directory -Force -Path $hol4Build | Out-Null
                Copy-Item -LiteralPath $u.Path -Destination (Join-Path $hol4Build $u.Name) -Force
                $win = ($hol4Build -replace '\\', '/')
                $wslDir = '/mnt/' + $win.Substring(0, 1).ToLower() + $win.Substring(2)
                $cmd = "cd '$wslDir' && timeout 120 $hol4Bin run '$($u.Name)'"
                $out = & wsl -d $wslDistro bash -lc $cmd 2>&1 | Out-String
                $ok = ($LASTEXITCODE -eq 0) -and ($out -match '\[OK\]') -and -not ($out -match 'uncaught exception')
                if (-not $ok) { $detail = $out }
            }
            'prolog' {
                $out = & 'G:\scoop\apps\swipl\current\bin\swipl.exe' -q -f $u.Path -g main -t halt 2>&1 | Out-String
                $ok = ($LASTEXITCODE -eq 0) -and ($out -match 'END ====')
                if (-not $ok) { $detail = $out }
            }
        }
    } catch {
        $ok = $false
        $detail = $_.Exception.Message
    }
    if ($skipped) {
        $skip++
        Write-Host "$tag SKIP" -ForegroundColor Yellow
    } elseif ($ok) {
        Write-Host "$tag OK" -ForegroundColor Green
    } else {
        $fail++
        Write-Host "$tag FAIL" -ForegroundColor Red
        if ($detail) { Write-Host ($detail.Trim() -split "`n" | Select-Object -First 25 | Out-String) }
        elseif ($out) { Write-Host ($out.Trim() -split "`n" | Select-Object -First 25 | Out-String) }
    }
}

$total = $units.Count
if ($fail -eq 0) {
    Write-Host "`n全部 $total 个验证单元通过（$skip 个 SKIP）。" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n$fail / $total 个验证单元失败（$skip 个 SKIP）。" -ForegroundColor Red
    exit 1
}
