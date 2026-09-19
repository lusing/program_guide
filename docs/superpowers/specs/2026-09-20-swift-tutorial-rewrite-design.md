# Swift 教程重写设计（2026-09-20）

## 1. 背景与问题

`swift/` 目录现状：单个 `Swift编程指南.md`（377 行，特性速览式）+ 10 个平铺单文件示例
（每个仅 2–35 行）+ `build.ps1`（**只编译不运行不测试**，产物从未跑过）+ `README.md`。
无 docs/ 分章、无章号=示例号对应、无坑位清单、无 CHEATSheet、无测试。

与 cpp20/rust/go/zig 教程标准（docs/ 24 章分章 + 章号=示例目录号 + 递进讲解 +
坑位清单 + 多层验证（含测试）+ CHEATSheet）差距极大。Swift 6 的严格并发、
swift-testing 新测试框架、Swift 6.x 生态现状完全没有覆盖。

## 2. 目标与非目标

**目标**：重写为 24 章独立文档（每章 200–350 行，特色章不压缩）、章号 = 示例目录号
（02–24 共 23 个示例目录）；定位"会编程（C/C++/Rust 背景最佳）、初学 Swift，从零教到
Swift 6 语言模式 + 严格并发 + SPM 工程化"；主线 **Swift 6.3.3（scoop，x86_64-windows-msvc）**；
全部示例在本机实测四层验证通过；第 24 章实战项目为**迷你 grep**（对齐 cpp20/rust/go/zig 收官标准）。

**非目标**：
- 不教 SwiftUI/iOS/macOS GUI（仓库已有 iosdev/macosdev 承接，README 给跳转）
- 不教 Xcode（通篇 CLI：swiftc + SPM；Xcode 在 01 章一段带过）
- 不做服务端生态（Vapor 等）、嵌入式（Embedded Swift 一瞥）
- 不教 Linux/macOS 实操交叉（讲原理与命令，实测只做 Windows）

## 3. 已确认决策

| 决策点 | 结论 |
|---|---|
| 工具链 | **钉死 6.3.3**：`G:\scoop\apps\swift\6.3.3\Toolchains\6.3.3+NoAsserts\usr\bin\swift.exe`（scoop 6.4.0 包损坏，见 §4）；scoop 修好后改 build.ps1 顶部 3 行环境配方即可升级 |
| 章节规模 | 24 章完整版（语言核心 14 + 内存并发 3 + 文件序列化测试 3 + 工程生态 2 + 实战 1，⭐ 特色章 8 个） |
| 读者定位 | 会编程、初学 Swift，Swift 6 语言模式现代写法；旧写法（OC 风格 API、XCTest 优先时代）只在坑位清单教"认得" |
| 实战项目 | 第 24 章迷你 grep（递归遍历 + TaskGroup 并发 + ANSI 高亮 + Codable JSON 报告 + swift-testing 测试） |
| 包结构 | 根 `Package.swift`（swift-tools-version 6.0）：02–21、23 共 21 个可执行目标 + 各章测试目标；`22_spm`/`24_minigrep` 为嵌套独立包（根包显式路径不受干扰——已实测） |
| 目标命名 | SPM 目标名不能数字开头 → `Ch02Hello` 形态，`path:` 映射到 `examples/NN_name/Sources/NN_name`（已实测） |
| 测试框架 | **swift-testing 为主**（`@Test`/`#expect`/参数化/suite），XCTest 一节教认读；测试目标 `@testable import` 可执行目标（已实测可行） |
| 验证策略 | 每示例四层：swift-format lint --strict → swift build --target → swift test --filter → swift run（exit 0） |
| 旧文件 | 删 `Swift编程指南.md`、旧 `examples/*.swift` 10 项、旧 `build/`；`build.ps1`/`README.md` 原地重写 |
| 新增 | `docs/` 24 章、新 `examples/` 23 目录、`CHEATSheet.md`、`run-all.sh`、根 README 条目更新 |

## 4. 环境实测结论（2026-09-19/20，Swift 6.3.3 + 6.4.0 @ scoop，Windows 11 + VS18）

| 项 | 结论 |
|---|---|
| **6.4.0 坏包**（本次最大坑） | scoop 的 6.4.0 **整个 `Runtimes\usr\bin` 目录缺失**（swiftCore/Foundation*/dispatch/swiftSwiftOnoneSupport/swift_Concurrency 等运行时 DLL 全没有）。动态链接产物一运行即 `0xC0000135`；SPM 清单 exe 导入 PackageDescription.dll→Foundation.dll 也死 → `swift build` 两种构建系统全灭。6.3.3 包完整（Runtimes 31 项齐全），**全链路实测绿灯** → 钉 6.3.3 |
| swiftbuild 新构建系统 | 6.4 默认 `swiftbuild`：扫描 `Toolchains\` 时撞上 scoop 压平别名 `usr` 目录 → `Unable to extract version from toolchain directory name` 直接死。6.3.3 默认 `native`（llbuild）正常；`--build-system native` 已标 deprecated——升级 6.4+ 时的已知雷，23 章收录 |
| 环境配方 | 三件套：`SDKROOT` → 6.3.3 的 Windows.sdk（**必须覆盖**，scoop 设的指向 `current`=6.4.0，混编报 `module compiled with Swift 6.4 cannot be imported by the Swift 6.3.3 compiler`）；PATH 前置 ① `Runtimes\usr\bin`（运行时 DLL）② `Toolchains\6.3.3+NoAsserts\usr\bin`（编译器）③ `Toolchains\usr\lib\swift\pm\ManifestAPI`（清单 exe 的 PackageDescription.dll）。build.ps1 自动设置 |
| scoop 布局 | `current` junction → 6.4.0；MSYS 对 junction 的 ls/find/stat **间歇性失明**（同一路径时有时无）→ 脚本一律用真实版本路径，不碰 `current` |
| 数字目录 | SPM 目标名必须合法标识符（不能 `02_hello`），但 `path:` 可指向任意目录 → `Ch02Hello` + `examples/02_hello/Sources/02_hello` 方案实测通过 |
| 可执行目标测试 | testTarget 依赖 executableTarget + `@testable import`，main.swift 里的顶层符号对测试可见——实测通过（这是每章测试的基石） |
| swift-testing | Windows 完全可用：`√ Test addWorks() passed`、参数化/`#expect` 宏正常；与 XCTest 同跑互不干扰 |
| swift-format | 6.3.3 自带 `swift-format.exe --version`=6.3.3；`lint --strict` 可用（warning 也算失败，正好当验证层） |
| MSVC 链接 | VS18 (14.51) + Win SDK 10.0.28000 自动发现正常；lld-link 输出 `.lib/.exp` 伴随文件（build 目录清扫项） |
| 运行产物 | exe 依赖运行时 DLL → 直接双击/裸跑不行（PATH 无 Runtimes）；教程统一 `swift run`，独立分发讲 `-static-stdlib`（23 章） |

其余坑位（String.Index、并发宏、Codable 细节、Windows Foundation 差异等）实施中边写边实测累积。

## 5. 章节结构（docs/，24 章，⭐ = 特色重点细讲）

| # | 文件 | 主题 | 示例 |
|---|---|---|---|
| 01 | `01-overview.md` | 全景：Chris Lattner 与 Swift 史、开源与平台（Apple/Linux/Windows/WASM 一瞥）、语言演进表（3→4→5.7→6 里程碑）、Swift 6 语言模式与严格并发、工具链安装（scoop 坑位：6.4.0 坏包故事+6.3.3 钉版）、REPL 一瞥 | — |
| 02 | `02-hello.md` | 第一个程序：三种形态（REPL/脚本 `swift file.swift`/编译 swiftc）、print 与字符串插值、顶层代码规则（main.swift）、SPM 工程解剖（本教程根包结构）、运行时 DLL 与 PATH 坑 | `02_hello` |
| 03 | `03-basics.md` | let/var 与值语义预告、基本类型（Int 家族/Double/Bool/Character/String 初识）、类型推断、字面量、整数溢出（`&+` 家族）、转换必须显式（无隐式数值转换——C 背景第一坑）、元组 | `03_basics` |
| 04 | `04-control.md` | if、⭐guard（与 if 的本质区别：作用域收窄）、switch（穷尽性、模式匹配初见、no fallthrough）、where、for-in + Range 家族、while/repeat、labeled break/continue、三元与 `??` | `04_control` |
| 05 | `05-functions.md` | 参数标签与 `_`（API 设计利器）、默认值、inout、变参、函数是一等公民、重载、`-> Void` 与 Optional 返回、never | `05_functions` |
| 06 | `06-optionals.md` ⭐ | 可选类型（nil 不是 null）、`?`/`!` 家族语义、if let/guard let（shadowing）、可选链 `?.`、`??`、map/flatMap/compactMap、隐式解包可选什么时候可以、 fatalError 与 precondition | `06_optionals` |
| 07 | `07-structs-classes.md` | struct（值语义/逐成员初始化器/mutating）、class（引用语义/deinit/继承一瞥）、二者选择决策树、存储/计算属性、属性观察者 willSet/didSet、static 与类型属性 | `07_structs_classes` |
| 08 | `08-enums.md` | 枚举即代数数据类型、关联值（附载荷）、raw value、indirect 递归枚举、模式匹配深用、CaseIterable/自定义构造、struct vs enum vs class 选型 | `08_enums` |
| 09 | `09-protocols.md` ⭐ | 协议即契约、conformance、extension 默认实现（面向协议编程）、协议作为类型、some vs any（5.7 后正确姿势）、标准库协议大观（Equatable/Hashable/Comparable/CustomStringConvertible/Error）、协议见证一瞥 | `09_protocols` |
| 10 | `10-generics.md` | 泛型函数/类型、类型约束、where 子句、关联类型与 PAT 风格泛型、泛型与协议的选择、不透明类型深入 | `10_generics` |
| 11 | `11-closures.md` | 闭包表达式语法进化（完整→尾随→简写）、捕获语义（值捕获 vs 引用捕获）、逃逸/非逃逸 `@escaping`、捕获列表预告（16 章深讲）、高阶函数实战、@autoclosure、lazy 与闭包 | `11_closures` |
| 12 | `12-errors.md` | throws 函数与 try 家族（try?/try!）、do-catch 模式匹配、Error 协议与自定义错误枚举、rethrows、⭐typed throws（Swift 6）、Result 与 throws 互转、错误分层（可恢复 vs precondition/fatalError） | `12_errors` |
| 13 | `13-collections.md` | Array（值语义 COW、切片与 Index 坑）、Set（Hashable 要求）、Dictionary（键要求/遍历无序）、常用算法（sort/filter/reduce/contains…）、Collection 协议族一瞥、不可变与拷贝时机 | `13_collections` |
| 14 | `14-strings.md` ⭐ | String 是值类型 Collection of Character、grapheme cluster（é 家族实测）、String.Index 为什么不是 Int（下标坑）、子串 Substring 与 COW、常用 API、多行字符串与原始字符串、⭐Regex（Swift 5.7 字面量 + builder 一瞥） | `14_strings` |
| 15 | `15-extensions.md` | extension 万物可扩展、计算属性/方法/构造器、 retroactive conformance 与孤儿 conformance 坑、subscript（含参数标签）、泛型约束 extension、属性进阶（lazy/property wrapper 一瞥） | `15_extensions` |
| 16 | `16-arc.md` ⭐ | ARC vs GC、强引用循环实测（deinit 不跑）、weak/unowned 选择、闭包捕获列表 [weak self]、COW 深入（isKnownUniquelyReferenced 思想）、内存独占检查（exclusivity）、值语义设计守则 | `16_arc` |
| 17 | `17-concurrency.md` ⭐ | async/await、异步函数与续体、结构化并发（async let/TaskGroup）、非结构化 Task、取消（cooperative cancellation）、AsyncSequence 一瞥、@MainActor 预告 | `17_concurrency` |
| 18 | `18-actors.md` ⭐ | 数据竞争为什么难、actor 隔离域、actor 方法与 await、Sendable（结构化/sendable 检查）、@MainActor 与 UI 线程、非隔离与 unsafe、Swift 6 严格并发迁移心法（Sendable 错误解读） | `18_actors` |
| 19 | `19-files.md` | Foundation 是什么（Windows 上的状态）、URL（不是字符串）、Data、String 读写文件、FileManager（目录遍历/创建/临时目录）、资源与 Bundle 一瞥、Windows 路径分隔符坑 | `19_files` |
| 20 | `20-codable.md` ⭐ | Codable 全家（Codable/Encodable/Decodable）、JSONEncoder/Decoder 配置（键策略/日期）、自定义 CodingKey 与 encode(to:)、嵌套与数组、 Codable + 多态的坑、 toJSON 从字符串 | `20_codable` |
| 21 | `21-testing.md` ⭐ | swift-testing（@Test/#expect/#require、参数化、suite、tag、并行）、TDD 工作流（改→测→看）、XCTest 认读（网上资料多）、测试可执行目标的 @testable 机制（本教程结构就是实例）、覆盖率一瞥 | `21_testing` |
| 22 | `22-spm.md` | SPM 深入：Package.swift 全字段（目标/产品/依赖/资源/宏）、swift build/test/run 分层、依赖管理（本地路径+Git 一瞥，离线实测以路径依赖为主）、多目标库+可执行拆分、嵌套包与根包关系（本教程自身就是案例） | `22_spm`（嵌套独立包） |
| 23 | `23-tooling.md` | 工具链与互操作：C 互操作（DllImport 调 Win32/UCRT 实测）、swift-format（.swift-format 配置、lint/format）、静态链接 `-static-stdlib` 分发、docc 一瞥、调试（LLDB）、编译模式（WMO/-O）、钉版与升级心法（6.4.0 坏包复盘） | `23_tooling` |
| 24 | `24-minigrep.md` ⭐ | 实战：迷你 grep——参数解析（子命令风格）、递归目录遍历（19 章）、TaskGroup 并发搜索（17/18 章）、ANSI 高亮输出、Codable 生成 JSON 报告（20 章）、过滤/统计/退出码约定、swift-testing 全覆盖（21 章）、工程结构 = 22 章独立包 | `24_minigrep`（独立工程） |

吸收旧内容：旧指南的语言特性速览按章拆散重组；示例代码全部重写（旧的只 print 不断言）。

## 6. 示例与验证

- 每章示例 `examples/NN_name/`：
  - `Sources/NN_name/main.swift`——章主程序：按 `// ═══ N.M 标题` 分节（与正文小节对应），
    关键路径用断言式输出（打印"计算值 → 期望值"格式），末行 `==== NN 结束 ====`。
  - `Tests/NN_nameTests/NN_nameTests.swift`——swift-testing：把 main.swift 的核心函数
    （纯逻辑部分）用 `@Test` + `#expect` 覆盖，每章 3–10 个用例，含至少 1 个中文/边界用例。
- 根 `Package.swift` 声明全部目标（显式 path，无 glob）；`22_spm`/`24_minigrep` 不在根包。
- `build.ps1`（pwsh 7，UTF-8 无 BOM，参数 `-All/-Example NN_name/-Clean`）：
  - 环境配方自动设置（§4 三件套 + `[Console]::OutputEncoding` UTF8 + chcp 65001）
  - 普通示例四层：`swift-format lint --strict --recursive <dir>` → `swift build --target ChNN…`
    → `swift test --filter <TestsTarget>` → `swift run ChNN…`（exit 0 + 输出含结束标记）
  - 独立包示例（22/24）：进入子目录 `swift build` → `swift test`（24 有测试）→ `swift run` exit 0
  - `-Clean`：删 `.build/` 与 `build/`
- `run-all.sh`（Git Bash）等价实现（环境配方用 export + winpath 转换）；任一失败退出码 1。

## 7. 交付物清单

1. `swift/docs/01-overview.md` … `24-minigrep.md`（24 章）
2. `swift/examples/02_hello/` … `24_minigrep/`（23 个示例目录）
3. `swift/Package.swift`（根包）+ `swift/build.ps1`（重写）+ `swift/run-all.sh`（新增）
4. `swift/CHEATSheet.md`（语法速查 + 6.3.3/Windows 坑位索引）
5. `swift/README.md`（重写：定位、目录结构、章节索引表、工具链、验证命令、相关教程）
6. 删除：`Swift编程指南.md`、旧 `examples/*.swift` 10 项、旧 `build/`
7. 根 `README.md` swift 条目更新
8. 记忆文件：`swift-tutorial-build.md`（实测坑位 + 结构）

## 8. 风险与对策

| 风险 | 对策 |
|---|---|
| 网上资料多 Swift 3/4 时代或 Xcode 向，API 说法过时 | 一切以 6.3.3 实测为准；some/any、typed throws、swift-testing 等新姿势优先，旧写法进坑位清单 |
| Windows 上 Foundation/并发 API 与 macOS 行为差异（路径、换行、编码） | 每处差异实测后写进坑位；UTF-8 纪律沿用全仓经验（源码无 BOM + 控制台 65001） |
| swiftbuild 默认化后 `--build-system native` 被移除（升级 6.4+） | 23 章钉版心法收录；build.ps1 顶部版本常量集中管理，scoop 修复后一处切换 |
| swift-format --strict 对教学代码风格过严 | 实测已可行（探针仅报缩进警告，正好修正）；必要时加 `.swift-format` 配置文件放宽行宽 |
| 根包 22+ 目标增量编译变慢 | 单目标验证走 `--target/--filter`；全量验证每批一次；必要时 `-Clean` 复测 |
| 24 章 × 200–350 行 + 23 示例的写作量 | 分 5 批交付分批提交（§9），每批 build.ps1 全绿再 commit |
| 旧文件删除不可逆 | git 历史保留；删除与新结构同批提交，diff 清晰可审 |

## 9. 实施批次

| 批 | 内容 | 验收 |
|---|---|---|
| 1 | 脚手架（删旧、Package.swift、build.ps1、run-all.sh、README 骨架）+ 第 1–5 章 + 示例 02–05 | build.ps1 -All 绿 + commit |
| 2 | 第 6–10 章 + 示例 06–10 | 同上 |
| 3 | 第 11–15 章 + 示例 11–15 | 同上 |
| 4 | 第 16–20 章 + 示例 16–20 | 同上 |
| 5 | 第 21–24 章 + 示例 21–24 + CHEATSheet + README 收官 + 根 README + 记忆文件 | 同上 + 全书收官检查 |
