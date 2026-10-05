# 18 轻松远程控制——可复用会话 PSSession

> 本章对应原书第 20 章"轻松实现远程控制"。第 13 章的 `Invoke-Command -ComputerName` 每次执行都要**新建连接、握手、执行、拆除**——单次命令无所谓，反复对同一批机器发命令就是浪费。本章给出远程的第三种形态：**可复用的持久会话（PSSession）**。

## 18.0 开篇：一次真实的多步任务

体会会话价值的最好方式是看一个没有会话的笨办法。任务：对 Server-R2 查系统信息 → 装了哪些补丁 → 服务状态，三步。

```powershell
# 没有会话：三次握手，每次都是陌生人
Invoke-Command -ComputerName Server-R2 { Get-CimInstance Win32_OperatingSystem }
Invoke-Command -ComputerName Server-R2 { Get-HotFix }
Invoke-Command -ComputerName Server-R2 { Get-Service }

# 有会话：一次握手，三次复用（还能共享状态）
$s = New-PSSession -ComputerName Server-R2
Invoke-Command -Session $s { $os = Get-CimInstance Win32_OperatingSystem }    # 结果存进会话
Invoke-Command -Session $s { $os.Caption }                                     # 下一步接着用
Invoke-Command -Session $s { Get-HotFix | Where-Object HotFixID -eq 'KB5001' } # 拿刚才的补丁号查
Remove-PSSession $s
```

第二个版本不仅快（省两次握手），而且**步骤之间能传递状态**——多步任务的代码从"三个孤岛"变成"一段连贯逻辑"。这就是本章要教的工作形态。

## 18.1 从"一次性"到"持久"

先量化痛点。对同一台机器连发三次 `Invoke-Command -ComputerName`，每次都完整走一遍：建立 WS-MAN 通道 → 认证 → 起远程 PowerShell → 执行 → 拆除。三次命令 = 三次全套握手。而 `Enter-PSSession` 虽然是持久连接，却是交互式的——脚本没法用。

**PSSession** 填的正是这个空档：显式创建、显式管理的**持久远程连接**，脚本与交互通吃：

```powershell
$s = New-PSSession -ComputerName Server-R2, Server17, DC5   # 一次建三条
Get-PSSession                                                # 列出当前会话
```

`New-PSSession` 返回会话对象（一个或一批），它活在**你的会话内存里**——只要这个 PowerShell 进程开着，连接就在。需要备用凭据/端口/认证方式，参数与 `Invoke-Command` 一致（`-Credential`、`-Port` 等）。

## 18.2 用会话干活：Invoke-Command -Session

`Invoke-Command` 有两种接目标的方式，语义不同：

```powershell
Invoke-Command -ComputerName s1 -ScriptBlock { ... }   # 一次性：命令级连接，用完即拆
Invoke-Command -Session $s -ScriptBlock { ... }        # 复用：走已有会话，免握手
```

**持久连接的最大红利是"状态活了下来"**——这是 `-ComputerName` 模式给不了的。对照实验（远程处理已启用时）：

```powershell
# 一次性模式：两次命令之间无记忆
Invoke-Command -ComputerName localhost -ScriptBlock { $x = 1 }     # 设了变量
Invoke-Command -ComputerName localhost -ScriptBlock { $x }         # 空——上次的 $x 已随连接销毁

# 会话模式：变量在会话里活着
Invoke-Command -Session $s -ScriptBlock { $x = 1 }                 # 设在会话的内存里
Invoke-Command -Session $s -ScriptBlock { $x }                     # 1——还在！
```

一次性模式每次都是**崭新的远程进程**（无状态，适合"问一句就走"）；会话模式是**同一个远程进程反复用**（有状态，适合"多步对话"——设变量、导入模块、定义函数，下一步接着用）。交互式入口同样吃会话：`Enter-PSSession -Session $s`，退出来会话还在（`Exit-PSSession` 只退出交互，不拆连接）。

## 18.3 会话的生命周期管理

会话占着**两头**的资源（你机器与远程机器各一份内存与连接），所以纪律比一次性命令严格：

```powershell
Get-PSSession                      # 清点
Get-PSSession -ComputerName s1     # 按机器过滤
Remove-PSSession -Session $s       # 用完拆除（资源纪律，等同第 15 章 Remove-Job）
Remove-PSSession *                 # 全拆
```

**断线重连**是会话的高阶能力：连接断了（网络抖动、本机重启），远程那头的会话还能**存活一段时间**，之后重新接上继续用：

```powershell
Disconnect-PSSession -Session $s   # 主动断开（远程会话挂起保留）
Connect-PSSession -Session $s      # 重连（同一会话对象满血复活）
```

用途画面：下班前发起一个长任务（`Invoke-Command -Session $s -ScriptBlock { 大任务 } -AsJob`——会话+作业组合拳），断线回家，VPN 重连后 `Connect-PSSession` 收结果。远程会话的默认存活策略（IdleTimeout 等）由端点配置决定，第 19 章的高级配置话题。

## 18.4 两族命令的心智模型

把远程命令按"目标怎么给"分两族，选型一目了然：

| | ComputerName 族 | Session 族 |
|---|---|---|
| 代表用法 | `Invoke-Command -ComputerName`、`Enter-PSSession -ComputerName` | `-Session $s`（同一批命令） |
| 连接 | 命令级，用完即拆 | 显式建、显式拆 |
| 状态 | 无（每次新进程） | **有**（变量/模块/函数跨命令存活） |
| 反复调用 | 慢（重复握手） | 快（复用通道） |
| 适用 | 单发查询、一次性巡检 | 多步任务、高频调用、状态累积 |

经验法则：**对同一目标的命令超过两三条，就值得建会话**。顺带一提，`*-PSSession` 命令族在两个引擎上都可用（pwsh 7 连 5.1 端点或 SSH 目标都行，端点选择见 13.5 与 19.5）。

## 18.4.1 扇出实战：会话 + 作业组合拳

第 15 章埋的"组合拳"在这里兑现：**持久会话（省握手）+ 后台作业（免等待）**是对一批机器跑长任务的最优形态：

```powershell
# 一批会话（一次建好）
$sessions = New-PSSession -ComputerName (Get-Content servers.txt)
# 在会话上异步执行长任务（立刻返回作业）
$job = Invoke-Command -Session $sessions -ScriptBlock {
    Get-WinEvent -LogName System -MaxEvents 5000 | Group-Object ProviderName
} -AsJob
# 干别的去……回来收割
$null = Wait-Job $job -Timeout 600
Receive-Job $job | Sort-Object PSComputerName, Count -Descending |
    Select-Object PSComputerName, Name, Count -First 20
# 清场：会话与作业各归各位
Remove-Job $job -Force
Remove-PSSession $sessions
```

注意收尾的**双清理**——作业和会话是两份资源（第 15 章与本章的纪律叠加）。清场的固定句式值得背下来：`Remove-Job …; Remove-PSSession …`，或者脚本里放进 `finally` 块（第 26 章）。

## 18.5 CIM 的对应物：CimSession

第 14 章的 CIM 查询也有会话形态——`New-CimSession`（WS-MAN 复用通道）与 `New-CimSession -SessionOption (New-CimSessionOption -Protocol Dcom)`（老机器 DCOM）。多机批量 CIM 查询（`Get-CimInstance -CimSession $cs`）既省握手又解决第 14 章说的"单机超时拖全批"问题（会话可并行收）。心智模型与 PSSession 完全同构：**一次性 vs 持久**的选择题再做一遍。两者并存不冲突：PSSession 跑命令，CimSession 查仓库。

## 18.5.1 名词辨析：Session 的三个亲戚

远程家族里有三个带"Session"的词，值得一次掰清（读文档与排错时都受益）：

| 词 | 是什么 | 谁管理 |
|---|---|---|
| **PSSession** | 你显式建立的持久远程连接 | 你（New/Remove） |
| **会话（进程内 session/runspace）** | 每个 PowerShell 进程本身的执行环境（变量、函数都在这里） | 引擎（隐式） |
| **CimSession** | CIM 命令的持久连接 | 你（New-CimSession） |

第 18.2 节"变量活下来"的机制其实就是：`Invoke-Command -Session` 把命令送进**远端那个进程内 session** 跑，同一个 PSSession 对应同一个远端 session，所以状态延续。而 `Get-PSSession` 显示的 `IdleTimeout` 等属性，管的是"这条 PSSession 连接空闲多久后回收"。三层各管一段：**PSSession 管连接、远端 session 管状态、CimSession 管仓库通道**。分清后再读 `about_PSSessions` 与错误信息（"session 已断开/超时"说的是连接层），不会再糊。

## 18.6 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| 会话变量"丢了" | 用了 `-ComputerName` 一次性模式 | 要状态就建会话（18.2 对照实验） |
| 会话越积越多、远程内存涨 | 只建不拆 | `Remove-PSSession` 收尾纪律；`Get-PSSession | Remove-PSSession` 一键清 |
| 断线后会话没了 | 超出 IdleTimeout 被回收 | 及时 `Connect-PSSession`；调优看端点配置（19 章） |
| `Enter-PSSession` 后退出就把会话拆了 | 误以为 Exit 会拆连接 | Exit 只退交互；拆连接是 `Remove-PSSession` |
| 多机会话结果混装 | 会话对象批量调用聚合输出 | 按结果 `PSComputerName` 分组（第 13 章句式） |
| 会话在脚本里用完忘拆 | 脚本异常路径跳过清理 | try/finally 里 Remove（第 26 章标准范式） |

最后用一段"会话的一天"把本章命令按时间线串起来（可直接当脚本骨架读）：

```powershell
# 早晨：建一批会话（清单来自文件）
$s = New-PSSession -ComputerName (Get-Content servers.txt) -Name DailyOps
# 上午：多步任务，状态在会话里累积
Invoke-Command -Session $s { $baseline = Get-Service }
Invoke-Command -Session $s { $baseline | Where-Object Status -ne 'Running' }
# 中午：长任务转作业，人去吃饭
$job = Invoke-Command -Session $s { Get-WinEvent -LogName System -MaxEvents 10000 } -AsJob
# 下午：收作业、拆作业
Receive-Job $job -Keep | Export-Csv today-events.csv; Remove-Job $job -Force
# 下班：拆会话（或 Disconnect 留到明天）
Remove-PSSession $s        # 或： Disconnect-PSSession $s
```

九行脚本里出现了本章全部主角：批量建、状态累积、会话+作业、双清理、断线可选。能读懂并改写它，本章毕业。

## 18.7 本章要点

- PSSession=**显式持久连接**：`New-PSSession` 建、`Get-PSSession` 清点、`-Session` 复用、`Remove-PSSession` 拆（资源纪律）。
- **状态红利**：会话内变量/模块/函数跨命令存活；一次性模式无状态——多步任务必须用会话。
- `Disconnect/Connect-PSSession` 断线重连；`Enter-PSSession -Session` 交互复用，Exit 不拆连接。
- 两族选择：单发用 `-ComputerName`，两三条以上/要状态用会话；CimSession 是 CIM 侧的同构物。

**动手实验**（需实验机已启用远程处理；未启用则参照第 13 章说明）：① `$s = New-PSSession -ComputerName localhost`，`Get-PSSession` 看它；② 复现 18.2 对照实验（一次性两次丢变量、会话两次变量在）；③ `Enter-PSSession -Session $s` 进出一次，确认会话还在；④ `Disconnect-PSSession` 后 `Connect-PSSession`，变量依然健在；⑤ `New-CimSession` 建 CIM 会话，`Get-CimInstance -CimSession` 查两台（本机两遍），与逐机查询对比手感；⑥ 最后 `Remove-PSSession *` 清场。

实验参考：②"变量丢没丢"用 `"$x" -eq ''` 判（远程空值序列化回来是空串或空，别用 `-eq $null` 较真）；④断线后 `Get-PSSession` 的 State 是 `Disconnected`，重连后变 `Opened`——状态机全程可观察。

会话命令速查卡（本章一图流）：

| 命令 | 一句话 |
|---|---|
| `New-PSSession -ComputerName a,b` | 建一批持久连接 |
| `Get-PSSession` / `-ComputerName a` | 清点 / 按机过滤 |
| `Invoke-Command -Session $s {}` | 在会话上执行（复用、有状态） |
| `Enter-PSSession -Session $s` / `Exit-PSSession` | 交互进出（不拆连接） |
| `Disconnect-` / `Connect-PSSession` | 挂起 / 重连 |
| `Remove-PSSession`（`*`） | 拆除（资源纪律） |
| `New-CimSession` / `Get-CimInstance -CimSession` | CIM 侧同构物 |

最后回答一个常见疑问：**"会话开着会占多少资源？"**——每条会话在两端各占一个 runspace（约几 MB 级）加一条 TCP 连接。十条八条无感，上千条要规划（此时你需要的已经不是手工管理，而是按批建拆的脚本化流程——第 33 章的方向）。

对应示例（可选）：`examples/18_sessions/`——WinRM 探针门控下的会话全流程：状态持久对照（会话 vs 一次性）、Exit 不拆连接、断线重连后变量存活、Remove 后查无。

---

本篇（三 远程与批量）其余各章：[13 远程处理](./13-remoting.md) · [14 CIM](./14-cim.md) · [15 后台作业](./15-jobs.md) · [16 多对象](./16-multiple-objects.md) · [17 安全](./17-security.md) · [19 高级远程](./19-advanced-remoting.md)

> **本篇收束**：13–19 章构成"企业级 PowerShell 用户"的全部技能面——单机查询到千机扇出、同步等待到异步收割、裸权限到受限端点。接下来的语言核心篇让你从"用户"进阶为"作者"。


---

本篇（三 远程与批量）导航：[13 远程处理](./13-remoting.md) · [14 CIM](./14-cim.md) · [15 后台作业](./15-jobs.md) · [16 多对象](./16-multiple-objects.md) · [17 安全](./17-security.md) · [18 会话](./18-sessions.md) · [19 高级远程](./19-advanced-remoting.md)

会话+作业组合拳（18.4.1）与双清理纪律是第 33 章工具上线的直接前置。
