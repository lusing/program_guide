#Requires -Version 5.1
# 示例 03：帮助系统——帮助是可编程访问的对象；语法/参数/参数集都能查
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) Get-Help 返回帮助对象（即使本地帮助未更新，也有自动生成的简要帮助） ——
$h = Get-Help Get-Service
Check ($null -ne $h) 'Get-Help 返回帮助对象'
Check ($h.Name -match 'Get-Service') '帮助对象带命令名'

# —— 2) 语法文本与参数元数据 ——
$syntax = Get-Command Get-Service -Syntax
Check ($syntax -match '-Name') '语法图含 -Name 参数'
Check ((Get-Command Get-Service).Parameters.ContainsKey('DisplayName')) '参数表含 -DisplayName'

# —— 3) 参数集：Get-Service 有多个用法（Name 集 / DisplayName 集 / InputObject 集） ——
Check ((Get-Command Get-Service).ParameterSets.Count -ge 2) '命令有多个参数集'

# —— 4) 通用参数八件套由引擎自动提供 ——
$p = (Get-Command Get-Service).Parameters
Check ($p.ContainsKey('Verbose') -and $p.ContainsKey('ErrorAction')) '通用参数 Verbose/ErrorAction 自动存在'

# —— 5) 开关参数无值：Get-Service -DependentServices 是 SwitchParameter ——
Check ($p['DependentServices'].ParameterType -eq [switch]) '-DependentServices 是开关参数'

# —— 6) 数组参数：-Name 接受 string[] ——
Check ($p['Name'].ParameterType -eq [string[]]) '-Name 接受字符串数组'

# —— 7) about 主题与 -Parameter/-Examples 详查（依赖本地帮助是否已更新，探针式） ——
$about = $null
try { $about = Get-Help about_Variables -ErrorAction Stop } catch { }
if ($about) { Check ($about -is [string] -or $about.Name -match 'about_') 'about 主题可读 [env]' }
else { Skip '本地帮助未更新，about 主题暂缺（可运行 Update-Help） [env]' }

$paramHelp = $null
try { $paramHelp = Get-Help Get-Service -Parameter Name -ErrorAction Stop } catch { }
if ($paramHelp) { Check (@($paramHelp).Count -ge 1) '单参数帮助可查 [env]' }
else { Skip '本地帮助未更新，-Parameter 详查暂缺 [env]' }

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
