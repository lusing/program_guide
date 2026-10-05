#Requires -Version 5.1
# 示例 10：格式化——Format 指令类型、右到左失效、4/5 规则、格式串计算属性、列头谎言
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) Format- 产出的是格式化指令，不再是原对象 ——
$ft = Get-Service | Format-Table -Property Name, Status | Select-Object -First 1
Check ($ft.GetType().Name -match 'Format') 'Format-Table 产出格式指令对象'
$raw = Get-Service | Select-Object -First 1
Check ($raw.GetType().Name -eq 'ServiceController') '不接 Format 时对象原样到达'

# —— 2) 右到左：Format 之后再排序悄悄失效 ——
$good = Get-Service | Sort-Object Status | Format-Table -Property Name, Status
$goodType = (@($good) | Select-Object -First 1).GetType().Name
Check ($goodType -match 'Format') '正确顺序：先排序后格式化（终点是指令）'
$broken = Get-Service | Format-Table -Property Name, Status | Sort-Object Status
$brokenType = (@($broken) | Select-Object -First 1).GetType().Name
Check ($brokenType -match 'Format') '错误顺序：Format 后排序拿到的已是指令（无 Status 可排）'
$brokenNames = @($broken | Where-Object { $_ -is [System.ServiceProcess.ServiceController] }).Count
Check ($brokenNames -eq 0) '右到左失效实证：管线里已无 ServiceController'

# —— 3) 4/5 规则：≤4 属性出表格、≥5 出列表（借 Out-String 行数判定） ——
$obj4 = [pscustomobject]@{ A = 1; B = 2; C = 3; D = 4 }
$obj6 = [pscustomobject]@{ A = 1; B = 2; C = 3; D = 4; E = 5; F = 6 }
$lines4 = @(($obj4 | Out-String) -split "`n" | Where-Object { $_ -match '\S' }).Count
$lines6 = @(($obj6 | Out-String) -split "`n" | Where-Object { $_ -match '\S' }).Count
Check ($lines4 -le 3) '4 属性默认渲染为表格（表头+数据两三行）'
Check ($lines6 -eq 6) '6 属性默认渲染为列表（每属性一行）'

# —— 4) 格式化计算属性：FormatString/Align 可用 ——
$row = 1234.5 | Format-Table @{ Label = 'Num'; Expression = { $_ }; FormatString = 'N1'; Align = 'Right' } | Out-String
Check ($row -match '1234\.5') 'FormatString=N1 定点一位小数渲染'
$rowPct = 0.25 | Format-Table @{ Label = 'Pct'; Expression = { $_ }; FormatString = 'P0' } | Out-String
Check ($rowPct -match '25') 'FormatString=P0 百分比渲染'

# —— 5) 列头会说谎：PM(K) 不是属性名 ——
Check (@(Get-Process | Get-Member -Name PM).Count -eq 1) '真实属性名是 PM（AliasProperty）'
$procHeader = (Get-Process | Select-Object -First 1 | Format-Table PM | Out-String)
Check ($procHeader -notmatch 'PM\(K\)') '选中 PM 属性时列头不再显示 PM(K)'

# —— 6) Format-List 全量与 Wide 铺排 ——
$fl = Get-Service -Name 'winmgmt' | Format-List * | Out-String
Check (($fl -split "`n").Count -gt 10) 'Format-List * 展示全部属性'
$fw = 1..8 | Format-Wide -Column 4 | Out-String
Check ($fw -match '\S') 'Format-Wide 多列铺排'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
