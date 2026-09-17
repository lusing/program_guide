# 06 · Foundation（Swift 篇）：桥接、Codable、值语义

> 示例：`examples/06_swift_foundation/main.swift`
> 实测输出见 `build/06_swift_foundation/stdout.clt.txt`

Swift 的 `String` / `Data` / `Array` 是**值类型**，`NSString` / `NSData` /
`NSArray` 是**引用类型**。两者可以自由桥接，但桥接处有一堆「看起来一样其实不一样」的地方。
本章把这些地方列清楚。

## 1) String ↔ NSString

```swift
let text = "café"
let nsText = text as NSString
text.count        // 4 —— 用户看到的字符数（grapheme cluster）
nsText.length     // 4 —— UTF-16 码元数
```

两者**大部分时候一样，emoji 上分道扬镳**：

```
  ok   Swift 的 count 是「用户看到的字符数」（实际 4）
  ok   NSString 的 length 是 UTF-16 码元数（实际 4）
  ok   emoji 在 Swift 里算 1 个字符
  ok   同一个 emoji 在 NSString 里是 2 个码元（代理对）
  ok   国旗在 Swift 里仍是 1 个字符
  ok   国旗在 NSString 里是 4 个码元
```

`😀` 在 Swift 里 1 个字符，NSString 里 2 个码元；
`🇨🇳`（两个 regional indicator）Swift 里 1 个，NSString 里 4 个。

**规则**：`String.count` 是 O(n) 的（要遍历），不是 O(1)。
不要写 `for i in 0..<str.count { str[i] }` —— 那是 O(n²)。
要么用 `for ch in str`，要么把 index 缓存起来。

### Range 与 NSRange：两套下标

```swift
let swiftRange = text.range(of: "fé")     // Range<String.Index>?
let nsRange    = nsText.range(of: "fé")   // NSRange，location 是 UTF-16 偏移
```

转换必须用专门的构造器：

```swift
let backToNS = NSRange(swiftRange, in: text)      // 总能成功
let backToSwift = Range(nsRange, in: text)        // 可能 nil！
```

`NSRange → Range` 会失败，因为 NSRange 的边界可能落在**代理对中间**。

实测：

```
  ok   Swift 的 range(of:) 找到了子串
  ok   NSString 的 range(of:) 给的是 NSRange
  ok   Range → NSRange 换算一致
  ok   NSRange → Range 在这个例子里成功
  ok   越界 NSRange 转 Range 得到 nil（不是崩溃）
```

> **坑**：`NSRegularExpression` / `NSTextStorage` / `NSTextView` 全用 `NSRange`。
> 一旦和 Swift 的 `String.Index` 混用，多字节字符上必然错位。
> **在 NSRange 的世界里就一直用 NSRange**，最后再转回 Swift。

## 2) Data ↔ NSData

```swift
let data = Data([0x43, 0x6F, 0x63, 0x6F, 0x61])   // "Cocoa"
let nsData = data as NSData
nsData.bytes.bindMemory(to: UInt8.self, capacity: 5).pointee   // 0x43
```

`Data` 是值类型（写时复制）：

```swift
var mutableData = data
mutableData.append(0x21)
// mutableData.count == 6，但 data.count 仍然是 5
```

实测：

```
  ok   Data 按字节计长度
  ok   与 UTF-8 字节一致
  ok   Data 解回字符串
  ok   桥接到 NSData 长度不变
  ok   Data 追加字节不影响原值（值语义）
```

> **坑**：`data as NSData` 桥接**不拷贝**（大多数情况下）。
> 桥接过去拿到 `bytes` 之后，Swift 侧一改，OC 侧那根指针就悬了。
> 需要长期持有的要 `data.withUnsafeBytes { ... }` 或者显式 `NSData(data:)` 拷一份。

## 3) Codable：Swift 原生的序列化

```swift
struct Settings: Codable, Equatable {
    var theme: String
    var fontSize: Int
    var recent: [String]
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]      // ← 需要稳定输出时必须开
let encoded = try! encoder.encode(settings)
```

实测：

```
  json = {"fontSize":13,"recent":["a.txt","b.txt"],"theme":"dark"}
  ok   sortedKeys 让输出可复现
  ok   解回来与原值相等
  ok   CodingKeys 把下划线键名映射成驼峰属性
  ok   日期按 secondsSince1970 解析
  ok   ISO8601 输出（UTC）
```

**`.sortedKeys` 和 OC 侧的 `NSJSONWritingSortedKeys` 是同一个道理**：
默认 key 顺序未定义，要 diff / 比对 / 做缓存就必须开。

### Codable vs NSJSONSerialization

| | Codable | NSJSONSerialization |
| --- | --- | --- |
| 类型安全 | 编译期检查 | 运行时全靠约定 |
| 模型 | `struct` / `class` | `NSDictionary` |
| 自定义键名 | `CodingKeys` 枚举 | 手动映射 |
| 继承/多态 | 麻烦 | 无所谓 |
| 与 OC 交互 | 要桥接 | 直接就是 OC 对象 |

新代码优先 `Codable`；要喂给 OC API / plist 才用 `NSJSONSerialization`。

## 4) Scanner

老式字符串解析器（`NSScanner` 的 Swift 版）：

```swift
let scanner = Scanner(string: " 320 200")
var width = 0, height = 0
let okW = scanner.scanInt(&width)
let okH = scanner.scanInt(&height)
```

- 默认**跳过空白**，所以连续扫两个整数就行。
- `scanInt` 返回 `Bool`（扫不到就 false），**不是抛异常**。
- 扫不到时**目标变量不会被改写**。

实测：

```
  ok   两次 scan 都拿到了值
  ok   扫出来的数字是 320 与 200
  ok   扫完两个整数后指针到了末尾
  ok   扫不到数字时返回 false
  ok   失败时目标变量不会被改写
```

适合解析简单的空格/逗号分隔文本。复杂的用 `NSRegularExpression` 或手写状态机。

## 5) URL 与 FileManager

```swift
let url = FileManager.default.temporaryDirectory
    .appendingPathComponent("demo-dir", isDirectory: true)
try data.write(to: url.appendingPathComponent("a.txt"))
```

> **坑**：`FileManager` 的相对路径是相对**进程的当前工作目录**，不是相对 bundle。
> 写文件一律先拼绝对路径。
>
> **坑**：增删文件后 `FileManager` 的枚举结果不保证立刻一致（有缓存/延迟）。
> 测试里判断「文件在不在」用 `fileExists(atPath:)`，别靠 `contentsOfDirectory` 的计数。

实测：

```
  ok   文件写出来了
  ok   读回来内容一致
  ok   URL 有 pathExtension
  ok   临时目录已删除
  ok   裸写相对路径不会落到临时目录（说明 cwd 是别处）
```

## 6) 相等性：`==` 与 `===`

Swift 的 `==` 走 `Equatable`；OC 对象的 `==` 走 `isEqual:`（桥接层做了这件事）。

```swift
let a = NSNumber(value: 1), b = NSNumber(value: 1)
a == b      // true  —— isEqual: 说相等
a === b     // false —— 不是同一个对象
```

实测：

```
  ok   == 走的是 isEqual，内容相同即相等
  ok   内容不同则不相等
  ok   放进 Set 时靠 hash + isEqual 去重
  ok   === 比的是指针
  ok   两个不同对象即使内容相同也不是同一指针
```

> **坑**：`Set` / 字典 key 依赖 `hash`。
> 自定义 `NSObject` 子类要**同时**实现 `isEqual:` 和 `hash`，
> 而且「相等的对象 hash 必须相等」。只实现 `isEqual:` 会让 Set 行为诡异。

## 7) NotificationCenter

```swift
let token = NotificationCenter.default.addObserver(
    forName: .init("demo"), object: nil, queue: nil) { note in ... }
// 用完必须移除
NotificationCenter.default.removeObserver(token)
```

iOS 9 / macOS 10.11 之后**不再需要**在 `deinit` 里移除基于 selector 的观察者，
但**基于 block 的**（`addObserver(forName:object:queue:using:)`）**必须手动移除**，
否则闭包捕获的对象一直活着。

实测：

```
  ok   移除观察者之后就收不到通知了（实际 ["1", "2"]）
```

`NotificationCenter` 是**同步**的：post 的时候，所有观察者的回调在当前线程、
在 post 返回之前就跑完了。别在通知回调里做重活。

## 8) 坑清单

| 现象 | 原因 |
| --- | --- |
| 中文/emoji 上截取字符串错位 | 混用了 `String.Index` 和 `NSRange.location` |
| `Range(nsRange, in:)` 返回 nil | NSRange 边界落在代理对中间 |
| JSON 每次输出顺序不同 | 没开 `.sortedKeys` |
| `Data` 转 `NSData` 后指针读到的内容变了 | 桥接不拷贝，Swift 侧的写时复制让原 buffer 失效 |
| Set 去重失败 | 只实现了 `isEqual:` 没实现 `hash` |
| 通知回调导致内存泄漏 | block 版观察者没 `removeObserver` |
| 文件写到了奇怪的地方 | 用了相对路径（相对 cwd，不是相对 bundle） |

## 小结

- `String.count` ≠ `NSString.length`；emoji 上差好几倍。
- `Range` 与 `NSRange` 用专门的构造器互转，`NSRange → Range` 可能失败。
- `Data`/`String`/`Array` 是值类型，桥接到 OC 后不再是。
- `Codable` 是新代码首选；`JSONEncoder` 要稳定输出记得 `.sortedKeys`。
- OC 对象当集合元素要同时实现 `isEqual:` 和 `hash`。
