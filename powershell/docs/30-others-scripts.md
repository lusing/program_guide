# 30 使用他人的脚本——阅读、审计与改造

> 本章对应原书第 26 章"使用他人的脚本"。真实工作里你写的第一段生产力脚本，多半是从网上抄来改的——这没什么不好，**"能快速看懂别人的脚本"是核心技能**。原书请两位社区作者故意提供了"带毛病的真实脚本"，本章保留这个精神：给你一份典型病脚本的完整剖析流程，方法论自包含。

## 30.1 五步阅读法：从外到内

拿到任何陌生脚本，按这个顺序读（每步都有工具支撑）：

1. **读头**：注释帮助（`.SYNOPSIS`）与头部注释——作者自己说它是什么；
2. **读 param 块**：它要什么输入（类型、默认值、必选项）——**输入清楚了，一半语义就清楚了**；
3. **读主流程骨架**：只看命令的**动词**——Get 取了什么、Set 改了什么、Remove 删了什么、管道怎么接——先无视所有 if/循环细节；
4. **回头看分支**：主流程懂了再啃 if/switch/try——它们只是"主流程的岔路"；
5. **跑前干演**：`-WhatIf` 干跑、或把变更命令临时注释掉跑一遍——用行为验证理解。

这套方法的本质：**先抓"做什么"，再抓"怎么做"**。读代码卡住的常见原因不是语法，而是没先建立"这份代码想完成什么"的框架。

## 30.2 案例剖析：一份典型病脚本

下面这份脚本浓缩了网上脚本的三大常见病（改编自原书案例的通用化版本，IIS 依赖已移除）。先自己按五步法读一遍，再看剖析：

```powershell
param (
    [string]$Path,
    [string]$LogPath = "C:\logs\cleanup.log",
    [string]$TempPath = "C:\temp",
    [int]$RetentionDays = 30,
    [string[]]$Exclude = @("keep"),
    [switch]$WhatIfLocal
)
if (-not $Path) { $Path = "C:\inetpub\logs" }
$files = Get-ChildItem -Path $Path -Recurse
foreach ($file in $files) {
    if ($Exclude -contains $file.Name) { continue }
    if ($file.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays)) {
        Remove-Item $file.FullName -Recurse -Force
    }
}
Write-Host "Done!"
```

**五步走读**：头（无帮助注释——第一印象分扣掉）；param（六参，`$Path` 无默认值却在体内补救——参数设计混乱的信号）；骨架（Get-ChildItem 取文件 → foreach 逐个 → 条件 → Remove-Item 删——这是"过期文件清理器"）；分支（Exclude 跳过、按保留期判断）；干演（不敢直接跑——见下）。

**三病确诊**：

1. **过度参数化 + 硬编码**：`$LogPath`、`$TempPath` 声明了却**从没用到**（死参数）；而真正该参数化的 `$Path` 却在体内硬编码兜底——参数面与实际需求脱节；
2. **无变更防护**：`Remove-Item -Recurse -Force` 直接上，没有 `-WhatIf` 支持（那个 `$WhatIfLocal` 开关声明了也没用——又一个死参数），没有确认环节；
3. **无错误处理与输出**：目录不存在会红字中断；结尾 `Write-Host "Done!"` 与实际结果无关（删了多少？失败了几个？一概不知）。

**修复版**长什么样（对照着读，每一处修改都对应上面的病）：

```powershell
<#
.SYNOPSIS
Remove-OldFiles 删除超过保留期的文件。
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ })]
    [string]$Path,

    [ValidateRange(1, 3650)]
    [int]$RetentionDays = 30,

    [string[]]$Exclude = @()
)
$removed = 0
Get-ChildItem -Path $Path -File -Recurse |
    Where-Object { $Exclude -notcontains $_.Name } |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$RetentionDays) } |
    ForEach-Object {
        if ($PSCmdlet.ShouldProcess($_.FullName, '删除过期文件')) {
            Remove-Item -Path $_.FullName -Force
            $removed++
        }
    }
[pscustomobject]@{ Path = $Path; Removed = $removed; At = Get-Date }
```

修复清单逐条对应：死参数删掉、`$Path` 转正为必选+存在性验证（`ValidateScript`）、管道三段式替代 foreach（流式+可读）、**ShouldProcess 接线**（`-WhatIf`/`-Confirm` 真的生效）、输出**结果对象**（调用方能知道发生了什么）——第 23/25 章的全部规范在"改造"场景下的总演习。

## 30.3 遇到没学过的语法怎么办

读别人脚本必然撞见陌生语法（`[Parameter(...)]`、`$using:`、`[Scriptblock]`、特殊变量）。三条消化路径：

1. **查 about 主题**：`help about_*` 列表里按关键词找（`about_Parameters`、`about_Scopes`、`about_Automatic_Variables`）——语法级问题 90% 有官方短文；
2. **Get-Command 验身份**：不认识的命令 `Get-Command 它 | Select-Object Name, CommandType, Source`——是 Cmdlet？函数？哪个模块的？（第 07 章"命令查三代"）；
3. **拆开逐段跑**：把可疑片段抠出来在隔离目录里跑（临时目录+假数据）——**行为是语法的最终解释权**。第 22 章的 F8 选中执行在脚本文件里同样好用。

## 30.4 安全审计：跑别人的代码之前

社区脚本=别人的代码在你的权限下运行。跑之前的固定检查清单（重要性递减）：

1. **来源可信度**：官方仓库/知名作者/团队内部 > 论坛随手贴；下载量与更新时间是参考项；
2. **通读全文**：重点扫危险模式——`Invoke-Expression`（IEX，执行任意字符串）、`DownloadString`/`Invoke-WebRequest` 到陌生域名（外传数据）、Base64 大块（混淆载荷）、`Remove-Item` 范围、注册表/计划任务写入；
3. **验签与来源标记**：`Get-AuthenticodeSignature` 看签名（第 17 章）；文件带 MOTW 时想清楚再 `Unblock-File`；
4. **沙箱首跑**：测试机/受限账户先跑，`-WhatIf` 能干跑就先干跑；
5. **改造后再用**：直接上生产是**别人的脚本**，按 30.2 的流程修一遍才是**你的工具**。

一句话原则（第 17 章的回响）：**你对自己的每一次运行负责**——脚本是文本，读它的成本永远低于它出错的价格。

## 30.5 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| 读半天读不懂 | 逐行啃，没先建"做什么"框架 | 五步法：头→param→骨架→分支→干演 |
| 抄来的脚本有死参数 | 作者拼凑遗留 | 通读时标记"声明未用"，改造时删 |
| 网上脚本带 IEX/下载器 | 混淆或恶意 | 30.4 清单；看不懂的代码不跑 |
| 脚本"能跑"但结果不明 | Write-Host 报喜不报实 | 改造时换结果对象输出（23 章） |
| 老脚本在 pwsh 7 报错 | 用了 5.1 独有命令（WMI 族等） | 14 章迁移对照表逐行换 |
| 直接把下载脚本进计划任务 | 跳过审计 | 生产化必经 30.4+30.2 流程 |

## 30.5.1 改造清单：从"别人的脚本"到"自己的工具"

把审计通过的脚本纳入自己工具箱前的最后一道工序——逐项打勾的改造清单（每项都指向本教程相应章）：

| # | 改造项 | 依据 |
|---|---|---|
| 1 | 删死参数、死代码；`$x = $null` 检查冗余兜底 | 30.2 三病之一 |
| 2 | 参数面收敛：必选+验证+默认值；`[CmdletBinding()]` 升高级 | 23 章 |
| 3 | 变更点接 `ShouldProcess`；`-WhatIf` 可干跑 | 25 章 |
| 4 | 错误路径 try/catch + 友好消息；外部退出码 `exit 非零` | 26 章 |
| 5 | 输出换结果对象（数据走管道，解说走 Verbose） | 21/23 章 |
| 6 | 装进函数、进模块、配注释帮助 | 24/27 章 |
| 7 | 补最小测试（Pester 三五个断言） | 32 章 |

七项全勾，"网上抄的脚本"就完成了到"自己维护的工具"的转化——从此它有说明书（帮助）、有门禁（验证）、有防护（ShouldProcess）、有售后（错误处理）、有体检（测试）。第 33 章的收官项目会把这张清单完整走一遍。

**再给一份"病灶识别速查"**（读脚本时按图索骥）：

| 代码气味 | 诊断 | 处方 |
|---|---|---|
| 声明却未用的参数/变量 | 拼凑遗留 | 删（git 里留着历史） |
| 体内 `$var = '默认'` 兜底 | 参数设计失焦 | 转正为 param 默认值 |
| `Write-Host` 结尾报平安 | 无真实输出 | 换结果对象 |
| 递归 `Remove-Item -Force` 无防护 | 变更裸奔 | ShouldProcess + 收窄目标 |
| 一行 200 字符的管道 | 不可读 | 按管道段折行（第 22 章格式纪律） |
| `cd` 到固定路径再干活 | 环境依赖 | `$PSScriptRoot`/参数化路径 |
| 硬编码的机器名/凭据 | 无法迁移 | 参数 + 凭据对象（17/19 章） |

## 30.5.2 更多真实病灶：三段速览

三个高频出现于真实脚本的"小病灶"（每个都不致命，但都值得在改造时顺手治好）：

**病灶：日志路径硬编码且不建目录**——`Out-File C:\Logs\x.log`，Logs 目录不存在时第一次写就崩。处方：`$logDir = Join-Path $PSScriptRoot 'logs'; New-Item -ItemType Directory -Force -Path $logDir | Out-Null`——`-Force` 幂等（第 01 章的复演）。

**病灶：依赖当前目录**——脚本里 `Get-Content .\config.json`，从别的目录调用就找不到文件。处方：一切相对路径以 `$PSScriptRoot` 为锚（`Join-Path $PSScriptRoot 'config.json'`）——脚本走到哪都带着自己的行李。

**病灶：凭据明文**——`$pass = 'P@ssw0rd'` 写在脚本里（即使"只是内网"）。处方：`Get-Credential` 交互获取，或 SecretManagement 模块管密钥；脚本里只留凭据**对象**的获取代码，永远不留值。

三段病灶的共同点：**在作者机器上好好的，换个环境就炸**——可移植性是"别人脚本"与"工具"的隐形分界线，也是审计清单里最值得花时间的一项。

## 30.6 本章要点

- **五步阅读法**：读头 → 读 param → 骨架（动词流）→ 分支 → 干演；先"做什么"后"怎么做"。
- 三大病与修法：死参数/硬编码（参数面收敛）、无防护（ShouldProcess 接线）、无输出（结果对象）——30.2 是完整对照样本。
- 陌生语法三消化：about 主题、Get-Command 验身份、隔离环境逐段跑。
- **跑前五查**：来源→通读危险模式→验签/MOTW→沙箱→改造；读的成本永远低于出错的价格。

**动手实验**：① 把 30.2 的病脚本存下来，按五步法走一遍并自己列出病灶，再对照"三病确诊"；② 给病脚本的 `Remove-Item` 行加 `-WhatIf` 跑一遍（在只有几个临时文件的目录里），看"将要发生什么"；③ 对照修复版逐条标注"哪处修改治了哪病"；④ 从 GitHub 或 Gallery 找一份百行左右的真实脚本，用五步法读懂并写三行摘要；⑤ 用 30.4 清单给它做一次审计。

实验参考：②注意病脚本原样干跑会**真的删除**（它没接 ShouldProcess——这本身就是实验的一部分，务必在临时目录）；③修复版的输出对象一行 `{ Path, Removed, At }` 就是"可被计划任务监控"的最小形态。

对应示例（可选）：`examples/30_others_scripts/`——配套 sample-buggy.ps1（三病样本）与 sample-fixed.ps1（修复版）：param 面对比、干跑防护对比、结果对象断言、签名状态检查，模拟五步阅读法的可执行版。

---

本篇（五 工具制作）其余各章：[24 函数](./24-functions.md) · [25 高级函数](./25-advanced-functions.md) · [26 错误处理](./26-error-handling.md) · [27 模块开发](./27-modules-dev.md) · [28 正则](./28-regex.md) · [29 技巧](./29-tips.md)

---

本篇（五 工具制作）导航：[24 函数](./24-functions.md) · [25 高级函数](./25-advanced-functions.md) · [26 错误处理](./26-error-handling.md) · [27 模块开发](./27-modules-dev.md) · [28 正则](./28-regex.md) · [29 技巧](./29-tips.md) · [30 他人脚本](./30-others-scripts.md)

实验参考：②病脚本原样干跑会真删（没有 ShouldProcess）——务必在临时目录；⑤真实脚本的摘要三行=SYNOPSIS/输入/输出。

三个小病灶的共同点是"作者机器上好好的"——可移植性是审计最值得花时间的一项；下一章进入进阶收官篇。
