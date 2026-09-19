# 06 · Foundation（Swift 篇）：值语义、可选、Codable、桥接

> 示例：`examples/06_swift_foundation/main.swift`
> 实测输出见 `build/06_swift_foundation/stdout.debug.txt`

第 05 章讲的是 OC 侧的 Foundation。本章讲 **Swift 侧**：`String` / `Data` /
`Array` 是**值类型**，`NSString` / `NSData` / `NSArray` 是**引用类型**，
两者可以自由桥接，但桥接处有一堆「看起来一样其实不一样」的地方。

> Swift 的纯语言基础（可选、协议、泛型、闭包）见仓库的 `swift/` 教程，
> 这里只讲**与 Foundation / iOS 相关**的部分。iOS 上你还会天天遇到
> `UserDefaults`、plist、`Codable`（第 18 章），底下全是这套值类型。

## 1) String.count vs NSString.length：字符数不等于码元数

```swift
let text = "café"
let nsText = text as NSString           // 免费桥接
text.count        // 4  —— Swift 数的是「用户看到的字符」（grapheme cluster）
nsText.length     // 4  —— NSString 数的是 UTF-16 码元
```

`café` 里两种数法都是 4，看不出差别。换 emoji 就露馅了：

```swift
let emoji = "😀"
emoji.count                  // 1  —— 一个 emoji 是一个字符
(emoji as NSString).length   // 2  —— UTF-16 里是一个代理对（surrogate pair）

let flag = "🇨🇳"
flag.count                   // 1  —— 一面国旗是「一个字符」
(flag as NSString).length    // 4  —— 两个 regional indicator，各占 2 码元
```

实测：

```
-- String.count vs NSString.length --
  ok   Swift 的 count 是「用户看到的字符数」
  ok   NSString 的 length 是 UTF-16 码元数
  ok   emoji 在 Swift 里算 1 个字符（grapheme cluster）
  ok   同一个 emoji 在 NSString 里是 2 个码元（代理对）
  ok   国旗在 Swift 里仍是 1 个字符
  ok   国旗在 NSString 里是 4 个码元（两个 regional indicator）
```

> **坑**：`count` 和 `length` **不等价**。要按字符截取/遍历，用 Swift 的
> `text.count` 和 `text.indices`；要跟 OC API 或 `NSRange` 打交道，才用
> `NSString.length`。混用会算错位置（尤其含 emoji / 国旗 / 肤色修饰符时）。

## 2) Range 与 NSRange：两套下标，换算是有方向的

Swift 用 `Range<String.Index>`，OC 用 `NSRange`（location + length，基于 UTF-16）。
两者通过 `NSRange(_:in:)` 和 `Range(_:in:)` 换算，但**不对称**：

```swift
if let swiftRange = text.range(of: "fé") {
    let nsRange = NSRange(swiftRange, in: text)      // Range → NSRange 总能成功
    let backToSwift = Range(nsRange, in: text)        // NSRange → Range 可能返回 nil！
}

// 越界的 NSRange 转 Range 得到 nil，而不是崩溃
let badNS = NSRange(location: 0, length: 999)
Range(badNS, in: text)   // nil
```

实测：

```
-- Range 与 NSRange：两套下标 --
  ok   Range → NSRange 换算一致
  ok   NSRange → Range 在这个例子里成功
  ok   越界 NSRange 转 Range 得到 nil（不是崩溃）
```

- `Range → NSRange`：初始化器 `NSRange(_:in:)` **非可选**，一定成功。
- `NSRange → Range`：初始化器 `Range(_:in:)` **返回可选**。越界 / 落在码元中间
  都会得到 `nil`，不会崩溃——这是安全设计，但你必须解包。

## 3) Data 的值语义：写时复制

```swift
let data = Data([0x43, 0x6F, 0x63, 0x6F, 0x61])   // "Cocoa"，按字节计长度
var mutableData = data
mutableData.append(0x21)                            // 改的是副本
mutableData.count   // 6
data.count          // 5  —— 原值不受影响
```

实测：

```
-- Data 值语义 --
  ok   Data 按字节计长度
  ok   Data 追加不影响原值（写时复制）
  ok   Data 解回字符串
```

`Data` 是**结构体**，赋值即拷贝语义（底层写时复制，只有真正修改才复制缓冲）。
这与 OC 的 `NSData`（引用类型，赋值只增引用计数）根本不同。要可变，OC 得用
`NSMutableData`；Swift 只要 `var` 就行，没有 `MutableData` 这个类型。

## 4) Codable：Swift 原生的序列化

```swift
struct Settings: Codable, Equatable {
    var theme: String
    var fontSize: Int
    var recent: [String]
}
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]            // 要稳定输出必须开
let json = String(data: try! encoder.encode(settings), encoding: .utf8)!
// {"fontSize":13,"recent":["a.txt","b.txt"],"theme":"dark"}
```

实测：

```
-- Codable：Swift 原生序列化 --
  json = {"fontSize":13,"recent":["a.txt","b.txt"],"theme":"dark"}
  ok   sortedKeys 让输出可复现
  ok   解回来与原值相等
  ok   CodingKeys 把蛇形键映射成驼峰属性
  ok   ISO8601 策略输出可读日期
```

三个要点：

**（a）`sortedKeys`**：默认 JSON 键顺序不保证，输出会「随机」。要做可复现的输出
（快照测试、逐字节比对、缓存 key），**必须**开 `.sortedKeys`。本教程所有示例
都靠它才能双配置输出逐字节一致。

**（b）`CodingKeys`**：网络返回的 JSON 常是蛇形键（`user_id`），Swift 属性是驼峰
（`userId`）。用嵌套的 `CodingKeys` 枚举做映射：

```swift
struct User: Codable {
    var userId: Int
    var fullName: String
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case fullName = "full_name"
    }
}
```

**（c）日期策略**：`JSONEncoder` 默认把 `Date` 编成「自 2001 参考日期起的秒数」
（一个裸浮点数，不可读）。要可读的 ISO8601，设 `dateEncodingStrategy = .iso8601`：

```swift
let enc2 = JSONEncoder(); enc2.dateEncodingStrategy = .iso8601
// Date(timeIntervalSince1970: 1_700_000_000) → "2023-11-14T22:13:20Z"
```

## 5) 可选类型与 Foundation 的 nil

很多 Foundation API **返回可选**：找不到就是 `nil`，不是异常、不是崩溃。

```swift
let maybeInt = Int("42")     // Int? == 42
let notInt   = Int("abc")    // Int? == nil   （字符串转数字失败返回 nil）
let dict = ["a": 1]
dict["a"]                    // Optional(1)
dict["z"]                    // nil           （字典下标天然返回可选）
let name: String? = nil
name ?? "匿名"               // "匿名"        （?? 兜底）
```

实测：

```
-- 可选类型与 Foundation 的 nil --
  ok   Int(String) 失败返回 nil（可选）
  ok   字典下标返回 Optional
  ok   ?? 给可选兜底
```

> OC 的 `nil` 是「给 nil 发消息返回 0/nil，不崩溃」；Swift 的可选是**编译期强制**
> 你处理「可能没有值」。桥接时 OC 的 `nullable` → Swift `T?`，OC 未标注的 →
> `T!`（见第 07 章）。

## 6) == 与 ===：内容相等 vs 指针相同

```swift
let a = NSNumber(value: 1), b = NSNumber(value: 1)
a == b      // true  —— == 走 isEqual，比内容
a === b     // true?! —— 小整数 NSNumber 是 tagged pointer，其实是「同一个指针」
```

实测：

```
-- == 与 === --
  ok   == 走 isEqual，内容相同即相等
  ok   小整数 NSNumber 是 tagged pointer，=== 竟为真（别拿它判相等）
  ok   === 比指针：两个独立对象不相等
  ok   === 同一对象为真
  ok   Set 靠 hash + isEqual 去重
```

这里有个**反直觉的坑**：`NSNumber(value: 1)` 是 **tagged pointer**——小整数直接
编码在指针位里，不分配堆内存，所以两个「独立的」`NSNumber(value:1)` 底层是同一个
指针值，`===` 竟然为 `true`。

**结论**：`===` 只用于「是不是同一个对象」的身份判断，**绝不能用来判断内容相等**。
要演示真正的指针身份，用普通堆对象：

```swift
let o1 = NSObject(), o2 = NSObject()
o1 !== o2     // true —— 两个独立堆对象
o1 === o1     // true —— 同一个
```

`Set` / 字典 key 的去重靠 `hashValue` + `==`（底层是 `hash` + `isEqual:`），
所以 `Set([NSNumber(value:1), NSNumber(value:1)])` 只剩 1 个元素。

## 7) NotificationCenter：观察者要记得移除

```swift
let noteName = Notification.Name("demo")
let token = NotificationCenter.default.addObserver(forName: noteName, object: nil, queue: nil) { note in
    if let v = note.userInfo?["v"] as? String { received.append(v) }
}
NotificationCenter.default.post(name: noteName, object: nil, userInfo: ["v": "1"])
NotificationCenter.default.post(name: noteName, object: nil, userInfo: ["v": "2"])
NotificationCenter.default.removeObserver(token)
NotificationCenter.default.post(name: noteName, object: nil, userInfo: ["v": "3"])  // 收不到
// received == ["1", "2"]
```

实测：

```
-- NotificationCenter --
  ok   移除观察者之后就收不到通知了
```

`addObserver(forName:...)` 返回一个 **token**（不透明对象），移除时要拿它去
`removeObserver(token)`。iOS 9+ 的 block 版观察者在 dealloc 时不会自动失效，
**忘记移除 = 悬挂回调**。App 生命周期里 `UIApplication` 的一系列通知
（`didEnterBackgroundNotification` 等，第 03 章）就是靠它广播的。

## 8) URL 与 FileManager：临时目录要自清场

```swift
let fm = FileManager.default
let dir = fm.temporaryDirectory.appendingPathComponent("iosdev-06-\(UUID().uuidString)", isDirectory: true)
try! fm.createDirectory(at: dir, withIntermediateDirectories: true)
let fileURL = dir.appendingPathComponent("a.txt")
try! "hello".data(using: .utf8)!.write(to: fileURL)
let readBack = try! String(contentsOf: fileURL, encoding: .utf8)   // "hello"
fileURL.pathExtension   // "txt"
try! fm.removeItem(at: dir)   // 用完删掉
```

实测：

```
-- URL 与 FileManager --
  ok   文件写出来了
  ok   读回来内容一致
  ok   URL 有 pathExtension
  ok   临时目录已删除
```

要点：

- **`URL` 不是 `String`**：iOS 上文件 API 一律用 `URL`（`file://`），路径拼接用
  `appendingPathComponent`，不要手拼字符串。`path` 属性才是 POSIX 路径。
- **`temporaryDirectory`**：每个 App 沙盒有临时目录，系统会在 App 不运行时清理，
  但**别依赖它**——自己用完 `removeItem`。示例用 `UUID()` 命名避免并行跑撞车。
- `try!`：这些是「不该失败」的操作，示例里用 `try!` 让失败直接崩溃（暴露问题），
  生产代码要 `do/catch`。

## 坑清单

| 现象 | 原因 |
| --- | --- |
| emoji 字符串长度对不上 | `count`（字符）与 `NSString.length`（UTF-16 码元）不等价 |
| `NSRange → Range` 崩溃或漏解包 | `Range(_:in:)` 返回可选，越界得 `nil`，必须解包 |
| 改 `Data` 副本却「影响」了原值 | 你把 `let` 写成了引用类型 `NSData`；Swift `Data` 是值语义 |
| JSON 输出键顺序每次不同 | 没开 `JSONEncoder.outputFormatting = [.sortedKeys]` |
| 日期编出来是个裸浮点数 | 默认参考日期 2001；要可读设 `dateEncodingStrategy = .iso8601` |
| `NSNumber(value:1) === NSNumber(value:1)` 为真 | 小整数是 tagged pointer；`===` 不能判内容相等 |
| 通知回调「莫名」触发或崩溃 | 忘记 `removeObserver(token)` |

## 小结

- Swift 的 `String`/`Data`/`Array` 是**值类型**；`NSString`/`NSData`/`NSArray` 是
  引用类型；桥接免费但语义有别（`count` vs `length`、写时复制 vs `NSMutable*`）。
- `Range ↔ NSRange` 换算**不对称**：转 `NSRange` 必成功，转回 `Range` 可能 `nil`。
- `Codable` 是 Swift 原生序列化；要可复现输出必须 `.sortedKeys`；键名映射用
  `CodingKeys`；日期用 `.iso8601` 策略。
- `==` 比内容（`isEqual`），`===` 比指针身份——**tagged pointer 会让 `===` 骗你**。
- `NotificationCenter` 的 block 观察者要拿 token 手动移除；`FileManager` 临时目录
  要自清场。
