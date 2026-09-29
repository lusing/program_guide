# iOS 应用开发教程（Xcode / Swift / Objective-C / SwiftUI / UIKit）

用**本机 Xcode 16.2（Swift 6.0.3）+ iOS 18.2 SDK**，在 **iPhone 模拟器**里讲 iOS 原生应用开发：
SwiftUI（主线）、UIKit（底层）、Objective-C 运行时与 C 语言层（地基）、Foundation、网络并发、持久化（含 SQLite3
与 CoreData）、权限通知、动画与多媒体、传感器定位、Quartz 2D 直接绘制、打包签名上架。

29 章正文放在 [`docs/`](./docs)（目录页见 [`iOS开发指南.md`](./iOS开发指南.md)），每章对应 `examples/` 下一个**可编译、可运行、可自测**的示例。
全部示例都**不打开 Xcode、不建窗口、不弹 UI**——只用 `swiftc` / `clang` 编成命令行可执行文件，
`xcrun simctl spawn` 在模拟器里跑 headless 自测，因为这样你才知道 Xcode 到底替你做了什么。

## 快速开始

```bash
cd iosdev

./run-all.sh                # 跑全部 29 个示例（debug + release 两配置 × 六条判定）
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
├── docs/                     29 章正文
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
│   └── 29-quartz-2d.md
├── examples/                 29 个示例目录（NN_topic）
│   ├── 01_toolchain/main.swift
│   ├── 07_objc_swift_mix/    (OC + Swift 混编，含 Bridging.h / Greeter.h/.m / LegacyNote.h/.m)
│   ├── 19_permissions_notifications/  (含 Frameworks 文件，声明额外链接的系统框架)
│   ├── 24_audio_video/       (含 Frameworks：AVFoundation / AVKit / MediaPlayer)
│   ├── 25_sensors_location/  (含 Frameworks：CoreMotion / CoreLocation / AVFoundation / LocalAuthentication / CoreBluetooth / MapKit / Security)
│   ├── 26_sqlite_coredata/   (SQLite3 走 `import SQLite3`，不需要额外 framework 文件)
│   ├── 27_objc_runtime/      (含 Bridging.h + 三个 .m：RTMsg 消息发送与类型编码 / RTDecl 属性·分类·协议 / RTDyn 转发·换实现·KVC·KVO)
│   ├── 28_c_layer/           (三方混编：四个 .c + 一个 .m + Swift，含 Bridging.h；.c/.m 恒为 -O2)
│   └── 29_quartz2d_drawing/  (含 Frameworks：CoreText；全章判据是回读自己提供的位图缓冲区)
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

## 建议阅读顺序

- **从零开始（SwiftUI 主线）**：01 → 02 → 03 → 08 → 09 → 10 → 11 → 12 → 17 → 18 → 26 → 20
- **要写 Objective-C / 维护老项目**：04 → 05 → 07 → 27（运行时）→ 28（C 层）
- **要吃透 UIKit 底层**：13 → 14 → 15 → 16 → 21 → 22 → 23
- **要做动画**：12（SwiftUI 侧）→ 23（Core Animation 侧）
- **要做自绘 / 图像 / PDF**：12（SwiftUI 的 Canvas/Path）→ 23（图层树侧）→ **29（像素侧：Quartz 2D）**
- **要摸到语言的地板**：28（C：尺寸、对齐、句柄、UB）→ 27（OC：消息、转发、KVC/KVO）
- **要做音视频 / 传感器 / 定位**：19（权限）→ 24、25
- **专项**：06（Swift 侧桥接）、19（权限/通知）、20（打包上架）、26（SQLite 与 CoreData）、29（离屏出图与画板）

## 验证状态（全部通过）

```
通过 58   失败 0   输出差异 0   示例 29   配置 2
```

- **29 个示例 × 2 个优化配置（debug/release）= 58 次运行，全部 PASS**
- **两配置 stdout 逐字节一致**（`[cmp]` 全绿）
- `tools/check_docs.py`：结构（01..29 齐全）/ 引用（示例·输出路径存在）/ 快照（文档里贴的断言行逐字对得上 build 输出）三项全绿

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
- 环境相关的数字（耗时、线程 id、`processorCount`、屏幕尺寸、系统版本）**只打印性质、不断言具体值**；耗时只作相对比较（如 `concElapsed < seqElapsed`）。

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
| 装到模拟器 | `xcrun simctl install <UDID> App.app` |
| 启动 App | `xcrun simctl launch <UDID> <bundle-id>` |

本教程没有 `.xcodeproj`：理解了命令行版本，你就能读懂 Xcode 的 Build Settings（它们本质上就是这些参数的一张表）。

## 维护

- 改了判定函数 → **必须重做反向验证**（造坏样例确认每条判定真的会 FAIL）
- 新增示例 → 同步本文件「各章索引」+ `iOS开发指南.md` + `docs/` 下加一章；跑 `python3 tools/check_docs.py`
- 改了示例断言文案 → 同步更新对应 doc 里贴的输出块（`check_docs.py` 的「快照漂移」会挡住不一致）
- 示例需要额外系统框架 → 在示例目录放一个 `Frameworks` 文件，每行一个框架名
