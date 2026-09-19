# 20 · 打包 / 签名 / 上架：一个 `.app` 到底是什么

> 示例：`examples/20_packaging_signing/main.swift`（headless 自测：亲手搭出并验证一个真 bundle）
> 实测输出见 `build/20_packaging_signing/stdout.debug.txt`
> 本章还包含**宿主 shell 上真实的 codesign + install + launch 实测记录**（见文末）

前 19 章都是「裸可执行文件 + `simctl spawn`」。这一章揭开**真 App 的形态**：一个 `.app`
其实就是一个**目录（bundle）**，里面按约定放着可执行文件、`Info.plist`、资源。系统启动时读
`Info.plist` 找入口、读**签名**验完整性与来源。本章 headless 地在磁盘上**亲手搭出一个合法的
`.app` bundle**、用 `Bundle` API 当真 bundle 加载并逐字段验证；再把只能在宿主 shell 跑的
「签名 → 装机 → 启动 → 归档 → 上架」流水线讲清楚，并附**真实跑通的实测输出**。

> **为什么签名/装机不在自测进程里跑**：iOS **没有** `Process`/`NSTask`（那是 macOS 独有 API），
> 裸 spawn 的进程无法再 `fork`/`exec` 去调 `codesign`、`simctl`。所以自测只负责**能 headless
> 验证的部分**（bundle 结构 + `Info.plist` 契约 + `Bundle` 加载）；签名与装机用真实命令在宿主
> shell 上跑（见文末实测）。这与第 16/18/19 章一致：能真跑的跑到底，跑不了的讲清楚、不伪造。

## 1) 对照：当前进程不是 `.app`

```
-- 对照：Bundle.main（当前运行进程）--
  Bundle.main.bundlePath = .../iosdev/build/20_packaging_signing
  Bundle.main.bundleIdentifier = nil
  Bundle.main.executableURL 非空 = true
  ok   裸 spawn 的 Bundle.main 没有 bundleIdentifier（不是 .app）
```

裸 spawn 时 `Bundle.main` 只是可执行文件所在目录，没有 `.app` 结构，所以
`bundleIdentifier` 为 **nil**——这正是「它不是打包好的 App」的铁证。**对比文末真实 `.app`
启动时 `bundleIdentifier = com.iosdev.realapp`（非 nil）**，一眼看出打包前后的差别。

## 2) 亲手搭一个 `.app` bundle

`.app` 就是目录，约定放三样东西：**可执行文件**、**`Info.plist`**、**资源**。

```swift
let appURL = tmp.appendingPathComponent("Demo.app")
try fm.createDirectory(at: appURL, withIntermediateDirectories: true)

// (a) 可执行文件：CFBundleExecutable 指的那个 Mach-O（真 App 里是 Xcode 链接产物）
try fm.copyItem(at: URL(fileURLWithPath: CommandLine.arguments[0]),
                to: appURL.appendingPathComponent("Demo"))

// (b) Info.plist：bundle 的身份证 + 说明书
let info: [String: Any] = [
    "CFBundleIdentifier": "com.iosdev.demo",   // 唯一标识，签名/上架都认它
    "CFBundleExecutable": "Demo",              // 指向 bundle 里的可执行文件名
    "CFBundleName": "Demo", "CFBundleDisplayName": "演示 App",
    "CFBundleVersion": "1",                    // build 号（每次上传递增）
    "CFBundleShortVersionString": "1.0",       // 市场版本号（用户看到的）
    "CFBundlePackageType": "APPL",
    "MinimumOSVersion": "15.0", "UIDeviceFamily": [1],
    "UILaunchStoryboardName": "LaunchScreen",
    "NSCameraUsageDescription": "用于扫描二维码",   // 第 19 章：请求相机前必须声明
]
try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
    .write(to: appURL.appendingPathComponent("Info.plist"))
```

```
-- 构造 Demo.app：一个 bundle 就是一个约定结构的目录 --
  ok   建出了 Demo.app 目录（bundle 本体）
  ok   把可执行文件放进了 bundle（名为 Demo）
  ok   写入了 Info.plist
  Demo.app/ 内容 = ["Assets", "Demo", "Info.plist", "PkgInfo"]
  ok   bundle 目录含 Assets/Demo/Info.plist/PkgInfo 四项
```

真 App 的 bundle 里还会有 `Assets.car`（图片）、`*.storyboardc`、本地化 `*.lproj`、
动态库 `Frameworks/`、`embedded.mobileprovision`（真机）等。示例放了个 `Assets/` 目录占位，
外加老式约定的 `PkgInfo`（8 字节 `APPL????`：类型 + 签名）。

## 3) `Bundle` 加载：系统怎么读这个 `.app`

`Bundle(url:)` 就是系统读 bundle 的方式——解析 `Info.plist`、按 `CFBundleExecutable` 定位入口：

```swift
let bundle = Bundle(url: appURL)!
bundle.bundleIdentifier            // 读 CFBundleIdentifier
bundle.executableURL               // 按 CFBundleExecutable 定位可执行文件
bundle.infoDictionary              // 解析后的整个 Info.plist
bundle.object(forInfoDictionaryKey: "NSCameraUsageDescription")   // 带本地化回退的取值
```

```
-- Bundle(url:) 加载：系统怎么读这个 .app --
  ok   bundlePath 指向 Demo.app
  ok   Bundle 读到 CFBundleIdentifier
  ok   Bundle 按 CFBundleExecutable 定位到可执行文件 Demo
  ok   该可执行文件在磁盘上真实存在
  ok   infoDictionary.CFBundleName == Demo
  ok   infoDictionary.CFBundleDisplayName == 演示 App
  ok   市场版本号 == 1.0
  ok   build 号 == 1
  ok   MinimumOSVersion == 15.0
  ok   相机用途说明已声明
  ok   object(forInfoDictionaryKey:) 取到相机用途说明
  ok   两个版本号是不同维度：short=1.0 vs build=1
```

### 两个版本号别搞混（上架高频考点）

| 键 | 名称 | 给谁看 | 规则 |
| --- | --- | --- | --- |
| `CFBundleShortVersionString` | 市场版本号 | 用户（App Store、设置里） | 语义化，如 `1.0`、`2.3.1`；同版本可复用 |
| `CFBundleVersion` | build 号 | 系统 / App Store Connect | 单调递增整数；**每次上传必须比上次大** |

同一市场版本可以多次上传（修 bug），靠 build 号区分。两者独立，别设成一样后忘了递增 build。

## 4) 签名：完整性 + 来源

iOS 要求每个可执行文件都被**签名**。签名把「谁签的（证书/团队）」和「内容哈希（防篡改）」
封进 bundle。模拟器用 **ad-hoc 签名**（无身份，`--sign -`）；真机 / 上架用 **Apple 签发的证书**
+ **provisioning profile** + **entitlements**。

```bash
codesign --sign - --force Demo.app          # ad-hoc：- 表示「无签名身份」
codesign --verify --verbose=2 Demo.app      # 验签
codesign -dv Demo.app                       # 查看签名详情
```

## 5) 装机 / 启动 / 上架流水线

```bash
# 模拟器（开发调试）
xcrun simctl install <UDID> Demo.app
xcrun simctl launch  <UDID> com.iosdev.demo       # 按 bundle id 启动
xcrun simctl launch --console-pty <UDID> com.iosdev.demo   # 启动并把 App 的 stdout 接到终端
xcrun simctl uninstall <UDID> com.iosdev.demo
```

**真机 / App Store** 走 Xcode：`Product → Archive`（Organizer 里归档）→ `Distribute App`
（导出 `.ipa` 或直接上传）→ **App Store Connect** 填元数据、截图、分级 → 提交审核。真机需要：
- **证书**（Distribution Certificate，Apple 签发）
- **Provisioning Profile**（把证书 + App ID + 设备/上架权限绑在一起）
- **Entitlements**（能力声明：推送、iCloud、Keychain 访问组等）

---

## 实测：真的 codesign + install + launch 一个 SwiftUI App

为了不让「签名/装机」停留在纸面，下面是在**本机模拟器**上真实跑通的完整记录。构造一个最小的
`@main` SwiftUI App，编译 → ad-hoc 签名 → 装机 → 启动，App 在 `init()` 里打印自己的 bundle 信息。

```swift
@main
struct DemoApp: App {
    init() {
        print("[DemoApp] init 被调用：真 App 从 @main 启动")
        print("[DemoApp] bundleIdentifier =", Bundle.main.bundleIdentifier ?? "nil")
        print("[DemoApp] version =", Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "?",
              "build =", Bundle.main.infoDictionary?["CFBundleVersion"] ?? "?")
    }
    var body: some Scene { WindowGroup { Text("Hello 真 App").padding() } }
}
```

**① 编译成 bundle 可执行文件**（注意 `@main` 需 `-parse-as-library`，且文件名不能叫 `main.swift`）：

```bash
swiftc -parse-as-library -sdk "$SDK" -target x86_64-apple-ios15.0-simulator \
    -module-name realapp DemoApp.swift -o build/realapp.app/realapp \
    -framework Foundation -framework UIKit -framework SwiftUI
cp Info.plist build/realapp.app/Info.plist
```

**② ad-hoc 签名 + 验签**（真实输出）：

```
$ codesign --sign - --force build/realapp.app
$ codesign --verify --verbose=2 build/realapp.app
build/realapp.app: valid on disk
build/realapp.app: satisfies its Designated Requirement
$ codesign -dv build/realapp.app
Executable=/private/tmp/realapp/build/realapp.app/realapp
Identifier=com.iosdev.realapp
Format=app bundle with Mach-O thin (x86_64)
CodeDirectory v=20400 size=651 flags=0x2(adhoc) hashes=14+3 location=embedded
Signature=adhoc
Info.plist entries=10
TeamIdentifier=not set
Sealed Resources version=2 rules=10 files=0
```

`flags=0x2(adhoc)`、`Signature=adhoc`、`Identifier=com.iosdev.realapp`——签名确实盖上了，
且验签通过（`valid on disk` + `satisfies its Designated Requirement`）。

**③ 装机 + 启动 + 捕获 App 自己的 stdout**（真实输出）：

```
$ xcrun simctl install <UDID> build/realapp.app          # exit 0
$ xcrun simctl launch --console-pty <UDID> com.iosdev.realapp
[DemoApp] init 被调用：真 App 从 @main 启动
[DemoApp] bundleIdentifier = com.iosdev.realapp
[DemoApp] version = 1.0 build = 1
com.iosdev.realapp: 12572
$ xcrun simctl uninstall <UDID> com.iosdev.realapp       # exit 0
```

**④ 装机后系统记录**（`simctl listapps`，真实输出节选）：

```
"com.iosdev.realapp" = {
    ApplicationType = User;
    Bundle = "file:///Users/.../data/Containers/Bundle/Application/<UUID>/realapp.app/";
    CFBundleIdentifier = "com.iosdev.realapp";
    CFBundleName = realapp;
    CFBundleVersion = 1;
};
```

三处对照，把整章串起来：

1. **`bundleIdentifier` 从 nil 变成 `com.iosdev.realapp`**——裸 spawn（§1）里是 nil，装成
   真 `.app` 后系统就填上了。这就是「打包」的本质区别。
2. **`[DemoApp] init 被调用`**——`@main` 的 `App` 真的被系统实例化、`init` 真的跑了（第 2 章
   讲的 SwiftUI 入口，在真 App 里落地）。
3. **系统把它拷进了 `Containers/Bundle/Application/<UUID>/`**——`simctl install` 不是原地引用，
   而是把 bundle 复制进该 App 的沙盒容器，`ApplicationType = User` 说明它是一个用户级 App。

> `--console-pty` 把 App 进程的 stdout 接到终端；不加它，`launch` 只回一行 `bundleid: PID`
> （如 `com.iosdev.realapp: 12572`），App 里的 `print` 会进系统日志而非终端。

## 心智模型小结

```
.app = 约定结构的目录(bundle)：可执行文件 + Info.plist + 资源
Info.plist = 身份证+说明书：CFBundleIdentifier 唯一标识，CFBundleExecutable 指入口
两个版本号：ShortVersionString 给用户，CFBundleVersion(build) 给系统，各自有递增规则
签名 = 完整性 + 来源：模拟器 ad-hoc；真机/上架用 Apple 证书 + provisioning profile + entitlements
装机/启动：simctl install/launch（模拟器）；Xcode Archive → Export → Upload（上架）
打包前 bundleIdentifier=nil，装成真 .app 后系统填上 —— 这就是「打包」的分水岭
```

## 坑清单

| 现象 | 原因 |
| --- | --- |
| `@main` 报「cannot be used in a module that contains top-level code」 | 文件名叫 `main.swift`；改名并加 `-parse-as-library` |
| `launch` 只回 `bundleid: PID`，看不到 App 的 print | 没加 `--console-pty`；App 的 stdout 进了系统日志 |
| 装到真机启动即闪退 | 签名/profile 不匹配，或缺 entitlements；检查证书与 provisioning profile |
| 上传 App Store Connect 报 build 无效 | `CFBundleVersion` 没比上次大；build 号必须单调递增 |
| 请求权限就崩 | `Info.plist` 缺对应 `NSxxxUsageDescription`（见第 19 章） |
| 上传被拒「缺启动屏」 | 没配 `UILaunchStoryboardName` / `UILaunchScreen` |

## 小结

- **`.app` 是一个目录（bundle）**：可执行文件 + `Info.plist` + 资源；本示例亲手在磁盘上搭出
  并用 `Bundle(url:)` 当真 bundle 加载、逐字段验证。
- **`Info.plist`** 是身份证 + 说明书；两个版本号（市场版本 / build）维度不同、各有规则。
- **签名**保证完整性与来源：模拟器 ad-hoc（`codesign --sign -`），真机/上架用 Apple 证书 +
  provisioning profile + entitlements。
- **装机/上架**：`simctl install`/`launch`（模拟器）；Xcode `Archive → Export → Upload`（App Store）。
- **实测跑通了完整流水线**：编译 → ad-hoc 签名（验签通过）→ 装机 → 启动，`@main` 的 `init`
  真实执行、`bundleIdentifier` 从 nil 变为 `com.iosdev.realapp`——打包前后的分水岭一目了然。

至此，iOS 应用开发指南的 20 章全部完成：从工具链、生命周期、ObjC/Swift/Foundation 基础，到
SwiftUI 主线、UIKit 补充、网络并发、持久化、权限通知，最后落到打包签名上架。每一章都有可
`./run-all.sh` 一键验证的 headless 示例，debug/release 双配置逐字节一致。
