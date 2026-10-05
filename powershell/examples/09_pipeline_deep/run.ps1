#Requires -Version 5.1
# 示例 09：深入管道——ByValue / ByPropertyName / 空绑 / 改名 / 开盒 / 括号
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

$work = Join-Path $PSScriptRoot 'tmp-bind'
New-Item -ItemType Directory -Force -Path $work | Out-Null

# —— 1) 两查动作：A 的类型、B 的绑定标注 ——
Check ((@('x') | Get-Member)[0].TypeName -eq 'System.String') 'Get-Content 类命令输出 String（ByValue 判据）'
$svcParam = (Get-Command Get-Service).Parameters['Name']
Check ($svcParam.ParameterType -eq [string[]]) 'Get-Service -Name 声明 string[]'

# —— 2) ByValue：String 整对象绑给 -Name ——
$byValue = 'winmgmt' | Get-Service
Check (@($byValue).Count -eq 1 -and $byValue.Name -eq 'winmgmt') 'ByValue：字符串直连 -Name'

# —— 3) 参数别名参与绑定：ServiceName 恰是 -Name 的别名 ——
$viaAlias = [pscustomobject]@{ ServiceName = 'winmgmt' } | Get-Service
Check (@($viaAlias).Count -eq 1 -and $viaAlias.Name -eq 'winmgmt') 'ByPropertyName 可经参数别名（ServiceName→-Name）绑定'
$viaMiss = [pscustomobject]@{ SvcName = 'winmgmt' } | Get-Service
Check (@($viaMiss).Count -eq 0) '空绑：属性名真正对不上时拿不到目标服务'

# —— 4) 改名桥接：计算属性把 ServiceName 改成 Name ——
$bridged = [pscustomobject]@{ ServiceName = 'winmgmt' } |
    Select-Object @{ n = 'Name'; e = { $_.ServiceName } } | Get-Service
Check (@($bridged).Count -eq 1 -and $bridged.Name -eq 'winmgmt') '改名桥接：ByPropertyName 通道打通'

# —— 5) ByPropertyName 双参数同绑：CSV 列名 = 参数名（New-Alias） ——
$csv = Join-Path $work 'aliases.csv'
@'
Name,Value
tutd,Get-ChildItem
tutsel,Select-Object
'@ | Set-Content -Path $csv -Encoding UTF8
Import-Csv -Path $csv | New-Alias
Check ((Get-Alias -Name tutd).Definition -eq 'Get-ChildItem') 'ByPropertyName：CSV 灌入 New-Alias（d 列）'
Check ((Get-Alias -Name tutsel).Definition -eq 'Select-Object') 'ByPropertyName：Value 列同绑'
Remove-Item -Path Alias:\tutd, Alias:\tutsel -ErrorAction SilentlyContinue
Check ($null -eq (Get-Alias -Name tutd -ErrorAction SilentlyContinue)) '别名清理'

# —— 6) 开盒：-Property 是包裹，-ExpandProperty 是裸值 ——
$namesCsv = Join-Path $work 'names.csv'
@'
Name
winmgmt
'@ | Set-Content -Path $namesCsv -Encoding UTF8
$boxed = Import-Csv -Path $namesCsv | Select-Object -Property Name
$opened = Import-Csv -Path $namesCsv | Select-Object -ExpandProperty Name
Check (@($boxed)[0].GetType().Name -eq 'PSCustomObject') '-Property 仍是包裹'
Check (@($opened)[0].GetType().Name -eq 'String') '-ExpandProperty 开盒得裸值'
Check (@(Get-Service -Name $opened).Count -eq 1) '裸值数组可直接喂参数'

# —— 7) 括号强喂：绕过绑定的圆括号 ——
$names = Join-Path $work 'names.txt'
Set-Content -Path $names -Value 'winmgmt' -Encoding UTF8
Check (@(Get-Service -Name (Get-Content $names)).Count -eq 1) '圆括号先执行再喂参'

# —— 8) 双引擎差异：Get-Service -ComputerName 仅 5.1 存在（ServiceController 远程被 pwsh 7 移除） ——
if ((Get-Command Get-Service).Parameters.ContainsKey('ComputerName')) {
    Check ($true) '本引擎保留 -ComputerName（5.1 的 .NET 服务远程） [ch51-only]'
}
else {
    Skip 'pwsh 7 已移除 Get-Service -ComputerName，跨机请用 Invoke-Command 或 CIM（13/14 章） [ch7-only]'
}

Remove-Item $work -Recurse -Force
Check (-not (Test-Path $work)) '临时目录清理'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
