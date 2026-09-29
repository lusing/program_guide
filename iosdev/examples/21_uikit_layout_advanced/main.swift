// ============================================================
// 21 - UIKit 布局进阶：autoresizingMask / VFL / 优先级 / 反推尺寸 / UIStackView
//
// 第 14 章讲了 UIView 的三个几何量和 anchor 式 Auto Layout。这一章补上实战里绕不开的
// 五块进阶内容：
//   1) autoresizingMask —— Auto Layout 之前的自适应机制，今天仍在 scroll view 的
//      内容视图、cell 内部布局里大量存在
//   2) translatesAutoresizingMaskIntoConstraints —— 两套系统之间的开关（谁生成约束）
//   3) NSLayoutConstraint 原始形式 + VFL 视觉格式语言 —— 读得懂老代码 / Masonry 的底层
//   4) 布局优先级 —— 固有尺寸和别的约束打架时，靠 priority 裁决
//   5) systemLayoutSizeFitting / UIStackView —— 由约束**反推**尺寸；把一串约束换成一个对象
//
// headless 验证：给容器 frame/bounds，setNeedsLayout() + layoutIfNeeded() 之后约束
// **同步**求解完毕，子视图 frame 可以直接读回来断言。全程不建窗口、不弹 UI。
//
// 重要：绝不制造**互相冲突的必需(required)约束**——那种冲突会通过 NSLog 打到 stderr，
// 触发判定 3（stderr 必须为空）。本示例的约束集全部可解；低优先级约束被打破是正常行为，
// 不会打日志。
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

// 把一条约束打印成**不含对象地址**的形式（含地址的行在 debug/release 之间必然不一致，
// 会破掉本仓库的逐字节比对判定）
func describeConstraint(_ c: NSLayoutConstraint) -> String {
    let fi = c.firstItem.map { String(describing: type(of: $0)) } ?? "nil"
    let si = c.secondItem.map { String(describing: type(of: $0)) } ?? "nil"
    return "\(fi)#\(c.firstAttribute.rawValue) \(c.relation.rawValue) \(si)#\(c.secondAttribute.rawValue) c=\(c.constant)"
}
// 有多少条约束的某一端是 UILayoutGuide（而不是 UIView）
func guideBacked(_ cs: [NSLayoutConstraint]) -> Int {
    cs.filter { $0.firstItem is UILayoutGuide || $0.secondItem is UILayoutGuide }.count
}

line("== 21 UIKit 布局进阶 ==")

// ---------------------------------------------------- 1) autoresizingMask
line("")
line("-- autoresizingMask：父视图 bounds 变化时，子视图怎么跟着变 --")

// 六个 case 的实际位值（Swift 里没有 .widthSizable/.heightSizable/.none 这几个 ObjC 名，
// 只有下面六个 flexible*；"固定"用空集合 [] 表示）
line("  flexibleLeftMargin=\(UIView.AutoresizingMask.flexibleLeftMargin.rawValue)"
     + " flexibleWidth=\(UIView.AutoresizingMask.flexibleWidth.rawValue)"
     + " flexibleRightMargin=\(UIView.AutoresizingMask.flexibleRightMargin.rawValue)")
line("  flexibleTopMargin=\(UIView.AutoresizingMask.flexibleTopMargin.rawValue)"
     + " flexibleHeight=\(UIView.AutoresizingMask.flexibleHeight.rawValue)"
     + " flexibleBottomMargin=\(UIView.AutoresizingMask.flexibleBottomMargin.rawValue)")
line("  [.flexibleWidth, .flexibleBottomMargin].rawValue = \(UIView.AutoresizingMask([.flexibleWidth, .flexibleBottomMargin]).rawValue)")
line("  [].rawValue = \(UIView.AutoresizingMask().rawValue)")

// —— 场景 A：父只变高，宽度不动 ——
let parentV = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))

// 顶部横条：上边距固定 + 高度固定 + 下边距弹性 + 宽弹性 → 永远贴在顶部、跟着父的宽变
let header = UIView(frame: CGRect(x: 10, y: 20, width: 300, height: 100))
header.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
parentV.addSubview(header)

// 居中小块：四边 margin 全弹性、自身尺寸固定 → 父变大时按比例挪到中间
let centered = UIView(frame: CGRect(x: 130, y: 220, width: 60, height: 40))
centered.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin,
                             .flexibleTopMargin, .flexibleBottomMargin]
parentV.addSubview(centered)

// 底部工具条（弹性的只有上边距和宽）：下边距固定 0、高度固定 → 真的贴住新底边
let bottomBar = UIView(frame: CGRect(x: 220, y: 440, width: 100, height: 40))
bottomBar.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleWidth]
parentV.addSubview(bottomBar)

// 同一位置再加一条**高度也弹性**的：弹性的项按比例缩放，固定的项保持点数不变
let growBar = UIView(frame: CGRect(x: 220, y: 440, width: 100, height: 40))
growBar.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin,
                            .flexibleWidth, .flexibleHeight]
parentV.addSubview(growBar)

parentV.bounds = CGRect(x: 0, y: 0, width: 320, height: 800)
parentV.setNeedsLayout()
parentV.layoutIfNeeded()
line("  场景 A：parent bounds 320x480 → 320x800")
line("  header.frame   = \(header.frame)")
line("  centered.frame = \(centered.frame)")
line("  bottomBar.frame = \(bottomBar.frame)")
line("  growBar.frame   = \(growBar.frame)")
expect(eqRect(header.frame, 10, 20, 300, 100),
       "header 纹丝不动：上边距和高度都是固定的，弹性的只有宽和下边距（父的宽没变）")
expect(eq(centered.frame.minY, 380), "centered 垂直居中：(800-40)/2 = 380")
expect(eq(centered.frame.minX, 130), "centered 的 x 没变（父的宽没变，左右 margin 都固定不变）")
expect(eq(bottomBar.frame.minY, 760), "bottomBar 贴住新底边：800-40 = 760（下边距固定 0、高度固定）")
expect(eq(bottomBar.frame.maxX, 320), "bottomBar 右边仍贴父右边缘（右下 margin 固定）")
expect(eq(growBar.frame.height, 40 * 800 / 480), "growBar 高度也弹性 → 按比例缩放：40 × 800/480 = \(growBar.frame.height)")
expect(eq(growBar.frame.maxY, 800), "growBar 底边仍贴父底边（固定项保持 0 个点）")

// —— 场景 B：父只变宽，高度不动 ——
let parentH = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
let stretchy = UIView(frame: CGRect(x: 8, y: 8, width: 100, height: 44))
stretchy.autoresizingMask = [.flexibleWidth]
parentH.addSubview(stretchy)
let huggingRight = UIView(frame: CGRect(x: 220, y: 8, width: 92, height: 44))
huggingRight.autoresizingMask = [.flexibleLeftMargin]
parentH.addSubview(huggingRight)

parentH.bounds = CGRect(x: 0, y: 0, width: 640, height: 480)
parentH.setNeedsLayout()
parentH.layoutIfNeeded()
line("  场景 B：parent bounds 320x480 → 640x480")
line("  stretchy.frame      = \(stretchy.frame)")
line("  huggingRight.frame  = \(huggingRight.frame)")
expect(eq(stretchy.frame.width, 420), "flexibleWidth：多出来的 320 宽全给了它（100+320=420）")
expect(eq(stretchy.frame.height, 44), "只有宽弹性 → 高度不受影响")
expect(eq(huggingRight.frame.minX, 540),
       "flexibleLeftMargin：左边距按比例放大 220 × (640-92-8)/(320-92-8) = 540")
expect(eq(huggingRight.frame.maxX, parentH.bounds.width - 8), "flexibleLeftMargin 保住右边距（右边仍留 8）")

// ---------------------------------------------------- 2) translatesAutoresizingMaskIntoConstraints
line("")
line("-- translatesAutoresizingMaskIntoConstraints：谁负责生成约束 --")
let raw = UIView(frame: CGRect(x: 5, y: 5, width: 40, height: 40))
line("  新建 UIView 默认 translatesAutoresizingMaskIntoConstraints = \(raw.translatesAutoresizingMaskIntoConstraints)")
expect(raw.translatesAutoresizingMaskIntoConstraints, "默认 true：frame 会被翻译成约束")

// UIStackView 接管布局时会自动把 arranged subview 的这个开关关掉——这是「不用自己写
// 约束」的实现基础。
let switchHost = UIStackView()
switchHost.axis = .horizontal
let beforeAdd = UIView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
line("  加入 stack 之前：beforeAdd.translatesAutoresizingMaskIntoConstraints = \(beforeAdd.translatesAutoresizingMaskIntoConstraints)")
switchHost.addArrangedSubview(beforeAdd)
line("  加入 stack 之后：beforeAdd.translatesAutoresizingMaskIntoConstraints = \(beforeAdd.translatesAutoresizingMaskIntoConstraints)")
expect(!beforeAdd.translatesAutoresizingMaskIntoConstraints,
       "addArrangedSubview 自动把 TAMIC 置 false（stack 负责给它加约束）")

// TAMIC=false 却不给任何约束：Auto Layout 不会凭空定位置，frame 保持你写进去的值——
// 真机上表现为「加了约束却完全没反应」，老代码里极常见。
let noConstraint = UIView(frame: CGRect(x: 12, y: 34, width: 66, height: 88))
noConstraint.translatesAutoresizingMaskIntoConstraints = false
let bareHost = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
bareHost.addSubview(noConstraint)
bareHost.setNeedsLayout()
bareHost.layoutIfNeeded()
line("  TAMIC=false 且零约束，layout 之后 frame = \(noConstraint.frame)")
expect(eqRect(noConstraint.frame, 12, 34, 66, 88), "没有任何约束时 Auto Layout 不动它，frame 保持原值")

// ---------------------------------------------------- 3) NSLayoutConstraint 原始形式 + multiplier
line("")
line("-- NSLayoutConstraint 原始形式（Masonry / 老代码的写法）--")
let host3 = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
let box = UIView()
box.translatesAutoresizingMaskIntoConstraints = false
host3.addSubview(box)
let leading = NSLayoutConstraint(item: box, attribute: .leading, relatedBy: .equal,
                                 toItem: host3, attribute: .leading,
                                 multiplier: 1, constant: 12)
let top = NSLayoutConstraint(item: box, attribute: .top, relatedBy: .equal,
                             toItem: host3, attribute: .top,
                             multiplier: 1, constant: 20)
// multiplier 用在同一个视图的宽和高上：宽 = 高 × 2
let ratio = NSLayoutConstraint(item: box, attribute: .width, relatedBy: .equal,
                               toItem: box, attribute: .height,
                               multiplier: 2, constant: 0)
let height = NSLayoutConstraint(item: box, attribute: .height, relatedBy: .equal,
                               toItem: nil, attribute: .notAnAttribute,
                               multiplier: 1, constant: 50)
NSLayoutConstraint.activate([leading, top, ratio, height])
host3.setNeedsLayout()
host3.layoutIfNeeded()
line("  box.frame = \(box.frame)")
expect(eqRect(box.frame, 12, 20, 100, 50), "宽=高×2 生效：高 50 → 宽 100")
line("  height 约束：relation.rawValue=\(height.relation.rawValue) constant=\(height.constant) priority=\(height.priority.rawValue)")
line("  relatedBy 等号第二个 item 为 nil 时（写自身尺寸）：height.secondItem == nil → \(height.secondItem == nil)")
expect(height.secondItem == nil, "自身尺寸约束没有第二个 item（secondItem 为 nil）")

// 也可以写不等式（relatedBy: .greaterThanOrEqual / .lessThanOrEqual）
let inequality = NSLayoutConstraint(item: box, attribute: .trailing, relatedBy: .lessThanOrEqual,
                                    toItem: host3, attribute: .trailing,
                                    multiplier: 1, constant: -10)
inequality.isActive = true
host3.setNeedsLayout()
host3.layoutIfNeeded()
line("  加了一条 box.trailing <= host3.trailing-10 之后 box.frame = \(box.frame)（仍满足，不参与改变解）")
line("  Relation 的 rawValue：lessThanOrEqual=\(NSLayoutConstraint.Relation.lessThanOrEqual.rawValue)"
     + " equal=\(NSLayoutConstraint.Relation.equal.rawValue)"
     + " greaterThanOrEqual=\(NSLayoutConstraint.Relation.greaterThanOrEqual.rawValue)")
expect(box.frame.maxX <= host3.bounds.width - 10 + 0.01, "不等式约束被满足")

// ---------------------------------------------------- 4) VFL 视觉格式语言
line("")
line("-- VFL：一行字符串生成一串约束 --")
// 语法：`|` 是容器边缘，`[名字(尺寸)]` 是视图，`-数字-` 是间距，metrics 字典给数字起名。
// 实测 (guideW) 与 (==guideW) **等价**——两者都生成同一条 `width == 80`。

// —— 容器宽 = 串里数字之和时，全部满足 ——
let fitHost = UIView(frame: CGRect(x: 0, y: 0, width: 164, height: 100))   // 16+80+12+40+16
let fa = UIView()
let fb = UIView()
for v in [fa, fb] {
    v.translatesAutoresizingMaskIntoConstraints = false
    fitHost.addSubview(v)
}
let fitHorizontal = NSLayoutConstraint.constraints(
    withVisualFormat: "|-16-[fa(==guideW)]-12-[fb(==40)]-16-|",
    options: [], metrics: ["guideW": 80], views: ["fa": fa, "fb": fb])
let fitVertical = NSLayoutConstraint.constraints(
    withVisualFormat: "V:|-8-[fa(==30)]", options: [], metrics: nil, views: ["fa": fa])
line("  水平串生成 \(fitHorizontal.count) 条约束，垂直串 \(fitVertical.count) 条")
if let faWidth = fitHorizontal.first(where: { $0.firstAttribute == .width && ($0.firstItem as? UIView) === fa }) {
    line("  fa 的那条：firstAttribute=.width relation.rawValue=\(faWidth.relation.rawValue) constant=\(faWidth.constant) priority=\(faWidth.priority.rawValue)")
}
NSLayoutConstraint.activate(fitHorizontal + fitVertical)
fitHost.setNeedsLayout()
fitHost.layoutIfNeeded()
line("  容器宽正好 164：fa.frame = \(fa.frame)   fb.frame = \(fb.frame)")
expect(eqRect(fa.frame, 16, 8, 80, 30), "串里数字之和 == 容器宽 → 每条都被满足（含 V 串的 8/30）")
expect(eqRect(fb.frame, 108, 0, 40, 0), "fb 起点 16+80+12 = 108；高度完全没约束 → 解为 0")

// —— 容器宽 != 串里数字之和：某条约束被**悄悄打破** ——
let wideHost = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
let wa = UIView()
let wb = UIView()
for v in [wa, wb] {
    v.translatesAutoresizingMaskIntoConstraints = false
    wideHost.addSubview(v)
}
let wideConstraints = NSLayoutConstraint.constraints(
    withVisualFormat: "|-16-[wa(==guideW)]-12-[wb(==40)]-16-|",
    options: [], metrics: ["guideW": 80], views: ["wa": wa, "wb": wb])
NSLayoutConstraint.activate(wideConstraints)
wideHost.setNeedsLayout()
wideHost.layoutIfNeeded()
line("  同一个串放进 320 宽的容器：wa.frame = \(wa.frame)   wb.frame = \(wb.frame)")
expect(eq(wa.frame.width, 236) && eq(wb.frame.width, 40),
       "总长对不上时求解器打破其中一条（实测打破 wa 的 width==80，wa 被撑成 236）")
if let broken = wideConstraints.first(where: { $0.firstAttribute == .width && ($0.firstItem as? UIView) === wa }) {
    line("  被打破的那条：constant=\(broken.constant) isActive=\(broken.isActive) priority=\(broken.priority.rawValue)")
    expect(broken.constant == 80 && broken.isActive,
           "约束对象既没被改也没被停用——它只是没被满足，这正是「布局错了却查不到报错」的根源")
}

// —— 关系符号也能写进 VFL，而且 `-|`（不带数字）钉的是谁，有实测答案 ——
let flexHost = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
let fla = UIView()
let flb = UIView()
for v in [fla, flb] {
    v.translatesAutoresizingMaskIntoConstraints = false
    flexHost.addSubview(v)
}
let flexConstraints = NSLayoutConstraint.constraints(
    withVisualFormat: "|-16-[fla(==80)]-(>=12)-[flb(==40)]-|",
    options: [], metrics: nil, views: ["fla": fla, "flb": flb])
NSLayoutConstraint.activate(flexConstraints)
flexHost.setNeedsLayout()
flexHost.layoutIfNeeded()
line("  |-16-[fla(==80)]-(>=12)-[flb(==40)]-| 解出 fla.frame = \(fla.frame)  flb.frame = \(flb.frame)")
expect(eq(fla.frame.width, 80) && eq(flb.frame.width, 40), "用 >= 关系给多余空间留出口，两条宽度约束都被满足")
line("  逐条看这串约束（打印 item 类型 + 属性号 + 关系号，不带对象地址）：")
line("  属性号对照：top=\(NSLayoutConstraint.Attribute.top.rawValue)"
     + " leading=\(NSLayoutConstraint.Attribute.leading.rawValue)"
     + " trailing=\(NSLayoutConstraint.Attribute.trailing.rawValue)"
     + " width=\(NSLayoutConstraint.Attribute.width.rawValue)"
     + " height=\(NSLayoutConstraint.Attribute.height.rawValue)"
     + " notAnAttribute=\(NSLayoutConstraint.Attribute.notAnAttribute.rawValue)")
for c in flexConstraints { line("    " + describeConstraint(c)) }
expect(guideBacked(flexConstraints) == 1,
       "其中正好 1 条的另一端是 UILayoutGuide（即父视图的 layoutMarginsGuide），就是末端那个不带数字的 -|")
expect(eq(flb.frame.maxX, 312), "所以右边缘只到 312 = 320-8（默认 layoutMargins 是 8），不是 320")

// 想钉父视图真正的边：把数字写出来（-0-|）
let zeroHost = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
let za = UIView()
let zb = UIView()
for v in [za, zb] {
    v.translatesAutoresizingMaskIntoConstraints = false
    zeroHost.addSubview(v)
}
let zeroConstraints = NSLayoutConstraint.constraints(
    withVisualFormat: "|-16-[za(==80)]-(>=12)-[zb(==40)]-0-|",
    options: [], metrics: nil, views: ["za": za, "zb": zb])
NSLayoutConstraint.activate(zeroConstraints)
zeroHost.setNeedsLayout()
zeroHost.layoutIfNeeded()
line("  末端改成显式 -0-|：zb.frame = \(zb.frame)")
line("  逐条看这串约束：")
for c in zeroConstraints { line("    " + describeConstraint(c)) }
expect(guideBacked(zeroConstraints) == 0, "带数字的 `-0-|` 两端都是 UIView，没有任何一条指向 UILayoutGuide")
expect(eq(zb.frame.maxX, 320), "显式 -0-| → 贴住父视图右边缘 320")

// 关系符号也能在 VFL 里写：>=、<=
let host4c = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
let atLeast = UIView()
atLeast.translatesAutoresizingMaskIntoConstraints = false
host4c.addSubview(atLeast)
let relConstraints = NSLayoutConstraint.constraints(
    withVisualFormat: "|-12-[atLeast(>=60)]",
    options: [], metrics: nil, views: ["atLeast": atLeast])
NSLayoutConstraint.activate(relConstraints + [
    atLeast.topAnchor.constraint(equalTo: host4c.topAnchor),
    atLeast.heightAnchor.constraint(equalToConstant: 20),
])
host4c.setNeedsLayout()
host4c.layoutIfNeeded()
line("  |-12-[atLeast(>=60)]（只有下限）解出 atLeast.frame = \(atLeast.frame)")
expect(atLeast.frame.width >= 60, ">= 只给下限；没有上限约束时，另一端被 trailing 关系解到贴边")

// options：一次对齐一串视图（NSLayoutConstraint.FormatOptions）
let row2 = UIView(frame: CGRect(x: 0, y: 60, width: 320, height: 50))
let r2a = UIView(); let r2b = UIView()
for v in [r2a, r2b] { v.translatesAutoresizingMaskIntoConstraints = false }
row2.addSubview(r2a)
row2.addSubview(r2b)
// r2b 有明确高度，r2a 没有：alignAllCenterY 把两者中心线对齐
let rowConstraints = NSLayoutConstraint.constraints(
    withVisualFormat: "|-4-[r2a(==60)]-4-[r2b(==20)]-4-|",
    options: .alignAllCenterY,
    metrics: nil,
    views: ["r2a": r2a, "r2b": r2b])
let rowV = NSLayoutConstraint.constraints(
    withVisualFormat: "V:|-15-[r2b]",
    options: [], metrics: nil, views: ["r2b": r2b])
NSLayoutConstraint.activate(rowConstraints + rowV)
row2.setNeedsLayout()
row2.layoutIfNeeded()
line("  alignAllCenterY：r2a.frame=\(r2a.frame)  r2b.frame=\(r2b.frame)")
let centerA = r2a.frame.midY
let centerB = r2b.frame.midY
expect(eq(centerA, centerB), "alignAllCenterY 让同串里的视图垂直中心线对齐（\(centerA) == \(centerB)）")

// ---------------------------------------------------- 5) 布局优先级
line("")
line("-- 优先级：固有尺寸 vs 你写的约束，谁赢看 priority --")
let host5 = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
let priLabel = UILabel()
priLabel.text = "Hello"
host5.addSubview(priLabel)
line("  UILabel 默认 contentHugging(水平) = \(priLabel.contentHuggingPriority(for: .horizontal).rawValue)")
line("  UILabel 默认 contentCompressionResistance(水平) = \(priLabel.contentCompressionResistancePriority(for: .horizontal).rawValue)")
let intrinsicW = priLabel.intrinsicContentSize.width
line("  intrinsicContentSize.width = \(intrinsicW)")

// 情形 A：宽度约束 priority 240 < hugging 250 → 固有尺寸赢
priLabel.translatesAutoresizingMaskIntoConstraints = false
let weakWidth = priLabel.widthAnchor.constraint(equalToConstant: 120)
weakWidth.priority = UILayoutPriority(240)
NSLayoutConstraint.activate([
    priLabel.leadingAnchor.constraint(equalTo: host5.leadingAnchor),
    priLabel.topAnchor.constraint(equalTo: host5.topAnchor),
    weakWidth,
])
host5.setNeedsLayout()
host5.layoutIfNeeded()
line("  A) 宽度约束 @240（低于 hugging 250）→ 实际宽 = \(priLabel.frame.width)")
expect(eq(priLabel.frame.width, intrinsicW), "A：240 < 250，固有尺寸赢，宽度仍是 intrinsic")

// 情形 B：同一条约束提到 260 > 250 → 你写的约束赢
weakWidth.priority = UILayoutPriority(260)
host5.setNeedsLayout()
host5.layoutIfNeeded()
line("  B) 同一条约束 @260（高于 hugging 250）→ 实际宽 = \(priLabel.frame.width)")
expect(eq(priLabel.frame.width, 120), "B：260 > 250，宽度约束赢，label 被拉到 120")
weakWidth.isActive = false

// 抗压缩：两个视图抢同一段宽度，让步的是 compression resistance 低的那个。
let host5b = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
let tough = UILabel(); tough.text = "挺住"
tough.setContentCompressionResistancePriority(UILayoutPriority(900), for: .horizontal)
let soft = UILabel(); soft.text = "随便"
soft.setContentCompressionResistancePriority(UILayoutPriority(100), for: .horizontal)
for v in [tough, soft] {
    v.translatesAutoresizingMaskIntoConstraints = false
    host5b.addSubview(v)
}
NSLayoutConstraint.activate([
    tough.leadingAnchor.constraint(equalTo: host5b.leadingAnchor),
    tough.trailingAnchor.constraint(equalTo: soft.leadingAnchor, constant: -4),
    soft.trailingAnchor.constraint(equalTo: host5b.trailingAnchor),
    tough.topAnchor.constraint(equalTo: host5b.topAnchor),
    soft.topAnchor.constraint(equalTo: host5b.topAnchor),
    tough.widthAnchor.constraint(equalToConstant: 140),
])
// 140 + 4 + 120 = 264 > 200：装不下。把 soft 的宽度约束标成 priority 500（非必需），
// 求解器就有得选——被打破的是它，而不是崩成一堆 required 冲突（那会往 stderr 打日志）。
let softWidth = soft.widthAnchor.constraint(equalToConstant: 120)
softWidth.priority = UILayoutPriority(500)
softWidth.isActive = true
host5b.setNeedsLayout()
host5b.layoutIfNeeded()
line("  tough.frame.width = \(tough.frame.width)   soft.frame.width = \(soft.frame.width)")
expect(eq(tough.frame.width, 140), "required 的 140 宽保住")
expect(eq(soft.frame.width, 56), "soft 被压缩到剩下的 200-140-4 = 56（它的宽度约束只有 500）")
expect(tough.frame.width > soft.frame.width, "高优先级 + 高抗压缩的一侧赢")

// ---------------------------------------------------- 6) systemLayoutSizeFitting：反推尺寸
line("")
line("-- systemLayoutSizeFitting：让约束告诉我「该多高」 --")
let cell = UIView()
cell.translatesAutoresizingMaskIntoConstraints = false
let body = UILabel()
body.numberOfLines = 0
body.font = UIFont.systemFont(ofSize: 17)
body.text = "这是一段足够长的中文文本，用来验证多行标签在固定宽度下能把高度反推出来。"
body.translatesAutoresizingMaskIntoConstraints = false
cell.addSubview(body)
NSLayoutConstraint.activate([
    body.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
    body.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
    body.topAnchor.constraint(equalTo: cell.topAnchor, constant: 8),
    body.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -8),
])
let targetWidth: CGFloat = 200
let fitting = cell.systemLayoutSizeFitting(
    CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
    withHorizontalFittingPriority: .required,
    verticalFittingPriority: .fittingSizeLevel)
line("  宽锁 200（水平 required / 垂直 fittingSizeLevel）→ \(fitting)")
expect(eq(fitting.width, targetWidth), "水平 fitting priority = required → 宽度精确等于 200")
expect(fitting.height > 8 * 2 + 20, "垂直 fitting priority = fittingSizeLevel → 由内容撑出高度（\(fitting.height)）")

// 反过来：水平也只给「尽量小」的意图时，label 会被撑成一行，高度只剩一行
let bothCompressed = cell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
line("  layoutFittingCompressedSize（双向尽量小）→ \(bothCompressed)")
expect(bothCompressed.height < fitting.height, "双向压缩时宽度不受限 → 文本排成一行，高度只剩一行")
let bothExpanded = cell.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize)
line("  layoutFittingExpandedSize（双向撑满）→ \(bothExpanded)")
expect(bothExpanded.height == bothCompressed.height,
       "撑满只是把无约束的方向放到 intrinsic 上限；垂直同受 intrinsic 单行限制 → 高度与压缩版相同")

// 经典用法：自适应行高。先用探针算高，再把结果给 tableView。
let fittingAgain = cell.systemLayoutSizeFitting(
    CGSize(width: targetWidth, height: UIView.layoutFittingCompressedSize.height),
    withHorizontalFittingPriority: .required,
    verticalFittingPriority: .fittingSizeLevel)
line("  同一套约束再算一次 = \(fittingAgain)")
expect(fittingAgain == fitting, "反推是纯函数：同样的约束+宽度必然同样的高度（所以行高可以缓存）")

// estimatedRowHeight 的做法：先给个估值，真实高度等算出来再填
line("  经典写法：cell 高度 = 探针 systemLayoutSizeFitting 的 \(fitting.height)（本例：宽 200 的多行文本）")

// ---------------------------------------------------- 7) UIStackView
line("")
line("-- UIStackView：把一串约束换成一个对象 --")
let host7 = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
let stack = UIStackView()
stack.translatesAutoresizingMaskIntoConstraints = false
stack.axis = .horizontal
stack.spacing = 10
stack.alignment = .center
host7.addSubview(stack)
NSLayoutConstraint.activate([
    stack.leadingAnchor.constraint(equalTo: host7.leadingAnchor),
    stack.trailingAnchor.constraint(equalTo: host7.trailingAnchor),
    stack.topAnchor.constraint(equalTo: host7.topAnchor),
])
let s1 = UIView()
let s2 = UIView()
let s3 = UIView()
for v in [s1, s2, s3] {
    v.translatesAutoresizingMaskIntoConstraints = false
    v.heightAnchor.constraint(equalToConstant: 40).isActive = true
}
s1.widthAnchor.constraint(equalToConstant: 50).isActive = true
s2.widthAnchor.constraint(equalToConstant: 70).isActive = true
s3.widthAnchor.constraint(equalToConstant: 90).isActive = true
stack.addArrangedSubview(s1)
stack.addArrangedSubview(s2)
stack.addArrangedSubview(s3)
line("  arrangedSubviews.count = \(stack.arrangedSubviews.count)   subviews.count = \(stack.subviews.count)")
line("  stack.spacing = \(stack.spacing)   distribution.rawValue = \(stack.distribution.rawValue)（0=fill 1=fillEqually 2=fillProportionally 3=equalSpacing 4=equalCentering）")
line("  三个 UIView 的 contentHugging(水平) = \(s1.contentHuggingPriority(for: .horizontal).rawValue)/\(s2.contentHuggingPriority(for: .horizontal).rawValue)/\(s3.contentHuggingPriority(for: .horizontal).rawValue)")

// .fill：主轴装得下就留白。但这里 stack 被两端 required 钉住宽度 320，而内容只有
// 50+10+70+10+90=230 —— 多出的 90 被塞给了最后一个视图（它的宽度约束与 stack 宽度
// 冲突时，.fill 的分配方式让它吃下剩余空间）。
stack.distribution = .fill
host7.setNeedsLayout()
host7.layoutIfNeeded()
line("  fill（stack 两端钉死）：\(s1.frame.width)/\(s2.frame.width)/\(s3.frame.width)")
expect(eq(s1.frame.width, 50) && eq(s2.frame.width, 70), ".fill：前面的视图保持自己的宽度约束")
expect(eq(s3.frame.width, 180), ".fill：多余空间落到最后一个视图（90+90=180）")

// 让 .fill 真的「留白」：只钉 stack 的起点，宽度交给内容
let fillHost = UIView(frame: CGRect(x: 0, y: 200, width: 320, height: 60))
let looseStack = UIStackView(frame: CGRect(x: 0, y: 0, width: 10, height: 40))
looseStack.axis = .horizontal
looseStack.spacing = 10
looseStack.distribution = .fill
looseStack.translatesAutoresizingMaskIntoConstraints = false
fillHost.addSubview(looseStack)
let l1 = UIView(); let l2 = UIView()
for v in [l1, l2] {
    v.translatesAutoresizingMaskIntoConstraints = false
    v.heightAnchor.constraint(equalToConstant: 40).isActive = true
}
l1.widthAnchor.constraint(equalToConstant: 50).isActive = true
l2.widthAnchor.constraint(equalToConstant: 70).isActive = true
looseStack.addArrangedSubview(l1)
looseStack.addArrangedSubview(l2)
NSLayoutConstraint.activate([
    looseStack.leadingAnchor.constraint(equalTo: fillHost.leadingAnchor),
    looseStack.topAnchor.constraint(equalTo: fillHost.topAnchor),
])
fillHost.setNeedsLayout()
fillHost.layoutIfNeeded()
line("  fill（stack 只钉起点）：stack.frame=\(looseStack.frame)  \(l1.frame.width)/\(l2.frame.width)")
expect(eq(looseStack.frame.width, 50 + 10 + 70), "起点钉住、宽度交给内容 → stack 宽 = 50+10+70 = 130，剩余空间是真的留白")

stack.distribution = .fillEqually
host7.setNeedsLayout()
host7.layoutIfNeeded()
let equally: CGFloat = (320 - 2 * 10) / 3
line("  fillEqually：(320-2*10)/3 = \(equally)，实际 \(s1.frame.width)/\(s2.frame.width)/\(s3.frame.width)")
expect(eq(s1.frame.width, equally) && eq(s3.frame.width, equally), ".fillEqually：等宽，各自的宽度约束被覆盖")

stack.distribution = .equalSpacing
host7.setNeedsLayout()
host7.layoutIfNeeded()
line("  equalSpacing：minX \(s1.frame.minX)/\(s2.frame.minX)/\(s3.frame.minX)，宽 \(s1.frame.width)/\(s2.frame.width)/\(s3.frame.width)")
let gapA = s2.frame.minX - s1.frame.maxX
let gapB = s3.frame.minX - s2.frame.maxX
expect(eq(gapA, gapB), ".equalSpacing：视图宽度不变，段间距相等（\(gapA) == \(gapB)）")
expect(eq(s1.frame.width, 50), ".equalSpacing 不改变宽度")

// 自定义段间距：setCustomSpacing(after:) 只覆盖那一个位置
stack.distribution = .fill
stack.setCustomSpacing(40, after: s1)
host7.setNeedsLayout()
host7.layoutIfNeeded()
let customGap = s2.frame.minX - s1.frame.maxX
let normalGap = s3.frame.minX - s2.frame.maxX
line("  setCustomSpacing(40, after: s1)：s1→s2 = \(customGap)，s2→s3 = \(normalGap)")
expect(eq(customGap, 40), "setCustomSpacing 只影响指定那个位置")
expect(eq(normalGap, 10), "其余位置仍用 stack.spacing")
stack.setCustomSpacing(10, after: s1)

// 隐藏：仍在 arrangedSubviews 里，但不再占布局
s2.isHidden = true
host7.setNeedsLayout()
host7.layoutIfNeeded()
line("  s2.isHidden=true：arrangedSubviews.count=\(stack.arrangedSubviews.count) subviews.count=\(stack.subviews.count) s3.minX=\(s3.frame.minX)")
expect(stack.arrangedSubviews.count == 3, "isHidden 不会把视图从 arrangedSubviews 摘掉")
expect(eq(s3.frame.minX, 60), "隐藏后 s3 前移：s2 既不占宽也不占间距（50+10=60）")
s2.isHidden = false

// removeArrangedSubview vs removeFromSuperview：一个只脱管，一个才真离开
stack.removeArrangedSubview(s3)
host7.setNeedsLayout()
host7.layoutIfNeeded()
line("  removeArrangedSubview(s3)：arrangedSubviews.count=\(stack.arrangedSubviews.count) subviews.count=\(stack.subviews.count)")
expect(stack.arrangedSubviews.count == 2 && stack.subviews.count == 3,
       "removeArrangedSubview 只是不再管它，视图仍在 subviews 里（坑！它不会被移除，还会留在原位绘制）")
s3.removeFromSuperview()
line("  再 removeFromSuperview()：subviews.count=\(stack.subviews.count)")
expect(stack.subviews.count == 2, "要真正移除必须 removeFromSuperview()")

// alignment（交叉轴）：普通 UIView 没有固有尺寸，不给高度约束就会塌成 0
let alignStack = UIStackView(frame: CGRect(x: 0, y: 0, width: 200, height: 120))
alignStack.axis = .horizontal
alignStack.alignment = .center
let tall = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 80))
let short = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 20))
alignStack.addArrangedSubview(tall)
alignStack.addArrangedSubview(short)
alignStack.setNeedsLayout()
alignStack.layoutIfNeeded()
line("  无尺寸约束时：tall.frame=\(tall.frame) short.frame=\(short.frame)")
expect(eq(tall.frame.height, 0) && eq(short.frame.height, 0),
       "普通 UIView 无 intrinsicContentSize、又没给约束 → stack 里高度解为 0（看不见但不算报错）")
let tallH = tall.heightAnchor.constraint(equalToConstant: 80)
let shortH = short.heightAnchor.constraint(equalToConstant: 20)
tallH.isActive = true
shortH.isActive = true
alignStack.setNeedsLayout()
alignStack.layoutIfNeeded()
line("  补上高度约束后：tall.frame=\(tall.frame) short.frame=\(short.frame)")
expect(eq(tall.frame.midY, short.frame.midY), "alignment=.center：交叉轴按中心线对齐（\(tall.frame.midY) == \(short.frame.midY)）")
expect(eq(alignStack.frame.height, 120), "stack 用的是自己 frame 给定的高度（这里由 frame 提供）")

// 交叉轴 .fill 与 .top 的差别
let topStack = UIStackView(frame: CGRect(x: 0, y: 0, width: 200, height: 120))
topStack.axis = .horizontal
topStack.alignment = .top
let tItem = UIView()
topStack.addArrangedSubview(tItem)
tItem.heightAnchor.constraint(equalToConstant: 30).isActive = true
topStack.setNeedsLayout()
topStack.layoutIfNeeded()
line("  alignment=.top：tItem.frame=\(tItem.frame)")
expect(eq(tItem.frame.minY, 0), ".top 把交叉轴贴到 stack 顶边")

// 内边距：默认 arranged subview 的排布**不看** layoutMargins，要显式打开开关
let marginsOffStack = UIStackView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
marginsOffStack.axis = .vertical
marginsOffStack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
let offItem = UIView()
marginsOffStack.addArrangedSubview(offItem)
marginsOffStack.setNeedsLayout()
marginsOffStack.layoutIfNeeded()
line("  isLayoutMarginsRelativeArrangement=false（默认）：offItem.frame = \(offItem.frame)")
expect(eqRect(offItem.frame, 0, 0, 200, 100), "默认即使设了 layoutMargins 也不生效，首个 arranged subview 占满")

let marginsOnStack = UIStackView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
marginsOnStack.axis = .vertical
marginsOnStack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
marginsOnStack.isLayoutMarginsRelativeArrangement = true
let onItem = UIView()
marginsOnStack.addArrangedSubview(onItem)
marginsOnStack.setNeedsLayout()
marginsOnStack.layoutIfNeeded()
line("  isLayoutMarginsRelativeArrangement=true：onItem.frame = \(onItem.frame)")
expect(eqRect(onItem.frame, 16, 12, 168, 76), "打开开关后才让出 16/12 边距（200-32=168 宽，100-24=76 高）")

// .fillProportionally：按固有尺寸的比例分配（UILabel 有固有高度）
let propStack = UIStackView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
propStack.axis = .vertical
propStack.spacing = 0
propStack.distribution = .fillProportionally
let lab1 = UILabel(); lab1.text = "一行"
let lab2 = UILabel(); lab2.text = "一行"
propStack.addArrangedSubview(lab1)
propStack.addArrangedSubview(lab2)
propStack.setNeedsLayout()
propStack.layoutIfNeeded()
line("  fillProportionally：lab1.h=\(lab1.frame.height) lab2.h=\(lab2.frame.height)")
expect(eq(lab1.frame.height + lab2.frame.height, 100), "两个固有高度相同的 label 按比例分完 100 高")
lab2.text = "一行文字更长一些所以固有宽度更大但高度一样"
propStack.setNeedsLayout()
propStack.layoutIfNeeded()
line("  改文本后：lab1.h=\(lab1.frame.height) lab2.h=\(lab2.frame.height)")
expect(eq(lab1.frame.height, lab2.frame.height), "高度仍相等：固有**高度**没变，比例自然没变")

// ---------------------------------------------------- 8) 布局时机与各种 guide
line("")
line("-- 布局时机：layoutIfNeeded 真的跑了几轮；三种 guide --")

// Swift 里没有公开的 `needsLayout` 属性（ObjC 的 _needsLayout 是私有 API），
// 想知道「这一轮到底布局了没有」，可靠的办法是自己数 layoutSubviews 的次数。
final class LayoutCountingView: UIView {
    var passCount = 0
    override func layoutSubviews() {
        super.layoutSubviews()
        passCount += 1
    }
}

let host8 = LayoutCountingView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
let v8 = UIView()
v8.translatesAutoresizingMaskIntoConstraints = false
host8.addSubview(v8)
NSLayoutConstraint.activate([
    v8.leadingAnchor.constraint(equalTo: host8.layoutMarginsGuide.leadingAnchor),
    v8.topAnchor.constraint(equalTo: host8.layoutMarginsGuide.topAnchor),
    v8.widthAnchor.constraint(equalToConstant: 44),
    v8.heightAnchor.constraint(equalToConstant: 44),
])
line("  host8.layoutMargins = \(host8.layoutMargins)")
line("  约束刚 activate、还没布局：v8.frame = \(v8.frame)，passCount=\(host8.passCount)")
let p0 = host8.passCount
host8.layoutIfNeeded()
let p1 = host8.passCount
line("  第一次 layoutIfNeeded()：v8.frame = \(v8.frame)，passCount \(p0) → \(p1)")
host8.layoutIfNeeded()
let p2 = host8.passCount
line("  紧接着再来一次（中间没改任何东西）：passCount \(p1) → \(p2)")
host8.setNeedsLayout()
host8.layoutIfNeeded()
let p3 = host8.passCount
line("  setNeedsLayout() + layoutIfNeeded()：passCount \(p2) → \(p3)")
expect(p1 > p0, "activate 之后 layoutIfNeeded 真的跑了一轮布局（\(p0)→\(p1)）")
expect(p2 == p1, "没有脏标记时 layoutIfNeeded 不会重复布局（\(p1)→\(p2)）")
expect(p3 > p2, "setNeedsLayout 标脏之后才会再走一轮（\(p2)→\(p3)）")
expect(eq(v8.frame.minX, host8.layoutMargins.left),
       "锚到 layoutMarginsGuide 时位置由 layoutMargins 决定（\(v8.frame.minX)）")

host8.layoutMargins = UIEdgeInsets(top: 24, left: 32, bottom: 24, right: 32)
host8.setNeedsLayout()
host8.layoutIfNeeded()
line("  把 layoutMargins 改成 (24,32,24,32) 后 v8.frame = \(v8.frame)")
expect(eqRect(v8.frame, 32, 24, 44, 44), "layoutMargins 变 → layoutMarginsGuide 跟着变，子视图位置随之挪动")

// readableContentGuide：正文字宽在 iPad/横屏上会收窄；裸 UIView 上它贴着 layoutMargins
let readHost = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
let readLabel = UIView()
readLabel.translatesAutoresizingMaskIntoConstraints = false
readHost.addSubview(readLabel)
NSLayoutConstraint.activate([
    readLabel.leadingAnchor.constraint(equalTo: readHost.readableContentGuide.leadingAnchor),
    readLabel.trailingAnchor.constraint(equalTo: readHost.readableContentGuide.trailingAnchor),
    readLabel.topAnchor.constraint(equalTo: readHost.topAnchor),
    readLabel.heightAnchor.constraint(equalToConstant: 20),
])
line("  readHost.layoutMargins = \(readHost.layoutMargins)")
readHost.setNeedsLayout()
readHost.layoutIfNeeded()
line("  锚到 readableContentGuide：readLabel.frame = \(readLabel.frame)")
expect(readLabel.frame.minX >= 0 && readLabel.frame.maxX <= readHost.bounds.width,
       "iPhone 竖屏下 readableContentGuide 基本等于整宽（iPad 上才会明显收窄）")

// safeAreaLayoutGuide 与 layoutMarginsGuide 是两个不同的 guide（第 14 章讲过安全区）
let guideHost = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
let g1 = UIView(); let g2 = UIView()
for v in [g1, g2] { v.translatesAutoresizingMaskIntoConstraints = false }
guideHost.addSubview(g1)
guideHost.addSubview(g2)
NSLayoutConstraint.activate([
    g1.leadingAnchor.constraint(equalTo: guideHost.safeAreaLayoutGuide.leadingAnchor),
    g1.topAnchor.constraint(equalTo: guideHost.safeAreaLayoutGuide.topAnchor),
    g1.widthAnchor.constraint(equalToConstant: 30),
    g1.heightAnchor.constraint(equalToConstant: 30),
    g2.leadingAnchor.constraint(equalTo: guideHost.layoutMarginsGuide.leadingAnchor),
    g2.topAnchor.constraint(equalTo: guideHost.layoutMarginsGuide.topAnchor),
    g2.widthAnchor.constraint(equalToConstant: 30),
    g2.heightAnchor.constraint(equalToConstant: 30),
])
guideHost.setNeedsLayout()
guideHost.layoutIfNeeded()
line("  未挂窗口时：safeArea 锚点解出 g1.frame=\(g1.frame)   layoutMargins 锚点解出 g2.frame=\(g2.frame)")
expect(eqRect(g1.frame, 0, 0, 30, 30), "safeAreaInsets 与 layoutMargins 都为 0/未知时，safeArea 锚点从 (0,0) 起")
expect(eqRect(g2.frame, 8, 8, 30, 30), "layoutMarginsGuide 从 layoutMargins(8) 起，两者不是一回事")

// ---------------------------------------------------- 9) 心智模型
line("")
line("-- 心智模型 --")
line("  autoresizingMask 描述「哪条边/哪个尺寸是弹性的」；只有六个 flexible* case，固定用 []")
line("  translatesAutoresizingMaskIntoConstraints=true 时 frame 自己变约束；stack 会替你关掉")
line("  VFL 一次生成一串约束，只能表达线性关系；括号里要写 (==metric)，光写名字不生效")
line("  冲突靠 priority 裁决：hugging 抗变大、contentCompressionResistance 抗变小")
line("  systemLayoutSizeFitting 反向求解：锁死一边，问另一边该多大（自适应行高的根）")
line("  UIStackView = 一组约束的封装：distribution 管主轴分配，alignment 管交叉轴，")
line("    内边距要额外打开 isLayoutMarginsRelativeArrangement")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 21 结束 ====")
exit(failures == 0 ? 0 : 1)
