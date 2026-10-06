# 11 过滤与比较——把结果集缩小到恰好

> 本章对应原书第 11 章"过滤和比较"。到这里你已经会"取全部、挑列、排序"了，日常任务的最后一环是**缩小**：只要运行中的服务、只要大于 1 GB 的磁盘、只要名字带 DC 的机器。本章把缩小结果的两条路讲透，并给出全教程使用频率最高的一族符号——比较运算符。

## 11.1 两条路：让命令少拿，还是拿回来再扔

PowerShell 缩小结果集有且只有两种方式：

**路一：左过滤（尽量提前过滤）**——告诉命令本身"我只要这些"：

```powershell
Get-Service -Name e*, *s*                       # 命令只检索名字匹配的服务
Get-ADComputer -Filter "Name -like '*DC'"       # 域控只返回匹配的计算机对象
Get-CimInstance -Filter "Name='explorer.exe'"   # WMI 在仓库端筛选
```

**路二：迭代过滤（客户端过滤）**——全量拿回来，用 `Where-Object` 扔掉不要的：

```powershell
Get-Service | Where-Object Status -eq 'Running'
```

**优先左过滤**是性能纪律：过滤越靠左（越靠近数据源），后续每一段命令要处理的对象越少；对远程数据源（AD、WMI、数据库），左过滤意味着**不匹配的数据根本不通过网络传回来**。在一个万条记录的环境里，`-Filter` 与 `| Where-Object` 可能是毫秒与分钟的区别。

左过滤的代价是**方言**：每个命令家族的过滤参数有自己的语法。`Get-Service` 只认 `-Name`；活动目录的 `-Filter` 用 PowerShell 风格运算符（`"Name -like '*DC'"`）；WMI/CIM 的 `-Filter` 用 WQL 方言（`"Name='explorer.exe' AND ProcessId>0"`——**等号单等号、字符串单引号、没有 `-eq`**）。学左过滤就是学各家的方言，好在帮助里的示例永远给你正确句式。当方言表达不了你的条件（比如"正在运行的服务"没有参数可表达），退到路二——`Where-Object` 是全 Shell 通用的普通话。

## 11.2 比较运算符全家福

两种路都建立在"比较"上。PowerShell 的比较永远返回布尔值 `$true`/`$false`，运算符全家如下（**字符串比较默认不区分大小写**——这与多数语言相反，是第一大记忆点）：

| 族 | 运算符 | 例 | 结果 |
|---|---|---|---|
| 相等 | `-eq` / `-ne` | `5 -eq 5`；`"hello" -eq "help"` | True；False |
| 次序 | `-gt -lt -ge -le` | `100 -gt 10`；`'2026-10-06' -lt '2026-12-31'`（字符串日期也能比） | True |
| 区分大小写 | 前缀 `c`：`-ceq -clike …` | `'HELLO' -ceq 'hello'` | False |
| 通配 | `-like` / `-notlike` | `'Hello' -like '*ll*'` | True |
| 正则 | `-match` / `-notmatch` | `'Hello' -match '^H.l+'` | True（并填 `$matches`，第 28 章） |
| 成员 | `-in` / `-notin` | `5 -in 1..10` | True |
| 成员（反向） | `-contains` / `-notcontains` | `1..10 -contains 5` | True |
| 类型 | `-is` / `-isnot` | `'x' -is [string]` | True |

四个易错点逐个点破：

**`= 不是比较**。`=` 是**赋值**（第 20 章），比较永远用 `-eq`——从 C/Python 迁移来的手最容易犯这个错，而且赋值不报错、悄悄改变量，危害极大。

**`-in` 与 `-contains` 是镜像**：`值 -in 集合`，`集合 -contains 值`——**左边永远是"单个"，哪边是集合看运算符**。搞反了（`1..10 -in 5`）不报错但永远 False，是安静的坑。

**数组遇上 `-eq` 会变成过滤器**：`@(1,2,1) -eq 1` 返回 `1,1`（**匹配的子集**）而不是 True/False！当左边是集合时，比较运算符逐元素求值并收集真值结果。这个行为有时极其好用（一句筛数组），有时让"我以为在比布尔"的人当场迷惑——见到 `-eq` 返回一串值，先看左边是不是数组。

**布尔组合**：`-and`、`-or`、`-not`（可写 `!`）。习惯给每个子条件加括号：`($_.Status -eq 'Running') -and ($_.Name -like 'W*')`——可读性比省四个字符重要。取反优先用 `-not $x` 而不是 `$x -eq $false`："没在响应"写作 `-not $_.Responding`，读起来就是它的意思。

## 11.3 Where-Object：通用过滤的三种写法

`Where-Object`（别名 `Where`、`?`）对管道里每个对象求值一次条件，真则放行。三种形态：

**老式（v1–v2 时代，脚本块）**——`-FilterScript` 参数（位置参数，通常省略）接一个脚本块：

```powershell
Get-Service | Where-Object { $_.Status -eq 'Running' -and $_.Name -like 'W*' }
```

**简化式（v3+，属性直接比较）**——单条件时省掉脚本块与 `$_`：

```powershell
Get-Service | Where-Object Status -eq 'Running'
```

读作"where Status 等于 Running"，与人话同构。**限制：只能表达一个比较**——要 `-and`/`-or`、要访问两个属性、要复杂表达式时，必须回到脚本块。两种形态完全等价（同一条件结果一致），选哪个看条件复杂度。

**弃用式**：v1 的 `Where-Object $_.Status ...`（无脚本块直接写表达式）只在极老的脚本里出现，认得即可。

三形态对照一张表（读旧脚本时认脸用）：

| 形态 | 写法 | 能力 | 出现场景 |
|---|---|---|---|
| 脚本块（标准） | `Where-Object { $_.Status -eq 'Running' }` | 任意复杂度 | 一切场合的保底 |
| 简化式 | `Where-Object Status -eq 'Running'` | 仅单条件 | 快速查询、教程示例 |
| 老式 | `Where-Object $_.Status -eq 'Running'`（无块） | 历史遗留 | 只在 v1/v2 时代脚本里 |

另有一个阅读提示：网上代码常把 `Where-Object` 缩成 `?`（问号）——`Get-Service | ? Status -eq 'Running'`。交互里省字，**脚本里别用**（问号的可读性差，且与正则语法混淆）；这与第 04 章"别名不出脚本"的纪律一致。

`$_`（同义 `$PSItem`）是脚本块里的**"当前对象"占位符**——`Where-Object`、`ForEach-Object`、计算属性的 `e` 里都是它。它是 PowerShell 出镜率最高的符号，务必读顺：`{ $_.Status -eq 'Running' }` = "这个对象的状态是运行中"。

## 11.4 左过滤与客户端过滤的等价性验证

两种路经常能表达同一条件，结果应一致。以"explorer 进程"为例（本机可跑）：

```powershell
$a = @(Get-CimInstance -ClassName Win32_Process -Filter "Name='explorer.exe'")   # WQL 方言，仓库端筛
$b = @(Get-CimInstance -ClassName Win32_Process | Where-Object Name -eq 'explorer.exe')   # 客户端筛
$a.Count -eq $b.Count    # True
```

两者计数相等，但工作量天差地别：第一条 WMI 仓库只交回匹配行；第二条把**全部进程**序列化穿过进程边界再筛。日常抉择树：**有过滤参数先用参数 → 参数表达不了加 Where-Object → 两者可叠加**（先 `-Filter` 粗筛减量，再 `Where` 精筛——对远程数据源是最优组合）。

## 11.5 通配符与正则的分界

`-like` 的世界只有 `*`（任意串）和 `?`（单字符）；`-match` 的世界是完整正则（第 28 章专讲）。选择原则：

- 模式是"前后缀包含"级别的简单形态 → `-like`，可读性最好；
- 模式涉及结构（开头锚定、重复次数、字符区间、分组提取）→ `-match`；
- 拿不准时先 `-match`：正则是超集，且 `.`、`*` 等在正则里有精确语义——**别用 `-like` 硬凑复杂模式，那是自造方言**。

两族都有 `c` 前缀变体处理大小写敏感场景（如比较文件名、比较证书指纹）。

## 11.6 过滤实战三连

把本章工具放进三个日常任务，体会"左过滤 + 计算属性 + Where"如何分工。

**实战一：找出本机"没有在运行"的自启动服务**（排障起手式）：

```powershell
Get-CimInstance -ClassName Win32_Service -Filter "StartMode='Auto'" |
    Where-Object State -ne 'Running' |
    Select-Object Name, DisplayName, State
```

左过滤让 WMI 只交回自启动的服务（`StartMode='Auto'` 是 WQL 方言），Where 在客户端筛"没跑起来的"。这类"应起未起"清单是早巡检的第一张表。

**实战二：列出空闲比例低于两成的本地磁盘**：

```powershell
Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Where-Object { ($_.FreeSpace / $_.Size) -lt 0.2 } |
    Select-Object DeviceID,
        @{ n = '空闲GB'; e = { [math]::Round($_.FreeSpace / 1GB, 1) } },
        @{ n = '空闲比'; e = { '{0:P1}' -f ($_.FreeSpace / $_.Size) } }
```

三段各司其职：WQL 限定本地硬盘（DriveType=3 排除网络盘/光驱）；脚本块 Where 做除法比较（**计算后再比，参数化过滤表达不了**——这正是"参数粗筛 + Where 精筛"的叠加式）；两个计算属性一个算数值一个出百分比（`-f` 格式串，第 29 章）。

**实战三：找出 7 天内没写过日志的目录**（卫生巡检）：

```powershell
Get-ChildItem -Path 'C:\Some\Logs' -Directory |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) } |
    Select-Object Name, LastWriteTime
```

注意条件里的**括号先执行**：`(Get-Date).AddDays(-7)` 算出七天前的时刻，再与每个目录的 `LastWriteTime` 比较。日期对象可以直接比较次序（第 08 章的方法在这里变现），`AddDays` 这类日期算术是时间窗口过滤的标配。

三个实战的共同骨架：**参数能筛的交给参数（左），参数筛不了的交给 Where（右），输出交给 Select 的计算属性**。这也是下一章综合实战的预演。

## 11.7 运算符族谱补遗

比较族之外，还有几个"长得像运算符"的符号在此归位（都在后面章节展开，先挂上号）：

- `-replace`/`-split`/`-join`：文本三兄弟（第 20/29 章）——注意它们是**运算符**不是方法，`'a,b' -split ','`；
- `-f`：格式化运算符（第 29 章），`'{0:P1}' -f 0.25`；
- `-is`/`-isnot` 已在表内；`-as` 是"温和转型"（第 20 章）：`'42' -as [int]` 失败给 `$null` 不抛错；
- `-band/-bor` 等位运算（低频，用到再查 `about_Comparison_Operators`）；
- `..` 范围运算符（第 20 章）：`1..10`。

## 11.8 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| 条件写成 `Status = 'Running'` | `=` 是赋值不是比较 | 比较一律 `-eq` 族 |
| 条件"永假"且不报错 | `-in/-contains` 方向搞反；或 `-eq` 大小写/类型不匹配被强转 | 记住"左单右集"口诀；类型先看 `gm` |
| `-eq` 返回一串值 | 左边是数组，比较变过滤 | 要布尔先 `@($x).Count` 或 `-contains` |
| `-Filter` 里写 `-eq` 报错 | WQL/AD 方言不认 PowerShell 运算符（WQL 用 `=`；AD 的 `-Filter` 反而认 `-eq/-like`） | 查该命令帮助的示例；两套方言列表见第 14 章 |
| 简化式 Where 多条件失效 | `Where A -eq 1 -and B -eq 2` 不是合法简化式 | 多条件回脚本块 |
| 大结果集过滤慢 | 全量拉回客户端筛 | 左过滤优先；远程场景叠加 `-Filter + Where` |
| CIM `-Filter` 左过滤在 macOS 上跑不了 | 无 CIM 栈 | 改用 `Get-Process -Name` 参数做"仓库端过滤"，与客户端 `Where-Object` 比对 |

## 11.9 性能小实验：亲眼看一次左过滤的赢面

用 `Measure-Command`（第 06 章介绍过）给两种过滤计时，感受差距量级：

```powershell
Measure-Command { Get-CimInstance -ClassName Win32_Process -Filter "Name='explorer.exe'" }
Measure-Command { Get-CimInstance -ClassName Win32_Process | Where-Object Name -eq 'explorer.exe' }
```

本机进程不过两三百个，两条命令都在亚秒级，差距不明显——**这正是误导所在**：数据量小时错误选择没有痛感，等它上量（远程万条记录、全域几万台机器）时早已定型。做实验时不妨把对比拉大：`Get-WinEvent -FilterHashtable @{LogName='System'; Id=7040}`（左过滤，事件日志按索引直取）对比 `Get-WinEvent -LogName System | Where-Object Id -eq 7040`（全量拉回）——后者在系统日志几万条时会慢到令人发指，甚至内存吃紧。左过滤不是洁癖，是规模下的生死线。

顺带预告：`Get-WinEvent` 的 `-FilterHashtable` 是左过滤的高级形态——把多个条件打包成哈希表交给日志引擎，比多个 `-Filter` 参数叠加更清晰，第 21 章讲哈希表后你会觉得它理所当然。

## 11.10 本章要点

- 两条路：**左过滤**（命令参数/方言，减负减网络流量，优先）与 **Where-Object**（通用客户端过滤，兜底与精筛）。
- 比较运算符：`-eq/-ne/-gt/-lt/-ge/-le`、通配 `-like`、正则 `-match`、成员 `-in/-contains`（左单右集）、类型 `-is`；**默认不区分大小写**，敏感加 `c` 前缀；`= 是赋值**。
- 集合在左时比较变过滤（`@(1,2,1) -eq 1`）——特性也是坑。
- `Where-Object` 两形态：简化式（单条件）与脚本块（`$_`，任意复杂度），等价。
- `-Filter` 是方言重灾区（WQL 单等号 vs AD 的 PS 运算符），照帮助示例写。
- 规模之下左过滤是生死线：数据量小没痛感，恰是最危险的错觉；`Measure-Command` 是亲眼看差距的工具。

**动手实验**：① 在命令行逐个验证 `5 -eq 5`、`'HELLO' -eq 'hello'`、`'HELLO' -ceq 'hello'`、`5 -in 1..10`、`1..10 -contains 5`、`@(1,2,1) -eq 1`；② 数出 `100` 以内 15 的倍数个数（`1..100 | Where-Object { $_ % 15 -eq 0 }`，应是 6 个）；③ 用简化式和脚本块两种写法过滤运行中的服务，验证计数一致；④ 复现 11.4 的等价性验证并体会两份命令的分寸；⑤ 故意写 `Where-Object Status = 'Running'`，观察赋值表达式在脚本块里的行为；⑥ 把实战三的三条命令各自换成你的真实路径/阈值跑一遍。

实验参考：①里 `@(1,2,1) -eq 1` 会打印两行 `1`——不是布尔，是过滤结果；⑤赋值表达式在脚本块里返回赋的值，`'Running'` 非空恒为真，于是**过滤失效变成全通过**——这就是"用错 = 却不报错"的活标本；⑥实战二的输出两列数值列，一个 GB 一个百分比，正好复习第 10 章的格式串。

对应示例（可选）：`examples/11_filtering/`——比较运算符全家断言、`-in/-contains` 方向性、数组过滤特性、两种 Where 等价、左/右过滤计数一致性。

---

本篇（二 对象与管道）其余各章：[06 管道](./06-pipeline-first.md) · [07 模块生态](./07-modules-usage.md) · [08 对象](./08-objects.md) · [09 深入管道](./09-pipeline-deep.md) · [10 格式化](./10-formatting.md) · [12 学以致用](./12-integration.md)

---

本篇（二 对象与管道）导航：[06 管道](./06-pipeline-first.md) · [07 模块](./07-modules-usage.md) · [08 对象](./08-objects.md) · [09 深入管道](./09-pipeline-deep.md) · [10 格式化](./10-formatting.md) · [12 学以致用](./12-integration.md)


补充阅读：本章所有断言都可以在本教程示例库 examples/11_filtering/ 里双引擎复现。

---

本篇导航：[06 管道](./06-pipeline-first.md) · [07 模块](./07-modules-usage.md) · [08 对象](./08-objects.md) · [09 深入管道](./09-pipeline-deep.md) · [10 格式化](./10-formatting.md) · [12 学以致用](./12-integration.md)
