#Requires -Version 5.1
# 示例 23：参数化——注释帮助、CmdletBinding 免费参数、验证属性门口拦截、Mandatory 非交互行为
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

$adv = Join-Path $PSScriptRoot 'asset-adv.ps1'

# —— 1) 注释帮助：离线可读 ——
$help = Get-Help $adv
Check ("$($help.Synopsis)" -match '验证属性') '注释帮助的 SYNOPSIS 可读'
Check (@(Get-Help $adv -Parameter Color).Count -eq 1) '单参数帮助（.PARAMETER 段）可查'

# —— 2) CmdletBinding：免费通用参数 ——
$cmd = Get-Command $adv
Check ($cmd.Parameters.ContainsKey('Verbose')) 'CmdletBinding 免费获得 -Verbose'
Check ($cmd.Parameters.ContainsKey('ErrorAction')) '免费获得 -ErrorAction'
Check (-not $cmd.Parameters.ContainsKey('WhatIf')) '未声明 SupportsShouldProcess 则无 -WhatIf（诚实）'

# —— 3) 验证属性：门口拦截 ——
$badColor = $false
try { & $adv -Name 'x' -Color 'Pink' | Out-Null } catch { $badColor = ($_.Exception.GetType().Name -match 'ParameterBindingValidation') }
Check ($badColor) 'ValidateSet 拦截非法值（ParameterBindingValidationException）'
$badRange = $false
try { & $adv -Name 'x' -Level 99 | Out-Null } catch { $badRange = $true }
Check ($badRange) 'ValidateRange 拦截越界值'
$okCall = & $adv -Name 'demo' -Color 'Red' -Level 3
Check ("$okCall" -eq 'demo/Red/3') '合法参数正常通过'
$defaultCall = & $adv -Name 'demo'
Check ("$defaultCall" -eq 'demo/Green/5') '默认值生效（Color/Level）'

# —— 4) Mandatory + 非交互：拒绝等待（本进程即 NonInteractive） ——
$mandatoryErr = $false
try { & $adv | Out-Null } catch { $mandatoryErr = $true }
Check ($mandatoryErr) 'Mandatory 缺参在 NonInteractive 下报错'

# —— 5) 空值拦截 ——
$emptyErr = $false
try { & $adv -Name '' | Out-Null } catch { $emptyErr = $true }
Check ($emptyErr) 'ValidateNotNullOrEmpty 拦截空串'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
