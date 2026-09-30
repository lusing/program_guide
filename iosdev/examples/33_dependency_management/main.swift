// ============================================================
// 33 - 依赖管理：一行 `import` 后面站着的四件事
//
// 《跟着项目学iOS应用开发：基于Swift 4》第 10 章（利用 Cocoapods、GPS、APIS、REST
// 制作天气应用）是全书第一次把「别人写的代码」放进工程。原书这一章的节次是
// 10.1 设置项目 / 10.2 注册免费的 API Key / 10.3 为什么需要 CocoaPods（10.3.1 装它、
// 10.3.2 用它装库）/ 10.4~10.7 定位与字典 / 10.8 使用 Alamofire / 10.9 解析 JSON /
// 10.10 创建气象数据模型 / 10.11 Segues。本章只接**依赖管理那一段**（10.1~10.4、10.8），
// 定位与 JSON 那几节归第 25 章与第 32 章。原书那条流水线是：
//   10.1 从 GitHub 下载 Weather 的初始代码：「在初始项目中已经包含了设计好的用户界面并
//        添加了相关约束，还有就是项目会用到的所有图片素材」，故事板里已经有两个控制器；
//   10.2 去 www.openweathermap.org 注册一个免费 Key，替换进
//        `let APP_ID = "1d505359c7db3fcf2502ffd40525ddc8"`（书里直接印了一个它自己的 Key）；
//   10.3 为什么需要 CocoaPods —— 它数了两类痛：「一个个手动去下载所需的类库十分麻烦」，
//        而且「可能某个类库又用到其他类库……『子子孙孙无穷尽也』」；第二类是「如果在项目中
//        用到的类库有版本更新，我们就必须重新下载新版本的代码，然后再将其重新加入到项目之中」；
//   10.3.1 `sudo gem install cocoapods`，再 `pod setup --verbose`；
//   10.3.2 在 Weather 文件夹里 `pod init` 得到一份 Podfile，往 `target 'Weather' do` 块里
//        写三行 `pod 'SwiftyJSON'` / `pod 'Alamofire'` / `pod 'SVProgressHUD'`（块里还留着
//        一句 `use_frameworks!`），然后 `pod install`；「如果将来某个开源库类发布了新版本，
//        就可以直接使用 pod update 进行升级，非常方便」；
//   10.4 「通过 CocoaPods 安装好开源库类以后，必须通过双击 Weather.xcworkspace（白色图标的）
//        文件才能正常打开项目，因为该文件中包含了 CocoaPods 的相关信息」，
//        项目导航里从此是「Weather 和 Pods 两个蓝色项目图标」，
//        而 Weather 文件夹里的源码「被组织成 Model、View 和 Controller 形式」（这句归第 32 章）；
//   10.8 在文件顶部一口气写四行 `import UIKit` / `import CoreLocation` / `import Alamofire` /
//        `import SwiftyJSON`，然后
//        `Alamofire.request(url, method: .get, parameters: parameters).responseJSON { … }`。
//
// 本机跑不动其中三条：CocoaPods 要 ruby gem 和网络，`pod 'Alamofire'` 要从 CDN 拉源码，
// 而 `pod install` 的产物是一个 .xcworkspace（本仓库从头到尾没有 Xcode 工程，
// 见 run-all.sh：每条示例都是一次 swiftc/clang 调用 + `xcrun simctl spawn`）。
// 所以本章换成同一个角色在本机的对应物 —— **Swift Package Manager**，
// 一个 Xcode 16.2 自带、离线也能用的依赖管理器：
//   Podfile            → Packages/WeatherKit/Package.swift（它本身是一段 Swift 程序，见探针 s02）
//   pod 'X'            → `.package(path:)` / `.package(url:from:)`（s07 / s08）
//   pod install        → `swift build --triple … --sdk …`（run-all.sh 的 build_packages）
//   Pods/ 那棵树       → --scratch-path 下面那棵树（s12）
//   .xcworkspace       → 「swiftc 多吃的四类输入」（本章 §1，也是全部落点）
//   use_frameworks!    → `.library(type: .dynamic)`（s10 量的正是 automatic/静态/动态三种落盘差别）
//   版本约束与锁       → tag + Package.resolved —— **原书这一章一步都没走**：那三行 pod
//                        一个字都没写版本号，而 SwiftPM 的两层（范围 vs 钉住）只有本地 git
//                        fixture 才量得动（s07：path 依赖连 Package.resolved 都不写）
//   import Alamofire   → import WeatherKit（主线 §2~§21）
// 离线这一条不是妥协，反而把原书 10.3 那一步拆得更开：**没有网络时，`import` 到底依赖
// 什么**，只有本地依赖能回答 —— 它依赖四个具体的输入，而不是一句「装好了」。
//
// 顺手把原书 10.8 那条「提示」也换成了可复现的东西。那一段逐字是：
//   「此时 Xcode 编译器可能会报错——No such module 'Alamofire'，尽管我们已经通过 CocoaPods
//    方式在项目安装了 Alamofire，但是 Xcode 还是没有发现它。不用担心，这只不过是 Xcode 的
//    Bug，可以先使用快捷键 Shift+Command+K 清理（Clean）一下项目，再使用 Command+B 重新
//    构建（Build）一下项目，报错就会消失。」
// 它不是 Bug，而是**这一章的全部内容**：那句 import 找的是磁盘上一份 .swiftmodule 的路径，
// 而那个路径此刻不在编译器的搜索路径里。本章把它量成三半 ——
// 名字没撞车时它确实会红（探针 e01 的 `no such module 'ClimateCore'`）；
// 撞了 SDK 的框架名时它**不红**，只是换一串错（§2 与探针 e07/e08）；
// 而一个「不碰任何只有包才有的名字」的文件，在无 -I 时能**六条判定全过**（探针 r01）。
//
// 本章最锋利的一条发现写在 §2：模拟器 SDK 里**正好有一个
// System/Library/Frameworks/WeatherKit.framework**（苹果自己的天气框架，iOS 16 起）。
// 本章那个包也叫 WeatherKit。少给 `-I` 时 swiftc 不报「找不到模块」，它安安静静绑到
// 苹果那个上面，错误变成一串「cannot find 'report' in scope」（探针 e07 原文），
// 而 `canImport(WeatherKit)` 在两种情况下都是真的。也就是说：**依赖没接上的失败
// 不一定是红的**，名字撞了 SDK 的时候，它靠「换个错」骗过你。这一章因此把
// 「接上了没有」做成主线里一条可断言的事实（出厂身份常量），而不是靠编译器没报错。
//
// 判据还是本仓库那六条（run-all.sh 头部与 README：编译日志为空、退出码 0、stderr 为空、
// stdout 非空、无多余控制字符、结尾 `==== 33 结束 ====`，外加 debug(-Onone) 与
// release(-O) 两份 stdout 逐字节一致）。所以原书里那些「编译器红一条」和「命令行上
// SwiftPM 自己说过的话」都不在本文件里，改由 probes/ 现跑并抄原文
// （编号约定见 probes/run.sh 头部：sNN SwiftPM 命令行现场、eNN 编译期诊断、
//  rNN 运行期现场、cNN 配置对照）：
//   少给 -I / 少给 modulemap / 少给一个 .o → e01 / e02 / e09 / e07+e08（同一份源码，报错换了人）；
//   **不给 -I 也能六条判定全过** → r01（这一支是本章 §3 那条警告的极限版）；
//   internal 写不出来、@testable 不是权限关键字、传递 import 不传染 → e03 / e04 / e05；
//   .copy 与 .process 的路径基准 → s03；Bundle.module 是生成出来的、而且是 internal
//     → s04 / s13 / c02；
//   product / target / module / identity / bundle 前缀 各自是谁 → s05（product 名 ≠ target 名，
//     而且撞 product 名不报错、撞 target 名才报错）、
//     s03（bundle 前缀 = Package 的 name，不是目录名）、s06 / s07（identity = 目录名小写）；
//   tag 与锁 → s07 / s08；
//   依赖两层的硬度不对称 → s09（内层不写：编译、链接、运行全过；外层不写：manifest 当场失败）；
//   默认目标是主机而不是模拟器 → s01（这条最阴：编出来的东西照样能在模拟器里跑绿）；
//   静态库 / 自动 / 动态三种 product 落盘差别 → s10；测试 target 在命令行上怎么跑 → s11；
//   中间目录里到底躺着哪些东西（modulemap / .o / 四份模块接口文件）→ s12；
//   包的两个优化配置给的浮点是否逐位相同 → c01（主线 §11 打全精度就是为了让这条被判定管住）。
// ============================================================

import CLIBrain
import ClimateCore
import Foundation
import WeatherKit

setvbuf(stdout, nil, _IONBF, 0)

var failures = 0
func expect(_ condition: Bool, _ parts: String...) {
    print("  \(condition ? "ok  " : "FAIL") \(parts.joined(separator: ""))")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
func section(_ n: Int, _ title: String) { print("\n== §\(n) \(title) ==") }

// ============================================================
// §1 管线自检：四类输入齐了没有
// ============================================================
section(1, "管线自检：一次 import 要吃到的四类输入")
// 这一节不做任何「知识点」，只做一件事：证明本章的示例真的把包接上了。
// 判据来自 run-all.sh 里那条 swiftc 命令额外多吃的四类东西 —— 这就是
// 「Xcode 里 pod install 之后一切自动出现」那句话在命令行上的展开形态：
//   1) -I <中间目录>/Modules           —— 每个 Swift target 的 .swiftmodule（二进制接口）
//   2) -Xcc -fmodule-map-file=…        —— C target 那份生成出来的 module.modulemap（e02）
//   3) <中间目录>/*.build/*.o          —— 三个 target 的目标码，缺它就成链接期未定义符号（e09）
//   4) 资源 bundle 目录                —— Bundle.module 的候选路径之一（s13）
// 少任何一类都编译得过或编译不过得明明白白，但**不会**变成「库没装好」那种一句话错误。
let layout = bundleLayout()
expect(layout.bundleName == "WeatherKit_WeatherKit.bundle", "bundle=\(layout.bundleName)")
expect(layout.entries == ["city.json", "token.txt"], "entries=\(layout.entries.joined(separator: ","))")
expect(brainVersion() == "CLIBrain/c-1", "brain=\(brainVersion())")
expect(report(for: Reading(city: "北京", celsius: 20)) == "北京：20.0°C / 68.0°F / 露点 12.0°C",
       "report=\(report(for: Reading(city: "北京", celsius: 20)))")

// ============================================================
// §2 import WeatherKit 绑到的到底是哪一个模块
// ============================================================
section(2, "撞名：SDK 里也有一个 WeatherKit.framework")
// 本机 SDK（iPhoneSimulator18.2）里躺着这些文件：
//   System/Library/Frameworks/WeatherKit.framework/WeatherKit.tbd
//   System/Library/Frameworks/WeatherKit.framework/Modules/WeatherKit.swiftmodule/
//       x86_64-apple-ios-simulator.swiftinterface   （1223 行，47 个顶层 public 声明）
//       x86_64-apple-ios-simulator.swiftdoc
//       arm64-apple-ios-simulator.{swiftinterface,swiftdoc}
// 也就是说 `import WeatherKit` 这个词**不需要任何依赖管理就已经能编译** ——
// 而且它是 source-based 的接口（.swiftinterface 而不是编译好的 .swiftmodule 二进制），
// 所以连「接口版本对不对」都不用编译器操心，SDK 里那份永远读得进去。
// 探针 e07 与 e08 是同一份源码的两次编译，只差 .args 里那一行 -I：
//   e07（无 -I，绑苹果的）：error: 'WeatherService' is only available in iOS 16.0 or newer
//                            error: cannot find 'report' in scope
//                            error: cannot find 'Reading' in scope
//   e08（有 -I，绑本章的）：error: cannot find 'WeatherService' in scope
// 两边都红，但红的是**不同的名字** —— 编译器把「我绑了谁」写在报错清单里。
// （苹果那 47 个声明里没有 report / Reading，SDK 接口里 grep 得到 0 个匹配；
//   `final public class WeatherService` 在 x86_64 那份的第 909 行，@available(iOS 16.0, …)。）
// 主线这条断言就是那一格的可复现版：`weatherKitID` 只存在于本章那个包里，
// 它能取到值，就等于 -I 真的生效了、绑的是包而不是框架。
expect(weatherKitID == "WeatherKit/1.0", "weatherKitID=\(weatherKitID)（SDK 的 WeatherKit 没有这个名字）")
expect(climateCoreID == "ClimateCore/1.0", "climateCoreID=\(climateCoreID)")

// ============================================================
// §3 canImport 分辨不了撞名
// ============================================================
section(3, "`canImport(…)` 问的是「有没有」，不是「有没有我要的那个」")
// 常见的自卫写法是 `#if canImport(WeatherKit)`。它在 e07 那个场景里同样是**真**：
// SDK 里确实有一个能 import 的 WeatherKit。所以这条指令只适合「这个模块存不存在」，
// 不适合「我的依赖接上了没有」—— 后者要靠 §2 那种身份常量，或者靠一个只有包才有的符号。
// 探针 r01 把这条推到尽头：一个只写 `import WeatherKit` 加一个 canImport 分支的文件，
// 在**不给 -I** 的情况下编译日志为空、退出码 0、放进模拟器照常打印 ——
// 六条判定全过，而这个「通过」里没有本章那个包。
#if canImport(WeatherKit)
let canImportWeatherKit = true
#else
let canImportWeatherKit = false
#endif
#if canImport(CLIBrain)
let canImportCLIBrain = true
#else
let canImportCLIBrain = false
#endif
expect(canImportWeatherKit, "canImport(WeatherKit)=true（注意：无 -I 时它也是 true，见 §2）")
expect(canImportCLIBrain, "canImport(CLIBrain)=true（C target 也过：它是本章独有的名字）")

// ============================================================
// §4 product 名、target 名、module 名是三个词
// ============================================================
section(4, "Package.swift 里的三行声明，import 用的是第三行")
// WeatherKit/Package.swift 里写着：
//   products:  .library(name: "WeatherKit", targets: ["WeatherKit"])   ← product 名
//   targets:   .target(name: "WeatherKit", …)                          ← target 名
//   （module 名没人写：它由 target 名推导，纯 Swift target 就是 target 名本身）
// 本章这几个名字恰好全都相同，所以 §4 讲不出规则，规则在探针里（四格各拆一刀）：
//   s05 把 product 名与 target 名拆开：App 那个包写着 .library(name: "Shared", targets: ["App"])，
//       product 叫 Shared、target 叫 App，于是「product 名」和「import 的那个词」彻底两回事。
//       同一支探针还顺手量了两种撞名的下场：**撞 product 名**（app 的 Shared 指向自己的
//       target App，core 的 Shared 指向 core 的 Shared）SwiftPM 一声不响，构建绿、
//       describe 里那两个 product 各指各的 target，跑起来 import Shared 拿到的是 core 那份；
//       **撞 target（=module）名**才真的红：error: multiple similar targets 'Shared'
//       appear in package 'app-targets' and 'core' … consider using the `moduleAliases`
//       parameter in manifest to provide unique names。名字这件事上，product 那层是软的。
//   s03 第三格把**资源 bundle 的命名规则**现形：包叫 TwoShapes、target 叫 Lib，
//       bundle 就叫 TwoShapes_Lib.bundle —— 它是两个名字拼出来的，跟 product 名无关；
//   s06 证明 `.product(package:)` 里要写的是**依赖的 identity**，不是 Package 的 name:；
//   s07 证明 path 依赖的 identity 就是目录名小写，与 Package.swift 里的 name: 无关
//       （那一格里目录叫 Climate-Kernel、Package 的 name 叫 TotallyDifferentName，
//         只有 product 与 module 还是一个词 —— 它俩都跟着 target 名）。
// 主线能断言的一格是：`import` 那个词跟的是 module 名，而 module 名与 product 名
// 可以完全不同（同名的时候你永远不会发现这件事）。
let productNames = ["WeatherKit", "CLIBrain"]          // Package.swift 的 products: 里那两行
let targetNames = ["WeatherKit", "CLIBrain"]           // targets: 里的三个名字去掉 testTarget
let importedNames = ["WeatherKit", "ClimateCore", "CLIBrain"]   // 本文件顶部真写过的 import
expect(productNames.count == 2 && targetNames.count == 2,
       "products=\(productNames.count) targets=\(targetNames.count) imported=\(importedNames.count)")
expect(Set(productNames).isSubset(of: Set(importedNames)),
       "product 名都在 import 清单里（同名时看不出区别）")

// ============================================================
// §5 依赖有两层，缺一层是两种不同的错
// ============================================================
section(5, "包↔包是一层，target↔target 是另一层")
// Package.swift 里那两处 dependencies: 经常被当成一件事：
//   外层 `.package(path: "../ClimateCore")` —— 让 SwiftPM **找得到**那个包；
//   内层 .target(dependencies: ["ClimateCore"]) —— 声明这个 target **应该**能看到谁。
// 这两层的硬度不一样，而且和直觉相反（探针 s09 六格全在现场跑）：
//   只写外层、忘写内层 —— **什么都没有发生**：`swift build` 退出码 0、链接也过、
//     放进模拟器照常打印。因为一趟构建里所有 target 的 .swiftmodule 落在**同一个**
//     Modules 目录（s09 第一格在数它），而链接吃的是整个依赖闭包的 .o。
//   只写内层、忘写外层 —— 硬失败，而且失败在编译开始之前（s09 第三格原文）：
//     error: 'client': product 'ClimateCore' required by package 'client' target 'Client' not found. Did you mean 'ClimateCore'?
// 所以「内层不写就 import 不到」这句话在命令行上是不成立的；真正成立的是 §8 那条
// —— 它是**语言**层的规则，跟构建系统无关。主线这一格从**结果**侧看同一条链：
// report(for:) 一次调用同时踩了两种依赖 —— 华氏度走 ClimateCore（Swift），
// 露点走 CLIBrain（C）。两层的产物在 §1 那四类输入里是两类东西：
// ClimateCore 给的是 .swiftmodule + .o，CLIBrain 给的只有 .o + 一份 module.modulemap。
expect(fahrenheit(20) == 68.0, "华氏度这一半来自 ClimateCore：fahrenheit(20)=\(fahrenheit(20))")
expect(cliDewPoint(20, 60) > 11.9 && cliDewPoint(20, 60) < 12.1,
       "露点这一半来自 CLIBrain（C）：cliDewPoint(20,60)=\(String(format: "%.4f", cliDewPoint(20, 60)))")

// ============================================================
// §6 public 才是 API：包外的可见边界
// ============================================================
section(6, "一个包对外只有 public 的那些名字")
// 原书 10.8 的说法是「要想使用好 Alamofire，最好先阅读一下它的说明文档」，
// 而文档只写 public API —— 这一格把「API 表面」变成可读的一屏：主线 import 了三个模块，
// 能用到的名字就是那三个包源码里带 `public` 的那几个。默认访问级别是 internal ——
// 它在单个模块里几乎感觉不到（同一 target 的每个文件互相可见），
// 一跨模块就咬人：探针 e03 把三个 internal 名字逐条写出来，swiftc 逐条回「找不到」。
let c = TemperatureUnit.celsius
let f = TemperatureUnit.fahrenheit
expect(c.convert(0) == 0.0 && f.convert(0) == 32.0,
       "celsius.convert(0)=\(c.convert(0)) fahrenheit.convert(0)=\(f.convert(0))")
expect(f.convert(100) == 212.0, "fahrenheit.convert(100)=\(f.convert(100))")
expect(averageCelsius([10, 20, 30]) == 20.0, "averageCelsius([10,20,30])=\(averageCelsius([10, 20, 30]))")

// ============================================================
// §7 internal 在包内跨文件可见：tagLine 的两半
// ============================================================
section(7, "同一个 target 的两个文件之间，internal 是通行证")
// WeatherKit 有两个源码文件：Forecast.swift 与 Resources.swift。
// `internalTag()` 是 internal，却在**另一个文件**里被 public 的 tagLine() 用了，
// 并且顺路把依赖包 ClimateCore 的出厂身份拼在尾巴上。
// 这一行断言同时量三件事：internal 在包内跨文件可见、包内可以调用依赖包的名字、
// 而 public 函数可以把 internal 的结果**传出去**（传的是字符串，不是那个 internal 符号 ——
// 这是 Swift 的规则：internal 类型不能出现在 public 签名里，值本身无所谓）。
expect(tagLine() == "internal-tag@ClimateCore/1.0", "tagLine()=\(tagLine())")
expect(!tagLine().contains("hiddenOffset"), "internal 的函数名没有泄漏成符号，只是一段文本")

// ============================================================
// §8 传递依赖不传染：import 不顺着依赖树走
// ============================================================
section(8, "`import WeatherKit` 不会顺手把 ClimateCore 也带进来")
// 依赖树是 WeatherKit → ClimateCore。探针 e05 只写 `import WeatherKit` 就直接用
// `climateCoreID`，报的是 cannot find in scope —— 符号链得上（.o 全给了），
// 名字落地是另一件事：每个模块的名字要各自 import。
// 这正是原书 10.8 那四行 import 的来处：它在同一个文件顶部写了
// `import UIKit` / `import CoreLocation` / `import Alamofire` / `import SwiftyJSON`，
// 而 10.3.2 的 Podfile 里装着三个库（SwiftyJSON、Alamofire、SVProgressHUD）——
// 少写一行 import 就少一个模块的名字，多装一个库也不自动送你一个名字。
// 库的依赖**也是**依赖，它不会因为你在用一个包就自动进你的作用域。
// 注意这条与 §5 不是一回事、也不互相担保：§5 讲的是**构建系统**认不认你写的那行
// dependencies（本机：不认，见 s09），这一条讲的是**语言**认不认你的 import（永远认）。
// 主线本文件顶部把三个 import 全写了，所以这一格从正面断言：两个包的 API 都能直接调。
expect(climateCoreID == "ClimateCore/1.0" && weatherKitID == "WeatherKit/1.0",
       "两个模块的名字各自 import 才各自可用")
expect(TemperatureUnit.allCases.count == 2,
       "allCases 来自 ClimateCore 的 CaseIterable：\(TemperatureUnit.allCases.map { $0.rawValue })")

// ============================================================
// §9 公开签名里带着别人的类型：能用，不能命名
// ============================================================
section(9, "返回值能用，但类型名要自己 import 才写得出来")
// WeatherKit 里那一行是 `public func preferredUnit() -> TemperatureUnit`，
// 而 TemperatureUnit 属于 ClimateCore。探针 e06 只 import WeatherKit：
//   第一半过了 —— 拿到返回值、调用 `unit.convert(20)`；
//   第二半红了 —— `let explicit: TemperatureUnit = .celsius` 写不出那个类型名。
// 「能用不能命名」是这一格的准确形状：模块决定了名字的可获得性，不决定的值可获得性。
// 主线 import 了 ClimateCore，所以两半都写得出来，正好把对照的另一边摆在这里。
let unit = preferredUnit()
expect(unit.convert(20) == 68.0, "不 import ClimateCore 也能这样用：unit.convert(20)=\(unit.convert(20))")
let explicit: TemperatureUnit = .fahrenheit
expect(explicit == unit, "写出类型名要自己 import 那个包（e06 红在这一行）")
expect(String(describing: unit) == "fahrenheit", "describing=\(String(describing: unit)) rawValue=\(unit.rawValue)")

// ============================================================
// §10 C target 在 Swift 侧叫什么名字
// ============================================================
section(10, "一个 C 头文件 → 一个模块：函数名一个都不改")
// CLIBrain 对外只有 include/CLIBrain.h 一张头文件，里面两行原型。
// SwiftPM 给每个 C target 生成一份 module.modulemap（探针 s12 在构建目录里点数），
// 于是 `import CLIBrain` 之后 C 的名字**原样**进 Swift：
//   const char *cliBrainVersion(void)  →  func cliBrainVersion() -> UnsafePointer<Int8>!
//   double cliDewPoint(double, double) →  func cliDewPoint(_:_:) -> Double
// 参数标签变成下划线、指针变成可选的 UnsafePointer、其余保持 C 的拼写。
// 包里那个 `brainVersion()` 就是为此存在的：它把 C 字符串转成 Swift String
// （`String(cString:)`），这层包装在 Swift/OC 混编那一章（§第 32 章的桥接）是同一件事。
// 唯一要改的是返回类型：C 的 `const char *` 在 Swift 里是 `UnsafePointer<Int8>!` ——
// 一个**可选**的指针，所以 String(cString:) 之前没人替它做判空（那是 C 侧的习惯，不是 Swift 的）。
expect(brainVersion() == String(cString: cliBrainVersion()),
       "包给的包装=\(brainVersion()) 与直接调 C=\(String(cString: cliBrainVersion())) 同值")
expect(String(format: "%.1f", cliDewPoint(37.7, 100)) == "37.7",
       "饱和时露点=气温这条物理不变量，C 侧算得出来：cliDewPoint(37.7,100)=\(String(format: "%.4f", cliDewPoint(37.7, 100)))")

// ============================================================
// §11 露点全表：同一个 .o 在两个优化配置下必须给同一个数
// ============================================================
section(11, "包也在换配置：clang 的 -O 有没有动浮点")
// run-all.sh 的第六条判定管的是**主线**两个配置的 stdout 逐字节一致；包是
// `swift build -c debug / -c release` 各编一遍的，判定同样落到包上，只是没人替它说话。
// 所以这一格把露点打到 `%.17g`（Double 的可复原精度）而不是 `%.1f`：
// 排版成 12.0 以后，clang 的 -O 若动了浮点（快数学那类重结合）你根本看不见，
// 而 17 位有效数字打出来之后，**第六条判定就顺带把包的两个配置也比了一遍** ——
// 这是本文件为什么要在这里打印全精度而不是打印结论。
// 第一条断言是给「为什么要打全精度」作证的：§1 那行印的是 12.0，
// 实测全精度是 11.999894615745436 —— 排版掉的这 1e-4 恰好是浮点求和的误差量级，
// 也就是说「看起来是整数」在这条公式里从来不代表「算出来是整数」。
// 后面三条是 Magnus 公式自己的不变量，与优化无关，因此两个配置下都必须成立：
//   同一气温下湿度越高露点越高；露点不可能高于气温；（饱和时露点 = 气温在 §10 那条）。
let dew = cliDewPoint(20, 60)
line("  20°C/60%  \(String(format: "%.17g", dew))   bits=\(String(format: "%016llx", dew.bitPattern))")
for (t, rh) in [(-3.5, 88.0), (37.7, 15.0), (100.0, 0.5)] {
    let d = cliDewPoint(t, rh)
    line("  \(String(format: "%6.2f", t))°C/\(String(format: "%5.2f", rh))%  "
         + "\(String(format: "%.17g", d))   bits=\(String(format: "%016llx", d.bitPattern))")
}
expect(String(format: "%.1f", dew) == "12.0" && dew != 12,
       "12.0 是排版出来的，不是算出来的：全精度=\(String(format: "%.17g", dew))")
expect(cliDewPoint(20, 80) > cliDewPoint(20, 60),
       "同温下 80% 的露点更高：\(String(format: "%.4f", cliDewPoint(20, 80))) > \(String(format: "%.4f", cliDewPoint(20, 60)))")
expect(cliDewPoint(20, 60) <= 20, "露点不可能高于气温：\(String(format: "%.4f", cliDewPoint(20, 60))) ≤ 20")

// ============================================================
// §12 错误类型也跨模块
// ============================================================
section(12, "库定义的 Error：抛在包里，判在主线上")
// Forecast.swift 里有一个 `public enum ForecastError: Error, Equatable`。
// 它对主线的意义有两条：一是错误也是 API 表面的一部分（`catch let e as ForecastError` 这种
// 写法要求你 import 那个模块才能匹配 case）；二是它声明了 Equatable，于是主线可以
// 直接比 case，不必一个个 `if case`。
let asError: Error = ForecastError.unknownCity("月球")
expect((asError as? ForecastError) == .unknownCity("月球"),
       "as? ForecastError 之后还能 == （Equatable 是包里声明的）")
var caught: String?
do {
    throw ForecastError.unknownCity("月球")
} catch ForecastError.unknownCity(let city) {
    caught = "unknownCity:\(city)"
} catch {
    caught = "other"
}
expect(caught == "unknownCity:月球", "catch 里的模式匹配同样要求那个模块在作用域里")

// ============================================================
// §13 协议一致性是模块的属性
// ============================================================
section(13, "`Reading` 能 == ：一致性写在包里，不是写在用的人身上")
// `public struct Reading: Equatable` —— 这一行在包源码里。主线拿到的只是一份
// .swiftmodule 描述的二进制接口，一致性跟着接口走：
// 主线不需要（也没办法）替包里的类型补 conformance。
let r1 = Reading(city: "北京", celsius: 20)
let r2 = Reading(city: "北京", celsius: 20)
let r3 = Reading(city: "上海", celsius: 20)
expect(r1 == r2 && r1 != r3, "r1==r2=\(r1 == r2) r1!=r3=\(r1 != r3)")
expect(r1.city == "北京" && r1.celsius == 20, "字段是 let：city=\(r1.city) celsius=\(r1.celsius)")

// ============================================================
// §14 库返回 String 还是 Double，决定了你能改什么
// ============================================================
section(14, "两种 API 形状：排好版的字符串 vs 没排版的数据")
// `report(for:)` 里已经做完了 `String(format: "%.1f", …)`，所以**精度丢失发生在包里**：
// 主线拿到的是一屏文本，想改成两位小数只能对字符串动手（切、拼），改不回数值语义。
// 旁边那行 `fahrenheit(_:) -> Double` 才是可组合的形状。
// 这一格在书 10.10 有一段现成的对照。书里从 SwiftyJSON 拿温度是这一行：
//   let tempResult = json["main"]["temp"].double
//   weatherDataModel.temperature = Int(tempResult! - 273.15)
// 同一个 JSON 值，库给了 `.double` / `.stringValue` / `.intValue` 好几种取法（各自返回
// 不同类型），而 Model 层的属性是 `var temperature: Int = 0` —— **从这一行起小数就没了**。
// 书里那句「openweathermap 提供的是绝对温度值，所以要减去 273.15」正是本章
// ClimateCore 里 `convert(_:)` 干的事（那边 K→°C，这边 °C→°F），只是本章把它留在 Double 上。
// 选一个库，就是在选它的返回值类型；等它变成界面上一屏文本，你连「它是几度」都问不回来。
let text = report(for: r1)
expect(text.hasPrefix("北京：20.0°C"), "文本前缀=\(text.prefix(9))（两位小数已经印不回来了）")
expect(String(format: "%.2f", fahrenheit(20)) == "68.00",
       "要几位小数取决于拿没拿到 Double：\(String(format: "%.2f", fahrenheit(20)))")

// ============================================================
// §15 边界情况归库管：averageCelsius 的空数组
// ============================================================
section(15, "`guard !values.isEmpty else { return 0 }`：库里那句防御，主线只能读源码才知道")
// ClimateCore 里那个函数如果不写这行 guard，空数组会给出 NaN（0/0）。
// 书 10.10 撞过同一类事，而且撞得更狠：它先写 `Int(tempResult! - 273.15)`，
// 然后原话是「openweathermap 返回的是无效 API key……这也就意味着 tempResult 的值为 nil，
// 在我们对 tempResult 强制拆包的时候，应用程序发生崩溃」，改法换成 `if let` 才了事。
// 那一次崩的不是调用方的逻辑，是**库选的失败形状**：书里明写「因为 json["main"]["temp"]
// 是 JSON 类型，所以需要使用 .double 将其转换为双精度，但是此时的 tempResult 是可选」——
// 「取不到」长什么样是 SwiftyJSON 决定的，于是拆包这件事、以及崩这件事，全落在调用方身上。
// 本章这行 guard 是同一件事的温和版：**第三方库的边界行为不在你的类型系统里**，它在库的实现里。
// 你唯一的办法是把包源码留在仓库里读（本章的 Packages/ 目录就是这个用途 —— path 依赖的最大好处）。
expect(averageCelsius([]) == 0, "averageCelsius([])=\(averageCelsius([]))（不是 NaN：guard 是 0）")
expect(!averageCelsius([1, 2, 4]).isNaN, "averageCelsius([1,2,4])=\(String(format: "%.4f", averageCelsius([1, 2, 4])))")

// ============================================================
// §16 资源清单：.copy 与 .process 摆出来的形状不一样
// ============================================================
section(16, "Package.swift 那两行 resources，运行时看一眼目录")
// Package.swift 里写的是：
//   .copy("Resources/city.json")      —— 单文件直接搬：进 bundle 根，名字不变
//   .process("Resources/nested")      —— 目录「按处理规则摊平」：递归把**里面每个文件**
//                                        提到 bundle 根，路径前缀全丢，同名就报重复
//                                        （探针 s03 第四格的原文：
//                                         error: 'dup': multiple resources named 's.txt' in target 'Lib'
//                                         —— 退出码 1，中间目录里 0 个 .o。注意那个 'dup' 是**身份**，
//                                         这一格里它等于目录名，而同一支探针落下来的 bundle 叫
//                                         DupNames_Lib.bundle（前缀是 name:），一条消息里两个名字）
// 于是包里的两个文件 Resources/city.json 与 Resources/nested/token.txt 在 bundle 里
// 是兄弟，不是父子（entries 精确等于 ["city.json","token.txt"]，§1 已经断过）。
// 这一格换个方向再断一次，顺便把「路径基准是 target 目录」那条规则（s03 的原文）
// 摆在这里：那两行写的是 Resources/…，基准是 Sources/WeatherKit/ 而不是包根目录；
// 写错时 SwiftPM 只警告、退出码 0，然后给你一份**少了那个文件**的 bundle。
expect(layout.entries.contains("city.json"), "city.json 在 bundle 根（.copy）")
expect(layout.entries.contains("token.txt") && !layout.entries.contains("nested/token.txt"),
       "token.txt 被 .process 摊平：路径里的 nested/ 不见了")

// ============================================================
// §17 bundle 的命名规则
// ============================================================
section(17, "`<Package 名>_<target 名>.bundle`：两个名字相同的时候看不出规则")
// 实测：本章这个包给的 bundle 叫 WeatherKit_WeatherKit.bundle ——
// 因为 Package 的 name 与 target 名**恰好都叫 WeatherKit**。
// 规则本身要靠拆开的名字才现形，而且拆它的是探针 s03 的第三格（不是 s05）：
// 那个 fixture 的**目录**叫 shapes、Package(name:) 写 TwoShapes、target 叫 Lib，
// 落下来的 bundle 是 TwoShapes_Lib.bundle —— 前缀取的是 manifest 里的 name:，
// 既不是目录名（那是 identity 的来源，见 s07），也不是 product 名（那格根本没写 products:）。
// 这条为什么值得记：Xcode 里那步「把资源 bundle 拷进 .app」是自动的，
// 命令行上你得自己知道要拷**哪一个目录**、以及拷到可执行文件旁边来（s13）。
expect(layout.bundleName.hasSuffix(".bundle"), "后缀=\(layout.bundleName.suffix(7))")
expect(!layout.bundleName.contains("/"), "只有目录名本身：父路径带着 debug/release，不进输出")

// ============================================================
// §18 Bundle.module 与 Bundle.main 是两个地方
// ============================================================
section(18, "包的资源不在主 bundle 里")
// 主线这个可执行文件是裸二进制（没有 .app 外壳），Bundle.main 就是它所在的目录。
// `city.json` 在那里吗？不在 —— 它在 WeatherKit_WeatherKit.bundle 这一层里。
// 这条就是原书 10.4 那句「必须通过双击 Weather.xcworkspace（白色图标的）文件才能正常打开项目，
// 因为该文件中包含了 CocoaPods 的相关信息」在命令行侧的真实代价：
// 依赖的资源永远**不**在你的主 bundle 里，它跟着依赖走，靠一个子 bundle 交付。
// run-all.sh 把那个子 bundle 拷到可执行文件旁边，正是为了让 s13 量到的
// 「两个候选路径」里的第一个能命中（第二个候选是构建目录里的绝对路径，
// 换台机器就没了 —— 那条假绿只有命令行构建会撞上，Xcode 里不会）。
//
// 还有一格只有命令行会撞到，而且它是**编译期**的：`Bundle.module` 用不了。
// 它是 SwiftPM 生成在 WeatherKit 那个 target 里的一个 `static let`，
// 没写访问级别 ⇒ internal ⇒ 模块外不可见（探针 c02 抄了原文，两个配置给的
// note 还不是同一个形状：debug 指向那个生成出来的源文件，release 指向
// .swiftmodule 里的接口）。所以「主线上读一下包的资源」这句话本身就是错的 ——
// 读资源必须走包自己 public 出来的那几个函数，§19 就是这条的正面。
expect(Bundle.main.url(forResource: "city", withExtension: "json") == nil,
       "Bundle.main 的根里没有 city.json（资源不跟着可执行文件走）")
expect(layout.cityJSON != "missing",
       "包内的 Bundle.module 找到了它：主线只能隔着 public API 看见（c02）")

// ============================================================
// §19 资源的内容通过包的 API 读回来
// ============================================================
section(19, "主线 import 的是 WeatherKit，读到的是包里的 JSON")
// cityOffset() 在 Resources.swift 里，读的是 Bundle.module 那份 city.json 的 "offset" 字段。
// 它证明的是「资源跟着 target 走，不跟着 product 走」：主线没有 import 任何
// 「资源产品」，资源的访问接口就是那个 Swift target 的普通函数。
// 读不到时的默认值是 -1（包里那句 `return -1`），所以这一格顺带演示了
// 「第三方库的失败模式是它选的」—— §15 那条的另一个面。
// 打印的形状也留意一下：包给的**不是**那段 JSON 原文，而是切过一遍的 token 串 ——
// JSON 原文里有换行，而本仓库的判定 5 不允许 stdout 出现多余控制字符，
// 所以库侧就地把排版做掉了（§14 那条「返回值类型由库决定」的资源版）。
expect(layout.cityJSON == "city|:|Beijing|,|offset|:|8", "JSON 内容=\(layout.cityJSON)")
expect(cityOffset() == 8, "cityOffset()=\(cityOffset())（-1 才是读失败的信号）")

// ============================================================
// §20 身份、锁与「没有版本号」
// ============================================================
section(20, "本章的依赖没有版本范围：path 依赖连 Package.resolved 都不写")
// 原书 10.3.2 那三行 pod **一个字都没写版本号**（`pod 'SwiftyJSON'` / `pod 'Alamofire'` /
// `pod 'SVProgressHUD'`），它关于版本只有一句「如果将来某个开源库类发布了新版本，
// 就可以直接使用 pod update 进行升级」—— 那句话把「声明的范围」和「解析后钉住的版本」
// 说成了同一件事，而这两层在 SwiftPM 里是分开的、可以分别量的。
// 本章主线用的是 `.package(path:)`，这两层天生都不存在（探针 s07 实测：这一趟之后
// `没有这个文件：client/Package.resolved`，而 workspace-state.json 里那一格是
// `"kind" : "fileSystem"` 加一条 `path`，没有 revision、没有 version）。
// 有版本范围的是探针 s08 那个本地 git fixture：tag 1.0.0/1.2.0，
// 加 tag 不动锁、`swift package update` 才动锁、--disable-automatic-resolution 反过来要求锁必须在。
// 主线这一格只能断言「出厂身份是源码里那行常量」：它跟着源码走，不跟着 tag 走 ——
// 这也正是 path 依赖的语义：**钉在目录上，而不是钉在版本上**。
expect(weatherKitID.hasSuffix("/1.0") && climateCoreID.hasSuffix("/1.0"),
       "两个包的身份都是硬编码常量：\(weatherKitID) / \(climateCoreID)")
expect(Reading(city: "x", celsius: 1).celsius == 1, "没有任何版本号参与运行期：只有 .o 里的这些符号")

// ============================================================
// §21 三个模块、一份 .o 清单：依赖是「链进来」的
// ============================================================
section(21, "一次调用走过的模块数")
// 这一节把 §5 那句话数出来：report(for:) 一次调用要跑过三个 target 的代码 ——
// WeatherKit（排版）、ClimateCore（换算）、CLIBrain（露点，C）。
// 三个 target 的 .o 都在链接输入里，缺任何一个都到不了运行这一步（s12 在数构建目录，
// e09 现场扣掉 CLIBrain 那一份 brain.c.o：类型检查一路放行，红在链接，报的是符号名）。
let one = report(for: Reading(city: "广州", celsius: 30))
expect(one == "广州：30.0°C / 86.0°F / 露点 21.4°C", "三个 target 合起来的一条字符串：\(one)")
expect(one.split(separator: "/").count == 3, "三段分别来自：Swift 排版 + ClimateCore 换算 + CLIBrain 计算")

// ============================================================
// §22 依赖管理真正省掉的那件事
// ============================================================
section(22, "没有依赖管理器时，这几行是自己写的")
// 原书 10.3 数过没有管理器时的两类痛：「一个个手动去下载所需的类库十分麻烦」，
// 以及「可能某个类库又用到其他类库，所以为了使用它，必须还得额外下载其他类库，
// 而其他类库又可能会用到其他类库——『子子孙孙无穷尽也』」。本章的形态更直白：如果没有 SwiftPM，
// §1 那四类输入要人肉维护 —— 而 run-all.sh 里那几十行（build_packages + spm_extra_args）
// 就是「没有管理器」时的样子：先跑一次 swift build 问它要产物，再把产物路径拼成参数。
// 换句话说，依赖管理器的**全部**工作就是替你把这四类输入管对；
// 它不做的事：不改你的访问级别（§6）、不传染 import（§8）、不替你选返回值类型（§14）。
// 这一格能落在运行时的只有第 4 类：那个 bundle 是**磁盘上的一个真目录**，
// 就在可执行文件旁边 —— 而它在主 bundle 的根里点不出来（§18），
// 只能按探针 s13 那份生成出来的 accessor 的方式自己拼一次：Bundle.main.bundleURL + 目录名。
let stagedURL = Bundle.main.bundleURL.appendingPathComponent(layout.bundleName)
let stagedFiles = (try? FileManager.default.contentsOfDirectory(
    at: stagedURL, includingPropertiesForKeys: nil)) ?? []
expect(stagedFiles.count == 2, "拷过来的 bundle 里有 \(stagedFiles.count) 个文件（.copy 一个 + .process 摊平一个）")
let stagedCity = stagedURL.appendingPathComponent("city.json")
expect(FileManager.default.fileExists(atPath: stagedCity.path),
       "命中的是 s13 那两个候选里的第一个（可执行文件旁边），不是构建目录里的绝对路径")

// ============================================================
// §23 收尾：把「装好了」压成一条断言
// ============================================================
section(23, "本章唯一一条「依赖接上了」的判据")
// 编译器不报错不等于接上了你要的那个依赖（§2）。这条主线用一句话收：
// 让库里独有的符号参与输出，它出得来才算接上。
expect(weatherKitID == "WeatherKit/1.0" && brainVersion() == "CLIBrain/c-1"
       && climateCoreID == "ClimateCore/1.0" && cityOffset() == 8,
       "三个模块 + 一份包内资源，四个出处各自签名")

line("")
line("failures=\(failures)")
print("==== 33 结束 ====")
exit(failures == 0 ? 0 : 1)
