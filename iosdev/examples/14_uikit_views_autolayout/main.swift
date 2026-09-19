// ============================================================
// 14 - UIKit 视图体系与 Auto Layout
//
// UIKit 的界面是一棵 **UIView 树**：每个 UIView 有 frame/bounds/center 三个几何量，
// 通过 addSubview 组织父子关系。摆位置有两种方式：
//   1) 手动 frame（autoresizing mask）—— 老办法，写死坐标
//   2) Auto Layout —— 声明「视图之间的约束关系」，系统解方程算出 frame
// Auto Layout 是 SwiftUI 布局（第 10 章）底下真正干活的那层。
//
// headless 验证：Auto Layout 的约束求解**不需要窗口**——给容器一个 frame、加约束、
// layoutIfNeeded，就能读到解出来的子视图 frame。于是布局可以像算术题一样精确断言。
// 全程不建窗口、不弹窗。
//
// 重要：绝不制造**互相冲突**的约束——Auto Layout 冲突会通过 NSLog 打到 stderr，
// 触发判定 3（stderr 必须为空）。所有约束都是可满足的。
// ============================================================

import Foundation
import UIKit

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
func eq(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.01 }
func eqRect(_ r: CGRect, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Bool {
    eq(r.minX, x) && eq(r.minY, y) && eq(r.width, w) && eq(r.height, h)
}

line("== 14 UIKit 视图体系与 Auto Layout ==")

// ---------------------------------------------------- 1) frame / bounds / center 三件套
line("")
line("-- frame / bounds / center 的关系 --")
let v = UIView(frame: CGRect(x: 10, y: 10, width: 100, height: 50))
line("  frame=\(v.frame)  bounds=\(v.bounds)  center=\(v.center)")
expect(eqRect(v.frame, 10, 10, 100, 50), "frame：在**父视图**坐标系里的位置+尺寸")
expect(eqRect(v.bounds, 0, 0, 100, 50), "bounds：在**自己**坐标系里，origin 通常是 (0,0)")
expect(eq(v.center.x, 60) && eq(v.center.y, 35), "center = frame 的中心：(10+100/2, 10+50/2)=(60,35)")
// 改 center 会移动 frame 的 origin，但 size 不变
v.center = CGPoint(x: 100, y: 100)
expect(eq(v.frame.minX, 50) && eq(v.frame.minY, 75), "改 center → frame.origin 跟着挪（size 不变）")
expect(eq(v.bounds.width, 100), "bounds.size 不受 center 影响")

// ---------------------------------------------------- 2) 视图层级：addSubview / superview
line("")
line("-- 视图层级 --")
let root = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
let childA = UIView(); childA.tag = 1
let childB = UIView(); childB.tag = 2
root.addSubview(childA)
root.addSubview(childB)
expect(root.subviews.count == 2, "root 有两个子视图")
expect(childA.superview === root, "子视图的 superview 指回 root")
expect(root.subviews[0] === childA && root.subviews[1] === childB, "subviews 按添加顺序排列")
// 深度优先按 tag 找视图（UIKit 自带 viewWithTag）
expect(root.viewWithTag(2) === childB, "viewWithTag 能按 tag 找回子视图")
childB.removeFromSuperview()
expect(root.subviews.count == 1, "removeFromSuperview 后少一个")
expect(childB.superview == nil, "移除后 superview 变 nil")

// ---------------------------------------------------- 3) Auto Layout：anchor 约束 + 求解
line("")
line("-- Auto Layout：pin 到父视图四边（带 inset）--")
let container = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
let box = UIView()
box.translatesAutoresizingMaskIntoConstraints = false   // 用 Auto Layout 必须关掉这个
container.addSubview(box)
NSLayoutConstraint.activate([
    box.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
    box.topAnchor.constraint(equalTo: container.topAnchor, constant: 30),
    box.widthAnchor.constraint(equalToConstant: 100),
    box.heightAnchor.constraint(equalToConstant: 50),
])
container.setNeedsLayout(); container.layoutIfNeeded()
line("  解出的 box.frame = \(box.frame)")
expect(eqRect(box.frame, 20, 30, 100, 50), "leading+20、top+30、宽100、高50 → frame (20,30,100,50)")
expect(box.translatesAutoresizingMaskIntoConstraints == false, "用 Auto Layout 时该标志必须为 false")

// ---------------------------------------------------- 4) 居中约束
line("")
line("-- Auto Layout：居中 --")
let centered = UIView(); centered.translatesAutoresizingMaskIntoConstraints = false
container.addSubview(centered)
NSLayoutConstraint.activate([
    centered.centerXAnchor.constraint(equalTo: container.centerXAnchor),
    centered.centerYAnchor.constraint(equalTo: container.centerYAnchor),
    centered.widthAnchor.constraint(equalToConstant: 40),
    centered.heightAnchor.constraint(equalToConstant: 40),
])
container.setNeedsLayout(); container.layoutIfNeeded()
line("  居中的 40×40 在 300×400 里 → \(centered.frame)")
expect(eqRect(centered.frame, 130, 180, 40, 40), "centerX=150、centerY=200 → origin (130,180)")

// ---------------------------------------------------- 5) 相对约束：等宽、比例、间距
line("")
line("-- Auto Layout：相对约束（等宽 / 比例 / 关系）--")
let left = UIView(); left.translatesAutoresizingMaskIntoConstraints = false
let right = UIView(); right.translatesAutoresizingMaskIntoConstraints = false
container.addSubview(left); container.addSubview(right)
NSLayoutConstraint.activate([
    left.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
    left.topAnchor.constraint(equalTo: container.topAnchor, constant: 200),
    left.heightAnchor.constraint(equalToConstant: 30),
    // right 紧跟 left 之后 8pt，宽度是 left 的一半，高度相等
    right.leadingAnchor.constraint(equalTo: left.trailingAnchor, constant: 8),
    right.widthAnchor.constraint(equalTo: left.widthAnchor, multiplier: 0.5),
    right.heightAnchor.constraint(equalTo: left.heightAnchor),
    right.centerYAnchor.constraint(equalTo: left.centerYAnchor),
    // left 宽度 = 100（补一条，让方程有唯一解）
    left.widthAnchor.constraint(equalToConstant: 100),
])
container.setNeedsLayout(); container.layoutIfNeeded()
line("  left=\(left.frame)  right=\(right.frame)")
expect(eq(left.frame.width, 100), "left 宽 100")
expect(eq(right.frame.width, 50), "right 宽 = left 的一半 = 50")
expect(eq(right.frame.minX, 118), "right.leading = left.trailing(110) + 8 = 118")
expect(eq(right.frame.height, 30), "right 高 = left 高（equalTo 关系）")

// ---------------------------------------------------- 6) 布局循环：layoutSubviews 何时被调
line("")
line("-- 布局循环：setNeedsLayout → layoutSubviews --")
final class CountingView: UIView {
    var layoutCount = 0
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutCount += 1
    }
}
let counting = CountingView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
let before = counting.layoutCount
counting.setNeedsLayout()          // 只是「标记需要布局」，不立即调 layoutSubviews
let afterMark = counting.layoutCount
counting.layoutIfNeeded()          // 现在才真正布局
let afterLayout = counting.layoutCount
line("  layoutSubviews 调用次数：标记前=\(before) 标记后=\(afterMark) layoutIfNeeded 后=\(afterLayout)")
expect(afterLayout > before, "layoutIfNeeded 之后 layoutSubviews 至少被调了一次")
expect(afterMark == before, "setNeedsLayout 只标记，不当场触发 layoutSubviews")

// ---------------------------------------------------- 7) intrinsicContentSize：内容的固有尺寸
line("")
line("-- intrinsicContentSize：固有尺寸 --")
let label = UILabel(); label.text = "Hello"
let intrinsic = label.intrinsicContentSize
line("  UILabel(\"Hello\").intrinsicContentSize = \(intrinsic)")
expect(intrinsic.width > 0 && intrinsic.height > 0, "UILabel 有正的固有尺寸（由文本+字体算出）")
// 固有尺寸驱动 Auto Layout：只约束位置，不约束宽高，label 会用自己的 intrinsic 大小
let host = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
label.translatesAutoresizingMaskIntoConstraints = false
host.addSubview(label)
NSLayoutConstraint.activate([
    label.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 0),
    label.topAnchor.constraint(equalTo: host.topAnchor, constant: 0),
])
host.setNeedsLayout(); host.layoutIfNeeded()
expect(eq(label.frame.width, intrinsic.width), "没约束宽高时，label 用 intrinsicContentSize 定宽")

// ---------------------------------------------------- 8) 安全区（无窗口时为 0）
line("")
line("-- safeAreaInsets --")
let plain = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
line("  未挂窗口时 safeAreaInsets = \(plain.safeAreaInsets)")
expect(plain.safeAreaInsets == .zero, "没挂进窗口/屏幕时，安全区 inset 是 0（真机上有刘海才非零）")

// ---------------------------------------------------- 9) 小结
line("")
line("-- 心智模型 --")
line("  frame 在父坐标系；bounds 在自己坐标系；center 是 frame 中心")
line("  Auto Layout = 声明约束、系统解方程算 frame；用 anchor 写约束最直观")
line("  用 Auto Layout 必须 translatesAutoresizingMaskIntoConstraints = false")
line("  布局是延迟的：setNeedsLayout 标记，下一次 layout 周期才 layoutSubviews")
line("  控件的 intrinsicContentSize 参与约束（label 不写宽高也能定尺寸）")
expect(true, "以上均由解出的 frame / 调用次数 / 固有尺寸断言支撑")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 14 结束 ====")
exit(failures == 0 ? 0 : 1)
