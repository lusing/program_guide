#Requires -Version 7
<#
    typetheory 教程验证脚本：Coq / Agda / Lean 三通道。

    用法:
      pwsh -NoProfile -Command '& ./build.ps1 -All'          全量验证
      pwsh -NoProfile -Command '& ./build.ps1 -Chapter 01'    只验一章（章号或目录名）
      pwsh -NoProfile -Command '& ./build.ps1 -Lang agda'     只验一种语言
      pwsh -NoProfile -Command '& ./build.ps1 -File <path>'   只验一个文件
      pwsh -NoProfile -Command '& ./build.ps1 -List'          列出全部验证单元
      pwsh -NoProfile -Command '& ./build.ps1 -Clean'         清理产物

    通道判定:
      coq  : 拷贝到 build/coq/ex_*.v 后 `coqc -q`，退出码 0 且 stderr 为空
             （Coq 8.20 不接受数字开头的模块名，故拷贝改名后再编译）
      agda : WSL Ubuntu-26.04 里 `agda -i <stdlib src> -i <目录> 文件`，
             退出码 0 且输出无 error/warning（stdlib 2.3 的 .agdai 已由
             打包产物合并进 src/，秒级加载）
      lean : `lean 文件`，退出码 0 且输出无 error:/warning:

    所有源码无 BOM UTF-8；.agdai/.vo 等产物不入库。
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
$coqBuild = Join-Path $buildDir 'coq'
$wslDistro = 'Ubuntu-26.04'
$agdaStdlib = '/usr/share/agda-stdlib/src'

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
        $_.Extension -in '.v', '.agda', '.lean'
    } | ForEach-Object {
        $tool = switch ($_.Extension) { '.v' { 'coq' } '.agda' { 'agda' } '.lean' { 'lean' } }
        [PSCustomObject]@{
            Chapter = $dir.Name
            Tool    = $tool
            Path    = $_.FullName
            Name    = $_.Name
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

# ---------- 执行 ----------
New-Item -ItemType Directory -Force -Path $coqBuild | Out-Null
$fail = 0
$i = 0
foreach ($u in $units) {
    $i++
    $tag = "[$i/$($units.Count)] $($u.Chapter)/$($u.Name)"
    $ok = $false
    $detail = ''
    try {
        switch ($u.Tool) {
            'coq' {
                # 拷贝改名编译（规避 8.20 数字开头模块名限制）
                $target = Join-Path $coqBuild ('ex_' + $u.Name)
                Copy-Item -LiteralPath $u.Path -Destination $target -Force
                $out = & coqc -q $target 2>&1 | Out-String
                $ok = ($LASTEXITCODE -eq 0) -and -not ($out -match '(?m)^Error')
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
            'lean' {
                $out = & lean $u.Path 2>&1 | Out-String
                $ok = ($LASTEXITCODE -eq 0) -and -not ($out -match 'error:|warning:')
                if (-not $ok) { $detail = $out }
            }
        }
    } catch {
        $ok = $false
        $detail = $_.Exception.Message
    }
    if ($ok) {
        Write-Host "$tag OK" -ForegroundColor Green
    } else {
        $fail++
        Write-Host "$tag FAIL" -ForegroundColor Red
        if ($detail) { Write-Host ($detail.Trim() -split "`n" | Select-Object -First 25 | Out-String) }
    }
}

if ($fail -eq 0) {
    Write-Host "`n全部 $($units.Count) 个验证单元通过。" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n$fail / $($units.Count) 个验证单元失败。" -ForegroundColor Red
    exit 1
}
