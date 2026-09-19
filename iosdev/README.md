# iOS 应用开发教程（Xcode / Swift / Objective-C / SwiftUI / UIKit）

用**本机 Xcode 16.2（Swift 6.0.3）+ iOS 18.2 SDK**，在 **iPhone 模拟器**里讲 iOS 原生应用开发：
SwiftUI（主线）、UIKit（底层）、Objective-C、Foundation、网络并发、持久化、权限通知、打包签名上架。

20 章正文放在 [`docs/`](./docs)（目录页见 [`iOS开发指南.md`](./iOS开发指南.md)），每章对应 `examples/` 下一个**可编译、可运行、可自测**的示例。
全部示例都**不打开 Xcode、不建窗口、不弹 UI**——只用 `swiftc` / `clang` 编成命令行可执行文件，
`xcrun simctl spawn` 在模拟器里跑 headless 自测，因为这样你才知道 Xcode 到底替你做了什么。

## 快速开始

```bash
cd iosdev

./run-all.sh                # 跑全部 20 个示例（debug + release 两配置 × 六条判定）
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
├── docs/                     20 章正文
│   ├── 01-toolchain.md
│   ├── ...
│   └── 20-packaging-signing.md
├── examples/                 20 个示例目录（NN_topic）
│   ├── 01_toolchain/main.swift
│   ├── 07_objc_swift_mix/    (OC + Swift 混编，含 Bridging.h / Greeter.h/.m / LegacyNote.h/.m)
│   ├── 19_permissions_notifications/  (含 Frameworks 文件，声明额外链接的系统框架)
│   └── 20_packaging_signing/main.swift
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

## 建议阅读顺序

- **从零开始（SwiftUI 主线）**：01 → 02 → 03 → 08 → 09 → 10 → 11 → 12 → 17 → 18 → 20
- **要写 Objective-C / 维护老项目**：04 → 05 → 07
- **要吃透 UIKit 底层**：13 → 14 → 15 → 16
- **专项**：06（Swift 侧桥接）、19（权限/通知）、20（打包上架）

## 验证状态（全部通过）

```
通过 40   失败 0   输出差异 0   示例 20   配置 2
```

- **20 个示例 × 2 个优化配置（debug/release）= 40 次运行，全部 PASS**
- **两配置 stdout 逐字节一致**（`[cmp]` 全绿）
- `tools/check_docs.py`：结构（01..20 齐全）/ 引用（示例·输出路径存在）/ 快照（文档里贴的断言行逐字对得上 build 输出）三项全绿

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
- 环境相关的数字（耗时、线程 id、`processorCount`、屏幕尺寸、系统版本）**只打印性质、不断言具体值**；耗时只作相对比较（如 `concElapsed < seqElapsed`）。

### 诚实处理 headless 的边界（不伪造绿灯）

有几件事在裸 `simctl spawn` 的进程里**做不到**，本教程一律**如实标注边界**，而不是假装成功：

| 边界 | 出现在 | 原因 |
| --- | --- | --- |
| `sendActions(for:)` / 手势状态迁移不触发 target-action | 第 16 章 | 需真实事件系统投递 |
| Keychain `SecItem*` 返回 `errSecMissingEntitlement(-34018)` | 第 18 章 | 裸 spawn 无 `keychain-access-groups` entitlement |
| `UNUserNotificationCenter.current()` 会崩，不调用 | 第 19 章 | 需真实 `.app` 包（`bundleProxyForCurrentProcess`） |
| 无法在进程内 `exec` `codesign`/`simctl` | 第 20 章 | iOS 无 `Process`/`NSTask`（macOS 独有） |

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
