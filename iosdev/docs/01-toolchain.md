# 01 · 全景与工具链：iOS 开发到底在跟什么打交道

> 示例：`examples/01_toolchain/main.swift`
> 实测输出见 `build/01_toolchain/stdout.debug.txt`

## 这一章回答什么

- iOS 应用开发的**技术栈**长什么样，各层各管什么；
- **SwiftUI** 和 **UIKit** 是什么关系，为什么本教程「SwiftUI 为主、UIKit 为底」；
- 这台机器上到底装了哪些工具、什么版本（下面有实测表）；
- 本教程为什么**不打开 Xcode 工程**、而是用命令行 `swiftc` + 模拟器把每个示例编出来跑；
- 一个示例「通过」要满足哪**六条判定**；
- iOS 里最容易被讲错的一对概念：**部署目标**（编译期）与 `#available`（运行期）。

## 1) 技术栈分层

iOS 应用不是「直接对着系统编程」，而是站在一摞框架上。从下往上：

```
┌─────────────────────────────────────────────┐
│  你的 App（Swift / Objective-C 代码）          │
├─────────────────────────────────────────────┤
│  SwiftUI（声明式 UI）   │   UIKit（命令式 UI）  │  ← 界面层，二选一或混用
├─────────────────────────────────────────────┤
│  Foundation：NSString/Array/Dict/Data/URL/     │  ← 数据与基础服务
│  JSON/日期/通知/KVC-KVO/错误处理                │
├─────────────────────────────────────────────┤
│  Core 服务：Core Animation / Core Graphics /   │  ← 图形、网络、定位、并发…
│  URLSession / Core Location / GCD / Combine    │
├─────────────────────────────────────────────┤
│  Darwin / XNU 内核 + POSIX + Mach              │  ← 操作系统底座
└─────────────────────────────────────────────┘
```

关键点：

- **Foundation 是跨 Apple 平台通用的**。你在 macOS 教程（`macosdev`）里学的
  `NSString`/`NSArray`/`Codable`/`URLSession`，在 iOS 上一字不差地照用。
  所以本教程的语言与 Foundation 章节（04–07）和 macOS 版高度呼应。
- **界面层才是 iOS 与 macOS 真正分家的地方**：iOS 用 UIKit（`UIView`/
  `UIViewController`）和 SwiftUI，macOS 用 AppKit（`NSView`/`NSViewController`）。
  SwiftUI 在两个平台是**同一套 API**，这正是它最大的价值。
- **Cocoa Touch** 是 UIKit + 一堆触摸/移动端框架的合称，对应 macOS 的 Cocoa。

## 2) SwiftUI 与 UIKit：不是替代，是分层

| | UIKit | SwiftUI |
|---|---|---|
| 范式 | 命令式（你告诉它怎么一步步搭界面） | 声明式（你描述界面长什么样） |
| 引入 | 2008（iOS 2） | 2019（iOS 13） |
| 基本单位 | `UIView` / `UIViewController` | `View`（一个 struct） |
| 布局 | frame + Auto Layout 约束 | 布局协议 + 修饰符链 |
| 状态 | 手动同步（改 model → 手动更新 view） | `@State`/`@Binding` 自动驱动重绘 |
| 现状 | 存量巨大、底层能力最全 | 新代码首选、每年补齐能力 |

**为什么本教程「SwiftUI 为主、UIKit 为底」：**

1. 新 App 的界面绝大多数用 SwiftUI 写，这是主线（第 08–13 章）。
2. 但 SwiftUI **底下仍是 UIKit**：每个 SwiftUI 视图最终都渲染进一个
   `UIHostingController` 的 `UIView` 树里。系统控件、键盘、`UIActivityIndicatorView`
   这些还是 UIKit 的东西。
3. 有些能力 SwiftUI 还没覆盖，或你需要复用一段老的 UIKit 代码 —— 这时用
   `UIViewRepresentable` 把 UIKit 包进 SwiftUI（第 13 章）。
4. 面试、维护存量项目、读懂报错，都要求你看得懂 UIKit（第 14–16 章）。

一句话：**SwiftUI 是你每天写的，UIKit 是你必须看懂的。**

## 3) 本机工具事实（实测）

本教程所有输出都在这台机器上真实跑出来过。环境如下：

| 项 | 值 | 怎么查 |
|---|---|---|
| 宿主 macOS | 14.8.9（Darwin 23.6.0，x86_64） | `sw_vers` / `uname -a` |
| Xcode | 16.2（Build 16C5032a） | `xcodebuild -version` |
| iOS SDK | 18.2（`iPhoneSimulator18.2.sdk`） | `xcrun --sdk iphonesimulator --show-sdk-path` |
| 模拟器运行时 | iOS 18.3.1（iPhone 16 Pro 等） | `xcrun simctl list` / 运行时 `UIDevice.systemVersion` |
| Swift | 6.0.3 | `swiftc --version` |
| Apple clang | 16.0.0 | `clang --version` |
| 部署目标（本教程钉死） | iOS 15.0（模拟器） | `run-all.sh` 里的 `DEPLOY_TARGET` |

> **注意 SDK 版本 ≠ 运行时版本**：SDK 是 18.2（编译时能看到的 API 到 18.2），
> 模拟器运行时是 18.3.1（`UIDevice.current.systemVersion` 报的）。两者经常差一个
> 小版本，别混为一谈。

## 4) 为什么不开 Xcode 工程

Xcode 工程（`.xcodeproj`）把「怎么编译、怎么签名、怎么打包、怎么装进模拟器」
全藏在图形界面和一堆构建配置里。对初学者，这层「魔法」恰恰是最该被拆开的：

本教程**全程用命令行**把每个示例编出来、丢进模拟器跑：

```bash
SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
# 为模拟器编译成一个命令行可执行文件（部署目标钉在 iOS 15）
SDKROOT=$SDK swiftc -sdk "$SDK" -target x86_64-apple-ios15.0-simulator \
    main.swift -o app \
    -framework Foundation -framework UIKit -framework SwiftUI
# 启动一台模拟器，把这个可执行文件丢进去跑
xcrun simctl boot <UDID>
xcrun simctl spawn <UDID> ./app --selftest
```

这样做的好处：

- **看得见每一步**：SDK、部署目标、链接哪些 framework、怎么进模拟器，全是明牌。
- **可复现、可自动验证**：`run-all.sh` 一条命令跑完 20 个示例，机器判定通过与否，
  不靠人眼看截图。
- **headless**：示例都是命令行可执行文件，构造真实的 UIKit/SwiftUI 对象、跑断言、
  打印、退出 —— 不需要真的弹出一个 App 界面（那属于第 20 章的打包内容）。

> `SDKROOT=$SDK` 这个环境变量不是可有可无：不设它，`swiftc` 调用 clang 链接时会
> 默认拿 MacOSX 的 sysroot，吐出一条 `-Wincompatible-sysroot` 告警。本教程判定
> 要求「编译日志全空」，所以必须消掉它。

## 5) 六条判定：什么叫「这个示例通过了」

`run-all.sh` 对每个示例、每个配置都卡这六条，任一不满足即 FAIL：

1. **编译日志为空** —— 零告警（`-Wall -Wextra` 已开，`SDKROOT` 已设）
2. **退出码为 0**
3. **stderr 为空** —— 示例一律用 `print`，不用 `NSLog`（后者写 stderr）
4. **stdout 非空** —— 挡住「进程根本没跑到业务代码、退出码却是 0」
5. **stdout 无多余控制字符**（0..31 除 TAB/LF/CR）
6. **stdout 有结束标记** `==== NN 结束 ====` —— 挡住输出被截断

再加一条安全网：

7. **debug(-Onone) 与 release(-O) 两个配置的 stdout 逐字节一致** ——
   挡住「只在优化下才暴露」的未定义行为，以及依赖优化等级的巧合。

> **和 macosdev 的差异**：iOS SDK 只随 Xcode 提供，Command Line Tools 里没有，
> 所以这里**只有一条工具链**。macosdev 用「CLT / Xcode 双工具链逐字节比对」，
> 本教程改成「debug / release 双配置逐字节比对」，保留同一张安全网。

### headless 自测约定

每个示例都认 `--selftest` 参数，遵守这些纪律：

- **不建窗口、不进 UI 事件循环、不调 `UIApplicationMain`/`@main`**（那需要打包成
  真正的 `.app`，见第 20 章）。
- 需要界面时，只**构造** `UIView`/`UIViewController`/SwiftUI `View`，
  用 `loadViewIfNeeded()` 触发建视图，然后断言其结构 —— 绝不 `makeKeyAndVisible`。
- **只断言性质，不打印环境相关的数字**（iOS 版本号、屏幕尺寸、时间戳、并发计数）。
  这样文档里的输出快照换台机器也对得上；真实版本号只写在上面的事实表里。

## 6) 部署目标 vs `#available`：编译期 vs 运行期

这是 iOS 开发最核心、也最常被讲错的一对概念。示例 01 专门演示了它：

- **部署目标（deployment target = iOS 15.0）** 是**编译期契约**。
  它告诉编译器「我最低支持到 iOS 15」，于是 iOS 15 及更早的 API 可以**无条件**
  直接调用。它**不**在运行时做任何检查，也**不**阻止你链接更高版本的 API。

- **`if #available(iOS 16, *)`** 是**运行期检查**。它问「当前这台设备的系统
  **实际**是不是 ≥ 16」，与部署目标、与用哪个 SDK 编译**全都无关**。只有它返回真，
  才能安全调用 iOS 16 才有的 API。

实测输出（节选）：

```
== 部署目标 vs 运行期 #available ==
  if #available(iOS 16,*) 命中 : true
  ok   运行期系统 ≥ iOS 16（本机模拟器满足）
  if #available(iOS 99,*) 命中 : false
  ok   远未来版本不命中（说明 #available 是真实的运行期门控）
  iOS 15 API 可直接调用（无 #available）: true
  ok   iOS 15+ 的 UIButton.Configuration 无需守卫即可用
```

读法：本机模拟器运行时是 iOS 18.x，所以 `#available(iOS 16,*)` 命中；
而 `#available(iOS 99,*)` 不命中 —— 证明它真的在做门控，不是「编过了就恒为真」。
`UIButton.Configuration` 是 iOS 15 引入的，因为部署目标就是 15.0，可以直接用、不用守卫。

> **口诀**：部署目标决定「最低能装到哪台设备」，`#available` 决定「此刻能不能用新 API」。
> 想调比部署目标更新的 API，就用 `#available` 守卫，并给旧系统留一条退路。

## 7) 模拟器 vs 真机

- **模拟器（Simulator）** 不是虚拟机：它把你的 App 当成宿主机上的一个普通进程跑，
  共享 macOS 内核，只是链接的是「模拟器版」的 iOS 框架。所以它**快**、能跑绝大多数
  UI 与逻辑代码，是本教程的验证环境。
- 模拟器**测不了**的：真实的相机/传感器、推送、性能与耗电、App Store 签名与安装、
  某些依赖真实 GPU/安全区的行为。这些要上真机。
- 架构差异：Apple Silicon 上模拟器是 `arm64`，Intel 上是 `x86_64`。`run-all.sh`
  用 `uname -m` 自动选，本机是 Intel，所以是 `x86_64-apple-ios15.0-simulator`。

## 8) 示例 01 完整输出

```
== 01 工具链与运行环境 ==
  --selftest 传入 : true
  ok   命令行能读到 --selftest（说明 argv 传递正常）

== 编译目标 ==
  ok   targetEnvironment(simulator) 为真（为模拟器编译）
  userInterfaceIdiom == .phone : true
  ok   运行在 iPhone/iPad 形态上（模拟器）

== 部署目标 vs 运行期 #available ==
  if #available(iOS 16,*) 命中 : true
  ok   运行期系统 ≥ iOS 16（本机模拟器满足）
  if #available(iOS 99,*) 命中 : false
  ok   远未来版本不命中（说明 #available 是真实的运行期门控）
  iOS 15 API 可直接调用（无 #available）: true
  ok   iOS 15+ 的 UIButton.Configuration 无需守卫即可用

== Foundation / UIKit / SwiftUI 可达性 ==
  ok   Foundation：JSON 往返正常
  ok   UIKit：UILabel 可构造并持有文本
  ok   UIKit：sizeToFit 之后 frame 合法
  ok   UIKit：UIViewController.loadViewIfNeeded 后 view 非空
  SwiftUI：Badge.body 的具体类型含 "Text" : true
  ok   SwiftUI：自定义 View 的 body 可求值，底层是 Text

全部断言通过。
==== 01 结束 ====
```

## 小结

- iOS 栈：**你的代码 → SwiftUI/UIKit → Foundation → Core 服务 → Darwin**。
  Foundation 跨平台通用，界面层才是 iOS 的特色。
- **SwiftUI 为主、UIKit 为底**：SwiftUI 是每天写的，UIKit 是必须看懂的（SwiftUI 底下就是它）。
- 本教程用**命令行 + 模拟器**，不开 Xcode 工程：看得见每一步，且能被机器自动验证。
- **六条判定 + debug/release 逐字节比对**，示例一律 headless `--selftest`、只断言性质。
- **部署目标是编译期契约，`#available` 是运行期检查**，两者独立，别混。

下一章：`02-hello-app.md` —— 用 SwiftUI 和 UIKit 各写一个最小 App 骨架，看清两套入口。
