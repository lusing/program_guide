#Requires -Version 5.1
# 示例 17：安全——作用域清单、Process 级放行、ADS/MOTW 闭环、签名状态
# 纪律：只动 Process 作用域（随进程消亡）；只写临时文件的 ADS。
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

$work = Join-Path $PSScriptRoot 'tmp-sec'
New-Item -ItemType Directory -Force -Path $work | Out-Null

# —— 1) 执行策略：六作用域全景与生效值 ——
$list = Get-ExecutionPolicy -List
$scopes = @($list | ForEach-Object Scope)
Check (@($scopes | Where-Object { $_ -in 'MachinePolicy', 'UserPolicy', 'Process', 'CurrentUser', 'LocalMachine' }).Count -eq 5) '作用域清单含全部五层'
Check ((Get-ExecutionPolicy) -in 'Restricted', 'RemoteSigned', 'AllSigned', 'Unrestricted', 'Bypass', 'Undefined') '生效值是已知策略之一'

# —— 2) Process 作用域：临时放行（自清理——进程结束即失效） ——
# 执行策略是 **Windows 专属机制**：pwsh 7 在 Unix/macOS 上 Get-ExecutionPolicy 恒为
# Unrestricted，Set-ExecutionPolicy 任何作用域都抛 "Operation is not supported on this
# platform"。这里用"设置是否真能生效"这个事实条件分支，不用平台宏（CHEATSheet 17a）。
$policySet = $null
try {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop
    $policySet = (Get-ExecutionPolicy -Scope Process)
}
catch { $policySet = $null }
if ($policySet -eq 'Bypass') { Check ($true) 'Process 作用域设为 Bypass 生效' }
else { Skip '本平台不支持执行策略设置（Unix/macOS 上恒 Unrestricted，脚本不设防） [platform]' }

# —— 3) ADS/MOTW：写读删闭环（临时文件上自演自净） ——
# NTFS 备用数据流（Alternate Data Stream）是 **文件系统特性**，不是 PowerShell 特性：
# macOS 的 APFS/HFS+ 没有等价物，-Stream 参数在 Unix 版上根本不存在于参数表。
$ps1 = Join-Path $work 'downloaded.ps1'
Set-Content -Path $ps1 -Value 'Write-Output "hi"' -Encoding UTF8
$hasAds = (Get-Command Get-Item).Parameters.ContainsKey('Stream')
if ($hasAds) {
    Set-Content -Path $ps1 -Stream Zone.Identifier -Value '[ZoneTransfer]', 'ZoneId=3' -Encoding ASCII
    $motw = Get-Content -Path $ps1 -Stream Zone.Identifier
    Check (($motw -join ';') -match 'ZoneId=3') 'Zone.Identifier 流写入并可读回（MOTW 模拟）'
    Check (@(Get-Item $ps1 -Stream *).Count -ge 2) 'Get-Item -Stream 可见数据流（含 Zone.Identifier）'
    Unblock-File -Path $ps1
    $after = Get-Item $ps1 -Stream Zone.Identifier -ErrorAction SilentlyContinue
    Check ($null -eq $after) 'Unblock-File 后 Zone.Identifier 流消失'
}
else {
    Skip '本平台无 NTFS 备用数据流（Get-Item -Stream 参数不存在），MOTW 闭环不可演示 [platform]'
}

# —— 4) 签名状态：自己刚写的脚本是 NotSigned ——
# Get-AuthenticodeSignature 属 Microsoft.PowerShell.Security 的 **Windows-only** 部分，
# Unix 版 pwsh 7 不带此 cmdlet。
if (Get-Command Get-AuthenticodeSignature -ErrorAction SilentlyContinue) {
    $sig = Get-AuthenticodeSignature -FilePath $ps1
    Check ($sig.Status -eq 'NotSigned') '新脚本签名状态 NotSigned'
}
else { Skip '本平台无 Authenticode 签名 cmdlet（Windows-only） [platform]' }

# —— 5) 脚本文件被策略管、交互命令不被管的体验（受控） ——
$out = & $ps1
Check ("$out" -eq 'hi') '策略放行后本地脚本能运行并输出'

Remove-Item $work -Recurse -Force
Check (-not (Test-Path $work)) '临时目录清理'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
