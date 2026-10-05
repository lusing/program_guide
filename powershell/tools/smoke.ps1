#Requires -Version 5.1
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

Check ((1..5 | Measure-Object).Count -eq 5) '管道计数'
Check ([int]'42' + 1 -eq 43) '类型转换'
Check (@{ a = 1; b = 2 }.Count -eq 2) '哈希表'
$dir = Join-Path $PSScriptRoot 'tmp-smoke'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Set-Content -Path (Join-Path $dir '清单.txt') -Value '中文内容' -Encoding UTF8
Check ((Get-ChildItem $dir).Count -eq 1) '临时目录与中文文件名'
Remove-Item $dir -Force -Recurse
Write-Host '日志通道：中文字符串可读性检查'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
