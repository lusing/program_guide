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

# 本章要演示的是**绑定引擎的规则**，不是某个 cmdlet 的业务。
# 原书用 Get-Service -Name 作锚点（别名 ServiceName）；Unix 上 Get-Service 不存在，
# 改用 Get-Process -Name（别名 ProcessName）——绑定元数据形状完全一致：
#   -Name 是 string[]、别名分别是 ServiceName / ProcessName、ByPropertyName 可经别名命中。
# ByValue 那条另有跨平台锚点：ForEach-Object -Process（见下，CHEATSheet 9a）。
$onWindows = [bool](Get-Command Get-Service -ErrorAction SilentlyContinue)
if ($onWindows) {
    $target = 'winmgmt'
    $aliasProp = 'ServiceName'
    $wrongProp = 'SvcName'
    $getCmd = 'Get-Service'
}
else {
    # 取一个当前确实存在的进程名，保证后面每条断言都有确定的对象可绑
    $target = (Get-Process | Where-Object { $_.Name } | Select-Object -First 1).Name
    $aliasProp = 'ProcessName'
    $wrongProp = 'ProcName'
    $getCmd = 'Get-Process'
}

# —— 1) 两查动作：A 的类型、B 的绑定标注 ——
Check ((@('x') | Get-Member)[0].TypeName -eq 'System.String') 'Get-Content 类命令输出 String（ByValue 判据）'
$nameParam = (Get-Command $getCmd).Parameters['Name']
Check ($nameParam.ParameterType -eq [string[]]) "$getCmd -Name 声明 string[]"

# —— 2) ByValue：整个 String 对象绑给值类型的参数 ——
# Get-Service 的 -Name 走 ByValue 集；Get-Process 在 Unix 版上 -Name 集只实现 ByPropertyName
# （元数据仍声明 ByValue=True，实际喂裸字符串报"cannot be bound"），
# 所以跨平台这条改锚在 ForEach-Object -Process 上——它的 ByValue 两引擎都真跑通。
$byValue = @('winmgmt' | ForEach-Object -Process { "[$_]" })
Check ($byValue.Count -eq 1 -and $byValue[0] -eq '[winmgmt]') 'ByValue：字符串直连值参数（ForEach-Object -Process）'
if ($onWindows) {
    $svcByValue = @('winmgmt' | Get-Service)
    Check ($svcByValue.Count -eq 1 -and $svcByValue.Name -eq 'winmgmt') 'ByValue：字符串直连 -Name [platform]'
}
else { Skip "本平台 Get-Process -Name 集只实现 ByPropertyName（喂裸字符串报 cannot be bound），ByValue 改用 ForEach-Object 演示 [platform]" }

# —— 3) 参数别名参与绑定：ProcessName 恰是 -Name 的别名（Windows 上是 ServiceName） ——
$viaAlias = @([pscustomobject]@{ $aliasProp = $target } | & $getCmd)
Check ($viaAlias.Count -eq 1 -and $viaAlias[0].Name -eq $target) "ByPropertyName 可经参数别名（$aliasProp→-Name）绑定"
$viaMiss = @([pscustomobject]@{ $wrongProp = $target } | & $getCmd -ErrorAction SilentlyContinue)
Check ($viaMiss.Count -eq 0) '空绑：属性名真正对不上时拿不到目标'

# —— 4) 改名桥接：计算属性把别名属性名改成 Name ——
$bridged = @([pscustomobject]@{ $aliasProp = $target } |
    Select-Object @{ n = 'Name'; e = { $_.$aliasProp } } | & $getCmd)
Check ($bridged.Count -eq 1 -and $bridged[0].Name -eq $target) '改名桥接：ByPropertyName 通道打通'

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
"Name`n$target" | Set-Content -Path $namesCsv -Encoding UTF8
$boxed = Import-Csv -Path $namesCsv | Select-Object -Property Name
$opened = Import-Csv -Path $namesCsv | Select-Object -ExpandProperty Name
Check (@($boxed)[0].GetType().Name -eq 'PSCustomObject') '-Property 仍是包裹'
Check (@($opened)[0].GetType().Name -eq 'String') '-ExpandProperty 开盒得裸值'
Check (@(& $getCmd -Name $opened).Count -eq 1) '裸值数组可直接喂参数'

# —— 7) 括号强喂：绕过绑定的圆括号 ——
$names = Join-Path $work 'names.txt'
Set-Content -Path $names -Value $target -Encoding UTF8
Check (@(& $getCmd -Name (Get-Content $names)).Count -eq 1) '圆括号先执行再喂参'

# —— 8) 双引擎差异：Get-Service -ComputerName 仅 5.1 存在（ServiceController 远程被 pwsh 7 移除） ——
if ($onWindows) {
    if ((Get-Command Get-Service).Parameters.ContainsKey('ComputerName')) {
        Check ($true) '本引擎保留 -ComputerName（5.1 的 .NET 服务远程） [ch51-only]'
    }
    else {
        Skip 'pwsh 7 已移除 Get-Service -ComputerName，跨机请用 Invoke-Command 或 CIM（13/14 章） [ch7-only]'
    }
}
else { Skip 'Get-Service 为 Windows-only，-ComputerName 差异见 Windows 侧 [platform]' }

Remove-Item $work -Recurse -Force
Check (-not (Test-Path $work)) '临时目录清理'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }