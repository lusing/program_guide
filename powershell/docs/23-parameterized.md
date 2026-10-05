# 23 优化可传参脚本——验证、帮助与高级形态

> 本章对应原书第 22 章"优化可传参脚本"。上一章的脚本已经能接参数；本章把它升级成**"别人也能放心用"的工具**：参数自带说明书、非法输入在门口就被拦下、一行注解换来一整套 Cmdlet 级特性。

## 23.1 起点：一个带说明书的脚本

先给出本章的起点版本（原书代码清单 22.1 的现代化改写，注释帮助是最大亮点）：

```powershell
<#
.SYNOPSIS
Get-DiskInventory 从一台或多台计算机取逻辑磁盘信息。
.DESCRIPTION
通过 CIM 查询 Win32_LogicalDisk 实例，输出盘符、空闲与总量、空闲比例。
.PARAMETER ComputerName
要查询的计算机名（可多个），默认本机。
.PARAMETER DriveType
驱动器类型（3=固定磁盘，默认；详见 Win32_LogicalDisk 文档）。
.EXAMPLE
.\Get-DiskInventory.ps1 -ComputerName SERVER-R2 -DriveType 3
#>
param (
    [string]$ComputerName = 'localhost',
    [int]$DriveType = 3
)
Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $ComputerName -Filter "DriveType=$DriveType" |
    Sort-Object -Property DeviceID |
    Select-Object DeviceID,
        @{ Name = '空闲(GB)'; Expression = { [math]::Round($_.FreeSpace / 1GB, 1) } },
        @{ Name = '总量(GB)'; Expression = { [math]::Round($_.Size / 1GB, 1) } }
```

两个设计决策值得先吃透：

**输出对象，不输出格式**。末段用 `Select-Object` 而不是 `Format-Table`——脚本输出的应该是**数据**，格式化留给调用者（`.\Get-DiskInventory.ps1 | Format-Table`、`| Export-Csv` 各取所需）。原书的理由一针见血：脚本若输出格式化结果，想接管道/导 CSV 的用户就**被你掐断了后路**。第 10 章"格式化是出口"的纪律在脚本层的落实。

**注释帮助（comment-based help）就是脚本的说明书**。`<# .SYNOPSIS … #>` 块写在脚本开头，`Get-Help .\Get-DiskInventory.ps1` 立刻能读到——**离线、随文件走、不用额外文档**。可用的段落：`.SYNOPSIS`（一句话）、`.DESCRIPTION`（详情）、`.PARAMETER 名字`（每参数一段）、`.EXAMPLE`（示例，可多段）、`.NOTES`、`.LINK`。VS Code 里把这段补全是写脚本的固定动作。

## 23.2 一行注解的奇迹：[CmdletBinding()]

在 `param()` 前面加**一行**：

```powershell
[CmdletBinding()]
param ( … )
```

脚本立刻升格为**高级脚本**（advanced script）——免费获得 Cmdlet 级的一整套能力：

1. **通用参数自动出现**：`-Verbose`、`-Debug`、`-ErrorAction`、`-ErrorVariable`、`-OutVariable`……（第 03 章预告的八件套，不用写一行就有了）；
2. **缺必选参数会礼貌提示**：配合 `[Parameter(Mandatory)]`，交互式 Shell 里会问"请提供 ComputerName"（无人值守则直接报错，第 21 章的行为）；
3. **`-WhatIf/-Confirm` 接口就绪**：声明 `SupportsShouldProcess` 后变更类脚本免费获得干跑能力（第 25 章在函数里正式讲）；
4. **帮助与补全升级**：Tab 补全、`Get-Help` 的参数节都按 Cmdlet 规格渲染。

这一行是"脚本"与"工具"的分水岭——**所有正式脚本都该有它**（本教程从本章起默认带上）。

## 23.3 必选与默认值的设计

```powershell
param (
    [Parameter(Mandatory = $true)]
    [string]$ComputerName,          # 必选：不给就提示/报错

    [string]$LogPath = (Join-Path $env:TEMP 'inventory.log'),   # 默认值可以是表达式！

    [string[]]$Servers = @()        # 数组参数默认空数组
)
```

三个设计要点：**能给默认值就给默认值**（80% 场景的用户不该被逼着敲参数）；**默认值可以是任意表达式**（`$env:TEMP`、`Get-Date`、甚至函数调用——求值发生在参数绑定时刻）；**必选参数宁少勿滥**（每加一个必选，使用门槛高一层）。

判断"必选还是默认"的口诀：**没有合理默认值的才必选**（比如"要操作哪台机器"没有万金油答案），有合理缺省的（端口、路径、阈值）一律给默认。

## 23.4 验证属性：把非法输入拦在门口

参数声明的方括号可以叠一串**验证属性**，非法值在**函数体执行前**就被拒绝：

```powershell
param (
    [ValidateSet('Development', 'Test', 'Production')]
    [string]$Environment = 'Test',            # 只许三选一

    [ValidateRange(1, 100)]
    [int]$Threshold = 20,                     # 数值界内

    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$Date,                            # 正则把关

    [ValidateNotNullOrEmpty()]
    [string]$Name,                            # 空串/null 不行

    [ValidateScript({ Test-Path $_ })]
    [string]$Path,                            # 任意脚本判据（$_ 是候选值）

    [AllowEmptyString()]
    [string]$Remark = ''                      # 显式开绿灯：允许空
)
```

报错形态统一：`ParameterBindingValidationException`，消息里写明参数名与原因——**错误发生在绑定阶段，函数体一行没跑**，不会出现"跑到一半留下半成品状态"。选型：固定选项用 `ValidateSet`（还免费获得 Tab 补全枚举值）；数值界用 `ValidateRange`；格式用 `ValidatePattern`；其余一切用 `ValidateScript` 兜底。验证属性 + 类型约束（`[int]` 连 "abc" 都进不来）共同构成参数的"门禁系统"。

## 23.5 $PSBoundParameters 与 [OutputType]

两个小而实用的收尾件：

**`$PSBoundParameters`**：字典，装着"调用者实际给了哪些参数"。经典用途——默认值填空的参数不进字典，可以据此判断"用户是真的想要默认，还是没说"：

```powershell
if ($PSBoundParameters.ContainsKey('Threshold')) { "用户显式给了阈值 $Threshold" }
```

（第 25 章高级函数里它还有 `$PSCmdlet` 联动的进阶用法。）

**`[OutputType([string])]`**：声明在 param 之前，告诉世界"这个脚本/函数输出什么类型"。它**不做任何强制**（纯声明），但 `Get-Command -Syntax`、IDE 补全、以及读代码的人都受益——工具的"输出合同"。

## 23.6 完整模板（本章成品）

把全部要素装订成模板（可直接当新脚本的起点，也是第 24/25 章函数版的底稿）：

```powershell
<#
.SYNOPSIS
一句话说明。
.DESCRIPTION
详细说明。
.PARAMETER Name
参数说明。
.EXAMPLE
调用示例。
#>
#Requires -Version 5.1
[CmdletBinding()]
[OutputType([pscustomobject])]
param (
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$Name,

    [ValidateRange(1, 100)]
    [int]$Threshold = 20
)
Set-StrictMode -Version Latest
# …… 主体（输出对象，不格式化）……
```

**顺序是实测出来的硬规则**：注释帮助块必须**真正的文件第一行**——`#Requires` 或任何普通行注释放在它前面，帮助识别都会失效（`Get-Help` 只给自动语法）。模板的头部四件按上图排序：**帮助 → Requires → CmdletBinding → OutputType → param**；param 内两件：必选+非空、验证+默认；主体第一行 `Set-StrictMode`（第 20 章）。照这个模板写，你的脚本已经具备微软官方命令的全部"表面工程"。

## 23.7 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| 注释帮助读不到 | 块没放在脚本开头 / 关键字拼错（`.SYNOPSIS`）/**文件第一行还有普通行注释**（实测：帮助块必须开门见山，前面任何行注释都会让它不被识别） | `<# #>` 放文件第一行；`#Requires` 之类的行注释挪到帮助块之后 |
| `Mandatory` 提示把 CI 卡死 | 无人值守时提示变报错是**设计** | CI 必须显式传参；或给默认值 |
| 验证报错难定位 | 不认识 ParameterBindingValidationException | 认准这个异常名=门口拦截，看消息里的参数名 |
| `ValidateScript` 里用 `$_` 拿错对象 | `$_` 是**候选参数值**（不是管道对象） | 脚本判据里把 `$_` 当"待验值"读 |
| 默认值"过期" | 表达式在**绑定时刻**求值，时间/路径类默认每次调用重算 | 了解时机即可，这通常正是你要的 |
| 输出被 Format-* 污染 | 脚本末尾手痒加了 Format-Table | 输出对象，格式化交给调用者 |
| 参数默认值想引用另一个参数 | param 块内不能互相引用 | 主体里 `if (-not $PSBoundParameters.ContainsKey('B')) { $B = $A }` |

## 23.7.1 从模板到工具：还差三步

23.6 的模板已经让脚本"长得像命令"，到"是工具"还差三步——每步是后续一章的入场券：

1. **装进函数**（24 章）：脚本 → `function Get-X { … }`，多个函数进一个库文件，随点源随用；
2. **接上管道**（25 章）：`[Parameter(ValueFromPipeline)]` + begin/process/end，让 `Get-X | 过滤 | 排序` 成为可能——工具与脚本的本质分界就是**能不能被管道**；
3. **处理错误**（26 章）：用户传错机器名时优雅地报告并 `exit 1`，而不是喷一屏红字——工具的可信度来自它失败时的样子。

记住这个"差三步"的清单，读下一篇时你会清楚每一章在补哪块拼图。

## 23.8 本章要点

- 脚本三升级：**注释帮助（随身说明书）→ `[CmdletBinding()]`（Cmdlet 级表面）→ 验证属性（门口门禁）**。
- 输出**对象**不输出格式——把呈现权留给调用者（`| Format-Table` / `| Export-Csv`）。
- 参数设计：默认值优先（可用表达式）、必选克制、类型+验证双层把关、`$PSBoundParameters` 区分"给了/没给"。
- `[OutputType()]` 是输出合同（纯声明）；23.6 模板=新脚本起点。

**动手实验**：① 把 23.1 起点脚本按模板升级：加 CmdletBinding、必选 ComputerName、`[ValidateSet(3,4)]` 的 DriveType、注释帮助补全，`Get-Help .\Get-DiskInventory.ps1` 验证；② 传非法 `DriveType 9` 看门口拦截的报错长相；③ 不传必选参数在交互与 `-NonInteractive` 两种模式下各试一次；④ 给脚本故意加回 `Format-Table`，然后 `.\x.ps1 | Export-Csv t.csv` 体会"被掐断的后路"；⑤ `$PSBoundParameters.ContainsKey` 做一个"用户显式给了阈值才打印提示"的小实验。

实验参考：②异常名含 `ParameterBindingValidationException`，错误**发生在任何主体代码执行前**；③非交互模式报"无法提示用户提供参数"——与第 21 章 Read-Host 的报错同族，都是"无人值守拒绝等待"的设计；④CSV 里出现 `Microsoft.PowerShell.Commands.Internal.Format...` 类的列——第 10 章"Format 产出指令"的实锤。

对应示例（可选）：`examples/23_parameterized/`——注释帮助可读、CmdletBinding 免费通用参数、ValidateSet/Range 门口拦截、Mandatory 非交互报错、`$PSBoundParameters` 判定（由 asset-adv.ps1 配合完成）。

---

本篇（四 语言核心）其余各章：[20 变量](./20-variables.md) · [21 输入输出](./21-io-streams.md) · [22 第一个脚本](./22-first-script.md)

本章配套示例的每条断言都对应正文一节，可对照阅读。

---

本篇（四 语言核心）导航：[20 变量](./20-variables.md) · [21 输入输出](./21-io-streams.md) · [22 第一个脚本](./22-first-script.md) · [23 参数化](./23-parameterized.md)

模板的六个要素（帮助、Requires、CmdletBinding、OutputType、验证、StrictMode）在示例 asset-adv.ps1 里逐条可查。
