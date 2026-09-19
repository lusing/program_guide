# 22 · Swift Package Manager

> 对应示例：`examples/22_spm/`——**嵌套独立包**（本教程根包之外的第二包）

## 22.1 包的解剖：目标、产品、依赖

```swift
// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "spm-demo",
    products: [
        .library(name: "MiniLib", targets: ["MiniLib"]),
        .executable(name: "spmdemo", targets: ["spmdemo"]),
    ],
    targets: [
        .target(name: "MiniLib", path: "Sources/MiniLib"),
        .executableTarget(name: "spmdemo", dependencies: ["MiniLib"], path: "Sources/spmdemo"),
        .testTarget(name: "MiniLibTests", dependencies: ["MiniLib"], path: "Tests/MiniLibTests"),
    ]
)
```

五个概念一图流：

```text
Package（包：一个版本化单元）
 ├── products（对外交付什么：库/可执行）
 │     └── 指向 targets
 ├── targets（编译单元：一个模块）
 │     ├── target        库目标（被别人 import）
 │     ├── executableTarget  可执行目标（有 main.swift）
 │     └── testTarget    测试目标（依赖被测目标）
 ├── dependencies（依赖别的包，见 22.4）
 └── swift-tools-version（清单语法的版本——第一行，决定可用 API）
```

**目标间的依赖是图**：`spmdemo → MiniLib`，`MiniLibTests → MiniLib`。模块名 = 目标名
（这就是本教程根包 `Ch02Hello` 不能叫 `02_hello` 的原因）。`path:` 可定制目录（默认
`Sources/<目标名>`——22 章示例用默认布局，根包用 path 映射数字目录，两种都见过）。

## 22.2 目录布局与惯例

```text
examples/22_spm/
├── Package.swift
├── Sources/
│   ├── MiniLib/            库目标（public API 的家）
│   │   └── Geometry.swift
│   └── spmdemo/            可执行目标（薄壳）
│       └── main.swift
└── Tests/
    └── MiniLibTests/       测试目标（只测库）
        └── GeometryTests.swift
```

**库做逻辑、壳做组装**：spmdemo 的 main.swift 只做"参数解析 → 调库 → 打印"——
可执行目标难测试（main.swift 的顶层代码没法 import），逻辑下沉到库才能被
`@testable import` 够到。本教程每章示例的"纯函数区 + main 组装"就是这条纪律的
微型版。

## 22.3 常用命令

```bash
swift build                     # 编译（Debug）
swift build -c release          # Release（-O + WMO）
swift test                      # 跑测试
swift run spmdemo 3 4           # 运行可执行产品（可带参数）
swift run --package-path .      # 指定包路径（本教程在子目录里跑就用 cd 或 --package-path）
swift package describe          # 打印包结构清单（核对解析结果）
swift package clean             # 清缓存
```

产物在 `.build/<配置>/`（Debug/Release），`swift run` 自动处理运行时 PATH（02 章
的 DLL 问题在 SPM 内部无感）。

## 22.4 依赖管理：本地与远程

```swift
dependencies: [
    // 本地路径依赖（教程/单仓多包的主力）
    .package(path: "../MiniLib"),
    // Git 依赖（版本区间）
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    // 分支/精确修订（慎用）
    .package(url: "...", branch: "main"),
]
// ...
.target(dependencies: [
    .product(name: "ArgumentParser", package: "swift-argument-parser"),
])
```

- **path 依赖**零网络、改了立即生效（教程环境的正解，22 章示例的 spmdemo→MiniLib
  是目标级依赖，同包内不需要 path）；
- **Git 依赖**按语义版本解析，锁定写入 `Package.resolved`（进版本库，团队可复现）；
- 使用依赖的**产品**要在 target 的 dependencies 里再声明一次（package 管下载，
  target 管链接）。

第一次拉依赖需要网络；离线环境先 `swift package resolve` 预热或全用 path 依赖。

## 22.5 资源与宏一瞥

```swift
.target(name: "Data", resources: [.process("Data/config.json"), .copy("Raw/")])
// 代码里：Bundle.module.url(forResource: "config", withExtension: "json")
```

资源打进包后在 `Bundle.module` 下取（`.process` 按平台优化，`.copy` 原样拷贝）。
宏包（`CompilerMacros` 目标 + `macro` 产品）是 5.9+ 的高级特性——swift-testing 的
`@Test`/`#expect` 就是宏，本教程只当用户不当作者。

## 22.6 本教程的"根包 + 嵌套包"结构

```text
swift/
├── Package.swift          根包：21 个可执行目标 + 测试（全显式 path，无 glob）
└── examples/
    ├── 02_hello/ ... 21_testing/, 23_tooling/   根包成员
    ├── 22_spm/            ← 自带 Package.swift：根包"看不见"它（path 不含它）
    └── 24_minigrep/       ← 同上
```

根包目标全用显式 `path:`，不写 `examples/*` 通配——嵌套的 Package.swift 目录不在
任何目标的 path 里，SPM 不会把它当源码扫（实测验证）。验证脚本对两种包分而治之：
根包成员走 `swift build --target`，独立包成员 cd 进去自成一套。

## 22.7 坑位清单（含实测）

1. **目标名 = 模块名 = 合法标识符**：数字开头不行（根包 ChNN 命名的由来）；
   目录名可以随意（path: 映射）。
2. **可执行目标难测试**：main.swift 顶层代码 import 不到——"库做逻辑、壳做组装"
   不是洁癖，是可测试性设计（24 章实战的 MinigrepCore 拆分同理由）。
3. **`swift test` 构建全部测试目标**（02 章坑的机制版）：任何一章测试编译不过，
   其他章的 --filter 也跑不动——报错看文件路径定位章号。
4. **`Package.resolved` 要进版本库**（应用类项目）：可复现构建靠它；库项目则通常
   忽略（把版本区间留给下游解析）。
5. **同名目标在根包与嵌套包会打架吗**：不会（互不可见），但**两个嵌套包之间**
   同名产品无冲突、同 Git 依赖会被各自解析缓存（`~//.swiftpm/cache` 共享下载）。
6. **修改 Package.swift 后的"幽灵缓存"**：偶尔清单缓存过期报奇怪的错——
   `swift package reset`（删 .build）是万金油（build.ps1 的 -Clean 同款）。

上一章：[21 · 测试](21-testing.md) ｜ 下一章：[23 · 工具链与互操作](23-tooling.md) ｜ 返回：[README](../README.md)
