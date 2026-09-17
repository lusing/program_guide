# 19 · 菜单、状态栏与工具栏

> 示例：`examples/19_menus/main.swift`
> 实测输出见 `build/19_menus/stdout.clt.txt`

macOS 的菜单栏**不属于任何窗口**，它属于 `NSApplication`。
这一条决定了菜单系统的全部设计：菜单项不知道当前焦点在哪个窗口，
它靠 `target = nil` + 响应链找到接收者。

## 0) 先说一个致命的坑

```swift
let app = NSApplication.shared        // ← 必须是第一句
app.setActivationPolicy(.accessory)

NSApp.setActivationPolicy(.accessory) // ← 不先建 shared 就直接用 NSApp 会崩
```

> **坑**：全局的 `NSApp` 在 `NSApplication.shared` 被创建之前是 **nil**。
> Swift 里它的类型是 `NSApplication!`（隐式解包可选），
> 所以第一次直接用 `NSApp.xxx` 就是「Unexpectedly found nil」→ **SIGILL（退出码 132）**，
> 而且 **stdout 上什么都没有**（进程在第一条输出之前就死了）。
> 这是本教程里最难查的一类崩：退出码 132 + 空 stdout + 空 stderr。

## 1) NSMenu / NSMenuItem

```swift
let fileMenu = NSMenu(title: "文件")
let newItem = NSMenuItem(title: "新建",
                         action: #selector(MenuTarget.newDocument(_:)),
                         keyEquivalent: "n")
newItem.keyEquivalentModifierMask = [.command]
newItem.target = target
fileMenu.addItem(newItem)
fileMenu.addItem(NSMenuItem.separator())
```

实测：

```
== NSMenu / NSMenuItem ==
  ok   菜单里有三项（含分隔线）（实际 3）
  ok   按标题能找回菜单项
  ok   第三项是分隔线
  ok   键等价是 n
  ok   修饰键含 ⌘
  ok   菜单项的 action 被调用了（实际 1）
```

要点：

- **分隔线也是一个 `NSMenuItem`**（`isSeparatorItem == true`），占一个位置
- `keyEquivalent` 是**字符**，不写修饰键就只有那个字符本身（比如 `"a"`）
- 回车是 `"\r"`，Esc 是 `"\u{1B}"`，删除是 `"\u{7F}"`
- `item(withTitle:)` 按标题查找 —— 本地化之后标题会变，**不要靠它做逻辑**

## 2) 子菜单

```swift
let recentItem = NSMenuItem(title: "最近打开", action: nil, keyEquivalent: "")
recentItem.submenu = recentMenu       // 挂上去
recentMenu.supermenu === fileMenu     // 反向指针自动建立
```

实测：

```
== 子菜单 ==
  ok   submenu 指向子菜单
  ok   子菜单里有两项
  ok   hasSubmenu 为 true
  ok   子菜单能找到自己的上级菜单
```

`supermenu` 是**自动**建立的 —— 你只需要设 `submenu`。

## 3) 关键机制：target = nil 交给响应链

```swift
let chainItem = NSMenuItem(title: "保存", action: #selector(Document.saveDocument(_:)), keyEquivalent: "s")
chainItem.target = nil      // ← 关键
```

实测：

```
== target = nil 与响应链 ==
  ok   菜单项的 target 是 nil
  ok   响应链上的对象认领这个 selector
  ok   随便一个对象不认领它
  ok   沿链找到的接收者被执行了
```

**这就是「代码里看不见连线」的原因。** 菜单项点下去时 AppKit：

1. 拿 `NSApp.keyWindow?.firstResponder`
2. 从它开始沿 `nextResponder` 一路问 `responds(to: action)`
3. 找到第一个认领的就发给它

**菜单项的自动启用（灰/亮）也是同一套**：没人认领 → 灰。

所以你只要在某个 `NSResponder` 子类里加：

```swift
@objc func saveDocument(_ sender: Any?) { ... }
```

菜单项自己就亮了。

> **坑**：菜单项的 action 方法签名同样是 `(_ sender: Any?)`。
> 而且必须在**响应链上**（view / view controller / window / window controller /
> document / AppDelegate）。放在一个普通对象里没人找得到它。

## 4) 应用主菜单

```swift
let mainMenu = NSMenu(title: "主菜单")
let appItem = NSMenuItem(title: "应用", action: nil, keyEquivalent: "")
appItem.submenu = fileMenu
mainMenu.addItem(appItem)
NSApp.mainMenu = mainMenu
```

实测：

```
== 应用主菜单 ==
  ok   主菜单挂上了
  ok   主菜单有一个顶层菜单
  ok   第一项是「应用」菜单
  ok   菜单项默认启用
  ok   可以手动禁用
```

macOS 主菜单的惯例（Xcode 模板自动给你）：

```
应用菜单 | 文件 | 编辑 | 格式 | 视图 | 窗口 | 帮助
```

- **第一个**菜单的标题是 app 名，里面放「关于/偏好设置/退出」
- **窗口**菜单系统会自动维护（最近窗口列表）
- **帮助**菜单里有系统自带的搜索框

### 自动启用的手动版本

需要更精细的控制时实现：

```swift
override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    if menuItem.action == #selector(saveDocument(_:)) {
        return isDirty          // 没改动就灰掉「保存」
    }
    return super.validateMenuItem(menuItem)
}
```

## 5) 上下文菜单

```swift
let view = NSView(frame: ...)
view.menu = NSMenu(title: "上下文")
```

实测：

```
== 上下文菜单 ==
  ok   视图可以挂上下文菜单
  ok   上下文菜单有一项
  ok   上下文菜单没有上级菜单
```

> **坑**：`NSView.menu` 是 **strong**（不像 delegate 那样要自己持有）。
> `supermenu` 是 nil —— 它不在主菜单树里。

## 6) 状态栏：NSStatusItem

```swift
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
statusItem.button?.title = "M"
// 或者：
statusItem.button?.image = NSImage(systemSymbolName: "gear", ...)
statusItem.button?.image?.isTemplate = true     // ← 菜单栏图标必须模板化
// 点开的菜单：
statusItem.menu = myMenu
```

实测：

```
== NSStatusItem ==
  ok   状态栏项默认可见
  ok   它属于系统状态栏
  ok   长度是 squareLength
  ok   variableLength 可以改长度
```

两种长度：

- `NSStatusItem.squareLength` —— 固定方形（放图标）
- `NSStatusItem.variableLength` —— 随内容变（放文字）

> **坑**：用完了要 `NSStatusBar.system.removeStatusItem(item)`，
> 否则图标一直留在菜单栏上（进程活着就在）。

做「只有菜单栏图标」的 app：`LSUIElement = true` + `setActivationPolicy(.accessory)`，
然后只建 status item，不建窗口。

## 7) 工具栏：NSToolbar

```swift
let toolbar = NSToolbar(identifier: "dev.macosdev.main")
toolbar.displayMode = .iconAndLabel
toolbar.allowsUserCustomization = true      // 允许用户拖动自定义
toolbar.autosavesConfiguration = true       // 记住用户的自定义
toolbar.delegate = self                     // 提供 item
```

实测：

```
== NSToolbar ==
  ok   工具栏有标识符
  ok   允许用户自定义
  ok   新工具栏没有 item
```

> **坑**：`NSToolbar.Identifier` 是 **`String` 的 typealias**，不是 struct。
> 所以直接 `toolbar.identifier == "xxx"`，**没有 `.rawValue`**
> （照抄 `NSUserInterfaceItemIdentifier` 的习惯会编译不过）。

工具栏的 item 也是 target-action，**同样可以 `target = nil` 走响应链** ——
这是 macOS 工具栏比 iOS 好写的地方。

## 8) 坑清单

| 现象 | 原因 |
| --- | --- |
| 退出码 132 + 空输出 | 在 `NSApplication.shared` 之前用了 `NSApp`（它是 nil） |
| 菜单项一直灰着 | 响应链上没人认领那个 selector（拼写或签名不对） |
| 菜单项点了没反应 | target 指向的对象已释放，或 action 拼写错 |
| 本地化后 `item(withTitle:)` 找不到 | 标题会变，别靠标题做逻辑，靠 `tag` 或持有引用 |
| `toolbar.identifier.rawValue` 编译不过 | `NSToolbar.Identifier` 是 String typealias |
| 状态栏图标关不掉 | 没 `removeStatusItem` |
| 菜单栏图标深色模式下看不见 | 图片没设 `isTemplate = true` |

## 小结

- **第一句一定是 `NSApplication.shared`**；`NSApp` 在那之前是 nil。
- 菜单不属于窗口，属于 `NSApplication`。
- `target = nil` 让菜单项沿响应链找接收者 —— 自动启用也是同一套机制。
- 分隔线也是 menu item，占一个位置。
- 菜单栏图标必须 `isTemplate = true`；用完 `removeStatusItem`。
- `NSToolbar.Identifier` 是 String，没有 `rawValue`。
