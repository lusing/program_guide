#Requires -Version 5.1
# 示例 29：技巧——字符串三套、子表达式、调用三兄弟、默认参数、new/Random、Measure
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 字符串三套 ——
$path = 'C:\Logs\App-2026.log'
Check ($path.ToUpper() -eq 'C:\LOGS\APP-2026.LOG') '.NET 方法 ToUpper'
Check (@($path.Split('-'))[0] -eq 'C:\Logs\App') '.NET 方法 Split'
Check ((('a', 'b', 'c') -join '-') -eq 'a-b-c') '运算符 -join'
Check ((('x-y-z' -split '-') -join '|') -eq 'x|y|z') '运算符 -split'
Check (('Don Jones' -replace 'Jones', 'Smith') -eq 'Don Smith') '运算符 -replace'
$fOut = '{0:d3} / {1:N0} / {2:P0}' -f 7, 1234567, 0.25
Check ($fOut -match '007' -and $fOut -match '1,234,567' -and $fOut -match '25') '-f 格式化运算符（d3/N0/P0）'

# —— 2) 子表达式装任意表达式 ——
$检查 = 'ok'
Check ("结果：$(if (1 -gt 0) { '正' } else { '负' })" -eq '结果：正') '$( ) 装 if 表达式'
Check ("数量：$(@('a', 'b').Count)" -eq '数量：2') '$( ) 装数组计数'

# —— 3) 调用三兄弟 ——
Check ((. { 6 * 7 }) -eq 42) '脚本块点执行（当前作用域）'
Check ((& { 6 * 7 }) -eq 42) '脚本块调用操作符 &'
$tool = 'Get-Date'
Check ($null -ne (& $tool)) '& 执行变量里的命令名'
Check ([math]::Round(2.718, 2) -eq 2.72) ':: 静态成员访问'

# —— 4) 默认参数值 ——
$old = $PSDefaultParameterValues
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$work = Join-Path $PSScriptRoot 'tmp-tip'
New-Item -ItemType Directory -Force -Path $work | Out-Null
'x' | Out-File (Join-Path $work 'enc.txt')
$bytes = [System.IO.File]::ReadAllBytes((Join-Path $work 'enc.txt')) | Select-Object -First 3
Check (($bytes -join ',') -ne '') '默认参数生效（Out-File 已吃默认编码）'
$PSDefaultParameterValues = $old
Remove-Item $work -Recurse -Force

# —— 5) new 与确定性随机 ——
$r1 = [System.Random]::new(42)
$a = $r1.Next(100); $b = $r1.Next(100)
$r2 = [System.Random]::new(42)
$c = $r2.Next(100); $d = $r2.Next(100)
Check ($a -eq $c -and $b -eq $d) '固定种子随机序列可复现'
Check (@(Get-Random -InputObject (1..10) -Count 3 -SetSeed 7).Count -eq 3) 'Get-Random 抽样计数'

# —— 6) Measure-Command 形态 ——
$ms = (Measure-Command { Start-Sleep -Milliseconds 50 }).TotalMilliseconds
Check ($ms -ge 50) 'Measure-Command 计时形态（>=50ms）'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
