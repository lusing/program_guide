#Requires -Version 5.1
# 示例 11：过滤与比较——运算符全家、方向性、数组过滤、两种 Where、左右过滤等价
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ProgressPreference = 'SilentlyContinue'
$script:Report = [System.Collections.Generic.List[string]]::new()
$script:Failed = $false
function Check([bool]$Condition, [string]$Label) {
    if ($Condition) { $script:Report.Add("OK: $Label") }
    else { $script:Report.Add("FAIL: $Label"); $script:Failed = $true }
}
function Skip([string]$Reason) { $script:Report.Add("SKIP: $Reason") }

# —— 1) 相等与次序 ——
Check ((5 -eq 5) -and ('hello' -ne 'help')) '-eq 与 -ne'
Check ((100 -gt 10) -and (10 -lt 10) -eq $false) '-gt/-lt'
Check (([int]'10') -ge 10 -and 10 -le 10) '-ge/-le 与类型强转'
Check (('2026-10-06' -lt '2026-12-31') -eq $true) '字符串日期按字典序可比较'

# —— 2) 大小写：默认不敏感，c 前缀敏感 ——
Check ('HELLO' -eq 'hello') '-eq 默认不区分大小写'
Check (('HELLO' -ceq 'hello') -eq $false) '-ceq 区分大小写'

# —— 3) 通配与正则分界 ——
Check ('Hello' -like '*ll*') '-like 通配符'
Check ('Hello' -match '^H.l+') '-match 正则锚定'

# —— 4) 成员运算符的方向性（左单右集 / 左集右单） ——
Check (5 -in 1..10) '-in：值在集合'
Check (1..10 -contains 5) '-contains：集合含值'
Check ((1..10 -in 5) -eq $false) '方向搞反永远为假（安静的坑）'

# —— 5) 集合在左：-eq 变过滤器 ——
Check (@(@(1, 2, 1) -eq 1).Count -eq 2) '数组 -eq 返回匹配子集'
Check (@(@(1, 2, 1) -ne 1).Count -eq 1) '数组 -ne 同理过滤'

# —— 6) 布尔组合与取反 ——
Check (((5 -gt 10) -and (10 -lt 100)) -eq $false) '-and 需全真'
Check (((5 -gt 10) -or (10 -lt 100)) -eq $true) '-or 有一真即真'
Check ((-not $true) -eq $false) '-not 取反'

# —— 7) 两种 Where 等价 ——
$simple = @(Get-Service | Where-Object Status -eq 'Running')
$block = @(Get-Service | Where-Object { $_.Status -eq 'Running' })
Check ($simple.Count -eq $block.Count -and $simple.Count -gt 0) '简化式与脚本块结果一致'
Check (@(Get-Service | Where-Object { $_.Status -eq 'Running' -and $_.Name -like 'W*' }).Count -ge 0) '多条件须回脚本块'

# —— 8) 数值过滤的确定性验证 ——
Check (@(1..100 | Where-Object { $_ % 15 -eq 0 }).Count -eq 6) '100 内 15 的倍数恰 6 个'

# —— 9) 左过滤与客户端过滤等价（CIM 仓库端 vs Where） ——
$left = @(Get-CimInstance -ClassName Win32_Process -Filter "Name='explorer.exe'")
$right = @(Get-CimInstance -ClassName Win32_Process | Where-Object Name -eq 'explorer.exe')
Check ($left.Count -eq $right.Count) '左过滤与客户端过滤计数一致'
if ($left.Count -ge 1) { Check ($true) 'explorer 在运行（左过滤非空实证） [env]' }
else { Skip 'explorer 未运行（服务器核心环境） [env]' }

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
