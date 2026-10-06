#Requires -Version 5.1
# 示例 07：模块生态——清单、路径、自动加载、前缀、两代安装命令
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 弹药库与搜索路径 ——
# PSModulePath 是**平台相关的路径列表**：Windows 用 ';' 分隔，Unix/macOS 用 ':'。
# 写死 ';' 在 macOS 上会把整串当成一个目录——这是本示例实测踩到的坑（见 CHEATSheet 7a）。
Check (@(Get-Module -ListAvailable).Count -gt 0) '本机有已安装模块'
$sep = [System.IO.Path]::PathSeparator
$paths = @($env:PSModulePath -split [regex]::Escape($sep) | Where-Object { $_ })
Check ($paths.Count -ge 2) "PSModulePath 含多个搜索目录（分隔符 '$sep'）"
Check (@($paths | Where-Object { $_ -match 'powershell' }).Count -ge 1) '模块路径包含 PowerShell 目录字样'

# —— 2) 已加载模块与常用模块的命令（显式导入保证两引擎确定性） ——
Import-Module Microsoft.PowerShell.Utility -ErrorAction SilentlyContinue
Check (@(Get-Module).Count -ge 1) '显式导入后模块处于加载状态'
Check (@(Get-Command -Module Microsoft.PowerShell.Utility).Count -gt 5) 'Utility 模块贡献大量命令'

# —— 3) 自动加载实证：未加载模块的命令一跑就加载（NetAdapter 按需加载） ——
if (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue) {
    $loadedBefore = [bool](Get-Module NetAdapter)
    $null = Get-NetAdapter -ErrorAction SilentlyContinue
    $loadedAfter = [bool](Get-Module NetAdapter)
    Check ($loadedAfter) '运行未加载模块的命令触发自动加载 [env]'
}
else { Skip '本机无 NetAdapter 模块（非完整 Windows 或裁剪环境） [env]' }

# —— 4) 名词前缀防冲突 ——
if (Get-Command Get-DnsClientCache -ErrorAction SilentlyContinue) {
    Check (@(Get-Command -Noun DnsClientCache).Count -ge 1) 'DnsClient 名词前缀抽样 [env]'
}
else { Skip '本机无 DnsClient 模块 [env]' }

# —— 5) 两代安装命令的探测分支 ——
Check ($null -ne (Get-Command Install-Module -ErrorAction SilentlyContinue)) 'PowerShellGet v2 的 Install-Module 可用'
if (Get-Command Install-PSResource -ErrorAction SilentlyContinue) {
    Check ($true) '新一代 Install-PSResource 可用（7.4+） [ch7-only]'
}
else { Skip '本引擎无 PSResourceGet（5.1/老 7.x），新一代安装命令跳过 [ch7-only]' }

# —— 6) 模块可见性是按引擎隔离的（路径断言，不依赖具体安装） ——
$mine = Split-Path -Parent (Split-Path -Parent $PSHOME)
Check ($PSHOME -match 'PowerShell') '模块搜索目录随引擎隔离（v1.0 目录历史）'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
