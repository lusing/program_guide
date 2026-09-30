# 22 · 滚动视图、容器控制器与高级控件

> 示例：`examples/22_scroll_containers_controls/main.swift`
> 实测输出见 `build/22_scroll_containers_controls/stdout.debug.txt`

第 14 章讲了视图与 Auto Layout，第 15 章讲了表格/集合视图与常用控件的属性读写，第 21 章补了布局进阶。
这一章把 UIKit 剩下的一整块骨架补齐——它们是教材里独立成章、实战里天天碰到的东西：

```
UIScrollView          表格/集合视图的父类：contentSize / contentOffset / inset / 分页 / 缩放
容器控制器            UINavigationController、UITabBarController、自定义 containment
高级控件              UIPickerView、UIDatePicker、UIAlertController、UIStepper、
                     UISegmentedControl、UIPageControl、UIProgressView、
                     UIActivityIndicatorView、UISearchBar、UIImageView 帧动画
ImageIO              自己合成一张多帧 GIF 并读回来（图片库在做的事）
```

headless 说明：这些对象**都不依赖窗口**就能创建、配置、读回状态；只有两处需要 `UIWindow` +
`rootViewController`——看安全区自动调整（第 2 节）和看 `present` 的边界（第 9 节），用法与第 21 章
一致。本章全程不等待用户点击。

## 1) contentSize / contentOffset：能滚多少是算出来的，但 setter 不做夹取

`UIScrollView` 只有一个几何规则：**可滚动范围 = contentSize − bounds.size**，而
`contentOffset` 就是可视区域在内容坐标系里的左上角。因为滚动视图是「把自己 bounds 的原点
挪到内容里某个位置」实现的，`bounds.origin` 与 `contentOffset` 是同一个数。

```swift
let scroll = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
scroll.contentSize = CGSize(width: 320, height: 2000)     // 纵向可滚 2000-480 = 1520

scroll.contentOffset = CGPoint(x: 0, y: 500)              // 范围内
scroll.contentOffset = CGPoint(x: 0, y: 99999)            // 超出最大可滚位置
scroll.contentOffset = CGPoint(x: 0, y: -500)             // 负方向
```

```
-- UIScrollView：contentSize / contentOffset --
  bounds=(320.0, 480.0) contentSize=(320.0, 2000.0)
  可滚动的最大 offset.y = contentSize.height - bounds.height = 1520.0
  ok   contentSize 比 bounds 大才会产生滚动
  设 offset=(0,500) 之后 contentOffset = (0.0, 500.0)
  ok   范围内直接生效
  设 offset=(0,99999) 之后 contentOffset = (0.0, 99999.0)
  ok   裸视图上超界 offset 不被夹（写多少读回多少）
  设 offset=(0,-500)（bounces=true）之后 contentOffset = (0.0, -500.0)
  ok   负方向也不夹， bounds.origin 就是 contentOffset
  ok   UIScrollView 的 bounds.origin 与 contentOffset 是同一个数
  contentSize == bounds 时设 offset=(0,100) → (0.0, 100.0)（内容不比视口大，滚不动）
  ok   即使没有可滚空间，属性写入仍然生效（不能靠它判断边界）
```

这是本章最需要修正直觉的一条。**「offset 会被夹在可滚范围内」是滚动循环的行为，不是属性 setter
的行为**：直接赋值 `contentOffset`（以及 `setContentOffset(_:animated:)`）在实测中写多少读回多少，
连 `contentSize == bounds`（根本没有可滚空间）都不拦。为了排除「没挂窗口所以不生效」这种解释，
我们额外用探针把同一个 scroll view 挂进窗口，再 `layoutIfNeeded()` 并抽干 run loop，
`99999` 和 `-500` 依然原样读回——夹取发生在有输入/动画驱动的滚动过程里，不在这两个 setter 里。

推论：
- 想知道「还能不能滚」，自己算 `contentSize.height - bounds.height`，别靠写超界值再读回来试探。
- 越界写不会报错，但界面会「空白」——`contentOffset` 超出内容范围时你看到的是 `backgroundColor`。
- 需要保证落在合法区间时，先 `min(max(offset, 0), maxOffset)` 再赋值。

`NaN` 是唯一会把进程带走的取值。探针（一次性，跑完即删）实测：

```swift
sv.contentOffset = CGPoint(x: CGFloat.nan, y: 0)   // 当场抛异常，不是等布局
```

stderr 原文是一整行，下面按可读性拆行、略去地址与偏移：

```
*** Terminating app due to uncaught exception 'CALayerInvalidGeometry',
    reason: 'CALayer bounds contains NaN: [nan 0; 320 480]. Layer: <CALayer:…>'
    -[CALayer setBounds:] + 371
    -[UIView _backing_setBounds:] + 86
    -[UIView(Geometry) setBounds:] + 431
    -[UIScrollView setBounds:] + 1199
    -[UIScrollView setContentOffset:] + 1076
    main
```

调用栈说明它是在 `setContentOffset` **同步**下推 `bounds` 时被 CoreAnimation 的几何校验拦住的，
所以不是「布局时才崩」，调试时断点直接打在赋值行即可。

顺带一个编译期的坑：`CGPoint(x: .nan, y: 0)` 编不过，因为 `.nan` 同时是 `CGFloat` 和 `Double`
的静态成员，编译器无法推断：

```
error: ambiguous use of 'nan'
```

写成 `CGFloat.nan` / `CGFloat.infinity` 就行。

要点：

- `contentOffset` 与 `bounds.origin` 是同一个值；`frame` 不变。
- 属性 setter **不夹取**越界值；只有滚动循环（手势、动画、`scrollRectToVisible`）才夹。
- `setZoomScale` 反过来**会**夹（见第 3 节），别把两者的语义混为一谈。
- `NaN` 立刻崩，`Infinity` 也属于同一族几何非法值。

## 2) contentInset 与 adjustedContentInset：安全区要挂进窗口才加得上

`contentInset` 是应用层的留白（你写的），`adjustedContentInset` 是**只读**的最终留白
（你写的 + 系统按安全区加上的）。二者的差只在 scroll view 已经进入窗口、有安全区可参考时才出现。

```swift
let s2 = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
s2.contentSize = CGSize(width: 320, height: 2000)
s2.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 40, right: 0)
// 裸视图：adjusted == content
s2.contentInsetAdjustmentBehavior = .never
s2.contentInsetAdjustmentBehavior = .automatic
```

```
-- UIScrollView：inset、contentInsetAdjustmentBehavior、paging、zoom --
  contentInset = UIEdgeInsets(top: 20.0, left: 0.0, bottom: 40.0, right: 0.0)
  adjustedContentInset = UIEdgeInsets(top: 20.0, left: 0.0, bottom: 40.0, right: 0.0)（contentInset + 安全区；裸视图安全区为 0）
  contentInsetAdjustmentBehavior = 0（0=automatic 1=scrollableAxes 2=never 3=always）
  ok   contentInset 是可读写的应用层 inset
  置为 .never 之后 adjustedContentInset = UIEdgeInsets(top: 20.0, left: 0.0, bottom: 40.0, right: 0.0)
  ok   automatic 下没挂进窗口 → adjusted 就等于 contentInset（20.0）
```

现在把 scroll view 放进 `UIWindow` 的根控制器视图里，让布局真跑一轮。`contentInset` 保持为 0，
但窗口有状态栏/灵动岛的安全区：

```swift
let hostWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
hostWindow.isHidden = false
let hostVC = UIViewController()
hostWindow.rootViewController = hostVC
let s2b = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
s2b.contentSize = CGSize(width: 320, height: 2000)
hostVC.view.addSubview(s2b)
hostWindow.layoutIfNeeded()
for _ in 0..<4 { RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.02)) }
```

```
  挂进窗口：window.safeAreaInsets.top=62.0 → contentInset=UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0) adjustedContentInset=UIEdgeInsets(top: 62.0, left: 0.0, bottom: 0.0, right: 0.0)
  …同一轮布局把 contentOffset 也移到了 (0.0, -62.0)（bounds.origin 跟着变）
  ok   adjusted = contentInset + 安全区（只有挂进窗口才有安全区可加）
  ok   automatic 会把 offset 抬到 -adjusted.top，让内容顶部正好落在安全区下面
  改成 .never 并重新布局 → contentOffset=(0.0, 0.0) adjustedContentInset=UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
```

这段是第 14 章「安全区」在滚动视图上的具体体现，也是最容易看走眼的地方：

- 系统不止把 `adjustedContentInset.top` 加到 62，还**顺手把 `contentOffset.y` 改成 `-62`**，
  于是内容的第一行正好落在安全区下方——这就是「表格顶部不会被状态栏压住」的实现方式。
- 因此「读到的 `contentOffset` 是负数」不是 bug，而是 automatic 调整的结果。做滚动位置恢复
  （保存/还原 offset）时，一定要意识到基准点是 `-adjustedContentInset.top`，不是 0。
- 四个取值：`.automatic`（由系统按场景决定）、`.scrollableAxes`（只在可滚的轴上加）、
  `.never`（完全不加，第 14 章里「列表顶到状态栏」就是这么来的）、`.always`（即使不可滚也加）。
  `contentInsetAdjustmentBehavior` 的原始值是 `0/1/2/3`。

要点：

- `contentInset` 可写、`adjustedContentInset` 只读；后者 = 前者 + 安全区贡献。
- 想让系统别碰你的 inset：`.never`；这是 scroll view 嵌在自定义布局里时最常设的一项。
- 判定 inset 是否生效要看 `adjustedContentInset`，不要看 `contentInset`。

## 3) 分页与缩放：一个不即时吸附，一个必须有 delegate

```swift
s2.isPagingEnabled = true
s2.contentOffset = CGPoint(x: 0, y: 700)
```

```
  isPagingEnabled=true 之后立刻读 offset = (0.0, 700.0)（非动画设置不会立刻吸附）
```

`isPagingEnabled` 改变的是**滚动结束时的对齐规则**（一页 = 一个 `bounds.width`），
它不会在你赋值的那一刻把 offset 吸附到整页；吸附同样属于滚动循环，与第 1 节同源。
`UIPageViewController` 的分页翻页、`UIScrollView` 的手势翻页都是「滚动减速结束时对齐」实现的。

缩放是三件事的组合：`minimumZoomScale`/`maximumZoomScale` 给出范围，
`delegate` 的 `viewForZooming(in:)` 指出**缩放谁**，`zoomScale` 是结果。缺 delegate 时
两个边界值都是 1，`setZoomScale` 完全无效——这是最常见的「缩放没反应」原因。

```swift
let zoomScroll = UIScrollView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
let zoomable = UIView(frame: CGRect(x: 0, y: 0, width: 600, height: 600))
zoomScroll.addSubview(zoomable)
zoomScroll.contentSize = CGSize(width: 600, height: 600)
// delegate 实现 viewForZooming(in:) → 返回 scrollView.subviews.first
zoomScroll.maximumZoomScale = 3
zoomScroll.minimumZoomScale = 0.5
zoomScroll.delegate = zoomDelegate
zoomScroll.setZoomScale(2, animated: false)
```

```
  没设 delegate 时：maximumZoomScale=1.0 minimumZoomScale=1.0
  设了 delegate 并 setZoomScale(2, animated:false) → zoomScale=2.0 zoomable.frame=(0.0, 0.0, 1200.0, 1200.0)
  ok   有 viewForZooming 才能真的缩放
  ok   被缩放视图的 frame 按 600×2=1200 变了
  setZoomScale(99) 被夹到 maximumZoomScale → 3.0
```

注意被缩放视图的 `frame` 直接变成 1200×1200：缩放是把子视图的 `bounds`/`frame` 放大，
不是给它加 `CGAffineTransform`。所以缩放后如果要继续用 Auto Layout 摆放内容，
应该让被缩放的那个视图自己持有固定尺寸约束，交给 scroll view 的
`contentSize`（或由约束反推，见第 21 章），而不是手算 600×2。

- `setZoomScale(_:)` **会**夹到 `[minimumZoomScale, maximumZoomScale]`（实测 99 → 3）。
- 想「双击放大到刚好铺满」用 `zoomRect(_:animated:)`；`maximumZoomScale` 通常按
  `大图的尺寸 / bounds 宽` 设。
- 缩放与 `isPagingEnabled` 互斥语义，别同时开。

## 4) UIScrollViewDelegate：headless 能观测到哪些回调

`scrollViewDidScroll(_:)` 由 offset 变化驱动，属性赋值同样驱动它；带动画的滚动要靠抽干
run loop 才看得到收尾回调。

代理类把九个回调方法**全部**实现，每个都往 `events` 里追加自己的名字，这样「哪些回调真的来了」
就变成可以直接打印的事实：

```swift
let rec = ScrollProbe()        // didScroll / willBeginDragging / didEndDragging /
                               // willBeginDecelerating / didEndDecelerating /
                               // willBeginZooming / didZoom / didScrollToTop / didEndScrollingAnimation
s3.delegate = rec
s3.contentOffset = CGPoint(x: 0, y: 200)
s3.setNeedsLayout()
s3.layoutIfNeeded()
rec.events.removeAll()
s3.setContentOffset(CGPoint(x: 0, y: 400), animated: true)
for _ in 0..<8 { RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.02)) }
```

```
-- UIScrollViewDelegate：headless 能观测到哪些回调 --
  给 contentOffset 属性赋值之后收到的回调：["didScroll"]
  ok   改 contentOffset 属性也会同步触发 scrollViewDidScroll
  带动画滚动 + 抽干 run loop 之后的回调：["didScroll", "didEndScrollingAnimation"]
  动画结束后 offset = (0.0, 400.0)
  再走一轮布局之后的回调：[]（offset 现在 = (0.0, 400.0)）
  缩放那个 scroll view 的 delegate 收到的回调：["didScroll", "didZoom", "didScroll", "didZoom"]
  ok   拖拽/减速一族回调只有真实触摸才会触发，headless 里一次都没有
  ok   setZoomScale 会同步触发 scrollViewDidZoom（不需要手势）
```

要点：

- `scrollViewDidScroll` 在 offset 每次变化时**同步**回调，代码赋值同样触发；它不是「只有用户滚动才有」，
  所以别在里面无条件再设一次 offset，容易递归。
- `willBeginDragging` / `didEndDragging` / `willBeginDecelerating` / `didEndDecelerating`
  一次都没收到（实测事件列表里只有 `didScroll` 和 `didEndScrollingAnimation`）——它们由触摸驱动。
- `didEndScrollingAnimation` 是 `animated: true` 的收尾，动画驱动的 offset 会被夹在合法范围
  （`400` 在 1520 以内，正好落在目标值上）。
- `didZoom` 由 `setZoomScale` 同步触发（实测两次设置两次回调），但 `willBeginZooming` 没有——
  它属于手势，与「谁被缩放」的 `viewForZooming` 是两回事。
- `didScrollToTop` 收不到，而且 Swift 侧**根本没有** `scrollToTop(_:)` 这个方法可以手动触发：
  在 `iPhoneSimulator18.2.sdk` 里 `grep -rn scrollToTop Headers/` 没有任何结果，
  编译器报 `error: value of type 'UIScrollView' has no member 'scrollToTop'`。它只能由点状态栏触发。

## 5) UINavigationController：栈是数组，显示的标题另有优先级

```swift
let root = UIViewController(); root.title = "首页"
let second = UIViewController(); second.title = "详情"
let nav = UINavigationController(rootViewController: root)
nav.pushViewController(second, animated: false)
let popped = nav.popViewController(animated: false)
nav.popToViewController(root, animated: false)
nav.setViewControllers([root, second], animated: false)
nav.popToRootViewController(animated: false)
```

```
-- UINavigationController：栈、pop、标题传递 --
  初始 viewControllers.count = 1，topViewController.title = Optional("首页")
  push 之后 count = 2，top = Optional("详情")
  ok   pushViewController 入栈，topViewController 变成栈顶
  visibleViewController = Optional("详情")（有 modal 时它是 modal，不是 topViewController）
  navigationBar.topItem.title = Optional("详情")
  navigationBar.topItem === second.navigationItem ? true（导航条当前项就是栈顶的 navigationItem）
  nav.navigationBar.isHidden = false，prefersLargeTitles = false
  打开 prefersLargeTitles 后 second.largeTitleDisplayMode = 0（0=automatic 1=always 2=never）
  root.navigationItem.backButtonTitle = nil（默认没设，返回按钮文案由系统决定）
  popViewController 返回被弹出的控制器：=== second ? true；count = 1，top = Optional("首页")
  ok   popViewController 出栈，回到上一页
  再 push 两层，count = 3
  popToViewController(root) 之后 count = 1
  setViewControllers([root, second]) 整体换栈：count = 2，top = Optional("详情")
  ok   setViewControllers 可以直接替换整个栈（恢复现场时常用）
  popToRootViewController 之后 count = 1，titles = ["首页"]
  ok   popToRoot 一次清回栈底
  interactivePopGestureRecognizer：存在 = true，isEnabled = Optional(true)，delegate 已设 = true
  ok   侧滑返回的手势一直在、isEnabled 也是 true，真正决定能不能滑的是它的 delegate（UINavigationController 内部）
  两个都设时：title=控制器 title、navigationItem.title=navigationItem.title，导航条 topItem.title = Optional("navigationItem.title")
  ok   两个标题同时存在时，导航条显示 navigationItem.title
  只设 title 时 topItem.title = Optional("只有 title")
  两个都不设时 topItem.title = nil，titleView = nil
  ok   没设标题就是 nil（导航条留空，titleView 也还是 nil）
  rightBarButtonItems.count = 1，title = Optional("完成")
  ok   bar button item 挂在 navigationItem 上
```

三个读栈的口，语义不同，这是导航栈里最容易混的一组：

| 属性 | 含义 | 有 modal 时 |
| --- | --- | --- |
| `viewControllers` | 整个栈（数组，可整体替换） | 不含 modal |
| `topViewController` | 栈顶控制器 | 仍是栈顶 |
| `visibleViewController` | 用户当前看到的控制器 | 是那个 modal |

标题的三条来源，实测按优先级排：`navigationItem.title` > `title` > 都没有时为 `nil`
（`titleView` 也仍是 `nil`，导航条留空）。`navigationBar.topItem` **就是**栈顶控制器的
`navigationItem`（实测 `===` 成立），所以「导航栏显示什么」永远跟着栈顶走。
`animated: false` 在 `push/pop` 上是合法的（无转场、直接改栈），headless 里必须用它——
`animated: true` 需要窗口与转场上下文。

- `prefersLargeTitles` / `largeTitleDisplayMode` 都是 `API_AVAILABLE(ios(11.0))`
  （头文件写 `prefersLargeTitles` 默认 NO，`largeTitleDisplayMode` 默认 Automatic，
  且「prefersLargeTitles=NO 时该属性无作用」）。
- `popViewController(animated:)` 的返回值就是被弹出的那个控制器（实测 `=== second`），
  所以想拿返回页做后续处理不用先存引用。
- 侧滑返回：`interactivePopGestureRecognizer` 存在、`isEnabled` 读到 `true`、`delegate` 非空
  ——三个值在栈深 1 和栈深 2 时都一样（实测）。也就是说「栈深为 1 时不能侧滑」这件事不是靠
  `isEnabled` 实现的，而是它的 delegate 在手势开始时拒绝；因此把 `delegate` 置 nil
  这种老写法会连带干掉全部侧滑，真要禁用应设 `isEnabled = false` 并理解 UIKit 可能改回它。
- 返回按钮：`backButtonTitle` 默认是 `nil`（实测），文案由系统按上一页标题/宽度决定；
  想要固定文字就设它，想要纯箭头就得靠 appearance 或空字符串。

## 6) UITabBarController 与自定义容器（containment）

```swift
let tabs = UITabBarController()
home.tabBarItem = UITabBarItem(title: "首页", image: nil, tag: 1)
tabs.viewControllers = [home, mine]
tabs.selectedIndex = 1
tabs.tabBar.items?[0].badgeValue = "3"
```

```
-- UITabBarController：selected index 与 tabBarItem --
  viewControllers.count = 2 selectedIndex = 0
  tabBar.items = ["首页", "我的"]
  置 selectedIndex=1 之后 selectedViewController.title = Optional("我的")
  ok   selectedIndex 直接换 selectedViewController
  viewControllers 里没有窗口、没布局过，tabBar.items 就已经同步生成：count=2 tags=[1, 2]
  ok   tabBarItem 是控制器自带的，items 与 viewControllers 同序
  badgeValue 写进第 0 项：items[0].badgeValue = Optional("3")
  ok   badge 属于 UITabBarItem，不是控制器
  加一个没设 tabBarItem、只有 title 的控制器之后 items 标题 = ["首页", "我的", "只有 title"] image 是否为空 = true
```

`tabBar.items` 与 `viewControllers` 同序，而且实测**不需要窗口也不需要布局**：一设
`viewControllers`，`items` 就同步生成好了，`tag` 也来自各控制器的 `tabBarItem`（实测 `[1, 2]`）。
真正需要注意的是反方向——最后一个控制器只设了 `title`、没设 `tabBarItem`，实测它的标题
回退成了 `"只有 title"`，而 `image` 是 `nil`（标签文字有、图标空）。badge 是
`UITabBarItem` 的属性（实测写进 `items[0]` 就能读回），不是控制器的属性。

自定义容器控制器的父子关系和视图层级是**两条独立的线**，必须都走：

```swift
container.addChild(child1)                 // ① 建立 parent
container.view.addSubview(child1.view)     // ② 视图层级
child1.view.frame = container.view.bounds  // ③ 定位（或用约束）
child1.didMove(toParent: container)        // ④ 通知生命周期
```

```
-- 自定义容器控制器：addChild / didMove / removeFromParent --
  addChild 之前：child1.parent = nil，container.children.count = 0
  addChild 之后：parent 已建立（true），但 didMove 还没调 → children.count=1
  didMove(toParent:) 之后：parent=true children.count=1
  ok   标准四步（addChild → 加 view → 设 frame → didMove）走完才算 containment 成立
  第二个 child 走完四步：children = 2
  反向三步（willMove → removeFromSuperview → removeFromParent）之后 children=1，child1.parent=nil
  ok   移除也必须走完整流程，否则容器仍持有它
  只做 removeFromSuperview：children=2，halfChild 还在 children 里=true
  ok   视图移走了但父子关系还在 —— 容器继续持有它
  只做 removeFromParent：children=2，但它的 view 还挂在容器视图上=true
  ok   关系解除了但视图还留着 —— 屏幕上会多一块没人管的东西
```

实测细节：`addChild` 之后 `parent` 与 `children` **立刻**都建立了（`children.count` 已经变成 1），
`didMove(toParent:)` 改的不是父子表，而是通知子控制器「你已经搬进来了」——它属于生命周期转发的一环，
headless 里看不到它连带触发 `viewWillAppear` 之类（那需要真正的转场/窗口显示），但约定的四步就是四步。

少做一步的两个对照实验把代价写得很清楚（上面最后四行）：

| 少做的步骤 | 实测后果 |
| --- | --- |
| 只做 `view.removeFromSuperview()` | `children` 仍然包含它、`parent` 仍然指向容器 → 容器继续强引用这个控制器 |
| 只做 `removeFromParent()` | `children` 里没有它了，但它的 `view` 还在 `container.view.subviews` 里 → 屏幕上多一块没人负责的东西 |

所以移除的三步顺序是 `willMove(toParent: nil)` → `view.removeFromSuperview()` →
`removeFromParent()`，两步都不能省。

## 7) UIPickerView：数据源给「有多少」，代理给「长什么样」

```swift
let picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: 320, height: 216))
picker.dataSource = pDS        // numberOfComponents / numberOfRowsInComponent
picker.delegate = pDS          // titleForRow / rowSizeForComponent / widthForComponent
picker.selectRow(2, inComponent: 0, animated: false)
```

```
-- UIPickerView：多列数据源与 rowSize --
  numberOfComponents = 2
  各列行数 = [3, 4]
  ok   numberOfComponents 由 dataSource 决定
  rowSize(forComponent:0) = (148.0, 32.0)
  selectRow(2, component:0) 之后 selectedRow(inComponent:0)=2 selectedRow(inComponent:1)=0
  ok   选中行可读回
  ok   未指定的列默认选中第 0 行
  各列 rowSize：[(148.0, 32.0), (148.0, 32.0)]（列宽由 delegate 的 widthForComponent 决定，没有 width(forComponent:) 这个 getter）
  delegate 提供的标题：北京/上海/周一/周二
```

- 列宽没有 `width(forComponent:)` 这样的读取口，只有 `rowSize(forComponent:)`，
  它返回 `(宽, 行高)`。实测两列都是 `(148, 32)`：本例没实现 `widthForComponent`，
  宽度由系统按可用宽度分配（比 `bounds.width / 2 = 160` 小，因为还要留出两侧的选中区边距）；
  行高同理是系统的默认值。
- `titleForRow` 是被逐个询问的（实测按列顺序问了 4 个标题：北京/上海/周一/周二），
  所以别在里面做重活；复杂内容用 `viewForRow`，但它会真的建视图。
- `numberOfRows(inComponent:)` 直接问 dataSource（实测 `[3, 4]`），`selectedRow(inComponent:)`
  没选过时是 0。

## 8) UIDatePicker：分钟刻度会向下吸附，非法 interval 被静默忽略

```swift
let dp = UIDatePicker()
dp.datePickerMode = .dateAndTime
dp.minuteInterval = 15
dp.timeZone = TimeZone(identifier: "Asia/Shanghai")!
var comps = DateComponents()
comps.year = 2026; comps.month = 9; comps.day = 28; comps.hour = 10; comps.minute = 7
dp.date = gregorian.date(from: comps)!
```

```
-- UIDatePicker：样式、日历、分钟步进 --
  datePickerMode = 2（0=time 1=date 2=dateAndTime 3=countdown）
  preferredDatePickerStyle = 0（0=automatic 1=wheels 2=compact 3=field）
  minuteInterval = 1 calendar 是公历 = true locale = Optional("zh_CN")
  设 2026-09-28 10:07 之后，按 picker 时区读回 = year Optional(2026) month Optional(9) day Optional(28) hour Optional(10) minute Optional(0)
  ok   写进去的年月日读回一致
  ok   分钟不在刻度上会被**向下**吸附（写 7 而 interval=15 → 读回 0）
```

写进去 10:07，读回来是 10:00。把一批数都试一遍能看出规律——**向下取刻度，不四舍五入**：

```
  interval=15 时逐个数写读：
    写 7 → hour 10 minute 0
    写 8 → hour 10 minute 0
    写 14 → hour 10 minute 0
    写 15 → hour 10 minute 15
    写 22 → hour 10 minute 15
    写 37 → hour 10 minute 30
    写 44 → hour 10 minute 30
    写 59 → hour 10 minute 45
  ok   吸附是向下取刻度（7→0、8→0、14→0、15→15、22→15、37→30、44→30、59→45），小时不受影响
  写 22：interval=5 → 20；再把 interval 改回 15（不重设 date）→ 15（按新刻度重新吸附）
  ok   换 interval 会对已有 date 重新向下吸附
```

吸附只动分钟，不动小时（14 → 0 而不是进位）。改 `minuteInterval` 会对**已经存在**的
`date` 重新吸附一次，所以「先设 interval 再设 date」和反过来会得到同一个结果。

`minuteInterval` 的合法取值是 60 的因子且小于 60（1/2/3/4/5/6/10/12/15/20/30）：

```
  minuteInterval 设 7（不是 60 的因子）→ 读回 15（原值 15 被保留）
  ok   非法 interval 静默忽略，不 crash 也不打日志
  设 60（60 的因子，但等于 60）→ 读回 15
```

非法值**不会报错也不会被改成别的值，而是直接被忽略**，属性保持原值（探针另一组数据同样如此：
从 1 起步时设 7/11/13/24/60/120 全部读回 1，设 4 读回 4）。这个静默行为很危险：
写死 `minuteInterval = 7` 的代码在界面上看到的是「步进仍然是旧值」，没有任何提示。

`minimumDate`/`maximumDate` 则是**会**夹的：

```
  countdownDuration = 0.0（.countdown 模式才用）
  设 minimumDate 再把 date 往前调 1 天 → 读回 Optional(2026)-Optional(9)-Optional(28)
  ok   早于 minimumDate 的日期被夹回下限
```

要点：

- 用 `Calendar(identifier: .gregorian)` + 设好 `timeZone` 的日历来读写 `dp.date` 的分量；
  `UIDatePicker` 自己没有 `date(from:)` / `dateComponents(for:)` 这类方法（第三方糖，别去找）。
- 属性名大小写：`countDownDuration`（不是 `countdownDuration`）；`locale` 是 `Locale?`。
- `preferredDatePickerStyle`：iOS 14+ 必设。`.compact`（值 2）是表单里常用的胶囊样式，
  `.wheels`（1）才是老式滚轮；`.automatic`（0，实测默认）会随容器场景变，放在表单里就是 compact。
- `.countdown` 模式用 `countDownDuration`，与 `date` 无关。

## 9) UIAlertController：动作与输入框，以及 present 的可观测边界

```swift
let alert = UIAlertController(title: "删除", message: "确定要删除这条记录吗？", preferredStyle: .alert)
alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in })
let ok = UIAlertAction(title: "删除", style: .destructive) { _ in }
alert.addAction(ok)
alert.preferredAction = ok
alert.addTextField { tf in tf.placeholder = "输入原因"; tf.text = "" }
```

```
-- UIAlertController：动作、输入框、preferredAction --
  preferredStyle = 1（1=alert 2=actionSheet）
  actions = ["取消/1", "删除/2"]
  preferredAction.title = Optional("删除")
  ok   addAction 顺序保留，读回即所见
  ok   preferredAction 指定默认高亮动作（.cancel=1 .destructive=2 .default=0）
  addTextField 之后 textFields.count = 1 placeholder = Optional("输入原因")
  ok   带输入框的告警用 addTextField{}，textFields 是只读的
  actionSheet 还没 present 时 popoverPresentationController = false
```

`UIAlertController` 一个类取代了老的 `UIAlertView` + `UIActionSheet`（两者都是 iOS 8 起废弃的
独立弹窗对象，没有 present、没有 action 表，本章不再用）。
样式原始值：`.alert = 1`、`.actionSheet = 2`（没有 0；0 是老的 `UIAlertView` 风格枚举残留）。
动作样式：`.default = 0`、`.cancel = 1`、`.destructive = 2`。`actions` 数组保持 `addAction`
的顺序，`preferredAction` 决定哪个动作被高亮为默认（`.destructive` 的红色仍由 style 决定）。

present 的边界值得单独测一遍——它决定了「弹窗没出现」这类问题该往哪儿查：

```swift
let windowlessVC = UIViewController()
windowlessVC.present(alert, animated: false)

hostVC.present(alert, animated: false)          // hostVC 是已显示窗口的根控制器
for _ in 0..<4 { RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05)) }
hostVC.dismiss(animated: false)
```

```
  在没有窗口的 VC 上 present → presentedViewController 建立了吗 = false（静默失败，不崩不报日志）
  在有窗口的 rootVC 上 present → presentedViewController === alert 为 true，但 alert.view.window 仍是 nil
  ok   present 建的是控制器关系；headless 里转场不会真的把视图搬进窗口
  把 sheet 的 modalPresentationStyle 设成 .popover：present 之前 popoverPresentationController 仍为 false
  dismiss(animated:false) 并抽干 runloop 之后 presentedViewController = 还在（解除要等转场结束，headless 里等不到）
```

三条实测结论：

1. 在没有窗口的控制器上 `present` 是**静默失败**（本机 stderr 0 字节；真机上会有日志），
   所以自检脚本里不要指望它报错。
2. `present` 建立的是 `presentingViewController` / `presentedViewController` 这对关系，
   转场才负责把视图搬进窗口；headless 里关系建好了但 `alert.view.window` 仍是 `nil`。
3. `dismiss` 不同步解除关系：转场没跑完，`presentedViewController` 就一直不空——
   「dismiss 之后立刻读状态」这类测试在真机上也建议改用 `presentationAnimator` 的完成回调。
4. `popoverPresentationController` 是伴随转场懒创建的：探针里即使把
   `modalPresentationStyle = .popover` 并从有窗口的根控制器呈现，它依然读回 `nil`，
   因此「iPad 上必须给 `sourceView`/`sourceRect`」这条约束在本环境观测不到，只能在真机验证。

## 10) 计数、选择、进度类控件：夹取、绕回与 -1 约定

```swift
let stepper = UIStepper()
stepper.minimumValue = 0; stepper.maximumValue = 10; stepper.stepValue = 2
stepper.value = 5
stepper.value += stepper.stepValue     // UIStepper 没有 increment(_:) 这个方法
```

```
-- UIStepper / UISegmentedControl / UIPageControl / UIProgressView / UIActivityIndicatorView / UISearchBar --
  stepper: min=0.0 max=10.0 step=2.0 value=5.0
  手动 += stepValue 之后 value = 7.0
  ok   一步 = stepValue（5 + 2 = 7）
  value=999 被夹到 maximumValue → 10.0
  wraps=true、value=10.0 再加一个 stepValue 会到 12.0，超过 maximumValue=10.0
  按 wraps 语义绕回并赋值 → value = 0.0
  ok   wraps 到顶后再加就绕回最小值（wraps 只在手点上生效，赋值本身仍会被夹住）
```

`UIStepper` 的公开面只有 `continuous` / `autorepeat` / `wraps` / `value` /
`minimumValue` / `maximumValue` / `stepValue` / `incrementImageForState(_:)`，
**没有** `increment(_:)`（头文件里找不到，编译器会直接报错），程序化「走一步」只能自己加 `stepValue`。
`wraps` 只影响用户点按时的绕回，属性赋值仍然被夹在 `[min, max]`（实测 `value = 999` → 10）。

```swift
let seg = UISegmentedControl(items: ["列表", "网格", "大图"])
seg.selectedSegmentIndex = -1                       // 无选中
seg.insertSegment(withTitle: "超小", at: 0, animated: false)
```

```
  numberOfSegments=3 titles=["列表", "网格", "大图"]
  selectedSegmentIndex=2 取标题=大图
  ok   items 初始化即三段，可选中任意一段
  selectedSegmentIndex = -1 表示无选中（现在 -1）
  在最前插入一段之后：count=4 第 0 段=超小
  removeAllSegments 之后 numberOfSegments=0
  numberOfPages=5 currentPage=2 hidesForSinglePage=false
  currentPage=99 之后 = 4（越界被夹到最后一页）
  hidesForSinglePage=true 且只有 1 页时 isHidden=true
  progress=1.5 之后 = 1.0（夹在 0...1）
  ok   UIProgressView.progress 被夹到 [0,1]（类型是 Float）
```

- `selectedSegmentIndex` 的「无选中」约定是 `-1`；用 `UISegmentedControl(items:)` 初始化时
  不会自动选中第一段，这跟 `UIPickerView`（默认第 0 行）不一样。
- `UIPageControl.currentPage` **会**夹到 `numberOfPages - 1`（实测 99 → 4）；
  `hidesForSinglePage = true` 且只剩 1 页时它自己 `isHidden = true`。
- `UIProgressView.progress` 是 `Float`（不是 `CGFloat`），夹在 `[0, 1]`，写 1.5 → 1.0。
  想拿它跟 `CGFloat` 比较要显式转换。

`observedProgress`（iOS 9+，配合 `Progress` 对象）在 headless 里有个反直觉的表现：

```swift
let obs = Progress(totalUnitCount: 4)
obs.completedUnitCount = 1
progress.observedProgress = obs
progress.layoutIfNeeded()
```

```
  挂上 observedProgress=Progress(1/4) 之后立刻读 progress = 1.0
  布局一次之后 progress = 1.0（headless 里观察不到它变成 0.25：进度值靠真正的显示周期驱动）
  ok   observedProgress 不会同步改写 progress 属性，别读它来做断言
```

`progress` 属性保持上一次的 1.0，并没有因为挂上 `Progress(1/4)` 就变成 0.25——
它的显示值是视图在窗口里的更新周期驱动的。所以「设了 observedProgress 却读 progress 做断言」
这种写法（在测试里很常见）测不到任何东西；要验证进度就更新 `Progress` 本身。

指示器与搜索框：

```
  初始 isAnimating=false hidesWhenStopped=true isHidden=true
  startAnimating 之后 isAnimating=true isHidden=false
  ok   hidesWhenStopped 默认 true：开启动画会自动显示
  stopAnimating 之后 isAnimating=false isHidden=true
  ok   停止时自动隐藏
  searchBar: placeholder=搜索 text=iOS searchTextField.text=iOS
  showsCancelButton=true autocorrectionType=1（0=default 1=no 2=yes）
  ok   UISearchBar 自己的开关里就有 showsCancelButton；isSearchEnabled 属于 UISearchController，不是它
```

`UIActivityIndicatorView(style:)` 是指定样式的新写法。旧名字在 Swift 里已经不能用了——
探针（一次性，跑完即删）实测两条编译诊断：

```
error: 'activityIndicatorViewStyle' has been renamed to 'style'
note: 'activityIndicatorViewStyle' was obsoleted in Swift 4.2
warning: 'gray' was deprecated in iOS 13.0: renamed to 'UIActivityIndicatorView.Style.medium'
warning: 'whiteLarge' was deprecated in iOS 13.0: renamed to 'UIActivityIndicatorView.Style.large'
```

obsoleted 是硬错误（属性根本不存在），deprecated 只是警告——但本仓库的构建判定要求
build log 为空，所以这类警告会让示例直接判失败，改名是唯一出路（`.gray` → `.medium`、
`.whiteLarge` → `.large`）。`hidesWhenStopped` 默认 `true`，所以 `startAnimating()`
会连带把 `isHidden` 置回 `false`（实测）。

`UISearchBar.searchTextField` 在 SDK 头文件里标的是 `API_AVAILABLE(ios(13.0))`、
`readonly`——不是很多人以为的 iOS 16+。`readonly` 只表示「这个属性本身不能换成别的文本框」，
取回来之后改它的 `text` 是合法的。实测在没有窗口、没有布局的情况下，
`search.text = "iOS"` 之后 `searchTextField.text` 立刻就是 `iOS`（两者同步）。
同一份头文件里还有一个坑：`@property (nonatomic, getter=isEnabled) BOOL enabled`
标的是 `API_AVAILABLE(ios(16.4))`，所以在 iOS 15 部署目标下直接写 `searchBar.isEnabled = false`
是**编译期错误**（探针实测，原文如下），这正是第 14 章讲的「部署目标挡住新 API」：

```
error: 'isEnabled' is only available in iOS 16.4 or newer
note: add 'if #available' version check
```

而 `isSearchEnabled` 属于 `UISearchController`，压根不在 `UISearchBar` 上（实测断言里写明）。

## 11) UIImageView 帧动画，以及用 ImageIO 真的造一张多帧 GIF

帧动画完全不需要窗口：`animationImages` 是 `[UIImage]`，`animationDuration` 是整轮秒数，
`animationRepeatCount` 为 0 表示无限。

```swift
let frames = (0..<4).map { i -> UIImage in
    UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { ctx in
        UIColor(red: CGFloat(i) / 3.0, green: 0.4, blue: 0.8, alpha: 1).setFill()
        ctx.fill(CGRect(origin: .zero, size: CGSize(width: 20, height: 20)))
    }
}
iv.animationImages = frames
iv.animationDuration = 0.8
iv.animationRepeatCount = 2
iv.startAnimating()
```

```
-- UIImageView 帧动画 --
  新建实例的默认值：duration=0.0 repeatCount=0 animationImages=nil image=nil
  只设 animationImages 之后 image 仍是 nil（设数组不会改动 image 属性）
  animationImages.count=4 duration=0.8 repeatCount=2
  初始 isAnimating=false highlighted=false
  startAnimating 之后 isAnimating=true
  ok   startAnimating 置位成功（不需要窗口）
  stopAnimating 之后 isAnimating=false
  设了 image/highlightedImage 之后 image 尺寸=Optional((20.0, 20.0)) highlighted 尺寸=Optional((20.0, 20.0))
  ok   单帧图用 image；按下时显示 highlightedImage
```

- `animationDuration` 是**一轮**的时长（4 帧 / 0.8s ⇒ 每帧 0.2s）。新建实例实测读回 `0.0`，
  头文件对它的注释是「for one cycle of images. default is number of images * 1/30th of a second
  (i.e. 30 fps)」——0 表示「用帧数按 30fps 自己算」，不是「不播」。
- `animationRepeatCount` 实测默认 0，头文件注释「0 means infinite (default is 0)」。
- `animationImages` 的注释是「Setting hides the single image」：实测设数组**不会**改动 `image`
  属性的值（读回仍是 `nil`），「隐藏单帧图」发生在显示层而不是属性层。
- headless 里 `startAnimating()` 只把 `isAnimating` 置位（实测），没有任何一帧真的被绘制过；
  要按帧驱动自己的绘制逻辑得用第 23 章的 `CADisplayLink`。

多帧 GIF 的读写用 ImageIO（`import ImageIO` 即可，不需要 CoreServices）。
两个细节：UTI 直接写字面量 `"com.compuserve.gif"`（`kUTTypeGIF` 在 Swift 里已不可用），
逐帧延时放在帧属性的 `kCGImagePropertyGIFDictionary` 里、循环次数放在**文件级**属性里。

```swift
let gifData = NSMutableData()
let dest = CGImageDestinationCreateWithData(gifData, "com.compuserve.gif" as CFString, frames.count, nil)!
CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]] as CFDictionary)
for img in frames {
    let props: [CFString: Any] = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.25]]
    CGImageDestinationAddImage(dest, img.cgImage!, props as CFDictionary)
}
let wrote = CGImageDestinationFinalize(dest)
let src = CGImageSourceCreateWithData(gifData, nil)!
```

```
-- ImageIO：合成多帧 GIF 并读回帧数 --
  finalize 写入 = true，GIF 字节数 = 405
  CGImageSourceGetCount = 4（帧数）
  ok   多帧 GIF 写出去、再读回来，帧数一致
  CGImageSourceGetType = com.compuserve.gif
  ok   类型标识读回来确认这确实是 GIF 数据
  第 0 帧 delayTime = 0.25
  ok   写进去的每帧 0.25 秒延时被原样读回
  文件级 loopCount = 0（0 = 无限循环）
  ok   无限循环标志写入成功
  第 0 帧尺寸 = 60x60
  ok   逐帧解码可用（CGImageSourceCreateImageAtIndex）
```

`第 0 帧尺寸 = 60x60` 而 `UIImage.size` 是 20×20：ImageIO 操作的是**像素**，
渲染器按屏幕 `scale = 3` 输出了 60 像素见方。这正是「GIF 帧率/尺寸」问题的根源之一——
`UIImage` 的 point 尺寸和图像数据的 pixel 尺寸差一个 `scale`，读属性时要认准单位。

- `CGImageDestinationFinalize` 才真正落盘；之前 `gifData.length` 是 0。
- `CGImageSourceGetCount` 给帧数，`CGImageSourceCopyPropertiesAtIndex` 给单帧属性，
  `CGImageSourceCopyProperties` 给文件级属性（loopCount 在这里）。
- 动图在 UIKit 里的现代做法是 `UIImage.animatedImage(with:duration:)` 或
  `AVPlayerLayer` / `CADisplayLink`（第 23 章）；GIF 只是存储格式。

## 心智模型小结

```
contentSize − bounds = 可滚范围（自己算）；contentOffset 的 setter 不夹取，滚动循环才夹
bounds.origin 就是 contentOffset：automatic 调整会把 offset 推到 -adjustedContentInset.top
adjustedContentInset = contentInset + 安全区，只有挂进窗口才有安全区可加
缩放 = min/max 范围 + delegate 的 viewForZooming(in:)；缺 delegate 时两个边界值都是 1，setZoomScale 无效
代码能触发的滚动回调只有 didScroll / didZoom / didEndScrollingAnimation；拖拽与减速一族靠真实触摸
容器 = 父子关系（addChild/didMove）+ 视图层级（child.view 进父视图），两条线都要走
导航栈三个读法：viewControllers（整栈）/ topViewController（栈顶）/ visibleViewController（含 modal）
标题优先级：navigationItem.title > title > nil（navigationBar.topItem 就是栈顶的 navigationItem）
高级控件的越界值处理各不相同：夹取（stepper/progress/pageControl）、吸附（datePicker 分钟）、忽略（minuteInterval）
帧动画 = UIImage 数组 + duration（一轮）+ repeatCount（0 = 无限）；GIF 读写用 ImageIO
```

## 坑清单

| 现象 | 原因 |
| --- | --- |
| 写了个很大的 `contentOffset`，界面一片空白还读回原值 | offset setter 不做夹取（实测 99999 原样读回）；越界后要自己 clamp |
| `contentOffset` 莫名其妙是负数 | 挂进窗口后 automatic 把它推到 `-adjustedContentInset.top`（实测 -62） |
| scroll view 顶到状态栏 | `contentInsetAdjustmentBehavior = .never`；改回 `.automatic` 或自己补 inset |
| 页面里内容贴住安全区仍差 8 个点 | 混淆 `contentInset` 与 `adjustedContentInset`；后者才是最终值且只读 |
| `setZoomScale(2)` 毫无反应 | 没实现 `viewForZooming(in:)`；此时 min/max 都还是 1 |
| 等 `scrollViewDidZoom` 等不到 `willBeginZooming` | 代码缩放只触发 `didZoom`（实测），`willBeginZooming` 属于手势 |
| 想手动调 `scrollToTop(nil)` 触发 `didScrollToTop` | UIKit 头文件里没有这个方法，Swift 报 `has no member 'scrollToTop'`；只有点状态栏会触发 |
| 设了 `isPagingEnabled` 后 offset 没吸附到整页 | 吸附发生在滚动结束，属性赋值不触发 |
| `contentOffset = CGPoint(x: .nan, ...)` 编译不过 | `.nan`/`.infinity` 在 CGFloat 与 Double 之间歧义，写 `CGFloat.nan` |
| 真的传了 NaN 进去，进程直接没了 | `CALayerInvalidGeometry`：`setContentOffset` 同步下推 `bounds` 时被几何校验拦住 |
| 导航栏标题不显示 | 只设了 `title`，但 `navigationItem.title` 被设成空字符串覆盖了它 |
| modal 弹出来时 `topViewController` 还是栈顶 | 应该读 `visibleViewController`（实测它返回 modal） |
| 子控制器生命周期方法一次都没调 | 只 `addChild` 没 `didMove(toParent:)`；四步是一个整体 |
| 移除子控制器后内存还持有它 | 少了 `willMove(toParent: nil)` + `removeFromSuperview()` |
| 子控制器已经 `removeFromParent` 了，界面上还留一块 | 视图没 `removeFromSuperview`（实测 `container.view.subviews` 仍含它） |
| `interactivePopGestureRecognizer.isEnabled` 读到 true 就以为侧滑开着 | 实测栈深 1 也是 true；能不能滑由它的 delegate 决定 |
| tab 有文字没图标 | 那个控制器只有 `title`、没有 `tabBarItem`（实测 `items[2].image == nil`） |
| 找不到 `UIStepper.increment(_:)` | 没有这个方法；`value += stepValue` 自己加 |
| `stepper.wraps = true` 后赋值 999 仍是最大值 | `wraps` 只作用于用户点按，属性赋值照样被夹 |
| `selectedSegmentIndex` 读出 -1 以为出错 | -1 是「无选中」的正常值；`UISegmentedControl(items:)` 不会自动选第一段 |
| `progress` 和 `CGFloat` 比较报类型错 | `UIProgressView.progress` 是 `Float` |
| 挂了 `observedProgress` 后读 `progress` 断言 | 它不同步改写属性（实测仍 1.0）；要验就改 `Progress` |
| `dp.minuteInterval = 7` 没生效也没报错 | 非法值被静默忽略，保持原值；只有 60 的因子且 <60 能用 |
| 日期写 10:07 读回 10:00 | `minuteInterval` 向下吸附到刻度（实测 14→0、22→15、59→45） |
| `UIDatePicker` 在表单里显示成一大列滚轮 | iOS 14+ 要显式设 `preferredDatePickerStyle = .compact` |
| 找不到 `countdownDuration` | 真名 `countDownDuration`（大写 D）；`locale` 是 `Locale?` |
| 没有 `pickerView.width(forComponent:)` | 只有 `rowSize(forComponent:)`，返回 `(宽, 行高)` |
| `present` 之后 `alert.view.window` 是 nil | headless 里转场不跑；关系（`presentedViewController`）才是 `present` 的直接结果 |
| `dismiss` 之后 `presentedViewController` 还在 | 解除依赖转场结束；用完成回调而不是立刻读 |
| `UIActivityIndicatorView` 用 `activityIndicatorViewStyle` 编译不过 | Swift 4.2 起 obsoleted，改名 `style`；`.gray`/`.whiteLarge` 也已废弃（→ `.medium`/`.large`），警告会让本仓库的构建判定失败 |
| `searchBar.isEnabled = false` 报「only available in iOS 16.4」 | 头文件标 `API_AVAILABLE(ios(16.4))`；本仓库部署目标是 iOS 15，必须 `if #available` |
| 以为 `searchTextField` 是 iOS 16+ | 头文件写的是 `API_AVAILABLE(ios(13.0))`，且是 `readonly`（属性对象不可换，内容可改） |
| GIF 帧尺寸和 `UIImage.size` 不一致 | 实测 60 vs 20：ImageIO 是像素，`UIImage.size` 是点，差一个 `scale` |
| 写了 `kUTTypeGIF` 编译不过 | 该常量在 Swift 侧不可用；直接写字面量 `"com.compuserve.gif" as CFString` |

## 小结

- `UIScrollView` 的全部几何就是「`contentSize` 减 `bounds`」加「`bounds.origin` 即 `contentOffset`」，
  但要记住夹取属于滚动循环而非 setter——这是本章最容易被直觉带偏的地方。
- 容器控制器只有两条线都走全才成立：父子关系与视图层级。`UINavigationController` 与
  `UITabBarController` 是这两个动作的封装，读状态用 `topViewController` /
  `visibleViewController` / `selectedViewController` 三个不同的口。
- 高级控件的属性读写在 headless 全部可测，越界值的行为分三家：夹取、吸附、忽略。
  「不报错」不等于「按你想的改了」，所以本章对每个控件都读回来打印。
- 帧动画与 GIF 读写不需要网络也不需要图片库；ImageIO 的 `CGImageDestination*` /
  `CGImageSource*` 一写一读就是全部所需。

下一章离开「视图与控件」，进入让 UIKit 界面动起来的那一层：**核心动画**——
`CALayer` 与锚点、`UIView.animate`、`CABasicAnimation` / `CAKeyframeAnimation` /
`CATransition` / `CAAnimationGroup`、3D 变换与计时函数，以及 `CATransaction`、
`CADisplayLink` 这些控制动画节奏的机制。
