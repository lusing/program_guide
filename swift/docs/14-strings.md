# 14 · 字符串

> 对应示例：`examples/14_strings/`

## 14.1 String 的三层解剖

```swift
let cafeA = "cafe\u{301}"     // e + 组合音符 U+0301 —— 两个 Unicode 标量
let cafeB = "café"            // 预组合 é（U+00E9）—— 一个标量

cafeA.utf8.count              // 6 —— UTF-8 视图（字节）
cafeB.utf8.count              // 5 —— 字节不同！
cafeA.count                   // 4 —— Character 视图（字位）
cafeB.count                   // 4
cafeA == cafeB                // true —— 规范等价
cafeA.unicodeScalars.count    // 5 —— 标量视图
```

Swift 字符串三层视图，各答各的问题：

| 视图 | 单位 | 用途 | 访问 |
|---|---|---|---|
| `Character`（字位/grapheme cluster） | 用户感知的字 | 展示、count、遍历 | 默认（`for c in s`） |
| `unicodeScalars` | Unicode 标量 | 精确码点处理 | `s.unicodeScalars` |
| `utf8` / `utf16` | 编码单元 | IO、网络、文件 | `s.utf8` |

**`count` 数的是 Character（字位）**，不是字节不是码点——这是 Swift 与 C 系字符串的
根本分野。`"👨‍👩‍👧‍👦".count == 1`（一家四口是一个字位，7 个标量，25 个 UTF-8 字节）、
`"🇨🇳🇯🇵".count == 2`。emoji、重音、中日韩兼容字全部正确——因为比较与计数都按
Unicode 规范等价做（示例的 cafeA == cafeB 实测通过）。

## 14.2 String.Index：为什么下标不能用 Int

```swift
let poem = "海内存知己"
let second = poem.index(poem.startIndex, offsetBy: 1)
poem[second]                          // 内
poem[1]                               // ❌ 编译错误：下标是 String.Index 不是 Int
let range = second..<poem.index(second, offsetBy: 2)
poem[range]                           // 内存
```

第 N 个**字节**和第 N 个**字位**不是一回事（变长编码 + 组合标量），"O(1) 按整数取
字位"在 Unicode 字符串上不存在。Swift 的答案：下标是 `String.Index`（不透明），跳
到目标位置必须走 `index(_:offsetBy:)`——O(n) 但正确。

惯用法备忘：

```swift
s.index(s.startIndex, offsetBy: 2)      // 跳 2 个字位
s.first / s.last                        // Optional<Character>
s.prefix(3) / s.suffix(2) / s.dropFirst(1)   // Substring
Array(s)                                // [Character]——要随机访问先转数组
s.indices                               // 所有合法下标（遍历用）
```

高频下标场景（解析器、算法题）：**开头就 `Array(s)` 或 `s.map { $0 }`**，按数组
做，最后再 `String(result)` 拼回。

## 14.3 Substring：零拷贝视图，用完即弃

```swift
let sentence = "Swift 字符串是值类型，但切片是视图"
let firstPart = sentence.prefix(5)    // Substring：共享原串缓冲
firstPart == "Swift"                  // true（当 String 比较都行）
String(firstPart)                     // 转正：O(n) 拷贝，此后独立
```

`prefix`/`suffix`/切片/range 访问返回 **Substring**——原字符串的视图（内存共享），
大多数 String API 都能用。纪律（官方 API guidelines 同款）：

- **短期局部用**：Substring 直接用（省一次拷贝）；
- **长期存储/跨作用域**：`String(substring)` 转正——视图会延长原串整个缓冲的
  生命周期（取 5 个字握住 5MB 的锅）。

## 14.4 多行与原始字符串

```swift
let multi = """
    第一行
    第二行缩进由结尾引号裁剪
    """

let raw = #"路径 "C:\tools" 里有 \d 个转义"#      // \d 原样、内嵌引号免转义
let interpolated = #"插值要写 \#(name)"#           // 原始串里插值是 \#(...)
```

三引号支持换行（结尾引号的缩进 = 裁剪基准）；`#"..."#` 里反斜杠不转义——正则、
Windows 路径、JSON 片段的救星。更多 `#`（`##"..."##`）处理嵌套 `"#`。

## 14.5 常用 API 与教学函数

```swift
s.hasPrefix("Swift") / s.hasSuffix("字符串")
s.uppercased() / s.lowercased()
s.split(separator: " ")            // [Substring]（注意不是 [String]）
s.contains("字") / s.isEmpty
s.replacingOccurrences(of: "a", with: "b")        // Foundation
s.trimmingCharacters(in: .whitespaces)            // Foundation
String(format: "%02X", 255)        // Foundation 的 printf 风格（03 章用过）
```

示例的三个教学函数（回文判断 / 姓名缩写 / 截断加省略号）覆盖了 filter、split、
compactMap、prefix 的组合使用。

## 14.6 Regex：Swift 5.7 的字面量正则

```swift
let contact = "电话 010-88886666，邮编 100101，年份 2024年"

contact.firstMatch(of: /\d{3}-\d{8}/)             // Regex.Match?
contact.matches(of: /\d+/).count                  // 全部匹配
let years = contact.matches(of: /(\d{4})年/).compactMap { Int($0.1) }   // [2024]

if let dynamic = try? Regex("[0-9]+") { ... }     // 运行期编译（字符串来源）
```

`/pattern/` 字面量是**编译期检查**的正则——语法错误编译就报，捕获组有类型化下标
（`$0.1` 是第一组）。运行期才知道模式时用 `Regex("...")` + try。注意匹配 API 挂在
**字符串一侧**（`text.matches(of:)` / `text.firstMatch(of:)`）——`Regex` 对象自身
没有 `matches(in:)`（实测坑）。中文与 `\d` 等字符类配合良好；注意模式里的空格是
字面空格（"2024 年"匹配不上 `(\d{4})年`——实测）。

## 14.7 与 C/C++ 互操作预告

String 不是 NUL 结尾字节串：跨 C 边界时 `s.utf8` 视图 + 手动补 NUL，或 Foundation
桥接（23 章实操）。

## 14.8 坑位清单（含实测）

1. **`count` ≠ 字节数**：`"🇨🇳".count == 1` 但 utf8 8 字节——所有"长度"先问自己
   要哪一层。
2. **下标是 String.Index 不是 Int**（编译器拦你）；高频下标场景先 `Array(s)`。
3. **`split` 返回 [Substring]**：要 `[String]` 记得 `map(String.init)`——否则存进
   属性时带着原串整个缓冲跑（14.3 纪律）。
4. **Regex 匹配 API 在字符串一侧**（实测）：`Regex` 对象没有 `matches(in:)`，用
   `text.matches(of: regex)` / `text.firstMatch(of:)`。
5. **正则模式里的空格是字面空格**（实测）：`(\d{4})年` 匹配 "2024 年" 失败——
   模式与文本的空格要一致，或模式用 `\s*`。
6. **组合字符的字面量不可见**：源码里直接敲 `"cafe"`（带组合音符）肉眼看不出——
   教学与测试都写显式转义 `"cafe\u{301}"`，自文档且不依赖编辑器。
7. **中文字符串比较/排序按 Unicode 标量序**（10 章实测的回响）：拼音序/笔画序要
   自定义排序器（Foundation 的 `localizedStandardCompare` 走 locale，服务器端慎依赖）。

上一章：[13 · 集合](13-collections.md) ｜ 下一章：[15 · 扩展与下标](15-extensions.md) ｜ 返回：[README](../README.md)
