# Swift 编程指南（6.3.3）

面向**会编程（C++/Rust/Go 背景皆可）、初学 Swift** 的读者：从零教到 Swift 6 语言
模式 + 严格并发 + SPM 工程化。**Swift 特色全部独立成章细讲**：可选类型（06）、协议
与 some/any（09）、字符串与 Unicode 正确性（14）、ARC 与循环引用（16）、async/await
结构化并发（17）、actor 与 Sendable（18）、Codable（20）、swift-testing（21）、
SPM（22）。每章"读讲解 → 跑示例 → 改代码再跑"，全部示例四层验证通过
（format + build + test + 运行 exit 0）。

> ⚠️ 网上 Swift 教程半数是 3.x/4.x 时代（NSArray 桥接、XCTest 优先、无并发）。
> 本教程所有代码在 **6.3.3 实测**，每章坑位清单收录版本差异与 Windows 实测坑。

> ⚠️ 工具链注意：scoop 的 swift **6.4.0 包损坏**（缺整个 `Runtimes\usr\bin`，程序
> 一运行即 0xC00000135 崩溃，SPM 亦不可用）；本教程实测基于**完整可用的 6.3.3 包**，
> 脚本已钉死路径（01 章有完整故事与升级路径）。

## 目录结构

```text
swift/
├── README.md       本文件
├── CHEATSheet.md   语法速查 + 实测坑位索引
├── Package.swift   根包（每章示例一个可执行目标 + swift-testing 测试目标）
├── .swift-format   格式化配置（4 空格——swift-format 无配置时默认 2 空格）
├── docs/           24 章教程（01 → 24 顺序阅读）
├── examples/       23 个示例目录（章号 = 目录号；22/24 为嵌套独立包）
├── build.ps1       统一验证脚本（须 PowerShell 7 / pwsh 运行）
└── run-all.sh      Git Bash 等价验证入口
```

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 全景](docs/01-overview.md) | 设计哲学、版本演进、工具链、6.4.0 坑位复盘 | — |
| [02 第一个程序](docs/02-hello.md) | 三种运行形态、插值、顶层代码、根包解剖 | `02_hello` |
| [03 基础类型](docs/03-basics.md) | let/var、字面量、溢出、无隐式转换、元组 | `03_basics` |
| [04 控制流](docs/04-control.md) | guard、switch 穷尽与模式、Range、标签 | `04_control` |
| [05 函数](docs/05-functions.md) | 参数标签、inout、变参、函数类型、重载 | `05_functions` |
| [06 ⭐可选类型](docs/06-optionals.md) | 解包四式、可选链、map/compactMap | `06_optionals` |
| [07 结构体与类](docs/07-structs-classes.md) | 值/引用语义、属性观察者、deinit | `07_structs_classes` |
| [08 枚举](docs/08-enums.md) | 关联值、raw value、indirect、代数类型 | `08_enums` |
| [09 ⭐协议](docs/09-protocols.md) | 默认实现、some/any、标准库协议 | `09_protocols` |
| [10 泛型](docs/10-generics.md) | 约束、where、关联类型、条件 conform | `10_generics` |
| [11 闭包](docs/11-closures.md) | 捕获语义、逃逸、@autoclosure、lazy | `11_closures` |
| [12 错误处理](docs/12-errors.md) | try 家族、typed throws、Result、分层 | `12_errors` |
| [13 集合](docs/13-collections.md) | Array/Set/Dictionary、切片坑、算法 | `13_collections` |
| [14 ⭐字符串](docs/14-strings.md) | grapheme、String.Index、Substring、Regex | `14_strings` |
| [15 扩展与下标](docs/15-extensions.md) | 万物可扩、retroactive、property wrapper | `15_extensions` |
| [16 ⭐ARC 与内存](docs/16-arc.md) | 循环引用、weak/unowned、COW、独占 | `16_arc` |
| [17 ⭐并发 I](docs/17-concurrency.md) | async/await、TaskGroup、取消、Stream | `17_concurrency` |
| [18 ⭐并发 II](docs/18-actors.md) | actor、Sendable、@MainActor、严格并发 | `18_actors` |
| [19 文件与 IO](docs/19-files.md) | URL/Data/FileManager、Windows 路径坑 | `19_files` |
| [20 ⭐Codable](docs/20-codable.md) | 键映射、日期策略、手写编解码 | `20_codable` |
| [21 ⭐测试](docs/21-testing.md) | swift-testing 参数化/suite/tag | `21_testing` |
| [22 SPM](docs/22-spm.md) | 目标/产品/依赖、嵌套独立包 | `22_spm`（独立包） |
| [23 工具与互操作](docs/23-tooling.md) | WinSDK/ucrt、静态分发、钉版心法 | `23_tooling` |
| [24 实战：迷你 grep](docs/24-minigrep.md) | 递归 + 并发 + 高亮 + JSON 报告 + 测试 | `24_minigrep`（独立工程） |

## 构建工具链

- Swift **6.3.3**（scoop）：`G:\scoop\apps\swift\6.3.3\Toolchains\6.3.3+NoAsserts\usr\bin\swift.exe`
  ——脚本自动设置 SDKROOT 与运行时 PATH，用户无需手动配环境
- 需 Visual Studio 2022+ 的 MSVC 与 Windows SDK（链接用）
- 升级工具链：改 `build.ps1`/`run-all.sh` 顶部三行常量 → 冒烟 `-Example 02_hello`
  → 全绿再切（01/23 章钉版心法）

## 验证命令

```powershell
cd G:\code\guide\swift
pwsh -ExecutionPolicy Bypass -File build.ps1 -All                # 全部 23 个示例：format+build+test+run
pwsh -ExecutionPolicy Bypass -File build.ps1 -Example 12_errors  # 单个示例四层验证
pwsh -ExecutionPolicy Bypass -File build.ps1 -Clean              # 清理 .build
```

```bash
./run-all.sh            # Git Bash 入口，等价
./run-all.sh 12_errors  # 单个示例
```

单跑某个示例（每章标准学法）——改代码后重跑：

```bash
cd swift
swift run Ch12Errors            # 改完立刻看效果（环境由 build.ps1 配方，脚本内已固化）
swift test --filter Ch12ErrorsTests
```

## 相关教程

系统语言对照：[cpp20](../cpp20/README.md)、[rust](../rust/README.md)、[go](../go/README.md)、
[zig](../zig/README.md)、[dlang](../dlang/README.md)；速查见 [CHEATSheet.md](CHEATSheet.md)；
Apple 平台 GUI 开发见 [iosdev](../iosdev)、[macosdev](../macosdev)。
