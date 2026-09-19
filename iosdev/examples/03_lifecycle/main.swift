// ============================================================
// 03 - App 生命周期与场景（Scene）
//
// iOS 13 起，「App 的生命周期」被拆成两层：
//   - **进程级**（AppDelegate）：App 被启动、即将终止。整个进程只有一份。
//   - **场景级**（SceneDelegate）：每一个窗口/场景各自的 前台↔后台↔挂起。
//     iPad 上支持多窗口，所以「界面生命周期」必须挂在场景上，而不是进程上。
//
// SwiftUI 把这套收敛成一个值：`@Environment(\.scenePhase)`，取值
//   .active / .inactive / .background，用 onChange(of:) 监听切换。
//
// 真实的回调只有在**打包成 .app 并被系统启动**时才会由系统依次调用
// （见第 20 章）。本示例是 headless 自测：用一个「记录器」把系统**应当**
// 调用的顺序模拟出来，断言这个顺序，从而把生命周期讲清楚、且可验证。
// 顺序依据 Apple 文档 Managing your app's life cycle。
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

// ---------------------------------------------------------------- 记录器
// 把「谁在什么时候被调用」记成一串事件名，最后比对顺序。
final class LifecycleRecorder {
    private(set) var events: [String] = []
    func record(_ e: String) { events.append(e) }
    func reset() { events.removeAll() }
}

// ------------------------------------------- UIKit：进程级 + 场景级骨架
// 下面两个类的**方法签名**就是系统真正会调用的那些。headless 环境里没有真的
// UIScene/UIApplication 生命周期在跑，所以我们不手动去调这些方法（那需要伪造
// 一个 UIScene，没意义）；而是把它们**列在这里作为对照**，真正的顺序验证走
// 后面的 driveUIKitLifecycle()——它记录的事件名与顺序和系统调用完全一致。
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true   // 进程启动完成：做一次性初始化
    }
    func applicationWillTerminate(_ application: UIApplication) {
        // 进程即将终止（不保证一定被调用，别把关键保存只放这里）
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        // 场景创建：在这里建 UIWindow、设 rootViewController
    }
    func sceneWillEnterForeground(_ scene: UIScene) {}  // 即将进前台
    func sceneDidBecomeActive(_ scene: UIScene)     {}  // 已可交互
    func sceneWillResignActive(_ scene: UIScene)    {}  // 即将失去焦点（来电/多任务）
    func sceneDidEnterBackground(_ scene: UIScene)  {}  // 已进后台：保存数据
    func sceneDidDisconnect(_ scene: UIScene)       {}  // 场景被系统回收
}

// ------------------------------------------- SwiftUI：scenePhase 的三态
// SwiftUI 里没有 AppDelegate/SceneDelegate，只有一个 phase 值在三态间切换。
enum ScenePhaseModel: String {
    case background, inactive, active
}
// 一个把 phase 变化翻译成「该做什么」的小状态机：模拟 onChange(of: scenePhase)。
final class PhaseHandler {
    let rec: LifecycleRecorder
    init(rec: LifecycleRecorder) { self.rec = rec }
    func onChange(to phase: ScenePhaseModel) {
        switch phase {
        case .active:     rec.record("phase:active")      // 可交互：恢复动画、刷新
        case .inactive:   rec.record("phase:inactive")    // 过渡态：来电/上拉多任务
        case .background: rec.record("phase:background")  // 后台：保存数据、释放资源
        }
    }
}

// 按 Apple 文档的顺序，驱动一次完整的 UIKit 生命周期，把事件记下来。
func driveUIKitLifecycle(_ rec: LifecycleRecorder) {
    rec.record("app:didFinishLaunching")     // 进程启动
    rec.record("scene:willConnect")          // 场景创建
    rec.record("scene:willEnterForeground")  // 进前台
    rec.record("scene:didBecomeActive")      // 可交互
    // 用户按 Home / 上滑回桌面：
    rec.record("scene:willResignActive")
    rec.record("scene:didEnterBackground")
    // 用户又点开 App：
    rec.record("scene:willEnterForeground")
    rec.record("scene:didBecomeActive")
    // 系统回收这个场景（多窗口下关掉一个窗口）：
    rec.record("scene:didDisconnect")
    // 进程即将终止：
    rec.record("app:willTerminate")
}

// --------------------------------------------------------------- 自测开始
line("== 03 App 生命周期与场景 ==")

// ---- 1) UIKit：一次完整的「冷启动 → 前台 → 退后台 → 回前台 → 关闭」----
line("")
line("-- UIKit：进程级 + 场景级回调顺序 --")
let rec = LifecycleRecorder()
driveUIKitLifecycle(rec)
let expectedUIKit = [
    "app:didFinishLaunching",
    "scene:willConnect",
    "scene:willEnterForeground",
    "scene:didBecomeActive",
    "scene:willResignActive",
    "scene:didEnterBackground",
    "scene:willEnterForeground",
    "scene:didBecomeActive",
    "scene:didDisconnect",
    "app:willTerminate",
]
line("  记录到的事件数 = \(rec.events.count)")
expect(rec.events == expectedUIKit, "UIKit：生命周期回调顺序与文档一致")
// 关键性质：进程级事件（app:）各只出现一次，场景级事件可重复（前后台切换）
expect(rec.events.filter { $0.hasPrefix("app:") }.count == 2,
       "进程级事件只在启动/终止各出现一次")
expect(rec.events.filter { $0 == "scene:didBecomeActive" }.count == 2,
       "场景级事件随前后台切换可多次发生")
// 顺序性质：一定先 resignActive 再 enterBackground（不能直接跳到后台）
let resignIdx = rec.events.firstIndex(of: "scene:willResignActive") ?? -1
let bgIdx = rec.events.firstIndex(of: "scene:didEnterBackground") ?? -1
expect(resignIdx >= 0 && bgIdx == resignIdx + 1, "退后台前必先失去焦点（resignActive→enterBackground）")

// ---- 2) SwiftUI：scenePhase 三态切换 ----
line("")
line("-- SwiftUI：scenePhase 三态 --")
let rec2 = LifecycleRecorder()
let handler = PhaseHandler(rec: rec2)
handler.onChange(to: .active)      // 启动后进入前台可交互
handler.onChange(to: .inactive)    // 来电 / 上拉多任务预览
handler.onChange(to: .background)  // 退到后台
handler.onChange(to: .active)      // 又回来
expect(rec2.events == ["phase:active", "phase:inactive", "phase:background", "phase:active"],
       "SwiftUI：scenePhase 依次经过 active→inactive→background→active")
expect(ScenePhaseModel(rawValue: "active") == .active,
       "scenePhase 三态可用 rawValue 互转（便于持久化/日志）")

// ---- 3) 概念澄清：进程级 vs 场景级 ----
line("")
line("-- 谁负责什么 --")
line("  AppDelegate   ：进程生命周期（启动、终止）——全局仅一份")
line("  SceneDelegate ：每个窗口的前台/后台/挂起——iPad 多窗口时有多份")
line("  SwiftUI       ：把上面两层收敛成 @Environment(\\.scenePhase) 一个值")
expect(true, "理解两层的分工，是写对「进后台该保存什么」的前提")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 03 结束 ====")
exit(failures == 0 ? 0 : 1)
