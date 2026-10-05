# 06 管道初步——一个命令一个职责

> 本章对应原书第 6 章"管道：连接命令"。让 PowerShell 独树一帜的不是"能运行命令"（哪个 Shell 都能），而是**管道**：把一个命令的输出接到下一个命令的输入，让多个各司其职的小命令组成一条任务流水线。

你在 cmd 里见过 `dir | more`——管道符 `|` 把左边命令的输出送给右边。PowerShell 保留了这层意思，但把管道里流动的东西从**文本**换成了**对象**（第 01 章的地基）。本章先用"肉眼可见"的方式体会管道：导出文件、对比快照、生成报告、批量变更。管道的深层规则（什么能接什么）是第 09 章的主角。

## 6.1 为什么"一个命令一个职责"值得追求

先立设计观。对比两种风格完成任务"把进程清单存成 CSV"：

- 巨型命令风格：找一个"获取进程并导出 CSV"的命令（`Export-ProcessToCsv`？不存在）；
- 管道风格：`Get-Process | Export-Csv procs.csv`——`Get-Process` 只管"取"，`Export-Csv` 只管"存"，中间的运输由管道负责。

管道风格的好处随任务复杂度指数放大：需求从"进程"换成"服务"，只改左半边；从"CSV"换成"HTML"，只改右半边；想先过滤再导出，中间插一段就行。**每个命令是一个乐高块，管道是卡扣**。这也是全书最重要的代码审美：看到一条长管道，你应该能逐段读出"谁在取数、谁在筛、谁在排序、谁在呈现"。

## 6.2 导出族：Export-Csv 与 Import-Csv

```powershell
Get-Process | Export-Csv procs.csv
Import-Csv procs.csv
```

第一条命令把**进程对象**整个交给 `Export-Csv`，它把每个对象变成一行、每个属性变成一列。用记事本打开文件能看到结构：

```
# TYPE System.Diagnostics.Process        ← 5.1 会写这行"类型头"，7+ 默认不写
"Name","SI","Handles","VM","WS","CPU",…  ← 列名行（每个属性一个）
"ApplicationFrameHost","…",…             ← 每对象一行
```

三个值得停下来的观察：

**CSV 里的列远比屏幕上多。** 屏幕上 `Get-Process` 只显示七八列，CSV 里几十列都在——因为屏幕输出经过格式化系统"挑重点"（第 10 章讲谁在挑），而 `Export-Csv` 拿到的是**完整对象**。"屏幕上看到的"永远只是对象的一个摘要视图，这是 PowerShell 的重要世界观。

**导入的是快照不是实时数据。** `Import-Csv procs.csv` 读出的对象反映的是导出那一刻的状态。这个"快照"语义正是它的价值：发邮件给同事、留档、回放。

**两个引擎的差异点**：5.1 导出的 CSV 默认带 `# TYPE` 首行，且老版本 Excel 直接双击打开会因编码问题中文乱码；7+ 默认不带类型头（默认编码也变成了 UTF-8）。要写"两引擎行为一致"的脚本，5.1 一侧显式加 `-NoTypeInformation`（7+ 里这个参数已无效果但接受）。

`Export-Csv` 常用参数再记两个：`-Append`（追加不覆盖）、`-Delimiter ';'`（欧式 CSV）。回读端 `Import-Csv` 同样简单——读出来的每一行是 `[pscustomobject]`（第 08 章细讲这个类型），可以继续管道。

## 6.3 序列化族：Export-Clixml 与基线比对

CSV 只保留"属性名=值"这一层。如果想要更完整的序列化（含类型信息、嵌套结构），用 PowerShell 专属的 CliXML 格式：

```powershell
Get-Process | Export-Clixml baseline.xml
Import-Clixml baseline.xml
```

CliXML 的招牌场景是**配置基线比对**——原书给的标准流程，值得整段吸收：

1. 在"标准配置"的机器上建基线：`Get-Process | Export-Clixml reference.xml`；
2. 把文件带到待检查的机器上（或反过来把那台机器的输出带回来）；
3. 比对：

```powershell
Compare-Object -ReferenceObject (Import-Clixml reference.xml) -DifferenceObject (Get-Process) -Property Name
```

`Compare-Object`（别名 `diff`）做三件事：括号里的 `Import-Clixml` 与 `Get-Process` **先执行**（圆括号强制求值顺序，第 03 章的老朋友），结果分别喂给 `-ReferenceObject`/`-DifferenceObject`；`-Property Name` 把比对聚焦到名字列。输出形如：

```
Name              SideIndicator
----              -------------
calc              =>
mspaint           =>
conhost           <=
```

读这张表的钥匙是 `SideIndicator`：`=>` 表示只在**右边**（当前机器）存在，`<=` 表示只在**左边**（基线）存在，两边都有的不出现。于是"新机器上多了哪些进程、少了哪些进程"一眼可见——审计、排障、安全检查的通用手法。

两个实战提醒：**`-Property` 几乎必给**。不给的话，比对会精细到每个属性值——进程的内存量每秒都在变，结果就是"全部有差异"，等于没比。选一个或几个"身份性"的列（如 Name、SID、路径）才有意义。另外，PowerShell 的 `diff` **不是文本文件比对工具**（不输出逐行差异），比两个文本文件请用 `git diff` 或 `fc.exe`。

## 6.4 Out 族：输出到底去了哪

问一个教科书式的问题：`Get-Service` 的输出去了哪？答案：**管道尽头有一个你看不见的终点**。每次回车，PowerShell 都默默补了一句：

```powershell
Get-Service | Out-Default
```

`Out-Default` 把对象送往 `Out-Host`（画到屏幕）。明白这层，`Out` 族命令就都好理解了——它们全是"管道终点"的候选：

| 命令 | 去向 |
|---|---|
| `Out-Host` | 屏幕（分页版是管道接 `more`） |
| `Out-File 路径` | 文本文件 |
| `Out-Null` | 丢弃（"我只要副作用不要输出"时用） |
| `Out-GridView` | 可排序可过滤的图形表格（Windows） |
| `Out-Printer` | 打印机（Windows） |
| `Out-String` | 转成字符串（把对象拍平成文本给外部程序用） |

重定向符 `>` 是 `Out-File` 的语法糖：`dir > list.txt` 就是 `dir | Out-File list.txt`。要记的是 `Out-File` 的两个脾气：**默认行宽 80 列**（屏幕表格超过 80 列会被硬折行，存进文件就"变样"了，用 `-Width 200` 调）；**默认编码两个引擎不同**（5.1 是 Unicode/UTF-16，7+ 是 UTF-8），跨引擎交换文件时显式给 `-Encoding`。

## 6.5 ConvertTo 族：动词的精确含义

```powershell
Get-Service | ConvertTo-Html
```

满屏 HTML 刷过去了，文件却没生成。这正是动词想告诉你的：

- **`ConvertTo-`（转换）**：只改变形态，**不管保存**——输出还在管道里，等你接下一段；
- **`Export-`（导出）**：转换 + **保存到文件**，一步到位。

所以存 HTML 的完整句式是"转换后交给终点"：

```powershell
Get-Service | ConvertTo-Html | Out-File services.html
```

为什么留两个粒度？因为"转换完不落盘"本身是需求：把 CSV 转好贴进邮件正文、把 HTML 发给 Web 接口、把 JSON（第 31 章的 `ConvertTo-Json`）塞进 REST 请求体。**动词是合同**：看到 `Export-` 就知道会写文件，看到 `ConvertTo-` 就知道还得自己安排落点。同理还有一对 `Import-`（读文件成对象）与 `ConvertFrom-`（把字符串转成对象）。

`ConvertTo-Html` 的实用参数：`-Property Name,Status` 挑列、`-Title`/`-PreContent` 加标题说明——生成巡检报告的三件套（第 12 章实战化）。

## 6.6 变更类管道：从"看"到"动手"

管道不只运输"数据"，还能运输"操作对象"。看这条危险命令（**不要运行**）：

```powershell
Get-Process | Stop-Process
```

它会把本机**每一个**进程逐个杀掉，包括关键系统进程——大概率当场蓝屏。教学价值在于揭示规则：**同名词的命令之间可以管道直连**——`Get-Process` 的输出（Process 对象）恰好是 `Stop-Process` 想要的输入。收敛到具体目标就是安全的日常操作：

```powershell
Get-Process -Name Notepad | Stop-Process
Get-Service -Name Spooler | Set-Service -StartupType Manual
```

"先 Get 看清楚，再接动词动手"是 PowerShell 变更操作的标准姿势；配合第 04 章的 `-WhatIf` 可以先干跑预演。至于"哪些命令能接哪些命令"的判定规则（以及接错了会发生什么），第 09 章给出完整判据——那之前，**只在同名词之间直连**是安全的经验法则。

## 6.7 管道的流式本质与内存观

一个常被问到的问题：`Get-Process | Export-Csv procs.csv` 里，进程对象是"先全部取完再一次性写出"，还是"取一个写一个"？答案是**后者**——PowerShell 管道是**流式**的：上游命令每产出一个对象，就立刻沿管道交给下游，下游处理完再要下一个（术语叫"逐对象的事务式传递"）。

这带来两个实际推论：

**内存友好**。几万行的事件日志接 `Select-Object -First 100`，取满 100 个后上游会被**提前终止**（管道停止传递），不会把几十万行全拉进内存。验证方式很直白：

```powershell
Measure-Command { Get-EventLog Security | Select-Object -First 5 }
Measure-Command { Get-EventLog Security }
```

两条命令的耗时天差地别——前者在拿到第 5 条后就叫停了整个枚举。（`Measure-Command` 返回 TimeSpan 对象，`$_.TotalSeconds` 是秒数；它是评估"两种写法哪个快"的标准工具，第 29 章还有它的进阶用法。）

**顺序即产出顺序**。`Sort-Object` 这类"必须看完全部才能排"的命令是例外（它们被迫缓冲所有对象再输出），除此之外管道各段看到对象的顺序与上游产出顺序一致。这也是"流式"与"批量"两类命令的分界：`Sort-Object`、`Group-Object`、`Measure-Object` 是缓冲型，`Where-Object`、`ForEach-Object`、`Select-Object -First` 是流式型。写长管道时心里有这张分类表，能预判内存行为。

## 6.8 把本章命令串成一次完整巡检

用一个半真实的小任务把本章工具全用上。需求：给"正在运行的服务"出一份 HTML 报告，并留一份 CSV 底档。

```powershell
Get-Service |
    Where-Object Status -eq 'Running' |
    Select-Object Name, DisplayName |
    ConvertTo-Html -Title '运行中服务巡检' -PreContent '<h2>本机巡检快照</h2>' |
    Out-File running-services.html -Encoding utf8
```

逐段读：`Get-Service` 取全部服务对象；`Where-Object` 按状态筛（第 11 章正式讲）；`Select-Object` 挑两列——**这步很关键**，不挑的话 HTML 表格会把几十个属性全部铺开，报告没法看；`ConvertTo-Html` 加标题和说明文字；`Out-File` 落盘并指定 UTF-8（HTML 里如果有中文服务名，不指定编码浏览器会按系统代码页误读）。同样的数据留底档只需把最后两段换成 `Export-Csv running-services.csv -NoTypeInformation -Encoding UTF8`。

这个"取数 → 筛 → 挑列 → 呈现/落盘"的四段式，就是 PowerShell 日常任务的万能骨架，第 12 章会把它升级成完整的多步流程。

## 6.9 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| CSV 在 Excel 里中文乱码 | 5.1 默认编码与 Excel 预期不符 | `Export-Csv -Encoding UTF8`，Excel 用"数据→从文本导入"兜底 |
| `Out-File` 存的表格"断了行" | 默认行宽 80 列，宽表被硬折 | `Out-File -Width 4096`（按需给大值） |
| `Compare-Object` 输出几百行全是差异 | 没给 `-Property`，比对精细到每列值 | 给"身份列"（Name/Id/路径），不给易变列（内存/时间） |
| 管道后 `Sort-Object` 看似没生效 | `Format-Table` 排在 `Sort-Object` 前面（右到左解析） | 排序永远放在格式化之前（第 10 章专题） |
| `diff` 两个文本文件结果看不懂 | PowerShell 的 diff 是对象比对不是文本比对 | 文本差异用 `git diff`/`fc.exe` |
| `Export-Csv` 报"文件被占用" | 文件正被 Excel 打开 | 关掉 Excel，或先 `-Append` 到新文件 |
| 管道杀进程杀到自己 | `Get-Process | Stop-Process` 无差别打击 | 永远带 `-Name`/`-Id` 收窄目标 |

这五条里前三条几乎每个人都会遇到一次——遇到了回来翻这张表，比搜索引擎快。

## 6.10 本章要点

- 管道让命令各司其职：**取数的只管取，筛的只管筛，存的只管存**；长管道逐段可读是代码审美。
- `Export-Csv`/`Import-Csv`：完整对象↔CSV 行；快照语义；5.1 的 `# TYPE` 头与 `-NoTypeInformation`。
- `Export-Clixml` + `Compare-Object` + `-Property` = **配置基线比对**工作法；`SideIndicator` 读法。
- 每条命令的输出终点是 `Out-Default`（→`Out-Host`）；`>` 是 `Out-File` 的糖；行宽 80 与编码差异要显式管理。
- 动词合同：`ConvertTo-` 只转换，`Export-` 转换+保存，`Import-`/`ConvertFrom-` 反向。
- 变更类管道：同名词直连（`Get-X | Verb-X`），先 Get 后动手，`-WhatIf` 预演。

**动手实验**：① 把服务清单导成 CSV 再导回来，对比 `Import-Csv` 前后的对象数量；② 打开 CSV 数数列数，与屏幕上的 `Get-Service` 列数对比，验证"屏幕是摘要"；③ 建一个 Clixml 基线，启动一个记事本，再比对，从 `SideIndicator` 里找到那个 `=>` 的记事本；④ `Get-Process | ConvertTo-Html | Out-File p.html`，浏览器打开看一眼；⑤ 用 `-WhatIf` 干跑 `Get-Process -Name Notepad | Stop-Process`；⑥ 用 `Measure-Command` 对比 `Get-Process | Select-Object -First 3` 与 `Get-Process` 的耗时差，感受提前终止；⑦ 给 6.8 的巡检命令换一个数据源（`Get-Process`）跑通。

实验提示（卡住再看）：②屏幕只有 3 列而 CSV 有十多列；③先 `Get-Process | Export-Clixml ref.xml`，开记事本，再 `Compare-Object -ReferenceObject (Import-Clixml ref.xml) -DifferenceObject (Get-Process) -Property Name`；⑤`-WhatIf` 加在 `Stop-Process` 那一段（管道最后一段）；⑥`Measure-Command { … }` 返回 TimeSpan，看 `.TotalMilliseconds`。

对应示例（可选）：`examples/06_pipeline_first/`——CSV/Clixml 往返守恒、`Compare-Object` 的方向断言、ConvertTo-Html 结构断言、管道终点的重定向等价性、拉起子进程再经管道停止的闭环。

> **下一篇衔接**：到现在用的都是内置命令。第 07 章打开命令生态——模块与 PowerShell 库，命令从几百个变成几万个。
>
> 读到本章你已经能完成"取数—筛—挑列—落盘"的完整闭环，这是后面所有章节反复复用的骨架。

---

本篇（二 对象与管道）其余各章：[07 模块生态](./07-modules-usage.md) · [08 对象](./08-objects.md) · [09 深入管道](./09-pipeline-deep.md) · [10 格式化](./10-formatting.md) · [11 过滤](./11-filtering.md) · [12 学以致用](./12-integration.md)
