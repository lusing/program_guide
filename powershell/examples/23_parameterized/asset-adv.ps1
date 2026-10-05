<#
.SYNOPSIS
演示用高级脚本：验证属性与参数绑定行为。
.DESCRIPTION
被 23 章示例调用来验证 ValidateSet/ValidateRange/Mandatory 的门口拦截。
注意：本帮助块必须位于文件第一行（前面不能有任何语句或普通注释，否则不被识别）。
.PARAMETER Name
必选且非空的名字。
.PARAMETER Color
只许 Red/Green/Blue 三选一。
.PARAMETER Level
1..10 的数值。
.EXAMPLE
.\asset-adv.ps1 -Name x -Color Red -Level 3
#>
[CmdletBinding()]
[OutputType([string])]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [ValidateSet('Red', 'Green', 'Blue')]
    [string]$Color = 'Green',

    [ValidateRange(1, 10)]
    [int]$Level = 5
)
"$Name/$Color/$Level"
