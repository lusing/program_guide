# Swift 教程重写实施计划（2026-09-20）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **状态：未开始**

**Goal:** 将 `swift/` 重写为对齐 cpp20/rust/go/zig 标准的 24 章教程（docs/ 分章 +
章号=示例目录号 + 递进讲解 + 坑位清单 + swift-format/build/test/run 四层验证 + 迷你 grep 实战收官）。

**Architecture:** 先删旧建新验证骨架（根 Package.swift + build.ps1/run-all.sh + 02_hello 冒烟），
再按批次"示例先行、正文随后"逐批交付（语言篇 3 批 → 内存并发与 IO 1 批 → 测试工程实战 2 批），
每批 build.ps1 全绿即提交；最后 01 章/CHEATSheet/README/根 README/记忆收官并全量终验。

**Tech Stack:** Swift 6.3.3（scoop，x86_64-windows-msvc，钉死不用 current junction）、
SPM（native 构建系统，根包 21 目标 + 2 嵌套独立包）、swift-testing、swift-format、
PowerShell 7（pwsh）、Git Bash（run-all.sh）。

**Spec:** `docs/superpowers/specs/2026-09-20-swift-tutorial-rewrite-design.md`（含 §4 环境实测
结论与 §5 章节结构表——各章内容主题清单出自该表，执行时以 spec 为准）

## Global Constraints（实施遵守，摘自 spec §3/§4/§6）

- **工具链常量**（build.ps1/run-all.sh 顶部固化，不碰 `current` junction——MSYS 对 junction
  间歇失明且指向 6.4.0 坏包）：

```text
SWIFT_ROOT = G:\scoop\apps\swift\6.3.3
swift      = G:\scoop\apps\swift\6.3.3\Toolchains\6.3.3+NoAsserts\usr\bin\swift.exe
swift-format 同目录 swift-format.exe
SDKROOT    = G:\scoop\apps\swift\6.3.3\Platforms\Windows.platform\Developer\SDKs\Windows.sdk
PATH 前置（顺序固定）：
  1. G:\scoop\apps\swift\6.3.3\Runtimes\usr\bin            ← 运行时 DLL（exe 能跑起来的前提）
  2. G:\scoop\apps\swift\6.3.3\Toolchains\6.3.3+NoAsserts\usr\bin  ← 编译器
  3. G:\scoop\apps\swift\6.3.3\Toolchains\usr\lib\swift\pm\ManifestAPI  ← 清单 exe 的 PackageDescription.dll
```

  SDKROOT **必须覆盖**（scoop 用户级指向 current=6.4.0，不覆盖则混编报
  `module compiled with Swift 6.4 cannot be imported by the Swift 6.3.3 compiler`）。
  6.4 三件套失效或路径变动时先复跑本计划 Task 1 的冒烟再排查。
- **四层验证**（普通示例，build.ps1 `-Example NN_name` 逐个执行）：
  1. `swift-format lint --strict --recursive examples/NN_name`（exit 0）
  2. `swift build --target ChNN…`（exit 0）
  3. `swift test --filter ChNN…Tests`（exit 0，全部 √）
  4. `swift run ChNN…`（exit 0，stdout 末行含 `==== NN 结束 ====`，stderr 空）
  判定补充：stdout 无乱码控制字符（TAB/LF/CR 除外）；任一失败脚本 exit 1。
- **独立包示例**（22_spm/24_minigrep）：不在根包；验证 = cd 子目录 → `swift build` →
  `swift test`（24 有测试）→ `swift run` exit 0。
- **根 Package.swift 模板**（每新增一章示例就追加一组目标；swift-tools-version 6.0；
  全部显式 path 无 glob）：

```swift
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "swift-guide",
    targets: [
        .executableTarget(
            name: "Ch02Hello",
            path: "examples/02_hello/Sources/02_hello"),
        .testTarget(
            name: "Ch02HelloTests",
            dependencies: ["Ch02Hello"],
            path: "examples/02_hello/Tests/02_helloTests"),
        // …按章号递增追加；22_spm / 24_minigrep 不进根包
    ]
)
```

  目标名固定 `Ch` + 章号 + 大驼峰主题词（Ch03Basics/Ch04Control/Ch05Functions/Ch06Optionals/
  Ch07StructsClasses/Ch08Enums/Ch09Protocols/Ch10Generics/Ch11Closures/Ch12Errors/
  Ch13Collections/Ch14Strings/Ch15Extensions/Ch16Arc/Ch17Concurrency/Ch18Actors/Ch19Files/
  Ch20Codable/Ch21Testing/Ch23Tooling；测试目标一律加 `Tests` 后缀）。
- **main.swift 骨架**（每章遵守；顶层语句只在 main.swift；核心逻辑写成可测试的纯函数）：

```swift
import Foundation   // 仅按需

// ═══ N.M 小节标题（与正文小节号一致）
func add(_ a: Int, _ b: Int) -> Int { a + b }
precondition(add(2, 3) == 5, "add 断言失败")
print("add(2, 3) = \(add(2, 3))")

print("==== NN 结束 ====")
```

- **测试骨架**（swift-testing，每章 3–10 用例，含中文/边界用例；函数名可中文）：

```swift
import Testing
@testable import Ch02Hello

@Test func add两个整数() {
    #expect(add(2, 3) == 5)
    #expect(add(-1, 1) == 0)
}
```

- **章正文 200–350 行**（⭐ 章不压缩）：`# NN · 标题` 开头、`## 1..N` 分节、每章末
  `## N. 坑位清单`（3–6 条实测坑）、最后一行导航
  `上一章：[..](..) ｜ 下一章：[..](..) ｜ 返回：[README](../README.md)`
  （01 章无上一章、24 章无下一章）。
- **编码纪律**：所有 .swift/.md/脚本 UTF-8 **无 BOM**；运行前控制台 UTF-8
  （build.ps1 设 `[Console]::OutputEncoding` + `chcp 65001`；run-all.sh 由 Git Bash天然 UTF-8）。
- **确定性纪律**：演示输出可复现——随机用固定种子、时间只演示不打印、不读 stdin、
  并发示例用固定任务集 + 汇总断言（17/18/24 章）。
- **.gitignore**：根 `.gitignore` 补 `swift/.build/`（根包与嵌套包的 `.build/` 均不进库）；
  旧 `swift/build/` 产物随 Task 1 删除。
- **提交风格**：`docs(swift): …` 中文描述；每批 Task 末提交一次，消息末尾带
  `Co-Authored-By: Claude Code <noreply@anthropic.com>`。

## Tasks

### Task 1: 基建——删旧 + 根包 + 验证骨架 + 冒烟

**Files:**
- Delete: `swift/Swift编程指南.md`、旧 `swift/examples/*.swift`（10 项）、旧 `swift/build/`（31 项）
- Create: `swift/Package.swift`（先只含 Ch02Hello 一组目标）、`swift/build.ps1`（重写）、
  `swift/run-all.sh`（新增）、`swift/examples/02_hello/Sources/02_hello/main.swift`（冒烟，Task 2 完善）、
  `swift/examples/02_hello/Tests/02_helloTests/HelloTests.swift`
- Rewrite: `swift/README.md`（过渡版：目录结构 + 工具链 + 验证命令，章节索引留待收官）
- Modify: 根 `.gitignore`（补 `swift/.build/`）

- [ ] Step 1: `git rm` 旧指南与旧示例、删旧 build/；确认 `git status` 无遗漏
- [ ] Step 2: 写根 `Package.swift`（Global Constraints 模板，仅 Ch02Hello 组）
- [ ] Step 3: 写 `build.ps1`（pwsh 7：环境配方三件套 + UTF-8 + 参数
  `-All/-Example NN_name/-Clean` + 四层验证函数 + 独立包分支——Task 7 前仅普通分支）
- [ ] Step 4: 写 `run-all.sh`（Git Bash 等价入口：export SDKROOT/PATH（MSYS 路径形态）+
  同四层；`./run-all.sh [NN_name]`）
- [ ] Step 5: 写 02_hello 冒烟（main.swift + HelloTests.swift，含中文输出 + precondition +
  `==== 02 结束 ====`）
- [ ] Step 6: 双入口验证：`pwsh -NoProfile -ExecutionPolicy Bypass -File build.ps1 -Example 02_hello`
  四层全绿；`./run-all.sh 02_hello` 同验
- [ ] Step 7: 同批提交
  `docs(swift): 重写基建——删旧指南与示例，根 Package.swift + build.ps1/run-all.sh 四层验证骨架 + 02 冒烟`

### Task 2: 批次 1——语言篇 02–05（4 章 4 示例）

**Files:**
- Create: `docs/02-hello.md`（三形态/顶层代码规则/根包解剖/运行时 DLL 坑）、
  `docs/03-basics.md`（无隐式转换/溢出/元组）、`docs/04-control.md`（guard/switch 穷尽/Range）、
  `docs/05-functions.md`（参数标签/inout/变参/重载）
- Create: `examples/02_hello/`（完善）、`03_basics/`、`04_control/`、`05_functions/`
- Modify: 根 `Package.swift`（追加 Ch03Basics…Ch05Functions 三组目标）

**Interfaces:**
- Consumes: Task 1 的四层验证入口（`build.ps1 -Example` / `run-all.sh`）
- Produces: 后续章节沿用的示例骨架惯例与 `add` 等教学函数仅限本章，无跨章代码依赖

- [ ] 示例先行：4 个示例按 spec §5 主题实现（03 打印尺寸表 + 溢出 `&+` + 转换断言；
  04 覆盖 guard/switch 穷尽与模式匹配/for-in Range/labeled break；05 覆盖标签/`_`/默认值/
  inout/变参/重载/递归）
- [ ] 每示例 `-Example NN_name` 四层绿，再 `-All` 全绿
- [ ] 正文随后：4 章按示例分节（`# ═══ N.M` 对应），坑位清单收实测坑
- [ ] 提交 `docs(swift): 02–05 章——第一个程序/基础类型/控制流/函数 + 四示例四层验证通过`

### Task 3: 批次 2——语言篇 06–10（5 章 5 示例）

**Files:**
- Create: `docs/06-optionals.md` ⭐、`docs/07-structs-classes.md`、`docs/08-enums.md`、
  `docs/09-protocols.md` ⭐（some/any）、`docs/10-generics.md`
- Create: `examples/06_optionals/`、`07_structs_classes/`、`08_enums/`、`09_protocols/`、
  `10_generics/`
- Modify: 根 `Package.swift`（追加五组目标）

- [ ] 示例先行（06 if let/guard let/可选链/`??`/map-flatMap；07 值 vs 引用语义对照 +
  属性观察者 + mutating + deinit 计数；08 关联值/indirect 表达式树/模式匹配；09 extension
  默认实现 + some/any 差异 + Equatable/CustomStringConvertible；10 泛型栈 + where + 关联类型）
- [ ] `-Example` 逐个四层绿 + `-All` 回归
- [ ] 正文 5 章 + 提交 `docs(swift): 06–10 章——可选/结构体类/枚举/协议/泛型 + 五示例验证通过`

### Task 4: 批次 3——语言篇 11–15（5 章 5 示例，语言篇收官）

**Files:**
- Create: `docs/11-closures.md`、`docs/12-errors.md`（typed throws）、`docs/13-collections.md`、
  `docs/14-strings.md` ⭐（grapheme/Index/Regex）、`docs/15-extensions.md`
- Create: `examples/11_closures/`、`12_errors/`、`13_collections/`、`14_strings/`、
  `15_extensions/`
- Modify: 根 `Package.swift`（追加五组目标）

- [ ] 示例先行（11 捕获语义实测 + 尾随闭包 + map/filter/reduce 组合；12 自定义错误枚举 +
  do-catch + Result + typed throws；13 三大容器 + 切片 Index 坑 + 排序；14 é 家族 +
  Index 遍历 + Regex 字面量实测；15 subscript + 泛型约束 extension + retroactive 坑）
- [ ] `-Example` 逐个四层绿 + `-All` 回归（02–15 共 14 示例）
- [ ] 正文 5 章 + 提交 `docs(swift): 11–15 章——闭包/错误处理/集合/字符串/扩展下标 + 五示例验证，语言篇收官`

### Task 5: 批次 4——内存并发与 IO 16–20（5 章 5 示例）

**Files:**
- Create: `docs/16-arc.md` ⭐、`docs/17-concurrency.md` ⭐、`docs/18-actors.md` ⭐、
  `docs/19-files.md`、`docs/20-codable.md` ⭐
- Create: `examples/16_arc/`、`17_concurrency/`、`18_actors/`、`19_files/`、`20_codable/`
- Modify: 根 `Package.swift`（追加五组目标）

- [ ] 示例先行（16 强引用循环实测 deinit 不跑 + weak/unowned 修复 + 捕获列表；17 async let +
  TaskGroup 固定任务集汇总断言 + 取消协作；18 actor 计数器竞态对照（非 actor 类 vs actor）+
  Sendable 检查实测；19 FileManager 临时目录读写 + URL/Data（跑后清理）；20 Codable 自定义
  CodingKey + JSONEncoder 日期/键策略 + 往返断言）
- [ ] `-Example` 逐个四层绿 + `-All` 回归
- [ ] 正文 5 章 + 提交 `docs(swift): 16–20 章——ARC/并发/actor/文件IO/Codable + 五示例验证通过`

### Task 6: 批次 5a——测试与工程 21–23（3 章 3 示例，含首个嵌套独立包）

**Files:**
- Create: `docs/21-testing.md` ⭐（swift-testing 为主）、`docs/22-spm.md`（嵌套包案例）、
  `docs/23-tooling.md`（C 互操作/静态分发/钉版复盘）
- Create: `examples/21_testing/`（根包示例：参数化 @Test/suite/tag 演示——本章测试本身就是
  教材）、`examples/22_spm/`（**嵌套独立包**：library 目标 + executable 目标 + 路径依赖本地
  mini 库 + 资源文件）、`examples/23_tooling/`（根包示例：DllImport 调 UCRT/Win32 实测 +
  命令行参数演示）
- Modify: 根 `Package.swift`（追加 Ch21Testing、Ch23Tooling 两组；22_spm 不进根包——
  验证根包 build 不受嵌套 Package.swift 干扰）

- [ ] 示例先行（21 用 suite + 参数化覆盖纯函数；22 子包 `swift build`/`swift run` 独立绿；
  23 `extern`/DllImport 实测调 `system()` 或 Win32 `GetTickCountW` 类 API——以 6.3.3 实测可编为准）
- [ ] 22_spm 走独立包验证路径（build.ps1 分支）；21/23 走普通四层
- [ ] `-All` 全绿（根包 21 示例 + 独立包 1 个）
- [ ] 正文 3 章 + 提交 `docs(swift): 21–23 章——swift-testing/SPM 深入/工具与互操作 + 三示例验证（22 为嵌套独立包）`

### Task 7: 批次 5b——24 章实战迷你 grep（独立工程）

**Files:**
- Create: `docs/24-minigrep.md` ⭐（架构图/数据流/分模块讲解 + 收官一节）
- Create: `examples/24_minigrep/`（嵌套独立包：`Sources/MinigrepCore/`（纯逻辑库：参数解析/
  匹配器/报告模型）+ `Sources/minigrep/`（CLI 入口）+ `Tests/MinigrepCoreTests/`（核心逻辑
  测试）+ `TestFixtures/`（固定样例文件）；功能：递归遍历 + TaskGroup 并发 + ANSI 高亮 +
  `--json` Codable 报告 + 退出码 0/1/2 约定）
- Modify: `build.ps1`（`-All` 分支纳入独立包验证）

**Interfaces:**
- Consumes: 17/18 章并发 API、19 章 FileManager、20 章 Codable、21 章 swift-testing
- Produces: 独立可分发教学工程（minigrep 用法：`minigrep <pattern> [path] [--json]`）

- [ ] 先写核心库与测试（MinigrepCore：pattern 编译/行匹配/报告聚合纯函数），`swift test` 绿
- [ ] 再写 CLI 入口（并发遍历 + ANSI + --json），准备 TestFixtures 固定样例
- [ ] 独立包全流程绿：`swift build` → `swift test` → 对 TestFixtures 跑 `swift run minigrep
  "lorem" TestFixtures`（exit 0 + 命中行 + `--json` 可解析）；无匹配 exit 1 路径也验一次
- [ ] build.ps1 `-Example 24_minigrep` 独立包分支绿 + `-All` 终验
- [ ] 正文 24 章 + 提交 `docs(swift): 24 章——实战迷你 grep（并发/高亮/JSON 报告/测试全覆盖）+ 独立工程验证通过`

### Task 8: 收官——01 章/CHEATSheet/README/根 README/记忆/终验

**Files:**
- Create: `docs/01-overview.md`（全景：历史/演进表/Swift 6 语言模式/scoop 6.4.0 坏包故事与
  6.3.3 钉版/REPL——吸收全部批次实测坑的"元视角"。**注**：spec §9 原将 01 章排在批 1，
  实施改为收官时写——01 章需要全部批次的坑位素材才能写出"元视角"，交付物不变）、
  `swift/CHEATSheet.md`（语法速查 + 6.3.3/Windows 坑位索引）
- Rewrite: `swift/README.md`（正式版：定位段 + ⚠️过时资料警告 + 目录结构 + 24 章索引表 +
  工具链 + 验证命令 + 相关教程）
- Modify: 根 `README.md` swift 条目
- Create: 记忆 `G:\xulun\.claude\projects\G--code-guide\memory\swift-tutorial-build.md` +
  更新 MEMORY.md 索引

- [ ] `pwsh build.ps1 -All` 全绿（根包 21 示例 + 独立包 2 个）；`./run-all.sh` 同验
- [ ] 24 章导航链逐章抽查（上一章/下一章链接有效、01/24 端点正确）
- [ ] 提交 `docs(swift): 收官——01 全景 + CHEATSheet + README，23 示例四层终验全绿`
- [ ] 写记忆文件（结构 + 全部实测坑位索引），勾掉本计划状态行

## 执行勘误（实施中实测发现，随时追加）

（暂无）
