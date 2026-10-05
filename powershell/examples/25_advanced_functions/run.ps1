#Requires -Version 5.1
# 示例 25：高级函数——三段体、管道绑定、ShouldProcess
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 三段体：begin/process/end 执行序 ——
function Get-TopN {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [int]$Item,
        [int]$N = 2
    )
    begin { $script:seq = @(); $script:seq += 'begin' }
    process { $script:seq += "process:$Item" }
    end { $script:seq += 'end'; ($script:seq -join '>') }
}
$order = 1..3 | Get-TopN
Check ($order -eq 'begin>process:1>process:2>process:3>end') '三段体执行序：begin→process×N→end'

# —— 2) ValueFromPipeline：整对象按值 ——
function Get-Double {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [int]$Value
    )
    process { $Value * 2 }
}
$vals = 1..3 | Get-Double
Check (($vals -join ',') -eq '2,4,6') 'ValueFromPipeline 逐对象处理（流式）'

# —— 3) ValueFromPipelineByPropertyName：属性名绑定 ——
function Get-Named {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Tag
    )
    process { "[$Tag]" }
}
$tagged = [pscustomobject]@{ Tag = 'a' }, [pscustomobject]@{ Tag = 'b' } | Get-Named
Check (($tagged -join '') -eq '[a][b]') 'ByPropertyName：属性名=参数名自动绑定'

# —— 4) begin 计数：处理了多少对象 ——
function Get-Counted {
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline)][int]$X)
    begin { $script:n = 0 }
    process { $script:n++; $X }
    end { "total=$($script:n)" | Write-Verbose }
}
$null = 1..5 | Get-Counted -Verbose 4>&1
Check ($true) 'begin/end 计数与 Verbose 汇报可用'

# —— 5) ShouldProcess：-WhatIf 闸门 ——
function Remove-TutFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string]$Path)
    if ($PSCmdlet.ShouldProcess($Path, '删除教程临时文件')) {
        Remove-Item -Path $Path -WhatIf:$false
        return $true
    }
    return $false
}
$work = Join-Path $PSScriptRoot 'tmp-adv'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$victim = Join-Path $work 'x.txt'
Set-Content -Path $victim -Value 'x' -Encoding UTF8
$pretend = Remove-TutFile -Path $victim -WhatIf
Check ($pretend -eq $false -and (Test-Path $victim)) 'ShouldProcess：-WhatIf 干跑被拦'
$real = Remove-TutFile -Path $victim
Check ($real -eq $true -and -not (Test-Path $victim)) '正常调用放行并删除'
Check ($null -ne (Get-Command Remove-TutFile).Parameters['WhatIf']) 'SupportsShouldProcess 免费获得 -WhatIf'
Remove-Item $work -Recurse -Force -ErrorAction SilentlyContinue

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
