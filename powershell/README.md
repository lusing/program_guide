# PowerShell 开发指南

以《Windows PowerShell 实战指南（第 3 版）》（Don Jones & Jeff Hicks，《Learn Windows PowerShell in a Month of Lunches, 3e》中译本）为纲的自包含教程：**34 章六篇 = 原书 27 章教学全保留重组 + 7 章现代扩充**（pwsh 7 主线、Windows PowerShell 5.1 差异全程标注）。

## 结构总览

| 篇 | 章 | 内容（书章源） |
|---|---|---|
| 一 壳与命令 | [01](docs/01-why-powershell.md)–[05](docs/05-providers.md) | 心智模型(书1) · 宿主与版本(书2) · 帮助系统(书3) · Cmdlet 语法(书4) · 提供程序(书5) |
| 二 对象与管道 | [06](docs/06-pipeline-first.md)–[12](docs/12-integration.md) | 管道(书6) · 模块生态(书7) · 对象(书8) · 参数绑定(书9) · 格式化(书10) · 过滤(书11) · 库存实战(书12) |
| 三 远程与批量 | [13](docs/13-remoting.md)–[19](docs/19-advanced-remoting.md) | 远程处理(书13) · CIM(书14) · 后台作业(书15) · 多对象+并行(书16) · 安全执行策略(书17) · 会话(书20) · 高级远程+SSH(书23) |
| 四 语言核心 | [20](docs/20-variables.md)–[23](docs/23-parameterized.md) | 变量(书18) · 六流 IO(书19) · 第一个脚本(书21) · 参数化与验证(书22) |
| 五 工具制作 | [24](docs/24-functions.md)–[30](docs/30-others-scripts.md) | 函数与作用域(扩) · 高级函数(扩) · 错误处理(扩) · 模块开发(扩) · 正则(书24) · 技巧(书25) · 他人脚本(书26) |
| 六 进阶收官 | [31](docs/31-classes.md)–[34](docs/34-cheatsheet.md) | 类与 JSON(扩) · Pester+ScriptAnalyzer(扩) · 工具制作收官(书27) · 备忘清单(书28) |

（扩 = 现代扩充章，共 7 章；其余 27 章对应原书教学章，书 28 → 34 章）

## 验证

本教程**在 Windows 与 macOS 两平台实测通过**。两个平台的可用引擎不同，验证入口也分两个：

```powershell
# Windows：双通道（pwsh 7 主线 + Windows PowerShell 5.1 差异通道）
pwsh -File build.ps1                 # 全量：34 示例 × 双引擎
pwsh -File build.ps1 -Only '09*'     # 单示例
```

```bash
# macOS/Linux：单引擎（Windows PowerShell 5.1 只存在于 Windows）
./run-all.sh              # 全量：34 示例
./run-all.sh 09 14        # 只跑指定章号
./run-all.sh -v           # 附带每个示例的完整输出
```

- **Windows：34/34 双通道全绿**；**macOS 14.8.9 + pwsh 7.6.6：34/34 全绿**（370 条 `OK:` 断言、23 条带理由 SKIP、0 FAIL）。
- 远程/SSH/Pester/ScriptAnalyzer/CIM 等按**探针门控**（环境不备则带理由 SKIP，不失败、不改系统状态）。
- 每示例自校验写 `report.txt`，双通道**对账剥离后逐字节一致**（`[ch7-only]/[ch51-only]/[platform]/[env]` 行除外）；
  macOS 单引擎侧改用**同命令连跑两遍、report 逐字节一致**的确定性纪律。
- macOS 侧另有一条**零断言告警**：某示例 report 里一条 `OK:` 都没有（全 SKIP）时单独点名——「没失败」不等于「验证到了东西」。
- 实测坑位汇总：[CHEATSheet.md](CHEATSheet.md)（18 条 Windows 构建期亲历坑 + 8 条 macOS 校验新增坑 + 协议与平台差异速查）。

### 平台差异速查

Windows-only 能力在 macOS 上**确实不存在**，示例一律走带 `[platform]` 标记的 SKIP（**不按平台宏 `#ifdef` 放宽判据**），并给出跨平台等价锚点：

| Windows 能力 | macOS 现状 | 受影响章 | 替代锚点 |
|---|---|---|---|
| `Get-Service` | 无（launchd 不是 SCM） | 01 03 04 08 09 10 11 | `Get-Process` / `Get-ChildItem` |
| CIM / WMI（`Get-CimInstance` 等 4 个） | 无（Windows COM/DCOM 技术栈） | 11 12 14 33 | `Get-PSDrive -PSProvider FileSystem` |
| `Registry::` 提供程序 | 无 | 05 | `FileSystem:` 的 `IsReadOnly` |
| `Get-AuthenticodeSignature` | 无 | 17 | — |
| NTFS ADS / `Zone.Identifier` / MOTW | 无（`-Stream` 不在参数表） | 17 | — |
| 执行策略可设置 | 恒 `Unrestricted`，设置抛"不支持" | 17 | — |
| `New-PSSessionOption` 的 WSMan 超时参数 | 被剔除，只剩 SSL 校验开关 | 19 | — |
| WinRM / `WSMan:` / 端点 | 无此服务 | 19 | SSH 腿（Unix 上 `-HostName` 可用） |

反过来的坑：`Get-PSDrive` **没有 `Size` 字段**（只有 `Used`/`Free`），总量要自己 `Used+Free` 算——与 CIM 分支的 `Size`/`FreeSpace` 写法不同，这是 12 章两条轨的真实差异。

**无法在 macOS 上验证的结论**（只在 Windows 成立，由 `build.ps1` 双通道覆盖）：CIM/WQL 方言、WSMan 端点与 WinRM、NTFS ADS/MOTW、Authenticode 签名状态、执行策略五作用域的真实拦截效果。macOS 侧只验证了"这些能力缺失时能正确降级"。

## 目录说明

- `docs/`——34 章分章文档（每章 ≥200 行、文字多于代码、自包含不要求翻原书）；
- `examples/NN_slug/run.ps1`——章号=示例号的自校验脚本（UTF-8 带 BOM，`build.ps1` 自动补）；
- `run-all.sh`——macOS/Linux 验证入口（单引擎 + 连跑两遍确定性对账）；
- `materials/book/ch01..28.txt`——原书文本提取（`tools/extract-epub.ps1` 可复现），仅写作查证用；
- `tools/`——提取与冒烟脚本。

## 快速上手

1. 读 [docs/01](docs/01-why-powershell.md)（为什么是 PowerShell）；
2. 章内"动手实验"逐条敲（每章实验只用当章与前章知识）；
3. 卡住查 [docs/34](docs/34-cheatsheet.md)（五张速查表）与 [CHEATSheet.md](CHEATSheet.md)。
