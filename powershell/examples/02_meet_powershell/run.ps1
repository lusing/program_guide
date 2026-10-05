#Requires -Version 5.1
# 示例 02：初识 PowerShell——版本表结构、宿主身份、profile 路径、PSReadLine 可用性
# 全部断言不依赖具体版本号/机器路径，双引擎输出一致。
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 版本表：结构断言（不看具体版本值） ——
Check ($PSVersionTable.PSVersion.Major -ge 5) 'PSVersion 主版本 >= 5'
Check ($PSVersionTable.PSEdition -in 'Desktop', 'Core') 'PSEdition 为 Desktop 或 Core'
Check ($PSVersionTable.ContainsKey('PSRemotingProtocolVersion')) '版本表含远程协议版本行'

# —— 2) 引擎身份：$PSHOME 与进程名（不打印具体值） ——
Check ($PSHOME -match 'PowerShell') '引擎目录名含 PowerShell（历史梗：目录永远是 v1.0）'
Check ((Get-Process -Id $PID).ProcessName -in 'pwsh', 'powershell', 'powershell_ise') '进程名为已知引擎之一'

# —— 3) 宿主 ——
Check ($Host.Name -eq 'ConsoleHost') '当前宿主为 ConsoleHost'
Check ($Host.UI.RawUI -ne $null) '宿主提供 UI 接口'

# —— 4) profile：路径结构断言（两引擎路径不同，但都叫 profile） ——
Check ($PROFILE -match 'profile\.ps1$') 'profile 路径以 profile.ps1 结尾'
$tp = $null
try { $tp = Test-Path $PROFILE } catch { }
Check ($tp -is [bool]) 'Test-Path 对 profile 返回布尔值不抛错'
Check ((Split-Path $PROFILE -Parent).Length -gt 0) 'profile 父目录路径可解析'

# —— 5) PSReadLine：交互体验层可用（不依赖其版本） ——
Check ($null -ne (Get-Module -ListAvailable -Name PSReadLine)) 'PSReadLine 模块可用'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
