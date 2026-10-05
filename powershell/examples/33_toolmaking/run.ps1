#Requires -Version 5.1
# 示例 33：工具制作收官——模块全流程：搭模块/清单→导入→取数→双格式导出→WhatIf→Pester→Analyzer
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

$work = Join-Path $PSScriptRoot 'tmp-project'
$modDir = Join-Path $work 'InventoryModule'
New-Item -ItemType Directory -Force -Path $modDir | Out-Null

# —— 1) 组装：模块代码 + New-ModuleManifest 清单 ——
Copy-Item -Path (Join-Path $PSScriptRoot 'InventoryModule.psm1') -Destination $modDir -Force
New-ModuleManifest -Path (Join-Path $modDir 'InventoryModule.psd1') `
    -ModuleVersion '1.2.0' -Author 'tutorial' -RootModule 'InventoryModule.psm1' `
    -Description '收官项目：机器磁盘库存工具' `
    -FunctionsToExport @('Get-InvMachineInfo', 'Export-InvReport') `
    -PowerShellVersion '5.1' | Out-Null
Check (Test-Path (Join-Path $modDir 'InventoryModule.psd1')) '清单生成（版本 1.2.0）'
Check ((Test-ModuleManifest -Path (Join-Path $modDir 'InventoryModule.psd1')).Version.Major -eq 1) 'Test-ModuleManifest 通过'

# —— 2) 导入与取数（管道函数 + 阈值参数） ——
Import-Module (Join-Path $modDir 'InventoryModule.psd1') -Force
$info = @('localhost') | Get-InvMachineInfo
Check (@($info).Count -ge 1) '管道取数产出对象'
Check (@($info)[0].PSObject.Properties['Low'] -ne $null) '结果含 Low 标记列'
$allLow = @('localhost' | Get-InvMachineInfo -MinFreePct 100)
Check (@($allLow | Where-Object Low).Count -eq @($allLow).Count) '极端阈值 100：全部标记 Low'

# —— 3) 双格式导出与往返 ——
$csvPath = Join-Path $work 'inv.csv'
$info | Export-InvReport -Path $csvPath -Format Csv
Check ((Test-Path $csvPath) -and @(Import-Csv $csvPath).Count -eq @($info).Count) 'CSV 导出往返守恒'
$jsonPath = Join-Path $work 'inv.json'
$info | Export-InvReport -Path $jsonPath -Format Json
Check ((Get-Content $jsonPath -Raw) -match '\{') 'JSON 导出结构可读回'
$ghost = Join-Path $work 'ghost.csv'
$info | Export-InvReport -Path $ghost -WhatIf
Check (-not (Test-Path $ghost)) 'Export 的 ShouldProcess 接线（-WhatIf 不落盘）'
$fmtErr = $false
try { $info | Export-InvReport -Path (Join-Path $work 'x') -Format 'Xml' } catch { $fmtErr = $true }
Check ($fmtErr) 'ValidateSet 拦截非法格式'

# —— 4) Pester 回归（第三层防线） ——
$pester = Get-Module -ListAvailable Pester | Sort-Object Version -Descending | Select-Object -First 1
if ($pester -and $pester.Version.Major -ge 5) {
    $r = Invoke-Pester -Path (Join-Path $PSScriptRoot 'InventoryModule.Tests.ps1') -Output None -PassThru
    Check ($r.FailedCount -eq 0) '模块 Pester 回归全绿 [env]'
}
else { Skip '本机无 Pester v5+，回归跳过（32.3 讲安装） [env]' }

# —— 5) ScriptAnalyzer 体检（第二层防线） ——
$analyzer = Get-Module -ListAvailable PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
if ($analyzer) {
    $findings = @(Invoke-ScriptAnalyzer -Path (Join-Path $modDir 'InventoryModule.psm1'))
    Check (@($findings | Where-Object Severity -eq 'Error').Count -eq 0) 'Analyzer 零 Error 级诊断 [env]'
}
else { Skip '本机无 PSScriptAnalyzer，体检跳过（32.5 讲安装） [env]' }

# —— 6) 卸载与清理 ——
Remove-Module -Name InventoryModule
Remove-Item $work -Recurse -Force
Check (-not (Test-Path $work)) '项目临时目录清理'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
