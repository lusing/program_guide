# 10 · 常用控件：NSButton、NSTextField、NSPopUpButton……

> 示例：`examples/10_controls/main.swift`
> 实测输出见 `build/10_controls/stdout.clt.txt`

AppKit 的控件名字和 UIKit 很像（`NSButton` vs `UIButton`），
但**行为差别很大**。本章逐个过一遍，重点讲 macOS 特有的那些。

## 1) NSButton

```swift
let button = NSButton(title: "确定", target: nil, action: nil)
button.bezelStyle = .rounded
button.image = NSImage(systemSymbolName: "plus", accessibilityDescription: nil)
```

`bezelStyle` 决定外观：

| bezelStyle | 样子 |
| --- | --- |
| `.rounded` | 标准圆角按钮（最常用） |
| `.texturedSquare` | 方形、随窗口材质 |
| `.helpButton` | 圆形问号 |
| `.smallSquare` | 小方块 |
| `.recessed` | 凹进去（用于工具栏切换） |
| `.inline` | 无边框（用于表格单元格里） |

按钮有**多种类型**（`setButtonType`），不只是「点一下」：

```swift
let check = NSButton(checkboxWithTitle: "启用", target: nil, action: nil)
check.state = .on              // .on / .off / .mixed
let radio = NSButton(radioButtonWithTitle: "选项 A", target: nil, action: nil)
let sw = NSButton(switchWithTitle: "开关", target: nil, action: nil)   // macOS 11+
```

实测：

```
== NSButton ==
  bezelStyle = 1, title = 确定
  ok   按钮标题
  ok   圆角样式
  ok   NSButton 内部还是 NSButtonCell
  ok   勾选框初始是 off
  ok   可以设成 on
  ok   on 的 rawValue 是 1
  ok   switch 型按钮也能设状态
  ok   单选按钮初始未选中
```

**NSCell 还在**：`NSButton` 内部有一个 `NSButtonCell`。
AppKit 从 NeXTSTEP 继承来的「cell 层」用于表格/矩阵里复用绘制。
新代码不用管它，但 `button.cell?.xxx` 仍是最省事的一些设置入口。

键等价（快捷键）：

```swift
button.keyEquivalent = "\r"                    // 回车
button.keyEquivalent = "\u{1B}"                // Esc
button.keyEquivalentModifierMask = [.command]  // ⌘
```

## 2) target-action

```swift
button.target = controller
button.action = #selector(Controller.tapped(_:))
```

实测：

```
== target-action ==
  ok   target 就是接收者
  ok   action 是 selector
  ok   手动派发成功
  ok   方法被调用，参数带上了控件本身（实际 ["点我"]）
  ok   target 为 nil 时会走响应链
```

- action 方法签名固定 `func f(_ sender: Any?)`
- 方法必须标 `@objc`
- `target == nil` → 沿响应链找（见第 03 章）

## 3) NSTextField

两种截然不同的形态：

```swift
let label = NSTextField(labelWithString: "说明文字")   // 不可编辑、无边框、无背景
let input = NSTextField(string: "可编辑")             // 可编辑、有边框、有背景
input.placeholderString = "请输入…"
```

实测：

```
== NSTextField ==
  ok   labelWithString 出来的不可编辑
  ok   没有边框
  ok   不画背景
  ok   普通 NSTextField 可以编辑
  ok   带边框
  ok   有占位文字
  ok   stringValue 就是内容
  ok   NSTextField 默认不换行
  ok   超出宽度时滚动而不是换行
```

> **坑**：`NSTextField` **默认单行**，超出宽度就横向滚动，不会自动换行。
> 要换行得改 cell 的 `wraps` + `isScrollable`。
> 多行文本**直接用 `NSTextView`**（它自带 `NSTextStorage`/布局管理器，见第 13 章）。

> **坑**：`labelWithString:` 和 `init(string:)` 是**两个不同的构造器**，
> 产出的对象默认属性完全不同。UI 上「看起来不对」时先确认用的是哪个。

## 4) NSPopUpButton

macOS 的下拉选择控件。两种模式：

```swift
let popup = NSPopUpButton(frame: .zero)
popup.addItems(withTitles: ["小", "中", "大"])
popup.selectItem(at: 1)
popup.titleOfSelectedItem          // "中"
popup.indexOfSelectedItem          // 1
```

```swift
// 下拉菜单模式（第一个 item 当「当前值」显示）
let pullDown = NSPopUpButton(frame: .zero, pullsDown: true)
```

实测：

```
== NSPopUpButton ==
  items = 小 / 中 / 大
  ok   三个选项按添加顺序排列
  ok   选中第 1 项
  ok   选中项的标题是「中」
  ok   共 3 项
  ok   按标题也能选中
```

## 5) NSSegmentedControl

```swift
let seg = NSSegmentedControl(labels: ["日", "周", "月"],
                             trackingMode: .selectOne,
                             target: nil, action: nil)
seg.selectedSegment = 0
seg.setWidth(60, forSegment: 1)
seg.setEnabled(false, forSegment: 2)
```

`trackingMode`：`.selectOne` / `.selectAny` / `.momentary`。

实测：

```
== NSSegmentedControl ==
  segments = 3, selected = 0
  ok   三个分段
  ok   可以单独设每段的宽度
  ok   可以禁用某一段
```

## 6) 数值控件

```swift
let slider = NSSlider(value: 50, minValue: 0, maxValue: 100, target: nil, action: nil)
slider.numberOfTickMarks = 5
slider.allowsTickMarkValuesOnly = true

let stepper = NSStepper(frame: .zero)
stepper.minValue = 0; stepper.maxValue = 10; stepper.increment = 2
```

实测：

```
== 数值控件 ==
  ok   滑块初值 50
  ok   范围 0...100
  ok   可以加刻度
  ok   吸附到刻度
  ok   步进器初值 4
  ok   每次加 2
  ok   值始终被夹在 min/max 之间
```

> **坑**：`NSStepper.minValue/maxValue/increment` 是 **`Double`**，
> 而 `intValue` 是 **`Int32`**。直接比较编译不过，要自己转一次类型。
> 这是 macOS 上最常见的「为什么这行编译不过」之一。

进度：

```swift
let spinner = NSProgressIndicator(frame: .zero)
spinner.style = .spinning          // 转圈（不确定进度）
spinner.isIndeterminate = true
let bar = NSProgressIndicator(frame: .zero)
bar.style = .bar                   // 进度条
bar.doubleValue = 40
```

## 7) NSImageView / NSComboBox

```swift
let iv = NSImageView(image: NSImage(systemSymbolName: "folder", accessibilityDescription: nil))
iv.imageScaling = .scaleProportionallyUpOrDown
```

**SF Symbols 在 macOS 上可用**（macOS 11+），而且默认是**模板图**
（跟随系统色调，菜单栏图标就该这样）。

`NSComboBox` = 输入框 + 下拉列表：

```swift
let combo = NSComboBox(frame: .zero)
combo.addItems(withObjectValues: ["a", "b", "c"])
combo.numberOfVisibleItems = 5
```

实测：

```
== NSImageView / NSComboBox ==
  ok   SF Symbol 可以直接当图片用
  ok   SF Symbol 默认是模板图（跟随系统色调）
  ok   下拉列表有 3 项
  ok   最多显示 5 行
  ok   默认用内部列表，不走 dataSource
```

## 8) 通用属性

```swift
view.isEnabled = false        // 禁用（不响应点击）
view.toolTip = "悬停提示"
view.frame = ...
```

实测：

```
== 通用属性 ==
  ok   禁用的控件不响应点击
  ok   tooltip 就是鼠标悬停提示
```

## 9) 与 UIKit 的对照表

| UIKit | AppKit | 差别 |
| --- | --- | --- |
| `UIButton` | `NSButton` | AppKit 多了 bezelStyle、buttonType（勾选/单选/开关） |
| `UILabel` | `NSTextField(labelWithString:)` | 同一个类，构造器不同 |
| `UITextField` | `NSTextField` | AppKit 默认单行 |
| `UITextView` | `NSTextView` | AppKit 功能强得多（TextKit） |
| `UISwitch` | `NSButton(switchWithTitle:)` | macOS 11 前用 checkbox |
| `UISegmentedControl` | `NSSegmentedControl` | 差不多 |
| `UISlider` | `NSSlider` | AppKit 有刻度 |
| `UIStepper` | `NSStepper` | **min/max 是 Double** |
| `UIActivityIndicatorView` | `NSProgressIndicator` | 两种 style 合在一个类里 |
| — | `NSPopUpButton` | iOS 没有对应控件 |
| — | `NSComboBox` | 输入框 + 下拉 |
| — | `NSColorWell` / `NSDatePicker` / `NSLevelIndicator` | macOS 独有 |

## 10) 坑清单

| 现象 | 原因 |
| --- | --- |
| 按钮点了没反应 | target 被释放（weak / 没人持有），或 action 拼写不对 |
| action 报 unrecognized selector | 方法没标 `@objc`，或签名不是 `(_ sender: Any?)` |
| `intValue` 和 `minValue` 比不了 | Int32 vs Double，要转类型 |
| 文本不换行 | NSTextField 默认单行，多行用 NSTextView |
| 标签「不像标签」 | 用了 `init(string:)` 而不是 `labelWithString:` |
| 窗口里 Tab 键不切换输入 | 要设 `nextKeyView` 或勾 `initialFirstResponder` |
| 控件灰着不动 | `isEnabled = false`（或窗口不是 key window） |

## 小结

- `NSButton` 一个顶 UIKit 四个（push/checkbox/radio/switch），靠 `setButtonType`。
- `NSTextField` 有两种形态，看构造器；多行用 `NSTextView`。
- `NSStepper` 的 min/max 是 Double，`intValue` 是 Int32。
- SF Symbols 在 macOS 上可用，默认是模板图。
- macOS 独有：`NSPopUpButton`、`NSComboBox`、`NSColorWell`、`NSDatePicker`。
