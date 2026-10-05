#Requires -Version 5.1
# 示例 24：函数与作用域——输出汇流、遮蔽与穿透、switch 参数、库点源
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 函数定义与参数 ——
function Get-Square {
    param([int]$N = 2)
    $N * $N
}
Check ((Get-Square) -eq 4) '默认参数调用函数'
Check ((Get-Square -N 7) -eq 49) '命名参数调用函数'

# —— 2) 输出真相：一切进管道的都算返回值 ——
function Get-Streams {
    '裸字符串'
    return 'return 的值'
}
$out = Get-Streams
Check (@($out).Count -eq 2 -and $out[1] -eq 'return 的值') '多源汇流：裸输出与 return 同为返回值'
function Get-Quiet {
    $null = ('丢弃的表达式' | Out-Null)
    return '仅此一句'
}
Check (@(Get-Quiet).Count -eq 1) '显式丢弃守住返回值纯净'

# —— 3) 作用域：遮蔽与穿透 ——
$x = 'outer'
function Set-Shadow { $x = 'inner'; return $x }
$shadowResult = Set-Shadow
Check ($shadowResult -eq 'inner' -and $x -eq 'outer') '写不透楼层：局部遮蔽不影响外层'
function Set-Pierce { $script:x = 'pierced' }
$null = Set-Pierce
Check ($x -eq 'pierced') '$script: 修饰符穿透写入'
$x = 'outer'

# —— 4) 读向下透 ——
$base = 'from-outer'
function Read-Through { return $base }
Check ((Read-Through) -eq 'from-outer') '读向下透：函数能读外层变量'

# —— 5) switch 参数 ——
function Invoke-Mode {
    param([switch]$Fast)
    if ($Fast) { 'fast' } else { 'normal' }
}
Check ((Invoke-Mode) -eq 'normal' -and (Invoke-Mode -Fast) -eq 'fast') 'switch 参数：带即真'

# —— 6) 函数库：点源加载 ——
$lib = Join-Path $PSScriptRoot 'asset-lib.ps1'
. $lib
Check ((Get-LibGreeting 'ops') -eq 'hello ops') '点源加载函数库并调用'
Check ((Get-Command Get-LibGreeting).CommandType -eq 'Function') '库函数以 Function 形态注册'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
