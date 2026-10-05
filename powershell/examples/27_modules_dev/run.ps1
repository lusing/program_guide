#Requires -Version 5.1
# 示例 27：模块开发——搭模块/清单、导入、导出面、内部函数不可见、Remove 再 Import 刷新（自演自净）
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 搭建：目录 + .psm1 + New-ModuleManifest 清单 ——
$modDir = Join-Path $PSScriptRoot 'tmp-mod\PsTut'
New-Item -ItemType Directory -Force -Path $modDir | Out-Null
@'
function Get-TutVersion {
    [CmdletBinding()]
    param()
    return 'v1'
}
function Initialize-TutInternal {
    return 'internal-only'
}
Export-ModuleMember -Function Get-TutVersion
'@ | Set-Content -Path (Join-Path $modDir 'PsTut.psm1') -Encoding UTF8
New-ModuleManifest -Path (Join-Path $modDir 'PsTut.psd1') `
    -ModuleVersion '1.0.0' -Author 'tutorial' -RootModule 'PsTut.psm1' `
    -Description '教程演示模块' -FunctionsToExport @('Get-TutVersion') `
    -PowerShellVersion '5.1' | Out-Null
Check (Test-Path (Join-Path $modDir 'PsTut.psd1')) 'New-ModuleManifest 生成清单'

# —— 2) 导入与清单验证 ——
$manifest = Test-ModuleManifest -Path (Join-Path $modDir 'PsTut.psd1')
Check ($manifest.Version.ToString() -eq '1.0.0') 'Test-ModuleManifest 读回版本一致'
Import-Module (Join-Path $modDir 'PsTut.psd1') -Force
Check ((Get-TutVersion) -eq 'v1') '导入后导出函数可调用'

# —— 3) 导出面：内部函数不可见 ——
Check ($null -eq (Get-Command Initialize-TutInternal -ErrorAction SilentlyContinue)) '内部函数 Get-Command 查无（导出闸门）'
Check (@(Get-Command -Module PsTut).Count -eq 1) '模块对外只贡献一个命令'

# —— 4) 开发循环：改代码须 Remove 再 Import ——
@'
function Get-TutVersion {
    [CmdletBinding()]
    param()
    return 'v2'
}
function Initialize-TutInternal {
    return 'internal-only'
}
Export-ModuleMember -Function Get-TutVersion
'@ | Set-Content -Path (Join-Path $modDir 'PsTut.psm1') -Encoding UTF8
Import-Module (Join-Path $modDir 'PsTut.psd1')
$stale = (Get-TutVersion)
Check ($stale -eq 'v1') '普通再 Import 不刷新（内存驻留；-Force 才会重载）'
Remove-Module -Name PsTut
Import-Module (Join-Path $modDir 'PsTut.psd1') -Force
Check ((Get-TutVersion) -eq 'v2') 'Remove 后再 Import 才加载新版'

# —— 5) 收尾清理 ——
Remove-Module -Name PsTut
Remove-Item (Split-Path $modDir -Parent) -Recurse -Force
Check (-not (Test-Path (Split-Path $modDir -Parent))) '临时模块目录清理'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
