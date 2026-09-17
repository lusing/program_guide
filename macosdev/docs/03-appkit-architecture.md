# 03 · AppKit 架构：MVC、响应链、委托

> 示例：`examples/03_appkit_architecture/main.swift`
> 实测输出见 `build/03_appkit_architecture/stdout.clt.txt`

iOS 和 macOS 都叫 MVC，但 macOS 上的「C」承担的东西多得多：
一个窗口控制器里塞着窗口、工具栏、sheet、文档、撤销栈。
本章讲支撑这一切的三个机制：**响应链**、**委托协议**、**target-action**。

## 1) Model / View / Controller 在 AppKit 里长什么样

示例里的分工：

```swift
struct Task {                       // Model：完全不知道界面存在
    var title: String
    var done: Bool
}

final class TaskController: NSObject, TaskListDataSource {   // Controller
    private var tasks: [Task] = []
    func numberOfTasks() -> Int { tasks.count }
    func task(at index: Int) -> String { ... }   // 渲染成字符串给 view
}
```

注意 `task(at:)` 返回的是**已经渲染好的字符串**，不是 `Task`。
这是 AppKit 老派 `dataSource` 的常见形态：控制器负责把 model 变成 view 能直接吃的东西。

AppKit 里 Controller 的两个典型子类：

- **`NSViewController`** —— 管一个 view 子树（`loadView` / `viewDidLoad`）
- **`NSWindowController`** —— 管一个窗口（含工具栏、sheet、文档）

iOS 上 `UIViewController` 一肩挑；macOS 上**两者是分开的**，
一个窗口里可以有多个 `NSViewController`（比如分栏界面）。
这是从 iOS 转过来最需要重新校准的地方。

## 2) 响应链（Responder Chain）

### 结构

```
NSView（最深的子视图）
  ↓ nextResponder
父 NSView
  ↓
NSViewController
  ↓
NSWindow 的 contentViewController
  ↓
NSWindow
  ↓
NSApplication
  ↓
NSApplicationDelegate   ← 链尾，兜底
```

每个 `NSResponder` 只有一个 `nextResponder`，整条链就是单向链表。

示例手工串了一条三节点的链：

```swift
let deepest = SilentResponder()      // 比喻某个子视图
let middle  = GreetingResponder()    // 父视图 / view controller
let top     = SilentResponder()      // 窗口
deepest.nextResponder = middle
middle.nextResponder = top
```

### 沿链找接收者

AppKit 的原生版本是 `NSResponder.tryToPerform(_:with:)`：
**自己不认领就交给 `nextResponder`**，一路走到链尾仍没人认领就返回 `false`。

```swift
expect(deepest.tryToPerform(action, with: button) == true,
       "tryToPerform 从链最深处开始，找到了中间层")
expect(top.tryToPerform(action, with: button) == false,
       "从已经越过响应者的位置出发则找不到")
```

实测：

```
== 响应链 ==
  ok   问到第 2 个响应者就找到了实现
  ok   绕过顺序正确
  ok   链上有人认领 sayHello:
  ok   按钮的 target 指向中间层
  ok   按钮的 action 是同一个 selector
    GreetingResponder 认领了 sayHello:
  ok   tryToPerform 从链最深处开始，找到了中间层
  ok   从已经越过响应者的位置出发则找不到
  ok   最深处自己不认领 action（靠 forwarding）
```

### 响应链解决了什么问题

**菜单项不需要知道当前焦点在哪个窗口。**

菜单栏里的「复制」菜单项 `target = nil`，action 是 `copy:`。
点击时 AppKit 从 `firstResponder`（可能是某个文本视图、某个表格、某个自定义 view）
开始沿链问「谁实现了 `copy:`」。谁实现了就谁干。

所以你只要在某个 `NSResponder` 子类里加一句：

```swift
@objc func copy(_ sender: Any?) { ... }
```

菜单项**自动就亮了**（菜单的自动启用也是靠 `responds(to:)` 查链实现的）。
这是 macOS 上最省心的一个机制，也是初学者最看不懂的一个 ——
因为代码里没有任何一处把菜单和你的类连起来。

> **坑**：`NSApplication.sendAction(_:to:from:)` 才是控件真正的派发入口，
> 但它要求应用正在 `NSApplication.run()` 的事件循环里。命令行自测里直接调用会
> **立刻 SIGILL**，连异常都抓不到。自测请用 `tryToPerform`。
>
> **坑**：`sendAction` 对**非空 target** 是直接 `performSelector` 的 ——
> target 不认领这个 selector 时会抛 `NSInvalidArgumentException`
> （不是返回 false）。所以「沿链找人」一定要让 target 为 nil 时自己走。

## 3) 委托协议：可选方法是常态

```swift
@objc protocol LifeCycleReporting: NSObjectProtocol {
    @objc optional func viewDidAppear()   // 可选：实现就回调，不实现就算了
    func viewTitle() -> String            // 必选
}
```

Swift 里 `@objc optional` **只能用在 `@objc protocol` 上**，而且协议必须继承
`NSObjectProtocol`。这是 Swift 与 ObjC 互操作时为数不多需要显式写 `@objc` 的地方之一。

调用可选方法前**必须**先问：

```swift
if delegate.responds(to: #selector(LifeCycleReporting.viewDidAppear)) {
    delegate.viewDidAppear?()
}
```

实测：

```
== 委托与可选方法 ==
  ok   必选方法直接调用
  ok   可选方法没实现 → responds 为 false
  ok   必选方法 responds 为 true
```

**`NSApplicationDelegate` 的方法全部是可选的**，所以你只实现关心的那几个就行。

> **坑**：Swift 里可选协议方法要用 `delegate.viewDidAppear?()`（带问号）。
> 不加问号编译不过；加了问号但没先 `responds(to:)` 也可能走到不该走的分支。

## 4) target-action

```swift
let button = NSButton(title: "发送", target: middle, action: #selector(GreetingResponder.sayHello(_:)))
```

- `target`：消息的接收者。**为 nil 时走响应链**。
- `action`：一个 `Selector`。签名固定是 `func f(_ sender: Any?)`。

`Selector` 在 Swift 里用 `#selector(Type.method(_:))` 写，
被调用的方法必须标 `@objc`（否则 ObjC 运行时看不到它）。

AppKit 的 action 方法**必须带一个参数**（`_ sender: Any?`），
这和 C# 的事件、JS 的回调不同 —— 参数里传来的是触发控件本身。

## 5) 一个真实的架构建议

小项目：

```
AppDelegate
 ├── NSWindowController（或直接在 AppDelegate 里持有 window）
 │    └── contentViewController: NSViewController
 │         └── view 子树
```

有多个窗口/文档时：

```
AppDelegate（只管生命周期和全局菜单）
 ├── NSDocumentController（系统单例，管文档类型）
 │    └── NSDocument（每个文档一个）
 │         └── makeWindowControllers() → NSWindowController
 │              └── NSViewController
```

**不要在 AppDelegate 里塞业务逻辑。** 它应该只有：建主菜单、响应 open/quit、
持有全局服务。业务放在 window controller / view controller 里。

## 6) 坑清单

| 现象 | 原因 |
| --- | --- |
| 委托回调一个都不来 | 委托是 weak，没人持有它 |
| 菜单项一直灰着 | 响应链上没人实现那个 selector（拼写/参数签名不对） |
| action 报 unrecognized selector | 方法没标 `@objc`，或签名不是 `(_ sender: Any?)` |
| 自测里调 `sendAction` 直接崩 | 不在 `NSApplication.run()` 的事件循环里，改用 `tryToPerform` |
| `@objc optional` 编译不过 | 协议没写 `@objc`，或没继承 `NSObjectProtocol` |

## 小结

- 响应链 = `nextResponder` 串起来的单向链表，解决「谁来处理」的问题。
- 委托 = 弱引用 + 一堆可选方法，调用可选方法前先 `responds(to:)`。
- target-action = `target` 为 nil 时沿响应链找人，这是菜单系统能工作的原因。
- macOS 上 `NSWindowController` 与 `NSViewController` 是分开的。
