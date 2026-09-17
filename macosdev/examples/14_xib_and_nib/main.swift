// ============================================================
// 14 - XIB 与 nib：Interface Builder 到底产出了什么
//   ibtool 编译 / Bundle 加载 / File's Owner / outlet 与 action 的连线
//
// 编译（三步，脚本就是这么干的）：
//   # 1. XIB 是 XML，运行时读不了，必须先编译成二进制 nib
//   ibtool --compile MainView.nib MainView.xib
//   # 2. 编 Swift
//   swiftc -O -sdk $SDK -target x86_64-apple-macos12.0 -module-name xib_and_nib \
//          main.swift -o 14_xib_and_nib -framework Foundation -framework AppKit
//   # 3. 运行时从 Bundle 的资源目录里找 MainView.nib
//   ./14_xib_and_nib
//
// 关键约定：
//   - XIB 里 customClass="DemoOwner" 的类必须真的存在，运行时才会用上
//   - customModule 必须等于 swiftc 的 -module-name，否则找不到 Swift 类
//     （Xcode 里这一项默认填的是 target 名，命令行下得自己写对）
//   - 编好的 nib 要在 Bundle 的资源目录里，也就是可执行文件所在的目录
// ============================================================

import AppKit
import Foundation

var failures = 0
func expect(_ condition: Bool, _ description: String) {
    if condition {
        print("  ok   \(description)")
    } else {
        print("  FAIL \(description)")
        failures += 1
    }
}

/// File's Owner：XIB 里的占位对象，加载时由**你**传进去的那个对象顶上。
/// 它自己不在 nib 里被创建，所以连到它身上的 outlet 会写到你给的对象里。
final class DemoOwner: NSObject {
    @IBOutlet var titleLabel: NSTextField?
    var tapCount = 0

    @IBAction func tapMe(_ sender: Any?) {
        tapCount += 1
    }
}

autoreleasepool {

    // MARK: - 1) nib 在哪

    print("== 资源与 nib ==")
    let bundle = Bundle.main
    // 命令行工具没有 .app 包，Bundle.main 的资源目录就是可执行文件所在目录。
    // 这里只判断存在性 —— 路径本身依赖构建目录，打印出来没有意义。
    let nibURL = bundle.url(forResource: "MainView", withExtension: "nib")
    print("  找到 nib = \(nibURL != nil)")
    expect(nibURL != nil, "资源目录里有编译好的 MainView.nib")
    expect(bundle.url(forResource: "NoSuchNib", withExtension: "nib") == nil,
           "不存在的 nib 返回 nil")

    // MARK: - 2) 加载 nib

    print("")
    print("== 加载 nib ==")
    let owner = DemoOwner()
    // 坑：topLevelObjects 里的对象**不会**被自动持有。
    // nib 只保证「加载时活着」，你不用变量接住，它们出了这一行就可能被释放。
    var topLevel: NSArray? = nil
    let loaded = bundle.loadNibNamed("MainView", owner: owner, topLevelObjects: &topLevel)
    print("  loaded = \(loaded), 顶层对象数 = \(topLevel?.count ?? -1)")
    expect(loaded, "loadNibNamed 返回 true")
    expect((topLevel?.count ?? 0) > 0, "顶层对象数组非空")

    let views = (topLevel ?? []).compactMap { $0 as? NSView }
    expect(views.count == 1, "顶层对象里有一个 NSView（实际 \(views.count)）")
    let rootView = views.first
    print("  根视图 = \(rootView.map { String(describing: type(of: $0)) } ?? "nil")"
        + " 尺寸 = \(rootView?.frame.size ?? .zero)")
    expect(rootView?.frame.width == 280, "根视图宽度来自 XIB（实际 \(rootView?.frame.width ?? -1)）")
    expect(rootView?.frame.height == 90, "根视图高度来自 XIB（实际 \(rootView?.frame.height ?? -1)）")
    expect(rootView?.subviews.count == 2, "XIB 里放了两个子视图（实际 \(rootView?.subviews.count ?? -1)）")

    // MARK: - 3) outlet 连上了没有

    print("")
    print("== outlet ==")
    print("  titleLabel = \(owner.titleLabel?.stringValue ?? "nil")")
    expect(owner.titleLabel != nil, "outlet 被填上了（File's Owner 的连线生效）")
    expect(owner.titleLabel?.stringValue == "来自 XIB 的标签", "标签文字来自 XIB")
    expect(owner.titleLabel?.isEditable == false, "XIB 里就是 label，不可编辑")
    // outlet 指向的对象就在根视图的子视图里
    expect(rootView?.subviews.contains { $0 === owner.titleLabel } == true,
           "outlet 指向的对象确实是根视图的子视图")

    // MARK: - 4) action 连上了没有

    print("")
    print("== action ==")
    let button = rootView?.subviews.compactMap { $0 as? NSButton }.first
    print("  按钮标题 = \(button?.title ?? "nil")")
    expect(button?.title == "点一下", "按钮文字来自 XIB")
    expect(button?.target === owner, "按钮的 target 就是 File's Owner")
    expect(button?.action == #selector(DemoOwner.tapMe(_:)), "action 指向 tapMe:")

    // 手动触发一次：不能用 NSApp.sendAction（需要事件循环），
    // 直接 perform 走运行时派发
    _ = owner.perform(button!.action, with: button)
    expect(owner.tapCount == 1, "点一次计数加一（实际 \(owner.tapCount)）")
    _ = owner.perform(button!.action, with: button)
    expect(owner.tapCount == 2, "再点一次变 2（实际 \(owner.tapCount)）")

    // MARK: - 5) 再加载一份：nib 是模板

    print("")
    print("== 重复加载 ==")
    let owner2 = DemoOwner()
    var topLevel2: NSArray? = nil
    _ = bundle.loadNibNamed("MainView", owner: owner2, topLevelObjects: &topLevel2)
    let view2 = (topLevel2 ?? []).compactMap { $0 as? NSView }.first
    expect(view2 !== rootView, "第二次加载得到的是新的视图实例")
    expect(owner2.titleLabel !== owner.titleLabel, "第二个 owner 有自己的 outlet 对象")
    expect(owner2.titleLabel?.stringValue == owner.titleLabel?.stringValue, "但文字内容一样")
    expect(owner2.tapCount == 0, "新 owner 的计数从 0 开始")

    // MARK: - 6) NSNib：把 nib 当对象用

    print("")
    print("== NSNib ==")
    // NSNib 适合「同一个 nib 要实例化很多次」的场景（比如表格的每一行）
    let nib = NSNib(nibNamed: "MainView", bundle: bundle)
    expect(nib != nil, "能造出 NSNib 对象")
    var objects: NSArray? = nil
    let owner3 = DemoOwner()
    let ok = nib?.instantiate(withOwner: owner3, topLevelObjects: &objects) ?? false
    expect(ok, "instantiate 成功")
    expect((objects ?? []).count > 0, "也能拿到顶层对象")
    expect(owner3.titleLabel?.stringValue == "来自 XIB 的标签", "第三个 owner 的 outlet 也连上了")

    // 名字写错会怎样：返回 false，不抛异常
    var nothing: NSArray? = nil
    let missing = bundle.loadNibNamed("NotThere", owner: owner3, topLevelObjects: &nothing)
    expect(missing == false, "加载不存在的 nib 返回 false（不是崩溃）")

    // MARK: - 7) 代码建 vs XIB 建

    print("")
    print("== 什么时候用 XIB ==")
    // 同一个视图，代码写出来和 XIB 加载出来的差别只在「谁负责设置属性」：
    let manual = NSTextField(labelWithString: "来自 XIB 的标签")
    expect(manual.stringValue == owner.titleLabel?.stringValue, "两者属性可以完全一致")
    expect(manual !== owner.titleLabel, "但显然是两个不同的对象")
    // XIB 的好处：布局、颜色、字体这类「看得见的东西」改起来不用重新编译；
    // 坏处：类名、属性名写错了只有运行时才知道 —— 所以本仓库用
    // tools/check_xib.py 在编译之前静态检查一遍。

    print("==== 14 结束 ====")
    exit(failures == 0 ? 0 : 1)
}
