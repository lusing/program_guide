# 33 工具制作收官——一个完整项目的诞生

> 本章对应原书第 27 章"学无止境"的 Toolmaking 指路（原书说这需要"一整本书"——本章把它压缩成一个可运行的完整项目）。前 32 章的每块积木在这里拼成一件真东西：**InventoryModule，一个能被安装、被调用、被测试、被体检的模块**。

## 33.1 需求与设计（先想清楚再动手）

任务书（模拟真实委派）："给团队做个磁盘库存工具：能对多台机器查磁盘空闲比例、标记告警、能导出 CSV 给老板看和 JSON 给看板系统用。"

拆成设计三问：

1. **对外接口是什么？** 两个命令：`Get-InvMachineInfo`（取数+加工，接管道）与 `Export-InvReport`（落盘，双格式）。一个查一个存——单一职责（第 06 章的哲学在工具层重演）；
2. **每个命令的合同？** Get：`-ComputerName`（必选、接管道、string[]）、`-MinFreePct`（1..100，默认 10）、输出 pscustomobject（Machine/Drive/FreeRatio/Low）；Export：`-InputObject`（接管道）、`-Path`（必选）、`-Format`（ValidateSet Csv/Json）、支持 `-WhatIf`；
3. **失败时的样子？** 单机失联：警告流提示、其余机器照常（宽容+审计，第 26 章模式）。

三问答完，代码其实已经"写完"了——剩下的是把合同誊进语法。

## 33.2 实现：逐块对应前文

模块本体 `InventoryModule.psm1`（本章示例库里有完整可运行版，这里讲每个块对应哪章）：

```powershell
function Get-InvMachineInfo {
    [CmdletBinding()]                                    # ← 25 章：高级函数编制
    [OutputType([pscustomobject])]                       # ← 23 章：输出合同
    param(
        [Parameter(Mandatory, ValueFromPipeline)]        # ← 25 章：接管管道
        [string[]]$ComputerName,                         # ← 23 章：类型约束
        [ValidateRange(1, 100)]                          # ← 23 章：门口门禁
        [int]$MinFreePct = 10
    )
    process {                                            # ← 25 章：三段体的流式段
        foreach ($computer in $ComputerName) {
            try {                                        # ← 26 章：只保卫危险段
                Get-CimInstance -ClassName Win32_LogicalDisk -Filter 'DriveType=3' -ErrorAction Stop |
                    ForEach-Object {                     # ← 14 章：CIM 取数+左过滤
                        $freeRatio = if ($_.Size -gt 0) { [math]::Round($_.FreeSpace / $_.Size * 100, 0) } else { 0 }
                        [pscustomobject]@{               # ← 20/31 章：字面量造对象
                            Machine   = $computer
                            Drive     = $_.DeviceID
                            FreeRatio = $freeRatio
                            Low       = ($freeRatio -lt $MinFreePct)
                        }
                    }
            }
            catch { Write-Warning "无法查询 $computer：$($_.Exception.Message)" }   # ← 21 章：警告流
        }
    }
}
```

`Export-InvReport`（begin 收集、end 落盘、ShouldProcess 闸门、双格式分支）同模式展开。设计上值得点名的三个决定：

- **取数与导出分成两个命令**而不是一个大函数——调用方可以 `Get-InvMachineInfo | Where-Object Low | Export-InvReport` 自由组合（工具的"可组合性"是第 06 章管道哲学的作者侧兑现）；
- **分母防御**（`if ($_.Size -gt 0)`）——第 12 章的老纪律：除零会炸整条管道；
- **异常降级为警告**——单机故障不毁全局批处理，错误信息带着机器名进警告流。

## 33.3 装配：清单与验证

`New-ModuleManifest` 生成清单（27 章），`FunctionsToExport` 逐个列出（27.4 的纪律）。装配完成后的**验证流水线**正是 32 章的三层防线：

```
Test-ModuleManifest           # 清单合法
Invoke-ScriptAnalyzer .psm1   # 代码体检（Error 级零诊断）
Invoke-Pester -PassThru       # 行为回归（8 个 It 全绿）
```

测试文件 `InventoryModule.Tests.ps1` 的覆盖策略值得一读：**正常路径**（管道取数产出四列对象）、**极端参数**（阈值 100 全标记 Low、阈值 1 零标记——第 32 章"把断言变成确定性"的手法）、**往返**（CSV/JSON 导出再读回行数守恒）、**防护**（-WhatIf 不落盘）。八条 It 就是这个工具的**行为合同全文**——将来任何人改坏任何一行，红灯会指出违反了哪条合同。

## 33.4 部署：从模块到"每天自动跑"

工具做完到"在团队里活着"，最后三步：

**分发**：复制到用户的模块目录（或 `Publish-Module` 进私有源）——从此 `Get-InvMachineInfo` 直接敲（自动加载，第 07 章）。

**定时化**：一条命令注册计划任务（第 22 章的预告兑现）：

```powershell
$action  = New-ScheduledTaskAction -Execute 'pwsh.exe' `
    -Argument '-NoProfile -ExecutionPolicy Bypass -File C:\Ops\daily-inventory.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At 7am
Register-ScheduledTask -TaskName 'DailyInventory' -Action $action -Trigger $trigger
```

而 `daily-inventory.ps1` 只有六行（工具化的意义：复杂度进了模块，脚本只是"装配线"）：

```powershell
try {
    Get-Content C:\Ops\servers.txt | Get-InvMachineInfo -MinFreePct 15 |
        Export-InvReport -Path "C:\Reports\inv-$(Get-Date -Format yyyyMMdd).csv"
    exit 0
}
catch { Write-Error $_; exit 1 }        # 26 章：退出码对 CI/计划任务汇报
```

**监控**：计划任务看退出码（非零=失败）；CSV 的 `Low` 列喂给看板；想更主动就把"有 Low 行"时发邮件/写事件日志加进脚本。

## 33.5 项目复盘：三十三条章的使用索引

这个项目动用的知识，按"如果不会 X 章就会在哪卡住"倒排：

| 卡点 | 对应章 |
|---|---|
| 结果对象怎么造、列怎么算 | 08（对象）/20（哈希表字面量） |
| 多机器怎么喂、怎么流式 | 09（绑定）/25（三段体） |
| 数据从哪来、怎么左过滤 | 14（CIM）/11（过滤） |
| 单机坏了怎么办、脚本怎么收场 | 26（错误处理） |
| 别人怎么"安装"它 | 27（模块） |
| 改了之后怎么知道没改坏 | 32（测试+体检） |
| 定时跑、退出码 | 22（脚本）+ 计划任务 |
| 给人看的报告、给系统的 JSON | 06/31（格式分流） |

对照第 01 章的三层读者：这个项目让你从"使用者"（1–19 章）走到了"工具制作者"（20–33 章）——**原书第 27 章说"需要一整本书"的部分，你已经用一章 + 前面 32 章的地基走完了主干**。

## 33.5.1 版本化与团队协作：工具的"运维期"

项目上线只是开始，工具进入**运维期**后的三个动作（个人工具长大成团队资产的路）：

**版本纪律**：每次发布前 `ModuleVersion` 按语义递增（27 章的 SemVer 表）；**破坏性变更（改参数名、改输出列）必须升主号**，并在注释帮助的 `.NOTES` 里写迁移提示——"2.0 把 ComputerName 改成了 MachineName"一句话，能省用户半天。

**变更防护**：团队仓库上把 33.3 的验证流水线挂进 CI（GitHub Actions / Azure Pipelines 的 PowerShell 任务跑 `Invoke-Pester` 与 `Invoke-ScriptAnalyzer`），**红灯禁止合并**——个人时期的"自律"升级为团队时期的"门禁"。

**弃用节奏**：要淘汰旧函数时，先在帮助里标 `.NOTES 已弃用，请改用 X`、保留两个版本过渡一两个周期，再在下个主号删除——直接删是最快让同事恨你的方式。

这套"运维期"动作与写代码无关，与**人和信任**有关——Toolmaking 的最后一课：工具是给别人用的，**别人的信任是你的接口**。

## 33.6 学无止境：下一站地图（自包含版）

原书末章指的"进一步方向"，逐个翻译成"它是什么、什么时候需要、从哪入手"：

| 方向 | 是什么 | 何时需要 | 入口 |
|---|---|---|---|
| **DSC**（Desired State Configuration） | 声明式配置管理："机器应该长这样"的幂等引擎 | 机群规模化配置漂移治理 | `about_DesiredStateConfiguration`；注意社区主推 DSC v3 |
| **JEA** | 受限端点体系（19 章画像的工业版） | 给一线人员最小权限运维入口 | `about_JEA` |
| **Graph / Az 模块** | 微软云的官方 PowerShell 面 | 管 Microsoft 365 / Azure | 各自官方文档 |
| **SecretManagement** | 凭据保险库统一接口 | 脚本要管密码/密钥 | `about_SecretManagement` |
| **工作流** | ~~并行编排~~ | **已废弃**（pwsh 7 移除）——见到老代码认得即可 | —— |
| **社区生态** | PSFramework、Pode、dbatools…… | 站在巨人肩上 | PowerShell Gallery + PowerShell.org |

选下一站的判断法：**回到你的真实痛点**——机群配置乱学 DSC、权限放不开学 JEA、上了云学 Graph/Az。工具人的成长路径不是学完清单，而是每个痛点出现时你已经知道"这有个名字、从哪查"。

## 33.6.1 项目文件走读：每一件为什么存在

收官项目的最终文件清单与存在理由（对照示例库 `examples/33_toolmaking/`）：

```
InventoryModule.psm1            # 本体：两个高级函数 + Export-ModuleMember 闸门
InventoryModule.Tests.ps1       # 行为合同：8 条 It（正常/极端/往返/防护）
run.ps1                         # 装配线：临时目录组装模块 → 全链验证 → 清理
（构建期生成）InventoryModule.psd1   # 清单：New-ModuleManifest 产物（版本/导出面/依赖）
```

三件"有意缺席"的东西同样值得说：

- **没有 `lib.ps1`**——函数库阶段（第 24 章）已过，直接以模块形态起步；
- **没有格式化/类型文件**（`*.format.ps1xml`）——输出列少，默认渲染够用（第 10 章的作者侧入口在"列多到难看"时才引入，YAGNI）；
- **没有安装脚本**——分发是复制目录或 Publish-Module（27 章），不自己发明安装器。

这份"存在的清单 + 缺席的理由"就是本章的架构决策记录（ADR 的微缩版）：**工具的形状是拒绝出来的，不是堆出来的**。

## 33.7 本章要点

- 项目四拍：**设计三问（接口/合同/失败形态）→ 实现（逐块对应 08/14/20–26 章）→ 装配验证（清单+三层防线）→ 部署（分发/计划任务/退出码监控）**。
- 取数与导出分命令=可组合性；分母防御与异常降级=健壮性的两个小钉子。
- 六行的调度脚本装下全部复杂度——**模块吃复杂度，脚本做装配**，这就是 Toolmaking 的本质。
- 复盘表=33 章的使用索引；下一站按真实痛点选（DSC/JEA/云/Secret），工作流已废弃。

## 33.8 全教程的最后一图：能力地图

34 章走完，把获得的全部能力按"读者分层"摆一遍（也是本教程目录的另一种读法）：

```
使用者层（01–12）：查帮助 → 跑命令 → 管驱动器 → 组管道 →
                  读对象 → 绑参数 → 控格式 → 过滤比较 → 综合实战
管理员层（13–19）：远程扇出 → CIM 仓库 → 后台作业 → 批量并行 →
                  安全策略 → 持久会话 → 端点/SSH
作者层　（20–33）：变量容器 → 流与 IO → 脚本 → 参数合同 →
                  函数 → 高级函数 → 错误处理 → 模块 → 正则 →
                  技巧 → 改造他人代码 → 类型与 JSON → 测试 → 收官项目
速查层　（34）：　 标点/运算符/任务/坑位/双引擎 五张表
```

三层之间不是"学完一层才能上楼"，而是**随时横向打通**：作者层的每个决定都在给使用者层供货（第 09 章的绑定规则、第 10 章的格式系统）；管理员层的每个通道都可能是作者层的部署目标（33.4 的计划任务）。教程到此收官，而**这张地图的空白处，就是 33.6 指给你的下一站**。

**动手实验**：① 跑通示例库的 `examples/33_toolmaking/`（模块装配→取数→双格式→WhatIf→Pester→Analyzer 全链）；② 把 `MinFreePct` 的默认值从 10 改成 20，跑 Pester 看哪些条款还绿、为什么全绿（合同没变）；③ 给 `Get-InvMachineInfo` 加一个 `-DriveType` 参数（默认 3），补两条测试条款；④ 按 33.4 注册一个每天 7 点的计划任务（自己的实验机），第二天早上看报告文件；⑤ 把 33.6 表里最贴近你痛点的一项查一遍 about 主题。

实验参考：②全绿的原因：测试断言的是行为合同（阈值参数的**效果**），不是实现细节——这正是好测试的标志；③提示：参数加 `[ValidateSet(2,3,4)]` 再配一条"非法值应抛错"的 It。

对应示例（可选）：`examples/33_toolmaking/`——收官项目全件套：`InventoryModule.psm1`（模块本体）、`InventoryModule.Tests.ps1`（八条合同）、`run.ps1`（装配-验证-清理流水线，双通道全绿）。

---

本篇（六 进阶收官）其余各章：[31 类与 JSON](./31-classes.md) · [32 测试](./32-testing.md) · [34 备忘清单](./34-cheatsheet.md)

实验参考：②测试全绿说明合同稳定；④第二天看文件名日期戳与内容行数即可自证运行。

---

本篇（六 进阶收官）导航：[31 类与 JSON](./31-classes.md) · [32 测试](./32-testing.md) · [33 工具制作收官](./33-toolmaking.md) · [34 备忘清单](./34-cheatsheet.md)

示例库的 run.ps1 就是本章流水线的可执行版；下一章 34 把全书压成五张速查表。
