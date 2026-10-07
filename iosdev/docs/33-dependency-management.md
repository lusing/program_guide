# 33 · 依赖管理：一行 `import` 后面站着的四类输入、三个名字、两层声明

> 示例：`examples/33_dependency_management/main.swift`（同级 `Needs-SwiftPM`、`Packages/ClimateCore/`、`Packages/WeatherKit/` 两个真的包，以及 `probes/` 26 支探针 + `run.sh`）
> 实测输出见 `build/33_dependency_management/stdout.debug.txt`

《跟着项目学iOS应用开发：基于Swift 4》的第 10 章是全书**第一次把别人写的代码放进工程**：
「利用Cocoapods、GPS、APIS、REST制作天气应用」。它的节次是 10.1 设置项目 / 10.2 注册免费的
API Key / 10.3 为什么需要 CocoaPods（10.3.1 装它、10.3.2 用它装库）/ 10.4~10.7 定位与字典与
API / 10.8 使用 Alamofire / 10.9 解析 JSON / 10.10 创建气象数据模型 / 10.11 Segues。
**本章只接依赖管理那一段**（10.1~10.4、10.8），定位那几节归第 25 章、字典与 Model 归第 32 章、
Segue 归第 31 章。原书这一段的流水线是：

- **10.1** 从 GitHub 下载 Weather 的初始代码：「在初始项目中已经包含了设计好的用户界面并添加了
  相关约束，还有就是项目会用到的所有图片素材」——也就是说这一章的活儿**不含界面**，它专门
  讲怎么把三个库装进来；
- **10.2** 去 www.openweathermap.org 注册一个免费 Key，替换进
  `let APP_ID = "1d505359c7db3fcf2502ffd40525ddc8"`（书里直接印了一份它自己的 Key），并且加了
  一条提示：「强烈建议读者使用自己注册后的API Key来构建当前的项目，因为当应用程序在每分钟有
  超过60次APP_ID访问的时候就会收取费用」；
- **10.3** 为什么需要 CocoaPods。它数了两类痛：「可能某个类库又用到其他类库，所以为了使用它，
  必须还得额外下载其他类库，而其他类库又可能会用到其他类库——『子子孙孙无穷尽也』」和
  「总而言之，一个个手动去下载所需的类库十分麻烦」；第二类是「如果在项目中用到的类库有版本更新，
  我们就必须重新下载新版本的代码，然后再将其重新加入到项目之中」；
- **10.3.1** `sudo gem install cocoapods`，再 `pod setup --verbose`，「当设置完成以后，会在最后
  显示Setup completed信息……现在就可以使用它，而且以后再也不用执行这个操作了」；
- **10.3.2** 在 Weather 文件夹里 `pod init` 得到一份 Podfile，往 `target 'Weather' do` 块里写
  三行 `pod 'SwiftyJSON'` / `pod 'Alamofire'` / `pod 'SVProgressHUD'`（块里还留着
  `use_frameworks!`），然后 `pod install`；「如果将来某个开源库类发布了新版本，就可以直接使用
  pod update 进行升级，非常方便」；
- **10.4** 「通过 CocoaPods 安装好开源库类以后，必须通过双击 Weather.xcworkspace（白色图标的）
  文件才能正常打开项目，因为该文件中包含了 CocoaPods 的相关信息」，从此项目导航里是
  「Weather 和 Pods 两个蓝色项目图标」；
- **10.8** 文件顶部一口气四行 `import UIKit` / `import CoreLocation` / `import Alamofire` /
  `import SwiftyJSON`，然后
  `Alamofire.request(url, method: .get, parameters: parameters).responseJSON { response in … }`。

原书的判据仍是这一类：**「构建并运行应用程序」**、以及 10.8 那条著名的提示 ——「此时 Xcode
编译器可能会报错——No such module 'Alamofire'……不用担心，这只不过是 Xcode 的 Bug，可以先使用
快捷键 Shift+Command+K 清理（Clean）一下项目，再使用 Command+B 重新构建（Build）一下项目，
报错就会消失。」

本教程的产物是一个**裸可执行文件**：`swiftc` 编一次，`xcrun simctl spawn` 在 iPhone 模拟器里
跑一遍，六条判定卡住（见 `run-all.sh` 头部与 `README.md`：编译日志为空、退出码 0、stderr 为空、
stdout 非空、无多余控制字符、结尾标记 `==== 33 结束 ====`，外加 debug(-Onone) 与 release(-O)
两份 stdout 逐字节一致）。而这一章恰好是全书**第一次**遇到「主线的编译命令本身要变」的一章：
`swiftc` 得多吃四类输入，`run-all.sh` 因此要先跑一遍 `swift build`。

## 这一章的换法（每条都有实测支撑，逐节展开）

本机跑不动原书那三条：CocoaPods 要 ruby gem 和网络，`pod 'Alamofire'` 要从 CDN 拉源码，
而 `pod install` 的产物是一个 `.xcworkspace`（本仓库从头到尾没有 Xcode 工程）。所以本章换成
同一个角色在本机的对应物 —— **Swift Package Manager**，Xcode 16.2 自带、离线也能用：

| 书 10.3.2 / 10.4 里的东西 | 本机对应物 | 量它的探针 |
| --- | --- | --- |
| `Podfile` | `Packages/WeatherKit/Package.swift`（它本身是一段 Swift 程序） | s02 |
| `pod 'Alamofire'` | `.package(path:)` / `.package(url:from:)` | s07 / s08 |
| `pod install` | `swift build --triple … --sdk …`（`run-all.sh` 的 `build_packages`） | s01 / s02 |
| `Pods/` 那棵树 | `--scratch-path` 下面那棵树 | s12 / s08 |
| `Weather.xcworkspace`（白色图标） | 「swiftc 多吃的四类输入」—— 本章 §1，全部落点 | e01 / e02 / e09 |
| `use_frameworks!` | `.library(type: .dynamic)` | s10 |
| 版本约束与锁 | tag + `Package.resolved`（**原书一步都没走**） | s07 / s08 |
| `import Alamofire` | `import WeatherKit`（主线 §2~§21） | r01 / c01 |

离线这一条不是妥协，它反而把原书 10.3 那一节拆得更开：**没有网络时，`import` 到底依赖什么**，
只有本地依赖能回答 —— 它依赖四个具体的输入，而不是「装好了」这三字。

下面是八条与书不同（或与本章初稿不同）的地方，全部有现跑原文兜底：

1. **10.8 那条「Xcode 的 Bug」不是 Bug，而是本章的全部内容。** 那句 `import` 找的是磁盘上一份
   `.swiftmodule` 的路径，而那个路径此刻不在搜索路径里。本章把它量成三半：名字没撞车时它确实
   会红（e01 的 `no such module 'ClimateCore'`）；撞了 SDK 的框架名时它**不红**，只换一串错
   （§2、e07/e08）；而一个「不碰任何只有包才有的名字」的文件，在无 `-I` 时能**六条判定全过**
   （r01）。Clean/Build 那两下改的正是第二类输入（构建目录），所以它「有时真的能治好」——
   这恰恰说明它是搜索路径问题而不是编译器缺陷（§1、§3）；
2. **本章最锋利的一条：依赖没接上的失败不一定是红的。** 本机模拟器 SDK 里**正好有一个**
   `System/Library/Frameworks/WeatherKit.framework`（苹果自己的天气框架，iOS 16 起，
   1223 行 `.swiftinterface`、47 个顶层 public 声明、`final public class WeatherService`
   在第 909 行）。本章那个包也叫 WeatherKit，于是 `import WeatherKit` **不需要任何依赖管理
   就能编译**。所以「编译器没报错」在这一章不作判据，主线改用一个只有包里才有的常量
   `weatherKitID`（§2、§23）；
3. **`#if canImport(WeatherKit)` 分辨不了撞名。** 它在「绑错了 SDK 那个框架」的场景里同样是真
   —— 它问的是「有没有」，不是「有没有我要的那个」（§3，极限版是探针 r01）；
4. **「不写 target 依赖就 import 不到」——这一条本章初稿写错了，实测反过来。** 依赖有两层，
   而两层的硬度与直觉相反：只写外层（`.package(path:)`）、忘写内层（target 的
   `dependencies:`）**什么都没有发生**，编译、链接、运行全过，因为一趟构建里所有 target 的
   `.swiftmodule` 落在同一个 `Modules/` 目录，而链接吃的是整个依赖闭包的 `.o`；反过来只写内层、
   忘写外层是硬失败，且失败在编译开始之前（s09 六格原文，§5）。真正一直成立的是**语言**那条
   —— 传递 import 不传染（§8，e05）；
5. **「有版本更新就 `pod update` 一下」把两层说成了一件事。** 声明里的**范围**与解析后**钉住的
   版本**是两层，可以分别量：加了新 tag 锁不动、`swift package update` 才动锁、
   `--disable-automatic-resolution` 反过来要求锁必须在场（s08）。而本章主线用的 path 依赖
   两层都不存在 —— 连 `Package.resolved` 都不写，`workspace-state.json` 里那一格是
   `"kind" : "fileSystem"` 加一条 `path`，没有 revision 也没有 version（s07、§20）；
6. **`import` 用的那个词是 module 名，而 product 名与它可以完全不同 —— 撞名时 SwiftPM 还不一定
   说话。** s05 量了两种撞名：**撞 product 名**（app 的 `Shared` 指向自己的 target `App`，
   core 的 `Shared` 指向 core 的 `Shared`）退出码 0、`Build complete!`，**一句警告都没有**，
   跑起来 `import Shared` 拿到的是 core 那份实现；**撞 target（=module）名**才真的红，而且报错
   直接给出解法：`consider using the \`moduleAliases\` parameter in manifest to provide unique
   names`（§4）。同一支探针顺手拆了 bundle 的命名：前缀取 manifest 里的 `name:`，既不是目录名
   也不是 product 名（s03 第三格、§17）；
7. **10.1 那句「项目会用到的所有图片素材」在本机是一个真的目录。** `.copy` 与 `.process` 摆出来
   的形状不同（摊平不保留路径）、路径基准是 **target 目录**而不是包根目录 —— 而写错基准时
   SwiftPM 只给一条 warning、退出码 0，然后给你一份**少了那个文件**的 bundle（s03、§16）。
   `Bundle.module` 更不是 SDK 的 API，它是 SwiftPM 看见 `resources:` 之后**塞进 target 的一个
   生成源文件**（s04），而且它是 internal（c02），所以「主线直接读包的资源」这句话本身就写不
   出来；它找 bundle 只有两个候选，第二个是编译期写死的构建目录绝对路径 —— 换台机器之前它一路
   绿灯（s13 那条假绿，§18、§22）；
8. **包的测试目录不参与主线，而 `@testable` 只成立于一半。** `swift build` 默认连 test target
   都不编（s11）；`@testable import` 在 debug 那套包产物上真的能编过（e04 退出码 0），换到
   release 那套才拒绝：`error: module 'WeatherKit' was not compiled for testing`（c03）。
   「`@testable` 是个权限关键字」的印象来自这里，其实它要求的是**被链接的那份模块带 instrumentation**。

## 本章的账本结构

```
管线   §1  一次 import 要吃到的四类输入（bundle / modulemap / .o / -I）
撞名   §2  import WeatherKit 绑到的到底是哪一个模块（SDK 里也有一个）
撞名   §3  canImport(…) 问的是「有没有」，不是「有没有我要的那个」
名字   §4  product 名、target 名、module 名是三个词
名字   §5  包↔包是一层，target↔target 是另一层（两层的硬度与直觉相反）
可见性 §6  一个包对外只有 public 的那些名字
可见性 §7  同一个 target 的两个文件之间，internal 是通行证
可见性 §8  import WeatherKit 不会顺手把 ClimateCore 也带进来
可见性 §9  返回值能用，但类型名要自己 import 才写得出来
C 层   §10 一个 C 头文件 → 一个模块：函数名一个都不改
配置   §11 包也在换配置：clang 的 -O 有没有动浮点
类型   §12 库定义的 Error：抛在包里，判在主线上
类型   §13 Reading 能 ==：一致性写在包里，不是写在用的人身上
API    §14 两种 API 形状：排好版的字符串 vs 没排版的数据
API    §15 库里那句 guard / 书 10.10 那次强拆包崩溃
资源   §16 .copy 与 .process 摆出来的形状不一样
资源   §17 <Package 名>_<target 名>.bundle 这条命名规则
资源   §18 包的资源不在主 bundle 里（Bundle.module 还是 internal）
资源   §19 主线 import 的是 WeatherKit，读到的是包里的 JSON
版本   §20 path 依赖连 Package.resolved 都不写
记账   §21 一次调用走过的模块数
记账   §22 没有依赖管理器时，这几行是自己写的
收口   §23 本章唯一一条「依赖接上了」的判据
```

## 复现

```bash
cd iosdev
./run-all.sh 33                                   # 主线：先 swift build 两个包，再两配置编译 + 模拟器跑 + 六条判定
bash examples/33_dependency_management/probes/run.sh          # 全部 26 支探针
bash examples/33_dependency_management/probes/run.sh s05 c03  # 只跑编号前缀匹配的
```

主线这一趟在 `build/33_dependency_management/` 里多出一批别处没有的产物：
`spm/<配置>/<包名>/…`（两个包各自的构建目录）、`spm.<配置>.log` 与
`spm.<配置>.diags`（`swift build` 的整屏输出与从中挑出的 warning/error），
以及可执行文件旁边那个 `WeatherKit_WeatherKit.bundle`。示例目录里那个
`Needs-SwiftPM` 文件的**每一行**是一个包目录（相对示例目录），脚本就按那几行去
`env -u SDKROOT swift build --package-path … --scratch-path … --triple $DEPLOY_TARGET --sdk $SDK -c $cfg`。

`probes/run.sh` 的四族分工写在它自己头部注释里，本文末尾「探针记录」逐支抄了原文：
（正文各节里引用的那些格子是**删节过的**：诊断路径统一缩成 `/var/folders/…/main.swift`、
swiftc 那段带行号的代码上下文常常整块省掉，只留 error/note 那几行。以「探针记录」那一份为准；
`Build complete! (…)` 里的耗时本来每次都不同，不作为对照对象。）

- `sNN_*` SwiftPM 命令行现场 —— 每支是一个 `.sh`，自己在临时目录里造包、造本地 git 仓库，
  跑原生 `swift build` / `swift package` / `swift test`，抄命令原文与退出码。本章一半的事实
  只有这里拿得到，因为它们发生在主线编译**之前**；
- `eNN_*` 编译期诊断 —— 主线那套 `swiftc` 命令，故意少给一类输入（`-I` / modulemap / `.o` /
  可见性），抄 swiftc 原文，不运行；
- `rNN_*` 运行期现场 —— 编好放进模拟器跑，抄 stdout / stderr / 退出码；
- `cNN_*` 配置对照 —— 同一份源码分别链 debug 与 release 两套包产物，抄两份输出的差异。

四处脚本层面的细节，都是本章实测踩出来的（它们本身就是三条事实）：

1. **`env -u SDKROOT`。** `run-all.sh` 为了别的原因 export 了 `SDKROOT`（模拟器 SDK），而
   manifest 是一段**主机**程序：带着它跑 `swift build`，得到的是
   `error: 'weatherkit': Invalid manifest` 加两句
   `warning: using sysroot for 'iPhoneSimulator' but targeting 'MacOSX'` /
   `error: unable to load standard library for target 'x86_64-apple-macosx13.0'`（s02 原文）。
   去掉它才绿；
2. **`--triple` 与 `--sdk` 两个都要给。** 只给 `--triple`、不给 `--sdk`，报的是
   `unable to load standard library for target 'x86_64-apple-ios12.0-simulator'`（s02 第三格）；
   两个都不给，SwiftPM 默认目标就是主机，产物落在 `x86_64-apple-macosx/` 那一层 ——
   而**它照样能在模拟器里跑绿**（s01，那条最阴）；
3. **scratch-path 必须显式给。** 探针一律 `--scratch-path "$TMP/…"`，因为包留在
   `examples/…/Packages/` 里被原地构建会写出几百 MB 的 `.build/`；
4. **`swift build` 的 stdout 不吃判定。** s09 那一格为了让 `--experimental-explicit-module-build`
   的原文可读，只挑 `error` / `Build complete` / 计时三类行 —— 它另外打的那一屏
   「Compiling Swift module XPC / CoreFoundation / …」是它在重编 SDK 模块，不是诊断。

---

## §1 管线自检：一次 `import` 要吃到的四类输入

书 10.3.2 的 `pod install` 跑完之后，Xcode 里发生的事是**自动**的：Pods 工程进了 workspace，
每个库编成一份 framework 或静态库，搜索路径、链接输入、资源拷贝全由 Xcode 接线。10.4 那句
「必须通过双击 Weather.xcworkspace（白色图标的）文件才能正常打开项目，因为该文件中包含了
CocoaPods 的相关信息」说的就是这套接线的入口。

本章把这套接线摊成四类具体的输入 —— 这就是主线能跑起来的全部前提，`run-all.sh` 里那几十行
（`build_packages` + `spm_extra_args`）逐条对应：

1. `-I <中间目录>/Modules` —— 每个 Swift target 的 `.swiftmodule`（二进制接口）；
2. `-Xcc -fmodule-map-file=…` —— C target 那份**生成出来的** `module.modulemap`（少它就是 e02）；
3. `<中间目录>/*.build/*.o` —— 三个 target 的目标码，缺它就成链接期未定义符号（e09）；
4. 资源 bundle 目录 —— `Bundle.module` 的候选路径之一（s13）。

少任何一类都逃不掉，但**不会**变成「库没装好」那种一句话错误。§1 这一节不做任何知识点，
它只做一件事：证明本章的示例真的把包接上了 —— 四类输入各出一格读数。

```
== §1 管线自检：一次 import 要吃到的四类输入 ==
  ok   bundle=WeatherKit_WeatherKit.bundle
  ok   entries=city.json,token.txt
  ok   brain=CLIBrain/c-1
  ok   report=北京：20.0°C / 68.0°F / 露点 12.0°C
```

第一格是第 4 类（bundle 的名字，规则在 §17）、第二格是它的内容（§16）、第三格是第 2 类
（一个 C target 给的名字）、第四格是第 1+3 类合起来才有的东西：`report(for:)` 这个函数
本身在包里，而它一次调用要走三个 target（§21）。

## §2 `import WeatherKit` 绑到的到底是哪一个模块

本机 SDK（iPhoneSimulator18.2）里躺着这些文件：

```
System/Library/Frameworks/WeatherKit.framework/WeatherKit.tbd
System/Library/Frameworks/WeatherKit.framework/Modules/WeatherKit.swiftmodule/
    x86_64-apple-ios-simulator.swiftinterface   （1223 行，47 个顶层 public 声明）
    x86_64-apple-ios-simulator.swiftdoc
    arm64-apple-ios-simulator.{swiftinterface,swiftdoc}
```

也就是说 `import WeatherKit` 这个词**不需要任何依赖管理就已经能编译**。而且它是 source-based
接口（`.swiftinterface` 而不是编译好的二进制 `.swiftmodule`），所以连「接口版本对不对」都不
用编译器操心 —— SDK 里那份永远读得进去。

e07 与 e08 是**同一份源码**的两次编译，只差 `.args` 里那一行 `-I`：

```
===== e07_sdk_name_collision (debug) —— 无 -I，绑苹果的那个
/var/folders/…/iosdev33probes/main.swift:16:5: error: 'WeatherService' is only available in iOS 16.0 or newer
/var/folders/…/iosdev33probes/main.swift:17:7: error: cannot find 'report' in scope
/var/folders/…/iosdev33probes/main.swift:17:19: error: cannot find 'Reading' in scope
swiftc 退出码 = 1

===== e08_package_module_wins (debug) —— 有 -I，绑本章的那个
/var/folders/…/iosdev33probes/main.swift:9:5: error: cannot find 'WeatherService' in scope
swiftc 退出码 = 1
```

两边都红，但红的是**不同的名字**：苹果那 47 个声明里没有 `report` / `Reading`，而
`WeatherService` 是它的（`final public class WeatherService` 在 x86_64 那份的第 909 行，
`@available(iOS 16.0, …)`，主线部署目标是 iOS 15.0 所以还要挨一条 availability 错误）。
本章那个包只有 `report` / `Reading`，没有 `WeatherService`。**编译器把「我绑了谁」写在报错
清单里** —— 这就是为什么撞名的时候不要只看有没有红，要看红在哪。

主线这条断言就是那一格的可复现版：

```
== §2 撞名：SDK 里也有一个 WeatherKit.framework ==
  ok   weatherKitID=WeatherKit/1.0（SDK 的 WeatherKit 没有这个名字）
  ok   climateCoreID=ClimateCore/1.0
```

`weatherKitID` 只存在于本章那个包里（`Packages/WeatherKit/Sources/WeatherKit/Forecast.swift`
第 8 行），它能取到值，就等于 `-I` 真的生效了、绑的是包而不是框架。这一格是全章判据的地基，
所以它在 §23 又出现了一次。

## §3 `canImport(…)` 问的是「有没有」，不是「有没有我要的那个」

常见的自卫写法是 `#if canImport(WeatherKit)`。它在 e07 那个场景里同样是**真** —— SDK 里确实
有一个能 import 的 WeatherKit。所以这条指令只适合问「这个模块存不存在」（比如同一个包在
iOS 16 与 15 上给不给同一个类型），不适合问「我的依赖接上了没有」；后者要靠 §2 那种身份
常量，或者靠一个只有包才有的符号。

探针 r01 把这条推到尽头：一个只写 `import WeatherKit` 加一个 canImport 分支的文件，在
**不给 `-I`** 的情况下编译日志为空、退出码 0、放进模拟器照常打印 —— 六条判定全过：

```
===== r01_imports_wrong_module_and_runs_green (debug)
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
canImport(WeatherKit) 为真 —— 但这不能说明接上了包
--- stderr ---（空）
```

换句话说：**如果本章的判据是「run-all.sh 过了没有」，这章会一直绿着骗过所有人。**
主线这一节因此只能从两个名字上各自问一遍，并明写那句括号：

```
== §3 `canImport(…)` 问的是「有没有」，不是「有没有我要的那个」 ==
  ok   canImport(WeatherKit)=true（注意：无 -I 时它也是 true，见 §2）
  ok   canImport(CLIBrain)=true（C target 也过：它是本章独有的名字）
```

`canImport(CLIBrain)` 那一格是它的反面：`CLIBrain` 这个名字 SDK 里没有，所以它问得出答案。
也就是说 canImport 好不好用，完全取决于你import 的名字撞没撞车 —— 而**你事先不知道**。

## §4 Package.swift 里的三行声明，import 用的是第三行

`Packages/WeatherKit/Package.swift` 里写着：

```swift
products: [
    .library(name: "WeatherKit", targets: ["WeatherKit"]),   // ← product 名
    .library(name: "CLIBrain", targets: ["CLIBrain"])
],
targets: [
    .target(name: "WeatherKit", dependencies: […])            // ← target 名
]
```

module 名没人写：它由 target 名推导（纯 Swift target 就是 target 名本身）。本章这几个名字
恰好全都相同，所以这一节讲不出规则 —— 规则在四格拆开的探针里：

- **s05** 把 product 名与 target 名拆开：app 那个包写着 `.library(name: "Shared", targets: ["App"])`，
  product 叫 `Shared`、target 叫 `App`，于是「product 名」和「import 的那个词」彻底两回事。
  它同时量了两种撞名的下场，而这两场**完全不对称**（原文见探针记录）：撞 product 名一声不响，
  撞 target（=module）名硬失败；
- **s03** 第三格把资源 bundle 的命名规则现形：包叫 `TwoShapes`、target 叫 `Lib`，bundle 就叫
  `TwoShapes_Lib.bundle`（§17 展开）；
- **s06** 证明 `.product(package:)` 里要写的是依赖的 **identity**，不是 `Package(name:)`；
- **s07** 证明 path 依赖的 identity 就是**目录名小写**，与 `Package.swift` 里的 `name:` 无关
  （那一格里目录叫 `Climate-Kernel`、`Package(name:)` 叫 `TotallyDifferentName`）。

四格跑完，本章这几个词的归属就清楚了：

| 名字 | 由什么决定 | 撞了会怎样 | 探针 |
| --- | --- | --- | --- |
| product 名 | `products:` 里那行的 `name:` | **不报错**，一句警告都没有 | s05 读数 1~4 |
| target 名 | `targets:` 里那行的 `name:` | 硬失败，提示 `moduleAliases` | s05 读数 5 |
| module 名 | 由 target 名推导 | 同上（它就是 target 名） | s05 读数 5 |
| package identity | **目录名**（小写） | `unknown package 'X'; valid packages are: 'Y'` | s06 / s07 |
| 资源 bundle 前缀 | manifest 里的 `Package(name:)` | 只是名字变了，构建照过 | s03 第三格 |

只有 product 与 module 还是一个词 —— 它俩都跟着 target 名。主线能断言的一格因此是「同名时
看不出区别」这句反话：

```
== §4 Package.swift 里的三行声明，import 用的是第三行 ==
  ok   products=2 targets=2 imported=3
  ok   product 名都在 import 清单里（同名时看不出区别）
```

## §5 包↔包是一层，target↔target 是另一层

书 10.3 那句「可能某个类库又用到其他类库，所以为了使用它，必须还得额外下载其他类库，
而其他类库又可能会用到其他类库——『子子孙孙无穷尽也』」讲的就是这一节：依赖是有树的，
而声明这棵树的地方有两处。`Package.swift` 里那两处 `dependencies:` 经常被当成一件事：

```swift
dependencies: [ .package(path: "../ClimateCore") ]        // ← 外层：让 SwiftPM 找得到那个包
…
.target(name: "WeatherKit", dependencies: ["ClimateCore"]) // ← 内层：这个 target 能看到谁
```

**这两层的硬度不一样，而且和直觉相反**（s09 六格全在现场跑，原文见探针记录）：

- 只写外层、忘写内层 —— **什么都没有发生**：`swift build` 退出码 0、链接也过、放进模拟器照常
  打印。原因很具体：一趟构建里所有 target 的 `.swiftmodule` 落在**同一个** `Modules/` 目录
  （s09 第一格在数它，那三行文件名就是它给的），而 `-I` 给的是这个目录本身，不是「你的 target
  声明过的那些模块」；链接吃的更是整个依赖闭包的 `.o`；
- 只写内层、忘写外层 —— 硬失败，而且失败在编译开始之前：
  `error: 'client': product 'ClimateCore' required by package 'client' target 'Client' not found. Did you mean 'ClimateCore'?`

那句 `Did you mean 'ClimateCore'?` 是 s09 第三格里最有意思的一屏：它建议的那个写法与 manifest
里已经写着的**一模一样**。SwiftPM 在这里说的是「这个 product 在依赖图里找不到」，而不是
「你拼错了」—— 提示是拼写建议，原因是图校验。

所以「内层不写就 import 不到」这句话在命令行上**不成立**；真正一直成立的是 §8 那条，
它是**语言**层的规则，跟构建系统无关。主线这一格从结果侧看同一条链：

```
== §5 包↔包是一层，target↔target 是另一层 ==
  ok   华氏度这一半来自 ClimateCore：fahrenheit(20)=68.0
  ok   露点这一半来自 CLIBrain（C）：cliDewPoint(20,60)=11.9999
```

一次 `report(for:)` 同时踩了两种依赖 —— 华氏度走 ClimateCore（Swift 包），露点走 CLIBrain（C
target）。两层的产物在 §1 那四类输入里是两类东西：ClimateCore 给的是 `.swiftmodule` + `.o`，
CLIBrain 给的只有 `.o` + 一份 `module.modulemap`。

## §6 一个包对外只有 public 的那些名字

书 10.8 关于怎么用一个库的说法是「要想使用好Alamofire，最好先阅读一下它的说明文档」，
而文档只写 public API。这一格把「API 表面」变成可读的一屏：主线 import 了三个模块，能用到的
名字就是那三个包源码里带 `public` 的那几个。

默认访问级别是 internal —— 它在单个模块里几乎感觉不到（同一 target 的每个文件互相可见，
§7），一跨模块就咬人。e03 把三个 internal 名字逐条写出来，swiftc 逐条回「找不到」：

```
===== e03_internal_not_visible (debug)
main.swift:14:7: error: cannot find 'hiddenOffset' in scope
main.swift:15:7: error: cannot find 'InternalReading' in scope
main.swift:16:7: error: cannot find 'internalTag' in scope
swiftc 退出码 = 1
```

注意这三条的措辞：不是「internal 不可访问」，而是「**找不到这个名字**」（`cannot find`，
不是 `is inaccessible` —— 后者是 c02 那一格才有的措辞，区别见 §7）。模块决定的是名字的
可获得性，编译器不会替你列出那个模块里有哪些名字 —— 这正是「读文档 / 读包源码」这件事在
SwiftPM 时代没有消失的原因（本章把两个包整个留在仓库里，就是这条的实操答案）。

```
== §6 一个包对外只有 public 的那些名字 ==
  ok   celsius.convert(0)=0.0 fahrenheit.convert(0)=32.0
  ok   fahrenheit.convert(100)=212.0
  ok   averageCelsius([10,20,30])=20.0
```

## §7 同一个 target 的两个文件之间，internal 是通行证

`Packages/WeatherKit/Sources/WeatherKit/` 里有两个源文件：`Forecast.swift` 与
`Resources.swift`。`internalTag()` 是 internal，却在**另一个文件**里被 public 的 `tagLine()`
用了，并且顺路把依赖包 ClimateCore 的出厂身份拼在尾巴上：

```swift
internal func internalTag() -> String { "internal-tag" }
public func tagLine() -> String { "\(internalTag())@\(climateCoreID)" }
```

这一行断言同时量三件事：internal 在包内跨文件可见、包内可以调用依赖包的名字、而 public 函数
可以把 internal 的结果**传出去**（传的是字符串，不是那个 internal 符号 —— internal 类型不能
出现在 public 签名里，值本身无所谓）：

```
== §7 同一个 target 的两个文件之间，internal 是通行证 ==
  ok   tagLine()=internal-tag@ClimateCore/1.0
  ok   internal 的函数名没有泄漏成符号，只是一段文本
```

第二格值得单独说一句：`tagLine()` 的返回值里带着 `internal-tag` 这串文本，但它**不是**一个
符号。s12 数过整个构建目录里的 `.o`，其中没有任何一个叫 `internalTag`；而 e03 那条
`cannot find 'internalTag' in scope` 才是符号层面的事实。internal 挡的是名字，不挡值 ——
把 internal 的结果拼进字符串返回出去，是包作者自愿的（`c02` 那格是同一件事的另一面：
`Bundle.module` 是 internal，可它算出来的 `bundlePath` 能 public 地递出来）。

还有一格只有在这里量得动：`@testable import`。书里没有对应物（CocoaPods 不管这个），
而本章那个包里真的放了一个 test target（`Tests/WeatherKitTests/ForecastTests.swift` 里
`@testable import WeatherKit`）。它是本章初稿写错的第二个地方 —— 它听起来像「internal 的一个
例外开关」，于是「主线里写 @testable import 就能看到 internal」这句话被写进了初稿。实测两半：

- e04（链 debug 那套包产物）：**编译通过，退出码 0，一个字都没报**；
- c03（同一份源码链 release 那套）：
  `error: module 'WeatherKit' was not compiled for testing`，退出码 1。

`@testable` 不是权限关键字，它要求**被链接的那份模块带 instrumentation**。这一格的凭据不用跑
探针也在仓库里：`build/33_dependency_management/spm/<配置>/WeatherKit/…/description.json`
是 `swift build` 自己写下的构建描述，逐条列出每个 target 的编译参数。debug 那套里
`-enable-testing` 出现在**四个** Swift target 的编译命令上（`ClimateCore`、`WeatherKit`，
加上两个 test target），release 那套里只剩**两个 test target** —— 库 target 不给。
于是本章那个包在 debug 下是「可测试的」，在 release 下不是，而 c03 两趟编译的差别就只有这个。
（s11 那格还补了一刀：`swift build` 连 test target 都不编，要 `--build-tests`；而 `swift test`
走的是**主机** `x86_64-apple-macosx`，换成本章的 triple 反而跑不动测试。）

## §8 `import WeatherKit` 不会顺手把 ClimateCore 也带进来

依赖树是 WeatherKit → ClimateCore。e05 只写 `import WeatherKit` 就直接用 `climateCoreID`，
报的是 `cannot find 'climateCoreID' in scope` —— 符号**链得上**（`.o` 全给了），名字落地是
另一件事：每个模块的名字要各自 import。

这正是原书 10.8 那四行 import 的来处：它在同一个文件顶部写了
`import UIKit` / `import CoreLocation` / `import Alamofire` / `import SwiftyJSON`，而 10.3.2
的 Podfile 里装着三个库（SwiftyJSON、Alamofire、SVProgressHUD）—— 少写一行 import 就少一个
模块的名字，多装一个库也不自动送你一个名字。书里从没解释过为什么顶部要写四行而不是两行，
因为对它来说这不是问题（Xcode 自动补全会替你加上）。

注意这条与 §5 不是一回事、也不互相担保：§5 讲的是**构建系统**认不认你写的那行
`dependencies`（本机：不认，见 s09），这一条讲的是**语言**认不认你的 `import`（永远认）。

主线本文件顶部把三个 import 全写了，所以这一格从正面断言：

```
== §8 `import WeatherKit` 不会顺手把 ClimateCore 也带进来 ==
  ok   两个模块的名字各自 import 才各自可用
  ok   allCases 来自 ClimateCore 的 CaseIterable：["celsius", "fahrenheit"]
```

## §9 返回值能用，但类型名要自己 import 才写得出来

`WeatherKit` 里那一行是 `public func preferredUnit() -> TemperatureUnit`，而
`TemperatureUnit` 属于 ClimateCore。e06 只 import WeatherKit：

```
===== e06_type_without_import (debug)
main.swift:18:15: error: cannot find type 'TemperatureUnit' in scope
16 | print("只用返回值：\(unit) / \(viaMember)")      ← 这一行之前全部通过
18 | let explicit: TemperatureUnit = .celsius        ← 红在这一行
```

**「能用不能命名」是这一格的准确形状**：模块决定了名字的可获得性，不决定值本身的可获得性。
书 10.9 里有一句现成的、同样形状的例子：`let weatherJSON: JSON = JSON(response.result.value!)`
—— `JSON` 是 SwiftyJSON 的结构体，那行的类型名之所以写得出来，全靠顶部那行
`import SwiftyJSON`。少写它，编译器不是不懂这个值，是写不出这个名字。

主线 import 了 ClimateCore，所以两半都写得出来，正好把对照的另一边摆在这里：

```
== §9 返回值能用，但类型名要自己 import 才写得出来 ==
  ok   不 import ClimateCore 也能这样用：unit.convert(20)=68.0
  ok   写出类型名要自己 import 那个包（e06 红在这一行）
  ok   describing=fahrenheit rawValue=fahrenheit
```

## §10 一个 C 头文件 → 一个模块：函数名一个都不改

`Packages/WeatherKit/Sources/CLIBrain/` 里没有一行 Swift，只有一张
`include/CLIBrain.h`（两行原型）和一份 `brain.c`。这是本章独有的一个 target：
书 10.3.2 那三个库全是纯 Swift 的（SwiftyJSON、Alamofire、SVProgressHUD），而本书第 28 章
量过的「C 与 Swift 之间那层桥」在这里换了个位置 —— **桥在包内部**，主线看不见它，
主线只看见 `import CLIBrain`。

SwiftPM 给每个 C target 生成一份 `module.modulemap`，s12 在构建目录里把它抄了出来：

```
### CLIBrain.build
    module CLIBrain {
        umbrella header "/private/var/folders/…/iosdev33probes/pkg/WeatherKit/Sources/CLIBrain/include/CLIBrain.h"
        export *
    }
```

三个细节全在这一屏里：它是**生成**的（源码目录里没有 `module.modulemap` 这个文件）、
umbrella 的路径是**绝对路径**（写进构建目录里那份，换台机器就变了）、而 Swift target 的那几份
长的是另一个样子（`header "…/<T>-Swift.h"` + `requires objc`，s12 同屏对照）。

于是 `import CLIBrain` 之后 C 的名字**原样**进 Swift：

| C 里的原型 | Swift 里的样子 |
| --- | --- |
| `const char *cliBrainVersion(void)` | `func cliBrainVersion() -> UnsafePointer<Int8>!` |
| `double cliDewPoint(double, double)` | `func cliDewPoint(_:_:) -> Double` |

参数标签变成下划线、指针变成**可选**的 `UnsafePointer`、其余保持 C 的拼写。最后那条是
这一节唯一的坑：`String(cString:)` 之前没人替它判空，因为可选性在这里是 C 侧的习惯产物，
不是 Swift 的类型语义。包里那个 `brainVersion()` 就是为此存在的（它做 `String(cString:)`
这一层转换，第 32 章那座 OC 桥上是同一件事）。

```
== §10 一个 C 头文件 → 一个模块：函数名一个都不改 ==
  ok   包给的包装=CLIBrain/c-1 与直接调 C=CLIBrain/c-1 同值
  ok   饱和时露点=气温这条物理不变量，C 侧算得出来：cliDewPoint(37.7,100)=37.7000
```

少给那份 modulemap 会怎样？e02 量的是这一格：主线那套 swiftc 命令，`.args` 里去掉
`-Xcc -fmodule-map-file=…` 那一行，红点不落在 C 的函数上，而是落在**那句 import**：

```
===== e02_missing_modulemap (debug)
main.swift:11:8: error: missing required module 'CLIBrain'
 9 | //
10 | // 跑法：bash probes/run.sh e02
11 | import WeatherKit
   |        `- error: missing required module 'CLIBrain'
```

这是 §2 那条判据的反向用法：**报错点名的是 CLIBrain，红点却画在 `import WeatherKit` 上** ——
因为 WeatherKit 那份 `.swiftmodule` 里记录着「我依赖 CLIBrain」，编译器顺着接口去找它的模块，
找不到就报给调用方。依赖树的形状在诊断里就这么露了一次头。

## §11 包也在换配置：clang 的 `-O` 有没有动浮点

`run-all.sh` 的第六条判定管的是**主线**两个配置的 stdout 逐字节一致；包是
`swift build -c debug` / `-c release` 各编一遍的，判定同样落到包上，**只是没人替它说话**。
所以这一格把露点打到 `%.17g`（Double 的可复原精度）而不是 `%.1f`：排版成 12.0 以后，
clang 的 `-O` 若动了浮点（快数学那类重结合）你根本看不见；而 17 位有效数字打出来之后，
**第六条判定就顺带把包的两个配置也比了一遍**。这是本文件为什么要在这里打印全精度、
而不是打印一个结论。

```
== §11 包也在换配置：clang 的 -O 有没有动浮点 ==
  20°C/60%  11.999894615745436   bits=4027fff22fe42572
   -3.50°C/88.00%  -5.2001997102501205   bits=c014cd012720c593
   37.70°C/15.00%  6.6543391413524242   bits=401a9e0b147267d1
  100.00°C/ 0.50%  -2.1923297106268742   bits=c00189e428c98855
  ok   12.0 是排版出来的，不是算出来的：全精度=11.999894615745436
  ok   同温下 80% 的露点更高：16.4444 > 11.9999
  ok   露点不可能高于气温：11.9999 ≤ 20
```

`bits=` 那一列是 `Double.bitPattern` 的十六进制 —— 逐位相同比逐字符相同更强，c01 在探针里
用同一串做了五个采样点，两个配置逐字节一致。而第一条断言是给「为什么要打全精度」作证的：
§1 那行印的是 `12.0`，实测全精度是 `11.999894615745436` —— **排版掉的这 1e-4 恰好是浮点求和的
误差量级**，也就是说「看起来是整数」在这条公式里从来不代表「算出来是整数」。

后面三条是 Magnus 公式自己的不变量（同一气温下湿度越高露点越高、露点不高于气温、饱和时
露点 = 气温），与优化无关，因此两个配置下都必须成立。

## §12 库定义的 `Error`：抛在包里，判在主线上

`Forecast.swift` 里有一个 `public enum ForecastError: Error, Equatable`。它对主线的意义有两条：
一是**错误也是 API 表面的一部分** —— `catch let e as ForecastError` 这种写法要求那个模块在
作用域里才匹配得上 case；二是它声明了 `Equatable`，于是主线可以直接比 case，不必一个个
`if case`。

这一格没有探针，因为它是纯语言事实；但它是 §15 的前置：库里那份**失败形状**（抛什么、
返回可选还是给默认值）会直接决定调用方要写几行防御。

```
== §12 库定义的 Error：抛在包里，判在主线上 ==
  ok   as? ForecastError 之后还能 == （Equatable 是包里声明的）
  ok   catch 里的模式匹配同样要求那个模块在作用域里
```

## §13 `Reading` 能 `==`：一致性写在包里，不是写在用的人身上

`public struct Reading: Equatable` —— 这一行在包源码里。主线拿到的只是一份 `.swiftmodule`
描述的二进制接口（s12 数过：一个模块在 `Modules/` 里其实有**四份**文件 ——
`.swiftmodule` / `.swiftdoc` / `.abi.json` / `.swiftsourceinfo`），一致性跟着接口走：
主线不需要、也**没办法**替包里的类型补 conformance。

```
== §13 `Reading` 能 == ：一致性写在包里，不是写在用的人身上 ==
  ok   r1==r2=true r1!=r3=true
  ok   字段是 let：city=北京 celsius=20.0
```

这条与第 30 章那句「conformance 是类型的属性」是同一件事，但在依赖管理的语境里它有另一个
名字：**你拿到的是二进制接口，不是源码**。你能做什么，在包作者写下 `: Equatable` 那一刻就
定完了。（书里对应的一段是 10.10 那句「为了让信息更加方便维护，我们要创建一个数据模型」——
它自己写 Model，所以这类决定全在自己手里；一旦 Model 来自一个包，这些决定就属于别人了。）

## §14 两种 API 形状：排好版的字符串 vs 没排版的数据

`report(for:)` 里已经做完了 `String(format: "%.1f", …)`，所以**精度丢失发生在包里**：主线
拿到的是一屏文本，想改成两位小数只能对字符串动手（切、拼），改不回数值语义。旁边那行
`fahrenheit(_:) -> Double` 才是可组合的形状。

这一格在书 10.10 有一段现成的对照。书里从 SwiftyJSON 拿温度是这两行：

```swift
let tempResult = json["main"]["temp"].double
weatherDataModel.temperature = Int(tempResult! - 273.15)
```

同一个 JSON 值，库给了 `.double` / `.stringValue` / `.intValue` 好几种取法（各自返回不同
类型），而 Model 层的属性是 `var temperature: Int = 0` —— **从这一行起小数就没了**。书里那句
「openweathermap提供的温度值是国际上的绝对温度值，所以要减去273.15得到摄氏温度值」正是本章
ClimateCore 里 `convert(_:)` 干的事（那边 K→°C，这边 °C→°F），只是本章把它留在 Double 上。

```
== §14 两种 API 形状：排好版的字符串 vs 没排版的数据 ==
  ok   文本前缀=北京：20.0°C（两位小数已经印不回来了）
  ok   要几位小数取决于拿没拿到 Double：68.00
```

选一个库，就是在选它的返回值类型；等它变成界面上一屏文本，你连「它是几度」都问不回来。

## §15 `guard !values.isEmpty else { return 0 }`：库里那句防御，主线只能读源码才知道

ClimateCore 里那个函数如果不写这行 guard，空数组会给出 NaN（0/0）。它写了，所以
`averageCelsius([])` 是 `0` —— 一个**看起来像有效读数**的值。

```
== §15 `guard !values.isEmpty else { return 0 }`：库里那句防御，主线只能读源码才知道 ==
  ok   averageCelsius([])=0.0（不是 NaN：guard 是 0）
  ok   averageCelsius([1,2,4])=2.3333
```

书 10.10 撞过同一类事，而且撞得更狠：它先写 `Int(tempResult! - 273.15)`，然后原话是
「openweathermap返回的是无效API key（因为我们修改了APP_ID）的JSON信息，所以并没有我们需要
的气象信息，这也就意味着tempResult的值为nil，在我们对tempResult强制拆包的时候，应用程序发生
崩溃」，改法换成 `if let` 才了事：

```swift
if let tempResult = json["main"]["temp"].double {
    weatherDataModel.temperature = Int(tempResult - 273.15)
    …
} else {
    cityLabel.text = "气象信息不可用"
}
```

那一次崩的不是调用方的逻辑，是**库选的失败形状**：书里明写「因为json["main"]["temp"]是JSON
类型，所以需要使用.double将其转换为双精度，但是此时的tempResult是可选，所以使用时要将其强制
拆包」——「取不到」长什么样是 SwiftyJSON 决定的，于是拆包这件事、以及崩这件事，全落在调用方
身上。本章那行 guard 是同一件事的温和版：**第三方库的边界行为不在你的类型系统里**，它在库的
实现里。你唯一的办法是把包源码留在仓库里读 —— 本章 `Packages/` 整个目录就是这个用途，
而这也是 path 依赖（`.package(path:)`）在真实项目里最大的好处。

## §16 `Package.swift` 那两行 `resources`，运行时看一眼目录

书 10.1 那句「在初始项目中已经包含了设计好的用户界面并添加了相关约束，还有就是项目会用到的
所有图片素材」，在本章的对应物就是 `Packages/WeatherKit/Sources/WeatherKit/Resources/` 下面
两个真文件（`city.json` 与 `nested/token.txt`）。它们进 bundle 的形状由这两行决定：

```swift
resources: [
    .copy("Resources/city.json"),      // 单文件直接搬：进 bundle 根，名字不变
    .process("Resources/nested")       // 目录「按处理规则摊平」：递归把里面每个文件提到根，
                                       //   路径前缀全丢，同名就报重复
]
```

于是包里的 `Resources/city.json` 与 `Resources/nested/token.txt` 在 bundle 里是**兄弟**，
不是父子（`entries` 精确等于 `["city.json","token.txt"]`，§1 已经断过一次，这里换个方向再断）：

```
== §16 Package.swift 那两行 resources，运行时看一眼目录 ==
  ok   city.json 在 bundle 根（.copy）
  ok   token.txt 被 .process 摊平：路径里的 nested/ 不见了
```

`.process` 那一半的原文在 s03 第三格：那个 fixture 在被处理的目录里放了两层
（`handled/b.txt` 与 `handled/inner/c.txt`），两个文件**都**被提到 bundle 根，
`inner/` 那层前缀整个消失；旁边 `.copy("Resources/flat")` 那一个目录则原样搬过去，
`flat/a.txt` 保留层级。落下来的清单因此是 `b.txt`、`c.txt`、`flat`、`flat/a.txt` ——
两行声明、两种形状，运行时一眼就分得开（这也是 §1 第二格那个精确断言能站住的原因）。

「同名就报重复」这一半也量了（s03 第四格）：两个目录里各放一个叫 `s.txt` 的文件，
`.copy` 与 `.process` 各认领一个 —— 这一次不是 warning：

```
swift build 退出码 = 1
    error: 'dup': multiple resources named 's.txt' in target 'Lib'
中间目录里有 .o 吗：0 个
```

三条读数都要记下。第一，它红在 **manifest 校验期**，中间目录里一个 `.o` 都没生成，所以不存在
「先编完再报」；第二，校验的是**末级名**而不是写下来的那条路径（两条路径一个叫 `one/`、一个叫
`two/`，一个字都不重合），因为 bundle 内部就是一张文件名的表；第三，把 `two/s.txt` 改名成
`two/t.txt`（第五格，目录层级照旧）就 `Build complete!`、bundle 里躺 `s.txt` 与 `t.txt`。
同一条消息里还会出现**两个名字**：报错点名的是包身份 `dup`（这一格里等于目录名，见 s07），
而第五格修好之后落下来的 bundle 叫 `DupNames_Lib.bundle` —— 前缀取的是 `name:`，规则本身在
第三格（`TwoShapes_Lib.bundle`）与 §17。

这一格更要紧的是**路径基准**：那两行写的是 `Resources/…`，基准是 `Sources/WeatherKit/`
（target 目录），不是包根目录。写错基准时 SwiftPM 的表现是本章所有「静默」里最像陷阱的一个：

```
=== 基准放错：文件在**包根**的 Resources/，声明写的却是 .copy("Resources/city.json")
swift build 退出码 = 0
    warning: 'wrong': Invalid Resource 'Resources/city.json': File not found.
    Building for debugging...
    Build complete! (5.48s)
```

**warning + 退出码 0**，然后给你一份少了那个文件的 bundle。它不会在编译期拦你，也不会在
运行期拦你（除非你恰好断言了清单）—— 只有 §1 那种「entries 精确等于两个名字」的断言抓得住。

## §17 `<Package 名>_<target 名>.bundle`：两个名字相同的时候看不出规则

实测：本章这个包给的 bundle 叫 `WeatherKit_WeatherKit.bundle` —— 因为 `Package(name:)` 与
target 名**恰好都叫 WeatherKit**。规则本身要靠拆开的名字才现形，而拆它的是 s03 的第三格
（不是 s05）：那个 fixture 的**目录**叫 `shapes`、`Package(name:)` 写 `TwoShapes`、target 叫
`Lib`，落下来的 bundle 是 `TwoShapes_Lib.bundle` —— 前缀取的是 manifest 里的 `name:`，
既不是目录名（那是 identity 的来源，见 s07），也不是 product 名（那一格根本没写 `products:`）。

```
== §17 `<Package 名>_<target 名>.bundle`：两个名字相同的时候看不出规则 ==
  ok   后缀=.bundle
  ok   只有目录名本身：父路径带着 debug/release，不进输出
```

第二格是排版层面的：`bundleLayout()` 返回的是 `bundleURL.lastPathComponent`，因为父路径里
带着 `x86_64-apple-ios-simulator/debug`，而那条路径在两处不同（探针跑在临时目录、主线跑在
`build/`）—— 打进 stdout 就成了判定 6 的必然失败。**能把路径打出来的断言，要先问它是不是
只带名字。**

这条命名规则为什么值得记：Xcode 里那步「把资源 bundle 拷进 .app」是自动的，命令行上你得
自己知道要拷**哪一个目录**、以及拷到哪儿（s13 量的就是「拷错地方会怎样」）。

## §18 包的资源不在主 bundle 里（而 `Bundle.module` 是 internal）

主线这个可执行文件是裸二进制（没有 `.app` 外壳），`Bundle.main` 就是它所在的目录。
`city.json` 在那里吗？不在 —— 它在 `WeatherKit_WeatherKit.bundle` 这一层里。

```
== §18 包的资源不在主 bundle 里 ==
  ok   Bundle.main 的根里没有 city.json（资源不跟着可执行文件走）
  ok   包内的 Bundle.module 找到了它：主线只能隔着 public API 看见（c02）
```

这一条就是原书 10.4 那句「必须通过双击 Weather.xcworkspace（白色图标的）文件才能正常打开项目，
因为该文件中包含了 CocoaPods 的相关信息」在命令行侧的真实代价：**依赖的资源永远不在你的主
bundle 里**，它跟着依赖走，靠一个子 bundle 交付。Xcode 里那个 workspace 干的活之一就是把
「哪些子 bundle 要拷进 .app」记在构建阶段里。

还有一格只有命令行会撞到，而且它是**编译期**的：`Bundle.module` 用不了。它是 SwiftPM 看见
`resources:` 之后**生成**在 WeatherKit 那个 target 里的一个 `static let`（s04 量的正是
「生成」这件事：不写 `resources:` 时用它是 `type 'Bundle' has no member 'module'`，
补一行之后构建目录里凭空多出一个
`<T>.build/DerivedSources/resource_bundle_accessor.swift`），
没写访问级别 ⇒ internal ⇒ 模块外一行都写不了：

```
===== c02_bundle_module_internal (debug)
main.swift:18:16: error: 'module' is inaccessible due to 'internal' protection level
18 | let u = Bundle.module.url(forResource: "city", withExtension: "json")
   |                `- error: 'module' is inaccessible due to 'internal' protection level

…/debug/WeatherKit.build/DerivedSources/resource_bundle_accessor.swift:4:16: note: 'module' declared here
 4 |     static let module: Bundle = {
```

把这条与 §6 的 e03 摆在一起才看得清形状：同是「跨模块用 internal」，`hiddenOffset()` 报的是
`cannot find … in scope`（名字根本不在作用域里），`Bundle.module` 报的是
`'module' is inaccessible due to 'internal' protection level` —— 因为 `Bundle` 这个类型看得见、
`.module` 这个成员名解得开，编译器**在访问级别这一步**才拦你。诊断措辞的不同就是这两步的
不同。c02 还有一格配置差异：debug 的 note 指向那个**生成出来的源文件**（带绝对路径），
release 的 note 指向 `.swiftmodule` 里的接口（`WeatherKit.Bundle (internal):2:25`）——
同一句错误，两个配置各自从哪儿读到的这件事也写在 note 里。

所以「主线上读一下包的资源」这句话本身就写不出来 —— 读资源必须走包自己 public 出来的函数，
§19 就是这条的正面。

## §19 主线 import 的是 WeatherKit，读到的是包里的 JSON

`cityOffset()` 在 `Resources.swift` 里，读的是 `Bundle.module` 那份 `city.json` 的 `offset`
字段。它证明的是「资源跟着 target 走，不跟着 product 走」：主线没有 import 任何
「资源产品」，资源的访问接口就是那个 Swift target 的普通函数。

```
== §19 主线 import 的是 WeatherKit，读到的是包里的 JSON ==
  ok   JSON 内容=city|:|Beijing|,|offset|:|8
  ok   cityOffset()=8（-1 才是读失败的信号）
```

读不到时的默认值是 `-1`（包里那句 `return -1`），所以这一格顺带演示了 §15 那条的另一个面：
**第三方库的失败模式是它选的**。

打印的形状也留意一下：包给的**不是**那段 JSON 原文，而是切过一遍的 token 串
（`city|:|Beijing|,|offset|:|8`）。JSON 原文里有换行与引号，而本仓库的判定 5 不允许 stdout
出现多余控制字符 —— 所以库侧就地把排版做掉了。这是 §14 那条「返回值类型由库决定」的资源版，
也是本章唯一一个「判据反过来影响了包源码写法」的地方。

## §20 本章的依赖没有版本范围：path 依赖连 `Package.resolved` 都不写

原书 10.3.2 那三行 pod **一个字都没写版本号**：

```ruby
platform :ios, '9.0'
target 'Weather' do
use_frameworks!
# Pods for Weather
pod 'SwiftyJSON'
pod 'Alamofire'
pod 'SVProgressHUD'
end
```

它关于版本只有一句：「如果将来某个开源库类发布了新版本，就可以直接使用 pod update 进行升级，
非常方便」。这句话把「**声明的范围**」和「**解析后钉住的版本**」说成了同一件事，而这两层在
SwiftPM 里是分开的、可以分别量的（s08，原文见探针记录）：

- 上游只有 tag `1.0.0` 时解析并写锁；再加一个 tag `1.2.0`，manifest 与锁都不改，重新
  `swift build` —— **锁里还是 1.0.0**（`Working copy … resolved at 1.0.0`）；
- `swift package update` 才动锁：`Computed … at 1.2.0`，锁里换成新的 `revision` 与 `version`；
- 删掉锁文件、加 `--disable-automatic-resolution` —— 反向要求：
  `error: a resolved file is required when automatic dependency resolution is disabled and should be placed at …/Package.resolved`。

而本章主线用的是 `.package(path:)`，这两层**天生都不存在**。s07 实测那一趟之后：

```
--- 这一趟成功之后：锁文件在不在，workspace-state.json 把这一格记成什么
    没有这个文件：client/Package.resolved
    有文件：c2.spm/workspace-state.json
        "identity" : "climate-kernel",
        "kind" : "fileSystem",
        "path" : "/private/var/folders/…/s07_identity_is_the_directory/Climate-Kernel"
        "version" : 6
```

没有 revision、没有 version，只有 `kind: fileSystem` 加一条 `path`。主线这一格因此只能断言
「出厂身份是源码里那行常量」：它跟着源码走，不跟着 tag 走 —— 这也正是 path 依赖的语义：
**钉在目录上，而不是钉在版本上**。

```
== §20 本章的依赖没有版本范围：path 依赖连 Package.resolved 都不写 ==
  ok   两个包的身份都是硬编码常量：WeatherKit/1.0 / ClimateCore/1.0
  ok   没有任何版本号参与运行期：只有 .o 里的这些符号
```

顺带一格与书里那段 Podfile 直接对得上的：`use_frameworks!` 在本机的对应物是
`.library(name: "Lib", type: .dynamic)`。s10 量了三种落法的差别 —— automatic（默认）只给
`.o`、静态给 `libLib.a`（`ar` 里就一个成员 `Lib.swift.o`）、动态给 `libLib.dylib`，
install name 是 `@rpath/libLib.dylib`。书里那句「Comment the next line if you're not using
Swift and don't want to use dynamic frameworks」翻译成本章的语言就是：**默认那个（automatic）
根本不会产出 framework**，是链进调用方的 `.o`；要 framework 就得明写 `.dynamic`，而那时
可执行文件运行时要靠 `@rpath` 找到它 —— 这一步在 Xcode 里是 Embed & Sign 那条阶段自动做的。

## §21 一次调用走过的模块数

这一节把 §5 那句话数出来：`report(for:)` 一次调用要跑过**三个 target** 的代码 ——
WeatherKit（排版）、ClimateCore（换算）、CLIBrain（露点，C）。

```
== §21 一次调用走过的模块数 ==
  ok   三个 target 合起来的一条字符串：广州：30.0°C / 86.0°F / 露点 21.4°C
  ok   三段分别来自：Swift 排版 + ClimateCore 换算 + CLIBrain 计算
```

三个 target 的 `.o` 都在链接输入里，缺任何一个都到不了运行这一步。s12 在构建目录里数到的
分层就是这条的磁盘形态：

```
=== 2) .o 的分层：源码文件名 → 目标文件名
    CLIBrain.build/brain.c.o
    ClimateCore.build/Unit.swift.o
    WeatherKit.build/Forecast.swift.o
    WeatherKit.build/Resources.swift.o
    WeatherKit.build/resource_bundle_accessor.swift.o
```

最后一行是本章最小的一个惊喜：`resource_bundle_accessor.swift.o` —— 那个源文件在仓库里不存在
（§18 说过它是生成的），但它的**目标码**和手写的三个文件混在同一批 `.o` 里，谁也看不出谁是
生成的。

e09 现场扣掉 `CLIBrain.build/brain.c.o` 那一份，量的是「少一类输入的最坏情况」：类型检查
一路放行，红在链接，而且报的是**符号名**：

```
===== e09_missing_object_file (debug)
error: link command failed with exit code 1 (use -v to see invocation)
Undefined symbols for architecture x86_64:
  "_cliBrainVersion", referenced from:
      WeatherKit.brainVersion() -> Swift.String in Forecast.swift.o
  "_cliDewPoint", referenced from:
      WeatherKit.report(for: WeatherKit.Reading) -> Swift.String in Forecast.swift.o
ld: symbol(s) not found for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
swiftc 退出码 = 1
```

这一屏值得逐行读：`_cliBrainVersion` 前面那个下划线是 C 符号在 Mach-O 里的惯例；
`referenced from: WeatherKit.brainVersion() … in Forecast.swift.o` 一句话说清了
「谁在哪个目标文件里等这个符号」；而 swiftc 的退出码是 1，**错误行却不带任何源文件行列号**
—— 因为它根本不是诊断，是链接器的抱怨。§1 那四类输入里的第 3 类少给一次，就是这一屏。

## §22 没有依赖管理器时，这几行是自己写的

书 10.3 数过没有管理器时的两类痛：「一个个手动去下载所需的类库十分麻烦」，以及
「可能某个类库又用到其他类库，所以为了使用它，必须还得额外下载其他类库，而其他类库又可能会
用到其他类库——『子子孙孙无穷尽也』」。本章的形态更直白：**如果没有 SwiftPM，§1 那四类输入
要人肉维护** —— 而 `run-all.sh` 里那几十行（`build_packages` + `spm_extra_args`）就是那个
样子：先跑一次 `swift build` 问它要产物，再把产物路径拼成 swiftc 的参数。

换句话说，依赖管理器的**全部**工作就是替你把这四类输入管对。它不做的事：
不改你的访问级别（§6）、不传染 import（§8）、不替你选返回值类型（§14）。

这一格能落在运行时的只有第 4 类：那个 bundle 是**磁盘上的一个真目录**，就在可执行文件旁边。
s13 抄了生成的那个文件全文，两个候选路径都在里面：

```
    let mainPath = Bundle.main.bundleURL.appendingPathComponent("WeatherKit_WeatherKit.bundle").path
    let buildPath = "/var/folders/…/s13.spm/x86_64-apple-ios-simulator/debug/WeatherKit_WeatherKit.bundle"
    let preferredBundle = Bundle(path: mainPath)
    guard let bundle = preferredBundle ?? Bundle(path: buildPath) else {
        Swift.fatalError("could not load resource bundle: from \(mainPath) or \(buildPath)")
    }
```

第二个候选是**编译期写死的构建目录绝对路径**。于是 s13 量出三种下场：

- 旁边有 bundle：第一个候选命中，跑绿；
- 旁边**没有** bundle、构建目录还在：第二个候选命中，**照样跑绿** —— 这就是「假绿」。
  它读到的资源一个字不差，可那份 bundle 在临时目录里，换台机器、清一次缓存就没了；
- 两份都没了：退出码 132（信号 4），stderr 是那句 `Fatal error: could not load resource
  bundle: from … or …`，**两个路径都印给你**。

```
== §22 没有依赖管理器时，这几行是自己写的 ==
  ok   拷过来的 bundle 里有 2 个文件（.copy 一个 + .process 摊平一个）
  ok   命中的是 s13 那两个候选里的第一个（可执行文件旁边），不是构建目录里的绝对路径
```

第二格就是本章对「假绿」的防御：`run-all.sh` 显式把 bundle `cp -R` 到可执行文件旁边
（判定不吃那条构建目录路径），主线再用 `Bundle.main.bundleURL + 目录名` 自己拼一次，
证明它**不需要**那个构建目录也能找到资源。Xcode 里不会撞上这一格（.app 里那条路径由
Copy Resources 阶段保证），命令行构建一定会撞上 —— 这是「换成本机环境」多出来的第三条事实。

## §23 本章唯一一条「依赖接上了」的判据

编译器不报错不等于接上了你要的那个依赖（§2）。这条主线用一句话收：**让库里独有的符号参与
输出，它出得来才算接上。**

```
== §23 本章唯一一条「依赖接上了」的判据 ==
  ok   三个模块 + 一份包内资源，四个出处各自签名
```

四个出处分别是 `weatherKitID`（撞名之下只有包里有）、`climateCoreID`（传递依赖那一层）、
`brainVersion()`（C 那一层，经过 `String(cString:)`）、`cityOffset()`（资源那一层）。
把它们写进同一条断言的意义是：这四样东西**分别**对应 §1 那四类输入，少任何一类，这一格就红。

## 本章开头那八条换法，现在的账目

| 开头那条换法 | 落在哪一节 | 证据（现跑原文） |
| --- | --- | --- |
| ①「Xcode 的 Bug」不是 Bug，是搜索路径 | §1、§3 | e01（红）、e07/e08（换个错）、r01（六条全过） |
| ② 依赖没接上也可能不红（SDK 里有个同名框架） | §2、§23 | SDK 那份 `.swiftinterface`、e07 与 e08 的对照 |
| ③ `canImport` 分辨不了撞名 | §3 | r01 |
| ④ 依赖两层的硬度与直觉相反 | §5 | s09 六格 |
| ⑤ 范围与锁是两层；path 依赖两层都没有 | §20 | s08、s07 |
| ⑥ product 名与 module 名可分，撞名还不一定报警 | §4 | s05 六读数、s06、s03 第三格 |
| ⑦ 资源那一侧的四处静默 | §16、§17、§18、§22 | s03（warning + 少文件）、s04（生成）、c02（internal）、s13（假绿） |
| ⑧ `@testable` 只成立于一半 | §7 | e04（退出码 0）、c03（release 拒绝）、s11 |

## 探针记录（26 支，逐字抄自现跑输出）

跑法与环境：

```bash
bash examples/33_dependency_management/probes/run.sh            # 全部 26 支（先准备包产物，约 1 分钟）
bash examples/33_dependency_management/probes/run.sh s03 c03    # 按编号挑；只挑 sNN 时跳过准备那一步
```

四族的分工写在 `probes/run.sh` 头部：`sNN_*` 是 SwiftPM 命令行现场（自己造 fixture，跑原生
`swift build` / `swift package` / `swift test`，抄命令原文与退出码）；`eNN_*` 是编译期诊断
（主线那套 swiftc 命令，故意少给一类输入，**不运行**）；`rNN_*` 编好放进模拟器跑；`cNN_*` 是同一份
源码分别链 debug 与 release 两套包产物的对照。与第 32 章不同，本章的 `eNN_*` **不做 `-typecheck`
预筛**，一律走完整编译 —— 这里要量的错多半在模块可见性与链接期（e09 那句 `Undefined symbols`
只有链接才报，`-typecheck` 那条路一个字都不给）。

模块名与主线一致（`-module-name dependency_management`），SDK 是
`xcrun -sdk iphonesimulator --show-sdk-path`，target 是 `x86_64-apple-ios15.0-simulator`，运行走
`xcrun simctl spawn`。`eNN`/`rNN`/`cNN` 链的那两套包产物由 run.sh 开头现编，而**编的是拷进临时目录
的那两份包**（`copy_packages`）：包留在 `examples/` 里被原地构建会写出一个几百 MB 的 `.build/`，
把「谁有 `.build`」这件事交给脚本管，回归就没法复现了。

四件记档口径，抄的时候要知道：

- 诊断里的源文件路径统一是 `/var/folders/…/iosdev33probes/main.swift`（探针的 `.swift` 必须先复制
  成 `main.swift` 才允许顶层语句），行列号是这一份临时文件的，不是仓库里那个探针文件的；
- **凡带 `/var/folders/…` 的路径都是现跑现场的绝对路径**，换一台机器、换一个 `$TMPDIR` 就不同。
  它们留在这里是为了看清「谁指向哪里」（s02 那串 manifest 编译命令、s07 的 identity、s12 的 umbrella
  header、s13 的两个候选），不参与任何比对。同理 `Build complete! (15.20s)` 里的**耗时每次都在变**，
  下面这些原文里的秒数只说明「这是一次真构建」；
- **退出码 132 = 信号 4（SIGILL）**，Swift 运行时的 `fatalError()` 走这一路。本章只有 s13 第三格一处
  崩溃（`could not load resource bundle: from … or …`），而且它是 SwiftPM 自己写的那句 `fatalError`，
  不是主线代码；
- `sNN_*` 那十三支的 stdout 前面统一有**四个空格**的缩进，那是 run.sh 末尾 `sed 's/^/    /'` 加的
  （为了和 c/e/r 三族的输出对齐）。本节按主线惯例把它去掉，其余一个字没动。

### `c01_package_optimization` —— 同一份源码分别链 debug 与 release **两套包产物**：clang 的 `-O` 有没有动浮点（§11）

```
===== c01_package_optimization (debug)
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
 20.00°C / 60.00% -> 11.999894615745436  bits=4027fff22fe42572
 -3.50°C / 88.00% -> -5.2001997102501205  bits=c014cd012720c593
 37.70°C / 15.00% -> 6.6543391413524242  bits=401a9e0b147267d1
  0.10°C / 99.90% -> 0.086193025660102923  bits=3fb610bf025a7a72
100.00°C /  0.50% -> -2.1923297106268742  bits=c00189e428c98855
北京：20.0°C / 68.0°F / 露点 12.0°C
--- stderr ---（空）

===== c01_package_optimization (release)
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
 20.00°C / 60.00% -> 11.999894615745436  bits=4027fff22fe42572
 -3.50°C / 88.00% -> -5.2001997102501205  bits=c014cd012720c593
 37.70°C / 15.00% -> 6.6543391413524242  bits=401a9e0b147267d1
  0.10°C / 99.90% -> 0.086193025660102923  bits=3fb610bf025a7a72
100.00°C /  0.50% -> -2.1923297106268742  bits=c00189e428c98855
北京：20.0°C / 68.0°F / 露点 12.0°C
--- stderr ---（空）
```

### `c02_bundle_module_internal` —— 主线上写 `Bundle.module` 会红，而且两个配置给的 note 不是同一个形状（§18）

```
===== c02_bundle_module_internal (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/main.swift:18:16: error: 'module' is inaccessible due to 'internal' protection level
16 | import WeatherKit
17 | 
18 | let u = Bundle.module.url(forResource: "city", withExtension: "json")
   |                `- error: 'module' is inaccessible due to 'internal' protection level
19 | print(u == nil ? "missing" : "found")
20 | 

/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/spm/debug/WeatherKit/x86_64-apple-ios-simulator/debug/WeatherKit.build/DerivedSources/resource_bundle_accessor.swift:4:16: note: 'module' declared here
 2 | 
 3 | extension Foundation.Bundle {
 4 |     static let module: Bundle = {
   |                `- note: 'module' declared here
 5 |         let mainPath = Bundle.main.bundleURL.appendingPathComponent("WeatherKit_WeatherKit.bundle").path
 6 |         let buildPath = "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/spm/debug/WeatherKit/x86_64-apple-ios-simulator/debug/WeatherKit_WeatherKit.bundle"
swiftc 退出码 = 1
（编译未通过：不运行）

===== c02_bundle_module_internal (release)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/main.swift:18:16: error: 'module' is inaccessible due to 'internal' protection level
16 | import WeatherKit
17 | 
18 | let u = Bundle.module.url(forResource: "city", withExtension: "json")
   |                `- error: 'module' is inaccessible due to 'internal' protection level
19 | print(u == nil ? "missing" : "found")
20 | 

WeatherKit.Bundle (internal):2:25: note: 'module' declared here
1 | extension Bundle {
2 |     internal static let module: Bundle
  |                         `- note: 'module' declared here
3 | }
swiftc 退出码 = 1
（编译未通过：不运行）
```

### `c03_testable_needs_instrumented` —— `@testable` 那道门开在**产物**上，不在配置名上：debug 能跑，release 当场红（§7）

```
===== c03_testable_needs_instrumented (debug)
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
internalTag() = internal-tag
--- stderr ---（空）

===== c03_testable_needs_instrumented (release)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/main.swift:16:18: error: module 'WeatherKit' was not compiled for testing
14 | //
15 | // 跑法：bash probes/run.sh c03（两个配置各编一遍，能跑的那个再进模拟器）
16 | @testable import WeatherKit
   |                  `- error: module 'WeatherKit' was not compiled for testing
17 | 
18 | print("internalTag() = \(internalTag())")
swiftc 退出码 = 1
（编译未通过：不运行）
```

### `e01_no_module_search_path` —— 主线那条 swiftc 命令里少给 `-I <中间目录>/Modules`（§1、§2）

```
===== e01_no_module_search_path (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/main.swift:13:8: error: no such module 'ClimateCore'
11 | //
12 | // 跑法：bash probes/run.sh e01
13 | import ClimateCore
   |        `- error: no such module 'ClimateCore'
14 | 
15 | print(climateCoreID)
swiftc 退出码 = 1
（编译类探针：到此为止，不运行）
```

### `e02_missing_modulemap` —— 给了 `-I Modules`，少给 C target 那条 `-Xcc -fmodule-map-file=`（§1、§10）

```
===== e02_missing_modulemap (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/main.swift:11:8: error: missing required module 'CLIBrain'
 9 | //
10 | // 跑法：bash probes/run.sh e02
11 | import WeatherKit
   |        `- error: missing required module 'CLIBrain'
12 | 
13 | let text = report(for: Reading(city: "北京", celsius: 20))
swiftc 退出码 = 1
（编译类探针：到此为止，不运行）
```

### `e03_internal_not_visible` —— 包里的 internal 名字在模块外一律不可见 —— 三种写法各撞一次（§6）

```
===== e03_internal_not_visible (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/main.swift:14:7: error: cannot find 'hiddenOffset' in scope
12 | import WeatherKit
13 | 
14 | print(hiddenOffset())
   |       `- error: cannot find 'hiddenOffset' in scope
15 | print(InternalReading(celsius: 1))
16 | print(internalTag())

/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/main.swift:15:7: error: cannot find 'InternalReading' in scope
13 | 
14 | print(hiddenOffset())
15 | print(InternalReading(celsius: 1))
   |       `- error: cannot find 'InternalReading' in scope
16 | print(internalTag())
17 | 

/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/main.swift:16:7: error: cannot find 'internalTag' in scope
14 | print(hiddenOffset())
15 | print(InternalReading(celsius: 1))
16 | print(internalTag())
   |       `- error: cannot find 'internalTag' in scope
17 | 
swiftc 退出码 = 1
（编译类探针：到此为止，不运行）
```

### `e04_testable_import` —— `@testable import` 链着 `swift build -c debug` 的产物：**编译通过，退出码 0**（§7）

```
===== e04_testable_import (debug)
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
（编译类探针：到此为止，不运行）
```

### `e05_transitive_import` —— `import WeatherKit` 会不会顺手把 ClimateCore 也带进来（§8）

```
===== e05_transitive_import (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/main.swift:14:7: error: cannot find 'climateCoreID' in scope
12 | import WeatherKit
13 | 
14 | print(climateCoreID)
   |       `- error: cannot find 'climateCoreID' in scope
15 | 
swiftc 退出码 = 1
（编译类探针：到此为止，不运行）
```

### `e06_type_without_import` —— 公开 API 的签名里带着另一个模块的类型：返回值能用，类型名写不出来（§9）

```
===== e06_type_without_import (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/main.swift:18:15: error: cannot find type 'TemperatureUnit' in scope
16 | print("只用返回值：\(unit) / \(viaMember)")
17 | 
18 | let explicit: TemperatureUnit = .celsius
   |               `- error: cannot find type 'TemperatureUnit' in scope
19 | print("写出类型名：\(explicit)")
20 | 
swiftc 退出码 = 1
（编译类探针：到此为止，不运行）
```

### `e07_sdk_name_collision` —— 不给 `-I` 的同一份源码 —— `import WeatherKit` 绑到 SDK 里那个框架（§2）

```
===== e07_sdk_name_collision (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/main.swift:16:5: error: 'WeatherService' is only available in iOS 16.0 or newer
14 | import WeatherKit
15 | 
16 | _ = WeatherService()
   |     |- error: 'WeatherService' is only available in iOS 16.0 or newer
   |     `- note: add 'if #available' version check
17 | print(report(for: Reading(city: "北京", celsius: 20)))
18 | 

/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/main.swift:17:7: error: cannot find 'report' in scope
15 | 
16 | _ = WeatherService()
17 | print(report(for: Reading(city: "北京", celsius: 20)))
   |       `- error: cannot find 'report' in scope
18 | 

/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/main.swift:17:19: error: cannot find 'Reading' in scope
15 | 
16 | _ = WeatherService()
17 | print(report(for: Reading(city: "北京", celsius: 20)))
   |                   `- error: cannot find 'Reading' in scope
18 | 
swiftc 退出码 = 1
（编译类探针：到此为止，不运行）
```

### `e08_package_module_wins` —— 源码与 e07 逐字相同，只有 `.args` 不同：报错的两个名字换了人（§2）

```
===== e08_package_module_wins (debug)
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/main.swift:9:5: error: cannot find 'WeatherService' in scope
 7 | import WeatherKit
 8 | 
 9 | _ = WeatherService()
   |     `- error: cannot find 'WeatherService' in scope
10 | print(report(for: Reading(city: "北京", celsius: 20)))
11 | 
swiftc 退出码 = 1
（编译类探针：到此为止，不运行）
```

### `e09_missing_object_file` —— 四类输入里少给**一个** `.o`：链接期才红，而且红得指名道姓（§1）

```
===== e09_missing_object_file (debug)
--- swiftc 输出 ---
error: link command failed with exit code 1 (use -v to see invocation)
Undefined symbols for architecture x86_64:
  "_cliBrainVersion", referenced from:
  WeatherKit.brainVersion() -> Swift.String in Forecast.swift.o
  "_cliDewPoint", referenced from:
  WeatherKit.report(for: WeatherKit.Reading) -> Swift.String in Forecast.swift.o
ld: symbol(s) not found for architecture x86_64
clang: error: linker command failed with exit code 1 (use -v to see invocation)
swiftc 退出码 = 1
（编译类探针：到此为止，不运行）
```

### `r01_imports_wrong_module_and_runs_green` —— 一条**期望它跑绿**的探针 —— 六条判定全过，而依赖根本没接上（§3）

```
===== r01_imports_wrong_module_and_runs_green (debug)
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
canImport(WeatherKit) 为真 —— 但这不能说明接上了包
--- stderr ---（空）
```

### `s01_default_destination_is_host` —— `swift build` 默认给**谁**编：不给 `--triple/--sdk` 得到一台跑在模拟器里的主机进程（「复现」）

```
$ ls <scratch>/            # 先看默认（不给 --triple/--sdk）落在哪个目录名里
swift build 退出码 = 0
[7/8] Applying HostDemo
Build complete! (26.00s)
artifacts
checkouts
repositories
x86_64-apple-macosx

--- 主机产物
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T//iosdev33probes/s01_default_destination_is_host/host/x86_64-apple-macosx/debug/HostDemo
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T//iosdev33probes/s01_default_destination_is_host/host/x86_64-apple-macosx/debug/HostDemo: Mach-O 64-bit executable x86_64

$ swift build --package-path fix --triple x86_64-apple-ios15.0-simulator --sdk <iphonesimulator> -c debug
swift build 退出码 = 0
[5/6] Linking HostDemo
Build complete! (16.00s)
artifacts
checkouts
repositories
x86_64-apple-ios-simulator

--- 设备（模拟器）产物
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T//iosdev33probes/s01_default_destination_is_host/sim/x86_64-apple-ios-simulator/debug/HostDemo
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T//iosdev33probes/s01_default_destination_is_host/sim/x86_64-apple-ios-simulator/debug/HostDemo: Mach-O 64-bit executable x86_64
      cmd LC_BUILD_VERSION
  cmdsize 32
 platform 7
    minos 12.0
      sdk 12.0
   ntools 1

$ swift build --triple x86_64-apple-ios15.0-simulator --sdk <sim> -c debug -v   # 只留 -target 那一段
swift build 退出码 = 0
   4 -target x86_64-apple-ios12.0-simulator

$ xcrun simctl spawn <sim> <主机那份二进制>
退出码 = 0
--- stdout ---
HostDemo 跑起来了：NSOperatingSystemVersion(majorVersion: 10, minorVersion: 16, patchVersion: 0)
--- stderr ---（空）

$ xcrun simctl spawn <sim> <设备那份二进制>
退出码 = 0
--- stdout ---
HostDemo 跑起来了：NSOperatingSystemVersion(majorVersion: 18, minorVersion: 3, patchVersion: 1)
--- stderr ---（空）
探针退出码 = 0
```

### `s02_manifest_is_a_host_program` —— `Package.swift` 自己也是一段要编译执行的 Swift —— 而它只能为主机编（「复现」）

```
$ SDKROOT=<模拟器 SDK> swift build --triple x86_64-apple-ios15.0-simulator --sdk <模拟器 SDK>
  （这就是 run-all.sh 里 export SDKROOT 之后的现场）
swift build 退出码 = 1
    -target
    -sdk
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator18.2.sdk
    -sdk
    /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator18.2.sdk
    -package-description-version
    error: 'weatherkit': Invalid manifest (compiled with: ["/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc", "-vfsoverlay", "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/TemporaryDirectory.GFvGiA/vfs.yaml", "-L", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-lPackageDescription", "-Xlinker", "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-target", "x86_64-apple-macosx13.0", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator18.2.sdk", "-F", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks", "-I", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-L", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-swift-version", "5", "-I", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator18.2.sdk", "-package-description-version", "5.9.0", "/private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/pkg/WeatherKit/Package.swift", "-o", "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/TemporaryDirectory.rGTFyL/weatherkit-manifest"])
    <unknown>:0: warning: using sysroot for 'iPhoneSimulator' but targeting 'MacOSX'
    <unknown>:0: error: unable to load standard library for target 'x86_64-apple-macosx13.0'
    error: 'weatherkit': Invalid manifest (compiled with: ["/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc", "-vfsoverlay", "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/TemporaryDirectory.MPhVZC/vfs.yaml", "-L", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-lPackageDescription", "-Xlinker", "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-target", "x86_64-apple-macosx13.0", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator18.2.sdk", "-F", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks", "-I", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-L", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-swift-version", "5", "-I", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator18.2.sdk", "-package-description-version", "5.9.0", "/private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/pkg/WeatherKit/Package.swift", "-o", "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/TemporaryDirectory.t5O9vl/weatherkit-manifest"])
    <unknown>:0: warning: using sysroot for 'iPhoneSimulator' but targeting 'MacOSX'
    <unknown>:0: error: unable to load standard library for target 'x86_64-apple-macosx13.0'

$ env -u SDKROOT swift build --triple x86_64-apple-ios15.0-simulator --sdk <模拟器 SDK>
swift build 退出码 = 0
[12/12] Emitting module WeatherKit
Build complete! (17.48s)

--- 只给 --triple、不给 --sdk（第二次编译没人告诉它设备 SDK 在哪）
swift build 退出码 = 1
    clang: warning: using sysroot for 'MacOSX' but targeting 'iPhone' [-Wincompatible-sysroot]
    error: emit-module command failed with exit code 1 (use -v to see invocation)
    <unknown>:0: warning: using sysroot for 'MacOSX' but targeting 'iPhone'
    <unknown>:0: error: unable to load standard library for target 'x86_64-apple-ios12.0-simulator'
    <unknown>:0: warning: using sysroot for 'MacOSX' but targeting 'iPhone'
    <unknown>:0: error: unable to load standard library for target 'x86_64-apple-ios12.0-simulator'
探针退出码 = 0
```

### `s03_resource_path_basis` —— 资源路径的基准是 target 目录，`.copy`/`.process` 两种形状，末级名撞车才是硬错误（§16、§17）

```
=== 基准放错：文件在**包根**的 Resources/，声明写的却是 .copy("Resources/city.json")
swift build 退出码 = 0
    warning: 'wrong': Invalid Resource 'Resources/city.json': File not found.
    Building for debugging...
    Build complete! (5.48s)

=== 基准放对：文件在 Sources/Lib/Resources/（同一行声明，一个字没改）
swift build 退出码 = 0
Build complete! (5.70s)

=== .copy 与 .process 在 bundle 里落成的形状（本章 §16 那张清单的来源）
swift build 退出码 = 0
bundle: TwoShapes_Lib.bundle
    b.txt
    c.txt
    flat
    flat/a.txt

=== 同名资源：两条路径都不一样，落进 bundle 的**末级名字**撞了（主线 §16 那句「同名就报重复」的出处）
swift build 退出码 = 1
    error: 'dup': multiple resources named 's.txt' in target 'Lib'
中间目录里有 .o 吗：0 个

=== 把末级名改掉（两条路径照旧，一个字都不动目录层级）
swift build 退出码 = 0
Build complete! (6.01s)
bundle: DupNames_Lib.bundle
    s.txt
    t.txt
探针退出码 = 0
```

### `s04_bundle_module_is_generated` —— 没声明 `resources:` 的 target 里用 `Bundle.module` —— 那个成员是**生成**出来的（§18）

```
=== 不写 resources，源码里用 Bundle.module
swift build 退出码 = 1
    warning: 'withmodule': found 1 file(s) which are unhandled; explicitly declare them as resources or exclude from the target
        /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s04_bundle_module_is_generated/withmodule/Sources/Lib/Resources/city.json
    Building for debugging...
    /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s04_bundle_module_is_generated/withmodule/Sources/Lib/Lib.swift:4:41: error: type 'Bundle' has no member 'module'
    2 | public let v = 1
    3 | import Foundation
    4 | public func where_() -> String { Bundle.module.bundlePath }
      |                                         `- error: type 'Bundle' has no member 'module'
    5 | 

=== 同一份源码，只在 Package.swift 里补一行 resources（源码一个字没改）
swift build 退出码 = 0
Build complete! (5.71s)
--- 这一次多出来的那个源文件：
    /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T//iosdev33probes/s04_bundle_module_is_generated/b.spm/x86_64-apple-ios-simulator/debug/Lib.build/DerivedSources/resource_bundle_accessor.swift
探针退出码 = 0
```

### `s05_duplicate_product_name` —— 同一个字符串撞两次车：撞 product 名一句话都不给，撞 target（=module）名才红（§4）

```
    core/：product "Shared" <- target Shared（module 名也是 Shared）
    app/ ：product "Shared" <- target App（module 名 App）—— 撞的只有 product 名

=== 读数 1：撞 product 名的那趟 swift build，SwiftPM 自己说了什么
swift build 退出码 = 0
    Build complete! (8.87s)
    （这一屏只剩 “Build complete!” —— 它连一句警告都没给）

=== 读数 2：app 对外列出的 product，那个叫 Shared 的指向谁的 target
    Products:
        Name: Shared
        Type:
            Library:
                automatic
        Targets:
            App
    
        Name: AppOnly
        Type:
            Library:
                automatic
        Targets:
            App
    
        Name: Run
        Type:
            Executable: nil
        Targets:
            Run
    
    Targets:

=== 读数 3：两份实现各自落在哪一个 .o（strings 从目标文件里挑常量）
    App.build/App.swift.o
    Run.build/main.swift.o
    Shared.build/Shared.swift.o
    strings App.build/App.swift.o              -> from-app-target-App 
    strings Run.build/main.swift.o             -> 
    strings Shared.build/Shared.swift.o        -> from-core-target-Shared 

=== 读数 4：跑一遍，Run 里那句 import Shared 拿到的是谁的实现
    二进制 = /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T//iosdev33probes/s05_duplicate_product_name/app-products.spm/x86_64-apple-ios-simulator/debug/Run
    运行退出码 = 0
    stdout: Run 里 import Shared 之后看到的 who = from-core-target-Shared

=== 读数 5：app 的本地 target 也叫 Shared（module 名撞车），同一趟构建的下场
swift build 退出码 = 1
    error: multiple similar targets 'Shared' appear in package 'app-targets' and 'core', this may indicate that the two packages are the same and can be de-duplicated by using mirrors. if they are not duplicate consider using the `moduleAliases` parameter in manifest to provide unique names

=== 读数 6：把这份 manifest 的 products 与 dependencies 换个位置（target 改名成 Lib，免得读数 5 那条先报）
swift build 退出码 = 1
    error: 'app-targets': Invalid manifest (compiled with: ["/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc", "-vfsoverlay", "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/TemporaryDirectory.rUxHOi/vfs.yaml", "-L", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-lPackageDescription", "-Xlinker", "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-target", "x86_64-apple-macosx13.0", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX15.2.sdk", "-F", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks", "-I", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-L", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-swift-version", "5", "-I", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX15.2.sdk", "-package-description-version", "5.9.0", "/private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s05_duplicate_product_name/app-targets/Package.swift", "-o", "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/TemporaryDirectory.zQONT6/app-targets-manifest"])
    /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s05_duplicate_product_name/app-targets/Package.swift:6:5: error: argument 'products' must precede argument 'dependencies'
    error: 'app-targets': Invalid manifest (compiled with: ["/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc", "-vfsoverlay", "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/TemporaryDirectory.CvNb7m/vfs.yaml", "-L", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-lPackageDescription", "-Xlinker", "-rpath", "-Xlinker", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-target", "x86_64-apple-macosx13.0", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX15.2.sdk", "-F", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks", "-I", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-L", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib", "-swift-version", "5", "-I", "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/pm/ManifestAPI", "-sdk", "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX15.2.sdk", "-package-description-version", "5.9.0", "/private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s05_duplicate_product_name/app-targets/Package.swift", "-o", "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/TemporaryDirectory.AQ1Xkn/app-targets-manifest"])
    /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s05_duplicate_product_name/app-targets/Package.swift:6:5: error: argument 'products' must precede argument 'dependencies'
探针退出码 = 0
```

### `s06_package_argument_identity` —— `.product(name:package:)` 的两个参数各写错一次 —— 报错顺手把合法值打出来（§4）

```
=== a) package 填一个凭记忆写的名字 "Climate"
swift build 退出码 = 1
    error: 'weatherkit': unknown package 'Climate' in dependencies of target 'WeatherKit'; valid packages are: 'ClimateCore' (at '/private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s06_package_argument_identity/ClimateCore')
    error: 'weatherkit': unknown package 'Climate' in dependencies of target 'WeatherKit'; valid packages are: 'ClimateCore' (at '/private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s06_package_argument_identity/ClimateCore')

=== b) package 填 "ClimateCore"（Package.swift 里的 name，也是目录名）
swift build 退出码 = 0
    Build complete! (17.37s)

=== c) product 名写错（ClimateCore 没有叫 Core 的 product）
swift build 退出码 = 1
    error: 'weatherkit': product 'Core' required by package 'weatherkit' target 'WeatherKit' not found in package 'ClimateCore'.
    error: ExitCode(rawValue: 1)

=== d) 退回主线那种写法：只给一个字符串 "ClimateCore"
swift build 退出码 = 0
    Build complete! (0.92s)

探针退出码 = 0
```

### `s07_identity_is_the_directory` —— 包的 identity 取的是**目录名**，不是 `Package(name:)`；path 依赖不写 `Package.resolved`（§4、§20）

```
    目录名 = Climate-Kernel
    Package 里的 name = TotallyDifferentName
    product 名 = ClimateCore
    target（module）名 = ClimateCore

--- .product(package:) 先填 Package 里那个 name
swift build 退出码 = 1
    error: 'client': unknown package 'TotallyDifferentName' in dependencies of target 'Client'; valid packages are: 'Climate-Kernel' (at '/private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s07_identity_is_the_directory/Climate-Kernel')
    error: 'client': unknown package 'TotallyDifferentName' in dependencies of target 'Client'; valid packages are: 'Climate-Kernel' (at '/private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s07_identity_is_the_directory/Climate-Kernel')

--- 同一个位置改成目录名的小写形式（identity），源码一个字没改
swift build 退出码 = 0
Build complete! (15.43s)

--- describe 里被依赖方的三个字符串
    Dependencies:
        Type:
            fileSystem
        Identity:
            climate-kernel
        Path:
            /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s07_identity_is_the_directory/Climate-Kernel
    
    Platforms:

--- show-dependencies --format json 里的 identity / name / url
    "identity": "client",
    "name": "Client",
    "url": "/private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s07_identity_is_the_directory/client",
    "version": "unspecified",
    "identity": "climate-kernel",
    "name": "TotallyDifferentName",
    "url": "/private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s07_identity_is_the_directory/Climate-Kernel",
    "version": "unspecified",

--- 这一趟成功之后：锁文件在不在，workspace-state.json 把这一格记成什么
    没有这个文件：client/Package.resolved
    有文件：c2.spm/workspace-state.json
        "identity" : "climate-kernel",
        "kind" : "fileSystem",
        "path" : "/private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s07_identity_is_the_directory/Climate-Kernel"
        "version" : 6
探针退出码 = 0
```

### `s08_version_range_and_lockfile` —— 版本区间、锁文件、`checkouts/` —— 书 10.3 那份 Podfile.lock 在本机的对应物（§20）

```
=== 上游只有一个 tag 1.0.0；root 的 target 依赖照抄本地路径那一格的写法 ["Remote"]
swift build 退出码 = 1
    Fetching /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream
    Fetched /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream from cache (0.16s)
    Computing version for /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream
    Computed /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream at 1.0.0 (0.12s)
    Creating working copy for /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream
    Working copy of /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream resolved at 1.0.0
    error: 'root': product 'Remote' required by package 'root' target 'Root' not found. Did you mean '.product(name: "Remote", package: "upstream")'?
--- 但解析已经发生：Package.resolved 在依赖图检查之前就写好了
    {
      "pins" : [
        {
          "identity" : "upstream",
          "kind" : "localSourceControl",
          "location" : "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream",
          "state" : {
            "revision" : "a6a201f2cdf3486acbbdbc057a542bbe35048bde",
            "version" : "1.0.0"
          }
        }
      ],
      "version" : 2
    }

=== 改成 .product(name:package:)，identity 用报错里提示的那个 upstream
    6:    targets: [.target(name: "Root", dependencies: [.product(name: "Remote", package: "upstream")])]
swift build 退出码 = 0
Build complete! (5.35s)
--- 中间目录里代码落在哪一层
    /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T//iosdev33probes/s08_version_range_and_lockfile/r1.spm
    artifacts
    checkouts
    checkouts/upstream
    checkouts/upstream/.git
    checkouts/upstream/Sources
    repositories
    repositories/upstream-e89296c0
    repositories/upstream-e89296c0/hooks
    repositories/upstream-e89296c0/info
    repositories/upstream-e89296c0/objects
    repositories/upstream-e89296c0/refs
    x86_64-apple-ios-simulator
    x86_64-apple-ios-simulator/debug
    x86_64-apple-ios-simulator/debug/ModuleCache
    x86_64-apple-ios-simulator/debug/Modules
    x86_64-apple-ios-simulator/debug/Remote.build
    x86_64-apple-ios-simulator/debug/Root.build
    x86_64-apple-ios-simulator/debug/index
--- 那份锁
    {
      "pins" : [
        {
          "identity" : "upstream",
          "kind" : "localSourceControl",
          "location" : "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream",
          "state" : {
            "revision" : "a6a201f2cdf3486acbbdbc057a542bbe35048bde",
            "version" : "1.0.0"
          }
        }
      ],
      "version" : 2
    }
--- workspace-state.json（在中间目录**根上**，不在 dest triple 那一层）：
    revision 与「工作副本」的对应关系写在这里，checkouts/ 里的内容由它决定
        "dependencies" : [
          {
            "basedOn" : null,
            "packageRef" : {
              "identity" : "upstream",
              "kind" : "localSourceControl",
              "location" : "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream",
              "name" : "Remote"
            },
            "state" : {
              "checkoutState" : {
                "revision" : "a6a201f2cdf3486acbbdbc057a542bbe35048bde",
                "version" : "1.0.0"
              },
              "name" : "sourceControlCheckout"
            },
            "subpath" : "upstream"
          }
        ]
      },
--- checkouts 里那份工作副本现在 checkout 在哪个 tag
    1.0.0

=== 上游再打一个 tag 1.2.0，manifest 与锁都不改，重新 build
    tag: 1.0.0
    tag: 1.2.0
swift build 退出码 = 0
    Computing version for /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream
    Creating working copy for /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream
    Working copy of /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream resolved at 1.0.0
    Build complete! (5.31s)
    锁里还是："revision" : "a6a201f2cdf3486acbbdbc057a542bbe35048bde",
    锁里还是："version" : "1.0.0"
    锁里还是："version" : 2

=== 显式解开：swift package update
swift package update 退出码 = 0
    Fetching /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream
    Fetched /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream from cache (0.17s)
    Computing version for /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream
    Computed /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream at 1.2.0 (0.13s)
    Creating working copy for /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream
    Working copy of /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream resolved at 1.2.0
    锁现在是："revision" : "cf7d2883383939338e66e604d61c92e9ffc9c233",
    锁现在是："version" : "1.2.0"
    锁现在是："version" : 2

=== 删掉锁文件，用 --disable-automatic-resolution 拦一次
swift build 退出码 = 1
    error: a resolved file is required when automatic dependency resolution is disabled and should be placed at /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/root/Package.resolved. Running resolver because the following dependencies were added: 'upstream' (/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s08_version_range_and_lockfile/upstream)
探针退出码 = 0
```

### `s09_transitive_dependency_layer` —— 依赖图里那个包在不在，与你的 target 能不能 import 它 —— 不是同一件事（§5）

```
=== 外层只有 WeatherKit（ClimateCore 是它的传递依赖），内层没写 —— 源码里却 import ClimateCore
    targets: [
    .target(name: "Client", dependencies: ["WeatherKit"])
swift build 退出码 = 0
    Build complete! (18.79s)

    --- 为什么它能过：这一趟的 Modules 目录里躺着谁的接口
        Client.swiftmodule
        ClimateCore.swiftmodule
        WeatherKit.swiftmodule
        —— -I 给的是这个目录本身，不是「你的 target 声明过的那些模块」

=== 两个包都出现在外层，内层里也各点名一次
    targets: [
    .target(name: "Client", dependencies: ["WeatherKit", "ClimateCore"])
swift build 退出码 = 0
    Build complete! (1.43s)

--- 只补内层、不补外层（target 里点名，但 .package 那层没有）
=== 内层写了 ClimateCore，外层没有
    targets: [
    .target(name: "Client", dependencies: ["WeatherKit", "ClimateCore"])
swift build 退出码 = 1
    error: 'client': product 'ClimateCore' required by package 'client' target 'Client' not found. Did you mean 'ClimateCore'?
    error: ExitCode(rawValue: 1)

=== 可执行形态·内层没写（只有 "WeatherKit"）：编译放行之后，链接放行吗
    targets: [
    .executableTarget(name: "Client", dependencies: ["WeatherKit"])
swift build 退出码 = 0
    Build complete! (18.19s)
    模拟器里跑：退出码 = 0
    stdout: pair = ("internal-tag@ClimateCore/1.0", "ClimateCore/1.0")
    stdout: climateCoreID = ClimateCore/1.0

=== 可执行形态·内层补齐（"WeatherKit", "ClimateCore"）
    targets: [
    .executableTarget(name: "Client", dependencies: ["WeatherKit", "ClimateCore"])
swift build 退出码 = 0
    Build complete! (18.99s)
    模拟器里跑：退出码 = 0
    stdout: pair = ("internal-tag@ClimateCore/1.0", "ClimateCore/1.0")
    stdout: climateCoreID = ClimateCore/1.0


--- swift build --help 里这两个开关的原文
      --explicit-target-dependency-import-check <explicit-target-dependency-import-check>
      --experimental-explicit-module-build

=== 第六格·a：漏写内层，只开 --explicit-target-dependency-import-check error（默认模块构建）
        targets: [
            .executableTarget(name: "Client", dependencies: ["WeatherKit"])
swift build 退出码 = 0
    Build complete! (18.62s)
    ——「Compiling Swift module XPC / CoreFoundation / …」那类行是它在重编 SDK 模块，
      本仓库的判定不吃 stdout，这里只挑 error / Build complete / 计时三类

=== 第六格·b：这一份 manifest 两层都写全了（对照用），三档齐开
        targets: [
            .executableTarget(name: "Client", dependencies: ["WeatherKit", "ClimateCore"])
swift build 退出码 = 1
    /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s09_transitive_dependency_layer/WeatherKit/Sources/WeatherKit/Forecast.swift:2:8: error: Unable to find module dependency: 'ClimateCore'
    /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s09_transitive_dependency_layer/client/Sources/Client/main.swift:2:8: error: Unable to find module dependency: 'ClimateCore'
    /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s09_transitive_dependency_layer/WeatherKit/Sources/WeatherKit/Forecast.swift:2:8: error: no such module 'ClimateCore'
       |        `- error: no such module 'ClimateCore'
    ——「Compiling Swift module XPC / CoreFoundation / …」那类行是它在重编 SDK 模块，
      本仓库的判定不吃 stdout，这里只挑 error / Build complete / 计时三类

=== 第六格·c：把上面那份「写全了」换成「漏写」，三档齐开，报错一个字没变
        targets: [
            .executableTarget(name: "Client", dependencies: ["WeatherKit"])
swift build 退出码 = 1
    /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s09_transitive_dependency_layer/WeatherKit/Sources/WeatherKit/Forecast.swift:2:8: error: Unable to find module dependency: 'ClimateCore'
    /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s09_transitive_dependency_layer/client/Sources/Client/main.swift:2:8: error: Unable to find module dependency: 'ClimateCore'
    /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s09_transitive_dependency_layer/WeatherKit/Sources/WeatherKit/Forecast.swift:2:8: error: no such module 'ClimateCore'
       |        `- error: no such module 'ClimateCore'
    ——「Compiling Swift module XPC / CoreFoundation / …」那类行是它在重编 SDK 模块，
      本仓库的判定不吃 stdout，这里只挑 error / Build complete / 计时三类

探针退出码 = 0
```

### `s10_static_vs_dynamic` —— `automatic` / `static` / `dynamic` 三种 products 声明的落盘形状（§20、§21）

```
=== automatic —— products 里那一行：.library(name: "Lib", targets: ["Lib"])
swift build 退出码 = 0
    Build complete! (13.48s)
    落盘：没有 .a / .dylib —— 只有 Lib.swift.o 

=== static —— products 里那一行：.library(name: "Lib", type: .static, targets: ["Lib"])
swift build 退出码 = 0
    Build complete! (14.01s)
    落盘：x86_64-apple-ios-simulator/debug/libLib.a

=== dynamic —— products 里那一行：.library(name: "Lib", type: .dynamic, targets: ["Lib"])
swift build 退出码 = 0
    Build complete! (14.95s)
    落盘：x86_64-apple-ios-simulator/debug/libLib.dylib
    落盘：x86_64-apple-ios-simulator/debug/libLib.dylib.dSYM/Contents/Resources/DWARF/libLib.dylib

--- 动态库那份的 install name：裸可执行文件运行时靠这一串找到它
    /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T//iosdev33probes/s10_static_vs_dynamic/dynamic.spm/x86_64-apple-ios-simulator/debug/libLib.dylib:
    @rpath/libLib.dylib
              cmd LC_ID_DYLIB
          cmdsize 48
             name @rpath/libLib.dylib (offset 24)
       time stamp 1 Thu Jan  1 08:00:01 1970

--- 静态库里的成员清单（ar 一眼看完：主线 §21 数的那些 .o 就是从这里进二进制的）
    __.SYMDEF SORTED
    Lib.swift.o
探针退出码 = 0
```

### `s11_tests_build_and_run` —— 包里那个 test target 什么时候真被编、在哪里跑得动（§7）

```
=== 1) swift build（不给 --build-tests）：WeatherKitTests.build 里有 .o 吗
swift build 退出码 = 0
  这些是 stdout 上的进度行（不是诊断）：
    Building for debugging...
    [0/6] Write sources
    [2/6] Copying city.json
    但目录确实存在：output-file-map.json 

=== 2) 加 --build-tests 再问一次
swift build --build-tests 退出码 = 1
    /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/pkg/WeatherKit/Tests/WeatherKitTests/ForecastTests.swift:11:9: error: cannot find 'XCTAssertEqual' in scope
       |         `- error: cannot find 'XCTAssertEqual' in scope
    /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/pkg/WeatherKit/Tests/WeatherKitTests/ForecastTests.swift:12:9: error: cannot find 'XCTAssertEqual' in scope
       |         `- error: cannot find 'XCTAssertEqual' in scope

=== 3) swift test（主机：不带 --triple/--sdk）
swift test 退出码 = 0
    Test Suite 'All tests' started at 2026-09-30 22:08:18.251.
    Test Suite 'WeatherKitPackageTests.xctest' started at 2026-09-30 22:08:18.255.
    Test Suite 'ForecastTests' started at 2026-09-30 22:08:18.255.
    Test Suite 'ForecastTests' passed at 2026-09-30 22:08:18.258.
    	 Executed 1 test, with 0 failures (0 unexpected) in 0.002 (0.003) seconds
    Test Suite 'WeatherKitPackageTests.xctest' passed at 2026-09-30 22:08:18.258.
    中间目录: /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T//iosdev33probes/s11_tests_build_and_run/t3.spm
    中间目录: artifacts
    中间目录: checkouts
    中间目录: x86_64-apple-macosx
    中间目录: repositories

=== 4) swift test 换成模拟器的 triple（本章的构建目标）
swift test 退出码 = 1
    /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/pkg/WeatherKit/Tests/WeatherKitTests/ForecastTests.swift:11:9: error: cannot find 'XCTAssertEqual' in scope
     9 | final class ForecastTests: XCTestCase {
    10 |     func testFahrenheitConversion() {
    11 |         XCTAssertEqual(fahrenheit(0), 32)
       |         `- error: cannot find 'XCTAssertEqual' in scope
    12 |         XCTAssertEqual(internalTag(), "internal-tag")
    13 |     }
    
探针退出码 = 0
```

### `s12_build_directory_inventory` —— 构建目录里到底生成了什么：module map、`.o`、`Modules/` 三份清单（§1、§10）

```
=== 1) 中间目录的第一层：谁有 .build、谁有 module.modulemap
CLIBrain                 modulemap=有  swiftmodule=没有  .o=1
ClimateCore              modulemap=有  swiftmodule=有  .o=1
WeatherKit               modulemap=有  swiftmodule=有  .o=3
WeatherKitPackageTests   modulemap=有  swiftmodule=没有  .o=0
WeatherKitTests          modulemap=没有  swiftmodule=没有  .o=0

--- 那两份 module.modulemap 各写了什么（umbrella 的路径是关键）
### CLIBrain.build
    module CLIBrain {
        umbrella header "/private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/pkg/WeatherKit/Sources/CLIBrain/include/CLIBrain.h"
        export *
    }
### ClimateCore.build
    module ClimateCore {
        header "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/spm/debug/WeatherKit/x86_64-apple-ios-simulator/debug/ClimateCore.build/ClimateCore-Swift.h"
        requires objc
    }
### WeatherKit.build
    module WeatherKit {
        header "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/spm/debug/WeatherKit/x86_64-apple-ios-simulator/debug/WeatherKit.build/WeatherKit-Swift.h"
        requires objc
    }
### WeatherKitPackageTests.build
    module WeatherKitPackageTests {
        header "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/spm/debug/WeatherKit/x86_64-apple-ios-simulator/debug/WeatherKitPackageTests.build/WeatherKitPackageTests-Swift.h"
        requires objc
    }

=== 2) .o 的分层：源码文件名 → 目标文件名
    CLIBrain.build/brain.c.o
    ClimateCore.build/Unit.swift.o
    WeatherKit.build/Forecast.swift.o
    WeatherKit.build/Resources.swift.o
    WeatherKit.build/resource_bundle_accessor.swift.o

=== 3) Modules/ 里一个模块其实有四份文件
    ClimateCore.abi.json
    ClimateCore.swiftdoc
    ClimateCore.swiftmodule
    ClimateCore.swiftsourceinfo
    WeatherKit.abi.json
    WeatherKit.swiftdoc
    WeatherKit.swiftmodule
    WeatherKit.swiftsourceinfo

--- .swiftmodule 里存的是什么（一句话：接口，不是代码）
    ..................+.B-.B)..(..+..*...B3
    ..
    . ...
    . 
    ..
    ..
    .I.
    .@
探针退出码 = 0
```

### `s13_bundle_module_two_candidates` —— `Bundle.module` 的两个候选路径 —— 一个只有本机才会命中的「假绿」（§17、§18、§22）

```
=== 生成的那个文件全文（十几行，两个候选路径都在里面）
    import Foundation
    
    extension Foundation.Bundle {
        static let module: Bundle = {
            let mainPath = Bundle.main.bundleURL.appendingPathComponent("WeatherKit_WeatherKit.bundle").path
            let buildPath = "/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s13_bundle_module_two_candidates/s13.spm/x86_64-apple-ios-simulator/debug/WeatherKit_WeatherKit.bundle"
    
            let preferredBundle = Bundle(path: mainPath)
    
            guard let bundle = preferredBundle ?? Bundle(path: buildPath) else {
                // Users can write a function called fatalError themselves, we should be resilient against that.
                Swift.fatalError("could not load resource bundle: from \(mainPath) or \(buildPath)")
            }
    
            return bundle
        }()
    }=== 旁边有 bundle —— 第一个候选命中
    退出码 = 0
    stdout: Bundle.module -> /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s13_bundle_module_two_candidates/withbundle/WeatherKit_WeatherKit.bundle
    stdout: Bundle.main   = /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s13_bundle_module_two_candidates/withbundle
    stdout: entries=city.json,token.txt cityJSON=city|:|Beijing|,|offset|:|8

=== 旁边**没有** bundle、构建目录还在 —— 第二个候选命中，这就是假绿
    退出码 = 0
    stdout: Bundle.module -> /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s13_bundle_module_two_candidates/s13.spm/x86_64-apple-ios-simulator/debug/WeatherKit_WeatherKit.bundle
    stdout: Bundle.main   = /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s13_bundle_module_two_candidates/nobundle
    stdout: entries=city.json,token.txt cityJSON=city|:|Beijing|,|offset|:|8

=== 再把构建目录里那份移走（等于换一台机器）
    退出码 = 132
    stderr: WeatherKit/resource_bundle_accessor.swift:12: Fatal error: could not load resource bundle: from /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s13_bundle_module_two_candidates/nobundle/WeatherKit_WeatherKit.bundle or /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s13_bundle_module_two_candidates/s13.spm/x86_64-apple-ios-simulator/debug/WeatherKit_WeatherKit.bundle
    stderr: Child process terminated with signal 4: Illegal instruction

=== 同样移走之后，旁边有 bundle 的那份还能跑
    退出码 = 0
    stdout: Bundle.module -> /var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s13_bundle_module_two_candidates/withbundle/WeatherKit_WeatherKit.bundle
    stdout: Bundle.main   = /private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev33probes/s13_bundle_module_two_candidates/withbundle
    stdout: entries=city.json,token.txt cityJSON=city|:|Beijing|,|offset|:|8

探针退出码 = 0
```

## 「跑起来没反应」排查表

这张表是本章 23 节 50 条断言加 26 支探针的用法说明：**症状 → 本机量到的真因 → 证据位置**。
左列尽量按书里（以及真机上会遇到的）说法写。凡写「静默」的行，意思是**退出码 0、stderr 为空**，
只有断言读得出来 —— 这类格子必须自己在代码里加账本（本章的四个身份常量就是干这个的）。

| 症状 | 本机量到的真因 | 证据 |
| --- | --- | --- |
| `import Alamofire` 报 `No such module` | 那个 `.swiftmodule` 的路径此刻不在 `-I` 里 —— 与「装没装」无关，与搜索路径有关 | §1、§2；探针 e01 |
| import 一个字没报，但库里的名字全都 `cannot find … in scope` | 撞上了 SDK 里的同名框架（本章是 `WeatherKit.framework`），编译器绑到了另一个模块 | §2；e07 与 e08 同一份源码的对照 |
| `#if canImport(WeatherKit)` 为真，就以为依赖接上了 | canImport 只回答「有没有一个能 import 的同名模块」 | §3；探针 r01（不给 -I 也能六条全过） |
| target 的 `dependencies:` 少写一行，编译链接运行全过 | 一趟构建里所有 target 的接口落在同一个 `Modules/`，`-I` 给的是那个目录 | §5；s09 第一、二、四、五格 |
| 反过来 `.package(path:)` 少写，报错还带一句 `Did you mean 'ClimateCore'?` | 失败在依赖图校验，不在拼写；那句提示与 manifest 里已写的**一模一样** | §5；s09 第三格 |
| `.product(package:)` 里填 `Package(name:)` → `unknown package` | 那里要填的是 **identity**，而 path 依赖的 identity 是目录名小写 | §4；s06、s07 |
| 资源明明在包的 `Resources/` 里，bundle 却没有它 | `resources:` 的基准是 **target 目录**；写错时只 warning，退出码 0 | §16；s03 第一格 |
| 两个目录里的同名资源，bundle 装不下两个 | 校验的是**末级名**，不是你写的那条路径：`multiple resources named 's.txt' in target 'Lib'`，红在 manifest 校验期、一个 `.o` 都不生成 | §16；s03 第四格（这次退出码 1） |
| `type 'Bundle' has no member 'module'` | `Bundle.module` 是 SwiftPM 按 `resources:` **生成**的，没声明就没有那个成员 | §18；s04 |
| `'module' is inaccessible due to 'internal' protection level` | 生成的那个 `static let` 没写访问级别 ⇒ internal ⇒ 只能在包内用 | §18；c02 |
| 资源在本机读得到、换台机器读不到（本机一切正常） | 生成的 accessor 有**两个**候选，第二个是编译期写死的构建目录绝对路径 | §22；s13 第二格（假绿） |
| `Fatal error: could not load resource bundle: from … or …`、退出码 132 | 两个候选同时消失；那句 fatal 把两条路径都印给你 | §22；s13 第三格 |
| `@testable import` 在 debug 能用、release 报 `not compiled for testing` | 它要的是被链接的那份模块带 instrumentation：debug 的构建描述里四个 target 都有 `-enable-testing`，release 只剩两个 test target | §7；e04、c03 |
| `swift build` 一路绿灯，产物却是 macOS 的 | 不给 `--triple/--sdk` 时默认目标就是主机；而主机二进制放进模拟器**照样跑** | 探针 s01 |
| `Invalid manifest` + `unable to load standard library for target 'x86_64-apple-macosx13.0'` | 环境里 export 了 `SDKROOT`：manifest 是主机程序，被塞了模拟器 sysroot | 「复现」一节；s02 第一格 |
| `unable to load standard library for target 'x86_64-apple-ios12.0-simulator'` | 只给了 `--triple`、没给 `--sdk` | s02 第三格 |
| 编译全过，链接报 `Undefined symbols … in Forecast.swift.o` | 少给一份 `.o`（第 3 类输入）——类型检查不看符号表 | §21；e09 |
| `import WeatherKit` 却报 `missing required module 'CLIBrain'` | 少给 C target 那份生成的 modulemap；红点画在**上层**那句 import 上 | §10；e02 |
| 上游打了新 tag，`swift build` 却没升级 | 锁钉住的是 revision/version，加 tag 不动锁；`swift package update` 才动 | §20；s08 第四、五格 |
| CI 删了 `Package.resolved` 后报 `a resolved file is required` | `--disable-automatic-resolution` 的反向要求 | §20；s08 第六格 |
| 找不着 path 依赖的 `Package.resolved` | fileSystem 依赖不写锁，状态在 `workspace-state.json` 里（`"kind" : "fileSystem"`） | §20；s07 最后一格 |
| 两个包各有一个同名 product，构建毫无动静 | product 名不参与全图唯一性检查 | §4；s05 读数 1~4 |
| 两个包各有一个同名 target，`error: multiple similar targets` | module 名必须全图唯一；报错直接给出 `moduleAliases` | §4；s05 读数 5 |
| `swift build --build-tests` 报 `cannot find 'XCTAssertEqual' in scope` | 本章的 triple 是模拟器，而命令行上的 XCTest 在宿主那套里；要用 `swift test`（它跑主机） | §7；s11 |

## 本章能带走的东西

- **「装好了」不是一个状态，是四类输入。** 一条 `-I`、一份 modulemap、一批 `.o`、一个 bundle
  目录 —— 这就是 §1 那张表，也是依赖管理器**唯一**在做的事。它不做的事同样值得记：
  不改访问级别（§6）、不传染 import（§8）、不替你选返回值类型（§14）、不替你选失败形状（§15）。
- **编译器没报错 ≠ 接上了你要的那个依赖。** 这是本章与前面所有章节不同的一条：撞名可以让
  一整条依赖链缺失而全程绿灯（§2 的 e07/e08、§3 的 r01）。所以本章的判据一律是「让只有包里
  才有的名字参与输出」（§23）。把这条推广开：**给依赖写断言时，先问这个名字在 SDK 里撞不撞车。**
- **构建系统那两层与语言那一层不互相担保**（§5 + §8）。忘写 target 依赖，构建系统不管；
  忘写 import，语言管到底。反过来说，显式依赖检查（`--explicit-target-dependency-import-check`
  那一族开关）在本机**给不出干净的答案**：单独开它一声不响，配上显式模块构建之后
  「写全了」和「漏写了」两份 manifest 报的是同一个错（s09 第六格 a/b/c）。
  所以别指望用工具开关补上纪律，那层的账只有断言读得出来。
- **名字是五个，不是一个**（§4 那张表）。product 名跟着 `name:`、target 名跟着 `name:`、
  module 名跟着 target 名、identity 跟着目录名小写、bundle 前缀跟着 `Package(name:)`。
  五个来源里只有一个（target/module 名）在全图上是硬约束，其余撞了都静默 —— 这就是为什么
  本章要在 §23 用四个身份常量各自签名，而不是靠编译器没报错。
- **版本有声明与钉住两层，而 path 依赖两层都没有**（§20）。原书那三行不带版本号的 `pod`
  恰好落在中间：它既没声明范围，也不告诉你钉在哪儿。本章的实测形状是：加 tag 不动锁、
  `update` 才动锁、`--disable-automatic-resolution` 要求锁必须在场，而 `.package(path:)`
  连 `Package.resolved` 都不生成。
- **资源跟着 target 走，不跟着 product 走**（§16~§19）。`.copy` 保留层级、`.process` 摊平；
  路径基准是 target 目录；bundle 名字由 `Package(name:)` 与 target 名拼出来；`Bundle.module`
  是生成出来的 internal 成员；它找 bundle 只有两个候选，其中一个是构建目录绝对路径 ——
  这四条在 Xcode 里全被自动化挡住了，在命令行上每一条都会咬一次。
- **本章的产物形态决定了三处「只有命令行会撞上」**：manifest 是主机程序（s02）、默认目标是
  主机（s01）、`@testable` 与配置有关（c03）、资源 bundle 的第二个候选路径（s13）。
  它们不是本仓库的怪癖，而是 Xcode 自动化替你挡住的那几件事 —— 知道它们存在，
  才能在 CI 脚本或 `xcodebuild -scheme` 的构建里认出同一个症状。
- **诚实处理边界**：本章覆盖的是「依赖怎么进工程」这一件事，网络那一半一条都没验证 ——
  书 10.2 的 API Key、10.6~10.8 的 HTTP 请求与异步回调全部归第 25 章与后续；
  `.package(url:from:)` 只用了**本地** git fixture（s08），真实网络解析、镜像（mirrors）、
  依赖冲突求解这三样本章没有证据。而 §4 那句报错里出现 `mirrors` 这个词，是本章离它们最近的一步。

---

上一章：[32 应用架构：MVC 三层里，状态到底住在谁的哪一次赋值里](32-app-architecture-mvc.md) · 下一章：[34 Core ML：一个 `.mlmodel` 的 46 个字节、一次断言、和一条走不通的摄像头路](34-core-ml.md)
