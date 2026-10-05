# 25 高级函数——CmdletBinding 全解与管道函数

> 本章是扩充章（原书第 27 章指路清单的核心项）。第 23 章给脚本加过 `[CmdletBinding()]`；本章把它在**函数**上的全部威力展开：三段式执行体、管道输入绑定、ShouldProcess——写完本章，你的函数与微软编译的 Cmdlet 在使用体验上没有区别。

## 25.1 CmdletBinding 的完整选项

```powershell
function Set-InvService {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param( … )
    …
}
```

常用选项三个：**`SupportsShouldProcess`**（免费获得 `-WhatIf`/`-Confirm`，见 25.4）；**`ConfirmImpact`**（'High' 时调用默认要确认——"高危操作该问一句"的声明式写法）；**`DefaultParameterSetName`**（多参数集时的默认分支，参数集语法 `Parameter(Mandatory, ParameterSetName='ByName')]` 与第 03 章的语法图概念同源）。加上它，函数名进入 `Get-Command` 时与 Cmdlet 同列一档——**"高级函数"（advanced function）是 PowerShell 给自制工具的最高编制**。

## 25.2 三段体：begin / process / end

普通函数的主体是一整块；高级函数可以拆成**三段**：

```powershell
function Get-TopN {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]    # 没有它，管道对象根本进不来（实测教训）
        [int]$Item,
        [int]$N = 2
    )
    begin {
        $items = @()          # ① 一次性准备（第一个对象到来前）
        "begin：初始化" | Write-Verbose
    }
    process {
        $items += $Item       # ② 每个对象跑一次（参数收到当前对象）
        "process：收到 $Item" | Write-Verbose
    }
    end {
        $items | Sort-Object -Descending | Select-Object -First $N   # ③ 收尾（全部对象处理后）
        "end：共 $($items.Count) 项" | Write-Verbose
    }
}
```

三段的执行时机是理解一切的关键：

| 段 | 执行次数 | 时机 | 适合放什么 |
|---|---|---|---|
| `begin` | 1 次 | 管道开始，第一个对象**之前** | 连接建立、计数器清零、表头 |
| `process` | **每对象 1 次** | 每个对象流到时 | 对该对象的处理（**经绑定参数**取对象——函数的 process 里 `$_` 没有定义，那是 `ForEach-Object` 脚本块的专利） |
| `end` | 1 次 | 管道结束，最后对象**之后** | 汇总输出、关闭连接 |

普通主体（没有三段）等价于"只有 process 且整体跑一次"——**不带管道输入的函数用普通主体；接管道的必须三段**，否则你会掉进"只处理了最后一个对象"或"每对象都重复初始化"的经典坑。

## 25.3 接管管道：ValueFromPipeline

三段体要有对象可处理，参数得声明"我从管道接"：

```powershell
function Get-FileSizeKB {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]              # 整对象按值（第 09 章 ByValue）
        [System.IO.FileInfo]$File,

        [Parameter(ValueFromPipelineByPropertyName = $true)] # 按属性名（第 09 章 ByPropertyName）
        [string]$Name
    )
    process {
        if ($File) { "{0} = {1} KB" -f $File.Name, [math]::Round($File.Length / 1KB, 0) }
    }
}
Get-ChildItem *.log | Get-FileSizeKB        # FileInfo 整对象按值进来，每个跑一遍 process
```

机制正是第 09 章的参数绑定：引擎对**每一个**流经对象做一次绑定，然后调用一次你的 process。所以第 09 章的判据（类型吻合、属性同名、改名桥接、开盒）在这里全部适用——**你现在是"接收端"的作者**，定义别人能怎么把数据喂给你。

设计准则一句话：**要么全流式（process 里逐个输出），要么别假装**。process 段逐对象处理、逐对象输出，函数就与 `Where-Object`、`ForEach-Object` 一样是流式的（第 06 章的内存观）；把对象攒到 end 再一起输出（如 Get-TopN 这种"必须看全"的场景）则是缓冲型——两种都合法，**别做"半吊子"（process 里攒但输出时机不对）**。

## 25.4 ShouldProcess：-WhatIf 的正规接线

`SupportsShouldProcess = $true` 只是把两个参数"接进来了"，真正让它们生效要**在变更点调用**：

```powershell
function Remove-InvTempFiles {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param([string[]]$Path)
    process {
        foreach ($p in $Path) {
            if ($PSCmdlet.ShouldProcess($p, '删除临时文件')) {   # ← 干跑/确认的闸门
                Remove-Item -Path $p
            }
        }
    }
}
Remove-InvTempFiles -Path 'C:\Temp\x.log' -WhatIf     # What if: 正在对目标 … 执行操作"删除临时文件"
```

`$PSCmdlet.ShouldProcess(目标, 动作)` 的行为随调用方式变：普通调用返回 `$true`（放行）；`-WhatIf` 打印"What if: …"并返回 `$false`（拦下）；`-Confirm` 弹确认问句。**把每个变更点都包进 ShouldProcess** 是工具作者的职业操守——用户拿 `-WhatIf` 预演（第 16 章安全带）的底气来自你接的这根线。姊妹方法 `ShouldContinue()`（无条件弹问，用于"你确定吗"类二次确认）不受 -WhatIf 影响，分工明确。

## 25.5 一段完整的管道函数（本章成品）

把全部要素装进一个像样的工具——"从管道收机器名，逐台查盘，流式输出"：

```powershell
function Get-InvDiskInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]$ComputerName,          # 按值接管道；string[] 让单个值也能直接传

        [ValidateRange(1, 100)]
        [int]$MinFreePct = 10
    )
    begin { $n = 0 }
    process {
        foreach ($c in $ComputerName) {
            $n++
            Get-CimInstance -ClassName Win32_LogicalDisk -ComputerName $c -Filter 'DriveType=3' -ErrorAction SilentlyContinue |
                ForEach-Object {
                    [pscustomobject]@{
                        Machine   = $c
                        Drive     = $_.DeviceID
                        FreeRatio = [math]::Round($_.FreeSpace / $_.Size * 100, 0)
                        Low       = ($_.FreeSpace / $_.Size * 100) -lt $MinFreePct
                    }
                }
        }
    }
    end { "共处理 $n 台机器" | Write-Verbose }
}
'srv1', 'srv2' | Get-InvDiskInfo -MinFreePct 20 -Verbose
```

逐行看设计：`ValueFromPipeline` 接管道、类型 `string[]` 兼容单值直传（内部 foreach 展开）；begin 计数、process 逐台输出（流式）、end 报 verbose；输出 `[pscustomobject]`（与 OutputType 声明一致）；`-ErrorAction SilentlyContinue` 让单台失联不炸全局（26 章细讲）。这个函数能被 `| Where-Object`、`| Sort-Object`、`| Export-Csv` 无缝续接——**它就是一个 Cmdlet**。

## 25.6 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| 管道喂入只处理了最后一个对象 | 没写 process 段（普通主体只跑一次） | 接管道必用三段体 |
| 每个对象都重复"初始化" | 初始化写在 process 里 | 挪进 begin |
| `$_` 在 begin/end 里拿不到 | `$_` 只在 process 段有含义 | 需要累计就在 process 里存变量 |
| `-WhatIf` 没效果 | 只声明了 SupportsShouldProcess，没调 ShouldProcess | 每个变更点包 `if ($PSCmdlet.ShouldProcess(...))` |
| 函数输出乱序混入进度 | process 里 Write-Host 混用 | 数据走输出，解说走 Verbose/Information（21 章） |
| 递归/内嵌管道把 $_ 弄混 | 嵌套管道里 $_ 指内层对象 | 内层用 `$PSItem` 或具名变量区分 |
| 管道绑定不触发 | 参数没声明 ValueFromPipeline* | 绑定判据回第 09 章两查动作 |

## 25.6.1 与 Cmdlet 的最后差距：两个进阶选项

高级函数已覆盖 Cmdlet 的九成体验，剩下的一成里有两个值得认识的选项：

**参数集（ParameterSetName）**——一个函数提供多种"用法入口"（第 03 章语法图的作者侧）：

```powershell
function Get-InvMachine {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$Name,

        [Parameter(Mandatory, ParameterSetName = 'ByIP')]
        [System.Net.IPAddress]$IPAddress
    )
    # 引擎保证同一时刻只有一个参数集生效——Name 和 IPAddress 互斥
}
```

声明后 `Get-Command` 的语法图自动出现两段（回忆第 03 章"SYNTAX 出现两次"）——你在帮助里见过的多段语法，作者侧就是这么写的。规则：跨集互斥、`DefaultParameterSetName` 兜底、`$PSCmdlet.ParameterSetName` 在函数体内告诉你当前走哪条路。

**SupportsPaging**——`-First/-Skip/-IncludeTotalCount` 一键获得（大数据集分页遍历的礼貌接口），声明即用，此处不展开（`help about_Functions_CmdletBindingAttribute`）。

## 25.7 本章要点

- 高级函数 = `[CmdletBinding()]` + 三段体（**begin 一次 / process 每对象 / end 一次**）。
- `ValueFromPipeline`/`ValueFromPipelineByPropertyName` 让函数接管管道——第 09 章绑定规则的使用者视角。
- `SupportsShouldProcess` + **每个变更点 `ShouldProcess()`** = 正规的 -WhatIf/-Confirm；`ConfirmImpact='High'` 声明高危。
- 设计准则：**要么全流式，要么明确缓冲**；输出对象 + OutputType 合同；数据与解说分流。
- 25.5 的模板是"自制 Cmdlet"的完整样张，第 27 章把它打包、第 33 章把它产品化。

**动手实验**：① 写 `Get-TopN`（三段体）喂 `1..10`，`-Verbose` 观察 begin/process/end 的执行序；② 给它加 `ValueFromPipeline`，验证 `1..5 | Get-TopN -N 3`；③ 故意删掉 process 段改普通主体，复现"只处理最后一个"；④ 写 `Remove-InvTempFiles` 完整接线 ShouldProcess，`-WhatIf` 与 `-Confirm` 各试一次；⑤ 把 25.5 的 `Get-InvDiskInfo` 存成 .ps1 点源后接 `| Where-Object Low`。

实验参考：①verbose 输出顺序是 begin → process×N → end，process 里对象按管道顺序；③普通主体版 `Get-TopN` 会只对**最后一个**对象输出/或整块执行一次——具体症状取决于你怎么写，但"流式语义丢失"是共性。

对应示例（可选）：`examples/25_advanced_functions/`——三段体执行序、ValueFromPipeline 双通道（整对象/按属性名）、ShouldProcess 干跑拦截、begin 计数与流式输出。

---

本篇（五 工具制作）其余各章：[24 函数](./24-functions.md) · [26 错误处理](./26-error-handling.md) · [27 模块开发](./27-modules-dev.md) · [28 正则](./28-regex.md) · [29 技巧](./29-tips.md) · [30 他人脚本](./30-others-scripts.md)

---

本篇（五 工具制作）导航：[24 函数](./24-functions.md) · [25 高级函数](./25-advanced-functions.md) · [26 错误处理](./26-error-handling.md) · [27 模块开发](./27-modules-dev.md) · [28 正则](./28-regex.md) · [29 技巧](./29-tips.md) · [30 他人脚本](./30-others-scripts.md)

实验参考：①verbose 顺序是 begin→process×N→end；③普通主体版表现为"管道对象无处绑定"的报错或只跑一次——流式语义丢失的两种面孔。
