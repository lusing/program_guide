#Requires -Version 5.1
# 示例 13：远程处理——命令族可用性（无条件）+ WinRM loopback 探针门控演示
# 本示例绝不修改系统状态；WinRM 未启用时全部远程断言带理由跳过。
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 远程命令族无条件断言 ——
Check ($null -ne (Get-Command Invoke-Command -ErrorAction SilentlyContinue)) 'Invoke-Command 存在'
Check ($null -ne (Get-Command Enter-PSSession -ErrorAction SilentlyContinue)) 'Enter-PSSession 存在'
Check ((Get-Command Invoke-Command).Parameters.ContainsKey('ConfigurationName')) 'Invoke-Command 支持 -ConfigurationName（端点选择）'
Check ((Get-Command Invoke-Command).Parameters.ContainsKey('ThrottleLimit')) 'Invoke-Command 支持 -ThrottleLimit（并发控制）'

# —— 2) WinRM loopback 探针（不改变任何系统设置） ——
$wsmanOk = $false
try { $null = Test-WSMan -ErrorAction Stop; $wsmanOk = $true } catch { }

if ($wsmanOk) {
    # —— 3) 远程执行：表达式与 PSComputerName ——
    $r = @(Invoke-Command -ComputerName localhost -ScriptBlock { 1 + 1 })
    Check ($r[0] -eq 2) '远程表达式 1+1 求值为 2'
    Check ($null -ne $r[0].PSComputerName) '远程结果自带 PSComputerName 属性'

    # —— 4) 一对多：双目标各返回一份 ——
    $many = @(Invoke-Command -ComputerName localhost, localhost -ScriptBlock { $env:COMPUTERNAME })
    Check ($many.Count -eq 2) '一对多：两个目标两条结果'
}
else {
    Skip 'WinRM loopback 不可用（未 Enable-PSRemoting），远程演示跳过——正文 13.1/13.2 讲解启用步骤'
}

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
