#Requires -Version 5.1
# 示例 30：使用他人的脚本——五步阅读法的可执行版：param 面对比、防护对比、结果对象、审计
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

$buggy = Join-Path $PSScriptRoot 'sample-buggy.ps1'
$fixed = Join-Path $PSScriptRoot 'sample-fixed.ps1'
$work = Join-Path $PSScriptRoot 'tmp-audit'
New-Item -ItemType Directory -Force -Path $work | Out-Null

# —— 1) 第 2 步（读 param 面）：病版 6 参、修复版 3 参 ——
$buggyCmd = Get-Command $buggy
$fixedCmd = Get-Command $fixed
Check (@($buggyCmd.Parameters.Keys | Where-Object { $_ -notmatch '^Verb|^Debug|^Error|^Warning|^Out|^Information|^Pipeline' }).Count -ge 5) '病版参数面臃肿（6 个自定义参数）'
Check (@($fixedCmd.Parameters.Keys | Where-Object { $_ -in 'Path', 'RetentionDays', 'Exclude' }).Count -eq 3) '修复版参数面收敛（3 个全在用）'
Check ($buggyCmd.Parameters.ContainsKey('LogPath') -and $buggyCmd.Parameters.ContainsKey('WhatIfLocal')) '病版含死参数（LogPath/WhatIfLocal 声明未用）'

# —— 2) 第 1 步（读头）：修复版有注释帮助，病版没有 ——
$fixedHelp = Get-Help $fixed
Check ("$($fixedHelp.Synopsis)" -match '删除超过保留期') '修复版有 SYNOPSIS（读头有料）'

# —— 3) 第 5 步（干演）：防护对比 ——
$old = (Get-Date).AddDays(-60)
1..2 | ForEach-Object { $f = Join-Path $work "old$_.log"; Set-Content -Path $f -Value 'x' -Encoding UTF8; (Get-Item $f).LastWriteTime = $old }
$keep = Join-Path $work 'keep.log'; Set-Content -Path $keep -Value 'x' -Encoding UTF8
Check (@(Get-ChildItem $work -Filter '*.log').Count -eq 3) '测试目录就位（2 旧 1 新）'
$result = & $fixed -Path $work -RetentionDays 30 -Exclude 'keep.log'
Check (@(Get-ChildItem $work -Filter '*.log').Count -eq 1) '修复版真删（旧文件清掉）'
Check ($result.Removed -eq 2 -and $result.Path -eq $work) '修复版输出结果对象（删了几个有据可查）'
$pretend = & $fixed -Path $work -RetentionDays 30 -WhatIf
Check (@(Get-ChildItem $work -Filter '*.log').Count -eq 1) '修复版 -WhatIf 干跑不落盘（防护接线）'
Check ($buggyCmd.Parameters.ContainsKey('WhatIf') -eq $false) '病版无 -WhatIf（死开关 WhatIfLocal 不算数）'

# —— 4) 审计：签名状态 ——
Check ((Get-AuthenticodeSignature $buggy).Status -eq 'NotSigned') '病版未签名（审计第 3 步）'
Check ((Get-AuthenticodeSignature $fixed).Status -eq 'NotSigned') '修复版同样未签名（本地改造件）'

Remove-Item $work -Recurse -Force
Check (-not (Test-Path $work)) '临时目录清理'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
