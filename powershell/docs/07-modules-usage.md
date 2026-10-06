# 07 扩展命令与模块生态

> 本章对应原书第 7 章"扩展命令"，并把 PowerShellGet 一节更新到 PSResourceGet 时代。学完本章，你面前的命令从出厂的几百个扩展到生态里的几万个，而且有一套**自学新命令集**的标准流程。

内置命令管的是操作系统本体：服务、进程、文件、注册表。但你迟早要管 DNS、DHCP、活动目录、Exchange、Azure——这些功能的命令以**模块**的形式到达你的 Shell。理解模块机制，就理解了"为什么 PowerShell 号称能管一切"。

## 7.1 只有一个 PowerShell

先拆掉一个流传极广的误解。装完 Exchange 后开始菜单里出现"Exchange Management Shell"——很多人因此以为存在"Exchange 版 PowerShell"。**右键看快捷方式的"目标"属性**，你会看到真相：

```
%windir%\system32\WindowsPowerShell\v1.0\powershell.exe
    -noexit -command import-module ActiveDirectory
```

它启动的就是标准的 `powershell.exe`，只是多传了一条"预加载某模块"的命令。**世界上只有一个 PowerShell 引擎**，产品间的差异只是"装了哪些模块"。这意味着：你可以打开一个普通 Shell，把 Exchange 模块和活动目录模块同时装进来一起用——产品快捷方式不是结界。（原书作者甚至专门为此写过博客澄清，PowerShell 团队官方背书过这个说法。）

## 7.2 两种扩展：管理单元（历史）与模块（现实）

**PSSnapin（管理单元）**是 v1 时代的扩展机制：一组 DLL 加配置 XML，必须先**安装注册**到系统才能被识别。查已注册的：`Get-PSSnapin -Registered`。微软自己已在淘汰它——现代产品全部改用模块，你在新环境里基本只会见到历史遗留的 SQL Server 老版本 snapin。**术语认识即可，新代码永远用模块。**

**模块**是一个目录：里面是命令（`.psm1` 脚本或编译 DLL）、可选的清单（`.psd1`）、帮助文件。它不需要注册——放进模块搜索路径（下一节）就被发现。查所有已安装模块：

```powershell
Get-Module -ListAvailable
```

输出按模块版本分组，列出每个模块的名字、版本和导出命令的**清单摘要**（`ExportedCommands` 列）。这个命令是"这台机器上到底有哪些弹药"的答案。

区分两个状态词：**Available（已安装未加载）**——模块躺在磁盘上，命令尚未进入内存；**Loaded（已加载）**——命令可用。`Get-Module`（不带参数）列已加载的，加 `-ListAvailable` 列全部已安装的。

## 7.3 自动发现与自动加载

v3 起的两个"魔法"，彻底改变了使用模块的方式：

**自动发现**：`Get-Command`、Tab 补全、`help` 能"看见"所有 Available 模块里的命令——哪怕它没加载。第 03 章你 `help *event*` 时列出的那些陌生模块命令，靠的就是它。

**自动加载**：直接运行一个未加载模块里的命令，引擎会**先悄悄加载模块再执行**。你可以全程不知道 Import-Module 的存在。

```powershell
Get-DnsClientCache        # 第一次运行：引擎自动加载 DnsClient 模块，然后执行
```

魔法背后的机关是一个环境变量——**`$env:PSModulePath`**：

```powershell
# 注意分隔符：Windows 是 ';'，macOS/Linux 是 ':'。写死 ';' 在 macOS 上等于没切。
$env:PSModulePath -split [regex]::Escape([System.IO.Path]::PathSeparator)
```

> **别写死分隔符。** `PSModulePath`（以及 `PATH`）是**平台相关的路径列表**：Windows 用分号 `;`，macOS/Linux 用冒号 `:`。在 macOS 上跑 `-split ';'` 会把整串当成一个目录，`$paths.Count` 恒为 1，看起来像"只有一个搜索路径"。要平台无关就用 `[System.IO.Path]::PathSeparator`——它是 .NET 提供的常量，两平台分别给出 `;` 和 `:`。

它是一串目录（Windows 系统模块目录、用户文档下的模块目录、pwsh 安装目录……），引擎在这些目录里找模块。两引擎的路径列表**不同**（5.1 有 `WindowsPowerShell` 目录，7 有 `PowerShell` 目录），所以"某模块装完两个引擎都看得见"的前提是装进了各自的路径——这是双引擎环境的经典坑（第 27 章开发模块时还会遇到）。模块不在路径里也不难：`Import-Module C:\SomePath\MyModule` 给全路径即可。

自动加载管的是"忘了 Import"的便利；反过来"用完想卸掉"用 `Remove-Module 模块名`（只卸出内存，不删磁盘文件）。

## 7.4 命令冲突与名词前缀

两个模块都导出 `Get-User` 怎么办？规则：**后加载的胜出**，先加载的同名命令被"遮蔽"。想精确点名，用"模块名\命令名"的全限定写法：`MyModule\Get-User`。

更优雅的解药是**名词前缀**：活动目录的命令叫 `Get-ADUser`，SQL 的叫 `Invoke-SqlCmd`——名词前面挂产品缩写，冲突概率趋近零，还自带"这命令来自哪个产品"的元信息。微软对此有正式规范（approved prefix），你将来写模块（第 27 章）也应给自己的名词加前缀。

## 7.5 玩转陌生模块：五步法

原书用一个真实任务演示"如何面对一组全新命令"——任务：清空本机 DNS 解析缓存。这套**五步法**比任何具体命令都值钱，是本章的核心交付物：

```powershell
# 第 1 步：按关键词搜命令（帮助系统覆盖未加载模块）
help *dns*

# 第 2 步：锁定一个模块，看它全部的命令（这一步同时把模块加载进来）
Import-Module DnsClient
Get-Command -Module DnsClient

# 第 3 步：看候选命令的帮助（语法、参数）
help Clear-DnsClientCache

# 第 4 步：跑起来（无必要参数，直接执行）
Clear-DnsClientCache

# 第 5 步：看不到动静？用 -Verbose 问它干了什么
Clear-DnsClientCache -Verbose
```

第 5 步值得专门说：**"没有消息就是好消息"是 Unix 传统，PowerShell 的传统是"每条命令都该会说详细话"**。开关参数 `-Verbose` 点亮第 4 条流（第 21 章机制篇），设计良好的命令会借它解释自己正在做什么。以后凡是对命令行为没把握，先 `-Verbose`（变更类命令还可以先 `-WhatIf`）。

第 2 步 `Get-Command -Module DnsClient` 的输出也值得读一眼。它是一张命令表，其中 `CommandType` 列透露"这命令是什么出身"：`Cmdlet` 是编译型（如 `Resolve-DnsName`），`Function` 是脚本型（DnsClient 里一大批 CIM 包装函数）。现代微软模块的趋势正是"薄薄的 Function 壳 + 底层 CIM 调用"——所以同一模块里两种类型混排是常态，使用上无差别。这一列还能帮你判断"这命令在我这引擎里有没有"，比如老 snapin 出品的命令在 pwsh 7 里就找不到。

**模块不止带命令，还可能带提供程序**。安装某些模块后 `Get-PSProvider` 会多出条目（比如启用远程处理后多出 `WSMan`——第 05 章的伏笔在这里兑现）。判断"新装的模块改变了我的 Shell 什么"，标准动作是 `Get-Command -Module 新模块` + `Get-PSProvider` 各看一眼：命令面和驱动器面，就是模块能扩展的全部疆域。

五步法的意义：面对任何新产品、任何陌生模块，你都不需要一本新书——搜、列、读、跑、问，循环往复。整个教程后面遇到新命令域时，我们会反复使用这套流程。

## 7.6 预加载：profile 与模块的搭配

自动加载让"开机加载"基本成了非需求，但两种场景仍想预载：常用模块想立刻可见（提示补全快）、或你想要一组固定的别名/函数。第 02 章的 profile 就是干这个的：

```powershell
# 在 $PROFILE 里写（示例）
Import-Module DnsClient
Set-Location C:\Work
```

每次启动 Shell 自动执行。历史包袱一提：v1-v2 时代用 `Export-Console` 导出 `.psc` 控制台文件保存 snapin 列表（模块时代之前的"预加载方案"），如今只剩考古价值。profile 里放 `Import-Module` 会让每次启动慢一点点（模块要真加载），所以只预载**每天必用**的，其余交给自动加载。

## 7.7 从互联网获取模块：PSGallery

本地安装的模块有限，真正的海洋在 **PowerShell Gallery**（powershellgallery.com）——微软**维护**的公共模块仓库（注意用词：维护平台 ≠ 生产并担保代码，Gallery 里是社区贡献，装之前看下载量、看源码、看维护者）。两代工具：

**PowerShellGet v2（5.1 与 7.0–7.3 时代，命令老但处处可用）**：

```powershell
Find-Module -Tag aws                        # 搜索
Install-Module AWSPowerShell -Scope CurrentUser   # 安装（不动系统目录，免管理员）
Save-Module AWSPowerShell -Path .           # 只下载不安装（离线分发用）
Update-Module / Uninstall-Module            # 升级 / 卸载
```

首次使用会提示"仓库不受信任"，选择 Yes（或先 `Set-PSRepository PSGallery -InstallationPolicy Trusted`）。`-Scope CurrentUser` 把模块装进你用户文档的模块目录——不需要管理员权限，也不污染机器全局，是默认推荐姿势。

**PSResourceGet（新一代，PowerShell 7.4+ 内置）**：命令从 `-Module` 后缀改成 `-PSResource` 后缀：`Find-PSResource`、`Install-PSResource`、`Update-PSResource`，更快、不依赖 NuGet 引导、支持仓库凭证。新脚本优先用它；给 5.1/老 7.x 用的脚本用 `Install-Module`。两代并存的判断办法与第 02 章的平台变量同款：探测 `Get-Command Install-PSResource` 是否存在。

安装后的模块对**对应引擎**生效（装进哪个引擎的模块路径，哪个引擎看得见——双引擎用户常犯的"装了但 pwsh 里找不到"就是装错了地方）。企业环境还可以搭内部 NuGet 仓库做私有分发，命令完全相同，只换仓库名。

## 7.8 本章要点

- **只有一个 PowerShell**：产品"管理 Shell"= 标准引擎 + 预载模块的快捷方式。
- snapin 是历史，模块是现实；`Get-Module -ListAvailable` 看弹药库，`Get-Module` 看已加载。
- 自动发现（未加载也能搜到）+ 自动加载（直接运行就加载）由 `$env:PSModulePath` 驱动；**两引擎路径不同**是双装环境的头号坑。
- 命令冲突：后加载者遮蔽；解法是 `模块\命令` 全限定名或名词前缀（`Get-ADUser` 的 AD）。
- **五步法**：搜（`help *x*`）→ 列（`Get-Command -Module`）→ 读（`help 命令`）→ 跑 → 问（`-Verbose`）——自学任何新命令域的循环。
- 网络生态：PSGallery + PowerShellGet v2（`Install-Module`）或 PSResourceGet（7.4+，`Install-PSResource`）；`-Scope CurrentUser` 是默认姿势；社区代码先审后装。

## 7.8 模块长什么样：目录解剖

"模块是目录"这句话具体化一下。找一个已安装模块看看（任选，如 `Microsoft.PowerShell.Utility`）：

```powershell
$m = Get-Module -ListAvailable Microsoft.PowerShell.Utility |
    Sort-Object Version -Descending | Select-Object -First 1
$m.Path                     # 模块入口文件
Split-Path $m.Path -Parent  # 模块目录
```

典型目录里的关键角色：

| 文件 | 角色 |
|---|---|
| `*.psm1` | **脚本模块**：用 PowerShell 语言写的命令（函数）集合，模块的入口 |
| `*.dll` | **二进制模块**：C# 编译的 Cmdlet 集合，功能更强的产品多用这种 |
| `*.psd1` | **模块清单**：名字、版本、作者、入口文件指哪、导出哪些命令、依赖哪些模块 |
| 版本子目录（如 `1.2.3/`） | 同一模块多版本并存时按版本分目录（PSResourceGet 安装的默认形态） |

现在只需要建立两个印象：**清单（.psd1）是模块的"说明书+合同"**——引擎读它来决定加载什么、你读它来了解依赖（`RequiredModules` 字段会自动连带加载依赖）；**`.psm1` 与 `.dll` 只是"命令用哪种语言写"的实现差异，用起来毫无区别**。第 27 章你会亲手做一个完整的模块目录。

顺带一个有用的自省命令：`(Get-Module 模块名).ExportedCommands`——列出某模块实际导出的命令表；它也解释了 `Get-Command -Module` 的数据来源。

## 7.9 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| 模块装了，另一个引擎里找不到 | 两个引擎的 PSModulePath 不同，装进了单侧目录 | 给目标引擎安装；或把模块目录放进两边共享的路径 |
| `Install-Module` 提示 NuGet provider 需要安装 | PowerShellGet v2 首跑引导 | 按提示确认安装（或改用 7.4+ 的 `Install-PSResource`） |
| 提示"无法解析别名/找不到命令"但模块明明在 | 模块不完整或清单损坏 | `Import-Module 模块名 -Verbose` 看加载过程报错 |
| 同名命令行为和文档不一致 | 被后加载模块的同名命令遮蔽 | `Get-Command 命令名 | Select-Object Name, Module, Version` 验明正身 |
| 启动明显变慢 | profile 里 Import 一堆不常用模块 | 精简 profile，依赖自动加载 |
| `PSModulePath` 按 `;` 切分只得到 1 项 | 分隔符是**平台相关**的：Windows `;`、macOS/Linux `:`，写死等于没切 | 用 `[System.IO.Path]::PathSeparator` + `-split [regex]::Escape(...)` |

第四条对策里的 `Get-Command 命令名`（不带通配符）能显示命令的**真实来源模块与版本**——"这命令到底是谁家的"一查便知，排错时极常用。

**动手实验**：① `Get-Module -ListAvailable | Measure-Object` 数数本机模块数；② 把 `$env:PSModulePath` 按分号切开，找到两个引擎各自的模块目录差异；③ 用五步法探索一个陌生模块（建议 `help *scheduled*` → TaskScheduler 相关）；④ 找出三个带名词前缀的命令（如 `Get-AD*`、`*-Sql*`、`*-Dns*`）；⑤ `Find-Module -Tag regex` 体验搜索（不安装）；⑥ 按 7.8 的方法解剖一个已安装模块，找到它的清单文件并用 `Get-Content` 看几行。

实验参考：②两台列表中 `Documents\WindowsPowerShell\Modules`（5.1）与 `Documents\PowerShell\Modules`（7）互不重叠；③`help *scheduled*` 会命中 `ScheduledTasks` 模块的 `Get-ScheduledTask` 等；④`Get-ADUser`（ActiveDirectory）、`Invoke-SqlCmd`（SqlServer）、`Get-DnsClientCache`（DnsClient）都是现成例子；⑥`.psd1` 开头几行是 `@{ ModuleVersion = ... Author = ... }` 的哈希表字面量——第 20 章会认识这个语法。

## 7.10 延伸：模块之外还有三种"命令来源"

把"命令从哪来"的全景补完整，避免模块概念过度泛化：

| 来源 | 例 | 特征 |
|---|---|---|
| 模块 | `Microsoft.PowerShell.Utility` | 现代标准，自动发现/自动加载 |
| snapin（历史） | `SqlServerCmdletSnapin100` | 需注册；`Get-PSSnapin -Registered` |
| 自动加载的内置函数 | `mkdir`、`help`、`cd` | 引擎自带，`Get-ChildItem Function:` 可见 |
| 外部程序 | `whoami.exe` | PATH 查找，第 04 章优先级 |

四类来源在 `Get-Command` 的 `CommandType` 列里各归各位（Cmdlet/Function/Application）。排错口诀"命令查三代"：`Get-Command 名字 -All | Select-Object Name, CommandType, Source`——一条命令看清它是什么、从哪来、有没有被遮蔽。

再看一眼这张表里的第三行会有新收获：`mkdir`、`help`、`cd` 这些"像内建关键字"的东西其实是**引擎启动时预定义的函数**——它们就是 PowerShell 给自己的"官方示例"：用函数封装命令、把常用操作做成人话。第 24 章你写第一个函数时，写的正是这类东西。

---

本篇（二 对象与管道）其余各章：[06 管道](./06-pipeline-first.md) · [08 对象](./08-objects.md) · [09 深入管道](./09-pipeline-deep.md) · [10 格式化](./10-formatting.md) · [11 过滤](./11-filtering.md) · [12 学以致用](./12-integration.md)

---

本篇（二 对象与管道）其余各章：[06 管道](./06-pipeline-first.md) · [08 对象](./08-objects.md) · [09 深入管道](./09-pipeline-deep.md) · [10 格式化](./10-formatting.md) · [11 过滤](./11-filtering.md) · [12 学以致用](./12-integration.md)


补充阅读：本章所有断言都可以在本教程示例库 examples/07_modules_usage/ 里双引擎复现。

---

本篇导航：[06 管道](./06-pipeline-first.md) · [08 对象](./08-objects.md) · [09 深入管道](./09-pipeline-deep.md) · [10 格式化](./10-formatting.md) · [11 过滤](./11-filtering.md) · [12 学以致用](./12-integration.md)
