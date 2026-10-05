# 15 多任务后台作业

> 本章对应原书第 15 章"多任务后台处理"，并补上原书出版后的新形态 ThreadJob。Shell 默认是单线程的：敲一条命令，等它跑完。**后台作业（Job）**把命令挪到独立执行环境里跑，控制台立刻空出来——长任务、多机任务的标准姿势。

## 15.0 全景：你会遇到的三种异步场景

后台作业在不同场景里有三副面孔，先认脸后学艺：

| 场景 | 你在做什么 | 命令形态 |
|---|---|---|
| 本地长任务 | 大文件处理、批量计算 | `Start-Job { … }` |
| 多机扇出 | 500 台机器各跑一条命令 | `Invoke-Command -ComputerName … -AsJob` |
| 命令自带的后台模式 | 某些命令本身支持 | 该命令的 `-AsJob` 开关 |

三副面孔一套管理命令（`Get-Job`/`Receive-Job`/`Remove-Job`）——本章把管理命令讲透，场景差异在 15.5 分说。

## 15.1 同步 vs 异步：四条关键差异

正常执行是**同步**的（等它跑完）；转入后台是**异步**的（它跑它的，你干你的）。转入后台前后有四条差异，每条都可能咬人：

1. **输入请求**：同步执行时缺参数会提示你补；后台作业**看不到任何提示**——缺参数直接失败。所以凡是要交互的命令（`Read-Host`、`Get-Credential` 裸调）都不能进作业；
2. **错误**：同步立刻红字；后台的错误**存进作业里**，要主动收（`Receive-Job` 连错误流一起给）；
3. **结果**：同步边跑边出；后台的结果**缓存在作业里**，跑完才可收；
4. **上下文**：作业跑在独立环境里，工作目录、部分变量都不继承——**用绝对路径，别赌相对路径**。

由此得出本章第一纪律（原书的原话级建议）：**先用同步模式把命令彻底调通，再转后台**。后台是给"已知能跑通的命令"提速的，不是给"还没调通的命令"躲错误的。

## 15.2 创建与查看：Start-Job 与 Get-Job

```powershell
$job = Start-Job -ScriptBlock { Get-ChildItem C:\ } -Name MyFirstJob
Get-Job
```

`Start-Job` 立即返回一个**作业对象**（不等你脚本块跑完），参数要点：`-Name`（好认）、`-ScriptBlock`（要跑的代码）、`-InitializationScript`（作业的预备脚本）。

`Get-Job` 列出当前会话的作业，重点读 `State` 与 `HasMoreData` 两列：

| State | 含义 |
|---|---|
| `NotStarted` / `Running` | 排队中 / 跑着 |
| `Completed` / `Failed` | 正常完 / 出错了（收结果看错误） |
| `Stopped` / `Stopped`（被停止） | `Stop-Job` 介入 |
| `Blocked` | 作业在等交互输入（第 1 条差异的现场） |

`HasMoreData = True` 表示**还有结果没收**；收完变 False——它是"要不要 Receive"的指示灯。看作业全貌用 `Get-Job -Id 1 | Format-List *`，其中 `ChildJobs` 属性是下一节的主角。

**一个实测发现的双引擎差异**（值得专门记）：**后台作业的初始工作目录两个引擎不同**——5.1 里作业从**用户的 Documents 目录**起步（原书专门用它讲"别猜路径"）；pwsh 7 改为**继承当前目录**。行为不一致本身就是"永远用绝对路径"的最好论据：同一条 `Start-Job { dir }`，两个引擎列出的目录不同。

## 15.3 收结果：Receive-Job 与 -Keep

```powershell
Receive-Job -Job $job
Receive-Job -Job $job          # 第二次：空！结果被上一条"取走"了
Receive-Job -Job $job -Keep    # -Keep：取走但在缓存留副本，可反复收
```

`Receive-Job` 的默认语义是**取件签收**——结果交给你之后缓存清空。要多次消费（先粗看再导出）就加 `-Keep`；或者收下后立刻 `Export-Clixml` 存档（第 06 章的快照手法）。

收到的结果有两点须知：**是反序列化快照**（属性齐全、方法全无——第 13 章序列化的同款规则，管道接筛/排/导出没问题）；**远程作业的结果带 `PSComputerName`**，`Receive-Job ... | Sort-Object PSComputerName | Format-Table -GroupBy PSComputerName` 是多机结果分组呈现的标准句式。

## 15.4 生命周期：Wait、Stop、Remove

作业的一生四步：创建（Start/AsJob）→ 查看（Get）→ 收割（Receive）→ **销毁（Remove）**。中间还有两个控制命令：

```powershell
Wait-Job -Job $job -Timeout 300    # 等它跑完（最多等 300 秒），脚本里同步化收尾用
Stop-Job -Job $job                 # 杀掉（作业进 Stopped，结果还可收）
Remove-Job -Job $job               # 真正销毁，释放缓存内存
```

**`Remove-Job` 是内存纪律**：作业对象与缓存结果常驻会话内存，只收不删的会话越用越沉。流程写全才是好习惯：Start → Wait/Get → Receive → Remove。清理顽固作业（Running 状态删不掉）先 `Stop-Job` 再 `Remove-Job -Force`。

## 15.5 作业的三种出身

"作业"是 PowerShell 的一个**扩展点**——多种命令都能产作业，长相一致但底层不同：

| 出身 | 创建方式 | 底层 | 特点 |
|---|---|---|---|
| 本地作业 | `Start-Job` | **新 PowerShell 进程** | 隔离最好；启动开销约 1 秒；跨进程传数据要序列化 |
| 远程作业 | `Invoke-Command -AsJob` | 远程机的 WinRM 会话 | 扇出 N 台机一条命令；结果带 `PSComputerName`；父作业下**每台机器一个子作业**（`ChildJobs`，单独收某一台的结果就找它） |
| 命令内建作业 | 各命令的 `-AsJob` 开关（如 CIM 查询） | 随命令而定 | 命令立刻返回，结果后台收 |
| 线程作业 | `Start-ThreadJob`（模块） | **同进程新线程** | 启动毫秒级、数据免序列化；隔离弱（崩了连累宿主） |

`Get-Job` 一视同仁地管理它们——所以"学一套管理命令，管所有类型的作业"。计划任务式的 `Register-ScheduledJob` 属于另一话题（跨会话持久），此处按住不表。

## 15.5.1 远程作业的父子结构实战

`Invoke-Command -AsJob` 是多机场景的主力，值得单独走一遍（远程处理已启用时）：

```powershell
$job = Invoke-Command -ComputerName s1, s2, s3 -ScriptBlock { Get-Service } -AsJob
$job | Format-List Name, State, HasMoreData

# 父作业下每台机器一个子作业——单台排查就看它
$job.ChildJobs | Select-Object Name, State, PSComputerName

# 收割：父作业一次收全部；按子作业收可以单独处理失败的那台
Receive-Job -Job $job -Keep
Receive-Job -Job $job.ChildJobs[1]      # 只收 s2 的结果
```

子作业的 `State` 逐台可见——`s2 Failed` 而其他 Completed 时，你不会因为一台机器坏掉丢掉整批结果。这是远程作业相对"裸 Invoke-Command"（一台失败整条命令报错）的最大工程优势。收尾别忘了父子两层都要释放：`Remove-Job $job -Force`（删父会连带子）。

## 15.6 ThreadJob：轻量级新形态

原书成书时只有进程级作业；今天多了一个重要选项 **ThreadJob**（`Start-ThreadJob`，pwsh 7 内置模块，5.1 可从 PSGallery 安装）：

```powershell
$fast = Start-ThreadJob -ScriptBlock { 1..3 | ForEach-Object { $_ * 2 } }
$fast | Wait-Job | Receive-Job        # 2 4 6
```

与 `Start-Job` 的选择：**要重隔离/要跑重型外部命令 → 进程作业；要高并发小任务 → 线程作业**。线程作业还是第 16 章 `ForEach-Object -Parallel` 的地基（那是一条命令里开 N 个线程作业）。数据传递注意：跨进程的 `Start-Job` 要用 `$using:` 把本地变量带进去（下一节），线程作业同样支持。

## 15.7 给作业传数据：$using:

作业环境拿不到你的本地变量——这条规则与远程处理一致（作业本质就是"本地远程"）。桥是 `$using:` 前缀：

```powershell
$path = 'C:\Windows'
$job = Start-Job -ScriptBlock { Get-ChildItem -Path $using:path | Measure-Object }
Receive-Job -Job $job -Wait
```

`$using:path` 在作业启动时把**值**的快照序列化送进去。反方向（作业改了变量想传回来）没有对称机制——作业能带回的只有**管道输出**，需要状态就用输出承载（输出对象里带状态字段）。

## 15.7.1 三问三答

**问：作业和会话（第 18 章）什么关系？**
两条正交的轴：会话管"连接复用"（省握手），作业管"执行异步"（不等它）。可以组合：`Invoke-Command -Session $s -AsJob`——在持久会话上异步执行。选型先问"我在等什么"：等结果（作业）还是省连接（会话）。

**问：关掉窗口，后台作业还在吗？**
不在。`Start-Job` 的作业属于当前会话，进程退出作业即亡。要"关机也在跑"的定时任务，用计划任务（`Register-ScheduledTask`/`Register-ScheduledJob`）——那是操作系统层的能力，不是 Shell 层的。

**问：怎么知道作业跑到哪了？**
作业没有"进度条"（除非脚本块自己写进度流并转发），只有 `State` 与输出缓存。要进度感，把脚本块里加 `Write-Progress` 或分阶段输出日志文件，从外面轮询文件。作业能给你的承诺是"跑完有结果、失败有错误流"，不是实况直播。

## 15.7.2 计划作业一瞥：跨会话的"定时后台"

`Start-Job` 的作业随会话生灭。要"每天凌晨两点自动跑、跑完结果可查"的作业，靠操作系统级的计划任务家族：

```powershell
# ScheduledJob：注册一个计划作业（需管理员，本教程不执行）
Register-ScheduledJob -Name NightlyInventory -ScriptBlock {
    Get-CimInstance Win32_LogicalDisk | Export-Csv C:\Reports\disk.csv
} -Trigger (New-JobTrigger -Daily -At 2am)
Get-Job -Name NightlyInventory      # 计划作业跑过的历史也是作业！可 Receive
```

它与本章的关系：**执行单元还是作业（同一套收割命令），触发权交给了任务计划程序**。`New-JobTrigger` 定义触发条件（每日/每周/一次性/开机后），`Register-ScheduledJob` 注册。现代更通用的做法是 `Register-ScheduledTask`（直接调度 `pwsh -File task.ps1`，不经过 ScheduledJob 抽象）——两条路都认识，见到老脚本里的 ScheduledJob 不陌生即可。第 33 章的收官项目会用 `Register-ScheduledTask` 把工具真正"上线"。

## 15.8 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| 作业 State=Failed / Blocked | 命令缺参要提示、或等交互输入 | 后台禁交互；先同步调通再转后台 |
| `Receive-Job` 第二次收不到 | 默认"取件签收"清缓存 | `-Keep` 或收完立刻存档 |
| 作业里相对路径全错 | 独立上下文，初始目录不保证（两引擎还不同！） | 脚本块内一律绝对路径 |
| 作业里读不到外面定义的变量 | 跨环境隔离 | `$using:变量` 传值快照 |
| 会话越跑越慢、内存涨 | 只收不删，作业与缓存积压 | Receive 后 `Remove-Job`；写脚本的固定收尾 |
| 多机作业某台结果缺失 | 父作业聚合，单台失败不显眼 | 查 `ChildJobs` 各自 State；按子作业收结果 |

## 15.9 本章要点

- 后台四差异：**无输入提示、错误进缓存、结果跑完可收、上下文独立**——先同步调通再转后台。
- `Start-Job`（进程级）→ `Get-Job`（State/HasMoreData 两灯）→ `Receive-Job`（默认签收制，`-Keep` 留副本）→ `Remove-Job`（内存纪律）；`Wait-Job -Timeout` 同步化收尾。
- 作业出身四种：本地/远程（`Invoke-Command -AsJob`，ChildJobs 每机一个）/命令内建/线程（`Start-ThreadJob`，毫秒级）；管理命令一套通用。
- 跨环境传值：`$using:`（单向、传值快照）；**初始目录两引擎不同**（5.1=Documents、7=继承当前）——绝对路径铁律。
- 结果是反序列化快照：筛排导出行，调方法不行。

**动手实验**：① `Start-Job { 1+1 }` 后 `Get-Job` 看 State 变化，`Receive-Job -Wait` 收结果；② 不带 `-Keep` 连收两次亲眼看第二次为空；③ 在作业里跑 `(Get-Location).Path`，与你当前目录对比（两个引擎各跑一次，看初始目录差异）；④ `$v=41; Start-Job { $using:v + 1 }` 收到 42；⑤ `Invoke-Command -ComputerName localhost -AsJob { 1+1 }`（需远程处理启用），收结果看 `PSComputerName`；⑥ 探测 `Get-Command Start-ThreadJob`，有则跑一个线程作业对比启动速度（`Measure-Command` 包住）。

实验参考：③5.1 作业目录是**用户 Documents**，pwsh 7 是**继承当前目录**——同一条命令两个答案，是"绝对路径纪律"最有说服力的教学现场；⑥`Measure-Command { Start-Job { 1 } | Wait-Job; Remove-Job (Get-Job) }` 与 ThreadJob 版对比，进程启动的约一秒差距肉眼可见。

再补一张"作业术语卡"（读 Help 与别人脚本时对号入座）：

| 术语 | 含义 | 在哪看 |
|---|---|---|
| 作业（Job） | 一个异步执行单元 | `Get-Job` 一行 |
| 父/子作业 | 多机作业的聚合层/每机一层 | `$job.ChildJobs` |
| 输出缓存 | 作业产出的暂存区（签收制） | `HasMoreData` 指示灯 |
| 反序列化结果 | 缓存里存的是快照不是活对象 | `Receive-Job` 后 `gm` 看 TypeName |
| runspace | 一条 PowerShell 执行线程的环境 | ThreadJob/-Parallel 的地基（16 章） |

对应示例（可选）：`examples/15_jobs/`——作业全生命周期断言、`-Keep` 双收实证、`$using:` 桥、ChildJobs 结构、Remove 后查无、ThreadJob 探针分支、初始目录差异（环境标记）。

---

本篇（三 远程与批量）其余各章：[13 远程处理](./13-remoting.md) · [14 CIM](./14-cim.md) · [16 多对象](./16-multiple-objects.md) · [17 安全](./17-security.md) · [18 会话](./18-sessions.md) · [19 高级远程](./19-advanced-remoting.md)

---

本篇（三 远程与批量）导航：[13 远程处理](./13-remoting.md) · [14 CIM](./14-cim.md) · [15 后台作业](./15-jobs.md) · [16 多对象](./16-multiple-objects.md) · [17 安全](./17-security.md) · [18 会话](./18-sessions.md) · [19 高级远程](./19-advanced-remoting.md)

本章示例演示了"作业初始目录两引擎不同"的实测差异；下章 -Parallel 的并行地基正是本章的 ThreadJob。
