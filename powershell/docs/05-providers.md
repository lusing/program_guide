# 05 提供程序——一切数据存储皆驱动器

> 本章对应原书第 5 章"使用提供程序"。原书坦言这是全书较难的部分之一，突破口是把最熟悉的**文件系统**当模板：你已经会 `dir` 和 `cd`，本章让你用同一套动作操作注册表、环境变量、变量、函数、证书。

## 5.1 提供程序是什么：把存储"装"成驱动器

**提供程序（PSProvider）本质是一个适配器**：它把某种数据存储（文件系统、注册表、环境变量……）包装成**硬盘驱动器**的样子，让你能用一套统一的命令去遍历和修改。看看当前 Shell 里有哪些：

```powershell
Get-PSProvider
```

输出三列值得逐一理解：

| 列 | 含义 |
|---|---|
| `Name` | 提供程序名：`FileSystem`、`Registry`、`Environment`、`Variable`、`Function`、`Alias`（启用远程处理后还会多出 `WSMan`——第 13 章的伏笔） |
| `Capabilities` | 能力清单：`ShouldProcess`（支持 `-WhatIf/-Confirm`）、`Filter`（支持 `-Filter`）、`Credentials`（支持备用凭据）、`Transactions`（支持事务） |
| `Drives` | 该提供程序当前挂出的**PSDrive** |

**能力列是本章的关键线索**：命令是通用的，但提供程序不一定都接得住。后面会看到 `Get-ItemProperty` 在 `Env:` 上直接报"提供程序不支持 IPropertyCmdletProvider 接口"——那不是你写错了，是 Environment 提供程序没实现属性接口。遇到"命令存在却不能用"，先想提供程序能力差异。

**PSDrive** 是"某提供程序连接到某存储"的实例。`Get-PSDrive` 列出当前全部驱动器：`C:`、`D:`（FileSystem），`HKLM:`、`HKCU:`（Registry），`Env:`、`Variable:`、`Function:`、`Alias:`……注意后几个**不是磁盘**——PSDrive 的"盘符"世界里，注册表和变量表与 C 盘平起平坐。这就是本章标题的含义：一切数据存储皆驱动器。

## 5.2 Item 命令家族：统一的数据操作词汇

操作 PSDrive 里内容的命令，名词里都带 **Item**：

```powershell
Get-Command -Noun *Item*
```

清单很长，但动词全是老朋友（`Get/Set/New/Remove/Copy/Move/Rename/Clear/Invoke`），名词只有三种：

| 名词 | 对应文件系统里的 | 举例 |
|---|---|---|
| `Item` | 一个文件或文件夹（**项**） | `Get-Item`、`New-Item`、`Move-Item` |
| `ItemProperty` | 项的**属性**（大小、只读、最后写入时间；注册表"键值"） | `Get-ItemProperty`、`New-ItemProperty`、`Set-ItemProperty` |
| `ChildItem` | 项里的**子项**（文件夹里的内容） | `Get-ChildItem` |

PowerShell 有意用"项"这个中性词而不用"文件/文件夹"——因为 `Env:\PSModulePath` 不是文件、`HKCU:\Software` 也不是文件夹，但它们都是"项"。学会 Item 三兄弟，等于学会了所有数据存储的 CRUD 词汇。

还有两个常用的配套命令：`Set-Location`（换当前目录，别名 `cd`——它是函数，历史彩蛋见 5.5 节）和 `Get-PSDrive`/`New-PSDrive`/`Remove-PSDrive`（管理驱动器本身）。

## 5.3 文件系统是模板：注册表长成文件夹的样子

Windows 注册表的结构与文件系统同构：**键 = 文件夹，键值 = 文件**。`HKCU:\Software\Microsoft\Windows` 用 `Get-ChildItem` 展开的体验和 `C:\Windows` 完全一致——同样的命令、同样的对象输出，只是底层换了个提供程序。这种"结构相似性到此为止"：再往下钻，各存储的**属性**（ItemProperty）差异很大，命令的可用性也随提供程序能力变化。

用注册表做个巡游（只读操作，放心执行）：

```powershell
Set-Location HKCU:
Get-ChildItem
Set-Location Software
Get-ChildItem Microsoft
```

你会在注册表里看到熟悉的"目录列表"式输出：`Name` 是子键，`Property` 列直接把键值摘要显示出来。想读某个键的具体值：

```powershell
Get-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer'
```

输出的对象里每个键值都是一个属性（`PSPath`、`PSParentPath` 等几个 `PS` 开头的是 PowerShell 附加的元数据属性，真实键值混在其中）。**注册表从此不需要 regedit**——而且命令行的注册表操作可以被管道、被自动化，regedit 不能。

## 5.4 通用命令撞上不支持的能力

项命令是"全存储通用"的，但这不等于处处可用。两个例子：

**Env: 没有属性接口。** 环境变量提供程序只实现了最基础的项接口：

```powershell
Get-ItemProperty -Path Env:\PSModulePath
```

得到红字：`此提供程序不支持 IPropertyCmdletProvider 接口`。正确姿势是**把环境变量当"项"而不是"属性"**：`Get-Item Env:\PSModulePath`（`.Value` 就是值），或者更常用的快通道 `$env:PSModulePath`（5.6 节）。

**FileSystem 没有事务。** 能力表里 FileSystem 不带 `Transactions`，所以文件系统命令不支持 `-UseTransaction` 参数。看到能力表的意义就在这里：**写脚本前看一眼目标存储的能力，能省掉一半的意外**。

## 5.5 New-Item 与类型：为什么 mkdir 更省心

新建一个目录：

```powershell
New-Item -Name testFolder -Type Directory
```

如果漏了 `-Type Directory`，Shell 会反问你 `Type:`——因为 `New-Item` 是全存储通用的，它不知道你要建文件夹还是文件还是注册表键，必须告知类型。（被问住了 Ctrl+C 退出。）

`mkdir` 就省心：`mkdir test2` 不问类型。**`mkdir` 不是 `New-Item` 的别名，而是一个函数**——内部替你隐式补上了 `-Type Directory`。这个细节值得记：它解释了"为什么有的命令像 cmd 一样好用"——那是有人（微软）写的**函数**在贴心，而函数你自己也能写（第 24 章）。

## 5.6 常用提供程序速览

**环境变量 `Env:`**——两套访问方式：

```powershell
Get-ChildItem Env:                    # 列出全部（按项遍历）
$env:PATH                             # 快通道：任何环境变量都是 $env:名字
$env:PSTUTORIAL = 'hello'             # 创建/修改
Remove-Item Env:\PSTUTORIAL           # 删除
```

`$env:` 语法是如此方便，以至于日常几乎只用它。注意：**子进程里改 `$env:` 只影响当前会话及子进程**，关掉窗口就没了——想永久生效要么写注册表（`[Environment]::SetEnvironmentVariable('名','值','User')`），要么去系统设置里点。

**变量 `Variable:`**——Shell 里的变量也挂在驱动器上：

```powershell
Get-ChildItem Variable:
Get-Item Variable:\PSVersionTable
```

调试价值极大：想看当前会话都存了什么状态，`dir Variable:` 一目了然（自动变量 `$PID`、`$HOST`、错误记录 `$Error` 都在里面，第 26 章会用）。

**函数 `Function:`**——函数也是项：

```powershell
Get-ChildItem Function:
Get-Item Function:\mkdir              # 看到 mkdir 的真身：函数定义
```

**别名 `Alias:`**——同理，别名表可遍历：`Get-ChildItem Alias:` 比 `Get-Alias` 输出略详细。`Function:` 和 `Alias:` 这两个驱动器揭示了 PowerShell 的自省能力：**命令空间本身也是数据**。

**证书 `Certificate:`**——需要证书管理单元时可用（`Get-ChildItem Cert:\CurrentUser\My`），第 30 章谈脚本签名时再见。

## 5.7 通配符与 -LiteralPath

`-Path` 参数默认接受通配符：`*` 匹配零或多个字符、`?` 匹配单个字符，`Get-ChildItem C:\Windows\*.exe` 是老朋友了。但注意一个跨存储的坑：**文件名里不允许出现 `*` 和 `?`，注册表键名里却允许**。当你要找的项名字里真的带 `?`（注册表里存在这种键），`-Path` 会把它当通配符解释——找不到，或者找错。

解药是 `-LiteralPath`：**严格按字面使用，不解释任何通配符**：

```powershell
Get-Item -LiteralPath 'HKLM:\SOFTWARE\SomeKey?'   # 问号是名字的一部分
```

注意 `-LiteralPath` 不能靠位置隐式传入——不写参数名时第一个位置参数永远绑给 `-Path`。**规律：路径里可能有特殊字符（`[]`、`?`、`*`）时，用 `-LiteralPath`；日常列文件用 `-Path` 加通配符。**

## 5.8 New-PSDrive：自己的盘符

现成的盘符不够用时，自己造：

```powershell
New-PSDrive -Name Tut -PSProvider FileSystem -Root 'C:\Some\Deep\Path'
Get-ChildItem Tut:
Remove-PSDrive Tut
```

三件事值得知道：

1. PSDrive 能用**任何提供程序**——给注册表深处建个盘符直达也行（`-PSProvider Registry -Root HKLM:\SOFTWARE\Microsoft`）；
2. FileSystem 型 PSDrive 加 `-Persist` 参数后成为**真实映射网络驱动器**（资源管理器可见、重启仍在）——v3 起新增，这就是 `net use` 的 PowerShell 正解；
3. 不加 `-Persist` 的 PSDrive **只存在于当前会话**——脚本结束就消失，天然自清理，适合做"临时快捷方式"。

## 5.9 过滤三兄弟：-Filter、-Include、通配符

`Get-ChildItem` 挑选内容有三种姿势，范围与性能各不相同，值得一次说清（性能话题第 11 章还会升级成"左过滤原则"）：

| 手段 | 例子 | 特点 |
|---|---|---|
| `-Path` 通配符 | `Get-ChildItem C:\Windows\*.exe` | 按"路径长什么样"筛，最直觉 |
| `-Filter` | `Get-ChildItem C:\Windows -Filter *.exe` | 交给**提供程序**在读取时筛（FileSystem 用文件系统 API），三者中最快、语法最像老式 DOS 通配符 |
| `-Include/-Exclude` | `Get-ChildItem C:\Windows -Include *.exe,*.dll -Recurse` | 引擎层过滤，可给多个模式；但**必须配合 `-Recurse` 或路径以通配符结尾**才生效——这是著名的"参数没反应"坑 |

`-Include` 不生效的场景是新手高频困惑：`Get-ChildItem C:\Windows -Include *.exe` 返回**空**，因为 `-Include` 作用在"被枚举的子项"上，而没加 `-Recurse` 时它拿到的是"目录本身"。两种解法：加 `-Recurse`，或写成 `Get-ChildItem C:\Windows\* -Include *.exe`（路径以 `\*` 结尾，枚举的就是子项了）。

## 5.10 两个实战小案例

把本章工具串起来做两件真实的小事。

**案例一：审计 PATH 里的可疑目录**。环境变量的每个条目都是路径，看看有哪些包含"tmp"：

```powershell
$env:PATH -split ';' | Where-Object { $_ -match 'tmp' }
```

做了什么：`-split ';'` 把一整条 PATH 切成数组（第 20 章的字符串运算符），`Where-Object` 逐条匹配（第 11 章）。不需要提供程序知识——但如果你想把整个环境变量表导出来审计，`Get-ChildItem Env: | Export-Csv env-audit.csv` 就是提供程序的贡献。

**案例二：查一台机器装没装某软件**。多数应用会在"卸载"注册表键下挂号：

```powershell
$uninstall = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
Get-ItemProperty $uninstall | Where-Object DisplayName -like '*PowerShell*' |
    Select-Object DisplayName, DisplayVersion
```

做了什么：通配符路径一次抓出全部子键的属性（每个键值变成对象属性），按 `DisplayName` 模糊匹配后取两列。这个三行命令是 Windows 软件清点的标准解法——**没有提供程序，你就得开 regedit 用眼睛扫**。

## 5.11 本章要点

- 提供程序 = 数据存储 → 驱动器的适配器；`Get-PSProvider` 看清单，**能力列决定哪些命令可用**。
- PSDrive 是"提供程序 + 存储位置"的实例；`Env:`、`Variable:`、`Function:`、`Alias:` 与 C 盘同权。
- Item 三名词（`Item`/`ItemProperty`/`ChildItem`）× 常用动词 = 全存储统一 CRUD 词汇；"项"是中性词。
- 注册表 = 键当文件夹、键值当文件；`Get-ItemProperty` 读值；`Env:` 不支持属性接口（当"项"访问或用 `$env:`）。
- `New-Item` 必须给 `-Type`；`mkdir` 是替你补参数的**函数**。
- 路径含 `*?[ ]` 时用 `-LiteralPath`（不能隐式传）；`New-PSDrive` 造临时盘符，FileSystem 型加 `-Persist` 成真盘。

`-Include` 不生效的场景是新手高频困惑：`Get-ChildItem C:\Windows -Include *.exe` 返回**空**，因为 `-Include` 作用在"被枚举的子项"上，而没加 `-Recurse` 时它拿到的是"目录本身"。两种解法：加 `-Recurse`，或写成 `Get-ChildItem C:\Windows\* -Include *.exe`（路径以 `\*` 结尾，枚举的就是子项了）。

三者的选择口诀：**性能敏感且模式简单 → `-Filter`；多模式组合 → `-Include`（记得配 `-Recurse` 或 `\*`）；顺手写一个 → 路径通配符**。

**动手实验**：① `Get-PSProvider` 数数几个提供程序，看 FileSystem 有哪些能力、Registry 缺哪个；② 巡游 `HKCU:\Software\Microsoft`，找出 `Windows` 键下有几个子键；③ `$env:PSTUTORIAL='x'` 后用 `Get-Item Env:\PSTUTORIAL` 验证两种视角，再删掉；④ `Get-Item Function:\mkdir | Select-Object -ExpandProperty Definition` 看 mkdir 函数的真身；⑤ 用 `New-PSDrive` 给 `HKCU:\Software` 建个盘符，`cd` 进去转一圈再删除；⑥ 亲手复现 `-Include` 之坑：在一个装了几个文件的目录里分别跑带 `-Include` 与带 `\*` 的两种写法，对比结果。

对应示例（可选）：`examples/05_providers/`——注册表 HKCU 临时键的建/写/读/删闭环、`Env:` 两种访问、自造 PSDrive 的建用拆，全程自演自净。

---

本篇（一 壳与命令）其余各章：[01 心智模型](./01-why-powershell.md) · [02 初识](./02-meet-powershell.md) · [03 帮助系统](./03-help-system.md) · [04 运行命令](./04-running-commands.md)
