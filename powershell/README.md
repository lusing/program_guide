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

```powershell
pwsh -File build.ps1                 # 全量：34 示例 × 双引擎（pwsh 7 + powershell 5.1）
pwsh -File build.ps1 -Only '09*'     # 单示例
```

- **34/34 双通道全绿**；远程/SSH/Pester/ScriptAnalyzer 等按**探针门控**（环境不备则带理由 SKIP，不失败、不改系统状态）。
- 每示例自校验写 `report.txt`，双通道**对账剥离后逐字节一致**（`[ch7-only]/[ch51-only]/[env]` 行除外）。
- 实测坑位汇总：[CHEATSheet.md](CHEATSheet.md)（18 条构建期亲历坑 + 协议速查）。

## 目录说明

- `docs/`——34 章分章文档（每章 ≥200 行、文字多于代码、自包含不要求翻原书）；
- `examples/NN_slug/run.ps1`——章号=示例号的自校验脚本（UTF-8 带 BOM，`build.ps1` 自动补）；
- `materials/book/ch01..28.txt`——原书文本提取（`tools/extract-epub.ps1` 可复现），仅写作查证用；
- `tools/`——提取与冒烟脚本。

## 快速上手

1. 读 [docs/01](docs/01-why-powershell.md)（为什么是 PowerShell）；
2. 章内"动手实验"逐条敲（每章实验只用当章与前章知识）；
3. 卡住查 [docs/34](docs/34-cheatsheet.md)（五张速查表）与 [CHEATSheet.md](CHEATSheet.md)。
