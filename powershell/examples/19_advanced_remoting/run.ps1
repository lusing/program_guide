#Requires -Version 5.1
# 示例 19：高级远程——SSH 腿探测、会话选项对象、端点/WSMan 只读门控
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) SSH 通道物料探测（OpenSSH 客户端） ——
if (Get-Command ssh -ErrorAction SilentlyContinue) {
    Check ($true) 'OpenSSH 客户端在 PATH（SSH 远程物料齐备） [env]'
}
else { Skip '本机无 ssh 客户端（SSH 远程演示不可用） [env]' }

# —— 2) -HostName 参数：SSH 腿是 pwsh 7 独享 ——
if ((Get-Command New-PSSession).Parameters.ContainsKey('HostName')) {
    Check ($true) 'New-PSSession 支持 -HostName（SSH 远程通道） [ch7-only]'
}
else { Skip '5.1 无 -HostName（SSH 腿为 pwsh 7 独享） [ch7-only]' }

# —— 3) 会话选项对象：连接高级面板（不建连接即可构造） ——
# 会话选项里的超时项（-IdleTimeout/-OpenTimeout 等）是 **WSMan 传输的参数**。
# pwsh 7 的 Unix 版把 WSMan 整条腿剔除了，New-PSSessionOption 只剩两个 SSL 证书校验开关
# （SkipCACheck/SkipCNCheck）——因为 Unix 上的 pwsh 远程只走 SSH，没有 WSMan。
# 所以判据是"这些参数在参数表里吗"，不是平台宏。
$optCmd = Get-Command New-PSSessionOption
if ($optCmd.Parameters.ContainsKey('IdleTimeout')) {
    $opt = New-PSSessionOption -IdleTimeout 600000 -OpenTimeout 15000
    Check ($opt.IdleTimeout.TotalMinutes -eq 10) 'SessionOption 空闲超时=10 分钟（TimeSpan）'
    Check ($opt.OpenTimeout.TotalSeconds -eq 15) 'SessionOption 连接超时=15 秒（TimeSpan）'
}
else {
    $opt = New-PSSessionOption -SkipCACheck
    Check ($null -ne $opt) 'SessionOption 可构造（本平台只余 SSL 校验开关）'
    Skip '本平台 New-PSSessionOption 无 WSMan 超时参数（-IdleTimeout/-OpenTimeout 不在参数表；Unix 远程只走 SSH） [platform]'
}

# —— 4) 端点清单与 WSMan 配置：只读门控（需 WinRM 服务） ——
$wsmanOk = $false
try { $null = Test-WSMan -ErrorAction Stop; $wsmanOk = $true } catch { }

if ($wsmanOk) {
    $eps = @(Get-PSSessionConfiguration -ErrorAction SilentlyContinue)
    Check ($eps.Count -ge 1) '端点清单可读（默认端点存在）'
}
else {
    Skip 'WinRM 服务未运行，端点清单与 WSMan: 驱动器只读演示跳过（正文 19.1/19.2 讲解步骤）'
}

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
