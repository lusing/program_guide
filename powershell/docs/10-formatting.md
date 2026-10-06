# 10 格式化——及如何正确使用

> 本章对应原书第 10 章"格式化及如何正确使用"。第 08 章说"屏幕输出只是对象的投影"，本章讲投影仪本身：默认格式从哪来、四个 Format 命令怎么用，以及全教程最容易踩的坑——**右到左解析**。

PowerShell 不是报表工具，但"把收集到的信息以正确的样子交出去"是日常刚需——给同事的表格、发邮件的 HTML、存档的文本。格式化系统就是"对象 → 人可读文本"的最后一公里，它大部分时候无声工作，偶尔给你惊喜（列宽刚好）、也给你惊吓（管道顺序一错全乱）。

## 10.1 输出的一段隐秘旅程

先回答第 06 章埋的问题：`Get-Process` 的输出到底怎么变成屏幕上那张表的？完整旅程六步：

1. `Get-Process` 把 `System.Diagnostics.Process` 对象放进管道；
2. 管道尽头站着隐藏的 **`Out-Default`**（你每按一次回车，它都被自动追加）；
3. `Out-Default` 把对象转交 **`Out-Host`**（默认输出设备是屏幕）；
4. `Out-` 族命令**不认识普通对象**——它们只吃"格式化指令"。于是 `Out-Host` 把对象转交**格式化系统**；
5. 格式化系统按对象类型查规则（下一节的三条规则），生成格式化指令，交回 `Out-Host`；
6. `Out-Host` 按指令渲染出你看到的表格。

关键推论：**这趟旅程对一切 `Out-` 终点都成立**。`Out-File`、`Out-Printer`、`Out-String` 收到普通对象时同样会先请格式化系统加工——所以"`Get-Process | Out-File p.txt` 存的文件和屏幕长得一样"不是巧合，是同一条流水线。这也再次解释了第 06 章的现象：`Export-Csv` **不是** `Out-` 族，它直接吃对象，所以存下全部属性；`Out-File` 吃的是"格式化后的文本"，存的就是屏幕那几列。**存数据用 Export/ConvertTo，存"给人看的"用 Out-File**——这条分界线现在有了机制层面的解释。

## 10.2 默认格式从哪来：三条规则与一个谎言

格式化系统拿到对象后，按顺序尝试三条规则定"默认长相"：

**规则一：预定义视图（`.format.ps1xml`）**。安装目录下有一组 `*.format.ps1xml` 文件（进程的视图在 `DotNetTypes.format.ps1xml` 里），每个视图按**类型全名**登记：显示哪些列、列头叫什么、多宽、用什么格式串。`Get-Process` 那张精心排版的表就来自这里。想亲眼看：`notepad "$PSHOME\DotNetTypes.format.ps1xml"` 搜 `System.Diagnostics.Process`（**只看不改**——这些文件带数字签名，多个空格都会作废签名）。自定义视图文件的写法本教程不展开（用到时查 `about_Format.ps1xml`）。

**规则二：默认属性集（`Types.ps1xml` 的 DefaultDisplayPropertySet）**。没有预定义视图的类型（比如 `Win32_OperatingSystem` 这类 WMI/CIM 对象），退而求其次查 `Types.ps1xml` 里登记的"默认显示属性集"——第 08 章 `Get-Member` 里见过的 `DefaultDisplayPropertySet` 就是这份名单。名单里有六个属性，于是屏幕显示六项。

值得亲眼看一次这两个文件（各五分钟，理解立刻落地）：

```powershell
notepad "$PSHOME\DotNetTypes.format.ps1xml"    # 搜 System.Diagnostics.Process
notepad "$PSHOME\Types.ps1xml"                  # 搜 Win32_OperatingSystem
```

在 `format.ps1xml` 的 Process 视图里你会看到 `<TableControl>` 内一列列的 `<TableColumnHeader>`——`PM(K)` 这个"谎言列头"、列宽、右对齐标记全在其中；在 `Types.ps1xml` 里你会看到 `<DefaultDisplayPropertySet>` 下六七个 `<Name>` 元素。**只读不改**：文件带数字签名，改一个空格就作废。看完这两个文件的收获是：默认格式不再是魔法，而是一张你读得懂的配置表——将来遇到"某个第三方模块的输出特别难看"，你就知道该去哪找病根（大概率是模块没提供视图文件，走到了规则三）。

**规则三：全部属性**。连属性集都没登记的对象，显示所有属性。

定了显示哪些属性之后，还有一条**排版规则**：**不超过 4 个属性 → 表格；5 个及以上 → 列表**。`Win32_OperatingSystem` 为什么是列表不是表？六个属性，触发了 5+ 规则——列表才能不截断地放下。这条规则解释了大量"为什么它长这样"的困惑。

最后一个真相，原书称之为"格式化系统撒谎"：**列头不是属性名**。`Get-Process` 的 `PM(K)` 列——没有任何属性叫 `PM(K)`，真实属性叫 `PM`，`PM(K)` 只是视图文件里定义的**列头别名**（还顺手标注了单位 K）。结论：**查属性名的唯一权威是 `Get-Member`，列头只能当阅读提示**。用错了列头名（比如脚本里 `$_.PM(K)` 或 `Select-Object 'PM(K)'`）就会踩空。

## 10.3 Format 四件套

覆盖默认格式，用 `Format-` 族命令。它们**不改变对象**（对象早在管道里流过去了），只生成格式化指令——所以有一条铁律先立好：**Format- 命令永远放在管道最后一段**（后面只准接 `Out-` 终点）。原因见 10.5 的右到左解析。

**Format-Table（ft）**——表格：

```powershell
Get-Service | Format-Table -AutoSize -Property Status, Name, DisplayName
```

- `-AutoSize`：按内容收紧列宽（代价：格式化系统必须看完所有对象才能定宽——大结果集会明显变慢，且失去了流式输出）；
- `-Property`：挑列，**你写什么列头就是什么**（顺手把小写属性名写成漂亮大小写）；支持通配符 `-Property *Name*`；
- `-Wrap`：超宽内容折行而不是截断；
- `-GroupBy`：按某属性分组渲染（每组一张小表）。

**Format-List（fl）**——列表，属性垂直排。两个高频用法：看**单个对象的全部细节**——`Get-Service -Name Spooler | Format-List *`；以及"属性太长被表格截断"时（比如 Description、SID）——列表每行独占，不截断。

**Format-Wide（fw）**——单属性多列铺开，适合"只要一列名字"的场景：`Get-Process | Format-Wide Name -Column 4`。

**Format-Custom（fc）**——按自定义视图渲染，日常少用（`ConvertTo-Json` 之前调试嵌套结构时会见到它的默认形态）。

## 10.4 格式化版的计算属性：多三把刷子

第 08 章的计算属性在 Format 命令里升级了——除了 `n/e`，还接受三个**格式专用键**：

```powershell
Get-Process |
    Format-Table Name,
        @{ Label     = '内存(MB)'
           Expression = { [math]::Round($_.WS / 1MB, 1) }
           Align      = 'Right'
           Width      = 12
           FormatString = 'N1' }
```

- `Label`：列头（与 `Name`/`n` 同义）；
- `Align`：整列对齐（Left/Right/Center）——数字列右对齐是排版常识；
- `Width`：固定列宽（字符数）；
- `FormatString`：.NET 格式串——`'N1'` 千分位一位小数、`'P1'` 百分比、`'X'` 十六进制、`'yyyy-MM-dd'` 日期。这套格式串与 `-f` 运算符（第 29 章）同源，学一次到处用。

这就是"用 PowerShell 出体面报表"的全部素材：挑列、算列、定头、定宽、定格式的组合拳。

FormatString 常用值速查（同一套语法通用于计算属性、`-f` 运算符与 .NET 的 ToString）：

| 格式串 | 例子输入 → 输出 | 用途 |
|---|---|---|
| `N0` / `N1` / `N2` | `1234.5` → `1234.5`（N1，一位小数） | 数量、金额 |
| `P0` / `P1` | `0.25` → `25%`（P0） | 百分比（自动乘 100） |
| `X` / `X8` | `255` → `FF` | 十六进制（掩码、句柄） |
| `yyyy-MM-dd` | 日期 → `2026-10-06` | 日期（大小写敏感，MM 是月、mm 是分） |
| `HH:mm:ss` | 时间 → `09:30:00` | 时间 |
| `#,0.0` | 自定义组合 | 千分位加一位小数 |

注意 P 系列会**自动乘 100**——拿 25 想显示 25% 要传 `0.25` 而不是 `25`，这是格式串的第一大坑。日期格式串里 `MM`（月）与 `mm`（分钟）的大小写之差是第二大坑，都值得在本子上记一笔。

## 10.5 右到左解析：本章最大的坑

看两条只差语序的命令：

```powershell
Get-Service | Sort-Object Status | Format-Table -Property Name, Status   # ✓
Get-Service | Format-Table -Property Name, Status | Sort-Object Status   # ✗
```

第二条不报错，但**排序完全没生效**。为什么？PowerShell 解析你的意图是**从右往左**找"终点命令"：`Sort-Object` 不是终点，`Format-Table` 也不是——但 `Format-Table` 把对象**变成了格式化指令**，`Sort-Object` 拿到的是指令（没有 `Status` 属性可排），原样放行。屏幕上看到的是未排序的表，**没有任何报错**。

这就是右到左解析的实用教训：**Format- 之后对象已经死了（变成指令），一切数据处理必须发生在它之前**。纪律版表述：

> 排序、过滤、选择、分组 → 永远在 Format- 之前；Format- 之后只接 `Out-File`、`Out-Host`、`Out-GridView`、`Out-String` 等终点。

同理还有一条姊妹坑：`Format-Table | Export-Csv`——存进 CSV 的会是指令的属性（`TypeName`、`FormatEntryInfo` 一类），完全不是你要的数据。遇到"导出的 CSV 全是乱七八糟的列"，第一反应检查管道里有没有 Format。

右到左家族的变体一起认清（症状全是"不报错但结果不对"）：

- `Format-Table | Where-Object …`——过滤失效（指令没有那些属性）；
- `Format-Table | Select-Object -First 3`——截断的不是数据行而是渲染块，行数对不上；
- `Format-List | Format-Table`——两次格式化叠加，后者把前者当普通对象重新走三规则；
- `Sort-Object | Format-Table | Export-Csv`——前半段对，最后一段前功尽弃。

判定口诀：**沿着管道从左到右读，一旦遇到 Format-，后面只允许出现 Out- 打头的命令**。写长命令时养成"最后写格式化"的习惯，与第 12 章的四段式骨架天然一致。

## 10.6 文件宽度与 Out-String

`Out-File` 落盘时按默认 **80 列**宽渲染宽表格（第 06 章提过），大表会被折得面目全非。解法二选一：`Out-File -Width 4096`，或 `Format-Table -AutoSize | Out-File -Width 4096`（AutoSize 定列宽、Width 定行宽，双管齐下）。`Out-String` 是"把对象变字符串"的通用出口（给邮件正文、日志、变量拼接到用），同样接受 `-Width`。

顺带认识 `Out-GridView`（仅 Windows）：`Get-Process | Out-GridView` 弹出一张**可排序、可过滤、可加规则**的图形表格——交互式探索数据的利器，配合 `-OutputMode Multiple` 还能让用户在窗口里勾选对象返回管道（做"人工挑选"环节的脚本神器）。

## 10.7 风格速决表：什么时候用什么

| 需求 | 选择 | 一句话理由 |
|---|---|---|
| 浏览多对象、看关键几列 | `Format-Table -AutoSize` | 表格是密度之王 |
| 看单个对象的全部细节 | `Format-List *` | 列表不截断 |
| 属性值很长（路径/描述/SID） | `Format-List` 或 `-Wrap` | 表格会截断 |
| 只要一列名字 | `Format-Wide -Column n` | 空间利用率高 |
| 给人的报告落盘 | `Format-* \| Out-File -Width 大` | 视图落盘 |
| 给程序的 数据落盘 | `Export-Csv` / `ConvertTo-Json` | 保数据不保视图 |
| 交互式探索 | `Out-GridView` | 排序过滤零成本 |
| 给行内变量拼文本 | `Out-String` | 对象→字符串的通用出口 |

最后一行的 `Out-String` 补一句：它也是"格式化进字符串"的调试通道——`$x = Get-Service | Format-Table | Out-String` 之后 `$x` 是渲染好的多行文本，能拼进邮件、日志、错误消息。而"格式化好的文本"再也不能当数据用——这条不可逆性（对象→文本单向门）是本章的哲学注脚：**格式化是出口，不是加工车间**。

## 10.8 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| `Format-Table \| Sort/Where` 悄悄失效 | 右到左：Format 后对象已变指令 | 数据处理全部前置，Format 收尾 |
| CSV/HTML 导出的列乱七八糟 | 管道里残留 Format- 命令 | Export/ConvertTo 前把 Format- 全删掉 |
| 屏幕属性名与 `gm` 对不上 | 列头是别名（`PM(K)`），会撒谎 | 属性名只信 `Get-Member` |
| 大表 `-AutoSize` 明显变慢 | 必须看完全部对象才能定宽 | 大结果集放弃 AutoSize，或先 `-First` 截断 |
| `Out-File` 的表断行 | 默认 80 列 | `-Width` 给大值 |
| 长字段（描述/路径）被表格截断 | 表格按列宽截断 | 换 `Format-List` 或 `-Wrap` |
| 排序键断言在 `Format-` 之后失效 | Format 输出的是格式指令对象，业务属性根本不在上面（`Sort-Object` 不报错，只是静默按缺省值排） | 断言"指令对象上该属性不存在"，而不是断言排出来的顺序 |

## 10.9 本章要点

- 输出旅程：管道尽头 `Out-Default → Out-Host → 格式化系统 → 指令 → 渲染`；一切 `Out-` 终点都走这条路——**存数据用 Export/ConvertTo，存视图用 Out-File**。
- 默认三规则：预定义视图（`.format.ps1xml`）→ 默认属性集（`Types.ps1xml` 的 DefaultDisplayPropertySet）→ 全属性；**≤4 属性表格、≥5 列表**。
- 列头会说谎，属性名只信 `Get-Member`；`PM` 是 AliasProperty，`PM(K)` 只是列头。
- 四件套：`Table`（-AutoSize/-Property/-Wrap/-GroupBy）、`List`（看全貌/防截断）、`Wide`（单列铺开）、`Custom`。
- 格式化计算属性五键：Label/Expression/Align/Width/FormatString；`Out-String` 是对象→文本的单向门。
- **右到左解析**：Format- 是管道的"最后一站"，之后只接 Out- 终点。

实验参考：①`PM(K)`/`NPM(K)`/`WS(K)` 三个都在 `format.ps1xml` 里有定义而 `gm` 里查无此名；③错误版不报错但状态列乱序依旧；⑥`Out-File` 里只有 Name/Status 两列文本，`Export-Csv` 里是完整对象的所有属性——这一对比就是"视图 vs 数据"最直观的教具。

**动手实验**：① `Get-Process | gm` 对照屏幕列头，找出两个"撒谎"列头；② 用 `notepad "$PSHOME\DotNetTypes.format.ps1xml"` 找到 Process 视图（只读不改）；③ 亲手复现右到左坑：两条语序命令各跑一遍对比；④ 给 `Get-Process` 出一张"Name + 内存(MB) 右对齐 N1 格式"的表；⑤ `Get-Service | Out-GridView` 体验图形筛选（Windows）；⑥ 把 ③ 的正确版分别接 `Out-File` 与 `Export-Csv`，对比两者内容的差异，体会"视图 vs 数据"。

## 10.10 延伸：五条"体检命令"

本章知识浓缩成五条随敲随查的体检命令（遇到输出问题按序排查）：

```powershell
# 1. 这对象到底是什么类型？（格式化规则的钥匙）
Get-Process | Get-Member | Select-Object -First 1 TypeName

# 2. 它的默认显示属性集是什么？（为什么屏幕只显示这几列）
(Get-Process | Get-Member -MemberType PropertySet).Name

# 3. 这个类型有没有预定义视图？（format.ps1xml 里搜类型名）
Select-String -Path "$PSHOME\*.format.ps1xml" -Pattern 'System.Diagnostics.Process'

# 4. 我当前的管道里还有没有活对象？（Format 之前 vs 之后）
Get-Service | Select-Object -First 1 | Get-Member
Get-Service | Format-Table | Select-Object -First 1 | Get-Member   # 已是指令

# 5. 渲染成文本长什么样、多宽？（Out-String 是无损出口）
$x = Get-Service | Format-Table -AutoSize | Out-String -Width 200
$x.Length; $x.Substring(0, 80)
```

第 4 条的两行对照是右到左规则最直观的体检——同一条管道加不加 Format，对象的"验尸报告"完全不同。把这五条放进你的工具箱，格式化的疑难杂症基本都有入口。

---

本篇（二 对象与管道）其余各章：[06 管道](./06-pipeline-first.md) · [07 模块生态](./07-modules-usage.md) · [08 对象](./08-objects.md) · [09 深入管道](./09-pipeline-deep.md) · [11 过滤](./11-filtering.md) · [12 学以致用](./12-integration.md)


补充阅读：本章所有断言都可以在本教程示例库 examples/10_formatting/ 里双引擎复现。

---

本篇导航：[06 管道](./06-pipeline-first.md) · [07 模块](./07-modules-usage.md) · [08 对象](./08-objects.md) · [09 深入管道](./09-pipeline-deep.md) · [11 过滤](./11-filtering.md) · [12 学以致用](./12-integration.md)
