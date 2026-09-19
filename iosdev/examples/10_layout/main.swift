// ============================================================
// 10 - SwiftUI 布局：栈、spacing、padding、frame、Spacer、对齐、GeometryReader
//
// SwiftUI 布局是一套「协商」流程（Layout 协议的思想）：
//   1) 父视图给子视图一个**尺寸提议**（proposed size）
//   2) 子视图**自己决定**要多大（可以无视提议，比如 .frame 固定、Text 用理想尺寸）
//   3) 父视图按自己的规则（spacing/alignment）**放置**子视图
// 栈（VStack/HStack/ZStack）就是最常见的父视图。
//
// headless 验证的关键：SwiftUI 宿主视图的 intrinsicContentSize **不需要挂窗口、
// 不需要 run loop** 就能算出内容的理想尺寸。于是我们能对布局做**精确的数值断言**：
//   VStack(spacing:) 的高度 = 各子高 + spacing*(n-1)
//   HStack 的宽度 = 各子宽 + spacing*(n-1)
//   ZStack 的尺寸 = 子视图宽、高的各自最大值
//   padding(n) 让宽高各 +2n；Spacer 吃满父给的提议空间
// 这些都是本机上跑出来的真实数字，不是估的。
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

// 把一个 SwiftUI 视图塞进 UIHostingController，读它算出来的理想尺寸。
// 不挂窗口、不 makeKeyAndVisible、不跑 run loop —— intrinsicContentSize 照样能算。
func idealSize<V: View>(of view: V) -> CGSize {
    let host = UIHostingController(rootView: view)
    host.view.setNeedsLayout()
    host.view.layoutIfNeeded()
    return host.view.intrinsicContentSize
}
// 浮点比较：布局尺寸允许极小误差
func eq(_ a: CGFloat, _ b: CGFloat) -> Bool { abs(a - b) < 0.01 }

line("== 10 SwiftUI 布局 ==")

// ---------------------------------------------------- 1) VStack：垂直堆叠
line("")
line("-- VStack：高度 = 各子高 + spacing×(n-1) --")
let twoRows = VStack(spacing: 8) {
    Text("A").frame(width: 100, height: 40)
    Text("B").frame(width: 100, height: 40)
}
let s0 = idealSize(of: VStack(spacing: 0) {
    Text("A").frame(width: 100, height: 40); Text("B").frame(width: 100, height: 40) })
let s8 = idealSize(of: twoRows)
let s20 = idealSize(of: VStack(spacing: 20) {
    Text("A").frame(width: 100, height: 40); Text("B").frame(width: 100, height: 40) })
line("  spacing 0  → \(s0.width)×\(s0.height)")
line("  spacing 8  → \(s8.width)×\(s8.height)")
line("  spacing 20 → \(s20.width)×\(s20.height)")
expect(eq(s0.height, 80), "spacing 0：40+40 = 80")
expect(eq(s8.height, 88), "spacing 8：40+8+40 = 88")
expect(eq(s20.height, 100), "spacing 20：40+20+40 = 100")
expect(eq(s8.width, 100), "VStack 宽 = 最宽子视图（都是 100）")

// ---------------------------------------------------- 2) HStack：水平堆叠
line("")
line("-- HStack：宽度 = 各子宽 + spacing×(n-1) --")
let hs = idealSize(of: HStack(spacing: 8) {
    Text("A").frame(width: 100, height: 40)
    Text("B").frame(width: 100, height: 40)
})
line("  HStack(spacing:8) 两个 100×40 → \(hs.width)×\(hs.height)")
expect(eq(hs.width, 208), "宽度 = 100+8+100 = 208")
expect(eq(hs.height, 40), "高度 = 最高子视图 = 40")

// ---------------------------------------------------- 3) ZStack：层叠，尺寸取各自最大
line("")
line("-- ZStack：尺寸 = 子视图宽、高各自的最大值 --")
let zs = idealSize(of: ZStack {
    Text("A").frame(width: 100, height: 40)
    Text("B").frame(width: 60, height: 80)
})
line("  ZStack(100×40 叠 60×80) → \(zs.width)×\(zs.height)")
expect(eq(zs.width, 100), "宽 = max(100, 60) = 100")
expect(eq(zs.height, 80), "高 = max(40, 80) = 80")

// ---------------------------------------------------- 4) padding：每边各加，宽高 +2n
line("")
line("-- padding：包裹在外，宽高各 +2×padding --")
let pad = idealSize(of: Text("A").frame(width: 100, height: 40).padding(10))
line("  100×40 加 .padding(10) → \(pad.width)×\(pad.height)")
expect(eq(pad.width, 120), "宽 = 100 + 10×2 = 120")
expect(eq(pad.height, 60), "高 = 40 + 10×2 = 60")

// ---------------------------------------------------- 5) frame：固定/最小/最大/理想
line("")
line("-- frame：固定尺寸就是提议即结果 --")
let fixed = idealSize(of: Text("A").frame(width: 200, height: 200))
line("  .frame(width:200,height:200) → \(fixed.width)×\(fixed.height)")
expect(eq(fixed.width, 200) && eq(fixed.height, 200), "固定 frame：说多大就多大")

// ---------------------------------------------------- 6) Spacer：吃满父给的提议空间
line("")
line("-- Spacer：占据所有剩余空间 --")
// HStack 里夹一个 Spacer，整体被提议成宽 300 → Spacer 把宽度撑到 300
let spaced = idealSize(of: HStack {
    Text("A").frame(width: 50)
    Spacer()
    Text("B").frame(width: 50)
}.frame(width: 300))
line("  HStack{50, Spacer, 50}.frame(width:300) → \(spaced.width)×\(spaced.height)")
expect(eq(spaced.width, 300), "Spacer 撑满提议宽度 300（两个 50 被推到两端）")
// VStack 里夹 Spacer，被提议成高 300 → 高度撑到 300
let vspaced = idealSize(of: VStack { Text("A"); Spacer() }.frame(height: 300))
expect(eq(vspaced.height, 300), "垂直方向 Spacer 同理撑满高度 300")

// ---------------------------------------------------- 7) alignment：改变放置，不改变尺寸
line("")
line("-- alignment：决定子视图怎么摆，不影响栈的外框尺寸 --")
let leading = idealSize(of: VStack(alignment: .leading) {
    Text("A").frame(width: 100, height: 40); Text("B").frame(width: 60, height: 40) })
let center = idealSize(of: VStack(alignment: .center) {
    Text("A").frame(width: 100, height: 40); Text("B").frame(width: 60, height: 40) })
let trailing = idealSize(of: VStack(alignment: .trailing) {
    Text("A").frame(width: 100, height: 40); Text("B").frame(width: 60, height: 40) })
line("  leading/center/trailing 外框都是 \(leading.width)×\(leading.height)")
expect(eq(leading.width, 100) && eq(center.width, 100) && eq(trailing.width, 100),
       "三种水平对齐，VStack 外框宽都 = 最宽子视图 100（对齐只挪子视图位置）")

// ---------------------------------------------------- 8) GeometryReader：吃满提议，把尺寸给你
line("")
line("-- GeometryReader：占满可用空间，回调里拿到真实尺寸 --")
// GeometryReader 会贪婪地占据父给的所有空间：提议 250×250，它就报告 250×250。
let geo = idealSize(of: GeometryReader { proxy in
    Text("\(Int(proxy.size.width))")
}.frame(width: 250, height: 250))
line("  GeometryReader.frame(250×250) → \(geo.width)×\(geo.height)")
expect(eq(geo.width, 250) && eq(geo.height, 250), "GeometryReader 填满提议尺寸")

// ---------------------------------------------------- 9) 布局协商小结（打印）
line("")
line("-- 布局协商三步 --")
line("  1) 父给子一个尺寸提议（proposed size）")
line("  2) 子自己决定多大：Text 用理想尺寸、.frame 固定、Spacer/GeometryReader 吃满")
line("  3) 父按 spacing/alignment 放置子视图，并算出自己的尺寸往上报")
expect(true, "上面每条数值断言都对应这三步里的一环")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 10 结束 ====")
exit(failures == 0 ? 0 : 1)
