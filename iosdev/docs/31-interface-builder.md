# 31 · Interface Builder：故事板、XIB 与代码之间的接线 —— 把「拖一条线」量成运行时的一张表

> 示例：`examples/31_interface_builder/main.swift`（同级 `Main.storyboard`、`Nav.storyboard`、`Card.xib`、`Resources/`，以及 `probes/` 26 支探针 + `run.sh`）
> 实测输出见 `build/31_interface_builder/stdout.debug.txt`

《跟着项目学iOS应用开发：基于Swift 4》的第 2 章与第 4 章讲的是同一件事的两半。
**第 2 章**（Interface Builder 介绍）：2.1 用向导建工程、2.2 在故事板上摆控件、2.3 用
Pin/Size 面板定位元素、2.4 把图像素材拖进项目；**第 4 章**（掷骰子游戏）：4.2 按住 ctrl
从按钮拖一条线到代码里、4.3 用 IBOutlet/IBAction 调试、4.7 用属性数组换取出的图。
那两章的所有判据都是同一类：**看着 Xcode 的面板，跑起来看一眼**。连上线了，控件就显示；
没连上，运行时报一句 `this class is not key value coding-compliant for the key xxx.`；
图像选错了，屏上就是一块空白。

本教程的示例全部是命令行产物：`swiftc` 编一个**裸可执行文件**，`ibtool` 把界面文件编成
`.storyboardc` / `.nib`，然后 `xcrun simctl spawn` 在模拟器里跑一次，六条判定
（见 `run-all.sh` 头部与 `README.md`：编译日志为空、退出码 0、stderr 为空、stdout 非空、
无多余控制字符、结尾标记 `==== 31 结束 ====`，外加 debug(-Onone) 与 release(-O) 两份
stdout 逐字节一致）。所以「跑起来看一眼」在这里必须换成一句句能打印、能断言的话。

## 这一章的换法（每条都有实测支撑，逐节展开）

这一节的每一条都是「书里（或六年间的通用教程里）怎么说」对「本机 Swift 6.0.3 +
Xcode 16.2 + iOS 18.2 模拟器上实际是什么」。它们不是勘误表，正文里每一条都会展开成
完整的例子与真实输出：

- 书 2.1「Xcode 会替你生成 Main.storyboard 与 Info.plist 里的 `UIMainStoryboardFile`」：
  本章的产物目录里**没有 Info.plist**（bundle 是那个目录本身），所以
  `Bundle.main.bundleIdentifier` 是 `nil`，`infoDictionary` 是空的 —— 而故事板照样取得到，
  因为 `UIStoryboard(name:bundle:)` 找的是 `<名字>.storyboardc` 这个目录，跟工程设置无关（§1）；
- 书 2.2「一个故事板就是一个界面」：一份 `Main.storyboard` 编出来的其实是
  **每场景两个 nib**（控制器一条、视图一条），3 个场景 → 6 个 nib（§2）。
  「instantiate 之后 outlet 全是 nil」这件事的全部原因就藏在这条分裂里（§5/§11）；
- 书 2.2 画布上那个箭头（Is Initial View Controller）：没有它、又没有
  `storyboardIdentifier` 的场景，**ibtool 直接不生成它的 nib**，而且零诊断。
  本章把这条量成两半：主线里没标识符的不可达场景被删（§3），探针 b03/b04 抄了
  那条 warning 的原文与「删掉之后 nib 不见了」的对照；
- 书 4.2「把线拖到代码里，Xcode 会替你写 `@IBOutlet`」：这条线在运行时不是指针，
  是**一次 KVC 赋值**（`setValue:forKey:`）。所以「属性名写错」的下场不是静默给 nil，
  而是 `NSUnknownKeyException` 把进程带走（§12 讲机制，探针 r03 抄原文；
  与之相对，Inspector 里 `keyPath` 写错只往 stderr 打一句 `Failed to set (…) user defined
  inspected property on …`，进程 `rc=0` 跑完 —— 探针 r04）；
- 书 4.2「拖一条线到代码里，起个名字，就是一个 IBAction」：落到运行时的东西是
  控件表里的**一个字符串选择器** `"didTap:"`，冒号是名字的一部分（§15）。
  XML 里把它写成 `didTapp:` 时 ibtool 一声不响（探针 b09），真派发起来是
  `-[… didTapp:]: unrecognized selector sent to instance …`（探针 r07）；
- 「`@IBInspectable` 是故事板属性生效的前提」：**不成立**。它只决定 Xcode 的 Inspector
  给不给你那一格填；运行时起作用的是 KVC，一个都没标的 `SecondVC` 照样被填进
  `title`（§14）；
- 「unwind 那条线连在控件上，所以控制器的 `performSegue(withIdentifier:)` 查不到它」：
  **这句本章初稿也写过，是错的**。正规写法（`<exit>` 在场景的 `<objects>` 里）下，
  `performSegue(withIdentifier: "backToAlpha")` 查得到，prepare 与 unwind 方法按顺序跑完
  （§20 实测）。当初那句「查不到」的实底是 `<exit>` 被放错位置，导致整条连接根本没编出来
  —— 探针 b11 就是那份坏 XML，它读出来的按钮 target 列表是空数组，而 ibtool 仍然 `rc=0`、
  输出为空；
- 「XIB 就是小一号的故事板」：差得很远。XIB 的 `instantiate(withOwner:options:)` 交回来的是
  **顶层对象数组**，File's Owner 不在数组里（它是你交进去的那个对象），而且
  **owner 的 `awakeFromNib` 一次都不会跑** —— 那是 AppKit 的习惯（§21）；
- 「按 XIB 设计的尺寸把视图摆出来」：设计稿那格 `<rect>` 对顶层视图**根本不生效**。
  Card.xib 里顶层视图写的是 `0,0,280,120`，交回来是 `(0.0, 0.0, 600.0, 600.0)`；
  而同一份文件里两个子标签的 frame 逐格照搬。600×600 的来历是这份 XIB 没有
  `<device>` 元素 —— 探针 r13/r14 用一对只差那一行的 XIB 量出 414×896 与 600×600（§21/§23）；
- 「加了约束，frame 就会按约束走」：只看一个开关 —— `translatesAutoresizingMaskIntoConstraints`。
  它是 `true` 时（界面文件解出来的标签默认就是 `true`），XML 里那两条 `<constraints>`
  明明装着、`active`、常数也对，可布局一轮下来 frame 还停在设计值 `(24,120,200,44)`；
  把它改成 `false`，同一轮布局立刻给出 `(24.0, 100.0, 46.0, 28.66…)`（§23）；
- 「`UIImage(named:)` 不能带扩展名」：这台 iOS 上带扩展名照样取到（§24）。
  更值得记住的是另一条：`UIImage(contentsOfFile:)` 指着 `pip.png` 那份 4×4 的文件，
  拿回来的 `UIImage` 却是 12×12 像素、scale 3.0 —— 倍率替换发生在 UIKit 装载图片的地方，
  不是 `named:` 的专利（§24）；
- 「`sendActions(for:)` 会替你点一次按钮」：在裸可执行文件里**它一个都不派发**，
  因为派发走的是共享应用对象，而 `UIApplication.shared` 在这里就是 `nil`（§16）。
  故事板连的线和代码 `addTarget` 连的线在这一条上没有区别。手工把表里那句 `perform:`
  打出去才调得到（§16/§20）；
- 「故事板是界面文件的唯一选项」：本章末尾用**同一个界面的三条路**做对照
  （界面文件 / `loadView` 里手工装配 / SwiftUI 的 `body`），三条路的钩子、尺寸从哪来、
  什么时候才算出界面，各不相同。其中「纯代码 `view = UIView()` 的根视图是零框，
  真正被改成屏幕尺寸的一刻是挂进 UIWindow」这条是 §25 现测的。

## 本章的账本结构

```
产物   §1  Bundle.main：命令行可执行文件的 bundle 就是产物目录
产物   §2  一份 XML 编出几个 nib，以及那张「标识符 → nib 名」查找表
产物   §3  不可达的场景被 ibtool 无声删掉
取     §4  UIStoryboard(name:bundle:)
取     §5  instantiateInitialViewController()：awakeFromNib 已经跑完，outlet 还是 nil
取     §6  签名里的 __kindof：编译器为什么不帮你转成子类
绑定   §7  customClass / customModule / 模块名：三段字符串要对齐谁
绑定   §8  写错之后的下场：静默退回 plain UIViewController
绑定   §9  storyboardIdentifier 与 XML 的 id 是两回事
绑定   §10 被 relationship 收养的场景：查找表里少一项
时机   §11 连接的时机：instantiate 解控制器 nib，loadView 解视图 nib
时机   §12 连线连的是对象身份：约束也能连，机制是 KVC
时机   §13 creator 闭包：UIKit 把解码器交给你（iOS 13 起）
填值   §14 Inspector 里那几格：三种取值类型，@IBInspectable 到底管什么
连线   §15 @IBAction：运行时是控件表里的一个字符串选择器
连线   §16 sendActions(for:) 为什么在本章什么都不做
连线   §17 按钮直连 segue：target 是那条 segue 模板
转场   §18 performSegue(withIdentifier:sender:) 的完整时序
转场   §19 UIStoryboardSegue 对象：identifier / source / destination / perform()
转场   §20 unwind：往回跳的线、exit 占位对象与两条触发路径
XIB    §21 Card.xib → Card.nib：顶层对象数组与 File's Owner
XIB    §22 XIB 是配方不是单例；owner 交错的下场
尺寸   §23 设计值 <rect> 与运行时 frame：哪几格真生效
图像   §24 image="pip"、松散 PNG 与 @2x/@3x 查表
对照   §25 同一个界面的三条路：界面文件 / 代码装配 / SwiftUI 的 body
收尾   §26 第三次实例化，然后把数字分成「结构性」与「这台机器的」两堆
```

## 复现

```bash
cd iosdev
./run-all.sh 31_interface_builder          # 主线：编译两份配置 + 跑模拟器 + 逐字节比对
bash examples/31_interface_builder/probes/run.sh           # 全部探针
bash examples/31_interface_builder/probes/run.sh b03 r10   # 只跑编号匹配的
```

`probes/run.sh` 的三支族分工写在其头部注释里，本文末尾「探针记录」逐支抄了原文：

- `bNN_*` 坏界面文件 —— 主要量「ibtool 对这种写法说了什么」（绝大多数时候：什么都没说）；
  带同名 `.swift` 的还会把产物 instantiate 一次，量运行时到底拿到什么；
- `eNN_*` Swift 编译期诊断 —— 只看 `swiftc` 的输出，不运行；
- `rNN_*` 运行期现场 —— 编好放进模拟器跑，抄 stdout / stderr / 退出码 / 崩溃原文。

探针二进制的 `-module-name` 与主线一致（都是 `interface_builder`）。这不是顺手写的：
坏 XML 里的 `customModule` 写的也是它，否则「类名写错」和「模块名写错」两种失败会被
「探针自己的模块名不对」这一种噪声盖掉。另一个细节是每支探针的 `.swift` 都要先复制成
`main.swift` 才允许顶层语句 —— 直接 `swiftc b01_ghost_class.swift` 报的是
`expressions are not allowed at the top level`，那和 Interface Builder 无关。

---

## §1 命令行里的 Bundle.main：产物目录就是 bundle（书 2.1 的 .app 对照）

书 2.1 用 Xcode 向导建工程，产物是一个 `.app`：里面 `Info.plist` 写着
`UIMainStoryboardFile = Main`，界面文件在 `CFBundleResources` 下。本章的产物是一个
裸可执行文件，`run-all.sh` 把编译产物、`.storyboardc`、`.nib`、松散 PNG 全放进同一个
目录（`build/31_interface_builder/`），于是「bundle」这一概念退化成了「可执行文件所在的目录」：

```swift
let bundle = Bundle.main
line("     bundlePath = \(bundle.bundlePath)")
```

`Foundation` 里 `Bundle.main` 对裸可执行文件的定义就是「包含这个可执行文件的那个 bundle」，
而一个不在 `.app` 里的可执行文件，它的 bundle 就是它自己所在的目录。这一条是本章所有
`UIStoryboard(name: "Main", bundle: nil)` 能work的前提 —— `bundle: nil` 的意思正是
「拿 `Bundle.main`」（§4）。

```
== §1 命令行里的 Bundle.main：产物目录就是 bundle（本书 2.1 的 .app 对照） ==
  ok   Bundle.main.bundlePath 是一个真实存在的目录：/Volumes/mac004/code/programming/iosdev/build/31_interface_builder
  ok   裸可执行文件的 resourcePath 就等于 bundlePath（.app 里 resourcePath 是 Contents/Resources）：/Volumes/mac004/code/programming/iosdev/build/31_interface_builder
  ok   bundleIdentifier 是 nil：没有 Info.plist 就没有 bundle id —— 但这一条不会在什么地方打出日志来（本章判定 3 全程 stderr 0 字节）。§24 会量到：松散 PNG 的按名字查找照常成功，找不到时也只是返回 nil，没有一句"identifier (null)"之类的提示
  ok   infoDictionary 是空的：书 2.1 里 Xcode 替你写的那份 Info.plist，这里一份都没有
  ok   Bundle 能直接定位到编译好的故事板包：Main.storyboardc
  ok   XIB 编出来的 .nib 也在同一个目录：Card.nib
```

逐条展开：

- **`bundlePath` 是个真目录**。`FileManager.default.fileExists` 在这里为真，且
  `isDirectory` 也为真 —— 所以下面所有「按名字找资源」的调用都是在同一个平面上找文件；
- **`resourcePath == bundlePath`**。在 macOS 的 `.app` 里 `resourcePath` 是
  `Contents/Resources`，`.app` 结构在 iOS 上又被摊平过；裸可执行文件没有这一层，
  两个路径逐字相同。这条决定了 §24 里 `pip.png` 该放在哪；
- **`bundleIdentifier` 是 `nil`，而且无声**。这是本章最容易被误读的一条：很多人以为
  「没有 bundle id，UIKit 加载资源时会打一行警告」。实测全程 `stderr` 是 0 字节
  （判定 3），`§24` 里名字写错时也只是返回 `nil`，没有一句提示。
  「图标怎么是空的」这类问题在现场就是没有日志；
- **`infoDictionary` 是空的**。没有那份 Xcode 替你写的 `Info.plist`，所以
  `UIMainStoryboardFile` 这类键也不存在 —— 「app 启动时该加载哪份故事板」这件事在
  本章是**代码里显式写的**（`UIStoryboard(name: "Main", …)`），不是配置决定的；
- **`Main.storyboardc` 与 `Card.nib` 就在 `Bundle.main` 里**，用
  `bundle.url(forResource:withExtension:)` 直接取得到。前者是一个**目录**（包），
  后者是一个**文件**（§21 会用到这个差别）。

## §2 ibtool 做了什么：一份 XML 编出几个 nib

这是全章最该先量的一条，因为它解释了后面所有「时机」问题。`Main.storyboard` 有 3 个场景：

```xml
<document … initialViewController="ENT-01-001">
    <scenes>
        <scene sceneID="scEntry">
            <objects>
                <viewController id="ENT-01-001" sceneMemberID="viewController"
                                customClass="EntryVC" customModule="interface_builder">
                    <view key="view" … id="vEnt"> … </view>
                    …
                </viewController>
                <placeholder placeholderIdentifier="IBFirstResponder" …/>
            </objects>
            <point key="canvasLocation" x="0.0" y="0.0"/>
        </scene>
        …（SEC-02-002 带 storyboardIdentifier="TheSecond"、PLN-03-003 带 "PlainScreen"）
    </scenes>
```

`ibtool --compile` 之后，`Main.storyboardc/` 里面是这样：

```
  ok   包里有一份 Info.plist：它是「场景标识符 → nib 名」的查找表（§9 要用它做账）
  ok   Main.storyboard 的 3 个场景编出 6 个 nib：["ENT-01-001-view-vEnt.nib", "PLN-03-003-view-vPln.nib", "PlainScreen.nib", "SEC-02-002-view-vSec.nib", "TheSecond.nib", "UIViewController-ENT-01-001.nib"]
  ok   入口场景的控制器 nib 叫 UIViewController-ENT-01-001.nib —— 后半截就是 XML 里那个 id 属性
  ok   它的视图单独一个 nib：ENT-01-001-view-vEnt.nib，尾巴上的 vEnt 是 <view id="vEnt"> 的 id
  ok   有 storyboardIdentifier 的场景，nib 直接用那个标识符命名（TheSecond.nib）而不是 objectID
  ok   UIStoryboardDesignatedEntryPointIdentifier 记的就是 XML 里 initialViewController 指向的那个场景：UIViewController-ENT-01-001
  ok   查找表只有三项（3 个场景都在），键是 storyboardIdentifier（没有就退化成「类名-objectID」）：["PlainScreen", "TheSecond", "UIViewController-ENT-01-001"]
```

把这份名单读透，四件事就到手了：

1. **一个场景两条 nib**。`ENT-01-001` 这个场景被拆成
   `UIViewController-ENT-01-001.nib`（控制器对象图：控制器本身、`navigationItem`、
   `userDefinedRuntimeAttributes`）和 `ENT-01-001-view-vEnt.nib`（视图对象图：`<view>`
   及其 `<subviews>`、`<constraints>`）。§5/§11 那条「instantiate 之后 outlet 还是 nil」
   的时序，物理上就是这两条 nib 被解的时刻不同；
2. **命名规则由 `storyboardIdentifier` 决定**。入口场景没写标识符，控制器 nib 就叫
   `UIViewController-<objectID>.nib`；`SEC-02-002` 写了 `TheSecond`，于是它的控制器 nib
   直接叫 `TheSecond.nib`，视图 nib 仍按 `<objectID>-view-<viewID>.nib` 命名；
3. **`Info.plist` 里那张表是查找入口**。键是 `storyboardIdentifier`，没写的场景退化成
   「类名-objectID」；值就是上面那些 nib 名。§9 拿它证明「XML 的 `id` 不是可取的键」，
   §10 拿它证明「被 relationship 收养的场景不在表里」；
4. **入口点是记在 plist 里的**，不是靠运行时猜：`UIStoryboardDesignatedEntryPointIdentifier`
   的值就是 `initialViewController="ENT-01-001"` 指向的那一条。§5 的
   `instantiateInitialViewController()` 读的就是这一格；§3 的另一份故事板没有箭头，
   这一格就没有值，那个方法返回 `nil`。

## §3 不可达的场景会被 ibtool 无声删掉

`Main.storyboard` 的第三个场景 `PLN-03-003` 没有任何 `customClass`，也不是入口，
也没有任何 segue 连到它 —— 在 Xcode 的画布上它就是一块「孤立的原稿」。
它唯一的可取之处是写了 `storyboardIdentifier="PlainScreen"`：

```xml
<viewController id="PLN-03-003" sceneMemberID="viewController" storyboardIdentifier="PlainScreen">
```

正是这一格让它活到了产物里。主线量到的三行：

```
  ok   没有任何 customClass 的场景 → 就是 plain UIViewController：UIViewController
  ok   加了 storyboardIdentifier 之后它的两个 nib 才出现在包里：["PLN-03-003-view-vPln.nib", "PlainScreen.nib"]
  ok   刚取出来的场景视图还没加载：isViewLoaded = false
```

- 第一行是「没有 `customClass`」的后果：对象就是 `UIViewController` 本身，没有子类，
  也没有 outlet 可连（§7/§8 把这条量得更细）；
- 第二行才是本节要说的：包里有它的两条 nib，**仅仅因为**那一格标识符。
  「反过来说：把标识符去掉，两条 nib 一起消失」这一半不能在同一份产物里量（改了 XML
  就不是这一份了），所以交给探针 b04 —— 它抄的正是「删掉之后 nib 不见了」；
- 第三行留一句提醒：即使取到了，`isViewLoaded` 仍是 `false` —— 取对象这一步不碰视图
  nib（§11 展开）。这里用 `isViewLoaded` 而不是读 `plain.view`，因为 `view` 是
  get-only 且**一访问就触发 `loadView`**，那样会把 §5 要量的「取出来一个钩子都没跑」
  写坏成自己制造的现场。

这件事在 Xcode 画布上有对应的警告，本章把它交给探针 b03（原文照抄）：

```
/Volumes/…/probes/b03_unreachable_scene.storyboard:C-03-003: warning: “GhostC“ is unreachable because it has no entry points, and no identifier for runtime access via -[UIStoryboard instantiateViewControllerWithIdentifier:]. [9]
```

注意这条 warning 的**退出码是 0**，`--compile` 照样产出 `.storyboardc`：正文那句
「nib 不见了」指的是产物里面的内容，不是产物本身。这也是本章开头说「Interface Builder
的错误进不了主线」的原因 —— 判据 1（编译日志为空）在这种场景下反而是通过的。

## §4 加载故事板：`UIStoryboard(name:bundle:)`

书里从来没出现过这一行 —— 它是 Xcode 的启动流程替做的（读 `Info.plist` 的
`UIMainStoryboardFile`，由 `UIApplicationMain` 去取那份故事板）。手写就两个参数，
而这两个参数各有一个坑：

```swift
let sb = UIStoryboard(name: "Main", bundle: nil)
let sb2 = UIStoryboard(name: "Nav", bundle: nil)
```

```
== §4 加载故事板：UIStoryboard(name:bundle:) ==
  ok   bundle: nil 意思是「拿 Bundle.main」，类型就是 UIStoryboard
  ok   同一个 bundle 里可以有多份故事板，靠名字区分：Main 与 Nav 是两个对象
  ok   本章不演示那次崩溃：bundle 里确实没有 NoSuch.storyboardc，取它 = 抛异常（探针 r01）
```

- **`name` 不带扩展名**。给 `"Main"`，UIKit 找的是 `Main.storyboardc`（目录）。
  给 `"Main.storyboard"` 找的是同名包，产物里不存在；
- **`bundle: nil` 不是「没有 bundle」**，是「用 `Bundle.main`」。这就是 §1 那条前提被
  用上的地方：本章的 `Bundle.main` 是产物目录；
- **名字不存在时不是返回 `nil`，是抛 ObjC 异常**。这句话是本教程里必须写清的一条，
  因为 `UIStoryboard` 的 Swift 初始化器不返回可选值 —— 它没法返回 nil，只能抛。原文（探针 r01）：

```
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: 'Could not find a storyboard named 'NoSuchStoryboard' in bundle NSBundle </private/var/folders/…/iosdev31probes> (loaded)'
*** First throw call stack:
(
	0   CoreFoundation   0x00007ff8004d0569 __exceptionPreprocess + 242
	1   libobjc.A.dylib  0x00007ff800090116 objc_exception_throw + 62
	2   UIKitCore        0x00007ff8066e816b -[UIStoryboard name] + 0
	3   probe            0x000000010ea726bd $sSo12UIStoryboardC4name6bundleABSS_So8NSBundleCSgtcfCTO + 61
	4   probe            0x000000010ea721d4 main + 276
)
libc++abi: terminating due to uncaught exception of type NSException
Child process terminated with signal 6: Abort trap
```

  运行退出码 134（信号 6）。主线示例只断言「那个 `.storyboardc` 确实不存在」，
  不去碰那一下 —— 一次未捕获异常会把后面所有输出全带走，判定 2 与判定 3 同时红。

## §5 入口点：`instantiateInitialViewController()`，以及「取出来那一刻已经跑到哪一步」

书 2.2 说「故事板左边那个箭头指着的就是入口」。这一句在产物里是一格实实在在的键
（§2 读到的 `UIStoryboardDesignatedEntryPointIdentifier`），所以「没有箭头」不是玄学，
而是「那一格没值」。本章为这件事专门准备了一份 `NoEntry.storyboard`：`<document>`
元素上不写 `initialViewController`，里面一个场景带 `storyboardIdentifier="LonelyScreen"`：

```swift
hookLog.removeAll(keepingCapacity: true)
let entry = sb.instantiateInitialViewController()
```

```
== §5 入口点：instantiateInitialViewController() ==
  ok   instantiateInitialViewController() 给出入口场景的控制器：Optional("interface_builder.EntryVC")
  ok   取出来这一刻 awakeFromNib 已经跑完了：["awakeFromNib：badge=7.0 caption=\"故事板填进来的标题\" flagged=true titleLabel=nil"] —— 解「控制器 nib」就发生在 instantiate 里，不等视图加载
  ok   而且 Inspector 里那三格（§14）此时已经生效：awakeFromNib：badge=7.0 caption="故事板填进来的标题" flagged=true titleLabel=nil
  ok   可 outlet 此刻还是连不上：awakeFromNib：badge=7.0 caption="故事板填进来的标题" flagged=true titleLabel=nil —— 标签住在另一个 nib 里（§2 数的 6 个就是这么分的）
  ok   没有入口点的故事板也照样编出了产物，一个场景两条 nib：["LON-01-001-view-vLonely.nib", "LonelyScreen.nib"]
  ok   而 Info.plist 里就是没有那一格（对照 §2 读到的 UIViewController-ENT-01-001）：nil
  ok   所以 instantiateInitialViewController() 返回 nil，不抛异常：nil —— 箭头这件事在产物里就是一格可选的键，没有它就是没有
  ok   查找表里只有那一个场景，键是它的 storyboardIdentifier：["LonelyScreen"]
  ok   按标识符照样取得到，只是它没有 customClass，所以就是 plain UIViewController：UIViewController —— §8 那条「静默退回」在这里是合法行为
```

这一节的三条结论请分开记：

1. **`instantiate` 里已经跑完 `awakeFromNib`**。有人以为 `awakeFromNib` 是「视图加载时」
   跑的钩子，实测不是：控制器对象图（`UIViewController-ENT-01-001.nib`）在
   `instantiateInitialViewController()` 里面就被解完了，钩子随之跑完；
2. **Inspector 那几格也已经生效**。同一条日志里 `badge=7.0`、`caption="故事板填进来的标题"`、
   `flagged=true` 全都到位 —— `userDefinedRuntimeAttributes` 属于控制器 nib 的对象图，
   所以它跟控制器一起被解出来（§14 专门量这三格的类型）；
3. **可 outlet 全是 nil**。同一条日志里的 `titleLabel=nil` 就是这一条。标签住在
   **视图 nib** 里，那一条还没被解。这三条一起构成本章最重要的一张时序表，§11 把它跑完整。

后面四行是「没有箭头」那一侧的对照：产物照样编出来（两条 nib），`Info.plist` 里就是少了
那一格键，于是那句 `instantiateInitialViewController()` 返回 `nil` —— 注意这里
**没有异常**，和 §4 那句「名字不存在」的对待完全不同：名字错了是抛，入口没有是返回 nil。

## §6 签名里的 `__kindof`：为什么编译器不帮你转成子类

Objective-C 的声明是：

```objc
- (nullable __kindof UIViewController *)instantiateInitialViewController;
```

`__kindof` 是 Clang 的属性：它表示「返回的是 `UIViewController` 或它的某个子类」，
在 ObjC 里可以省一次显式转型。**Swift 的导入器不保留这个性质**，它塌回
`UIViewController?`。所以书里那种「拖完线就在代码里点 `vc.titleLabel`」的写法，
在 Swift 侧必须先自己 downcast：

```
== §6 签名里的 __kindof：为什么编译器不帮你转成子类 ==
  ok   静态类型是 UIViewController，动态类型才是真正的子类：Optional("interface_builder.EntryVC")
  ok   downcast 之后能写 .titleLabel 了，但此刻还是 nil —— 视图没加载，连接还没发生：nil
```

「静态类型 vs 动态类型」这一对在 §7 还要用一次（那里换成运行时类名的问法）。
拿不到子类成员这件事是编译期就拦的，`swiftc` 的原话由探针 e01 抄下：

```
/var/folders/…/iosdev31probes/main.swift:10:11: error: value of type 'UIViewController' has no member 'titleLabel'
/var/folders/…/iosdev31probes/main.swift:11:11: error: value of type 'UIViewController' has no member 'badge'
```

这条拦得越死越好 —— 它和 §8 那条「运行时静默退回」正好是两种保护力度：
一个在编译期（静态类型），一个根本没有（字符串绑定）。

## §7 类绑定的三段字符串：`customClass`、`customModule` 与模块名

XML 里只有两段：

```xml
<viewController id="ENT-01-001" sceneMemberID="viewController"
                customClass="EntryVC" customModule="interface_builder">
```

可运行时问的是**一个**名字：`"interface_builder.EntryVC"`。所以第三段其实是
`swiftc` 的 `-module-name` 给的 —— 本仓库的 `run-all.sh` 用
`-module-name "${目录名#*_}"`，`31_interface_builder` 削掉前缀就是 `interface_builder`。
三段拼错任何一段，运行时问的名字就不存在：

```
== §7 类绑定的三段字符串：customClass、customModule 与模块名 ==
  ok   绑定成功时 NSStringFromClass 给出的就是「模块名.类名」：interface_builder.EntryVC
  ok   String(reflecting:) 带模块前缀，和运行时同名：interface_builder.EntryVC
  ok   String(describing:) 只有类名，没有模块前缀 —— 拿它去比对 XML 里的 customClass 才对得上：EntryVC
  ok   NSClassFromString("interface_builder.EntryVC") 找得到 —— customModule 那一段是在问运行时
  ok   去掉模块前缀就找不到：NSClassFromString("EntryVC") = nil。所以 customModule 填错时 UIKit 不是「找错了类」，是「一个也没找到」
```

上面那段就是 `build/31_interface_builder/stdout.debug.txt` 里 §7 那一段的逐字引用 ——
文档里所有 `  ok ` 开头的行都不许改写，`tools/check_docs.py` 会把它们逐条比回快照。

三个打印类名的函数各是什么形状，这段值得单独记：

| 写法 | 本章的返回值 | 用在哪 |
|---|---|---|
| `NSStringFromClass(type(of: x))` | `interface_builder.EntryVC` | 运行时问的名字，与 XML 拼出来的那一个直接可比 |
| `String(reflecting: type(of: x))` | `interface_builder.EntryVC` | Swift 侧的完整名，含模块 |
| `String(describing: type(of: x))` | `EntryVC` | 只有类名 —— 要核对 XML 的 `customClass` 用它才对得上 |

最后一行是本章最容易自欺的地方：如果你把 `String(describing:)` 的输出拿去和
`customModule + "." + customClass` 比，它永远不等；如果你拿它去和 `customClass` 比，
它对了 —— 而**运行时真正查的那个名字是带模块前缀的那一个**。最后两行把这件事钉死：
`NSClassFromString("interface_builder.EntryVC")` 有值，
`NSClassFromString("EntryVC")` 是 `nil`。

所以「`customModule` 填错」的下场不是「加载了另一个模块的同名类」，而是
**一个也没找到**。找不到之后是什么？§8。

## §8 绑定写错之后：UIKit 一声不响地退回 plain `UIViewController`

这是书 4.3 那句「为什么我的 outlet 全是空的」的第一根因，也是本章开头那句
「Interface Builder 的错误是运行时的、而且是静默的」最干净的一个样本。
三种写错的样式（类名不存在 / 模块名不存在 / 两个属性都不写）由探针 b01、b02 各编一份产物、
各取一次对象，三条结论逐字抄在这里：

```
b01（customClass="GhostVC"，类不存在）
取到的对象运行时类名 = UIViewController
NSClassFromString("interface_builder.GhostVC") = nil
as? NSObject 之外的成员一律读不到：这个对象身上没有 badge 这个键 → setValue 的现场见 r03/r04

b02（customClass 存在、customModule="wrong_module_name"）
取到的对象运行时类名 = UIViewController
本模块里那个类的全名 = interface_builder.RealButWrongModuleVC
NSClassFromString("wrong_module_name.RealButWrongModuleVC") = nil
as? RealButWrongModuleVC = nil
```

而 ibtool 对这两份 XML 的态度是**退出码 0、输出为空**（两份都是）：

```
########## b01_ghost_class
ibtool（storyboard）退出码 = 0，产物 = b01_ghost_class.storyboardc
--- ibtool 输出 ---（空）
########## b02_wrong_module
ibtool（storyboard）退出码 = 0，产物 = b02_wrong_module.storyboardc
--- ibtool 输出 ---（空）
```

主线这边只跑安全的那一半 —— 用 §3 那个合法版本（没填 `customClass`）做等价的对照：

```
== §8 绑定写错之后：UIKit 一声不响地退回 plain UIViewController ==
  ok   「忘了填 customClass」和「填错了」在运行时是同一个结果：UIViewController
  ok   拿它当 EntryVC 用就是 nil —— 这正是书 4.3 那句「为什么我的 outlet 全是空的」的根因之一
```

请把这两行读成一句话：**「忘了填」与「填错了」在运行时不可区分**。
没有异常、没有日志、没有警告，只是你的那个子类永远拿不到，于是它身上所有
`@IBOutlet` 都是空的、所有 `@IBInspectable` 的属性都是类里写的默认值。
排查方向因此非常明确：先问运行时类名（`NSStringFromClass(type(of: vc))`），
再问 XML 的三段字符串，最后才去看连接本身。

## §9 `storyboardIdentifier` 与 XML 的 `id` 是两回事

同一个 `<viewController>` 元素上有两个看起来都是「名字」的属性：

```xml
<viewController id="SEC-02-002" sceneMemberID="viewController"
                customClass="SecondVC" customModule="interface_builder"
                storyboardIdentifier="TheSecond">
```

`id` 是 IB 对象图内部的编号（`<connections>` 里的 `destination="…"` 指的就是它，
nib 文件名里也是它）；只有 `storyboardIdentifier` 会进 `Info.plist` 那张查找表，
也就是只有它是运行时可以拿来 `instantiateViewController(withIdentifier:)` 的键：

```
== §9 storyboardIdentifier 与 XML 的 id 是两回事 ==
  ok   用 storyboardIdentifier 取：interface_builder.SecondVC
  ok   XML 里 SEC-02-002 那个 id 从来没进查找表：["PlainScreen", "TheSecond", "UIViewController-ENT-01-001"] 里没有它 —— 所以 it 不是一个「可以取的键」
  ok   进了表的是 storyboardIdentifier，而且键值同名字同 nib：mainMap["TheSecond"] = TheSecond
  ok   没写 storyboardIdentifier 的场景，查找表里的键就是它的 objectID（带 UIViewController- 前缀）：interface_builder.EntryVC
```

第 4 行有个容易被忽略的对称性：没写标识符的场景**并不是取不到**，它在表里的键就是
那个退化的名字 `UIViewController-ENT-01-001`（§2 说的命名规则在这儿第二次生效）。
主线用这个字符串取了一次，拿到的正是入口场景的 `EntryVC`。

拿 `id` 去取会怎样？抛异常，而且消息里明写着是「identifier」查不到（探针 r02）：

```
查找表键 = ["NamedScreen", "UIViewController-OI-02-020"]
用 storyboardIdentifier 取得到 = interface_builder.HostOI
再把 XML 里那个 id="OI-02-020" 当标识符用：
运行退出码 = 134
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: 'Storyboard (<UIStoryboard: 0x600002608600>) doesn't contain a view controller with identifier 'OI-02-020''
```

## §10 被 `relationship` 收养的场景：查找表里少一项

`Nav.storyboard` 有 4 个场景，其中导航控制器靠一条 `kind="relationship"` 的 segue 收养
Alpha 作为它的 `rootViewController`：

```xml
<navigationController id="NAV-10-010" sceneMemberID="viewController">
    <connections>
        <segue destination="A-11-011" kind="relationship" relationship="rootViewController" id="sgRoot"/>
    </connections>
</navigationController>
```

这条关系改变的是**产物结构**：

```
== §10 被 relationship 收养的场景：nav.storyboardc 的查找表少一项 ==
  ok   Nav 的 4 个场景编出 6 个 nib：["A-11-011-view-vA.nib", "B-12-012-view-vB.nib", "M-14-014-view-vM.nib", "UINavigationController-NAV-10-010.nib", "UIViewController-B-12-012.nib", "UIViewController-M-14-014.nib"]
  ok   Alpha 只有视图 nib、没有控制器 nib：视图 nib 在 = true，控制器 nib 在 = false
  ok   查找表只有 3 项，Alpha 不在里面：["UINavigationController-NAV-10-010", "UIViewController-B-12-012", "UIViewController-M-14-014"] —— 单独取不到，只能顺着关系走
  ok   但顺着关系走就能拿到它：nav.viewControllers[0] = interface_builder.AlphaVC，栈深 1
  ok   这条关系是真的接上了：子控制器的 navigationController 指回那个导航控制器
```

4 个场景却只有 6 条 nib（按 §2 的规则本该是 8 条），少的两条里的一条正是
`UIViewController-A-11-011.nib` —— **Alpha 的控制器对象被编码进了导航控制器那条 nib 里面**，
所以它既没有自己的控制器 nib，也不在查找表里。工程后果是那句
「`instantiateViewController(withIdentifier:)` 取不到 Alpha」：它不是 bug，
是这类场景唯一的取法（顺着 `viewControllers[0]` 走）。

第 1 行还有一处细节值得指出来：导航控制器那条 nib 的名字前缀是
`UINavigationController-` 而不是 `UIViewController-`（§9 说的「类名-objectID」退化规则，
这里类名就是容器自己的类名）。

顺带一条 XML 层面的观察：`Nav.storyboard` 末尾有
`<inferredMetricsTieBreakers><segue reference="sgShowB"/></inferredMetricsTieBreakers>`
—— 因为 Alpha 有两条 segue 指向同一个场景 `B-12-012`（`showB` 与 `customFade`），
ibtool 需要一个「用哪条的度量」的提示。它是 ibtool 自己维护的（画布上的行为），
运行时读不到任何对应物；主线 §19 分别按 identifier 走那两条 segue，量的就是这个提示
不影响选择。

## §11 连接的时机：`instantiate` 解控制器 nib，`loadView` 解视图 nib

书 4.2 拖完线就跑起来了，从来没说过「线是什么时候接上的」。把 §5 的两半
（`awakeFromNib` 已跑完 / outlet 还是 nil）和 §2 的两条 nib 对上，答案就是：
**连接发生在视图 nib 被解的那一刻，也就是 `loadView`**：

```
== §11 连接的时机：instantiate 解控制器 nib，loadView 解视图 nib ==
  ok   实例化只跑了一个钩子：["awakeFromNib：badge=7.0 caption=\"故事板填进来的标题\" flagged=true titleLabel=nil"]
  ok   刚实例化，outlet 全 nil：nil —— 控制器对象和它的视图是两条 nib、两次解码
  ok   loadViewIfNeeded() 只多了 viewDidLoad 这一个钩子：["awakeFromNib：badge=7.0 caption=\"故事板填进来的标题\" flagged=true titleLabel=nil", "viewDidLoad：titleLabel=欢迎 badge=7.0"]
  ok   到 viewDidLoad 里已经读得到值了，说明连接在这之前完成：viewDidLoad：titleLabel=欢迎 badge=7.0
  ok   同上，事后读也一样：titleLabel.text = 欢迎
  ok   按钮的连接也一样：currentTitle = 点我
  ok   viewWillAppear 没跑：["awakeFromNib：badge=7.0 caption=\"故事板填进来的标题\" flagged=true titleLabel=nil", "viewDidLoad：titleLabel=欢迎 badge=7.0"] —— 没有 window 就没有 Appearance 回调，这是 §16 那条边界的根
```

这张时序表请完整记住，本章后面有一半的节都建立在它上面：

| 时刻 | 跑了什么 | 值是什么 |
|---|---|---|
| `instantiateInitialViewController()` | 解控制器 nib → `awakeFromNib` | `badge/caption/flagged` 已到位；`titleLabel` 是 nil |
| `loadViewIfNeeded()` → `loadView` | 解视图 nib → **做连接** → `viewDidLoad` | `titleLabel.text` = 欢迎 |
| 挂进窗口、转场 | `viewWillAppear` 等 Appearance 回调 | 本章拿不到（最后一行） |

两个测量上的讲究：

- **钩子必须靠账本，不能靠人眼看顺序**。`EntryVC` 的 `awakeFromNib` / `viewDidLoad` 各自
  往全局 `hookLog` 里 append 一行，并把「这一刻属性里已经是什么」一起写进那行文本 ——
  于是「连接在 `viewDidLoad` 之前完成」这句话的证据就是同一行里的
  `titleLabel=欢迎`，不需要额外的断点或打印时机；
- **最后一行是一条边界，不是一条结论**。`viewWillAppear` 没跑不是因为故事板没配好，
  而是视图从没进过窗口。§16（事件派发）、§20（转场不弹栈）、§23（安全区全 0）、
  §25（SwiftUI 的 `body` 不算）量的都是同一个根的不同侧面。

## §12 连线连的是对象身份：约束也能连，而机制是 KVC

§11 把连接钉在了「视图 nib 被解的那一刻」，这一节问「接上」这两个字到底是什么物理量。
答案是：UIKit 拿 XML 里 `property=` 那个字符串，对 owner 做一次 **KVC 赋值**
（`setValue:forKey:`）。于是两件事直接跟着成立 —— 一、连上的不是副本，是同一个对象，
必须用 `===` 才问得出来；二、凡是能被 KVC 赋值的对象都能当 outlet，
不限于 `UIView`。**书 4.2 只连过标签和按钮**，本章连的是那条约束：

```xml
<constraints>
    <constraint firstItem="lblTitle" firstAttribute="leading" secondItem="saEnt" secondAttribute="leading" constant="24" id="cLead"/>
    <constraint firstItem="lblTitle" firstAttribute="top"   secondItem="saEnt" secondAttribute="top"    constant="100" id="cTop"/>
</constraints>
…
<outlet property="titleLeading" destination="cLead" id="olLead"/>
```

```swift
@IBOutlet var titleLeading: NSLayoutConstraint!   // 类里就是普通属性，KVC 不知道它是 outlet
```

```
== §12 连线连的是对象身份：约束也能连，而机制是 KVC ==
  ok   outlet 也可以连到 NSLayoutConstraint（书里只连过 UILabel/UIButton）：Optional(<NSLayoutConstraint:0x… UILabel:0x….leading == UILayoutGuide:0x…'UIViewSafeAreaLayoutGuide'.leading + 24   (active)>)
     根视图上一共有 6 条约束，逐条列出来：
     约束1  UILabel.leading ↔ UILayoutGuide.leading  常数 = 24.0
     约束2  UILabel.top ↔ UILayoutGuide.top  常数 = 100.0
     约束3  UIView.bottom ↔ UILayoutGuide.bottom  常数 = 0.0
     约束4  UILayoutGuide.left ↔ UIView.left  常数 = 0.0
     约束5  UIView.right ↔ UILayoutGuide.right  常数 = 0.0
     约束6  UILayoutGuide.top ↔ UIView.top  常数 = 0.0
  ok   根视图上此刻有 6 条约束：2 条来自 XML + 4 条是 UIKit 给 safeArea 布局指南补的
  ok   以这个标签为第一项的正好是 XML 里那 2 条（cLead、cTop）：2
  ok   XML 那 2 条的常数都不是 0：[24.0, 100.0]
  ok   另外 4 条常数全是 0，第一项都不是标签 —— 它们不是界面内容，是布局基础设施：["bottom", "left", "right", "top"]
  ok   outlet 拿到的就是层级里那一条本身，不是它的拷贝：=== 成立 = true
  ok   连着 safeArea 的约束装在公共祖先（根视图）上，不在标签自己身上：true
  ok   XML 里 constant="24" 原样进了运行时：constant = 24.0
  ok   value(forKey: "titleLabel") 与 .titleLabel 是同一个对象：true —— 所以属性名写错时 UIKit 不会「静默给 nil」，它是在问一个不存在的 key
```

这一节里有三条值得单独抄进笔记：

1. **6 条约束里只有 2 条是你写的**。另外 4 条常数全 0、第一项是根视图或布局指南 ——
   它们是 UIKit 把 `safeArea` 那个 `UILayoutGuide` 钉在视图四边上补出来的。
   书 2.3「定位元素」完全没有这一层，而它解释了「为什么我一条约束都没写，
   视图却不肯跟着窗口走」；分清「界面内容」与「布局基础设施」的判据就是这里的
   `firstItem` 与 `constant`；
2. **`===` 才是「连上了」的正确问法**。`cLead === sameObject`（层级里第一项是该标签、
   属性为 leading 的那一条）为 `true`，且 `viewConstraints.contains { $0 === cLead }`
   为 `true` —— 后者顺带回答了「约束装在谁身上」：连着 `safeArea` 的约束装在
   **公共祖先**（这里是根视图）上，不在标签自己身上；
3. **最后一行把「断线为什么抛异常」讲完了**。属性访问和
   `value(forKey: "titleLabel")` 拿到的是同一个对象，说明 `@IBOutlet` 在运行时
   就是普通存储属性、连接就是 `setValue:forKey:`。既然走的是 KVC，那么
   「类里没有这个属性」就不是「赋值对象找不到」，而是**问了一个不存在的 key** ——
   KVC 对这件事的规定动作是抛 `NSUnknownKeyException`。

两种「名字对不上」的下场不对称得很实用，主线都不重演（一个抛异常、一个只打 stderr，
都过不了六条判定），原文交给探针 r03 / r04：

```
r03（<outlet property="titleLabel"> 而类里没有这个属性）
stdout 只到这里：instantiate 过去了（控制器 nib 解完，连接还没开始）
运行退出码 = 134
*** Terminating app due to uncaught exception 'NSUnknownKeyException', reason: '[<interface_builder.HostNP 0x107105150> setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key noSuchProperty.'
    3   Foundation    -[NSObject(NSKeyValueCoding) setValue:forKey:] + 278
    4   UIKitCore     -[UIViewController setValue:forKey:] + 74
    5   UIKitCore     -[UIRuntimeOutletConnection connect] + 109
    7   UIKitCore     -[UINib instantiateWithOwner:options:] + 2163
    8   UIKitCore     -[UIViewController loadView] + 643
    9   UIKitCore     -[UIViewController loadViewIfRequired] + 337
   10   probe         main + 437
```

（探针是直接 `print` 的，没走主线那句地址脱敏，所以 `0x107105150` 这类数每跑一次都会变；
抄在这里是为了那句消息与栈的形状。栈里只留了编号 3–10 这几帧，
0/1/2/6/11 之后是 `__exceptionPreprocess`、`objc_exception_throw`、`-[NSException init]`、
`-[NSArray makeObjectsPerformSelector:]` 与 dyld。）

于是本章最有用的诊断学一句话可以背下来：
**崩了通常是连线（`<outlet>` 的 `property`），没崩但值还是代码里的默认值通常是
Inspector 里那一格（`keyPath`）。** 两句话里的 `this class is not key value
coding-compliant for the key …` 是同一段代码发的，区别只在有没有人把它接住。

r03 的栈里那几帧也值得看一眼：`-[UIRuntimeOutletConnection connect]` 在
`-[UINib instantiateWithOwner:options:]` 上面，而后者在 `-[UIViewController loadView]` 上面 ——
这就是 §11 那张时序表在崩溃现场的模样。顺带一提，
把 `@IBOutlet` 的类型从 `UILabel!` 改成 `UILabel?` 会怎样，是探针 r05 问的问题（原文见末尾）。

## §13 creator 闭包：UIKit 把解码器交给你，但你必须拿它去 `init`（iOS 13 起）

`instantiateInitialViewController` 还有第二个重载，Swift 签名是泛型的：

```swift
let madeB = sb.instantiateInitialViewController { (coder: NSCoder) -> EntryVC? in
    callCount += 1
    coderClass = NSStringFromClass(type(of: coder))
    return EntryVC(coder: coder)      // 必须是拿这台 coder 走过 super.init(coder:)
}
```

```
== §13 creator 闭包：UIKit 把解码器交给你，但你必须拿它去 init（iOS 13 起） ==
  ok   闭包在一次取对象的过程里只被调用一次：callCount = 1
     闭包收到的参数类型：UINibDecoder
  ok   UIKit 传进来的是 UINibDecoder —— 就是解 nib 用的那台解码器，探针 r06 那条崩溃栈里反复出现的也是它：UINibDecoder
  ok   交付物就是闭包返回的那个对象：Optional("interface_builder.EntryVC")
  ok   静态类型对了，但连接还没发生 —— outlet 此刻仍是 nil：nil
  ok   视图加载之后故事板的一切照常生效：titleLabel.text = 欢迎
  ok   Inspector 里那格也一样：badge = 7.0
     闭包取对象这一路跑过的钩子：["awakeFromNib：badge=7.0 caption=\"故事板填进来的标题\" flagged=true titleLabel=nil", "viewDidLoad：titleLabel=欢迎 badge=7.0"]
```

三点：

- **这不是「你想返回谁就返回谁」的钩子**。UIKit 把解这个场景用的那台解码器
  （`UINibDecoder`）交给你，并要求返回的对象是拿它走过 `super.init(coder:)` 的。
  直接 `return HostCR()` 的下场由探针 r06 抄下：

```
准备让闭包返回一个 plain HostCR()……
  闭包被调用，收到的 coder = UINibDecoder
运行退出码 = 134
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Custom instantiated view controller must call -[super initWithCoder:]'
	3   UIKitCore    -[UIClassSwapper initWithCoder:] + 998
	4   UIFoundation UINibDecoderDecodeObjectForValue + 711
	11  UIKitCore    -[UINib instantiateWithOwner:options:] + 1118
	12  UIKitCore    -[UIStoryboard __reallyInstantiateViewControllerWithIdentifier:creator:storyboardSegueTemplate:sender:] + 285
```

- **它顺手解决了 §6 那个 `__kindof` 问题**。这个方法是泛型的，闭包返回 `EntryVC?`
  就意味着 `madeB` 的**静态类型**是 `EntryVC?` —— 下一行直接写 `.titleLabel` 就过编译，
  不需要 `as?`。§6 抄的那句 `value of type 'UIViewController' has no member 'titleLabel'`
  在这里不会出现；
- **但它不改变时机**。第 4 行到第 6 行连着看：静态类型对了、outlet 还是 nil，
  `loadViewIfNeeded()` 之后值才到位，钩子账本和 §11 一字不差。
  这条闭包的真实用途是「换掉故事板对象图里的某一部分」（比如把一个依赖注进控制器），
  而不是整个绕开 nib —— 整个绕开请直接写代码，见 §25 三条路的对照。

## §14 Inspector 里那几格：三种取值类型，和「`@IBInspectable` 到底管什么」

Xcode 的 Utilities 面板（Attributes Inspector）里那些自定义的格子，落到 XML 是
`<userDefinedRuntimeAttributes>`。`EntryVC` 场景里有三格，`type` 各不一样：

```xml
<userDefinedRuntimeAttributes>
    <userDefinedRuntimeAttribute type="number" keyPath="badge">
        <real key="value" value="7"/>
    </userDefinedRuntimeAttribute>
    <userDefinedRuntimeAttribute type="string" keyPath="caption">
        <string key="value">故事板填进来的标题</string>
    </userDefinedRuntimeAttribute>
    <userDefinedRuntimeAttribute type="boolean" keyPath="flagged" value="YES"/>
</userDefinedRuntimeAttributes>
```

类里对应的是三个 `@IBInspectable` 属性（`badge: Double = 0` / `caption: String = ""` /
`flagged: Bool = false`），默认值全都不是 XML 里那个数，所以「值进来了」是可证的：

```
== §14 Inspector 里那几格：三种取值类型，和「@IBInspectable 到底管什么」 ==
  ok   number 那一格进来了：badge = 7.0
  ok   string 那一格进来了：caption = 故事板填进来的标题
  ok   boolean 那一格进来了：flagged = true
  ok   XML 的 number 落到 Swift 侧是 Double（不是 Int、不是 CGFloat）：Double
  ok   取到的确实是子类（动态类型；静态类型仍然要 §6 那样自己 downcast）：interface_builder.SecondVC
  ok   instantiate 那一刻：Inspector 填的 title 已经在了，视图里的标签还没连上 → Second.awakeFromNib：messageLabel=nil title="第二页的标题"
  ok   没标 @IBInspectable 的 title 也被填进来了：title = 第二页的标题
  ok   顺带确认这个场景的 outlet 也连上了：messageLabel.text = 第二页
  ok   loadView 之后两条钩子都在账本里，值的变化就是那两条 nib 的分界：["Second.awakeFromNib：messageLabel=nil title=\"第二页的标题\"", "Second.viewDidLoad：messageLabel=第二页 title=\"第二页的标题\""]
```

四条要点：

1. **`type="number"` 在 Swift 侧是 `Double`**，不是 `Int`、不是 `CGFloat`。
   所以属性声明成 `var badge: Int` 时，KVC 会去做数值转换，但你在 Inspector 里填
   `7.5` 会得到一个被截断的值 —— 本章的场景是 `Double`，所以 `7` 读回来是 `7.0`；
2. **`type` 的名字与取值子元素的名字是两件事**。这一点本章初稿写错过，实测改在这里：
   `type="number"` 配 `<integer key="value">` **完全合法**（探针 b05：ibtool 零诊断，
   运行时 `badge = 7.0`），因为取值子元素只是「用 XML 的类型转成一个对象」，
   转成 `NSNumber` 就够了。真正会崩的是**两者对不上** —— 探针 b10 把 `type` 写成
   `"string"` 却留着 `<real>`，ibtoold 抛 DVTAssertion、退出码 255：

```
ibtool（storyboard）退出码 = 255，产物 = b10_type_mismatch.storyboardc
2026-09-30 06:42:26.589 ibtoold[…:… ] [MT] DVTAssertions: ASSERTION FAILURE in IDEInterfaceBuilder/InterfaceBuilderKit/Document/Compiler/IBDocumentCompiler.m:79
Details:  Error: Failed to save document. UserInfo: {
    NSLocalizedDescription = "Failed to save document.";
    NSLocalizedFailureReason = "-[__NSCFNumber length]: unrecognized selector sent to instance 0x…";
}
Object:   <IBCocoaTouchStoryboardDocumentCompiler: 0x…>
Method:   -invokeWithIntermediateDocument:
（ibtool 没放行：没有产物可跑，探针到此为止）
```

   请注意这条崩溃的**消息内容**（`[__NSCFNumber length]`）与「字符串类型却有数字」
   这件事之间没有任何字面联系 —— 那是 ibtool 内部把 `NSNumber` 当 `NSString` 用而已。
   工具自己崩了，也不告诉你为什么。这类「XML 写错 → 编译器崩溃」的现场，
   在 Xcode 里表现为一句 `Command_ibtool_tool_… failed with a nonzero exit code`；
3. **`@IBInspectable` 只决定 Xcode 给不给你那一格填，运行时起作用的是 KVC**。
   证据在 `TheSecond` 场景里：`SecondVC` 一个 `@IBInspectable` 都没写，XML 却给它填了
   `keyPath="title"`，而 `title` 是 `UIViewController` 的属性，从来没人标过它 ——
   第 7 行 `没标 @IBInspectable 的 title 也被填进来了：title = 第二页的标题`。
   反过来的那一半（属性存在但没标）就是探针 r04 的场景：填得进去，只是 Xcode 里没有格子；
4. **第 6 行与第 9 行是 §11 那张时序表的第二次独立测量**。`title` 住在控制器 nib
   （所以 `awakeFromNib` 里已经有值），`messageLabel` 住在视图 nib（所以那一刻还是 nil，
   `viewDidLoad` 里才变成「第二页」）。同一趟 instantiate 里两个键的一有一无，
   比任何解释都直接。

## §15 `@IBAction`：那条「线」在运行时是控件表里的一个字符串选择器

书 4.2 的操作是「ctrl 按住从按钮拖到代码里，起个名字」。XML 里落地成三样东西：

```xml
<button … id="btnTap">
    <state key="normal" title="点我"/>
    <connections>
        <action selector="didTap:" destination="ENT-01-001" eventType="touchUpInside" id="actTap"/>
    </connections>
</button>
```

三段分别是**选择器名**、**目标**、**事件掩码**。这张表在运行时是可以读出来的 ——
这就是本章对「拖线到底拖出了什么」最直接的回答：

```
== §15 @IBAction：那条「线」在运行时是控件表里的一个字符串选择器 ==
  ok   没点之前 tapLog 是空的：[]
  ok   btnTap 的 target 只有一个，就是场景里的控制器：["interface_builder.EntryVC"]
  ok   而且是**同一个对象**，不是拷贝 —— XML 里 destination="ENT-01-001" 指的正是它：true
  ok   表里的动作是一个 Objective-C 选择器字符串：["didTap:"] —— 那个冒号是名字的一部分，代表「带一个参数」
  ok   控制器确实实现了 didTap:（responds(to:) 为真）—— 这就是「方法名改了一个字就断线」的那个检查点
  ok   少写那个冒号就是另一个选择器，运行时查不到：false
```

读表用的是 `UIControl` 自己的两句 API：

```swift
let tapTargets = Array(fresh.tapButton.allTargets)          // Set<AnyHashable>
fresh.tapButton.actions(forTarget: tapTargets.first, forControlEvent: .touchUpInside)
```

一个小坑先记下来：`allTargets` 的元素在 Swift 侧被 `AnyHashable` 包了一层，
直接打印类名会看到 `Swift.AnyHashable`，要取 `.base` 才是真正那个对象
（本章的 `targetNames(_:)` 就是干这件事的）。

三样齐了这条线才算通：表里有 target、表里有 selector、target 那侧
`responds(to:)` 为真。最后两行是这条检查点的正反面 ——
少写那个冒号就是**另一个选择器**，运行时查不到，而编译器与 ibtool 都不拦：

```
b09（XML 里写 selector="didTapp:"，类里实现的是 didTap:）
ibtool（storyboard）退出码 = 0
--- ibtool 输出 ---（空）
表里的 target 类名 = ["interface_builder.HostSL"]
touchUpInside 这一格的表 = ["didTapp:"]
类里实现的是 didTap:，两边各问一句 responds(to:)：
  responds(to: "didTapp:") = false
  responds(to: "didTap:") = true
写错的名字照样能进表、照样能被 SEL 构造出来 —— 这一步没人拦
```

上面那句「这一步没人拦」的下一站就是有派发者的场合怎么崩（探针 r07）：

```
表里的选择器名 = didTapp:，类里实现的是 didTap:
下面这一行就是 unrecognized selector 的现场：
运行退出码 = 134
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[interface_builder.HostSL didTapp:]: unrecognized selector sent to instance 0x…'
	6   probe        main + 3022
```

这一支的框架帧里没有 UIKit —— 因为探针是**手工**把那一句打出去的（`perform(_:with:)`），
这也正是 §16 的写法。

## §16 `sendActions(for:)` 为什么在本章什么都不做：没有 UIApplication 就没有派发

`UIControl` 有一句「照着表把这个事件打一遍」的公开 API：`sendActions(for:)`。
§15 读出来的那张表是完整的，可这一步在裸可执行文件里永远静默 —— 派发是走共享应用
对象的，而它在这里根本不存在：

```
== §16 sendActions(for:) 为什么在本章什么都不做：没有 UIApplication 就没有派发 ==
  ok   UIApplication.shared 在命令行可执行文件里就是 nil：nil
  ok   两条线都在这里，但 sendActions(for:) 一个都不派发：[] —— 故事板与代码在这一条上没有区别
  ok   手工派发就调用到了，说明前面那条静默不是断线：["didTap: 点我 sender就是那颗按钮=true"]
  ok   而且方法收到的 sender 就是那颗按钮本身，所以能当场问出它的标题：didTap: 点我 sender就是那颗按钮=true
  ok   事件掩码不匹配同样是零次调用（这一条在有派发者时才区分得开）：[]
```

第二条断言的对照设计是这一节的关键：主线**另外用代码**造了一颗按钮并 `addTarget`
连到同一个 `didTap:`：

```swift
let probeButton = UIButton(type: .system)
fresh.view.addSubview(probeButton)
probeButton.addTarget(fresh, action: NSSelectorFromString("didTap:"), for: .touchUpInside)
fresh.tapButton.sendActions(for: .touchUpInside)     // 故事板拖的那条
probeButton.sendActions(for: .touchUpInside)         // 代码 addTarget 的那条
```

两条都不动。**这就证明静默来自「没有派发者」，而不是来自 Interface Builder** ——
如果只量故事板那一条，这一节就什么都证不了。第三条是补救写法：
手工把 `(target, selector, sender)` 走一遍，

```swift
_ = fresh.perform(NSSelectorFromString("didTap:"), with: fresh.tapButton)
```

调用到了，而且 `sender === tapButton` 为真 —— 方法收到的就是那颗按钮本身。
最后一条留一句提醒：事件掩码不匹配（`.touchDown`）同样是零次调用，
所以「一次都没跑」这一条在 headless 里**区分不了**「表没连」与「事件不对」，
在有派发者的场合才区分得开。

这条边界决定了本章后面所有「触发」类断言的写法：能读表、能手递，就是不能靠手指。
§20（转场不弹栈）、§23（安全区全 0）、§25（SwiftUI 的 `body` 不算）都是它的同族。

## §17 按钮直连 segue：还是 target-action，但 target 是那条 segue 模板

`Main.storyboard` 里第二颗按钮 `btnSegue` 的 `<connections>` 只有一条 segue，没有任何
`<action>`：

```xml
<button … id="btnSegue">
    <state key="normal" title="去第二页"/>
    <connections>
        <segue destination="SEC-02-002" kind="show" identifier="byeButton" animates="NO" id="sgBtn"/>
    </connections>
</button>
```

在 Xcode 里它同样是「从按钮拖一条线出去」，看上去和 §15 一模一样。把表读出来才知道差别：

```
== §17 按钮直连 segue：还是 target-action，但 target 是那条 segue 模板 ==
     btnSegue 的 target 列表：["UIStoryboardShowSegueTemplate"]
     → 这个 target 在 touchUpInside 上的动作：["perform:"]
  ok   target 不是控制器，而是那条 segue 自己：["UIStoryboardShowSegueTemplate"] —— XML 里 kind="show" 直接写进了这个类名
  ok   对照 §15：那颗按钮的 target 是控制器本身，这颗的不是（as? EntryVC = nil）
  ok   选择器是 perform:，不是你写的某个方法：["perform:"]
     它的继承链：["UIStoryboardShowSegueTemplate", "UIStoryboardSegueTemplate", "NSObject"]
  ok   第 2 层就是 UIStoryboardSegueTemplate：["UIStoryboardShowSegueTemplate", "UIStoryboardSegueTemplate", "NSObject"] —— 换 kind 只换最下面那一层类名
  ok   注意链上并没有 UIStoryboardSegue：模板不是 segue 对象本身（segue 对象 §19 才出现）
```

- **同一个事件表，第三种 target**。§15 那颗按钮的 target 是控制器；这颗的 target 是
  `UIStoryboardShowSegueTemplate`，类名里就带着 XML 那句 `kind="show"`。
  选择器永远是 `perform:`；
- **「模板」是字面意思**。它的父类是 `UIStoryboardSegueTemplate`，链上没有
  `UIStoryboardSegue` —— 模板是「造 segue 的配方」，不是 segue 对象本身。
  继承链是问运行时问出来的（`superclassChain(of:)`：`object_getClass` + `class_getSuperclass`），
  这些私有类没有公开头文件，运行时是唯一入口；
- 所以「点这颗按钮」在运行时是一条完整的 target-action：派发 `perform:` 给模板 →
  模板造出 segue → 实例化目的地 → 回调 `prepare(for:sender:)` → `segue.perform()`。
  前半截在没有派发者时不会动（§16）；后半截在**没有容器**时的下场是探针 r08 的问题：

```
r08（kind="show" 的发起者没有父控制器、也没有被呈现）
parent = nil，navigationController = nil
performSegue(withIdentifier: "goX")（这条 segue 的 kind 是 show）：
之后：seen = ["prepare: goX → interface_builder.HostKX"]
presentedViewController = nil
运行退出码 = 0
--- stderr ---（空）
```

  也就是说：**没有容器时 `performSegue` 一声不响地跑完**，prepare 照跑、谁也不被呈现、
  不抛异常。而这份 XML 在 ibtool 那里也是零诊断（b08 的 ibtool 输出为空）。
  「点了按钮没反应」这一类问题，如果 `prepare` 里已经打到了日志，
  就基本可以确定是转场上下文的问题而不是连线的问题。

## §18 `performSegue(withIdentifier:sender:)` 的完整时序（Nav 场景，有容器）

Nav 那份故事板里 Alpha 是导航控制器的根，所以「有容器」这一半成立，整条链能量完：

```swift
let nav = navSB.instantiateInitialViewController() as! UINavigationController
let alpha = nav.viewControllers[0] as! AlphaVC      // §10：Alpha 只能这么取
alpha.loadViewIfNeeded()
alpha.performSegue(withIdentifier: "showB", sender: "手工给的 sender")
```

```
== §18 performSegue(withIdentifier:sender:) 的完整时序（Nav 场景，有容器） ==
     取整条导航栈时跑的钩子：["Alpha.awakeFromNib：navItem.title=\"第一层\""]
  ok   Alpha 是被导航控制器那条 nib 一起解出来的，它的 awakeFromNib 照样跑了一次：["Alpha.awakeFromNib：navItem.title=\"第一层\""]
  ok   而且连在 <navigationItem> 上的 outlet 这一刻已经有值了：Alpha.awakeFromNib：navItem.title="第一层" —— 对比 §11 的 titleLabel，那一个住在视图 nib 里
  ok   视图加载只多出 viewDidLoad 这一条：["Alpha.viewDidLoad：navItem.title=\"第一层\""]
     perform 之后的完整账本：["Alpha.prepare(showB)：目的地=interface_builder.BetaVC 目的地视图已加载=false sender=手工给的 sender"]
  ok   第一步是源控制器的 prepare(for:sender:)：Alpha.prepare(showB)：目的地=interface_builder.BetaVC 目的地视图已加载=false sender=手工给的 sender
  ok   进 prepare 时目的地的视图还没加载 —— 所以这一格里赋值才是安全的：Alpha.prepare(showB)：目的地=interface_builder.BetaVC 目的地视图已加载=false sender=手工给的 sender
  ok   performSegue 给什么 sender，prepare 就收到什么（走按钮时是那颗按钮，§17）：Alpha.prepare(showB)：目的地=interface_builder.BetaVC 目的地视图已加载=false sender=手工给的 sender
  ok   整条链跑完，目的地的 viewDidLoad 一次都没跑：["Alpha.prepare(showB)：目的地=interface_builder.BetaVC 目的地视图已加载=false sender=手工给的 sender"] —— 入栈只是改栈；视图要等导航控制器的视图进了窗口、转场真跑起来才加载
  ok   所以此刻 beta.isViewLoaded = false，它的 outlet 也还是 nil：nil
  ok   perform 结束时已经真的入栈了：栈深 2
  ok   栈顶换人了：Optional("interface_builder.BetaVC")
  ok   XML 里 <navigationItem title="第二层"> 落在 navigationItem 上：第二层
  ok   而 vc.title 是 nil：nil —— 场景顶上那个「Title」格（XML 里的 <title>场景上的名字</title>）既没进 vc.title 也没进 navigationItem
  ok   vc.title → navigationItem.title 是通的：代码里改的
  ok   反过来不通（只改了 navigationItem，vc.title 没跟着变）：代码里改的 —— 这就是「改了导航条标题却还在显示旧标题」那个 bug 的形状
```

这一节的信息量很密，逐条拆开：

1. **`awakeFromNib` 与「nib 住在谁家里」有关**。Alpha 的控制器对象在导航控制器那条 nib 里
   （§10），所以取整条栈时它就被一起解出来，钩子跑了一次。而它的
   `navItem`（`<outlet property="navItem" destination="niA"/>`，连的是
   `<navigationItem>` 元素——它是 `viewController` 元素的直接子对象，
   所以住在**控制器 nib** 里）这一刻已经有值。对比 §11 的 `titleLabel`（视图 nib），
   同一个「outlet 什么时候连上」的问题给出的是两个不同答案，差别只在对象在哪条 nib 里；
2. **`prepare` 里目的地的视图还没加载**（`目的地视图已加载=false`）。这就是
   书 4.2 那种「在 `prepare` 里给目的地赋值」的写法为什么安全的全部理由 ——
   此刻改的是控制器的存储属性，视图那边还没开始读它们。反过来说，
   在 `prepare` 里写 `segue.destination.view.backgroundColor = …` 会**当场触发**
   目的地的 `loadView`；
3. **`sender` 是原样传过去的**。`performSegue(…, sender: "手工给的 sender")` 里给什么，
   `prepare` 就收到什么；走按钮时（§17）收到的是那颗按钮对象。
   书 4.7「用数组换显示」那类「一个目的地场景服务多个来源」的写法就靠这一格；
4. **入栈不等于「显示」**。`perform` 结束时 `nav.viewControllers.count == 2`、栈顶换成
   `BetaVC`，可 `beta.isViewLoaded == false`、`markLabel == nil` —— 目的地的视图要等
   导航控制器的视图进了窗口、转场真跑起来才加载。这是本章「在栈里」与「在屏幕上」
   这对区分的第一次出现（§20 会把它推到极限）；
5. **最后四行是导航标题的方向性**。XML 里 `<navigationItem title="第二层">` 落在
   `navigationItem.title` 上；场景顶上那个「Title」格（`<title>场景上的名字</title>`）
   在这里既没进 `vc.title` 也没进 `navigationItem.title`。而代码里给 `vc.title` 赋值
   会带着 `navigationItem.title` 一起变，反过来只改 `navigationItem` 时 `vc.title`
   不动 —— 这条单向耦合就是「改了导航条标题却还在显示旧标题」那个 bug 的形状。

## §19 `UIStoryboardSegue` 对象：identifier / source / destination 与 `perform()`

`prepare` 收到的那个对象可以留到事后问（`AlphaVC` 里存了 `lastSegue`）：

```
== §19 UIStoryboardSegue 对象：identifier / source / destination 与 perform() ==
  ok   prepare 收到的那个 segue 对象可以留到事后问：UIStoryboardSegue
  ok   identifier 就是 XML 里那个属性：showB
  ok   source 是发起者的那个对象本身：interface_builder.AlphaVC
  ok   destination 就是被推进栈的那个对象（同一个，不是第二份）：interface_builder.BetaVC
     这个 segue 实例的继承链：["UIStoryboardSegue", "NSObject"]
  ok   kind="show" 造出来的 segue 对象本身就是 plain UIStoryboardSegue：["UIStoryboardSegue", "NSObject"] —— kind 只写进 §17 那个**模板**的类名，转场行为是模板配好的，不是 segue 子类的 perform()
  ok   自定义的这条路同样先走 prepare：Alpha.prepare(customFade)：目的地=interface_builder.BetaVC 目的地视图已加载=false sender=无
  ok   perform() 里就是我们自己的代码：FadeSegue.perform：interface_builder.AlphaVC → interface_builder.BetaVC
  ok   这一次 segue 对象的类就是 XML 里 customClass 写的那个：Optional("interface_builder.FadeSegue")
  ok   我们的 perform() 只记了一行账、没搬视图，所以栈深一点没变：2
```

`Nav.storyboard` 里那两条指向同一个场景的 segue 正好是一组对照：

```xml
<segue destination="B-12-012" kind="show"  identifier="showB"     id="sgShowB"/>
<segue destination="B-12-012" kind="custom" identifier="customFade"
       customClass="FadeSegue" customModule="interface_builder"   id="sgCustom"/>
```

- 第一条造出来的 segue 对象**就是 plain `UIStoryboardSegue`**（继承链只有两层）。
  这句话值得强调，因为一个常见误解是「`kind` 决定 segue 对象的类」——
  不。`kind` 决定的是 §17 那个**模板**的类名，转场行为由模板配好，
  `UIStoryboardSegue` 本身没有子类；
- 第二条的类才是 `customClass` 给的 `FadeSegue`，而它唯一要写的就是 `perform()`：

```swift
final class FadeSegue: UIStoryboardSegue {
    override func perform() {
        hookLog.append("FadeSegue.perform：\(String(reflecting: type(of: source))) → \(String(reflecting: type(of: destination)))")
    }
}
```

- 三行合起来就是「自定义转场」的全部接口面：UIKit 只负责造对象和调 `perform()`，
  剩下的都是你的。第 10 行（栈深没变）就是这句话的证据 —— 我们的 `perform()` 只记了一行账、
  没搬视图，所以什么都没发生。故事板里那条 `kind="custom"` 只是把一个类名写进了 XML，
  而这个类名的绑定规则与 §7 完全一致（`customClass` + `customModule` + 模块名三段对齐）。

## §20 unwind：往回跳的线、exit 占位对象与两条触发路径

书 4.4「返回到某个视图控制器」的那条线在 XML 里长这样（Beta 场景）：

```xml
<button … id="btnBack">
    <connections>
        <segue destination="EXIT-13-013" kind="unwind" identifier="backToAlpha" unwindAction="unwindToAlpha:" id="sgUnwind"/>
    </connections>
</button>
…
<placeholder placeholderIdentifier="IBFirstResponder" …/>
<exit id="EXIT-13-013" userLabel="Exit" sceneMemberID="exit"/>
```

`destination` 指的 `<exit>` 就是 Xcode 画布上那个「Exit」圆形图标，
动作名写在 `unwindAction` 属性上。这个 `<exit>` 元素的位置很要紧（它在 `<objects>`
**里面**），本节末尾会回到这件事。

```
== §20 unwind segue：往回跳的线连在控件上，destination 是一个 exit 占位对象 ==
     btnBack 的 target 列表：["UIStoryboardUnwindSegueTemplate"]
     → 它在 touchUpInside 上的动作：["perform:"]
  ok   §17 那张表的第三兄弟：kind="unwind" 把 target 换成 UIStoryboardUnwindSegueTemplate：["UIStoryboardUnwindSegueTemplate"]
  ok   选择器仍是 perform:，和直连 show 的那颗一模一样：["perform:"]
     它的继承链：["UIStoryboardUnwindSegueTemplate", "UIStoryboardSegueTemplate", "NSObject"]
  ok   它和 §17 那个模板同住一个父类，kind 换掉的只有最下面一层类名：["UIStoryboardUnwindSegueTemplate", "UIStoryboardSegueTemplate", "NSObject"]
     这个类自己声明的方法：[".cxx_destruct", "_legacyUnwindExecutorForTarget:", "_perform:", "_performWithDestinationViewController:sender:", "action", "encodeWithCoder:", "initWithCoder:", "instantiateOrFindDestinationViewControllerWithSender:", "newDefaultPerformHandlerForSegue:", "segueWithDestinationViewController:", "setAction:"]
  ok   unwindAction="unwindToAlpha:" 那格存进了模板自己的 action 属性（这一对 action / setAction: 就是它的存取器）：[".cxx_destruct", "_legacyUnwindExecutorForTarget:", "_perform:", "_performWithDestinationViewController:sender:", "action", "encodeWithCoder:", "initWithCoder:", "instantiateOrFindDestinationViewControllerWithSender:", "newDefaultPerformHandlerForSegue:", "segueWithDestinationViewController:", "setAction:"] —— 上层控制器身上没有留下任何「我是 unwind 目的地」的标记
  ok   而这个类自己声明的这个方法名，正是普通 segue 与 unwind 的分岔口：["instantiateOrFindDestinationViewControllerWithSender:"] —— 前半截是「造一个目的地」，unwind 走的是后半截「找到那个已经在栈里的」
     §17 那个 show 模板自己声明的方法：[".cxx_destruct", "action", "encodeWithCoder:", "initWithCoder:", "newDefaultPerformHandlerForSegue:", "setAction:"]
     只在 unwind 模板上出现的方法：["_legacyUnwindExecutorForTarget:", "_perform:", "_performWithDestinationViewController:sender:", "instantiateOrFindDestinationViewControllerWithSender:", "segueWithDestinationViewController:"]
  ok   unwind 独有的就是这一串：["_legacyUnwindExecutorForTarget:", "_perform:", "_performWithDestinationViewController:sender:", "instantiateOrFindDestinationViewControllerWithSender:", "segueWithDestinationViewController:"] —— destination 那个 <exit> 在编译期就不需要是一个控制器
  ok   上层这个 @IBAction 是 unwind 的全部落点：responds(to:) = true
  ok   发起方自己没有这个方法：responds(to:) = false —— 「unwind 到某个控制器」在 XML 里其实只写成「某个方法名」
```

「自己声明的方法清单」用的是 `class_copyMethodList`（不含父类继承来的），
把 show 模板与 unwind 模板各问一遍再取差集。这一步把两件事钉死了：
`unwindAction=` 那一格存进了**模板自己的** `action` 属性（`action` / `setAction:` 成对出现），
上层控制器身上没有任何「我是 unwind 目的地」的标记；
而 `instantiateOrFind**Destination**ViewControllerWithSender:` 这个方法名本身就是分岔口的名字——
前半截「造一个目的地」（普通 segue），后半截「找到那个已经在栈里的」（unwind）。

**触发路径一：控制器的 `performSegue(withIdentifier:)`**

```swift
beta.performSegue(withIdentifier: "backToAlpha", sender: beta.unwindButton)
```

```
     performSegue("backToAlpha") 之后的完整账本：["Beta.prepare(backToAlpha)：目的地=interface_builder.AlphaVC 目的地视图已加载=true sender=UIButton", "unwindToAlpha：sender.source=interface_builder.BetaVC sender.destination=interface_builder.AlphaVC"]
  ok   先经过的是**发起方**的 prepare：Beta.prepare(backToAlpha)：目的地=interface_builder.AlphaVC 目的地视图已加载=true sender=UIButton —— §18 那条流水线的顺序在 unwind 上一模一样
  ok   控制器的表里查得到这条 unwind 线，方法当场被调：unwindToAlpha：sender.source=interface_builder.BetaVC sender.destination=interface_builder.AlphaVC
  ok   整条路只有这两步（prepare 在发起方、动作在上层）：2 条 —— 中间没有「实例化目的地」那一步，destination 就是栈里那个 AlphaVC 本身
  ok   可栈还是没动：2 个，栈顶还是 interface_builder.BetaVC —— 「顺着栈找到目的地 + 调它的方法」是模板做的，「弹」是转场做的，后一半撞在 §16 那条边界上
```

这一组是本章改过的一处**错误说法**，值得完整记住。「那条线连在控件上，
所以控制器的 `performSegue(withIdentifier:)` 查不到它」——本章初稿就是这么写的，
实测是错的：查得到，`prepare`（**发起方**的）先跑，然后上层那个 `@IBAction` 被调到，
`segue.source` 是下层、`segue.destination` 是模板顺着栈**找到**的那个上层控制器，
中间没有「实例化目的地」这一步。

**触发路径二：绕过控制器，直接派发按钮表里那句 `perform:`**（§16 的写法）：

```
  ok   先按 §16 的老路试一次：sendActions(for:) 对这条线同样一声不响：[]
     手工派发 perform: 之后的完整账本：["Beta.prepare(backToAlpha)：目的地=interface_builder.AlphaVC 目的地视图已加载=true sender=UIButton", "unwindToAlpha：sender.source=interface_builder.BetaVC sender.destination=interface_builder.AlphaVC"]
  ok   Alpha 的 unwindToAlpha(_:) 被调到了：unwindToAlpha：sender.source=interface_builder.BetaVC sender.destination=interface_builder.AlphaVC
  ok   这条 segue 对象里 source 是发起方（下层）：unwindToAlpha：sender.source=interface_builder.BetaVC sender.destination=interface_builder.AlphaVC
  ok   destination 是模板顺着栈**找到**的那个上层控制器，不是 XML 里的 exit：unwindToAlpha：sender.source=interface_builder.BetaVC sender.destination=interface_builder.AlphaVC —— 「往回跳」在运行时仍然是 source→destination 这条方向
     派发之后：nav.isViewLoaded=true beta.isViewLoaded=true beta.view.superview=nil 栈深=2
  ok   方法调到了，栈却没动：现在 2 个，栈顶还是 interface_builder.BetaVC
  ok   这一格里有原因：Beta 的视图从没进过 nav 的视图层级（superview = nil），可它的控制器在栈里、视图也已经加载完 —— 「在栈里」和「在屏幕上」是两件事，而弹栈是转场那一步的事
     挂上窗口之后：nav.view.window 非空=false win.subviews.count=0 beta.view.superview=nil
  ok   挂不上：nav.view.window = nil，win.subviews.count = 0 —— 没有 UIApplicationMain 的运行循环，UIWindow 就只是一个普通 UIView，§11 那句「没有 window 就没有 Appearance 回调」、§16 那句「没有派发者」和这里是同一个根
     第二次派发之后的完整账本：["Beta.prepare(backToAlpha)：目的地=interface_builder.AlphaVC 目的地视图已加载=true sender=UIButton", "unwindToAlpha：sender.source=interface_builder.BetaVC sender.destination=interface_builder.AlphaVC"]
  ok   绕过控制器的派发走出的是同一条流水线（prepare 在先、动作在后）：["Beta.prepare(backToAlpha)：目的地=interface_builder.AlphaVC 目的地视图已加载=true sender=UIButton", "unwindToAlpha：sender.source=interface_builder.BetaVC sender.destination=interface_builder.AlphaVC"]
  ok   而且和上面那句 performSegue 的账本逐字相同：true —— 公开写法（控制器的 performSegue）与手工派发（模板那句 perform:）做的是同一件事，一条都没多、一条都没少
  ok   「弹」这一步在 headless 里就是拿不到：现在 2 个，栈顶 = interface_builder.BetaVC
  ok   nav.popToViewController(_:animated:) 一写就生效：现在 1 个，栈顶 = interface_builder.AlphaVC
  ok   被弹掉的 Beta 已经脱离了容器：navigationController = nil
```

三件事连着看：两条路的账本**逐字相同**（`hookLog == ledgerViaController` 为 `true`）；
「弹」这一步在 headless 里拿不到，`nav.view.window` 仍是 `nil`、
`UIWindow` 在这里就只是一个普通 `UIView`；而「弹」本身是可量的 ——
`nav.popToViewController(alpha, animated: false)` 一写就生效，
`beta.navigationController` 随之变成 `nil`。真实 app 里那条默认 unwind 替你做的正是这件事。

**最后回到那句被推翻的话**。当初「performSegue 查不到」也不是凭空写的，它有一次真实的
崩溃现场：`Receiver (<interface_builder.BetaUN: 0x…>) has no segue with identifier 'backToAlpha'`。
原因查下来是那份故事板把 `<exit>` 元素放在了 `</objects>` **外面**（还在 `<scene>` 里面，
XML 完全合法）。探针 b11 就是那份坏 XML：

```
########## b11_exit_outside_objects
ibtool（storyboard）退出码 = 0，产物 = b11_exit_outside_objects.storyboardc
--- ibtool 输出 ---（空）
运行退出码 = 0
按钮对象本身是好的：Optional("UIButton")
可它的 target 列表 = [] —— 一条动作都没有
对照：把同一个 <exit> 写进 <objects>（探针 r10），这里读出来就是 ["UIStoryboardUnwindSegueTemplate"] + ["perform:"]
按钮本身还在层级里（superview = UIView），outlet 也连上了 —— 丢的只是那一条 segue 连接
```

于是那句话的正确形状是：**「has no segue with identifier」说的是「这个控制器名下
没有这条 identifier 的模板」，而它不区分「模板本来该挂在控件上还是控制器上」**。
拿它当「unwind 天生不能用 `performSegue`」的证据是错的；
它真正的意思是**那条连接根本没编出来**（`<exit>` 位置错、或者 XML 里压根没写那条线）。
这也是本章「ibtool 对坏 XML 的态度」最典型的又一例：`rc=0`，输出为空。

## §21 XIB：`Card.xib` 编成 `Card.nib`，`instantiate(withOwner:options:)` 交回来的是「顶层对象」数组

书 2.5 与 4.5 用 XIB 的场景是「一个可复用的界面片段」，作者的做法是
`Bundle.main.loadNibNamed(...)` 之后从返回的数组里取第一个元素。这一节把那句话拆开量：
**返回的数组里装的是什么、`File's Owner` 去哪儿了、以及 owner 的 `awakeFromNib` 跑没跑**。

先看 `Card.xib` 的 `<objects>`，里面只有三样东西：

```xml
<objects>
    <placeholder placeholderIdentifier="IBFilesOwner" id="-1" userLabel="File's Owner"
                 customClass="CardOwner" customModule="interface_builder">
        <connections>
            <outlet property="titleLabel" destination="xTitle" id="xoTitle"/>
            <outlet property="rootView"   destination="xRoot"  id="xoRoot"/>
        </connections>
    </placeholder>
    <placeholder placeholderIdentifier="IBFirstResponder" id="-2" customClass="UIResponder"/>
    <view contentMode="scaleToFill" id="xRoot">
        <rect key="frame" x="0.0" y="0.0" width="280.0" height="120.0"/>
        <subviews>
            <label … id="xTitle" customClass="CardLabel" customModule="interface_builder">
                <rect key="frame" x="16.0" y="16.0" width="248.0" height="28.0"/> …
            <label … id="xSub">
                <rect key="frame" x="16.0" y="52.0" width="248.0" height="20.0"/> …
    </view>
</objects>
```

三个位置各有各的身份，这一节的每一条断言都落在这上面：

- `<placeholder … IBFilesOwner id="-1">` —— **File's Owner 是一个占位符，不是一个对象**。
  文件里只留下「外面要交进来一个 `CardOwner`」这句话（`customClass` / `customModule`
  还是 §7 那三段字符串），加上两条连在它身上的 `outlet`。它没有 `id` 可以被 instantiate 出来，
  因为它的 `id` 是固定的 `-1`，语义是「参数」。
- `<placeholder … IBFirstResponder id="-2">` —— 响应链的头，同样不会被解出来（§20 讲 unwind 时
  每个场景里都有它，这里不重复）。
- `<view id="xRoot">` —— **唯一一个真正的顶层对象**。它和它的 `<subviews>` 才是被编进 `.nib`
  里、等 instantiate 去解的那批对象。

编译这一步和故事板不同：`run-all.sh` 对 XIB 调的仍是 `ibtool`，但产物是**一个文件**
`Card.nib`，不是 §2 那种 `.storyboardc` 目录，也没有那张「标识符 → nib 名」的查找表 ——
一个 XIB 就一个名字。取它要用 `UINib`，而不是 `UIStoryboard`：

```swift
let cardUINib = UINib(nibName: "Card", bundle: nil)
let owner = CardOwner()                       // 这就是 XIB 里那个 customClass
let topLevel = cardUINib.instantiate(withOwner: owner, options: nil)   // 返回 [AnyObject]
```

```
== §21 XIB：Card.xib 编成 Card.nib，instantiate(withOwner:options:) 交回来的是「顶层对象」数组 ==
     §1 里那句 url(forResource:withExtension:) 取到的就是它：/Volumes/mac004/code/programming/iosdev/build/31_interface_builder/Card.nib
  ok   而且它是 bundle 根目录下的一个文件，不是包：Card.nib 的父目录 = 31_interface_builder
  ok   故事板那边是 UIStoryboard(name:bundle:)（§4），XIB 这边是 UINib(nibName:bundle:)：UINib —— bundle: nil 同样是 Bundle.main，名字既不带 .xib 也不带 .nib
     交回来的数组：["UIView"]
  ok   XIB 里只有 1 个顶层对象（那个 <view>），数组就 1 项：1 项 —— 故事板一次能交一整栈（§10），XIB 一次只交它自己的顶层对象
  ok   数组里没有 owner 自己：File's Owner 不是被解出来的对象，是你交进去的那个 interface_builder.CardOwner
  ok   两个 <label> 都在它的 subviews 里：["interface_builder.CardLabel", "UILabel"]
     两个子视图的 frame：["(16.0, 16.0, 248.0, 28.0)", "(16.0, 52.0, 248.0, 20.0)"]（XML 里那两格是 16,16,248,28 和 16,52,248,20）
     顶层视图的 frame = (0.0, 0.0, 600.0, 600.0)，translatesAutoresizingMaskIntoConstraints = true，它自己身上的约束数 = 0（XML 那格写的是 0,0,280,120）
  ok   子视图的 frame 逐格等于 XML 里那两格 <rect>：["(16.0, 16.0, 248.0, 28.0)", "(16.0, 52.0, 248.0, 20.0)"]
  ok   可顶层这一个不是：设计稿上的 280×120 没跟着出来，交回来的是 (0.0, 0.0, 600.0, 600.0) —— 「按 XIB 设计的尺寸把卡片摆出来」这件事在 iOS 上从来不是自动的（§23 清点这一格）
  ok   File's Owner 那两条 outlet 连的就是刚交出来的这个对象本身（§12 的「对象身份」在这儿同样成立）：=== 成立 = true
  ok   第二个 outlet 连的是里面的标签：卡片标题
  ok   而那个标签的类就是 XIB 里 customClass 写的那个：interface_builder.CardLabel —— §7 那三段字符串在 XIB 里同样要对齐
     这一次 instantiate 跑过的钩子：["CardLabel.awakeFromNib：text=\"卡片标题\""]，owner.awakeRan = false
  ok   被解出来的标签收到了 awakeFromNib：["CardLabel.awakeFromNib：text=\"卡片标题\""]
  ok   可 File's Owner 的一次都没跑：awakeRan = false，账本里也没有 CardOwner 那一条（["CardLabel.awakeFromNib：text=\"卡片标题\""]）—— UIKit 只把这条通知发给「从 nib 里解出来的对象」，owner 是外面交进来的，不在那个名单里。「在 File's Owner 的 awakeFromNib 里做初始化」是 AppKit 的习惯，搬到 iOS 就是静默失效
```

逐条展开：

1. **`Card.nib` 是 bundle 根目录下的一个文件**。§1 那句
   `Bundle.main.url(forResource: "Card", withExtension: "nib")` 取到它，父目录就是产物目录本身。
   和 `.storyboardc`（一个目录包）对照着记：故事板是「一个文件编出好几个 nib，靠查找表选」，
   XIB 是「一个文件编出一个 nib，名字就是它」。
2. **`UINib(nibName:bundle:)` 的 `bundle: nil` 与 §4 同义**（`Bundle.main`），
   名字既不带 `.xib` 也不带 `.nib` —— 传 `"Card"`，找的是 `Card.nib`。
   注意 `UIStoryboard` 与 `UINib` 是两个类型、两套 API，书里把它们混着讲，
   这里是分开的：`UIStoryboard` 面向「场景 + 查找表」，`UINib` 面向「一批顶层对象 + 一个 owner」。
3. **返回数组的项数 = `<objects>` 里真正的顶层对象数**，这里 1 项（`UIView`）。
   故事板一次能交一整栈（§10 那个 `instantiateInitialViewController()` 给出导航控制器，
   顺着 `relationship` 把 Alpha 也带出来），XIB 一次只交它自己的顶层对象 ——
   「XIB 是小一号的故事板」这句在返回形状上就不成立。
4. **owner 不在这个数组里**。`topLevel.contains { $0 === owner }` 为 `false`。
   这是最容易读错的一格：数组是「被解出来的对象」，owner 是「外面交进来的对象」，
   方向相反。所以 `loadNibNamed` 之后「拿数组最后一项当 owner」这类写法是误会。
5. **子视图的 frame 逐格照搬 XML**。`(16,16,248,28)` 与 `(16,52,248,20)` 两格，
   一个数字都没变。这两格属于下面 §23 的「情形二」。
6. **顶层视图那一格（`0,0,280,120`）根本没生效**，交回来的是 `(0.0, 0.0, 600.0, 600.0)`，
   而且它身上约束数 0、`translatesAutoresizingMaskIntoConstraints = true`。
   「600×600 从哪来」不是猜的，探针 r13/r14 是一对只差 `<device>` 那一行的 XIB：

   ```
   ########## r13_xib_with_device
   ibtool（xib）退出码 = 0，产物 = r13_xib_with_device.nib
   --- ibtool 输出 ---（空）
   --- swiftc 输出 ---（空）
   swiftc 退出码 = 0
   运行退出码 = 0
   --- stdout ---
   顶层对象 = ["UIView"]
   顶层视图的 frame = (0.0, 0.0, 414.0, 896.0)
   XML 里那一格写的是 600.0×600.0；UIScreen.main.bounds = (0.0, 0.0, 402.0, 874.0)
   titleLabel.text = 卡片标题，它的 frame = Optional((24.0, 24.0, 200.0, 30.0))
   --- stderr ---（空）

   ########## r14_xib_without_device
   ibtool（xib）退出码 = 0，产物 = r14_xib_without_device.nib
   --- ibtool 输出 ---（空）
   --- swiftc 输出 ---（空）
   swiftc 退出码 = 0
   运行退出码 = 0
   --- stdout ---
   顶层对象 = ["UIView"]
   顶层视图的 frame = (0.0, 0.0, 600.0, 600.0)
   XML 里那一格写的是 600.0×600.0；UIScreen.main.bounds = (0.0, 0.0, 402.0, 874.0)
   titleLabel.text = 卡片标题，它的 frame = Optional((24.0, 24.0, 200.0, 30.0))
   --- stderr ---（空）
   ```

   两份 XIB 的 `<rect key="frame">` 都写着 `600×600`：有 `<device id="retina6_1" …/>` 的那份
   交回来 `414×896`（那台设备的高），没有的那份交回来 `600×600`（按「没有目标设备」的
   默认画布盖章）。**`Card.xib` 正是没有 `<device>` 那一行**，所以它的顶层视图是 600×600，
   而 XML 里那 `280,120` 一格从头到尾没被读过 —— 「按 XIB 设计的尺寸摆出来」在 iOS 上
   从来不是自动的：要么给顶层视图加约束（并把 §23 那个 flag 关掉），要么自己 `frame =` 一遍。
7. **`File's Owner` 上那两条 outlet 连的就是刚交出来的对象本身** ——
   `owner.rootView === cardView` 成立，`===` 是对象身份而不是「长得一样」，
   和 §12 在故事板那侧量到的是同一件事；`owner.titleLabel?.text == "卡片标题"` 说明
   连接也做到了 `<subviews>` 里那一个（`destination="xTitle"`）。
8. **`customClass` 在 XIB 里同样要对齐三段字符串**：那个标签的动态类型是
   `interface_builder.CardLabel`。`CardLabel` 在这章存在的唯一理由就是下一格 ——
   它是个探针类：

   ```swift
   final class CardLabel: UILabel {
       override func awakeFromNib() {
           super.awakeFromNib()
           hookLog.append("CardLabel.awakeFromNib：text=\"\(text ?? "nil")\"")
       }
   }

   final class CardOwner: NSObject {
       @IBOutlet var rootView: UIView!
       @IBOutlet var titleLabel: UILabel!
       var awakeRan = false
       override func awakeFromNib() {
           super.awakeFromNib()
           awakeRan = true
           hookLog.append("CardOwner.awakeFromNib：rootView=\(rootView == nil ? "nil" : "已连上") titleLabel=\"\(titleLabel?.text ?? "nil")\"")
       }
   }
   ```

   账本里只有 `["CardLabel.awakeFromNib：…"]`，`owner.awakeRan` 是 `false`，
   连 `CardOwner.awakeFromNib` 那一条都没出现。
9. **`awakeFromNib` 只发给「从 nib 里解出来的对象」**。owner 是外面交进来的，不在那个名单里。
   这条对从 AppKit 转过来的人尤其反直觉 —— 在 Mac 上「把 File's Owner 的 `awakeFromNib`
   当初始化入口」是标准写法，搬到 iOS 就是**静默失效**：不报错、不告警、方法就是不被调。
   iOS 上 owner 该做的事写在别的钩子里（如果 owner 是视图控制器就写 `viewDidLoad`；
   像本章这样是个 plain `NSObject`，就自己调一个 `configure()`）。

## §22 XIB 是配方不是单例；owner 交错不是静默，是 §12 那句 KVC 异常

「一份 XIB 在运行时是不是只有一个 Card」——不是。`UINib` 对象可以复用，
但每 `instantiate` 一次就**重新解一遍 nib、重新造一套对象、重新做一遍连接**：

```swift
let owner2 = CardOwner()
let secondTop = cardUINib.instantiate(withOwner: owner2, options: nil)
let card2 = secondTop[0] as! UIView        // card2 !== cardView
```

```
== §22 XIB 是配方不是单例；owner 交错不是静默，是 §12 那句 KVC 异常 ==
  ok   第二次 instantiate 交回来的是另一个 UIView：!== 成立 = true —— 界面文件是配方，instantiate 才是生产
  ok   这一趟的连接落在这一趟的 owner 上：owner2.rootView === 刚交出来的视图 = true
  ok   §21 那一套也还原封不动在第一趟的 owner 手里：true —— 「当前 Card」这种全局状态并不存在，连接是每次各做一遍（§12）
  ok   第二趟整批重做：标签的 awakeFromNib 又跑了一次（["CardLabel.awakeFromNib：text=\"卡片标题\""]），owner2 的照旧不跑（awakeRan = false）—— 解 nib 不是「共享一份对象」，是每次从头解一遍
  ok   Bundle.main.loadNibNamed(_:owner:options:) 交回来的形状一样（可选数组，1 项）：1
  ok   第三个 owner 拿到第三个对象：三套彼此独立 = true/true/true
  ok   两条 outlet 同样是这一趟现做的：titleLabel.text = 卡片标题
  ok   shorthand 也是整批重解：这一趟的钩子账本 ["CardLabel.awakeFromNib：text=\"卡片标题\""]
  ok   options: [:] 与 options: nil 一样出 1 个顶层对象：1
```

- **界面文件是配方，`instantiate` 才是生产**。第二次的 `card2` 与第一次的 `cardView` 不是同一个对象，
  而两趟的连接各归各的 owner（`owner2.rootView === card2` 且 `owner.rootView === cardView` 同时成立）。
  「`File's Owner` 指向当前那个 Card」这种全局状态并不存在 —— 这跟 §12 那句
  「连接是一次 KVC 赋值，写在**你交进去的那个对象**上」是同一个机制的两面。
- **第二趟整批重做**：`CardLabel.awakeFromNib` 又跑了一次（说明对象真的重新解码过，
  不是共享），`owner2.awakeRan` 照旧 `false`（§21 那条对每一趟都成立）。
- **书里那句 `Bundle.main.loadNibNamed("Card", owner: owner3, options: nil)` 走的是同一条路**，
  只是把「先建一个 `UINib`」这一步省进字符串参数里，返回值也从 `[AnyObject]` 变成
  `[AnyObject]?`（所以取值要 `viaBundle?[0]`）。第三个 owner 拿到第三个对象，
  三套彼此独立；钩子账本同样整批重跑。
- **`options` 那一格传 `[:]` 与传 `nil` 在这一份 XIB 里等价**（都是 1 个顶层对象）。
  它是留给外部参数与本地化的通道（例如 `UINibInstantiateOptions` 那类键），
  本章的 XIB 没用到，所以不必为它设计代码。

**owner 传错会怎样？** 常见猜想是「连接静默落空，outlet 保持 nil」。实测正相反：
UIKit 会在 `owner` 为 `nil` 时拿一个 plain `NSObject` 顶替 File's Owner，然后照 §12 那条 KVC
去 `setValue:forKey:"rootView"`，当场抛 `NSUnknownKeyException`。两支探针各抄一句原文：

```
########## r11_owner_nil
ibtool（xib）退出码 = 0，产物 = r11_owner_nil.nib
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 134
--- stdout ---
先按正规用法跑一次：顶层对象 = ["UIView"]，owner.rootView = Optional(<UIView: 0x108006510; frame = (0 0; 414 896); autoresize = RM+BM; backgroundColor = UIExtendedSRGBColorSpace 1 1 1 1; layer = <CALayer: 0x60000020a540>>)
再把 owner 换成 nil：
--- stderr ---
*** Terminating app due to uncaught exception 'NSUnknownKeyException', reason: '[<NSObject 0x600000020010> setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key rootView.'
*** First throw call stack:
(
	0   CoreFoundation                      0x00007ff8004d0569 __exceptionPreprocess + 242
	1   libobjc.A.dylib                     0x00007ff800090116 objc_exception_throw + 62
	2   CoreFoundation                      0x00007ff8004d0059 -[NSException init] + 0
	3   Foundation                          0x00007ff800f3783f -[NSObject(NSKeyValueCoding) setValue:forKey:] + 278
	4   UIKitCore                           0x00007ff805f25aac -[UIRuntimeOutletConnection connect] + 109
	5   CoreFoundation                      0x00007ff8004bd54f -[NSArray makeObjectsPerformSelector:] + 240
	6   UIKitCore                           0x00007ff805f14ce4 -[UINib instantiateWithOwner:options:] + 2163
	7   probe                               0x0000000106aa6fcd main + 1549
	8   dyld                                0x0000000106f02478 start_sim + 10
	9   ???                                 0x0000000112101345 0x0 + 4598010693
)
libc++abi: terminating due to uncaught exception of type NSException
Child process terminated with signal 6: Abort trap

########## r12_owner_wrong_type
ibtool（xib）退出码 = 0，产物 = r12_owner_wrong_type.nib
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 134
--- stdout ---
owner = NSObject()：
--- stderr ---
*** Terminating app due to uncaught exception 'NSUnknownKeyException', reason: '[<NSObject 0x600000004080> setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key rootView.'
*** First throw call stack:
(
	0   CoreFoundation                      0x00007ff8004d0569 __exceptionPreprocess + 242
	1   libobjc.A.dylib                     0x00007ff800090116 objc_exception_throw + 62
	2   CoreFoundation                      0x00007ff8004d0059 -[NSException init] + 0
	3   Foundation                          0x00007ff800f3783f -[NSObject(NSKeyValueCoding) setValue:forKey:] + 278
	4   UIKitCore                           0x00007ff805f25aac -[UIRuntimeOutletConnection connect] + 109
	5   CoreFoundation                      0x00007ff8004bd54f -[NSArray makeObjectsPerformSelector:] + 240
	6   UIKitCore                           0x00007ff805f14ce4 -[UINib instantiateWithOwner:options:] + 2163
	7   probe                               0x000000010fbe4abb main + 347
	8   dyld                                0x0000000110002478 start_sim + 10
	9   ???                                 0x00000001147ea345 0x0 + 4638810949
)
libc++abi: terminating due to uncaught exception of type NSException
Child process terminated with signal 6: Abort trap
```

（两支探针的栈同形：帧 3 `-[NSObject(NSKeyValueCoding) setValue:forKey:]`、
帧 4 `-[UIRuntimeOutletConnection connect]`、帧 6 `-[UINib instantiateWithOwner:options:]`。
地址每进程重新分配，`run.sh` 里那一次留档就是那一份。）

三点值得记住：

1. **owner 交错不是「静默」，是崩**。和 §12 在故事板那侧的 r03 是同一句话，
   差别只在栈里没有 `-[UIViewController setValue:forKey:]` 那一帧（这里 owner 不是控制器）。
   也就是说：**连接问的是 key，不是类型声明** —— 交一个 `NSObject()` 进去，
   UIKit 不会先看「类型对不对」，它直接问 `setRootView:` 这个 key 存不存在。
2. **r11 那行正规用法里能顺带看到 §23 的另一半**：`frame = (0 0; 414 896)`、
   `autoresize = RM+BM`。这份探针 XIB 有 `<device>` 元素，所以顶层视图跟着那台设备的高；
   `RM+BM` 就是 `flexibleRightMargin|flexibleBottomMargin`（§23 情形二那个 36）。
3. **主线不重演这两次崩溃**。一次未捕获异常会把 §23 之后的所有输出带走：本章最初就是这么死的
   —— `rc=134`、stderr 1266 字节，六条判定里的第 2 条（退出码 0）和第 3 条（stderr 为空）同时红。
   这正是探针目录存在的理由：把「有声音的失败」留在 `probes/`，主线只留可断言的测量。

## §23 设计值 `<rect key="frame">` 与运行时 frame：界面文件里那些尺寸有几格真生效

书 2.2 在画布上摆控件时，每个控件旁边都写着一个小框的坐标；2.3 用 Pin/Size 面板加约束。
这两套数字在 XML 里是**并排写着**的：

```xml
<label … id="lblTitle">
    <rect key="frame" x="24.0" y="120.0" width="200.0" height="44.0"/>      ← 设计值
    <autoresizingMask key="autoresizingMask" flexibleMaxX="YES" flexibleMaxY="YES"/>
…
<constraints>
    <constraint firstItem="lblTitle" firstAttribute="leading" secondItem="saEnt" secondAttribute="leading" constant="24" id="cLead"/>
    <constraint firstItem="lblTitle" firstAttribute="top"    secondItem="saEnt" secondAttribute="top"    constant="100" id="cTop"/>
</constraints>
```

于是「运行时到底听谁的」必须分三种情形量，混在一起说就会得出错的结论。

```
== §23 设计值 <rect key="frame"> 与运行时 frame：界面文件里那些尺寸有几格真生效 ==
     UIScreen.main.bounds = (0.0, 0.0, 402.0, 874.0)，scale = 3.0
  ok   运行时它等于屏幕，不是设计画布：frame = (0.0, 0.0, 402.0, 874.0)，XML 那格是 414×896 —— 加载视图控制器时 UIKit 按屏幕把它重摆了一次
  ok   可 XML 那行 <autoresizingMask widthSizable="YES" heightSizable="YES"> 原样进了运行时：UIViewAutoresizing(rawValue: 18)（rawValue = 18，也就是 2|16）
  ok   逐格照搬：[(16.0, 16.0, 248.0, 28.0), (16.0, 52.0, 248.0, 20.0)] —— 顶层那一个被换成 600×600，子视图这一格却完完整整跟着对象出来
  ok   两个标签的 <autoresizingMask flexibleMaxX="YES" flexibleMaxY="YES"> 也在：[36, 36]（4|32 = 36：右边距与下边距可伸缩，位置与尺寸固定）
  ok   父视图从 320 加宽到 600、再布局一遍，标签一点没动：卡片宽 = 600.0，标签宽还是 [248.0, 248.0] —— 多出来的宽度全落进它们右边那条可伸缩边距里，这就是书里那几张 Struts 图在运行时的样子
  ok   而卡片自己一条约束都没有（0 条），TAMIC 还是 true —— 它靠 autoresizing 活着；§12 那种约束型的界面文件是另一套机制
     fresh.view.safeAreaInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
  ok   安全区在这一章是全 0：UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0) —— 视图从没进过窗口（§11、§20 同一条边界），所以 UIKit 给 safeArea 加的那 4 条约束把布局指南摆成了整个视图
  ok   跑一次布局，标签仍然停在设计值上：Optional((24.0, 120.0, 200.0, 44.0)) —— XML 里 <constraints> 那两条此刻什么都没做
  ok   可那两条约束是真装着的：Optional("constant=24.0 active=true") —— 不是「没编进来」，是这个标签不归引擎管
  ok   关键就在这一格：Optional(true) —— 它为「维持原 frame」自动生成一组约束，于是设计值和 <constraints> 各说各话，运行时看到的是设计值
     把这一格改成 false 之后立刻重布局：frame = (24.0, 100.0, 46.0, 28.666666666666668)，intrinsicContentSize = (46.0, 28.666666666666668)
  ok   引擎一句话就把标签挪到约束说的那个位置：x = 24.0（leading 24）、y = 100.0（top 100）—— 那两条 <constraints> 一直都在，只是没人听它
  ok   尺寸也换成了内容自己报的那个：(46.0, 28.666666666666668)，不再是设计那格的 200×44 —— 「约束明明加了，frame 却还是设计稿那一格」这个 bug 就出在这一个 flag 上
  ok   纯代码那四条约束算出来的 frame：(24.0, 100.0, 120.0, 40.0) —— 没有窗口也一样算
  ok   additionalSafeAreaInsets.top = 50 之后指南纹丝不动：(0.0, 0.0, 402.0, 874.0) —— 安全区归容器与窗口管，视图不在窗口里就轮不到它
```

### 情形一：控制器的根视图 —— 那一格被屏幕值覆盖

`Main.storyboard` 里入口场景的 `<view id="vEnt">` 写的是 `0,0,414,896`（Xcode 画布的
设计设备尺寸），运行时 `fresh.view.frame` 是 `(0.0, 0.0, 402.0, 874.0)` —— 本机
`UIScreen.main.bounds`。所以**根视图那一格从来不是承诺，只是画布上看到的样子**；
被覆盖发生在「加载视图控制器」那一步。同一段 XML 里的
`<autoresizingMask widthSizable="YES" heightSizable="YES">` 却是原样进运行时的
（`UIViewAutoresizing(rawValue: 18)`，`18 = 2|16 = flexibleWidth|flexibleHeight`），
这解释了为什么之后窗口尺寸再变它也跟着变。§25 会把「谁盖的章」量得更精确：
不是加载视图，而是根视图被放进 `UIWindow` 的那一刻。

### 情形二：XIB 里的子视图 —— 那一格逐格生效

两个 `<label>` 的 frame 完全等于 `16,16,248,28` 与 `16,52,248,20`；它们的
`<autoresizingMask flexibleMaxX="YES" flexibleMaxY="YES">` 是 `36`
（`4|32 = flexibleRightMargin|flexibleBottomMargin`：位置和尺寸固定，右边距与下边距可伸缩）。
把卡片从 320 加宽到 600、再布局一遍，两个标签一点没动（宽还是 248）——
多出来的 280 全部落进它们右边那条可伸缩边距里。这就是书 2.2 那几张 Struts（橡皮筋）示意图
在运行时的样子：**autoresizing 不是「按比例缩放」，是「哪几条边/距可伸缩」**。
而卡片自己 `constraints.count == 0`、`translatesAutoresizingMaskIntoConstraints == true`
—— 它整套靠 autoresizing 活着，和 §12 那种靠约束的界面文件是两套并行机制。

### 情形三：同一份 XML 里 `<rect>` 与 `<constraints>` 都在 —— 只看一个 flag

这是最容易误解、也最容易出 bug 的一格。入口场景的 `lblTitle` 同时有设计值
`(24,120,200,44)` 和两条约束（leading 24 / top 100）。跑一轮 `layoutIfNeeded()` 之后：

```swift
fresh.view.setNeedsLayout()
fresh.view.layoutIfNeeded()
// fresh.titleLabel?.frame 仍然 == (24.0, 120.0, 200.0, 44.0)
```

- 约束**没有失效**：`fresh.titleLeading` 那条读出来是 `constant=24.0 active=true`；
- 而是那个标签**不归布局引擎管**：`translatesAutoresizingMaskIntoConstraints` 是 `true`。
  这个 flag 为 `true` 时，UIKit 会拿它的 autoresizingMask **自动翻译出一组约束**
  去维持原 frame，于是 XML 那两条 `<constraints>` 与这组自动约束各说各话，
  引擎按「维持设计值」这一边解出来；
- 只把 flag 改成 `false`，同一轮布局立刻换成约束说的那个位置：
  `x = 24.0`（leading 24）、`y = 100.0`（top 100），尺寸也不再是设计的 200×44，
  而是标签自己报的 `intrinsicContentSize`（`(46.0, 28.66…)`，「欢迎」两个字在 24 pt
  粗体下的宽度）。

**「约束明明加了、frame 却还是设计稿那一格」这个 bug 就出在这一个 flag 上**，
和有没有窗口、和 ibtool 都无关。

两个对照组把话说死：

1. **纯代码 Auto Layout** 在同一进程里算得出结果 —— 建一个 400×800 的 `box`，
   把一个 `translatesAutoresizingMaskIntoConstraints = false` 的 `inner` 用四条约束
   （leading 24 / top 100 / 宽 120 / 高 40）钉住，`layoutIfNeeded()` 之后
   `inner.frame == (24.0, 100.0, 120.0, 40.0)`。**没有窗口也一样算**，
   所以上面那些「停在设计值」不是布局引擎在 headless 里罢工。
2. **安全区改不动**：`fresh.additionalSafeAreaInsets = UIEdgeInsets(top: 50, …)` 之后再布局，
   `safeAreaLayoutGuide.layoutFrame` 仍是整块 `(0.0, 0.0, 402.0, 874.0)` ——
   安全区归容器与窗口管，视图不在窗口里就轮不到它（和 §25 的实测对得上：
   挂上窗口那一刻才出现 62/34）。

顺带把 §12 那 4 条「UIKit 自己给 safeArea 补的约束」在这里收口：因为本章的视图
从没进过窗口，`safeAreaInsets` 全 0，布局指南被摆成了整个视图 —— 所以那条
「top = 安全区顶 + 100」的约束在关掉 flag 后量到的 `y` 正好是 `100.0`。
**这一步是巧合而不是通则**；§25 里同一个界面上屏之后，顶边立刻要加 62。

## §24 图像：XML 里 `image="pip"`、松散 PNG 与 @2x/@3x 查表

书 2.4 的素材工作流是「把 `xxx.png`、`xxx@2x.png`、`xxx@3x.png` 拖进 `Images.xcassets`」。
本章没有 `xcassets`，也没有 `actool`：`run-all.sh` 只调 `ibtool`，
示例目录里的 `Resources/` 被原样拷进 `build/31_interface_builder/`
（就是 §1 那个「可执行文件自己所在的目录就是 `Bundle.main`」）。于是四种取法摆在同一批松散文件上：

```
Resources/pip.png     4×4 像素
Resources/pip@2x.png  8×8 像素
Resources/pip@3x.png  12×12 像素
Resources/bare.png    4×4 像素（没有 @2x/@3x 兄弟，作对照）
```

界面文件那一侧对应的是这两行（入口场景）：

```xml
<imageView … image="pip" id="imgPip">
    <rect key="frame" x="24.0" y="330.0" width="48.0" height="48.0"/>
<resources>
    <image name="pip" width="4" height="4"/>
```

```
== §24 图像：XML 里 image="pip"、松散 PNG 与 @2x/@3x 查表 ==
     bundle 根目录里的图像文件：/Volumes/mac004/code/programming/iosdev/build/31_interface_builder/pip.png、pip@2x.png、pip@3x.png、bare.png
  ok   松散 PNG 用 Bundle.main.url(forResource:withExtension:) 就取到：/Volumes/mac004/code/programming/iosdev/build/31_interface_builder/pip.png
  ok   而这个 bundle 里没有 Assets.car：nil —— 素材目录那条路（Xcode 用 actool 编成一份 .car）在命令行管线里不存在，松散文件是它的替身；反过来说，任何「只有 Assets.car 才有」的东西在这儿都取不到
  ok   XML 那格 image="pip" 在解视图 nib 的时候被兑现了：Optional(<UIImage:0x… anonymous {4, 4} renderingMode=automatic(original)>) —— 注意它印的是 anonymous，而 §24 下面代码里取到的印的是 named(...)；两条路各给各的对象
  ok   点数 4×4、倍率 3、像素 12×12：size = Optional((4.0, 4.0)) scale = Optional(3.0) 像素 = Optional("12x12") —— 故事板里那个名字走的也是「按屏幕倍率挑文件」这套查表，不是硬绑 pip.png
  ok   UIImage(named: "pip")（不带扩展名，书 2.4 的写法）给出同一个数：size = Optional((4.0, 4.0)) scale = Optional(3.0) 像素 = Optional("12x12")
  ok   可它和故事板那一张不是同一个对象：false —— 而同一个名字再取一次就是同一个：true（UIImage(named:) 那侧有一层按名字的缓存，nib 解码那侧没有）
  ok   名字带扩展名在这台 iOS 上也取得到：Optional("<UIImage:0x… named(pip.png) {4, 4} renderingMode=automatic(original)>") —— 「named 只能不带扩展名」是老文档的说法，别把它当判据
  ok   更意外的一格：路径明明指着 pip.png，UIImage(contentsOfFile:) 拿到的却是 12×12 那一份（像素 = Optional("12x12") scale = Optional(3.0)）—— 倍率替换发生在 UIKit 装载图片的地方，不是 imageNamed 的专利；要拿到确凿那 4×4 个像素得绕开 UIImage，走 ImageIO 的 CGImageSource
  ok   同一块 3× 屏上，只有一份 bare.png（没有 @2x/@3x 兄弟）时：scale = Optional(1.0)，像素 = Optional("4x4")，size = Optional((4.0, 4.0)) —— 所以那个 3 不是屏幕给的，是文件名里 @3x 那三个字给的
  ok   名字写错就是 nil：nil —— 不抛异常，也不往 stderr 写一个字（本章判定 3 全程 0 字节）。「图标怎么是空的」这类问题在现场没有任何日志
  ok   ImageView 上那个 image 是普通属性，不是每次读都重新查表：现在再读一次，还是 §24 开头记下那张 = true
     pipView.frame = (24.0, 330.0, 48.0, 48.0)，contentMode rawValue = Optional(1)
  ok   框是 XML 那格 48×48 pt（§23 情形三里那种「子视图照搬设计值」），contentMode = 1（scaleAspectFit）—— 4 pt 见方的图放进 48 pt 的框里，运行时是放大 12 倍摆出来的：这就是「图标糊了」最常见的形状
```

- **`<resources>` 那一节是编译期用的**（`ibtool` 要据此把图像引用编进 nib 并校验名字），
  运行时没有「resources 表」这个东西：真正被兑现的是 `image` 属性那一次赋值，
  时机在**解视图 nib** 的那一刻（§11 的分界）。所以 `fresh.pipView.image` 在 `loadView` 之前是 nil、
  之后就有值。
- **两条路各给各的 `UIImage` 对象**：nib 解码那张的 `description` 印 `anonymous {4, 4}`，
  `UIImage(named:)` 那张印 `named(pip)`；它们不是同一个对象（`===` 为 `false`），
  但**同一个名字再取一次是同一个**（`UIImage(named:)` 侧有一层按名字的缓存，nib 解码侧没有）。
  这就是为什么「用 `UIImage(named:)` 换掉 imageView 的图」不会让故事板那张一起变。
- **`image` 是普通属性，不是每次读都重新查表**：把 nib 里那张记下来，之后再读
  `fresh.pipView.image`，`===` 依旧成立。改它要显式赋值。
- **倍率来自文件名，不是屏幕**：`pip`（三兄弟齐全）在 3× 屏上给出 `scale = 3.0`、像素 12×12、
  `size = 4×4` pt；`bare`（只有 4×4 那一份）在同一块屏上给出 `scale = 1.0`、像素 4×4、
  `size = 4×4` pt。所以 `size`（点）与像素之间那个 3 是文件名里 `@3x` 那三个字给的。
  这一条也是「同一份素材在 @2x 机器上看起来一样大」的原因。
- **`UIImage(contentsOfFile:)` 也会做倍率替换** —— 这一格是本章写探针时才撞出来的：
  路径明明指着 `pip.png`（4×4 那个文件），拿回来的 `UIImage` 却是 12×12 像素、`scale = 3.0`。
  倍率替换发生在 UIKit 装载图片的公共入口，不是 `imageNamed:` 的专利。
  要拿到「确凿那 4×4 个像素」必须绕开 `UIImage`，用 ImageIO 的
  `CGImageSourceCreateWithURL` + `CGImageSourceCreateImageAtIndex` 直接拿 `CGImage`。
- **`named:` 带扩展名在这台 iOS 上取得到**（`UIImage(named: "pip.png")` 给出同一个数）。
  「`named:` 不能带扩展名」是老文档的说法，别把它当判据 —— 反过来也别依赖它：
  带扩展名会绕过按名字的那层缓存。
- **找不到时什么声音都没有**：`UIImage(named: "NoSuchImage")` 是 `nil`，不抛异常，
  stderr 也 0 字节（本章判定 3 全程为空）。所以「图标怎么是空的」这类问题在现场没有任何日志，
  只能自己 `assert(image != nil)`。同理 §1 那条 `bundleIdentifier == nil` 也没打任何警告。
- **框和图是两回事**：`pipView.frame` 是 XML 那格 `48×48` pt（情形二那种「子视图照搬设计值」），
  `contentMode.rawValue == 1`（`scaleAspectFit`）。一张 4 pt 见方的图放进 48 pt 的框里，
  运行时是**放大 12 倍**摆出来的 —— 「图标糊了」最常见的形状就是这样量出来的：
  不是素材不清楚，是框与素材尺寸差了 12 倍。

## §25 同一个界面的三条路：界面文件 / `loadView` 里手工装配 / SwiftUI 的 `body`

本章前面所有断言都走在第一条路上。这一节把另外两条摆到同一张桌子上，
**不比审美、不比代码行数**，只量四件读得出来的事：跑过哪些钩子、根视图的框是多少、
子视图的 frame 从哪来、界面上的东西是**什么时候**被造出来的。

路二是纯代码 UIKit（书 2.5「不用 XIB」的那条）：

```swift
final class CodeScreenVC: UIViewController {
    let madeLabel = UILabel()
    let madeButton = UIButton(type: .system)
    override func loadView() {
        let root = UIView()
        root.backgroundColor = .white
        madeLabel.text = "欢迎"
        madeLabel.frame = CGRect(x: 24, y: 120, width: 200, height: 44)
        madeButton.setTitle("点我", for: .normal)
        madeButton.frame = CGRect(x: 24, y: 200, width: 120, height: 44)
        root.addSubview(madeLabel)
        root.addSubview(madeButton)
        madeButton.addTarget(self, action: #selector(didTapCode(_:)), for: .touchUpInside)
        view = root
        hookLog.append("CodeScreenVC.loadView：subviews = \(root.subviews.count)")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        hookLog.append("CodeScreenVC.viewDidLoad")
    }
    @objc func didTapCode(_ sender: UIButton) { … }
}
```

```
== §25 同一个界面的三条路：界面文件 / loadView 里手工装配 / SwiftUI 的 body ==
     纯代码那条路的账本：["CodeScreenVC.loadView：subviews = 2", "CodeScreenVC.viewDidLoad"]
  ok   跑过的钩子只有这两个：["CodeScreenVC.loadView：subviews = 2", "CodeScreenVC.viewDidLoad"] —— 对照 §5/§11：故事板那条路多出来的是 awakeFromNib，因为它的对象是「从 nib 里解出来的」；代码 new 出来的控制器没有这一站
  ok   根视图是零框：(0.0, 0.0, 0.0, 0.0) —— §23 情形一那句「根视图等于屏幕」在这一路上不成立。原因就在 loadView 的 `view = UIView()`：一个新建 UIView 的 frame 默认就是零，而这条路上没有谁去改它。两个对照组：
     · 什么都不写、让 UIKit 自己造视图：UIView 的 frame = (0.0, 0.0, 402.0, 874.0)（屏幕是 (0.0, 0.0, 402.0, 874.0)）
  ok   再对照一条通则：装进去的那一刻谁也没动谁 —— 子视图还是 (0.0, 0.0, 123.0, 45.0)，父视图还是 (0.0, 0.0, 0.0, 0.0)（addSubview 不改子视图的框）—— 所以下面那颗标签的 (24,120) 能一路活到挂窗口之后
     · 各挂进一个 300×600 的窗口之后：纯代码 = (0.0, 0.0, 300.0, 600.0)，默认 = (0.0, 0.0, 300.0, 600.0)
  ok   两条路一起被改成窗口那一格：(0.0, 0.0, 300.0, 600.0) / (0.0, 0.0, 300.0, 600.0) —— 所以「根视图 = 屏幕尺寸」不是加载视图的通则，而是「根视图被放进窗口那一刻由窗口盖章」；本章量到的场景根视图是屏幕尺寸，只是因为窗口就是屏幕
  ok   盖的是根视图的章，子视图原封不动：(24.0, 120.0, 200.0, 44.0)、(24.0, 200.0, 120.0, 44.0) —— 代码里写的那两格；没有 XML 那格 <rect> 参与，也就没有 §23 情形三那种「设计值与约束各说各话」
  ok   两个子视图都直接挂在根视图上：2 个，按钮的 superview 是根视图 = true
  ok   §15 那张 target-action 表在这儿是同一套机制，只是这张表由 addTarget 填：["interface_builder.CodeScreenVC"]
  ok   表里的动作名来自 #selector：["didTapCode:"] —— 写错一个字母编译期就报错，这是界面文件那条路没有的保护（对照探针 b09：XML 里的选择器写错，ibtool 一声不响）
  ok   派发这一环同样过不去：sendActions 之后账本还是 ["CodeScreenVC.loadView：subviews = 2", "CodeScreenVC.viewDidLoad"] —— §16 那条边界跟界面文件无关，是「没有 UIApplication」
  ok   两条路最后都落在同一件事上：视图挂在根视图的某个后代位置（代码 true，故事板 true） —— 分别是那两行 addSubview 与 §11 那次视图 nib 解码；而代码这条路没有 outlet 要连，那两个视图是类里声明的存储属性，UILabel 直接可读
```

- **钩子的差集正好是 `awakeFromNib`**。故事板那条路（§5/§11）走
  `awakeFromNib → viewDidLoad`，这条路只有 `loadView → viewDidLoad`。
  原因不是「代码没写」，而是 `awakeFromNib` 的定义就是「**作为 nib 里的对象被解出来**」——
  代码 `new` 出来的控制器压根不是被解出来的（§21 里 owner 不跑同一个钩子，是同一个道理的另一面）。
- **这一路把 §23 情形一的因果关系钉死了**：`loadView` 里 `view = UIView()` 之后根视图是零框；
  而「什么都不写、让 UIKit 自己造视图」的对照组给出 `(0.0, 0.0, 402.0, 874.0)`。
  差别不在「代码 vs 界面文件」，在于**这条路上没人去改那个零框**：
  再挂进一个 300×600 的 `UIWindow`，两条路**一起**变成 `(0.0, 0.0, 300.0, 600.0)`。
  所以「根视图 = 屏幕尺寸」不是加载视图的通则，而是「根视图被放进窗口那一刻由窗口盖章」。
  本章量到的场景根视图是屏幕尺寸，只是因为窗口就是屏幕。
- **`addSubview` 不改子视图的框**（123×45 装进零框父视图之后两边都没动）。
  所以代码里写的 `(24,120)` 能一路活到挂窗口之后 —— 盖的是根视图的章，子视图原封不动。
- **target-action 是同一套机制**：`#selector(didTapCode(_:))` 填出来的表读出来还是
  `["interface_builder.CodeScreenVC"]` + `["didTapCode:"]`（§15 那张表的形状一模一样）。
  唯一的区别是名字的来源：`#selector` 写错一个字母**编译期就报错**，
  而 XML 里把 `selector="didTapp:"` 写错时 ibtool 一声不响（探针 b09），
  到运行时才炸（探针 r07）。这是界面文件那条路没有的保护。
- **§16 那条边界与界面文件无关**：`sendActions(for:)` 在这条路上同样一个都不派发，
  账本还是那两条。根是「没有 `UIApplication`」，不是「用了故事板」。

路三是 SwiftUI（今天的新写法，书里没有；放进来是为了让「界面什么时候存在」这一格有第三种答案）：

```swift
struct MeasuredCard: View {
    let titleText: String
    var body: some View {
        bodyRuns += 1
        return Text(titleText).font(.system(size: 20))
    }
}
var bodyRuns = 0          // 全局计数，好把「算了几次 body」变成一个可断言的数
```

```
  ok   它的类型是本模块里的一个 struct：interface_builder.MeasuredCard —— §7 那三段字符串的绑定问题在这一路上不存在：没有 XML 要写类名，也没有模块名字符串要和 target 对上
  ok   值里的字段直接读得到，不需要连接、不需要等谁：["titleText=欢迎"]
  ok   刚造出这个值，body 一次都没算：bodyRuns = 0 —— 界面文件那条路在 instantiate 那一刻就把对象全解出来了（§5），这一条连「界面」都还不存在，只有一个 struct 的实例
  ok   连 UIHostingController(rootView:) 都还没算：bodyRuns = 0
     hostCard.view 的实际类 = SwiftUI._UIHostingView<interface_builder.MeasuredCard>，frame = (0.0, 0.0, 0.0, 0.0)
  ok   宿主里面那层视图的类名里就带着 MeasuredCard：SwiftUI._UIHostingView<interface_builder.MeasuredCard> —— 类型是编译期从泛型参数推出来的，不是运行时按字符串去找的
  ok   顺带一个测量上的坑：UIViewController 的 view 声明成 UIView!（隐式解包可选），直接 type(of:) 拿到的是 Swift.Optional<__C.UIView> —— 上一行末尾那个 ! 不是笔误，是必须解包才量得到真身
     sizeThatFits(320×200) 返回 (38.33333333333333, 24.0)，bodyRuns = 1
  ok   第一次算 body 是被「你要多大尺寸」问出来的：bodyRuns = 1，返回 (38.33333333333333, 24.0) —— 320×200 的提议没被接受，Text 按自己的字宽回了 (38.33333333333333, 24.0)；界面文件那条路没人问尺寸，对象是解出来的
  ok   另一条路试过了：不给窗口、只手工布局，body 一次都不算（bodyRuns = 1，宿主视图的子视图 0 个）—— 这一路上的「上屏」和 §16 的派发一样，得先把视图放进窗口
     挂上屏幕尺寸的窗口：bodyRuns = 1，hostCard.view.frame = (0.0, 0.0, 402.0, 874.0)
  ok   放上屏幕这一刻只改框、不算 body：(0.0, 0.0, 402.0, 874.0)（bodyRuns 仍是 1）—— 跟上面纯代码那条对照组同一个机制
     布局一轮之后：bodyRuns = 1，子视图 = ["SwiftUI.CGDrawingView@(182.0, 439.0, 38.33333333333333, 24.0)"]
  ok   屏幕上第一次出现东西：SwiftUI.CGDrawingView @ (182.0, 439.0, 38.33333333333333, 24.0)，而 body 没有再算一次（1）—— 布局用的是 sizeThatFits 那一轮算好的结果；注意它不是 UILabel，本章前面 §15 那张 target-action 表、§24 那个 image 属性在这一路上都没有落脚的地方
  ok   画出来的那一格大小就是 sizeThatFits 的答复：(38.33333333333333, 24.0) == (38.33333333333333, 24.0) —— 布局没有另算一份尺寸，它把问出来的答案原样用了；代码那条路上没有这一问，(24,120,200,44) 是写死的
     宿主视图的 safeAreaInsets = UIEdgeInsets(top: 62.0, left: 0.0, bottom: 34.0, right: 0.0)，bounds = (0.0, 0.0, 402.0, 874.0)，那一格 = (182.0, 439.0, 38.33333333333333, 24.0)
  ok   竖直方向是「安全区正中」，不是「整屏正中」：整屏正中该是 425.0，实测 439.0 = 62.0 + (874.0 − 62.0 − 34.0 − 24.0) ÷ 2 = 439.0 —— 一个字没提安全区的 Text，位置是被安全区推着走的
  ok   水平方向差一点，差得有名堂：正中间该是 181.83333333333334，实测 182.0 —— 多出来的 0.1666666666666572 是往上贴到一个像素：屏幕 scale = 3.0，1 px = 1/3.0 pt，182.0 × 3.0 = 546.0 刚好是整数（546.0 px）
```

这一段是本章唯一一次「三种『界面何时存在』同桌」，把时间线摆出来：

1. `MeasuredCard(titleText: "欢迎")` —— `bodyRuns = 0`。界面上一个东西都还不存在，
   只有一个 struct 的实例（**值是主角，界面是派生的**）。
2. `UIHostingController(rootView: card)` —— 还是 `0`。造宿主不算 body。
3. `hostCard.sizeThatFits(in: 320×200)` —— **`1`**。第一次算 body 是被
   「你要多大尺寸」问出来的，答复是 `(38.33…, 24.0)`：320×200 这个提议没被接受，
   `Text` 按自己的字宽回答。界面文件那条路上没有人问尺寸（对象是解出来的，`<rect>` 里写着尺寸）。
4. 另一支对照：不给窗口、只 `setNeedsLayout()` + `layoutIfNeeded()` —— body 一次都不算，
   宿主视图 0 个子视图。**这一路上的「上屏」和 §16 的派发一样，得先把视图放进窗口**。
5. `makeKeyAndVisible()` —— 只改框（`(0,0,402,874)`），`bodyRuns` 仍是 1。
6. 再布局一轮 —— 屏幕上第一次出现东西：`SwiftUI.CGDrawingView @ (182.0, 439.0, 38.33…, 24.0)`，
   而 body **没有**再算（用的是第 3 步问出来的答案）。注意那个类不是 `UILabel`：
   §15 那张 target-action 表、§24 那个 `image` 属性在这一路上都没有落脚的地方。

然后是两格「没写安全区，却被安全区推着走」的算术，值得按一遍：

- 竖直：整屏正中该是 `(874 − 24) / 2 = 425.0`，实测 `439.0`。
  `439.0 = 62.0 + (874.0 − 62.0 − 34.0 − 24.0) ÷ 2` —— 是**安全区**正中。
- 水平：正中间该是 `(402 − 38.33…) / 2 = 181.83333333333334`，实测 `182.0`。
  多出来的 `0.1666…` 是往上贴到一个像素：屏幕 `scale = 3.0`，1 px = 1/3.0 pt，
  `182.0 × 3.0 = 546.0` 刚好是整数。**这一格是这台 3× 屏的脾气**（§26 登记在「只在这台机器上成立」那堆）。

安全区那三行把 §23 的悬念收掉：

```
     三个视图的安全区：没上屏的 fresh = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)，挂在 300×600 窗口的 byCode = UIEdgeInsets(top: 62.0, left: 0.0, bottom: 0.0, right: 0.0)，整屏窗口的 hostCard = UIEdgeInsets(top: 62.0, left: 0.0, bottom: 34.0, right: 0.0)
  ok   安全区是窗口给的，不是界面文件写的（XML 里没有一行写 62 或 34）：没挂进任何窗口的 fresh 四项全零，所以 §23 那条「顶边 = 安全区顶 + 100」的约束量出来 y 正好是 100.0（那一刻 safeAreaLayoutGuide = (0.0, 0.0, 402.0, 874.0)，就是整块 bounds）；同一个界面上屏，62 与 34 立刻出现 —— 而 300×600 那种小窗口只有上边 62、下边 0，因为它的底还没碰到 Home 指示条那一带
```

**XML 里没有一行写 62 或 34** —— 这两格是窗口按设备算出来的。
这也解释了 §23 里那个「y 正好 100.0」为什么是巧合：那一刻布局指南等于整块 bounds。

最后三行是「改了值为什么看不见」，以及这条路和 UIKit 的接缝：

```
  ok   换掉 rootView 这一行执行完，body 还是 1 次、屏幕上那一格的 frame 一模一样（(182.0, 439.0, 38.33333333333333, 24.0)）—— 值换了，什么都还没发生；对照 §16：界面文件那条路上换了 target 表也不会自己派发
     再布局一轮：bodyRuns = 2，子视图 = ["SwiftUI.CGDrawingView@(114.66666666666666, 439.0, 173.0, 24.0)"]
  ok   这一次 body 被重算了（2），而且新的字真的变了大小：38.33333333333333 → 173.0，x 也跟着挪 182.0 → 114.66666666666666 —— 「改了值看不见」不是 SwiftUI 不重算，是还没走到布局那一轮
  ok   什么也没改，再布局一轮还是不涨：bodyRuns = 2 —— body 不是每帧重算的；这一路上「算了几个」和「布局了几轮」是两个数
     宿主控制器自己的父链：["_TtGC7SwiftUI19UIHostingControllerV17interface_builder12MeasuredCard_", "UIViewController", "UIResponder", "NSObject"]
  ok   它本身就是一个 UIViewController（父链里找得到）—— 所以本章前面每一条 UIKit 缝隙（导航栈、outlet、segue、§23 的框）它都塞得进去，两条路混用不需要桥
     路一：Main.storyboard 入口场景 → §2 那 6 个 nib；路二：CodeScreenVC.loadView() 里那两行 addSubview；路三：MeasuredCard.body 里的一次 Text 调用
     清点 fresh.view.subviews：["UILabel@(24.0, 100.0, 46.0, 28.666666666666668)", "UIButton@(24.0, 200.0, 160.0, 44.0)", "UIButton@(24.0, 260.0, 160.0, 44.0)", "UIImageView@(24.0, 330.0, 48.0, 48.0)", "UIButton@(0.0, 0.0, 0.0, 0.0)"]
  ok   故事板那个场景跑起来是 5 个子视图，纯代码那个是 2 个 —— 别按 XML 数：那份 <subviews> 里只有 4 个（标签、两颗按钮、一个 imageView），第 5 个 UIButton 是 §16 用代码 addSubview 加进去的（那个零框的）。运行时数出来的是「XML 解出来的 + 代码加的」，只看 XML 会数少
```

`hostCard.rootView = MeasuredCard(titleText: "第二个值，比方才长")` 这一行执行完，
body 还是 1 次、屏幕上那一格 frame 一字不变 —— 和 §16「换了 target 表也不会自己派发」
是同一种「赋值 ≠ 生效」。要走完**布局那一轮**才看见：字宽 38.33 → 173.0，x 跟着挪。
而什么都不改再布局一轮，`bodyRuns` 不涨：**body 不是每帧重算的**，
「算了几个」和「布局了几轮」是两个数。最后一行那 5 个子视图里第一个是
`(24.0, 100.0, 46.0, 28.66…)` —— 正是 §23 把 flag 关掉之后引擎重算出来的那一格，
两条节之间互相印证。

## §26 收尾：第三次实例化同一份 XML，然后分成「结构性」与「这台机器的」两堆

§22 已经对 XIB 量过「配方不是单例」。收尾把同一句话对故事板钉一遍，
再把整章的数字分成两堆 —— 哪些换设备就变、哪些是机制本身。

```swift
hookLog.removeAll(keepingCapacity: true)
let third = sb.instantiateInitialViewController() as! EntryVC
third.loadViewIfNeeded()
```

```
== §26 收尾：第三次实例化同一份 XML，然后把本章的数字分成「结构性」与「这台机器的」两堆 ==
  ok   第三次开锅还是全新的一组对象：控制器与 §11 那个 = 不是同一个，视图与它 = 不是同一个 —— 每次 instantiate 都重新解一遍 nib，没有缓存好的那一份「界面」在等着被复用
  ok   而 XML 那几格一字不差地重现：badge = 7.0、caption = "故事板填进来的标题"、flagged = true、titleLabel.text = 欢迎 —— 「跑起来看看」难复制就在这两件事同时成立：对象每次都是新的，值每次都是准的
  ok   钩子也每趟都重跑：["awakeFromNib：badge=7.0 caption=\"故事板填进来的标题\" flagged=true titleLabel=nil", "viewDidLoad：titleLabel=欢迎 badge=7.0"] —— §5/§11 那张时序表不是这一进程的偶然，任何一次 instantiate 都走这两站
  ok   顺带确认本章的证据链没在中途变过：磁盘上还是 §2 那 6 个 nib、查找表还是那 3 项（["PlainScreen", "TheSecond", "UIViewController-ENT-01-001"]）—— 中途没有任何一步「运行时把界面文件改了」
     跑这一份输出的机器：iOS 18.3.1（Version 18.3.1 (Build 22D8075)），UIScreen.main.bounds = (0.0, 0.0, 402.0, 874.0)，scale = 3.0
```

「对象每次都是新的，值每次都是准的」这两件事同时成立，才是「跑起来看看」难复制的原因：
新对象意味着不能靠「拿全局那份界面」来理解行为；值准确意味着 XML 是唯一配方。
最后一条是对本章自身的校验 —— 磁盘上的产物从 §2 到 §26 没变过，
所以前面所有断言引用的是同一批 nib。

### 只在这台机器上成立的数字（换设备 / 换 iOS 版本请重跑，别照抄）

```
  【只在这台机器上成立的数字】—— 换设备/换 iOS 版本请重跑，别照抄：
    · 屏幕 402.0×874.0 pt、scale 3.0：§23 把 XML 的 414×896 改成屏幕值、§25 把根视图改成窗口值、
      §24 拿 @2x/@3x 时用的都是它；§25 里 182.0 那个 x 是贴到 1/3.0 pt 的像素格上得到的。
    · 安全区 62 / 34（§25）：刘海机才有的数；XML 里没有这两个数，§23 那条 top = 安全区顶 + 100 的约束在没上屏时量到 100.0、
      挂上 300×600 的小窗口时底部变成 0，都是这一条的推论。
    · 38.33…×24（§25）：那是系统字体 20 pt 排「欢迎」两个字的字宽，换文案、换字体、换 Dynamic Type 全都变。
    · §2 那 6 个 nib、§10 查找表少一项：场景数一变，数目跟着变；结构（一个场景两条 nib）才是要记的。
    · ObjC description 里的内存地址：每进程重新分配，所以本章所有输出前统一走了一次脱敏（把 0x 后面的长十六进制串换成 0x…）——
      这是 run-all.sh 最后那条「debug 与 release 逐字节一致」能过的原因之一。
```

### 与这台机器无关的结构性结论

```
  【与这台机器无关的结构性结论】：
    · 一份 XML → 一个场景两条 nib（控制器一条、视图一条），标识符决定 nib 名（§2/§9/§10）。
    · customClass/customModule 三段字符串写错，ibtool 零诊断，运行时静默退回 plain UIViewController（§7/§8，原文见探针 b01/b02）。
    · 不可达的场景 ibtool 直接不生成 nib（§3，探针 b03）—— 本章最危险的一条，因为它连报错都没有。
    · 连接是视图 nib 被解的那一刻做的一次 KVC 赋值：对象身份（===）能连、约束也能连（§11/§12）。
      问错 key 分两种下场：outlet 的 property 名在类里不存在 → NSUnknownKeyException 直接 abort（探针 r03），
      File's Owner 交错（nil 或类型不含那个 key）是同一句话（探针 r11/r12）；
      而 userDefinedRuntimeAttribute 的 keyPath 写错只往 stderr 打一句 NSLog、进程 rc=0 跑完（探针 r04）—— 软失败与硬失败的分界就在这儿。
    · @IBInspectable 只管 Xcode 给不给那一格，运行时起作用的是 KVC（§14：SecondVC 一个都没标，title 照样被填）。
    · @IBAction 落到运行时是控件表里的一个字符串选择器；kind="unwind" 那条线的 target 是 segue 模板而不是控制器（§15/§17/§20）。
      可控制器的 performSegue(withIdentifier:) 照样查得到那条 identifier，它和手工派发模板那句 perform: 的账本逐字相同（§20）。
      「has no segue with identifier」说的是那条连接根本没编出来 —— 例如 <exit> 放错了位置（探针 b11），不是 unwind 天生不能用 performSegue。
```

### 三条 headless 边界（不是界面文件的问题，是「没有 UIApplication」的问题）

```
  【三条 headless 边界】—— 不是界面文件的问题，是「没有 UIApplication」的问题：
    · §16：sendActions(for:) 表读得出、事件不派发；
    · §20：手工 perform: 能调到 segue 模板，模板自己 perform 完但栈不弹，得自己 popToViewController；
    · §25：SwiftUI 那条路 body 不挂窗口就不会算，只有 sizeThatFits 问得出（挂上窗口 + 布局一轮才看见 CGDrawingView 落地）。
    同一个根：§11 那句「没有 window 就没有 Appearance 回调」。
```

三条看起来是三件事，其实是一个缺失的单例造成的连锁：
`UIApplication.shared == nil` → 没有事件派发者（§16）、没有转场执行环境（§20）、
没有 window 也就没有 Appearance 回调与安全区（§11/§23/§25）。
**这三条边界不是「界面文件的缺陷」**，读本章任何一条「没生效」的断言时都要先问：
是机制如此，还是这一格本来就依赖那个不存在的运行循环。

### 本章刻意没量的

```
  【本章刻意没量的】：actool 与 Assets.car（产物目录里只有松散 PNG，§24 走的是那条查表通路）；@IBDesignable 的画布渲染
     （那是 Xcode 进程里的事，不在运行时）；UITabBarController / UICollectionView / UITableView 的故事板 wiring；
     Auto Layout 的优先级、content hugging、stack view（§23 只量了 translatesAutoresizingMaskIntoConstraints 这一开关）；
     trait variations 与 size classes；state restoration；launch storyboard；xcodeproj 里 MAIN_STORYBOARD 那类工程设置
     （本书 2.1 的向导产物是 .app，本章产物是裸可执行文件，两边「界面从哪来」的机制不同，§1 量了差别）。
```

```
  一句话：这一章把「一张 XML 画出来的界面怎么和 Swift 接上线」拆成了三段可查的账——编译产物里有什么（§1–§3）、
  运行时解出什么、什么时候解（§4–§14）、线和 segue 在运行时是谁（§15–§22）、框与尺寸有几格真生效（§23–§25）。
  凡是「Xcode 里拖一条线、跑起来看看」的问题，在这儿都能换成一句能跑、能读、能断言的话。

全部断言通过。
==== 31 结束 ====
```

## 探针记录

下面 26 支全部是**现跑现抄**的原文（`bash examples/31_interface_builder/probes/run.sh` 一次跑完，
留档于本轮实测）。每支的形状是：`ibtool` 退出码与产物 → `ibtool` 的输出（多数为空）→
`swiftc` 退出码 → 运行退出码 → stdout → stderr。崩溃类的记了退出码与信号
（`134` = `SIGABRT`，也就是 Objective-C 异常没被接住）。
运行期的临时源文件路径统一是 `/var/folders/…/iosdev31probes/main.swift`
（探针的 `.swift` 必须先复制成 `main.swift` 才允许顶层语句），下面按原样抄。
**探针的留档没走主线那次地址脱敏**（§26 那条），所以栈里的 `0x…` 每次重跑都会变 ——
比对时以消息文本、帧号与符号名为准。
正文里已经引过的探针（b01/b02/b03/b05/b10/b11/r01/r02/r03/r04/r06/r07/r11/r12/r13/r14），
这一节给的是**完整留档**：正文那几处为了排版只截了关键帧（r03、r06、b10），
截了哪几帧都就地写了，这里补齐剩下的。

### 坏界面文件（b01~b11）：`ibtool` 对每种写法说了什么

**`probes/b01_ghost_class.storyboard` + `.swift`** — `customClass="GhostVC"`，本模块里没有这个类

```
########## b01_ghost_class
ibtool（storyboard）退出码 = 0，产物 = b01_ghost_class.storyboardc
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
取到的对象运行时类名 = UIViewController
NSClassFromString("interface_builder.GhostVC") = nil
as? NSObject 之外的成员一律读不到：这个对象身上没有 badge 这个键 → setValue 的现场见 r03/r04
--- stderr ---（空）
```

`ibtool` 不校验类名是否存在（它只需要一个字符串），所以**编得过、跑得掉、静默退回
plain `UIViewController`**。Inspector 里那三格（`userDefinedRuntimeAttributes`）此刻
是往一个不含那些 key 的对象上赋值 —— 那就是 r04 的现场。

**`probes/b02_wrong_module.storyboard` + `.swift`** — 类存在，`customModule` 写成 `wrong_module_name`

```
########## b02_wrong_module
ibtool（storyboard）退出码 = 0，产物 = b02_wrong_module.storyboardc
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
取到的对象运行时类名 = UIViewController
本模块里那个类的全名 = interface_builder.RealButWrongModuleVC
NSClassFromString("wrong_module_name.RealButWrongModuleVC") = nil
as? RealButWrongModuleVC = nil
--- stderr ---（空）
```

和 b01 的**运行时结果完全一样**（这也是 §8 那条断言的依据）：`customModule` 错了不是
「找错类」，是「一个也没找到」。

**`probes/b03_unreachable_scene.storyboard`** — 无入口、无 `storyboardIdentifier`、也没有人连它（纯 ibtool 探针）

```
########## b03_unreachable_scene
ibtool（storyboard）退出码 = 0，产物 = b03_unreachable_scene.storyboardc
--- ibtool 输出 ---
/* com.apple.ibtool.document.warnings */
/Volumes/mac004/code/programming/iosdev/examples/31_interface_builder/probes/b03_unreachable_scene.storyboard:sgAB: warning: Segues initiated directly from view controllers must have an identifier [9]
/Volumes/mac004/code/programming/iosdev/examples/31_interface_builder/probes/b03_unreachable_scene.storyboard:C-03-003: warning: “GhostC“ is unreachable because it has no entry points, and no identifier for runtime access via -[UIStoryboard instantiateViewControllerWithIdentifier:]. [9]
（纯 ibtool 探针：无同名 .swift，到此为止）
```

本章唯一一次 `ibtool` **主动开口**（而且是 `warning`，退出码仍 0）。注意引号是中文弯引号
`“GhostC“` —— 原文如此。第二行还顺带说了另一件事：从控制器直接发起的 segue 必须有 identifier。

**`probes/b04_unreachable_removed.storyboard` + `.swift`** — 同一份 XML 删掉那个不可达场景之后的 nib 账

```
########## b04_unreachable_removed
ibtool（storyboard）退出码 = 0，产物 = b04_unreachable_removed.storyboardc
--- ibtool 输出 ---
/* com.apple.ibtool.document.warnings */
/Volumes/mac004/code/programming/iosdev/examples/31_interface_builder/probes/b04_unreachable_removed.storyboard:C-03-003: warning: “GhostC“ is unreachable because it has no entry points, and no identifier for runtime access via -[UIStoryboard instantiateViewControllerWithIdentifier:]. [9]
/Volumes/mac004/code/programming/iosdev/examples/31_interface_builder/probes/b04_unreachable_removed.storyboard:sgAB: warning: Segues initiated directly from view controllers must have an identifier [9]
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
包内文件 = ["A-01-001-view-vA.nib", "B-02-002-view-vB.nib", "Info.plist", "UIViewController-A-01-001.nib", "UIViewController-B-02-002.nib"]
nib 个数 = 4
nib 名单 = ["A-01-001-view-vA.nib", "B-02-002-view-vB.nib", "UIViewController-A-01-001.nib", "UIViewController-B-02-002.nib"]
查找表键 = ["UIViewController-A-01-001", "UIViewController-B-02-002"]
查找表里有没有 C-03-003 = false
```

（两份警告的顺序和 b03 相反，`ibtoold` 的输出顺序不参与比较，两支各自留档。）
§3 说「不可达的场景会被无声删掉」，这一支就是它的账：三个场景只剩 4 个 nib，
`C-03-003` 连进查找表的机会都没有。

**`probes/b05_integer_value.storyboard` + `.swift`** — `type="number"` 配 `<integer key="value">`

```
########## b05_integer_value
ibtool（storyboard）退出码 = 0，产物 = b05_integer_value.storyboardc
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
type="number" + <integer> 编出来的产物照常可用，取到的类型 = interface_builder.HostIV
badge = 7.0（类里声明的默认值是 0，所以这个数只能是 XML 填进来的）
这一格没崩、没告警、值也进来了 —— 与 b10 那种「type 与取值子元素对不上」正好成对照
```

这一支推翻的正是本章初稿写在 §14 注释里的说法。`type` 的名字与取值子元素的名字
**不需要字面配对**，能转成 `NSNumber` 就够了。

**`probes/b06_outlet_missing_target.storyboard` + `.swift`** — `<outlet property="titleLabel">` 的 `destination` 指向一个不存在的对象 id

```
########## b06_outlet_missing_target
ibtool（storyboard）退出码 = 0，产物 = b06_outlet_missing_target.storyboardc
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
视图照样加载：subviews = 1
titleLabel = nil —— 这就是「拖了个半截线」的运行时样子
```

和 §12 的硬失败对照着记：key 存在、**对端的对象不存在** → 这条连接压根没编进去，
于是既不赋值也不报错，outlet 保持 `nil`。「半截线」是唯一一种真·静默的失效。

**`probes/b07_duplicate_identifier.storyboard`** — 两个场景写同一个 `storyboardIdentifier`（纯 ibtool 探针）

```
########## b07_duplicate_identifier
ibtool（storyboard）退出码 = 0，产物 = b07_duplicate_identifier.storyboardc
--- ibtool 输出 ---（空）
（纯 ibtool 探针：无同名 .swift，到此为止）
```

`ibtool` 不查重。这一条的运行时分岔交给 r09（两条 **segue** 用同一个 identifier）。

**`probes/b08_show_without_container.storyboard`** — `kind="show"` 的发起者没有被放进任何容器（纯 ibtool 探针）

```
########## b08_show_without_container
ibtool（storyboard）退出码 = 0，产物 = b08_show_without_container.storyboardc
--- ibtool 输出 ---（空）
（纯 ibtool 探针：无同名 .swift，到此为止）
```

编译期照样零诊断；运行时那一半见 r08。

**`probes/b09_bad_selector.storyboard` + `.swift`** — XML 里 `selector="didTapp:"`，类里实现的是 `didTap:`

```
########## b09_bad_selector
ibtool（storyboard）退出码 = 0，产物 = b09_bad_selector.storyboardc
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
表里的 target 类名 = ["interface_builder.HostSL"]
touchUpInside 这一格的表 = ["didTapp:"]
类里实现的是 didTap:，两边各问一句 responds(to:)：
  responds(to: "didTapp:") = false
  responds(to: "didTap:") = true
写错的名字照样能进表、照样能被 SEL 构造出来 —— 这一步没人拦（上面 ibtool 输出就是「没人拦」的证据）
--- stderr ---（空）
```

§15 那句「方法名改一个字就断线」的完整链条在这一支上只到一半：线**没断**，
表里躺着的就是那个错名字。断的是下一次派发（r07）。

**`probes/b10_type_mismatch.storyboard`** — `type="string"` 却留着 `<real key="value">`

```
########## b10_type_mismatch
ibtool（storyboard）退出码 = 255，产物 = b10_type_mismatch.storyboardc
--- ibtool 输出 ---
2026-09-30 06:51:05.292 ibtoold[29143:4890393] [MT] DVTAssertions: ASSERTION FAILURE in IDEInterfaceBuilder/InterfaceBuilderKit/Document/Compiler/IBDocumentCompiler.m:79
Details:  Error: Failed to save document. UserInfo: {
    NSLocalizedDescription = "Failed to save document.";
    NSLocalizedFailureReason = "-[__NSCFNumber length]: unrecognized selector sent to instance 0x22a4bc1b8109a48d";
}
Object:   <IBCocoaTouchStoryboardDocumentCompiler: 0x7fd5055ee600>
Method:   -invokeWithIntermediateDocument:
Thread:   <_NSMainThread: 0x7fd4ff720d30>{number = 1, name = main}
Hints: 

Backtrace:
  0   -[DVTAssertionHandler handleFailureInMethod:object:fileName:lineNumber:assertionSignature:messageFormat:arguments:] (in DVTFoundation)
  1   _DVTAssertionHandler (in DVTFoundation)
  2   _DVTAssertionFailureHandler (in DVTFoundation)
  3   -[IBDocumentCompiler invokeWithIntermediateDocumentOfTargetRuntime:alwaysCopy:block:] (in IDEInterfaceBuilderKit)
  4   -[IBDocumentCompiler invokeWithIntermediateDocumentOfTargetRuntime:alwaysCopy:block:] (in IDEInterfaceBuilderKit)
  5   -[IBStoryboardDocumentCompiler compileWithOptions:error:] (in IDEInterfaceBuilderKit)
  6   +[IBDocumentCompiler compileContentsOfDocument:options:error:] (in IDEInterfaceBuilderKit)
  7   __47-[IBDocument compiledPackageWithOptions:error:]_block_invoke (in IDEInterfaceBuilderKit)
  8   -[IBDocumentAutolayoutManager ignoreAutolayoutStatusInvalidationDuring:] (in IDEInterfaceBuilderKit)
  9   -[IBDocument compiledPackageWithOptions:error:] (in IDEInterfaceBuilderKit)
 10   -[IBDocument compileAndWriteToPath:withOptions:error:] (in IDEInterfaceBuilderKit)
 11   IBCompileDocumentForSingleTargetDevice (in ibtoold)
 12   IBCompileDocumentIfTargetDevicesAreSupported (in ibtoold)
 13   -[IBCLIInterfaceBuilderToolPersona invokeArguments:outputDictionary:] (in ibtoold)
 14   -[IBCLIInterfaceBuilderToolPersona runSingleInvocation:outputtingToFileHandle:andVerifyingEnvironment:] (in ibtoold)
 15   IBCLIServerRunSingleInvocation (in ibtoold)
 16   __IBCLIServerRunSingleInvocationWithIODirectedAtPipesAndUnlinkOnSuccess_block_invoke_2 (in ibtoold)
 17   __IBCLIServerRunSingleInvocationWithIODirectedAtPipesAndUnlinkOnSuccess_block_invoke (in ibtoold)
 18   -[IBCLIErrorForwarder forwardErrorOutputToDescriptor:whileInvokingBlock:] (in ibtoold)
 19   IBCLIServerRunSingleInvocationWithIODirectedAtPipesAndUnlinkOnSuccess (in ibtoold)
 20   main (in ibtoold)
 21   start (in dyld)
（ibtool 没放行：没有产物可跑，探针到此为止）
```

本章唯一一次 `ibtool` **拒绝编译**：`rc=255`，报的是它自己的断言失败
（`-[__NSCFNumber length]: unrecognized selector` —— 编译器拿字符串的 API 去问一个数字），
不是一句「你这行 XML 写错了」的人话。全 22 帧原文在 §14。

**`probes/b11_exit_outside_objects.storyboard` + `.swift`** — `<exit>` 元素放在 `</objects>` 外面（仍在 `<scene>` 内，XML 合法）

```
########## b11_exit_outside_objects
ibtool（storyboard）退出码 = 0，产物 = b11_exit_outside_objects.storyboardc
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
按钮对象本身是好的：Optional("UIButton")
可它的 target 列表 = [] —— 一条动作都没有
对照：把同一个 <exit> 写进 <objects>（探针 r10），这里读出来就是 ["UIStoryboardUnwindSegueTemplate"] + ["perform:"]
按钮本身还在层级里（superview = UIView），outlet 也连上了 —— 丢的只是那一条 segue 连接
--- stderr ---（空）
```

这一支是 §20 那次纠错的实底：当初「`performSegue` 查不到 unwind」的崩溃现场
（`has no segue with identifier 'backToAlpha'`）就是这么来的 —— 那条连接根本没编出来，
而 `ibtool` 零诊断。

### 编译期诊断（e01）

**`probes/e01_static_member.swift`** — 拿 `instantiateInitialViewController()` 的返回值直接 `.titleLabel`（§6 的 `__kindof`）

```
########## e01_static_member
--- swiftc 输出 ---
/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev31probes/main.swift:10:11: error: value of type 'UIViewController' has no member 'titleLabel'
 8 | let sb = UIStoryboard(name: "b01_ghost_class", bundle: nil)
 9 | let vc = sb.instantiateInitialViewController()
10 | print(vc?.titleLabel)
   |           `- error: value of type 'UIViewController' has no member 'titleLabel'
11 | print(vc?.badge ?? -1)
12 | 

/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev31probes/main.swift:11:11: error: value of type 'UIViewController' has no member 'badge'
 9 | let vc = sb.instantiateInitialViewController()
10 | print(vc?.titleLabel)
11 | print(vc?.badge ?? -1)
   |           `- error: value of type 'UIViewController' has no member 'badge'
12 | 
swiftc 退出码 = 1
（编译未通过：不运行）
```

两条报错是同一件事：`__kindof UIViewController` 的静态类型就是 `UIViewController`，
编译器不会替你下转型（§6）。这是本章少数**编译器站在你这边**的格子 —— 和 b09/r07 那条
「XML 里的名字没人拦」正好互补。

### 运行期现场（r01~r14）

**`probes/r01_no_such_storyboard.swift`** — `UIStoryboard(name: "NoSuchStoryboard", bundle: nil)`

```
########## r01_no_such_storyboard
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 134
--- stdout ---
准备取一个 bundle 里不存在的故事板 NoSuchStoryboard……
--- stderr ---
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: 'Could not find a storyboard named 'NoSuchStoryboard' in bundle NSBundle </private/var/folders/yy/0rcrdqxj5ldg_m__j6t3fn1c0000gn/T/iosdev31probes> (loaded)'
*** First throw call stack:
(
	0   CoreFoundation                      0x00007ff8004d0569 __exceptionPreprocess + 242
	1   libobjc.A.dylib                     0x00007ff800090116 objc_exception_throw + 62
	2   UIKitCore                           0x00007ff8066e816b -[UIStoryboard name] + 0
	3   probe                               0x000000010ec6d6bd $sSo12UIStoryboardC4name6bundleABSS_So8NSBundleCSgtcfCTO + 61
	4   probe                               0x000000010ec6d1d4 main + 276
	5   dyld                                0x000000010f102478 start_sim + 10
	6   ???                                 0x000000011709f345 0x0 + 4681495365
)
libc++abi: terminating due to uncaught exception of type NSException
Child process terminated with signal 6: Abort trap
```

**取不到就是抛，不是返回 nil** —— `UIStoryboard` 的 Swift 初始化器没法返回可选值。
栈里那帧 `$sSo12UIStoryboardC4name6bundleABSS_So8NSBundleCSgtcfCTO` 是初始化器的
`TO`（thunk）。注意它和 §4/§5 那条「没有入口点就返回 nil，不抛」是两件事，
主线里两份对照都有。

**`probes/r02_objectid_lookup.storyboard` + `.swift`** — 拿 XML 的 `id="OI-02-020"` 当 `storyboardIdentifier` 去取

```
########## r02_objectid_lookup
ibtool（storyboard）退出码 = 0，产物 = r02_objectid_lookup.storyboardc
--- ibtool 输出 ---
/* com.apple.ibtool.document.warnings */
/Volumes/mac004/code/programming/iosdev/examples/31_interface_builder/probes/r02_objectid_lookup.storyboard:sgToSecond: warning: Segues initiated directly from view controllers must have an identifier [9]
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 134
--- stdout ---
查找表键 = ["NamedScreen", "UIViewController-OI-02-020"]
用 storyboardIdentifier 取得到 = interface_builder.HostOI
再把 XML 里那个 id="OI-02-020" 当标识符用：
--- stderr ---
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: 'Storyboard (<UIStoryboard: 0x6000026103c0>) doesn't contain a view controller with identifier 'OI-02-020''
*** First throw call stack:
(
	0   CoreFoundation                      0x00007ff8004d0569 __exceptionPreprocess + 242
	1   libobjc.A.dylib                     0x00007ff800090116 objc_exception_throw + 62
	2   UIKitCore                           0x00007ff8066e8a6e -[UIStoryboard _instantiateInitialViewControllerWithCreator:storyboardSegueTemplate:sender:] + 0
	3   probe                               0x000000010daf5358 main + 2952
	4   dyld                                0x000000010df02478 start_sim + 10
	5   ???                                 0x000000010e8d9345 0x0 + 4539126597
)
libc++abi: terminating due to uncaught exception of type NSException
Child process terminated with signal 6: Abort trap
```

这一支还顺带把 §9 那条「退化」测出来了：查找表里那一格是 `UIViewController-OI-02-020` ——
没写 `storyboardIdentifier` 时键会**退化成「类名-objectID」**，
但那不是「objectID 本身可以当键」的意思（帧 2 那个方法名也说明查的是 identifier）。

**`probes/r03_outlet_no_property.storyboard` + `.swift`** — `<outlet property="noSuchProperty">`，类里没有这个属性

```
########## r03_outlet_no_property
ibtool（storyboard）退出码 = 0，产物 = r03_outlet_no_property.storyboardc
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 134
--- stdout ---
instantiate 过去了（控制器 nib 解完，连接还没开始）
--- stderr ---
*** Terminating app due to uncaught exception 'NSUnknownKeyException', reason: '[<interface_builder.HostNP 0x10f107070> setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key noSuchProperty.'
*** First throw call stack:
(
	0   CoreFoundation                      0x00007ff8004d0569 __exceptionPreprocess + 242
	1   libobjc.A.dylib                     0x00007ff800090116 objc_exception_throw + 62
	2   CoreFoundation                      0x00007ff8004d0059 -[NSException init] + 0
	3   Foundation                          0x00007ff800f3783f -[NSObject(NSKeyValueCoding) setValue:forKey:] + 278
	4   UIKitCore                           0x00007ff805a690a5 -[UIViewController setValue:forKey:] + 74
	5   UIKitCore                           0x00007ff805f25aac -[UIRuntimeOutletConnection connect] + 109
	6   CoreFoundation                      0x00007ff8004bd54f -[NSArray makeObjectsPerformSelector:] + 240
	7   UIKitCore                           0x00007ff805f14ce4 -[UINib instantiateWithOwner:options:] + 2163
	8   UIKitCore                           0x00007ff805a733c7 -[UIViewController loadView] + 643
	9   UIKitCore                           0x00007ff805a73814 -[UIViewController loadViewIfRequired] + 337
	10  probe                               0x000000010db78ca5 main + 437
	11  dyld                                0x000000010e002478 start_sim + 10
	12  ???                                 0x0000000119b25345 0x0 + 4726084421
)
libc++abi: terminating due to uncaught exception of type NSException
Child process terminated with signal 6: Abort trap
```

§12 抄的是它的帧 3–10（那几帧就是「崩在解视图 nib」的证词），这里补全 13 帧。
这一支的 stdout 只有一行，说明「控制器解出来了、连接还没开始」，
把 §11 那条分界钉在了崩溃栈上。

**`probes/r04_keypath_no_property.storyboard` + `.swift`** — `userDefinedRuntimeAttribute` 的 `keyPath="noSuchKey"`，属性不存在

```
########## r04_keypath_no_property
ibtool（storyboard）退出码 = 0，产物 = r04_keypath_no_property.storyboardc
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
instantiate 回来了，类型 = interface_builder.HostKP
视图照常加载：subviews = 0
这一支是跑完的（对照上面的运行退出码）—— 软失败与硬失败的分界就在这儿
--- stderr ---
2026-09-30 06:51:19.122 probe[31297:4901497] Failed to set (noSuchKey) user defined inspected property on (interface_builder.HostKP): [<interface_builder.HostKP 0x10e305df0> setValue:forUndefinedKey:]: this class is not key value coding-compliant for the key noSuchKey.
```

同样是 KVC 失败，**这一支 `rc=0`**：Inspector 赋值那一路把异常接住、只打一行 `NSLog`。
所以「同样的 KVC 为什么一次崩一次不崩」的答案是调用方包不包 `@try`，
而不是两条路的检查松紧不同。这一支也是本章唯一在 stderr 有字的探针 —— 主线里
凡是可能走到这条的路径都换成了「先问 `responds(to:)`」。

**`probes/r05_optional_iboutlet.storyboard` + `.swift`** — `@IBOutlet var titleLabel: UILabel?`（可选而非隐式解包）

```
########## r05_optional_iboutlet
ibtool（storyboard）退出码 = 0，产物 = r05_optional_iboutlet.storyboardc
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
instantiate 之后 titleLabel = nil
loadView 之后 titleLabel?.text = 连得上吗
Mirror 里这一项的类型 = Optional("Swift.Optional<__C.UILabel>")
```

连接照样发生（`loadView` 之后读得到 text），差别只在类型：`Optional<UILabel>` 而不是
`ImplicitlyUnwrappedOptional<UILabel>`，所以每次取值都要自己 `?`。
这和 §25 那句「`hostCard.view` 的 `type(of:)` 量到 `Swift.Optional<__C.UIView>`」是同一类
测量上的坑 —— 声明的可选性会进到反射里。

**`probes/r06_creator_no_super.storyboard` + `.swift`** — §13 的 creator 闭包里 `return HostCR()` 而没走 `super.init(coder:)`

```
########## r06_creator_no_super
ibtool（storyboard）退出码 = 0，产物 = r06_creator_no_super.storyboardc
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 134
--- stdout ---
准备让闭包返回一个 plain HostCR()……
  闭包被调用，收到的 coder = UINibDecoder
--- stderr ---
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Custom instantiated view controller must call -[super initWithCoder:]'
*** First throw call stack:
(
	0   CoreFoundation                      0x00007ff8004d0569 __exceptionPreprocess + 242
	1   libobjc.A.dylib                     0x00007ff800090116 objc_exception_throw + 62
	2   Foundation                          0x00007ff800efb7c0 _userInfoForFileAndLine + 0
	3   UIKitCore                           0x00007ff805f1256a -[UIClassSwapper initWithCoder:] + 998
	4   UIFoundation                        0x00007ff80509d3f8 UINibDecoderDecodeObjectForValue + 711
	5   UIFoundation                        0x00007ff80509d126 -[UINibDecoder decodeObjectForKey:] + 246
	6   UIKitCore                           0x00007ff805f199bf -[UIRuntimeConnection initWithCoder:] + 125
	7   UIFoundation                        0x00007ff80509d3f8 UINibDecoderDecodeObjectForValue + 711
	8   UIFoundation                        0x00007ff80509d602 UINibDecoderDecodeObjectForValue + 1233
	9   UIFoundation                        0x00007ff80509d126 -[UINibDecoder decodeObjectForKey:] + 246
	10  UIKitCore                           0x00007ff805f11bca -[NSCoder(UIIBDependencyInjectionInternal) _decodeObjectsWithSourceSegueTemplate:creator:sender:forKey:] + 447
	11  UIKitCore                           0x00007ff805f148cf -[UINib instantiateWithOwner:options:] + 1118
	12  UIKitCore                           0x00007ff8066e8973 -[UIStoryboard __reallyInstantiateViewControllerWithIdentifier:creator:storyboardSegueTemplate:sender:] + 285
	13  UIKitCore                           0x00007ff8066e8818 -[UIStoryboard _instantiateViewControllerWithIdentifier:creator:storyboardSegueTemplate:sender:] + 97
	14  UIKitCore                           0x00007ff80541885d block_destroy_helper.22 + 9949
	15  probe                               0x000000010f5b59c9 main + 329
	16  dyld                                0x000000010fa02478 start_sim + 10
	17  ???                                 0x0000000112790345 0x0 + 4604887877
)
libc++abi: terminating due to uncaught exception of type NSException
Child process terminated with signal 6: Abort trap
```

§13 抄的是它的帧 3/4/11/12（那几帧就够说明「闭包的返回值被 `UIClassSwapper` 接住后
要求 `super.init(coder:)`」），这里补全 18 帧。栈里 `-[UIClassSwapper initWithCoder:]`
与反复出现的 `UINibDecoderDecodeObjectForValue` 是这一支的特征；
报错消息把要求写得很直白：闭包收到的那台解码器**必须用掉**，
`init(coder:)` 得转给 `super`。

**`probes/r07_unrecognized_selector.storyboard` + `.swift`** — 把 b09 那个错选择器真派发一次

```
########## r07_unrecognized_selector
ibtool（storyboard）退出码 = 0，产物 = r07_unrecognized_selector.storyboardc
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 134
--- stdout ---
表里的选择器名 = didTapp:，类里实现的是 didTap:
下面这一行就是 unrecognized selector 的现场：
--- stderr ---
*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[interface_builder.HostSL didTapp:]: unrecognized selector sent to instance 0x109407340'
*** First throw call stack:
(
	0   CoreFoundation                      0x00007ff8004d0569 __exceptionPreprocess + 242
	1   libobjc.A.dylib                     0x00007ff800090116 objc_exception_throw + 62
	2   CoreFoundation                      0x00007ff8004e606e +[NSObject(NSObject) instanceMethodSignatureForSelector:] + 0
	3   UIKitCore                           0x00007ff8064e572f -[UIResponder doesNotRecognizeSelector:] + 266
	4   CoreFoundation                      0x00007ff8004d4ecc ___forwarding___ + 1459
	5   CoreFoundation                      0x00007ff8004d7288 _CF_forwarding_prep_0 + 120
	6   probe                               0x000000010862e4fe main + 3022
	7   dyld                                0x0000000108b02478 start_sim + 10
	8   ???                                 0x0000000114758345 0x0 + 4638212933
)
libc++abi: terminating due to uncaught exception of type NSException
Child process terminated with signal 6: Abort trap
```

这一支的写法值得抄进笔记：它**自己当派发者** —— 先从控件表里把那个错名字读出来
（`actions(forTarget:forControlEvent:)` → `"didTapp:"`），再
`perform(NSSelectorFromString(selName), with: 按钮)` 打出去。
主线 §16/§25 量过「没有 `UIApplication` 就没有派发」，这里绕过的就是那一环，
所以炸点才是真实的。栈帧 3 是
`-[UIResponder doesNotRecognizeSelector:]`，帧 4–5 是消息转发的桩 —— 这就是
「点按钮就崩，栈里只有一行 `HostSL didTapp:`」那种现场的最小形状。

**`probes/r08_show_no_container.storyboard` + `.swift`** — `kind="show"` 的发起者 `parent == nil`、`navigationController == nil`

```
########## r08_show_no_container
ibtool（storyboard）退出码 = 0，产物 = r08_show_no_container.storyboardc
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
parent = nil，navigationController = nil
performSegue(withIdentifier: "goX")（这条 segue 的 kind 是 show）：
之后：seen = ["prepare: goX → interface_builder.HostKX"]
presentedViewController = nil
--- stderr ---（空）
```

`prepare` 照跑（那是第一段），**转场那段没有落脚点**：既没入栈也没呈现，
而且不抛异常。§17 结尾提到这条边界就是它。真实 app 里UIKit 会给一个
「没有容器时的 show」退化成 `modalPresentationStyle`，本章量到的是这条路在
headless 里静悄悄 —— 别把它读成「会崩」。

**`probes/r09_dup_identifier_runtime.storyboard` + `.swift`** — 两条 segue 用同一个 `identifier="dup"`

```
########## r09_dup_identifier_runtime
ibtool（storyboard）退出码 = 0，产物 = r09_dup_identifier_runtime.storyboardc
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
prepare 记账 = ["prepare: dup → interface_builder.HostZ1"]
栈里现在 = ["interface_builder.HostNU", "interface_builder.HostZ1"]
XML 里两条 segue 的 id 分别是 sgDupA（→ HostZ1）与 sgDupB（→ HostZ2）
--- stderr ---（空）
```

按 identifier 发起时**第一条匹配 wins**（`HostZ1`），第二条永远不会被这个名字取到。
`ibtool` 不查重（b07），所以这一条只能靠运行时或代码审查抓 —— 也就是 §18 里
「identifier 是你自己唯一的名字索引」那句的实际代价。

**`probes/r10_unwind_by_identifier.storyboard` + `.swift`** — 正规写法下用控制器的 `performSegue` 触发 unwind

```
########## r10_unwind_by_identifier
ibtool（storyboard）退出码 = 0，产物 = r10_unwind_by_identifier.storyboardc
--- ibtool 输出 ---（空）
--- swiftc 输出 ---（空）
swiftc 退出码 = 0
运行退出码 = 0
--- stdout ---
第一步 入栈：栈深 = 2，unwindButton = UIButton
那张表里的 target：["UIStoryboardUnwindSegueTemplate"]
  touchUpInside 上的动作：["perform:"]
第二步 拿那条线的 identifier 去控制器的 performSegue：
  Beta 的 prepare 也跑了：segue=backToAlpha 类名=UIStoryboardSegue
  unwindToAlpha 被调了：source=interface_builder.BetaUN destination=interface_builder.AlphaUN identifier=backToAlpha
没有抛异常，走到了这一行。
之后：栈深 = 2 栈顶 = interface_builder.BetaUN
     beta.navigationController = Optional("还在容器里")
     beta.view.superview = nil
第三步 再点一次同一个 identifier（此时 beta 已经在栈外，如果它被弹掉了的话）：
  Beta 的 prepare 也跑了：segue=backToAlpha 类名=UIStoryboardSegue
  unwindToAlpha 被调了：source=interface_builder.BetaUN destination=interface_builder.AlphaUN identifier=backToAlpha
也还没抛？栈深 = 2
--- stderr ---（空）
```

这一支是 §20 那次纠错的来源（主线里把它升级成了两条触发路径的完整账本）。
三个要点：**查得到**（没抛）；`prepare` 是**发起方**的；「弹」没发生 ——
`beta.navigationController` 还在、`superview` 是 `nil`。第三步再点一次照样不抛，
因为这条线根本不依赖「beta 在不在屏幕上」。

**`probes/r11_owner_nil.xib` + `.swift`** — `instantiate(withOwner: nil, …)`，XIB 里有两条连在 File's Owner 上的 outlet

原文（含两条 9 帧栈）见 §22。要点：`rc=134`，异常是
`[<NSObject 0x…> setValue:forUndefinedKey:] … key rootView` —— owner 为 `nil` 时 UIKit
拿 plain `NSObject` 顶替，然后照 KVC 问那个 key。

**`probes/r12_owner_wrong_type.xib` + `.swift`** — `instantiate(withOwner: NSObject(), …)`

原文见 §22。`rc=134`、同一句话。两支合起来说明：**连接问的是 key，不是类型声明**，
XIB 里那个 `customClass` 只是给 Xcode 的 Inspector 用的提示。

**`probes/r13_xib_with_device.xib` + `.swift` / `probes/r14_xib_without_device.xib` + `.swift`** — 只差 `<document>` 底下那一行 `<device id="retina6_1" orientation="portrait" appearance="light"/>`

```
########## r13_xib_with_device
ibtool（xib）退出码 = 0，产物 = r13_xib_with_device.nib
运行退出码 = 0
--- stdout ---
顶层对象 = ["UIView"]
顶层视图的 frame = (0.0, 0.0, 414.0, 896.0)
XML 里那一格写的是 600.0×600.0；UIScreen.main.bounds = (0.0, 0.0, 402.0, 874.0)
titleLabel.text = 卡片标题，它的 frame = Optional((24.0, 24.0, 200.0, 30.0))

########## r14_xib_without_device
ibtool（xib）退出码 = 0，产物 = r14_xib_without_device.nib
运行退出码 = 0
--- stdout ---
顶层对象 = ["UIView"]
顶层视图的 frame = (0.0, 0.0, 600.0, 600.0)
XML 里那一格写的是 600.0×600.0；UIScreen.main.bounds = (0.0, 0.0, 402.0, 874.0)
titleLabel.text = 卡片标题，它的 frame = Optional((24.0, 24.0, 200.0, 30.0))
```

（这两支的 ibtool / swiftc 输出均为空、退出码均为 0，§21 抄的是全量原文。）
两份 `<rect>` 都写 `600×600`：有 `<device>` 的那份交回 `414×896`（那台设备的高），
没有的那份交回 `600×600`。**顶层视图那一格从来没被读**，读到的是设备参数。
`Card.xib` 属于 r14 那一类，所以主线量到 600×600。

## 「跑起来没反应」排查表

这张表是本章 26 节、220 条断言的用法说明：**症状 → 在本机量到的真因 → 证据位置**。
左列全是书里（以及六年间的论坛帖里）出现过的那种「怎么办在线等」，
右两列是本章能给出的、可复现的答案。凡列「零诊断」的行，意思是 `ibtool` 退出码 0
且输出为空 —— 编译这一步永远不会替你检查界面文件里的名字。

| 症状 | 本机量到的真因 | 证据 |
| --- | --- | --- |
| outlet 全是 `nil`，一句报错都没有 | `customClass` 忘了填 / 填错 / `customModule` 不匹配 → 静默退回 plain `UIViewController` | §8；探针 b01/b02 |
| 崩在 `this class is not key value coding-compliant for the key xxx.` | `<outlet property="xxx">` 那个属性在类里不存在（KVC 硬失败） | §12；探针 r03 |
| 同上，但用的是 XIB | `owner:` 传了 `nil` 或类型不含那个 key —— 同一句话，问的是 key | §22；探针 r11/r12 |
| Inspector 填的值运行时读不到，但也没崩 | `keyPath` 写的属性不存在（KVC 被包起来，只打一行 `NSLog`） | §14；探针 r04 |
| outlet 是 `nil`，可类名明明对 | 那条线**没编进去**：`destination` 指向不存在的对象 id（真·静默） | 探针 b06 |
| 填了 `@IBInspectable` 却没格子 / 没标却有值 | `@IBInspectable` 只管 Xcode 给不给格子；运行时起作用的是 KVC | §14 |
| 按钮点了没反应 | 表里 target/selector 都读得出，但 headless 没有派发者（`UIApplication.shared == nil`） | §16 |
| 一点就崩 `-[… didTapp:]: unrecognized selector` | XML 里 selector 写错（`ibtool` 不校验），或方法名改了没重连线 | §15；探针 b09 → r07 |
| `has no segue with identifier 'xxx'` | 那条连接根本没编出来（`<exit>` 位置错、或压根没写线），**不是** unwind 不能用 `performSegue` | §20；探针 b11、对照 r10 |
| segue 跑了 `prepare` 却没跳转 | 发起者没有容器（`parent == nil`），转场段没有落脚点，且不抛 | §17；探针 r08（XML 见 b08） |
| 两条同名 identifier 只有一条生效 | 按 identifier 发起取**第一条匹配**，`ibtool` 不查重 | §18；探针 r09（XML 见 b07） |
| `instantiateViewController(withIdentifier:)` 抛 `doesn't contain …` | 拿的是 XML 的 `id`；查找表里的键是 `storyboardIdentifier`（没写才退化成 `类名-objectID`） | §9；探针 r02 |
| 场景在 Xcode 里还在，运行时找不到 | 不可达（无入口、无 identifier、无人连线）→ `ibtool` **不生成它的 nib** | §3；探针 b03/b04 |
| 某个场景取不到，但它在 XML 里明明写着 | 它被 `relationship` 收养了：只有视图 nib，得顺着容器走 | §10 |
| 故事板取出来 `nil`（不崩） | 没有入口点：`initialViewController` 那一格缺 → 查找表少 `UIStoryboardDesignatedEntryPointIdentifier` | §5（NoEntry）；对照 r01 |
| 加了约束，frame 还是设计稿那一格 | `translatesAutoresizingMaskIntoConstraints == true`，XML 那两条 `<constraints>` 没人听 | §23 |
| XIB 出来的视图尺寸和画布不一样 | 顶层视图那格 `<rect>` 不生效（没有 `<device>` 时是 600×600） | §21；探针 r13/r14 |
| 图标位置是空白，日志里什么都没有 | `UIImage(named:)` 查不到就是 `nil`，不抛、不写 stderr | §24 |
| 图标糊 | 框 48 pt、素材 4 pt（`scaleAspectFit` 放大 12 倍） | §24 |
| 图片比预期清晰/小，`UIImage` 却是 12×12 | 倍率替换发生在 UIKit 装载处，`contentsOfFile:` 也一样；`scale` 来自文件名不是屏幕 | §24 |
| `type="number"` 配 `<integer>` 编不过？ | 不会 —— 那格合法。编不过的是 `type` 与取值子元素**对不上**（`rc=255`，报 `ibtoold` 自己的断言） | §14；探针 b05 / b10 |
| `File's Owner` 里的初始化代码没跑 | `awakeFromNib` 只发给「从 nib 里解出来的对象」；owner 是交进来的（AppKit 习惯搬到 iOS 会静默失效） | §21 |
| 代码写的界面根视图是 `(0,0,0,0)` | `loadView` 里 `view = UIView()` 之后没人改它；被改成屏幕尺寸的一刻是**挂进窗口** | §25 |
| SwiftUI 改了值看不见 | 换 `rootView` 只算赋值，得走到布局那一轮；`body` 不是每帧重算 | §25 |
| 安全区全是 0 / 约束算出的 y 正好等于常数 | 视图从没进过窗口；上屏后 62 与 34 立刻出现 | §23/§25 |

## 本章能带走的东西

- 「这张 XML 画出来的界面怎么和 Swift 接上线」被拆成三段可查的账：
  **编译产物里有什么**（§1–§3）、**运行时解出什么、什么时候解**（§4–§14）、
  **线和 segue 在运行时是谁**（§15–§22）、**框与尺寸有几格真生效**（§23–§25）。
- 界面文件与代码之间只有三种耦合，每种都能当场验：
  **类名**（三段字符串，问的是运行时，§7/§8）、**key**（一次 KVC 赋值，§11/§12/§14）、
  **名字**（selector 字符串或 segue identifier，§15/§17/§18/§20）。
  除这三样，界面文件里的一切都只是给 Xcode 画布看的提示。
- 「静默」是有名有姓的：`ibtool` 零诊断（b01/b02/b05/b06/b07/b08/b09/b11）、
  运行时静默退化（§8 退回 plain `UIViewController`、§24 图像 `nil`、§17/r08 转场没落脚点）、
  以及唯一一种「声音都没有」的硬失败对照（r03 崩 / r04 只打一行 / b06 静默）。
  **排查表里右列凡是写「零诊断」的行，都必须在运行时自己加断言。**
- headless 的三条边界（不派发、不弹栈、不算 `body`）来自同一个缺失的单例，
  而不是界面文件的机制。任何一条「没生效」先问这一格是不是依赖那个不存在的运行循环。
- 本章的两处自我纠正值得留着当方法：§14 那条「`<integer>` 会让 ibtool 崩」被 b05/b10 推翻，
  §20 那条「unwind 不能用 `performSegue`」被修好 XML 的 r10 推翻。
  两处的共同点是：**当初的结论来自一次真实观察，但把相关当成了因果**
  （`rc=255` 的是 type 与子元素不匹配；崩的原因是 `<exit>` 放错位置）。
  这就是本章坚持「每条 claim 配一条可跑断言或一支探针原文」的理由。
