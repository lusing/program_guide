// ============================================================
// 09 - 视图与布局：frame、autoresizing、Auto Layout、NSStackView
//
// 编译：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name layout main.swift -o 09_layout \
//          -framework Foundation -framework AppKit
// 运行：
//   ./09_layout
//
// 本章只碰 NSView，不碰 NSWindow，所以不需要跑 run loop ——
// 视图树和 Auto Layout 求解都是纯计算，命令行里就能验。
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

// MARK: - 1) 视图树与坐标系

print("== 视图树与坐标系 ==")
let root = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
let child = NSView(frame: NSRect(x: 20, y: 30, width: 40, height: 40))
root.addSubview(child)
expect(root.subviews.count == 1, "addSubview 之后有 1 个子视图")
expect(child.superview === root, "子视图的 superview 指回父视图")
expect(root.subviews.first === child, "subviews 的顺序就是添加顺序")

// AppKit 的原点在**左下角**（UIKit 在左上角）
let converted = child.convert(NSPoint(x: 0, y: 0), to: root)
print("  child 原点在 root 坐标系里 = \(converted)")
expect(converted.x == 20 && converted.y == 30, "坐标换算就是加上子视图的 origin")

// 想让某个子树用左上角原点，就重写 isFlipped —— 但只影响你自己的 draw 和
// 手工算的坐标，不影响 Auto Layout 的语义（leading = 左，top = 上）
final class FlippedView: NSView {
    override var isFlipped: Bool { true }
}
let flipped = FlippedView(frame: NSRect(x: 0, y: 0, width: 50, height: 50))
expect(flipped.isFlipped, "isFlipped 可以重写")
expect(root.isFlipped == false, "默认不翻转")

// 坑：AppKit 的 NSView.tag 是**只读**的（UIView 的可以写）。
// 需要「找视图」时得自己存引用，或者用 identifier（NSUserInterfaceItemIdentifier）
let labeled = NSView(frame: .zero)
labeled.identifier = NSUserInterfaceItemIdentifier("detail")
expect(labeled.identifier?.rawValue == "detail", "identifier 用来给视图做标记")
expect(child.tag == -1, "NSView.tag 没有设置过时是 -1")

// MARK: - 2) autoresizingMask（老式布局）

print("")
print("== autoresizingMask ==")
// 这是 Auto Layout 之前的做法：声明「父视图变宽时我跟着变宽」这类规则。
// 现在新代码一律用 Auto Layout，但读老代码、读 XIB 时还是会碰到它。
let parent = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
let grow = NSView(frame: NSRect(x: 10, y: 10, width: 50, height: 20))
grow.autoresizingMask = [.width, .height]
parent.addSubview(grow)

parent.setFrameSize(NSSize(width: 400, height: 200))
print("  .width/.height 之后 = \(grow.frame)")
expect(grow.frame.width == 250, "父视图宽 +200，子视图宽也 +200（实际 \(grow.frame.width)）")
expect(grow.frame.height == 120, "父视图高 +100，子视图高也 +100（实际 \(grow.frame.height)）")
expect(grow.frame.origin.x == 10, "左边距保持不动")

// 只让「左边距」可变 → 子视图被推到父视图右边
let parent2 = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
let pinned = NSView(frame: NSRect(x: 150, y: 10, width: 30, height: 20))
pinned.autoresizingMask = [.minXMargin]
parent2.addSubview(pinned)
parent2.setFrameSize(NSSize(width: 400, height: 200))
print("  .minXMargin 之后 = \(pinned.frame)")
expect(pinned.frame.origin.x == 350, "右边距保持不变，左边距被拉开（实际 \(pinned.frame.origin.x)）")
expect(pinned.frame.width == 30, "宽度不变")

// MARK: - 3) Auto Layout

print("")
print("== Auto Layout ==")
let container = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
let box = NSView()
// 坑：用 Auto Layout 的视图必须关掉自动转换。忘了这一行，
// AppKit 会把 frame 变成一堆隐式约束，和手写约束打架，报错信息还特别难懂。
box.translatesAutoresizingMaskIntoConstraints = false
container.addSubview(box)
NSLayoutConstraint.activate([
    box.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
    box.topAnchor.constraint(equalTo: container.topAnchor, constant: 30),
    box.widthAnchor.constraint(equalToConstant: 100),
    box.heightAnchor.constraint(equalToConstant: 40),
])
// 约束加完不会立刻生效，要显式求解一次（窗口里由 run loop 自动做）
container.layoutSubtreeIfNeeded()
print("  解出的 frame = \(box.frame)")
expect(box.frame.origin.x == 20, "leading 20（实际 \(box.frame.origin.x)）")
expect(box.frame.width == 100 && box.frame.height == 40, "尺寸来自宽高约束")
// top 约束是「离父视图顶部 30」，AppKit 原点在左下，所以 y = 200 - 30 - 40
expect(box.frame.origin.y == 130, "top 30 换算成 y = 130（实际 \(box.frame.origin.y)）")
// 坑：约束不是全部挂在父视图上 —— 谁是两个视图的共同祖先就挂谁。
// 这里 leading/top 是 box 与 container 之间的，所以挂在 container 上；
// width/height 只涉及 box 自己，就挂在 box 上。
expect(container.constraints.count == 2, "位置约束挂在共同祖先上（实际 \(container.constraints.count)）")
expect(box.constraints.count == 2, "尺寸约束挂在视图自己身上（实际 \(box.constraints.count)）")
expect(container.hasAmbiguousLayout == false, "约束足够，没有歧义")

// 少一条约束会怎样：去掉高度约束，让高度由「离底部 20」决定
let container2 = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
let box2 = NSView()
box2.translatesAutoresizingMaskIntoConstraints = false
container2.addSubview(box2)
NSLayoutConstraint.activate([
    box2.leadingAnchor.constraint(equalTo: container2.leadingAnchor, constant: 10),
    box2.trailingAnchor.constraint(equalTo: container2.trailingAnchor, constant: -10),
    box2.topAnchor.constraint(equalTo: container2.topAnchor, constant: 10),
    box2.bottomAnchor.constraint(equalTo: container2.bottomAnchor, constant: -10),
])
container2.layoutSubtreeIfNeeded()
print("  四面都钉住的 frame = \(box2.frame)")
expect(box2.frame.width == 280, "左右各 10 → 宽 280（实际 \(box2.frame.width)）")
expect(box2.frame.height == 180, "上下各 10 → 高 180（实际 \(box2.frame.height)）")
// 坑：trailing / bottom 的 constant 是**负数**（往里缩），写正数会往反方向顶出去
expect(box2.frame.origin.y == 10, "bottom -10 等价于 y = 10（实际 \(box2.frame.origin.y)）")

// MARK: - 4) intrinsicContentSize 与 fittingSize

print("")
print("== 内容尺寸 ==")
let label = NSTextField(labelWithString: "Hello")
print("  label intrinsic = \(label.intrinsicContentSize)  fitting = \(label.fittingSize)")
// 字体相关的尺寸随系统字体而变，所以这里只断言「性质」，不写死数字
expect(label.intrinsicContentSize.width > 0, "标签有固有宽度")
expect(label.intrinsicContentSize.height > 0, "标签有固有高度")
expect(label.fittingSize.width >= label.intrinsicContentSize.width, "fittingSize 不小于固有尺寸")

// 只给了固有宽高、没给宽高约束时，视图会自己保持固有大小
let auto = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
let stretched = NSTextField(labelWithString: "Hi")
stretched.translatesAutoresizingMaskIntoConstraints = false
auto.addSubview(stretched)
NSLayoutConstraint.activate([
    stretched.leadingAnchor.constraint(equalTo: auto.leadingAnchor, constant: 5),
    stretched.centerYAnchor.constraint(equalTo: auto.centerYAnchor),
])
auto.layoutSubtreeIfNeeded()
print("  只钉左边的标签 = \(stretched.frame)")
expect(stretched.frame.width <= label.intrinsicContentSize.width,
       "没有宽度约束时，宽度由固有尺寸决定")
expect(stretched.frame.height > 0, "高度也是固有尺寸给的")

// MARK: - 5) NSStackView

print("")
print("== NSStackView ==")
let stack = NSStackView(views: [
    NSTextField(labelWithString: "第一项"),
    NSTextField(labelWithString: "第二项"),
])
stack.orientation = .vertical
stack.spacing = 8
stack.alignment = .leading
print("  vertical fitting = \(stack.fittingSize)")
expect(stack.views.count == 2, "装了两个视图")
expect(stack.orientation == .vertical, "方向是竖向")
expect(stack.spacing == 8, "间距 8")

let vStack = stack.fittingSize
stack.orientation = .horizontal
let hStack = stack.fittingSize
print("  horizontal fitting = \(hStack)")
expect(hStack.width > vStack.width, "横向排列时更宽（实际 \(hStack.width) > \(vStack.width)）")
expect(hStack.height < vStack.height, "横向排列时更矮（实际 \(hStack.height) < \(vStack.height)）")

// 运行时往里加视图
let extra = NSTextField(labelWithString: "第三项")
stack.addView(extra, in: .bottom)
expect(stack.views.count == 3, "addView(_:in:) 能动态加视图")
stack.removeView(stack.views[0])
expect(stack.views.count == 2, "removeView 能删掉视图")

// MARK: - 6) NSScrollView

print("")
print("== NSScrollView ==")
let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 200, height: 120))
let big = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 600))
scroll.documentView = big
scroll.hasVerticalScroller = true
print("  documentVisibleRect = \(scroll.documentVisibleRect)")
expect(scroll.documentView === big, "documentView 是被滚动的内容")
print("  contentSize = \(scroll.contentSize)")
expect(scroll.contentView.documentView === big, "文档视图装在 clip view（contentView）里")
expect(big.frame.size == NSSize(width: 200, height: 600), "文档视图尺寸保持 200x600")
expect(scroll.contentSize.height < big.frame.height, "contentSize 是可见区尺寸，小于文档总高")
expect(scroll.documentVisibleRect.height == 120, "可见区域高度是滚动视图的高度")
expect(scroll.hasVerticalScroller, "开了竖向滚动条")

print("==== 09 结束 ====")
exit(failures == 0 ? 0 : 1)
