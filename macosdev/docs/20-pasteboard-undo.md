# 20 · 剪贴板、拖放与撤销

> 示例：`examples/20_pasteboard_undo/main.swift`
> 实测输出见 `build/20_pasteboard_undo/stdout.clt.txt`

复制粘贴和拖放在 macOS 上**共用同一套机制**：`NSPasteboard`。
撤销则是每个窗口/文档自带的一根栈。这两个都是「macOS 应用的完成度」所在 ——
一个不支持 ⌘Z 的 Mac app 会被用户认为「半成品」。

## 1) NSPasteboard

```swift
let board = NSPasteboard(name: NSPasteboard.Name("dev.macosdev.selftest"))
board.clearContents()
board.setString("Hello Cocoa", forType: .string)
board.string(forType: .string)        // "Hello Cocoa"
```

实测：

```
== NSPasteboard ==
  ok   字符串写进去了
  ok   能读回来
  ok   types 里有 .string
  ok   同一份内容挂了多种类型（实际 6）
  ok   RTF 数据能取出来
  ok   加 RTF 不影响已经放进去的字符串
  ok   读没有的类型返回 nil
  ok   clearContents 之后类型清空
```

> **坑**：**不要动 `NSPasteboard.general`** —— 那是用户真正的剪贴板。
> 自测里读写它会破坏用户刚复制的东西。用自己的命名 pasteboard。

几个系统 pasteboard：

| name | 用途 |
| --- | --- |
| `.general` | 复制粘贴（⌘C / ⌘V） |
| `.find` | 查找面板的内容 |
| `.drag` | 拖放（系统自动用，你一般不直接碰） |
| 自定义 `NSPasteboard.Name("...")` | 自己用（服务、内部传递） |

### 一份数据挂多种类型

文本编辑器复制一段富文本时会同时放：

- `public.utf8-plain-text`（纯文本，给记事本）
- `public.rtf`（给支持 RTF 的）
- `public.html`（给网页编辑器）
- ……

接收方挑**自己认识的最好的那个**。这是「从 Word 复制的东西粘到备忘录里格式还在」的原因。

实测里放一份 RTF 就多出 6 个类型（系统自动生成派生 UTI）。

## 2) NSPasteboardItem 与 writeObjects

一行（一个被复制的对象）就是一个 `NSPasteboardItem`：

```swift
let item = NSPasteboardItem()
item.setString("行内容", forType: .string)
board.writeObjects([item])
```

实测：

```
== NSPasteboardItem ==
  ok   item 能存字符串
  ok   writeObjects 把 item 写进了剪贴板
  ok   从剪贴板读回来
```

`writeObjects` 接受任何实现了 `NSPasteboardWriting` 的对象
（`NSString`、`NSURL`、`NSImage`、`NSAttributedString` 都实现了）。

### 文件 URL 的坑

```swift
board.writeObjects([fileURL as NSURL])
board.propertyList(forType: .fileURL)        // "file:///tmp/demo-dir/a.txt"
board.readObjects(forClasses: [NSURL.self], options: nil)   // [URL]
```

实测：

```
  fileURL 内容 = file:///tmp/demo-dir/a.txt
  ok   fileURL 类型里存的是 URL 字符串
  ok   readObjects 能直接读出 URL 对象
  ok   为了兼容老 API，同时也会挂上 NSFilenamesPboardType
```

> **坑**：`.fileURL` 类型里存的是**一个 URL 字符串**，不是 URL 对象、也不是数组。
> 老式的 `NSFilenamesPboardType` 才是「路径字符串数组」（已废弃，但为了兼容还在）。
> 想直接拿到 `URL` 就用 `readObjects(forClasses: [NSURL.self], options: nil)`。

## 3) 拖放：先协商类型，再传数据

拖放两端**不是**直接传对象：

1. 接收方 `registerForDraggedTypes([...])` 声明「我接受这些」
2. 拖出方在 `draggingSession` 里声明「我能给这些」
3. 系统取交集，接收方选一个（`draggingEntered` 里返回操作类型）

```swift
let dropView = NSView(frame: ...)
dropView.registerForDraggedTypes([.fileURL, .string])
```

实测：

```
== 拖放的类型协商 ==
  ok   协商结果是双方都有的第一个类型（实际 public.utf8-plain-text）
  ok   视图注册了接受的拖放类型
  ok   注册了两个类型
```

真正实现拖放要写两个协议：

```swift
// 拖出方
extension MyView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession,
                         sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .copy
    }
}

// 接收方
extension MyView: NSDraggingDestination {
    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }
    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pb = sender.draggingPasteboard
        guard let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return false
        }
        open(urls)
        return true
    }
}
```

> **坑**：`performDragOperation` 里读的是 `sender.draggingPasteboard`，
> 不是 `NSPasteboard.general`。拖放期间数据在**拖拽 pasteboard** 上，
> 用户的剪贴板不受影响。

自测里不模拟真实鼠标拖拽（那需要 WindowServer + 事件循环），
只验证「注册类型」这一层。

## 4) NSUndoManager

```swift
let undo = UndoManager()
undo.groupsByEvent = false        // ← 自测必需，见下面的坑

func setTitle(_ new: String, _ manager: UndoManager) {
    let old = doc.title
    manager.beginUndoGrouping()
    manager.registerUndo(withTarget: doc) { target in
        setTitle(old, manager)    // 撤销时把旧值设回去，顺便登记反向的 redo
    }
    manager.setActionName("改标题")
    manager.endUndoGrouping()
    doc.title = new
}
```

实测：

```
== NSUndoManager ==
  ok   一开始没有可撤销的操作
  ok   改了标题
  ok   现在可以撤销了
  ok   撤销菜单项会显示「撤销改标题」（实际「改标题」）
  ok   撤销一次回到第一次改（实际 第一次改）
  ok   现在可以重做了
  ok   重做又回到第二次改
```

### 两个大坑

> **坑 1**：`groupsByEvent` 默认是 `true` —— UndoManager 靠 **run loop 的每次事件**
> 自动开合「撤销组」。命令行自测里没有 run loop，于是**所有登记都掉进同一个组**，
> 一次 `undo()` 会把全部操作一起撤掉。自测必须设 `groupsByEvent = false`
> 然后自己 `begin/endUndoGrouping`。
>
> **坑 2**：`groupsByEvent = false` 时，`registerUndo` **和** `setActionName`
> 都必须在组内调用，否则抛
> `NSInternalInconsistencyException: must begin a group before registering undo`。

### 分组：把一批操作合成一次撤销

```swift
undo.beginUndoGrouping()
undo.registerUndo(...)   // ×3
undo.endUndoGrouping()
undo.undo()              // 一次撤销掉整组
```

实测：

```
== 分组与批量撤销 ==
  ok   分组里有操作，可以撤销
  ok   一次撤销把整组都撤了（组是原子单位）
  ok   disableUndoRegistration 期间的操作不进撤销栈
```

`disableUndoRegistration()` / `enableUndoRegistration()` 用来排除
「不该进撤销栈」的改动（加载文档、初始化界面）。

### 谁提供 undoManager

macOS 上 `NSWindow` 有 `undoManager`，`NSDocument` 也有，
`NSResponder` 链会一路往上找到它。所以：

- 文档的改动 → 自动进文档的撤销栈
- 每个窗口有**独立的**撤销栈（这点和 iOS 一样）

## 5) 通知联动

撤销/重做会发通知，界面靠它刷新「撤销」按钮：

```swift
NotificationCenter.default.addObserver(
    forName: .NSUndoManagerDidUndoChange, object: nil, queue: nil) { note in ... }
```

实测：

```
== 通知 ==
  ok   撤销时发了 DidUndoChange 通知（实际 1）
  ok   移除观察者之后不再收到
```

相关的通知：

| 通知 | 时机 |
| --- | --- |
| `.NSUndoManagerDidOpenUndoGroup` | 开组 |
| `.NSUndoManagerDidCloseUndoGroup` | 关组（非顶层） |
| `.NSUndoManagerDidRegisterUndo` | 登记了一个操作 |
| `.NSUndoManagerDidUndoChange` | 撤销完成 |
| `.NSUndoManagerDidRedoChange` | 重做完成 |
| `.NSUndoManagerWillCloseUndoGroup` | 即将关组（可在这里做收尾） |

> **坑**：block 版观察者**必须手动 `removeObserver`**，否则闭包捕获的对象一直活着。

## 6) 坑清单

| 现象 | 原因 |
| --- | --- |
| 自测把用户的剪贴板搞坏了 | 动了 `NSPasteboard.general` |
| `.fileURL` 读出来是字符串不是 URL | 那个类型存的就是 URL 字符串；用 `readObjects` |
| 一次 `undo()` 把全部操作都撤了 | `groupsByEvent = true` 但没 run loop（自测） |
| `NSInternalInconsistencyException` | `groupsByEvent = false` 时在组外 registerUndo / setActionName |
| 撤销菜单显示「撤销」没有具体内容 | 没设 `setActionName` |
| 界面初始化也算进撤销栈 | 那段要包在 `disableUndoRegistration()` 里 |
| 拖放收不到数据 | 读的是 `general` 而不是 `sender.draggingPasteboard` |
| block 观察者导致泄漏 | 没 `removeObserver` |

## 小结

- 复制粘贴和拖放共用 `NSPasteboard`；一份数据可挂多种类型。
- 自测用自己的命名 pasteboard，别动 `.general`。
- `.fileURL` 存 URL **字符串**；要 URL 对象用 `readObjects(forClasses:)`。
- 拖放先协商类型，数据从 `sender.draggingPasteboard` 读。
- `UndoManager` 自测要 `groupsByEvent = false` 且所有登记/命名都在组内。
- 分组 = 原子撤销单位；用 `disableUndoRegistration` 排除不该记录的改动。
