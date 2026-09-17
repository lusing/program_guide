// ============================================================
// 19 - 菜单、状态栏与响应链的配合
//   NSMenu / NSMenuItem / 键等价 / 自动启用 / NSStatusItem
//
// 编译：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name menus main.swift -o 19_menus \
//          -framework Foundation -framework AppKit
// 运行：
//   ./19_menus --selftest
//
// macOS 的菜单栏不属于任何窗口 —— 它属于 NSApplication。
// 菜单项靠 target=nil + 响应链工作，这是「代码里看不见连线」的典型。
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

// 坑：全局的 NSApp 在 NSApplication.shared 被创建之前是 **nil**。
// Swift 里它是 NSApplication!（隐式解包可选），所以第一次直接用 NSApp.xxx
// 会是「Unexpectedly found nil」→ SIGILL，而且 stdout 上什么都没有，
// 极难查。任何示例的第一句都应该是 NSApplication.shared。
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// MARK: - 1) 菜单与菜单项

print("== NSMenu / NSMenuItem ==")

final class MenuTarget: NSObject {
    var newCount = 0
    var saveCount = 0

    @objc func newDocument(_ sender: Any?) { newCount += 1 }
    @objc func saveDocument(_ sender: Any?) { saveCount += 1 }
    @objc func deleteItem(_ sender: Any?) {}
}

let target = MenuTarget()

let fileMenu = NSMenu(title: "文件")
let newItem = NSMenuItem(title: "新建",
                         action: #selector(MenuTarget.newDocument(_:)),
                         keyEquivalent: "n")
newItem.keyEquivalentModifierMask = [.command]
newItem.target = target
fileMenu.addItem(newItem)

let saveItem = NSMenuItem(title: "保存",
                          action: #selector(MenuTarget.saveDocument(_:)),
                          keyEquivalent: "s")
saveItem.keyEquivalentModifierMask = [.command]
saveItem.target = target
fileMenu.addItem(saveItem)

fileMenu.addItem(NSMenuItem.separator())

expect(fileMenu.items.count == 3, "菜单里有三项（含分隔线）（实际 \(fileMenu.items.count)）")
expect(fileMenu.item(withTitle: "新建") === newItem, "按标题能找回菜单项")
expect(fileMenu.items[2].isSeparatorItem, "第三项是分隔线")
expect(newItem.keyEquivalent == "n", "键等价是 n")
expect(newItem.keyEquivalentModifierMask.contains(.command), "修饰键含 ⌘")

// 手动派发：菜单项自己就有 target/action，perform 走运行时派发
_ = target.perform(newItem.action, with: newItem)
expect(target.newCount == 1, "菜单项的 action 被调用了（实际 \(target.newCount)）")

// MARK: - 2) 子菜单

print("")
print("== 子菜单 ==")
let recentMenu = NSMenu(title: "最近打开")
recentMenu.addItem(withTitle: "a.txt", action: nil, keyEquivalent: "")
recentMenu.addItem(withTitle: "b.txt", action: nil, keyEquivalent: "")

let recentItem = NSMenuItem(title: "最近打开", action: nil, keyEquivalent: "")
recentItem.submenu = recentMenu
fileMenu.addItem(recentItem)

expect(recentItem.submenu === recentMenu, "submenu 指向子菜单")
expect(fileMenu.item(withTitle: "最近打开")?.submenu?.items.count == 2, "子菜单里有两项")
expect(recentItem.hasSubmenu, "hasSubmenu 为 true")
// 反向指针也有
expect(recentMenu.supermenu === fileMenu, "子菜单能找到自己的上级菜单")

// MARK: - 3) target 为 nil：交给响应链

print("")
print("== target = nil 与响应链 ==")
final class Document: NSResponder {
    var saved = 0
    @objc func saveDocument(_ sender: Any?) { saved += 1 }
}
let doc = Document()
let chainItem = NSMenuItem(title: "保存", action: #selector(Document.saveDocument(_:)), keyEquivalent: "s")
chainItem.target = nil      // ← 关键：交给响应链
expect(chainItem.target == nil, "菜单项的 target 是 nil")
// 手工模拟 AppKit 的自动启用：菜单项亮不亮取决于响应链上有没有人认领
expect(doc.responds(to: chainItem.action!), "响应链上的对象认领这个 selector")
expect(NSResponder().responds(to: chainItem.action!) == false, "随便一个对象不认领它")
_ = doc.perform(chainItem.action, with: chainItem)
expect(doc.saved == 1, "沿链找到的接收者被执行了")

// MARK: - 4) 应用主菜单

print("")
print("== 应用主菜单 ==")
// 主菜单不属于任何窗口，它挂在 NSApplication 上。
// 坑：命令行工具默认没有主菜单；给它设一个不会报错，但也不会显示。
let mainMenu = NSMenu(title: "主菜单")
let appItem = NSMenuItem(title: "应用", action: nil, keyEquivalent: "")
appItem.submenu = fileMenu
mainMenu.addItem(appItem)
NSApp.mainMenu = mainMenu

expect(app.mainMenu === mainMenu, "主菜单挂上了")
expect(app.mainMenu?.items.count == 1, "主菜单有一个顶层菜单")
expect(app.mainMenu?.item(at: 0)?.title == "应用", "第一项是「应用」菜单")

// 菜单的自动启用：靠 validateMenuItem / 响应链
// 这里只验证「没实现 validateMenuItem 时默认是启用」
expect(newItem.isEnabled, "菜单项默认启用")
newItem.isEnabled = false
expect(newItem.isEnabled == false, "可以手动禁用")
newItem.isEnabled = true

// MARK: - 5) 上下文菜单

print("")
print("== 上下文菜单 ==")
let view = NSView(frame: NSRect(x: 0, y: 0, width: 100, height: 50))
let contextMenu = NSMenu(title: "上下文")
contextMenu.addItem(withTitle: "删除", action: #selector(MenuTarget.deleteItem(_:)), keyEquivalent: "")
view.menu = contextMenu
expect(view.menu === contextMenu, "视图可以挂上下文菜单")
expect(view.menu?.items.count == 1, "上下文菜单有一项")
// 坑：NSView.menu 是 strong，不像 delegate 那样需要自己持有
expect(contextMenu.supermenu == nil, "上下文菜单没有上级菜单")

// MARK: - 6) 状态栏

print("")
print("== NSStatusItem ==")
let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
statusItem.button?.title = "M"
expect(statusItem.isVisible, "状态栏项默认可见")
expect(statusItem.statusBar === NSStatusBar.system, "它属于系统状态栏")
// 长度：squareLength 是固定值，variableLength 会随内容变
expect(statusItem.length == NSStatusItem.squareLength, "长度是 squareLength")
let variable = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
variable.length = 80
expect(variable.length == 80, "variableLength 可以改长度")
// 用完了要移除，否则图标一直留着
NSStatusBar.system.removeStatusItem(variable)
NSStatusBar.system.removeStatusItem(statusItem)

// MARK: - 7) 工具栏（只讲结构，不真的装进窗口）

print("")
print("== NSToolbar ==")
let toolbar = NSToolbar(identifier: "dev.macosdev.main")
toolbar.displayMode = .iconAndLabel
toolbar.allowsUserCustomization = true
toolbar.autosavesConfiguration = true
// 坑：NSToolbar.Identifier 是 String 的 typealias（不是 struct），
// 所以直接比字符串，没有 rawValue。
expect(toolbar.identifier == "dev.macosdev.main", "工具栏有标识符")
expect(toolbar.allowsUserCustomization, "允许用户自定义")
// 工具栏的 item 也是 target-action，同样可以 target=nil 走响应链
expect(toolbar.items.count == 0, "新工具栏没有 item")

print("==== 19 结束 ====")
exit(failures == 0 ? 0 : 1)
