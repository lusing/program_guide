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

# 本章的教学点是「帮助与命令元数据是可编程访问的对象」，不依赖某个具体 cmdlet。
# 探针命令按平台选：Windows 有 Get-Service，Unix/macOS 没有（launchd 不是 SCM），
# 改用 Get-Process——两者的元数据形状对本章每条断言都成立（都有 -Name 位置参数、
# 都是 string[]、都有多个参数集、都至少有一个 switch 参数）。
$probe = if (Get-Command Get-Service -ErrorAction SilentlyContinue) { 'Get-Service' } else { 'Get-Process' }
$common = @('Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction',
    'ProgressAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable',
    'OutVariable', 'OutBuffer', 'PipelineVariable')

# —— 1) Get-Help 返回帮助对象（即使本地帮助未更新，也有自动生成的简要帮助） ——
$h = Get-Help $probe
Check ($null -ne $h) "Get-Help 返回帮助对象（探针 $probe）"
Check ($h.Name -match [regex]::Escape($probe)) "帮助对象带命令名（$probe）"

# —— 2) 语法文本与参数元数据 ——
$syntax = Get-Command $probe -Syntax
Check ($syntax -match '-Name') '语法图含 -Name 参数'
$meta = (Get-Command $probe)
$business = @($meta.Parameters.Keys | Where-Object { $_ -notin $common })
Check ($business.Count -ge 2) "参数表含业务参数（$($business.Count) 个非通用参数）"

# —— 3) 参数集：一个 cmdlet 有多种用法 ——
Check ($meta.ParameterSets.Count -ge 2) "命令有多个参数集（$($meta.ParameterSets.Count) 个）"

# —— 4) 通用参数十二件套由引擎自动提供（不是 cmdlet 自己写的） ——
$p = $meta.Parameters
Check (@($common | Where-Object { $p.ContainsKey($_) }).Count -eq $common.Count) '通用参数十二件套自动存在'

# —— 5) 开关参数无值：参数表里 ParameterType 是 [switch] 的那些 ——
$switches = @($p.GetEnumerator() | Where-Object { $_.Value.ParameterType -eq [switch] -and $_.Key -notin $common } | Select-Object -ExpandProperty Key)
Check ($switches.Count -ge 1) "存在开关参数（$($switches -join ', ')）"

# —— 6) 数组参数：-Name 接受 string[]（不是 string） ——
Check ($p['Name'].ParameterType -eq [string[]]) '-Name 接受字符串数组'

# —— 7) about 主题与 -Parameter/-Examples 详查（依赖本地帮助是否已更新，探针式） ——
$about = $null
try { $about = Get-Help about_Variables -ErrorAction Stop } catch { }
if ($about) { Check ($about -is [string] -or $about.Name -match 'about_') 'about 主题可读 [env]' }
else { Skip '本地帮助未更新，about 主题暂缺（可运行 Update-Help） [env]' }

$paramHelp = $null
try { $paramHelp = Get-Help $probe -Parameter Name -ErrorAction Stop } catch { }
if ($paramHelp) { Check (@($paramHelp).Count -ge 1) '单参数帮助可查 [env]' }
else { Skip '本地帮助未更新，-Parameter 详查暂缺 [env]' }

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
