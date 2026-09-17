// ============================================================
// 02 - 第一个 AppKit 应用（纯代码，无 XIB）
//   NSApplication 生命周期 / NSWindow / NSView 层级 / target-action
//
// 编译：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name hello_appkit main.swift -o 02_hello_appkit \
//          -framework Foundation -framework AppKit
// 运行：
//   ./02_hello_appkit             # 显示窗口，直到你关闭它
//   ./02_hello_appkit --selftest  # 不显示窗口，只跑断言后退出（验证脚本用这个）
//
// AppKit 与 UIKit 最大的差别：Mac 上一个进程可以有任意多个窗口，
// 没有 WindowScene 那一层，窗口要自己创建、自己 retain、自己显示。
// ============================================================

import AppKit
import Foundation

// MARK: - 自测小框架（本教程所有 AppKit 示例都沿用这一套）

let isSelfTest = CommandLine.arguments.contains("--selftest")

var failures = 0

/// 打印一条「ok / FAIL」断言；失败时累计计数，最后决定退出码。
func expect(_ condition: Bool, _ description: String) {
    if condition {
        print("  ok   \(description)")
    } else {
        print("  FAIL \(description)")
        failures += 1
    }
}

/// 让 NSApplication 的 run loop 转一圈然后收工。
/// 注意两件事：① 只 stop 不住 —— run() 会卡在取下一个事件那里，
/// 必须再补投一个事件；② 不要用 terminate(nil)，那会直接 exit()，
/// 导致 run() 之后的代码（含结束标记）全部来不及执行。
func stopRunLoop(after seconds: Double = 0.05) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        NSApp.stop(nil)
        let synthetic = NSEvent.otherEvent(with: .applicationDefined,
                                           location: .zero,
                                           modifierFlags: [],
                                           timestamp: 0,
                                           windowNumber: 0,
                                           context: nil,
                                           subtype: 0,
                                           data1: 0,
                                           data2: 0)!
        NSApp.postEvent(synthetic, atStart: true)
    }
}

// MARK: - 视图层：把窗口内容搭出来（GUI 模式和自测模式共用同一段代码）

func makeContentView() -> NSView {
    let root = NSView(frame: NSRect(x: 0, y: 0, width: 360, height: 220))

    let label = NSTextField(labelWithString: "你好，macOS")
    label.frame = NSRect(x: 20, y: 160, width: 320, height: 24)
    label.font = .systemFont(ofSize: 20)

    let detail = NSTextField(labelWithString: "窗口是代码一行一行堆出来的")
    detail.frame = NSRect(x: 20, y: 132, width: 320, height: 16)

    let button = NSButton(title: "点我", target: nil, action: nil)
    button.frame = NSRect(x: 20, y: 60, width: 96, height: 32)
    button.bezelStyle = .rounded

    // AppKit 的坐标原点在左下角（UIKit 在左上角）。
    // 这也是从 iOS 转过来的人最容易写错坐标的地方。
    let hint = NSTextField(labelWithString: "AppKit 的 (0,0) 在左下角")
    hint.frame = NSRect(x: 20, y: 20, width: 320, height: 16)

    root.addSubview(label)
    root.addSubview(detail)
    root.addSubview(button)
    root.addSubview(hint)
    return root
}

func makeMainWindow() -> NSWindow {
    let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 360, height: 220),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered,
                          defer: false)
    window.title = "02 第一个 AppKit 应用"
    window.contentView = makeContentView()
    return window
}

// MARK: - 应用委托

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let window = makeMainWindow()
        self.window = window
        if isSelfTest {
            // 自测模式：建好了就行，绝不 orderFront —— 否则每次验证都会闪窗口。
            // setActivationPolicy(.accessory) 可以让进程连 Dock 图标都不出现。
            return
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

// MARK: - 启动

autoreleasepool {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate

    if isSelfTest {
        app.setActivationPolicy(.accessory)

        print("== 运行 AppKit run loop（不显示任何窗口）==")
        stopRunLoop()
        app.run()          // 真的跑一轮：applicationDidFinishLaunching 会在这里被调用

        guard let window = delegate.window else {
            print("  FAIL 委托没有建成窗口")
            print("==== 02 结束 ====")
            exit(1)
        }
        let root = window.contentView!
        expect(window.title == "02 第一个 AppKit 应用", "窗口标题已设置")
        expect(root.subviews.count == 4, "根视图有 4 个子视图（实际 \(root.subviews.count)）")
        expect(root.subviews[0] is NSTextField, "第一个子视图是 NSTextField")
        expect(root.subviews[2] is NSButton, "第三个子视图是 NSButton")
        expect(window.styleMask.contains(.closable), "窗口有关闭按钮")
        expect(window.styleMask.contains(.resizable), "窗口可缩放")
        expect(window.isVisible == false, "自测模式下窗口没有显示出来")

        let labels = root.subviews.compactMap { $0 as? NSTextField }.compactMap { $0.stringValue }
        expect(labels.count == 3, "三个标签都有文字")
        expect(labels.first == "你好，macOS", "首个标签文字正确")

        print("==== 02 结束 ====")
        exit(failures == 0 ? 0 : 1)
    }

    app.setActivationPolicy(.regular)
    app.run()
}
