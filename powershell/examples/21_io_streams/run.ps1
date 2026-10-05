#Requires -Version 5.1
# 示例 21：输入输出——管道 vs 直写、流重定向、偏好变量、Tee、NonInteractive 行为
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) Write-Output 进管道 vs Write-Host 直写 ——
$viaPipe = Write-Output 'Hello' | Where-Object { $_.Length -gt 10 }
Check (@($viaPipe).Count -eq 0) 'Write-Output 进管道：可被下游筛掉'
Check (('Hello' | Where-Object { $_.Length -gt 10 }) -eq $null) '裸输出默认就是 Write-Output'
$hostInfo = & { Write-Host 'DIRECT' } 6>&1
Check ("$hostInfo" -match 'DIRECT') 'Write-Host 走信息流：6>&1 可捕获'

# —— 2) 流重定向：警告(3)、错误(2)并入输出 ——
$warn = & { Write-Warning '小心' } 3>&1
Check ("$warn" -match '小心') '警告流 3>&1 可捕获'
$err = & { Write-Error '坏了' } 2>&1
Check ("$err" -match '坏了') '错误流 2>&1 可捕获'

# —— 3) 偏好变量：Verbose 默认沉默、开关点亮 ——
$silent = & { Write-Verbose 'v' } 4>&1
Check (@($silent).Count -eq 0) 'Verbose 默认沉默（SilentlyContinue）'
$lit = & { Write-Verbose 'v' -Verbose } 4>&1
Check ("$lit" -match 'v') '-Verbose 单命令点亮'
$oldVP = $VerbosePreference
$VerbosePreference = 'Continue'
$globalLit = & { Write-Verbose 'gv' } 4>&1
$VerbosePreference = $oldVP
Check ("$globalLit" -match 'gv') '全局偏好变量点亮后输出'

# —— 4) Tee-Object：落档 + 继续管道 ——
$work = Join-Path $PSScriptRoot 'tmp-io'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$teeFile = Join-Path $work 'tee.txt'
$count = 'a', 'b', 'c' | Tee-Object -FilePath $teeFile | Measure-Object | Select-Object -ExpandProperty Count
Check ($count -eq 3 -and (Get-Content $teeFile).Count -eq 3) 'Tee 双通道：管道与文件各得全量'
Remove-Item $work -Recurse -Force

# —— 5) NonInteractive 下 Read-Host 当场报错（本进程即 -NonInteractive） ——
$rhErr = $false
try { Read-Host '永远等不到的回答' | Out-Null } catch { $rhErr = $true }
Check ($rhErr) 'NonInteractive 下 Read-Host 报错而非挂死'

# —— 6) Write-Progress 不在六流内但命令可用 ——
Check ($null -ne (Get-Command Write-Progress)) 'Write-Progress 命令存在（编外成员）'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
