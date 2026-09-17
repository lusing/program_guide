// ============================================================
// 08 - 窗口、sheet 与模态
//   NSWindow 的 frame / contentRect / styleMask / level / NSWindowController
//   / NSAlert / NSSavePanel
//
// 编译：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name window_and_modals main.swift -o 08_window_and_modals \
//          -framework Foundation -framework AppKit
// 运行：
//   ./08_window_and_modals             # 真的开一个窗口
//   ./08_window_and_modals --selftest  # 不开窗口，只跑断言
//
// 为什么所有断言都写在 applicationDidFinishLaunching 里：
// NSWindow 的初始化会去找 NSApplication 的 WindowServer 连接，命令行进程
// 在 run() 之前并没有准备好 —— 在 main 里直接 new 一个 NSWindow 会 SIGILL。
// 同理，Swift 的全局 NSApp 在 run() 之前是空的，访问它也会崩。
// 正确顺序：NSApplication.shared → setActivationPolicy → delegate → run()。
// ============================================================

import AppKit
import Foundation
import UniformTypeIdentifiers

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

func stopRunLoop(after seconds: Double = 0.05) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        NSApp.stop(nil)
        let synthetic = NSEvent.otherEvent(with: .applicationDefined, location: .zero,
                                           modifierFlags: [], timestamp: 0, windowNumber: 0,
                                           context: nil, subtype: 0, data1: 0, data2: 0)!
        NSApp.postEvent(synthetic, atStart: true)
    }
}

// MARK: - 1) frame 与 contentRect

func probeFrameGeometry() {
    print("== frame 与 contentRect ==")
    let content = NSRect(x: 0, y: 0, width: 400, height: 300)
    let titled = NSWindow.frameRect(forContentRect: content, styleMask: [.titled, .closable])
    let borderless = NSWindow.frameRect(forContentRect: content, styleMask: .borderless)
    print("  titled     frame 高 = \(titled.height)")
    print("  borderless frame 高 = \(borderless.height)")
    expect(titled.height == 328, "有标题栏时窗口外框比内容区高 28 点（实际 \(titled.height)）")
    expect(borderless.height == 300, "无边框时外框就等于内容区（实际 \(borderless.height)）")

    // 反算回去：contentRect(forFrameRect:) 是上面的逆运算
    let window = NSWindow(contentRect: content, styleMask: [.titled, .closable],
                          backing: .buffered, defer: false)
    let back = window.contentRect(forFrameRect: window.frame)
    expect(back.width == 400 && back.height == 300, "contentRect 与 frame 互为逆运算（尺寸部分）")

    // 坑：contentRect 的 y 是相对屏幕的，同一段代码在不同屏幕高度上得到不同的 y。
    // 所以断言只比 width/height，别把 origin 打出来。
    expect(window.frame.width == 400, "contentRect: 初始化时给的是内容区尺寸")
}

// MARK: - 2) styleMask

func probeStyleMask() {
    print("")
    print("== styleMask ==")
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
    let mask = window.styleMask
    expect(mask.contains(.titled), "有标题栏")
    expect(mask.contains(.closable), "有关闭按钮")
    expect(mask.contains(.resizable), "可缩放")
    expect(mask.contains(.miniaturizable), "可最小化")
    expect(mask.contains(.fullScreen) == false, "默认不允许全屏（要显式加 .resizable 之外的选项）")

    // 标题栏按钮是真的 NSButton，可以拿到，但不要改它的 frame
    let closeButton = window.standardWindowButton(.closeButton)
    expect(closeButton != nil, "能拿到标准关闭按钮")
    // standardWindowButton 返回的静态类型就是 NSButton，这里只验证它确实存在
    expect(closeButton != nil, "关闭按钮拿得到")
    expect(closeButton?.action != nil, "关闭按钮自带 triggered action")
    print("  关闭按钮类 = \(closeButton.map { String(describing: type(of: $0)) } ?? "nil")")

    // 标题栏透明 / 可移动这类外观属性，改起来不影响布局
    window.titlebarAppearsTransparent = true
    expect(window.titlebarAppearsTransparent, "标题栏可以设为透明")
    window.titlebarAppearsTransparent = false
}

// MARK: - 3) 窗口层级

func probeLevels() {
    print("")
    print("== 窗口层级 ==")
    print("  normal=\(NSWindow.Level.normal.rawValue) floating=\(NSWindow.Level.floating.rawValue) "
        + "modalPanel=\(NSWindow.Level.modalPanel.rawValue) "
        + "screenSaver=\(NSWindow.Level.screenSaver.rawValue)")
    expect(NSWindow.Level.normal.rawValue == 0, "普通窗口 level 是 0")
    expect(NSWindow.Level.floating.rawValue > NSWindow.Level.normal.rawValue, "浮窗在普通窗口之上")
    expect(NSWindow.Level.modalPanel.rawValue > NSWindow.Level.floating.rawValue, "模态面板在浮窗之上")
    expect(NSWindow.Level.screenSaver.rawValue > NSWindow.Level.modalPanel.rawValue, "屏保在最上层")

    let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 200, height: 120),
                        styleMask: [.titled, .utilityWindow], backing: .buffered, defer: false)
    panel.level = .floating
    expect(panel.level == .floating, "NSPanel 常配 .floating 做工具窗口")
    expect(panel.isFloatingPanel, "isFloatingPanel 反映这一设置")
}

// MARK: - 4) sheet 与模态的状态

func probeModalState() {
    print("")
    print("== sheet 与模态 ==")
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 320, height: 200),
                          styleMask: [.titled], backing: .buffered, defer: false)
    // 没有 sheet 挂上去时这两个属性都是 nil —— 这就是「当前是不是模态」的判据
    expect(window.attachedSheet == nil, "没有挂 sheet 时 attachedSheet 为 nil")
    expect(window.sheetParent == nil, "没有父窗口时 sheetParent 为 nil")
    expect(window.isModalPanel == false, "普通窗口不是模态面板")
    expect(NSApp.modalWindow == nil, "当前没有模态窗口在跑")

    // 坑：NSApp.runModal(for:) / beginSheet 都会真的阻塞主线程等用户操作，
    // 命令行自测里调用它们会永久卡死。要测模态逻辑，只能断言「还没进入模态」。
    // 这也是本教程把所有 runModal 都排除在自测之外的原因。
    expect(NSApp.keyWindow == nil, "自测模式下没有 key window（窗口没显示过）")
}

// MARK: - 5) NSWindowController

func probeWindowController() {
    print("")
    print("== NSWindowController ==")
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                          styleMask: [.titled, .closable], backing: .buffered, defer: false)
    window.title = "08 窗口"
    let controller = NSWindowController(window: window)
    expect(controller.window === window, "控制器持有同一个窗口对象")
    expect(controller.window?.title == "08 窗口", "能通过控制器读到标题")
    controller.windowFrameAutosaveName = "MainWindow"
    expect(controller.windowFrameAutosaveName == "MainWindow", "自动保存名用于下次启动时恢复位置")

    // 坑：控制器的 window 是 weak-ish 语义（其实是 strong，但 showWindow 之后
    // 窗口自己会被 window controller 表持有）。自测里调用 showWindow 会真的弹窗，
    // 所以这里只检查「控制器已就位」，GUI 模式下再显示。
}

// MARK: - 6) NSAlert 与 NSSavePanel

func probeAlertAndPanel() {
    print("")
    print("== NSAlert / NSSavePanel ==")
    let alert = NSAlert()
    alert.messageText = "要保存修改吗？"
    alert.informativeText = "关闭文档前需要确认。"
    alert.alertStyle = .warning
    alert.addButton(withTitle: "保存")
    alert.addButton(withTitle: "不保存")
    alert.addButton(withTitle: "取消")
    // 按钮顺序：第一个是默认按钮（有回车键等价），最后一个通常是「取消」
    let titles = alert.buttons.map { $0.title }
    print("  buttons = \(titles.joined(separator: " / "))")
    expect(titles.count == 3, "加了三个按钮")
    expect(titles == ["保存", "不保存", "取消"], "按钮顺序与添加顺序一致")
    expect(alert.buttons[0].keyEquivalent == "\r", "第一个按钮的快捷键是回车")
    expect(alert.alertStyle == .warning, "alertStyle 设为 warning")

    // NSSavePanel 只构造、不 run —— runModal 会真的弹系统面板
    let panel = NSSavePanel()
    panel.nameFieldStringValue = "untitled"
    // macOS 12 起用 UTType（UniformTypeIdentifiers）代替扩展名字符串，
    // 老写法 allowedFileTypes 已经废弃，编译会有告警。
    panel.allowedContentTypes = [.plainText]
    expect(panel.nameFieldStringValue == "untitled", "面板的初始文件名")
    expect(panel.allowedContentTypes.count == 1, "限制了允许的类型")
    expect(panel.allowedContentTypes.first?.identifier == "public.plain-text",
           "UTType 的标识符是 public.plain-text")
    // 坑：panel.prompt / message 这些文案是系统本地化的，自测里不要拿它们做断言，
    // 换了系统语言就会挂。
}

// MARK: - 应用委托

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        probeFrameGeometry()
        probeStyleMask()
        probeLevels()
        probeModalState()
        probeWindowController()
        probeAlertAndPanel()

        print("")
        print("== 窗口集合 ==")
        expect(NSApp.windows.isEmpty == false, "应用至少有一个窗口（系统也会建隐藏窗口）")

        if isSelfTest {
            print("==== 08 结束 ====")
            exit(failures == 0 ? 0 : 1)
        }

        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 360, height: 240),
                              styleMask: [.titled, .closable, .resizable],
                              backing: .buffered, defer: false)
        window.title = "08 窗口与模态"
        window.contentView = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 240))
        self.window = window
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

// MARK: - 启动

autoreleasepool {
    // 坑：不要用 NSApp。命令行进程里 NSApp 在 run() 之前还是空的，
    // 访问它会直接 SIGILL；要自己拿 NSApplication.shared 并持有它。
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate          // delegate 是 weak，必须用变量持有

    if isSelfTest {
        app.setActivationPolicy(.accessory)   // 连 Dock 图标都不出现
        stopRunLoop()
        app.run()
        // run() 正常返回说明上面的 exit() 没走到（不该发生）
        print("  FAIL run loop 结束后仍在执行")
        print("==== 08 结束 ====")
        exit(1)
    }

    app.setActivationPolicy(.regular)
    app.run()
}
