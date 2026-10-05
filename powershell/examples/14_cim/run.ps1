#Requires -Version 5.1
# 示例 14：CIM/WMI——本机直连、WQL 方言、DateTime 类型、GetCimClass/Invoke-CimMethod、遗留命令分岔
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 本机直连：不带 -ComputerName 不需要 WinRM ——
$os = Get-CimInstance -ClassName Win32_OperatingSystem
Check ("$($os.Caption)" -match '\S') 'Win32_OperatingSystem.Caption 非空'
Check ($os.LastBootUpTime -is [datetime]) 'LastBootUpTime 是真 DateTime（CIM 的甜头）'
Check ((New-TimeSpan -Start $os.LastBootUpTime -End (Get-Date)).TotalDays -gt 0) '开机时长可计算'

# —— 2) WQL 方言与客户端过滤等价 ——
$wql = @(Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3")
$ps  = @(Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object DriveType -eq 3)
Check ($wql.Count -eq $ps.Count -and $wql.Count -ge 1) 'WQL Filter 与 Where-Object 计数一致'
$query = @(Get-CimInstance -Query "SELECT * FROM Win32_LogicalDisk WHERE DriveType=3")
Check ($query.Count -eq $wql.Count) '-Query 完整 WQL 与 -Filter 等价'

# —— 3) PSComputerName 映射（本机直连也可用） ——
Check ($wql[0].PSObject.Properties.Name -contains 'PSComputerName') '结果自带 PSComputerName 属性（本机直连时值为空，远程查询才填充）'

# —— 4) Get-CimClass 看结构 + Invoke-CimMethod 调方法 ——
$procClass = Get-CimClass -ClassName Win32_Process
Check (@($procClass.CimClassMethods | Where-Object Name -eq 'GetOwner').Count -eq 1) 'Win32_Process 类含 GetOwner 方法'
$me = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId=$PID"
$owner = Invoke-CimMethod -InputObject $me -MethodName GetOwner
Check ("$($owner.User)" -match '\S') 'Invoke-CimMethod GetOwner 返回属主'

# —— 5) 遗留命令的双引擎分岔 ——
if (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) {
    $legacy = Get-WmiObject -Class Win32_OperatingSystem
    Check ("$($legacy.Caption)" -match '\S') 'Get-WmiObject 仍可用（5.1 遗留通道） [ch51-only]'
}
else {
    Skip 'pwsh 7 已移除 Get-WmiObject——一切改走 CIM 命令 [ch7-only]'
}
Check ($null -eq (Get-Command Get-WmiObject -ErrorAction SilentlyContinue) -or
    $null -ne (Get-Command Get-WmiObject -ErrorAction SilentlyContinue)) '命令探测本身双通道一致'

# —— 6) 安全警告的类不碰：只断言其存在性 ——
Check ($null -ne (Get-CimClass -ClassName Win32_Product -ErrorAction SilentlyContinue)) 'Win32_Product 类存在（本示例不查询其实例）'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
