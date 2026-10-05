# 32 测试与代码质量——Pester 与 ScriptAnalyzer

> 本章是扩充章（原书第 27 章指路清单的"测试"项落地）。第 26 章说过"工具的可信度来自失败时的样子"；本章补另一半——**不失败的时候你怎么知道它是对的**：Pester 给行为上锁，ScriptAnalyzer 给代码体检。二者构成"改动之后敢一键回归"的底气。

## 32.1 测试的心智模型：行为合同

测试不是"多写一堆代码"，而是把你工具的**行为合同**写成可执行文档：

```powershell
Get-Double -V 21 | Should -Be 42
```

这一行读出来就是合同条款："'给 21 应得 42'"。它同时做三件事：现在验证实现、将来防止回归（有人改坏了立刻红）、给接手的人展示**预期用法**。工具类代码（第 24–27 章）的每条导出函数都值得两三个这样的条款——正常路径一条、边界一条、异常路径一条。

## 32.2 Pester：结构与语法

Pester 是 PowerShell 的事实标准测试框架。测试文件命名约定 **`*.Tests.ps1`**（发现机制按它扫描），内部四层积木：

```powershell
BeforeAll {
    . (Join-Path $PSScriptRoot 'math.ps1')     # 引入被测函数（v5+ 必须显式 BeforeAll）
}

Describe 'Get-Double' {                        # 组织层：一个函数/主题一个 Describe
    It '正常翻倍' {                             # 断言层：一条合同一个 It
        Get-Double -V 21 | Should -Be 42
    }
    It '零也翻倍' {
        Get-Double -V 0 | Should -Be 0
    }
    It '非数字应抛错' {
        { Get-Double -V 'x' } | Should -Throw  # 异常路径：脚本块包住待炸代码
    }
}
```

要点逐个嚼：

- **`BeforeAll`**：跑测试前的准备。v3 时代测试文件与被测文件同目录就"自动可见"，v5 起必须显式引入——**新手上路第一大坑**（不写 BeforeAll 直接"命令找不到"）。配套 `BeforeEach`（每个 It 前重置状态，造干净现场）；
- **`Should` 断言**：管道接值，`-Be`（相等）、`-BeOfType [int]`（类型）、`-Throw`（应抛异常，**注意待炸代码要包脚本块 `{ }`**——第 24 章"脚本块是值"的用武之地）、`-BeGreaterThan`、`-Match`、`-Contain`（集合含）、`-BeNullOrEmpty`；
- **失败输出**：断言失败时 Pester 打出"期望 42 实得 43"式对照——**测试消息就是未来的排错现场**，条款写得具体，红起来就省时间。

**运行方式**：`Invoke-Pester`（当前目录扫 `*.Tests.ps1`，交互看绿红）；脚本化跑法（CI、或本教程示例的做法）拿结果对象：

```powershell
$r = Invoke-Pester -Path .\tests -Output None -PassThru
$r.PassedCount; $r.FailedCount          # 数字在手，断言随你
```

## 32.3 版本地雷：3.4 与 5/6 语法断层

Windows 内置 Pester **3.4.0**（随系统分发，永远停在 v3），而现代 Pester 是 **v5/v6**（PSGallery 安装）。两代断言语法**不兼容**：

| | v3（内置老版） | v5+（现代） |
|---|---|---|
| 相等 | `$x | Should Be 42`（**无横线**） | `$x | Should -Be 42`（**有横线**） |
| 抛错 | `Should Throw` | `Should -Throw` |
| 引入被测代码 | 同目录自动可见 | 必须显式 `BeforeAll { . … }` |

升级内置版的正确姿势（装给当前用户，避免动系统目录）：

```powershell
Install-Module Pester -MinimumVersion 5.0 -Scope CurrentUser -Force -SkipPublisherCheck
```

（`-SkipPublisherCheck` 是绕开"新版与内置版签名主体不同"的官方许可。）读到 `Should Be`（无横线）的老测试别慌——那是 v3 语法，认得即可；新代码一律 v5+ 语法。判定现场装的是哪代：`(Get-Module -ListAvailable Pester | Measure-Object -Maximum Version).Maximum`。

## 32.4 给上一章的工具写测试：实操

拿第 25 章的管道函数当被测对象（测试对象不限于纯函数——管道、WhatIf 都可测）：

```powershell
BeforeAll { . (Join-Path $PSScriptRoot 'tool.ps1') }

Describe 'Get-InvDiskInfo' {
    It '管道逐台流式输出' {
        $r = 'localhost' | Get-InvDiskInfo
        ($r | Measure-Object).Count | Should -BeGreaterThan 0
        $r[0].PSObject.Properties['Machine'] | Should -Not -BeNullOrEmpty
    }
    It '阈值参数影响 Low 标记' {
        $r = 'localhost' | Get-InvDiskInfo -MinFreePct 100
        @($r | Where-Object Low).Count | Should -Be @($r).Count   # 100% 阈值下全部告警
    }
}
Describe 'Remove-TutFile（ShouldProcess）' {
    It '-WhatIf 不落盘' {
        $f = New-Item -Path (Join-Path $TESTDRIVE 'x.txt') -Force
        Remove-TutFile -Path $f.FullName -WhatIf
        Test-Path $f.FullName | Should -BeTrue
    }
}
```

两个新面孔：`$TESTDRIVE` 是 Pester 给每个测试**临时建的沙箱目录**（测试文件随便造、跑完自动清——变更类测试不怕弄脏现场）；`-MinFreePct 100` 的"极端参数"手法——把阈值推到边界让断言变成确定性的"全部告警"（比抓真实磁盘比例可靠得多）。

## 32.5 ScriptAnalyzer：静态体检

Pester 测**行为**（跑起来对不对），ScriptAnalyzer 测**代码**（写得规范吗）——PowerShell 官方 linter：

```powershell
Invoke-ScriptAnalyzer -Path .\MyModule\MyModule.psm1
```

输出是**诊断对象**（可管道续加工）：`RuleName`、`Severity`（Error/Warning/Information）、`Line`、`ScriptName`、`Message`、`SuggestedCorrections`。值得认识的高频规则：

| 规则 | 查什么 | 为什么 |
|---|---|---|
| `PSAvoidUsingWriteHost` | Write-Host | 绕过流体系（第 21 章） |
| `PSAvoidUsingPlainTextForPassword` | 密码参数用 `[string]` | 应 `[securestring]`/`[pscredential]` |
| `PSAvoidUsingInvokeExpression` | IEX | 注入风险（第 30 章） |
| `PSUseShouldProcessForStateChangingFunctions` | 变更函数没接 ShouldProcess | 第 25 章的纪律 |
| `PSUseApprovedVerbs` | 未批准动词 | 第 04/24 章 |
| `PSAvoidUsingConvertToSecureStringWithPlainText` | 明文转安全串 | 安全惯例 |

工程化用法：配置文件 `.PSScriptAnalyzerSettings.psd1` 定制规则集（ Severity 门槛、排除目录）；`Invoke-ScriptAnalyzer -Recurse` 全仓扫；CI 里"**警告非零即失败**"。VS Code 的 PowerShell 扩展**实时**跑它——写代码时绿波浪线就是 Analyzer 在说话，本章的规则表也是那堆波浪线的字典。

## 32.6 质量流水线：三层防线

把两件武器与前面的错误处理串成流水线（第 33 章项目会原样落地）：

```
写代码 → VS Code 实时 Analyzer（第一层：写时就纠）
       → 提交前 Invoke-ScriptAnalyzer -Recurse（第二层：仓库门禁）
       → Invoke-Pester -PassThru（第三层：行为回归）
       → 全绿才 Publish-Module / 部署
```

三层各有盲区、互为补位：Analyzer 抓不到逻辑错（测试的活）、测试抓不到风格隐患（Analyzer 的活）、两者都绿的代码仍需错误处理兜运行时意外（26 章的活）。**"Analyzer 零警告 + 测试全绿 + try/catch 完备"**——这就是本教程对"可信工具"的操作性定义。

## 32.6.1 什么值得测：断言的性价比排序

"都写测试"与"都不写"之间，是**断言的性价比排序**（预算有限时从上往下投）：

| 优先级 | 测什么 | 为什么 |
|---|---|---|
| ★★★ | 异常路径（缺参抛、非法值抛、目标不存在抛） | 最容易在重构中悄悄坏掉，`Should -Throw` 一行锁死 |
| ★★★ | 边界值（0、空集合、极端参数） | 边界是 bug 聚居地；极端参数还能把断言变成确定性 |
| ★★ | 输出合同（列存在、类型正确、往返守恒） | 消费者依赖的形状变了就是破坏性更新 |
| ★★ | 核心正常路径（一两条就够） | 太多重复的正常路径断言是安慰剂 |
| ★ | 风格/实现细节 | **别测**——重构的自由比测试数量值钱（32.4 改默认值仍全绿正是好范本） |

这张表反过来说明**什么不值得测**：实现细节、私有函数、第三方库的行为（信任它的测试）。测试金字塔的底部永远是"合同"，不是"代码行"。

配套的**测试命名法**：It 的名字写**行为**不写实现——`'极端阈值 100 使全部标记 Low'`（好）而非 `'foreach 循环正确执行'`（差：重构换掉 foreach 测试名就撒谎了）。

## 32.7 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| 测试里"找不到命令" | 没写 BeforeAll 引入被测代码 | v5+ 必须显式 `. 路径` |
| `Should Be` 报语法错 | 用 v3 语法跑了 v5/v6 | 现代语法带横线 `Should -Be` |
| Should -Throw 没接到 | 待炸代码没包脚本块 | `{ 危险代码 } | Should -Throw` |
| 测试互相污染 | 共享状态没重置 | 状态造进 `BeforeEach`；文件用 `$TESTDRIVE` |
| 机器差异导致测试红 | 断言依赖真实环境值 | 极端参数/固定样本/结构断言（12 章套路） |
| Analyzer 在 5.1 找不到 | 模块按引擎隔离安装 | 各装各的 CurrentUser |
| CI 里 Pester 弹交互 | v3 的某些行为；或 Read-Host | 无人值守 `-Output None -PassThru`；代码层禁交互 |

## 32.7.1 CI 里的两行：把防线挂上门禁

GitHub Actions 的最小 PowerShell 质检工作流（其它 CI 同理，核心就是两行命令）：

```yaml
# .github/workflows/quality.yml
steps:
  - uses: actions/checkout@v4
  - name: Analyzer 体检（零警告门禁）
    run: pwsh -Command "Invoke-ScriptAnalyzer -Path .\src -Recurse -Severity Error -ErrorAction Stop"
  - name: Pester 回归（红灯即失败）
    run: pwsh -Command "\$r = Invoke-Pester -Path .\tests -Output None -PassThru; if (\$r.FailedCount -gt 0) { exit 1 }"
```

两个细节：Analyzer 加 `-Severity Error` 把门禁定在"错误级零容忍"（警告级可以先记录不拦截，团队消化存量再收紧）；Pester 的 `exit 1` 把红字翻译成 CI 的失败状态——**从此"合并"就是"验证过"的同义词**。本地脚本（`build.ps1` 一类的自用验证器）与 CI 用同两条命令，本地绿 CI 就绿，别造两套标准。

## 32.8 本章要点

- 测试=**可执行的行为合同**；`Describe`/`It`/`Should -断言`/`BeforeAll` 引入/`$TESTDRIVE` 沙箱。
- **v3 与 v5+ 语法断层**（无横线 vs 有横线）；升级 `-Scope CurrentUser -SkipPublisherCheck`；本机版本一查便知。
- `Invoke-Pester -PassThru` 拿 `PassedCount/FailedCount` 做脚本化判定；确定性手法：**极端参数 + 结构断言**。
- ScriptAnalyzer：诊断对象流（RuleName/Severity/Line）、高频规则表、`.psd1` 定制、CI 门禁。
- 三层质量流水线：**实时 lint → 仓库扫描 → 行为回归**，与 26 章错误处理合成"可信工具"定义。

**动手实验**：① 给第 24 章的 `Get-Square` 写 `math.Tests.ps1`（正常/边界/异常三条款），`Invoke-Pester` 看绿；② 故意把实现改错，看红字里的期望/实得对照；③ 写个 `Write-Host` 的脏脚本给 Analyzer 扫，对照规则表认规则名；④ 用 `$TESTDRIVE` 写一个"创建文件→验证存在"的测试；⑤ 把 ① 跑成脚本形态（`-PassThru` 取数、`FailedCount -eq 0` 断言）。

实验参考：②红字格式 `[ - ] It 名字 … Expected: 42 But was: 43`——记住这个长相，它是最省时间的失败报告；③脏脚本至少触发 `PSAvoidUsingWriteHost` 一条。

对应示例（可选）：`examples/32_testing/`——Pester 探针（版本分支）、被测函数+测试（含 -Throw 与沙箱）、`-PassThru` 结果断言、Analyzer 干净/脏样本双扫。

---

本篇（六 进阶收官）其余各章：[31 类与 JSON](./31-classes.md) · [33 工具制作收官](./33-toolmaking.md) · [34 备忘清单](./34-cheatsheet.md)

实验参考：②红字的 Expected/But was 对照即失败报告全文；⑤FailedCount 就是 CI 的红灯信号量。

---

本篇（六 进阶收官）导航：[31 类与 JSON](./31-classes.md) · [32 测试](./32-testing.md) · [33 工具制作收官](./33-toolmaking.md) · [34 备忘清单](./34-cheatsheet.md)
