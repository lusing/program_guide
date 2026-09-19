# iOS 应用开发指南

> iOS 原生应用开发讲的是 **两套界面框架 + 一套地基**：**SwiftUI** 是现代的声明式 UI（`body` 描述界面长什么样，系统负责画），**UIKit** 是它底下的命令式基石（`UIView`/`UIViewController`、Auto Layout、响应链）——即便你只写 SwiftUI，`UIHostingController`、手势、列表复用这些仍是 UIKit 在扛。而两者都建立在 **Foundation** 与 **Objective-C 运行时**之上：字符串、集合、`Codable`、`NotificationCenter`，以及 Swift↔OC 双向桥接处那些「看起来一样其实不一样」的坑。本教程 **SwiftUI 为主、UIKit 为底**，ObjC 与 Swift 并重。

本教程面向「想真正搞懂 iOS 开发、而不是只会拖 Xcode 控件」的读者，按依赖链组织为 **20 章（五篇）**，每章对应 `examples/` 下一个**可编译、可运行、可自测**的示例，全部用本机 **Xcode 16.2（Swift 6.0.3）+ iOS 18.2 SDK** 在 **iPhone 模拟器**里编译运行验证，`debug(-Onone)` 与 `release(-O)` 两个配置**输出逐字节一致**。全部示例**不打开 Xcode、不建窗口、不弹 UI**——只用 `swiftc` / `clang` 编成命令行可执行文件，`xcrun simctl spawn` 在模拟器里跑 headless 自测，因为这样你才知道 Xcode 到底替你做了什么。

## 目录

### 第一篇 入门与生命周期

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [01 全景与工具链](docs/01-toolchain.md) | iOS SDK 只随 Xcode 提供、模拟器 `simctl spawn`、部署目标 vs `#available`、六条判定 + debug/release 双配置比对 | 不打开 Xcode，怎么把一个 iOS 程序编出来、在模拟器里跑起来 |
| [02 第一个 App](docs/02-hello-app.md) | SwiftUI `@main App` / `WindowGroup` 与 UIKit `UIApplicationMain` / `AppDelegate` / `SceneDelegate` 两条最小骨架 | 一个最小的 iOS App 由哪几块拼成 |
| [03 生命周期与场景](docs/03-lifecycle.md) | App 级 vs Scene 级生命周期、`UIScene` 多窗口、前后台状态迁移、`@Environment(\.scenePhase)` | App 从启动到进后台，回调按什么顺序来、各归谁管 |

### 第二篇 语言与 Foundation（Objective-C / Swift 基础）

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [04 Objective-C 语言基础](docs/04-objc-language.md) | 消息发送、nil 消息、SEL、协议与分类、block、`NSError`、`@try`、ARC 要点 | 读懂/改动/排查 OC 代码所需的最小集合是什么 |
| [05 Foundation（OC 篇）](docs/05-objc-foundation.md) | `NSString.length` 是 UTF-16 码元、`NSNotFound` ≠ -1、`NSNumber`/`NSValue`/`NSNull`、集合、`NSData`、日期、JSON | OC 侧的地基类有哪些「一半安全一半不安全」的坑 |
| [06 Foundation（Swift 篇）](docs/06-swift-foundation.md) | `String`↔`NSString`、`Range`↔`NSRange`、`Data` 值语义、`Codable`、`==` vs `===`、`NotificationCenter`、`URL`/`FileManager` | Swift 值类型与 OC 引用类型桥接时哪里会错位 |
| [07 OC 与 Swift 混编](docs/07-objc-swift-mix.md) | bridging header、生成的 `<Module>-Swift.h`、nullability 注解（`String!` 的来历）、轻量泛型、`BOOL`+`NSError**`→`throws` | 两个方向（Swift→OC、OC→Swift）各怎么打通 |

### 第三篇 SwiftUI 主线

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [08 SwiftUI 基础](docs/08-swiftui-basics.md) | `View`/`body`/`some View`（opaque）、修饰符的**值语义**（`ModifiedContent` 层层包裹）、栈、组合、`UIHostingController` | 声明式的视图树到底是个什么东西 |
| [09 状态与数据流](docs/09-state-dataflow.md) | `@State`/`@Binding`/`@StateObject`/`@ObservedObject`/`@Environment`、`ObservableObject`/`@Published`/`objectWillChange`、`$` 前缀（projectedValue）、拥有 vs 借用 | 数据变了界面怎么自动跟着变、该用哪个属性包装器 |
| [10 布局](docs/10-layout.md) | `VStack`/`HStack`/`ZStack`、`spacing`/`padding`/`frame`/`Spacer`、对齐、`GeometryReader`；用 `intrinsicContentSize` 做**精确布局算术** | 视图怎么摆、尺寸怎么算出来的 |
| [11 列表与导航](docs/11-list-navigation.md) | `List`/`ForEach`/`Section`、`LazyVStack` vs `VStack`、`Identifiable`、`NavigationStack`/`NavigationPath`/`navigationDestination` | 列表怎么渲染、页面怎么跳转传值 |
| [12 绘制与动画](docs/12-drawing-animation.md) | `Shape`/`Path`（boundingRect/trim）、内置形状、自定义 `Shape`、`animatableData`、`Canvas`、`Animation`/`AnyTransition` | 自定义图形怎么画、怎么让它动起来 |
| [13 SwiftUI ⇄ UIKit 互操作](docs/13-swiftui-uikit-interop.md) | `UIViewRepresentable`/`Coordinator`、`makeUIView`/`updateUIView`、`UIHostingController` 把 SwiftUI 嵌进 UIKit | 两套框架怎么互相嵌套、边界在哪 |

### 第四篇 UIKit 补充

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [14 视图体系与 Auto Layout](docs/14-uikit-views-autolayout.md) | `frame`/`bounds`/`center`、视图层级、anchor 约束、布局周期（`setNeedsLayout`/`layoutIfNeeded`/`layoutSubviews`）、`intrinsicContentSize`、safe area | 命令式界面怎么摆、约束怎么解 |
| [15 控件与列表](docs/15-uikit-controls-lists.md) | `UILabel`/`UIButton.Configuration`/`UITextField`/`UISwitch`/`UISlider`、`UITableView` dataSource/delegate、**cell 复用**、Diffable Data Source、`UICollectionView` | UIKit 的列表怎么高效渲染上万行 |
| [16 手势、触摸与响应链](docs/16-gestures-responder.md) | `hitTest`/`point(inside:)`、响应链（`next`/`isFirstResponder`）、`UIGestureRecognizer` 状态机 | 一次点击怎么找到目标视图、怎么变成事件 |

### 第五篇 系统能力与工程

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [17 网络与并发](docs/17-networking-concurrency.md) | 自定义 `URLProtocol` 离线测网络、`URLComponents`、`URLSession` + `async`/`await`、`async let`、`withTaskGroup`、`actor`（消灭 data race）、`@MainActor` | 怎么「同时做多件事」且不违反 UI 线程规则 |
| [18 数据持久化](docs/18-persistence.md) | `UserDefaults`（suite 隔离）、`FileManager` 三类目录、`Codable`+`.sortedKeys`、plist（XML/二进制）、Keychain `SecItem*`（含 headless 的 entitlement 边界） | 数据存哪、怎么存、敏感数据怎么加密 |
| [19 权限 / 通知 / 设备能力](docs/19-permissions-notifications.md) | `UIDevice`/`UIScreen`/`ProcessInfo`、各框架 `authorizationStatus`（只查不弹框）、`Info.plist` 用途说明、`UNNotification` 内容对象（含需 `.app` 包的调度边界） | 受保护能力怎么申请、设备信息怎么读 |
| [20 打包 / 签名 / 上架](docs/20-packaging-signing.md) | `.app` = 目录（bundle）、`Info.plist` 契约、两个版本号、`codesign` ad-hoc、`simctl install`/`launch`、Archive→Export→Upload；附**真实签名+装机+启动实测** | 怎么把可执行文件变成能装、能跑、能上架的 App |

## 示例代码

`examples/` 下每个目录对应一个可编译工程，全部经本机模拟器编译并运行验证（**20 个示例 × 2 配置 = 40 次运行全部通过，debug/release 输出逐字节一致**，构建说明见 [README](README.md)）。每个示例都是 headless `--selftest`：构造 SwiftUI `View` / `UIViewController` / Foundation 对象，跑断言，打印，退出——**不建窗口、不弹 UI、不调 `UIApplicationMain`**，却真用了 iOS SDK 与 UIKit/SwiftUI 运行时。

| # | 示例 | 章 | 一句话 |
|---|------|----|----|
| 01 | `01_toolchain` | 01 | 编译目标 / 部署目标 vs `#available` / 三框架可达性 |
| 02 | `02_hello_app` | 02 | SwiftUI + UIKit 两条最小骨架 |
| 03 | `03_lifecycle` | 03 | App / Scene 生命周期与 scenePhase 观测 |
| 04 | `04_objc_language` | 04 | OC 消息发送 / nil / SEL / 协议分类 / block / NSError |
| 05 | `05_objc_foundation` | 05 | OC 侧 Foundation 的字符串/集合/数据/日期/JSON 坑 |
| 06 | `06_swift_foundation` | 06 | Swift 侧桥接 / Codable / 值语义 / 相等性 |
| 07 | `07_objc_swift_mix` | 07 | OC↔Swift 双向混编（含 bridging header + nullability） |
| 08 | `08_swiftui_basics` | 08 | View/body / 修饰符值语义 / 栈 / UIHostingController |
| 09 | `09_state_dataflow` | 09 | ObservableObject/@Published / Binding / $ / Environment |
| 10 | `10_layout` | 10 | 栈/spacing/padding/frame/Spacer 的精确布局算术 |
| 11 | `11_list_navigation` | 11 | List/ForEach/Section + NavigationStack |
| 12 | `12_drawing_animation` | 12 | Path/Shape/animatableData/Canvas |
| 13 | `13_swiftui_uikit_interop` | 13 | UIViewRepresentable/Coordinator/UIHostingController 嵌套 |
| 14 | `14_uikit_views_autolayout` | 14 | frame/bounds/center + Auto Layout + 布局周期 |
| 15 | `15_uikit_controls_lists` | 15 | 控件 + UITableView 复用 + Diffable + UICollectionView |
| 16 | `16_gestures_responder` | 16 | hitTest / 响应链 / 手势状态机 |
| 17 | `17_networking_concurrency` | 17 | 离线 URLProtocol + async/await + TaskGroup + actor |
| 18 | `18_persistence` | 18 | UserDefaults / 文件 / Codable / plist / Keychain |
| 19 | `19_permissions_notifications` | 19 | 设备能力 / 权限状态查询 / 通知内容对象 |
| 20 | `20_packaging_signing` | 20 | 亲手搭 .app bundle + Info.plist + Bundle 加载验证 |

## 建议阅读顺序

- **从零开始（SwiftUI 主线）**：01 → 02 → 03 → 08 → 09 → 10 → 11 → 12 → 17 → 18 → 20
- **要写 Objective-C / 维护老项目**：04 → 05 → 07
- **要吃透 UIKit 底层**：13 → 14 → 15 → 16
- **专项**：06（Swift 侧桥接）、19（权限/通知）、20（打包上架）

> 第二篇（04–07）是本教程的地基：SwiftUI/UIKit 的每一条 API 都建立在 Foundation 与 OC 运行时之上，Foundation 的每个类都有 Swift/OC 两副面孔。把这几章读透，后面所有界面章节都会顺理成章。第三篇（08–13）是现代 iOS 的主线；第四篇（14–16）补上你迟早要读懂的 UIKit 底层。
