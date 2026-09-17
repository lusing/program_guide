// ============================================================
// 06 - Swift 与 Foundation 的桥接
//   String ↔ NSString / Data ↔ NSData / Codable / Scanner / URL 与文件
//   / NSObject 的相等性 / NotificationCenter
//
// 编译：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name swift_foundation main.swift -o 06_swift_foundation \
//          -framework Foundation
// 运行：
//   ./06_swift_foundation
//
// Swift 的 String/Array/Dictionary 与 Foundation 的 NSString/NSArray/NSDictionary
// 是「免费桥接」的：as 一下就换过去，代价几乎为零。但两边的 API 形状不同
// （Range vs NSRange、下标 vs objectAtIndex:），混用时最容易踩的就是下标。
// ============================================================

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

// MARK: - 1) String 与 NSString

print("== String ↔ NSString ==")
let text = "café"
let nsText = text as NSString
expect(text.count == 4, "Swift 的 count 是「用户看到的字符数」（实际 \(text.count)）")
expect(nsText.length == 4, "NSString 的 length 是 UTF-16 码元数（实际 \(nsText.length)）")

// 一个 BMP 之外的字符（emoji）在 UTF-16 里要占两个码元
let emoji = "😀"
expect(emoji.count == 1, "emoji 在 Swift 里算 1 个字符")
expect((emoji as NSString).length == 2, "同一个 emoji 在 NSString 里是 2 个码元（代理对）")
// 两个 regional indicator 拼起来的国旗：Swift 算 1 个字符，NSString 是 4 个码元
let flag = "🇨🇳"
expect(flag.count == 1, "国旗在 Swift 里仍是 1 个字符")
expect((flag as NSString).length == 4, "国旗在 NSString 里是 4 个码元")

// 回到 Swift 侧要用 String(...) 显式转回来，别让类型自己滑过去
expect(String(nsText) == text, "String(nsString) 转回来内容不变")

// 坑：Swift 的 range(of:) 返回 Range<String.Index>，NSString 的返回 NSRange。
// 两者的下标不是一个东西，混用会错位 —— 转换要用 Range(nsRange, in:)。
let swiftRange = text.range(of: "fé")
expect(swiftRange != nil, "Swift 的 range(of:) 找到了子串")
let nsRange = nsText.range(of: "fé")
expect(nsRange.location == 2 && nsRange.length == 2, "NSString 的 range(of:) 给的是 NSRange")

if let r = swiftRange {
    let backToNS = NSRange(r, in: text)
    expect(backToNS.location == nsRange.location && backToNS.length == nsRange.length,
           "Range → NSRange 换算一致")
    // 反向：NSRange → Range 是可能失败的（NSRange 可能落在代理对中间）
    let backToSwift = Range(nsRange, in: text)
    expect(backToSwift != nil, "NSRange → Range 在这个例子里成功")
}

// 一个越界的 NSRange：拿它去转 Range 会得到 nil，而不是崩溃
let badRange = NSRange(location: 99, length: 1)
expect(Range(badRange, in: text) == nil, "越界 NSRange 转 Range 得到 nil（不是崩溃）")

// MARK: - 2) Data 与 NSData

print("")
print("== Data ↔ NSData ==")
let bytes: [UInt8] = [0x43, 0x6F, 0x63, 0x6F, 0x61]   // "Cocoa"
let data = Data(bytes)
expect(data.count == 5, "Data 按字节计长度")
expect(data == Data("Cocoa".utf8), "与 UTF-8 字节一致")
expect(String(data: data, encoding: .utf8) == "Cocoa", "Data 解回字符串")

// 桥接后 NSData 的 bytes 就能直接用，但 Swift 侧更推荐 withUnsafeBytes
let sum = data.reduce(0) { $0 + Int($1) }
expect(sum == 0x43 + 0x6F + 0x63 + 0x6F + 0x61, "逐字节求和正确")

let nsData = data as NSData
expect(nsData.length == data.count, "桥接到 NSData 长度不变")
expect(nsData.bytes.bindMemory(to: UInt8.self, capacity: 5).pointee == 0x43, "NSData.bytes 可读")

// 坑：Data 是值类型，NSMutableData 是引用类型。桥接过去改的是同一份字节，
// 但 Swift 侧的 var 不会再看到变化（写时复制）。
var mutableData = data
mutableData.append(0x21)
expect(mutableData.count == 6 && data.count == 5, "Data 追加字节不影响原值（值语义）")

// MARK: - 3) Codable：Swift 原生的序列化

print("")
print("== Codable ==")
struct Settings: Codable, Equatable {
    var theme: String
    var fontSize: Int
    var recent: [String]
}
let settings = Settings(theme: "dark", fontSize: 13, recent: ["a.txt", "b.txt"])

let encoder = JSONEncoder()
// 坑：和 NSJSONSerialization 一样，默认不排序 key，输出顺序未定义。
// 需要稳定输出（测试、diff、签名）时一定要开 .sortedKeys。
encoder.outputFormatting = [.sortedKeys]
let encoded = try! encoder.encode(settings)
let encodedText = String(data: encoded, encoding: .utf8)!
print("  json = \(encodedText)")
expect(encodedText == "{\"fontSize\":13,\"recent\":[\"a.txt\",\"b.txt\"],\"theme\":\"dark\"}",
       "sortedKeys 让输出可复现")

let decoded = try! JSONDecoder().decode(Settings.self, from: encoded)
expect(decoded == settings, "解回来与原值相等")

// 键名和 Swift 属性名不一样时用 CodingKeys 映射，这是最常见的定制点
struct ApiUser: Codable {
    var name: String
    var joinedAt: Date
    enum CodingKeys: String, CodingKey {
        case name = "user_name"
        case joinedAt = "joined_at"
    }
}
let userJson = "{\"user_name\":\"Ada\",\"joined_at\":1700000000}".data(using: .utf8)!
let apiDecoder = JSONDecoder()
apiDecoder.dateDecodingStrategy = .secondsSince1970
let user = try! apiDecoder.decode(ApiUser.self, from: userJson)
expect(user.name == "Ada", "CodingKeys 把下划线键名映射成驼峰属性")
expect(user.joinedAt.timeIntervalSince1970 == 1700000000, "日期按 secondsSince1970 解析")

// 日期的输出同样必须钉住时区，否则跟着系统走
let iso = ISO8601DateFormatter()
iso.timeZone = TimeZone(secondsFromGMT: 0)
expect(iso.string(from: user.joinedAt) == "2023-11-14T22:13:20Z", "ISO8601 输出（UTC）")

// MARK: - 4) Scanner

print("")
print("== Scanner ==")
// Scanner 是从字符串里「读」出值的工具，比 split + Int() 更能处理空白
// Scanner 默认会跳过空白，所以连续扫两个整数就行，不用自己切分。
// 坑：scanInt 返回 Bool（找不到就 false），不是抛异常；而且它不会回退位置。
let scanner = Scanner(string: " 320 200")
var width = 0
var height = 0
let okW = scanner.scanInt(&width)
let okH = scanner.scanInt(&height)
expect(okW && okH, "两次 scan 都拿到了值")
expect(width == 320 && height == 200, "扫出来的数字是 320 与 200")
expect(scanner.isAtEnd, "扫完两个整数后指针到了末尾")

// 扫不出来时返回 false，值保持不变 —— 一定要检查返回值
let badScanner = Scanner(string: "abc")
var nothing = -1
let okBad = badScanner.scanInt(&nothing)
expect(okBad == false, "扫不到数字时返回 false")
expect(nothing == -1, "失败时目标变量不会被改写")

// MARK: - 5) URL 与文件

print("")
print("== URL / FileManager ==")
// 坑：写文件路径时不要用字符串拼，用 URL。URL 会正确处理空格和百分号转义。
let dir = FileManager.default.temporaryDirectory
    .appendingPathComponent("macosdev-06-scratch", isDirectory: true)
try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
let file = dir.appendingPathComponent("note.txt")
try? "hello".data(using: .utf8)?.write(to: file)
expect(FileManager.default.fileExists(atPath: file.path), "文件写出来了")

let readBack = try? String(contentsOf: file, encoding: .utf8)
expect(readBack == "hello", "读回来内容一致")
expect(file.pathExtension == "txt", "URL 有 pathExtension")
expect(file.lastPathComponent == "note.txt", "URL 有 lastPathComponent")

// 相对路径的坑：FileManager 的当前目录是进程的 cwd，不是源文件所在目录。
// 测试里要写文件，永远先造一个明确的绝对 URL，别裸写 "note.txt"。
let relativeWorked = FileManager.default.fileExists(atPath: "note.txt")
expect(relativeWorked == false, "裸写相对路径不会落到临时目录（说明 cwd 是别处）")

// 收尾：把临时目录删掉，不留垃圾
try? FileManager.default.removeItem(at: dir)
expect(FileManager.default.fileExists(atPath: dir.path) == false, "临时目录已删除")

// MARK: - 6) NSObject 的相等性

print("")
print("== 相等性 ==")
// Swift 的 struct 有自动合成的 ==；NSObject 子类没有，必须自己写 isEqual。
// 坑：只重写 isEqual 不重写 hash，放进 NSSet / 当字典 key 时就会行为诡异。
final class Person: NSObject {
    let name: String
    init(name: String) { self.name = name; super.init() }
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? Person else { return false }
        return other.name == name
    }
    override var hash: Int { name.hashValue }
    override var description: String { "Person(\(name))" }
}
let p1 = Person(name: "Ada")
let p2 = Person(name: "Ada")
let p3 = Person(name: "Grace")
expect(p1 == p2, "== 走的是 isEqual，内容相同即相等")
expect(p1 != p3, "内容不同则不相等")
expect(Set([p1, p2, p3]).count == 2, "放进 Set 时靠 hash + isEqual 去重")
// 注意 p1 == p2 为真但 p1 === p2 为假：前者比较内容，后者比较指针
expect(p1 === p1, "=== 比的是指针")
expect(!(p1 === p2), "两个不同对象即使内容相同也不是同一指针")

// MARK: - 7) NotificationCenter

print("")
print("== NotificationCenter ==")
// AppKit 大量使用通知（键盘、窗口、系统外观变化）。它是同步派发的：
// post 的那一行会直接跑完所有观察者。
let center = NotificationCenter.default
var seen: [String] = []
let token = center.addObserver(forName: .init("demo.tick"), object: nil, queue: nil) { note in
    seen.append(note.userInfo?["n"] as? String ?? "?")
}
center.post(name: .init("demo.tick"), object: nil, userInfo: ["n": "1"])
center.post(name: .init("demo.tick"), object: nil, userInfo: ["n": "2"])
center.removeObserver(token)      // 坑：不移除，闭包捕获的对象就一直活着（泄漏）
center.post(name: .init("demo.tick"), object: nil, userInfo: ["n": "3"])
expect(seen == ["1", "2"], "移除观察者之后就收不到通知了（实际 \(seen)）")

print("==== 06 结束 ====")
exit(failures == 0 ? 0 : 1)
