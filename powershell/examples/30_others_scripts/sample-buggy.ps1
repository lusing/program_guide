# sample-buggy.ps1 —— 三病样本（过度参数化+硬编码兜底 / 无变更防护 / 无错误处理与输出）
# 教学用途：病脚本的完整形态，供五步阅读法剖析。请勿在生产使用。
param (
    [string]$Path,
    [string]$LogPath = 'C:\logs\cleanup.log',
    [string]$TempPath = 'C:\temp',
    [int]$RetentionDays = 30,
    [string[]]$Exclude = @('keep'),
    [switch]$WhatIfLocal
)
if (-not $Path) { $Path = 'C:\inetpub\logs' }
$files = Get-ChildItem -Path $Path -Recurse
foreach ($file in $files) {
    if ($Exclude -contains $file.Name) { continue }
    if ($file.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays)) {
        Remove-Item $file.FullName -Recurse -Force
    }
}
Write-Host 'Done!'
