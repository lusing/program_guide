# 17 安全警报——执行策略与信任模型

> 本章对应原书第 17 章"安全警报"。PowerShell 越强大，"它会不会成为风险"就越值得正面回答。本章讲清 PowerShell 的安全设计原则、执行策略的正确理解（**它不是安全边界**）、文件来源标记，以及管理员真正该做的防护。

> **平台提示**：本章三项机制在 macOS/Linux 上**都不存在**——执行策略（Unix 上恒 `Unrestricted` 且任何作用域都不可设）、NTFS 备用数据流（`Zone.Identifier` / MOTW 依赖文件系统，APFS 没有）、Authenticode 签名（`Get-AuthenticodeSignature` 是 Windows-only cmdlet）。示例按能力探测走 SKIP（标记 `[platform]`）。


## 17.0 开篇：先把三个流行疑问答掉

安全话题流行偏见多，开篇先答三个最常被问的（依据都是 17.1 的三条原则）：

**"新闻里说攻击者用 PowerShell，是不是它不安全？"**
攻击者爱用它的原因恰恰是它**对管理员太好用**：在已有权限的机器上，用 Shell 做任何事都高效——包括心怀不轨的人在已攻陷的机器上。防线从来不是"禁用 Shell"（既禁不干净——`powershell.exe -ExecutionPolicy Bypass` 旁路无数——又捆住了自己的手脚），而是**权限最小化 + 日志审计**（17.5 节）。

**"执行策略设成 AllSigned 是不是就安全了？"**
执行策略只管"脚本文件要不要手续"，不管交互命令、不管 `-Command` 字符串、不管被其他程序加载的引擎。它是防误触层的一环，不是防火墙（17.2 节官方澄清）。

**"我可以删掉 powershell.exe 吗？"**
技术上删不掉（系统组件保护），实践上不该（大量系统功能依赖）。正确姿势是应用控制（WDAC/AppLocker）按角色限定"谁可以用什么能力"。

带着这三个答案读本章，你会更专注于"机制怎么用"而不是"要不要怕"。

## 17.1 三条设计原则

PowerShell 的安全模型建立在三条朴素原则上，理解它们能回答 90% 的"PowerShell 安全吗"疑问：

1. **不提权**：PowerShell 不会给你超出当前用户的任何权限——GUI 里干不了的事，Shell 里同样干不了；
2. **不绕权**：脚本不会继承你的权限之外的权力。给用户部署脚本 ≠ 给用户管理员权限；脚本只能做"用户本来就能做的事"；
3. **防误触，不防故意**：安全机制的设计目标是**阻止用户被欺骗运行不明脚本**，不是阻止一个铁了心要在自己机器上跑代码的人。

第三条常被误解。执行策略、文件来源标记都是"防误触"层——它们提高"双击/复制粘贴运行来路不明代码"的门槛，但用户真想跑，条条大路（改策略、Bypass 参数、直接敲命令）都拦不住。**用行政手段防故意（权限最小化、审计），用技术手段防误触**——两层各司其职。

## 17.2 执行策略：它管什么、不管什么

执行策略（Execution Policy）回答一个问题：**运行脚本文件前要什么手续**。注意它**只管脚本文件**——交互式敲命令、命令行 `-Command` 参数都不受影响（这也是"它不是安全边界"的第一层原因：想干坏事的人可以不用文件）。

六个策略值：

| 值 | 含义 |
|---|---|
| `Restricted` | 不允许任何脚本（**Windows 客户端默认**；交互命令照常） |
| `RemoteSigned` | 本地脚本随便跑；**下载来的脚本必须有数字签名**（域环境推荐档） |
| `AllSigned` | 所有脚本都要签名（含你自己写的） |
| `Unrestricted` | 都能跑，但下载来的会提示确认 |
| `Bypass` | 都能跑且不提示（自动化/CI 用） |
| `Undefined` | 该作用域未设置（向上回落） |

**作用域与优先级**——执行策略不是"一个值"而是六层叠放，优先级从高到低：

```
组策略(MachinePolicy) > 组策略(UserPolicy) > Process > CurrentUser > LocalMachine > (内置默认)
```

查全部作用域的当前值：

```powershell
Get-ExecutionPolicy -List
```

只看"最终生效值"用 `Get-ExecutionPolicy`（不带参数，返回优先级决议的结果）。组策略层一旦设置，用户层改什么都没用（企业管控的正当用法）；反过来，**`-Scope Process` 只影响当前进程**，关窗口即失效——这是"临时放开跑一次"的安全姿势，也是本教程示例采用的方式。

改策略的标准操作：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser   # 持久（写注册表，不动系统层）
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process             # 本进程临时
```

**官方澄清值得原文级转述**：微软文档明确说执行策略**不是安全系统**——它是防止用户无意运行脚本的选择开关。真正的防线是：Windows 的权限体系（谁能干什么）、文件来源标记（下一节）、应用控制（AppLocker/WDAC）、日志与审计（17.4 节）。

## 17.3 文件来源标记：MOTW 与 Zone.Identifier

"下载来的脚本"是怎么被认出来的？Windows 在下载文件时会写入一条 **Mark of the Web（MOTW）**——具体形态是 NTFS 的**备用数据流**（Alternate Data Stream，ADS）`Zone.Identifier`，内容标记来源区域（3 = Internet）。

亲手看一眼（只读操作）：

```powershell
Get-Item .\somescript.ps1 -Stream ZoneIdentifier -ErrorAction SilentlyContinue
Get-Content .\somescript.ps1 -Stream ZoneIdentifier
```

`Get-Item -Stream` 把 ADS 当"文件的隐藏分身"列出来（第 05 章项概念的延伸）；无此流说明没有下载标记。`RemoteSigned`/`Unrestricted` 策略正是**读这个流**来判定"是否下载来的"。

解除标记的正规命令：

```powershell
Unblock-File .\somescript.ps1      # 删除 Zone.Identifier 流，文件从此按"本地"对待
```

安全含义：`Unblock-File` 之前**先读一遍文件内容**——标记的存在是系统在提醒你"这东西来路是网络"；确认可信再解除，是"防误触"机制的最后一节车厢。反过来，压缩包解压时 MOTW 会传播给内部文件（新系统对部分格式），而纯文本复制粘贴内容则不带标记——所以"复制代码粘贴到记事本另存"绕过了 MOTW，是好是坏取决于你对来源的判断。

## 17.4 数字签名：验与签

`RemoteSigned`/`AllSigned` 的"Signed"指 **Authenticode 数字签名**（证书链可验证的签名，嵌在文件里）。验证一个脚本有没有签、签得对不对：

```powershell
Get-AuthenticodeSignature .\somescript.ps1 | Format-List Status, StatusMessage, SignerCertificate
```

`Status` 的常见值：`NotSigned`（没签，你自己刚写的都这样）、`Valid`（签名有效）、`HashMismatch`（内容被改过，签名作废——签名是"内容+身份"的封条）。**给自己或团队签脚本**需要代码签名证书（企业内部 CA 或购买），用 `Set-AuthenticodeSignature` 签——这属于工具分发话题，第 30 章谈"用别人的脚本"时再回到验签这一侧。

## 17.5 管理员真正该做的：日志与审计

"防故意"层的三件套（概念级了解，落地查专门文档）：

- **脚本块日志**（Script Block Logging）：组策略开启后，执行过的代码块内容进事件日志（`Microsoft-Windows-PowerShell/Operational` 4104 事件）——攻防两侧都重视的透明化机制；
- **转录**（`Start-Transcript`，第 29 章）：会话全程录成文本文件，配合 profile/组策略可全员开启；
- **AMSI**（反恶意软件扫描接口）：脚本执行前把内容交给杀毒引擎过目——这就是"混淆脚本能被识别"的底层机制之一。

应用控制（AppLocker/WDAC）是比执行策略强硬得多的手段（直接限定"什么代码能跑"），企业环境的正经答案。个人环境记住三条即可：**别用管理员账户日常操作**、**下载的脚本先看再跑**、**`-Scope Process` 是你的临时放行通道**。

## 17.5.1 企业加固清单（管理员视角）

把"防误触 + 防故意"两层落地成一张可执行的清单（按投入产出排序）：

| 措施 | 层 | 动作 |
|---|---|---|
| 日常账户非管理员 | 防故意 | 用户用标准账户；提权走单独的管理账户/UAC |
| 脚本块日志 | 防故意 | GPO：管理模板→Windows 组件→PowerShell→"打开 PowerShell 脚本块日志记录" |
| 转录 | 两者 | GPO 开启转录或 profile 里 `Start-Transcript`（第 29 章命令细节） |
| 执行策略 RemoteSigned | 防误触 | GPO 或 `Set-ExecutionPolicy -Scope LocalMachine` |
| AppLocker/WDAC | 防故意 | 按角色限定可执行代码范围（超出本教程，企业必做项） |
| AMSI | 防故意 | 默认开启（Windows 10+），保持杀软与系统更新即可 |

这张表的灵魂是：**执行策略只占一行**——它有用，但只是整个体系的六分之一。把安全押在单一开关上，是本章最想纠正的认知。

## 17.5.2 转录实操：给会话装行车记录仪

第 17.5 节的"转录"值得给一段实操（个人机也能用，是企业日志的微缩版）：

```powershell
Start-Transcript -Path C:\Logs\session-$($PID).txt -IncludeInvocationHeader
# …… 干活：所有输入与输出被完整记录 ……
Stop-Transcript
```

转录文件记录"这个会话里发生过什么"：命令、输出、时间戳，格式是带头的纯文本。三个实用细节：文件名带 `$PID` 避免多会话互相覆盖；`Start-Transcript` 已在转录中会拒绝重开（先 Stop 或 `-Append` 追加）；**转录与脚本块日志互补**——转录记"会话的壳"，脚本块日志记"引擎执行的代码块"，审计时两边对照。放进 profile（第 02 章）可实现"每次开 Shell 自动记录"——管理员给自己的操作留痕，是安全习惯里性价比最高的一条。

## 17.6 双引擎差异

| | Windows PowerShell 5.1 | PowerShell 7+ |
|---|---|---|
| Windows 客户端默认 | `Restricted` | `Restricted`（MSI 安装时可选；微软刻意保守） |
| Linux/macOS | ——（不存在） | **无执行策略概念**（`Unrestricted`，仅作占位） |
| `Set-ExecutionPolicy` | 全作用域可用 | Windows 上可用；非 Windows 报"不支持" |

跨平台脚本别依赖执行策略做任何逻辑判断——它在非 Windows 上是"不存在的存在"。

## 17.7 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| "无法加载脚本，未对此系统启用脚本执行" | 执行策略 Restricted（默认）挡了 .ps1 | `-Scope Process` 临时放行或 `CurrentUser` 持久设 `RemoteSigned` |
| 改了 CurrentUser 却不生效 | 组策略层更高优先级压着 | `Get-ExecutionPolicy -List` 看六层，找最高的非 Undefined 层 |
| 签了名还说 HashMismatch | 签名后文件被改（哪怕一行） | 内容定稿后再签；分发用签名包 |
| Unblock 后策略还是挡 | 签名要求（AllSigned）与 MOTW 是两回事 | AllSigned 下必须真签名 |
| CI 里跑脚本被策略卡 | 默认策略随环境 | 启动参数 `-ExecutionPolicy Bypass`（进程级，最干净的自动化姿势） |
| ADS 操作报错 | 目标文件系统不支持流（FAT32/exFAT） | MOTW 依赖 NTFS；移动文件时标记可能丢失 |
| "策略明明是 RemoteSigned 还是挡我" | 文件带 MOTW 且未签名 | `Unblock-File`（确认内容可信后）或签名 |
| `Set-ExecutionPolicy` 抛 "Operation is not supported on this platform" | 执行策略是 **Windows 专属机制**，Unix 上恒 `Unrestricted` 且任何作用域都不可设 | try/catch 后按"生效值是否真变成 Bypass"分支，否则 SKIP `[platform]` |

再补一个高频追问：**"从网络共享（UNC 路径）运行的脚本算下载来的吗？"**——UNC 路径运行通常被视为"远程位置"（RemoteSigned 下要求签名），这是文件服务器上放脚本的团队最常踩的一条。规避方式有三：签名（正解）、把脚本分发到本地再跑、或对内网文件服务器场景评估后用 GPO 设 `Bypass`（不推荐作为长期方案）。判断"我这份文件为什么被挡"的通用口诀：`Get-ExecutionPolicy -List` 看策略层，`Get-Item 文件 -Stream *` 看来源标记，两查定位 90% 的策略问题。

## 17.8 本章要点

- 三原则：**不提权、不绕权、防误触不防故意**——技术防误触，行政防故意。
- 执行策略**只管脚本文件**、**不是安全边界**；六值六作用域、优先级链、`-List` 看全景、`-Scope Process` 是安全临时通道。
- MOTW：NTFS ADS `Zone.Identifier`；`Get-Item -Stream` 查看、`Unblock-File` 解除（先读后解）。
- `Get-AuthenticodeSignature` 验签（NotSigned/Valid/HashMismatch）。
- 防故意层：脚本块日志、转录、AMSI、AppLocker；执行策略在非 Windows 上不存在。

**动手实验**：① `Get-ExecutionPolicy -List` 读六层，找出你机器上最高非 Undefined 层；② `Set-ExecutionPolicy Bypass -Scope Process` 后 `Get-ExecutionPolicy` 验证生效（开新窗口即还原）；③ 建一个临时 .ps1，`Get-AuthenticodeSignature` 看 `NotSigned`；④ 给它手写一条 `Zone.Identifier` 流（`Set-Content -Stream`），再 `Get-Content -Stream` 读回、`Unblock-File` 清除，全流程体验 MOTW；⑤ 把 ③ 的脚本在策略 `Restricted` 下试着跑一次，读那条著名错误。

实验参考：①多数个人机最高层是 `LocalMachine`（Restricted 或由用户改过的值），组策略两层是 Undefined；④写流时两行内容（`[ZoneTransfer]` 与 `ZoneId=3`）都要给，`Unblock-File` 之后用 `Get-Item -Stream` 复查为空；⑤错误文本里明确写着"有关详细信息，请参阅 about_Execution_Policies"——**错误信息指路的帮助主题**，这本身就是第 03 章"帮助即文档"的又一次兑现。

一张"策略速决卡"收尾（被人问"我该设什么策略"时照抄）：

| 你是谁 | 建议 |
|---|---|
| 个人开发机 | `RemoteSigned`（CurrentUser 作用域） |
| 团队服务器 | `RemoteSigned`（GPO 统一） |
| CI/自动化 | 启动参数 `-ExecutionPolicy Bypass`（不动系统设置） |
| 高管控环境 | `AllSigned` + 代码签名流程 + 应用控制 |

对应示例（可选）：`examples/17_security/`——作用域清单断言、Process 级放行与还原、ADS 写读删闭环、签名状态 `NotSigned` 断言（全部自演自净，不动系统层设置）。

---

本篇（三 远程与批量）其余各章：[13 远程处理](./13-remoting.md) · [14 CIM](./14-cim.md) · [15 后台作业](./15-jobs.md) · [16 多对象](./16-multiple-objects.md) · [18 会话](./18-sessions.md) · [19 高级远程](./19-advanced-remoting.md)

---

本篇（三 远程与批量）导航：[13 远程处理](./13-remoting.md) · [14 CIM](./14-cim.md) · [15 后台作业](./15-jobs.md) · [16 多对象](./16-multiple-objects.md) · [17 安全](./17-security.md) · [18 会话](./18-sessions.md) · [19 高级远程](./19-advanced-remoting.md)

本章示例只动 Process 作用域与临时文件 ADS，关闭进程即自清理；执行策略速决卡可直接抄给团队。
