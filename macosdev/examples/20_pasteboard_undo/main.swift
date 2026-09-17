// ============================================================
// 20 - 剪贴板、拖放与撤销
//   NSPasteboard / NSPasteboardItem / 拖放的类型协商 / NSUndoManager
//
// 编译：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name pasteboard_undo main.swift -o 20_pasteboard_undo \
//          -framework Foundation -framework AppKit
// 运行：
//   ./20_pasteboard_undo --selftest
//
// macOS 的剪贴板不止能放文本：一个 pasteboard 上可以同时挂
// 多种「类型」的同一份数据（纯文本 / RTF / 文件 URL / 自定义类型），
// 拖放和复制粘贴共用同一套机制。
// ============================================================

import AppKit
import Foundation

var failures = 0
func expect(_ condition: Bool, _ description: String) {
    if condition {
        print("  ok   \(description)")
    } else {
        print("  FAIL \(description)")
        failures += 1
    }
}

// 坑：全局的 NSApp 在 NSApplication.shared 被创建之前是 nil（见第 19 章）
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// MARK: - 1) 剪贴板

print("== NSPasteboard ==")
// 坑：不要动 NSPasteboard.general —— 那是用户真正的剪贴板，
// 自测里读写它会破坏用户刚复制的东西。用自己的命名 pasteboard。
let board = NSPasteboard(name: NSPasteboard.Name("dev.macosdev.selftest"))
board.clearContents()

let okWrite = board.setString("Hello Cocoa", forType: .string)
expect(okWrite, "字符串写进去了")
expect(board.string(forType: .string) == "Hello Cocoa", "能读回来")
expect(board.types?.contains(.string) == true, "types 里有 .string")

// 一份数据可以挂多种类型：文本 + RTF 一起放，接收方挑自己认识的
let attributed = NSAttributedString(string: "富文本",
                                    attributes: [.foregroundColor: NSColor.systemRed])
if let rtf = try? attributed.data(from: NSRange(location: 0, length: attributed.length),
                                  documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
    board.setData(rtf, forType: .rtf)
}
expect(board.types?.count ?? 0 >= 2, "同一份内容挂了多种类型（实际 \(board.types?.count ?? 0)）")
expect(board.data(forType: .rtf) != nil, "RTF 数据能取出来")
// 文本类型还在 —— 多种类型互不覆盖（只要不是同一种 UTI 族）
expect(board.string(forType: .string) == "Hello Cocoa", "加 RTF 不影响已经放进去的字符串")

// 读不存在的东西：返回 nil，不是崩溃
expect(board.string(forType: .pdf) == nil, "读没有的类型返回 nil")

// clearContents 之后全没了
board.clearContents()
expect(board.types?.count ?? 0 == 0, "clearContents 之后类型清空")

// MARK: - 2) NSPasteboardItem 与 NSPasteboardWriting

print("")
print("== NSPasteboardItem ==")
// 一个 item 上挂多个类型；一行（row）就是一个 item
let item = NSPasteboardItem()
item.setString("行内容", forType: .string)
expect(item.string(forType: .string) == "行内容", "item 能存字符串")
expect(item.types.contains(.string), "item 的 types 里有 .string")

board.clearContents()
let wrote = board.writeObjects([item])
expect(wrote, "writeObjects 把 item 写进了剪贴板")
expect(board.string(forType: .string) == "行内容", "从剪贴板读回来")

// 文件 URL 也是常见的粘贴类型（从 Finder 复制文件）
board.clearContents()
let fileURL = URL(fileURLWithPath: "/tmp/demo-dir/a.txt")
board.writeObjects([fileURL as NSURL])
expect(board.types?.contains(.fileURL) == true, "写 URL 会带出 fileURL 类型")
// 坑：fileURL 类型里存的是**一个 URL 字符串**，不是 URL 对象也不是数组。
// 想要真的 URL 对象，用 readObjects(forClasses:) 直接读。
let urlText = board.propertyList(forType: .fileURL) as? String
print("  fileURL 内容 = \(urlText ?? "nil")")
expect(urlText?.hasSuffix("a.txt") == true, "fileURL 类型里存的是 URL 字符串")
let urls = board.readObjects(forClasses: [NSURL.self], options: nil) as? [URL]
expect(urls?.count == 1, "readObjects 能直接读出 URL 对象")
expect(urls?.first?.lastPathComponent == "a.txt", "读出来的 URL 指向那个文件")
// 老式的 NSFilenamesPboardType 才是「路径数组」，但已经废弃
expect(board.types?.contains(.init("NSFilenamesPboardType")) == true,
       "为了兼容老 API，同时也会挂上 NSFilenamesPboardType")

board.clearContents()

// MARK: - 3) 拖放：类型协商

print("")
print("== 拖放的类型协商 ==")
// 拖放两端不是直接传对象，而是先「协商类型」：
//   拖出方声明：我能给这些类型（registerForDraggedTypes 的反面）
//   接收方声明：我接受这些类型（registerForDraggedTypes）
//   重叠的那一个就是实际传的类型。
let draggingTypes: [NSPasteboard.PasteboardType] = [.string, .fileURL, .rtf]
let offered: [NSPasteboard.PasteboardType] = [.rtf, .string]
// 接收方挑自己能处理、且对方也提供了的第一个
let accepted = draggingTypes.first { offered.contains($0) }
expect(accepted == .string, "协商结果是双方都有的第一个类型（实际 \(accepted?.rawValue ?? "nil")）")

// 真正做拖放要实现的两个协议：
//   NSDraggingSource（拖出方）：draggingSession(_:sourceOperationMaskFor:)
//   NSDraggingDestination（接收方）：draggingEntered / performDragOperation
// 自测里不去模拟真实的鼠标拖拽（那需要 WindowServer + 事件循环），
// 只验证「注册类型」这一层。
let dropView = NSView(frame: NSRect(x: 0, y: 0, width: 100, height: 50))
dropView.registerForDraggedTypes([.fileURL, .string])
expect(dropView.registeredDraggedTypes.contains(.fileURL), "视图注册了接受的拖放类型")
expect(dropView.registeredDraggedTypes.count == 2, "注册了两个类型")

// MARK: - 4) NSUndoManager

print("")
print("== NSUndoManager ==")
// macOS 上每个窗口（其实是每个 NSDocument / responder 链）自带一个 undoManager。
// 命令行示例里自己 new 一个。
// 坑：UndoManager 默认 groupsByEvent = true —— 它靠 run loop 的每次事件
// 自动开合「撤销组」。命令行自测里没有 run loop，于是所有登记都掉进
// 同一个组，一次 undo() 会把全部操作一起撤掉。自测要自己管分组。
let undo = UndoManager()
undo.groupsByEvent = false
expect(undo.canUndo == false, "一开始没有可撤销的操作")
expect(undo.canRedo == false, "也没有可重做的")

final class Doc: NSObject {
    var title = "初始"
}
let doc = Doc()

func setTitle(_ new: String, _ manager: UndoManager) {
    let old = doc.title
    manager.beginUndoGrouping()
    manager.registerUndo(withTarget: doc) { target in
        setTitle(old, manager)      // 撤销时把旧值再设回去（并且登记反向的 redo）
    }
    // 坑：动作名也要在**组内**设置。groupsByEvent = false 时在组外调
    // setActionName 会抛 NSInternalInconsistencyException。
    manager.setActionName("改标题")
    manager.endUndoGrouping()
    doc.title = new
}

setTitle("第一次改", undo)
expect(doc.title == "第一次改", "改了标题")
expect(undo.canUndo, "现在可以撤销了")
expect(undo.undoActionName == "改标题", "撤销菜单项会显示「撤销改标题」（实际「\(undo.undoActionName)」）")

setTitle("第二次改", undo)
expect(doc.title == "第二次改", "又改了一次")
undo.undo()
expect(doc.title == "第一次改", "撤销一次回到第一次改（实际 \(doc.title)）")
expect(undo.canRedo, "现在可以重做了")
undo.redo()
expect(doc.title == "第二次改", "重做又回到第二次改")

// 分组：把一批操作合成一次撤销
print("")
print("== 分组与批量撤销 ==")
let undo2 = UndoManager()
undo2.groupsByEvent = false
undo2.beginUndoGrouping()
undo2.registerUndo(withTarget: doc) { _ in }
undo2.registerUndo(withTarget: doc) { _ in }
undo2.registerUndo(withTarget: doc) { _ in }
undo2.endUndoGrouping()
expect(undo2.canUndo, "分组里有操作，可以撤销")
undo2.undo()      // 一次撤销掉整组
expect(undo2.canUndo == false, "一次撤销把整组都撤了（组是原子单位）")

// 关掉登记：加载文档、初始化界面时改的值不该进撤销栈
undo2.disableUndoRegistration()
undo2.registerUndo(withTarget: doc) { _ in }
undo2.enableUndoRegistration()
expect(undo2.canUndo == false, "disableUndoRegistration 期间的操作不进撤销栈")

// 撤销栈上的操作在 dealloc 时会被自动清理，不需要手工 removeAllActions

// MARK: - 5) NotificationCenter 与撤销的联动

print("")
print("== 通知 ==")
// 撤销/重做会发通知，界面可以靠它刷新「撤销」按钮的启用状态
let center = NotificationCenter.default
var undoNotifications: [String] = []
let obs = center.addObserver(forName: .NSUndoManagerDidUndoChange,
                             object: nil, queue: nil) { note in
    undoNotifications.append(note.name.rawValue)
}
let undo3 = UndoManager()
undo3.groupsByEvent = false
// 坑：groupsByEvent = false 时，registerUndo 之前**必须**先 beginUndoGrouping，
// 否则抛 NSInternalInconsistencyException（"must begin a group before registering undo"）。
undo3.beginUndoGrouping()
undo3.registerUndo(withTarget: doc) { _ in }
undo3.endUndoGrouping()
undo3.undo()
expect(undoNotifications.count == 1, "撤销时发了 DidUndoChange 通知（实际 \(undoNotifications.count)）")
center.removeObserver(obs)
// 用完必须移除（block 版观察者不会自动失效）
undo3.beginUndoGrouping()
undo3.registerUndo(withTarget: doc) { _ in }
undo3.endUndoGrouping()
undo3.undo()
expect(undoNotifications.count == 1, "移除观察者之后不再收到")

print("==== 20 结束 ====")
exit(failures == 0 ? 0 : 1)
