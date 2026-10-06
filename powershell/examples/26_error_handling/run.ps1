#Requires -Version 5.1
# 示例 26：错误处理——双形态、升级、分流、finally、ErrorRecord 解剖、-ErrorVariable、throw/exit
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 双形态：非终止错误不进 catch ——
$reached = $true
try {
    Get-Content -Path (Join-Path $PSScriptRoot 'definitely-missing.txt') -ErrorAction SilentlyContinue
} catch { $reached = $false }
Check ($reached) '非终止错误（SilentlyContinue）不进 catch、脚本继续'

$caught = $false
try {
    Get-Content -Path (Join-Path $PSScriptRoot 'definitely-missing.txt') -ErrorAction Stop
} catch { $caught = $true }
Check ($caught) '-ErrorAction Stop 升级为终止错误后被 catch 接住'

# —— 2) 按类型分流 ——
$pathErr = 'none'
try {
    Get-Content -Path (Join-Path $PSScriptRoot 'missing\deeper.txt') -ErrorAction Stop
}
catch [System.Management.Automation.ItemNotFoundException] { $pathErr = 'item' }
catch { $pathErr = "other:$($_.Exception.GetType().Name)" }
Check ($pathErr -eq 'item') "catch 按异常类型分流（ItemNotFoundException，实际=$pathErr）"

# —— 3) ErrorRecord 解剖 ——
try {
    Get-Content -Path (Join-Path $PSScriptRoot 'definitely-missing.txt') -ErrorAction Stop
} catch {
    Check ($_.Exception.Message -match '\S') 'Exception.Message 有人类可读信息'
    Check ($_.FullyQualifiedErrorId -match 'PathNotFound') 'FullyQualifiedErrorId 是稳定身份证'
    Check ($_.InvocationInfo.PositionMessage -match 'Get-Content') 'InvocationInfo 定位到出错语句'
    Check ($null -ne $_.TargetObject) 'TargetObject 指明出错目标'
}

# —— 4) finally 必执行 ——
$fin = 0
function Test-Finally {
    try { throw 'boom' } catch { return 'from-catch' } finally { $script:fin++ }
}
$null = Test-Finally
Check ($fin -eq 1) 'finally 在 return 之后仍然执行'

# —— 5) -ErrorVariable 旁路收集（宽容执行 + 事后审计） ——
$work = Join-Path $PSScriptRoot 'tmp-err'
New-Item -ItemType Directory -Force -Path $work | Out-Null
Set-Content -Path (Join-Path $work 'ok.txt') -Value 'fine' -Encoding UTF8
$missed = $null
Get-Content -Path (Join-Path $work 'ok.txt'), (Join-Path $work 'bad1.txt'), (Join-Path $work 'bad2.txt') `
    -ErrorVariable missed -ErrorAction SilentlyContinue | Out-Null
Check (@($missed).Count -eq 2) '-ErrorVariable 收到两份错误记录'
Check (@($missed | ForEach-Object { $_.TargetObject } | Where-Object { $_ -match 'bad' }).Count -eq 2) 'TargetObject 列出坏文件清单'
Remove-Item $work -Recurse -Force

# —— 6) throw 与 exit 分工 ——
function Assert-TutPath {
    param([string]$Path)
    if (-not (Test-Path $Path)) { throw "路径不存在：$Path" }
    return $true
}
$threw = $false
try { Assert-TutPath -Path 'Z:\nowhere' } catch { $threw = ($_.Exception.Message -match 'Z:\\nowhere') }
Check ($threw) 'throw 对内抛出（携带消息）'

# 子进程用**当前引擎自身**（两通道里 5.1 与 pwsh 7 的可执行名不同，写死 'pwsh' 在 5.1 侧会找不到）。
# -WindowStyle 只在 Windows 版受支持：参数**在参数表里存在**（ContainsKey 为真），
# 但非 Windows 版调用时抛 "not supported ... on this edition of PowerShell"——
# 所以只能按"实际调用是否抛错"这个事实条件分支，不能按参数表判断（CHEATSheet 26a）。
$engineExe = (Get-Process -Id $PID).Path
$exitArgs = @('-NoProfile', '-Command', 'try { throw } catch { exit 7 }')
$probe = $null
try {
    $probe = Start-Process -FilePath $engineExe -ArgumentList $exitArgs -Wait -PassThru -WindowStyle Hidden
    Check ($probe.ExitCode -eq 7) 'exit 对外汇报（子进程退出码 7 直通，-WindowStyle Hidden 生效）'
}
catch {
    # 本 edition 不支持 -WindowStyle：去掉它语义不变，退出码仍应直通
    $probe = Start-Process -FilePath $engineExe -ArgumentList $exitArgs -Wait -PassThru
    Check ($probe.ExitCode -eq 7) 'exit 对外汇报（子进程退出码 7 直通；本 edition 不支持 -WindowStyle） [platform]'
}

# —— 7) $Error 仓库 ——
$Error.Clear()
Write-Error '受控错误' -ErrorAction SilentlyContinue
Check ($Error[0].Exception.Message -match '受控错误') '$Error[0] 是最新错误（后悔药）'
$Error.Clear()

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
