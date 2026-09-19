# 13 · 富文本：NSAttributedString、字体度量与 TextKit

> 示例：`examples/13_attributed_text/main.swift`
> 实测输出见 `build/13_attributed_text/stdout.clt.txt`

macOS 的文本系统是 Cocoa 里最深的坑之一，也是它最强的地方。
本章覆盖三段：**属性串**、**字体度量**、**TextKit 三层结构**。

## 1) NSAttributedString

「字符串 + 按范围附加的属性」。

```swift
let attr = NSMutableAttributedString(string: "Hello Cocoa")
attr.addAttribute(.foregroundColor, value: NSColor.systemRed,
                  range: NSRange(location: 0, length: 5))
```

### 查询属性要拿 effectiveRange

```swift
var range = NSRange()
let color = attr.attribute(.foregroundColor, at: 0, effectiveRange: &range)
// color = NSColor.systemRed, range = {0, 5}
```

`effectiveRange` 告诉你「这个属性连续覆盖了多长」，
遍历属性串时靠它跳，而不是一个字符一个字符问。

实测：

```
== NSAttributedString ==
  length = 11
  ok   长度按 UTF-16 码元算（实际 11）
  ok   纯文本内容不变
  ok   第 0 位有前景色
  ok   第 0 位没有字体属性
  前景色作用范围 = {0, 5}
  ok   effectiveRange 给出属性连续的范围
```

> **坑**：`length` 是 **UTF-16 码元数**，和 `NSString` 一样（不是字符数）。
> 所有 range 都是 UTF-16 偏移。

### 属性对象是共享引用，不是副本

这是本章最反直觉的一条：

```swift
let paragraph = NSMutableParagraphStyle()
paragraph.lineSpacing = 6
styled.addAttribute(.paragraphStyle, value: paragraph, range: ...)
let readBack = styled.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle

paragraph.lineSpacing = 20
// readBack?.lineSpacing 现在也是 20 ！
```

实测：

```
  改原对象之前读回来 = 6.0
  改原对象之后读回来 = 20.0
  ok   属性串持有的是同一个对象（不是副本）
  ok   改原对象会连带改掉串里的样式
  ok   加进去之前先 copy 就不会被外面的改动带跑
```

正确做法：

```swift
styled.addAttribute(.paragraphStyle, value: paragraph.copy(), range: ...)
```

**所有可变属性对象**（`NSMutableParagraphStyle`、`NSMutableAttributedString`
作为属性时、`NSShadow`、`NSMutableDictionary`）都有这个问题。

## 2) 字体度量

```swift
let font = NSFont.systemFont(ofSize: 13)
font.ascender      //  12.6   基线上方
font.descender     //  -2.7   基线下方（负数）
font.capHeight     //   9.2   大写字母高度
font.leading       //   0.0   行间距
```

实测：

```
  systemFont 13: ascender=12.6 descender=-2.7 capHeight=9.2 leading=0.0
  ok   ascender 为正
  ok   descender 为负（基线以下）
  ok   capHeight 为正
  ok   ascender+descender 大于 capHeight
  行高 = 15.3
  ok   行高比字号大（实际 15.3）
```

排版时常用的量：

- **`ascender + descender + leading`** = 一行文字占的高度
- **`capHeight`** / **`xHeight`** = 用来对齐图标和文字
- 不要用 `pointSize` 当行高 —— 13 号字的行高是 15.3

字重转换：

```swift
let bold = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
// 字号不变
```

实测：

```
  ok   能转成粗体
  ok   转字重不改变字号
```

## 3) 量尺寸

```swift
let size = attr.boundingRect(with: NSSize(width: 1e6, height: 1e6),
                             options: [.usesLineFragmentOrigin, .usesFontLeading])
```

实测：

```
  单行需要 = 53.0 x 16.0
  ok   能量出尺寸
  ok   高度至少一行
  限宽 40 时 = 39.8 x 32.0
  ok   宽度不会超过限制（实际 39.8）
  ok   高度大于 0
```

> **坑**：`options` **必须**带 `.usesLineFragmentOrigin`，
> 否则多行文本只算第一行的宽度（这是个从 iOS 到 macOS 都存在的经典坑）。
>
> **坑**：量出来的**具体宽高会随系统字体版本漂移**。同一段文本限宽 40 时，
> 本机（macOS 14）最长行是 39.8，老系统上可能是 26.5 —— 换行点变了。
> 所以断言只判**性质**（「不超过限制」「高度大于 0」），绝不写死具体数字。
> 文档里印出的数值只是本机快照，换台机器/换个系统版本就对不上，属正常。

## 4) TextKit：三层结构

```
NSTextStorage   （NSMutableAttributedString 的子类，存内容）
    ↓ addLayoutManager
NSLayoutManager （排版：字符 → 字形，算位置）
    ↓ addTextContainer
NSTextContainer （几何：可用区域、形状）
    ↓
NSTextView      （真正画出来、处理输入）
```

示例手工搭了一遍：

```swift
let storage = NSTextStorage(string: "...")
let layout = NSLayoutManager()
storage.addLayoutManager(layout)
let container = NSTextContainer(size: NSSize(width: 200, height: 1e6))
layout.addTextContainer(container)
layout.glyphRange(for: container)     // 触发排版
layout.usedRect(for: container)       // 实际占用
```

实测：

```
== TextKit ==
  ok   NSTextStorage 挂着一个布局管理器
  ok   布局管理器挂着一个容器
  ok   布局管理器指回文本存储
  glyph 数 = 32, 字符数 = 32
  ok   触发排版后能拿到字形数
  ok   字形数不超过字符数（可能有连字）
  实际占用 = 195.3 x 34.0
  ok   能算出实际占用高度
  ok   宽度不超过容器
```

**一个 layout manager 可以挂多个 text container**（做多栏排版）；
**一个 text storage 可以挂多个 layout manager**（做「同一份内容两处显示」）。

`NSTextView` 自带这一整套：

```
  ok   NSTextView 里能读到字符串
  ok   自带布局管理器
  ok   自带文本容器
  ok   默认可编辑
  ok   默认支持富文本
```

## 5) RTF 往返

```swift
let rtf = attr.rtf(from: NSRange(location: 0, length: attr.length))
let back = NSAttributedString(rtf: rtf, documentAttributes: nil)
```

实测：

```
== RTF 往返 ==
  ok   能导出 RTF 数据
  ok   RTF 读回来的文字一致
  ok   长度也一致
  ok   读回来还带着字体属性
  ok   纯文本导出再读回一致
```

其他可用的文档格式：

- `rtf(from:)` / `rtfd(from:)`（带附件）
- `data(from:documentAttributes:)` 配 `.rtf` / `.html` / `.docFormat` / `.officeOpenXML`
- 读：`NSAttributedString(html:baseURL:documentAttributes:)`（macOS 12+）

## 6) 什么时候用什么

| 需求 | 用什么 |
| --- | --- |
| 只读标签，带一点颜色/字体 | `NSTextField` + `attributedStringValue` |
| 可编辑单行 | `NSTextField` |
| 可编辑多行、富文本、代码高亮 | `NSTextView`（+ TextKit） |
| 只要算尺寸、画到自定义 view 里 | `NSAttributedString` + `boundingRect` / `draw(in:)` |
| 复杂的排版（多栏、绕排） | TextKit 三层手工搭 |

> **坑**：`NSTextField` 也能显示属性串，但它的编辑能力和排版能力都很有限。
> 一旦要「富文本编辑」，直接上 `NSTextView`。

## 7) 坑清单

| 现象 | 原因 |
| --- | --- |
| 改了样式对象，界面全变了 | 属性串持有引用不 copy；加进去前先 `.copy()` |
| 多行文本量出来的宽度只有第一行 | `boundingRect` 没带 `.usesLineFragmentOrigin` |
| 中文/emoji 上 range 错位 | 所有 range 都是 UTF-16 偏移 |
| 行高不对 | 用 `ascender+descender+leading`，不是 `pointSize` |
| `NSTextView` 排版没更新 | 改了 textStorage 会自动触发；改了 container.size 要手动 |
| RTF 读回来属性丢了 | 属性不是 RTF 支持的（比如自定义 key） |

## 小结

- 属性串的 range 全是 UTF-16 偏移；查询属性要用 `effectiveRange` 跳。
- **属性对象是共享引用** —— 加进去前 `.copy()`。
- 行高 = `ascender + descender + leading`，不是 `pointSize`。
- TextKit 是 storage → layout manager → container → view 四层。
- `boundingRect` 一定要带 `.usesLineFragmentOrigin`。
