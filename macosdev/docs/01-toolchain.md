# 01 · 工具链：不打开 Xcode 也能开发 macOS 应用

> 示例：`examples/01_toolchain/main.swift`
> 实测输出见 `build/01_toolchain/stdout.clt.txt`

## 为什么要先讲命令行

Xcode 很好用，但它把三件事藏起来了：编译器怎么被调起来的、SDK 在哪、
资源是怎么变成二进制的。出了问题你会束手无策，因为 IDE 里全是「Build Failed」
四个字，而真正的成因在下面两层。

**本章的目标是：不用 Xcode 打开任何工程，只靠终端就把一个 AppKit 程序编出来、跑起来。**
后面 19 章全部建立在这个能力上 —— 本教程的 20 个示例没有一个用 Xcode 工程，
全是脚本编译的，所以你可以随时复现。

## 本机事实（这些数据是从机器上实测来的）

| 项目 | 值 |
| --- | --- |
| macOS | 14.8.9（Darwin 23.6.0） |
| 架构 | x86_64 |
| Xcode | 16.2（Build 16C5032a，`/Applications/Xcode.app`） |
| Xcode 工具链 | `.../Toolchains/XcodeDefault.xctoolchain` |
| Xcode SDK | `.../Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk`（macOS 15.2） |
| Command Line Tools | `/Library/Developer/CommandLineTools` |
| CLT SDK | `/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk`（macOS 15.2） |
| Swift | 6.0.3（swiftlang-6.0.3.1.10）—— 两套工具链同版本 |
| Apple clang | 16.0.0（clang-1600.0.26.6） |
| 部署目标 | `x86_64-apple-macos12.0`（**刻意钉得比本机低**，见下） |

也就是说**本机有两套可用的 Swift**：

```bash
/usr/bin/swiftc                                          # CLT 自带的（走 xcode-select）
/Applications/Xcode.app/.../usr/bin/swiftc               # Xcode.app 里那套
```

这两套版本号可能不一样（本机恰好都是 6.0.3）。本教程的验证脚本**两条通道都跑一遍，再逐字节比对输出** ——
这一步不是强迫症，它抓到过的真实问题包括「SDK 版本不同导致某个 API 的默认值不同」。

## xcrun：永远不要硬编码路径

```bash
xcrun --show-sdk-path              # 当前 SDK 的根目录
xcrun --find swiftc                # swiftc 在哪
xcrun --find ibtool                # ibtool 在哪
xcrun --sdk macosx --find clang
```

`xcrun` 会按 `DEVELOPER_DIR` → `xcode-select -p` 的顺序找工具。
想临时切到另一套工具链，设置环境变量即可，**不要去改系统级配置**：

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

> **坑**：只装了 Command Line Tools 的机器上，`ibtool` / `actool` / `xcodebuild`
> **不存在**。这两个是 Xcode.app 独有的（Interface Builder 编译器和 Asset Catalog
> 编译器）。本教程里的 XIB 章节因此必须在有 Xcode.app 的机器上跑。

## 编译一个 Swift 程序

```bash
swiftc -O -sdk "$(xcrun --show-sdk-path)" \
       -target x86_64-apple-macos12.0 \
       -module-name toolchain main.swift \
       -o 01_toolchain \
       -framework Foundation -framework AppKit
```

几个参数的意思：

- **`-sdk`**：去哪个 SDK 里找头文件与 `.tbd`（stub 动态库）。不给也能编，
  但 macOS 上 Swift 会自动挑一份，跨机器就可能挑到不一样的 —— **显式给**。
- **`-target <arch>-apple-macos<version>`**：产出什么架构、要求最低系统版本。
  这是写进 Mach-O 里的元数据，运行时 dyld 会检查。
- **`-module-name`**：模块名。混编时 Swift 生成的头文件叫 `<module>-Swift.h`，
  这个名字不对就找不到。
- **`-framework X`**：链接系统框架。AppKit 不在默认链接集合里，必须显式给。

## 编译一个 Objective-C 程序

```bash
clang -O2 -std=gnu11 -fobjc-arc -fmodules \
      -Wall -Wextra -Wno-unused-parameter \
      -isysroot "$(xcrun --show-sdk-path)" \
      -target x86_64-apple-macos12.0 \
      main.m -o demo -framework Foundation -framework AppKit
```

- **`-fobjc-arc`**：ARC。**现代 OC 一律开**，不开就是手动 `retain/release`。
- **`-fmodules`**：模块化的 framework 导入（`@import AppKit;` 也能用）。
- **`-Wall -Wextra`**：本教程把「编译零告警」当成硬性判定标准，所以告警开着。

## ibtool：XIB → nib

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  ibtool --errors --warnings --notices --compile MainView.nib MainView.xib
```

`--compile` 出来的 `.nib` 是一个**单文件**（早期是目录）。运行时用
`Bundle.loadNibNamed` 加载。

> **坑**：`ibtool` 在本机上**很慢**，编一个只有几个控件的 XIB 要 30 秒到 3 分钟
> （它要加载 Interface Builder 的 Cocoa 插件）。别以为它卡死了，给足超时。
> 本教程的脚本给它 180 秒。
>
> **坑**：`ibtool` 只在有问题时输出内容。**日志非空 = 有告警**，
> 反过来「一片安静」才是正常的。

## 编译期条件：把「跑在哪」变成常量

```swift
#if canImport(AppKit)
// 只有能 import AppKit 的时候才编译这段
#endif

#if os(macOS)
// macOS 专用代码
#endif

if #available(macOS 12.0, *) {
    // 运行时判断，部署目标低于 12 时也能编过
}
```

示例实测：

```
== 编译期事实 ==
swift 版本 >= 5.7 : true
canImport(AppKit) : true
os(macOS)         : true
simulator         : false
```

`#if` 是**编译期**，不满足的代码根本不进二进制；`#available` 是**运行时**，
两段代码都在二进制里，跑起来才选。想支持老系统就用后者，想让 iOS 版不带桌面代码
就用前者。

## 部署目标

```
== 部署目标（编译进二进制的一条元数据）==
系统 >= 14.0 : true
系统 >= 15.0 : false
走进 macOS 15 分支 : false
```

`-target` 里的 `macos12.0` 就是**部署目标**：它是一条**编译进二进制**的元数据，
声明「这个程序最低要跑在 macOS 12.0 上」。它的作用在**编译期**——
如果你不加 `#available` 守卫就用了一个 macOS 13 才有的 API，编译器会**直接报错**，
而不是等到运行时才崩。本教程把部署目标刻意钉在比本机（14.8.9）低的 12.0，
就是为了让「误用新 API」在编译期暴露出来。

**但要分清两件事**（这是最容易搞混的一点）：

- **部署目标**（`-target ...macos12.0`）：编译期契约，决定编译器放不放行新 API。
- **`#available` / `isOperatingSystemAtLeast`**：**运行期**判定，判的是
  「**此刻实际跑在哪个系统版本上**」，跟部署目标、跟 SDK 版本都**无关**。

所以上面 `系统 >= 14.0` 是 true、`系统 >= 15.0` 是 false，判的是本机实际系统
（14.8.9），**不是**部署目标 12.0。`if #available(macOS 15.0, *)` 同理：
本机还不到 15，所以走 else 分支。部署目标只影响「编译器要不要保留 else 分支」
（部署目标 ≥ 15 时编译器知道 else 永远走不到，会优化掉并允许你省略守卫），
真正运行时走哪条，永远由**实际系统版本**决定。

> 一句话：**部署目标管编译，`#available` 管运行。** 两者要成对设置——
> 部署目标定低（支持老系统），新 API 一律用 `#available` 守卫。

## Bundle 与进程信息

命令行工具也是个 bundle，只不过结构极简：

```
== Bundle ==
bundlePath 是目录 : true
资源目录名 == 工作目录名 : true
Info.plist 存在 : true
```

`Bundle.main.bundlePath` 对命令行工具来说就是**可执行文件所在目录**，
而 `resourcePath` 等于它自己。这就是为什么示例里能直接 `loadNibNamed("MainView")`
—— 脚本把编好的 nib 放在了可执行文件旁边。

`ProcessInfo` 给出运行时的机器信息：

```
argc == 2 : true              // 脚本传了 --selftest
收到 --selftest : true
当前是主线程 : true
物理内存 > 0 : true
处理器数 > 0 : true
```

**示例一律用 `--selftest` 参数进入自测模式**：不弹窗、不建窗口、
只做断言然后退出。这样示例才能在 CI/终端里跑。

## 区域与格式化：最典型的不稳定源

```
== 区域与格式化：不稳定的典型 ==
固定 en_US_POSIX : 1234567.89
使用系统 locale 时非空 : true
两种 locale 的分隔符是否必然相同 : false  ← 所以上面才不打印它的原文
```

**坑**：`NumberFormatter` / `DateFormatter` 不指定 `locale` 就跟着系统走。
同一份代码，在一台中文机上和一台英文机上输出不同。写断言时：

1. 要么显式钉住 `locale = Locale(identifier: "en_US_POSIX")`；
2. 要么**只断言性质**（非空、能解析回来），绝不打印原文。

本教程 20 个示例能「双工具链输出逐字节一致」，靠的就是这条纪律。

## 判定标准（本教程全部示例共用）

一个示例「通过」要同时满足六条：

1. **编译日志为空** —— 零告警，包括 `ibtool` 的
2. **退出码为 0**
3. **stderr 为空**
4. **stdout 非空** —— 防止进程根本没执行到业务代码却返回 0
5. **stdout 无多余控制字符**（0..31 除 TAB/LF/CR）
6. **stdout 有结束标记** `==== NN 结束 ====` —— 防止输出被截断

第 4 条来自真事：macOS 上用 PowerShell 启动一个 `.dll` 会被 LaunchServices
当文档「打开」，报 `No application knows how to open URL ...`，**退出码却是 0**。
只看退出码会漏掉一整类假阳性。

## 与 Xcode 工程的对照

| 你在 Xcode 里看到的 | 命令行等价物 |
| --- | --- |
| Build Settings → Deployment Target | `-target ...-apple-macos12.0` |
| Build Settings → SDKROOT | `-sdk` / `-isysroot` |
| Link Binary With Libraries | `-framework X` |
| Product Module Name | `-module-name` |
| Build Phases → Compile Sources | `swiftc -c` + `clang -c` |
| 编译 .xib | `ibtool --compile` |
| 编译 .xcassets | `actool` |
| Scheme → Arguments | 命令行参数 |

Xcode 工程项目文件（`.xcodeproj`/`.pbxproj`）本质就是这些参数的一个庞大数据库。
理解命令行版本，你就能读懂它。

## 动手

```bash
cd macosdev
./run-all.sh               # 跑全部 20 个示例（双通道）
./run-all.sh 01 02         # 只跑 01、02
/opt/local/bin/pwsh ./build.ps1 -All
```

两个入口做的事情完全等价 —— 这不是重复劳动，是**互证**：
同一份示例在两条脚本下结论一致，才能说明判定的不是脚本自己的 bug。
