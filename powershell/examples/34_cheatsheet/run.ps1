#Requires -Version 5.1
# 示例 34：备忘清单——每个标点/运算符/坑一条确定性断言（全表可执行化）
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 标点符号区 ——
Check ('a`tb' -match "a`t b".Replace(' ', '') -or "a`tb".Contains("`t")) '反引号 `t = Tab'
Check ("`$x" -eq '$x') '反引号 `$ = 字面美元'
Check ((1..3) -join ',' -eq '1,2,3') '范围运算符 1..3'
Check (@(@(1) | Measure-Object).Count -eq 1) '@() 保证数组形态'
Check (@{ k = 5 }.k -eq 5) '@{} 哈希表点访问'
Check (('a' + 'b') -eq 'ab') '字符串拼接 +'
Check (('x' | ForEach-Object { $_.ToUpper() }) -eq 'X') '脚本块与 $_'
Check ((& { 2 + 3 }) -eq 5) '& 调用脚本块'
Check ([math]::Max(3, 7) -eq 7) ':: 静态成员'
Check ((@('a', 'b', 'c')[1..2] -join '') -eq 'bc') '数组切片 [1..2]'
Check ((@('a', 'b', 'c')[-1]) -eq 'c') '负索引 [-1]'
Check ("$(2 + 3)" -eq '5') '$() 子表达式'
$hs = @'
字面 $x 与 `n
'@
Check ($hs -eq "字面 `$x 与 ``n") "单引号 here-string 全字面"

# —— 运算符区 ——
Check (('HELLO' -eq 'hello') -and ('HELLO' -ceq 'hello') -eq $false) '-eq 不敏感 / -ceq 敏感'
Check (('abc' -replace 'b', 'X') -eq 'aXc') '-replace（正则引擎）'
Check ((('a1', 'b2') -match '\d').Count -eq 2) '数组 -match 变过滤'
Check ((5 -in 1..10) -and (1..10 -contains 5)) '-in 与 -contains 方向'
Check (('42' -as [int]) -eq 42 -and ('x' -as [int]) -eq $null) '-as 温和转型'
Check (('{0:N0}' -f 1234) -match '1,?234') '-f 格式化'
Check (((3, 1, 2 | Sort-Object) -join '') -eq '123') '管道接 Sort-Object'

# —— 十大坑的症状复现区 ——
Check (@('a').Count -eq 1 -and (@('a') | Measure-Object).Count -eq 1) '坑3：计数用 @() 兜底'
$fmt = Get-Service | Select-Object -First 1 | Format-Table Name | Select-Object -First 1
Check ($fmt.GetType().Name -match 'Format') '坑4：Format 产出指令（后接数据命令失效）'
$null = $f = $null
Check ($null -eq $f) '坑（判空方向铺垫）'
Check (($null -eq @($null, 1)) -eq $false) '坑11：$null 在左判空恒稳'
Check (('x' | ForEach-Object { $s = $_; $s }) -eq 'x') '坑7：脚本块输出一切'
$shadow = '外层'
function Tut-Shadow { $shadow = '内层'; return $shadow }
Check ((Tut-Shadow) -eq '内层' -and $shadow -eq '外层') '坑8：作用域遮蔽（内层赋值不穿透）'
$bytes = [System.Text.Encoding]::UTF8.GetBytes('PowerShell')
Check ($bytes.Count -eq 10) '字节数验证（UTF-8 英文单字节）'
Check (@(1..5 | ForEach-Object { $_ * $_ }).Count -eq 5) '坑2 旁证：管道展开自然'

# —— 双引擎差异区 ——
if ($PSVersionTable.PSEdition -eq 'Core') {
    Check ($true) '本引擎 PSEdition=Core（pwsh 7） [ch7-only]'
}
else {
    Check ($true) '本引擎 PSEdition=Desktop（5.1） [ch51-only]'
}

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
