# 06 · Foundation（Swift 篇）：值语义、可选、Codable、桥接

> 示例：`examples/06_swift_foundation/main.swift`
> 实测输出见 `build/06_swift_foundation/stdout.debug.txt`

第 05 章把 Foundation 在 **Objective-C 一侧**的面孔测清了：`NSString` 的 `length`
是 UTF-16 码元、`NSNumber` 不带类型记忆、容器越界是**抛异常**、日期一定要钉
时区与 locale。本章把同一批类型在 **Swift 一侧**再测一遍，一共 18 节、
**277 条断言**，一条 `FAIL` 都没有，debug（`-Onone`）与 release（`-O`）两份输出
逐字节一致。

Swift 侧的主线只有一句话：**`String` / `Data` / `Array` / `Dictionary` / `Set`
是值类型，`NSString` / `NSData` / `NSArray` 是引用类型，桥接免费但语义不等价。**
本章每个「坑」都是这句话的一个具体断面：

- 同一串内容有**四种长度口径**（字符 / UTF-16 码元 / Unicode 标量 / UTF-8 字节），
  而 `NSRange` 只认其中一种；
- 桥接之后**方法名会换、参数会变**，重载还会挑错那一个；
- `==` 走 Unicode 规范等价，`NSString` 的 `isEqual:` 只比码元序列 —— 两个「同一个词」
  在一侧相等、在另一侧不等；
- `NSArray` 是**快照**，`NSMutableArray` 才是真引用；`as?` 条件桥接是**全有或全无**；
- `NSNumber` 的 `is Bool` 与 `is Int` **双向都真**，分清 1 与 `true` 只剩 `objCType` 一条路；
- `Codable` 默认把 `Date` 编成「自 2001 参考日期起的秒数」，这不是 bug 是参考系换轨；
- 解码失败的 `DecodingError` 有**四个** case，`keyNotFound`、`typeMismatch`、
  `valueNotFound`、`dataCorrupted` 各对应一种真实坏数据；
- Swift 的**哈希种子每进程随机**，所以集合的顺序、字典的键序都不能写进断言。

> Swift 的纯语言基础（可选、协议、泛型、闭包的语法本体）在第 30 章；
> 本章只讲**与 Foundation / iOS 直接相关**的部分，并且和 05 章逐项对照：
> 同一件事在 OC 里怎么写、在 Swift 里怎么写、坑在哪一侧。

和 05 章一样的三条硬约束：**会崩的行为只在独立探针里量**（原文收在 §18）、
**不打印任何指针值 / 地址 / UUID / 路径 / 环境相关数字**（`domain=NSCocoaErrorDomain
code=3840` 这类**稳定**的错误码可以打，`0x1a2b…` 不行）、**所有随系统语言与时区
变化的输出都必须先钉死 locale + timeZone**，钉不住的（`DateComponentsFormatter`、
`ByteCountFormatter` 干脆没有 `locale` 属性）只对**结构**下断言。

## 0) 本章的道具：断言器、六个固定类型、两个钉死的格式化器

```swift
var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }
```

断言器只有这两个函数：`expect` 把「条件」变成一行 `ok` / `FAIL`，`line` 负责打印
**观测值本身**（长度、字符串、错误描述）。这个分工很重要：`ok` 行是「结论」，
`line` 行是「证据」，文档里两种都原样抄出来。

本章在文件顶部声明了六个类型，各自服务一节，**必须声明在顶层**（Swift 的
`main.swift` 里嵌套类型不能参与某些桥接，且 §8 的实验要「对象都活在局部之外」）：

```swift
// §8：只重写 isEqual / 两个都重写 —— 哈希契约的两半
class MXCredOnly: NSObject {
    var name: String
    init(_ n: String) { name = n }
    override func isEqual(_ object: Any?) -> Bool { (object as? MXCredOnly)?.name == name }
}
class MXCredBoth: NSObject { /* 同上，再加 override var hash: Int { name.hashValue } */ }

// §9/§10：编解码的最小结构体
struct MXConf: Codable, Equatable { var name: String; var port: Int; var tags: [String] }
struct MXNum: Codable { var v: Double }
struct MXInt: Codable { var v: Int }

// §14：归档 —— Swift 侧要 NSSecureCoding
@objc(MXDoc) class MXDoc: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }
    func encode(with coder: NSCoder) { coder.encode(title, forKey: "title"); coder.encode(n, forKey: "n") }
    required init?(coder: NSCoder) { /* decodeObject(of:forKey:) + decodeInteger(forKey:) */ }
}

// §15：KVC / KVO / perform 的靶子
@objc class MXPerson: NSObject {
    @objc var name: String = ""
    @objc var age: Int = 0
    @objc dynamic var count: Int = 0        // 少一个 dynamic 就观察不到
    var blockHits = 0
    var legacyHits = 0
    @objc func greet() -> String { "你好 \(name)" }
    @objc func shout(_ s: String) -> String { s.uppercased() }
    override func observeValue(forKeyPath:of:change:context:) { legacyHits += 1 }
}
```

两个细节值得单独说：

1. **`MXDoc` 的 `encode(with:)` 不写 `override`**。它是从 `NSCoding` 协议来的要求，
   `NSObject` 上并没有一个同签名实现给你覆盖；写 `override` 编译器直接报
   `method does not override any method from its superclass`。
2. **`MXPerson.count` 必须 `@objc dynamic`**。少了 `dynamic`，属性读写走 Swift 的
   静态直路，KVO 的观察根本没机会插进去 —— 这是第 27 章消息转发那套机制在 Swift
   侧的直接后果。

最后是两个「全局钉死」的格式化器，本章 §12 之后到处复用：

```swift
let posix = Locale(identifier: "en_US_POSIX")
let utc = TimeZone(secondsFromGMT: 0)!
let dayFmt = DateFormatter()   // locale=posix, timeZone=utc, "yyyy-MM-dd"
let fullFmt = DateFormatter()  // locale=posix, timeZone=utc, "yyyy-MM-dd HH:mm:ss"
```

**`en_US_POSIX` 不是「美式」，是「机读」**：它不分组、不随系统语言变、不受用户
设置影响。iOS 上任何要写进文件 / 网络 / 快照的日期串，Apple 自己的建议就是
`en_US_POSIX` + 显式 `timeZone`；§13 会实测到它连千分位都不打。

## 1) String 与 NSString：同一串内容的四种「长度」

```swift
let text = "café"
let nsText = text as NSString            // 免费桥接
text.count                               // 字符（grapheme cluster）
nsText.length                            // UTF-16 码元
text.unicodeScalars.count                // Unicode 标量
text.utf8.count                          // UTF-8 字节
```

`café` 这个例子刻意选了「两种数法恰好一样」的串，然后立刻用 emoji、国旗、
肤色修饰符把它们拆开：

```swift
let emoji = "😀"      // 1 个字符 = 2 个码元 = 1 个标量
let flag  = "🇨🇳"      // 1 个字符 = 4 个码元 = 2 个标量
let skin  = "a👍🏽b"    // 3 个字符 = 6 个码元 = 4 个标量 = 10 字节
```

实测：

```
-- 1) String 与 NSString：同一串内容的四种「长度」--
  ok   Swift 的 count 是「用户看到的字符数」（grapheme cluster）
  ok   NSString 的 length 是 UTF-16 码元数，这一串里恰好也是 4
  ok   café 是 4 个标量：é 用的是预组合码点 U+00E9
  ok   UTF-8 字节数是 5：é 吃掉 2 个字节
  ok   emoji 在 Swift 里算 1 个字符
  ok   同一个 emoji 在 NSString 里是 2 个码元（代理对）
  ok   国旗在 Swift 里仍是 1 个字符
  ok   国旗在 NSString 里是 4 个码元（两个 regional indicator）
  ok   国旗只有 2 个标量，却要 4 个 UTF-16 码元来装
  同一串「a👍🏽b」：count=3 utf16.count=6 scalars=4 utf8.count=10
  ok   手势+肤色修饰符合成一个字符，加上 a、b 共 3 个
  ok   NSString 数到 6 个码元：a + 代理对 + 代理对 + b
  ok   标量是 4 个：a、👍、🏽、b —— 肤色修饰符自己就是一个标量
  ok   UTF-8 是 10 字节
```

四把尺子的分工记牢：

| 你要做的事 | 用哪个 | 别用哪个 |
|---|---|---|
| 遍历用户看到的字符、按字符截取、显示长度 | `s.count` / `s.indices` | `ns.length` |
| 和 OC API、`NSRange`、正则、`NSAttributedString` 打交道 | `(s as NSString).length`、UTF-16 视图 | `s.count` |
| 判断「有没有超出某个码点范围」 | `s.unicodeScalars` | 前两个 |
| 算字节数、写文件、算 base64 | `s.utf8.count`、`s.data(using:)` | `s.count` |

两个补充结论：

- **`🇨🇳` 只有 2 个标量却要 4 个码元**：区域指示符 `U+1F1E8`/`U+1F1F3` 各自在
  BMP 之外，各占一个代理对。所以「标量数」和「码元数」也不是 1:1 ——
  凡是码点 > `U+FFFF` 的字符都要 2 个码元。
- **`a👍🏽b` 的 UTF-8 是 10 字节**：`a`、`b` 各 1 字节，👍 与 🏽 各 4 字节。
  Swift 5 起 `String` 的底层存储就是 UTF-8，`utf8.count` 是**真实字节数**，
  不是另一种编码视图的转换结果。

> **坑（和 05 章同一条，但方向相反）**：OC 侧你必须记得 `length` 是码元；
> Swift 侧你必须记得 `count` 是**字符**，而 `count` 是 **O(n)** 的 ——
> 因为它要跑一遍字素簇边界算法。要在循环里反复取长度，先存成常量，
> 或者干脆桥成 `NSString` 拿它的 `length`（O(1)，但口径是码元）。

## 2) 桥接之后：方法名会换、参数会变、重载会挑错那个

```swift
let upperFromNS = nsText.uppercased(with: nil)   // NSString 版要求给 locale
let upperFromSwift = text.uppercased()           // Swift 版不要参数
```

这两行写的是**同一件事**，签名却不同：`NSString` 上的方法是
`-uppercasedWithString:` 家族（`uppercased(with: Locale?)`），Swift 的 `String`
只给了 `uppercased()` 和 `uppercased(locale:)`。**静态类型是 `NSString` 时，
无参的 `uppercased()` 直接编译不过**：

```
error: missing argument for parameter 'with' in call
```

同一行代码，把 `let nsText = text as NSString` 改成 `let nsText = text`，
就从「必须写参数」变成「写了参数反而没有这个方法」。桥接类型声明在 `let` 上，
就等于把这行的 API 钉死在一侧。

大小写转换是**带语言**的，这不是学术例子（土耳其语的 i）：

```swift
"i".uppercased()                        // "I"
"i".uppercased(with: Locale(identifier: "tr"))   // "İ"（带点的大写 I）
```

实测：

```
-- 2) 桥接之后：方法名会换、参数会变、重载会挑错那个 --
  ok   两个 uppercased 结果一致，但**签名不同**
  无 locale 的 i → I；土耳其语 locale 的 i → İ
  ok   大小写转换是**带语言的**，土耳其语的 i 大写是 İ
  ok   反过来：İ 小写后仍是 1 个字符
  ok   但它由 i + 组合点上标两个标量拼成，长度不能想当然
  NSString 切分 = ["a", "", "b", ""]（4 段）
  Swift split 切分 = ["a", "b"]（2 段）
  ok   NSString 的 components 保留空段，末尾的分号也算一段
  ok   Swift 的 split 默认丢掉空段：同一个分隔符，段数少一半
  ok   想要 OC 的行为，得显式关掉「省略空段」
  ok   NSString(string:) 造的串长度按码元算
```

三个结论：

1. **反过来的方向更长**：`"İ".lowercased()` 在 Swift 里仍是 **1 个字符**，
   但它是 `i` + `U+0307`（组合点上标）**两个标量**拼的。所以
   「大写转小写长度不变」「一个字符转完还是一个字符」都不能假设。
2. **切分语义完全不同**（这是本章最容易在生产代码里翻车的一条）：
   `NSString` 的 `components(separatedBy:)` **保留空段**，末尾那个分隔符
   也算出一段空串，`"a,,b,"` → `["a", "", "b", ""]`（4 段）；
   Swift 的 `split(separator:)` **默认丢掉空段** → `["a", "b"]`（2 段）。
   想要 OC 的行为必须显式写 `omittingEmptySubsequences: false`。
   CSV、自定义协议、按 `\n` 分行都栽在这上面。
3. **`NSString(string:)` 与 `as NSString` 结果一样**，但前者是「造一个 OC 串」，
   后者是「按 OC 的眼睛看同一个值」；`length` 的口径都是码元。

## 3) Index / Range / NSRange：三套下标互不通用

Swift 的字符串下标是 `String.Index`（**不透明**，不能加减整数、不能比较大小），
范围是 `Range<String.Index>`；OC 侧是 `NSRange`（`location` + `length`，基于 UTF-16
码元）。两者靠两个初始化器换算，而这两个初始化器**不对称**：

```swift
if let swiftRange = text.range(of: "fé") {
    let nsRange = NSRange(swiftRange, in: text)   // Range → NSRange：非可选，一定成功
    let backToSwift = Range(nsRange, in: text)     // NSRange → Range：返回 Optional，可能 nil
}
```

实测（含一个刻意构造的错误用法）：

```
-- 3) Index / Range / NSRange：三套下标互不通用 --
  ok   Range → NSRange 换算一致
  ok   NSRange → Range 在这个例子里成功
  ok   把 café 上量出的 NSRange 用到别的串上，只要不越界就照样成功
  ok   但截出来的绝不是当初那段文本：位置全错
  ok   越界 NSRange 转 Range 得到 nil（不是崩溃）
  ok   起点越界同样得到 nil
  「z」在「a😀éz」里：字符偏移=3 码元偏移=5 标量偏移=4
  ok   同一个位置，三把尺子量出三个数
  ok   整串也是：Swift 数 4 个字符，NSString 数 6 个码元
  ok   offsetBy 数的是「字符」：跳过 a 之后剩下的整串里，é 仍是一个字符
  ok   想要不崩的版本，用带 limitedBy 的重载
  ok   越界时它返回 nil 而不是 trap
```

逐条说清：

- **`NSRange` 不绑定字符串**。它只是两个整数。把在 `café` 上量出来的
  `NSRange` 拿去截 `a👍🏽b`，只要不越界就**照样成功**，但截出来的绝不是当初那段
  文本 —— 位置全错。这正是富文本（§17）、正则、`NSAttributedString` 与
  `String` 混用时最常见的错法。
- **越界给 `nil`，不是崩溃**：`location` 或 `location+length` 超出码元边界，
  `Range(_:in:)` 返回 `nil`；落在**代理对中间**同样返回 `nil`（不会给你一个
  半个 emoji 的范围）。这是安全设计，但你必须解包。
- **同一个位置，三把尺子量出三个数**。`"a😀e\u{0301}z"`（`a` + 一个 emoji + `e` 加组合急性重音 + `z`）里的 `z`：

  ```
  「z」在「a😀éz」里：字符偏移=3 码元偏移=5 标量偏移=4
  ```

  换算用 `samePosition(in:)`，它是**跨视图投影**而不是「取个整数」：

  ```swift
  let zIdx = mix.firstIndex(of: "z")!
  mix.distance(from: mix.startIndex, to: zIdx)                                    // 3
  mix.utf16.distance(from: mix.utf16.startIndex,
                     to: zIdx.samePosition(in: mix.utf16)!)                        // 5
  mix.unicodeScalars.distance(from: mix.unicodeScalars.startIndex,
                              to: zIdx.samePosition(in: mix.unicodeScalars)!)      // 4
  ```

  `samePosition(in:)` 返回**可选**：当这个字符边界在目标视图里不存在
  （例如落在组合序列中间）就是 `nil`。
- **`index(_:offsetBy:)` 越界是 trap**（§18 第 4 条实测 `String index is out of
  bounds` + signal 4）。安全的写法是带 `limitedBy:` 的重载，它给 `nil`：

  ```swift
  mix.index(mix.startIndex, offsetBy: 99, limitedBy: mix.endIndex)   // nil，不崩
  ```

- **`offsetBy` 数的是「字符」**：跳过 1 个字符之后剩下的整串里，
  `é`（e + 组合点）仍然算一个字符。这一点和 OC 的 `characterAtIndex:`
  拿到半个代理对（05 章 §1）正好是一组对照。

## 4) 归一化、忽略大小写、忽略重音：== 与 compare 不是一回事

同一个「café」有两种 Unicode 写法：预组合（`é` = `U+00E9` 一个标量）和
分解（`e` + `U+0301` 两个标量）。它们**看起来完全一样**。

```swift
let text = "café"                 // 预组合（é = U+00E9）
let decomposed = "cafe\u{0301}"   // 分解式（e + U+0301）
text == decomposed                             // Swift：true
let nsDec = decomposed as NSString
let nsPre = text as NSString
nsDec != nsPre                                   // NSString 的 isEqual:：false
```

实测：

```
-- 4) 归一化、忽略大小写、忽略重音：== 与 compare 不是一回事 --
  ok   分解式和预组合式在 Swift 里直接相等：== 走 Unicode 规范等价
  ok   字符数也一样是 4
  ok   但 NSString 数出 5 个码元：多出来的组合点自己占一格
  ok   换成 NSString 的 isEqual，这两个「同一个词」就不等了
  ok   isEqual(to:) 同样只比码元序列，不做归一化
  ok   要 OC 那套「先归一化再比」，得显式调 precomposedStringWithCanonicalMapping
  ok   hasSuffix 也按字符走：单独的组合上标不构成串尾那个字符（它和 e 粘成了 é）
  ok   compare 说两者一样：它内部做了规范等价
  ok   folding 把 É 折成 E，用来做「不区分重音」的搜索/去重
  ok   两个选项合起来 = 忽略大小写又忽略重音
  ok   只给 caseInsensitive 时 É 仍是 É
  ok   caseInsensitiveCompare：不看 locale
  ok   localizedCaseInsensitiveCompare：看当前 locale
  'a' 与 'A' 谁在前：de_DE=-1 en_US_POSIX=1（-1/1 才是「谁在前」）
  ok   同一个比较，换 locale 结论**反过来**：德语里小写在前，POSIX 里按 ASCII 码点大写在前
  默认字典序 = ["File1.txt", "file10.txt", "file2.txt"]
  localizedStandardCompare = ["File1.txt", "file2.txt", "file10.txt"]
  ok   默认 sorted 按 UTF-16 码元：大写排在前面，10 在 2 之前
  ok   localizedStandardCompare 是「访达」式排序：识别串里的数字，Finder 同款
```

这一段是全章最「反直觉」的部分，值得逐行读完：

1. **Swift 的 `==` 走 Unicode 规范等价**，所以分解式和预组合式直接相等，
   连 `count` 都是 4。**但 `(decomposed as NSString).length` 是 5** ——
   多出来的组合点自己占一格。也就是说「相等」和「一样长」可以同时成立，
   只要你用的是两把不同的尺子。
2. **`NSString` 的 `isEqual:` / `isEqual(to:)` 只比码元序列，不做归一化**。
   所以两个「同一个词」在 OC 侧不相等。要 OC 那套「先归一化再比」，
   得显式调 `precomposedStringWithCanonicalMapping`（05 章 §4 同一条）。
3. **`hasSuffix("\u{0301}")` 是 `false`**：Swift 的后缀判断也按字符走，
   单独的组合上标不构成串尾那个字符 —— 它和 `e` 粘成了 `é`。
4. **`compare(_:)` 说两者一样**：它内部做了规范等价。所以「用 `==` 还是用
   `compare`」不只是「要不要忽略大小写」的问题，还牵涉要不要归一化。
5. **`folding(options:locale:)` 是给搜索/去重用的**：
   `.diacriticInsensitive` 把 `É` 折成 `E`；只给 `.caseInsensitive` 时 `É`
   仍然是 `É`（大小写折了，重音没折）；两个选项一起给才是「不看大小写也不看重音」。
6. **三种「忽略大小写比较」的作用域不一样**：
   `caseInsensitiveCompare` 不看 locale（按码位），
   `localizedCaseInsensitiveCompare` 看**当前** locale（于是随用户手机设置变），
   `compare(_:options:range:locale:)` 可以自己传 locale。
7. **换 locale 会让结论反过来**：`'a'` 与 `'A'` 谁在前，`de_DE` 给 `-1`
   （德语字典序小写在前），`en_US_POSIX` 给 `1`（按 ASCII 码点，大写在前）。
   同一段代码在两台机器上排序结果不同，就是这个原因。
8. **文件名排序要的是「访达」那套**：默认 `sorted()` 按 UTF-16 码元，
   得到 `["File1.txt", "file10.txt", "file2.txt"]`（大写在前、10 在 2 之前）；
   用 `localizedStandardCompare` 才是 `["File1.txt", "file2.txt", "file10.txt"]`
   —— 它认串里的数字，是 Finder 同款。iOS 上任何列文件的界面都应该用它。

> **实操结论**：做「用户输入的字符串是否相同」（用户名、标签、搜索词）时，
> 光靠 `==` 不够安全 —— 它虽然做了规范等价，却不做大小写/重音折叠。
> 常见做法是 `folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)`
> 之后比，或者把折叠后的串当 key。反过来，**做协议、路径、ID 时绝对不要折叠**，
> 要逐字节比。

## 5) Data：值语义、切片、坏字节

```swift
let data = Data([0x43, 0x6F, 0x63, 0x6F, 0x61])   // "Cocoa"
var mutableData = data
mutableData.append(0x21)                           // 改的是副本
```

实测：

```
-- 5) Data：值语义、切片、坏字节 --
  ok   Data 按字节计长度
  ok   Data 追加不影响原值（写时复制）
  ok   Data 解回字符串
  ok   append(contentsOf:) 才是拼接整块的重载（Data 上没有 appending(_:)）
  ok   加号也能拼，且拼完还是值语义
  ok   subdata 返回**新 Data**，不是切片
  ok   Data 的 SubSequence 就是 Data 自己，所以切片不用二次转换
  ok   base64 往返一致
  ok   解不开的 base64 返回 nil（探针里没异常这条路）
  ok   isoLatin1 下 é 只占 1 字节，4 字符正好 4 字节
  ok   按同一个编码解回去才还原
  ok   ASCII 装不下 é：无损转换直接给 nil
  ok   有损转换是**丢掉**é，不是替换成 ?（探针实测）
  ok   String(data:encoding:) 遇到非法 UTF-8 返回 nil
  ok   String(decoding:as:) 永远成功：坏字节换成替换符 U+FFFD
  ok   第一个坏字节换出 U+FFFD
  ok   坏字节被逐个替换，后面的合法字符 A 还留着
```

要点逐条：

- **`Data` 是结构体，赋值即拷贝语义**（底层写时复制：只有真正修改才复制缓冲）。
  这和 `NSData`（引用类型，赋值只增引用计数）根本不同；OC 要可变得换
  `NSMutableData`，Swift 只要 `var`，**没有 `MutableData` 这个类型**。
- **`append` 的两个重载容易搞混**：`append(_ byte: UInt8)` 只加**一个字节**，
  拼**一整块**必须写 `append(contentsOf: Data)`。`Data` 上**没有**
  `appending(_:)`（这是和 `Array` 不同的地方，`Array` 有）。
  加号 `data + [0x21]` 也可以，结果仍是值语义。
- **`subdata(in:)` 返回新的 `Data`（独立副本），切片不是**：
  `data.prefix(2)` 的类型是 `Data.SubSequence`，而它**就是 `Data` 自己** ——
  这一点比 `Array` 友好（`Array` 的 `SubSequence` 是 `ArraySlice`，
  传给要 `Array` 的 API 得再 `Array(...)` 一次）。
- **base64 是可选返回**：`Data(base64Encoded:)` 解不开就给你 `nil`，
  **没有抛异常这条路**（探针里也没找到异常）。
- **老编码仍然在**：`isoLatin1` 下 `é` 只占 1 字节，所以 `café` 正好 4 字节；
  按**同一个**编码解回去才还原。拿 UTF-8 去解 ISO-Latin-1 的字节会得到 `nil`
  或乱码，这是「导入历史文件」的经典 bug。
- **ASCII 装不下 `é`**：无损转换（默认 `allowLossyConversion: false`）**直接给
  `nil`**；开了有损转换的结果是**丢掉** `é`（`"café"` → `"cafe"`），
  **不是**替换成 `?`（探针实测原文见 §18）。很多教程写「会变成问号」，
  在本机上是错的。
- **面对真正的非法字节，两种解法命运不同**：

  ```swift
  let bad = Data([0xFF, 0xFE, 0x41])
  String(data: bad, encoding: .utf8)        // nil —— 严格，一个坏字节就整串拒收
  String(decoding: bad, as: UTF8.self)       // 永远成功，坏字节换成 U+FFFD
  ```

  后者逐个把坏字节替换成 `U+FFFD`（替换字符），**后面的合法字符 `A` 还留着**。
  读网络/磁盘上不完全可信的数据时，用 `String(decoding:as:)` 才不会因为一个
  坏字节把整屏内容变成空。

## 6) Array/Dictionary/Set 与 NSArray/NSDictionary/NSSet

```swift
var arr = [1, 2, 3]
let snapshot = arr as NSArray      // 桥接出来的 NSArray 是「当时那份」
arr.append(4)
```

实测：

```
-- 6) Array/Dictionary/Set 与 NSArray/NSDictionary/NSSet --
  ok   桥接出来的 NSArray 是快照：之后改 Swift 数组，它不动
  ok   同一个 Swift 数组桥两次得到两个不同对象：别拿桥接结果当身份
  ok   mutableCopy 路线：NSMutableArray 是**真引用类型**，改了就看得到
  ok   NSArray 里混着 Int，整个 as? [String] 失败返回 nil
  ok   混着 String 时 as? [Int] 也是 nil：条件桥接是**全有或全无**
  ok   桥接本身不丢元素，也不做类型检查
  ok   字典桥过去再桥回来，值还在
  ok   要「可变的 NSDictionary」得用 NSMutableDictionary(dictionary:)：as 直转编译不过（见 §18）
  ok   NSSet 可以条件桥回 Set
  ok   Set ↔ NSSet 免费桥；Array → NSSet 不合法（§18）
  ok   想打印集合就**必须**排序，否则同一份代码每次输出不一样
  ok   去重 + 排序是安全写法
  ok   grouping 出来的键顺序同样不可依赖，先 sorted 再断言
  ok   取的时候按可选处理
  ok   要可变的就显式 mutableCopy()：它给的是新对象，不是把原数组「看成」可变的
```

这是 iOS 项目里最常用也最容易误解的一节：

1. **桥接出来的是快照**。`arr as NSArray` 之后再加元素，`snapshot.count`
   仍是 3。它不是「同一个缓冲的两个视图」，而是**造出来的一个 OC 对象**。
2. **同一个 Swift 数组桥两次得到两个不同对象**（`!==`）。所以
   **别拿桥接结果当身份**：`arr as NSArray === arr as NSArray` 为假，
   字典里当 key、通知的 `object` 参数、`===` 判等处都会出错。
   要稳定身份只能自己持有那个 `NSArray`。
3. **`NSMutableArray` 才是真引用类型**：`NSMutableArray(array: snapshot)`
   之后 `add(5)`，`mutArr.count` 变 4 而 `snapshot.count` 不动 ——
   改的是那个可变对象自己。
4. **条件桥接（`as?`）是全有或全无**。`[1, "x"]` 桥成 `NSArray` 之后，
   `as? [String]` 和 `as? [Int]` **都是 `nil`**，不会「能转几个算几个」。
   而**桥接本身**（`as NSArray`）不丢元素也不做类型检查 —— 检查发生在
   `as?` 回来那一刻。这就是 §18 第 5、6 条那两个崩溃的由来：
   `NSArray as! [Int]` 里元素是 `NSString` 时直接 `Could not cast value …`。
5. **要「可变的 `NSDictionary`」只能构造**：`dict as NSMutableDictionary`
   **编译不过**（`Array` 只能桥 `NSArray`，`Dictionary` 只能桥 `NSDictionary`，
   见 §18 第 11 条）。正确写法是 `NSMutableDictionary(dictionary:)`。
   `Set ↔ NSSet` 是免费双向桥，但 `[String] as NSSet` **不合法**，
   得先 `Set(...)`。
6. **顺序不可依赖**：Swift 的 `Set` / `Dictionary` 迭代顺序**每进程随机**
   （§18 第 12 条记了连跑三次的实测结果）。所以任何要打印或断言的集合
   **必须先 `sorted()`**；`Dictionary(grouping:by:)` 出来的 `keys` 同理。
   取值时按可选处理（`grouped["偶"]?.count`）。
7. **`mutableCopy()` 给的是新对象**，不是「把原数组看成可变的」。
   这点和第 2 条呼应：OC 的 `copy`/`mutableCopy` 语义在 Swift 侧原样保留。

> **和 05 章的对照**：OC 里「不可变版返回新对象、可变版就地改」是命名契约
> （`arrayByAddingObject:` vs `addObject:`）；Swift 里这条契约变成了
> `let`/`var` + 值语义，但一旦你桥成 `NSArray`/`NSMutableArray`，
> **两套契约同时生效** —— 这就是 §6 全部坑的来源。

## 7) NSNumber、NSValue 与 `is` / `as?` 的判定

```swift
let nInt = NSNumber(value: 7)
let nDbl = NSNumber(value: 3.7)
let nBool = NSNumber(value: true)
```

实测：

```
-- 7) NSNumber、NSValue 与 is / as? 的判定 --
  objCType：Int=q Double=d Bool=c
  ok   Swift 的 Int 桥成 long long(q)、Double 桥成 double(d)，和 05 章 OC 那侧一致
  ok   Bool 桥成 char(c)：OC 里 BOOL 与 char 同字符，这里也一样
  ok   取 intValue 会**截断**，不四舍五入
  ok   装着 3.7 的 NSNumber 条件桥不成 Int：拿不到就给你 nil，而不是悄悄截断
  ok   条件桥成 Double 成功
  ok   装整数的 NSNumber 走 intValue 正常
  ok   is 判定是**双向都真**的：1 算 Bool、true 也算 Int
  ok   四种组合全为真——is 问的是「能不能按这个类型解释」，不是「当初装的是什么」
  ok   要分清 1 与 true，只有 objCType 这一条路：q 是整数、c 是 char/BOOL
  逐项 is 判定 = ["Int", "Str", "Dbl", "Date", "Dict"]
  ok   Int 不是 Double、Double 不是 Int：Swift 数字类型之间**不做**隐式加宽
  ok   字典按具体类型匹配，[String: Int] is [String: String] 为假
  ok   CGRect 进出不变：Swift 的 CGRect 是结构体，NSValue 是它的盒子
  ok   CGPoint 同理
  ok   CGSize 同理
  ok   赋值是拷贝：改副本动不了原值（OC 里 NSString 结构体没这待遇）
  ok   CGRect.null 是「空矩形」，和 .zero 不是一回事
  ok   insetBy 是四边内缩：宽高各减 2 倍
```

**（a）`objCType` 是和 05 章对得上的那条**：Swift 的 `Int` 桥成 `long long`（`"q"`），
`Double` 桥成 `double`（`"d"`），`Bool` 桥成 `char`（`"c"`）。05 章里 OC 侧
`NSNumber` 的 `BOOL` 与 `char` 同为 `"c"`，这条在 Swift 侧完全一致。
64 位上 `long` 与 `long long` 也都是 `"q"`，**分不出来**。

**（b）取值的两条路命运不同**：

```swift
nDbl.intValue          // 3        —— 向零截断，不四舍五入
nDbl as? Int           // nil      —— 条件桥接不给你悄悄截断的机会
nDbl as? Double        // 3.7
```

这是 Swift 桥接比 OC 安全的一处：`as?` 会在「装箱内容和你要求的类型对不上」时
给你 `nil`，而 `intValue` 是 OC 那套「按类型解释」的老路，照旧截断。

**（c）本章最阴的一条：`is` 判定双向都真**。

```swift
let oneAsAny: Any = NSNumber(value: 1)
let trueAsAny: Any = NSNumber(value: true)
oneAsAny is Bool     // true
trueAsAny is Int     // true
```

四种组合全为真。`is` 问的是「**能不能按这个类型解释**」，不是「当初装的是什么」。
所以想用 `is Bool` 来区分「JSON 里的 1」和「真正的 true」是**行不通的**
（很多教程就是这么写的，本机实测是反例）。唯一的分辨路径是 `objCType`：
`"q"` 是整数、`"c"` 才是 `char`/`BOOL`。注意要分清 1 与 `true` 得先 `as! NSNumber`
—— **`Any` 上直接写 `as NSNumber` 编译器拒绝**（`'Any' is not convertible to 'NSNumber'`），
必须 `as!` 或用泛型/协议路径。

**（d）`Any` 逐项 `is` 判定的清单**（实测那行 `逐项 is 判定 = ["Int", "Str", "Dbl", "Date", "Dict"]`）：
`[1, "s", 2.5, Date(), ["a": 1]]` 里 `Int` 就是 `Int`、`Double` 就是 `Double`，
**Swift 数字类型之间不做隐式加宽**（`1 is Double` 为假！这和 OC 的
`@compatibility_alias` / 自动装箱习惯完全相反，写 `as? Double` 之前要记得）。
字典按**具体类型**匹配：`[String: Int] is [String: String]` 为假。

**（e）`NSValue` 装几何值**：`CGPoint` / `CGSize` / `CGRect` 在 Swift 里是
**结构体**，`NSValue` 只是它们的盒子；但 `NSValue(cgRect:)` 这类**便利构造器
在 UIKit 里，不在 Foundation 里**（05 章 §6 实测过：只链接 Foundation 的裸可执行文件
里这个方法编得过、跑起来 `unrecognized selector`）。所以本章文件顶部
`import UIKit`。

```swift
let vRect = NSValue(cgRect: rc)
vRect.cgRectValue == rc      // true：进出不变
var rectCopy = rc
rectCopy.origin.x = 99        // 改副本动不了原值
```

赋值是拷贝 —— 这一条 OC 里 `NSString` 那种「结构体套指针」的待遇完全没有。
另外两个几何值细节：`CGRect.null.isNull` 为真而 `CGRect.zero.isNull` 为假
（**「空矩形」和「原点零尺寸」不是一回事**，UIKit 里判断「没布局出来」要看
`isNull` 或 `isEmpty`）；`insetBy(dx:dy:)` 是**四边**各内缩，宽高各减 `2×`。

## 8) `==` 与 `===` 与 `hash`：三条契约一次测清

```swift
let a = NSNumber(value: 1), b = NSNumber(value: 1)
a == b      // true —— == 走 isEqual，比内容
a === b     // true?! —— 小整数 NSNumber 是 tagged pointer，其实是同一个指针值
```

实测：

```
-- 8) == 与 === 与 hash：三条契约一次测清 --
  ok   == 走 isEqual，内容相同即相等
  ok   小整数 NSNumber 是 tagged pointer，=== 竟为真（别拿它判相等）
  ok   === 比指针：两个独立对象不相等
  ok   === 同一对象为真
  ok   Set 靠 hash + isEqual 去重
  ok   只重写 isEqual：两个实例按我们的规则相等
  ok   但 hash 没重写：NSObject 默认按对象身份给值，两个实例两个 hash
  （只重写一半时 Set 里到底留几个，取决于桶位是否撞上——同一份代码可能 1 也可能 2，所以不作断言）
  ok   isEqual 与 hash 一起重写，Set 才真的去重
  ok   内容同 → hash 同（这正是契约要求）
  ok   没重写 hash → 内容同、hash 也不同：这就是漏写的那一半（对象都存在局部，不让地址复用糊弄我们）
  ok   结构体只要声明 Hashable，两个字段自动参与 hash
```

**（a）`===` 会骗你**。小整数 `NSNumber` 是 **tagged pointer**：整数值直接编码在
指针位里，不分配堆内存，于是两个「独立创建」的 `NSNumber(value: 1)` 底层是
同一个指针值，`===` 竟然为 `true`。**结论**：`===` 只用于「是不是同一个对象」的
身份判断，**绝不能用来判内容相等**。要演示真正的指针身份，用普通堆对象
（`NSObject()` 两个，`!==` 为真）。

**（b）`Set` / 字典 key 的去重靠 `hash` + `isEqual` 两半**。本节用两个类把
「只重写一半」的后果实测出来：

```swift
class MXCredOnly: NSObject {      // 只重写 isEqual
    override func isEqual(_ object: Any?) -> Bool { (object as? MXCredOnly)?.name == name }
}
class MXCredBoth: NSObject {      // isEqual + hash 都重写
    override var hash: Int { name.hashValue }
}
```

- `MXCredOnly("x") == MXCredOnly("x")` 为真（按我们的规则相等），
  但两者的 `hash` **不同** —— `NSObject` 的默认 `hash` 来自对象身份。
- **只重写一半时 `Set` 里到底留几个是不确定的**：取决于两个 hash 有没有撞上
  同一个桶。同一份代码可能 1 也可能 2，所以本章**不对这件事下断言**，只把
  「两个 hash 不同」这条实测出来。这比写一条会随机器翻脸的断言诚实。
- 两个都重写（`MXCredBoth`）之后 `Set([d1, d2]).count == 1` 才是稳定的，
  且 `MXCredBoth("y").hash == MXCredBoth("y").hash`（内容同 → hash 同，契约要求）。
- 注意实验里的对象都**存在局部变量**里（`h1`、`h2`）。如果写成
  `MXCredOnly("x").hash != MXCredOnly("x").hash`，编译器可能复用地址，
  结论会被「糊弄」过去 —— 这类断言必须先把对象留住。

**（c）Swift 结构体没有这个坑**：`struct MXKey: Hashable { var u, p: String }`
只要声明 `Hashable`，两个字段自动参与 `hash` 与 `==`，`Set` 里只剩 1 个。
这也是为什么 iOS 新代码更该用值类型当 key。

> 对照 05 章 §12：OC 里「重写 `isEqual:` 不重写 `hash`」是**同一类 bug**，
> 只是 OC 侧没人替你合成，忘了就是忘了。Swift 侧的差别是：`struct` + `Hashable`
> 会帮你合成，`class : NSObject` 则回到 OC 的老规矩 —— 两者在同一个文件里并存，
> 这正是混合工程里最容易出事的地方。

## 9) Codable：编码侧

```swift
struct Settings: Codable, Equatable {
    var theme: String
    var fontSize: Int
    var recent: [String]
}
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]           // 要稳定输出必须开
let json = String(data: try! encoder.encode(settings), encoding: .utf8)!
```

实测：

```
-- 9) Codable：编码侧 --
  json = {"fontSize":13,"recent":["a.txt","b.txt"],"theme":"dark"}
  ok   sortedKeys 让输出可复现
  ok   解回来与原值相等
  ok   字典顶层不带 sortedKeys 也能编，但键序不可复现（§18 记了三次不同结果）
  ok   开了 sortedKeys 才有唯一正确答案
  ok   CodingKeys 把蛇形键映射成驼峰属性
  ok   convertFromSnakeCase 连嵌套字典里的键一起改
  ok   iso8601 策略解出的正是那一刻
  编码回蛇形 = {"created_at":"2023-11-14T22:13:20Z","nested":{"item_name":"x"},"user_id":9}
  ok   编码侧有对称的 convertToSnakeCase
  Date 的默认写法 = {"at":721692800}
  ok   1.7e9（自 1970）减去 978307200（1970→2001）= 721692800，这是参考系换轨不是 bug
  ok   ISO8601 策略输出可读日期
  ok   和后端对表时常用 millisecondsSince1970，别用默认的 timeIntervalSinceReferenceDate
  ok   .formatted(DateFormatter) 把「格式」交给 DateFormatter；它没有默认 locale，务必自己钉死
  ok   .custom 闭包自己写：这里把 Date 按「整秒」出，丢掉小数
  ok   两个可选都是 nil → 整个键消失，不是 "a":null
  ok   只出现非 nil 的那个
  ok   String 枚举直接编成它的 rawValue
  顶层字符串 = "字符串"；顶层数组 = [1,2,3]
  ok   JSONEncoder 允许顶层片段，OC 的 NSJSONSerialization 却只接对象/数组（05 章 §15）
  ok   默认把 / 转义成 \/（JSON 里斜杠转义是无害的装饰）
  ok   .withoutEscapingSlashes 关掉它；这是 outputFormatting 的一个选项，不是单独的属性
  ok   Double 按最短可回读形式出
  NaN 编码：domain=NSCocoaErrorDomain code=4866 「Unable to encode Double.nan directly in JSON.」
  ok   编码失败抛的是可 catch 的 EncodingError；它桥到 OC 侧落在 NSCocoaErrorDomain，原因写在 NSDebugDescription 里
  ok   无穷同样抛 EncodingError；可选字段里的 NaN 会连带整个 encode 失败
  ok   prettyPrinted：每个键各占一行，缩进由系统给
```

**（a）`sortedKeys` 决定「有没有唯一正确答案」**。结构体按 `CodingKeys`
（即声明顺序）出，所以不开也稳定；**字典**按哈希顺序出，每进程随机 ——
探针里同一份 `["z":1,"y":2,"x":3]` 连跑三次给出三种键序（§18 第 12 条）。
所以：快照测试、逐字节比对、缓存 key、Git 里提交的 JSON **必须**开
`[.sortedKeys]`。本章所有输出能双配置逐字节一致，靠的就是它。

**（b）键名映射有两种写法**：

```swift
// 逐个键手写
enum CodingKeys: String, CodingKey {
    case userId = "user_id"
    case fullName = "full_name"
}
// 整表策略
snakeDec.keyDecodingStrategy = .convertFromSnakeCase
snakeEnc.keyEncodingStrategy = .convertToSnakeCase
```

`convertFromSnakeCase` 会**连嵌套字典里的键一起改**（实测
`"nested":{"item_name":"x"}` 解成了 `NestedInfo(itemName:)`）。编码侧有对称的
`convertToSnakeCase`，实测输出：

```
编码回蛇形 = {"created_at":"2023-11-14T22:13:20Z","nested":{"item_name":"x"},"user_id":9}
```

**（c）日期策略是 Codable 最容易和后端打架的一处**。默认策略是
`timeIntervalSinceReferenceDate`（**自 2001-01-01 起的秒数**），实测：

```
Date 的默认写法 = {"at":721692800}
```

`1.7e9`（自 1970）减去 `978307200`（1970→2001 的秒差）正好等于 `721692800` ——
**这是参考系换轨，不是 bug**。§12 里会实测到这个差值本身。可选策略：

| 策略 | 输出 | 什么时候用 |
|---|---|---|
| 默认（`timeIntervalSinceReferenceDate`） | `{"at":721692800}` | 只在 Apple 自家 App 之间传 |
| `.iso8601` | `{"at":"2023-11-14T22:13:20Z"}` | 后端给的是 ISO 串 |
| `.millisecondsSince1970` | `{"at":1700000000000}` | 和 JS/Java 后端对表，**最常用** |
| `.formatted(DateFormatter)` | 自定义文本 | 格式已经由一个 `DateFormatter` 定义 |
| `.custom { date, encoder in … }` | 完全自己写 | 例如这里按整秒出、丢掉小数 |

`.formatted(...)` 有个陷阱：它**不会**继承你 App 里那个 DateFormatter 的默认
locale —— 传进去的 formatter 若没钉 `locale`/`timeZone`，输出就随机器变。
`.custom` 闭包里通常用 `singleValueContainer()` 直接 encode 一个标量。

**（d）可选字段的编码规则：nil 干脆不出现**。两个都是 `nil` → `{}`，
**不是** `{"a":null,"b":null}`；只有非 nil 的那个键会出现。这条要和 §10 的
解码侧（缺键 → `nil`）合起来看：**Swift 用「键不存在」表达 nil，
而不是用 JSON 的 `null`**。

**（e）枚举编成 `rawValue`**：`enum Kind: String, Codable { case light, dark }`
→ `{"kind":"dark"}`。

**（f）顶层片段**：`JSONEncoder` 允许把 `"字符串"` 或 `[1,2,3]` 直接编成顶层 JSON，
而 OC 的 `NSJSONSerialization` **只接对象/数组**（05 章 §15 实测那是抛异常）。
这是两侧不对称的一处。

**（g）斜杠转义与浮点**：默认把 `/` 转义成 `\/`（JSON 里无害的装饰），
要关掉写 `outputFormatting = [.sortedKeys, .withoutEscapingSlashes]` ——
它是 `outputFormatting` 的一个**选项**，不是单独的属性。`Double` 按
**最短可回读**形式出（`1.5` 就是 `1.5`，不会变成 `1.5000000000000002`）。

**（h）非有限浮点是唯一「编不出来」的常规值**，实测原文：

```
NaN 编码：domain=NSCocoaErrorDomain code=4866 「Unable to encode Double.nan directly in JSON.」
```

抛的是**可 catch 的 `EncodingError`**；它桥到 OC 侧落在 `NSCocoaErrorDomain`，
人类可读的原因写在 `userInfo[NSDebugDescriptionErrorKey]` 里
（`localizedDescription` 的话术更含糊，读崩溃日志建议取 debug description）。
`Double.infinity` 同样抛；**可选字段里的 NaN 会连带整个 `encode` 失败** ——
一个字段坏掉会让整份数据编不出来，这在「把传感器读数装箱上报」的场景里很致命，
要么先过滤非有限值，要么用 `.custom` 策略把它写成 `null`。

**（i）`prettyPrinted`**：每个键各占一行，缩进由系统给（所以只对
「有换行、行数 > 3」下断言，不把空格数写死）。

## 10) 解码失败：`DecodingError` 的四个 case

示例里写了一个 `decodeErr(_:_:)` 辅助函数，把九种输入各自解一遍，
**把错误原文打成行**（而不是断言「它失败了」）：

```swift
func decodeErr(_ label: String, _ json: String) -> String {
    do {
        let c = try JSONDecoder().decode(MXConf.self, from: Data(json.utf8))
        return "\(label) → ok name=\(c.name) port=\(c.port) tags=\(c.tags)"
    } catch let e as DecodingError {
        switch e {
        case .keyNotFound(let k, let ctx):
            return "\(label) → keyNotFound key=\(k.stringValue) path=\(ctx.codingPath.map { $0.stringValue })"
        case .typeMismatch(let t, let ctx): /* … */
        case .valueNotFound(let t, let ctx): /* … */
        case .dataCorrupted(let ctx): /* … */
        @unknown default: /* … */
        }
    } catch {
        return "\(label) → 其他错误 \(type(of: error))"
    }
}
```

实测九行：

```
-- 10) 解码失败：DecodingError 的四个 case --
  正常   → ok name=gw port=8080 tags=["a", "b"]
  缺 port → keyNotFound key=port path=[]
  port 是字符串 → typeMismatch want=Int path=["port"]
  port 为 null → valueNotFound nullFor=Int path=["port"]
  tags 混入整数 → typeMismatch want=String path=["tags", "Index 1"]
  多余键 → ok name=gw port=8080 tags=[]
  非 JSON → dataCorrupted path=[]
  空 Data → dataCorrupted path=[]
  顶层是数组 → typeMismatch want=Dictionary<String, Any> path=[]
```

对应断言：

```
  ok   字段齐全就正常解出
  ok   缺非可选键 → keyNotFound
  ok   类型不符 → typeMismatch
  ok   键在但值是 null，而非可选字段要不到值 → valueNotFound：和 typeMismatch 是**两个** case
  ok   整份数据不是 JSON → dataCorrupted
  ok   空 Data 也归 dataCorrupted
  ok   该给对象却给了数组 → typeMismatch（不是 dataCorrupted）
  ok   codingPath 里带数组下标：报的是 "Index 1"，直接告诉你第几个元素坏了
  ok   可选字段缺键 → nil：合成的解码器对 Optional 用 decodeIfPresent
  ok   显式 null 也是 nil：两条路同一个结果
  ok   decodeIfPresent + ?? 兜默认值：老数据里没有的字段自己补
  ok   有值时照用
  ok   逐条 try? 才能容错；一次性解 [MXInt] 会整包失败
  逐条解 = [1, -1, 3]
```

四个 case 的分工要背下来，因为**线上排障全靠 `codingPath`**：

| case | 触发条件 | 实测 path |
|---|---|---|
| `keyNotFound` | 缺**非可选**键 | `[]` —— 键名在 `codingKey` 里，`codingPath` 是空数组 |
| `typeMismatch` | 值的类型不对（**含顶层该给对象却给了数组**） | `["port"]`、`["tags", "Index 1"]`、`[]` |
| `valueNotFound` | 键**在**，但值是 `null` 而非可选字段要不到值 | `["port"]` |
| `dataCorrupted` | 整份数据不是 JSON / 空 `Data` | `[]` |

（`decodeErr` 的第一列标签是给人看的对齐文本，`path` 才是真实值：缺 `port` 时
`keyNotFound` 报的 `codingPath` 是**空数组**，键名在 `codingKey` 里 —— 这也是
为什么示例同时打了 `key=` 和 `path=`，只看一个会误判。）

三条最容易搞错的：

1. **`valueNotFound` 与 `typeMismatch` 是两个 case**。「`port` 是字符串」
   → `typeMismatch want=Int`；「`port` 为 `null`」→ `valueNotFound nullFor=Int`。
   很多教程把后者也归成类型错误，实际解码器给你的是不同的 case，
   分开处理才能把「后端没填」和「后端填错类型」在日志里区分开。
2. **`codingPath` 里带数组下标**，报的是 `"Index 1"` ——
   直接告诉你「`tags` 的第 2 个元素坏了」。这是 `DecodingError` 最好用的地方，
   一定要把 `codingPath` 打进日志。
3. **顶层给错类型是 `typeMismatch`，不是 `dataCorrupted`**：
   `want=Dictionary<String, Any>`（`[1]` 解 `MXConf`）。数据本身是好 JSON，
   只是形状不对。

可选字段的解码（与 §9 的编码规则成对）：

```swift
struct Opt: Codable { var a: String?; var b: Int }
// "{"b":1}"          → a == nil（缺键：合成 decoder 对 Optional 用 decodeIfPresent）
// "{"a":null,"b":1}" → a == nil（显式 null：两条路同一个结果）
```

手写 `init(from:)` 给老数据补默认值 —— 这是版本迁移的标准写法：

```swift
init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: Key.self)
    value = try c.decode(Int.self, forKey: .value)
    kind = (try c.decodeIfPresent(Kind.self, forKey: .kind)) ?? .light
}
```

最后一条容错规则：`JSONDecoder` 解 `[MXInt]` 时**一个元素坏掉整包失败**。
想要「坏一条丢一条」，必须自己逐条 `try?`：

```
逐条解 = [1, -1, 3]
```

（第 2 条是 `{"v":"x"}`，`try?` 给 `nil`，用 `?? -1` 标成无效行。）

## 11) 可选类型与 Foundation 的 nil

很多 Foundation / Swift 标准库 API **返回可选**：做不到就是 `nil`，
不抛、不崩。实测：

```
-- 11) 可选类型与 Foundation 的 nil --
  ok   Int(String) 失败返回 nil（可选）
  ok   带空格就解不出来：Swift 的 Int 不 trim，也不认千分位
  ok   字面量里的下划线只属于源码，不属于字符串
  ok   小数字符串解不成 Int
  ok   Double 认科学计数法
  ok   也不认千分位逗号
  ok   字典下标返回 Optional
  ok   ?? 给可选兜底
  ok   KVC 取回来是 Any?，必须 as? 才敢用
  ok   firstObject 是 Any?：空数组时为 nil，所以它天生可选
  ok   空数组的 firstObject/lastObject 都是 nil，不崩（05 章 §8 同一条）
  ok   可选链：环上是 nil 就整条 nil
  ok   compactMap 顺手把 nil 滤掉
  ok   joined() 摊平数组；空子数组自然消失
```

字符串转数字这组规则特别值得单列，因为「从 `UITextField` 拿到的文本」天天用：

| 输入 | `Int(...)` | `Double(...)` | 说明 |
|---|---|---|---|
| `"42"` | `42` | `42` | 正常 |
| `"abc"` | `nil` | `nil` | 失败返回可选 |
| `" 42 "` | `nil` | `nil` | **不 trim**，前后空格致命 |
| `"1_000"` | `nil` | `nil` | 源码字面量的下划线**不属于**字符串 |
| `"42.0"` | `nil` | `42` | 小数字符串解不成 `Int` |
| `"1e3"` | `nil` | `1000` | `Double` 认科学计数法 |
| `"1,234"` | `nil` | `nil` | **不认千分位**（要 `NumberFormatter`，见 §13） |

所以从输入框取数字的正确写法是**先 trim 再转**，并且准备好 `nil` 分支；
取「用户可能打逗号」的数字要走 `NumberFormatter`。

桥接回来的 OC API 一律带可选：

```swift
person.value(forKey: "name") as? String        // KVC 取回来是 Any?，必须 as? 才敢用
(NSArray(array: [1, 2])).firstObject as? Int    // firstObject 天生可选（空数组时为 nil）
(NSArray(array: [])).firstObject == nil         // 不崩（05 章 §8 同一条）
```

可选链 / `compactMap` / `joined()` 三条：

```swift
wNil.inner?.title                                   // 环上是 nil 就整条 nil
[wNil, wSome].compactMap { $0.inner?.title }         // ["t"]，顺手把 nil 滤掉
[[1, 2], [], [3]].joined()                           // 摊平，空子数组自然消失
```

> OC 的 `nil` 是「给 nil 发消息返回 0/nil，不崩」；Swift 的可选是**编译期强制**
> 你处理「可能没有值」。桥接时 OC 的 `nullable` → Swift `T?`，未标注 → `T!`
> （见第 07 章）。这两套 `nil` 语义在同一行代码里并存，是混合工程崩溃日志的
> 第一大来源。

## 12) Date / Calendar / DateFormatter / ISO8601

`Date` 只是一个时间点（无时区、无历法）。所有「看起来是日期」的东西都是
**格式化器 + 时区 + locale** 三个参数决定的。示例统一用
`Date(timeIntervalSince1970: 1_700_000_000)`（UTC `2023-11-14 22:13:20`）。

实测：

```
-- 12) Date / Calendar / DateFormatter / ISO8601 --
  ISO8601 默认 = 2023-11-14T22:13:20Z
  ok   ISO8601DateFormatter 默认就是「互联网日期时间」，恒为 UTC
  ok   同格式回读一致
  带小数秒 = 2023-11-14T22:13:20.500Z
  ok   小数秒要显式开 .withFractionalSeconds
  ok   默认配置的解析器遇到带小数秒的串直接给 nil：写出去读不回来是常见 bug
  ok   DateFormatter 按模板输出
  ok   按同一模板回读
  ok   格式对不上返回 nil（不是异常）
  不设 timeZone 时本机给：2023-11-15 06:13:20（跟随系统时区，不是可复现值）
  ok   **不设 timeZone 就跟随系统时区**：同一瞬间打出别的钟点，跨机器结果不同
  ok   设了 UTC 才有唯一答案：与 noTZ 只差一个 timeZone 一行代码
  2023-12-31 这一天：YYYY-MM-dd = 2024-12-31，yyyy-MM-dd = 2023-12-31
  ok   大写 YYYY 是「周年份」：12/31 落在 2024 那一周里，年份直接跳一年
  ok   小写 yyyy 才是日历年份
  dateComponents = y2023 m11 d14 时22 分13 weekday=3 季4
  ok   Calendar + TimeZone 定死，分量才可复现
  ok   weekday 从 1（周日）数起：11/14 是周二 → 3
  ok   1/31 加一个月**夹紧**到 2/29（2024 是闰年），不会滚到 3 月
  ok   「加 1 个月零 1 天」是另一回事：先加月再滚一天 → 3/1
  ok   减法同样夹紧
  ok   range(of:in:for:) 给的是该月天数范围（1..<32）
  ok   换成 2 月就是 29 天：闰年判断不用自己写
  ok   UTC 历法里一天 24 小时
  ok   dateInterval 给「所在周」的起止，end 是下一周的第一天（左闭右开）
  ok   这个 Calendar 的一周从周日开始；换 locale 会变（探针里量过）
  ok   compare 带粒度：按月看 1 月早于 2 月
  ok   1/31 → 3/1 相差 30 天
  ok   1/31 → 3/15 按「月」数只算 1 个整月：0 点和非 0 点起算会影响进位，这里起点是 UTC 零点
  ok   nextDate 找下一个匹配时刻：月末零点就是下月 1 号
  ok   7 月的纽约偏移 -4 小时（夏令时）
  ok   12 月是 -5 小时：查偏移必须带日期
  ok   同一瞬间，纽约是 17 点、UTC 是 22 点
  ok   认不出的时区名给 nil，不抛
  ok   固定偏移时区给缩写 GMT；带夏令时的时区缩写随日期变，所以别把它写进快照
  ok   1970 与 2001 两个参考系差 978307200 秒：Codable 默认日期策略就是靠它换轨的
  纽约 2024-03-10 这一天的真实长度 = 82800 秒
  ok   春令时切换日只有 23 小时（82800 秒）
  ok   秋令时切换日有 25 小时（90000 秒）
  ok   可 range(of: .hour, in: .day) 照样报 24：它给的是**理想范围**，那天真实小时数只能自己减
  ok   3/10 的 02:00 根本不存在：加两小时被推到 03:00
  ok   dateInterval(of: .day) 的 duration 才是那天真正的秒数
```

**（a）`ISO8601DateFormatter` 默认恒为 UTC**，给 `2023-11-14T22:13:20Z`。
小数秒要显式开 `.withFractionalSeconds`：写出去是
`2023-11-14T22:13:20.500Z`，**用默认配置的解析器读回来直接给 `nil`** ——
「自己写的串自己读不回来」是这个 API 最常见的 bug，成对配置才对。

**（b）`DateFormatter`**：按模板 `string(from:)`、按同模板 `date(from:)` 回读；
格式对不上（`"14/11/2023"`）返回 **`nil`**，不是异常。

**（c）不设 `timeZone` 就跟随系统时区**（本机 UTC+8），实测这行打的是
`2023-11-15 06:13:20` —— 同一瞬间打出别的钟点、还跨了一天。
和设了 UTC 的版本**只差一行代码**，但一个可复现一个不可复现。
所以本章所有 formatter 都从 §0 那两个钉死的实例拿。

**（d）大写 `YYYY` 是「周年份」**，这是 iOS 日期 bug 排行榜第一：

```
2023-12-31 这一天：YYYY-MM-dd = 2024-12-31，yyyy-MM-dd = 2023-12-31
```

`2023-12-31` 落在「2024 年的第一周」里，于是 `YYYY` 直接把年份跳了一年。
**永远用 `yyyy`**。同理 `DD`（一年中的第几天）、`mm`（分）与 `MM`（月）、
`hh`（12 小时制）与 `HH`（24 小时制）都是经典错处（05 章 §14 列过整张表）。

**（e）`Calendar` + `TimeZone` 定死，`DateComponents` 才可复现**：
`y2023 m11 d14 时22 分13 weekday=3 季4`。注意 **`weekday` 从 1（周日）数起**
（11/14 是周二 → 3），这套编号来自 OC 的 `NSCalendar` 传统，和 `Intl` 的
「周一为 1」不同；`firstWeekday` 随 locale 变（探针里量过），所以「第一周」
的定义也要钉。

**（f）月末加法是「夹紧」不是「滚动」**：

```
1/31 + 1 个月 → 2/29（2024 闰年），不会跑到 3 月
3/31 − 1 个月 → 2/29
1/31 + (1 个月零 1 天) → 3/1   ← 先加月夹到 2/29，再滚一天
```

第三条是「加一个月零一天」与「加一天再加一个月」不等价的实例，
做订阅周期、账期计算时必须写成 `DateComponents(month: 1, day: 1)` 一次给全。

**（g）`range(of:in:for:)` 给该月天数范围**：1 月 `1..<32`（31 天），
2024 年 2 月 29 天 —— **闰年判断不用自己写**。

**（h）`dateInterval(of: .weekOfYear, for:)` 给所在周的起止，`end` 是下周第一天**
（左闭右开）；`compare(_:to:toGranularity:)` 带粒度比较（按月看 1 月早于 2 月）；
`dateComponents([.day], from:to:)` 是**完整**单位数（1/31→3/1 是 30 天，
1/31→3/15 按「月」数只算 **1** 个整月 —— 起点是不是零点会影响进位，
例里起点是 UTC 零点）；`nextDate(after:matching:matchingPolicy:)` 找下一个
匹配时刻（月末找下一个零点 = 下月 1 号）。

**（i）时区偏移必须带日期查**：纽约 7 月 `-4*3600`、12 月 `-5*3600`（夏令时）。
同一瞬间纽约 17 点、UTC 22 点。`TimeZone(identifier: "Mars/Rome")` 给 **`nil`**，
不抛。固定偏移时区的 `abbreviation` 是 `GMT`；带夏令时的时区缩写随日期变
（`EDT`/`EST`），所以**别把缩写写进快照**。

**（j）两个参考系的差值实测**：

```swift
Date(timeIntervalSince1970: 0).timeIntervalSinceReferenceDate   // -978307200
```

`978307200` 就是 §9 里 `721692800` 的来源 —— Codable 默认日期策略靠它换轨。

**（k）夏令时切换日：一天不是 24 小时，而 `range` 照样报 24**。这是本节最
值得记住的一段：

```
纽约 2024-03-10 这一天的真实长度 = 82800 秒
```

- 春令时切换日**只有 23 小时**（`82800` 秒），秋令时切换日**有 25 小时**
  （`90000` 秒）；
- 可 `range(of: .hour, in: .day, for:)` 仍然给 **24** —— 它给的是**理想范围**，
  那天的真实小时数只能自己拿两个正午相减，或者用
  `dateInterval(of: .day, for:).duration`（实测 `82800`，才是真正秒数）；
- 2024-03-10 的 **`02:00` 根本不存在**：从零点加两小时被推到 `03:00`
  （`matchingPolicy` 决定了这类「不存在的时间」怎么落地）。

> 凡是「倒计时」「工作时长」「按天聚合」的逻辑，跨夏令时就会差一小时。
> 安全做法：用 `Calendar` 的 `dateInterval` 拿真实 duration，别用
> `24 * 3600` 这个常量。

## 13) NumberFormatter 一族：格式随 locale 走，解析也随 locale 走

```swift
let nfPosix = NumberFormatter(); nfPosix.numberStyle = .decimal; nfPosix.locale = posix
let nfEn = NumberFormatter(); nfEn.numberStyle = .decimal; nfEn.locale = Locale(identifier: "en_US")
let bigNum = NSNumber(value: 1234567)
```

实测：

```
-- 13) NumberFormatter 一族：格式随 locale 走，解析也随 locale 走 --
  同一个数：en_US_POSIX=1234567 en_US=1,234,567
  ok   POSIX locale 连分组都不做——它是「机读」用的，不是「美式」用的
  ok   en_US 解得动自己写出来的串
  ok   POSIX 解不动 en_US 写的带逗号串：格式化和解析必须用**同一个** formatter
  currency：en_US_POSIX="$ 12.50" en_US="$12.50"
  ok   currency 风格只断言「以 $ 开头 + 含数字」：符号和符号与数字之间那个空格都由 locale 给，写死必翻车
  ok   percent 风格吃的是**比值**，不是百分数：0.1 → 10%
  ok   spellOut 风格
  ok   ordinal 风格
  ok   scientific 风格，小数位数由 maximumFractionDigits 管
  ok   超过最大小数位就**四舍五入**（和 NSNumber 截断成 int 那条规则不同）
  ok   NSNumber 里的 bool 也能按数字格式化
  DateComponentsFormatter .positional(3720 秒) = 1:02:00
  ok   positional 风格是唯一接近「机器可读」的那档：小时:分钟:秒
  ok   高位为零时干脆不写：45 秒就是 "45"，不是 "0:0:45"
  ok   零秒是 "0"
  ByteCountFormatter(.useMB, .file, 1536000) = 1.5 MB
  ok   字节格式化：单位与进位由 countStyle 决定（.binary 走 1024，.decimal 走 1000）
  同一个值：.binary=1,500 KB .decimal=1,536 KB
  ok   1024 与 1000 两种进位给的字符串不一样
  String(format: "%.2f")：de_DE=12,50 posix=12.50
  ok   小数点/逗号由 locale 决定——05 章 §2 的说明符表在这里同样成立
  ok   1000 米换公里：换算走 Measurement，别自己乘除
  ok   摄氏 100 = 华氏 212：温标有偏移量，不能用比例函数蒙
```

**（a）`en_US_POSIX` 连分组都不打**。同一个 `1234567`：POSIX 给 `1234567`，
`en_US` 给 `1,234,567`。**POSIX 是「机读」不是「美式」** —— 这条最容易被
「反正都是英文」绕过，然后把不可复现的输出写进快照。

**（b）格式化和解析必须用同一个 formatter**：`en_US` 解得动自己写出来的
`1,234,567`，而 POSIX **解不动**它（给 `nil`）。所以「用 A formatter 写、
用 B formatter 读」在数字上和 §12 的日期「写出去读不回来」是同一类 bug。

**（c）`currency` 风格断言只能对结构下**。实测两个 locale 的输出：

```
currency：en_US_POSIX="$ 12.50" en_US="$12.50"
```

POSIX 在符号与数字之间塞了一个**不换行空格**（U+00A0），`en_US` 没有。
所以断言写成 `hasPrefix("$") && contains("12.50")`，**不能**写死整串 ——
符号、位置、空格全由 locale 给，德语下是 `12,50 €`（符号在后）。

**（d）其余风格**：`percent` 吃的是**比值**（`0.1` → `"10%"`，不是 `10` → `10%`）；
`spellOut` 把 `2345` 写成 `"two thousand three hundred forty-five"`；
`ordinal` 把 `3` 写成 `"3rd"`；`scientific` 给 `1.23E+004`（小数位数由
`maximumFractionDigits` 管）；超过最大小数位是**四舍五入**
（`1234.567` + `maximumFractionDigits = 1` → `1234.6`）——
这和 §7 里 `intValue` 的**向零截断**是两条不同规则，很容易记混。
`NSNumber(value: true)` 也能按数字格式化（不返回 nil）。

**（e）`DateComponentsFormatter` / `ByteCountFormatter` 根本没有 `locale` 属性**
（探针确认；原文见 §18 第 13 条）。它们的输出直接跟系统语言：本机 `zh_CN` 下
`.abbreviated` 给「1小时2分钟」、`.spellOut` 给「一小时二分钟」。
本章因此只对**结构**下断言：

- `.positional` 是唯一接近「机器可读」的那档：`3720` 秒 → `1:02:00`；
- **高位为零时干脆不写**：`45` 秒就是 `"45"`，不是 `"0:0:45"`；`0` 秒是 `"0"`。
  这两条对做「剩余时间」显示的 UI 很关键（宽度会跳）。
- `ByteCountFormatter`：单位由 `allowedUnits` 限、进位由 `countStyle` 定 ——
  `.binary` 走 1024、`.decimal` 走 1000，同一个 `1_536_000` 分别给
  `1,500 KB` 和 `1,536 KB`。`.file` 风格在本机走的是 1000 进位（Apple 对
  「磁盘容量」用十进制的既定策略），所以 `1536000` 显示 `1.5 MB`。
  **存储用量、下载进度必须统一选一种**，否则「用户看到的 MB」和
  「接口返回的 bytes」永远差 7%。

**（f）`String(format:)` 也吃 locale**：`%.2f` 配 `de_DE` 给 `12,50`，
配 POSIX 给 `12.50` —— 05 章 §2 那张说明符表在这里同样成立（Swift 的
`String(format:locale:_:)` 直接走 `CFStringCreateWithFormat`）。

**（g）单位换算走 `Measurement`**，别自己乘除：

```swift
Measurement(value: 1000, unit: .meters).converted(to: .kilometers).value   // 1
Measurement(value: 100, unit: .celsius).converted(to: .fahrenheit).value    // 212
```

摄氏→华氏**有偏移量**（`×9/5 + 32`），所以「用比例函数蒙」必然错；
`Measurement` 同时管住了量纲（`UnitLength`、`UnitMass`、`UnitTemperature`…，
在 CoreFoundation/UIKit 一侧）。要给用户看的话再加 `MeasurementFormatter` ——
它的输出随 locale 变，本章没有用它下断言。

## 14) JSONSerialization / plist / NSKeyedArchiver / UserDefaults

Swift 里照样能走 OC 的 `Any` 路线（05 章 §15 的对照）：

```swift
let obj: [String: Any] = ["n": 1, "s": "x", "arr": [1, 2]]
let jsonAny = String(data: try! JSONSerialization.data(withJSONObject: obj,
                                                       options: [.sortedKeys]), encoding: .utf8)!
```

实测：

```
-- 14) JSONSerialization / plist / NSKeyedArchiver / UserDefaults --
  JSONSerialization = {"arr":[1,2],"n":1,"s":"x"}
  ok   Any 路线照旧可用，options 里同样是 sortedKeys
  读坏 JSON：domain=NSCocoaErrorDomain code=3840
  ok   读失败是 Swift 可 catch 的 error（05 章同一条：读坏给 error，写坏抛异常）
  ok   JSON 的 null 在 Any 世界里是 NSNull，**不是** Swift 的 nil
  ok   字典 + 数组是合法 plist
  ok   Date 是 plist 的原生类型（JSON 就得分手写成字符串/数字）
  ok   解回来的日期仍是 Date
  ok   二进制 plist 以 bplist 开头
  ok   归档/解档往返（要写 encode(with:) 与 required init?(coder:)）
  用错类解档：domain=NSCocoaErrorDomain code=4864 提到类型不符
  ok   用错的类去解**是抛错**（4864），不是给 nil：安全解档宁可报错也不给你意外的对象
  解一份假归档：domain=NSCocoaErrorDomain code=4864 只说格式不对
  ok   坏归档数据同样抛 error，不是崩
  ok   整数存取
  ok   字符串数组存取
  ok   没存过的键给 0/false：**取不出「没这个键」和「存了 0」的区别**
  ok   string(forKey:) 会替你把数字转成字符串（7 → 「7」），这不是类型安全的读法
  ok   object(forKey:) 才保留原类型
  ok   removeObject 之后真没了
```

**（a）读失败与写失败不对称**（和 05 章同一条）：**读**坏数据给的是 Swift
**可 catch 的 `error`**：

```
读坏 JSON：domain=NSCocoaErrorDomain code=3840
```

而**写**非法类型（比如往字典里塞 `Date`）在 Swift 里抛的是 **OC 异常**，
`do/catch` **接不住**（§18 第 7 条实测 signal 6）。所以「写 JSON 之前先确认
值类型合法」不是建议而是必须 —— 这一条把 05 章的结论在 Swift 侧重新画了一遍：
**跨语言调用的容错边界，Swift 的 `catch` 只覆盖 `Error`，不覆盖 `NSException`。**

**（b）JSON 的 `null` 在 `Any` 世界里是 `NSNull`，不是 Swift 的 `nil`**。
`backNull["a"] is NSNull` 为真而 `backNull["a"] != nil` 也为真 ——
「键存在但值是 NSNull」和「键不存在」在字典下标上都能给你非 nil，
必须显式 `is NSNull` 判断。走 `Codable` 就没这个麻烦（§10：`null` → `Optional`）。

**（c）plist 是 iOS 的本地存储底座**（`UserDefaults` 背后就是它）：

```swift
PropertyListSerialization.propertyList(["a": 1, "b": ["x"]], isValidFor: .binary)   // true
PropertyListSerialization.propertyList(["d": Date()], isValidFor: .xml)             // true
```

**`Date` 是 plist 的原生类型**，JSON 就得分手写成字符串或数字 —— 这是选 plist
还是 JSON 的第一个理由。注意 API 名是 `isValidFor:`（`isValidForFormat:` 不存在）；
`.json` 也**不是** `PropertyListFormat` 的成员。二进制 plist 以 `bplist` 开头
（前 6 字节就是 magic，可以拿来判类型）。

**（d）`NSKeyedArchiver` 在 Swift 侧要求 `NSSecureCoding`**：

```swift
let archived = try! NSKeyedArchiver.archivedData(withRootObject: MXDoc(title: "t", n: 5),
                                                 requiringSecureCoding: true)
let unarchived = try! NSKeyedUnarchiver.unarchivedObject(ofClass: MXDoc.self, from: archived)
```

要写 `encode(with:)` 与 `required init?(coder:)`，并提供
`static var supportsSecureCoding: Bool { true }`。

关键实测：**用错的类去解是抛错，不是给 `nil`**：

```
用错类解档：domain=NSCocoaErrorDomain code=4864 提到类型不符
解一份假归档：domain=NSCocoaErrorDomain code=4864 只说格式不对
```

（示例里那个 `unarchiveErr` 辅助函数刻意**把原文里的对象地址和镜像路径剥掉**，
只留「提到类型不符 / 只说格式不对」这个结论词 —— 快照不能带地址。）
安全解档的设计意图是**宁可报错也不给你一个意外的对象**，所以
`try? NSKeyedUnarchiver…` 会把「类型不符」和「数据坏了」都糊成 `nil`，
排障时务必 `do/catch` 打印 `domain` + `code`。

**（e）`UserDefaults` 的四个实测结论**（headless 环境照样能用，套件名自己给、
不写进输出）：

```swift
let defaults = UserDefaults(suiteName: "iosdev.tutorial.06.selftest")!
defaults.set(7, forKey: "mx.int"); defaults.set(["a", "b"], forKey: "mx.arr")
```

1. `integer(forKey:)` / `array(forKey:) as? [String]` 正常存取。
2. **没存过的键给 `0` / `false`** —— 你**取不出**「没这个键」和「存了 0」的区别。
   要区分只能 `object(forKey:) != nil`（或 `persistentDomain` 查）。
   这条决定了「开关默认值」的写法：不要用 `bool(forKey:)` 的默认 `false` 当
   「用户没选过」。
3. `string(forKey:)` 会替你把数字转成字符串（`7` → 「7」），
   **这不是类型安全的读法**；要保类型用 `object(forKey:)`（实测 `is Int` 为真）。
4. `removeObject(forKey:)` 之后 `object(forKey:)` 真变 `nil`。

## 15) NotificationCenter、KVC、KVO 与 `@objc` 动态派发

```swift
let token = NotificationCenter.default.addObserver(forName: noteName, object: nil, queue: nil) { note in
    if let v = note.userInfo?["v"] as? String { received.append(v) }
}
NotificationCenter.default.post(name: noteName, object: nil, userInfo: ["v": "1"])
NotificationCenter.default.removeObserver(token)
```

实测：

```
-- 15) NotificationCenter、KVC、KVO 与 @objc 动态派发 --
  ok   移除观察者之后就收不到通知了
  ok   Notification.Name 是值类型，按字符串比相等
  ok   object 非 nil 时是**按发送者过滤**；nil 的那个观察者两次都收到
  ok   同步投递：post 调用返回的那一刻，三个观察者块已经全部跑完
  ok   setValue/value 走的是 OC 那套按字符串找属性的机制，要求属性 @objc
  ok   KVC 写的就是真属性，不是另存一份
  ok   responds(to:) 问方法在不在
  ok   没有的方法给 false，不崩
  ok   perform 回来的是 Unmanaged，得手动 takeUnretainedValue
  ok   带一个参数就 with: 传进去（参数必须是对象类型）
  ok   observe(\.) 的块被调了两次
  ok   块式 KVO **不**经过 observeValue(forKeyPath:)：两套机制各走各的
  ok   invalidate 之后不再收到
  ok   自己直接调 observeValue 才会计数——它平时不会被块式 KVO 调用
  ok   Swift 原生类型/结构体完全不参与 KVC/KVO，一切得先过 @objc 这道门
```

**（a）观察者要自己移除**。`addObserver(forName:object:queue:using:)` 返回一个
**token**，移除时要拿它去 `removeObserver(token)`；block 版观察者在对象 dealloc
时**不会**自动失效 —— 忘记移除就是悬挂回调（iOS 17 起可以走
`addObserver(forName:object:queue:inherit:` 与 `withObservationTracking`，
但 token 版仍是主流）。

**（b）`Notification.Name` 是值类型**，按字符串比相等（`== Notification.Name("mx.demo")`
成立）。它只是包了一个 `String`，所以自定义名字要**全局唯一 + 常量化**，
拼错不会有编译期警告。

**（c）`object:` 是过滤器，`nil` 是「不限」**。实测这段最能说明投递规则：
一个观察者限定 `srcA`，一个不限；先 `post(object: srcA)` 再 `post(object: srcB)`，
收到的序列是 `["限定A", "不限", "不限"]` —— 限定 A 的那个只命中一次，
**不限的那个两次都命中**。别把 `object: nil` 理解成「只收无发送者的通知」。

**（d）`queue: nil` = 就在 posting 线程同步回调**。所以 `post` 调用返回的那一刻，
三个观察者块已经全部跑完（示例据此断言计数）。
如果传 `OperationQueue.main`，就得等主 runloop —— **headless 自测里没有 runloop，
一条都收不到**。这是本章示例必须用 `nil` 的原因，也是所有「通知在单元测试里
没触发」的原因。

**（e）KVC 在 Swift 侧要求 `@objc`**：

```swift
p15.setValue("Ada", forKey: "name")
p15.value(forKey: "name") as? String       // "Ada"
```

`setValue` / `value` 走的是 OC 那套**按字符串找属性**的机制（找 setter / ivar），
所以属性必须 `@objc`；写的就是真属性，不是另存一份（`p15.name == "Ada"`）。
键名写错会抛 `NSUnknownKeyException`（§18 第 8 条），而
`value(forKeyPath: "name.count")` 同样抛 —— `String.count` 是 Swift 成员，
KVC 那套按 OC 选择器找属性的机制**看不见它**（§18 第 9 条）。

**（f）动态派发**：

```swift
p15.responds(to: #selector(MXPerson.greet))                       // true
p15.responds(to: NSSelectorFromString("noSuchMethod"))             // false，不崩
p15.perform(#selector(MXPerson.greet))?.takeUnretainedValue()      // "你好 Ada"
p15.perform(#selector(MXPerson.shout(_:)), with: "go")?.takeUnretainedValue()  // "GO"
```

`perform` 回来的是 **`Unmanaged<AnyObject>?`**，必须手动
`takeUnretainedValue()`（或 `takeRetainedValue()`）才拿得到 Swift 对象。
带一个参数的选择器用 `with:`，**参数必须是对象类型**（不能传 `Int`，要 `NSNumber`）。
`NSSelectorFromString` 用来测「不存在的方法」；写 `Selector(("..."))` 会有
`use '#selector' instead` 的警告，判定 1（编译日志必须为空）就过不了。

**（g）块式 KVO 与老式 `observeValue(forKeyPath:)` 是两套机制**：

```swift
let obs = model.observe(\.count, options: [.new]) { obj, change in obj.blockHits += 1 }
model.count = 1; model.count = 2
// blockHits == 2，legacyHits == 0
obs.invalidate()
model.count = 3          // 不再收到
model.observeValue(forKeyPath: "count", of: model, change: nil, context: nil)  // 手工调才计数
```

实测三条：`observe(\.)` 的块被调两次；块**不经过** `observeValue`（`legacyHits`
仍是 0）；`invalidate()` 之后不再收到，而 `legacyHits` 只在**自己直接调用**时才变 1。
前提是属性 `@objc dynamic`（§0 说过），且**观察对象必须持有 `obs`**，
它一被释放观察就没了。

**（h）Swift 原生类型/结构体完全不参与 KVC/KVO** —— 一切得先过 `@objc` 这道门。
这是 Swift 与 OC 混合工程里最硬的一条边界：`struct`、`enum`、泛型、
非 `@objc` 的 `class` 成员，运行时那套按名字找东西的机制一概看不见
（第 27 章会从 runtime 角度再讲一遍）。

## 16) URL、URLComponents 与 FileManager

```swift
let fm = FileManager.default
let dir = fm.temporaryDirectory.appendingPathComponent("iosdev-06-\(UUID().uuidString)", isDirectory: true)
try! fm.createDirectory(at: dir, withIntermediateDirectories: true)
let fileURL = dir.appendingPathComponent("a.txt")
try! "hello".data(using: .utf8)!.write(to: fileURL)
```

实测：

```
-- 16) URL、URLComponents 与 FileManager --
  ok   文件写出来了
  ok   读回来内容一致
  ok   URL 有 pathExtension
  ok   deletingPathExtension 取主名
  ok   contentsOfDirectory 只给这一层，排序后可复现
  ok   想区分目录就用 isDirectory 出参
  ok   temporaryDirectory 出来的是 file:// URL；HTTP 那份才是 URL(string:) 造的
  ok   standardizedFileURL 把已是规范形式的临时目录原样返回
  ok   临时目录已删除
  queryItems = ["n=1", "name=张三"]
  ok   queryItems 把 & 串拆成对，值自动解码（顺序不保证，先 sorted 再比）
  ok   percentEncodedQuery 给的是编码形态
  拼出来的 URL = https://e.com/a%20b?q=a%20b%26c
  ok   自己拼 URL 时空格与 & 由 URLComponents 负责转义
  ok   转义过的 & 不会在解析时被当成分隔符：往返安全
  ok   URL(string:) 会顺手把空格补上转义
  ok   彻底拼不出结构的串给 nil（不是崩）
  ok   相对解析会**吃掉基址的最后一段**：c 不是目录，除非基址以 / 结尾
  ok   只给 query 时路径整体保留
  ok   .. 让上一级真的生效
  ok   **坑**：standardized 先对相对串做规范化，.. 被折掉，结果退回 a/b 下面去了
  ok   appendingPathComponent 里带斜杠会被照单收下（它只管拼接）
  ok   appendingPathExtension 加的是扩展名
```

**（a）FileManager 部分**：`URL` **不是 `String`**，iOS 文件 API 一律收 `URL`
（`file://`），拼接用 `appendingPathComponent`，`.path` 才是 POSIX 路径。
`contentsOfDirectory(at:includingPropertiesForKeys:options:)` **只给这一层**
（顺序不保证，先 `sorted()` 再断言）；要区分目录用 `fileExists(atPath:isDirectory:)`
的出参。临时目录用完自己 `removeItem`（示例还实测了
`standardizedFileURL` 对已规范路径是原样返回）。UUID 只出现在**目录名**里，
不出现在输出里 —— 这是「不打印环境相关量」的规矩。

**（b）`URLComponents` 才是拼 URL 的工具**：

```swift
let urlComps = URLComponents(string: "https://e.com/p?name=张三&n=1")!
urlComps.queryItems          // [(name, value)]，值已自动解码
urlComps.percentEncodedQuery // "name=%E5%BC%A0%E4%B8%89&n=1"
```

`queryItems` 的顺序**不保证**（实测 sorted 之后是 `["n=1", "name=张三"]`）。
自己拼的时候空格和 `&` 由它负责转义：

```
拼出来的 URL = https://e.com/a%20b?q=a%20b%26c
```

关键一条：**转义过的 `&` 不会在解析时被当成分隔符**（往返安全）。
反过来，用字符串手拼 `"...&q=a b&c"` 就会把 `&c` 当成新参数 ——
这就是「query 里带 `=`/`&`/中文一定要走 `URLComponents`」的实测依据。
`URL(string:)` 会顺手把空格补上转义（`"https://e.com/a b"` →
`https://e.com/a%20b`），彻底拼不出结构的串（`"// ::"`）给 **`nil`**，不是崩。

**（c）相对解析的两个坑**：

```swift
let base = URL(string: "https://e.com/a/b/c")!
URL(string: "sub", relativeTo: base)!.absoluteURL    // https://e.com/a/b/sub  ← 吃掉了 c
URL(string: "?x=1", relativeTo: base)!.absoluteURL   // https://e.com/a/b/c?x=1 ← 路径整体保留
URL(string: "../x", relativeTo: base)!.absoluteURL   // https://e.com/a/x
```

第一条是 RFC 3986 的规则：**基址的最后一段是「文件名」不是目录**，
相对解析会吃掉它；要让 `sub` 落在 `c/` 下面，基址必须以 `/` 结尾。
第二条更阴：

```swift
upURL.standardized.absoluteString     // https://e.com/a/b/x   ← 期望是 a/x
```

**`standardized` 先对「相对串」做规范化，`../x` 里的 `..` 被折掉，
结果退回 `a/b` 下面去了。** 要做路径规范化只能对**绝对 URL**
（`.absoluteURL`）再 `standardized`。

**（d）两个 appending 的区别**：`appendingPathComponent("a/b.txt")` 里带斜杠
会被**照单收下**（它只管拼接，不校验）；`appendingPathExtension("log")`
加的是**扩展名**（实测 `URL(fileURLWithPath: "/tmp").appendingPathExtension("log")`
的最后一段是 `tmp.log`）。

## 17) NSAttributedString：UIKit 那几章要用的富文本，长度仍是码元

第 14、15、22 章里 `UILabel`、`UITextView`、富文本表格都要用它。
它的下标体系是 **`NSRange`**，所以 05 章那条「`length` 是 UTF-16 码元」
在 Swift 侧同样成立：

```swift
let attr = NSMutableAttributedString(string: "红色加粗")
attr.addAttribute(.foregroundColor, value: UIColor.systemRed, range: NSRange(location: 0, length: 2))
attr.addAttribute(.font, value: "粗", range: NSRange(location: 0, length: 2))
attr.addAttribute(.font, value: "细", range: NSRange(location: 2, length: 2))
```

实测：

```
-- 17) NSAttributedString：UIKit 那几章要用的富文本，长度仍是码元 --
  ok   NSAttributedString.length 数的是**码元**（05 章同一条），这里四个汉字刚好四个
  ok   按下标取属性：第 1 个字符落在「粗」这一段
  ok   第 3 个字符已经是「细」
  ok   没设过的属性取回来是 nil，不是默认色
  ok   带 effectiveRange 出参，顺带告诉你这个值管到哪：0 起、长 2
  ok   enumerateAttribute 按「属性变化的边界」切段：两段各 2 个字符
  ok   append 拼的是属性串，字符串部分照常连起来
  ok   新段带着自己的属性进来，旧段不受影响
  ok   前两个字符仍然没有这个属性
  逐段 = ["0+2=2", "2+2=-1", "4+2=2"]
  ok   整段设一个属性再挖掉中间两格 → 属性段从 1 段变 3 段（有-无-有）
  ok   每段的起止与值都能读回来：位置 2、3 的 kern 真没了
  ok   换一种改法（先设 [1,3) 再挖掉中间 1 格）却是 5 段：段数按内部记录切，不按「值有没有变」切
  ok   纯文本的 attributes 是空字典，不是 nil
```

逐条：

- `attr.length` 数的是**码元**；四个汉字刚好四个，看不出来 ——
  一旦文本里进 emoji，`location`/`length` 就得按 2 来给（§1 的换算在这里必须用）。
- **`attribute(_:at:effectiveRange:)`** 是按下标取值的主力：
  第 1 个字符落在「粗」段、第 3 个已经是「细」；**没设过的属性取回来是
  `nil`，不是默认色**（`nil` 表示「这一段没有这个属性」，UI 上会退回控件默认值）。
  `effectiveRange:` 给 `UnsafeMutablePointer<NSRange>?`，顺带告诉你这个值
  **管到哪**（实测 `0 起、长 2`）。
- **`enumerateAttribute(_:in:using:)` 按「属性变化的边界」切段**：
  例里两段、各 2 个字符。这是做富文本高亮、逐段测量、拼 `NSAttributedString`
  预览的标准遍历。
- **`append(_:)` 拼的是属性串**：新段带着自己的属性进来，旧段不受影响
  （实测 `attribute(.init("k"), at: 0)` 仍是 `nil`）。
- **段数不是按「值有没有变」切的，而是按内部记录切的**。两条实测对照：

  ```
  逐段 = ["0+2=2", "2+2=-1", "4+2=2"]
  ```

  整段 `[0,6)` 设 `kern = 2` 再挖掉中间 `[2,4)` → **3 段**（有-无-有）；
  但先设 `[1,4)` 再挖掉 `[2,3)` → **5 段**。属性值看起来一样的相邻段，
  在内部仍是两条记录。所以任何依赖「段数」的逻辑都不要把它当常量假设；
  要合并得自己重排（`setAttributes` 整段重写最稳）。
- **纯文本的 `attributes(at:effectiveRange:)` 是空字典，不是 `nil`**。

> 富文本这一节把 §1、§3 的结论收口了：**`String` 的世界用 `Index`，
> `NSAttributedString` 的世界只用 `NSRange`**。跨过去时
> `(s as NSString).length` 算长度、`NSRange(swiftRange, in: s)` 换算范围，
> 反过来一定要 `Range(_:in:)` 并处理 `nil`。

## 18) 探针记录：这些行为会崩 / 会随机器变，只在独立探针里量

示例必须跑在六条判定里（编译日志为空、退出码 0、stderr 为空、stdout 非空、
无控制字符、有结束标记，外加 debug/release 逐字节一致）。所以
**会崩的、会乱的、随机器变的**都先用独立探针量出来，原文抄在这里 ——
这一段是本章最该读的：它们全是**你在真实项目崩溃日志里会一字不差看到的消息**。

```
-- 18) 探针记录：这些行为会崩/会随机器变，只在独立探针里量 --
  1) 强制解包 nil（opt!）：Fatal error: Unexpectedly found nil while unwrapping an Optional value，进程收 signal 4。
  2) Swift 数组越界（a[5]）：Swift/ContiguousArrayBuffer.swift 报 Fatal error: Index out of range，signal 4。
     这和 05 章 OC 的 NSRangeException 不是一回事：OC 那边是异常，能 @try 接住；Swift 这边是 trap，接不住。
  3) 整数溢出（Int.max + 1）：signal 4。-Onone 与 -O **都**陷阱；且这行的 Fatal error 文本没进 stderr，只在崩溃报告里。
  4) index(_:offsetBy:) 越界：探针里对「abc」偏移 99 得到 Swift/StringCharacterView.swift: Fatal error: String index is out of bounds，signal 4。
     示例里只用带 limitedBy: 的重载，它给 nil。
  5) NSArray as! [Int]（元素是 NSString）：Could not cast value of type 'NSTaggedPointerString' to 'NSNumber'，signal 6。
     注意括号里的类型名是 NSNumber：Swift 的 Int 桥过去就是它。地址每次都不同，此处只记类型名。
  6) [String: Any] as! [String: String]：Could not cast value of type 'Swift.Int' to 'Swift.String'。
     同一个 as! 失败，桥接来的容器报 OC 类名、Swift 原生容器报 Swift 类型名——读崩溃日志时用得上这条经验。
  7) Swift 的 do/catch **接不住** OC 异常：探针里 JSONSerialization.data(withJSONObject: ["d": Date()])
     抛 NSInvalidArgumentException（Invalid type in JSON write (__NSTaggedDate)），catch 没反应，进程 signal 6。
     05 章里同一件事在 OC 可以 @try 接住；跨语言调用的容错边界要按这条重新画。
  8) value(forKey:) / setValue(_:forKey:) 用错键：NSUnknownKeyException。示例里那行故意不做取值。
  9) value(forKeyPath: "name.count")：同样 NSUnknownKeyException，reason 里 valueForUndefinedKey: 说的就是 key count。
     Swift 的 String.count 是 Swift 成员，KVC 那套按 OC 选择器找属性的机制看不见它。
  10) NSMutableArray.insert(_:at:) 下标越界：NSRangeException（index 9 beyond bounds [0 .. 0]），signal 6。
  11) [String] as NSSet 编译不过：cannot convert value of type '[String]' to type 'NSSet' in coercion。
      Array 只能桥 NSArray，要 NSSet 得先 Set(...)。同理 [String: Int] as NSMutableDictionary 也编译不过。
  12) Swift 的哈希种子每次启动随机：同一份代码连跑三次，Array(Set) 给出三种顺序、
      Array(dict.keys) 三种、不带 sortedKeys 的字典 JSON 三种（探针实测）。同一进程内则稳定。
      所以本章凡是打印出来的集合都排过序，测试里也别拿 Set 的顺序写断言。
  13) DateFormatter 不设 timeZone 就跟随系统时区（本机 UTC+8），NumberFormatter 的分组符号随 locale 变，
      DateComponentsFormatter / ByteCountFormatter 干脆没有 locale 属性：本机 zh_CN 下 .abbreviated 给「1小时2分钟」、
      .spellOut 给「一小时二分钟」。要可复现输出只能自己钉 locale + 时区，或像本章只对结构做断言。
  14) NSDateFormatter 的五档 style 依赖 ICU 版本（05 章 §14 同条），本机的具体字符串不写进断言。
```

把 14 条归成四类：

**（a）Swift 的 trap 与 OC 的异常是两回事**（第 1、2、3、4 条）。
强制解包 `nil`、数组越界、`index(offsetBy:)` 越界、整数溢出都是 `Fatal error` + signal 4，
**`do/catch` 接不住**；而 OC 那边（05 章）是 `NSRangeException`，`@try` 能接。
所以「用 Swift 包一层 OC 的容错」这件事，边界要重新画。第 3 条还多一个坑：
整数溢出在 `-Onone` 与 `-O` **都**陷阱，但那行 `Fatal error` 文本**不进 stderr**，
只在崩溃报告里 —— 指望「日志里能看到溢出原因」是靠不住的。

**（b）`as!` 失败的两副面孔**（第 5、6 条）。同一个 `as!` 桥接失败，
**桥接来的容器报 OC 类名**（`NSTaggedPointerString` → `NSNumber`），
**Swift 原生容器报 Swift 类型名**（`Swift.Int` → `Swift.String`）。
读崩溃日志时这条经验直接决定你能不能一眼看懂。另外注意第 5 条括号里是
`NSNumber`：Swift 的 `Int` 桥过去就是它。

**（c）`do/catch` 接不住 OC 异常**（第 7、8、9、10 条）。
`JSONSerialization.data(withJSONObject: ["d": Date()])` 抛
`NSInvalidArgumentException`，Swift 的 `catch` 完全没反应，进程 signal 6 ——
而 05 章里同一件事在 OC 可以 `@try` 接住。KVC 键名错（`NSUnknownKeyException`）、
`NSMutableArray` 下标越界（`NSRangeException`）同理。

**（d）不可复现的三类来源**（第 11、12、13、14 条）：
两处**编译不过**的桥接写法（`[String] as NSSet`、
`[String: Int] as NSMutableDictionary`）；**哈希种子每进程随机**导致
`Array(Set)`、`Array(dict.keys)`、未开 `sortedKeys` 的字典 JSON 三种顺序；
`DateFormatter` 不设 timeZone 跟系统时区、`DateComponentsFormatter` /
`ByteCountFormatter` 没有 `locale` 属性、`NSDateFormatter` 的五档 style
依赖 ICU 版本。

> **写测试时的三条硬规矩**（都是上面这些实测换来的）：
> 1. 断言集合内容用 `sorted()` 或 `Set` 的**成员关系**，永远不断言顺序；
> 2. 快照 JSON 必开 `.sortedKeys`；
> 3. 一切格式化输出先钉 `locale` + `timeZone`，钉不住的（那三个没有 locale
>    属性的 formatter）只对**结构**（前缀、是否含分隔符、相对长短）下断言。

## 坑清单

| 现象 | 原因 / 结论 |
|---|---|
| 同一串内容 `count` 和 `length` 不一样 | `count` 是字符（grapheme），`length` 是 UTF-16 码元；emoji/国旗/组合点全会差 |
| `text.count` 在循环里很慢 | Swift 的 `count` 是 **O(n)**（要跑字素簇边界算法）；先存常量或桥 `NSString` 取 `length` |
| `nsText.uppercased()` 编译不过 | 静态类型是 `NSString` 时只有 `uppercased(with:)`；改声明方式就换 API |
| 土耳其语用户的 i 大写变成 İ | 大小写转换**带语言**；机读串要显式给 `nil`/POSIX locale |
| 分隔符切出来段数不对 | `components(separatedBy:)` 保留空段（4 段），`split` 默认丢空段（2 段） |
| `İ.lowercased()` 长度变了 | 折成 `i` + 组合点**两个标量**，仍是一个字符 |
| NSRange 截出来的字符串不对 | `NSRange` 只是两个整数，**不绑定字符串**；换串复用必错 |
| `Range(nsRange, in: s)` 解包崩 | 它返回 `Optional`：越界或落在代理对中间给 `nil`（不崩，但你得处理） |
| `index(_:offsetBy:)` 越界 Fatal error | trap，接不住；用带 `limitedBy:` 的重载，它给 `nil` |
| 两个「同一个词」在 OC 侧不相等 | Swift `==` 走 Unicode 规范等价，`NSString.isEqual:` 只比码元序列 |
| 组合点让 `NSString.length` 多 1 | 分解式（`e` + `U+0301`）自己占一格；先 `precomposedStringWithCanonicalMapping` |
| 换台机器排序结果不同 | `compare` 随 locale：`'a'` vs `'A'` 在 `de_DE` 与 POSIX 下**结论相反** |
| `file10` 排在 `file2` 前 | 默认 `sorted()` 按码元；要 Finder 序用 `localizedStandardCompare` |
| `data.appending(other)` 不存在 | `Data` 只有 `append(contentsOf:)` / `+`；`appending(_:)` 是 `Array` 的 |
| 切片传不进 API | `Data` 的 `SubSequence` 就是 `Data`（`Array` 的是 `ArraySlice`，要 `Array(...)`） |
| ASCII 转换返回 nil | 无损转换装不下 `é`；有损是**丢掉**它，不是换成 `?` |
| 一段坏字节让整串解不出来 | `String(data:encoding:)` 严格给 `nil`；用 `String(decoding:as:)` 换 `U+FFFD` |
| 改了 Swift 数组，桥出来的 `NSArray` 没变 | 桥接出来的是**快照**，且每次桥都是**新对象**（`===` 为假） |
| `NSArray as? [String]` 整个失败 | 条件桥接是**全有或全无**，不会「能转几个算几个」 |
| `arr as NSSet` / `dict as NSMutableDictionary` 编译不过 | `Array` 只桥 `NSArray`、`Dictionary` 只桥 `NSDictionary`；要可变用构造器或 `Set(...)` |
| 同一份代码每次打印集合顺序不同 | Swift 哈希种子**每进程随机**；先 `sorted()` 再打印/断言 |
| `NSNumber(value: 1) is Bool` 为真 | `is` 问「能不能按这个类型解释」；分不清就用 `objCType`（`q` vs `c`） |
| `1.0 as? Int` 给 nil | Swift 数字类型之间**不做**隐式加宽；装箱类型同理 |
| `a === b` 判相等出错 | 小整数 `NSNumber` 是 tagged pointer，同一指针；`===` 不能判内容 |
| 「相等」的两个对象都在 `Set` 里 | 只重写 `isEqual` 没重写 `hash`；且**留几个元素本身不确定**，别写断言 |
| JSON 每次键顺序不同 | 没开 `.sortedKeys`；结构体按声明顺序、字典按哈希顺序 |
| `Date` 编出来是个裸浮点数 | 默认策略是「自 **2001** 参考日期起的秒数」（差值 978307200） |
| 后端说时间差 55 年 | 策略不匹配；对表常用 `.millisecondsSince1970` |
| 字段为 nil 时 JSON 里没这个键 | 这是**规则**（`encodeIfPresent`），不是 bug；解码侧缺键 → `nil` |
| NaN 让整份 encode 失败 | `EncodingError`（`NSCocoaErrorDomain` 4866），可选字段也救不了 |
| 缺字段与填 null 报同一个错 | 不是：缺 → `keyNotFound`，`null` → `valueNotFound`，类型错 → `typeMismatch`，坏 JSON → `dataCorrupted` |
| 数组里一个元素坏了整包解不出来 | 逐条 `try?` 才能「坏一条丢一条」 |
| `Int(" 42 ")` 是 nil | Swift 的 `Int` 不 trim、不认下划线、不认千分位 |
| 12/31 的日期年份跳一年 | 用了 `YYYY`（周年份）；**永远用 `yyyy`** |
| 换设备日期差 8 小时 | `DateFormatter` 不设 `timeZone` 就跟随系统时区 |
| ISO 串写出去读不回来 | 带小数秒要两端都开 `.withFractionalSeconds` |
| 1/31 加一个月跑到 3 月 | 不会：`Calendar` **夹紧**到 2/29；但「1 个月 1 天」会滚到 3/1 |
| 一天算成 24 小时结果差一小时 | 夏令时切换日真实长度 82800 / 90000 秒；用 `dateInterval.duration` |
| 数字串在两台机器上解析结果不同 | 格式化与解析必须用**同一个** formatter；POSIX 连分组都不做 |
| currency 断言写死整串后翻车 | POSIX 在符号与数字间塞 **U+00A0**；只对前缀和数字下断言 |
| `percent` 打出的值大 100 倍 | 它吃的是**比值**（0.1 → 10%） |
| 「剩余时间」显示宽度乱跳 | `DateComponentsFormatter` 高位为零时干脆不写（45 秒 → `"45"`） |
| 存储用量和接口 bytes 差 7% | `ByteCountFormatter` 的 `.binary`（1024）vs `.decimal`（1000） |
| `DateComponentsFormatter` 输出随语言变 | 它**没有** `locale` 属性；只能对结构下断言 |
| JSON 里的 `null` 判不出来 | `Any` 世界里是 `NSNull`，`!= nil` 也为真，要 `is NSNull` |
| 往 JSON 里塞自定义对象崩了 | **写**失败是抛 OC 异常，Swift `catch` 接不住（**读**失败才是 error 3840） |
| `try?` 解档拿到 nil 却不知为何 | 安全解档「类型不符」是**抛错** 4864；`do/catch` 才看得见 domain/code |
| `bool(forKey:)` 分不清「没存」和「存了 false」 | 取不出区别；用 `object(forKey:) != nil` |
| `string(forKey:)` 读出「7」 | 它替你做了数字→字符串转换，不是类型安全读法 |
| 通知在单元测试里没触发 | `queue: .main` 要等 runloop；headless 里没有 —— 用 `nil`（同步投递） |
| `object: nil` 的观察者收了两遍 | `nil` 是「不限发送者」，不是「只收无发送者」 |
| 加了观察者的块里 `observeValue` 没被调 | 块式 KVO 与 `observeValue(forKeyPath:)` 是两套机制 |
| KVO 观察不到值变化 | 属性缺 `@objc dynamic`；或 `NSObservation` token 被释放 |
| `value(forKey: "name.count")` 抛异常 | `String.count` 是 Swift 成员，KVC 的 OC 选择器机制看不见 |
| `perform` 拿不回值 | 回来的是 `Unmanaged`，要 `takeUnretainedValue()`；参数必须是对象类型 |
| NSRange 落在 emoji 中间 | `NSAttributedString.length` 是**码元**；下标只能 `NSRange`，跨视图要换算 |
| 富文本段数比预期多 | 段按**内部记录**切，不按「值有没有变」切；要合并就整段 `setAttributes` |
| Swift 数组越界 `@try` 接不住 | Swift 是 trap（signal 4），OC 是异常 —— 容错边界不同 |
| `as!` 崩溃日志里的类型名看不懂 | 桥接容器报 OC 类名（`NSTaggedPointerString`→`NSNumber`），原生容器报 Swift 名（`Swift.Int`） |

## 本章的七条通则

把 277 条断言压成七句，这一页可以直接贴到工位上：

1. **先问「按哪把尺子量」。** 字符 / 码元 / 标量 / 字节四种口径在同一个串上
   给出四个数；`String` 用 `Index`，`NSRange` 世界只用码元，两者换算
   **单向必成、反向可选**。
2. **值语义在桥接处断裂。** `Data`/`Array` 赋值即拷贝，但桥成 `NSArray` 之后
   得到的是**快照**、每次桥都是**新对象**；要可变只能 `mutableCopy()` 或
   构造器 —— 别把 `as NSMutableArray` 当「换个看法」。
3. **`is` / `as?` 问的是「能不能这样解释」，不是「当初装了什么」。**
   所以 `NSNumber(1) is Bool` 与 `NSNumber(true) is Int` 双向都真，
   条件桥接全有或全无，`as!` 失败就是 trap。要类型身份只有 `objCType`。
4. **等价 = `isEqual` + `hash`，两半都要写。** 只写一半时连「`Set` 里剩几个」
   都不确定；结构体声明 `Hashable` 就自动补齐。`===` 只判身份，
   tagged pointer 还会让它假阳性。
5. **顺序未定义 → 稳定输出必须自己排。** `Set`、`Dictionary.keys`、
   `grouping`、字典顶层 JSON —— 四处同一个原因（每进程随机哈希种子）。
   本章所有打印出去的集合都排过序。
6. **格式化/解析是一对，locale 与时区是它们的隐形参数。** 必须用同一个
   formatter 读写；`DateFormatter` 要钉 `locale` + `timeZone`；
   `YYYY` ≠ `yyyy`；POSIX 不是「美式」而是「机读」；
   没有 `locale` 属性的 formatter 只能对结构下断言；一天未必 24 小时。
7. **错误处理不对称，而且分语言。** 解码给 `nil`、`DecodingError` 分四个 case、
   `JSONEncoder` 抛可 catch 的 `EncodingError`、安全解档抛 4864、
   读坏 JSON 给 error 3840；但**写**坏 JSON、KVC 错键、OC 容器越界抛的是
   `NSException`，Swift 的 `do/catch` **接不住**。

下一章：`07-objc-swift-mix.md` —— 同一 target 里 Swift 与 OC 互相调用：
桥接头、`@objc` 暴露边界、`nullable` 与隐式解包可选、以及本章 §18 那批
「跨语言容错边界」的正式讲法。

---

上一章：[05 Foundation（OC 篇）](05-objc-foundation.md) · 下一章：[07 OC 与 Swift 混编](07-objc-swift-mix.md)
