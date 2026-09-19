# macOS 应用开发指南

> macOS 原生应用开发讲的是 **Cocoa** 这一整套东西：AppKit 负责窗口、控件、绘图、菜单这些界面能力；Foundation 提供字符串、集合、数据、日期这些地基类；而它们全部建立在 **Objective-C 运行时**之上——消息发送、selector、KVO、Bindings、XIB 里的 outlet/action，无一不是 OC 语义。即使你只写 Swift，也躲不开它：Swift 与 OC 在 Foundation/AppKit 这一层是**双向桥接**的，桥接处的「看起来一样其实不一样」正是大多数 bug 的来源。

本教程面向「想真正搞懂 macOS 开发、而不是只会拖 Xcode 控件」的读者，按依赖链组织为 **20 章（五篇）**，每章对应 `examples/` 下一个**可编译、可运行、可自测**的示例，全部用本机 Xcode 16.2（Swift 6.0.3）+ Command Line Tools **双工具链**编译验证，输出逐字节比对。全部示例**不打开 Xcode**——只用 `swiftc` / `clang` / `ibtool` 在终端里编出来跑，因为这样你才知道 Xcode 到底替你做了什么。

## 目录

### 第一篇 入门与工具链

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [01 工具链](docs/01-toolchain.md) | `xcrun`、两套 SDK、`ibtool`、部署目标 vs `#available`、六条判定标准 | 不打开 Xcode，怎么把一个 AppKit 程序编出来跑起来 |
| [02 第一个 AppKit 应用](docs/02-hello-appkit.md) | `NSApplication` / `NSWindow`、左下角原点、`--selftest` 自测模式 | 一个最小的 macOS 程序由哪几块拼成 |
| [03 AppKit 架构](docs/03-appkit-architecture.md) | 响应链、委托的可选方法、target-action、MVC | 事件从哪来、该交给谁处理 |

### 第二篇 语言与 Foundation（Objective-C / Swift 基础）

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [04 Objective-C 语言基础](docs/04-objc-language.md) | 消息发送、nil 消息、SEL、协议与分类、block、`NSError`、`@try`、ARC 要点 | 读懂/改动/排查 OC 代码所需的最小集合是什么 |
| [05 Foundation（OC 篇）](docs/05-objc-foundation.md) | `NSString.length` 是 UTF-16 码元、`NSNotFound` ≠ -1、`NSNumber`/`NSValue`/`NSNull`、集合、`NSData`、日期、JSON | OC 侧的地基类有哪些「一半安全一半不安全」的坑 |
| [06 Foundation（Swift 篇）](docs/06-swift-foundation.md) | `String`↔`NSString`、`Range`↔`NSRange`、`Data` 值语义、`Codable`、相等性、`NotificationCenter` | Swift 的值类型与 OC 的引用类型桥接时哪里会错位 |
| [07 OC 与 Swift 混编](docs/07-objc-swift-mix.md) | bridging header、生成的 `<Module>-Swift.h`、nullability 注解、轻量泛型 | 两个方向（Swift→OC、OC→Swift）各怎么打通 |

### 第三篇 窗口与控件

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [08 窗口、sheet、模态](docs/08-window-and-modals.md) | `frame` vs `contentRect`、window level、`NSAlert`、`NSSavePanel` | 窗口和各种「弹出来」的东西怎么摆、怎么阻塞输入 |
| [09 布局](docs/09-layout.md) | `autoresizingMask`、Auto Layout、`NSStackView`、`NSScrollView` | 控件怎么随窗口缩放而不散架 |
| [10 常用控件](docs/10-controls.md) | `NSButton` 四种类型、`NSTextField`、`NSPopUpButton`、`NSStepper` | 按钮/输入框/下拉/步进器怎么用、事件怎么回来 |
| [11 KVC / KVO / Bindings](docs/11-kvo-bindings.md) | `@objc dynamic`、KVO 观察、Bindings 双向绑定、`NSArrayController` | 数据变了界面怎么自动跟着变 |
| [12 表格与大纲](docs/12-table-outline.md) | view-based vs cell-based、`NSTableView`、`NSOutlineView` 的 item 模型 | 列表和树形结构怎么展示 |

### 第四篇 文本、资源与绘图

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [13 富文本与 TextKit](docs/13-attributed-text.md) | 属性串共享引用、字体度量、storage-layout-container 三层 | 带格式的文本怎么量、怎么排、怎么画 |
| [14 XIB 与 nib](docs/14-xib-and-nib.md) | `ibtool`、File's Owner、outlet/action 连线、`customModule` | 界面文件怎么变成运行时对象、连线怎么生效 |
| [15 绘图](docs/15-drawing.md) | `NSRect` 运算、`NSBezierPath`、语义色、`bitmapData`、`NSImage`、变换 | 自定义内容怎么画到屏幕上 |

### 第五篇 数据、打包与系统集成

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [16 持久化](docs/16-persistence.md) | `UserDefaults` 的域、plist、文件读写、本地化、沙箱 | 数据存哪、怎么存、沙箱拦了什么 |
| [17 打包](docs/17-packaging.md) | `.app` 包结构、`Info.plist`、`.lproj`、签名与公证 | 怎么把可执行文件变成能双击、能分发的 App |
| [18 并发](docs/18-concurrency.md) | GCD、`concurrentPerform`、`OperationQueue`、主线程规则 | 怎么「同时做多件事」且不违反 UI 线程规则 |
| [19 菜单、状态栏、工具栏](docs/19-menus.md) | `NSMenu`、`target=nil` 走响应链、`NSStatusItem`、`NSToolbar` | 命令入口和常驻界面怎么搭 |
| [20 剪贴板、拖放、撤销](docs/20-pasteboard-undo.md) | `NSPasteboard` 多类型、拖放协商、`NSUndoManager` 分组 | 复制粘贴、拖放、撤销怎么实现 |

## 示例代码

`examples/` 下每个目录对应一个可编译工程，全部经本机双工具链编译并运行验证（20 个示例 × 2 通道，构建说明见 [README](README.md)）。每个 AppKit 示例都支持 `--selftest`：不弹窗、不建窗口，只跑断言然后退出。

| # | 示例 | 章 | 一句话 |
|---|------|----|----|
| 01 | `01_toolchain` | 01 | 编译期/运行期环境事实与六条判定 |
| 02 | `02_hello_appkit` | 02 | 最小 AppKit 程序骨架 |
| 03 | `03_appkit_architecture` | 03 | 响应链 / 委托 / target-action 观测 |
| 04 | `04_objc_language` | 04 | OC 消息发送 / nil / SEL / 协议分类 / block / NSError |
| 05 | `05_objc_foundation` | 05 | OC 侧 Foundation 的字符串/集合/数据/日期/JSON 坑 |
| 06 | `06_swift_foundation` | 06 | Swift 侧桥接 / Codable / 值语义 / 相等性 |
| 07 | `07_objc_swift_mix` | 07 | OC↔Swift 双向混编（含 bridging header） |
| 08 | `08_window_and_modals` | 08 | 窗口几何 / level / 警告框 / 存取面板 |
| 09 | `09_layout` | 09 | autoresizing / Auto Layout / StackView / ScrollView |
| 10 | `10_controls` | 10 | 按钮四型 / 文本框 / 下拉 / 步进器 |
| 11 | `11_kvo_bindings` | 11 | KVC / KVO / Bindings 双向 / NSArrayController |
| 12 | `12_table_outline` | 12 | view-based 表格 + 大纲的 item 模型 |
| 13 | `13_attributed_text` | 13 | 属性串 / 字体度量 / TextKit 三层 |
| 14 | `14_xib_and_nib` | 14 | XIB 编译成 nib + outlet 连线加载 |
| 15 | `15_drawing` | 15 | 几何 / 路径 / 颜色 / 位图 / 变换 |
| 16 | `16_persistence` | 16 | UserDefaults 域 / plist / 文件 / 本地化 |
| 17 | `17_packaging` | 17 | 手工搭 .app 包 + Info.plist + 签名 |
| 18 | `18_concurrency` | 18 | GCD / concurrentPerform / OperationQueue / 主线程 |
| 19 | `19_menus` | 19 | 菜单 / 状态栏项 / 工具栏 |
| 20 | `20_pasteboard_undo` | 20 | 剪贴板多类型 / 拖放协商 / 撤销分组 |

## 建议阅读顺序

- **从零开始**：01 → 02 → 03 → 09 → 10 → 14 → 11 → 12 → 16 → 17
- **要写 Objective-C / 维护老项目**：04 → 05 → 07 → 13
- **专项**：06（Swift 侧桥接）、08（窗口）、15（绘图）、18（并发）、19（菜单）、20（拖放撤销）

> 第二篇（04–07）是本教程的地基：AppKit 的每一条 API 都是 OC 语义，Foundation 的每一个类都有 Swift/OC 两副面孔。把这几章读透，后面所有界面章节都会顺理成章。
