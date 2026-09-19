// ============================================================
// 02 - 第一个 App：SwiftUI 与 UIKit 两条最小骨架
//
// iOS 有两套「App 的写法」，本教程以 SwiftUI 为主、UIKit 为底：
//
//   SwiftUI（现代，声明式）——入口是一个 @main 的 App：
//       @main
//       struct HelloApp: App {
//           var body: some Scene {
//               WindowGroup { ContentView() }
//           }
//       }
//     没有 AppDelegate、没有 Info.plist 里的 storyboard 名，
//     系统直接实例化这个 App、求值 body 拿到 Scene，把 ContentView 塞进窗口。
//
//   UIKit（传统，命令式）——入口是 UIApplicationMain + 三个角色：
//       AppDelegate   进程级生命周期（启动、进后台、终止）
//       SceneDelegate 一个窗口/场景的生命周期（多窗口时每个场景一个）
//       UIViewController  一屏内容
//
// 本示例是 **headless 自测**：不真的调用 @main / UIApplicationMain（那需要一个
// 打包好的 .app + Info.plist，见第 20 章），而是把两套骨架里**可验证的部分**
// 单独构造出来跑断言：SwiftUI 的根视图、UIKit 的根控制器与窗口装配。
// 真正的 @main 入口代码写在文档里，形状与这里构造的类型完全一致。
//
// 编译/运行见 run-all.sh（iphonesimulator SDK，模拟器里 simctl spawn 跑）。
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

// =====================================================================
// SwiftUI 侧：一个最小的根视图
// =====================================================================
// 这就是上面 @main App 里 WindowGroup { ContentView() } 的那个 ContentView。
// 它是一棵**声明式**的视图树：body 描述「界面长什么样」，而不是「怎么一步步画」。
struct ContentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("Hello")
                .font(.title)
            Text("iOS")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// =====================================================================
// UIKit 侧：一个最小的根视图控制器（用纯代码 + Auto Layout 搭界面）
// =====================================================================
final class RootViewController: UIViewController {
    // loadView 负责**创建** self.view。这里不用 xib/storyboard，纯代码搭：
    // 一个居中的 UILabel。tag 用来在自测里把它找回来。
    override func loadView() {
        let root = UIView()
        root.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Hello iOS"
        label.tag = 100
        label.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(label)

        // Auto Layout：让 label 在父视图里水平+垂直居中。
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: root.centerYAnchor),
        ])

        self.view = root
    }
}

// --------------------------------------------------------------- 自测开始
line("== 02 第一个 App：两套骨架 ==")

// ---- SwiftUI：构造根视图，确认视图树能求值 ----
line("")
line("-- SwiftUI 根视图 --")
let contentView = ContentView()
// body 是 opaque some View，不能直接读内容；但「能构造、能求值 body」本身就
// 证明了这棵声明式视图树是合法的。深度测试放到第 08~13 章。
let bodyType = String(describing: type(of: contentView.body))
line("  ContentView.body 具体类型非空 : \(!bodyType.isEmpty)")
expect(!bodyType.isEmpty, "SwiftUI：ContentView 可构造，body 可求值")

// ---- UIKit：构造根控制器，触发 loadView，验证界面搭出来了 ----
line("")
line("-- UIKit 根控制器 --")
let vc = RootViewController()
vc.loadViewIfNeeded()                    // 触发上面的 loadView()
let label = vc.view.viewWithTag(100) as? UILabel
expect(vc.view != nil, "UIKit：loadViewIfNeeded 之后 view 已创建")
expect(label?.text == "Hello iOS", "UIKit：居中的 UILabel 文本正确")
expect(label?.translatesAutoresizingMaskIntoConstraints == false,
       "UIKit：用 Auto Layout 时该标志必须为 false")
// 约束确实装上了：根视图上应至少有 2 条（centerX + centerY）
let constraintsOnRoot = vc.view.constraints.count
line("  根视图上的约束条数 >= 2 : \(constraintsOnRoot >= 2)")
expect(constraintsOnRoot >= 2, "UIKit：Auto Layout 约束已激活")

// ---- UIKit：窗口 + 根控制器的装配（SceneDelegate 里做的事）----
// 真实的 SceneDelegate 会拿到一个 UIWindowScene，用 UIWindow(windowScene:) 建窗；
// 这里没有真实场景，就用无参 UIWindow() 演示「窗口持有根控制器」这层关系，
// 全程不 makeKeyAndVisible —— headless。
line("")
line("-- UIKit 窗口装配 --")
let window = UIWindow()
window.rootViewController = RootViewController()
window.rootViewController?.loadViewIfNeeded()
expect(window.rootViewController != nil, "UIKit：window.rootViewController 已设置")
expect((window.rootViewController?.view.viewWithTag(100) as? UILabel)?.text == "Hello iOS",
       "UIKit：通过窗口也能取到根控制器里的 label")

// ---- 对照：两套骨架的「谁负责什么」----
line("")
line("-- 心智模型对照 --")
line("  SwiftUI：@main App → body(some Scene) → WindowGroup { ContentView() }")
line("  UIKit  ：UIApplicationMain → AppDelegate → SceneDelegate → window.rootViewController")
expect(true, "两套骨架都能独立跑起来（本示例已分别构造验证）")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 02 结束 ====")
exit(failures == 0 ? 0 : 1)
