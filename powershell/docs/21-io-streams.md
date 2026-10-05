# 21 输入与输出——六条流和它们的方向盘

> 本章对应原书第 19 章"输入和输出"。前面所有输出的呈现都交给默认机制；本章把"输出"拆开看清楚——你的信息走的是哪条流、会被谁过滤、怎么点亮/关闭它们，以及"问用户要输入"的正确姿势。

先立一个使用前提（原书开篇就强调的）：**交互技术（提示、问答）只对"有人值守"的场景有意义**。无人值守的脚本（计划任务、CI）里没有"人"来回答 `Read-Host`，一切交互设计都会变成挂死——自动化脚本的输入应该来自**参数**（第 23 章）。本章教的是"与人对话"的一半，下一章之后的重点转向"与机器对话"。

## 21.1 宿主决定交互的样子

第 02 章说过：引擎不画界面，宿主负责。这条规则在输入输出上最直观——同一个 `Read-Host`，在控制台宿主里是**命令行提示**，在老 ISE 里可能弹**图形对话框**，在某些第三方宿主里又会写到独立窗格。所以"这命令在我这长得不一样"的第一嫌疑永远是宿主差异（第 02 章 2.7 节的三步诊断同样适用）。

## 21.2 问用户要输入：Read-Host

```powershell
$computername = Read-Host 'Enter a computer name'
```

运行后提示用户输入，**用户敲的内容作为命令结果返回**（进管道，所以能赋值给变量）。三个细节：提示文本会自动补一个冒号；用户输入的永远是**字符串**（要数字自己转型：`[int](Read-Host '端口号')`）；密码输入用 `-AsSecureString`——按键显示为星号、返回 `SecureString` 对象（安全形态的字符串，不能直接读明文，给 `-Credential` 体系用）。

需要**图形输入框**（给不习惯命令行的用户部署脚本）时，借 .NET 的 Visual Basic 组件：

```powershell
Add-Type -AssemblyName Microsoft.VisualBasic
$computername = [Microsoft.VisualBasic.Interaction]::InputBox('Enter a computer name', 'Computer Name', 'localhost')
```

`Add-Type` 载入程序集（原书用的是更老的 `LoadWithPartialName`，现代写法是上面这句），然后 `::` 调用静态方法（第 08 章）。三个参数依次是提示、窗口标题、默认值。照抄即用，不必深究 VB 的家谱——它是"借 .NET 车库"的又一例。

**边界提醒**：`-NonInteractive` 模式下（自动化场景的标准启动参数）`Read-Host` 会**直接报错**——这是设计而非故障。本教程示例就是在这个模式下跑的，示例里专门演示了这个报错。

## 21.3 两个 Write 的分野：管道 vs 直写

`Write-Host` 与 `Write-Output` 是本章最重要的一组对照，原书用两幅图讲透了，文字版如下。

**`Write-Output`：把对象放进管道**。它其实是你天天在用的东西——**裸写任何表达式/字符串，引擎默认就是 `Write-Output`**（`'Hello'` 等价于 `Write-Output 'Hello'`）。既然进管道，就服从管道的一切规则：

```powershell
Write-Output 'Hello' | Where-Object { $_.Length -gt 10 }
# 无输出！'Hello' 在管道里被 Where 筛掉了，到不了屏幕
```

**`Write-Host`：直写显示界面**（技术上 v5+ 起它写入第 6 条信息流并即刻呈现）：

```powershell
Write-Host 'Hello' | Where-Object { $_.Length -gt 10 }
# 屏幕上照样 Hello —— 它压根没进"输出"管道
```

结论与选型：**要"数据"（可能被后续命令消费、可能被导出）→ `Write-Output`（或干脆裸输出）；要"给操作者看的进度说明"（状态、分隔线、颜色提示）→ `Write-Host` 或更规范的 `Write-Verbose`/`Write-Information`**。把两类混用（该进管道的用 Write-Host 写屏幕）是脚本数据链断裂的头号原因。

## 21.4 六条流：输出的完整地图

PowerShell 的"输出"其实有**六条并行的流**，各走各的通道：

| 流号 | 名字 | 写入命令 | 默认去向 |
|---|---|---|---|
| 1 | 输出（成功） | `Write-Output`（默认） | 屏幕（可管道、可重定向） |
| 2 | 错误 | `Write-Error`、命令报错 | 红字到屏幕 |
| 3 | 警告 | `Write-Warning` | 黄字带"警告:"前缀 |
| 4 | 详细 | `Write-Verbose` | **默认关闭** |
| 5 | 调试 | `Write-Debug` | **默认关闭**（还带确认暂停） |
| 6 | 信息 | `Write-Information`、`Write-Host` | 默认继续（5.0+） |

**重定向语法**——把一条流并入另一条（编号加 `>&1`）：

```powershell
& { Write-Warning '小心' } 3>&1            # 警告并入输出流（能捕获了）
& { Write-Error '坏了' } 2>&1 | ForEach-Object { "$_" }   # 错误对象并入输出
command *> all.log                          # 全部六条流进一个文件
```

这套语法是**收集"非输出流"进变量**的唯一入口：想在脚本里判断"有没有产生警告"，就 `3>&1` 收进来数。

**方向盘：偏好变量**。3/4/5 号流各有一个总开关（ preference 变量），决定对应 Write 命令"写不写得出"：

| 变量 | 默认 | 效果 |
|---|---|---|
| `$WarningPreference` | `Continue` | 警告正常显示 |
| `$VerbosePreference` | `SilentlyContinue` | **详细流默认沉默** |
| `$DebugPreference` | `SilentlyContinue` | 调试流默认沉默 |
| `$ErrorActionPreference` | `Continue` | 错误继续执行（第 26 章主角） |

点亮方式两种：全局拧开关（`$VerbosePreference = 'Continue'`，作用域内有效），或**单命令点亮**（`Get-Service -Verbose`——通用参数 `-Verbose`/`-Debug` 只作用于这一条命令，第 03 章的伏笔兑现）。设计意图：**详细流是命令内置的"工作过程自白"，平时安静、要时即开**——第 07 章五步法里"跑完没动静就 `-Verbose` 问一句"的机制就是它。

补一位编外成员：`Write-Progress`（进度条）——独立的呈现机制（不属于六流），长循环里给用户"还在跑"的安心感，`help Write-Progress` 有现成模板。

## 21.4.1 Write 家族参数速查

各 Write 命令的常用参数一表备查（都在 `help` 里有，这里挑高频的）：

| 命令 | 常用参数 | 用途 |
|---|---|---|
| `Write-Host` | `-ForegroundColor`/`-BackgroundColor`（红绿黄……）、`-NoNewline` | 状态着色（红=失败绿=成功）、同行拼接 |
| `Write-Warning` | 无特殊参数 | 黄字+前缀，宿主渲染 |
| `Write-Verbose` | 无特殊参数 | 过程说明，随 `-Verbose` 点亮 |
| `Write-Error` | `-Message`、`-Category`、`-TargetObject`（错误对象附带目标，排错金矿，26 章） | 产生非终止错误 |
| `Write-Information` | `-MessageData`、`-Tags`（给信息打标签，宿主可筛选） | 结构化信息流（比 Write-Host 正规的"给宿主的话"） |
| `Write-Progress` | `-Activity`/`-Status`/`-PercentComplete`/`-Completed` | 进度条（长循环必备） |

着色的提醒：`Write-Host -ForegroundColor Green '成功'` 在日志重定向后颜色信息丢失（文件里没有颜色）——**颜色只该做冗余强调，不做唯一区分**（无色环境读起来也该成立）。

## 21.4.2 丢弃输出的三种姿势

反向需求"我只要副作用不要输出"也有三种写法，顺路认清：

```powershell
$result = New-Item -Path x -Force | Out-Null    # 一：管道到 Out-Null
[void](New-Item -Path x -Force)                 # 二：强转 void（原书在载入程序集时用过）
$null = New-Item -Path x -Force                 # 三：赋给 $null（最快，且不吃管道）
```

三种都合法；`$null =` 少一层管道开销，脚本里更常见。真正要避免的是第四种"什么都不做"——输出裸奔进管道可能意外混进函数返回值（第 24 章"函数输出一切"的伏笔）。**丢弃要显式**，是脚本卫生的一部分。

## 21.5 Tee-Object 与输出复制

想把数据**一边落盘一边继续走管道**：`Tee-Object`（三通管）：

```powershell
Get-Service | Tee-Object -FilePath services.txt | Where-Object Status -eq 'Running'
```

文件里是全量快照、管道里继续筛——"留档 + 继续加工"一步到位。调试时它还有个妙用：在长管道中间插一段 `Tee-Object` 把中间结果存下来，看数据流到这一步长什么样（比断点轻量）。

## 21.6 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| `Write-Host` 的内容导不出来 | 直写屏幕不进管道（数据链断裂） | 数据用 `Write-Output`/裸输出 |
| `Write-Verbose` 没输出 | `$VerbosePreference` 默认沉默 | 命令加 `-Verbose` 或全局拧开 |
| 自动化里脚本半夜卡住 | `Read-Host` 等一个不存在的人 | 无人值守改参数输入（23 章）；`-NonInteractive` 让它当场报错而不是挂死 |
| 想捕获警告/错误进变量失败 | 默认各走各的流 | `3>&1`/`2>&1` 并流后再捕获 |
| `-Debug` 一条条弹确认 | `Write-Debug` 默认带 Inquire 行为 | 批量场景设 `$DebugPreference='Continue'` 免确认 |
| `Write-Host` 在老脚本里被骂 | v1-v4 它绕过一切流 | 5.0+ 已并入第 6 流，可 `6>&1` 捕获；新代码仍优先 Write-Information |

## 21.6.1 流重定向编号速记与两问

重定向编号背不下来时用这张三行卡：

```
成功流是 1（可省略：> file 即 1>）
其他流按"2 错 3 警 4 详 5 调 6 信"顺口溜
N>&1 = 把 N 号流并进成功流（之后就能存变量/继续管道）；*> = 全收
```

两问收尾：

**问：`2>&1` 时错误对象和普通输出混在一起，类型不统一怎么办？**
混流后数组里既有数据对象又有 ErrorRecord——`Where-Object { $_ -is [System.Management.Automation.ErrorRecord] }` 可以把错误单独滤出来（`-is` 判型，第 11 章）。要彻底分流就别并流：错误用 `-ErrorVariable` 旁路收集（26 章），输出走 1 号流，各干各的。

**问：宿主里看不到 Write-Information 的输出？**
5.0+ 的控制台宿主默认渲染信息流，但**部分宿主/重定向下不显示**——`Write-Information` 的定位是"给宿主程序消费的结构化消息"（带 `-Tags`），给"人"看的场合 `Write-Host`/`Write-Verbose` 更直接。两个命令的分工：Information 面向程序、Host 面向屏幕。

## 21.7 本章要点

- 交互看宿主：同一命令不同宿主不同脸；`-AsSecureString` 收密码。
- **`Write-Output` 进管道（默认输出），`Write-Host` 直写屏幕**——数据与解说分流，别混。
- 六条流编号 + `N>&1` 重定向语法；偏好变量是总开关，`-Verbose`/`-Debug` 是单命令开关。
- `Write-Verbose` 是"过程自白"，默认安静、按需点亮——工具作者（25 章）必须给足verbose。
- `Tee-Object` 三通：落档 + 继续管道。
- 无人值守 = 参数输入，不用 Read-Host。

## 21.5.1 一条命令把六条流全看一遍

把本章知识拼成一个"全流演示脚本"（可以抄进 .ps1 跑，也可以逐行交互执行）：

```powershell
& {
    Write-Output   '①输出流——数据本体'
    Write-Warning  '③警告流——黄字提醒'
    Write-Verbose  '④详细流——过程自白' -Verbose
    Write-Error    '②错误流——非终止错误'
    Write-Host     '⑥信息流——给操作者的画外音' -ForegroundColor Cyan
} *> all-streams.log
Get-Content all-streams.log
```

`*>` 把六条流**按序收进同一个文件**——文件里能看到每条流的渲染形态（红黄前缀、颜色丢失为纯文本）。再做一次对照：把 `*>` 换成 `3>&1 4>&1 2>&1 6>&1 | Out-File mixed.log`，内容相同但**顺序可能不同**（并流后各流交错）。排错时"日志里顺序怎么乱了"的答案就在这：并流不改内容、只汇通道，交错是并行写入的自然结果。

这个演示也是理解第 26 章（错误处理）的绝佳铺垫——错误流与输出流的关系，那里会从"捕获"升级到"处置"。

**动手实验**：① 复现 21.3 的两条管道对照（筛掉 vs 照显）；② `& { Write-Warning '小心' } 3>&1` 存进变量并断言拿到；③ `Write-Verbose 'v'`（无输出）与 `Write-Verbose 'v' -Verbose`（有输出）对比，再用 `$VerbosePreference='Continue'` 全局点亮后恢复；④ `[int](Read-Host '数字')` 交互试一次；⑤ `Get-Service | Tee-Object t.txt | Measure-Object` 验证双通道；⑥ 在 `-NonInteractive` 的子进程里跑 `Read-Host` 看报错（`pwsh -NonInteractive -Command 'Read-Host x'`）；⑦ 跑一遍 21.5.1 的全流演示。

实验参考：②捕获到的是**WarningRecord 对象**（`gm` 验证），`"$x"` 后带"警告:"前缀；⑥报错是"无法提示……宿主未实现或非交互"一类——把这条错误长相记住，CI 排错时一眼可辨。

对应示例（可选）：`examples/21_io_streams/`——Write-Output/Write-Host 管道分野、3/4 号流并流捕获、偏好变量开关对照、Tee 双通道、NonInteractive 下 Read-Host 的报错捕获。

---

本篇（四 语言核心）其余各章：[20 变量](./20-variables.md) · [22 第一个脚本](./22-first-script.md) · [23 参数化](./23-parameterized.md)

---

本篇（四 语言核心）导航：[20 变量](./20-variables.md) · [21 输入输出](./21-io-streams.md) · [22 第一个脚本](./22-first-script.md) · [23 参数化](./23-parameterized.md)

本章配套示例的每条断言都对应正文一节，可对照阅读。

三种丢弃姿势（Out-Null/[void]/$null=）与全流演示脚本在示例里都有对应断言。
