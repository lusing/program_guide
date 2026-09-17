// ============================================================
// 10 - 常用控件与 target-action
//   NSButton（各种类型）/ NSTextField / NSPopUpButton / NSSegmentedControl
//   / NSSlider / NSStepper / NSProgressIndicator / NSImageView / NSComboBox
//
// 编译：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name controls main.swift -o 10_controls \
//          -framework Foundation -framework AppKit
// 运行：
//   ./10_controls
//
// AppKit 的控件比 UIKit 老派得多：它们继承自 NSControl，内部大多还包着一个
// NSCell（早年的「轻量复用」设计）。所以你会看到 title/stringValue 这类
// 「控件一层、cell 一层」的双份属性 —— 新代码只操作控件这一层就行。
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

/// 模拟一次控件点击：直接把 action 发给 target。
/// 坑：不能用 NSApp.sendAction / control.sendAction —— 那两个要走 NSApplication
/// 的事件派发，命令行进程里会崩。这里用 NSObject.perform 走纯运行时派发。
func fire(_ control: NSControl) -> Bool {
    guard let action = control.action, let target = control.target else { return false }
    _ = target.perform(action, with: control)
    return true
}

// MARK: - 1) NSButton 的几种形态

print("== NSButton ==")
let push = NSButton(title: "确定", target: nil, action: nil)
push.bezelStyle = .rounded
push.frame = NSRect(x: 0, y: 0, width: 96, height: 32)
print("  bezelStyle = \(push.bezelStyle.rawValue), title = \(push.title)")
expect(push.title == "确定", "按钮标题")
expect(push.bezelStyle == .rounded, "圆角样式")
expect(push.image == nil, "默认没有图标")
expect(push.cell is NSButtonCell, "NSButton 内部还是 NSButtonCell")

// 勾选项：setButtonType 决定它长什么样、state 怎么循环
let checkbox = NSButton(checkboxWithTitle: "自动保存", target: nil, action: nil)
expect(checkbox.state == .off, "勾选框初始是 off")
checkbox.state = .on
expect(checkbox.state == .on, "可以设成 on")
expect(checkbox.state.rawValue == 1, "on 的 rawValue 是 1")

// 开关（macOS 11 之后也有独立的 NSSwitch 类，老代码都用 setButtonType）
let toggle = NSButton(frame: .zero)
toggle.setButtonType(.switch)
toggle.title = "深色模式"
toggle.state = .on
expect(toggle.state == .on, "switch 型按钮也能设状态")

// 单选按钮：同一个父视图里、同一个 action 的一组 radio 才会互斥
let radio = NSButton(radioButtonWithTitle: "选项 A", target: nil, action: nil)
expect(radio.state == .off, "单选按钮初始未选中")
radio.state = .on
expect(radio.state == .on, "选中后 state 变 on")

// 键等价：给按钮设快捷键
push.keyEquivalent = "\r"
expect(push.keyEquivalent == "\r", "回车可以设成按钮的键等价")
let escButton = NSButton(title: "取消", target: nil, action: nil)
escButton.keyEquivalent = "\u{1b}"
expect(escButton.keyEquivalent == "\u{1b}", "Esc 也能设")

// MARK: - 2) target-action 真的能跑起来

print("")
print("== target-action ==")
final class ClickSink: NSObject {
    var hits: [String] = []
    @objc func buttonClicked(_ sender: NSButton) {
        hits.append(sender.title)
    }
}
let sink = ClickSink()
let action = NSButton(title: "点我", target: sink, action: #selector(ClickSink.buttonClicked(_:)))
expect(action.target === sink, "target 就是接收者")
expect(action.action == #selector(ClickSink.buttonClicked(_:)), "action 是 selector")
expect(fire(action), "手动派发成功")
expect(sink.hits == ["点我"], "方法被调用，参数带上了控件本身（实际 \(sink.hits)）")
_ = fire(action)
expect(sink.hits.count == 2, "再点一次再记一次")

// 把 target 设成 nil 就变成「沿响应链找」，这是菜单项和工具栏按钮的常见写法
let chainButton = NSButton(title: "链", target: nil, action: #selector(ClickSink.buttonClicked(_:)))
expect(chainButton.target == nil, "target 为 nil 时会走响应链")

// MARK: - 3) NSTextField

print("")
print("== NSTextField ==")
// labelWithString 出来的标签：不可编辑、不接收焦点、背景透明
let title = NSTextField(labelWithString: "标题")
expect(title.isEditable == false, "labelWithString 出来的不可编辑")
expect(title.isBezeled == false, "没有边框")
expect(title.drawsBackground == false, "不画背景")

let input = NSTextField(string: "可编辑")
input.isEditable = true
input.isBezeled = true
input.placeholderString = "请输入"
expect(input.isEditable, "普通 NSTextField 可以编辑")
expect(input.isBezeled, "带边框")
expect(input.placeholderString == "请输入", "有占位文字")
input.stringValue = "改过了"
expect(input.stringValue == "改过了", "stringValue 就是内容")

// 多行文本用 NSTextView（包在 NSScrollView 里），NSTextField 只有一行
expect(input.cell?.wraps == false, "NSTextField 默认不换行")
expect(input.cell?.isScrollable == true, "超出宽度时滚动而不是换行")

// MARK: - 4) NSPopUpButton

print("")
print("== NSPopUpButton ==")
let popup = NSPopUpButton(frame: .zero)
popup.addItems(withTitles: ["小", "中", "大"])
popup.selectItem(at: 1)
let titles = popup.itemTitles
print("  items = \(titles.joined(separator: " / "))")
expect(titles == ["小", "中", "大"], "三个选项按添加顺序排列")
expect(popup.indexOfSelectedItem == 1, "选中第 1 项")
expect(popup.titleOfSelectedItem == "中", "选中项的标题是「中」")
expect(popup.numberOfItems == 3, "共 3 项")
popup.selectItem(withTitle: "大")
expect(popup.indexOfSelectedItem == 2, "按标题也能选中")

// MARK: - 5) NSSegmentedControl

print("")
print("== NSSegmentedControl ==")
let segmented = NSSegmentedControl(labels: ["列表", "图标", "分栏"],
                                   trackingMode: .selectOne,
                                   target: nil, action: nil)
segmented.selectedSegment = 0
print("  segments = \(segmented.segmentCount), selected = \(segmented.selectedSegment)")
expect(segmented.segmentCount == 3, "三个分段")
expect(segmented.selectedSegment == 0, "选中第一个")
expect(segmented.label(forSegment: 2) == "分栏", "能读回文字")
segmented.setWidth(80, forSegment: 0)
expect(segmented.width(forSegment: 0) == 80, "可以单独设每段的宽度")
expect(segmented.trackingMode == .selectOne, "单选模式")
segmented.setEnabled(false, forSegment: 2)
expect(segmented.isEnabled(forSegment: 2) == false, "可以禁用某一段")

// MARK: - 6) NSSlider / NSStepper / NSProgressIndicator

print("")
print("== 数值控件 ==")
let slider = NSSlider(value: 50, minValue: 0, maxValue: 100, target: nil, action: nil)
expect(slider.doubleValue == 50, "滑块初值 50")
expect(slider.minValue == 0 && slider.maxValue == 100, "范围 0...100")
slider.doubleValue = 75
expect(slider.doubleValue == 75, "设值后能读回")
slider.numberOfTickMarks = 5
expect(slider.numberOfTickMarks == 5, "可以加刻度")
slider.allowsTickMarkValuesOnly = true
expect(slider.allowsTickMarkValuesOnly, "吸附到刻度")
// 坑：allowsTickMarkValuesOnly 只影响交互，手工 doubleValue 不会被吸附
expect(slider.doubleValue == 75, "手工设的值不会被刻度吸附（75 不在 25/50/75 之外？）")

let stepper = NSStepper(frame: .zero)
stepper.minValue = 0
stepper.maxValue = 10
stepper.increment = 2
stepper.intValue = 4
expect(stepper.intValue == 4, "步进器初值 4")
expect(stepper.increment == 2, "每次加 2")
stepper.intValue = 0
// 坑：NSStepper 的 minValue/maxValue 是 Double，intValue 是 Int32 ——
// 直接比会编译不过，要自己转一次类型。
expect(Double(stepper.intValue) >= stepper.minValue
       && Double(stepper.intValue) <= stepper.maxValue,
       "值始终被夹在 min/max 之间")

let spinner = NSProgressIndicator(frame: .zero)
spinner.style = .spinning
spinner.startAnimation(nil)
expect(spinner.isIndeterminate, "旋转指示器是不确定进度")
expect(spinner.style == .spinning, "样式是 spinning")

let bar = NSProgressIndicator(frame: .zero)
bar.style = .bar
bar.minValue = 0
bar.maxValue = 100
bar.doubleValue = 40
bar.isIndeterminate = false
expect(bar.isIndeterminate == false, "进度条是确定进度")
expect(bar.doubleValue == 40, "进度 40")

// MARK: - 7) NSImageView / NSComboBox

print("")
print("== NSImageView / NSComboBox ==")
let imageView = NSImageView(frame: NSRect(x: 0, y: 0, width: 48, height: 48))
imageView.imageScaling = .scaleProportionallyUpOrDown
if let symbol = NSImage(systemSymbolName: "folder", accessibilityDescription: nil) {
    imageView.image = symbol
    expect(imageView.image != nil, "SF Symbol 可以直接当图片用")
    expect(symbol.isTemplate, "SF Symbol 默认是模板图（跟随系统色调）")
} else {
    expect(false, "拿不到 SF Symbol")
}
expect(imageView.imageScaling == .scaleProportionallyUpOrDown, "缩放模式已设置")

let combo = NSComboBox(frame: .zero)
combo.addItems(withObjectValues: ["Swift", "Objective-C", "C"])
combo.numberOfVisibleItems = 5
expect(combo.numberOfItems == 3, "下拉列表有 3 项")
expect(combo.numberOfVisibleItems == 5, "最多显示 5 行")
expect(combo.usesDataSource == false, "默认用内部列表，不走 dataSource")
combo.stringValue = "Swift"
expect(combo.stringValue == "Swift", "输入框内容可读写")

// MARK: - 8) 通用状态

print("")
print("== 通用属性 ==")
let disabled = NSButton(title: "禁用", target: nil, action: nil)
disabled.isEnabled = false
expect(disabled.isEnabled == false, "禁用的控件不响应点击")
disabled.toolTip = "暂时不可用"
expect(disabled.toolTip == "暂时不可用", "tooltip 就是鼠标悬停提示")
let sized = NSButton(title: "尺寸", target: nil, action: nil)
sized.frame = NSRect(x: 0, y: 0, width: 100, height: 24)
expect(sized.frame.size == NSSize(width: 100, height: 24), "frame 还是那套")

print("==== 10 结束 ====")
exit(failures == 0 ? 0 : 1)
