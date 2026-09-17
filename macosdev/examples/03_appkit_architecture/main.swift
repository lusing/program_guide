// ============================================================
// 03 - AppKit 架构：响应链、委托、MVC
//   NSResponder 链 / target-action / delegate 协议 / model 与 view 分离
//
// 编译：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name appkit_architecture main.swift -o 03_appkit_architecture \
//          -framework Foundation -framework AppKit
// 运行：
//   ./03_appkit_architecture --selftest
//
// AppKit 里「谁来处理这个事件」不是靠继承树，而是靠一条由 nextResponder
// 串起来的链：view → 父 view → 窗口 → NSApplication → AppDelegate。
// ============================================================

import AppKit
import Foundation

let isSelfTest = CommandLine.arguments.contains("--selftest")

var failures = 0
func expect(_ condition: Bool, _ description: String) {
    if condition {
        print("  ok   \(description)")
    } else {
        print("  FAIL \(description)")
        failures += 1
    }
}

// MARK: - 1) Model：完全不知道界面存在

struct Task {
    var title: String
    var done: Bool
}

// MARK: - 2) Controller：持有 model，向 view 提供「渲染结果」

@objc protocol TaskListDataSource: NSObjectProtocol {
    func numberOfTasks() -> Int
    func task(at index: Int) -> String
}

final class TaskController: NSObject, TaskListDataSource {
    private var tasks: [Task] = []

    func add(_ title: String) {
        tasks.append(Task(title: title, done: false))
    }

    func toggle(at index: Int) {
        tasks[index].done.toggle()
    }

    func numberOfTasks() -> Int { tasks.count }

    func task(at index: Int) -> String {
        let task = tasks[index]
        return "\(task.done ? "[x]" : "[ ]") \(task.title)"
    }

    var doneCount: Int { tasks.filter { $0.done }.count }
}

// MARK: - 3) 响应链：手工串一条出来看它怎么走

/// 一个只实现 apply 的响应者。AppKit 的 target-action 允许 target 为 nil，
/// 此时消息会沿着响应链往下传，直到有人认领这个 selector。
final class GreetingResponder: NSResponder {
    @objc func sayHello(_ sender: Any?) {
        print("    GreetingResponder 认领了 sayHello:")
    }

    override var description: String { "GreetingResponder" }
}

final class SilentResponder: NSResponder {
    override var description: String { "SilentResponder" }
}

// MARK: - 4) 委托：AppKit 里最常见的「回调协议」

@objc protocol LifeCycleReporting: NSObjectProtocol {
    @objc optional func viewDidAppear()
    func viewTitle() -> String
}

final class ViewModel: NSObject, LifeCycleReporting {
    // 未实现 viewDidAppear —— 可选方法就是这样被允许缺失的
    func viewTitle() -> String { "03 AppKit 架构" }
}

/// 模拟 AppKit 的行为：先 respondsToSelector 再调用可选方法。
/// 这一句 if 是每个写 AppKit 的人最终都会背下来的写法。
func callOptional<T: NSObjectProtocol>(_ delegate: T, _ selector: Selector) -> Bool {
    delegate.responds(to: selector)
}

// MARK: - 跑断言

let controller = TaskController()
controller.add("读一遍 NSResponder 文档")
controller.add("把 tableView.reloadData 挪出主线程之外的地方")
controller.toggle(at: 0)

print("== Model / Controller ==")
expect(controller.numberOfTasks() == 2, "数据条数为 2（实际 \(controller.numberOfTasks())）")
expect(controller.task(at: 0) == "[x] 读一遍 NSResponder 文档", "第一项已勾选")
expect(controller.task(at: 1) == "[ ] 把 tableView.reloadData 挪出主线程之外的地方", "第二项未勾选")
expect(controller.doneCount == 1, "已完成数量正确")
expect(controller.responds(to: #selector(TaskListDataSource.numberOfTasks)), "控制器响应数据源方法")
expect(controller.conforms(to: NSApplicationDelegate.self) == false, "它不是应用委托")

print("")
print("== 响应链 ==")
let deepest = SilentResponder()      // 链的最深处（比喻：某个子视图）
let middle = GreetingResponder()     // 中间层（父视图 / view controller）
let top = SilentResponder()          // 链头（窗口）
deepest.nextResponder = middle
middle.nextResponder = top

// 手工实现 AppKit 的「沿响应链找 processor」：一路问 respondsToSelector
let action = #selector(GreetingResponder.sayHello(_:))
var cursor: NSResponder? = deepest
var chain: [String] = []
var found = false
while let node = cursor {
    chain.append(node.description)
    if node.responds(to: action) { found = true; break }
    cursor = node.nextResponder
}
expect(chain.count == 2, "问到第 \(chain.count) 个响应者就找到了实现")
expect(chain == ["SilentResponder", "GreetingResponder"], "绕过顺序正确")
expect(found, "链上有人认领 sayHello:")

// target=nil 的消息：AppKit 会用 firstResponder 开始走链，这里 stub 一个确认坐标系外的行为
let button = NSButton(title: "发送", target: middle, action: action)
expect(button.target === middle, "按钮的 target 指向中间层")
expect(button.action == action, "按钮的 action 是同一个 selector")
// NSResponder.tryToPerform 是 AppKit 原生版「沿链找接收者」：自己不认领就交给
// nextResponder，一路走到链尾仍没人认领就返回 false。它是纯运行时派发，
// 不需要 WindowServer，所以自测时能用。
//
// 坑：NSApplication.sendAction(_:to:from:) 才是 AppKit 真正处理控件的入口，
// 但它要求应用正在 NSApplication.run() 的事件循环里；命令行自测直接调用会
// 立刻 SIGILL（unrecognized selector 之外的运行时陷阱），**不要**在自测里用。
expect(deepest.tryToPerform(action, with: button) == true, "tryToPerform 从链最深处开始，找到了中间层")
expect(top.tryToPerform(action, with: button) == false, "从已经越过响应者的位置出发则找不到")
expect(deepest.responds(to: action) == false, "最深处自己不认领 action（靠 forwarding）")

print("")
print("== 委托与可选方法 ==")
let viewModel = ViewModel()
expect(viewModel.viewTitle() == "03 AppKit 架构", "必选方法直接调用")
expect(callOptional(viewModel, #selector(LifeCycleReporting.viewDidAppear)) == false, "可选方法没实现 → responds 为 false")
expect(callOptional(viewModel, #selector(LifeCycleReporting.viewTitle)) == true, "必选方法 responds 为 true")

// NSApplication.delegate 也是同一个套路：一个弱引用 + 一堆可选方法
let app = NSApplication.shared
expect(app.delegate == nil, "尚未设置应用委托")
expect(NSApp === NSApplication.shared, "NSApp 就是 sharedApplication")

print("==== 03 结束 ====")
if !isSelfTest && failures > 0 {
    exit(1)
}
exit(failures == 0 ? 0 : 1)
