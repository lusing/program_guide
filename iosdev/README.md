# iOS 应用开发教程（Xcode / Swift / Objective-C / SwiftUI / UIKit）

用**本机 Xcode 16.2（Swift 6.0.3）+ iOS 18.2 SDK**，在 **iPhone 模拟器**里讲 iOS 原生应用开发：
SwiftUI（主线）、UIKit（底层）、Objective-C 运行时与 C 语言层（地基）、Foundation、网络并发、持久化（含 SQLite3
与 CoreData）、权限通知、动画与多媒体、传感器定位、Quartz 2D 直接绘制、依赖管理（SwiftPM 离线版）、打包签名上架。

33 章正文放在 [`docs/`](./docs)（目录页见 [`iOS开发指南.md`](./iOS开发指南.md)），每章对应 `examples/` 下一个**可编译、可运行、可自测**的示例。
全部示例都**不打开 Xcode、不建窗口、不弹 UI**——只用 `swiftc` / `clang` 编成命令行可执行文件，
`xcrun simctl spawn` 在模拟器里跑 headless 自测，因为这样你才知道 Xcode 到底替你做了什么。

## 快速开始

```bash
cd iosdev

./run-all.sh                # 跑全部 33 个示例（debug + release 两配置 × 六条判定）
./run-all.sh 13             # 只跑编号 13 的示例（SwiftUI ⇄ UIKit 互操作）
./run-all.sh 08 09 10       # 跑指定的几个
./run-all.sh --clean        # 清空 build/
./run-all.sh --keep-booted  # 结束后不关闭本脚本启动的模拟器

python3 tools/check_docs.py # 文档一致性 / 输出快照漂移检查（结构 + 引用 + 快照）
```

## 本机工具链

| 项目 | 值 |
| --- | --- |
| macOS | 14.8.9（Darwin 23.6.0，x86_64） |
| Xcode | 16.2（Build 16C5032a，`/Applications/Xcode.app`） |
| Swift | 6.0.3（swiftlang-6.0.3.1.10） |
| Apple clang | 16.0.0（clang-1600.0.26.6） |
| iOS SDK | `.../Platforms/iPhoneSimulator.platform/.../iPhoneSimulator18.2.sdk`（iOS 18.2） |
| 模拟器运行时 | iOS 18.3.1（iPhone） |
| 部署目标 | `x86_64-apple-ios15.0-simulator`（刻意钉得比 SDK 低，让误用 iOS 16/17/18 新 API 在**编译期**暴露） |

> **iOS SDK 只随 Xcode 提供**，Command Line Tools 里没有，所以这里**只有一条工具链**
> （Xcode + iphonesimulator），不像 macosdev 那样能跑两套 Swift。为了保留「双通道逐字节比对」
> 这张安全网，改成**同一工具链的两个优化配置**：`debug(-Onone)` 与 `release(-O)`。两份产物都在
> 模拟器里跑，stdout 必须**逐字节一致**——能挡住「只在 `-O` 下才暴露」的未定义行为，以及依赖
> 优化等级的巧合。

## 目录结构

```
iosdev/
├── README.md                 本文件
├── iOS开发指南.md             教程目录页（指向 docs/ 各章）
├── run-all.sh                构建 / 模拟器运行 / 六条判定 / debug·release 比对
├── docs/                     33 章正文
│   ├── 01-toolchain.md
│   ├── ...
│   ├── 20-packaging-signing.md
│   ├── 21-uikit-layout-advanced.md
│   ├── 22-scroll-containers-controls.md
│   ├── 23-core-animation.md
│   ├── 24-audio-video.md
│   ├── 25-sensors-location.md
│   ├── 26-sqlite-coredata.md
│   ├── 27-objc-runtime.md
│   ├── 28-c-layer.md
│   ├── 29-quartz-2d.md
│   ├── 30-swift-language-basics.md
│   ├── 31-interface-builder.md
│   ├── 32-app-architecture-mvc.md
│   └── 33-dependency-management.md
├── examples/                 33 个示例目录（NN_topic）
│   ├── 01_toolchain/main.swift
│   ├── 07_objc_swift_mix/    (OC + Swift 混编，含 Bridging.h / Greeter.h/.m / LegacyNote.h/.m)
│   ├── 19_permissions_notifications/  (含 Frameworks 文件，声明额外链接的系统框架)
│   ├── 24_audio_video/       (含 Frameworks：AVFoundation / AVKit / MediaPlayer)
│   ├── 25_sensors_location/  (含 Frameworks：CoreMotion / CoreLocation / AVFoundation / LocalAuthentication / CoreBluetooth / MapKit / Security)
│   ├── 26_sqlite_coredata/   (SQLite3 走 `import SQLite3`，不需要额外 framework 文件)
│   ├── 27_objc_runtime/      (含 Bridging.h + 三个 .m：RTMsg 消息发送与类型编码 / RTDecl 属性·分类·协议 / RTDyn 转发·换实现·KVC·KVO)
│   ├── 28_c_layer/           (三方混编：四个 .c + 一个 .m + Swift，含 Bridging.h；.c/.m 恒为 -O2)
│   ├── 29_quartz2d_drawing/  (含 Frameworks：CoreText；全章判据是回读自己提供的位图缓冲区)
│   ├── 30_swift_language_basics/  (含 probes/ 目录：55 个一次性小文件 + run.sh/w01_whitespace.sh，专量「编译器会报错 / 运行会崩」的原文)
│   ├── 31_interface_builder/  (主线之外的界面文件：Main.storyboard / Nav.storyboard / Card.xib / Resources/*.png；含 probes/ 26 支：b01–b11 坏界面文件、e01 编译期、r01–r14 运行期现场 + run.sh)
│   ├── 32_app_architecture/   (MVC 小测验 App + 情商测试产品线；Swift/OC 混编四件：Bridging.h / ProgressHUD.h / ProgressHUD.m / 空标记 Needs-Swift-Header（后者让构建脚本加 -emit-objc-header-path）；含 probes/ 18 支：e01–e09 编译期原文、r01–r05 崩溃现场、c01 两配置对照、m01–m03 混编 + run.sh)
│   └── 33_dependency_management/  (两个真的包 Packages/ClimateCore 与 Packages/WeatherKit（后者内含一个 C target CLIBrain 与一份 test target）；标记文件 Needs-SwiftPM 的**每一行**是一个包目录，构建脚本先跑 `swift build` 再把四类输入拼进 swiftc；含 probes/ 26 支：s01–s13 SwiftPM 命令行现场、e01–e09 编译期原文、r01 运行期现场、c01–c03 两配置对照 + run.sh)
├── tools/
│   └── check_docs.py         文档一致性 / 输出快照漂移检查
└── build/                    编译产物（stdout/stderr/日志，不入库）
```

## 各章索引

| 章 | 标题 | 示例 | 要点 |
| --- | --- | --- | --- |
| 01 | 全景与工具链 | `01_toolchain` | 单工具链 / 模拟器 spawn / 部署目标 vs `#available` / 六条判定 |
| 02 | 第一个 App | `02_hello_app` | SwiftUI `@main App` 与 UIKit `AppDelegate`/`SceneDelegate` 两条骨架 |
| 03 | 生命周期与场景 | `03_lifecycle` | App 级 vs Scene 级、多窗口、前后台迁移、`scenePhase` |
| 04 | Objective-C 语言基础 | `04_objc_language` | 消息发送 / nil / SEL / 协议分类 / block / NSError |
| 05 | Foundation（OC 篇） | `05_objc_foundation` | NSString length / NSNotFound / NSNumber / JSON |
| 06 | Foundation（Swift 篇） | `06_swift_foundation` | String↔NSString / Range↔NSRange / Codable / 值语义 / ==·=== |
| 07 | OC 与 Swift 混编 | `07_objc_swift_mix` | bridging header / 生成的 Swift 头 / nullability / 轻量泛型 |
| 08 | SwiftUI 基础 | `08_swiftui_basics` | View/body/some View / 修饰符值语义 / 栈 / UIHostingController |
| 09 | 状态与数据流 | `09_state_dataflow` | @State/@Binding/@StateObject/@ObservedObject/@Environment / @Published / `$` |
| 10 | 布局 | `10_layout` | VStack/HStack/ZStack / spacing/padding/frame/Spacer / 精确布局算术 |
| 11 | 列表与导航 | `11_list_navigation` | List/ForEach/Section / LazyVStack / NavigationStack/NavigationPath |
| 12 | 绘制与动画 | `12_drawing_animation` | Shape/Path / animatableData / Canvas / Animation/AnyTransition |
| 13 | SwiftUI ⇄ UIKit | `13_swiftui_uikit_interop` | UIViewRepresentable/Coordinator / UIHostingController 嵌套 |
| 14 | UIKit 视图与 Auto Layout | `14_uikit_views_autolayout` | frame/bounds/center / anchor 约束 / 布局周期 / safe area |
| 15 | UIKit 控件与列表 | `15_uikit_controls_lists` | 控件 / UITableView dataSource·delegate / cell 复用 / Diffable / UICollectionView |
| 16 | 手势、触摸与响应链 | `16_gestures_responder` | hitTest/point(inside:) / 响应链 / UIGestureRecognizer 状态机 |
| 17 | 网络与并发 | `17_networking_concurrency` | 离线 URLProtocol / async·await / async let / TaskGroup / actor / @MainActor |
| 18 | 数据持久化 | `18_persistence` | UserDefaults / 文件三目录 / Codable·sortedKeys / plist / Keychain |
| 19 | 权限 / 通知 / 设备能力 | `19_permissions_notifications` | UIDevice/UIScreen/ProcessInfo / authorizationStatus / UNNotification 内容对象 |
| 20 | 打包 / 签名 / 上架 | `20_packaging_signing` | .app=bundle / Info.plist 契约 / codesign / simctl install·launch / Archive→Upload |
| 21 | UIKit 布局进阶 | `21_uikit_layout_advanced` | autoresizingMask 六档弹性位 / `translatesAutoresizingMaskIntoConstraints` / VFL / 布局优先级 / `systemLayoutSizeFitting` / UIStackView |
| 22 | 滚动视图、容器控制器与高级控件 | `22_scroll_containers_controls` | UIScrollView 五量与越界/NaN / Navigation·Tab·自定义 containment / 十个高级控件 / ImageIO 多帧 GIF |
| 23 | 核心动画 | `23_core_animation` | CALayer 四量 / model vs presentation / 隐式动画 / Basic·Keyframe·Group·Transition·Spring / 八种特殊图层 / CATransform3D / CATransaction / CADisplayLink |
| 24 | 音频与视频 | `24_audio_video` | AVAudioSession / AVAudioPlayer / AVAssetWriter 造 mp4 / AVPlayer 状态机与 KVO / Reader·Export·ImageGenerator / AVAudioEngine offline 渲染 / MediaPlayer |
| 25 | 传感器、定位与设备能力 | `25_sensors_location` | CMMotionManager 八条可用性 / Pedometer·Altimeter·MotionActivity / CLLocationManager 五档授权 / CLLocation 纯数学 / CLCircularRegion / CLGeocoder / UIDevice·UIScreen·ProcessInfo / AVCaptureDevice / LAContext 政策与错误码 / CBManager 状态机与 CBUUID / MapKit 墨卡托数学·标注·渲染器·GeoJSON / proximity |
| 26 | SQLite3 与 CoreData | `26_sqlite_coredata` | prepare·tail·nByte / 绑定与槽位 / 类型亲和 / 主码·扩展码 / 事务与 close_v2 / 自定义函数 / CoreData 模型·容器·Z 表·删除规则·objectID·fault·迁移·聚合·批量请求 |
| 27 | Objective-C 运行时 | `27_objc_runtime` | 选择器与 nil 返回值 / objc_msgSend 与隐藏参数 / @encode 类型编码 / 属性·ivar·关联对象 / 分类与协议的可执行面 / 动态注册与消息转发三步 / method_setImplementation·交换实现 / KVC 的四个取值路径 / KVO 手动触发 / 类 introspection |
| 28 | C 语言层 | `28_c_layer` | LP64 尺寸与符号性 / 数组退化与指针相减 / 结构体对齐与 padding / 联合体看 IEEE 754 / 不透明句柄三件套 / va_list 与函数指针表 / memcpy vs memmove 的 UB / malloc 与「-O2 把判空删了」/ 宏的六种坑 / Swift 看见的 C 类型映射 / withUnsafeBytes 与 @convention(c) |
| 29 | Quartz 2D 直接绘制 | `29_quartz2d_drawing` | 位图上下文与 bytesPerRow 对齐 / 内存行号与用户 y 镜像 / 翻转 CTM 与 UIKit 等价 / 面积覆盖与抗锯齿 / 色空间与预乘 / 绘画模型层序 / 当前路径与「谁吃路径」/ winding vs even-odd / CTM 乘法顺序与退化逆 / 裁剪求交与蒙版 / 端帽·连接·miterLimit / 点线相位取模 / addArcToPoint 与 flatness / 状态栈 LIFO / 透明层消接缝 / 十三种混合模式的字节 / 阴影走设备轴 / 梯度像素中心 / CoreText 直画 / CGImage·UIImage·插值·平铺 / headless 绘制周期驱动 / PDF 写出与读回 / 画板案例 |
| 30 | Swift 语言基础与面向对象 | `30_swift_language_basics` | 注释与 `print(_:terminator:)` / 操作符空格的真实诊断 / `UInt32`→`Int` / 外部名·默认值·`inout` / `ClosedRange` vs `Range` 与 `99...1` 的运行期 fatal / 斐波那契 off-by-one / 作用域三层 / `do·catch·try?·try!`·`defer`·`rethrows` / class 与 struct 的 `let` 语义 / 枚举（原始值·关联值·`CaseIterable`）/ designated 与 convenience 的硬规则 / 方法与 `self` / 继承·重写·两阶段初始化 / 可选四种拆法 / 闭包六步简化与逃逸捕获 / `#if swift` vs `#if compiler` / 数组·字典·Set 的三种「取不到」 |
| 31 | Interface Builder：故事板、XIB 与代码之间的接线 | `31_interface_builder` | 产物目录就是 bundle（无 Info.plist，`bundleIdentifier=nil` 也能取到故事板）/ 一份 XML → 每场景两条 nib / `.storyboardc` 里那张「标识符 → nib 名」查找表 / 不可达场景被 ibtool 无声删掉 / `customClass`·`customModule` 三段字符串写错 → 静默退回 plain `UIViewController` / `storyboardIdentifier` ≠ XML 的 `id` / `relationship` 收养后查找表少一项 / 连接的时机（`instantiate` 解控制器 nib、`loadView` 解视图 nib）/ 连线是一次 KVC 赋值（约束也能连、`===` 成立）/ creator 闭包与 `UINibDecoder` / Inspector 三格与 `@IBInspectable` 到底管什么 / `@IBAction` 是控件表里的字符串选择器 / 按钮直连 segue 时 target 是 `UIStoryboardSegueTemplate` / `performSegue` 时序与 `UIStoryboardSegue` 三量 / unwind 的 `<exit>` 与两条触发路径 / XIB 的顶层对象数组与 File's Owner 不跑 `awakeFromNib` / 设计值 `<rect>` 有几格真生效（`translatesAutoresizingMaskIntoConstraints`）/ 松散 PNG 的 @2x/@3x 查表与 `contentsOfFile:` 的倍率替换 / 同一个界面的三条路（界面文件·代码装配·SwiftUI `body`） |
| 32 | 应用架构：MVC 三层里状态住在谁的哪一次赋值 | `32_app_architecture` | Model 层不碰 UIKit（整章 `UIApplication.shared == nil`）/ 无 init 的 class 红点落在类声明那行 / 两阶段初始化里 `didSet` 一次都不跑 / 游标只有一个主人 / class 与 struct 的「改一次影响谁」/ `let` 锁引用不锁数据 / `list[13]` 与 `[-1]` 同一句 `Index out of range`（132 / SIGILL）/ 抄来的边界不跟着源头动 / `questionNumber + 1` 的编号差 / 进度条提前一格满格 / CGFloat 与 Int 混算 / `sender.tag - 1` 那道焊缝 / 五种更新机制的账本（手动·KVO·NotificationCenter·代理·闭包）/ `@objc dynamic` 才有 KVO（e06 只 warning，r05 当场 trap）/ KVC 一句跨过分层：MVC 那句话是纪律不是机制 / 弹窗四字段可读、`present` 不生效 / `UIAlertAction.handler` 读不回来 → 自存闭包 → 三方环 / 回收时机由自动释放池层次决定（不是优化等级）/ 29 题产品线：两个数组没人强制对齐、「最大 EQ 154」连可达都不是 / 四个 `else if` 之间 129 掉进缝里（空标题 + 空正文，仍带那颗按钮）/ 二选一三选一混排：`isHidden` 挡住手挡不住方法调用 / 「只需把 13 改成 29」值三处字面量 / ProgressHUD 混编：桥接头标记、三个名字、nullability 三种态度、单例即全局状态、OC 反方向写进来 / 一个协议两份 Model 同一台控制器 |
| 33 | 依赖管理：一行 `import` 后面的四类输入、三个名字、两层声明 | `33_dependency_management` | 「装好了」= 一条 `-I` + 一份 modulemap + 一批 `.o` + 一个 bundle 目录 / **SDK 里也有一个 `WeatherKit.framework`**：依赖没接上可以全程绿灯（e07 与 e08 同一份源码换个错，r01 不给 `-I` 也六条全过）/ `canImport` 只问「有没有」/ product·target·module·identity·bundle 前缀是五个来源，只有 target 名全图唯一（撞 product 名一句警告都没有，撞 target 名报 `moduleAliases`）/ 依赖两层的硬度与直觉相反（内层漏写全过，外层漏写死在 manifest）/ 传递 import 不传染 / internal 跨模块两种措辞（`cannot find` vs `inaccessible`）/ `@testable` 只成立于一半（debug 带 `-enable-testing`，release 拒绝）/ C target 的 modulemap 是生成的、umbrella 是绝对路径 / `.copy` 保留层级、`.process` 摊平、路径基准是 target 目录（写错只 warning + 少文件）/ bundle 名 = `Package(name:)_<target>.bundle` / `Bundle.module` 是生成出来的 internal `static let`，两个候选路径里那个绝对值是**假绿** / path 依赖连 `Package.resolved` 都不写，加 tag 不动锁、`package update` 才动 / `env -u SDKROOT`（manifest 是主机程序）/ 默认目标是主机而产物照样能在模拟器里跑 / automatic·static·dynamic 三种 product 的落盘 |

## 建议阅读顺序

- **从零开始（SwiftUI 主线）**：01 → 02 → 03 → 08 → 09 → 10 → 11 → 12 → 17 → 18 → 26 → 20
- **要写 Objective-C / 维护老项目**：04 → 05 → 07 → 27（运行时）→ 28（C 层）→ 32（拖进一份 OC 第三方库）→ 33（换成一个包）
- **要弄清「状态住在谁的哪一次赋值里」**：30（语言地板）→ 27（KVC/KVO 那张表）→ **32（MVC 三层、五种更新机制、小测验 App）** → 31（界面文件那一侧同一条「名字即接口」的焊缝）
- **要吃透 UIKit 底层**：13 → 14 → 15 → 16 → 21 → 22 → 23 → **32（Controller 层的五种更新机制）**
- **要弄清「一句 import 到底靠什么成立」**：01（工具链与那条 swiftc 命令）→ 20（.app 与 bundle）→ 28（C 与模块地图）→ **33（SwiftPM：四类输入、五个名字、撞名可以全程绿灯）**
- **要弄懂「拖一条线」到底连上了什么**：21（布局与生命周期）→ **31（Interface Builder：故事板 / XIB / segue）** → 16（事件与响应链）
- **要做动画**：12（SwiftUI 侧）→ 23（Core Animation 侧）
- **要做自绘 / 图像 / PDF**：12（SwiftUI 的 Canvas/Path）→ 23（图层树侧）→ **29（像素侧：Quartz 2D）**
- **要摸到语言的地板**：28（C：尺寸、对齐、句柄、UB）→ 27（OC：消息、转发、KVC/KVO）
- **要做音视频 / 传感器 / 定位**：19（权限）→ 24、25
- **语言层地板**：30（Swift 语法与 OOP，55 个探针）⇄ 28（C）⇄ 27（OC 运行时）⇄ 06（Swift 侧桥接）
- **专项**：06（Swift 侧桥接）、19（权限/通知）、20（打包上架）、26（SQLite 与 CoreData）、29（离屏出图与画板）、30（语言层探针方法学）、31（界面文件的编译产物与运行时接线）、32（架构与混编）、33（依赖管理与构建目录）

## 验证状态（全部通过）

```
通过 66   失败 0   输出差异 0   示例 33   配置 2
```

- **33 个示例 × 2 个优化配置（debug/release）= 66 次运行，全部 PASS**
- **两配置 stdout 逐字节一致**（`[cmp]` 全绿）
- `tools/check_docs.py`：结构（01..33 齐全）/ 引用（示例·输出路径存在）/ 快照（文档里贴的断言行逐字对得上 build 输出）三项全绿

### 六条判定标准

一个示例「通过」要同时满足：

1. **编译日志为空** —— 零告警（`-Wall -Wextra`；`SDKROOT` 已设，无 sysroot 噪声）
2. **退出码为 0**
3. **stderr 为空**
4. **stdout 非空** —— 防止进程根本没执行到业务代码却返回 0
5. **stdout 无多余控制字符**（0..31 除 TAB/LF/CR）
6. **stdout 有结束标记** `==== NN 结束 ====` —— 防止输出被截断

外加一条：**debug 与 release 两个配置的 stdout 逐字节一致**。

### 示例的 headless 自测约定

每个示例都支持 `--selftest`：不建窗口、不弹 UI、不调 `UIApplicationMain`，只构造对象跑断言然后退出。
关键技巧（都在对应章节里讲清楚）：

- **SwiftUI 布局**用 `UIHostingController.view.intrinsicContentSize` 算出真实尺寸——无需窗口/runloop。
- **SwiftUI ⇄ UIKit 互操作**用 `UIWindow(isHidden:false)` + **有界的** run-loop 抽送（`RunLoop.current.run(mode:before:)` 转若干圈）触发 `makeUIView`/`updateUIView`——**绝不** `makeKeyAndVisible`、**绝不**无限 runloop。
- **`UITableView`/`UICollectionView`** 给了 frame 后 `reloadData()` 即同步填充，行数/cell/diffable 快照都可读——无需窗口。
- **网络**用自定义 `URLProtocol` 拦截所有请求返回写死响应，离线、确定。
- **动画**不看画面，只读回值：`presentationLayer` 的实时值、`animationKeys`、`CAMediaTimingFunction` 求点、`CATransaction` 的 completion 计数；墙钟不参与判断。
- **音视频**用 `AVAudioFile` 现场写出定长 wav、`AVAssetWriter` + pixel buffer 现场写出定长 mp4，再用 `AVAssetReader` 解回来数样本；`AVAudioEngine` 切**手动（offline）渲染**，长度由帧数决定而不是由播放进度决定。
- **传感器/定位**只断言「可用性=false」「属性=nil」「回调计数==0」这类可复现形态，时间一律用固定时间戳（连「查过去一小时」都写成两个常量之差正好 3600 秒），于是错误码也能逐字断言。
- **CoreData** 全部用代码构造模型（没有 `.xcdatamodeld`），每个出厂值都读回来打印；故意制造的失败用 `quiet()` 临时把 fd 2 指向 `/dev/null`，错误信息由自己从 `NSError` 取。
- **OC 运行时**只读结构体的字段值和「有没有」：`Method`/`Ivar`/`Property` 一律问名字、类型编码、属性串，不打印指针；类列表用 `objc_copyClassList(&count)` 拿计数，再对具体类做 `isKindOfClass` 判断。转发链、换实现这些「谁被调用」的问题靠一根自己维护的日志数组计数回答。
- **C 与三方混编**（`.c` + `.m` + Swift）：`.c` 只负责量、不 `printf`（C 的 `printf` 混进 ObjC 运行时的 stdout 缓冲会打乱顺序，而判定 3 要 stderr 为空）；`.m` 负责排版；Swift 侧逐条 `expect` 复核。`run-all.sh` 见到 `Bridging.h` 走混编路径，`.c` 与 `.m` 两种配置下都恒为 `-O2`，只有 Swift 跟着配置变——这是「优化器把 malloc 判空删掉」那条结论能在两配置下给出同一份输出的前提。
- **Quartz 2D** 的一切结论都来自**回读自己提供的位图缓冲区**（`CGBitmapContext`），因为 UIKit 的 `draw(_:)` 给的那个上下文读不到像素（§20 实测 `width`/`bytesPerRow` 为 0、`data` 为 nil）。内存行号与用户 y 是镜像关系（`row = h-1-y`），所以量具同时交出 `mem()` 与 `at()` 两种读法，防止混用得假结论。像素值只选能精确落在格点上的分量（0/1/0.5），避免量化抖动写进断言。
- **界面文件（故事板 / XIB）**：`.storyboardc` / `.nib` 由 `ibtool` 在 Swift 编译之后单独编一次，放进**可执行文件所在目录**——那里没有 `.app`、没有 Info.plist，`UIStoryboard(name:bundle:)` 与 `UINib(nibName:bundle:)` 照样取得到（找的就是同名那个目录）。断言读两样东西：**编译产物的清单**（包里有几条 nib、那张「标识符 → nib 名」查找表有哪些键）和**运行时解出的对象**（类名、`===` 身份、frame、控件的 target-action 表）。ObjC 的 `description` 会把内存地址打进 stdout，所以本章所有输出统一先过一次脱敏（长十六进制串换成 `0x…`），否则同一份代码的 debug 与 release 两次进程对不齐。
- **依赖管理（SwiftPM 离线版）**：章节根放一个 `Needs-SwiftPM` 清单（每行一个包目录），`run-all.sh` 在编译 `main.swift` **之前**先按配置各跑一遍 `env -u SDKROOT swift build --package-path … --scratch-path build/33_dependency_management/spm/<cfg>/<PkgName> --triple $DEPLOY_TARGET --sdk $SDK`，再把 `-I <cfgdir>/Modules`、每个 `<T>.build/*.o` 交给 swiftc（C 语言的 target 另给一条 `-Xcc -fmodule-map-file=`），并把 `*.bundle` **拷到可执行文件旁边**。三个开关各自挡掉一种「照样绿着但结果是错的」：不给 `--triple`/`--sdk` 会编出**主机**二进制（落在 `x86_64-apple-macosx/`，而它 `simctl spawn` 居然也能跑起来，只是读到的系统是 10.16 而不是 18.3）；只给 `--triple` 不给 `--sdk` 会红在 `unable to load standard library for target 'x86_64-apple-ios12.0-simulator'`；不 `env -u SDKROOT` 会红在 `Package.swift` 自己身上——manifest 是一段只能为**主机**编译执行的 Swift 程序，模拟器 SDK 递给它就当场 `Invalid manifest`。`--scratch-path` 必须显式给：不给就在包目录里写一个 `.build/`，而本章的两个包就住在 `examples/` 下面（主线把它指到 `build/33_dependency_management/spm/<cfg>/<包名>`，探针指到 `$TMP`，两处都可复现、也都不会被别人当成产品）。SwiftPM 自己的 `warning:` **不进判定 1**（判定 1 只管 swiftc），而是单独筛进 `spm.<cfg>.diags` 留档；进度文本（`Building for debugging…` / `Build complete! (…)`）进 `spm.<cfg>.log`，两样都不并进 `build.<cfg>.log`——`swift build` 一定跑在 `build_config` 截断那句之前，直接写会被抹掉。
- 环境相关的数字（耗时、线程 id、`processorCount`、屏幕尺寸、系统版本）**只打印性质、不断言具体值**；耗时只作相对比较（如 `concElapsed < seqElapsed`）。这条的现形记在第 24 章：一行 `currentTime()=… secs=0.0` 平时次次过，全量回归里被抓到 debug 读到 `0.042566414`、release 读到 `0.0`（那一行在 `play()` 之后跑，读的就是「播了几秒」），两配置比对当场报 DIFF，单独重跑又九成能过——正是最难查的那类偶发失败。现在只打 `valid`/`indefinite` 两个布尔，断言也跟着改成形状判断。

### 诚实处理 headless 的边界（不伪造绿灯）

有几件事在裸 `simctl spawn` 的进程里**做不到**，本教程一律**如实标注边界**，而不是假装成功：

| 边界 | 出现在 | 原因 |
| --- | --- | --- |
| `sendActions(for:)` / 手势状态迁移不触发 target-action | 第 16 章 | 需真实事件系统投递 |
| Keychain `SecItem*` 返回 `errSecMissingEntitlement(-34018)` | 第 18 章 | 裸 spawn 无 `keychain-access-groups` entitlement |
| `UNUserNotificationCenter.current()` 会崩，不调用 | 第 19 章 | 需真实 `.app` 包（`bundleProxyForCurrentProcess`） |
| 无法在进程内 `exec` `codesign`/`simctl` | 第 20 章 | iOS 无 `Process`/`NSTask`（macOS 独有） |
| 真机才能验的行为（相机取景、录音、扬声器、震动、真实 GPS 轨迹、指纹/面容弹窗、蓝牙收发数据、地图出图） | 第 24、25 章 | 模拟器没有对应硬件；本章只断言「可用性=false / 属性=nil / 回调 0 次 / 错误码 -7·-1004 / state=unsupported」这些可复现的形态 |
| 会崩或会死循环的调用只在独立探针进程里量，正文只引原文 | 第 22、23、25、26、27、28、29 章 | 判定 2 要退出码为 0、判定 3 要 stderr 为空（`CLVisit` 日期、`CMAttitude` 属性、`MKOverlayPathRenderer()` 裸构造、`CBUUID(string:)` 非法形状、`localizedReason: ""`、不设 flag 的 `evaluatePolicy` 挂死、`MKMapSnapshotter.start` 不回、`NSFetchRequest<NSDictionary>` 泛型错配、`dictionaryHandler` 永不返回、`object_getIvar` 读标量 ivar、`memcpy` 重叠区、iOS 上被标 `unavailable` 的 `CGContext` 文本 API、行距写小还继续用的缓冲区） |
| `MKMapView` 整条使用面只引探针原文 | 第 25 章 | 单纯 `MKMapView(frame:)` 就往 stderr 写一条 `CAMetalLayer ignoring invalid setDrawableSize…`（120 字节），判定 3 直接判死；`MKMarkerAnnotationView` 等对象的 `description` 又带 `0x…` 指针地址，无法做逐字节比对 |
| CoreData 的失败日志带绝对路径，一律 `quiet()` 包住 fd 2 | 第 26 章 | 判定 3/4 要求 stderr 为空且输出可复现，错误信息改由 `NSError` 的 `domain/code/userInfo` 自己打印 |
| 路径、store UUID、BLOB 内容、`Z_MAX` 之外的行数一并不打印 | 第 26 章 | 临时目录带设备标识、UUID 每次建库都不同，BLOB 会踩判定 5 的控制字符 |
| OC 侧会崩/会递归的调用只在独立探针里量（`object_getIvar` 读 `int` ivar、把返回 void 的方法值当对象用、消息转发钩子里写 `[self label]`、stret 结构体走普通 `objc_msgSend`） | 第 27 章 | 判定 2/3 要退出码 0 与空 stderr；这些不是「拿到脏数据」而是当场 SIGSEGV 或无限递归到栈溢出 |
| 分类加 ivar、分类重写主类方法只引编译器诊断原文 | 第 27 章 | 前者编译期就失败（`error: instance variables may not be placed in categories`）；后者「谁赢由链接顺序决定」，不是可复现的断言 |
| C 层的 UB 写法（有符号溢出、`memcpy` 重叠区）不进示例 | 第 28 章 | 标准不承诺任何结果，`-Onone` 与 `-O2` 给出不同答案；这类只能靠 sanitizer 与反汇编登记成探针记录 |
| `.c` 不 `printf`、`.m` 不 `NSLog`；`.c`/`.m` 两种配置下恒 `-O2` | 第 28 章 | 判定 3 要 stderr 为空；而「优化器把 malloc 判空整体删掉」这条必须在两配置下给出同一份 stdout，否则逐字节比对过不了 |
| Quartz 2D 的文本三件套（`selectFont` / `showText` / `showText(at:)`）在 Swift 侧不存在 | 第 29 章 | 本机 SDK 把它们标成 `@available(*, unavailable)`（iOS 7 废弃后封死），编译期就失败；示例改走 CoreText 的 `CTLineDraw`，另用 `UIGraphicsPushContext` 验 UIKit 那条通路 |
| 非法位图参数组合（非预乘 RGBA、灰度 + 预乘、行距小于 `width × bytesPerPixel`）只登记不演示 | 第 29 章 | CG 一律静默给 `nil`，不崩、不报错、不打日志；拿这个返回值继续用就是越界写内存 |
| renderer 给的 `cgContext` 读不到像素、阴影偏移方向、真机 Metal 光栅化性能 | 第 29 章 | 那个上下文不是位图上下文（`width`/`bytesPerRow`=0、`data`=nil）；阴影偏移实测走设备轴、与文档措辞相反，需真机目视复核；性能数字不属于可复现断言 |
| 字体栅格化的墨像素绝对值、PNG/JPEG 体积差 | 第 29 章 | 随 iOS 版本与字体版本变，体积还会踩判定 4/5；只断言「有没有墨」「谁比谁多」和排版宽的近似区间 |
| 本章所有「编译器会报错 / 运行会崩」的写法只进 `examples/30_*/probes/` | 第 30 章 | 主线示例的六条判定要编译日志为空、退出码 0、stderr 为空；不合规的空格、缺 `override`、convenience 没委托、`99...1`、拆 nil 这些一律当场失败，只能各开一个进程量原文（`probes/run.sh` 跑 55 个，`w01_whitespace.sh` 跑 §2 那张空格表） |
| 随机数只问范围、字典与 Set 必先排序才打印 | 第 30 章 | `arc4random_uniform` 每次进程换种子、`Dictionary`/`Set` 的遍历顺序每进程重随机，都会让 debug/release 两份 stdout 对不齐（判定「两配置逐字节一致」） |
| 文档注释的 Quick Help 渲染、报错画线位置、Playground 结果栏不在验证范围 | 第 30 章 | 那是 IDE 功能；headless 只能拿到诊断**文本**（`file:line:col:` 里已带行列号）。本书原判据是「Playground 右侧显示什么」，本章整体换成 stdout 断言 |
| Swift 6 语言模式只测了一条新增拦截 | 第 30 章 | 探针 s06（全局可变状态被非隔离函数改）。`Sendable`/`actor`/`@MainActor` 整座山属于并发章节，本章不做 |
| 界面文件「名字写错」这一大类只登记在 `examples/31_*/probes/` | 第 31 章 | 因为编译期**根本没有信号**：`customClass`/`customModule` 写错、场景不可达、选择器多打一个字母，`ibtool` 一律 `rc=0`、诊断区为空、产物照出。能看见的下场全在运行时（静默退回 plain `UIViewController` / nib 根本不生成 / `unrecognized selector`），所以坏 XML 不进主线示例（探针 b01–b04、b09） |
| 会崩的连接错误只在独立探针进程里量 | 第 31 章 | 判定 2/3 要退出码 0、stderr 为空。`NSUnknownKeyException`（outlet 名在类里不存在、File's Owner 交错）、`Storyboard doesn't contain a view controller with identifier`（把 XML 的 `objectID` 当标识符）、`Custom instantiated view controller must call -[super initWithCoder:]`、`unrecognized selector` 这六种都是当场 abort（r01/r02/r03/r06/r07/r11/r12），正文只抄原文 |
| `ibtoold` 自己崩掉的那种坏写法不算产品行为 | 第 31 章 | 探针 b10（`type="number"` 配 `<real>` 之外的错形状）让 `ibtoold` 抛 `-[__NSCFNumber length]: unrecognized selector` 的 DVTAssertion、退出码 255、没有产物。登记原文，不写进任何断言 |
| `sendActions(for:)` 不派发、unwind 模板 `perform:` 弹不掉栈、SwiftUI 的 `body` 不挂窗口不算 | 第 31 章 | 三条同一个根：裸可执行文件里 `UIApplication.shared == nil`，事件派发与呈现都归它管。主线只断言「target-action 表读得出 + 手工把那句 `perform:` 打出去调得到」，并给出 Xcode 真 App 里的对应写法（§16/§20/§25） |
| 主线输出里所有 ObjC `description` 过一次地址脱敏，探针留档不脱敏 | 第 31 章 | 判定「debug 与 release 逐字节一致」容不下内存地址；而崩溃原文的 `0x…` 是异常消息的一部分，改了就不是原文。附录比对以消息文本、帧号与符号名为准 |
| Xcode 面板与资源编译器的功能不在验证范围 | 第 31 章 | 画布渲染、Inspector 的红点、`@IBDesignable` 预览、launch storyboard、trait variations、state restoration、导航容器在故事板里的 wiring，以及 `actool`/`Assets.car`（本章产物目录里只有松散 PNG，§24 走的是那条按文件名查表的路）。判据一律换成「`.storyboardc` 里有什么 + 运行时解出什么」 |
| 会崩的下标与 KVO 现场只进 `examples/32_*/probes/`，主线只断言可算的那一半 | 第 32 章 | 判定 2/3 要退出码 0、stderr 为空。`list[13]`（答完再点）、`questionScore[-1]`（忘填 tag）、`questionScore[2]`（隐藏按钮按在二选一那题）、漏改守卫的 `<= 28`、纯 Swift 属性上的 `observe(\.score)` 五处都是当场 SIGILL（退出码 132 / 信号 4），一句话都留不下；原文交给探针 r01–r05 |
| OC 侧的 nil 崩溃同样只在探针里量 | 第 32 章 | 探针 m02 把 `nil` 递进 `NSMutableArray` 的 `addObject:`，得到 `NSInvalidArgumentException`、退出码 **134 / SIGABRT**。这个数字和 rNN 那五支的 **132 / SIGILL** 不是一类崩溃（Swift 运行时断言走 `fatalError()`，OC 异常走 `objc_exception_throw`），正文只登记两族读数 |
| 书 7.12 那批「黄色叹号」在本仓库是硬失败 | 第 32 章 | 判定 1 要求编译日志为空。而 `-Wnullability-completeness` 的触发条件是头文件**标了一半**：m01（`HUDLoose` 并排一个 `NS_ASSUME_NONNULL` 包起来的 `HUDStrict`）逐条点出裸指针，m03（整份都不标）swiftc 日志为空、退出码 0 —— 所以「第三方库完全没标」这一种连判定 1 都碰不到，反而是工程里另一处标了、两边一撞才叫起来。原文交给探针 m01/m03 现跑现抄，主线那份 `ProgressHUD.h` 用第三种写法（宏不写、逐指针标 `_Null_unspecified`，Swift 侧与 m03 同样是隐式解析可选）—— 「不影响应用程序的功能」与「不许进构建」差的正是脚本里那一行判定 |
| 弹窗的**出现**、HUD 的**显示**、按钮的**点击**三件事不在验证范围 | 第 32 章 | 同一个缺失的 window 与事件循环：`present` 之后 `presentedViewController=nil`、`view.window=nil` 且 stderr 空；HUD 的 `frame` 是真的（`UIScreen.main.bounds`）而 `window`/`superview` 是 `nil`、`onScreen=false`；`sendActions(for:)` 不派发。判据换成「读回弹窗四字段 + `Trace` 账本 + 直调方法」（§17/§24/§30），与第 31 章 §16 是同一条边 |
| 不写「断环之后对象当场被收」这类断言 | 第 32 章 | 探针 c01 把同一句置空放进七种位置、两遍配置实测：`-Onone` 与 `-O` 两份 stdout 逐字一致，只有「连创建都在 `autoreleasepool` 里」那一格收得干净。回收时机由自动释放池层次决定，不由优化等级决定，所以 §25 只断言两个属性归 `nil` |
| 情商测试其余 27 题的题干文本不在仓库里 | 第 32 章 | 书 7.13 步骤 2 只印了前两题的 `Question` 构造，剩下让读者去 GitHub 的初始化项目取。主线用「第3题…第29题」占位，并把这件事写在断言里；本章量的是那组**数字**（29 题、6/3/0 三档、四个结论区间），不是那 27 行文字 |
| 故事板 / XIB 的装配与 IBOutlet·IBAction 接线归第 31 章 | 第 32 章 | 本章三台控制器全部代码装配（`tag` 也写代码里，等价于 Inspector 填 1/2/3），`init(coder:)` 直接 `fatalError`。第 32 章量的是「状态与更新机制」，界面文件那一侧的同一条「名字即接口」留给第 31 章 |
| 从 GitHub 真拉一个包、registry、`mirrors`、冲突求解不在第 33 章 | 第 33 章 | 回归不联网。s08 用本地 git fixture（`git init` + 打 tag）走同一条解析通路，锁里写的是 `"kind" : "localSourceControl"`；版本区间、`Package.resolved` 钉死 revision、`swift package update` 才放开、`--disable-automatic-resolution` 拦一次，这些全量到了。真实远端（`remoteSourceControl`）与多包冲突求解没验证 |
| 「资源路径写错基准」这一类在编译期**不报红** | 第 33 章 | s03 第一格：文件放在**包根**的 `Resources/`，声明照写 `.copy("Resources/city.json")`，得到的是 `warning: 'wrong': Invalid Resource … File not found.` + **退出码 0** + `Build complete!`。bundle 里根本没那条资源，要到运行时读 `Bundle.module` 才现形（本章 §16 用 `cityOffset()` 返回 `-1` 把它抓住）。末级名撞车才是硬错误（s03 第四格），它红在 manifest 校验期、一个 `.o` 都不产生 |
| 中间目录的绝对路径一律不进 stdout | 第 33 章 | s13 实测 `Bundle.module` 有两条候选：二进制旁边那份 `<Package>_<target>.bundle`，和**编译期写死在生成源码里的构建目录**。第二条在本机能命中（`退出码 = 0`、`entries=city.json,token.txt` 全对），所以「忘了拷 bundle」在本地是个**假绿**；把那份移走（等于换台机器）才当场 `Fatal error: could not load resource bundle: from … or …`、退出码 **132 / 信号 4**。主线按第一条摆，并把这条边写在 §18 |
| `swift test` 只在主机上跑通，本章主线不调它 | 第 33 章 | s11：`swift test`（不给 `--triple`）退出码 0、`Executed 1 test, with 0 failures`；换成 `--triple x86_64-apple-ios15.0-simulator` 得 `error: cannot find 'XCTAssertEqual' in scope`（那条路上没有 XCTest 的模块搜索路径）。测试的断言在主线里全部换成 `main.swift` 里的 `expect` |
| 动态库（`.library(type: .dynamic)`）只登记形状，不在主线加载 | 第 33 章 | s10 量到落盘 `libLib.dylib` 与 `LC_ID_DYLIB name @rpath/libLib.dylib`，但裸可执行文件要真加载它得自己补 `-Xlinker -rpath -Xlinker <那个目录>`，而那个目录带绝对路径（同上一条）。主线 §21 走静态：把各 target 的 `.o` 直接交给 swiftc |
| SwiftPM 的 `warning:` 不进判定 1 | 第 33 章 | 判定 1 管的是 swiftc 那份日志。`swift build` 的进度文本（`Building for debugging…` / `Build complete! (…)`）不是诊断，混进 `build.<cfg>.log` 会让每个用包的示例当场失败；所以进度进 `spm.<cfg>.log`，从里面**筛出**含 warning/error 的行单独立 `spm.<cfg>.diags`，由 `build_config` 在截断那句之后接进日志——包里的告警照样是硬失败，构建噪声不算 |
| Xcode 的「Add Package」面板、`.xcworkspace` 里的 `Package.resolved`、framework embedding 与签名不在范围 | 第 33 章 | 本教程没有 `.xcodeproj`/`.xcworkspace`，也没有 `.app` 可签。判据换成命令行上可数的东西：`swift build` 的退出码与原文、`--scratch-path` 下有什么（s12 那三层清单：`<T>.build/`、`Modules/<T>.{swiftmodule,swiftdoc,abi.json,swiftsourceinfo}`、`resource_bundle_accessor.swift.o`）、swiftc 实际收到的四类输入 |
| 预编译产物（`.xcframework`、裸 `.a`、`vendored_frameworks`）不在第 33 章 | 第 33 章 | 本章的 C 依赖是**源码级**的（`CLIBrain` 的 `brain.c` + `include/CLIBrain.h`），s12 量到它的 `module.modulemap` 里 umbrella 指向源码那个头。书 10.4 那节讲的「把第三方 `.framework` 拖进工程」在这一台机器上没有对应的可复现断言 |

这些都给出了**正确的 API 用法**并解释清楚为什么 headless 下走不通。第 20 章更进一步：把签名/装机/启动
的完整流水线**在宿主 shell 上真实跑通**（编译 → ad-hoc 签名 → `simctl install` → `launch --console-pty`），
实测输出收录在正文——真 App 里 `bundleIdentifier` 从 nil 变为 `com.iosdev.realapp`，`@main` 的 `init` 真实执行。

### Objective-C 示例为什么用 printf

`NSLog` 写的是**系统日志（stderr）**，而判定标准要求「stderr 为空」。生产代码用 `NSLog` 没问题，自测代码一律 `printf` / `print`。

## 与 Xcode 工程的对照

| Xcode 里 | 命令行等价物 |
| --- | --- |
| Deployment Target | `-target x86_64-apple-ios15.0-simulator` |
| SDKROOT | `-sdk` / `SDKROOT=` |
| Link Binary With Libraries | `-framework X`（或示例目录里的 `Frameworks` 文件） |
| Product Module Name | `-module-name` |
| Bridging Header | `-import-objc-header` |
| 生成的 Swift 头文件 | `-emit-objc-header-path` |
| `@main` App 入口 | 源文件不叫 `main.swift` 且加 `-parse-as-library` |
| Build Configuration | `-Onone`（debug） / `-O`（release） |
| 故事板 / XIB 的编译（Build Phases 里自动的那一步） | `xcrun ibtool --compile <输出目录或 .nib> <文件.storyboard\|.xib>`（第 31 章：`run-all.sh` 自动扫示例目录里的界面文件，产物直接放进可执行文件所在目录，ibtool 输出并入 `build.<配置>.log` 参与「编译日志为空」判定） |
| 装到模拟器 | `xcrun simctl install <UDID> App.app` |
| 启动 App | `xcrun simctl launch <UDID> <bundle-id>` |

本教程没有 `.xcodeproj`：理解了命令行版本，你就能读懂 Xcode 的 Build Settings（它们本质上就是这些参数的一张表）。

## 维护

- 改了判定函数 → **必须重做反向验证**（造坏样例确认每条判定真的会 FAIL）
- 新增示例 → 同步本文件「各章索引」+ `iOS开发指南.md` + `docs/` 下加一章；跑 `python3 tools/check_docs.py`
- 改了示例断言文案 → 同步更新对应 doc 里贴的输出块（`check_docs.py` 的「快照漂移」会挡住不一致）
- 示例需要额外系统框架 → 在示例目录放一个 `Frameworks` 文件，每行一个框架名
