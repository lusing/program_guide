#Requires -Version 5.1
# 示例 12：学以致用——磁盘库存全流程（取数→加工→筛→三态输出→回读对账）
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

$work = Join-Path $PSScriptRoot 'tmp-inv'
New-Item -ItemType Directory -Force -Path $work | Out-Null

# —— 1) 取数 + 加工（左过滤 + 计算属性 + 分母防御） ——
# 原书取 Win32_LogicalDisk（DriveType=3 = 本地固定盘）；Unix/macOS 没有 CIM/WMI 栈，
# 改用 Get-PSDrive -PSProvider FileSystem。两者字段形状不同——这本身是个真实差异：
#   CIM  给 Size / FreeSpace 两个独立字段；
#   PSDrive 只给 Free，"总量"要自己 Used+Free 算出来。
# 所以下面的计算属性在两条轨上写法不同，但**分母防御、舍入、列名**这些教学点一致。
if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
    $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
        Select-Object DeviceID,
        @{ n = 'TotalGB'; e = { [math]::Round($_.Size / 1GB, 1) } },
        @{ n = 'FreeGB'; e = { [math]::Round($_.FreeSpace / 1GB, 1) } },
        @{ n = 'FreeRatio'; e = { if ($_.Size -gt 0) { [math]::Round($_.FreeSpace / $_.Size, 3) } else { 0 } } }
    Check (@($disks).Count -ge 1) '本地磁盘至少一枚（DriveType=3 左过滤）'
}
else {
    $disks = Get-PSDrive -PSProvider FileSystem |
        Where-Object { $null -ne $_.Used -and ($_.Used + $_.Free) -gt 0 } |
        Select-Object @{ n = 'DeviceID'; e = { $_.Name } },
        @{ n = 'TotalGB'; e = { [math]::Round(($_.Used + $_.Free) / 1GB, 1) } },
        @{ n = 'FreeGB'; e = { [math]::Round($_.Free / 1GB, 1) } },
        @{ n = 'FreeRatio'; e = { $total = $_.Used + $_.Free; if ($total -gt 0) { [math]::Round($_.Free / $total, 3) } else { 0 } } }
    Check (@($disks).Count -ge 1) '本机文件系统盘至少一枚（Get-PSDrive 左过滤；CIM 不可用）'
}
Check (@($disks | Where-Object { $_.FreeRatio -ge 0 -and $_.FreeRatio -le 1 }).Count -eq @($disks).Count) '空闲比值域全部合法 [0,1]'

# —— 2) 告警子集：阈值条件对子集成立 ——
$alerts = @($disks | Where-Object FreeRatio -lt 0.2 | Sort-Object FreeRatio)
Check (($alerts | Where-Object { $_.FreeRatio -ge 0.2 }).Count -eq 0) '告警子集全部低于阈值'

# —— 3) 三态输出：屏幕视图（Format 收尾） ——
$view = $disks | Format-Table DeviceID, TotalGB, FreeGB,
    @{ n = 'Pct'; e = { '{0:P1}' -f $_.FreeRatio }; Align = 'Right' } -AutoSize | Out-String
Check ($view -match 'DeviceID' -and $view -match '%') '屏幕视图含表头与百分比'

# —— 4) CSV 底档 + 回读对账 ——
$csv = Join-Path $work 'inventory.csv'
$disks | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8
$back = @(Import-Csv -Path $csv)
Check ($back.Count -eq @($disks).Count) 'CSV 往返行数守恒'
Check ($back[0].PSObject.Properties.Name -contains 'FreeRatio') 'CSV 列名保留计算属性'

# —— 5) HTML 报告（排序前置 + 结构断言） ——
$html = $disks | Sort-Object FreeRatio |
    ConvertTo-Html -Property DeviceID, TotalGB, FreeGB, FreeRatio -Title 'inventory' |
    Out-String
Check ($html -match '<table' -and $html -match 'FreeRatio') 'HTML 含表格与列名'

# —— 6) 日期戳归档命名 ——
$stamp = Get-Date -Format 'yyyyMMdd'
$stampFile = Join-Path $work "inventory-$stamp.csv"
$disks | Export-Csv -Path $stampFile -NoTypeInformation -Encoding UTF8
Check (Test-Path $stampFile) '日期戳归档文件生成'

Remove-Item $work -Recurse -Force
Check (-not (Test-Path $work)) '临时目录清理'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }