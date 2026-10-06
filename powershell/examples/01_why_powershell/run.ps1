#Requires -Version 5.1
# 示例 01：为什么是 PowerShell——批量、一致、自动清理的自动化闭环
# 演示三件事：1) 一条命令批量创建；2) 同样的命令重复执行，结果一致；3) 清理也是一条命令。
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 批量创建：GUI 要点 5 次，这里一条命令 ——
$work = Join-Path $PSScriptRoot 'tmp-sites'
New-Item -ItemType Directory -Force -Path $work | Out-Null
1..5 | ForEach-Object { New-Item -ItemType Directory -Force -Path (Join-Path $work "site$_") } | Out-Null
Check ((Get-ChildItem $work -Directory).Count -eq 5) '一条命令批量创建 5 个目录'

# —— 2) 一致性：同样的命令再跑一遍，结果不变（幂等） ——
1..5 | ForEach-Object { New-Item -ItemType Directory -Force -Path (Join-Path $work "site$_") } | Out-Null
Check ((Get-ChildItem $work -Directory).Count -eq 5) '重复执行结果一致（幂等）'

# —— 3) 结构化查询：一条命令得到结构化答案 ——
# Get-Service 是 Windows-only cmdlet（pwsh 7 在 Unix 上不带它，因为 launchd 不是 SCM）。
# 教学点是"单命令枚举一个系统集合并直接拿到对象"，两平台各有事实锚点：
# Windows 用服务集合，Unix 用进程集合——都不断言。
if (Get-Command Get-Service -ErrorAction SilentlyContinue) {
    Check (@(Get-Service).Count -gt 10) '单命令枚举服务集合'
}
else { Skip '本平台无 Get-Service（Windows-only；Unix 用 launchd 而非 SCM） [platform]' }
Check (@(Get-Process).Count -gt 5) '单命令枚举进程集合'

# —— 4) 组合：管道把命令接起来（创建→统计→筛选） ——
$big = 1..5 | ForEach-Object { New-Item -ItemType Directory -Force -Path (Join-Path $work "deep$_") } |
    Measure-Object | Select-Object -ExpandProperty Count
Check ($big -eq 5) '创建结果经管道统计'

# —— 5) 清理：一条命令收尾，不留垃圾 ——
Remove-Item $work -Recurse -Force
Check (-not (Test-Path $work)) '自动清理完成'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
