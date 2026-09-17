// ============================================================
// 16 - 持久化与设置：UserDefaults / plist / Codable / Bundle 资源 / 本地化
//
// 编译：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name persistence main.swift -o 16_persistence \
//          -framework Foundation -framework AppKit
// 运行：
//   ./16_persistence
//
// 一个 Mac 应用要存的东西大致分三类：
//   小设置 → UserDefaults（本质是 ~/Library/Preferences 下的 plist）
//   结构化数据 → Codable 写成 JSON/plist，放到 Application Support
//   资源文件 → 打进 Bundle，只读
// 沙箱应用还要考虑容器路径，本章不涉及签名，只讲 API 行为。
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

// MARK: - 1) UserDefaults

print("== UserDefaults ==")
// 用独立的 suite 名，别去污染 standard（standard 会被别的进程共享）
let suite = "macosdev.selftest.16"
let defaults = UserDefaults(suiteName: suite)!
// 先清一遍，保证每次跑的起点一样
defaults.removePersistentDomain(forName: suite)
defaults.synchronize()

expect(defaults.string(forKey: "theme") == nil, "一开始没有值")
defaults.set("dark", forKey: "theme")
defaults.set(13, forKey: "fontSize")
defaults.set(true, forKey: "autoSave")
expect(defaults.string(forKey: "theme") == "dark", "字符串存进去了")
expect(defaults.integer(forKey: "fontSize") == 13, "整数存进去了")
expect(defaults.bool(forKey: "autoSave"), "布尔存进去了")

// 坑：读不存在的 key 返回的是「零值」而不是 nil —— 布尔尤其危险
expect(defaults.bool(forKey: "notThere") == false, "不存在的布尔读到 false（不是 nil）")
expect(defaults.integer(forKey: "notThere") == 0, "不存在的整数读到 0")
expect(defaults.object(forKey: "notThere") == nil, "想区分「没设过」和「设成了 false」要用 object(forKey:)")

// 注册默认值：不改变磁盘，只在没设过时兜底
defaults.register(defaults: ["lineNumbers": true])
expect(defaults.bool(forKey: "lineNumbers"), "register 提供默认值")
// 坑：register 之后 object(forKey:) **能**读到值（它搜的是包括注册域在内的全部域），
// 想确认「没落盘」要看持久域，不能看 object(forKey:)。
expect(defaults.object(forKey: "lineNumbers") != nil, "register 之后 object(forKey:) 能读到")
expect(defaults.persistentDomain(forName: suite)?["lineNumbers"] == nil,
       "但持久域里没有它（register 不落盘）")

// 数组和字典
defaults.set(["a", "b"], forKey: "recent")
expect(defaults.array(forKey: "recent") as? [String] == ["a", "b"], "数组也能存")
expect(defaults.dictionaryRepresentation()["theme"] as? String == "dark",
       "dictionaryRepresentation 能看到全部")

// 改完不一定立刻落盘。synchronize() 是「尽快写」的提示，
// 而且官方已经不推荐依赖它 —— 正常退出时系统会自己写。
defaults.synchronize()
expect(defaults.string(forKey: "theme") == "dark", "同步之后值还在")

// 收尾：删掉这一轮写的东西，下次跑还是干净的起点
defaults.removeObject(forKey: "theme")
expect(defaults.string(forKey: "theme") == nil, "removeObject 之后就没了")
defaults.removePersistentDomain(forName: suite)
// 坑：dictionaryRepresentation() 合并了全部域（含系统级的 NSGlobalDomain 等），
// 所以它几乎不可能为空 —— 要看自己这一域就用 persistentDomain(forName:)。
expect(defaults.persistentDomain(forName: suite) == nil, "删掉整个持久域之后读不回来")

// MARK: - 2) plist

print("")
print("== plist ==")
let plist: [String: Any] = ["name": "Cocoa", "version": 2, "tags": ["ui", "mac"]]
let plistData = try! PropertyListSerialization.data(fromPropertyList: plist,
                                                    format: .xml, options: 0)
expect(plistData.count > 0, "能序列化成 plist 数据")
let plistText = String(data: plistData, encoding: .utf8)!
expect(plistText.contains("<plist"), "xml 格式是文本，能直接看")
expect(plistText.contains("<string>Cocoa</string>"), "字符串按 XML 存")

let parsedPlist = try! PropertyListSerialization.propertyList(from: plistData, options: [], format: nil)
    as? [String: Any]
expect(parsedPlist?["name"] as? String == "Cocoa", "反序列化回来取值正确")
expect(parsedPlist?["version"] as? Int == 2, "数字也回来了")
// 坑：plist 里的整数/浮点在 Swift 里都是 NSNumber，用 as? Int 有时取不到
expect((parsedPlist?["version"] as? NSNumber) != nil, "数字统一是 NSNumber")

// plist 能表示的类型是有限的：Data / Date / String / Number / Bool / Array / Dict
let types: [String: Any] = ["d": Date(timeIntervalSince1970: 0), "b": true, "n": 1.5]
let typeData = try! PropertyListSerialization.data(fromPropertyList: types, format: .binary,
                                                   options: 0)
expect(typeData.count > 0, "二进制格式也能写")
expect(PropertyListSerialization.propertyList(types, isValidFor: .binary), "这组类型对 binary 合法")

// MARK: - 3) Codable 存文件

print("")
print("== 文件读写 ==")
struct Preferences: Codable, Equatable {
    var theme: String
    var fontSize: Int
    var recentFiles: [String]
}
let prefs = Preferences(theme: "dark", fontSize: 14, recentFiles: ["a.md", "b.md"])

let dir = FileManager.default.temporaryDirectory
    .appendingPathComponent("macosdev-16-scratch", isDirectory: true)
try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
let jsonFile = dir.appendingPathComponent("prefs.json")

let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]
try! encoder.encode(prefs).write(to: jsonFile)
expect(FileManager.default.fileExists(atPath: jsonFile.path), "JSON 文件写出来了")

let loadedData = try! Data(contentsOf: jsonFile)
let loadedPrefs = try! JSONDecoder().decode(Preferences.self, from: loadedData)
expect(loadedPrefs == prefs, "读回来和原值相等")

// plist 格式：PropertyListEncoder
let plistFile = dir.appendingPathComponent("prefs.plist")
try! PropertyListEncoder().encode(prefs).write(to: plistFile)
let loadedPlist = try! PropertyListDecoder().decode(Preferences.self, from: Data(contentsOf: plistFile))
expect(loadedPlist == prefs, "plist 编解码也能往返")

// 文件属性
let attrs = try! FileManager.default.attributesOfItem(atPath: jsonFile.path)
expect(attrs[.size] as? NSNumber != nil, "能读到文件大小")
expect(attrs[.type] as? FileAttributeType == .typeRegular, "类型判断可用（实际 \(attrs[.type] ?? "nil")）")

// 列出目录
let listed = try! FileManager.default.contentsOfDirectory(atPath: dir.path).sorted()
print("  目录内容 = \(listed.joined(separator: ", "))")
expect(listed == ["prefs.json", "prefs.plist"], "两个文件都在（实际 \(listed)）")

try? FileManager.default.removeItem(at: dir)
expect(FileManager.default.fileExists(atPath: dir.path) == false, "收尾删掉临时目录")

// MARK: - 4) Bundle

print("")
print("== Bundle ==")
// 应用自己的包：资源、Info.plist、本地化都从这里取
let main = Bundle.main
expect(main.bundleURL.pathExtension == "", "命令行工具的包就是可执行文件所在目录")
expect(main.resourcePath != nil, "有资源路径")
expect(main.bundleIdentifier == nil, "命令行工具没有 bundle identifier")

// 造一个真的 .app 结构来读（第 17 章会完整搭一遍，这里先看读取侧）
let appDir = FileManager.default.temporaryDirectory
    .appendingPathComponent("MacOSDev16.app", isDirectory: true)
try? FileManager.default.createDirectory(at: appDir.appendingPathComponent("Contents/MacOS"),
                                         withIntermediateDirectories: true)
let infoPlist: [String: Any] = [
    "CFBundleName": "MacOSDev16",
    "CFBundleIdentifier": "dev.macosdev.example",
    "CFBundleShortVersionString": "1.0",
]
try? PropertyListSerialization.data(fromPropertyList: infoPlist, format: .xml, options: 0)
    .write(to: appDir.appendingPathComponent("Contents/Info.plist"))

let appBundle = Bundle(url: appDir)!
expect(appBundle.bundleIdentifier == "dev.macosdev.example", "能读到 bundle identifier")
expect(appBundle.infoDictionary?["CFBundleName"] as? String == "MacOSDev16", "能读到显示名")
expect(appBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String == "1.0",
       "object(forInfoDictionaryKey:) 是读 Info.plist 的正路（它会做本地化替换）")

try? FileManager.default.removeItem(at: appDir)

// MARK: - 5) 本地化

print("")
print("== 本地化 ==")
// 没有对应 strings 文件时，NSLocalizedString 直接返回 key —— 这就是兜底行为
let fallback = NSLocalizedString("no_such_key_anywhere", comment: "演示兜底")
print("  缺少 strings 文件 = \(fallback)")
expect(fallback == "no_such_key_anywhere", "找不到翻译时返回 key 本身")

// 格式化：%@ 和 %d 的位置在不同语言里可能要换，用带位置参数的写法最稳
let formatted = String(format: "%1$@ 有 %2$d 条", "收件箱", 5)
print("  带位置参数 = \(formatted)")
expect(formatted == "收件箱 有 5 条", "位置参数按顺序填")

// 数字的本地化：不指定 locale 就跟着系统走，写测试时一定要钉住
let numberFormatter = NumberFormatter()
numberFormatter.locale = Locale(identifier: "en_US_POSIX")
numberFormatter.numberStyle = .decimal
// 坑：en_US_POSIX 下的 .decimal 不带千位分隔符，所以格式化出来是 "12345.678"；
// 具体有没有分隔符要实测，别照抄书上的 "12,345.678"。
let numberText = numberFormatter.string(from: 12345.678) ?? ""
print("  12345.678 = \(numberText)")
expect(numberText.isEmpty == false, "钉住 locale 后能格式化出字符串")

// 反过来：从字符串读数字也要钉住 locale，否则 "1,234" 在某些地区会被读成 1.234。
// 这里用**同一个** formatter 做往返，断言「格式化 → 解析」能回到原值。
let parsed = numberFormatter.number(from: numberText)
print("  读回来 = \(parsed?.doubleValue ?? -1)")
expect(parsed?.doubleValue == 12345.678, "同一个 formatter 能读回来")

// 系统偏好语言每次都可能不同，别拿它做断言；只看它是不是非空
expect(Locale.preferredLanguages.isEmpty == false, "系统语言列表非空")

print("==== 16 结束 ====")
exit(failures == 0 ? 0 : 1)
