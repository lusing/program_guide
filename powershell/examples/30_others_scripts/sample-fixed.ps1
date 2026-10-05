<#
.SYNOPSIS
Remove-OldFiles 删除超过保留期的文件（修复版）。
.DESCRIPTION
病脚本三处的对照修复：参数面收敛、ShouldProcess 防护、结果对象输出。
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$Path,

    [ValidateRange(1, 3650)]
    [int]$RetentionDays = 30,

    [string[]]$Exclude = @()
)
$removed = 0
Get-ChildItem -Path $Path -File -Recurse |
    Where-Object { $Exclude -notcontains $_.Name } |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) } |
    ForEach-Object {
        if ($PSCmdlet.ShouldProcess($_.FullName, '删除过期文件')) {
            Remove-Item -Path $_.FullName -Force
            $removed++
        }
    }
[pscustomobject]@{ Path = $Path; Removed = $removed; At = Get-Date }
