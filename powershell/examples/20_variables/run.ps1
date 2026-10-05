#Requires -Version 5.1
# 示例 20：变量——引号规则、单元素陷阱、数组与哈希表、类型与转型、判空方向、StrictMode
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 引号规则 ——
$name = 'SERVER-R2'
Check ('the name is $name' -eq 'the name is $name') '单引号字面'
Check ("name = $name" -eq 'name = SERVER-R2') '双引号展开变量'
Check ("$(@(1, 2, 3).Count)" -eq '3') '属性须经 $() 子表达式展开'
$esc = "`$name`n$name"
Check ($esc.Contains("`$name") -and $esc.Contains("`n") -and $esc.Contains('SERVER-R2')) '反引号转义：$ 原样与换行'
$hs = @'
字面 $name 与 `n
'@
Check ($hs -eq "字面 `$name 与 ``n") '单引号 here-string 全字面'

# —— 2) 单元素陷阱与 @() ——
$scalar = 'a'
Check (@($scalar).Count -eq 1) '@() 包裹计数恒可靠'
$single = @('only')
Check (@($single).Count -eq 1 -and $single[0] -eq 'only') '单元素数组显式构造'

# —— 3) 数组索引/切片/拼接 ——
$c = 'one', 'two', 'three'
Check (($c[0], $c[-1], ($c[1..2] -join '+')) -join '|' -eq 'one|three|two+three') '索引、负索引与切片'
Check ((($c + 'four')[-1]) -eq 'four') '+ 拼接出新数组'
Check (@(($c -eq 'two')).Count -eq 1) '数组 -eq 兼职过滤'

# —— 4) 哈希表：两种访问、有序、转对象 ——
$h = @{ Name = 'svc'; Depth = 2 }
Check ($h.Name -eq 'svc' -and $h['Depth'] -eq 2) '哈希表两种键访问'
$key = 'Name'
Check ($h[$key] -eq 'svc') '变量键须方括号'
$ord = [ordered]@{ A = 1; B = 2; C = 3 }
Check (($ord.Keys -join ',') -eq 'A,B,C') 'ordered 保插入序'
$obj = [pscustomobject]$ord
Check ($obj.GetType().Name -eq 'PSCustomObject' -and $obj.B -eq 2) '哈希表转对象'

# —— 5) 类型约束与转型 ——
[int]$port = '9100'
Check ($port -eq 9100) '类型约束自动解析字符串'
[datetime]$due = '2026-10-06'
Check ($due.Year -eq 2026) '[datetime] 解析日期字符串'
Check (('42' -as [int]) -eq 42) '-as 温和转型成功'
Check ($null -eq ('abc' -as [int])) '-as 失败给 null 不抛错'
$badCast = $false
try { [int]$x = 'abc' } catch { $badCast = $true }
Check ($badCast) '类型约束装不下时赋值即报错'

# —— 6) 判空方向铁律 ——
$arr = $null, 1, $null
Check (@(($arr -eq $null)).Count -eq 2) '数组在左：-eq 变过滤（反面教材）'
Check (($null -eq $arr) -eq $false) '$null 在左：判空方向正确'

# —— 7) StrictMode ——
Set-StrictMode -Version Latest
$strictErr = $false
try { Get-Variable -Name 'definitely_not_defined_var' -ErrorAction Stop | Out-Null } catch { $strictErr = $true }
Check ($strictErr) '显式探测未定义变量可控报错'
Set-StrictMode -Off

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
