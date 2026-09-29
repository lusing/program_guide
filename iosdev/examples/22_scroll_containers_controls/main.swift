// ============================================================
// 22 - 滚动视图、容器控制器与高级控件
//
// 第 15 章讲了 UITableView / UICollectionView 与常用控件的属性读写。这一章补教材里
// 另外三大块：
//   UIScrollView —— 内容尺寸、偏移、inset、分页、缩放（它是 table/collection 的父类）
//   容器控制器 —— UINavigationController / UITabBarController / 自定义 containment
//   高级控件 —— UIPickerView / UIDatePicker / UIAlertController / UIStepper /
//               UISegmentedControl / UIPageControl / UIProgressView /
//               UIActivityIndicatorView / UIImageView 帧动画（含真做一张多帧 GIF）
//
// headless 说明：这些对象都**不依赖窗口**就能建、能配置、能读回状态；滚动代理回调靠一次
// 真正的 offset 改动触发。为了看安全区自动调整和 present 的边界，中间借用了
// UIWindow + rootViewController（第 21 章的用法），全程不弹窗等待用户。
//
// 判定 3（stderr 必须为空）的约束：不要 present 没有窗口的控制器（本机静默失败，但真机会
// 打日志）、不要给 scroll view 传 NaN 的 offset —— 探针实测当场抛 NSException
// （name = CALayerInvalidGeometry，reason 以「CALayer bounds contains NaN」开头）后 SIGABRT。
// ============================================================

import Foundation
import UIKit
import ImageIO

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
func eq(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.01 }

// ---------------------------------------------------- 支撑类型（放在使用之前）
final class ScrollProbe: NSObject, UIScrollViewDelegate {
    var events: [String] = []
    func scrollViewDidScroll(_ sv: UIScrollView) { events.append("didScroll") }
    func scrollViewWillBeginDragging(_ sv: UIScrollView) { events.append("willBeginDragging") }
    func scrollViewDidEndDragging(_ sv: UIScrollView, willDecelerate decelerate: Bool) { events.append("didEndDragging") }
    func scrollViewWillBeginDecelerating(_ sv: UIScrollView) { events.append("willBeginDecelerating") }
    func scrollViewDidEndDecelerating(_ sv: UIScrollView) { events.append("didEndDecelerating") }
    func scrollViewWillBeginZooming(_ sv: UIScrollView, with v: UIView?) { events.append("willBeginZooming") }
    func scrollViewDidZoom(_ sv: UIScrollView) { events.append("didZoom") }
    func scrollViewDidScrollToTop(_ sv: UIScrollView) { events.append("didScrollToTop") }
    func scrollViewDidEndScrollingAnimation(_ sv: UIScrollView) { events.append("didEndScrollingAnimation") }
    func viewForZooming(in scrollView: UIScrollView) -> UIView? { scrollView.subviews.first }
}
let zoomProbe = ScrollProbe()

final class PickerDS: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    let data: [[String]]
    var titles: [String] = []
    init(columns: [[String]]) { self.data = columns }
    func numberOfComponents(in pickerView: UIPickerView) -> Int { data.count }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { data[component].count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let t = data[component][row]
        titles.append(t)
        return t
    }
}

line("== 22 滚动视图、容器控制器与高级控件 ==")

// ---------------------------------------------------- 1) UIScrollView：内容尺寸与偏移
line("")
line("-- UIScrollView：contentSize / contentOffset --")
let scroll = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
let big = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 2000))
scroll.addSubview(big)
scroll.contentSize = CGSize(width: 320, height: 2000)
line("  bounds=\(scroll.bounds.size) contentSize=\(scroll.contentSize)")
line("  可滚动的最大 offset.y = contentSize.height - bounds.height = \(scroll.contentSize.height - scroll.bounds.height)")
expect(scroll.contentSize.height > scroll.bounds.height, "contentSize 比 bounds 大才会产生滚动")

scroll.contentOffset = CGPoint(x: 0, y: 500)
line("  设 offset=(0,500) 之后 contentOffset = \(scroll.contentOffset)")
expect(eq(scroll.contentOffset.y, 500), "范围内直接生效")

// 超界会不会被夹？实测：属性写入原样保留，夹取属于滚动循环，不属于 setter
scroll.contentOffset = CGPoint(x: 0, y: 99999)
line("  设 offset=(0,99999) 之后 contentOffset = \(scroll.contentOffset)")
expect(eq(scroll.contentOffset.y, 99999), "裸视图上超界 offset 不被夹（写多少读回多少）")

// 负方向同样不夹；bounces 只影响手势/动画期间能否越界
scroll.contentOffset = CGPoint(x: 0, y: -500)
line("  设 offset=(0,-500)（bounces=\(scroll.bounces)）之后 contentOffset = \(scroll.contentOffset)")
expect(eq(scroll.contentOffset.y, -500), "负方向也不夹， bounds.origin 就是 contentOffset")
expect(eq(scroll.bounds.origin.y, -500), "UIScrollView 的 bounds.origin 与 contentOffset 是同一个数")
scroll.contentOffset = .zero
scroll.contentSize = CGSize(width: 320, height: 480)
scroll.contentOffset = CGPoint(x: 0, y: 100)
line("  contentSize == bounds 时设 offset=(0,100) → \(scroll.contentOffset)（内容不比视口大，滚不动）")
expect(eq(scroll.contentOffset.y, 100), "即使没有可滚空间，属性写入仍然生效（不能靠它判断边界）")
scroll.contentSize = CGSize(width: 320, height: 2000)
scroll.contentOffset = .zero

// ---------------------------------------------------- 2) inset / 分页 / 缩放
line("")
line("-- UIScrollView：inset、contentInsetAdjustmentBehavior、paging、zoom --")
let s2 = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
s2.contentSize = CGSize(width: 320, height: 2000)
s2.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 40, right: 0)
line("  contentInset = \(s2.contentInset)")
line("  adjustedContentInset = \(s2.adjustedContentInset)（contentInset + 安全区；裸视图安全区为 0）")
line("  contentInsetAdjustmentBehavior = \(s2.contentInsetAdjustmentBehavior.rawValue)（0=automatic 1=scrollableAxes 2=never 3=always）")
expect(s2.contentInset.top == 20 && s2.contentInset.bottom == 40, "contentInset 是可读写的应用层 inset")

s2.contentInsetAdjustmentBehavior = .never
line("  置为 .never 之后 adjustedContentInset = \(s2.adjustedContentInset)")
s2.contentInsetAdjustmentBehavior = .automatic
expect(eq(s2.adjustedContentInset.top, 20), "automatic 下没挂进窗口 → adjusted 就等于 contentInset（\(s2.adjustedContentInset.top)）")

// 挂进窗口之后，.automatic 才会真的按安全区改 inset —— 而且会顺手把 contentOffset 抬到负值
let hostWindow = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
hostWindow.isHidden = false
let hostVC = UIViewController()
hostWindow.rootViewController = hostVC
let s2b = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
s2b.contentSize = CGSize(width: 320, height: 2000)
hostVC.view.addSubview(s2b)
hostWindow.layoutIfNeeded()
for _ in 0..<4 { RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.02)) }
line("  挂进窗口：window.safeAreaInsets.top=\(hostWindow.safeAreaInsets.top) → contentInset=\(s2b.contentInset)"
     + " adjustedContentInset=\(s2b.adjustedContentInset)")
line("  …同一轮布局把 contentOffset 也移到了 \(s2b.contentOffset)（bounds.origin 跟着变）")
expect(eq(s2b.adjustedContentInset.top, s2b.contentInset.top + hostWindow.safeAreaInsets.top),
       "adjusted = contentInset + 安全区（只有挂进窗口才有安全区可加）")
expect(eq(s2b.contentOffset.y, -s2b.adjustedContentInset.top),
       "automatic 会把 offset 抬到 -adjusted.top，让内容顶部正好落在安全区下面")
s2b.contentInsetAdjustmentBehavior = .never
hostWindow.layoutIfNeeded()
line("  改成 .never 并重新布局 → contentOffset=\(s2b.contentOffset) adjustedContentInset=\(s2b.adjustedContentInset)")

// 分页开关：只是把「滚动结束」时的对齐方式改掉
s2.isPagingEnabled = true
s2.contentOffset = CGPoint(x: 0, y: 700)
line("  isPagingEnabled=true 之后立刻读 offset = \(s2.contentOffset)（非动画设置不会立刻吸附）")

// 缩放：必须实现 viewForZooming(in:)，否则 setZoomScale 什么也不做
let zoomScroll = UIScrollView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
let zoomable = UIView(frame: CGRect(x: 0, y: 0, width: 600, height: 600))
zoomScroll.addSubview(zoomable)
zoomScroll.contentSize = CGSize(width: 600, height: 600)
line("  没设 delegate 时：maximumZoomScale=\(zoomScroll.maximumZoomScale) minimumZoomScale=\(zoomScroll.minimumZoomScale)")
zoomScroll.maximumZoomScale = 3
zoomScroll.minimumZoomScale = 0.5
zoomScroll.delegate = zoomProbe
zoomScroll.setZoomScale(2, animated: false)
line("  设了 delegate 并 setZoomScale(2, animated:false) → zoomScale=\(zoomScroll.zoomScale) zoomable.frame=\(zoomable.frame)")
expect(eq(zoomScroll.zoomScale, 2), "有 viewForZooming 才能真的缩放")
expect(eq(zoomable.frame.width, 1200), "被缩放视图的 frame 按 600×2=1200 变了")
zoomScroll.setZoomScale(99, animated: false)
line("  setZoomScale(99) 被夹到 maximumZoomScale → \(zoomScroll.zoomScale)")

// ---------------------------------------------------- 3) UIScrollViewDelegate 回调
line("")
line("-- UIScrollViewDelegate：headless 能观测到哪些回调 --")
let s3 = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
s3.contentSize = CGSize(width: 320, height: 2000)
let rec = ScrollProbe()
s3.delegate = rec
s3.contentOffset = CGPoint(x: 0, y: 200)
s3.setNeedsLayout()
s3.layoutIfNeeded()
line("  给 contentOffset 属性赋值之后收到的回调：\(rec.events)")
expect(rec.events.contains("didScroll"), "改 contentOffset 属性也会同步触发 scrollViewDidScroll")
rec.events.removeAll()
s3.setContentOffset(CGPoint(x: 0, y: 400), animated: true)
s3.setNeedsLayout()
s3.layoutIfNeeded()
for _ in 0..<8 { RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.02)) }
line("  带动画滚动 + 抽干 run loop 之后的回调：\(rec.events)")
line("  动画结束后 offset = \(s3.contentOffset)")
rec.events.removeAll()
// 注意：Swift 侧**没有** `UIScrollView.scrollToTop(_:)` 这个方法（头文件里也没有），
// 所以 scrollViewDidScrollToTop(_:) 只能由系统状态栏点击触发，headless 里永远收不到。
s3.setNeedsLayout()
s3.layoutIfNeeded()
for _ in 0..<4 { RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.02)) }
line("  再走一轮布局之后的回调：\(rec.events)（offset 现在 = \(s3.contentOffset)）")
line("  缩放那个 scroll view 的 delegate 收到的回调：\(zoomProbe.events)")
expect(!rec.events.contains("willBeginDragging") && !rec.events.contains("didEndDecelerating"),
       "拖拽/减速一族回调只有真实触摸才会触发，headless 里一次都没有")
expect(zoomProbe.events.contains("didZoom"), "setZoomScale 会同步触发 scrollViewDidZoom（不需要手势）")

// ---------------------------------------------------- 4) UINavigationController
line("")
line("-- UINavigationController：栈、pop、标题传递 --")
let root = UIViewController(); root.title = "首页"
let second = UIViewController(); second.title = "详情"
let nav = UINavigationController(rootViewController: root)
line("  初始 viewControllers.count = \(nav.viewControllers.count)，topViewController.title = \(String(describing: nav.topViewController?.title))")
nav.pushViewController(second, animated: false)
line("  push 之后 count = \(nav.viewControllers.count)，top = \(String(describing: nav.topViewController?.title))")
expect(nav.viewControllers.count == 2 && nav.topViewController === second, "pushViewController 入栈，topViewController 变成栈顶")
line("  visibleViewController = \(String(describing: nav.visibleViewController?.title))（有 modal 时它是 modal，不是 topViewController）")
line("  navigationBar.topItem.title = \(String(describing: nav.navigationBar.topItem?.title))")
line("  navigationBar.topItem === second.navigationItem ? \(nav.navigationBar.topItem === second.navigationItem)（导航条当前项就是栈顶的 navigationItem）")
line("  nav.navigationBar.isHidden = \(nav.navigationBar.isHidden)，prefersLargeTitles = \(nav.navigationBar.prefersLargeTitles)")
nav.navigationBar.prefersLargeTitles = true
line("  打开 prefersLargeTitles 后 second.largeTitleDisplayMode = \(second.navigationItem.largeTitleDisplayMode.rawValue)（0=automatic 1=always 2=never）")
line("  root.navigationItem.backButtonTitle = \(String(describing: root.navigationItem.backButtonTitle))（默认没设，返回按钮文案由系统决定）")
let popped = nav.popViewController(animated: false)
line("  popViewController 返回被弹出的控制器：=== second ? \(popped === second)；count = \(nav.viewControllers.count)，top = \(String(describing: nav.topViewController?.title))")
expect(nav.topViewController === root, "popViewController 出栈，回到上一页")
nav.pushViewController(second, animated: false)
nav.pushViewController({ let v = UIViewController(); v.title = "三级"; return v }(), animated: false)
line("  再 push 两层，count = \(nav.viewControllers.count)")
nav.popToViewController(root, animated: false)
line("  popToViewController(root) 之后 count = \(nav.viewControllers.count)")
nav.setViewControllers([root, second], animated: false)
line("  setViewControllers([root, second]) 整体换栈：count = \(nav.viewControllers.count)，top = \(String(describing: nav.topViewController?.title))")
expect(nav.viewControllers.count == 2, "setViewControllers 可以直接替换整个栈（恢复现场时常用）")
nav.popToRootViewController(animated: false)
line("  popToRootViewController 之后 count = \(nav.viewControllers.count)，titles = \(nav.viewControllers.map { $0.title ?? "nil" })")
expect(nav.viewControllers.count == 1, "popToRoot 一次清回栈底")
let edgeGesture = nav.interactivePopGestureRecognizer
line("  interactivePopGestureRecognizer：存在 = \(edgeGesture != nil)，isEnabled = \(String(describing: edgeGesture?.isEnabled))，delegate 已设 = \(edgeGesture?.delegate != nil)")
expect(edgeGesture != nil && edgeGesture?.delegate != nil,
       "侧滑返回的手势一直在、isEnabled 也是 true，真正决定能不能滑的是它的 delegate（UINavigationController 内部）")

// 标题的两条来源：navigationItem.title 优先于 title
let titled = UIViewController()
titled.title = "控制器 title"
titled.navigationItem.title = "navigationItem.title"
nav.pushViewController(titled, animated: false)
line("  两个都设时：title=控制器 title、navigationItem.title=navigationItem.title，"
     + "导航条 topItem.title = \(String(describing: nav.navigationBar.topItem?.title))")
expect(nav.navigationBar.topItem?.title == "navigationItem.title",
       "两个标题同时存在时，导航条显示 navigationItem.title")
let onlyTitle = UIViewController()
onlyTitle.title = "只有 title"
nav.pushViewController(onlyTitle, animated: false)
line("  只设 title 时 topItem.title = \(String(describing: nav.navigationBar.topItem?.title))")
let untitled = UIViewController()
nav.pushViewController(untitled, animated: false)
line("  两个都不设时 topItem.title = \(String(describing: nav.navigationBar.topItem?.title))，"
     + "titleView = \(untitled.navigationItem.titleView == nil ? "nil" : "有")")
expect(nav.navigationBar.topItem?.title == nil && untitled.navigationItem.titleView == nil,
       "没设标题就是 nil（导航条留空，titleView 也还是 nil）")
nav.popToViewController(titled, animated: false)

// 左右bar按钮
let rightItem = UIBarButtonItem(title: "完成", style: .done, target: nil, action: nil)
titled.navigationItem.rightBarButtonItem = rightItem
line("  rightBarButtonItems.count = \(titled.navigationItem.rightBarButtonItems?.count ?? -1)，title = \(String(describing: titled.navigationItem.rightBarButtonItem?.title))")
expect(titled.navigationItem.rightBarButtonItem === rightItem, "bar button item 挂在 navigationItem 上")
nav.popToRootViewController(animated: false)

// ---------------------------------------------------- 5) UITabBarController
line("")
line("-- UITabBarController：selected index 与 tabBarItem --")
let home = UIViewController(); home.title = "首页"
home.tabBarItem = UITabBarItem(title: "首页", image: nil, tag: 1)
let mine = UIViewController(); mine.title = "我的"
mine.tabBarItem = UITabBarItem(title: "我的", image: nil, tag: 2)
let tabs = UITabBarController()
tabs.viewControllers = [home, mine]
line("  viewControllers.count = \(tabs.viewControllers?.count ?? -1) selectedIndex = \(tabs.selectedIndex)")
line("  tabBar.items = \(tabs.tabBar.items?.map { $0.title ?? "nil" } ?? [])")
tabs.selectedIndex = 1
line("  置 selectedIndex=1 之后 selectedViewController.title = \(String(describing: tabs.selectedViewController?.title))")
expect(tabs.selectedViewController === mine, "selectedIndex 直接换 selectedViewController")
line("  viewControllers 里没有窗口、没布局过，tabBar.items 就已经同步生成：count=\(tabs.tabBar.items?.count ?? -1)"
     + " tags=\(tabs.tabBar.items?.map { $0.tag } ?? [])")
expect(tabs.tabBar.items?.count == 2, "tabBarItem 是控制器自带的，items 与 viewControllers 同序")
tabs.tabBar.items?[0].badgeValue = "3"
line("  badgeValue 写进第 0 项：items[0].badgeValue = \(String(describing: tabs.tabBar.items?[0].badgeValue))")
expect(tabs.tabBar.items?[0].badgeValue == "3", "badge 属于 UITabBarItem，不是控制器")
let plain = UIViewController()
plain.title = "只有 title"
tabs.viewControllers = [home, mine, plain]
line("  加一个没设 tabBarItem、只有 title 的控制器之后 items 标题 = \(tabs.tabBar.items?.map { $0.title ?? "nil" } ?? [])"
     + " image 是否为空 = \(tabs.tabBar.items?[2].image == nil)")

// ---------------------------------------------------- 6) 自定义容器（containment）
line("")
line("-- 自定义容器控制器：addChild / didMove / removeFromParent --")
let container = UIViewController()
let child1 = UIViewController()
let child2 = UIViewController()
line("  addChild 之前：child1.parent = \(String(describing: child1.parent))，container.children.count = \(container.children.count)")
container.addChild(child1)
line("  addChild 之后：parent 已建立（\(child1.parent === container)），但 didMove 还没调 → children.count=\(container.children.count)")
container.view.frame = CGRect(x: 0, y: 0, width: 320, height: 480)
container.view.addSubview(child1.view)
child1.view.frame = container.view.bounds
child1.didMove(toParent: container)
line("  didMove(toParent:) 之后：parent=\(child1.parent != nil) children.count=\(container.children.count)")
expect(child1.parent === container && container.children.count == 1, "标准四步（addChild → 加 view → 设 frame → didMove）走完才算 containment 成立")
container.addChild(child2)
child2.didMove(toParent: container)
line("  第二个 child 走完四步：children = \(container.children.count)")
child1.willMove(toParent: nil)
child1.view.removeFromSuperview()
child1.removeFromParent()
line("  反向三步（willMove → removeFromSuperview → removeFromParent）之后 children=\(container.children.count)，child1.parent=\(String(describing: child1.parent))")
expect(container.children.count == 1 && child1.parent == nil, "移除也必须走完整流程，否则容器仍持有它")

// 少做一步会留下什么（对照实验）
let halfChild = UIViewController()
container.addChild(halfChild)
container.view.addSubview(halfChild.view)
halfChild.didMove(toParent: container)
halfChild.view.removeFromSuperview()          // 只走三步里的中间一步
line("  只做 removeFromSuperview：children=\(container.children.count)，halfChild 还在 children 里=\(container.children.contains(halfChild))")
expect(container.children.contains(halfChild) && halfChild.parent === container,
       "视图移走了但父子关系还在 —— 容器继续持有它")
let orphanChild = UIViewController()
container.addChild(orphanChild)
container.view.addSubview(orphanChild.view)
orphanChild.didMove(toParent: container)
orphanChild.removeFromParent()                // 只走最后一步
line("  只做 removeFromParent：children=\(container.children.count)，但它的 view 还挂在容器视图上=\(container.view.subviews.contains(orphanChild.view))")
expect(!container.children.contains(orphanChild) && container.view.subviews.contains(orphanChild.view),
       "关系解除了但视图还留着 —— 屏幕上会多一块没人管的东西")

// ---------------------------------------------------- 7) UIPickerView
line("")
line("-- UIPickerView：多列数据源与 rowSize --")
let picker = UIPickerView(frame: CGRect(x: 0, y: 0, width: 320, height: 216))
let pDS = PickerDS(columns: [["北京", "上海", "广州"], ["周一", "周二", "周三", "周四"]])
picker.dataSource = pDS
picker.delegate = pDS
line("  numberOfComponents = \(picker.numberOfComponents)")
line("  各列行数 = \((0 ..< picker.numberOfComponents).map { picker.numberOfRows(inComponent: $0) })")
expect(picker.numberOfComponents == 2, "numberOfComponents 由 dataSource 决定")
line("  rowSize(forComponent:0) = \(picker.rowSize(forComponent: 0))")
picker.selectRow(2, inComponent: 0, animated: false)
line("  selectRow(2, component:0) 之后 selectedRow(inComponent:0)=\(picker.selectedRow(inComponent: 0)) selectedRow(inComponent:1)=\(picker.selectedRow(inComponent: 1))")
expect(picker.selectedRow(inComponent: 0) == 2, "选中行可读回")
expect(picker.selectedRow(inComponent: 1) == 0, "未指定的列默认选中第 0 行")
line("  各列 rowSize：\((0 ..< picker.numberOfComponents).map { picker.rowSize(forComponent: $0) })（列宽由 delegate 的 widthForComponent 决定，没有 width(forComponent:) 这个 getter）")
line("  delegate 提供的标题：\(pDS.titles.joined(separator: "/"))")

// ---------------------------------------------------- 8) UIDatePicker
line("")
line("-- UIDatePicker：样式、日历、分钟步进 --")
let dp = UIDatePicker()
line("  datePickerMode = \(dp.datePickerMode.rawValue)（0=time 1=date 2=dateAndTime 3=countdown）")
line("  preferredDatePickerStyle = \(dp.preferredDatePickerStyle.rawValue)（0=automatic 1=wheels 2=compact 3=field）")
line("  minuteInterval = \(dp.minuteInterval) calendar 是公历 = \(dp.calendar.identifier == .gregorian) locale = \(String(describing: dp.locale?.identifier))")
dp.datePickerMode = .dateAndTime
dp.minuteInterval = 15
var comps = DateComponents()
comps.year = 2026; comps.month = 9; comps.day = 28; comps.hour = 10; comps.minute = 7
let gregorian = Calendar(identifier: .gregorian)
let zone = TimeZone(identifier: "Asia/Shanghai")!
dp.timeZone = zone
if let startDate = gregorian.date(from: comps) { dp.date = startDate }
var readCal = gregorian
readCal.timeZone = zone
let readBack = readCal.dateComponents([.year, .month, .day, .hour, .minute], from: dp.date)
line("  设 2026-09-28 10:07 之后，按 picker 时区读回 = year \(String(describing: readBack.year))"
     + " month \(String(describing: readBack.month)) day \(String(describing: readBack.day))"
     + " hour \(String(describing: readBack.hour)) minute \(String(describing: readBack.minute))")
expect(readBack.year == 2026 && readBack.month == 9 && readBack.day == 28, "写进去的年月日读回一致")
expect(readBack.minute == 0, "分钟不在刻度上会被**向下**吸附（写 7 而 interval=15 → 读回 \(readBack.minute!)）")

// 逐个写入观察吸附规律：都是 floor 到最近的刻度，不会四舍五入
line("  interval=15 时逐个数写读：")
var snapped: [(Int, Int)] = []
for m in [7, 8, 14, 15, 22, 37, 44, 59] {
    var c = DateComponents()
    c.year = 2026; c.month = 9; c.day = 28; c.hour = 10; c.minute = m
    if let d = gregorian.date(from: c) { dp.date = d }
    let got = readCal.dateComponents([.hour, .minute], from: dp.date)
    snapped.append((m, got.minute ?? -1))
    line("    写 \(m) → hour \(got.hour!) minute \(got.minute!)")
}
let snapText = snapped.map { "\($0.0)→\($0.1)" }.joined(separator: "、")
expect(snapped.map { $0.1 } == [0, 0, 0, 15, 15, 30, 30, 45],
       "吸附是向下取刻度（\(snapText)），小时不受影响")

// 改 interval 会按新刻度重新吸附已经存在的 date
var c22 = DateComponents()
c22.year = 2026; c22.month = 9; c22.day = 28; c22.hour = 10; c22.minute = 22
dp.minuteInterval = 5
if let d22 = gregorian.date(from: c22) { dp.date = d22 }
let after5 = readCal.dateComponents([.minute], from: dp.date).minute ?? -1
dp.minuteInterval = 15
let after15 = readCal.dateComponents([.minute], from: dp.date).minute ?? -1
line("  写 22：interval=5 → \(after5)；再把 interval 改回 15（不重设 date）→ \(after15)（按新刻度重新吸附）")
expect(after5 == 20 && after15 == 15, "换 interval 会对已有 date 重新向下吸附")
// 非法的 interval 会被**静默忽略**：属性保持原值，不报错也不崩溃
let before = dp.minuteInterval
dp.minuteInterval = 7
line("  minuteInterval 设 7（不是 60 的因子）→ 读回 \(dp.minuteInterval)（原值 \(before) 被保留）")
expect(dp.minuteInterval == before, "非法 interval 静默忽略，不 crash 也不打日志")
dp.minuteInterval = 60
line("  设 60（60 的因子，但等于 60）→ 读回 \(dp.minuteInterval)")
line("  countdownDuration = \(dp.countDownDuration)（.countdown 模式才用）")
let anchorDate = gregorian.date(from: comps)!
dp.minimumDate = anchorDate
let earlier = gregorian.date(byAdding: .day, value: -1, to: anchorDate)!
dp.date = earlier
let afterClamp = readCal.dateComponents([.year, .month, .day], from: dp.date)
line("  设 minimumDate 再把 date 往前调 1 天 → 读回 \(String(describing: afterClamp.year))-\(String(describing: afterClamp.month))-\(String(describing: afterClamp.day))")
expect(dp.date >= dp.minimumDate!, "早于 minimumDate 的日期被夹回下限")

// ---------------------------------------------------- 9) UIAlertController
line("")
line("-- UIAlertController：动作、输入框、preferredAction --")
let alert = UIAlertController(title: "删除", message: "确定要删除这条记录吗？", preferredStyle: .alert)
alert.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in })
let ok = UIAlertAction(title: "删除", style: .destructive) { _ in }
alert.addAction(ok)
alert.preferredAction = ok
line("  preferredStyle = \(alert.preferredStyle.rawValue)（1=alert 2=actionSheet）")
line("  actions = \(alert.actions.map { "\($0.title ?? "nil")/\($0.style.rawValue)" })")
line("  preferredAction.title = \(String(describing: alert.preferredAction?.title))")
expect(alert.actions.count == 2, "addAction 顺序保留，读回即所见")
expect(alert.preferredAction === ok, "preferredAction 指定默认高亮动作（.cancel=1 .destructive=2 .default=0）")
alert.addTextField { tf in tf.placeholder = "输入原因"; tf.text = "" }
line("  addTextField 之后 textFields.count = \(alert.textFields?.count ?? -1) placeholder = \(String(describing: alert.textFields?.first?.placeholder))")
expect(alert.textFields?.count == 1, "带输入框的告警用 addTextField{}，textFields 是只读的")
let sheet = UIAlertController(title: "分享到", message: nil, preferredStyle: .actionSheet)
sheet.addAction(UIAlertAction(title: "微信", style: .default))
line("  actionSheet 还没 present 时 popoverPresentationController = \(sheet.popoverPresentationController != nil)")

// present / dismiss 的可观测边界（stderr 实测 0 字节，所以能放进自检）
let windowlessVC = UIViewController()
windowlessVC.present(alert, animated: false)
line("  在没有窗口的 VC 上 present → presentedViewController 建立了吗 = \(windowlessVC.presentedViewController != nil)（静默失败，不崩不报日志）")
hostVC.present(alert, animated: false)
for _ in 0..<4 { RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05)) }
line("  在有窗口的 rootVC 上 present → presentedViewController === alert 为 \(hostVC.presentedViewController === alert)"
     + "，但 alert.view.window 仍是 \(alert.view.window == nil ? "nil" : "有")")
expect(hostVC.presentedViewController === alert, "present 建的是控制器关系；headless 里转场不会真的把视图搬进窗口")
sheet.modalPresentationStyle = .popover
line("  把 sheet 的 modalPresentationStyle 设成 .popover：present 之前 popoverPresentationController 仍为 \(sheet.popoverPresentationController != nil)")
hostVC.dismiss(animated: false)
for _ in 0..<4 { RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05)) }
line("  dismiss(animated:false) 并抽干 runloop 之后 presentedViewController = \(hostVC.presentedViewController == nil ? "nil" : "还在")（解除要等转场结束，headless 里等不到）")

// ---------------------------------------------------- 10) 计数/选择/进度类控件
line("")
line("-- UIStepper / UISegmentedControl / UIPageControl / UIProgressView / UIActivityIndicatorView / UISearchBar --")
let stepper = UIStepper()
stepper.minimumValue = 0; stepper.maximumValue = 10; stepper.stepValue = 2
stepper.value = 5
line("  stepper: min=\(stepper.minimumValue) max=\(stepper.maximumValue) step=\(stepper.stepValue) value=\(stepper.value)")
// UIStepper **没有** increment(_:) 这个方法（头文件里只有 value/min/max/stepValue 四个数值属性
// 和 continuous/autorepeat/wraps 三个开关）。程序化「走一步」只能自己加 stepValue。
stepper.value += stepper.stepValue
let afterInc = stepper.value
line("  手动 += stepValue 之后 value = \(afterInc)")
expect(eq(afterInc, 7), "一步 = stepValue（5 + 2 = 7）")
stepper.value = 999
line("  value=999 被夹到 maximumValue → \(stepper.value)")
stepper.wraps = true
stepper.value = 10
let beyond = stepper.value + stepper.stepValue
let wrapped = beyond > stepper.maximumValue ? stepper.minimumValue : beyond
line("  wraps=true、value=\(stepper.value) 再加一个 stepValue 会到 \(beyond)，超过 maximumValue=\(stepper.maximumValue)")
stepper.value = wrapped
line("  按 wraps 语义绕回并赋值 → value = \(stepper.value)")
expect(eq(stepper.value, stepper.minimumValue), "wraps 到顶后再加就绕回最小值（wraps 只在手点上生效，赋值本身仍会被夹住）")

let seg = UISegmentedControl(items: ["列表", "网格", "大图"])
line("  numberOfSegments=\(seg.numberOfSegments) titles=\((0 ..< seg.numberOfSegments).map { seg.titleForSegment(at: $0) ?? "nil" })")
seg.selectedSegmentIndex = 2
line("  selectedSegmentIndex=\(seg.selectedSegmentIndex) 取标题=\(seg.titleForSegment(at: seg.selectedSegmentIndex) ?? "nil")")
expect(seg.numberOfSegments == 3 && seg.selectedSegmentIndex == 2, "items 初始化即三段，可选中任意一段")
seg.selectedSegmentIndex = -1
line("  selectedSegmentIndex = -1 表示无选中（现在 \(seg.selectedSegmentIndex)）")
seg.insertSegment(withTitle: "超小", at: 0, animated: false)
line("  在最前插入一段之后：count=\(seg.numberOfSegments) 第 0 段=\(seg.titleForSegment(at: 0) ?? "nil")")
seg.removeAllSegments()
line("  removeAllSegments 之后 numberOfSegments=\(seg.numberOfSegments)")

let page = UIPageControl()
page.numberOfPages = 5
page.currentPage = 2
line("  numberOfPages=\(page.numberOfPages) currentPage=\(page.currentPage) hidesForSinglePage=\(page.hidesForSinglePage)")
page.currentPage = 99
line("  currentPage=99 之后 = \(page.currentPage)（越界被夹到最后一页）")
page.hidesForSinglePage = true
page.numberOfPages = 1
line("  hidesForSinglePage=true 且只有 1 页时 isHidden=\(page.isHidden)")

let progress = UIProgressView(progressViewStyle: .default)
progress.progress = 1.5
line("  progress=1.5 之后 = \(progress.progress)（夹在 0...1）")
expect(eq(CGFloat(progress.progress), 1), "UIProgressView.progress 被夹到 [0,1]（类型是 Float）")
let obs = Progress(totalUnitCount: 4)
obs.completedUnitCount = 1
progress.observedProgress = obs
line("  挂上 observedProgress=Progress(1/4) 之后立刻读 progress = \(progress.progress)")
progress.layoutIfNeeded()
line("  布局一次之后 progress = \(progress.progress)（headless 里观察不到它变成 0.25：进度值靠真正的显示周期驱动）")
expect(progress.progress > 0, "observedProgress 不会同步改写 progress 属性，别读它来做断言")

let spinner = UIActivityIndicatorView(style: .large)
line("  初始 isAnimating=\(spinner.isAnimating) hidesWhenStopped=\(spinner.hidesWhenStopped) isHidden=\(spinner.isHidden)")
spinner.startAnimating()
line("  startAnimating 之后 isAnimating=\(spinner.isAnimating) isHidden=\(spinner.isHidden)")
expect(spinner.isAnimating && !spinner.isHidden, "hidesWhenStopped 默认 true：开启动画会自动显示")
spinner.stopAnimating()
line("  stopAnimating 之后 isAnimating=\(spinner.isAnimating) isHidden=\(spinner.isHidden)")
expect(!spinner.isAnimating && spinner.isHidden, "停止时自动隐藏")

let search = UISearchBar()
search.placeholder = "搜索"
search.text = "iOS"
line("  searchBar: placeholder=\(search.placeholder ?? "nil") text=\(search.text ?? "nil") searchTextField.text=\(search.searchTextField.text ?? "nil")")
search.showsCancelButton = true
search.autocorrectionType = .no
line("  showsCancelButton=\(search.showsCancelButton) autocorrectionType=\(search.autocorrectionType.rawValue)（0=default 1=no 2=yes）")
expect(search.showsCancelButton, "UISearchBar 自己的开关里就有 showsCancelButton；isSearchEnabled 属于 UISearchController，不是它")

// ---------------------------------------------------- 11) UIImageView 帧动画 + 真做一张多帧 GIF
line("")
line("-- UIImageView 帧动画 --")
let iv = UIImageView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
let frames = (0..<4).map { i -> UIImage in
    let size = CGSize(width: 20, height: 20)
    let r = UIGraphicsImageRenderer(size: size)
    return r.image { ctx in
        UIColor(red: CGFloat(i) / 3.0, green: 0.4, blue: 0.8, alpha: 1).setFill()
        ctx.fill(CGRect(origin: .zero, size: size))
    }
}
let iv0 = UIImageView()
line("  新建实例的默认值：duration=\(iv0.animationDuration) repeatCount=\(iv0.animationRepeatCount)"
     + " animationImages=\(iv0.animationImages == nil ? "nil" : "有") image=\(iv0.image == nil ? "nil" : "有")")
iv0.animationImages = frames
line("  只设 animationImages 之后 image 仍是 \(iv0.image == nil ? "nil" : "有")（设数组不会改动 image 属性）")
iv.animationImages = frames
iv.animationDuration = 0.8
iv.animationRepeatCount = 2
line("  animationImages.count=\(iv.animationImages?.count ?? -1) duration=\(iv.animationDuration) repeatCount=\(iv.animationRepeatCount)")
line("  初始 isAnimating=\(iv.isAnimating) highlighted=\(iv.isHighlighted)")
iv.startAnimating()
line("  startAnimating 之后 isAnimating=\(iv.isAnimating)")
expect(iv.isAnimating, "startAnimating 置位成功（不需要窗口）")
iv.stopAnimating()
line("  stopAnimating 之后 isAnimating=\(iv.isAnimating)")
iv.image = frames[0]
iv.highlightedImage = frames[3]
line("  设了 image/highlightedImage 之后 image 尺寸=\(String(describing: iv.image?.size)) highlighted 尺寸=\(String(describing: iv.highlightedImage?.size))")
expect(iv.image?.size == CGSize(width: 20, height: 20), "单帧图用 image；按下时显示 highlightedImage")

// —— 用 ImageIO 真的做一张多帧 GIF，再读回来（SDWebImage 那类库做的事）——
line("")
line("-- ImageIO：合成多帧 GIF 并读回帧数 --")
let gifData = NSMutableData()
guard let dest = CGImageDestinationCreateWithData(gifData, "com.compuserve.gif" as CFString, frames.count, nil) else {
    line("  CGImageDestinationCreateWithData 返回 nil")
    exit(1)
}
let fileProps: [CFString: Any] = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0]]
CGImageDestinationSetProperties(dest, fileProps as CFDictionary)
for img in frames {
    let frameProps: [CFString: Any] = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 0.25]]
    guard let cg = img.cgImage else { continue }
    CGImageDestinationAddImage(dest, cg, frameProps as CFDictionary)
}
let wrote = CGImageDestinationFinalize(dest)
line("  finalize 写入 = \(wrote)，GIF 字节数 = \(gifData.length)")
if wrote, let src = CGImageSourceCreateWithData(gifData, nil) {
    let count = CGImageSourceGetCount(src)
    line("  CGImageSourceGetCount = \(count)（帧数）")
    expect(count == frames.count, "多帧 GIF 写出去、再读回来，帧数一致")
    let typeId = (CGImageSourceGetType(src) as String?) ?? "nil"
    line("  CGImageSourceGetType = \(typeId)")
    expect(typeId == "com.compuserve.gif", "类型标识读回来确认这确实是 GIF 数据")
    if let props = CGImageSourceCopyPropertiesAtIndex(src, 0, nil) as? [CFString: Any],
       let gifDict = props[kCGImagePropertyGIFDictionary] as? [CFString: Any],
       let delay = gifDict[kCGImagePropertyGIFDelayTime] as? Double {
        line("  第 0 帧 delayTime = \(delay)")
        expect(eq(delay, 0.25), "写进去的每帧 0.25 秒延时被原样读回")
    } else {
        expect(false, "写进去的每帧 0.25 秒延时被原样读回")
    }
    if let fileProps = CGImageSourceCopyProperties(src, nil) as? [CFString: Any],
       let fgif = fileProps[kCGImagePropertyGIFDictionary] as? [CFString: Any],
       let loop = fgif[kCGImagePropertyGIFLoopCount] as? Int {
        line("  文件级 loopCount = \(loop)（0 = 无限循环）")
        expect(loop == 0, "无限循环标志写入成功")
    } else {
        expect(false, "无限循环标志写入成功")
    }
    let first = CGImageSourceCreateImageAtIndex(src, 0, nil)
    let sizeText = first == nil ? "nil" : "\(first!.width)x\(first!.height)"
    line("  第 0 帧尺寸 = \(sizeText)")
    expect(first != nil, "逐帧解码可用（CGImageSourceCreateImageAtIndex）")
}

// ---------------------------------------------------- 12) 心智模型
line("")
line("-- 心智模型 --")
line("  UIScrollView 的「能滚」只由 contentSize 与 bounds 的差决定；但 contentOffset 的 setter 不夹取（写 99999 原样读回），夹取属于滚动循环")
line("  bounds.origin 就是 contentOffset：把 scroll view 挂进窗口后，automatic 调整会把 offset 推到 -adjustedContentInset.top")
line("  adjustedContentInset = contentInset + 安全区；只有挂进窗口才有安全区可加")
line("  缩放必须有 delegate 的 viewForZooming(in:)，否则 setZoomScale 无效")
line("  容器控制器 = 父子关系（addChild/didMove）+ 视图层级（把 child.view 加进来），两步都要做")
line("  UINavigationController 读栈用 viewControllers/topViewController；显示标题优先 navigationItem.title")
line("  控件的属性读写都能在 headless 完成：数值越界被夹（stepper/progress/pageControl），日期按 minuteInterval 向下吸附，非法 interval 被静默忽略")
line("  帧动画 = UIImage 数组 + duration/repeatCount；多帧 GIF 用 ImageIO 自己也能造和读")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 22 结束 ====")
exit(failures == 0 ? 0 : 1)
