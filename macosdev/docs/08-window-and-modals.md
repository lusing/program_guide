# 08 · 窗口、sheet、模态与面板

> 示例：`examples/08_window_and_modals/main.swift`
> 实测输出见 `build/08_window_and_modals/stdout.clt.txt`

macOS 的窗口比 iOS 复杂得多：有层级（level）、有 sheet（贴在窗口上的模态）、
有模态会话（modal session）、有工具面板（panel）。本章把这些概念理顺。

## 1) frame 与 contentRect：两套尺寸

```swift
let content = NSRect(x: 0, y: 0, width: 400, height: 300)
let titled     = NSWindow.frameRect(forContentRect: content, styleMask: [.titled, .closable])
let borderless = NSWindow.frameRect(forContentRect: content, styleMask: .borderless)
```

实测：

```
  titled     frame 高 = 328.0
  borderless frame 高 = 300.0
  ok   有标题栏时窗口外框比内容区高 28 点（实际 328.0）
  ok   无边框时外框就等于内容区（实际 300.0）
  ok   contentRect 与 frame 互为逆运算（尺寸部分）
```

- **`frame`** = 含标题栏的外框（屏幕坐标）
- **`contentRect`** = 内容区（不含标题栏）

`NSWindow(contentRect:...)` 的初始化器收的是**内容区**，
`window.frame` 读出来会更大。想按外框尺寸建窗口，先用
`NSWindow.contentRect(forFrameRect:styleMask:)` 反算。

> **坑**：`NSWindow(contentRect:)` 里的 origin 是**屏幕坐标**，
> 而 macOS 的屏幕坐标原点在**左下角**（主屏幕）。同一段代码在不同屏幕高度、
> 不同显示器排列下得到不同的 y。所以示例只断言 width/height，不打印 origin。
> 要把窗口放到屏幕中间请用 `window.center()`。

## 2) styleMask

```swift
let window = NSWindow(contentRect: ..., styleMask: [.titled, .closable, .miniaturizable, .resizable], ...)
```

常用选项：

| 选项 | 效果 |
| --- | --- |
| `.titled` | 有标题栏 |
| `.closable` | 关闭按钮 |
| `.miniaturizable` | 最小化按钮 |
| `.resizable` | 可缩放 |
| `.fullSizeContentView` | 内容区延伸到标题栏下面（配合透明标题栏做「无边框但有按钮」） |
| `.unifiedTitleAndToolbar` | 标题栏与工具栏合并 |
| `.hudWindowPanel` | HUD 风格（半透明黑） |
| `.borderless` | 什么都不要 |
| `.utilityWindow` | 工具窗口（不在 Dock、不抢焦点） |

全屏**不是** `.resizable` 的一部分，要显式加 `.fullScreen`（或让系统给）。

标题栏按钮是真对象，可以拿到：

```swift
let closeButton = window.standardWindowButton(.closeButton)
```

实测：

```
  关闭按钮类 = _NSThemeCloseWidget
  ok   关闭按钮拿得到
  ok   关闭按钮自带 triggered action
```

> **坑**：类型是私有的 `_NSThemeCloseWidget`。可以改 `isHidden` / `isEnabled`，
> **不要改它的 frame**（系统会自己排）。

## 3) 窗口层级（level）

```swift
NSWindow.Level.normal.rawValue       // 0
NSWindow.Level.floating.rawValue     // 3
NSWindow.Level.modalPanel.rawValue   // 8
NSWindow.Level.screenSaver.rawValue  // 1000
```

实测：

```
  normal=0 floating=3 modalPanel=8 screenSaver=1000
  ok   普通窗口 level 是 0
  ok   浮窗在普通窗口之上
  ok   模态面板在浮窗之上
  ok   屏保在最上层
```

level 决定**谁盖住谁**，和「谁有焦点」无关。

- **普通窗口**：`normal`(0)
- **工具面板**：`NSPanel` + `floating`(3) —— 永远在主窗口上面，但不抢焦点
- **模态**：`modalPanel`(8)

`NSPanel` 是 `NSWindow` 的子类，专门为工具窗口设计：

```swift
let panel = NSPanel(contentRect: ..., styleMask: [.titled, .closable, .utilityWindow], ...)
panel.level = .floating
panel.isFloatingPanel       // true
```

## 4) sheet 与模态会话

macOS 有两种模态：

### sheet（窗口内模态）

```swift
window.beginSheet(sheetWindow) { response in
    // 用户点了某个按钮之后
}
```

sheet 从窗口标题栏下方「展开」出来，**只挡住那一个窗口**。
这是 macOS 上最推荐的模态形式（比应用级模态温和得多）。

### 应用级模态（modal session）

```swift
let session = NSApp.beginModalSession(for: window)
while NSApp.runModalSession(session) == .continue { }
NSApp.endModalSession(session)
```

会阻塞整个应用。

示例只验证**状态**（不真的弹 sheet，自测里弹窗会挂住）：

```
== sheet 与模态 ==
  ok   没有挂 sheet 时 attachedSheet 为 nil
  ok   没有父窗口时 sheetParent 为 nil
  ok   普通窗口不是模态面板
  ok   当前没有模态窗口在跑
  ok   自测模式下没有 key window（窗口没显示过）
```

> **坑**：`runModal()` 会**阻塞主线程**并启动自己的事件循环。
> 在它返回之前，你的代码不会往下走。单元测试里跑它会挂死 ——
> 这就是为什么本教程的示例只查状态、不真跑模态。

## 5) NSWindowController

```swift
let wc = NSWindowController(window: window)
wc.window === window        // true
wc.windowFrameAutosaveName = "MainWindow"    // 下次启动自动恢复位置
```

`NSWindowController` 负责：

- 持有窗口（以及它自己的 nib）
- 窗口位置自动保存（`windowFrameAutosaveName`）
- 文档型应用里一个文档一个 window controller

实测：

```
== NSWindowController ==
  ok   控制器持有同一个窗口对象
  ok   能通过控制器读到标题
  ok   自动保存名用于下次启动时恢复位置
```

**每个窗口都应该有一个 window controller**。AppDelegate 里直接持有 NSWindow
只在「单窗口小工具」里可接受。

## 6) NSAlert

```swift
let alert = NSAlert()
alert.messageText = "要保存吗？"
alert.informativeText = "关闭前不保存，改动会丢失。"
alert.addButton(withTitle: "保存")
alert.addButton(withTitle: "不保存")
alert.addButton(withTitle: "取消")
alert.alertStyle = .warning
```

实测：

```
  buttons = 保存 / 不保存 / 取消
  ok   加了三个按钮
  ok   按钮顺序与添加顺序一致
  ok   第一个按钮的快捷键是回车
  ok   alertStyle 设为 warning
```

约定：

- **第一个**按钮是默认按钮，绑定**回车键**
- **第二个**（如果有）绑定 Esc
- 三个按钮的顺序按 macOS HIG 是「确认 / 取消 / 其他」还是
  「确认 / 不保存 / 取消」要看具体语义，HIG 建议默认操作放**右边**

运行方式：

```swift
alert.beginSheetModal(for: window) { response in
    switch response {
    case .alertFirstButtonReturn:  ...
    case .alertSecondButtonReturn: ...
    default: ...
    }
}
// 或者无窗口时：
let response = alert.runModal()
```

## 7) NSSavePanel / NSOpenPanel

```swift
let panel = NSSavePanel()
panel.nameFieldStringValue = "untitled"
panel.allowedContentTypes = [.plainText]      // macOS 12+
```

实测：

```
  ok   面板的初始文件名
  ok   限制了允许的类型
  ok   UTType 的标识符是 public.plain-text
```

> **坑**：`allowedFileTypes = ["txt"]` 在 macOS 12 起**已废弃**，会编译告警。
> 用 `allowedContentTypes = [UTType]`（需要 `import UniformTypeIdentifiers`）。
> UTType 的标识符是 `public.plain-text` 这种**反向域名**，不是扩展名。

`NSOpenPanel` 额外有 `canChooseDirectories` / `allowsMultipleSelection`。

## 8) 窗口集合

```
  ok   应用至少有一个窗口（系统也会建隐藏窗口）
```

`NSApp.windows` 里**不只有你建的窗口** —— 系统可能塞了隐藏窗口、
颜色面板、字体面板。遍历时别假设「窗口数 == 我的窗口数」。

## 9) 坑清单

| 现象 | 原因 |
| --- | --- |
| 窗口一闪就没 | 没人强引用它（ARC 立刻释放） |
| 窗口位置每次都不一样 | 用了屏幕坐标硬编码；用 `center()` 或 frame autosave |
| 外框尺寸和内容区差 28 | `frame` 含标题栏，`contentRect` 不含 |
| `allowedFileTypes` 编译告警 | macOS 12 起改用 `allowedContentTypes`（UTType） |
| 工具面板老是抢焦点 | 要用 `NSPanel` + `.utilityWindow`，不是普通 NSWindow |
| 模态跑起来测试挂死 | `runModal()` 阻塞主线程；自测只查状态 |
| `NSApp.windows.count` 比预期大 | 系统隐藏窗口也在里面 |

## 小结

- `frame`（含标题栏）vs `contentRect`（内容区），互相用 `NSWindow.frameRect(forContentRect:)` 换算。
- level 决定遮挡顺序：normal(0) < floating(3) < modalPanel(8)。
- sheet 是窗口内模态，应用级模态要 `runModal()`（会阻塞主线程，别在测试里跑）。
- `NSAlert` 的第一个按钮绑定回车。
- macOS 12 起用 `UTType` 代替扩展名字符串。
