# math.ps1 —— 被测函数（32 章示例）
function Get-TutDouble {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$Value
    )
    return $Value * 2
}
