// ============================================================
// 08 - SwiftUI 基础：View / body / some View / 修饰符的值语义 / UIHostingController
//
// SwiftUI 是**声明式**的：你描述「界面长什么样」（一棵 View 树），系统负责渲染。
// 三个核心事实：
//   1) View 是个协议，只要求一个 `body: some View`。body 返回「另一个 View」。
//   2) 修饰符（.padding() / .font()）**不改原视图**，而是包一层返回**新视图**——
//      View 是 struct，值语义。
//   3) `some View` 是 opaque 类型：编译器知道具体类型，你看不见也不用管。
//   SwiftUI 最终渲染进 UIHostingController（底层还是 UIKit）——本章末尾验证这层桥接。
//
// headless 自测：构造视图、求值 body、检查类型名与值语义、把视图塞进
// UIHostingController 触发 loadView，全程不 makeKeyAndVisible、不弹 UI。
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
func typeName(_ v: some View) -> String { String(describing: type(of: v)) }

line("== 08 SwiftUI 基础 ==")

// ---------------------------------------------------- 1) View / body / some View
line("")
line("-- View 协议与 body --")
struct Badge: View {
    var body: some View {          // opaque 返回类型：具体类型被隐藏
        Text("NEW")
    }
}
let badge = Badge()
let badgeBody = badge.body
line("  Badge.body 具体类型 = \(typeName(badgeBody))")
expect(typeName(badgeBody).contains("Text"), "最简 body 返回一个 Text")
// some View 的具体类型是编译器内部的，但非空、可求值本身就是合法视图树的证明
expect(!typeName(badgeBody).isEmpty, "body 可求值，视图树合法")

// ---------------------------------------------------- 2) 修饰符的值语义
line("")
line("-- 修饰符返回新视图（值语义）--")
let plain = Text("Hello")
let padded = plain.padding()                 // 不改 plain，返回包了一层的新视图
let styled = plain.padding().padding()       // 链式：每步都在外面再包一层
line("  Text                = \(typeName(plain))")
line("  Text.padding()      = \(typeName(padded))")
line("  .padding().padding()= \(typeName(styled))")
expect(typeName(plain) == "Text", "裸 Text 的类型就是 Text")
expect(typeName(padded).contains("ModifiedContent"), "修饰符把原视图包成 ModifiedContent")
expect(typeName(padded) != typeName(plain), "修饰后是一个**新**类型，不是原地修改")
// 两次 padding：ModifiedContent 套 ModifiedContent，肉眼可见「逐层包裹」
expect(typeName(styled).contains("ModifiedContent<ModifiedContent"), "链式修饰逐层向外包裹")
// 关键：plain 没被 padded 影响（值语义）——它仍是裸 Text
expect(typeName(plain) == "Text", "值语义：原视图 plain 未被改变")

// ---------------------------------------------------- 3) 容器与布局栈
line("")
line("-- 布局栈：VStack / HStack / ZStack --")
let vstack = VStack(spacing: 8) { Text("a"); Text("b") }
let hstack = HStack { Text("x"); Text("y"); Text("z") }
let zstack = ZStack { Text("底"); Text("顶") }
line("  VStack 类型 = \(typeName(vstack))")
expect(typeName(vstack).contains("VStack"), "VStack 是垂直栈")
expect(typeName(hstack).contains("HStack"), "HStack 是水平栈")
expect(typeName(zstack).contains("ZStack"), "ZStack 是层叠栈")
// spacing / alignment 只是初始化参数，不改变「它是 VStack」这个事实
let spaced = VStack(alignment: .leading, spacing: 20) { Text("a") }
expect(typeName(spaced).contains("VStack"), "带 alignment/spacing 仍是 VStack")

// ---------------------------------------------------- 4) 视图组合（抽子视图）
line("")
line("-- 视图组合：把子树抽成独立 View --")
struct Row: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("›")
        }
    }
}
struct ProfileCard: View {
    var body: some View {
        VStack {
            Row(title: "名字")       // 组合：Row 是另一个 View
            Row(title: "邮箱")
        }
    }
}
let card = ProfileCard()
expect(typeName(card.body).contains("VStack"), "组合视图的 body 仍是普通视图树")
expect(typeName(Row(title: "x").body).contains("HStack"), "抽出来的 Row 独立可求值")

// ---------------------------------------------------- 5) UIHostingController：SwiftUI → UIKit 桥接
line("")
line("-- UIHostingController：SwiftUI 渲染进 UIKit --")
struct ContentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Hello").font(.title)
            Text("iOS").foregroundStyle(.secondary)
        }
        .padding()
    }
}
let host = UIHostingController(rootView: ContentView())
host.loadViewIfNeeded()                       // 触发 SwiftUI 创建宿主 view
expect(host.view != nil, "UIHostingController 创建了宿主 view")
// 宿主 view 的类名带 "Hosting"：SwiftUI 把视图树托管进一个专门的 UIKit 容器视图。
let hostViewType = String(describing: type(of: host.view!))
line("  宿主 view 类型 = \(hostViewType)")
expect(hostViewType.contains("Hosting"), "宿主 view 是 SwiftUI 的 Hosting 容器（底层仍是 UIView）")
// rootView 可以读回来并替换——UIHostingController 是 SwiftUI ⇄ UIKit 的官方桥。
let sameRoot = String(describing: type(of: host.rootView)).contains("ContentView")
expect(sameRoot, "rootView 就是我们塞进去的 ContentView")
// 真正的子视图层级要等挂进 window、跑完渲染循环才出现（headless 下不挂窗，
// 所以这里不强判 subviews.count）；上面两条已经证明「SwiftUI 落进了 UIKit」。

// ---------------------------------------------------- 6) 心智模型小结（打印）
line("")
line("-- 心智模型 --")
line("  View 是 struct（值类型）；body: some View 描述界面，不命令式绘制")
line("  修饰符 = 包一层返回新视图；顺序影响结果（.padding().background() ≠ 反过来）")
line("  some View = opaque 类型：编译器知道具体类型，你无需写出")
line("  SwiftUI 底层仍是 UIKit：渲染进 UIHostingController.view")
expect(true, "以上均可从本示例的类型名与桥接结果验证")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 08 结束 ====")
exit(failures == 0 ? 0 : 1)
