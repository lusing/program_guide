#Requires -Version 5.1
# 示例 08：对象——Get-Member、Select 双向、计算属性、排序、实例与静态成员
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) Get-Member：类型名与成员类型 ——
$gmStr = 'abc' | Get-Member
Check (@($gmStr | Where-Object Name -eq 'ToUpper').Count -eq 1) '字符串对象有 ToUpper 方法'
$gmSvc = Get-Service | Get-Member
Check ($gmSvc[0].TypeName -match 'ServiceController') '服务对象的 TypeName 含 ServiceController'
Check (@($gmSvc | Where-Object MemberType -eq 'Property').Count -gt 2) '服务对象有多个属性'
Check (@($gmSvc | Where-Object MemberType -eq 'Method').Count -gt 2) '服务对象有多个方法'

# —— 2) Select-Object 两种取法：对象 vs 裸值 ——
$sample = [pscustomobject]@{ Name = 'alpha'; Score = 3 },
[pscustomobject]@{ Name = 'beta'; Score = 1 },
[pscustomobject]@{ Name = 'gamma'; Score = 2 }
$subset = $sample | Select-Object -Property Name
Check ($subset[0].GetType().Name -match 'PSCustomObject') '-Property 产出对象（仍是行）'
$vals = $sample | Select-Object -ExpandProperty Name
Check (@($vals)[0].GetType().Name -eq 'String') '-ExpandProperty 产出裸值（列）'
Check (($vals -join ',') -eq 'alpha,beta,gamma') '裸值数组保序'

# —— 3) 计算属性：现做一列 ——
$sq = 1..3 | Select-Object @{ n = 'Sq'; e = { $_ * $_ } }
Check (($sq.Sq -join ',') -eq '1,4,9') '计算属性平方列'
$ws = [pscustomobject]@{ N = 'x'; Bytes = 3MB } | Select-Object @{ n = 'MB'; e = { [math]::Round($_.Bytes / 1MB, 0) } }
Check ($ws.MB -eq 3) '计算属性单位换算（1MB 数值后缀）'

# —— 4) 排序：单键/多键/方向 ——
Check (((3, 1, 2 | Sort-Object) -join ',') -eq '1,2,3') 'Sort-Object 升序'
Check (((3, 1, 2 | Sort-Object -Descending) -join ',') -eq '3,2,1') 'Sort-Object 降序'
$byScore = $sample | Sort-Object Score | ForEach-Object Name
Check (($byScore -join ',') -eq 'beta,gamma,alpha') '按属性排序对象集合'
$multi = [pscustomobject]@{ G = 'a'; N = 2 }, [pscustomobject]@{ G = 'a'; N = 1 }, [pscustomobject]@{ G = 'b'; N = 0 }
$multiKeys = $multi | Sort-Object G, N | ForEach-Object { "$($_.G)$($_.N)" }
Check (($multiKeys -join ',') -eq 'a1,a2,b0') '多键排序（G 升序内 N 升序）'

# —— 5) 实例方法与静态成员 ——
Check ('powerShell'.ToUpper() -eq 'POWERSHELL') '实例方法 ToUpper'
Check ('powerShell'.Length -eq 10) 'Length 是属性不是方法'
Check ([math]::Round(3.14159, 2) -eq 3.14) '静态方法 [math]::Round'
Check ([math]::Sqrt(144) -eq 12) '静态方法 [math]::Sqrt'
Check (([datetime]'2026-10-06').AddDays(10) -eq [datetime]'2026-10-16') '实例方法 AddDays'
Check ([string]::Join('-', 'a', 'b', 'c') -eq 'a-b-c') '静态方法 [string]::Join'
Check (@([math] | Get-Member -Static -Name Round).Count -eq 1) 'Get-Member -Static 列静态成员'

# —— 6) 管道前后对象类型不变（投影不改对象） ——
$afterSort = $sample | Sort-Object Score
Check ($afterSort[0].Name -eq 'beta' -and $afterSort[0].Score -eq 1) '排序后仍是原对象（带全部属性）'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
