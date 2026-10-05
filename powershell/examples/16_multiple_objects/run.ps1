#Requires -Version 5.1
# 示例 16：同时处理多个对象——数组参数、两种枚举、-Parallel、-WhatIf
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

$work = Join-Path $PSScriptRoot 'tmp-multi'
New-Item -ItemType Directory -Force -Path $work | Out-Null

# —— 1) 批处理参数：一条命令吃数组 ——
$files = 1..5 | ForEach-Object { $p = Join-Path $work "f$_.txt"; Set-Content -Path $p -Value $_ -Encoding UTF8; $p }
Check (@(Get-ChildItem $work -Filter '*.txt').Count -eq 5) '批量创建 5 个文件'
Remove-Item -Path $files
Check (@(Get-ChildItem $work -Filter '*.txt' -ErrorAction SilentlyContinue).Count -eq 0) '数组参数一条命令批删'

# —— 2) 枚举两形态：ForEach-Object 与 foreach 语句等价 ——
$viaPipe = 1..5 | ForEach-Object { $_ * 10 }
$viaStmt = foreach ($i in 1..5) { $i * 10 }
Check (($viaPipe -join ',') -eq ($viaStmt -join ',') -and ($viaPipe -join ',') -eq '10,20,30,40,50') '两种枚举结果一致且保序'

# —— 3) 方法批量（.NET 静态调用走管道） ——
$cubes = 1..3 | ForEach-Object { [math]::Pow($_, 3) }
Check (($cubes -join ',') -eq '1,8,27') '管道逐对象计算立方'

# —— 4) -WhatIf 安全带：干跑不落盘 ——
$safe = Join-Path $work 'safe.txt'
Set-Content -Path $safe -Value 'x' -Encoding UTF8
Remove-Item -Path $safe -WhatIf | Out-Null
Check (Test-Path $safe) '-WhatIf 干跑未删除'
Remove-Item -Path $safe
Check (-not (Test-Path $safe)) '正式调用删除成功'

# —— 5) -Parallel（pwsh 7 独有）：乱序治理后确定性 ——
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $par = 1..5 | ForEach-Object -Parallel { $_ * 2 } -ThrottleLimit 5 | Sort-Object
    Check (($par -join ',') -eq '2,4,6,8,10') '-Parallel 结果排序后确定 [ch7-only]'
    $m = 3
    $parUse = 1..3 | ForEach-Object -Parallel { $using:m * $_ } -ThrottleLimit 3 | Sort-Object
    Check (($parUse -join ',') -eq '3,6,9') '-Parallel 经 $using: 传值 [ch7-only]'
}
else {
    Skip 'ForEach-Object -Parallel 是 pwsh 7 语法，5.1 跳过 [ch7-only]'
    Skip '同上（$using: 并行演示一并跳过） [ch7-only]'
}

Remove-Item $work -Recurse -Force
Check (-not (Test-Path $work)) '临时目录清理'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
