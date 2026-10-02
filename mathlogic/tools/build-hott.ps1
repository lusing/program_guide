#Requires -Version 7
<#
    Coq-HoTT 库全量构建（Rocq Platform 9.1 coqc）。
    绕开上游 CRLF Makefile：coqdep 生成依赖 + Kahn 拓扑排序 + 串行编译。
    已存在的 .vo 跳过（断点续编）。
#>
$ErrorActionPreference = 'Stop'
$hott = 'G:\github\misc\Coq-HoTT'
$bin  = 'G:\rocq\Rocq-Platform~9.1~2026.01\bin'
Set-Location $hott

$files = Get-ChildItem theories -Recurse -Filter *.v |
    ForEach-Object { $_.FullName.Substring($hott.Length + 1) -replace '\\', '/' }
Write-Host "共 $($files.Count) 个 .v 文件，运行 coqdep ..."
$depText = & "$bin\coqdep.exe" -R theories HoTT @files 2>&1 | Out-String

$depMap = @{}
foreach ($line in ($depText -split "`n")) {
    if ($line -match '^\s*([^:]+):\s*(.*)$') {
        $lhs = $Matches[1].Trim()
        $voT = ($lhs -split '\s+' | Where-Object { $_ -like '*.vo' } | Select-Object -First 1)
        if ($voT) {
            $deps = @($Matches[2].Trim() -split '\s+' | Where-Object { $_ -like '*.vo' })
            $depMap[$voT] = $deps
        }
    }
}
Write-Host "依赖图节点数: $($depMap.Count)"

# Kahn 拓扑排序
$indeg = @{}
foreach ($k in $depMap.Keys) { $indeg[$k] = 0 }
foreach ($k in $depMap.Keys) {
    foreach ($d in $depMap[$k]) { if ($depMap.ContainsKey($d)) { $indeg[$k]++ } }
}
$queue = [System.Collections.Generic.Queue[string]]::new()
foreach ($k in $indeg.Keys) { if ($indeg[$k] -eq 0) { $queue.Enqueue($k) } }
$order = [System.Collections.Generic.List[string]]::new()
while ($queue.Count -gt 0) {
    $k = $queue.Dequeue()
    $order.Add($k)
    foreach ($o in $depMap.Keys) {
        if ($depMap[$o] -contains $k) {
            $indeg[$o]--
            if ($indeg[$o] -eq 0) { $queue.Enqueue($o) }
        }
    }
}
if ($order.Count -ne $depMap.Count) {
    Write-Host "拓扑排序不完整（环？）: $($order.Count)/$($depMap.Count)"; exit 1
}

$i = 0; $built = 0; $skip = 0; $fail = 0
foreach ($vo in $order) {
    $v = $vo -replace '\.vo$', '.v'
    $voPath = Join-Path $hott ($vo -replace '/', '\')
    if (Test-Path $voPath) { $skip++; continue }
    $i++
    $out = & "$bin\coqc.exe" -q -noinit -indices-matter -R theories HoTT $v 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0 -or $out -match '(?m)^Error') {
        Write-Host "FAIL: $v"; Write-Host ($out -split "`n" | Select-Object -First 15)
        $fail++; break
    }
    $built++
    if ($built % 50 -eq 0) { Write-Host "进度: $built 编译 / $skip 跳过 / 共 $($order.Count)" }
}
Write-Host "HOTT_BUILD_DONE total=$($order.Count) built=$built skip=$skip fail=$fail"
if ($fail -gt 0) { exit 1 } else { exit 0 }
