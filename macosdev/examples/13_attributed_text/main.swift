// ============================================================
// 13 - 富文本：NSAttributedString 与 TextKit
//   属性串 / 段落样式 / 字体度量 / NSTextStorage + NSLayoutManager + NSTextContainer
//
// 编译：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name attributed_text main.swift -o 13_attributed_text \
//          -framework Foundation -framework AppKit
// 运行：
//   ./13_attributed_text
//
// macOS 的文本系统是 Cocoa 里最完整的一块：
//   NSTextStorage（存字符串和属性）
//     → NSLayoutManager（排版成字形、算行片段）
//       → NSTextContainer（决定排版区域）
//         → NSTextView（显示与编辑）
// 这三层可以拆开单独用，做「离屏量文字高度」这类事情非常方便。
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

// MARK: - 1) 属性串基本操作

print("== NSAttributedString ==")
let text = "Hello Cocoa"
let attributed = NSMutableAttributedString(string: text)
attributed.addAttribute(.foregroundColor, value: NSColor.systemBlue,
                        range: NSRange(location: 0, length: 5))
attributed.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 14),
                        range: NSRange(location: 6, length: 5))
print("  length = \(attributed.length)")
expect(attributed.length == text.utf16.count, "长度按 UTF-16 码元算（实际 \(attributed.length)）")
expect(attributed.string == "Hello Cocoa", "纯文本内容不变")

// 取某一位上的属性
let attrsAt0 = attributed.attributes(at: 0, effectiveRange: nil)
expect(attrsAt0[.foregroundColor] != nil, "第 0 位有前景色")
expect(attrsAt0[.font] == nil, "第 0 位没有字体属性")

var effective = NSRange()
_ = attributed.attributes(at: 0, effectiveRange: &effective)
print("  前景色作用范围 = \(effective)")
expect(effective.location == 0 && effective.length == 5, "effectiveRange 给出属性连续的范围")

// 遍历某一种属性
var ranges: [NSRange] = []
attributed.enumerateAttribute(.foregroundColor, in: NSRange(location: 0, length: attributed.length)) { value, range, _ in
    if value != nil { ranges.append(range) }
}
expect(ranges.count == 1, "整串只有一处前景色（实际 \(ranges.count)）")

// 拼接
let tail = NSAttributedString(string: "!")
attributed.append(tail)
expect(attributed.string == "Hello Cocoa!", "append 之后内容变长")
expect(attributed.length == 12, "长度也跟着变（实际 \(attributed.length)）")

// MARK: - 2) 段落样式

print("")
print("== 段落样式 ==")
let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
paragraph.lineSpacing = 6
paragraph.firstLineHeadIndent = 12
paragraph.lineBreakMode = .byWordWrapping
expect(paragraph.alignment == .center, "居中对齐")
expect(paragraph.lineSpacing == 6, "行距 6")

let styled = NSMutableAttributedString(string: "带段落样式的文本")
styled.addAttribute(.paragraphStyle, value: paragraph,
                    range: NSRange(location: 0, length: styled.length))
let readBack = styled.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
expect(readBack?.alignment == .center, "段落样式能读回来")
expect(readBack?.lineSpacing == 6, "行距也能读回来")

// 坑：段落样式是**对象**，NSAttributedString 只持有引用，**不会** copy。
// 所以改了原对象，串里的样式跟着变 —— 这是共享可变状态，最容易出诡异 bug。
print("  改原对象之前读回来 = \(readBack?.lineSpacing ?? -1)")
paragraph.lineSpacing = 20
print("  改原对象之后读回来 = \(readBack?.lineSpacing ?? -1)")
expect(readBack === paragraph, "属性串持有的是同一个对象（不是副本）")
expect(readBack?.lineSpacing == 20, "改原对象会连带改掉串里的样式")

// 正确做法：加进去之前先 copy 一份，或者改完再重新 addAttribute
let safeParagraph = NSMutableParagraphStyle()
safeParagraph.lineSpacing = 6
let safeStyled = NSMutableAttributedString(
    string: "安全写法", attributes: [.paragraphStyle: safeParagraph.copy()])
safeParagraph.lineSpacing = 20
let safeRead = safeStyled.attribute(.paragraphStyle, at: 0,
                                    effectiveRange: nil) as? NSParagraphStyle
expect(safeRead?.lineSpacing == 6, "加进去之前先 copy 就不会被外面的改动带跑")

// MARK: - 3) 字体度量

print("")
print("== 字体度量 ==")
let font = NSFont.systemFont(ofSize: 13)
print("  systemFont 13: ascender=\(round(font.ascender * 10) / 10) "
    + "descender=\(round(font.descender * 10) / 10) "
    + "capHeight=\(round(font.capHeight * 10) / 10) "
    + "leading=\(round(font.leading * 10) / 10)")
expect(font.ascender > 0, "ascender 为正")
expect(font.descender < 0, "descender 为负（基线以下）")
expect(font.capHeight > 0, "capHeight 为正")
expect(font.ascender + (-font.descender) > font.capHeight, "ascender+descender 大于 capHeight")
// 行高 = ascender - descender + leading
let lineHeight = font.ascender - font.descender + font.leading
print("  行高 = \(round(lineHeight * 10) / 10)")
expect(lineHeight > font.pointSize, "行高比字号大（实际 \(round(lineHeight * 10) / 10)）")

// 字重与斜体：通过 NSFontManager 转换
let bold = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
expect(NSFontManager.shared.traits(of: bold).contains(.boldFontMask), "能转成粗体")
expect(bold.pointSize == font.pointSize, "转字重不改变字号")

// 坑：字体相关的数值（度量、宽度）都跟着系统字体走。
// 断言里只写「性质」（> 0、谁比谁大），别写死数字，否则换台机器就挂。

// MARK: - 4) 量文字尺寸

print("")
print("== 量尺寸 ==")
let measured = NSAttributedString(string: "一行文字", attributes: [.font: font])
let needed = measured.size()
print("  单行需要 = \(round(needed.width * 10) / 10) x \(round(needed.height * 10) / 10)")
expect(needed.width > 0 && needed.height > 0, "能量出尺寸")
expect(needed.height >= lineHeight, "高度至少一行")

// 给定宽度算需要多高
let bounding = measured.boundingRect(with: NSSize(width: 40, height: 1000),
                                     options: [.usesLineFragmentOrigin, .usesFontLeading])
print("  限宽 40 时 = \(round(bounding.width * 10) / 10) x \(round(bounding.height * 10) / 10)")
expect(bounding.width <= 40, "宽度不会超过限制（实际 \(round(bounding.width * 10) / 10)）")
expect(bounding.height > 0, "高度大于 0")

// MARK: - 5) TextKit 三件套

print("")
print("== TextKit ==")
let container = NSTextContainer(size: NSSize(width: 200, height: 1000))
container.lineFragmentPadding = 0
let layoutManager = NSLayoutManager()
layoutManager.addTextContainer(container)
let storage = NSTextStorage(string: "TextKit 由三个对象组成：文本存储、布局管理器、文本容器。")
storage.addLayoutManager(layoutManager)

expect(storage.layoutManagers.count == 1, "NSTextStorage 挂着一个布局管理器")
expect(layoutManager.textContainers.count == 1, "布局管理器挂着一个容器")
expect(layoutManager.textStorage === storage, "布局管理器指回文本存储")

// 排版是懒的：不显式触发，glyph 数就是 0
let glyphRange = layoutManager.glyphRange(for: container)
print("  glyph 数 = \(glyphRange.length), 字符数 = \(storage.length)")
expect(glyphRange.length > 0, "触发排版后能拿到字形数")
expect(glyphRange.length <= storage.length, "字形数不超过字符数（可能有连字）")

let used = layoutManager.usedRect(for: container)
print("  实际占用 = \(round(used.width * 10) / 10) x \(round(used.height * 10) / 10)")
expect(used.height > 0, "能算出实际占用高度")
expect(used.width <= container.size.width, "宽度不超过容器")

// NSTextView 把三件套包起来
let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 200, height: 100))
textView.textStorage?.setAttributedString(measured)
expect(textView.string == "一行文字", "NSTextView 里能读到字符串")
expect(textView.textStorage?.length == 4, "文本存储长度正确")
expect(textView.layoutManager != nil, "自带布局管理器")
expect(textView.textContainer != nil, "自带文本容器")
expect(textView.isEditable, "默认可编辑")
expect(textView.isRichText, "默认支持富文本")

// MARK: - 6) 序列化

print("")
print("== RTF 往返 ==")
let rich = NSMutableAttributedString(string: "加粗的一段")
rich.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 12),
                  range: NSRange(location: 0, length: rich.length))
let rtfData = rich.rtf(from: NSRange(location: 0, length: rich.length), documentAttributes: [:])
expect(rtfData != nil, "能导出 RTF 数据")
if let data = rtfData {
    let restored = NSAttributedString(rtf: data, documentAttributes: nil)
    expect(restored?.string == "加粗的一段", "RTF 读回来的文字一致")
    expect((restored?.length ?? 0) == rich.length, "长度也一致")
    expect(restored?.attribute(.font, at: 0, effectiveRange: nil) != nil, "读回来还带着字体属性")
}

// 纯文本往返
let plainData = rich.string.data(using: .utf8)!
expect(String(data: plainData, encoding: .utf8) == "加粗的一段", "纯文本导出再读回一致")

print("==== 13 结束 ====")
exit(failures == 0 ? 0 : 1)
