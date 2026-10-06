# 03 帮助系统——可发现性的入口

> 本章对应原书第 3 章"使用帮助系统"。原书作者把这一章放在全书极靠前的位置并反复强调它的重要性，理由在本章开头就会看到。

GUI 之所以好上手，是因为它有**可发现性**：菜单、右键、工具栏提示把"能做什么"摊开在你眼前。命令行天生没有这个摊开的面板——PowerShell 用帮助系统把它补了回来。原书有个毫不客气的论断，值得原样转述：**如果你不愿意花时间读 PowerShell 的帮助文档，你就无法高效使用 PowerShell**。作者们在课堂上见到的学生问题，90% 靠"坐下来读一遍帮助"就能解决。这不是态度说教，而是使用方式问题：帮助系统同时回答了三个高频问题——

1. 我该用**哪个命令**？（不需要搜索引擎，帮助里就能搜）
2. 命令为什么**报错**？（帮助里的语法与参数说明给出正确用法）
3. 哪些命令能**组合**？（帮助里的管道绑定信息告诉你接线的位置，第 9 章展开）

从本章起，本教程只会在正文中讲清每个命令的关键参数，**完整的参数清单请养成 `help <命令>` 的习惯**——这不是"参见帮助"，而是这个工具链的预定用法：帮助就是 PowerShell 的右键菜单。

## 3.1 一个术语澄清：命令与 Cmdlet

PowerShell 里可执行的东西有多种：**Cmdlet**（编译型的核心命令，如 `Get-Service`）、**函数**（脚本型命令）、外部程序（如 `net.exe`）等。它们的统称是**命令**。你日常运行的大多数是 Cmdlet 和函数，两者在帮助系统里一视同仁——帮助主题按名字索引，不关心实现形式。本教程行文也遵循这个约定：说"命令"泛指，说 Cmdlet 特指。

## 3.2 可更新的帮助：为什么第一次看帮助是空的

PowerShell v3 引入了**可更新的帮助**机制：帮助文档不随安装包内置（太占体积且很快过时），而是在你第一次需要时提示下载。所以全新环境里运行 `help Get-Service`，看到的可能是一份"自动生成的简要帮助"——只有名字、语法骨架，外加一行提示：用 `Update-Help` 下载完整帮助。

```powershell
Update-Help
```

它做的事：连到微软的帮助服务器，把所有已安装模块的帮助文件下载到本地。两个引擎在这件事上行为不同（差异标注）：

| | Windows PowerShell 5.1 | PowerShell 7+ |
|---|---|---|
| 默认保存范围 | `AllUsers`（写入 System32 下的模块目录） | `CurrentUser`（写入用户文档目录） |
| 是否需要管理员 | **是**（否则报 `UpdatableHelpSystemRequiresElevation` 错误） | 通常不需要 |

离线环境的配套设计是 `Save-Help`：找一台能上网的机器，把帮助"**下载成文件**"而不是装进帮助系统：

```powershell
Save-Help -DestinationPath '\\fileserver\ps-help' -UICulture en-US
```

然后内网机器用 `Update-Help -SourcePath '\\fileserver\ps-help'` 从这台文件服务器更新，全程不接触互联网。这一对命令是企业管理员给全公司维护帮助版本的标准做法。另外，PowerShell 的帮助文档已在 GitHub 开源（github.com/PowerShell），在线版本永远最新，`Update-Help` 大约每月跑一次是合理的节奏。

## 3.3 Get-Help、Help 与 Man

访问帮助的命令是 `Get-Help`。你也会大量见到 `help`——**`help` 不是 Cmdlet，而是一个函数**，它把 `Get-Help` 的输出送进分页器（`more`），一页一页显示。`man` 则是 `help` 的别名（Unix 血统的纪念品）。三者的内容完全一致：

```powershell
Get-Help Get-Service
help Get-Service          # 同上，但分页显示
man Get-Service           # help 的别名
```

日常敲命令用 `help`（省三个字符还分页）；在脚本里要用对象时用 `Get-Help`（第 08 章会看到帮助也能当对象处理）。分页看烦了按空格翻页、`Q` 退出；**控制台里 Ctrl+C 永远是"打断当前命令回到提示符"**，不是复制——复制是鼠标选中后按回车或 Ctrl+Shift+C（宿主相关）。

## 3.4 用帮助找命令：通配符与 about 主题

帮助系统的第一个用途是**发现命令**。`Get-Help` 的 `-Name` 参数（位置参数，可省略参数名）支持通配符。想操作事件日志但不知道用什么命令：

```powershell
help *event*
help *log*
```

返回的列表有三列：`Name`（主题名）、`Category`（Cmdlet/Function/HelpFile…）、`Module`（所属模块）。这张表有几个值得消化的细节：

- **列表覆盖所有已安装模块**——即使模块还没加载进内存，它的命令帮助也列得出来。这是"发现被遗漏命令"的正规途径（模块机制第 07 章展开）；
- 列表最后混进了 `about_Eventlogs`、`about_Logical_Operators` 这样的 **HelpFile** 类别——它们是"**关于**主题"（about topics），不挂靠任何具体命令，讲的是语言与概念的背景知识。搜 `*log*` 时 `about_Logical_Operators` 因为名字里含 "logi" 也被捞了出来——通配符不智能，搜宽一点是特性不是缺陷；
- 命中**唯一**主题时，`help` 不列清单而是直接显示该主题的完整帮助（`help Get-EventL*` 试试）。

about 主题是帮助系统里最容易被忽视的宝藏。语言本身的所有背景文档都在里面：`about_Arrays`、`about_Quoting_Rules`、`about_CommonParameters`……列出全部：

```powershell
help about_*
```

本书时代的老习惯"网上搜示例"可以退役了：**示例就在帮助里**（3.6 节）。

## 3.5 读语法图：本章核心技能

打开任一命令的帮助，SYNTAX 部分是一张"语法图"。以 `Get-EventLog` 为例（简化排版）：

```
SYNTAX
    Get-EventLog [-AsString] [-ComputerName <string[]>] [-List] [<CommonParameters>]

    Get-EventLog [-LogName] <string> [[-InstanceId] <Int64[]>] [-After <DateTime>] ... [<CommonParameters>]
```

这张图信息密度极高，逐个符号拆解。

### 3.5.1 参数集：一段语法 = 一种用法

SYNTAX 出现了**两段**，说明该命令有两个**参数集**（parameter set）——两种互不兼容的使用方式。规则：**一旦你用了某参数集特有的参数，就只能继续用该集合内的参数**。上例中 `-List` 与 `-LogName` 分属两个集合，互斥——"列出本机有哪些日志"和"读某个日志的内容"是两种任务，微软用参数集把两种入口分开，你混着写就会报"无法绑定参数"类错误。只带公共参数运行时，Shell 默认选第一个参数集。

### 3.5.2 方括号的三种含义

方括号在语法图里出现在三个位置，含义各不相同——这是初学者最容易混的地方，一张表说清：

| 写法 | 含义 | 例 |
|---|---|---|
| `[-ComputerName <string[]>]` | 参数名和值**一起**被括起：**可选参数** | 可不给 `-ComputerName`，默认本机 |
| `[-LogName] <string>` | 参数名**单独**被括起：**位置参数**（本例且必选） | `Get-EventLog Application` 等价于 `-LogName Application` |
| `<string[]>` | 尖括号是**类型占位**；类型后的 `[]` 表示**接受数组** | 可传一个值，也可逗号分隔传一串 |

判断"可选还是必选"只看一条：**参数值 `<...>` 有没有被包进方括号**。`[-LogName] <string>` 里 `<string>` 裸露在外——必选；只是名字被括起来，所以它同时是位置参数。

### 3.5.3 开关参数与通用参数

`[-AsString]` 这种**只有名字没有值的参数**叫**开关参数**（`<SwitchParameter>`）——像开关一样只有"开"一种动作，写了就是开，不写就是关。开关参数永远可选、永远按名使用（没有"位置"）。

每段语法末尾的 `[<CommonParameters>]` 指**通用参数**：所有 Cmdlet 都自动带的八个参数（`-Verbose`、`-Debug`、`-WarningAction`、`-WarningVariable`、`-ErrorAction`、`-ErrorVariable`、`-OutVariable`、`-OutBuffer`），外加两个"风险缓解"参数 `-WhatIf`/`-Confirm`（仅变更类命令提供）。它们由引擎统一实现，第 21/25/26 章会逐一用到，现在混个脸熟即可——想预习就 `help about_Common_Parameters`。

### 3.5.4 参数值的书写规则

类型占位告诉你值长什么样，三条规则覆盖日常：

**string 含空格要引号**。`C:\Windows` 不用引号，`C:\Program Files` 必须 `'C:\Program Files'`（单双引号目前可互换，建议养成单引号习惯——原因第 20 章揭晓）。

**数组用逗号**。`string[]` 参数给多个值就是逗号分隔：`-ComputerName Server-R2,DC4,Files02`。引号规则按"单个值"判定：`'Server-R2','Files02'` 合法，而 `'Server-R2,Files02'` 是**一台名字里带逗号的电脑**——经典笔误。

**圆括号强制先执行**。想从文本文件读计算机名清单喂给参数：

```powershell
Get-EventLog Application -ComputerName (Get-Content names.txt)
```

圆括号的语义和数学课一致：先算里面。`Get-Content` 先执行，读出的每行一个名字，整体作为数组交给 `-ComputerName`。"把服务器清单维护在一个文本文件里，所有命令都用括号喂给它"是原书传授的实战模式，第 09 章还会进化出更优雅的管道版。

### 3.5.5 参数名缩写

参数名只需输入到**能唯一区分**的前缀：`-Li` 能代表 `-List`（没有别的参数以 Li 开头），`-L` 不行（`-LogName` 也以 L 开头）。加上第 02 章的 Tab 补全，长参数名的输入成本很低。但注意缩写是交互便利：**写进脚本文件时永远用全名**——脚本是要"将来被读"的，可读性优先（原书最佳实践，本教程全书的示例都遵守）。

## 3.6 要示例：-Examples

管理员大多靠示例学习，帮助系统内置了每个命令的官方示例：

```powershell
help Get-EventLog -Examples
```

只输出示例部分。示例从简到繁排列，看不懂的先跳过——帮助里的示例偶尔偏长，但**官方示例永远是"设计者预期用法"的第一手样本**，比网上随手抄的脚本可靠。`-Detailed` 则给"描述+参数+示例"，`-Full` 给全部（含每个参数的完整表格），按需取用。还可以用 `-Parameter Name` 只看一个参数的说明：

```powershell
help Get-Service -Parameter Name
```

`-Full` 输出里每个参数都有六行属性表：是否必需、位置、默认值、**是否接受管道输入**（第 09 章的钥匙）、是否接受通配符——这五行是深度使用任何命令前的必读项。

## 3.7 在线帮助

本地帮助由人写成，会滞后于产品。`-Online` 直接打开官方最新版：

```powershell
help Get-EventLog -Online
```

Windows 上还有 `-ShowWindow` 把本地帮助弹到独立窗口（不占控制台）。判断本地帮助可疑（示例跑不通、参数对不上）时，先查在线版——两版不一致时以在线为准，再跑一次 `Update-Help`。

## 3.8 检索命令的三条路

到现在你已经见过三种"找命令"的入口，分工明确：

| 入口 | 搜的是什么 | 特长 |
|---|---|---|
| `help *event*`（通配符） | **帮助主题** | 一网打尽：命令 + 函数 + about 主题，覆盖未加载模块 |
| `Get-Command -Noun *event*` | **命令本身** | 能按动词/名词/类型精确定向（`-Verb Get -CommandType Cmdlet`），返回对象可继续管道 |
| `Get-Verb` | **批准动词表** | 命名与"猜名字"的依据，不是搜索工具 |

经验法则：**不知道用什么命令时用 `help` 通配符；知道一半名字（名词或动词）时用 `Get-Command`；要给别人讲命名规范或写模块时用 `Get-Verb`**。顺带一提帮助文件本身落在哪：`Update-Help` 会把内容写进各模块目录的子目录（5.1 在 `C:\Windows\System32\WindowsPowerShell` 下需管理员；7 在用户文档的模块目录），出问题想"重装帮助"时，删掉对应目录再 `Update-Help -Force` 即可。

## 3.9 把一份 -Full 帮助读穿

用 `Get-ChildItem` 的 `-Path` 参数做一次"精读示范"，把上面所有规则串起来。`help Get-ChildItem -Parameter Path` 会给出类似这样的内容（中文系统为中文，这里是意译）：

```
-Path <String[]>
    指定一个或多个位置的路径。允许使用通配符。默认位置为当前目录 (.)。

    是否必需?                 False
    位置?                     1
    默认值                    当前目录
    是否接受管道输入?         true (ByValue, ByPropertyName)
    是否接受通配符?           True
```

六行表格逐行读：**不必需**——可以不带 `-Path` 直接跑；**位置 1**——第一个裸参数会绑给它（`Get-ChildItem C:\Windows` 那种写法的依据）；**默认值当前目录**——不带参数时列的是"你所在的目录"；**接受管道输入 ByValue, ByPropertyName**——这行现在是天书，但它是第 09 章整章的主角，记住"管道绑定信息就藏在参数帮助里"；**接受通配符**——所以 `*.exe` 可以直接放这里。

这段示范想教的方法论是：**任何一个命令用到第三遍，就该把它的参数表读一遍**——五分钟换来的参数视野，比背一百个示例值钱。

## 3.10 本章要点

- 帮助系统 = 命令行的"可发现性面板"：找命令、懂用法、查组合三合一；**读帮助是使用 PowerShell 的一部分**，不是补充。
- 可更新帮助：`Update-Help`（5.1 需管理员、7 免提权）装本地，`Save-Help`/`-SourcePath` 组合做离线分发，`-Online` 看最新。
- `help`（函数、分页）= `Get-Help`（Cmdlet）= `man`（别名）；Ctrl+C 打断。
- 找命令：通配符 `help *event*`；about 主题是语言级文档（`help about_*`）。
- 语法图四读：**参数集看段数、方括号看可选、名字单独括起看位置、尖括号加 [] 看数组**；开关参数无值；`[<CommonParameters>]` 八件套自动配。
- 值规则：空格加引号、数组逗号分隔、圆括号强制先执行；脚本里用全名。

- **平台差异**：本章示例用 `Get-Service` 作探针命令，它在 macOS/Linux 上不存在（launchd 不是 SCM）。改用 `Get-Process` 时本章每条断言依然成立——因为讲的是**元数据形状**（`-Name` 是 `string[]`、有多个参数集、有 switch 参数、通用参数十二件套），不是业务。断言要锚在元数据上，别锚在某个 Windows cmdlet 上。

**动手实验**（改编自原书本章实验，都能用本章知识独立完成）：

1. 运行 `Update-Help`（5.1 记得以管理员身份），装好本地帮助；
2. 哪个命令能把其他命令的输出转成 HTML？——`help *html*`；
3. 哪个命令操作**进程**？名词是 process——`Get-Command -Noun process`；
4. `Out-File` 默认每行多宽？哪个参数改宽度？——`help Out-File -Parameter Width`；
5. 怎么只取安全日志最近 100 条？——`help Get-EventLog -Parameter Newest`；
6. 8 个通用参数叫什么？——`help about_Common_Parameters`。

对应示例（可选）：`examples/03_help_system/`——验证帮助对象可编程访问：语法文本、参数表、参数集数量、通用参数存在性，全部不依赖帮助是否已更新（未更新的部分以带理由的 SKIP 呈现）。

---

本篇（一 壳与命令）其余各章：[01 心智模型](./01-why-powershell.md) · [02 初识](./02-meet-powershell.md) · [04 运行命令](./04-running-commands.md) · [05 提供程序](./05-providers.md)
