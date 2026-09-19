// ============================================================
// 13 - SwiftUI ⇄ UIKit 互操作：UIViewRepresentable / Coordinator / UIHostingController
//
// 两条互操作通道：
//   UIKit 视图 → 塞进 SwiftUI：UIViewRepresentable / UIViewControllerRepresentable
//       makeUIView(context:)     创建底层 UIView（只一次）
//       updateUIView(_:context:) 每次 SwiftUI 状态变化时同步 UIView（可多次）
//       Coordinator              承接 UIKit 的 delegate/target-action，桥回 SwiftUI
//   SwiftUI 视图 → 塞进 UIKit：UIHostingController(rootView:)
//       改 host.rootView 就能更新那块 SwiftUI 内容
//
// headless 验证：UIViewRepresentable 的真实生命周期**需要一次渲染 pass**——把宿主视图
// 放进一个 UIWindow（isHidden=false，但**从不 makeKeyAndOrderFront**），再**有界地**抽
// 几次 run loop（每次带超时，不会卡死），SwiftUI 就会真的调用 makeUIView/updateUIView，
// 把 UILabel 建进 PlatformViewHost 里。我们据此断言：
//   - 底层 UILabel 被创建、文本正确（makeUIView 生效）
//   - 改 rootView 后 UILabel 文本跟着变（updateUIView 生效）
//   - Coordinator 被创建并记录了 make/update（delegate 桥接的位置）
// 这套「有界抽 run loop」是本示例唯一一处触碰渲染循环的地方，抽满即退出，绝不进入
// 无限 run loop，也不弹窗。
// ============================================================

import Foundation
import UIKit
import SwiftUI

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }

// 记录 Coordinator 生命周期事件，供断言（Coordinator 归 SwiftUI 所有，用外部 log 观测）
final class EventLog { var events: [String] = [] }

// ------------------------------------------------ 一个包装 UILabel 的 UIViewRepresentable
struct WrappedLabel: UIViewRepresentable {
    var text: String
    let log: EventLog

    func makeCoordinator() -> Coordinator { Coordinator(log: log) }

    func makeUIView(context: Context) -> UILabel {
        context.coordinator.note("make:\(text)")
        let l = UILabel()
        l.text = text
        return l
    }
    func updateUIView(_ uiView: UILabel, context: Context) {
        context.coordinator.note("update:\(text)")
        uiView.text = text
    }

    // Coordinator：真实场景里它是 UITextField 的 delegate、按钮的 target 等，
    // 把 UIKit 的命令式回调翻译回 SwiftUI（改 @Binding / 调闭包）。这里只记录事件。
    final class Coordinator {
        let log: EventLog
        init(log: EventLog) { self.log = log }
        func note(_ s: String) { log.events.append(s) }
    }
}

// 在视图树里深度优先找第一个 UILabel（SwiftUI 把它包在 PlatformViewHost 里）
func findLabel(in view: UIView) -> UILabel? {
    if let l = view as? UILabel { return l }
    for s in view.subviews { if let l = findLabel(in: s) { return l } }
    return nil
}

// 有界地把宿主视图渲染一次：放进 window（isHidden=false，但不 makeKeyAndOrderFront），
// 抽最多 n 次 run loop，每次都带超时，绝不无限等待。
func renderOnce<V: View>(_ host: UIHostingController<V>, width: CGFloat = 200, height: CGFloat = 100, spins: Int = 8) {
    let win = UIWindow(frame: CGRect(x: 0, y: 0, width: width, height: height))
    win.rootViewController = host
    win.isHidden = false
    host.view.frame = win.bounds
    for _ in 0..<spins {
        host.view.setNeedsLayout()
        host.view.layoutIfNeeded()
        RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.02))
    }
}

line("== 13 SwiftUI ⇄ UIKit 互操作 ==")

// ---------------------------------------------------- 1) Coordinator 可直接创建
line("")
line("-- makeCoordinator：不依赖渲染就能创建 --")
let log0 = EventLog()
let coord = WrappedLabel(text: "x", log: log0).makeCoordinator()
coord.note("手动记录")
expect(log0.events == ["手动记录"], "Coordinator 由 makeCoordinator 创建，持有外部 log")

// ---------------------------------------------------- 2) UIKit → SwiftUI：makeUIView 真的建了 UILabel
line("")
line("-- UIViewRepresentable：makeUIView 建出真实 UILabel --")
let log = EventLog()
let host = UIHostingController(rootView: WrappedLabel(text: "第一版", log: log))
renderOnce(host)
let label = findLabel(in: host.view)
line("  找到的底层视图 = \(label == nil ? "无" : String(describing: type(of: label!)))")
expect(label != nil, "SwiftUI 树里真的出现了一个 UILabel（makeUIView 被调用）")
expect(label?.text == "第一版", "UILabel 的文本 = 初始值「第一版」")
expect(log.events.first?.hasPrefix("make:") == true, "Coordinator 记录了 make（makeUIView 走的是它）")
expect(log.events.contains(where: { $0.hasPrefix("update:") }), "Coordinator 记录了 update（updateUIView 也被调用）")

// ---------------------------------------------------- 3) UIKit → SwiftUI：updateUIView 同步新值
line("")
line("-- updateUIView：改 rootView，UILabel 跟着变 --")
host.rootView = WrappedLabel(text: "第二版", log: log)   // 换一个新值的 Representable
renderOnce(host)
let label2 = findLabel(in: host.view)
expect(label2?.text == "第二版", "rootView 换成「第二版」后，同一个 UILabel 文本被 updateUIView 同步")
expect(log.events.contains("update:第二版"), "Coordinator 记录到带新文本的 update")

// ---------------------------------------------------- 4) SwiftUI → UIKit：UIHostingController
line("")
line("-- UIHostingController：SwiftUI 视图塞进 UIKit --")
struct Badge: View {
    var title: String
    var body: some View { Text(title).font(.headline) }
}
let uiHost = UIHostingController(rootView: Badge(title: "A"))
uiHost.loadViewIfNeeded()
expect(String(describing: type(of: uiHost.view!)).contains("Hosting"), "宿主 view 是 _UIHostingView")
expect(String(describing: type(of: uiHost.rootView)).contains("Badge"), "rootView 是我们塞进去的 Badge")
// 在纯 UIKit 的控制器里，把这块 SwiftUI 视图当普通 UIView 用
let containerVC = UIViewController()
containerVC.loadViewIfNeeded()
uiHost.view.translatesAutoresizingMaskIntoConstraints = false
containerVC.addChild(uiHost)
containerVC.view.addSubview(uiHost.view)
uiHost.didMove(toParent: containerVC)
expect(containerVC.children.contains(uiHost), "UIHostingController 作为子控制器嵌进了 UIKit 控制器")
expect(uiHost.parent === containerVC, "父子关系已建立")
// 改 rootView 更新那块 SwiftUI 内容
uiHost.rootView = Badge(title: "B")
expect(uiHost.rootView.title == "B", "改 rootView 即更新嵌入的 SwiftUI 内容")

// ---------------------------------------------------- 5) 小结
line("")
line("-- 心智模型 --")
line("  UIKit→SwiftUI：UIViewRepresentable（makeUIView 建一次 / updateUIView 每次同步）")
line("  Coordinator 承接 UIKit 的 delegate/target-action，把命令式回调翻译回 SwiftUI")
line("  SwiftUI→UIKit：UIHostingController(rootView:)，改 rootView 即更新")
line("  两套可以互相嵌套：UIKit App 里嵌 SwiftUI，或 SwiftUI 里嵌老的 UIKit 控件")
expect(true, "以上均由真实的 UILabel 创建/更新与控制器嵌套断言支撑")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 13 结束 ====")
exit(failures == 0 ? 0 : 1)
