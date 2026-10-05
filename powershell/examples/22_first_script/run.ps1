#Requires -Version 5.1
# 示例 22：第一个脚本——param 三态、& vs 点源、exit 退出码、#Requires 门槛
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

$asset = Join-Path $PSScriptRoot 'asset-param.ps1'
$scope = Join-Path $PSScriptRoot 'asset-scope.ps1'
$exitr = Join-Path $PSScriptRoot 'asset-exit.ps1'

# —— 1) param()：默认值 / 命名参数 / 位置参数 ——
$default = & $asset
Check ("$default" -eq 'default-1') '默认参数（不给参数）'
$named = & $asset -Name 'srv' -Count 3
Check ("$named" -eq 'srv-3') '命名参数显式传入'
$positional = & $asset 'pos' 9
Check ("$positional" -eq 'pos-9') '位置参数按 param 顺序'

# —— 2) $args 兜底（无 param 的脚本） ——
$argsOut = & (Join-Path $PSScriptRoot 'asset-args.ps1') one two
Check ("$argsOut" -eq 'one|two') '无 param 时 $args 兜底'

# —— 3) & 与点源的作用域对照 ——
Remove-Variable scopeProbe -ErrorAction SilentlyContinue
& $scope
$afterCall = Test-Path Variable:scopeProbe
Check ($afterCall -eq $false) '& 调用：脚本作用域隔离（变量出不来）'
. $scope
$afterDot = (Get-Variable scopeProbe -ErrorAction SilentlyContinue).Value
Check ("$afterDot" -eq 'set-inside') '点源加载：变量写入当前作用域'
Remove-Variable scopeProbe -ErrorAction SilentlyContinue

# —— 4) exit 与 $LASTEXITCODE ——
$null = & $exitr
Check ($LASTEXITCODE -eq 42) 'exit 42 经 $LASTEXITCODE 传出'
$LASTEXITCODE = 0

# —— 5) $PSCOMMANDPATH/$PSScriptRoot：脚本知道自己在哪 ——
Check ((& $asset) -ne $null) '辅助脚本可执行（$PSScriptRoot 定位素材）'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
