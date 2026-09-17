# 02 · 第一个 AppKit 应用：不用 XIB 也能建窗口

> 示例：`examples/02_hello_appkit/main.swift`
> 实测输出见 `build/02_hello_appkit/stdout.clt.txt`

```bash
./02_hello_appkit             # 显示窗口，关掉就退出
./02_hello_appkit --selftest  # 不显示窗口，跑完断言直接退出
```

## macOS 应用的心脏：NSApplication

一个 AppKit 程序的骨架只有五行：

```swift
let app = NSApplication.shared     // 1. 拿到进程唯一的那个应用对象
app.delegate = delegate            // 2. 挂上委托
app.setActivationPolicy(.regular)  // 3. 决定要不要 Dock 图标
app.run()                          // 4. 进入 run loop（这一行不返回，直到退出）
```

和 iOS 最大的三个差别：

| | iOS / UIKit | macOS / AppKit |
| --- | --- | --- |
| 入口 | `@main` + `UIApplicationMain` | 你自己写 `NSApplication.shared.run()` |
| 窗口 | 系统给你一个 `UIWindow` | **窗口要自己 new** |
| 多窗口 | 一个场景一个窗口 | 一个进程任意多个窗口，没有 Scene 层 |

`NSApplication.shared` 是个单例。第一次触碰它时 AppKit 会做一大堆初始化
（连 WindowServer、建主菜单、装 Apple Event 处理器……）。

> **坑**：`NSApplication.shared` 一被创建，进程就会尝试连接 WindowServer。
> 在纯命令行/ssh 会话里这可能失败或很慢。本教程在自测里一律
> `setActivationPolicy(.accessory)` —— 既不显示 Dock 图标，也不去抢焦点。

## Activation Policy

```swift
app.setActivationPolicy(.regular)    // 有 Dock 图标、有菜单栏（正常 App）
app.setActivationPolicy(.accessory)  // 无 Dock 图标，可以有菜单栏（后台/代理 App）
app.setActivationPolicy(.prohibited) // 连菜单栏都没有（纯后台）
```

菜单栏常驻应用（比如输入法、剪贴板工具）用 `.accessory`；
想做成「只有状态栏图标」的 App，就 `.accessory` **并且**不在 `applicationDidFinishLaunching`
里 `makeKeyAndOrderFront`。

## 窗口：contentRect 与 styleMask

```swift
let window = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 360, height: 220),
    styleMask: [.titled, .closable, .miniaturizable, .resizable],
    backing: .buffered,
    defer: false)
```

- **`contentRect` 是内容区的尺寸**，不含标题栏。外框（frame）会更大。
- **`styleMask`** 决定标题栏、关闭按钮、缩放等。`.borderless` 就是啥都没有。
- **`backing: .buffered`** 是唯一还在用的选项（历史上还有 `retained`/`nonretained`）。
- **`defer: false`** 表示立刻创建窗口的底层资源。

窗口**必须被强引用持有**，否则 ARC 立刻释放它，你会看到「窗口闪一下就没了」。
示例里用 `AppDelegate.window` 持有。

## 坐标系：(0,0) 在左下角

```
AppKit                          UIKit
y ↑                             (0,0) ┌─────────┐
  │  ┌─────────┐                      │         │
  │  │         │                      │         │
  │  │         │                      └─────────┘
 (0,0)──────────→ x                        y ↓
```

从 iOS 转过来的人在这里必踩一次。Y 轴向上，**数值越小越靠下**。

`NSView` 可以用 `isFlipped` 翻转自己的坐标系（只影响自己和子视图），
画文本/排版时经常这么干，但**不要为了「顺手」乱翻**，会和外界的坐标换算打架。

## 视图层级

```swift
let root = NSView(frame: ...)
root.addSubview(label)
root.addSubview(button)
window.contentView = root
```

`NSWindow.contentView` 是内容区的根视图，它自带一个，你也可以整个换掉。
`subviews` 数组的顺序**等于添加顺序**，也等于绘制顺序（后面的盖在上面）。

实测：

```
== 运行 AppKit run loop（不显示任何窗口）==
  ok   窗口标题已设置
  ok   根视图有 4 个子视图（实际 4）
  ok   第一个子视图是 NSTextField
  ok   第三个子视图是 NSButton
  ok   窗口有关闭按钮
  ok   窗口可缩放
  ok   自测模式下窗口没有显示出来
  ok   三个标签都有文字
  ok   首个标签文字正确
```

## 委托：NSApplicationDelegate

```swift
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) { ... }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
```

**所有方法都是可选的**（`optional func`），实现哪个就接管哪个。常用的：

| 方法 | 时机 |
| --- | --- |
| `applicationDidFinishLaunching` | 启动完成，此时建窗口最合适 |
| `applicationWillTerminate` | 即将退出，最后一次存数据的机会 |
| `applicationShouldTerminateAfterLastWindowClosed` | 返回 true = 关掉最后一个窗口就退出 |
| `applicationShouldHandleReopen` | 点 Dock 图标时（无窗口时用来重建窗口） |
| `application(_:open:)` | 拖文件到 Dock 图标、open URL |

> **坑**：委托是 `weak` 的。写成 `NSApp.delegate = MyDelegate()` 会让对象当场释放，
> 什么回调都收不到。必须用一个变量持有它。

## 自测模式：让 GUI 程序能在终端里验证

这是本教程所有 AppKit 示例的关键设计。做法：

```swift
let isSelfTest = CommandLine.arguments.contains("--selftest")
```

自测模式下：

1. `setActivationPolicy(.accessory)` —— 不出 Dock 图标；
2. 建完窗口**绝不** `makeKeyAndOrderFront` —— 否则每次验证都闪窗口；
3. 断言照跑，最后打印 `==== 02 结束 ====` 并按失败数决定退出码。

### 让 run loop 转一圈再收工

`app.run()` 进去就不出来了，所以示例用了这个技巧：

```swift
func stopRunLoop(after seconds: Double = 0.05) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        NSApp.stop(nil)
        let synthetic = NSEvent.otherEvent(with: .applicationDefined, location: .zero,
                                           modifierFlags: [], timestamp: 0, windowNumber: 0,
                                           context: nil, subtype: 0, data1: 0, data2: 0)!
        NSApp.postEvent(synthetic, atStart: true)
    }
}
```

两个坑都在这一小段里：

1. **只调 `stop(nil)` 不够** —— `run()` 正卡在 `nextEventMatchingMask` 里等事件，
   没人叫醒它。必须补投一个事件。
2. **不要用 `NSApp.terminate(nil)`** —— 它直接 `exit()`，
   `run()` 之后的代码（包括结束标记）一行都不会执行。

## target-action：AppKit 的事件模型

```swift
button.target = controller
button.action = #selector(Controller.doSomething(_:))
```

`target` 为 `nil` 时，控件会把 action **沿响应链往上抛**，直到有人认领。
这是 AppKit 与 UIKit 共有的机制，但 macOS 上用得更凶 ——
菜单栏、工具栏、右键菜单全靠它。第 03 章细讲。

## 与 Xcode 模板的对照

Xcode 的 "macOS App" 模板会给你：

- `AppDelegate.swift`（或 SwiftUI 的 `@main App`）
- `MainMenu.xib` / `Main.storyboard` —— 主菜单和一个窗口
- `ViewController.swift`

本章是**这些文件的纯代码等价物**。理解它之后，再看模板就知道
「那几个文件分别在干什么」，而不是对着一堆连线发懵。

## 小结

- `NSApplication.shared.run()` 是心脏，`delegate` 上挂生命周期回调。
- 窗口要自己 new、自己持有、自己 `makeKeyAndOrderFront`。
- 坐标原点在左下角。
- 示例用 `--selftest` 进入无 GUI 模式，这是全教程能自动验证的基础。
