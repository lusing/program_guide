# PowerShell 开发指南设计（34 章，书为纲 + 现代扩充）

日期：2026-10-06
状态：设计已与用户确认（pwsh 7 主线+5.1 差异标注 / 双通道验证 / 书为纲+现代扩充，三项决策均选推荐项）

## 目标

以《Windows PowerShell 实战指南（第3版）》（Don Jones & Jeff Hicks，《Learn Windows PowerShell in a Month of Lunches, 3e》中译本，28 章）为纲，在 `G:\code\guide\powershell\` 落地一份**自包含的 PowerShell 开发指南**：

- 正文以 **PowerShell 7（pwsh，本机 7.6）** 为基准；Windows PowerShell 5.1 行为不同的地方显式标注差异。
- 原书 27 章教学内容**全保留并重组**（其教学哲学"先当 Shell 用户、再当管理员、最后才是脚本作者"贯彻到篇结构），28 章备忘清单转化为收官章。
- 追加 **7 章现代扩充**：函数与作用域、高级函数、错误处理、模块开发、类与枚举、Pester 测试、工具制作收官实战。
- 书的内容自包含蒸馏：教学案例（库存清单实战、管道参数绑定、执行策略安全观、他人脚本剖析）全部在正文重述清楚，正文可提名，绝不指派读者翻原书。

## 取材

- epub 文本层完好、代码清单（pre 块）存活，**无需 OCR**。已验证：`N.xhtml = 第 N+1 章`，全书 28 章正文 + 复习实验。
- 全书文本提取为 txt 入库 `powershell/materials/book/`（写作时查证用，不进教程正文引用链）。

## 最终 34 章结构（六篇）

| 篇 | 章 | slug | 主题（书章源） |
|---|---|---|---|
| 一 壳与命令 | 01 | 01-why-powershell | 心智模型：为何 Shell 优于 GUI（书1） |
| | 02 | 02-meet-powershell | 宿主/版本/$PSVersionTable/profile；现代 pwsh 7 与 VS Code（书2） |
| | 03 | 03-help-system | 帮助系统：Get-Help 全解、-Examples、Update-Help（书3） |
| | 04 | 04-running-commands | Cmdlet 动宾结构、Get-Command、参数类型、别名（书4） |
| | 05 | 05-providers | 提供程序：注册表/环境/证书/变量皆驱动器（书5） |
| 二 对象与管道 | 06 | 06-pipeline-first | 管道初步：一个命令一个职责（书6） |
| | 07 | 07-modules-usage | 扩展命令与模块生态 + PSGallery（书7 现代化） |
| | 08 | 08-objects | 对象：Get-Member、属性/方法（书8） |
| | 09 | 09-pipeline-deep | 深入管道：ByValue/ByPropertyName 参数绑定（书9） |
| | 10 | 10-formatting | 格式化双刃剑：Format-* 与右到左解析（书10） |
| | 11 | 11-filtering | 过滤与比较运算符、左过滤（书11） |
| | 12 | 12-integration | 学以致用：库存清单综合实战（书12） |
| 三 远程与批量 | 13 | 13-remoting | 远程处理 1:1 与 1:N、WS-MAN/WinRM（书13） |
| | 14 | 14-cim | CIM/WMI：Get-CimInstance、WQL、CimSession（书14） |
| | 15 | 15-jobs | 后台作业 + ThreadJob（书15） |
| | 16 | 16-multiple-objects | 多对象处理 + ForEach-Object -Parallel（书16） |
| | 17 | 17-security | 安全警报与执行策略全解（书17） |
| | 18 | 18-sessions | 可复用会话 New-PSSession（书20） |
| | 19 | 19-advanced-remoting | 高级远程：端点/TrustedHosts/SSH 远程（书23） |
| 四 语言核心 | 20 | 20-variables | 变量、数组、哈希表、引号与展开（书18） |
| | 21 | 21-io-streams | 输入输出与五条流、Write-* 家族（书19） |
| | 22 | 22-first-script | 从命令行到 .ps1、param()、执行策略（书21） |
| | 23 | 23-parameterized | 参数化脚本：CmdletBinding 入门、验证属性、注释帮助（书22） |
| 五 工具制作 | 24 | 24-functions | 函数与作用域（扩；书27 指路展开） |
| | 25 | 25-advanced-functions | 高级函数：CmdletBinding 全解、process 块、ShouldProcess（扩） |
| | 26 | 26-error-handling | 错误处理：错误流、try/catch、-ErrorAction（扩） |
| | 27 | 27-modules-dev | 模块开发：脚本模块、.psd1 清单、发布（扩） |
| | 28 | 28-regex | 正则解析文本：-match/-replace、Select-String（书24） |
| | 29 | 29-tips | 提示与技巧：字符串、子表达式、调用操作符（书25） |
| | 30 | 30-others-scripts | 使用他人的脚本：剖析方法论（书26，案例改编现代版） |
| 六 进阶收官 | 31 | 31-classes | 类、枚举与结构化数据 JSON（扩） |
| | 32 | 32-testing | Pester 测试与 ScriptAnalyzer（扩） |
| | 33 | 33-toolmaking | 工具制作收官：综合项目整合全书（书27 Toolmaking） |
| | 34 | 34-cheatsheet | 备忘清单：标点/运算符/速查总表（书28） |

（扩 = 现代扩充章，共 7 章；其余 27 章对应书 1–27 章教学内容重组，书 28 → 34 章）

## 示例与验证

- `examples/NN_slug/run.ps1`（章号=示例号），支持文件同目录；**一律 UTF-8 带 BOM**（5.1 解析含中文脚本的无 BOM 文件按 ANSI 读，硬要求）。
- 脚本**自校验**：打印确定性摘要行（OK:/SKIP: 前缀），退出码非 0 表示失败。
- `build.ps1` 双通道：pwsh 7 + powershell.exe 5.1，各以 `-NoProfile -NonInteractive -ExecutionPolicy Bypass` 跑全部示例，启动时设 `[Console]::OutputEncoding = UTF8`；目标**双通道输出逐字节一致**（版本相关内容不进确定性输出区）。
- 门控策略（延续探针模式）：
  - pwsh 7 独有特性（`-Parallel`、三元/`??`、`&&`/`||`）在 5.1 通道打印带理由的 SKIP 行；5.1 独有（`Get-WmiObject`）反向同理。
  - 远程章（13/18/19）：loopback WinRM/SSH 探针，不通则带理由跳过；**绝不 Enable-PSRemoting / Set-Item TrustedHosts 改系统状态**（讲解正文写清真实操作步骤）。
  - CIM 章只读查询双通道直跑（本地无 WinRM 依赖）；输出含机器差异字段的做结构断言（类型/属性存在性）而非字节断言。
  - Pester/ScriptAnalyzer 章先探测模块，缺失尝试 PSGallery `Install-Module -Scope CurrentUser`，仍失败则带理由 SKIP。
- 变更类演示**自演自净**：Start-Process 拉起子进程再 Stop、临时目录建删成对、注册表写 HKCU 临时键再删。

## 文档规格（全仓既有标准）

- `docs/NN-slug.md`：每章 ≥200 行、**文字多于代码**、每段代码前有"为什么"后有"在做什么+关键点"；示例指路 `examples/NN_slug/` 放章末且标可选。
- `powershell/README.md`：分章导航 + 验证状态。
- `powershell/CHEATSheet.md`：实测坑位汇总（写作过程中滚动收录）。
- 根 `README.md` 登记 powershell 条目。

## 批次计划

| 批 | 内容 | 验收 |
|---|---|---|
| 0 | 骨架 + materials 入库 + build.ps1 + 样例示例双通道跑通 | 样例 1/1 双通道一致 |
| 1 | docs 01–05 + examples | 5/5 双绿 |
| 2 | docs 06–12 + examples | 7/7 双绿 |
| 3 | docs 13–19 + examples（远程门控） | 7/7 双绿（或带理由 SKIP） |
| 4 | docs 20–23 + examples | 4/4 双绿 |
| 5 | docs 24–30 + examples | 7/7 双绿 |
| 6 | docs 31–34 + examples + CHEATSheet | 4/4 双绿 |
| 7 | powershell/README + 根 README 登记 + 全量终验 | 34/34 双通道全绿 |

每批完成即 commit（feat(powershell): 批次 N——……），提交信息经 `-F` 文件提交（防安全层误判）。

## 已知风险与预案（开工前已有证据的坑）

- **编码三连**：GBK 控制台（输出统一 UTF8 强制）、ps1 必带 BOM、5.1 与 pwsh 对 `[Console]::OutputEncoding` 生效时机不同——build.ps1 在引擎内部首行设置而非外层 chcp。
- pwsh 7.6/.NET 9 的 `ArgumentList` 引号转义回归（cpp20 教训）——子进程调用用 `-File` 直跑，不拼 `-Command` 内嵌引号。
- WinRM 在家庭机大概率未启用——远程章全部设计成门控可跳过，正文不依赖真实远程环境即可教学。
- `Sort-Object`/`Get-Service` 等机器相关输出不进对账区。
- Pester 在 5.1 随 Windows 内置 3.x 老版本，pwsh 7 不内置——版本探测分支处理，教学正文以 Pester 5 语法为准并标注 3.x 差异。
