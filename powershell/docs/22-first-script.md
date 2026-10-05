# 22 你把这叫作脚本——从命令行到 .ps1

> 本章对应原书第 21 章"你把这叫作脚本"。原书给恐惧"编程"的管理员的定心丸：**脚本不是编程，是把调通的命令存档**。你已经写了 21 章的"脚本零件"，本章只做一件事——把它们装订成册。

## 22.1 脚本是什么：给计算机的剧本

批处理文件（.bat）你大概写过：一个文本文件，里面一列命令，cmd 按顺序执行。**PowerShell 脚本（.ps1）就是同一件事**：把命令按顺序存进文本文件，Shell 逐行执行。原书的类比是好莱坞剧本——你写给"演员"（计算机）的台词与走位。

"这不是编程"的三个证据：脚本里**每一行都是你已经会在命令行跑的命令**；不需要编译、不需要 main 函数；从命令行到脚本的转换是**复制粘贴**。你已经完成了 21 章的"演员训练"，本章只是开拍。

## 22.2 从命令到脚本：四步工作流

原书用磁盘库存命令贯穿全章（本教程第 12 章的老朋友，正好升级成脚本版）。标准工作流四步：

**第一步：命令行调通。** 在交互 Shell 里把命令写到满意——这是"脚本质量"的上游，命令不通就存档等于存档错误。

```powershell
Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Sort-Object -Property DeviceID |
    Format-Table -Property DeviceID,
        @{ Label = '空闲(GB)'; Expression = { [math]::Round($_.FreeSpace / 1GB, 1) } },
        @{ Label = '总量(GB)'; Expression = { [math]::Round($_.Size / 1GB, 1) } },
        @{ Label = '空闲比';  Expression = { [math]::Round($_.FreeSpace / $_.Size * 100, 0) } }
```

**第二步：装订成册。** 命令复制进 VS Code（原书时代是 ISE，现代替代见第 02 章），保存为 `Get-DiskInventory.ps1`。注意**命名沿用 Verb-Noun 规范**（第 04 章）——脚本是"自制命令"的雏形，从第一个脚本就用命令的标准要求它。

**第三步：格式化。** 上面命令的排版藏着两条纪律（值得原样学走）：**长命令折行时，行尾以 `|` 或 `,` 结尾**（解析器知道没说完，自然续行——比反引号续行干净）；**全名全参数零别名**（脚本是被"读"的，第 04 章纪律）。VS Code 里 F8（运行选中部分）支持**分步测试**：选中第一段跑通，再选中前两段……逐段验证。

**第四步：运行。**

```powershell
.\Get-DiskInventory.ps1
```

**`.\` 前缀是刻意的安全设计**：PowerShell 不像 cmd 那样优先搜当前目录——你必须显式说"运行当前目录下这个脚本"，防止恶意脚本藏在目录里冒名顶替系统命令。写全路径或相对 `.\` 路径都行，就是不能裸敲文件名（除非脚本目录进了 PATH）。

第一次运行大概率撞上**执行策略**（第 17 章）：默认 Restricted 会拒绝。个人机的标准解法之一是临时放行：`pwsh -ExecutionPolicy Bypass -File .\Get-DiskInventory.ps1`，或按 17 章把 CurrentUser 设为 RemoteSigned 一劳永逸。

## 22.3 param()：让脚本接参数

存档的脚本若只能干死一件事，复用性太差。`param()` 块让脚本像命令一样接参数——**必须放在脚本最前面**（注释之外）：

```powershell
param(
    [string]$ComputerName = 'localhost',
    [int]$MinFreePct = 20
)

Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Where-Object { ($_.FreeSpace / $_.Size * 100) -lt $MinFreePct } |
    Select-Object DeviceID, @{ Label = '空闲比'; Expression = { [math]::Round($_.FreeSpace / $_.Size * 100, 0) } }
```

调用方式与任何命令一致：

```powershell
.\Get-DiskInventory.ps1                                    # 用默认值
.\Get-DiskInventory.ps1 -MinFreePct 40                     # 命名参数
.\Get-DiskInventory.ps1 SRV1 30                            # 位置参数（按 param 顺序）
```

`$ComputerName = 'localhost'` 里的 `'localhost'` 是**默认值**——不给就用它。还有个兜底变量 `$args`：没有 `param()` 的脚本里，传入参数全进 `$args` 数组（`$args[0]` 取第一个）。**正式脚本一律用 param()**（类型、默认值、后续第 23 章的验证属性都是它的红利），`$args` 只在两三行的临时脚本里凑合。

## 22.4 两种调用方式：& 与点源

脚本有两种执行方式，差别在**变量的可见性**：

```powershell
& .\sets-var.ps1      # & 调用：脚本在自己的作用域里跑，里面的变量"出不来"
. .\sets-var.ps1      # 点源：脚本在当前作用域跑，变量留在这里
```

`sets-var.ps1` 里若有一句 `$inside = 'hello'`：用 `&` 跑完后 `$inside` **不存在**（随脚本作用域销毁）；用 `.` 跑完后 `$inside` 就是 `'hello'`（写进了当前作用域）。这正是第 02/24 章"函数库要 dot-source 加载"的原理——**`. .\lib.ps1` 把库里的函数定义倒进当前会话**。规则：**跑任务用 `&`（或 `.\` 直跑），加载定义用 `.`**。

## 22.5 退出码与成功标志

脚本的"结局"有两种汇报渠道：

```powershell
exit 42               # 脚本里：进程退出码 42
```

外部世界（计划任务、CI、调用你的另一个脚本）通过 `$LASTEXITCODE` 读它：`.\exit42.ps1; $LASTEXITCODE` → `42`。约定俗成：**0=成功，非 0=失败**（计划任务与 CI 按这个判定）。另一路是 PowerShell 内部的 `$?`（上一次命令"是否成功"的布尔标志）——它跟退出码是两套体系，第 26 章错误处理会看到它们分别该在哪用。省略 `exit` 的脚本自然退出，退出码 0。

## 22.6 #Requires 与脚本头部

```powershell
#Requires -Version 7
#Requires -Modules @{ ModuleName = 'CimCmdlets' }
```

`#Requires` 是**脚本自报家门**的门槛声明：条件不满足时**拒绝运行**（比跑到一半才神秘报错体面得多）。常用三种：`-Version`（引擎版本下限）、`-Modules`（依赖模块）、`-PSEdition`（Core/Desktop——直接解决"这脚本要 7 还是 5.1"）。放在文件任意位置的注释行都有效，习惯放最顶上。

脚本头部三件套（本教程所有示例的模板）：

```powershell
#Requires -Version 5.1
# 示例 NN：一句话说明这个脚本演示什么
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
```

第一行门槛、第二行注释、第三行编码声明（中文 Windows 控制台输出的保险，第 01 章的坑位在此有了正解）。

## 22.6.1 脚本的五种运行方式对照

到本章为止你见过的"让一段代码跑起来"的全部方式，一张表收齐（每种各有主场）：

| 方式 | 写法 | 场景 | 特点 |
|---|---|---|---|
| 相对路径直跑 | `.\task.ps1` | 日常 | 作用域隔离（同 `&`） |
| 调用操作符 | `& $path` / `& $path 参数` | 路径/命令在变量里 | 同上，路径可动态拼 |
| 点源 | `. .\lib.ps1` | 加载函数库 | 定义进当前作用域 |
| 引擎调用 | `pwsh -File task.ps1 参数` | 新进程跑（CI/计划任务） | 全新环境、退出码直通 |
| 选中运行 | VS Code F8 / ISE F8 | 调试 | 只跑选中片段，逐段验证 |

第五种值得多说一句：**F8 分步运行是"脚本界的一键还原"**——把长脚本按空行/管道段选中、逐段 F8，哪段结果不对当场就能定位（配第 08 章的 gm 检查中间对象类型）。这比 print 调试高效得多，是原书 F8 技巧（当时在 ISE 里）在现代 VS Code 里的延续。

## 22.6.2 给脚本装行车记录仪：Start-Transcript

第 17 章介绍过转录的命令形态，放进脚本的固定写法是：

```powershell
# 脚本开头
$log = Join-Path $env:TEMP ("task-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))
Start-Transcript -Path $log | Out-Null
try {
    # …… 脚本主体 ……
}
finally {
    Stop-Transcript | Out-Null
}
```

三个工程细节：文件名带时间戳（`-f` 格式化，第 29 章）避免覆盖历史；`Stop-Transcript` 放 **finally**（第 26 章的语法，保证出错也停转录）；日志路径用 `$env:TEMP`（通用、可写）。转录把脚本的输入输出全录进文本——"昨晚计划任务到底干了什么"从此有据可查，这也正是第 17 章企业清单里"全员转录"条目的单机实现。

## 22.7 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| 裸敲文件名说找不到命令 | 当前目录不在搜索路径（安全设计） | `.\script.ps1` 显式相对路径 |
| 脚本跑不了，红字提执行策略 | Restricted 默认挡 .ps1（17 章） | `-ExecutionPolicy Bypass` 或设 CurrentUser |
| param() 块报语法错 | 不在脚本最前（前面有可执行代码） | param 永远开门第一句 |
| 反引号续行总出毛病 | 行尾多了空格（反引号后不能有任何字符） | 改用 `|`/`,` 结尾续行 |
| 引入库后函数变量串进会话 | 用 `&` 跑了"库"脚本 | 定义用 `.` 点源，任务用 `&` |
| 计划任务说脚本"成功"但没干活 | 脚本没写 exit，出错也返回 0 | 失败路径显式 `exit 非零`（26 章系统化） |
| 脚本在别的机器中文乱码 | 无 BOM 的 UTF-8 被 5.1 按 ANSI 读 | 保存为 **UTF-8 带 BOM**（17 章专题） |

## 22.7.1 新脚本的五个脚手架决定

动手写新脚本前，五问五答把"脚手架"搭对（每问都对应本章某节）：

| 问题 | 默认答案 | 依据 |
|---|---|---|
| 放哪、叫什么 | `Verb-Noun.ps1`，动词查 `Get-Verb` | 22.2 第二步 |
| 要哪些参数？默认值？ | 能给默认就给默认 | 22.3（本章版详见 23 章） |
| 谁调用它？人还是计划任务？ | 人：可留 Read-Host；任务：纯参数 | 21 章交互边界 |
| 出事怎么收场？ | `exit` 非零 + `$LASTEXITCODE` 约定 | 22.5 |
| 需要什么版本/模块？ | `#Requires` 写明，别让人猜 | 22.6 |

第五问最常被跳过、出事时最贵——"这脚本要 7 还是 5.1、要不要 AD 模块"写在门槛上，比写在报错后的排查文档里便宜一百倍。

## 22.8 本章要点

- 脚本=存档的命令序列；四步工作流：**命令行调通 → 存档命名（Verb-Noun）→ 格式化（行尾续行、全名全参）→ `.\` 运行**。
- `.\` 前缀是防劫持设计；执行策略是第一道门。
- `param()` 开门接参数（默认值/位置/命名），`$args` 只是兜底。
- `&` 跑任务（作用域隔离）、`.` 点源加载定义（变量/函数入当前作用域）。
- `exit N` + `$LASTEXITCODE` 对外汇报（0 成功）；`#Requires -Version/-Modules` 门槛前置；头部三件套。

**动手实验**：① 把 22.2 的磁盘命令按四步工作流做成 `Get-DiskInventory.ps1` 并运行；② 给它加 `param([int]$MinFreePct = 20)`，用 `-MinFreePct 90` 调用看告警变化；③ 写 `sets-var.ps1`（内含 `$inside='x'`），分别用 `&` 和 `.` 各跑一次，检验 `$inside` 的存在性；④ 写 `exit 42` 的脚本，跑完读 `$LASTEXITCODE`；⑤ 给脚本加 `#Requires -Version 7`，在 5.1 里跑看拒绝信息；⑥ 故意裸敲 `script.ps1`（无 `.\`）看报错；⑦ 给 ① 的脚本加 22.6.2 的转录壳，跑完去 TEMP 翻日志。

实验参考：②参数改 90 后几乎所有盘都进告警——阈值即参数的复用价值直观呈现；⑤拒绝信息里写明"requires PowerShell version 7.0"，且**发生在任何代码执行之前**——对比"跑一半因版本差异失败"，门槛前置的价值不言自明；⑦日志开头有主机信息、结尾有耗时统计，是免费的可观测性。

## 22.9 下一步预告：脚本之上是函数

本章的 `Get-DiskInventory.ps1` 已经很像一个"命令"了——Verb-Noun 名字、param 参数、可以传参调用。下一步（第 24 章）把它**搬进函数**：名字从文件名变成函数名、`.\` 调用变成直接敲名字、多个函数装进一个库文件（.psm1 模块）随取随用。**脚本与函数的关系是"单个任务 vs 可组合的零件"**——第 33 章的收官项目会把这条进化链走完：命令 → 脚本 → 函数 → 模块 → 工具。

实验参考：③`&` 版后 `Test-Path Variable:inside` 为 False、`.` 版为 True——作用域差异一测就明；⑤5.1 报"requires PowerShell version 7.0"——这是门槛声明在替你挡事故；⑥报错形态即第 04 章"无法识别为 cmdlet"家族。

对应示例（可选）：`examples/22_first_script/`——param 默认值/命名/位置三态调用、`&` 与点源的作用域对照、exit 退出码传递、`#Requires` 门控行为（由辅助脚本 asset-*.ps1 配合完成）。

---

本篇（四 语言核心）其余各章：[20 变量](./20-variables.md) · [21 输入输出](./21-io-streams.md) · [23 参数化](./23-parameterized.md)

---

本篇（四 语言核心）导航：[20 变量](./20-variables.md) · [21 输入输出](./21-io-streams.md) · [22 第一个脚本](./22-first-script.md) · [23 参数化](./23-parameterized.md)

本章配套示例的每条断言都对应正文一节，可对照阅读。

---

本篇（四 语言核心）导航：[20 变量](./20-variables.md) · [21 输入输出](./21-io-streams.md) · [22 第一个脚本](./22-first-script.md) · [23 参数化](./23-parameterized.md)

param 三态、& 与点源、exit 退出码的对照实验在示例 22 逐条复现。
