// ============================================================
// 01 - iOS 工具链与运行环境（Swift）
//
// 这是全教程第一个可运行示例。它不画任何界面，只做三件事：
//   1) 证明「命令行 swiftc + iphonesimulator SDK + 模拟器」这条链路是通的；
//   2) 演示 iOS 开发里两个最容易混淆的概念：**部署目标**（编译期）与
//      **#available**（运行期）；
//   3) 顺手确认 Foundation / UIKit / SwiftUI 三层都能 import 并构造对象。
//
// 编译（本教程统一由 run-all.sh 代劳，这里只是让你能手动复现）：
//   SDK=$(xcrun --sdk iphonesimulator --show-sdk-path)
//   SDKROOT=$SDK swiftc -sdk $SDK -target $(uname -m)-apple-ios15.0-simulator \
//       main.swift -o 01 -framework Foundation -framework UIKit -framework SwiftUI
// 运行（模拟器里跑，不是直接 ./01）：
//   xcrun simctl boot <UDID>          # 先启动一台 iPhone 模拟器
//   xcrun simctl spawn <UDID> ./01 --selftest
//
// 约定：本教程所有示例都只**断言性质**（true/false、ok/FAIL），
// 不打印「iOS 18.3.1」这类随机器变化的原始数字 —— 那样文档里的输出快照
// 换台机器就对不上了。真实版本号写在 README 的「机器事实」表里。
// ============================================================

import Foundation
import UIKit
import SwiftUI

// ---- 极简断言框架：失败就累加，最后据此决定退出码 ------------------
var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }

// --selftest 是本教程统一的「headless 自测」开关：不建窗口、不进 UI 事件循环，
// 只跑断言然后退出。run-all.sh 每次都会带上它。
let selfTest = CommandLine.arguments.contains("--selftest")

line("== 01 工具链与运行环境 ==")
line("  --selftest 传入 : \(selfTest)")
expect(selfTest, "命令行能读到 --selftest（说明 argv 传递正常）")

// ------------------------------------------------- 1) 我们在哪种环境里跑
// targetEnvironment(simulator) 是**编译期**判断：为 iphonesimulator 编译时恒为真。
// 它和「运行期这台设备是不是模拟器」是两回事，但本教程只在模拟器里跑，两者一致。
#if targetEnvironment(simulator)
let compiledForSimulator = true
#else
let compiledForSimulator = false
#endif
line("")
line("== 编译目标 ==")
expect(compiledForSimulator, "targetEnvironment(simulator) 为真（为模拟器编译）")

// 运行期问 UIDevice：它报告的是「当前这台（模拟）设备」的属性。
let idiom = UIDevice.current.userInterfaceIdiom
line("  userInterfaceIdiom == .phone : \(idiom == .phone)")
expect(idiom == .phone || idiom == .pad, "运行在 iPhone/iPad 形态上（模拟器）")

// ------------------------------------------------- 2) 部署目标 vs #available
// 这是 iOS 开发最核心、也最常被讲错的一对概念，务必分清：
//
//   部署目标 (deployment target = iOS 15.0)
//     —— **编译期**契约。它告诉编译器「我最低支持到 iOS 15」，
//        于是 iOS 15 及更早的 API 可以**无条件**直接调用。
//        它**不**在运行时做任何检查，也不会阻止你链接更高版本的 API。
//
//   if #available(iOS 16, *)
//     —— **运行期**检查。它问的是「当前这台设备的系统**实际**是不是 ≥ 16」，
//        与部署目标、与用哪个 SDK 编译，全都无关。
//        只有它返回真，你才能安全调用 iOS 16 才有的 API。
//
// 换句话说：部署目标决定「最低能装到哪」，#available 决定「此刻能不能用新 API」。
line("")
line("== 部署目标 vs 运行期 #available ==")

// 本机模拟器运行时是 iOS 18.x，所以下面这些运行期检查都该命中。
var hit16 = false
if #available(iOS 16, *) { hit16 = true }
line("  if #available(iOS 16,*) 命中 : \(hit16)")
expect(hit16, "运行期系统 ≥ iOS 16（本机模拟器满足）")

// 反过来，一个远未来的版本号一定不命中 —— 证明 #available 真的在做门控，
// 而不是「反正编过了就永远为真」。
var hit99 = false
if #available(iOS 99, *) { hit99 = true }
line("  if #available(iOS 99,*) 命中 : \(hit99)")
expect(!hit99, "远未来版本不命中（说明 #available 是真实的运行期门控）")

// 部署目标是 15.0，意味着 iOS 15 的 API 可以直接写、不用守卫。
// 这里用一个 iOS 15 才引入的 API 举例：UIButton.Configuration。
var config = UIButton.Configuration.filled()
config.title = "确定"
let button = UIButton(configuration: config)
line("  iOS 15 API 可直接调用（无 #available）: \(button.configuration?.title == "确定")")
expect(button.configuration?.title == "确定", "iOS 15+ 的 UIButton.Configuration 无需守卫即可用")

// ------------------------------------------------- 3) 三层框架都能构造对象
line("")
line("== Foundation / UIKit / SwiftUI 可达性 ==")

// Foundation：跑一个最小的 JSON 往返，确认不是只 import 成功、而是真能干活。
let payload: [String: Any] = ["name": "iOS", "version": 18]
let data = try? JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
let back = data.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]
expect(back?["name"] as? String == "iOS", "Foundation：JSON 往返正常")

// UIKit：构造一个 UILabel 和一个 UIViewController，跑通「加载视图」这一步。
// 全程 headless —— 不 addSubview 到窗口、不 makeKeyAndVisible。
let label = UILabel()
label.text = "Hello iOS"
label.sizeToFit()
expect(label.text == "Hello iOS", "UIKit：UILabel 可构造并持有文本")
expect(label.frame.width >= 0, "UIKit：sizeToFit 之后 frame 合法")

let vc = UIViewController()
vc.loadViewIfNeeded()          // 触发 loadView，创建 vc.view
expect(vc.view != nil, "UIKit：UIViewController.loadViewIfNeeded 后 view 非空")

// SwiftUI：定义一个最小 View，求值它的 body（只构造视图树，不渲染）。
struct Badge: View {
    let count: Int
    var body: some View { Text("badge-\(count)") }
}
let badge = Badge(count: 7)
let bodyTypeName = String(describing: type(of: badge.body))
line("  SwiftUI：Badge.body 的具体类型含 \"Text\" : \(bodyTypeName.contains("Text"))")
expect(bodyTypeName.contains("Text"), "SwiftUI：自定义 View 的 body 可求值，底层是 Text")

// ------------------------------------------------- 收尾
line("")
if failures == 0 {
    line("全部断言通过。")
} else {
    line("有 \(failures) 条断言失败。")
}
print("==== 01 结束 ====")
exit(failures == 0 ? 0 : 1)
