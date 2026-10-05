#Requires -Version 5.1
# 示例 32：测试与质量——Pester 探针与现代语法、-PassThru 断言、Analyzer 干净/脏双扫
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) Pester 探针：版本决定语法分支 ——
$pester = Get-Module -ListAvailable Pester | Sort-Object Version -Descending | Select-Object -First 1
if ($pester -and $pester.Version.Major -ge 5) {
    $r = Invoke-Pester -Path (Join-Path $PSScriptRoot 'math.Tests.ps1') -Output None -PassThru
    Check ($r.FailedCount -eq 0) '现代语法测试全绿（v5/v6） [env]'
    Check ($r.PassedCount -ge 4) '覆盖正常/边界/类型/异常多条款 [env]'
}
elseif ($pester) {
    Skip "本机最高 Pester 为 v$($pester.Version)（Windows 内置 3.4），现代语法跳过——正文 32.3 讲升级 [env]"
}
else {
    Skip '本机无 Pester（Windows 通常内置 3.4；正文 32.3 讲安装） [env]'
}

# —— 2) ScriptAnalyzer：干净样本与脏样本双扫 ——
$analyzer = Get-Module -ListAvailable PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
if ($analyzer) {
    $work = Join-Path $PSScriptRoot 'tmp-sa'
    New-Item -ItemType Directory -Force -Path $work | Out-Null
    $clean = Join-Path $work 'clean.ps1'
    @'
function Get-CleanDemo {
    [CmdletBinding()]
    param([int]$Value)
    return $Value + 1
}
'@ | Set-Content -Path $clean -Encoding UTF8
    $dirty = Join-Path $work 'dirty.ps1'
    @'
function grab-stuff {
    Write-Host '看我看我'
}
'@ | Set-Content -Path $dirty -Encoding UTF8
    $cleanFindings = @(Invoke-ScriptAnalyzer -Path $clean)
    Check ($cleanFindings.Count -eq 0) '干净样本零诊断 [env]'
    $dirtyFindings = @(Invoke-ScriptAnalyzer -Path $dirty)
    Check ($dirtyFindings.Count -ge 2) '脏样本命中多条诊断 [env]'
    Check (@($dirtyFindings | Where-Object RuleName -eq 'PSAvoidUsingWriteHost').Count -eq 1) '命中 PSAvoidUsingWriteHost（Write-Host 规则） [env]'
    Check (@($dirtyFindings | Where-Object RuleName -match 'ApprovedVerb').Count -ge 1) '命中未批准动词规则（grab-） [env]'
    Check ($null -ne ($dirtyFindings[0].PSObject.Properties['Line'])) '诊断对象带行号定位 [env]'
    Remove-Item $work -Recurse -Force
}
else {
    Skip '本机无 PSScriptAnalyzer（正文 32.5：Install-Module PSScriptAnalyzer -Scope CurrentUser） [env]'
}

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
