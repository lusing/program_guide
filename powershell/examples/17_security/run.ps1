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
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
Check ((Get-ExecutionPolicy -Scope Process) -eq 'Bypass') 'Process 作用域设为 Bypass 生效'

# —— 3) ADS/MOTW：写读删闭环（临时文件上自演自净） ——
$ps1 = Join-Path $work 'downloaded.ps1'
Set-Content -Path $ps1 -Value 'Write-Output "hi"' -Encoding UTF8
Set-Content -Path $ps1 -Stream Zone.Identifier -Value '[ZoneTransfer]', 'ZoneId=3' -Encoding ASCII
$motw = Get-Content -Path $ps1 -Stream Zone.Identifier
Check (($motw -join ';') -match 'ZoneId=3') 'Zone.Identifier 流写入并可读回（MOTW 模拟）'
Check (@(Get-Item $ps1 -Stream *).Count -ge 2) 'Get-Item -Stream 可见数据流（含 Zone.Identifier）'
Unblock-File -Path $ps1
$after = Get-Item $ps1 -Stream Zone.Identifier -ErrorAction SilentlyContinue
Check ($null -eq $after) 'Unblock-File 后 Zone.Identifier 流消失'

# —— 4) 签名状态：自己刚写的脚本是 NotSigned ——
$sig = Get-AuthenticodeSignature -FilePath $ps1
Check ($sig.Status -eq 'NotSigned') '新脚本签名状态 NotSigned'

# —— 5) 脚本文件被策略管、交互命令不被管的体验（受控） ——
$out = & $ps1
Check ("$out" -eq 'hi') '策略放行后本地脚本能运行并输出'

Remove-Item $work -Recurse -Force
Check (-not (Test-Path $work)) '临时目录清理'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
