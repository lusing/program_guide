#Requires -Version 5.1
# 示例 18：可复用会话——探针门控；状态持久对照、Exit 不拆连接、断线重连、Remove 清场
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 命令族可用性（无条件） ——
Check ($null -ne (Get-Command New-PSSession -ErrorAction SilentlyContinue)) 'New-PSSession 存在'
Check ((Get-Command Invoke-Command).Parameters.ContainsKey('Session')) 'Invoke-Command 支持 -Session（复用通道）'

# —— 2) WinRM loopback 探针 ——
$wsmanOk = $false
try { $null = Test-WSMan -ErrorAction Stop; $wsmanOk = $true } catch { }

if ($wsmanOk) {
    # —— 3) 状态持久：会话 vs 一次性 对照 ——
    $s = New-PSSession -ComputerName localhost
    Invoke-Command -Session $s -ScriptBlock { $x = 1 } | Out-Null
    $kept = Invoke-Command -Session $s -ScriptBlock { $x }
    Check ("$kept" -eq '1') '会话模式：变量跨命令存活'

    Invoke-Command -ComputerName localhost -ScriptBlock { $x = 1 } | Out-Null
    $lost = Invoke-Command -ComputerName localhost -ScriptBlock { "$x" }
    Check ("$lost" -eq '') '一次性模式：变量随连接销毁'

    # —— 4) 断线重连：状态仍在 ——
    Disconnect-PSSession -Session $s | Out-Null
    $disconnected = ($s.State -eq 'Disconnected')
    Connect-PSSession -Session $s | Out-Null
    $reKept = Invoke-Command -Session $s -ScriptBlock { $x }
    Check ($disconnected -and "$reKept" -eq '1') '断线重连后变量健在'

    # —— 5) 清场 ——
    Remove-PSSession -Session $s
    Check ($null -eq (Get-PSSession -InstanceId $s.InstanceId -ErrorAction SilentlyContinue)) 'Remove-PSSession 后会话查无'
}
else {
    Skip 'WinRM loopback 不可用（未 Enable-PSRemoting），会话演示跳过——正文 18.2 讲解对照实验'
}

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
