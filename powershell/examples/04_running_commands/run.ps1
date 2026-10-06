#Requires -Version 5.1
# 示例 04：运行命令——命名惯例、别名、位置参数、缩写、-WhatIf、大小写、外部命令
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 命名惯例：批准动词表 ——
$verbs = Get-Verb
Check (@($verbs).Count -ge 90) '批准动词表约百个'
Check (@($verbs | Where-Object Verb -in 'Get', 'Set', 'New', 'Remove').Count -eq 4) 'Get/Set/New/Remove 均在批准表'

# —— 2) 别名是纯昵称：解析回全名，参数不变 ——
# gsv 指向 Get-Service，而 Get-Service 只在 Windows 上存在（Unix 用 launchd）。
# 教学点是「别名解析到全名、且能按需选一个两平台都有的别名来断言」，
# 所以 gsv 在缺 cmdlet 的平台上降级为 SKIP，另用 gci/gps 这类跨平台别名做实证。
if (Get-Command Get-Service -ErrorAction SilentlyContinue) {
    Check ((Get-Alias -Name gsv).Definition -eq 'Get-Service') 'gsv 解析到 Get-Service'
}
else { Skip '本平台无 Get-Service，故无 gsv 别名（别名随其目标 cmdlet 一起缺失） [platform]' }
Check ((Get-Alias -Name gci).Definition -eq 'Get-ChildItem') 'gci 解析到 Get-ChildItem（跨平台别名）'
Check ((Get-Alias -Name gps).Definition -eq 'Get-Process') 'gps 解析到 Get-Process'

# —— 3) 位置参数与命名参数等价（在受控临时目录里做） ——
$dir = Join-Path $PSScriptRoot 'tmp-cmd'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Set-Content -Path (Join-Path $dir 'a.txt') -Value 'x' -Encoding UTF8
Check (@(Get-ChildItem $dir).Count -eq 1) '位置参数绑定到 -Path'
Check (@(Get-ChildItem -Path $dir).Count -eq 1) '命名参数显式等价'
Check (@(Get-ChildItem -Path $dir -Fi '*.txt').Count -eq 1) '参数名可缩写（-Fi 唯一匹配 -Filter）'

# —— 4) 大小写无关 ——
# 用 Get-ChildItem 而不是 Get-Service：命令名大小写无关是引擎行为，与 cmdlet 平台无关。
Check ((gET-cOMMAND get-cHILDITEM).Name -eq 'Get-ChildItem') '命令与参数大小写无关'
Check ((Get-ChildItem -pATH $dir -fILter '*.txt').Count -eq 1) '参数名大小写同样无关'

# —— 5) -WhatIf 风险缓解参数：干跑不落盘 ——
$target = Join-Path $dir 'a.txt'
Remove-Item $target -WhatIf
Check (Test-Path $target) '-WhatIf 干跑未真正删除'
Check ((Get-Command Remove-Item).Parameters.ContainsKey('WhatIf')) 'Remove-Item 自带 -WhatIf'

# —— 6) 外部命令照常可用（值不进对账区，只断言形态） ——
$whoami = @(Get-Command whoami -CommandType Application -ErrorAction SilentlyContinue)[0]
if ($whoami) {
    $out = & $whoami.Source
    Check ($LASTEXITCODE -eq 0 -and "$out" -match '\S') '外部命令 whoami 正常执行'
}
else { Skip '未找到 whoami 外部命令 [env]' }

Remove-Item $dir -Recurse -Force
Check (-not (Test-Path $dir)) '临时目录清理'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
