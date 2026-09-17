# 17 · 打包：.app 的结构、Info.plist、资源与本地化

> 示例：`examples/17_packaging/`（`main.swift` + `AppWindow.xib`）
> 实测输出见 `build/17_packaging/stdout.clt.txt`

Xcode 的「Archive」帮你做了很多事，也因此把很多事藏起来了。
本章**手工造一遍 .app**，好让你知道每一步在干什么 —— 出了问题才有地方下手。

## 1) .app 就是一个目录 + 一套约定

```
MyApp.app/
  Contents/
    Info.plist            系统的说明书
    MacOS/MyApp           真正的可执行文件
    Resources/            nib、图片、strings、Assets.car
    Frameworks/           内嵌的 dylib / framework
    _CodeSignature/       签名（codesign 生成）
```

Finder 把它显示成一个「文件」，只是因为目录带 `.app` 后缀
（以及 `Info.plist` 存在）。右键「显示包内容」就能进去。

示例手工搭了一遍：

```
== 目录骨架 ==
  ok   Contents/MacOS 建好了
  ok   Contents/Resources 建好了
  ok   Contents/Frameworks 建好了
  ok   可执行文件带上了可执行权限
```

> **坑**：`CFBundleExecutable` 的值必须和 `Contents/MacOS/` 下的文件名
> **一字不差**。不一致时双击图标**毫无反应**（系统找不到可执行文件，
> 也不报错）。

## 2) Info.plist

```swift
let info: [String: Any] = [
    "CFBundleName": "MacOSDevDemo",
    "CFBundleDisplayName": "macOS 开发示例",
    "CFBundleIdentifier": "dev.macosdev.demo",
    "CFBundleExecutable": executableName,
    "CFBundlePackageType": "APPL",                  // APPL = 应用程序包
    "CFBundleShortVersionString": "1.0",            // 对外显示的版本
    "CFBundleVersion": "100",                       // 内部构建号，提交时要递增
    "CFBundleDevelopmentRegion": "en",              // 没匹配语言时的兜底
    "LSMinimumSystemVersion": "12.0",
    "LSApplicationCategoryType": "public.app-category.developer-tools",
    "NSHighResolutionCapable": true,                // 不勾 → Retina 上模糊
    "NSSupportsAutomaticTermination": true,
    "NSSupportsSuddenTermination": false,
    "LSUIElement": false,                           // true = 不在 Dock 显示
]
```

几个容易忽略的 key：

| key | 作用 |
| --- | --- |
| `NSHighResolutionCapable` | **必须 true**，否则 Retina 上整个 app 模糊 |
| `LSUIElement` | `true` = 无 Dock 图标（菜单栏常驻 app） |
| `CFBundleDevelopmentRegion` | 没有匹配语言时的兜底；**不写的话 `Bundle.localizations` 可能为空** |
| `LSMinimumSystemVersion` | 比部署目标更「对外」的一条声明 |
| `NSSupportsAutomaticTermination` | 允许系统在无人使用时静默退出（省电） |

读取：

```
== 读这个包 ==
  ok   读得到 bundle identifier
  ok   读得到 CFBundleName
  ok   布尔型 Info.plist 项也能读
  ok   系统按 CFBundleExecutable 找到可执行文件
  ok   包类型是 APPL
```

## 3) 资源

```swift
bundle.url(forResource: "AppWindow", withExtension: "nib")
bundle.path(forResource: "note", ofType: "txt")
```

实测：

```
  ok   Bundle 能定位到 nib 资源
  ok   不存在的资源返回 nil
  ok   普通文件也能当资源读
```

> **坑（很隐蔽）**：**CFBundle 会缓存包目录的内容清单，而且按路径共享。**
> 「先建 `Bundle(url:)`、再往 `Contents/Resources` 里塞文件」的话，
> 后面新加的资源**可能查不到** —— 同一个路径拿到的还是那个带旧清单的实例。
>
> 示例的做法是：**把目录彻底铺完之后才第一次碰 Bundle API**。
> 症状是「文件明明在，但 `url(forResource:)` 返回 nil」，
> 而且只在「先建 bundle 后加文件」的顺序下出现，极难复现。

## 4) 本地化目录

```
Resources/
  en.lproj/Localizable.strings
  zh-Hans.lproj/Localizable.strings
```

每种语言一个 `.lproj` 目录，里面放**同名**文件，系统按用户语言挑一个。

实测：

```
  ok   Bundle 认出了 en 这一种本地化（实际 ["en"]）
  ok   strings 文件本质上就是 plist
  localizedString("greeting") = Hello
```

`.strings` 文件本质就是一个 plist（旧式格式）：

```
"greeting" = "Hello";
"quit" = "Quit";
```

可以直接用 `PropertyListSerialization` 解析（示例就是这么做的）。

> **坑**：`Bundle.localizedString(forKey:)` 的返回值**取决于系统当前语言顺序**，
> 换台机器结果就不一样。自测里不要断言它的具体值，只断言「非空」。

## 5) 从打好的包里加载 nib

这是本章最有用的一段：证明「手工搭的 .app 和 Xcode 打出来的一样能用」。

```swift
let owner = PackagingOwner()          // 有 @IBOutlet statusLabel
var topLevel: NSArray? = nil
let ok = bundle.loadNibNamed("AppWindow", owner: owner, topLevelObjects: &topLevel)
```

实测：

```
== 从包里加载 nib ==
  loaded = true, 顶层对象数 = 2
  ok   打进 .app 之后 nib 照样能加载
  ok   outlet 也照样连上了
  ok   视图尺寸来自 XIB（实际 240.0）
  ok   XIB 里的子视图数量也对得上
```

只要 `Contents/Resources` 里有 nib，`Bundle.loadNibNamed` 就能加载，
outlet/action 一样生效。**Xcode 做的只是「把这些文件拷到对的位置」**。

## 6) 签名与公证

真实流程：

```bash
# 1) 签名（Hardened Runtime）
codesign --sign "Developer ID Application: Your Name (TEAMID)" \
         --options runtime --entitlements App.entitlements \
         --timestamp MyApp.app

# 2) 打 zip 提交公证
ditto -c -k --keepParent MyApp.app MyApp.zip
xcrun notarytool submit MyApp.zip --keychain-profile "AC_PASSWORD" --wait

# 3) 把公证结果「钉」到 app 上（离线也能验证）
xcrun stapler staple MyApp.app
```

示例不真的签（要证书、要联网、要几分钟），只列检查项：

```
== 签名 ==
  - Info.plist 的 CFBundleExecutable 与 MacOS/ 下的文件名一致
  - 所有内嵌的 framework / dylib 都签了名（--deep 或逐个签）
  - 开了 Hardened Runtime（--options runtime）
  - 有 entitlements 文件声明需要的权限（沙箱、网络、麦克风……）
```

> **坑**：`--deep` 看起来方便，但它用同一套参数签所有内嵌物，
> 往往不是你想要的（ entitlements 不该继承）。
> **逐个签**（从内到外）才是正确做法。
>
> **坑**：Hardened Runtime 下，某些能力（JIT、dyld 环境变量注入、
> 调试附加）默认被禁。需要就用 entitlement 显式开。

### 常用 entitlement

```xml
<key>com.apple.security.app-sandbox</key><true/>
<key>com.apple.security.files.user-selected.read-write</key><true/>
<key>com.apple.security.network.client</key><true/>
<key>com.apple.security.device.audio-input</key><true/>
```

## 7) 命令行工具 vs .app

| | 命令行工具 | .app |
| --- | --- | --- |
| Bundle 结构 | 无（bundlePath = 可执行文件所在目录） | 有 |
| `bundleIdentifier` | nil | 有 |
| Info.plist | 无 | 必需 |
| 能被 Finder 双击 | 不能 | 能 |
| 需要签名 | 一般不需要 | 分发必须 |

本教程的示例全是命令行工具，所以 `Bundle.main.resourcePath` 就是
构建目录 —— 编好的 nib 放那儿就能被 `loadNibNamed` 找到。

## 8) 坑清单

| 现象 | 原因 |
| --- | --- |
| 双击 app 没反应 | `CFBundleExecutable` 与 `MacOS/` 下的文件名不一致 |
| `url(forResource:)` 返回 nil（文件明明在） | 先建了 Bundle 再加文件（CFBundle 缓存了目录清单） |
| `Bundle.localizations` 是空数组 | 没有 `CFBundleDevelopmentRegion`，或 `.lproj` 目录没建对 |
| Retina 上模糊 | `NSHighResolutionCapable` 没设 true |
| 想做菜单栏 app 却有 Dock 图标 | `LSUIElement` 没设 true |
| 公证失败 | 内嵌的 dylib 没签名 / 没开 Hardened Runtime / 缺 timestamp |
| 用户打开时提示「已损坏」 | 没公证（Gatekeeper 拦截） |

## 小结

- `.app` = 目录 + `Contents/{Info.plist,MacOS,Resources,Frameworks}`。
- `CFBundleExecutable` 必须与可执行文件名一致。
- **先铺完目录再拿 Bundle 对象**（CFBundle 缓存目录清单）。
- 资源/本地化目录都在 `Resources/`；`.lproj` 一个语言一个。
- 分发要 codesign（Hardened Runtime）→ notarytool → stapler。
