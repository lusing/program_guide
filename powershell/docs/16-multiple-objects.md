# 16 同时处理多个对象——批处理、枚举与并行

> 本章对应原书第 16 章"同时处理多个对象"，并补上 pwsh 7 的 `ForEach-Object -Parallel`。自动化管理的本义就是"对很多目标做同一件事"：重启 50 台机器、改 200 个服务的启动模式、给 1000 个用户建邮箱。本章给出从"最省力"到"最并行"的完整工具阶梯。

## 16.0 开篇：一张决策图

拿到"对 N 个目标做一件事"的需求，按这张图走（本章各节是每个分支的展开）：

```
命令参数能直接吃数组吗？（-Name a,b / -Path 清单）
 ├─ 能 → 一条命令搞定（16.2）
 └─ 不能 ↓
对象之间能管道直连吗？（Get-X | Verb-X，第 09 章绑定）
 ├─ 能 → 管道直连（16.2 末尾）
 └─ 不能 ↓
需要对每个对象做什么？
 ├─ 只是处理数据（过滤/映射） → ForEach-Object（16.4）
 ├─ 需要循环控制（break/continue/多集合） → foreach 语句（16.4）
 └─ 调方法 → 有 Cmdlet 用 Cmdlet，没有用 Invoke-CimMethod（16.3）
最后：任务独立且单件耗时长？
 └─ 是 → ForEach-Object -Parallel（16.6，pwsh 7）
```

从上往下试，**落在越靠上的分支，代码越短越快**。这张图也是本章的阅读地图。

## 16.1 老一代的答案：For Each 循环

原书用一段 VBScript 开场，值得保留——因为它塑造了几代管理员的直觉：

```vbscript
For Each varService in colServices
  varService.ChangeStartMode("Automatic")
Next
```

三步：把所有服务收进集合；逐个取出；对每个调一次方法。这个模式**能工作**，但有两个代价：它是**串行**的（一次一个，与人在 GUI 里点没本质区别）；它要求你写"怎么遍历"的指令代码。PowerShell 的进化方向正是消灭这两件事——**让批量成为参数的自然属性，让并行成为命令的内建能力**。

## 16.2 第一条路：批处理参数（能批量绝不循环）

PowerShell 命令的数组参数天然吃"一批目标"（第 03 章 `string[]` 的力量时刻）：

```powershell
Get-Service -Name Spooler, W32Time, Winmgmt        # 一次查仨
Stop-Service -Name Spooler, W32Time                # 一次停俩
Remove-Item -Path C:\Temp\log1.txt, C:\Temp\log2.txt, C:\Temp\log3.txt   # 一次删仨
```

**性能与健壮性阶梯**（本章的总纲）：

```
命令参数吃数组（最优）  >  管道直连（Get-X | Verb-X，第 09 章绑定）  >  ForEach-Object  >  foreach 语句  >  逐个调方法
```

越靠左：越少的"解释一层"、越少的中间对象、越接近命令的优化路径。**动手前先问：这条命令的参数能不能直接吃数组？** 能就别写循环。这也是"左处理"思想（第 11 章左过滤）在变更操作上的镜像。

## 16.3 第二条路：对象方法的批量调用

拿到一整批对象，对每个调用方法（VBScript 直觉的 PowerShell 版）：

```powershell
Get-Process -Name notepad | ForEach-Object { $_.Kill() }     # 对每个进程调 Kill()
```

但注意两道闸门：**手里得是活对象**（第 13/15 章的序列化快照没有方法——本地查询没问题，远程/作业结果不行，远程的动作要写进远程脚本块）；**有对应 Cmdlet 时优先 Cmdlet**（`Get-Process notepad | Stop-Process` 更规范：可 `-WhatIf`、可 `-Confirm`、错误处理统一）。方法调用是"CIM 类方法、.NET 特有功能"这类 Cmdlet 没覆盖的领域的补充手段（第 14 章 `Invoke-CimMethod` 正是此路的正规化）。

## 16.4 第三条路：枚举——ForEach-Object 与 foreach 语句

两种"逐个处理"的写法，语义有细差，各有主场：

**`ForEach-Object`（管道式，流式）**：

```powershell
1..5 | ForEach-Object { $_ * 10 }        # 10 20 30 40 50
Get-Service | ForEach-Object { $_.Status }
```

它在**管道里**逐个处理对象：上游来一个处理一个（流式，第 06 章），当前对象是 `$_`。适合"接在管道后面"的场景；开销略高（每对象调用一次脚本块）。

**`foreach` 语句（先收集，后迭代）**：

```powershell
$files = Get-ChildItem C:\Temp
foreach ($f in $files) { $f.Length }
```

它先把右侧**全部收进集合**再逐个迭代，元素在具名变量 `$f` 里（没有 `$_`）。适合"已经有一批东西在手"的场景；速度比 ForEach-Object 快一截（无管道开销）。

选择口诀：**管道中游用 ForEach-Object（流式、可组合）；独立循环用 foreach 语句（快、可读、可 break/continue）**。注意 `foreach` 语句在管道里**不能**用（它不是命令），而 `ForEach-Object` 离开管道没有意义——两者错位竞争，不是替代关系。

另一个易混点：`ForEach-Object` 有个别名 **`foreach`**——于是 `1..5 | foreach { $_ }`（管道里的 foreach 是 ForEach-Object）与 `foreach ($i in 1..5) {}`（语句）长得像却完全是两个东西。**脚本里别名 foreach 一律写全名**，避免读者（包括三个月后的你）歧义。

## 16.4.1 变更三段式：预演—执行—回查

把 16.5 的安全带串成一次完整的批量变更（以"停掉三个测试服务"为例），这就是第 33 章综合项目里会固化的工作流：

```powershell
# 第一段：预演（WhatIf 干跑 + 清点）
$targets = 'SvcA', 'SvcB', 'SvcC'
Get-Service -Name $targets                       # 清点：三个都在、都不是系统关键服务
Stop-Service -Name $targets -WhatIf              # 预演：逐条列出将要发生的操作

# 第二段：执行（真动手）
Stop-Service -Name $targets

# 第三段：回查（验证）
Get-Service -Name $targets | Select-Object Name, Status   # 应全部 Stopped
```

三段缺一不可：没有清点，`-Name` 里的拼写错误会让你"以为停了其实没停"；没有预演，通配符比预想宽的目标会误伤；没有回查，"命令成功"只是没报错，不等于"结果正确"（服务可能有依赖导致停止失败但延迟报错）。**批量操作的正确性是验证出来的，不是命令返回出来的**——这句话会在错误处理（26 章）与测试（32 章）里反复回响。

## 16.5 批量变更的安全带

对"一批目标"动手前，三条安全带按顺序系：

1. **先 Get 后动词**（第 06 章纪律）：`Get-Service -Name ... ` 确认清单再 `Stop-Service`；
2. **`-WhatIf` 干跑**：`Remove-Item -Path $files -WhatIf` 逐行列出将要发生什么；
3. **`-Confirm` 门槛**：变更类命令加 `-Confirm` 每个目标问一次；或 `-ConfirmImpact` 设计（第 25 章你自己的工具也会接入这套机制）。

大列表可以分批（`$list | Select-Object -First 50` 一批批来），变更后立刻回查（再 Get 一次验证）——"改完不查"等于没改。

## 16.6 pwsh 7：ForEach-Object -Parallel

前述一切都是**串行**的。pwsh 7 给 `ForEach-Object` 加了 `-Parallel`：每个对象进一个**并行 runspace**（基于 ThreadJob 技术池化，默认同时 5 个，`-ThrottleLimit` 调）：

```powershell
1..10 | ForEach-Object -Parallel { Start-Sleep -Milliseconds 200; $_ * 2 } -ThrottleLimit 10
```

三个必须知道的特性：

- **`$using:` 传值**：并行块里看不到外面的变量，`$using:x` 带快照进去（与第 15 章作业同机制）；
- **输出不保序**：各线程完成顺序不定，`1..5 | ForEach -Parallel {$_}` 可能输出 `3 1 2 5 4`——**要顺序先 `Sort-Object`**；
- **块内只有部分模块预载**：并行 runspace 是新环境， import 常用模块要显式（`Import-Module` 写进脚本块或用 `-Using` 模式）。

适用判断：任务**单个耗时且互相独立**（网络请求、远程查询、大文件处理）→ 并行收益大；纯本地 CPU 计算 → PowerShell 单线程解释执行，并行收益有限甚至为负（线程开销）。`-Parallel` 是 5.1 没有的语法，跨版本脚本要做版本探测（`$PSVersionTable.PSVersion.Major -ge 7`）。

## 16.6.1 分批：给大列表上保险

目标成千上万时，"一条命令全上"会同时打满网络与目标——分批（chunking）是给批量操作上的保险：

```powershell
$targets = Get-Content all-servers.txt          # 假设 1000 台
$batchSize = 50
for ($i = 0; $i -lt $targets.Count; $i += $batchSize) {
    $batch = $targets[$i..($i + $batchSize - 1)]
    Invoke-Command -ComputerName $batch -ScriptBlock { … } -ThrottleLimit 50
    "批次 $($i / $batchSize + 1) 完成" | Write-Host
}
```

三个要点：`$targets[$i..($j)]` 是数组切片（第 20 章），一批 50 台按序推进；`-ThrottleLimit` 与批大小对齐（每批内部并发打满，批与批之间串行给系统喘息）；每批之间可以加检查点（记录进度文件），中断后从断点续跑。**分批不是慢，是可控**——错误只影响一批、进度可观测、随时可停。这一节的 `for` 循环写法也是第 22 章（脚本）之前唯一一次"正经循环"，注意它与 foreach 的分工：**步进逻辑用 for，遍历用 foreach**。

## 16.7 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| 循环里改了集合，结果跳项 | foreach 迭代的是快照集合 | 迭代副本、变更收集到新数组再处理 |
| 管道里写 `foreach` 语句报错 | 语句不是命令，不能进管道 | 管道里用 `ForEach-Object`（全名） |
| `-Parallel` 输出乱序 | 各线程完成顺序不定 | 收集后 `Sort-Object`；或输出里带序号字段 |
| `-Parallel` 里读不到外部变量 | 并行块是独立 runspace | `$using:变量` |
| 批量删除把目标外文件也删了 | 通配符比预想宽 / 未先 Get 清点 | `-WhatIf` 干跑 + 先 Get 确认清单 |
| 快照对象调方法报错 | 远程/作业结果无方法 | 动作写进远程脚本块（第 13/15 章） |

## 16.8 本章要点

- 性能阶梯：**参数吃数组 > 管道直连 > ForEach-Object > foreach 语句 > 逐个方法**——动手前先问参数能不能直接吃一批。
- 方法批量调用要活对象、优先 Cmdlet（`-WhatIf/-Confirm` 安全带）；`Invoke-CimMethod` 是正规化形态。
- `ForEach-Object`（管道流式、`$_`）vs `foreach` 语句（先收集、具名变量、可 break）——错位竞争；别名 `foreach` 的歧义要靠写全名化解。
- `-Parallel`（pwsh 7）：runspace 池 + `-ThrottleLimit` + `$using:` + **不保序**；独立耗时任务收益大。

**动手实验**：① 建三个临时文件，用一条 `Remove-Item -Path`（数组）删掉，验证"参数吃数组"；② 同一组数据分别用 `ForEach-Object` 与 `foreach` 语句各乘 10，比对输出；③ `1..5 | ForEach-Object -Parallel { $_ }`（pwsh 7）多跑几次亲眼看乱序，再 `Sort-Object` 治它；④ `Get-Process -Name notepad | Stop-Process -WhatIf`（先开个记事本）干跑；⑤ 把 `foreach ($i in 1..3) { $i }` 接进管道（`| foreach (...)`）看报错，体会语句与命令的边界。

实验参考：⑤的报错是"foreach 不是 cmdlet/命令"一类——语句进管道，解析器按**命令**找 foreach，命中的是 ForEach-Object 的别名，但你给的是语句语法，于是报错形态取决于写法（`| foreach ($i in 1..3)` 是"无法识别"）；这恰好证明别名 `foreach` 的双重身份是多事之源。

性能阶梯的实测方法也值得带走（在小数据上量级感即可，别较绝对值）：

```powershell
$n = 1..1000
Measure-Command { foreach ($x in $n) { $x * 2 } }                          # 语句：最快
Measure-Command { $n | ForEach-Object { $_ * 2 } }                         # 管道：略慢（每对象一次调用）
Measure-Command { $n | ForEach-Object -Parallel { $_ * 2 } -ThrottleLimit 5 }   # 并行：本地纯计算反而更慢！
```

第三条是反直觉教学点：纯 CPU 计算（尤其这么轻的）并行开销远大于收益——**-Parallel 的主场是等待型任务**（网络、远程、IO），不是计算型任务。这个实测做一次，选型直觉就有了。

对应示例（可选）：`examples/16_multiple_objects/`——数组参数批删、两种枚举等价、管道保序断言、`-Parallel`（含 `$using:` 与排序后确定性，通道标记）、`-WhatIf` 干跑。

---

本篇（三 远程与批量）其余各章：[13 远程处理](./13-remoting.md) · [14 CIM](./14-cim.md) · [15 后台作业](./15-jobs.md) · [17 安全](./17-security.md) · [18 会话](./18-sessions.md) · [19 高级远程](./19-advanced-remoting.md)

---

本篇（三 远程与批量）导航：[13 远程处理](./13-remoting.md) · [14 CIM](./14-cim.md) · [15 后台作业](./15-jobs.md) · [16 多对象](./16-multiple-objects.md) · [17 安全](./17-security.md) · [18 会话](./18-sessions.md) · [19 高级远程](./19-advanced-remoting.md)

本章示例含 -Parallel 的 5.1 通道 SKIP 演示；分批与三段式工作流将在 33 章收官项目合流。
