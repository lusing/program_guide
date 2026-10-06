# 19 高级远程配置——端点、TrustedHosts 与 SSH

> 本章对应原书第 23 章"高级远程控制配置"，并把 pwsh 7 的 **SSH 远程处理**正式收进来。第 13/18 章覆盖了日常 80%～90% 的场景；本章是"剩下的 10%"——但每人迟早都会撞上一次。

> **平台提示**：本章的端点、TrustedHosts、`WSMan:` 驱动器都建立在 **WinRM** 上，那是 Windows 服务。macOS/Linux 上 pwsh 7 把整条 WSMan 腿剔除了——`New-PSSessionOption` 只剩两个 SSL 校验开关，连超时参数都不在参数表里；但 **SSH 腿（`-HostName`）在 Unix 上可用**，那才是非 Windows 平台的远程通道。


原书对本章内容的定位很诚实：不是所有配置都会用到，但**每个人都应该知道这些选项存在**——遇到时知道往哪查。本章所有"动系统"的操作（注册端点、改 TrustedHosts）只讲清步骤与后果，示例一律探针只读。

## 19.1 端点深潜：会话配置

第 13 章说过端点（会话配置）是"WinRM 背后的 PowerShell 入口"。看看一台机器有哪些：

```powershell
Get-PSSessionConfiguration          # 需管理员权限读取（且需 WinRM 服务运行）
```

默认能看到的几行值得逐个认识：

| 端点名 | 是什么 |
|---|---|
| `Microsoft.PowerShell` | **默认端点**：64 位 5.1，`-ConfigurationName` 不指定时连的就是它 |
| `Microsoft.PowerShell32` | 32 位 5.1（64 位系统上成对注册） |
| `Microsoft.PowerShell.Workflow` | 工作流端点（工作流已废弃，认得即可） |
| `PowerShell.7` | 在 pwsh 7 里跑过 `Enable-PSRemoting` 后出现的 7 端点 |

每个端点是一条完整的"入站合同"：**谁能连**（`Permission` 字段，默认管理员与远程管理用户组）、**连上后跑哪个 PowerShell**（PSVersion）、**进来先执行什么**（StartupScript）、**以谁的身份跑**（RunAsUser）。`-ConfigurationName` 选端点（第 13 章 13.5 的版本选择就是它的应用）。

**自定义端点**是高级运维的正经武器（本教程只讲清概念与步骤，不执行）：

```powershell
# 概念示例：注册一个"受限运维端点"（需管理员）
Register-PSSessionConfiguration -Name HelpDesk -StartupScript C:\Scripts\helpdesk-startup.ps1 -RunAsCredential (Get-Credential)
# 之后：Invoke-Command -ComputerName s1 -ConfigurationName HelpDesk { ... }
```

StartupScript 里可以只暴露几 个函数（用 `Set-CommandVisibility`/模块白名单），RunAs 让普通用户以受限服务账号执行特定操作——**给一线人员"能做十件事的按钮"而不是管理员密码**，这是最小权限思想在远程处理上的落地。它的工业级形态叫 **JEA**（Just Enough Administration，基于角色能力的端点），规模化管理场景值得专门学（`about_JEA`）。注册的端点用 `Unregister-PSSessionConfiguration` 撤销。

## 19.2 非域环境：TrustedHosts

第 13 章说过：默认 Kerberos 认证**只认计算机名且要求同域**。工作组环境（家里两台机器、云上裸机、跨域访问）怎么办？客户端这边把目标加入 **TrustedHosts 名单**：

```powershell
# 查看（需 WinRM 服务运行；此命令本教程示例不执行，只演示读法）
Get-Item WSMan:\localhost\Client\TrustedHosts
# 设置（管理员；本教程不执行）
Set-Item WSMan:\localhost\Client\TrustedHosts -Value 'SERVER1, SERVER2' -Concatenate
Set-Item WSMan:\localhost\Client\TrustedHosts -Value '*'      # 信任一切（仅测试环境！）
```

`WSMan:` 是个 PSDrive（第 05 章"一切皆驱动器"的又一兑现——WinRM 配置就挂在驱动器上）。信任后认证降级为 **NTLM/Basic**（不再有 Kerberos 的双向保障），连接时通常还要显式给凭据：`-Credential (Get-Credential SERVER1\Admin)`。

**安全含义必须写进脑门**：TrustedHosts 是"我声明我信任这些机器的身份声明"——把 `*` 设进去等于接受任何服务器的凭据质询（中间人风险）。正确姿势是：**清单点名、用完收回、绝不裸奔 `*`**。域环境的正解永远是 Kerberos + 必要时 SSH（下一节）。

## 19.3 备用凭据与会话选项

跨环境远程最常见的两个"带参"需求：

**备用凭据**：几乎一切远程命令都接受 `-Credential (Get-Credential 域\用户)`。脚本里别明文放密码——用凭据对象（`Get-Credential` 交互获取）或保管库（SecretManagement 模块）；`Invoke-Command` 成批跑时**一条会话一份凭据**，不要每条命令问一遍。

**会话选项**：`New-PSSessionOption` 造一个选项对象，塞给 `-SessionOption`：

```powershell
$opt = New-PSSessionOption -IdleTimeout 600000 -OpenTimeout 15000 -SkipCACheck
New-PSSession -ComputerName s1 -SessionOption $opt
```

常用开关：`-OpenTimeout`（连接超时，慢网络调大）、`-IdleTimeout`（会话空闲存活，18 章断线重连的调节阀）、`-SkipRevocationCheck`（证书吊销查不了的内网）、`-NoMachineProfile`（不加载远程用户配置，启动更快）。它是"远程连接的高级设置面板"，选项对象先造后用、可复用。

## 19.4 第二跳问题

远程执行里再访问第三台机器（A 上远程到 B，B 的脚本又要访问 C 的共享/数据库）就叫**第二跳**（second hop）。默认认证协议**不把你的凭据带给 B**（安全设计），于是 B 访问 C 时是匿名——失败。

三条出路（按推荐序）：**CredSSP**（把凭据委托给 B——方便但风险大，域管慎开）；**资源端 Kerberos 约束委托**（KCD，域管理员配置，正规军）；**显式凭据到资源**（B 的脚本里对 C 用 `-Credential`，最朴素也最可控）。第 13 章说的"别远程链"是同一个问题的交互式变体——诊断"远程里访问网络资源失败"时，第一反应先想第二跳。

## 19.4.1 SSH 落地：三步配置清单

`-HostName` 能连通的前提（Windows 目标机视角，Linux 同理更简单）：

1. **装并启用 OpenSSH 服务器**：`Add-WindowsCapability -Online -Name 'OpenSSH.Server*'`；`Start-Service sshd; Set-Service sshd -StartupType Automatic`；
2. **给 sshd 配 PowerShell 子系统**：编辑 `C:\ProgramData\ssh\sshd_config`，加一行
   `Subsystem powershell c:/progra~1/powershell/7/pwsh.exe -sshs -NoLogo`
   （8.3 短路径避开空格转义），然后 `Restart-Service sshd`；
3. **认证**：密码即可通；要免密则 `ssh-keygen` 生成密钥对，公钥追加进目标的 `C:\ProgramData\ssh\administrators_authorized_keys`（管理员组）或用户级 `authorized_keys`。

验证链：`ssh user@host pwsh -c '$PSVersionTable.PSVersion'`（普通 SSH 直呼 pwsh）通了，再试 `New-PSSession -HostName host -UserName user`——前者通后者不通，问题必在子系统配置那一行。这份清单与微软官方文档的"PowerShell remoting over SSH"一节对应，细节以官方为准。

## 19.5 SSH 远程处理（pwsh 7）

pwsh 7 的远程处理有**两条腿**：WinRM（Windows 传统）与 **SSH**（跨平台新贵）。SSH 形态的识别标志是 `-HostName`（WinRM 用的参数名是 `-ComputerName`）：

```powershell
# 目标机：sshd 运行且安装了 PowerShell 子系统（默认 shell 或 winsshd 配置，见官方文档）
$s = New-PSSession -HostName linux1.contoso.com -UserName ops
Invoke-Command -Session $s -ScriptBlock { $PSVersionTable.OS }     # Linux 上的 PowerShell！
Enter-PSSession -HostName linux1 -UserName ops
```

与 WinRM 的对照表（选型依据）：

| | WinRM | SSH |
|---|---|---|
| 平台 | Windows ↔ Windows | **任意 ↔ 任意**（Windows/Linux/macOS 互通） |
| 认证 | Kerberos/NTLM/Basic | 密码/**公钥** |
| 端口 | 5985/5986 | 22 |
| 前置 | Enable-PSRemoting + 域或 TrustedHosts | 装 OpenSSH + 配子系统 |
| 典型场景 | 域内 Windows 机群 | 混合环境、跳板机、云上裸机 |

SSH 腿的认证用公钥最顺手（`ssh-keygen` 生成、公钥放进远端 `authorized_keys`，与普通 SSH 完全一致）。5.1 没有 `-HostName` 参数——SSH 远程是 7 的独享能力（跨版本脚本用 `Parameters.ContainsKey('HostName')` 探测，本章示例正是这么做的）。

## 19.5.1 选型决策树（全章收束）

把 13/18/19 三章的通道选择压成一棵树：

```
目标是 Windows 且在域里？
 ├─ 是 → WinRM + Kerberos（Invoke-Command/New-PSSession）
 │       多步任务？→ 持久会话（18 章）
 │       要限权？→ 自定义端点/JEA（19.1）
 └─ 否 ↓
 目标是 Windows 但工作组/跨域？
 ├─ 能改服务端 → TrustedHosts 点名 + Credential（19.2）
 └─ 不想动 WinRM → SSH 腿（19.4.1，pwsh 7）
 目标是 Linux/macOS？
 └─ SSH 腿（-HostName），密钥认证
 远程里还要访问第三台？→ 第二跳三选一（19.4）
```

这棵树加一个补丁就是现实世界的全部：**混合机群（Windows+Linux）时 SSH 腿是统一答案**——一条通道管所有平台，代价是每台装 OpenSSH 与子系统。没有完美选项，只有与环境和运维能力匹配的选项。

## 19.5.2 一个受限端点的完整画像

把 19.1 的概念拼成一个具体场景，看自定义端点解决什么问题（纯设计图，不执行）：

> 需求：让服务台员工能"重置打印队列服务"，但不能给他们管理员权限。
>
> 方案：`Register-PSSessionConfiguration -Name HelpDesk -RunAsCredential (Get-Credential svc-helpdesk) -StartupScript C:\PsEndpoints\helpdesk.ps1`。启动脚本 `helpdesk.ps1` 只做两件事：定义 `Reset-PrintQueue` 函数；随后 `Set-CommandVisibility -Hidden *` 把其他命令全部藏起来（或只导出白名单函数）。端点 Permission 加上服务台组。
>
> 使用：员工跑 `Invoke-Command s1 -ConfigurationName HelpDesk { Reset-PrintQueue 'PRN-03' }`——命令以 `svc-helpdesk` 服务账号执行（员工自己无权），环境里也只有这一个函数可用。

这幅画像里藏着三个关键设计：**RunAs 委托**（权限跟着端点走，不跟着人来）、**启动脚本塑形**（进去的世界由你定义）、**Permission 门槛**（谁能敲这扇门）。JEA（Just Enough Administration）把这三件事标准化成"角色能力文件"，规模化管理数十个受限端点——看到 JEA 材料时，对照本节这张画像即可秒懂它的骨架。

## 19.6 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| 工作组连不上（拒绝访问） | 默认 Kerberos 不跨工作组 | TrustedHosts 点名 + `-Credential`；或走 SSH |
| `Get-PSSessionConfiguration` 报拒 | 需要管理员且 WinRM 在跑 | 提权；先 `Test-WSMan` 探活 |
| 改了 TrustedHosts 还是连不上 | 服务端 WinRM 未启用/防火墙 | 两端都查；`winrm qc` 服务端视角 |
| 远程里访问网络资源失败 | 第二跳凭据没跟过去 | 19.4 三选一（优先约束委托/显式凭据） |
| pwsh 7 连过去发现是 5.1 | 默认端点是 5.1 | `-ConfigurationName PowerShell.7` |
| SSH 连接报 subsystem 错 | 目标 sshd 未配 PowerShell 子系统 | 按官方文档配 `sshd_config` 的 subsystem 行 |
| 会话空闲几分钟就断 | IdleTimeout 到点 | `-SessionOption (New-PSSessionOption -IdleTimeout …)` |
| `New-PSSessionOption -IdleTimeout` 报找不到参数 | WSMan 超时参数是 **WSMan 传输专用**；Unix 版把整条 WSMan 腿剔除了，只剩两个 SSL 校验开关 | 按 `Parameters.ContainsKey('IdleTimeout')` 探测，不按平台宏 |

## 19.7 本章要点

- 端点=入站合同（版本/权限/启动脚本/RunAs）；`Get-PSSessionConfiguration` 清点、`-ConfigurationName` 选择；自定义端点是受限授权的正解，JEA 是其工业形态。
- 非域环境：TrustedHosts 点名放行（`WSMan:` 驱动器），认证降级需显式凭据；**绝不 `*`**。
- `-Credential` 带凭据、`New-PSSessionOption` 造连接高级面板；第二跳三出路（CredSSP/约束委托/显式凭据）。
- **SSH 腿（pwsh 7 独享）**：`-HostName`/`-UserName`、公钥认证、跨平台互通——混合环境的正解。

**动手实验**（只读探测为主）：① `Test-WSMan` 与 `Get-Command ssh` 各探一下，看你环境有哪些远程通道；② `(Get-Command New-PSSession).Parameters.ContainsKey('HostName')` 在两个引擎各跑一次，验证 SSH 腿的存在性差异；③ `New-PSSessionOption -IdleTimeout 600000` 造一个选项对象，`Format-List` 看看面板里都有什么；④ 若实验机开了远程处理：`Get-PSSessionConfiguration` 读端点清单；⑤ 文字推演：家里两台工作组电脑要互相远程，写出两端的操作清单（服务端 Enable、客户端 TrustedHosts+Credential），对照 19.2 检查。

实验参考：②5.1 返回 False、7 返回 True——一条探测语句就是"SSH 腿可用性"的完整判定，跨版本脚本直接用它分支；③注意属性是 TimeSpan（`.TotalMinutes` 读法），毫秒只是入参单位；⑤正确清单：服务端（管理员）`Enable-PSRemoting -Force`，客户端（管理员）`Set-Item WSMan:\localhost\Client\TrustedHosts -Value '对方机器名' -Concatenate`，连接 `Enter-PSSession -ComputerName 对方 -Credential (Get-Credential 对方\用户)`——三步两台机器各做一遍（互连就双向各一轮）。

端点清单的读法补一个实例（`Get-PSSessionConfiguration` 典型输出逐行解读）：

```
Name          : Microsoft.PowerShell          ← 端点名（-ConfigurationName 用它）
PSVersion     : 5.1                           ← 连上来跑的引擎版本
StartupScript :                               ← 入场先跑的脚本（自定义端点常用）
RunAsUser     :                               ← 以谁的身份执行（RunAs 委托）
Permission    : BUILTIN\Administrators, …     ← 谁能连（访问控制）
```

五行的含义在 19.1 的"入站合同"里各就各位——**读懂这张表，你就读懂了一台机器对外开放了哪些"远程 PowerShell 窗口"**。安全巡检时它是必查项：多出来的自定义端点、权限给宽的端点，都是要问为什么的地方。

对应示例（可选）：`examples/19_advanced_remoting/`——SSH 客户端与 `-HostName` 参数的探测（引擎差异标记）、会话选项对象断言、WSMan/端点清单的门控只读探测（不通则带理由跳过）。

---

本篇（三 远程与批量）其余各章：[13 远程处理](./13-remoting.md) · [14 CIM](./14-cim.md) · [15 后台作业](./15-jobs.md) · [16 多对象](./16-multiple-objects.md) · [17 安全](./17-security.md) · [18 会话](./18-sessions.md)

> **下一篇衔接**：远程与批量的"用户技能"到此完整。下一篇进入语言核心（20–23 章）：变量、流、脚本、参数化——把命令固化成可复用的资产。


---

本篇（三 远程与批量）导航：[13 远程处理](./13-remoting.md) · [14 CIM](./14-cim.md) · [15 后台作业](./15-jobs.md) · [16 多对象](./16-multiple-objects.md) · [17 安全](./17-security.md) · [18 会话](./18-sessions.md) · [19 高级远程](./19-advanced-remoting.md)

SSH 落地三步（19.4.1）与选型决策树（19.5.1）是混合环境远程的速查页。
