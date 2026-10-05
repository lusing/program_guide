# 13 远程处理——一对一与一对多

> 本章对应原书第 13 章"远程处理：一对一及一对多"。远程处理（Remoting）是 PowerShell 最强大的企业级能力：**在远程机器上运行任何命令**——哪怕那台机器上你一个管理工具都没装。本章讲清机制、两种使用形态（交互式 1:1 与扇出 1:N），以及"为什么结果对象是快照"。

原书从一个小失望讲起：`Get-Service` 有 `-ComputerName` 参数能查别的机器，但大部分命令没有——因为微软没打算给每个命令都塞一份远程代码。他们做的是**把远程能力建在 Shell 层**：任何命令都能被送到远程机器的 PowerShell 里执行。这就是 Remoting。

## 13.0 全景：远程命令的三种形态

本章会碰到的所有远程用法，其实只有三种形态。先立总表，后文各节展开：

| 形态 | 命令 | 连接生命周期 | 状态 | 适用 |
|---|---|---|---|---|
| 一次性扇出 | `Invoke-Command -ComputerName …` | 每命令一次握手 | 无 | 单发查询、批量巡检 |
| 交互式 | `Enter-PSSession` | 连接持续到你退出 | 有（你在里面） | 探索一台机器 |
| 持久会话 | `New-PSSession` + `-Session` | 显式建、显式拆 | 有（跨命令） | 多步任务、高频调用（第 18 章） |

一个术语速查（本章的"单词表"，遇到混用回来查）：

- **WS-MAN**：协议标准（Web Services for Management），走 HTTP(S)；
- **WinRM**：微软对 WS-MAN 的实现（Windows 后台服务，也就是你要"启用"的那个东西）；
- **侦听器**（listener）：WinRM 在端口上等连接的组件；
- **端点/会话配置**：连进来之后落到的"PowerShell 入口"（可以有很多个）；
- **PSSession**：建立起来的一条持久连接（第 18 章主角）。

## 13.1 机制解剖：WS-MAN、WinRM 与端点

PowerShell 远程处理基于 **WS-MAN**（Web Services for Management）协议——完全走 HTTP(S)，所以能穿防火墙（只要相应端口放行）。微软对 WS-MAN 的实现是 **WinRM**（Windows Remote Management）后台服务，Windows Vista 以后内置、Server 系统默认启用、客户端系统默认禁用。

三个构件的关系（原书图 13.1 的文字版）：

```
客户端 PowerShell ──HTTP 5985──▶ WinRM 侦听器 ──▶ 端点（会话配置）──▶ 一个 PowerShell 实例
                                    （等网络进来）   （可有一批）        （可限制权限/命令集）
```

- **侦听器**：像 Web 服务器一样等在端口上（默认 5985=HTTP、5986=HTTPS），只认**计算机名**不认 IP/别名（默认 Kerberos 认证的要求）；
- **端点**（会话配置，session configuration）：WinRM 背后的一组"PowerShell 入口"。一台机器可以有很多端点——不同端点可以指向不同版本的 PowerShell、甚至限制只暴露少数命令（第 19 章展开）。

把这一切打开的命令（**需要管理员权限**）：

```powershell
Enable-PSRemoting
```

它一口气做五件事：启动 WinRM 服务、设为自动启动、注册默认端点、创建防火墙例外、（必要时）重启服务。原书特别警告的常见失败：**网卡网络类型是"公用"** 时防火墙例外建不了——把网络改成"专用"再跑（连着公共 WiFi 时别改）。域环境用组策略批量启用（`about_Remote_Troubleshooting` 里有现成指引）。

**本教程不执行这条命令**——示例章用探针检测本机 WinRM 是否可用，不可用则带理由跳过（正文所讲机制不受影响；你在自己的实验机上可以启用后体验）。

## 13.2 一对一：Enter-PSSession

最接近"远程桌面"的形态，但只占一个命令行的资源：

```powershell
Enter-PSSession -ComputerName Server-R2
[Server-R2]: PS C:\>
```

提示符前缀 `[Server-R2]:` 是**你正在别的机器上**的信号——之后敲的每条命令都在远程执行，导入模块、跑脚本皆可。`Exit-PSSession`（无参）退出；直接关窗口也没事，WinRM 会自己收摊。三个值得知道的细节：

1. **凭据随行**：Kerberos 认证带着你的安全令牌过去（用户名密码不网上明文走），权限与本地登录一致；
2. **远程的 profile 不加载**、远程机器的执行策略生效——你连过去的世界按它的规矩来；
3. **不要远程链**（在 `[Server-R2]:` 里再 `Enter-PSSession` 别的机器）：链路难追踪、开销翻倍，跨防火墙中转是唯一正当理由（第 19 章的"第二跳"话题）。

一组真实会话长什么样（命令行实录，体会提示符的变化）：

```
PS C:\Users\you> Enter-PSSession -ComputerName localhost
[localhost]: PS C:\Users\you> $PSVersionTable.PSVersion
Major  Minor  Build  Revision
-----  -----  -----  --------
5      1      …      …          ← 连的是默认端点（5.1）
[localhost]: PS C:\Users\you> hostname
localhost
[localhost]: PS C:\Users\you> Exit-PSSession
PS C:\Users\you>                  ← 回到本机，前缀消失
```

三个观察点：进了远程后 `hostname` 说的是远程的名字（你真的在那）；`$PSVersionTable` 显示的是**远程**的版本（判断"连到哪个 PowerShell"的最快办法，比猜端点可靠）；`Exit-PSSession` 后前缀消失，一切如常。交互式远程不适合自动化（要人在场），但**探索陌生机器**（看装了什么模块、什么版本、什么配置）时它是效率之王。

## 13.3 一对多：Invoke-Command

本章的主角，原书称之为"PowerShell 最酷的功能之一"：

```powershell
Invoke-Command -ComputerName Server-R2, Server-DC4, Server12 -ScriptBlock {
    Get-EventLog Security -Newest 200 | Where-Object { $_.EventID -eq 1212 }
}
```

发生了什么：`-ScriptBlock`（帮助里查 `-Command` 是查不到的——那是它的**参数别名**，第 03/09 章的知识点在这里兑现）里的整段命令被**原样发送到三台机器**，各自在对方的 PowerShell 里执行，结果汇总传回你的屏幕。这是真正的**分布式扇出**：每台机器独立干活，回来的只有结果。

规模控制：默认 `-ThrottleLimit 32`——同时最多 32 台并发，超出的排队等位（网络好可以调大）。机器清单的喂法正好复习第 09 章：

```powershell
Invoke-Command -ScriptBlock { dir } -ComputerName (Get-Content WebServers.txt)   # 文本文件，圆括号先执行
Invoke-Command -ScriptBlock { dir } -ComputerName (Get-ADComputer -Filter * |
    Select-Object -ExpandProperty Name)    # 对象先开盒再喂（第 09 章）
```

复杂任务不必塞进脚本块：`-FilePath .\task.ps1` 把**整个本地脚本文件**下发执行（参数还能用 `-ArgumentList` 传）——"脚本只在我机器上有，但要在 500 台机器上跑"的标准解。

`Invoke-Command` 常用参数收一张表（扇出的控制面板）：

| 参数 | 作用 | 默认/示例 |
|---|---|---|
| `-ScriptBlock`（别名 -Command） | 远程执行的代码块 | `{ Get-Service }` |
| `-FilePath` | 远程执行的本地脚本 | `-FilePath .\collect.ps1` |
| `-ComputerName` | 目标清单（逗号/变量/括号表达式） | `localhost, s2` |
| `-ConfigurationName` | 连哪个端点（选版本） | `PowerShell.7` |
| `-Credential` | 备用凭据 | `(Get-Credential 域\用户)` |
| `-ThrottleLimit` | 并发上限 | 32 |
| `-AsJob` | 转后台作业（第 15 章） | 开关 |
| `-Session` | 复用持久会话（第 18 章） | `$s` |

最后两项各开一扇门：机器多、耗时长的扇出转成后台作业先干活；反复对同一批机器发命令则用持久会话省去反复握手——分别是 15/18 章的剧情。

## 13.4 回来的对象是"快照"：序列化

远程结果有个必知特性：网络上传的不是活对象，而是**序列化再反序列化**的快照（XML 表示）。 practical 后果：

- 结果对象的**属性齐全**，可以继续筛、排、导出；
- 但**方法大都没有了**——`Invoke-Command ... { Get-Process -Name notepad }` 拿回的进程对象不能直接 `.Kill()`（快照没有这条命）；
- 引擎给结果**自动贴上 `PSComputerName` 属性**——多机结果混在一起时，靠它分辨"这条来自谁"，这也是远程命令输出的标志性列。

要"对远程对象做事"，正确姿势是把**动作写进脚本块**（在远程执行）：`Invoke-Command ... { Get-Process notepad | Stop-Process }`——杀进程的动作发生在那台机器上，本地只收到结果。一句话原则：**数据可以回来，动作必须过去**。

序列化的边界值得多看两眼（排错时能救命）：

- **类型名会"带标记"**：远程回来的对象 `Get-Member` 看 TypeName，常见 `Deserialized.System.Diagnostics.Process` 这样的前缀——看到 `Deserialized` 就知道手里是快照；
- **静态成员仍然可用**：实例方法没了，但 `[math]::Round` 这类**类型级**调用在本地照常（它们不依赖具体实例）；
- **字符串/数字/日期等简单属性原样保留**——99% 的"筛、排、选、导出"工作流完全不受影响，受影响的只是"对快照调实例方法"这一件事；
- **深度有限制**：嵌套对象序列化到一定深度（`$SerializationDepth` 相关，默认够用）会截断成类型名——极深对象结构传输后"变浅"属正常。

把这条特性与前一章衔接：`Invoke-Command` 的输出接 `Where-Object`、`Sort-Object`、`Export-Csv`（都是属性消费者）毫无问题；接 `Stop-Process` 这类 ByValue 吃活对象的命令才会翻车（快照类型不匹配）——第 09 章的绑定判据在这里第二次兑现。

## 13.5 双引擎差异：端点与版本

两引擎并存的机器上，远程处理多了一层"连到哪个 PowerShell"的选择（实测要点）：

- `Enable-PSRemoting` 在 **5.1** 里跑，注册的是 5.1 端点（默认端点 `Microsoft.PowerShell`）；
- 在 **pwsh 7** 里跑 `Enable-PSRemoting`（或 `Enable-PSRemoting -Force`），会额外注册 **PowerShell 7 专用端点**（名如 `PowerShell.7`）；
- 连接时用 `-ConfigurationName` 指定端点：`Invoke-Command -ComputerName s1 -ConfigurationName PowerShell.7 { $PSVersionTable.PSVersion }`——不指定则连到默认端点，多半是 5.1。

另外，**pwsh 7 还支持基于 SSH 的远程处理**（`-HostName` 参数，跨平台、密钥认证），那是第 19 章的主角。WinRM 与 SSH 的取舍表也放在那里。

## 13.5.1 连不上怎么办：诊断五步

远程失败时按固定顺序排查（每步都是只读操作）：

```powershell
# 1. 名字解析通不通
ping SERVER-R2
# 2. 端口通不通（5985 是 WinRM 默认）
Test-NetConnection SERVER-R2 -Port 5985
# 3. 对方 WinRM 活不活（协议层探针）
Test-WSMan SERVER-R2
# 4. 认证/权限（本机身份对不对、是否在端点允许名单）
whoami; Get-LocalGroupMember Administrators   # 或域侧检查
# 5. 端点层（要不要指定 -ConfigurationName）
Invoke-Command -ComputerName SERVER-R2 -ConfigurationName PowerShell.7 { 1 }
```

`Test-NetConnection -Port` 是无 PowerShell 参与的裸 TCP 探测——第 2 步通而第 3 步败，问题在 WinRM 服务或防火墙；第 3 步通而第 5 步败，问题多半在认证或端点选择。这套"从下往上"的排查顺序同样适用于 18/19 章的所有远程变体。

## 13.6 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| `Enter-PSSession` 拒绝连接 | 目标未 Enable-PSRemoting / 网卡是公用网络 / 防火墙 | 逐项排查；`Test-WSMan 目标名` 是连通性探针 |
| 用 IP 地址连不上 | 默认 Kerberos 认证只认计算机名 | 用机器名；非域/IP 场景走 TrustedHosts 或 SSH（19 章） |
| 远程结果调方法报错 | 序列化快照无方法（13.4） | 动作写进脚本块，让动作过去 |
| 多机结果分不清来源 | 混装输出 | 看 `PSComputerName` 列，或 `| Sort-Object PSComputerName` |
| 连上的是 5.1 不是 7 | 默认端点是 5.1 | `-ConfigurationName PowerShell.7` |
| 某机器超时拖慢整批 | 默认排队机制 + 单机故障 | `-ThrottleLimit` 调并发；用 `Invoke-Command -AsJob`（15 章）收晚到的 |

## 13.7 本章要点

- Remoting 是 **Shell 层**的通用远程：WS-MAN/WinRM（HTTP 5985）+ 侦听器 + 端点；`Enable-PSRemoting` 一键开五件事（管理员、公用网卡会挡防火墙例外）。
- **1:1 `Enter-PSSession`**：交互式、`[机器]:` 提示符、凭据随行、远程规矩生效、勿远程链。
- **1:N `Invoke-Command`**：脚本块/`-FilePath` 整脚本下发；`-ThrottleLimit` 并发；清单喂法=第 09 章（括号+开盒）。
- **结果=序列化快照**：属性在、方法无、自带 `PSComputerName`；**数据回来，动作过去**。
- 端点可选版本：默认 5.1，`-ConfigurationName PowerShell.7` 连 7；SSH 远程 19 章见。

**动手实验**（若你的实验机已启用远程处理；未启用则先在虚拟机上 `Enable-PSRemoting`）：① `Test-WSMan localhost` 看探测输出；② `Enter-PSSession localhost` 进去跑 `$PSVersionTable`（看清连的是哪个版本）再退出；③ `Invoke-Command -ComputerName localhost { Get-Process -Name pwsh }` 观察结果里的 `PSComputerName` 列；④ 用 `-ScriptBlock { 1+1 }` 验证表达式也能远程；⑤ 试试 `Invoke-Command -ComputerName localhost -ConfigurationName PowerShell.7 { $PSVersionTable.PSVersion }`（若注册过 7 端点）。

实验参考：①`Test-WSMan` 输出里 `ProductVersions` 一行能看出 WSMan 协议版本；②默认端点显示 5.1 的版本号（`Desktop` edition）——这就是 13.5 说"默认连的是 5.1"的实证；⑤没注册过 7 端点会报"未找到会话配置"——去 pwsh 7 里跑一次 `Enable-PSRemoting -Force` 再试。三个实验合起来正好把"端点=可选的远程 PowerShell 版本"这个概念闭环。

对应示例（可选）：`examples/13_remoting/`——WinRM 探针门控（不通则带理由 SKIP）：`Invoke-Command` 表达式求值、多目标计数、`PSComputerName` 存在性、远程命令族可用性断言（无条件）。

---

本篇（三 远程与批量）其余各章：[14 CIM](./14-cim.md) · [15 后台作业](./15-jobs.md) · [16 多对象](./16-multiple-objects.md) · [17 安全](./17-security.md) · [18 会话](./18-sessions.md) · [19 高级远程](./19-advanced-remoting.md)

---

本篇（三 远程与批量）导航：[13 远程处理](./13-remoting.md) · [14 CIM](./14-cim.md) · [15 后台作业](./15-jobs.md) · [16 多对象](./16-multiple-objects.md) · [17 安全](./17-security.md) · [18 会话](./18-sessions.md) · [19 高级远程](./19-advanced-remoting.md)

本章示例可在 examples/13_remoting 下双引擎复现；探测类断言（WinRM/SSH/模块可用性）按环境自动 SKIP，理由见报告行尾。
