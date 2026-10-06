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
# 原书用服务集合（Status='Running'）；Unix 上 Get-Service 不存在，改用进程集合。
# 简化式与脚本块等价是**引擎行为**，与集合来自哪里无关。
if (Get-Command Get-Service -ErrorAction SilentlyContinue) {
    $simple = @(Get-Service | Where-Object Status -eq 'Running')
    $block = @(Get-Service | Where-Object { $_.Status -eq 'Running' })
    Check ($simple.Count -eq $block.Count -and $simple.Count -gt 0) '简化式与脚本块结果一致'
    Check (@(Get-Service | Where-Object { $_.Status -eq 'Running' -and $_.Name -like 'W*' }).Count -ge 0) '多条件须回脚本块'
}
else {
    $simple2 = @(Get-Process | Where-Object Name -eq 'kernel_task')
    $block2 = @(Get-Process | Where-Object { $_.Name -eq 'kernel_task' })
    Check ($simple2.Count -eq $block2.Count) '简化式与脚本块结果一致（进程集合，-eq 对不存在的值两侧同为 0）'
    # 取一个确实存在的进程名再比一次，避免"两侧都空"这种退化的真
    $live = (Get-Process | Where-Object { $_.Name } | Select-Object -First 1).Name
    $s3 = @(Get-Process | Where-Object Name -eq $live)
    $b3 = @(Get-Process | Where-Object { $_.Name -eq $live })
    Check ($s3.Count -eq $b3.Count -and $s3.Count -ge 1) '简化式与脚本块在非空结果上仍一致'
    Check (@(Get-Process | Where-Object { $_.Id -gt 0 -and $_.Name -like '*' }).Count -ge 1) '多条件须回脚本块'
}

# —— 8) 数值过滤的确定性验证 ——
Check (@(1..100 | Where-Object { $_ % 15 -eq 0 }).Count -eq 6) '100 内 15 的倍数恰 6 个'

# —— 9) 左过滤与客户端过滤等价（仓库端 -Filter vs 客户端 Where） ——
# 原书用 CIM：Win32_Process 是 Windows 的 WMI 类，Unix 上没有 CIM/WMI 栈。
# 跨平台用 Get-Process 自己的 -Name 参数做"仓库端过滤"，与客户端 Where-Object 比对——
# 教学点（两种过滤位置结果一致）不变，只是数据源不同。
$liveName = (Get-Process | Where-Object { $_.Name } | Select-Object -First 1).Name
$left = @(Get-Process -Name $liveName)
$right = @(Get-Process | Where-Object Name -eq $liveName)
Check ($left.Count -eq $right.Count -and $left.Count -ge 1) '左过滤（-Name 参数）与客户端过滤计数一致'
$missLeft = @(Get-Process -Name 'no-such-proc-xyz')
$missRight = @(Get-Process | Where-Object Name -eq 'no-such-proc-xyz')
Check ($missLeft.Count -eq $missRight.Count -and $missLeft.Count -eq 0) '两侧都无匹配时计数同为 0'

$script:Report | Out-File -FilePath (Join-Path $PSScriptRoot 'report.txt') -Encoding utf8
if ($script:Failed) { exit 1 } else { exit 0 }
