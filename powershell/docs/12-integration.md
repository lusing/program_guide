# 12 学以致用——把前六章串成一个真实任务

> 本章对应原书第 12 章"学以致用"。原书在本章不教任何新东西，而是完整走一遍"面对陌生任务，从零到交付"的全过程——这个"过程本身"才是它要教的内容。本章同样：**没有新命令**，只有 06–11 章的工具在一台真实机器上协同作战。

原书的实战任务是修改 Windows 用户权限（privileges），靠安装社区模块 PoshPrivilege 完成。本章把这个**方法论**完整保留（12.2 节），另选一个每台机器都能跑、不改动系统的主任务作为串联载体：**磁盘库存清单**——"本机有哪些盘、多大、还剩多少、哪些快满了"，输出成屏幕表格、CSV 底档与 HTML 报告三种形态。

## 12.1 任务定义与提问

拿到任何任务先问三个问题，答案决定后面每一步：

1. **数据在哪？**——磁盘容量与空闲空间存放在 WMI/CIM 仓库的 `Win32_LogicalDisk` 类里（第 14 章正式讲 CIM，本章当"取数命令"用即可）；
2. **要什么形态的结果？**——即时看（屏幕表）、留底档（CSV，给程序再处理）、发给人（HTML，邮件附件）；
3. **跑多大范围？**——本章先做本机；跨机器版本等第 13/14 章的远程能力到位后回来升级。

问题想清楚，四段式骨架（第 06 章 6.8 节）直接上桌：**取数 → 筛/加工 → 排序 → 呈现/落盘**。

## 12.2 发现命令：原书的自学五步法

原书第 12 章的最大价值是这段"从不知道到会用"的流程，完整蒸馏如下（以它的真实案例为叙述线索）：

任务"修改用户权限"，第一步搜关键词：

```powershell
help *privilege*        # 命中一堆不相干的命令和两个 about 主题——没找到
Get-Command -Noun *priv*    # 空——本机没有相关命令
```

本地没有，转向生态（PowerShell Gallery，第 07 章）：

```powershell
Find-Module *privilege*     # 命中 PoshPrivilege
Install-Module PoshPrivilege   # 首次安装会弹"不受信任仓库"确认
```

**安装前后的信任三问**（原书专门停下来说的）：谁写的（作者是知名 MVP Boe Prox）；有没有帮助文件（"写模块不带帮助文件的都是坏人"——原书原话级别的态度）；代码敢不敢看（社区模块就是文本，`Get-Module` 找到路径翻一遍）。确认后探索模块（第 07 章五步法）：

```powershell
Get-Command -Module PoshPrivilege   # 看到 Add/Enable/Disable/Get/Remove-Privilege 一族
help Add-Privilege                  # 读语法：-AccountName + -Privilege（枚举值）
Get-Privilege                       # 先看现状，顺便拿到合法权限名清单
Add-Privilege -AccountName Administrators -Privilege SeDenyBatchLogonRight
Get-Privilege | Where-Object Privilege -eq 'SeDenyBatchLogonRight'   # 回查验证生效
```

注意流程的纪律性：**搜本地 → 搜生态 → 审查 → 列命令 → 读帮助 → 先 Get 现状 → 最小变更 → 回查验证**。这套循环不依赖任何具体模块——你将来面对 DNS、Exchange、Azure 模块时，走的都是同一条路。这也是"学完这本书不用再买每本书"的底气所在。

审查一步展开成具体动作（装任何社区模块前的固定仪式）：

1. `Find-Module 名字` 看 **Version 与发布时间**——三年没更新的模块要掂量；
2. 看 **Description 与作者信息**——作者是谁、有没有组织背书；
3. `Save-Module 名字 -Path .` **只下载不安装**，用 VS Code 翻一遍 `.psm1` 源码——重点看有没有网络外传（`Invoke-WebRequest` 到陌生域名）、有没有混淆代码（Base64 大块、`IEX` 调用）；
4. 过目后在测试机（不是生产机）上安装试用。

第 3 步是关键防线：PSGallery 只审恶意不审质量，**入口防的是投毒，内容审的是你自己**。这套动作也解释了为什么团队里应该有人负责"模块准入"而不是人人随手 `Install-Module`。

## 12.3 主任务第一步：取数与加工

磁盘库存，先取本地固定硬盘：

```powershell
Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
```

`DriveType=3` 是 WQL 方言的左过滤（第 11 章）：3 代表本地磁盘，网络盘、光驱、可移动盘在仓库端就被排除了。原始输出的 `Size`/`FreeSpace` 是**字节数**——能看但不友好，加工它（第 08 章计算属性）：

```powershell
$disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
        @{ n = '总GB'; e = { [math]::Round($_.Size / 1GB, 1) } },
        @{ n = '空闲GB'; e = { [math]::Round($_.FreeSpace / 1GB, 1) } },
        @{ n = '空闲比'; e = { if ($_.Size -gt 0) { [math]::Round($_.FreeSpace / $_.Size, 3) } else { 0 } } }
```

三个要点：`1GB` 数值后缀让换算可读；`空闲比`是**比率**（0.85 而不是 85）——后面格式串 `P1` 渲染时自动乘 100；分母为零的防御（`if ($_.Size -gt 0)`）——空光驱类对象可能出现 0，除以零会炸掉整条管道。**把中间结果存进变量 `$disks**：一次取数、三种输出复用，不给 WMI 增加三次查询。

## 12.4 第二步：筛与排序

"快满的盘"（空闲比低于 20%）单独拉一张告警表：

```powershell
$alerts = $disks | Where-Object 空闲比 -lt 0.2 | Sort-Object 空闲比
```

筛选条件是**算出来的属性**，任何命令参数都表达不了——所以走 `Where-Object`（第 11 章"参数粗筛 + Where 精筛"的定式）。中文属性名在管道里与英文名一视同仁（属性名只是字符串键），这个例子顺带证明了整条链对非 ASCII 的友好性。

## 12.5 第三步：三种呈现

同一份 `$disks`，三种出口各取所需（第 06/10 章的"数据用 Export、视图用 Out"）：

```powershell
# 形态一：屏幕速览（视图，格式化收尾）
$disks | Format-Table DeviceID, 总GB, 空闲GB,
    @{ n = '空闲比'; e = { '{0:P1}' -f $_.空闲比 }; Align = 'Right' } -AutoSize

# 形态二：CSV 底档（数据，全属性）
$disks | Export-Csv -Path inventory.csv -NoTypeInformation -Encoding UTF8

# 形态三：HTML 报告（给人）
$disks | Sort-Object 空闲比 |
    ConvertTo-Html -Property DeviceID, 总GB, 空闲GB, 空闲比 -Title '磁盘库存巡检' |
    Out-File -FilePath inventory.html -Encoding utf8
```

三个刻意的设计决策值得复盘：屏幕版把比率格式串 `P1` 放进**格式化层**（显示 85.0%），而 CSV 里保留**原始数值**（0.85）——下游 Excel 要算数，不能给人看的字符串；HTML 版排序**在转换之前**（第 10 章右到左铁律——转换命令不是 Format，但"先处理再转换"的顺序纪律不变）；文件名可以带日期戳：`"inventory-$(Get-Date -Format 'yyyyMMdd').csv"`（子表达式插值，第 20 章），日积月累就是天然的巡检归档。

## 12.6 第四步：回读对账

数据落盘不是终点，**能读回来才算闭环**：

```powershell
$back = Import-Csv -Path inventory.csv
$back.Count -eq $disks.Count          # True：行数守恒
$back[0].空闲比                        # 还是那个 0.85（以字符串形态）
```

注意一个细节：CSV 里一切都是字符串，`'0.85' -lt 0.2` 会**静默出错**（字符串与数字比较走强转，行为微妙）——下游要算数时先 `'-as' [double]` 转回来。这是"CSV 快照"形态的固有税，第 31 章的 JSON 会好一些（数字类型保留）。

## 12.7 决策复盘：每步为什么这样选

把全过程的选型理由列成一张表，它就是前六章的"使用索引"：

| 环节 | 选择 | 依据 |
|---|---|---|
| 取数 | `Get-CimInstance -Filter` | 左过滤（11）；CIM 是现代通道（14） |
| 只要本地盘 | `DriveType=3`（WQL） | 参数能表达就不 Where（11） |
| 单位与比率 | 计算属性 `@{n=;e=}`（08） | 现算一列，排序/过滤通用 |
| 分母防御 | `if ($_.Size -gt 0)` | 除零会炸管道，防御性脚本习惯 |
| 快满清单 | `Where-Object`（11） | 条件是计算属性，参数表达不了 |
| 屏幕表格 | `Format-Table` + `P1`（10） | 视图；Format 收尾 |
| 底档 | `Export-Csv`（06） | 数据出口，全属性 |
| 报告 | `ConvertTo-Html + Out-File`（06/10） | 转换+终点；排序前置 |
| 闭环 | `Import-Csv` 回读对账 | 快照可用性验证（06） |
| 复用 | `$disks` 变量存中间结果 | 一次取数多次呈现 |

## 12.8 本章要点

- **自学循环**：搜本地（`help *x*`/`Get-Command -Noun`）→ 搜生态（`Find-Module`）→ 信任三问 → `Get-Command -Module` → `help` → 先 Get 现状 → 最小变更 → 回查验证。
- 四段式骨架实战：取数（左过滤）→ 加工（计算属性+防御）→ 筛排（Where/Sort）→ 三态输出（屏幕视图 / CSV 数据 / HTML 报告）。
- 数据与视图分流：CSV 存原始数值、格式串留给显示层；**排序永远在转换/格式化之前**。
- 回读对账才闭环；CSV 全字符串，算数前 `-as` 转型。
- 文件名带日期戳，归档即巡检史。

## 12.8.1 从命令到"每天自动跑"还有几步

这条流程今天在命令行里敲完，明天还要再敲一遍——让它"自己跑"的路线图在这里立个路标（每一步都是后续某章的入口）：

1. **固化成脚本**：把命令存进 `.ps1`，用参数承接变量（阈值 0.2、目标路径）——第 22 章；
2. **参数验证**：阈值不许是负数、路径必须存在——第 23 章的 `[ValidateRange()]`；
3. **跨机器**：把 `Get-CimInstance` 换成带 `-CimSession` 的多目标版本——第 14 章；或整条命令丢给 `Invoke-Command` 扇出——第 13 章；
4. **定时执行**：Windows 计划任务（`Register-ScheduledTask`，或图形界面建任务指向 `pwsh -File inventory.ps1`）——工具化后的一行配置；
5. **结果推送**：`Send-MailMessage` 把 HTML 报告发进邮箱（现代替代：Graph API），或在告警非空时才发——第 25 章的条件逻辑。

注意这个顺序：**先在命令行把每一步调通，再谈固化与自动化**——这正是第 01 章"先当 Shell 用户"哲学的落点。反着来（先搭脚本框架再填命令）是新手项目烂尾的第一大原因。

## 12.8.2 变体练习：同一骨架换三个数据源

四段式骨架的复用性，最好的体会方式是换数据源原样再跑：

- **服务清单**：`Get-CimInstance Win32_Service`，计算属性换成"启动模式"，告警条件换成 `State -ne 'Running' -and StartMode -eq 'Auto'`（12.6 节实战一已给）；
- **大文件巡查**：`Get-ChildItem -Path C:\ -Recurse -File -ErrorAction SilentlyContinue`，计算属性"MB"，告警条件 `-gt 500`——注意这个取数没有左过滤可用，`-Filter` 不支持大小比较，只能在客户端筛（参数方言表达不了时的标准退路）；
- **补丁清单**：`Get-HotFix`，按 `InstalledOn` 排序取最近五个（日期排序，留意部分补丁该属性为空）。

三个变体的"筛排呈现"段几乎不用改——**骨架稳定、取数段随数据源换脸**，这就是管道组合的复利。

- **平台差异**：取数层按平台分两条路，但对外**列名保持一致**。Windows 走 `Get-CimInstance Win32_LogicalDisk`，它给 `Size`/`FreeSpace` 两个独立字段；macOS/Linux 没有 CIM 栈，改用 `Get-PSDrive -PSProvider FileSystem`——**PSDrive 没有 `Size` 字段**，只有 `Used`/`Free`，总量得自己 `Used + Free` 算。所以两条轨的计算属性写法不同，下游（筛排、三态输出、回读对账）完全共用。

**动手实验**：① 把 12.3–12.6 全流程在本机跑通（建一个临时目录存放产物，做完删掉）；② 把告警阈值从 0.2 调到 0.5，观察告警表变化；③ 给 HTML 报告加 `-PreContent '<h3>生成于自动巡检</h3>'`；④ 用 `Compare-Object` 比对两次导出的 CSV（先跑一次生成基线，删一个临时文件再……想想为什么这个比对对象选磁盘不太合适，选什么才合适）；⑤ 把 12.8.2 的三个变体至少跑通一个；⑥ 把整条流程的命令复制进一个 `.txt`，恭喜——你离第 22 章的"第一个脚本"只差改扩展名。

实验参考：④磁盘的空闲字节随时在变，比对会被噪音淹没——**选"身份型"数据**（已装补丁清单、服务名单）做基线比对才有意义（第 06 章 `-Property` 聚焦身份列的教训在此兑现）；⑤大文件巡查在系统盘可能跑几分钟，建议换个浅目录练手。

## 12.9 一页流程图（可贴墙版）

把本章全过程画成一段文字流程，遇到任何"从零到报表"的任务照着走：

```
定义任务
   │  数据在哪？要什么形态？跑多大范围？
   ▼
发现命令
   │  help *关键词* → Get-Command -Noun → Find-Module →（审查四步）→ Get-Command -Module
   ▼
读帮助                    语法图四读：参数集 / 方括号 / 位置 / 类型（第 03 章）
   ▼
取数（左过滤优先）
   │  有参数方言就写进参数；WQL/AD 方言照帮助示例
   ▼
加工（计算属性 + 分母防御）
   ▼
筛与排序（Where-Object / Sort-Object；条件是算出来的属性时必走这里）
   ▼
呈现（三态分流）
   │  屏幕 → Format-* 收尾；数据 → Export-Csv；给人 → ConvertTo-Html + Out-File
   ▼
回读对账（Import-Csv；字符串要 -as 转型）
   ▼
（后续路标：固化脚本 22 → 参数验证 23 → 跨机 13/14 → 计划任务）
```

这张图同时也是本教程第二篇（06–12 章）的目录——每一行都能翻回对应章节找到依据。

对应示例（可选）：`examples/12_integration/`——库存全流程的结构断言：行数守恒（CSV 往返）、HTML 含表与列名、告警子集阈值成立、空闲比值域合法、日期戳文件名生成与清理。

---

本篇（二 对象与管道）其余各章：[06 管道](./06-pipeline-first.md) · [07 模块生态](./07-modules-usage.md) · [08 对象](./08-objects.md) · [09 深入管道](./09-pipeline-deep.md) · [10 格式化](./10-formatting.md) · [11 过滤](./11-filtering.md)

---

本篇（三 远程与批量）后续各章：[13 远程处理](./13-remoting.md) · [14 CIM](./14-cim.md) · [15 后台作业](./15-jobs.md) · [16 多对象](./16-multiple-objects.md) · [17 安全](./17-security.md) · [18 会话](./18-sessions.md) · [19 高级远程](./19-advanced-remoting.md)
