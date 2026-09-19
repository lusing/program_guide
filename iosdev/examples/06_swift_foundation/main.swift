// ============================================================
// 06 - Foundation（Swift 篇）：值语义、可选、Codable、桥接
//
// Swift 的 String/Data/Array 是**值类型**，NSString/NSData/NSArray 是**引用类型**。
// 两者自由桥接，但桥接处有一堆「看起来一样其实不一样」的地方。本章列清楚。
// 纯 Swift 语言基础（可选、协议、泛型）见仓库的 swift/ 教程，这里只讲与
// Foundation / iOS 相关的部分。
// ============================================================

import Foundation
import UIKit

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }

line("== 06 Foundation（Swift 篇）==")

// ---------------------------------------------------- 1) String ↔ NSString
line("")
line("-- String.count vs NSString.length --")
let text = "café"
let nsText = text as NSString           // 免费桥接
expect(text.count == 4, "Swift 的 count 是「用户看到的字符数」")
expect(nsText.length == 4, "NSString 的 length 是 UTF-16 码元数")
let emoji = "😀"
expect(emoji.count == 1, "emoji 在 Swift 里算 1 个字符（grapheme cluster）")
expect((emoji as NSString).length == 2, "同一个 emoji 在 NSString 里是 2 个码元（代理对）")
let flag = "🇨🇳"
expect(flag.count == 1, "国旗在 Swift 里仍是 1 个字符")
expect((flag as NSString).length == 4, "国旗在 NSString 里是 4 个码元（两个 regional indicator）")

// ---------------------------------------------------- 2) Range ↔ NSRange
line("")
line("-- Range 与 NSRange：两套下标 --")
if let swiftRange = text.range(of: "fé") {
    let nsRange = NSRange(swiftRange, in: text)      // Range → NSRange 总能成功
    expect(nsRange.length == 2, "Range → NSRange 换算一致")
    let backToSwift = Range(nsRange, in: text)        // NSRange → Range 可能 nil！
    expect(backToSwift == swiftRange, "NSRange → Range 在这个例子里成功")
} else {
    expect(false, "应能找到子串 fé")
}
// 越界的 NSRange 转 Range 得到 nil，而不是崩溃
let badNS = NSRange(location: 0, length: 999)
expect(Range(badNS, in: text) == nil, "越界 NSRange 转 Range 得到 nil（不是崩溃）")

// ---------------------------------------------------- 3) Data 值语义
line("")
line("-- Data 值语义 --")
let data = Data([0x43, 0x6F, 0x63, 0x6F, 0x61])   // "Cocoa"
expect(data.count == 5, "Data 按字节计长度")
var mutableData = data
mutableData.append(0x21)                            // 改副本
expect(mutableData.count == 6 && data.count == 5, "Data 追加不影响原值（写时复制）")
let asString = String(data: data, encoding: .utf8)
expect(asString == "Cocoa", "Data 解回字符串")

// ---------------------------------------------------- 4) Codable
line("")
line("-- Codable：Swift 原生序列化 --")
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

// 日期：JSONEncoder 默认把 Date 编成「2001 参考日期起的秒数」
struct Event: Codable { let at: Date }
let enc2 = JSONEncoder(); enc2.dateEncodingStrategy = .iso8601
let evData = try! enc2.encode(Event(at: Date(timeIntervalSince1970: 1_700_000_000)))
let evJson = String(data: evData, encoding: .utf8)!
expect(evJson.contains("2023-11-14"), "ISO8601 策略输出可读日期")

// ---------------------------------------------------- 5) 可选 与 Foundation
line("")
line("-- 可选类型与 Foundation 的 nil --")
// 很多 Foundation API 返回可选：找不到就是 nil，不是异常。
let maybeInt = Int("42")            // String → Int? 失败返回 nil
let notInt = Int("abc")
expect(maybeInt == 42 && notInt == nil, "Int(String) 失败返回 nil（可选）")
// 字典下标取值天然返回可选
let dict = ["a": 1]
expect(dict["a"] == 1 && dict["z"] == nil, "字典下标返回 Optional")
// 可选链 + nil 合并
let name: String? = nil
expect((name ?? "匿名") == "匿名", "?? 给可选兜底")

// ---------------------------------------------------- 6) == 与 ===
line("")
line("-- == 与 === --")
let a = NSNumber(value: 1), b = NSNumber(value: 1)
expect(a == b, "== 走 isEqual，内容相同即相等")
// 坑：小整数 NSNumber 是 tagged pointer，a 与 b 其实是**同一个指针**，
// 所以 a === b 为真。这正说明「别用 === 判断内容相等」。
expect(a === b, "小整数 NSNumber 是 tagged pointer，=== 竟为真（别拿它判相等）")
// 要演示 === 比指针，用两个真正独立的堆对象：
let o1 = NSObject(), o2 = NSObject()
expect(o1 !== o2, "=== 比指针：两个独立对象不相等")
expect(o1 === o1, "=== 同一对象为真")
let set = Set([NSNumber(value: 1), NSNumber(value: 1)])
expect(set.count == 1, "Set 靠 hash + isEqual 去重")

// ---------------------------------------------------- 7) NotificationCenter
line("")
line("-- NotificationCenter --")
var received: [String] = []
let noteName = Notification.Name("demo")
let token = NotificationCenter.default.addObserver(forName: noteName, object: nil, queue: nil) { note in
    if let v = note.userInfo?["v"] as? String { received.append(v) }
}
NotificationCenter.default.post(name: noteName, object: nil, userInfo: ["v": "1"])
NotificationCenter.default.post(name: noteName, object: nil, userInfo: ["v": "2"])
NotificationCenter.default.removeObserver(token)
NotificationCenter.default.post(name: noteName, object: nil, userInfo: ["v": "3"])  // 移除后收不到
expect(received == ["1", "2"], "移除观察者之后就收不到通知了")

// ---------------------------------------------------- 8) URL / FileManager
line("")
line("-- URL 与 FileManager --")
let fm = FileManager.default
let dir = fm.temporaryDirectory.appendingPathComponent("iosdev-06-\(UUID().uuidString)", isDirectory: true)
try! fm.createDirectory(at: dir, withIntermediateDirectories: true)
let fileURL = dir.appendingPathComponent("a.txt")
try! "hello".data(using: .utf8)!.write(to: fileURL)
expect(fm.fileExists(atPath: fileURL.path), "文件写出来了")
let readBack = try! String(contentsOf: fileURL, encoding: .utf8)
expect(readBack == "hello", "读回来内容一致")
expect(fileURL.pathExtension == "txt", "URL 有 pathExtension")
try! fm.removeItem(at: dir)
expect(!fm.fileExists(atPath: dir.path), "临时目录已删除")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 06 结束 ====")
exit(failures == 0 ? 0 : 1)
