# 04 运行命令——语法、命名与解剖刀

> 本章对应原书第 4 章"运行命令"。原书的态度值得开门见山：**没有脚本、没有编程，仅仅是运行命令**——这是 PowerShell 的主要工作模式，也是"普通驾驶员"阶段能完成大量真实工作的方式。

网上的 PowerShell 示例常让人觉得它是一门编程语言。真相是：PowerShell 首先是 Shell（第 01 章的心智模型）。你输入一条命令、加几个参数、回车、看到结果——与你在 cmd.exe 或 bash 里做的事同一形态。什么时候会有"脚本"？原书描述的那个时刻非常真实：**当你厌倦了一遍遍输入同样的命令，把调通的命令复制进文本文件、改名为 `.ps1` 的那一刻，你就"写"了一个 PowerShell 脚本**。脚本不是学习的起点，是命令用熟的副产品（第 22 章才正式登场）。

## 4.1 解剖一条完整命令

看一条包含所有"部件"的命令：

```powershell
Get-EventLog -LogName Security -ComputerName Win8,Server1 -Verbose
```

从左到右：

- **`Get-EventLog`**——命令名。动词-名词形式（下一节细讲）；
- **`-LogName Security`**——参数名 `-LogName`，值 `Security`。值不含空格和标点，不用引号；
- **`-ComputerName Win8,Server1`**——数组参数：逗号分隔的两个值（第 03 章的 `string[]`）；
- **`-Verbose`**——开关参数：只有名字没有值（第 21 章讲它点亮哪条流）。

标点规则一张表（**PowerShell 挑剔空格与破折号，不挑剔大小写**）：

| 规则 | 正确 | 错误 |
|---|---|---|
| 命令名与第一个参数之间必须空格 | `Get-EventLog -LogName x` | `Get-EventLog-LogName x` |
| 参数名以短横线开头，参数名与值之间空格 | `-LogName Security` | `-LogNameSecurity`、`-LogName:Security` |
| 多个参数值（数组）用逗号分隔 | `-ComputerName a,b` | `-ComputerName a b`（成了两个参数） |
| 命令名内部的短横线不能省 | `Get-Content` | `Get Content`、`GetContent`、`Get=Content`、`Get_Content` |
| 大小写无关 | `get-service` = `GET-SERVICE` | —— |

新手报错的一大半来自这张表：读作"Get Content"很自然，敲成 `Get Content` 就是"找不到命令 Get"。养成对空格、短横线的敏感度，是消灭低级错误的最短路径。

## 4.2 命令的分类：Cmdlet、函数、应用程序

严格术语（第 03 章已给过一版，这里正式收全）：

- **Cmdlet**：原生编译命令，如 `Get-Service`。读音 "command-let"，这个词只在 PowerShell 生态里存在；
- **函数**：用 PowerShell 自己的语言写的命令（第 24 章你将写自己的函数）；
- **应用程序**：一切外部可执行程序，`ping`、`ipconfig`、`net.exe`；
- **命令**：以上全部的统称。

日常运行的大多是 Cmdlet 与函数，但**应用程序照常可用**：`net use` 在 PowerShell 里原样工作。微软的态度是"你已经会的继续用，同时提供更好的新工具"——`ping` 可用的同时也有对象输出的 `Test-Connection`（输出能继续管道，见第 08 章）。老命令不必急着换，但当需要把结果**当作数据继续处理**时，Cmdlet 版本几乎总是更好的选择。

## 4.3 命名惯例：动词-名词

所有 Cmdlet（以及微软期望所有函数）都遵守 **动词-单数名词** 结构。动词来自一份**批准动词表**：

```powershell
Get-Verb
```

大约一百来个，按分组（Common/Data/Lifecycle/Security…）排列。常用的不过二十个：`Get`（读取）、`Set`（修改）、`New`（新建）、`Remove`（删除）、`Invoke`（执行动作）、`Stop`/`Start`、`Export`/`Import`、`ConvertTo`/`ConvertFrom`……（注意 `New`、`Where` 这些"动词"语法上并不是动词——习惯就好。）

这套惯例的真正价值是**可猜测性**。看看 `New-Service`、`Get-Process`、`Set-Service` 之后，试着回答：创建 Exchange 邮箱的命令叫什么？修改 Active Directory 用户的呢？——`New-Mailbox`、`Set-ADUser`，你大概率猜对了。**先按惯例猜名字，再用 `help *名词*` 或 `Get-Command` 验证**，这是比搜索引擎快得多的工作流。名词部分没有统一清单（各产品自定义），但都用**单数**：`Get-Process` 不是 `Get-Processes`。

未批准动词并非不能用，但写模块时会收到警告（第 27 章会见到），遵守惯例也是在帮未来读你代码的人。

## 4.4 别名：命令的昵称

命令全名清晰但长（`Set-WinDefaultInputMethodOverride`……），于是有**别名**。查某命令有哪些别名：

```powershell
Get-Alias -Definition Get-Service
```

输出会告诉你 `gsv` 是 `Get-Service` 的别名。反查（看到别人写的 `gsv` 不认识时）用 `help gsv`——帮助会显示**全名**的帮助，语法部分写明真实身份。别名的性质要记牢：

- **别名只是名字的替换**，参数、行为完全不变；
- **别名不能带参数**（Unix 的 `alias ll='ls -l'` 在 PowerShell 里没有对应物——那是函数干的事）；
- 会话内可用 `New-Alias` 自建，**关闭窗口即失效**（要持久化得写进 profile）；自建别名别人看不懂，**不推荐**；
- 内置别名里有大量"跨血统兼容"产物：`ls`/`cat`/`ps` 来自 Unix（`Get-ChildItem`/`Get-Content`/`Get-Process`），`dir`/`cls` 来自 cmd。它们让你迁移时手不生，但**写进脚本时一律用全名**——本教程正文的示例遵守这条纪律，只在"纯交互"场景示意别名。

## 4.5 三种合法的偷懒

第 03 章讲过语法图，这里把"省字数"的手段收拢成三招，并说明各自的适用边界。

**招一：参数名缩写。** 输入到能唯一识别的前缀即可：`-comp` 代替 `-ComputerName`——前提是没有别的参数也以 `comp` 开头。配合 Tab 键：敲前缀再 Tab，自动补全成全名。

**招二：参数别名。** 有些参数有官方短别名，如 `Get-EventLog -ComputerName` 的别名 `-Cn`。它们不在帮助里明示（能从 `(Get-Command Get-EventLog).Parameters.ComputerName.Aliases` 挖出来），Tab 补全会列出来。知道即可，别依赖。

**招三：位置参数。** 语法图里参数名被单独方括号包住的（如 `Get-ChildItem [[-Path] <string[]>]`）可以只给值不给名：`Get-ChildItem C:\users` 等价于 `-Path C:\users`。位置参数必须**按顺序**出现在命名参数之前，顺序错了值就挂到错误的参数上——`move file.txt users\` 这种写法省字但可读性差，原书的建议也就是本教程的纪律：

> **交互式敲命令可以用快捷；任何要保存下来的东西（脚本、博客、文档）一律全名全参数。**

## 4.6 Show-Command：图形化拼命令

被空格、逗号、引号折磨时，Windows 上有个救命稻草：

```powershell
Show-Command Get-EventLog
```

弹出一个图形表单，把该命令的参数按**参数集分页签**摆好（第 03 章的参数集概念在这里可视化）。填完点"复制"回到 Shell 粘贴——你得到一条**全名全参数**的规范命令。它一次只能服务一个命令、且需要 GUI（服务器核心版没有），但作为"学语法的辅助轮"非常好用。非 Windows 平台无此命令。

## 4.7 外部命令的坑与两把钥匙

大部分外部命令在 PowerShell 里直接跑没问题（`whoami`、`net use`）。但当命令**参数很多、含引号或特殊字符**时，PowerShell 解析器可能猜错你的意图——它毕竟要先按 PowerShell 的规则拆解你的输入，再转交外部程序。两把钥匙：

**钥匙一：调用操作符 `&` + 变量。** 把可执行文件路径放进变量、参数值也放进变量，用 `&` 调用：

```powershell
$exe = 'C:\tools\vcbMounter.exe'
$targetHost = 'server'
& $exe -h $targetHost -u 'joe' -p 'password' -s 'name:somepc' -r 'somewhere' -t 'incremental'
```

`&` 的语义是"把后面的值当作命令来调用"。因为路径和参数都在变量里，PowerShell 不再试图解析它们内部的特殊字符。任何外部命令都可以这样安全地调。（`&` 与 `::`、`.` 一起构成 PowerShell 的"调用三兄弟"，第 29 章总表收全。）

**钥匙二：停止解析符号 `--%`（仅 Windows）。** 写在外部命令名之后，PowerShell 把后面的一切原封不动交给 cmd 的规则：

```powershell
sc.exe --% qc bits
```

代价是 `--%` 之后**变量不再展开**（`$n` 会被当成字面量 `$n` 传过去）——原书演示过 `sc.exe --% qc $n` 查不到服务、`qc bits` 才成功的对照。它是给"cmd 语法长命令"准备的逃生舱，不是日常工具。

## 4.8 面对红字：错误信息的读法

红色报错不是失败，是 Shell 在指路。两件事要会做：

**读位置。** 错误信息几乎总带 `行:字符` 定位（脚本场景第 26 章细讲）。命令行里最常见的红字是 `无法将"get"项识别为 cmdlet`——意思就是"这个词我不认识"，九成是拼错或漏了短横线。

**分辨"鸡同鸭讲"。** 原书有个经典案例：输入 `Get-ChildItem C:\Windows /s` 得到"第二路径不得为驱动器或 UNC 名称"——谁都不知道"第二路径"是什么。真相：`/s` 是 **cmd 的语法**，PowerShell 把它当成了**下一个位置参数的值**（第二个路径！）。解药永远是同一个：`help Get-ChildItem` 查正确参数名（`-Recurse`），用全名重写。**错误信息像外语时，先怀疑自己带了别的 Shell 的口音。**

三类最高频的红字与它们的真实含义：

| 错误关键词 | 真实含义 | 第一反应 |
|---|---|---|
| 无法将"X"项识别为 cmdlet… | 名字拼错 / 漏短横线 / 该命令不在本机 | 重敲名字，`Get-Command X*` 验证 |
| 找不到接受实际参数"X"的位置形式 | 多余的裸值没参数可绑（位置参数用光了） | 给中间参数补名字，或查语法看位置 |
| 无法绑定命令的参数，因为名称"X"不存在 | 参数名拼错（如 `-Recurss`） | `-Recur` 按准 Tab；`help` 查全名 |

这张表的用法不是背，是**读红字最后一段**——PowerShell 的错误信息几乎总在最后一句告诉你它"以为你要什么"，把那句读懂，八成的错误当场可解。

## 4.9 从 cmd 迁移：对照表与口音检查

PowerShell 给 cmd 老用户准备了别名级兼容，同时每个 cmd 命令都有正式的 Cmdlet 对应物：

| cmd 习惯 | 兼容别名 | 正式命令 |
|---|---|---|
| `dir` | ✔ | `Get-ChildItem` |
| `cd` | ✔ | `Set-Location` |
| `cls` | ✔ | `Clear-Host` |
| `copy` | ✔ | `Copy-Item` |
| `move` | ✔ | `Move-Item` |
| `del` / `rd` | ✔ | `Remove-Item` |
| `ren` | ✔ | `Rename-Item` |
| `type` | ✔ | `Get-Content` |
| `md` / `mkdir` | ✔（函数） | `New-Item -Type Directory` |
| `set`（变量） | ✔ | `Set-Variable` |
| `echo` | ✔ | `Write-Output` |

真正要改的不是命令名，是**口音**——两套最容易带进 PowerShell 的 cmd 习惯：

- **斜杠开关**：cmd 的 `/s` 在 PowerShell 里是 `-Recurse`（4.8 节"第二路径"事故的根源）；
- **等号赋值**：cmd 的 `set name=value` 在 PowerShell 里是 `$name = 'value'`（变量赋值是语言功能，第 20 章）。

迁移期的实用策略：别名继续用（手感不断），但**每用一个别名，顺手 `help 它` 看一眼全名**——两周后你会自然过渡到 Cmdlet 词汇，并开始享受它们输出对象的红利。

## 4.10 命令解析的优先级

当你输入一个词，PowerShell 按**固定顺序**寻找它是什么：

1. **别名**（`gsv` 最先被替换成全名）；
2. **函数**；
3. **Cmdlet**；
4. **外部可执行文件**（按 PATH 顺序）。

这就是为什么你能在 PowerShell 里输入 `ls` 得到增强版的目录列表（别名先命中），而 `whoami` 才轮到外部程序。想看一个名字背后"其实有几个候选"，用 `Get-Command 名字 -All`；想强制选择某一种，写全路径或用 `&` 调用（第 4.7 节的钥匙一）。这也解释了一个实践建议：**自定义函数别与内置命令重名**——同名时函数会压住 Cmdlet，团队里其他人拿到你的脚本就出现"同一个命令两台机器行为不同"的灵异事件。

## 4.11 一条命令的一生

把本章的规则串成时间线，你输入回车之后 Shell 里发生的事：

1. **解析**：按第 4.1 节的标点规则，把你的输入切成命令名、参数名、参数值（切不动就红字——"无法识别"类错误全部发生在这步）；
2. **找命令**：按优先级（别名 → 函数 → Cmdlet → 外部程序）解析命令名；
3. **绑参数**：把每个值挂到正确的参数上（位置参数按位次、命名参数按名字；绑不上就报"找不到接受实际参数"类错误）；
4. **执行**：命令跑起来，产出对象；
5. **输出**：到了管道尽头，格式化系统（第 10 章）把对象画成屏幕上的表格或列表。

本章管的只是 1–3 步的书写规则。第 8 章深入第 4 步（对象长什么样），第 9 章深入第 3 步的管道形态，第 10 章深入第 5 步。带着这张地图读后面章节，不会迷路。

## 4.12 本章要点

- PowerShell 的主模式是**运行命令**；脚本是命令调通后的复制粘贴（第 22 章）。
- 标点铁律：短横线连命令名与参数名，**空格**分隔一切；大小写无所谓。`Get Content`/`Get_Content`/`-Name:Value` 都是红字预定户。
- **动词-单数名词** + 批准动词表 = 命令名可猜可搜；`Get-Verb` 看全表。
- 别名是纯昵称（不带参数、会话级、脚本里禁用）；三种合法偷懒（参数缩写/参数别名/位置参数）只用于交互，**落盘全名**。
- 外部命令照常可用；解析打架时用 `& $exe 参数` 或 `--%`（Windows，之后不展开变量）。
- 红字读位置、查帮助、检查是否带了 cmd/Unix 口音。

**动手实验**：① 用 `Get-Command -Verb Export` 数数有几个导出类命令；② 查出 `gsv`、`gps`、`gal` 各是谁的别名；③ 用**位置参数**列 `C:\Windows` 下前 3 项；④ 同一条命令分别用缩写参数与全参数各写一遍对比可读性；⑤ 体验 `Show-Command Get-Process`（Windows）；⑥ 故意输 `Get Service` 和 `Get-ChildItem C:\ /s`，读两条红字，用帮助改对。

对应示例（可选）：`examples/04_running_commands/`——断言批准动词表、别名解析、位置绑定、参数缩写、`-WhatIf` 干跑、大小写无关与外部命令调用。

> **下一章预告**：到目前为止数据都来自"命令自己吐出来"。第 05 章打开 PowerShell 的地图观：注册表、环境变量、函数表……一切数据存储都被统一装成"驱动器"。

---

本篇（一 壳与命令）其余各章：[01 心智模型](./01-why-powershell.md) · [02 初识](./02-meet-powershell.md) · [03 帮助系统](./03-help-system.md) · [05 提供程序](./05-providers.md)
