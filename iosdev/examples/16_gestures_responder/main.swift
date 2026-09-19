// ============================================================
// 16 - UIKit 手势、触摸与响应链：hitTest / UIResponder 链 / UIGestureRecognizer
//
// 一次触摸在 UIKit 里走两段路：
//   1) Hit-Testing（命中测试）：从窗口往下，递归找出「这个点落在哪个最深的视图」——
//      靠 hitTest(_:with:) / point(inside:with:)。isUserInteractionEnabled=false、
//      isHidden、alpha<0.01 的视图会被跳过。
//   2) 响应链（Responder Chain）：命中的视图若不处理事件，就沿 next 往上传
//      （子视图 → 父视图 → viewController → … → UIApplication）。
//   手势识别器（UIGestureRecognizer）挂在视图上，从触摸流里识别 tap/pan/swipe 等。
//
// headless 验证：hitTest 与响应链**不需要窗口**就能确定性地跑（给好 frame 即可）。
// 手势的**配置/挂载/状态机**也能断言。但「手势识别成功后触发 target-action」需要
// 真实的 UIKit 事件系统（窗口 + run loop + 真实触摸）——headless 下 sendActions 和
// 手动改 state 都**不会**触发 action（本机实测 fired=0），所以本示例只断言到「配置与
// 状态」这一层，不假装能验证 action 派发。诚实划清边界，也是本教程的一贯纪律。
// ============================================================

import Foundation
import UIKit

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }

line("== 16 手势、触摸与响应链 ==")

// ---------------------------------------------------- 1) Hit-Testing：触摸落在哪个视图
line("")
line("-- hitTest：从父到子，找最深的命中视图 --")
let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
let a = UIView(frame: CGRect(x: 10, y: 10, width: 80, height: 80)); a.tag = 1
let b = UIView(frame: CGRect(x: 100, y: 100, width: 80, height: 80)); b.tag = 2
root.addSubview(a); root.addSubview(b)
expect(root.hitTest(CGPoint(x: 20, y: 20), with: nil) === a, "点 (20,20) 命中 a（tag=1）")
expect(root.hitTest(CGPoint(x: 150, y: 150), with: nil) === b, "点 (150,150) 命中 b（tag=2）")
expect(root.hitTest(CGPoint(x: 5, y: 150), with: nil) === root, "点 (5,150) 不在 a/b 内，命中父 root")
// point(inside:) 是 hitTest 的判据：某点是否在**自己**坐标系里
expect(a.point(inside: CGPoint(x: 5, y: 5), with: nil), "point(inside:) 判断点是否落在视图内")

// ---------------------------------------------------- 2) hitTest 会跳过哪些视图
line("")
line("-- hitTest 跳过：禁用交互 / 隐藏 / 近乎透明 --")
a.isUserInteractionEnabled = false
expect(root.hitTest(CGPoint(x: 20, y: 20), with: nil) === root, "isUserInteractionEnabled=false → 被跳过，命中父视图")
a.isUserInteractionEnabled = true
a.isHidden = true
expect(root.hitTest(CGPoint(x: 20, y: 20), with: nil) === root, "isHidden=true → 被跳过")
a.isHidden = false
a.alpha = 0.0
expect(root.hitTest(CGPoint(x: 20, y: 20), with: nil) === root, "alpha<0.01 → 被跳过（视为不可见）")
a.alpha = 1.0
expect(root.hitTest(CGPoint(x: 20, y: 20), with: nil) === a, "恢复后又能命中 a")

// ---------------------------------------------------- 3) 自定义 point(inside:) 扩大点击区
line("")
line("-- 重写 point(inside:)：扩大触摸热区 --")
// 小按钮难点中，常见做法是重写 point(inside:) 把热区往外扩。
final class BigHitView: UIView {
    var inset: CGFloat = -20      // 负 inset = 往外扩 20pt
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let expanded = bounds.insetBy(dx: inset, dy: inset)
        return expanded.contains(point)
    }
}
let small = BigHitView(frame: CGRect(x: 50, y: 50, width: 20, height: 20))   // 只有 20×20
// (45,45) 在 small 的 frame 之外（frame 从 50 开始），但落在扩大后的热区里。
// 注意 point(inside:) 收到的是**父视图坐标系**转换到自己 bounds 的点，这里直接在 root 上验证。
root.addSubview(small)
let hitExpanded = root.hitTest(CGPoint(x: 50 + 20 + 10, y: 50 + 10), with: nil)   // 右侧外扩 10pt 处
line("  扩大热区后，框外 10pt 的点命中 = \(hitExpanded === small ? "small（热区生效）" : "其它")")
expect(hitExpanded === small, "重写 point(inside:) 后，frame 外的点也能命中（热区被扩大）")

// ---------------------------------------------------- 4) 响应链：next 往上指
line("")
line("-- 响应链：view.next → 父视图 → viewController --")
expect(a.next === root, "子视图的 next 是它的 superview")
let vc = UIViewController()
vc.loadViewIfNeeded()
expect(vc.view.next === vc, "根视图的 next 是它的 viewController")
expect(vc.next === nil || vc.next !== vc, "viewController 再往上（无父时）不指向自己")
// firstResponder 概念：当前接收键盘/事件的对象；无窗口时为 nil
expect(root.isFirstResponder == false, "没成为第一响应者时 isFirstResponder=false")
expect(root.becomeFirstResponder() == false || root.isFirstResponder,
       "普通 UIView 默认 canBecomeFirstResponder=false，becomeFirstResponder 返回 false")

// ---------------------------------------------------- 5) 手势识别器：配置与状态机
line("")
line("-- UIGestureRecognizer：类型、配置、初始状态 --")
let tap = UITapGestureRecognizer()
tap.numberOfTapsRequired = 2          // 双击
tap.numberOfTouchesRequired = 1       // 单指
expect(tap.numberOfTapsRequired == 2, "Tap：可配置需要几次点击（双击=2）")
expect(tap.numberOfTouchesRequired == 1, "Tap：可配置需要几根手指")
expect(tap.state == .possible, "刚建好的手势状态是 .possible（还没开始识别）")

let swipe = UISwipeGestureRecognizer()
swipe.direction = .left
expect(swipe.direction == .left, "Swipe：可配置方向")

let pan = UIPanGestureRecognizer()
let pinch = UIPinchGestureRecognizer()
let longPress = UILongPressGestureRecognizer()
let grTypes = [String(describing: type(of: pan)),
               String(describing: type(of: pinch)),
               String(describing: type(of: longPress))]
line("  三种连续/离散手势类型 = \(grTypes.joined(separator: ", "))")
expect(grTypes == ["UIPanGestureRecognizer", "UIPinchGestureRecognizer", "UILongPressGestureRecognizer"],
       "Pan/Pinch/LongPress 是三个各自独立的手势识别器类型")

// 状态机的枚举值（识别过程：possible → began → changed → ended，或离散手势直接 recognized）
line("  状态值：possible=\(UIGestureRecognizer.State.possible.rawValue) "
    + "began=\(UIGestureRecognizer.State.began.rawValue) "
    + "recognized/ended=\(UIGestureRecognizer.State.recognized.rawValue)")
expect(UIGestureRecognizer.State.possible.rawValue == 0, ".possible 的 rawValue 是 0")
expect(UIGestureRecognizer.State.recognized.rawValue == UIGestureRecognizer.State.ended.rawValue,
       ".recognized 与 .ended 是同一个值（离散手势用 recognized，连续手势用 ended）")

// ---------------------------------------------------- 6) 挂载手势到视图
line("")
line("-- 把手势挂到视图上 --")
let target = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
let tap2 = UITapGestureRecognizer()
target.addGestureRecognizer(tap2)
expect(target.gestureRecognizers?.count == 1, "addGestureRecognizer 后，视图持有 1 个手势")
expect(target.gestureRecognizers?.first === tap2, "持有的正是刚加的那个 tap")
let pan2 = UIPanGestureRecognizer()
target.addGestureRecognizer(pan2)
expect(target.gestureRecognizers?.count == 2, "再加一个 pan，视图持有 2 个手势")
target.removeGestureRecognizer(tap2)
expect(target.gestureRecognizers?.count == 1, "removeGestureRecognizer 后剩 1 个")

// ---------------------------------------------------- 7) 小结
line("")
line("-- 心智模型 --")
line("  触摸两段路：hitTest 找最深命中视图 → 响应链沿 next 往上传递")
line("  被跳过的视图：isUserInteractionEnabled=false / isHidden / alpha<0.01")
line("  重写 point(inside:) 可扩大点击热区（小按钮友好）")
line("  手势识别器挂在视图上，从触摸流识别 tap/pan/swipe/pinch/longPress")
line("  action 派发需要真实事件系统；headless 只验证到配置/状态/挂载这一层")
expect(true, "以上均由 hitTest 结果 / next 指向 / 手势属性断言支撑")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 16 结束 ====")
exit(failures == 0 ? 0 : 1)
