# 14 CIM 与 WMI——管理信息的中央仓库

> 本章对应原书第 14 章"Windows 管理规范"（WMI）。WMI 是微软给管理员的最强工具之一，也是最容易把人绕晕的技术之一——原书开篇就承认"一直期望但又害怕写这一章"。本章按现代口径讲：**用 CIM 命令访问 WMI 仓库**，并讲清老 WMI 命令与新 CIM 命令的分界。

PowerShell 内置命令再丰富，也盖不住一个事实：**Windows 数以万计的系统信息（硬件、BIOS、磁盘、服务、补丁、网络……）存在一个独立于 PowerShell 的仓库里**——WMI（Windows Management Instrumentation）。PowerShell 只是这个仓库的查询接口。学会它，"查这台机器的出厂信息/装了哪些补丁/内存条几根"都变成一行命令。

## 14.1 仓库的结构：命名空间 → 类 → 实例

WMI 仓库（repository）是一棵三层树：

| 层 | 类比 | 例子 |
|---|---|---|
| **命名空间**（namespace） | 文件夹（按产品/技术分） | `root\CIMv2`（系统与硬件主库）、`root\SecurityCenter2`（安全软件）、`root\MicrosoftDNS` |
| **类**（class） | 表结构（描述一种信息） | `Win32_LogicalDisk`（逻辑磁盘）、`Win32_BIOS`、`AntiVirusProduct` |
| **实例**（instance） | 表里的行（现实中的一个实物） | 两块盘 = 2 个 `Win32_LogicalDisk` 实例；一根内存条 = 1 个 `Win32_PhysicalMemory` 实例 |

`root\CIMv2` 是默认命名空间（系统与硬件的大多数类都在这），类名带 `Win32_`（历史前缀，64 位系统也叫 Win32）或 `CIM_`（国际标准 Common Information Model 的基类，通常不直接用）。其他命名空间各有各的类名习惯。

两个务实提醒：**类存在 ≠ 对应硬件存在**（`Win32_TapeDrive` 类永远在，磁带机你多半没有——查出来是空集而已）；**命名空间随 Windows 版本变**（`SecurityCenter` 变成 `SecurityCenter2` 是 WMI 混乱史的经典梗，写脚本前先探一下目标机器有什么）。

## 14.1.1 逛仓库：从命名空间到类的两条浏览路径

不知道要查什么类时，两个"逛"的入口：

```powershell
# 入口一：列某命名空间下的所有类（类名模糊匹配）
Get-CimClass -Namespace root\CIMv2 -ClassName *Disk*

# 入口二：列顶层有哪些命名空间（仓库的"楼层索引"）
Get-CimInstance -Namespace root -ClassName __Namespace | Select-Object Name
```

入口二的 `__Namespace` 是 WMI 的元类（双下划线开头=系统类，第 14.4 节的规则提前用上）——`root` 下能看到 `cimv2`、`securitycenter2`、`Microsoft` 等楼层。逛的典型路径：**先想关键词（disk/bios/service…）→ `Get-CimClass` 模糊搜 → 看中某个类的属性方法（14.5 节）→ 再查实例**。与第 03 章的"帮助系统是命令的地图"对应，`Get-CimClass` 是仓库的地图。

顺带一个新旧命令的对照小考：老 WMI 时代列类用 `Get-WmiObject -List`，新写法 `Get-CimClass` 返回的是**类定义对象**（属性方法清单可直接管道），信息质量高出一截——换代的又一处甜头。

## 14.2 两代命令：Get-WmiObject（遗留）与 Get-CimInstance（现代）

与仓库通信的命令经历了一次换代，分界线必须记清：

| | WMI 命令（v1–v2 时代） | CIM 命令（v3 起，现代） |
|---|---|---|
| 代表命令 | `Get-WmiObject`、`Invoke-WmiMethod` | `Get-CimInstance`、`Invoke-CimMethod` |
| 传输协议 | RPC/DCOM（穿防火墙难） | WS-MAN（同远程处理，5985 端口）；也支持退回 DCOM |
| 状态 | **遗留**：5.1 还有，**pwsh 7 已整体移除** | 微软主线，持续改进 |
| 日期时间 | DMTF 字符串（`20261006120000.000000+480`，要转换） | 真 `DateTime` 对象（可直接比较、格式化） |
| 远程 | `-ComputerName` 走 DCOM | 远程走 WS-MAN；**本机查询不需要任何远程设置** |

结论一句话：**新代码一律 CIM 命令**。`Get-WmiObject` 只在维护 5.1 老脚本时才会遇到（本教程示例里它只作为"仅 5.1"的对照出现一次）。

一个常被误解的点值得专门澄清（也是本教程示例能在普通开发机上跑的原因）：**`Get-CimInstance` 不带 `-ComputerName` 时走本地 COM 直连，与 WinRM 服务是否启用无关**。远程（`-ComputerName`）才需要目标启用远程处理。所以"查本机信息"永远可用，"查别机信息"是第 13 章的门槛。

## 14.2.1 WQL 运算符全表

`-Filter`/`-Query` 说的 WQL 方言，运算符全集一表收齐（写复杂条件时对照）：

| 类别 | 运算符 | 例 |
|---|---|---|
| 比较 | `=`、`<>`、`>`、`<`、`>=`、`<=` | `"DriveType=3"`、`"State<>'Running'"` |
| 模式 | `LIKE`（`%` 任意串、`_` 单字符） | `"Name LIKE 'Win%'"` |
| 范围/集合 | `ISA`（是否某类族） | `"__CLASS ISA 'Win32_Service'"` |
| 逻辑 | `AND`、`OR`、`NOT` | `"StartMode='Auto' AND State<>'Running'"` |
| 判空 | `IS NULL`、`IS NOT NULL` | `"Description IS NULL"` |

注意 `IS NULL` 里**没有** `-eq $null` 的对应物；以及整个表达式是**一个字符串**（外双内单），不是 PowerShell 表达式——引擎把它原样交给仓库解析。写错时 WMI 会直接回"查询无效"，报错行号指向你的 `-Filter` 参数，挺好认。

## 14.3 查询：Get-CimInstance 与 WQL 方言

基本形态（`-ClassName` 是位置参数）：

```powershell
Get-CimInstance -ClassName Win32_OperatingSystem
Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct
```

缩小结果集用 `-Filter`，但注意**它说的是 WQL 方言，不是 PowerShell**（第 11 章方言坑的正式展开）：

```powershell
Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"
Get-CimInstance -ClassName Win32_Service -Filter "StartMode='Auto' AND State<>'Running'"
```

WQL 方言四条铁律：

1. 比较符是 `=`、`<>`、`>`、`<`、`>=`、`<=`——**没有 `-eq`**；布尔关键字 `AND/OR/NOT`；
2. 字符串值用**单引号**，整个表达式用**双引号**包住（所以外双内单）；
3. `LIKE` 的通配符是 **`%`** 不是 `*`：`"Name LIKE '%server%'"`；
4. 反斜杠要写成两个：`"Name='COMPANY\\Administrator'"`。

还有个孪生参数 `-Query`，接收完整 WQL 语句（`-Query "SELECT * FROM Win32_LogicalDisk WHERE DriveType=3"`）——与 `-Filter` 等价，复杂条件（JOIN 之类）时更顺手，日常 `-Filter` 更简洁。

多机查询：`-ComputerName s1,s2`（需要远程处理启用；某台不通会**超时 30–45 秒后跳过**——大批量时这个超时很伤，第 18 章的 CimSession 池是解药之一）。

## 14.4 结果对象：属性、系统属性与 PSComputerName

查回来的实例对象，属性可以正常筛排选（第 08/11 章全套适用），两件事特别值得知道：

**隐藏的系统属性**：WMI 实例自带一批 `__` 开头的系统属性（`__SERVER` 来源机器、`__PATH` 实例绝对引用、`__CLASS` 类名……）。默认显示配置会隐藏它们，但 `Format-List *`、`Select-Object -Property *` 时会倾巢而出——看到一屏 `__GENUS`、`__DERIVATION` 不要慌，那是仓库的元数据，过滤掉即可。CIM 命令贴心地把最常用的 `__SERVER` 映射成了好记的 **`PSComputerName`** 属性（与第 13 章远程结果的标记列同名；实测注意：**本机直连时该属性存在但值为空**，远程查询时才填机器名——多机结果按它分组）。

**日期已经是日期**：`LastBootUpTime` 这类属性在 CIM 命令下是真 `DateTime`（`gm` 验证），可以直接 `((Get-Date) - $os.LastBootUpTime).Days` 算开机天数——WMI 命令时代还得 `[Management.ManagementDateTimeConverter]::ToDateTime()` 转一道，这是换代最实在的甜头之一。

## 14.5 看结构：Get-CimClass 与方法调用

查询之前想知道"这个类有什么属性/方法"？看**类**而不是查**实例**：

```powershell
Get-CimClass -ClassName Win32_Process |
    Select-Object -ExpandProperty CimClassMethods        # 方法清单：GetOwner、Terminate…
Get-CimClass -ClassName Win32_LogicalDisk |
    Select-Object -ExpandProperty CimClassProperties     # 属性清单（连类型带只读标记）
```

WMI 不只是数据库，很多类带**方法**（对实物下指令：关机、杀进程、取属主）。CIM 时代调用方法的正解是 `Invoke-CimMethod`：

```powershell
$proc = Get-CimInstance -ClassName Win32_Process -Filter "ProcessId=$PID"
Invoke-CimMethod -InputObject $proc -MethodName GetOwner      # 返回 .Domain/.User —— 这个进程是谁的
```

先取实例、再带着实例调方法——替代了 WMI 时代的 `$proc.GetOwner()` 直接调用（快照对象没有实例方法，与第 13 章序列化的教训同源）。常用方法速记：`Win32_OperatingSystem.Reboot/Shutdown`、`Win32_Process.Terminate`、`Win32_Service.StartService/StopService`（不过服务类操作用 `Start-Service` 等 Cmdlet 更顺手，方法集是给"Cmdlet 没覆盖的场景"准备的）。

## 14.5.1 关联：把两张表连起来

仓库里的类不是孤岛——WMI 维护着**关联**（association）：比如"这块磁盘分区在哪个物理磁盘上"。PowerShell 侧的入口是 `Get-CimAssociatedInstance`：

```powershell
$os = Get-CimInstance Win32_OperatingSystem
Get-CimAssociatedInstance -InputObject $os -ResultClassName Win32_SystemPartition   # OS → 分区
# 再进一步：分区 → 物理磁盘
Get-CimAssociatedInstance -InputObject ($disk…) -ResultClassName Win32_DiskDrive
```

日常用得不多，但遇到"从 A 实体查到 B 实体"（逻辑盘→物理盘、打印机→驱动、进程→服务）时，先想想关联类，往往比手工拼属性匹配干净。用 `Get-CimClass -ClassName Win32_*System*` 能扫出一批关联类（名字里带 System/Partition 的大多是）。

## 14.6 高频类速查（值得贴墙）

| 需求 | 类 |
|---|---|
| 操作系统版本/安装时间/开机时长 | `Win32_OperatingSystem` |
| 序列号/出厂信息 | `Win32_BIOS`（+ `Win32_ComputerSystemProduct`） |
| 磁盘空间 | `Win32_LogicalDisk`（DriveType=3 本地盘） |
| 物理内存条数与容量 | `Win32_PhysicalMemory` |
| 服务清单与启动模式 | `Win32_Service` |
| 进程（含命令行） | `Win32_Process`（`CommandLine` 属性是 Get-Process 没有的宝藏） |
| 已装补丁 | `Win32_QuickFixEngineering` |
| 网卡（物理） | `Win32_NetworkAdapter`（`PhysicalAdapter=True`） |
| 已装软件（传统 MSI） | `Win32_Product`（⚠️ 触发自检修复，慎用；注册表 Uninstall 键更安全，见第 05 章） |

最后一行的警告是 WMI 圈的名坑：`Win32_Product` 查询会顺带做 MSI 一致性校验（可能重新配置软件），生产环境用第 05 章的注册表方案。

## 14.7 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| `-Filter` 里写 `-eq` 报语法错 | WQL 方言用 `=`（14.3 四铁律） | 照铁律改写；复杂条件换 `-Query` |
| 过滤值含 `\` 查不到 | WQL 反斜杠要双写 | `'COMPANY\\Administrator'` |
| 多机查询卡半分钟 | 某台不通，等超时才跳 | 小批先 `Test-WSMan` 探活；大批用 CimSession（18 章） |
| 结果里一堆 `__GENUS` 噪音 | 系统属性被 `*` 放出 | `Select-Object` 明确列属性，别用 `*` |
| pwsh 7 报"找不到 Get-WmiObject" | WMI 命令族已被移除 | 全部改 CIM 命令（本表第 1 行链接 14.2） |
| `Win32_Product` 越查越慢/弹安装 | MSI 自检修复副作用 | 改用注册表 Uninstall 键（第 05 章案例二） |

## 14.8 本章要点

- WMI=独立仓库：**命名空间→类→实例** 三层；`root\CIMv2` 是主库；类存在≠硬件存在。
- **新代码一律 CIM 命令**（`Get-CimInstance`/`Get-CimClass`/`Invoke-CimMethod`）；WMI 命令族 pwsh 7 已移除。
- **本机查询免远程设置**（本地 COM 直连）；`-ComputerName` 才需要远程处理。
- WQL 方言四铁律（`=`、外双内单、`%` 通配、双反斜杠）；`-Filter` 与 `-Query` 等价。
- 结果：`__` 系统属性 + `PSComputerName` 映射；日期是真 DateTime。
- 方法调用 = 先查实例再 `Invoke-CimMethod`；类结构用 `Get-CimClass` 预览；`Win32_Product` 慎用。

**动手实验**：① 查 `Win32_OperatingSystem` 的 `Caption` 与 `LastBootUpTime`，算开机天数（`(Get-Date) - $os.LastBootUpTime`）；② 用 `gm` 验证 `LastBootUpTime` 是 DateTime；③ `-Filter "DriveType=3"` 数本地盘，与 `Where-Object` 版对比计数；④ `Get-CimClass Win32_Process` 看 `CimClassMethods`，对自己进程 `Invoke-CimMethod GetOwner`；⑤ 故意在 `-Filter` 里写 `-eq` 看报错长什么样；⑥ 5.1 下跑 `Get-WmiObject Win32_OperatingSystem`（pwsh 7 跑不了，正好验证 14.2）。

实验参考：①`New-TimeSpan` 或直接相减都行，结果的 `.Days` 就是天数；⑤报错是"查询无效"一类，错误位置指向 `-Filter` 字符串——记住这个长相，它是 WQL 方言错的第一现场；⑥5.1 里同一属性用 `gm` 看是**字符串**（DMTF 格式），与 ② 的 DateTime 对比就是两代命令最直观的差异标本。

最后补一张"两代命令对照卡"（迁移老脚本时逐行替换）：

| 老（WMI 命令） | 新（CIM 命令） |
|---|---|
| `Get-WmiObject -Class X` | `Get-CimInstance -ClassName X` |
| `Get-WmiObject -List` | `Get-CimClass` |
| `$obj.Invoke()` / `$obj.GetOwner()` | `Invoke-CimMethod -InputObject $obj -MethodName GetOwner` |
| `[wmi]'\\server\root\cimv2:X=k'` | `Get-CimInstance -Query "SELECT * FROM X WHERE k=…"` |
| `-Amended`/`-Locale` 等参数 | 大多不再需要（默认行为更合理） |

替换时的一个陷阱：`Get-WmiObject` 的 `__SERVER` 改成了 `PSComputerName`，老脚本里按 `__SERVER` 分组的地方要一并改（两个属性在 CIM 结果里都存在，前者值恒有、后者本机为空——14.4 的实测结论）。

对应示例（可选）：`examples/14_cim/`——本机 CIM 直连免远程实证、WQL/Where 等价、DateTime 类型验证、GetOwner 方法调用、WMI 遗留命令的双引擎分岔。

---

本篇（三 远程与批量）其余各章：[13 远程处理](./13-remoting.md) · [15 后台作业](./15-jobs.md) · [16 多对象](./16-multiple-objects.md) · [17 安全](./17-security.md) · [18 会话](./18-sessions.md) · [19 高级远程](./19-advanced-remoting.md)

---

本篇（三 远程与批量）导航：[13 远程处理](./13-remoting.md) · [14 CIM](./14-cim.md) · [15 后台作业](./15-jobs.md) · [16 多对象](./16-multiple-objects.md) · [17 安全](./17-security.md) · [18 会话](./18-sessions.md) · [19 高级远程](./19-advanced-remoting.md)

本章全部断言不依赖 WinRM——本机直连走 COM（14.2 澄清），示例可随时双引擎复现。
