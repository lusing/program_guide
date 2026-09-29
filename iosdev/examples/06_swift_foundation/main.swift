// ============================================================
// 06 - Foundation（Swift 篇）：值语义、可选、Codable、桥接
//
// Swift 的 String/Data/Array 是**值类型**，NSString/NSData/NSArray 是**引用类型**。
// 两者自由桥接，但桥接处有一堆「看起来一样其实不一样」的地方。本章列清楚。
//
// 纯 Swift 语言基础（可选、协议、泛型）见第 30 章（同仓库的 swift/ 教程也有一份）。
// 本章只讲与 Foundation / iOS 相关的部分，并和上一章（05 OC 篇）逐项对照：
// 同一件事在 OC 里怎么写、在 Swift 里怎么写、坑在哪一侧。
//
// 本章所有会崩、会随机器变、依赖系统语言的行为都放到独立探针里量，
// 结果记在 §18「探针记录」——示例本身永远跑得过、输出永远可复现。
// ============================================================

import Foundation
import UIKit

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }

// —— 供 §8 用的三个自定义类型：只重写 isEqual / 两个都重写 / 故意违背契约 ——
class MXCredOnly : NSObject {
    var name: String
    init(_ n: String) { name = n }
    override func isEqual(_ object: Any?) -> Bool { (object as? MXCredOnly)?.name == name }
}
class MXCredBoth : NSObject {
    var name: String
    init(_ n: String) { name = n }
    override func isEqual(_ object: Any?) -> Bool { (object as? MXCredBoth)?.name == name }
    override var hash: Int { name.hashValue }
}
// —— 供 §9/§10 的编解码用 ——
struct MXNum: Codable { var v: Double }
struct MXInt: Codable { var v: Int }
// —— 供 §10 的解码用 ——
struct MXConf: Codable, Equatable {
    var name: String
    var port: Int
    var tags: [String]
}
// —— 供 §14 的归档用 ——
func unarchiveErr<T: NSObject & NSCoding>(ofClass cls: T.Type, data: Data) -> String {
    do {
        let got = try NSKeyedUnarchiver.unarchivedObject(ofClass: cls, from: data)
        return got == nil ? "nil" : "解出了一个对象"
    } catch {
        let ns = error as NSError
        let raw = (ns.userInfo[NSDebugDescriptionErrorKey] as? String) ?? ns.localizedDescription
        // 原话里带对象地址和镜像路径，快照不能要，只取「unexpected class」这个结论词
        let verdict = raw.contains("unexpected class") ? "提到类型不符" : "只说格式不对"
        return "domain=\(ns.domain) code=\(ns.code) \(verdict)"
    }
}
@objc(MXDoc) class MXDoc: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }
    var title: String
    var n: Int
    init(title: String, n: Int) { self.title = title; self.n = n }
    func encode(with coder: NSCoder) {
        coder.encode(title, forKey: "title")
        coder.encode(n, forKey: "n")
    }
    required init?(coder: NSCoder) {
        title = coder.decodeObject(of: NSString.self, forKey: "title") as String? ?? ""
        n = coder.decodeInteger(forKey: "n")
    }
}
// —— 供 §15 的 KVC / KVO / perform 用 ——
@objc class MXPerson: NSObject {
    @objc var name: String = ""
    @objc var age: Int = 0
    @objc dynamic var count: Int = 0
    var blockHits = 0
    var legacyHits = 0
    @objc func greet() -> String { return "你好 \(name)" }
    @objc func shout(_ s: String) -> String { return s.uppercased() }
    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        legacyHits += 1
    }
}

// 后面所有 DateFormatter / NumberFormatter 都钉在 POSIX locale + UTC 上，
// 否则输出跟着模拟器语言与时区走，快照就没法比对了（原因见 §12、§13、§18）。
let posix = Locale(identifier: "en_US_POSIX")
let utc = TimeZone(secondsFromGMT: 0)!
let dayFmt = DateFormatter()
dayFmt.locale = posix; dayFmt.timeZone = utc; dayFmt.dateFormat = "yyyy-MM-dd"
let fullFmt = DateFormatter()
fullFmt.locale = posix; fullFmt.timeZone = utc; fullFmt.dateFormat = "yyyy-MM-dd HH:mm:ss"

line("== 06 Foundation（Swift 篇）==")

// ---------------------------------------------------- 1) 长度口径
line("")
line("-- 1) String 与 NSString：同一串内容的四种「长度」--")
let text = "café"
let nsText = text as NSString            // 免费桥接
expect(text.count == 4, "Swift 的 count 是「用户看到的字符数」（grapheme cluster）")
expect(nsText.length == 4, "NSString 的 length 是 UTF-16 码元数，这一串里恰好也是 4")
expect(text.unicodeScalars.count == 4, "café 是 4 个标量：é 用的是预组合码点 U+00E9")
expect(text.utf8.count == 5, "UTF-8 字节数是 5：é 吃掉 2 个字节")
let emoji = "😀"
expect(emoji.count == 1, "emoji 在 Swift 里算 1 个字符")
expect((emoji as NSString).length == 2, "同一个 emoji 在 NSString 里是 2 个码元（代理对）")
let flag = "🇨🇳"
expect(flag.count == 1, "国旗在 Swift 里仍是 1 个字符")
expect((flag as NSString).length == 4, "国旗在 NSString 里是 4 个码元（两个 regional indicator）")
expect(flag.unicodeScalars.count == 2, "国旗只有 2 个标量，却要 4 个 UTF-16 码元来装")
let skin = "a👍🏽b"
line("  同一串「\(skin)」：count=\(skin.count) utf16.count=\(skin.utf16.count) scalars=\(skin.unicodeScalars.count) utf8.count=\(skin.utf8.count)")
expect(skin.count == 3, "手势+肤色修饰符合成一个字符，加上 a、b 共 3 个")
expect((skin as NSString).length == 6, "NSString 数到 6 个码元：a + 代理对 + 代理对 + b")
expect(skin.unicodeScalars.count == 4, "标量是 4 个：a、👍、🏽、b —— 肤色修饰符自己就是一个标量")
expect(skin.utf8.count == 10, "UTF-8 是 10 字节")
// 结论和 05 章一致：写正则、算截断、跨语言传长度之前，先问清按哪把尺子。

// ---------------------------------------------------- 2) 桥接后的方法名
line("")
line("-- 2) 桥接之后：方法名会换、参数会变、重载会挑错那个 --")
let upperFromNS = nsText.uppercased(with: nil)   // NSString 版要求给 locale
let upperFromSwift = text.uppercased()          // Swift 版不要参数
expect(upperFromNS == "CAFÉ" && upperFromSwift == "CAFÉ", "两个 uppercased 结果一致，但**签名不同**")
// 静态类型是 NSString 时，无参的 uppercased() 直接编译不过：
//   error: missing argument for parameter 'with' in call
// 于是同一行代码，改个变量声明就从「能写」变成「必须写」。
let iPlain = "i".uppercased()
let iTurkish = "i".uppercased(with: Locale(identifier: "tr"))
line("  无 locale 的 i → \(iPlain)；土耳其语 locale 的 i → \(iTurkish)")
expect(iPlain == "I" && iTurkish == "İ", "大小写转换是**带语言的**，土耳其语的 i 大写是 İ")
let dottedLower = "İ".lowercased()
expect(dottedLower.count == 1, "反过来：İ 小写后仍是 1 个字符")
expect(dottedLower.unicodeScalars.count == 2, "但它由 i + 组合点上标两个标量拼成，长度不能想当然")
// NSString 独有的方法在 String 上不存在，只能先 as NSString
let nsParts = ("a,,b," as NSString).components(separatedBy: ",")
let swiftParts = "a,,b,".split(separator: ",")
line("  NSString 切分 = \(nsParts)（\(nsParts.count) 段）")
line("  Swift split 切分 = \(swiftParts.map(String.init))（\(swiftParts.count) 段）")
expect(nsParts.count == 4, "NSString 的 components 保留空段，末尾的分号也算一段")
expect(swiftParts.count == 2, "Swift 的 split 默认丢掉空段：同一个分隔符，段数少一半")
expect("a,,b,".split(separator: ",", omittingEmptySubsequences: false).count == 4, "想要 OC 的行为，得显式关掉「省略空段」")
// 便利构造：NSString(string:) 与 as NSString 效果一样，但前者是「造一个」
expect(NSString(string: "abc").length == 3, "NSString(string:) 造的串长度按码元算")

// ---------------------------------------------------- 3) 下标体系
line("")
line("-- 3) Index / Range / NSRange：三套下标互不通用 --")
if let swiftRange = text.range(of: "fé") {
    let nsRange = NSRange(swiftRange, in: text)          // Range → NSRange 总能成功
    expect(nsRange.length == 2, "Range → NSRange 换算一致")
    let backToSwift = Range(nsRange, in: text)           // NSRange → Range 可能 nil！
    expect(backToSwift == swiftRange, "NSRange → Range 在这个例子里成功")
    // 反过来，拿另一个字符串的长度去套就危险了：NSRange 只认码元，不知道你要截谁
    let wrongHost = Range(nsRange, in: skin)
    expect(wrongHost != nil, "把 café 上量出的 NSRange 用到别的串上，只要不越界就照样成功")
    if let h = wrongHost { expect(String(skin[h]) != "fé", "但截出来的绝不是当初那段文本：位置全错") }
} else {
    expect(false, "应能找到子串 fé")
}
let badNS = NSRange(location: 0, length: 999)
expect(Range(badNS, in: text) == nil, "越界 NSRange 转 Range 得到 nil（不是崩溃）")
let negNS = NSRange(location: 99, length: 2)
expect(Range(negNS, in: text) == nil, "起点越界同样得到 nil")
// 三种口径下的偏移量各不相同
let mix = "a😀e\u{0301}z"                                // a + 代理对 emoji + e+组合点 + z
if let zIdx = mix.firstIndex(of: "z") {
    let gOff = mix.distance(from: mix.startIndex, to: zIdx)
    let uOff = mix.utf16.distance(from: mix.utf16.startIndex, to: zIdx.samePosition(in: mix.utf16)!)
    let sOff = mix.unicodeScalars.distance(from: mix.unicodeScalars.startIndex, to: zIdx.samePosition(in: mix.unicodeScalars)!)
    line("  「z」在「\(mix)」里：字符偏移=\(gOff) 码元偏移=\(uOff) 标量偏移=\(sOff)")
    expect(gOff == 3 && uOff == 5 && sOff == 4, "同一个位置，三把尺子量出三个数")
    expect(mix.count == 4 && (mix as NSString).length == 6, "整串也是：Swift 数 4 个字符，NSString 数 6 个码元")
}
// offsetBy 会崩：探针里 offsetBy 越界触发 trap，示例只走安全路径
let safeOffset = mix.index(mix.startIndex, offsetBy: 1)
expect(String(mix[safeOffset...]) == "😀\u{0065}\u{0301}z", "offsetBy 数的是「字符」：跳过 a 之后剩下的整串里，é 仍是一个字符")
expect(mix.index(mix.startIndex, offsetBy: 2, limitedBy: mix.endIndex) != nil, "想要不崩的版本，用带 limitedBy 的重载")
expect(mix.index(mix.startIndex, offsetBy: 99, limitedBy: mix.endIndex) == nil, "越界时它返回 nil 而不是 trap")

// ---------------------------------------------------- 4) 归一化与比较
line("")
line("-- 4) 归一化、忽略大小写、忽略重音：== 与 compare 不是一回事 --")
let decomposed = "cafe\u{0301}"                          // e + 组合急性重音
expect(decomposed == text, "分解式和预组合式在 Swift 里直接相等：== 走 Unicode 规范等价")
expect(decomposed.count == text.count, "字符数也一样是 4")
expect((decomposed as NSString).length == 5, "但 NSString 数出 5 个码元：多出来的组合点自己占一格")
let nsDec = decomposed as NSString
let nsPre = text as NSString
expect(nsDec != nsPre, "换成 NSString 的 isEqual，这两个「同一个词」就不等了")
expect(!nsDec.isEqual(to: nsPre as String), "isEqual(to:) 同样只比码元序列，不做归一化")
expect(nsDec.precomposedStringWithCanonicalMapping == nsPre as String,
       "要 OC 那套「先归一化再比」，得显式调 precomposedStringWithCanonicalMapping")
expect(!decomposed.hasSuffix("\u{0301}"), "hasSuffix 也按字符走：单独的组合上标不构成串尾那个字符（它和 e 粘成了 é）")
expect(decomposed.compare(text) == .orderedSame, "compare 说两者一样：它内部做了规范等价")
let foldDia = "CAFÉ".folding(options: .diacriticInsensitive, locale: nil)
expect(foldDia == "CAFE", "folding 把 É 折成 E，用来做「不区分重音」的搜索/去重")
let foldCase = "Cocoa".folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
expect(foldCase == "cocoa", "两个选项合起来 = 忽略大小写又忽略重音")
expect("CAFÉ".folding(options: [.caseInsensitive], locale: nil) == "café", "只给 caseInsensitive 时 É 仍是 É")
// 大小写不敏感比较的三种写法，作用域并不一样
expect("a".caseInsensitiveCompare("A") == .orderedSame, "caseInsensitiveCompare：不看 locale")
expect("a".localizedCaseInsensitiveCompare("A") == .orderedSame, "localizedCaseInsensitiveCompare：看当前 locale")
let deCmp = "a".compare("A", locale: Locale(identifier: "de_DE"))
let posixCmp = "a".compare("A", locale: posix)
line("  'a' 与 'A' 谁在前：de_DE=\(deCmp.rawValue) en_US_POSIX=\(posixCmp.rawValue)（-1/1 才是「谁在前」）")
expect(deCmp == .orderedAscending && posixCmp == .orderedDescending,
     "同一个比较，换 locale 结论**反过来**：德语里小写在前，POSIX 里按 ASCII 码点大写在前")
let nums = ["file10.txt", "file2.txt", "File1.txt"]
line("  默认字典序 = \(nums.sorted())")
line("  localizedStandardCompare = \(nums.sorted { $0.localizedStandardCompare($1) == .orderedAscending })")
expect(nums.sorted() == ["File1.txt", "file10.txt", "file2.txt"], "默认 sorted 按 UTF-16 码元：大写排在前面，10 在 2 之前")
expect(nums.sorted { $0.localizedStandardCompare($1) == .orderedAscending } == ["File1.txt", "file2.txt", "file10.txt"],
       "localizedStandardCompare 是「访达」式排序：识别串里的数字，Finder 同款")

// ---------------------------------------------------- 5) Data
line("")
line("-- 5) Data：值语义、切片、坏字节 --")
let data = Data([0x43, 0x6F, 0x63, 0x6F, 0x61])   // "Cocoa"
expect(data.count == 5, "Data 按字节计长度")
var mutableData = data
mutableData.append(0x21)                          // 追加一个 UInt8
expect(mutableData.count == 6 && data.count == 5, "Data 追加不影响原值（写时复制）")
let asString = String(data: data, encoding: .utf8)
expect(asString == "Cocoa", "Data 解回字符串")
// 追加「一整块」必须写 contentsOf —— 这里踩过一次编译报错，记下来
var blockData = data
blockData.append(contentsOf: Data([0x21, 0x3F]))
expect(blockData.count == 7 && data.count == 5, "append(contentsOf:) 才是拼接整块的重载（Data 上没有 appending(_:)）")
let plusData = data + [0x21]
expect(plusData.count == 6 && data.count == 5, "加号也能拼，且拼完还是值语义")
expect(data.subdata(in: 1..<3).count == 2, "subdata 返回**新 Data**，不是切片")
let prefixSlice = data.prefix(2)
expect(type(of: prefixSlice) == Data.self, "Data 的 SubSequence 就是 Data 自己，所以切片不用二次转换")
// base64
let b64 = data.base64EncodedString()
expect(Data(base64Encoded: b64) == data, "base64 往返一致")
expect(Data(base64Encoded: "!!!") == nil, "解不开的 base64 返回 nil（探针里没异常这条路）")
// 编码往返：非 UTF-8 的老编码仍在
let latinBytes = "café".data(using: .isoLatin1)
expect(latinBytes?.count == 4, "isoLatin1 下 é 只占 1 字节，4 字符正好 4 字节")
expect(String(data: latinBytes ?? Data(), encoding: .isoLatin1) == "café", "按同一个编码解回去才还原")
expect("café".data(using: .ascii) == nil, "ASCII 装不下 é：无损转换直接给 nil")
let lossy = "café".data(using: .ascii, allowLossyConversion: true)
expect(String(data: lossy ?? Data(), encoding: .ascii) == "cafe", "有损转换是**丢掉**é，不是替换成 ?（探针实测）")
// 真正非法的字节序列
let bad = Data([0xFF, 0xFE, 0x41])
expect(String(data: bad, encoding: .utf8) == nil, "String(data:encoding:) 遇到非法 UTF-8 返回 nil")
let lossyString = String(decoding: bad, as: UTF8.self)
expect(lossyString.unicodeScalars.count == 3, "String(decoding:as:) 永远成功：坏字节换成替换符 U+FFFD")
expect(lossyString.unicodeScalars.first?.value == 0xFFFD, "第一个坏字节换出 U+FFFD")
expect(lossyString.contains("A"), "坏字节被逐个替换，后面的合法字符 A 还留着")

// ---------------------------------------------------- 6) 集合桥接
line("")
line("-- 6) Array/Dictionary/Set 与 NSArray/NSDictionary/NSSet --")
var arr = [1, 2, 3]
let snapshot = arr as NSArray       // 桥接出来的 NSArray 是「当时那份」
arr.append(4)
expect(snapshot.count == 3 && arr.count == 4, "桥接出来的 NSArray 是快照：之后改 Swift 数组，它不动")
let twice1 = arr as NSArray
let twice2 = arr as NSArray
expect(twice1 !== twice2, "同一个 Swift 数组桥两次得到两个不同对象：别拿桥接结果当身份")
let mutArr = NSMutableArray(array: snapshot)
mutArr.add(5)
expect(mutArr.count == 4 && snapshot.count == 3, "mutableCopy 路线：NSMutableArray 是**真引用类型**，改了就看得到")
// 类型不符的元素：as? 整个失败，不会「能转几个算几个」
let mixed: [Any] = [1, "x"]
let nsMixed = mixed as NSArray
expect((nsMixed as? [String]) == nil, "NSArray 里混着 Int，整个 as? [String] 失败返回 nil")
expect((nsMixed as? [Int])?.count == nil, "混着 String 时 as? [Int] 也是 nil：条件桥接是**全有或全无**")
expect(nsMixed.count == 2, "桥接本身不丢元素，也不做类型检查")
// 反向：Swift 字典 / Set 的桥接
let dict: [String: Int] = ["a": 1, "b": 2]
let nsDict = dict as NSDictionary
expect(((nsDict as? [String: Int]) ?? [:])["a"] == 1, "字典桥过去再桥回来，值还在")
let mutDict = NSMutableDictionary(dictionary: dict as [AnyHashable: Any])
mutDict["c"] = 3
expect(mutDict.count == 3 && dict.count == 2, "要「可变的 NSDictionary」得用 NSMutableDictionary(dictionary:)：as 直转编译不过（见 §18）")
let setFromNS = NSSet(array: ["a", "b", "c"])
expect((setFromNS as? Set<String>)?.count == 3, "NSSet 可以条件桥回 Set")
expect((Set(["a", "b"]) as NSSet).count == 2, "Set ↔ NSSet 免费桥；Array → NSSet 不合法（§18）")
// 顺序：Swift 的 Set/Dictionary 迭代顺序每进程随机（§18 记了三次实测）
let orderedSet: Set<String> = ["alpha", "bravo", "charlie"]
expect(orderedSet.sorted() == ["alpha", "bravo", "charlie"], "想打印集合就**必须**排序，否则同一份代码每次输出不一样")
expect(Array(Set([1, 2, 2, 3])).sorted() == [1, 2, 3], "去重 + 排序是安全写法")
let grouped = Dictionary(grouping: [1, 2, 3, 4], by: { $0.isMultiple(of: 2) ? "偶" : "奇" })
expect(grouped.keys.sorted() == ["偶", "奇"], "grouping 出来的键顺序同样不可依赖，先 sorted 再断言")
expect(grouped["偶"]?.count == 2, "取的时候按可选处理")
// 不可变 vs 可变的另一个面：Swift 的 let 数组桥成 NSArray 之后，强转 NSMutableArray 只是「换个类型看」
let letArr: [String] = ["a"]
let madeMut = (letArr as NSArray).mutableCopy() as? NSMutableArray
expect(madeMut?.count == 1, "要可变的就显式 mutableCopy()：它给的是新对象，不是把原数组「看成」可变的")

// ---------------------------------------------------- 7) NSNumber / NSValue
line("")
line("-- 7) NSNumber、NSValue 与 is / as? 的判定 --")
let nInt = NSNumber(value: 7)
let nDbl = NSNumber(value: 3.7)
let nBool = NSNumber(value: true)
line("  objCType：Int=\(String(cString: nInt.objCType)) Double=\(String(cString: nDbl.objCType)) Bool=\(String(cString: nBool.objCType))")
expect(String(cString: nInt.objCType) == "q" && String(cString: nDbl.objCType) == "d",
       "Swift 的 Int 桥成 long long(q)、Double 桥成 double(d)，和 05 章 OC 那侧一致")
expect(String(cString: nBool.objCType) == "c", "Bool 桥成 char(c)：OC 里 BOOL 与 char 同字符，这里也一样")
expect(nDbl.intValue == 3, "取 intValue 会**截断**，不四舍五入")
expect((nDbl as? Int) == nil, "装着 3.7 的 NSNumber 条件桥不成 Int：拿不到就给你 nil，而不是悄悄截断")
expect((nDbl as? Double) == 3.7, "条件桥成 Double 成功")
expect(nInt.intValue == 7, "装整数的 NSNumber 走 intValue 正常")
// 最阴的一个：Swift 里 NSNumber 与 Bool 的身份判定
let oneAsAny: Any = NSNumber(value: 1)
let trueAsAny: Any = NSNumber(value: true)
expect(oneAsAny is Bool && trueAsAny is Int, "is 判定是**双向都真**的：1 算 Bool、true 也算 Int")
expect(oneAsAny is Int && trueAsAny is Bool, "四种组合全为真——is 问的是「能不能按这个类型解释」，不是「当初装的是什么」")
expect(String(cString: (oneAsAny as! NSNumber).objCType) == "q" && String(cString: (trueAsAny as! NSNumber).objCType) == "c",
       "要分清 1 与 true，只有 objCType 这一条路：q 是整数、c 是 char/BOOL")
// Any 上想用 NSNumber 的的成员得 as!，写成 as 编译器直接拒绝（'Any' is not convertible to 'NSNumber'）
let anyList: [Any] = [1, "s", 2.5, Date(), ["a": 1]]
let kinds = anyList.map { v in
    [v is Int ? "Int" : "", v is String ? "Str" : "", v is Double ? "Dbl" : "",
     v is Date ? "Date" : "", v is [String: Int] ? "Dict" : ""].filter { !$0.isEmpty }.joined(separator: "+")
}
line("  逐项 is 判定 = \(kinds)")
expect(kinds[0] == "Int" && kinds[2] == "Dbl", "Int 不是 Double、Double 不是 Int：Swift 数字类型之间**不做**隐式加宽")
expect(kinds[4] == "Dict", "字典按具体类型匹配，[String: Int] is [String: String] 为假")
// NSValue 装几何值：这些分类在 UIKit 里，不在 Foundation 里
let pt = CGPoint(x: 3, y: 4)
let sz = CGSize(width: 10, height: 20)
let rc = CGRect(origin: pt, size: sz)
let vRect = NSValue(cgRect: rc)
expect(vRect.cgRectValue == rc, "CGRect 进出不变：Swift 的 CGRect 是结构体，NSValue 是它的盒子")
expect(NSValue(cgPoint: pt).cgPointValue.x == 3, "CGPoint 同理")
expect(NSValue(cgSize: sz).cgSizeValue.height == 20, "CGSize 同理")
var rectCopy = rc
rectCopy.origin.x = 99
expect(rc.origin.x == 3 && rectCopy.origin.x == 99, "赋值是拷贝：改副本动不了原值（OC 里 NSString 结构体没这待遇）")
expect(CGRect.null.isNull && CGRect.zero.isNull == false, "CGRect.null 是「空矩形」，和 .zero 不是一回事")
expect(CGRect(x: 5, y: 5, width: 10, height: 10).insetBy(dx: 1, dy: 2) == CGRect(x: 6, y: 7, width: 8, height: 6),
       "insetBy 是四边内缩：宽高各减 2 倍")

// ---------------------------------------------------- 8) == / === / hash
line("")
line("-- 8) == 与 === 与 hash：三条契约一次测清 --")
let a = NSNumber(value: 1), b = NSNumber(value: 1)
expect(a == b, "== 走 isEqual，内容相同即相等")
// 坑：小整数 NSNumber 是 tagged pointer，a 与 b 其实是**同一个指针**，
// 所以 a === b 为真。这正说明「别用 === 判断内容相等」。
expect(a === b, "小整数 NSNumber 是 tagged pointer，=== 竟为真（别拿它判相等）")
let o1 = NSObject(), o2 = NSObject()
expect(o1 !== o2, "=== 比指针：两个独立对象不相等")
expect(o1 === o1, "=== 同一对象为真")
let dedupSet = Set([NSNumber(value: 1), NSNumber(value: 1)])
expect(dedupSet.count == 1, "Set 靠 hash + isEqual 去重")
// 只重写 isEqual、不重写 hash：NSObject 的默认 hash 来自对象身份 → 两个「相等」的对象各进各的桶
let c1 = MXCredOnly("x"), c2 = MXCredOnly("x")
expect(c1 == c2, "只重写 isEqual：两个实例按我们的规则相等")
expect(c1.hash != c2.hash, "但 hash 没重写：NSObject 默认按对象身份给值，两个实例两个 hash")
line("  （只重写一半时 Set 里到底留几个，取决于桶位是否撞上——同一份代码可能 1 也可能 2，所以不作断言）")
// 两个都重写：契约补齐
let d1 = MXCredBoth("y"), d2 = MXCredBoth("y")
expect(d1 == d2 && Set([d1, d2]).count == 1, "isEqual 与 hash 一起重写，Set 才真的去重")
expect(MXCredBoth("y").hash == MXCredBoth("y").hash, "内容同 → hash 同（这正是契约要求）")
let h1 = MXCredOnly("x")
let h2 = MXCredOnly("x")
expect(h1.hash != h2.hash, "没重写 hash → 内容同、hash 也不同：这就是漏写的那一半（对象都存在局部，不让地址复用糊弄我们）")
// Swift 结构体：Hashable 全部自动合成，不存在这个坑
struct MXKey: Hashable { var u: String; var p: String }
expect(Set([MXKey(u: "a", p: "1"), MXKey(u: "a", p: "1")]).count == 1, "结构体只要声明 Hashable，两个字段自动参与 hash")

// ---------------------------------------------------- 9) Codable 编码侧
line("")
line("-- 9) Codable：编码侧 --")
struct Settings: Codable, Equatable {
    var theme: String
    var fontSize: Int
    var recent: [String]
}
let settings = Settings(theme: "dark", fontSize: 13, recent: ["a.txt", "b.txt"])
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]            // 要稳定输出必须开
let encoded = try! encoder.encode(settings)
let json = String(data: encoded, encoding: .utf8)!
line("  json = \(json)")
expect(json == #"{"fontSize":13,"recent":["a.txt","b.txt"],"theme":"dark"}"#, "sortedKeys 让输出可复现")
let decoded = try! JSONDecoder().decode(Settings.self, from: encoded)
expect(decoded == settings, "解回来与原值相等")
// 结构体按 CodingKeys 顺序出，字典按哈希顺序出——后者每进程随机，必须 sortedKeys
let dictJson = String(data: (try? JSONEncoder().encode(["z": 1, "y": 2, "x": 3])) ?? Data(), encoding: .utf8) ?? "?"
expect(dictJson.contains("\"x\"") && dictJson.contains("\"y\"") && dictJson.contains("\"z\""), "字典顶层不带 sortedKeys 也能编，但键序不可复现（§18 记了三次不同结果）")
let dictSorted = String(data: (try? encoder.encode(["z": 1, "y": 2, "x": 3])) ?? Data(), encoding: .utf8) ?? "?"
expect(dictSorted == "{\"x\":3,\"y\":2,\"z\":1}", "开了 sortedKeys 才有唯一正确答案")
// CodingKeys：把下划线/蛇形键名映射成 Swift 的驼峰属性
struct User: Codable {
    var userId: Int
    var fullName: String
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case fullName = "full_name"
    }
}
let userJson = #"{"user_id":7,"full_name":"Ada L"}"#.data(using: .utf8)!
let user = try! JSONDecoder().decode(User.self, from: userJson)
expect(user.userId == 7 && user.fullName == "Ada L", "CodingKeys 把蛇形键映射成驼峰属性")
// 整表策略：不用手写每个键
struct Snake: Codable {
    var userId: Int
    var createdAt: Date
    var nested: NestedInfo
}
struct NestedInfo: Codable, Equatable { var itemName: String }
let snakeJson = #"{"user_id":9,"created_at":"2023-11-14T22:13:20Z","nested":{"item_name":"x"}}"#.data(using: .utf8)!
let snakeDec = JSONDecoder()
snakeDec.keyDecodingStrategy = .convertFromSnakeCase
snakeDec.dateDecodingStrategy = .iso8601
let snake = try! snakeDec.decode(Snake.self, from: snakeJson)
expect(snake.userId == 9 && snake.nested == NestedInfo(itemName: "x"), "convertFromSnakeCase 连嵌套字典里的键一起改")
expect(snake.createdAt.timeIntervalSince1970 == 1_700_000_000, "iso8601 策略解出的正是那一刻")
let snakeEnc = JSONEncoder()
snakeEnc.keyEncodingStrategy = .convertToSnakeCase
snakeEnc.dateEncodingStrategy = .iso8601
snakeEnc.outputFormatting = [.sortedKeys]
let snakeOut = String(data: try! snakeEnc.encode(snake), encoding: .utf8)!
line("  编码回蛇形 = \(snakeOut)")
expect(snakeOut.contains("\"user_id\":9") && snakeOut.contains("\"item_name\":\"x\""), "编码侧有对称的 convertToSnakeCase")
// 日期：默认策略是「2001 参考日期起的秒数」
struct Event: Codable { let at: Date }
let rawEvent = String(data: try! JSONEncoder().encode(Event(at: Date(timeIntervalSince1970: 1_700_000_000))), encoding: .utf8)!
line("  Date 的默认写法 = \(rawEvent)")
expect(rawEvent.contains("721692800"), "1.7e9（自 1970）减去 978307200（1970→2001）= 721692800，这是参考系换轨不是 bug")
let enc2 = JSONEncoder(); enc2.dateEncodingStrategy = .iso8601
let evJson = String(data: try! enc2.encode(Event(at: Date(timeIntervalSince1970: 1_700_000_000))), encoding: .utf8)!
expect(evJson.contains("2023-11-14"), "ISO8601 策略输出可读日期")
let enc3 = JSONEncoder(); enc3.dateEncodingStrategy = .millisecondsSince1970
let msJson = String(data: try! enc3.encode(Event(at: Date(timeIntervalSince1970: 1_700_000_000))), encoding: .utf8)!
expect(msJson == #"{"at":1700000000000}"#, "和后端对表时常用 millisecondsSince1970，别用默认的 timeIntervalSinceReferenceDate")
let dfmt = DateFormatter()
dfmt.locale = posix; dfmt.timeZone = utc; dfmt.dateFormat = "yyyy-MM-dd HH:mm:ss"
let enc4 = JSONEncoder(); enc4.dateEncodingStrategy = .formatted(dfmt)
let fmtJson = String(data: try! enc4.encode(Event(at: Date(timeIntervalSince1970: 1_700_000_000))), encoding: .utf8)!
expect(fmtJson.contains("2023-11-14 22:13:20"), ".formatted(DateFormatter) 把「格式」交给 DateFormatter；它没有默认 locale，务必自己钉死")
let enc5 = JSONEncoder()
enc5.dateEncodingStrategy = .custom { (date: Date, encoder: Encoder) in
    var container = encoder.singleValueContainer()
    try container.encode(Int64(date.timeIntervalSince1970))
}
let customJson = String(data: try! enc5.encode(Event(at: Date(timeIntervalSince1970: 1_700_000_000.5))), encoding: .utf8)!
expect(customJson == #"{"at":1700000000}"#, ".custom 闭包自己写：这里把 Date 按「整秒」出，丢掉小数")
// 可选字段：nil 干脆不出现
struct Deep: Codable { var a: Int?; var b: String? }
let deepJson = String(data: (try? encoder.encode(Deep(a: nil, b: nil))) ?? Data(), encoding: .utf8)!
expect(deepJson == "{}", "两个可选都是 nil → 整个键消失，不是 \"a\":null")
let deepOne = String(data: (try? encoder.encode(Deep(a: 1, b: nil))) ?? Data(), encoding: .utf8)!
expect(deepOne == "{\"a\":1}", "只出现非 nil 的那个")
// 枚举与原始值
enum Kind: String, Codable { case light, dark }
struct Pref: Codable { var kind: Kind }
expect(String(data: (try? encoder.encode(Pref(kind: .dark))) ?? Data(), encoding: .utf8) == "{\"kind\":\"dark\"}",
       "String 枚举直接编成它的 rawValue")
// 顶层不是对象也合法
let topString = String(data: try! JSONEncoder().encode("字符串"), encoding: .utf8)!
let topArray = String(data: try! JSONEncoder().encode([1, 2, 3]), encoding: .utf8)!
line("  顶层字符串 = \(topString)；顶层数组 = \(topArray)")
expect(topString == "\"字符串\"" && topArray == "[1,2,3]", "JSONEncoder 允许顶层片段，OC 的 NSJSONSerialization 却只接对象/数组（05 章 §15）")
// 斜杠转义
let slashJson = String(data: (try? JSONEncoder().encode(["u": "a/b"])) ?? Data(), encoding: .utf8)!
expect(slashJson.contains("a\\/b"), "默认把 / 转义成 \\/（JSON 里斜杠转义是无害的装饰）")
let slashOpen = JSONEncoder()
slashOpen.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
expect(String(data: try! slashOpen.encode(["u": "a/b"]), encoding: .utf8) == "{\"u\":\"a/b\"}",
       ".withoutEscapingSlashes 关掉它；这是 outputFormatting 的一个选项，不是单独的属性")
expect(String(data: (try? JSONEncoder().encode(MXNum(v: 1.5))) ?? Data(), encoding: .utf8).map { $0 == "{\"v\":1.5}" } ?? false, "Double 按最短可回读形式出")
// 非有限浮点是唯一「编不出来」的常规值
do {
    _ = try JSONEncoder().encode(MXNum(v: .nan))
    expect(false, "NaN 竟然编出来了")
} catch let e as EncodingError {
    let ns = e as NSError
    let why = (ns.userInfo[NSDebugDescriptionErrorKey] as? String) ?? "?"
    line("  NaN 编码：domain=\(ns.domain) code=\(ns.code) 「\(why)」")
    expect(ns.domain == NSCocoaErrorDomain && why.contains("nan"),
           "编码失败抛的是可 catch 的 EncodingError；它桥到 OC 侧落在 NSCocoaErrorDomain，原因写在 NSDebugDescription 里")
}
do {
    _ = try JSONEncoder().encode(MXNum(v: .infinity))
    expect(false, "无穷竟然编出来了")
} catch is EncodingError {
    expect(true, "无穷同样抛 EncodingError；可选字段里的 NaN 会连带整个 encode 失败")
}
// prettyPrinted
let pretty = JSONEncoder(); pretty.outputFormatting = [.sortedKeys, .prettyPrinted]
let prettyOut = String(data: try! pretty.encode(settings), encoding: .utf8)!
expect(prettyOut.hasPrefix("{\n") && prettyOut.split(separator: "\n").count > 3, "prettyPrinted：每个键各占一行，缩进由系统给")

// ---------------------------------------------------- 10) Codable 解码侧
line("")
line("-- 10) 解码失败：DecodingError 的四个 case --")
func decodeErr(_ label: String, _ json: String) -> String {
    do {
        let c = try JSONDecoder().decode(MXConf.self, from: Data(json.utf8))
        return "\(label) → ok name=\(c.name) port=\(c.port) tags=\(c.tags)"
    } catch let e as DecodingError {
        switch e {
        case .keyNotFound(let k, let ctx):
            return "\(label) → keyNotFound key=\(k.stringValue) path=\(ctx.codingPath.map { $0.stringValue })"
        case .typeMismatch(let t, let ctx):
            return "\(label) → typeMismatch want=\(t) path=\(ctx.codingPath.map { $0.stringValue })"
        case .valueNotFound(let t, let ctx):
            return "\(label) → valueNotFound nullFor=\(t) path=\(ctx.codingPath.map { $0.stringValue })"
        case .dataCorrupted(let ctx):
            return "\(label) → dataCorrupted path=\(ctx.codingPath.map { $0.stringValue })"
        @unknown default:
            return "\(label) → 未来的某个 case"
        }
    } catch {
        return "\(label) → 其他错误 \(type(of: error))"
    }
}
line("  " + decodeErr("正常  ", #"{"name":"gw","port":8080,"tags":["a","b"]}"#))
line("  " + decodeErr("缺 port", #"{"name":"gw","tags":[]}"#))
line("  " + decodeErr("port 是字符串", #"{"name":"gw","port":"8080","tags":[]}"#))
line("  " + decodeErr("port 为 null", #"{"name":"gw","port":null,"tags":[]}"#))
line("  " + decodeErr("tags 混入整数", #"{"name":"gw","port":8080,"tags":["a",1]}"#))
line("  " + decodeErr("多余键", #"{"name":"gw","port":8080,"tags":[],"extra":1}"#))
line("  " + decodeErr("非 JSON", "not json"))
line("  " + decodeErr("空 Data", ""))
line("  " + decodeErr("顶层是数组", "[1]"))
expect(decodeErr("正常", #"{"name":"gw","port":8080,"tags":["a"]}"#).hasPrefix("正常 → ok"), "字段齐全就正常解出")
expect(decodeErr("", #"{"name":"gw","tags":[]}"#).contains("keyNotFound"), "缺非可选键 → keyNotFound")
expect(decodeErr("", #"{"name":"gw","port":"x","tags":[]}"#).contains("typeMismatch"), "类型不符 → typeMismatch")
expect(decodeErr("", #"{"name":"gw","port":null,"tags":[]}"#).contains("valueNotFound"),
       "键在但值是 null，而非可选字段要不到值 → valueNotFound：和 typeMismatch 是**两个** case")
expect(decodeErr("", "not json").contains("dataCorrupted"), "整份数据不是 JSON → dataCorrupted")
expect(decodeErr("", "").contains("dataCorrupted"), "空 Data 也归 dataCorrupted")
expect(decodeErr("", "[1]").contains("typeMismatch"), "该给对象却给了数组 → typeMismatch（不是 dataCorrupted）")
expect(decodeErr("", #"{"name":"gw","port":8080,"tags":["a",1]}"#).contains("Index 1"),
       "codingPath 里带数组下标：报的是 \"Index 1\"，直接告诉你第几个元素坏了")
// 可选字段：键缺失与显式 null 都落到 nil
struct Opt: Codable { var a: String?; var b: Int }
let o1v = try! JSONDecoder().decode(Opt.self, from: #"{"b":1}"#.data(using: .utf8)!)
expect(o1v.a == nil && o1v.b == 1, "可选字段缺键 → nil：合成的解码器对 Optional 用 decodeIfPresent")
let o2v = try! JSONDecoder().decode(Opt.self, from: #"{"a":null,"b":1}"#.data(using: .utf8)!)
expect(o2v.a == nil, "显式 null 也是 nil：两条路同一个结果")
// 手写 init(from:)：给旧数据补默认值
struct Hand: Codable {
    var value: Int
    var kind: Kind
    init(value: Int, kind: Kind) { self.value = value; self.kind = kind }
    private enum Key: String, CodingKey { case value, kind }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: Key.self)
        value = try c.decode(Int.self, forKey: .value)
        kind = (try c.decodeIfPresent(Kind.self, forKey: .kind)) ?? .light
    }
}
let handOld = try! JSONDecoder().decode(Hand.self, from: #"{"value":3}"#.data(using: .utf8)!)
expect(handOld.kind == .light, "decodeIfPresent + ?? 兜默认值：老数据里没有的字段自己补")
let handNew = try! JSONDecoder().decode(Hand.self, from: #"{"value":3,"kind":"dark"}"#.data(using: .utf8)!)
expect(handNew.kind == .dark, "有值时照用")
// 一个字段坏了整份数据就没了：想要「坏一条丢一条」得自己接
let rows = [#"{"v":1}"#, #"{"v":"x"}"#, #"{"v":3}"#].map {
    (try? JSONDecoder().decode(MXInt.self, from: Data($0.utf8)))?.v ?? -1
}
expect(rows == [1, -1, 3], "逐条 try? 才能容错；一次性解 [MXInt] 会整包失败")
line("  逐条解 = \(rows)")

// ---------------------------------------------------- 11) 可选与 nil
line("")
line("-- 11) 可选类型与 Foundation 的 nil --")
let maybeInt = Int("42")
let notInt = Int("abc")
expect(maybeInt == 42 && notInt == nil, "Int(String) 失败返回 nil（可选）")
expect(Int(" 42 ") == nil, "带空格就解不出来：Swift 的 Int 不 trim，也不认千分位")
expect(Int("1_000") == nil, "字面量里的下划线只属于源码，不属于字符串")
expect(Int("42.0") == nil, "小数字符串解不成 Int")
expect(Double("1e3") == 1000, "Double 认科学计数法")
expect(Double("1,234") == nil, "也不认千分位逗号")
let dict11 = ["a": 1]
expect(dict11["a"] == 1 && dict11["z"] == nil, "字典下标返回 Optional")
let name: String? = nil
expect((name ?? "匿名") == "匿名", "?? 给可选兜底")
let person = MXPerson()
person.name = "Ada"
expect(person.value(forKey: "name") as? String == "Ada", "KVC 取回来是 Any?，必须 as? 才敢用")
let arr11 = NSArray(array: [1, 2])
expect(arr11.firstObject as? Int == 1, "firstObject 是 Any?：空数组时为 nil，所以它天生可选")
expect((NSArray(array: [])).firstObject == nil, "空数组的 firstObject/lastObject 都是 nil，不崩（05 章 §8 同一条）")
// 可选链：一路点下去，中间任何一环是 nil 就整条表达式是 nil
class MXWrapper { var inner: MXLeaf? }
class MXLeaf { var title: String = "t" }
let wNil = MXWrapper()
let wSome = MXWrapper(); wSome.inner = MXLeaf()
expect((wNil.inner?.title) == nil && wSome.inner?.title == "t", "可选链：环上是 nil 就整条 nil")
expect([wNil, wSome].compactMap { $0.inner?.title } == ["t"], "compactMap 顺手把 nil 滤掉")
let flats = [[1, 2], [], [3]].joined()
expect(Array(flats) == [1, 2, 3], "joined() 摊平数组；空子数组自然消失")

// ---------------------------------------------------- 12) 日期
line("")
line("-- 12) Date / Calendar / DateFormatter / ISO8601 --")
let d12 = Date(timeIntervalSince1970: 1_700_000_000)
let iso = ISO8601DateFormatter()
let isoStr = iso.string(from: d12)
line("  ISO8601 默认 = \(isoStr)")
expect(isoStr == "2023-11-14T22:13:20Z", "ISO8601DateFormatter 默认就是「互联网日期时间」，恒为 UTC")
expect(iso.date(from: isoStr) == d12, "同格式回读一致")
let withFrac = ISO8601DateFormatter()
withFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
let fracStr = withFrac.string(from: Date(timeIntervalSince1970: 1_700_000_000.5))
line("  带小数秒 = \(fracStr)")
expect(fracStr.hasSuffix(".500Z"), "小数秒要显式开 .withFractionalSeconds")
expect(iso.date(from: fracStr) == nil, "默认配置的解析器遇到带小数秒的串直接给 nil：写出去读不回来是常见 bug")
let df12 = DateFormatter()
df12.locale = posix; df12.timeZone = utc; df12.dateFormat = "yyyy-MM-dd HH:mm:ss"
expect(df12.string(from: d12) == "2023-11-14 22:13:20", "DateFormatter 按模板输出")
expect(df12.date(from: "2023-11-14 22:13:20") == d12, "按同一模板回读")
expect(df12.date(from: "14/11/2023") == nil, "格式对不上返回 nil（不是异常）")
let noTZ = DateFormatter()
noTZ.locale = posix; noTZ.dateFormat = "yyyy-MM-dd HH:mm:ss"
let localStyled = noTZ.string(from: d12)
line("  不设 timeZone 时本机给：\(localStyled)（跟随系统时区，不是可复现值）")
expect(localStyled != "2023-11-14 22:13:20", "**不设 timeZone 就跟随系统时区**：同一瞬间打出别的钟点，跨机器结果不同")
expect(fullFmt.string(from: d12) == "2023-11-14 22:13:20", "设了 UTC 才有唯一答案：与 noTZ 只差一个 timeZone 一行代码")
let weekYear = DateFormatter()
weekYear.locale = posix; weekYear.timeZone = utc; weekYear.dateFormat = "YYYY-MM-dd"
let yearFmt = DateFormatter()
yearFmt.locale = posix; yearFmt.timeZone = utc; yearFmt.dateFormat = "yyyy-MM-dd"
var cal = Calendar(identifier: .gregorian)
cal.timeZone = utc
let newYearEve = cal.date(from: DateComponents(year: 2023, month: 12, day: 31))!
line("  2023-12-31 这一天：YYYY-MM-dd = \(weekYear.string(from: newYearEve))，yyyy-MM-dd = \(yearFmt.string(from: newYearEve))")
expect(weekYear.string(from: newYearEve) == "2024-12-31", "大写 YYYY 是「周年份」：12/31 落在 2024 那一周里，年份直接跳一年")
expect(yearFmt.string(from: newYearEve) == "2023-12-31", "小写 yyyy 才是日历年份")
let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .weekday, .quarter], from: d12)
line("  dateComponents = y\(comps.year!) m\(comps.month!) d\(comps.day!) 时\(comps.hour!) 分\(comps.minute!) weekday=\(comps.weekday!) 季\(comps.quarter!)")
expect(comps.year == 2023 && comps.month == 11 && comps.day == 14 && comps.hour == 22, "Calendar + TimeZone 定死，分量才可复现")
expect(comps.weekday == 3, "weekday 从 1（周日）数起：11/14 是周二 → 3")
let jan31 = cal.date(from: DateComponents(year: 2024, month: 1, day: 31))!
let plusOneMonth = cal.date(byAdding: .month, value: 1, to: jan31)!
expect(dayFmt.string(from: plusOneMonth) == "2024-02-29", "1/31 加一个月**夹紧**到 2/29（2024 是闰年），不会滚到 3 月")
let plusOneMonthDay = cal.date(byAdding: DateComponents(month: 1, day: 1), to: jan31)!
expect(dayFmt.string(from: plusOneMonthDay) == "2024-03-01", "「加 1 个月零 1 天」是另一回事：先加月再滚一天 → 3/1")
let minusOneMonth = cal.date(byAdding: .month, value: -1, to: cal.date(from: DateComponents(year: 2024, month: 3, day: 31))!)!
expect(dayFmt.string(from: minusOneMonth) == "2024-02-29", "减法同样夹紧")
expect(cal.range(of: .day, in: .month, for: jan31)!.count == 31, "range(of:in:for:) 给的是该月天数范围（1..<32）")
let feb15 = cal.date(from: DateComponents(year: 2024, month: 2, day: 15))!
expect(cal.range(of: .day, in: .month, for: feb15)!.count == 29, "换成 2 月就是 29 天：闰年判断不用自己写")
expect(cal.range(of: .hour, in: .day, for: d12)!.count == 24, "UTC 历法里一天 24 小时")
let week = cal.dateInterval(of: .weekOfYear, for: jan31)!
expect(dayFmt.string(from: week.start) == "2024-01-28" && dayFmt.string(from: week.end) == "2024-02-04",
       "dateInterval 给「所在周」的起止，end 是下一周的第一天（左闭右开）")
expect(cal.firstWeekday == 1, "这个 Calendar 的一周从周日开始；换 locale 会变（探针里量过）")
expect(cal.compare(jan31, to: plusOneMonth, toGranularity: .month) == .orderedAscending, "compare 带粒度：按月看 1 月早于 2 月")
expect(cal.dateComponents([.day], from: jan31, to: plusOneMonthDay).day == 30, "1/31 → 3/1 相差 30 天")
expect(cal.dateComponents([.month], from: jan31, to: cal.date(from: DateComponents(year: 2024, month: 3, day: 15))!).month == 1,
       "1/31 → 3/15 按「月」数只算 1 个整月：0 点和非 0 点起算会影响进位，这里起点是 UTC 零点")
let nextMidnight = cal.nextDate(after: jan31, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime)!
expect(dayFmt.string(from: nextMidnight) == "2024-02-01", "nextDate 找下一个匹配时刻：月末零点就是下月 1 号")
let ny = TimeZone(identifier: "America/New_York")!
expect(ny.secondsFromGMT(for: Date(timeIntervalSince1970: 1_720_000_000)) == -4 * 3600, "7 月的纽约偏移 -4 小时（夏令时）")
expect(ny.secondsFromGMT(for: Date(timeIntervalSince1970: 1_735_000_000)) == -5 * 3600, "12 月是 -5 小时：查偏移必须带日期")
var calNy = Calendar(identifier: .gregorian); calNy.timeZone = ny
expect(calNy.component(.hour, from: d12) == 17, "同一瞬间，纽约是 17 点、UTC 是 22 点")
expect(TimeZone(identifier: "Mars/Rome") == nil, "认不出的时区名给 nil，不抛")
expect(TimeZone(secondsFromGMT: 0)!.abbreviation(for: d12) == "GMT", "固定偏移时区给缩写 GMT；带夏令时的时区缩写随日期变，所以别把它写进快照")
let refDiff = Date(timeIntervalSince1970: 0).timeIntervalSinceReferenceDate
expect(refDiff == -978307200, "1970 与 2001 两个参考系差 978307200 秒：Codable 默认日期策略就是靠它换轨的")
// 夏令时：range(of:in:for:) 说一天 24 小时，真实长度却是 23 或 25 小时
var calNy2 = Calendar(identifier: .gregorian); calNy2.timeZone = ny
let springMid = calNy2.date(from: DateComponents(year: 2024, month: 3, day: 10))!
let nextNoon = calNy2.date(from: DateComponents(year: 2024, month: 3, day: 11))!
let fallMid = calNy2.date(from: DateComponents(year: 2024, month: 11, day: 3))!
let fallNext = calNy2.date(from: DateComponents(year: 2024, month: 11, day: 4))!
line("  纽约 2024-03-10 这一天的真实长度 = \(Int(nextNoon.timeIntervalSince(springMid))) 秒")
expect(Int(nextNoon.timeIntervalSince(springMid)) == 82800, "春令时切换日只有 23 小时（82800 秒）")
expect(Int(fallNext.timeIntervalSince(fallMid)) == 90000, "秋令时切换日有 25 小时（90000 秒）")
expect(calNy2.range(of: .hour, in: .day, for: springMid)!.count == 24,
       "可 range(of: .hour, in: .day) 照样报 24：它给的是**理想范围**，那天真实小时数只能自己减")
let skipped = calNy2.date(byAdding: .hour, value: 2, to: springMid)!
expect(fullFmt.string(from: skipped) != "2024-03-10 02:00:00", "3/10 的 02:00 根本不存在：加两小时被推到 03:00")
let dayInterval = calNy2.dateInterval(of: .day, for: springMid)!
expect(Int(dayInterval.duration) == 82800, "dateInterval(of: .day) 的 duration 才是那天真正的秒数")

// ---------------------------------------------------- 13) 格式化器一族
line("")
line("-- 13) NumberFormatter 一族：格式随 locale 走，解析也随 locale 走 --")
let nfPosix = NumberFormatter(); nfPosix.numberStyle = .decimal; nfPosix.locale = posix
let nfEn = NumberFormatter(); nfEn.numberStyle = .decimal; nfEn.locale = Locale(identifier: "en_US")
let bigNum = NSNumber(value: 1234567)
let posixOut = nfPosix.string(from: bigNum)!
let enOut = nfEn.string(from: bigNum)!
line("  同一个数：en_US_POSIX=\(posixOut) en_US=\(enOut)")
expect(posixOut == "1234567" && enOut == "1,234,567", "POSIX locale 连分组都不做——它是「机读」用的，不是「美式」用的")
expect(nfEn.number(from: enOut)?.doubleValue == 1234567, "en_US 解得动自己写出来的串")
expect(nfPosix.number(from: enOut) == nil, "POSIX 解不动 en_US 写的带逗号串：格式化和解析必须用**同一个** formatter")
let nfCur = NumberFormatter(); nfCur.numberStyle = .currency; nfCur.locale = posix
let nfCurEn = NumberFormatter(); nfCurEn.numberStyle = .currency; nfCurEn.locale = Locale(identifier: "en_US")
let curPosix = nfCur.string(from: NSNumber(value: 12.5))!
let curEn = nfCurEn.string(from: NSNumber(value: 12.5))!
line("  currency：en_US_POSIX=\(curPosix.debugDescription) en_US=\(curEn.debugDescription)")
expect(curPosix.hasPrefix("$") && curPosix.contains("12.50") && curEn.contains("12.50"),
       "currency 风格只断言「以 $ 开头 + 含数字」：符号和符号与数字之间那个空格都由 locale 给，写死必翻车")
let nfPct = NumberFormatter(); nfPct.numberStyle = .percent; nfPct.locale = posix
expect(nfPct.string(from: NSNumber(value: 0.1)) == "10%", "percent 风格吃的是**比值**，不是百分数：0.1 → 10%")
let nfSpell = NumberFormatter(); nfSpell.numberStyle = .spellOut; nfSpell.locale = posix
expect(nfSpell.string(from: NSNumber(value: 2345)) == "two thousand three hundred forty-five", "spellOut 风格")
let nfOrd = NumberFormatter(); nfOrd.numberStyle = .ordinal; nfOrd.locale = posix
expect(nfOrd.string(from: NSNumber(value: 3)) == "3rd", "ordinal 风格")
let nfSci = NumberFormatter(); nfSci.numberStyle = .scientific; nfSci.locale = posix; nfSci.maximumFractionDigits = 2
expect(nfSci.string(from: NSNumber(value: 12345)) == "1.23E+004", "scientific 风格，小数位数由 maximumFractionDigits 管")
let nfRound = NumberFormatter(); nfRound.numberStyle = .decimal; nfRound.locale = posix; nfRound.maximumFractionDigits = 1
let rounded = nfRound.string(from: NSNumber(value: 1234.567))!
expect(rounded == "1234.6", "超过最大小数位就**四舍五入**（和 NSNumber 截断成 int 那条规则不同）")
expect(nfPosix.string(from: NSNumber(value: true)) != nil, "NSNumber 里的 bool 也能按数字格式化")
// 数字之外的格式化器：这三个都没有可设的 locale，输出跟着系统语言走
let dcf = DateComponentsFormatter(); dcf.unitsStyle = .positional
let posStr = dcf.string(from: 3720)!
line("  DateComponentsFormatter .positional(3720 秒) = \(posStr)")
expect(posStr.contains(":") && posStr.hasSuffix(":00"), "positional 风格是唯一接近「机器可读」的那档：小时:分钟:秒")
expect(dcf.string(from: 45) == "45", "高位为零时干脆不写：45 秒就是 \"45\"，不是 \"0:0:45\"")
let dcfZero = DateComponentsFormatter(); dcfZero.unitsStyle = .positional
expect(dcfZero.string(from: 0) == "0", "零秒是 \"0\"")
let bcf = ByteCountFormatter(); bcf.allowedUnits = [.useMB]; bcf.countStyle = .file
let mbStr = bcf.string(fromByteCount: 1_536_000)
line("  ByteCountFormatter(.useMB, .file, 1536000) = \(mbStr)")
expect(mbStr.hasPrefix("1.5"), "字节格式化：单位与进位由 countStyle 决定（.binary 走 1024，.decimal 走 1000）")
let bcfBin = ByteCountFormatter(); bcfBin.allowedUnits = [.useKB]; bcfBin.countStyle = .binary
let bcfDec = ByteCountFormatter(); bcfDec.allowedUnits = [.useKB]; bcfDec.countStyle = .decimal
let binStr = bcfBin.string(fromByteCount: 1_536_000)
let decStr = bcfDec.string(fromByteCount: 1_536_000)
line("  同一个值：.binary=\(binStr) .decimal=\(decStr)")
expect(binStr != decStr, "1024 与 1000 两种进位给的字符串不一样")
// String(format:) 也吃 locale
let fmtDe = String(format: "%.2f", locale: Locale(identifier: "de_DE"), 12.5)
let fmtEn = String(format: "%.2f", locale: posix, 12.5)
line("  String(format: \"%.2f\")：de_DE=\(fmtDe) posix=\(fmtEn)")
expect(fmtDe == "12,50" && fmtEn == "12.50", "小数点/逗号由 locale 决定——05 章 §2 的说明符表在这里同样成立")
// 单位换算：Measurement 不带 locale 时才安全
let km = Measurement(value: 1000, unit: UnitLength.meters).converted(to: .kilometers)
expect(km.value == 1, "1000 米换公里：换算走 Measurement，别自己乘除")
let far = Measurement(value: 100, unit: UnitTemperature.celsius).converted(to: .fahrenheit)
expect((far.value - 212).magnitude < 1e-8, "摄氏 100 = 华氏 212：温标有偏移量，不能用比例函数蒙")

// ---------------------------------------------------- 14) 其余序列化
line("")
line("-- 14) JSONSerialization / plist / NSKeyedArchiver / UserDefaults --")
// Swift 里走 Any 路线的 JSON（05 章 §15 的 OC 对照）
let obj: [String: Any] = ["n": 1, "s": "x", "arr": [1, 2]]
let jsonAny = String(data: try! JSONSerialization.data(withJSONObject: obj, options: [.sortedKeys]), encoding: .utf8)!
line("  JSONSerialization = \(jsonAny)")
expect(jsonAny == #"{"arr":[1,2],"n":1,"s":"x"}"#, "Any 路线照旧可用，options 里同样是 sortedKeys")
do {
    _ = try JSONSerialization.jsonObject(with: Data("坏".utf8))
    expect(false, "坏数据竟然解出来了")
} catch {
    let ns = error as NSError
    line("  读坏 JSON：domain=\(ns.domain) code=\(ns.code)")
    expect(ns.domain == NSCocoaErrorDomain && ns.code == 3840, "读失败是 Swift 可 catch 的 error（05 章同一条：读坏给 error，写坏抛异常）")
}
let nullJson = try! JSONSerialization.data(withJSONObject: ["a": NSNull()])
let backNull = try! JSONSerialization.jsonObject(with: nullJson) as! [String: Any]
expect(backNull["a"] is NSNull && backNull["a"] != nil, "JSON 的 null 在 Any 世界里是 NSNull，**不是** Swift 的 nil")
// plist：日期能进，浮点数也能进，但自定义对象不能
expect(PropertyListSerialization.propertyList(["a": 1, "b": ["x"]], isValidFor: .binary), "字典 + 数组是合法 plist")
expect(PropertyListSerialization.propertyList(["d": Date()], isValidFor: .xml), "Date 是 plist 的原生类型（JSON 就得分手写成字符串/数字）")
let plistData = try! PropertyListSerialization.data(fromPropertyList: ["d": Date(timeIntervalSince1970: 0)], format: .xml, options: 0)
let backPlist = try! PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any]
expect(backPlist?["d"] is Date, "解回来的日期仍是 Date")
let binaryPlist = try! PropertyListSerialization.data(fromPropertyList: ["k": "v"], format: .binary, options: 0)
expect(String(data: binaryPlist.prefix(6), encoding: .ascii) == "bplist", "二进制 plist 以 bplist 开头")
// NSKeyedArchiver：Swift 侧要求 NSSecureCoding
let archived = try! NSKeyedArchiver.archivedData(withRootObject: MXDoc(title: "t", n: 5), requiringSecureCoding: true)
let unarchived = try! NSKeyedUnarchiver.unarchivedObject(ofClass: MXDoc.self, from: archived)
expect(unarchived?.title == "t" && unarchived?.n == 5, "归档/解档往返（要写 encode(with:) 与 required init?(coder:)）")
let wrongClass = unarchiveErr(ofClass: NSString.self, data: archived)
line("  用错类解档：\(wrongClass)")
expect(wrongClass.contains("提到类型不符"), "用错的类去解**是抛错**（4864），不是给 nil：安全解档宁可报错也不给你意外的对象")
let brokenArchive = unarchiveErr(ofClass: MXDoc.self, data: Data([1, 2, 3]))
line("  解一份假归档：\(brokenArchive)")
expect(brokenArchive.contains("4864") || brokenArchive.contains("NSCocoaErrorDomain"), "坏归档数据同样抛 error，不是崩")
// UserDefaults：headless 环境下照样能用（套件名自己给，别写进输出）
let defaults = UserDefaults(suiteName: "iosdev.tutorial.06.selftest")!
defaults.removeObject(forKey: "mx.int")
defaults.removeObject(forKey: "mx.arr")
defaults.set(7, forKey: "mx.int")
defaults.set(["a", "b"], forKey: "mx.arr")
expect(defaults.integer(forKey: "mx.int") == 7, "整数存取")
expect(defaults.array(forKey: "mx.arr") as? [String] == ["a", "b"], "字符串数组存取")
expect(defaults.integer(forKey: "mx.absent") == 0 && defaults.bool(forKey: "mx.absent") == false,
       "没存过的键给 0/false：**取不出「没这个键」和「存了 0」的区别**")
expect(defaults.string(forKey: "mx.int") == "7", "string(forKey:) 会替你把数字转成字符串（7 → 「7」），这不是类型安全的读法")
expect(defaults.object(forKey: "mx.int") is Int, "object(forKey:) 才保留原类型")
defaults.removeObject(forKey: "mx.int")
expect(defaults.object(forKey: "mx.int") == nil, "removeObject 之后真没了")
defaults.removeObject(forKey: "mx.arr")

// ---------------------------------------------------- 15) 通知 / KVC / KVO / 动态派发
line("")
line("-- 15) NotificationCenter、KVC、KVO 与 @objc 动态派发 --")
var received: [String] = []
let noteName = Notification.Name("mx.demo")
let token = NotificationCenter.default.addObserver(forName: noteName, object: nil, queue: nil) { note in
    if let v = note.userInfo?["v"] as? String { received.append(v) }
}
NotificationCenter.default.post(name: noteName, object: nil, userInfo: ["v": "1"])
NotificationCenter.default.post(name: noteName, object: nil, userInfo: ["v": "2"])
NotificationCenter.default.removeObserver(token)
NotificationCenter.default.post(name: noteName, object: nil, userInfo: ["v": "3"])  // 移除后收不到
expect(received == ["1", "2"], "移除观察者之后就收不到通知了")
expect(noteName == Notification.Name("mx.demo"), "Notification.Name 是值类型，按字符串比相等")
// object 参数是过滤器：只收这个对象发出来的
var objHits: [String] = []
let srcA = NSObject(), srcB = NSObject()
let filtered = NotificationCenter.default.addObserver(forName: noteName, object: srcA, queue: nil) { _ in
    objHits.append("限定A")
}
NotificationCenter.default.addObserver(forName: noteName, object: nil, queue: nil) { _ in
    objHits.append("不限")
}
NotificationCenter.default.post(name: noteName, object: srcA, userInfo: nil)
NotificationCenter.default.post(name: noteName, object: srcB, userInfo: nil)
expect(objHits == ["限定A", "不限", "不限"], "object 非 nil 时是**按发送者过滤**；nil 的那个观察者两次都收到")
NotificationCenter.default.removeObserver(filtered)
// queue 传 nil = 就在 posting 线程同步回调，所以 post 返回时 received 已经齐了；
// 传 OperationQueue.main 就得等 runloop，headless 自测里没有 runloop，收不到。
expect(objHits.count == 3, "同步投递：post 调用返回的那一刻，三个观察者块已经全部跑完")
// KVC：Swift 侧写/读
let p15 = MXPerson()
p15.setValue("Ada", forKey: "name")
p15.setValue(36, forKey: "age")
expect((p15.value(forKey: "name") as? String) == "Ada" && (p15.value(forKey: "age") as? Int) == 36,
       "setValue/value 走的是 OC 那套按字符串找属性的机制，要求属性 @objc")
expect(p15.name == "Ada" && p15.age == 36, "KVC 写的就是真属性，不是另存一份")
// 动态派发
expect(p15.responds(to: #selector(MXPerson.greet)), "responds(to:) 问方法在不在")
expect(!p15.responds(to: NSSelectorFromString("noSuchMethod")), "没有的方法给 false，不崩")
expect((p15.perform(#selector(MXPerson.greet))?.takeUnretainedValue() as? String) == "你好 Ada",
       "perform 回来的是 Unmanaged，得手动 takeUnretainedValue")
expect((p15.perform(#selector(MXPerson.shout(_:)), with: "go")?.takeUnretainedValue() as? String) == "GO",
       "带一个参数就 with: 传进去（参数必须是对象类型）")
// KVO：块式观察与老式 observeValue 的关系
let model = MXPerson()
let obs = model.observe(\.count, options: [.new]) { obj, change in
    obj.blockHits += 1
    _ = change.newValue
}
model.count = 1
model.count = 2
expect(model.blockHits == 2, "observe(\\.) 的块被调了两次")
expect(model.legacyHits == 0, "块式 KVO **不**经过 observeValue(forKeyPath:)：两套机制各走各的")
obs.invalidate()
model.count = 3
expect(model.blockHits == 2, "invalidate 之后不再收到")
model.observeValue(forKeyPath: "count", of: model, change: nil, context: nil)
expect(model.legacyHits == 1, "自己直接调 observeValue 才会计数——它平时不会被块式 KVO 调用")
// @objc dynamic 是 KVO 的前提：少了 dynamic，属性访问走 Swift 直路，观察不到
struct PlainCount { var count = 0 }        // 结构体没有 KVO 一说
expect(PlainCount().count == 0, "Swift 原生类型/结构体完全不参与 KVC/KVO，一切得先过 @objc 这道门")

// ---------------------------------------------------- 16) URL / FileManager
line("")
line("-- 16) URL、URLComponents 与 FileManager --")
let fm = FileManager.default
let dir = fm.temporaryDirectory.appendingPathComponent("iosdev-06-\(UUID().uuidString)", isDirectory: true)
try! fm.createDirectory(at: dir, withIntermediateDirectories: true)
let fileURL = dir.appendingPathComponent("a.txt")
try! "hello".data(using: .utf8)!.write(to: fileURL)
expect(fm.fileExists(atPath: fileURL.path), "文件写出来了")
let readBack = try! String(contentsOf: fileURL, encoding: .utf8)
expect(readBack == "hello", "读回来内容一致")
expect(fileURL.pathExtension == "txt", "URL 有 pathExtension")
expect(fileURL.deletingPathExtension().lastPathComponent == "a", "deletingPathExtension 取主名")
let nested = dir.appendingPathComponent("sub", isDirectory: true)
try! fm.createDirectory(at: nested, withIntermediateDirectories: true)
let listed = (try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: []).map { $0.lastPathComponent }.sorted()) ?? []
expect(listed == ["a.txt", "sub"], "contentsOfDirectory 只给这一层，排序后可复现")
var isDir: ObjCBool = false
expect(fm.fileExists(atPath: nested.path, isDirectory: &isDir) && isDir.boolValue, "想区分目录就用 isDirectory 出参")
expect(fileURL.isFileURL, "temporaryDirectory 出来的是 file:// URL；HTTP 那份才是 URL(string:) 造的")
expect(dir.standardizedFileURL == dir, "standardizedFileURL 把已是规范形式的临时目录原样返回")
try! fm.removeItem(at: dir)
expect(!fm.fileExists(atPath: dir.path), "临时目录已删除")
// 字符串型 URL：percent 编码由 URLComponents 负责
let urlComps = URLComponents(string: "https://e.com/p?name=张三&n=1")!
let itemNames = (urlComps.queryItems ?? []).map { "\($0.name)=\($0.value ?? "")" }.sorted()
line("  queryItems = \(itemNames)")
expect(itemNames == ["n=1", "name=张三"], "queryItems 把 & 串拆成对，值自动解码（顺序不保证，先 sorted 再比）")
expect(urlComps.percentEncodedQuery == "name=%E5%BC%A0%E4%B8%89&n=1", "percentEncodedQuery 给的是编码形态")
var built = URLComponents()
built.scheme = "https"; built.host = "e.com"; built.path = "/a b"
built.queryItems = [URLQueryItem(name: "q", value: "a b&c")]
let builtStr = built.url?.absoluteString ?? ""
line("  拼出来的 URL = \(builtStr)")
expect(builtStr.contains("q=a%20b%26c"), "自己拼 URL 时空格与 & 由 URLComponents 负责转义")
expect(URLComponents(string: builtStr)?.queryItems?.first?.value == "a b&c", "转义过的 & 不会在解析时被当成分隔符：往返安全")
expect(URL(string: "https://e.com/a b")?.absoluteString == "https://e.com/a%20b", "URL(string:) 会顺手把空格补上转义")
expect(URL(string: "// ::") == nil, "彻底拼不出结构的串给 nil（不是崩）")
let base = URL(string: "https://e.com/a/b/c")!
expect(URL(string: "sub", relativeTo: base)?.absoluteURL.absoluteString == "https://e.com/a/b/sub",
       "相对解析会**吃掉基址的最后一段**：c 不是目录，除非基址以 / 结尾")
expect(URL(string: "?x=1", relativeTo: base)?.absoluteURL.absoluteString == "https://e.com/a/b/c?x=1",
       "只给 query 时路径整体保留")
let upURL = URL(string: "../x", relativeTo: base)!
expect(upURL.absoluteURL.absoluteString == "https://e.com/a/x", ".. 让上一级真的生效")
expect(upURL.standardized.absoluteString == "https://e.com/a/b/x",
       "**坑**：standardized 先对相对串做规范化，.. 被折掉，结果退回 a/b 下面去了")
let fileStyle = URL(fileURLWithPath: "/tmp")
expect(fileStyle.appendingPathComponent("a/b.txt").path == "/tmp/a/b.txt", "appendingPathComponent 里带斜杠会被照单收下（它只管拼接）")
expect(fileStyle.appendingPathExtension("log").lastPathComponent == "tmp.log", "appendingPathExtension 加的是扩展名")

// ---------------------------------------------------- 17) 富文本
line("")
line("-- 17) NSAttributedString：UIKit 那几章要用的富文本，长度仍是码元 --")
let attr = NSMutableAttributedString(string: "红色加粗")
attr.addAttribute(.foregroundColor, value: UIColor.systemRed, range: NSRange(location: 0, length: 2))
attr.addAttribute(.font, value: "粗", range: NSRange(location: 0, length: 2))
attr.addAttribute(.font, value: "细", range: NSRange(location: 2, length: 2))
expect(attr.length == 4 && attr.string == "红色加粗", "NSAttributedString.length 数的是**码元**（05 章同一条），这里四个汉字刚好四个")
expect(attr.attribute(.font, at: 1, effectiveRange: nil) as? String == "粗", "按下标取属性：第 1 个字符落在「粗」这一段")
expect(attr.attribute(.font, at: 3, effectiveRange: nil) as? String == "细", "第 3 个字符已经是「细」")
expect(attr.attribute(.foregroundColor, at: 3, effectiveRange: nil) == nil, "没设过的属性取回来是 nil，不是默认色")
var effective = NSRange(location: 0, length: 0)
let gotFont = attr.attribute(.font, at: 1, effectiveRange: &effective)
expect((gotFont as? String) == "粗" && effective == NSRange(location: 0, length: 2),
       "带 effectiveRange 出参，顺带告诉你这个值管到哪：0 起、长 2")
var runs = 0
var runLengths: [Int] = []
attr.enumerateAttribute(.font, in: NSRange(location: 0, length: attr.length)) { _, sub, _ in
    runs += 1
    runLengths.append(sub.length)
}
expect(runs == 2 && runLengths == [2, 2], "enumerateAttribute 按「属性变化的边界」切段：两段各 2 个字符")
let joinedAttr = NSMutableAttributedString(string: "ab")
joinedAttr.append(NSAttributedString(string: "cd", attributes: [.init("k"): "v"]))
expect(joinedAttr.string == "abcd", "append 拼的是属性串，字符串部分照常连起来")
expect(joinedAttr.attribute(.init("k"), at: 2, effectiveRange: nil) as? String == "v", "新段带着自己的属性进来，旧段不受影响")
expect(joinedAttr.attribute(.init("k"), at: 0, effectiveRange: nil) == nil, "前两个字符仍然没有这个属性")
let replaceAttr = NSMutableAttributedString(string: "abcdef")
replaceAttr.addAttribute(.kern, value: 2, range: NSRange(location: 0, length: 6))
replaceAttr.removeAttribute(.kern, range: NSRange(location: 2, length: 2))
var kernRuns = 0
var runSpans: [String] = []
replaceAttr.enumerateAttribute(.kern, in: NSRange(location: 0, length: replaceAttr.length)) { v, sub, _ in
    kernRuns += 1
    runSpans.append("\(sub.location)+\(sub.length)=\(v as? Int ?? -1)")
}
line("  逐段 = \(runSpans)")
expect(kernRuns == 3, "整段设一个属性再挖掉中间两格 → 属性段从 1 段变 3 段（有-无-有）")
expect(runSpans == ["0+2=2", "2+2=-1", "4+2=2"], "每段的起止与值都能读回来：位置 2、3 的 kern 真没了")
let partialAttr = NSMutableAttributedString(string: "abcdef")
partialAttr.addAttribute(.kern, value: 2, range: NSRange(location: 1, length: 3))
partialAttr.removeAttribute(.kern, range: NSRange(location: 2, length: 1))
var partialRuns = 0
partialAttr.enumerateAttribute(.kern, in: NSRange(location: 0, length: partialAttr.length)) { _, _, _ in partialRuns += 1 }
expect(partialRuns == 5, "换一种改法（先设 [1,3) 再挖掉中间 1 格）却是 5 段：段数按内部记录切，不按「值有没有变」切")
let plainAttr = NSAttributedString(string: "只文本")
expect(plainAttr.attributes(at: 0, effectiveRange: nil).isEmpty, "纯文本的 attributes 是空字典，不是 nil")
// 富文本的下标一律是 NSRange：Swift 的 String index 在这儿用不上，只能 (s as NSString).length 算长度

// ---------------------------------------------------- 18) 探针记录
line("")
line("-- 18) 探针记录：这些行为会崩/会随机器变，只在独立探针里量 --")
line("  1) 强制解包 nil（opt!）：Fatal error: Unexpectedly found nil while unwrapping an Optional value，进程收 signal 4。")
line("  2) Swift 数组越界（a[5]）：Swift/ContiguousArrayBuffer.swift 报 Fatal error: Index out of range，signal 4。")
line("     这和 05 章 OC 的 NSRangeException 不是一回事：OC 那边是异常，能 @try 接住；Swift 这边是 trap，接不住。")
line("  3) 整数溢出（Int.max + 1）：signal 4。-Onone 与 -O **都**陷阱；且这行的 Fatal error 文本没进 stderr，只在崩溃报告里。")
line("  4) index(_:offsetBy:) 越界：探针里对「abc」偏移 99 得到 Swift/StringCharacterView.swift: Fatal error: String index is out of bounds，signal 4。")
line("     示例里只用带 limitedBy: 的重载，它给 nil。")
line("  5) NSArray as! [Int]（元素是 NSString）：Could not cast value of type 'NSTaggedPointerString' to 'NSNumber'，signal 6。")
line("     注意括号里的类型名是 NSNumber：Swift 的 Int 桥过去就是它。地址每次都不同，此处只记类型名。")
line("  6) [String: Any] as! [String: String]：Could not cast value of type 'Swift.Int' to 'Swift.String'。")
line("     同一个 as! 失败，桥接来的容器报 OC 类名、Swift 原生容器报 Swift 类型名——读崩溃日志时用得上这条经验。")
line("  7) Swift 的 do/catch **接不住** OC 异常：探针里 JSONSerialization.data(withJSONObject: [\"d\": Date()])")
line("     抛 NSInvalidArgumentException（Invalid type in JSON write (__NSTaggedDate)），catch 没反应，进程 signal 6。")
line("     05 章里同一件事在 OC 可以 @try 接住；跨语言调用的容错边界要按这条重新画。")
line("  8) value(forKey:) / setValue(_:forKey:) 用错键：NSUnknownKeyException。示例里那行故意不做取值。")
line("  9) value(forKeyPath: \"name.count\")：同样 NSUnknownKeyException，reason 里 valueForUndefinedKey: 说的就是 key count。")
line("     Swift 的 String.count 是 Swift 成员，KVC 那套按 OC 选择器找属性的机制看不见它。")
line("  10) NSMutableArray.insert(_:at:) 下标越界：NSRangeException（index 9 beyond bounds [0 .. 0]），signal 6。")
line("  11) [String] as NSSet 编译不过：cannot convert value of type '[String]' to type 'NSSet' in coercion。")
line("      Array 只能桥 NSArray，要 NSSet 得先 Set(...)。同理 [String: Int] as NSMutableDictionary 也编译不过。")
line("  12) Swift 的哈希种子每次启动随机：同一份代码连跑三次，Array(Set) 给出三种顺序、")
line("      Array(dict.keys) 三种、不带 sortedKeys 的字典 JSON 三种（探针实测）。同一进程内则稳定。")
line("      所以本章凡是打印出来的集合都排过序，测试里也别拿 Set 的顺序写断言。")
line("  13) DateFormatter 不设 timeZone 就跟随系统时区（本机 UTC+8），NumberFormatter 的分组符号随 locale 变，")
line("      DateComponentsFormatter / ByteCountFormatter 干脆没有 locale 属性：本机 zh_CN 下 .abbreviated 给「1小时2分钟」、")
line("      .spellOut 给「一小时二分钟」。要可复现输出只能自己钉 locale + 时区，或像本章只对结构做断言。")
line("  14) NSDateFormatter 的五档 style 依赖 ICU 版本（05 章 §14 同条），本机的具体字符串不写进断言。")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 06 结束 ====")
exit(failures == 0 ? 0 : 1)
