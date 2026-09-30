# iOS 应用开发指南

> iOS 原生应用开发讲的是 **两套界面框架 + 一套地基**：**SwiftUI** 是现代的声明式 UI（`body` 描述界面长什么样，系统负责画），**UIKit** 是它底下的命令式基石（`UIView`/`UIViewController`、Auto Layout、响应链）——即便你只写 SwiftUI，`UIHostingController`、手势、列表复用这些仍是 UIKit 在扛。而两者都建立在 **Foundation** 与 **Objective-C 运行时**之上：字符串、集合、`Codable`、`NotificationCenter`，以及 Swift↔OC 双向桥接处那些「看起来一样其实不一样」的坑。本教程 **SwiftUI 为主、UIKit 为底**，ObjC 与 Swift 并重。

本教程面向「想真正搞懂 iOS 开发、而不是只会拖 Xcode 控件」的读者，按依赖链组织为 **31 章（六篇）**，每章对应 `examples/` 下一个**可编译、可运行、可自测**的示例，全部用本机 **Xcode 16.2（Swift 6.0.3）+ iOS 18.2 SDK** 在 **iPhone 模拟器**里编译运行验证，`debug(-Onone)` 与 `release(-O)` 两个配置**输出逐字节一致**。全部示例**不打开 Xcode、不建窗口、不弹 UI**——只用 `swiftc` / `clang` 编成命令行可执行文件，`xcrun simctl spawn` 在模拟器里跑 headless 自测，因为这样你才知道 Xcode 到底替你做了什么。

## 目录

### 第一篇 入门与生命周期

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [01 全景与工具链](docs/01-toolchain.md) | iOS SDK 只随 Xcode 提供、模拟器 `simctl spawn`、部署目标 vs `#available`、六条判定 + debug/release 双配置比对 | 不打开 Xcode，怎么把一个 iOS 程序编出来、在模拟器里跑起来 |
| [02 第一个 App](docs/02-hello-app.md) | SwiftUI `@main App` / `WindowGroup` 与 UIKit `UIApplicationMain` / `AppDelegate` / `SceneDelegate` 两条最小骨架 | 一个最小的 iOS App 由哪几块拼成 |
| [03 生命周期与场景](docs/03-lifecycle.md) | App 级 vs Scene 级生命周期、`UIScene` 多窗口、前后台状态迁移、`@Environment(\.scenePhase)` | App 从启动到进后台，回调按什么顺序来、各归谁管 |

### 第二篇 语言与 Foundation（Objective-C / Swift / C 的地基）

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [04 Objective-C 语言基础](docs/04-objc-language.md) | 消息发送、nil 消息、SEL、协议与分类、block、`NSError`、`@try`、ARC 要点 | 读懂/改动/排查 OC 代码所需的最小集合是什么 |
| [05 Foundation（OC 篇）](docs/05-objc-foundation.md) | `NSString.length` 是 UTF-16 码元、`NSNotFound` ≠ -1、`NSNumber`/`NSValue`/`NSNull`、集合、`NSData`、日期、JSON | OC 侧的地基类有哪些「一半安全一半不安全」的坑 |
| [06 Foundation（Swift 篇）](docs/06-swift-foundation.md) | `String`↔`NSString`、`Range`↔`NSRange`、`Data` 值语义、`Codable`、`==` vs `===`、`NotificationCenter`、`URL`/`FileManager` | Swift 值类型与 OC 引用类型桥接时哪里会错位 |
| [07 OC 与 Swift 混编](docs/07-objc-swift-mix.md) | bridging header、生成的 `<Module>-Swift.h`、nullability 注解（`String!` 的来历）、轻量泛型、`BOOL`+`NSError**`→`throws` | 两个方向（Swift→OC、OC→Swift）各怎么打通 |
| [27 Objective-C 运行时](docs/27-objc-runtime.md) | 选择器与 nil 消息的返回值表、`objc_msgSend` 与四个隐藏参数、`@encode` 类型编码、属性/ivar/关联对象、分类与协议的可执行面、动态注册与消息转发三步、`method_setImplementation`/交换实现、KVC 四条取值路径、KVO 手动触发、类内省与 `objc_copyClassList` | `[self foo]` 这一行到底走了哪些步、哪些步能在运行时被改写 |
| [28 C 语言层](docs/28-c-layer.md) | LP64 尺寸与 `char` 符号性、数组退化与指针相减、结构体对齐与 padding、联合体看 IEEE 754、不透明句柄三件套、`va_list` 与函数指针表、`memcpy`/`memmove` 的 UB、`malloc` 与「`-O2` 把判空整体删掉」、宏的六种坑、Swift 看见的 C 类型映射、`withUnsafeBytes` 与 `@convention(c)` | Swift/OC 眼里的那个 C 到底是什么，跨界时要付哪些账 |
| [30 Swift 语言基础与面向对象](docs/30-swift-language-basics.md) | 注释与 `print(_:terminator:)`、操作符空格的真实诊断、`UInt32`→`Int` 与外部名/`inout`、`ClosedRange` vs `Range` 与 `99...1` 的运行期 fatal、斐波那契的 off-by-one、作用域三层、`do/catch/try?/try!` 与 `defer`/`rethrows`、class 与 struct 的 `let` 语义、枚举（原始值/关联值/`CaseIterable`）、designated/convenience 的硬规则、方法与 `self`、继承重写与两阶段初始化、可选的四种拆法、闭包六步简化与逃逸捕获、`#if swift` vs `#if compiler`、数组/字典/Set 的三种「取不到」 | 这本书拿 Playground 侧栏和 Xcode 红点当判据的语言层条目，在没有 IDE 的机器上还能不能逐条兑现——「编译器会报错」这句话的证据在哪 |

### 第三篇 SwiftUI 主线

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [08 SwiftUI 基础](docs/08-swiftui-basics.md) | `View`/`body`/`some View`（opaque）、修饰符的**值语义**（`ModifiedContent` 层层包裹）、栈、组合、`UIHostingController` | 声明式的视图树到底是个什么东西 |
| [09 状态与数据流](docs/09-state-dataflow.md) | `@State`/`@Binding`/`@StateObject`/`@ObservedObject`/`@Environment`、`ObservableObject`/`@Published`/`objectWillChange`、`$` 前缀（projectedValue）、拥有 vs 借用 | 数据变了界面怎么自动跟着变、该用哪个属性包装器 |
| [10 布局](docs/10-layout.md) | `VStack`/`HStack`/`ZStack`、`spacing`/`padding`/`frame`/`Spacer`、对齐、`GeometryReader`；用 `intrinsicContentSize` 做**精确布局算术** | 视图怎么摆、尺寸怎么算出来的 |
| [11 列表与导航](docs/11-list-navigation.md) | `List`/`ForEach`/`Section`、`LazyVStack` vs `VStack`、`Identifiable`、`NavigationStack`/`NavigationPath`/`navigationDestination` | 列表怎么渲染、页面怎么跳转传值 |
| [12 绘制与动画](docs/12-drawing-animation.md) | `Shape`/`Path`（boundingRect/trim）、内置形状、自定义 `Shape`、`animatableData`、`Canvas`、`Animation`/`AnyTransition` | 自定义图形怎么画、怎么让它动起来 |
| [13 SwiftUI ⇄ UIKit 互操作](docs/13-swiftui-uikit-interop.md) | `UIViewRepresentable`/`Coordinator`、`makeUIView`/`updateUIView`、`UIHostingController` 把 SwiftUI 嵌进 UIKit | 两套框架怎么互相嵌套、边界在哪 |

### 第四篇 UIKit 补充与界面文件接线

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [14 视图体系与 Auto Layout](docs/14-uikit-views-autolayout.md) | `frame`/`bounds`/`center`、视图层级、anchor 约束、布局周期（`setNeedsLayout`/`layoutIfNeeded`/`layoutSubviews`）、`intrinsicContentSize`、safe area | 命令式界面怎么摆、约束怎么解 |
| [15 控件与列表](docs/15-uikit-controls-lists.md) | `UILabel`/`UIButton.Configuration`/`UITextField`/`UISwitch`/`UISlider`、`UITableView` dataSource/delegate、**cell 复用**、Diffable Data Source、`UICollectionView` | UIKit 的列表怎么高效渲染上万行 |
| [16 手势、触摸与响应链](docs/16-gestures-responder.md) | `hitTest`/`point(inside:)`、响应链（`next`/`isFirstResponder`）、`UIGestureRecognizer` 状态机 | 一次点击怎么找到目标视图、怎么变成事件 |
| [21 UIKit 布局进阶](docs/21-uikit-layout-advanced.md) | `autoresizingMask` 六档弹性位、`translatesAutoresizingMaskIntoConstraints`、`NSLayoutConstraint` 原始形式与 VFL、布局优先级裁决、`systemLayoutSizeFitting` 反推尺寸、`UIStackView` | Auto Layout 之外那套老机制还在哪活着、约束与尺寸怎么互相推导 |
| [22 滚动视图、容器控制器与高级控件](docs/22-scroll-containers-controls.md) | `UIScrollView` 的 contentSize/Offset/Inset/分页/缩放（含越界赋值不夹取、NaN 崩）、`UINavigationController`/`UITabBarController`/自定义 containment、`UIPickerView`/`UIDatePicker`/`UIAlertController` 等十个控件、ImageIO 合成多帧 GIF | 表格集合视图的父类到底管什么、一个界面怎么装进另一个界面 |
| [29 Quartz 2D 直接绘制](docs/29-quartz-2d.md) | 位图上下文与 `bytesPerRow` 对齐、内存行号与用户 y 的镜像、翻转 CTM 与 UIKit 逐字节等价、面积覆盖与抗锯齿、色空间与预乘、绘画模型层序、当前路径与「谁吃路径」、winding vs even-odd、CTM 乘法顺序与退化逆矩阵、裁剪求交与蒙版、端帽/连接/`miterLimit`、点线图案与相位取模、`addArcToPoint` 与 `flatness`、状态栈 LIFO、透明层消接缝、十三种混合模式的逐通道字节、阴影走设备轴、梯度的像素中心采样、CoreText 直画与 UIKit 文本两条通路、`CGImage`/`UIImage`/插值/平铺、headless 绘制周期驱动、PDF 写出与读回、画板案例 | 「这一笔落在哪四个字节上」——把第 16 章那套「眼睛看效果」的判据换成回读缓冲区 |
| [31 Interface Builder：故事板、XIB 与代码之间的接线](docs/31-interface-builder.md) | `Bundle.main` 在命令行产物里就是那个目录（无 Info.plist、`bundleIdentifier=nil`，故事板照样取得到）、一份 XML → **每场景两条 nib**、`.storyboardc` 里那张「标识符 → nib 名」查找表与 `UIStoryboardDesignatedEntryPointIdentifier`、不可达场景被 `ibtool` 无声删掉、`customClass`/`customModule` 三段字符串写错 → 静默退回 plain `UIViewController`、`storyboardIdentifier` ≠ XML 的 `id`、`relationship` 收养后查找表少一项、连接的时机（`instantiate` 解控制器 nib、`loadView` 解视图 nib）、连线是**一次 KVC 赋值**（约束也能连、`===` 成立、`@IBInspectable` 只管 Xcode 给不给那一格）、creator 闭包与 `UINibDecoder`、`@IBAction` 落到运行时是控件表里的一个字符串选择器、按钮直连 segue 时 target 是 `UIStoryboardSegueTemplate`、`performSegue` 时序与 `UIStoryboardSegue` 三量、unwind 的 `<exit>` 占位对象与两条触发路径、XIB 的顶层对象数组与 File's Owner 不跑 `awakeFromNib`、设计值 `<rect>` 有几格真生效（只看 `translatesAutoresizingMaskIntoConstraints`）、松散 PNG 的 @2x/@3x 查表与 `contentsOfFile:` 的倍率替换、同一个界面的三条路（界面文件/代码装配/SwiftUI `body`） | 「按住 ctrl 拖一条线」在运行时到底是什么——那条线连上了吗、什么时候连的、名字写错的下场是崩溃还是静默、按 XIB 设计的尺寸摆出来为什么不是那个尺寸 |

### 第五篇 动画与硬件

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [23 核心动画](docs/23-core-animation.md) | `CALayer` 四量推导、model 层与 presentation 层、隐式动画与关闭、`CABasicAnimation` 三条给值路数与 `fillMode`、时序函数与 `speed`/`timeOffset`/`beginTime`、`CAKeyframeAnimation`（含沿 `CGPath`）、`CAAnimationGroup`/`CATransition`/`CASpringAnimation`、八种特殊图层、`CATransform3D` 与 m34 透视、`CATransaction`、`CADisplayLink` | 不看文档的情况下，怎么让一个层动起来、动到哪、什么时候算完 |
| [24 音频与视频](docs/24-audio-video.md) | `AVAudioSession` 类别与打断、`AVAudioPlayer` 状态机、`AVAssetWriter` 现场造 mp4、`AVPlayer`/`AVPlayerItem` 与 KVO 抢跑、`AVPlayerViewController`/`AVPlayerLayer`/画中画能力、`AVAsset` 新旧两读法、`AVAssetReader` 解码与 reader→writer 转码、`AVAssetExportSession`、`AVAssetImageGenerator`、`AVAudioEngine` 手动（offline）渲染与五个内置 `AVAudioUnit`、`MediaPlayer` 锁屏与远端命令 | 没有扬声器也没有画面时，怎么验证音视频代码是对的 |
| [25 传感器、定位与设备能力](docs/25-sensors-location.md) | `CMMotionManager` 出厂状态与八条可用性、拉取 vs 推送、陀螺仪/磁力计/融合姿态、`CMQuaternion`/`CMRotationMatrix`/`CMAttitude` 空壳、`CMAltimeter`、`CMPedometer`（离线查询必回，错误码可逐字断言）、`CMMotionActivityManager`、`CLLocationManager` 五档授权与精度常量、`CLLocation` 纯数学、`CLCircularRegion.contains`、`CLGeocoder` 悬住不回、`UIDevice`/`UIScreen`/`ProcessInfo`、`AVCaptureDevice` 权限、`LAContext` 政策与负数错误码（`interactionNotAllowed` 把异步变同步）、`CBManager` 状态机与 `CBUUID`、MapKit 墨卡托数学（±85 夹紧、metersPerMapPoint）与标注/渲染器/GeoJSON、proximity 开关写不进、四种崩溃形态 | 硬件不存在、界面不在、网络不在时，这七个框架各自用什么方式告诉你「现在给不了」 |

### 第六篇 系统能力与工程

| 章 | 内容 | 回答的问题 |
|---|------|-----------|
| [17 网络与并发](docs/17-networking-concurrency.md) | 自定义 `URLProtocol` 离线测网络、`URLComponents`、`URLSession` + `async`/`await`、`async let`、`withTaskGroup`、`actor`（消灭 data race）、`@MainActor` | 怎么「同时做多件事」且不违反 UI 线程规则 |
| [18 数据持久化](docs/18-persistence.md) | `UserDefaults`（suite 隔离）、`FileManager` 三类目录、`Codable`+`.sortedKeys`、plist（XML/二进制）、Keychain `SecItem*`（含 headless 的 entitlement 边界） | 数据存哪、怎么存、敏感数据怎么加密 |
| [19 权限 / 通知 / 设备能力](docs/19-permissions-notifications.md) | `UIDevice`/`UIScreen`/`ProcessInfo`、各框架 `authorizationStatus`（只查不弹框）、`Info.plist` 用途说明、`UNNotification` 内容对象（含需 `.app` 包的调度边界） | 受保护能力怎么申请、设备信息怎么读 |
| [20 打包 / 签名 / 上架](docs/20-packaging-signing.md) | `.app` = 目录（bundle）、`Info.plist` 契约、两个版本号、`codesign` ad-hoc、`simctl install`/`launch`、Archive→Export→Upload；附**真实签名+装机+启动实测** | 怎么把可执行文件变成能装、能跑、能上架的 App |
| [26 SQLite3 与 CoreData](docs/26-sqlite-coredata.md) | `import SQLite3` 与返回码族、`open` 的三种「成功」、`prepare`/`tail`/`nByte`、绑定与槽位、类型亲和、主码 vs 扩展码、扁平事务与 `close_v2`、`sqlite3_exec` 回调与自定义函数；CoreData 侧的程序化模型出厂值、容器默认值、Z 表结构、四种删除规则、`objectID`/fault/多上下文/合并冲突、两个迁移开关、聚合表达式、批量请求 | 第 18 章那一层底下真正的事务与查询是谁在做、出事时谁说话 |

## 示例代码

`examples/` 下每个目录对应一个可编译工程，全部经本机模拟器编译并运行验证（**31 个示例 × 2 配置 = 62 次运行全部通过，debug/release 输出逐字节一致**，构建说明见 [README](README.md)）。每个示例都是 headless `--selftest`：构造 SwiftUI `View` / `UIViewController` / Foundation 对象 / Quartz 位图上下文，跑断言，打印，退出——**不建窗口、不弹 UI、不调 `UIApplicationMain`**，却真用了 iOS SDK 与 UIKit/SwiftUI 运行时。

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
| 21 | `21_uikit_layout_advanced` | 21 | autoresizingMask / VFL / 优先级 / systemLayoutSizeFitting / UIStackView |
| 22 | `22_scroll_containers_controls` | 22 | UIScrollView 五量 + 容器控制器 + 十个高级控件 + ImageIO |
| 23 | `23_core_animation` | 23 | CALayer 四量 / 显式动画 / 关键帧 / 特殊图层 / CATransform3D |
| 24 | `24_audio_video` | 24 | AVAudioSession·Player·Writer·Reader·Engine 全链路（offline 渲染） |
| 25 | `25_sensors_location` | 25 | CoreMotion·CoreLocation·LA·CoreBluetooth·MapKit 的「没反应」十二种形态 + 设备自查 |
| 26 | `26_sqlite_coredata` | 26 | SQLite3 C API 八节 + CoreData 八节，两套 API 指向同一个库文件 |
| 27 | `27_objc_runtime` | 27 | OC 侧三个 .m 出证据、Swift 侧逐条复核：消息发送 / 属性分类协议 / 转发·换实现·KVC·KVO |
| 28 | `28_c_layer` | 28 | 全教程第一个 .c + .m + Swift 三方混编示例：C 只负责量，ObjC 负责说，Swift 负责印 |
| 29 | `29_quartz2d_drawing` | 29 | 自己给缓冲区的 23 节绘制实验：每条断言都回读那四个字节（含 CoreText 文本、PDF、画板） |
| 30 | `30_swift_language_basics` | 30 | 22 节 209 条断言 + 55 个独立探针：把「编译器会报错 / 运行会崩」的每一句量成一行证据 |
| 31 | `31_interface_builder` | 31 | 26 节 220 条断言 + 26 支探针（b01–b11 坏界面文件 / e01 编译期 / r01–r14 运行期现场）：主线示例之外还要先经 `ibtool` 把 `.storyboard`/`.xib` 编进产物目录 |

## 建议阅读顺序

- **从零开始（SwiftUI 主线）**：01 → 02 → 03 → 08 → 09 → 10 → 11 → 12 → 17 → 18 → 26 → 20
- **要写 Objective-C / 维护老项目**：04 → 05 → 07 → 27（运行时）→ 28（C 层）
- **Swift 语言本身没吃透**：30（语法与 OOP：可选、闭包、init 规则、class vs struct）→ 06（Foundation 桥接）→ 27（运行时）
- **要吃透 UIKit 底层**：13 → 14 → 15 → 16 → 21 → 22 → 23 → 29
- **要弄懂「拖一条线」连上了什么**：21（布局与 `translates…`）→ **31（故事板 / XIB / segue）** → 16（事件与响应链）→ 13（SwiftUI `body` 那条对照路）
- **要做动画**：12（SwiftUI 侧）→ 23（Core Animation 侧）
- **要做自绘 / 图像 / PDF**：12（SwiftUI 的 `Canvas`/`Path`）→ 23（图层树侧）→ **29（像素侧：Quartz 2D）**
- **要摸到语言的地板**：30（Swift 语法与 OOP）→ 28（C：尺寸、对齐、句柄、UB）→ 27（OC：消息、转发、KVC/KVO）
- **要做音视频 / 传感器 / 定位**：19（权限）→ 24、25
- **专项**：06（Swift 侧桥接）、19（权限/通知）、20（打包上架）、26（SQLite 与 CoreData）、29（离屏出图与画板）、30（语言层探针方法学）、31（界面文件的编译产物与运行时接线）

> 第二篇（04–07、27–28、30）是本教程的地基：SwiftUI/UIKit 的每一条 API 都建立在 Foundation 与 OC 运行时之上，而运行时底下还有一层 C——`CGContextRef` 是个不透明句柄、`CGRect` 是个值类型、`NSError **` 是个出参，这些在第 28 章一次讲清；第 30 章则把本书语言层的每一条「编译器会报错」「运行会崩」都换成 55 个独立探针的原文与 209 条断言，是全教程「判据换成可复现输出」这件事最集中的示范。把这几章读透，后面所有界面章节都会顺理成章。第三篇（08–13）是现代 iOS 的主线；第四篇（14–16、21–22、29、31）补上你迟早要读懂的 UIKit 底层，其中第 29 章把「画出来」这件事从「眼睛看效果」变成「回读四个字节」，是第 12、13、22、23 章所有绘制代码的共同地基；第 31 章则把「在 Xcode 里拖一条线、跑起来看看」换成三段可查的账——编译产物里有什么、运行时解出什么、线和 segue 在运行时是谁，它也是全教程唯一一章需要 `ibtool` 参与构建的示例；第五篇（23–25）是动画与硬件——它们共用一套「headless 环境下怎么验证」的方法；第六篇（17–20、26）把网络、数据、上架这条工程链路走完。
