# 13 · SwiftUI ⇄ UIKit 互操作：UIViewRepresentable / Coordinator / UIHostingController

> 示例：`examples/13_swiftui_uikit_interop/main.swift`
> 实测输出见 `build/13_swiftui_uikit_interop/stdout.debug.txt`

本教程是「SwiftUI 为主、UIKit 补充」。两条线迟早要交汇：你可能要在 SwiftUI 界面里用
一个还没有 SwiftUI 版的老 UIKit 控件（地图、WebView、自定义绘制视图），也可能要在一个
既有的 UIKit App 里嵌一块 SwiftUI。这就是**互操作**，两条通道：

- **UIKit → SwiftUI**：`UIViewRepresentable` / `UIViewControllerRepresentable`
- **SwiftUI → UIKit**：`UIHostingController`

## 1) UIKit → SwiftUI：UIViewRepresentable

把一个 `UIView` 包成 SwiftUI `View`，要实现两个方法：

```swift
struct WrappedLabel: UIViewRepresentable {
    var text: String
    let log: EventLog

    func makeCoordinator() -> Coordinator { Coordinator(log: log) }

    func makeUIView(context: Context) -> UILabel {      // 创建底层 UIView（只一次）
        context.coordinator.note("make:\(text)")
        let l = UILabel(); l.text = text; return l
    }
    func updateUIView(_ uiView: UILabel, context: Context) {   // 状态变化时同步（可多次）
        context.coordinator.note("update:\(text)")
        uiView.text = text
    }
    final class Coordinator { … }
}
```

三个角色的分工：

- **`makeUIView(context:)`**：**创建**底层 `UIView`，SwiftUI 只在视图首次出现时调**一次**。
  这里只做「建视图」，不要放会随状态变的配置。
- **`updateUIView(_:context:)`**：SwiftUI 每次「这个 Representable 相关的状态变了」都会
  调它，把**最新值同步到已存在的 UIView**。所有依赖外部状态的配置都放这里。
- **`Coordinator`**：承接 UIKit 的**命令式回调**（delegate、target-action），把它翻译回
  SwiftUI（改 `@Binding`、调闭包）。见第 3 节。

### headless 怎么验证真实生命周期

`makeUIView`/`updateUIView` **需要一次真实的渲染 pass** 才会被调用——光 `loadView` +
`layoutIfNeeded` 不够。示例的做法：把宿主视图放进一个 `UIWindow`（`isHidden = false`，
但**从不 `makeKeyAndOrderFront`**），再**有界地**抽几次 run loop（每次带 0.02s 超时，
抽满即退出，绝不无限等待、不弹窗）：

```swift
func renderOnce<V: View>(_ host: UIHostingController<V>, …, spins: Int = 8) {
    let win = UIWindow(frame: …)
    win.rootViewController = host
    win.isHidden = false
    host.view.frame = win.bounds
    for _ in 0..<spins {
        host.view.setNeedsLayout(); host.view.layoutIfNeeded()
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.02))
    }
}
```

这样 SwiftUI 会**真的**调用 `makeUIView`，把 `UILabel` 建进一个 `PlatformViewHost` 里。
示例用深度优先搜索在视图树里找到那个 `UILabel` 来断言：

```
-- UIViewRepresentable：makeUIView 建出真实 UILabel --
  找到的底层视图 = UILabel
  ok   SwiftUI 树里真的出现了一个 UILabel（makeUIView 被调用）
  ok   UILabel 的文本 = 初始值「第一版」
  ok   Coordinator 记录了 make（makeUIView 走的是它）
  ok   Coordinator 记录了 update（updateUIView 也被调用）
```

渲染后的真实层级长这样（探测实验得到）：

```
_UIHostingView<WrappedLabel>
  PlatformViewHost<PlatformViewRepresentableAdaptor<WrappedLabel>>
    UILabel text=第一版
```

`PlatformViewHost` 就是 SwiftUI 用来托管你的 UIKit 视图的容器。

## 2) updateUIView：改状态，UIView 同步

更新 `rootView` 为一个带新值的 Representable，再渲染一次：

```swift
host.rootView = WrappedLabel(text: "第二版", log: log)
renderOnce(host)
findLabel(in: host.view)?.text     // "第二版"
```

```
-- updateUIView：改 rootView，UILabel 跟着变 --
  ok   rootView 换成「第二版」后，同一个 UILabel 文本被 updateUIView 同步
  ok   Coordinator 记录到带新文本的 update
```

注意：**同一个** `UILabel` 实例被复用（`makeUIView` 不会再调），只是 `updateUIView`
把它的 `text` 改成了「第二版」。这就是为什么「随状态变的配置」必须放 `updateUIView`
而不是 `makeUIView`——后者只跑一次，状态再变它也不会重跑。

## 3) Coordinator：UIKit 命令式回调 → SwiftUI

UIKit 的交互是**命令式**的：`UITextFieldDelegate`、按钮的 `target-action`、
`UIScrollViewDelegate`……这些回调发生时，SwiftUI 的声明式世界怎么知道？答案是
`Coordinator`。

```swift
func makeCoordinator() -> Coordinator { Coordinator(log: log) }

final class Coordinator: NSObject, UITextFieldDelegate {
    @Binding var text: String
    func textField(_ tf: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString s: String) -> Bool {
        // 把 UIKit 的回调翻译回 SwiftUI：改 @Binding
        text = (tf.text ?? "") + s
        return true
    }
}
```

- `makeCoordinator()` 在 `makeUIView` **之前**被调一次，SwiftUI 持有这个 Coordinator，
  并通过 `context.coordinator` 传给 `make/update`。
- Coordinator 通常持有 `@Binding` 或回调闭包，在 delegate 方法里改它——状态一变，
  SwiftUI 就重新求值 `body`、`updateUIView` 又把新值同步回 UIView，形成闭环。

示例里 Coordinator 只记录事件（不接真实 delegate），验证它被创建、被 `make/update` 用到：

```
-- makeCoordinator：不依赖渲染就能创建 --
  ok   Coordinator 由 makeCoordinator 创建，持有外部 log
```

`makeCoordinator()` 本身**不需要渲染**就能直接调用，所以这条能脱离 run loop 单独测。

> **UIViewControllerRepresentable** 完全同理，只是包的是 `UIViewController`
> （`makeUIViewController` / `updateUIViewController`），用于嵌 `UINavigationController`、
> 相机、`UIPageViewController` 这类控制器级的东西。

## 4) SwiftUI → UIKit：UIHostingController

反方向：把一块 SwiftUI 视图塞进 UIKit。桥就是 `UIHostingController`（第 08 章见过它是
SwiftUI 的落地容器）：

```swift
struct Badge: View {
    var title: String
    var body: some View { Text(title).font(.headline) }
}
let uiHost = UIHostingController(rootView: Badge(title: "A"))

// 当普通子控制器嵌进一个 UIKit 控制器
let containerVC = UIViewController()
containerVC.loadViewIfNeeded()
uiHost.view.translatesAutoresizingMaskIntoConstraints = false
containerVC.addChild(uiHost)
containerVC.view.addSubview(uiHost.view)
uiHost.didMove(toParent: containerVC)

// 更新那块 SwiftUI 内容：直接改 rootView
uiHost.rootView = Badge(title: "B")
```

```
-- UIHostingController：SwiftUI 视图塞进 UIKit --
  ok   宿主 view 是 _UIHostingView
  ok   rootView 是我们塞进去的 Badge
  ok   UIHostingController 作为子控制器嵌进了 UIKit 控制器
  ok   父子关系已建立
  ok   改 rootView 即更新嵌入的 SwiftUI 内容
```

要点：

- `UIHostingController` 就是个普通的 `UIViewController`，可以用标准的
  **child view controller** 三件套（`addChild` → `addSubview` → `didMove(toParent:)`）
  嵌进任何 UIKit 界面。
- 更新内容不用重建控制器，**改 `rootView` 即可**（`rootView` 是可写属性）。
- 别忘了 `translatesAutoresizingMaskIntoConstraints = false` 并用 Auto Layout 约束它，
  否则那块 SwiftUI 视图不会跟着 UIKit 布局走。

## 什么时候用哪条通道

| 场景 | 用 |
| --- | --- |
| SwiftUI 界面里要用某个只有 UIKit 版的控件 | `UIViewRepresentable` |
| 要嵌一整个 UIKit 控制器（导航/相机/分页） | `UIViewControllerRepresentable` |
| UIKit 控件的 delegate/target-action 要驱动 SwiftUI 状态 | `Coordinator` + `@Binding` |
| 既有 UIKit App 里想局部改用 SwiftUI | `UIHostingController` 当子控制器 |
| 全新 App | 直接 SwiftUI，别自找互操作麻烦 |

## headless 验证的边界

本示例是全套里**唯一**触碰渲染循环的地方，而且是**有界**的（抽满 8 次、每次 0.02s
超时、绝不 `makeKeyAndOrderFront`、绝不进入无限 run loop）。即便如此，它验证的是
「makeUIView 建了 UILabel、updateUIView 同步了新值、Coordinator 被创建并使用、
UIHostingController 能嵌套并更新」这些**确定性事实**，不去断言渲染帧数、时序等
环境相关数字——这仍是本教程「只断言性质」的纪律。

## 坑清单

| 现象 | 原因 |
| --- | --- |
| `makeUIView` 里配的样式，状态变了不更新 | 随状态变的配置要放 `updateUIView`，`makeUIView` 只跑一次 |
| UIKit 控件的编辑不回写 SwiftUI | 没有 Coordinator 接 delegate、没有 `@Binding` 回写 |
| 嵌进 UIKit 的 SwiftUI 视图尺寸不对 | 忘了关 `translatesAutoresizingMaskIntoConstraints` + 加约束 |
| 更新 SwiftUI 内容却重建了整个控制器 | 不必重建，改 `uiHost.rootView` 即可 |
| Representable 里的 UIView 反复被重建 | `updateUIView` 里又 `new` 了一个视图；应改已有的那个 |

## 小结

- **UIKit → SwiftUI**：`UIViewRepresentable`（`makeUIView` 建一次 / `updateUIView`
  每次同步）；`Coordinator` 把 UIKit 的命令式回调翻译回 SwiftUI 的 `@Binding`。
- **SwiftUI → UIKit**：`UIHostingController(rootView:)`，当子控制器嵌入，改 `rootView`
  即更新。
- 真实生命周期需要一次渲染 pass；本示例用「有界抽 run loop」headless 地跑通了
  make/update/coordinator 全链路。
- 至此 **SwiftUI 主线（08–13）完成**。第四篇（14–16）转入 **UIKit 补充**：视图体系与
  Auto Layout、控件与列表、手势与响应链——这些是 SwiftUI 底层依赖、也是读懂老代码的
  必备功底。
