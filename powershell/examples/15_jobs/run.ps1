#Requires -Version 5.1
# 示例 15：后台作业——生命周期、-Keep、$using、ChildJobs、Remove、ThreadJob、初始目录差异
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 全生命周期：Start → Wait → Receive → Remove ——
$job = Start-Job -ScriptBlock { 1 + 1 } -Name 'tut-job'
Check ($job.State -in 'NotStarted', 'Running', 'Completed') 'Start-Job 立即返回作业对象'
$null = Wait-Job -Job $job -Timeout 60
Check ($job.State -eq 'Completed') 'Wait-Job 后状态 Completed'
$first = Receive-Job -Job $job
Check ($first -eq 2) 'Receive-Job 收到 1+1=2'
Check ($job.HasMoreData -eq $false) '收取后 HasMoreData 熄灭（签收制）'

# —— 2) -Keep：留副本可双收 ——
$keepJob = Start-Job -ScriptBlock { 'x' }
$null = Wait-Job -Job $keepJob -Timeout 60
$a = Receive-Job -Job $keepJob -Keep
$b = Receive-Job -Job $keepJob -Keep
Check ("$a" -eq 'x' -and "$b" -eq 'x') '-Keep 双收均可得结果'
Remove-Job -Job $keepJob -Force

# —— 3) $using: 跨环境传值 ——
$v = 41
$useJob = Start-Job -ScriptBlock { $using:v + 1 }
$null = Wait-Job -Job $useJob -Timeout 60
Check ((Receive-Job -Job $useJob) -eq 42) '$using: 把本地变量值传入作业'
Remove-Job -Job $useJob -Force

# —— 4) ChildJobs 结构：本地作业也有父子两层 ——
Check (@($job.ChildJobs).Count -eq 1) '父作业挂一个子作业'

# —— 5) Remove 后查无 ——
Remove-Job -Job $job -Force
Check ($null -eq (Get-Job -Name 'tut-job' -ErrorAction SilentlyContinue)) 'Remove-Job 后会话内查无此作业'

# —— 6) 作业初始目录：两引擎不同（值不进对账区，只断言可取到路径） ——
$locJob = Start-Job -ScriptBlock { (Get-Location).Path }
$null = Wait-Job -Job $locJob -Timeout 60
$jobLoc = Receive-Job -Job $locJob
Check ("$jobLoc" -match '\S') '作业上下文独立可测（初始目录两引擎不同 [env]） [env]'
Remove-Job -Job $locJob -Force

# —— 7) ThreadJob 探针（pwsh 7 内置；5.1 视安装情况） ——
if (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue) {
    $tj = Start-ThreadJob -ScriptBlock { 2 * 21 }
    $null = Wait-Job -Job $tj -Timeout 60
    Check ((Receive-Job -Job $tj) -eq 42) 'ThreadJob 线程级作业可用 [env]'
    Remove-Job -Job $tj -Force
}
else { Skip '本引擎默认路径无 ThreadJob 模块（5.1 需另装） [env]' }

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
