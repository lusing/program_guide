# 02 初识 PowerShell——宿主、版本与环境

> 本章对应原书第 2 章"初识 PowerShell"，并把其中关于 ISE 与控制台配置的内容更新到 Windows Terminal 与 PowerShell 7 时代。

打开 PowerShell 的方式不止一种，选错"入口"会平白遇到一堆怪问题（乱码、32 位陷阱、没有管理员权限）。本章把"你面对的到底是什么"讲清楚：**你看到的窗口不是 PowerShell 本身**，版本号怎么查、怎么看，以及如何把输入环境调教顺手。

## 2.1 宿主：窗口不是 Shell

第一个要建立的概念是**宿主（host）**。PowerShell 引擎（负责解析命令、跑管道的那套东西）是一个类库，它自己不画窗口。你用的 `pwsh.exe`、`powershell.exe`、VS Code 里的集成终端、ISE——都只是"宿主"：负责把你的键盘输入递给引擎、把引擎的输出画到屏幕上的外壳程序。

原书对此有个精辟的说法：那个蓝色（现在是黑色）的控制台窗口可以追溯到 1985 年的古老设计，不要指望它本身给你流畅的体验——它不是 PowerShell。这个认知在排错时很关键：**同一个 PowerShell 版本在不同宿主里表现可能不同**。比如乱码问题：控制台窗口受系统代码页影响，而 VS Code 的集成终端默认 UTF-8；再比如 PSReadLine（下面会讲）在交互式控制台自动加载，但被 `-NonInteractive` 方式调起的引擎里就没有。

现代 Windows 上的宿主选择如下：

| 宿主 | 说明 | 适用 |
|---|---|---|
| Windows Terminal + pwsh | Windows 11 内置的终端程序，多标签、好字体、真彩色 | **日常首选** |
| VS Code + PowerShell 扩展 | 编辑器即宿主，断点调试、语法提示 | 写脚本时首选 |
| 裸控制台 `pwsh.exe` | 轻量、零依赖，服务器上永远可用 | 远程/服务器环境 |
| ISE | 随 5.1 出厂的图形化脚本环境，**已停止演进，不支持 PowerShell 7** | 仅维护老 5.1 脚本时 |

原书花了大量篇幅教读者配置老式控制台（字体、缓冲区宽度、不要出现水平滚动条）。这些忠告的精神在 Windows Terminal 时代依然成立：**保证你能区分 `'`（撇号）和 `` ` ``（重音符）**——这两个字符在 PowerShell 里含义完全不同（字符串定界 vs 转义符），字体糊一点就是事故源；**保证窗口宽度足够、输出不被水平滚动条藏起来**——原书讲过有学生盯着空输出找了半小时，其实结果全在右边藏着。Windows Terminal 里这些都在"设置"里调整，改一次全局生效。

## 2.2 两个引擎、四个入口的历史

原书写作时（第 3 版，2017 年），开始菜单里最多能找到四个 PowerShell 图标：64 位控制台、32 位控制台（x86）、64 位 ISE、32 位 ISE。今天的局面简化成了两条线：

- **`powershell.exe`（Windows PowerShell 5.1）**：Windows 出厂自带，只有 64 位和 32 位两个变体；
- **`pwsh.exe`（PowerShell 7+）**：手动安装，只提供 64 位版本（从 7 起不再发布 32 位 Windows 版）。

**32 位陷阱**仍然值得知道：64 位 Windows 上，32 位进程看到的是被"文件系统重定向"处理过的世界——`C:\Windows\System32` 会被重定向到 `SysWOW64`。后果是 32 位 PowerShell 里访问注册表 `HKLM:\SOFTWARE` 看到的也是 32 位视图，某些只注册了 64 位 COM 组件的命令在 32 位宿主里会找不到。判断办法很简单：看窗口标题或进程路径有没有 `x86`/`SysWOW64` 字样。今天的实践中基本没有理由再用 32 位 PowerShell，认得这个坑就行。

另一个原书强调的要点：**需要动系统时以管理员身份运行**。窗口标题带"管理员"才是提权会话；普通会话里跑 `Enable-PSRemoting` 之类的命令会直接吃权限错误。日常查询类操作则不需要提权——养成"默认普通权限、按需提权"的习惯比一律提权安全。

## 2.3 查版本：$PSVersionTable

每代 PowerShell 都装在名字叫 `v1.0` 的目录里（`$PSHOME` 看一眼就知道，5.1 至今路径都是 `...\WindowsPowerShell\v1.0`）——这是为了保持 COM 接口兼容的历史决定，所以**不能靠目录名判断版本**。权威答案是：

```powershell
$PSVersionTable
```

输出是一张键值表，每一行都值得认识：

| 键 | 含义 | 备注 |
|---|---|---|
| `PSVersion` | PowerShell 自身版本 | 日常说的"版本"指它 |
| `PSEdition` | `Desktop`（5.1）或 `Core`（7+） | **区分两个引擎的最快办法** |
| `OS` | 操作系统描述 | 仅 7+ 有；5.1 没有这一行 |
| `GitCommitId` | 开源仓库的提交号 | 7+ 有 |
| `CLRVersion` / `FrameworkVersion` | 底层 .NET 版本 | 5.1 显示 .NET Framework 的 CLR；7+ 无此项，改看 `RuntimeVersion` |
| `PSCompatibleVersions` | 兼容的语言版本集合 | |
| `WSManStackVersion`、`PSRemotingProtocolVersion` | 远程处理协议栈版本 | 第 13 章会再见到它们 |

两个引擎并存的机器上，想写"跨版本都成立"的判断，用 `PSEdition`：

```powershell
if ($PSVersionTable.PSEdition -eq 'Core') { 'PowerShell 7+' } else { 'Windows PowerShell 5.1' }
```

这段代码做的事：从版本表里取 `PSEdition` 属性（引擎在启动时自动生成这个只读哈希表），与字符串 `'Core'` 比较相等。`-eq` 是 PowerShell 的相等运算符（第 11 章系统讲）。7+ 恒为 `Core`，5.1 恒为 `Desktop`——比比对版本号数字更稳。

还有一个历史细节：`powershell.exe -Version 2.0` 可以显式拉起 v2 引擎（用于极老的兼容场景），但 v2 引擎需要在 Windows 功能里单独安装，现代系统默认没有。知道有这回事即可。

## 2.4 输入辅助：PSReadLine 与四种 Tab 补全

命令行是打字密集的界面，打错一个空格、一对引号都可能让命令变味。PowerShell 的对策有两层。

**第一层是 Tab 补全**，覆盖四种场景（下面每条都可以现在就试）：

1. **命令名**：输入 `Get-Ser` 按 Tab，循环补全所有 `Get-Ser*` 命令；Shift+Tab 反向循环；
2. **路径**：输入 `Get-ChildItem` 空格 `C:\Win` 按 Tab，循环补全该前缀下的文件/目录名；
3. **参数名**：输入 `Set-Execu` Tab 补全出 `Set-ExecutionPolicy`，输入 `-` 再 Tab，循环列出该命令全部参数；输入 `-Sc` 再 Tab 则只匹配 `Sc` 开头的参数；
4. **参数的合法值**：对枚举型参数（如 `Set-ExecutionPolicy -ExecutionPolicy` 后面按 Tab），循环列出全部合法值。

**第二层是 PSReadLine**——现代 PowerShell 的交互体验担当。它由引擎在交互式控制台自动加载，提供：上下键历史（跨会话持久化，默认存 4096 条）、`Ctrl+R` 历史反向搜索、语法着色（命令/参数/字符串/变量不同色，打错括号立刻变色）、以及**预测式 IntelliSense**（根据你的历史边打边弹灰色建议，右方向键采纳）。开启预测：

```powershell
Set-PSReadLineOption -PredictionSource History
```

这行命令把 PSReadLine 的预测来源设为"命令历史"。想让它每次启动都生效，把这行写进 profile（下一节）。

PSReadLine 值得背下来的快捷键（用 `Get-PSReadLineKeyHandler` 查看全部）：

| 按键 | 作用 |
|---|---|
| `↑` / `↓` | 历史上下翻 |
| `Ctrl+R` | 历史反向搜索（再按继续往前找） |
| `Tab` / `Shift+Tab` | 补全 / 反向补全 |
| `→`（有灰色建议时） | 采纳整条预测 |
| `Ctrl+空格`（或菜单键） | 弹出补全菜单 |
| `Alt+.` | 把上一条命令的**最后一个参数**取到当前命令（复用长路径神器） |
| `Esc` | 清空当前输入行 |

5.1（Windows 10 及以后）也内置 PSReadLine，但版本旧、没有预测功能——这属于"7+ 的体验优势"，不影响脚本兼容性，因为 PSReadLine 只管交互输入，与脚本执行无关。顺带一提，ISE 的智能提示（IntelliSense 弹出菜单）在当年是它相对控制台的核心优势，如今 VS Code 的 PowerShell 扩展把这个体验带给了 7+。

## 2.5 Profile：每次启动都执行的脚本

PowerShell 启动时会在特定位置找 profile 脚本，找到就先执行它——相当于 Shell 的"开机自启动"。看你的 profile 路径：

```powershell
$PROFILE
```

`$PROFILE` 默认显示的是**当前用户、当前宿主**的 profile 路径，Windows 上形如 `...\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`（7+）或 `...\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`（5.1）——两个引擎各有各的 profile，互不通用，这是双版本并存时容易被忽略的一点。

实际上 `$PROFILE` 是一个"一物四址"的对象，对应四个作用域，用 `$PROFILE | Select-Object *Host*` 能看全：

| 作用域 | 文件 | 谁会执行 |
|---|---|---|
| 所有用户、所有宿主 | `profile.ps1` | 任何引擎、任何宿主启动都跑 |
| 所有用户、当前宿主 | `Microsoft.PowerShell_profile.ps1` | 该宿主启动都跑 |
| 当前用户、所有宿主 | `profile.ps1` | 该用户任何宿主 |
| 当前用户、当前宿主 | `Microsoft.PowerShell_profile.ps1` | **最常用** |

实践建议：个人的别名、PSReadLine 选项、提示符定制放"当前用户、当前宿主"（即 `$PROFILE` 默认指的那个）；团队统一定制才动"所有用户"那两个。profile 文件默认不存在，直接 `New-Item -Force $PROFILE` 创建即可。

一个必须知道的坑：`$PROFILE` 是字符串，但**放在双引号里会展开成路径，放在单引号里就是字面量 `$PROFILE` 七个字符**——这是第 20 章引号规则的预告。以及：profile 出错不会阻止 Shell 启动，但会打印一片红色错误；排查时用 `pwsh -NoProfile` 启动一个干净会话对比，是标准诊断动作（本教程的构建脚本也是用 `-NoProfile` 跑示例的，就是为了隔绝每个人 profile 的差异）。

## 2.6 常用自动变量速览

Shell 里有一些"生来就有值"的**自动变量**（只读或由引擎维护），本章阶段先认六个最常用的，后面各章随用随补（完整清单：`Get-Help about_Automatic_Variables`）：

| 变量 | 含义 | 典型用途 |
|---|---|---|
| `$PID` | 当前 PowerShell 进程号 | 精确操作"自己"这个进程 |
| `$PWD` | 当前目录（PathInfo 对象） | 脚本里取当前路径 |
| `$HOME` | 用户主目录 | 拼路径 |
| `$null` | 空值 | 判空（第 20 章的判空方向陷阱） |
| `$true` / `$false` | 布尔字面量 | 条件判断 |
| `$IsWindows` / `$IsLinux` / `$IsMacOS` | 平台开关（**仅 7+ 有**，5.1 未定义） | 跨平台脚本分支 |

最后一个值得多说一句：5.1 里 `$IsWindows` **不存在**（未定义变量在默认模式下求值为 `$null`），判断平台得用 `$env:OS -eq 'Windows_NT'` 之类——这是"同一脚本跑两个引擎"时的经典分岔点，本教程示例库里有专门演示。

## 2.7 三个立即可用的诊断动作

把本章知识收束成三个动作，它们能解决"我这和你那不一样"的大多数现场：

1. **看身份**：`$PSVersionTable`——先确认引擎与版本，再谈行为；
2. **开干净会话**：`pwsh -NoProfile`——排除 profile（别名、函数、选项）的干扰，脚本自动化环境一律这么起；
3. **换宿主**：同一命令在控制台、VS Code、Windows Terminal 里各跑一遍——能复现的是命令问题，不能复现的是宿主问题（编码、字体、交互组件）。

## 2.8 本章要点

- 你看到的窗口是**宿主**，不是 PowerShell 引擎；宿主差异（代码页、PSReadLine 加载与否）能解释一大类"我这怎么不行"。
- 两引擎并存：`pwsh`（7+，`PSEdition = Core`）与 `powershell`（5.1，`Desktop`）；`$PSVersionTable` 是权威版本答案，目录名不是。
- Tab 补全四场景（命令/路径/参数/枚举值）+ PSReadLine（历史/着色/预测）是输入效率的两大支柱；预测用 `Set-PSReadLineOption -PredictionSource History` 开启。
- Profile 四作用域，两个引擎互不通用；`-NoProfile` 是隔离环境差异的诊断与测试手段。
- 32 位宿主的文件系统重定向坑认得即可；需要动系统时才提权。

动手验证一遍自动变量（每行都该有输出，读一读输出说明什么）：

```powershell
$PID          # 输出一个数字——当前进程号；开着任务管理器能对上号
$PWD          # 输出 PathInfo 对象，Path 属性就是当前目录
$HOME         # 你的用户目录
$null -eq $x  # True——$x 从未定义过；判空要把 $null 放左边（第 20 章细讲为什么）
$IsWindows    # 7+ 输出 True；5.1 里输出空白（变量不存在）
```

最后一行的行为差异请务必亲手在两个引擎里各跑一次——"5.1 里 `$IsWindows` 是空白"这件事，比任何文档描述都更能让你记住"两引擎并存"不是理论问题。

## 2.8 双引擎对照速查

收束成一张随时可查的对照表（后续各章的差异点都会汇聚到 CHEATSheet，这张是入口）：

| 场景 | PowerShell 7+ | Windows PowerShell 5.1 |
|---|---|---|
| 启动 | `pwsh` | `powershell` |
| 身份字段 | `PSEdition = Core`，含 `OS` 行 | `PSEdition = Desktop`，无 `OS` 行 |
| profile 目录 | `Documents\PowerShell\` | `Documents\WindowsPowerShell\` |
| 用户模块目录 | `Documents\PowerShell\Modules\` | `Documents\WindowsPowerShell\Modules\` |
| `Update-Help` | 默认 CurrentUser，免提权 | 默认 AllUsers，需管理员 |
| 平台开关变量 | `$IsWindows` 等已定义 | 未定义（求值为空） |
| 老命令 | 无 `Get-WmiObject`（用 CIM，第 14 章） | 有 |
| 默认文件编码 | UTF-8（无 BOM） | ANSI/UTF-16（第 17 章专题） |

## 2.9 启动参数速查

从命令行（或任务计划、CI 脚本）拉起引擎时，几个开关决定引擎的"脾气"。本教程的验证器就是用它们跑示例的，理解它们你也能写出同样干净的自动化调用：

| 参数 | 作用 | 什么时候用 |
|---|---|---|
| `-NoProfile` | 跳过所有 profile | 自动化/测试必加——隔离个人环境差异 |
| `-NonInteractive` | 不弹任何交互提示（缺参数直接报错而非询问） | 无人值守场景（否则脚本会在半夜卡在"请输入值："上） |
| `-ExecutionPolicy Bypass` | 本次进程放开执行策略（第 17 章专题） | 跑别人机器上的脚本、CI 环境 |
| `-File 路径 [参数]` | 执行脚本文件并传参（退出码=脚本的 exit） | 正道：比 `-Command` 少一层引号转义地狱 |
| `-Command "命令串"` | 执行一段命令文本 | 交互便利；引号嵌套时优先改用 `-File` |
| `-WorkingDirectory 路径` | 指定启动目录（7.4+ 新增，5.1 无） | 免去脚本里自己 `Set-Location` |

一个直接的记忆锚点：**`-File` 传参是数组式的（每个参数独立），`-Command` 是字符串式的（整串重解析）**——前者不会因为参数里有空格或引号而被二次解释。这正是不久前真实踩过的坑：给 `cmd /c` 之类拼 `-Command` 长串时，内嵌引号会被引擎重新转义，而 `-File` 从根上避开了这个问题。

**动手实验**：① 运行 `$PSVersionTable`，记下 `PSVersion` 和 `PSEdition`；② 输入 `Get-ChildItem -` 后按 Tab 十次，观察参数循环；③ `Test-Path $PROFILE` 看你是否已有 profile，没有则创建一个，写入 `Set-PSReadLineOption -PredictionSource History`，重开终端体验预测补全；④ `pwsh -NoProfile` 启动干净会话，确认预测没生效（profile 被跳过了）；⑤ 把自动变量验证块在两个引擎里各跑一遍，记下 `$IsWindows` 的两种表现。

对应示例（可选）：`examples/02_meet_powershell/`——断言版本表结构、宿主身份、profile 路径与 PSReadLine 可用性，全程不依赖具体版本号。

> **下一章预告**：环境就绪后，第 03 章教整个教程里"最值钱的一个习惯"——用帮助系统自己回答"这个命令怎么用"。

---

本篇（一 壳与命令）其余各章：[01 心智模型](./01-why-powershell.md) · [03 帮助系统](./03-help-system.md) · [04 运行命令](./04-running-commands.md) · [05 提供程序](./05-providers.md)
