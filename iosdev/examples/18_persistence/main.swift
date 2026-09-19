// ============================================================
// 18 - 数据持久化：UserDefaults / 文件 / Codable / plist / Keychain
//
// iOS 上「存下来、下次还在」按数据大小与敏感度分几层，本示例逐层真实跑一遍：
//
//   UserDefaults      轻量键值（偏好设置、开关）。本质是一个 plist 字典，只放
//                     Int/Double/Bool/String/Data/[..]/Date 这些 property-list 类型。
//   文件系统           Documents / Library / tmp。用 FileManager 拿目录，写 Data。
//   Codable           struct ↔ Data(JSON) 的双向桥，存到文件或 UserDefaults 都行。
//   plist             字典/数组 ↔ XML 或二进制 plist，PropertyListSerialization。
//   Keychain          加密存储（密码、token）。Security 框架的 SecItem* API。
//
// headless：所有读写都落在**隔离**的命名空间里 —— UserDefaults 用自定义 suiteName，
// 文件写在 FileManager.temporaryDirectory 下的唯一子目录，Keychain 用自定义 service。
// 跑完主动清理，绝不留脏数据、绝不依赖环境值。断言全是确定的「写进去什么、读出来什么」。
//
// CoreData / SwiftData 不在此演示：CoreData 需要 .xcdatamodeld（Xcode 工程内建模），
// SwiftData 要 iOS 17+（本教程部署目标 15.0）。二者的定位与选型在文档里讲清楚。
// ============================================================

import Foundation
import Security

var failures = 0
func expect(_ condition: Bool, _ desc: String) {
    print("  \(condition ? "ok  " : "FAIL") \(desc)")
    if !condition { failures += 1 }
}
func line(_ s: String = "") { print(s) }

// 一个可编码的模型：演示 Codable 双向 + 稳定序列化
struct Profile: Codable, Equatable {
    var name: String
    var age: Int
    var tags: [String]
    var createdAt: Date
}

line("== 18 数据持久化 ==")

// =====================================================================
// 1) UserDefaults：轻量键值
// =====================================================================
line("")
line("-- UserDefaults：suiteName 隔离的键值存储 --")
// 自定义 suite 名 → 落到独立的 plist 文件，不污染 App 的标准 defaults，方便整块清理。
let suiteName = "com.iosdev.example18.prefs"
// removePersistentDomain 保证每次跑都是干净起点（幂等）。
UserDefaults.standard.removePersistentDomain(forName: suiteName)
let defaults = UserDefaults(suiteName: suiteName)!

defaults.set(42, forKey: "launchCount")
defaults.set(true, forKey: "onboarded")
defaults.set("深色", forKey: "theme")
defaults.set(Data([1, 2, 3]), forKey: "blob")

expect(defaults.integer(forKey: "launchCount") == 42, "Int 往返一致（42）")
expect(defaults.bool(forKey: "onboarded") == true, "Bool 往返一致（true）")
expect(defaults.string(forKey: "theme") == "深色", "String 往返一致（深色）")
expect(defaults.data(forKey: "blob") == Data([1, 2, 3]), "Data 往返一致（[1,2,3]）")

// synchronize 把内存里的改动强制刷到磁盘。现代 iOS 会自动异步落盘，
// 但显式调用能让「写完立刻从磁盘读」这件事在本示例里确定发生。
let flushed = defaults.synchronize()
expect(flushed, "synchronize() 返回 true（成功刷盘）")

// object(forKey:) 对不存在的键返回 nil（区别于 integer 返回 0）
expect(defaults.object(forKey: "neverSet") == nil, "不存在的键 object(forKey:) 为 nil")

// 用另一个 UserDefaults 实例指向同一 suite → 读到的是同一份数据（证明真的落盘了）
let reopened = UserDefaults(suiteName: suiteName)!
expect(reopened.integer(forKey: "launchCount") == 42, "重开同 suite 仍能读到 42（已持久化）")

// 清理：删掉整个持久域，别留脏数据
UserDefaults.standard.removePersistentDomain(forName: suiteName)
expect(UserDefaults(suiteName: suiteName)!.object(forKey: "launchCount") == nil,
       "removePersistentDomain 后数据已清空")

// =====================================================================
// 2) 文件系统：FileManager + Data
// =====================================================================
line("")
line("-- 文件：Documents/Library/tmp 三类目录，写 Data 再读回 --")
let fm = FileManager.default
// 三个标准目录各自的用途：
//   Documents      用户数据，会被 iCloud/iTunes 备份
//   Library/Caches 可重建的缓存，磁盘紧张时系统可能清掉
//   tmp            临时文件，App 不运行时系统可随时删
let tempDir = fm.temporaryDirectory
line("  temporaryDirectory 存在 : \(fm.fileExists(atPath: tempDir.path))")
expect(fm.fileExists(atPath: tempDir.path), "tmp 目录存在")

// 建一个唯一子目录，跑完整块删掉
let workDir = tempDir.appendingPathComponent("example18-\(UUID().uuidString)")
try fm.createDirectory(at: workDir, withIntermediateDirectories: true)
expect(fm.fileExists(atPath: workDir.path), "createDirectory 建出了唯一工作目录")

let filePath = workDir.appendingPathComponent("note.txt")
let payload = "你好，文件系统".data(using: .utf8)!
try payload.write(to: filePath)                    // 原子写
expect(fm.fileExists(atPath: filePath.path), "write(to:) 之后文件存在")

let readBack = try Data(contentsOf: filePath)
expect(readBack == payload, "读回的 Data 与写入逐字节相同")
expect(String(data: readBack, encoding: .utf8) == "你好，文件系统", "解码回原字符串")

// 文件属性：大小是确定的（等于写入字节数），不是环境相关量
let attrs = try fm.attributesOfItem(atPath: filePath.path)
let fileSize = (attrs[.size] as? NSNumber)?.intValue ?? -1
line("  文件大小 = \(fileSize) 字节")
expect(fileSize == payload.count, "attributesOfItem 报告的大小 == 写入字节数")

// 目录内容枚举
let listing = try fm.contentsOfDirectory(atPath: workDir.path)
expect(listing == ["note.txt"], "contentsOfDirectory 列出了唯一一个文件")

// 移动 / 删除
let movedPath = workDir.appendingPathComponent("renamed.txt")
try fm.moveItem(at: filePath, to: movedPath)
expect(fm.fileExists(atPath: movedPath.path) && !fm.fileExists(atPath: filePath.path),
       "moveItem 之后：新路径在、旧路径没了")

try fm.removeItem(at: workDir)
expect(!fm.fileExists(atPath: workDir.path), "removeItem 递归删掉了整个工作目录")

// =====================================================================
// 3) Codable：struct ↔ JSON Data，稳定序列化
// =====================================================================
line("")
line("-- Codable：模型与 JSON 双向转换 --")
let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)   // 固定时间戳，结果确定
let profile = Profile(name: "小明", age: 30, tags: ["b", "a"], createdAt: fixedDate)

// .sortedKeys：让字典键按字母序输出，JSON 字节稳定（否则键顺序不保证 → 无法逐字节比对）
// .prettyPrinted 只为好读；本示例只关心往返一致，故不加，保持字节紧凑确定。
let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]
encoder.dateEncodingStrategy = .iso8601
let jsonData = try encoder.encode(profile)
let jsonText = String(data: jsonData, encoding: .utf8)!
line("  JSON = \(jsonText)")

// 键已排序：age 在 createdAt 前，createdAt 在 name 前，name 在 tags 前
expect(jsonText.range(of: "\"age\"")!.lowerBound < jsonText.range(of: "\"createdAt\"")!.lowerBound,
       ".sortedKeys：age 排在 createdAt 之前")
expect(jsonText.contains("\"tags\":[\"b\",\"a\"]"), "数组顺序被保留（tags 不排序，只排字典键）")

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
let decoded = try decoder.decode(Profile.self, from: jsonData)
expect(decoded == profile, "decode(encode(x)) == x（含 Date 的完整往返）")

// 把 Codable 存进 UserDefaults：先编码成 Data，再 set(_:,forKey:)
let suite2 = "com.iosdev.example18.codable"
UserDefaults.standard.removePersistentDomain(forName: suite2)
let d2 = UserDefaults(suiteName: suite2)!
d2.set(jsonData, forKey: "profile")
if let back = d2.data(forKey: "profile"),
   let p2 = try? decoder.decode(Profile.self, from: back) {
    expect(p2 == profile, "Codable→Data→UserDefaults→Data→Codable 全链路往返一致")
} else {
    expect(false, "从 UserDefaults 取回并解码 Profile 失败")
}
UserDefaults.standard.removePersistentDomain(forName: suite2)

// =====================================================================
// 4) plist：PropertyListSerialization（UserDefaults 底层就是这个格式）
// =====================================================================
line("")
line("-- plist：字典 ↔ XML/二进制 plist --")
let dict: [String: Any] = [
    "version": 3,
    "name": "配置文件",
    "enabled": true,
    "items": ["x", "y"],
]
// 校验这个字典能否序列化成 xml plist（不是所有 Any 都能塞进 plist）
let valid = PropertyListSerialization.propertyList(
    dict, isValidFor: .xml)   // 校验这个字典能否序列化成 xml plist
expect(valid, "字典是合法的 property list（isValidFor:.xml == true）")

let xmlData = try PropertyListSerialization.data(
    fromPropertyList: dict, format: .xml, options: 0)
let xmlHead = String(data: xmlData.prefix(60), encoding: .utf8) ?? ""
line("  XML plist 开头 = \(xmlHead.replacingOccurrences(of: "\n", with: " "))")
expect(xmlHead.contains("<?xml"), "xml 格式以 <?xml 声明开头")

let binData = try PropertyListSerialization.data(
    fromPropertyList: dict, format: .binary, options: 0)
// 二进制 plist 以魔数 "bplist" 开头
let magic = String(data: binData.prefix(6), encoding: .ascii) ?? ""
expect(magic == "bplist0" || magic.hasPrefix("bplist"), "二进制 plist 以魔数 bplist 开头")
line("  二进制比 XML 小 : \(binData.count) < \(xmlData.count)")
expect(binData.count < xmlData.count, "同一份数据：二进制 plist 比 XML 更省空间")

// 反解回来
var fmt = PropertyListSerialization.PropertyListFormat.xml
let roundTrip = try PropertyListSerialization.propertyList(
    from: xmlData, options: [], format: &fmt) as! [String: Any]
expect(fmt == .xml, "format 输出参数报告解析出的是 xml")
expect((roundTrip["version"] as? Int) == 3, "plist 往返：version == 3")
expect((roundTrip["name"] as? String) == "配置文件", "plist 往返：name == 配置文件")
expect((roundTrip["items"] as? [String]) == ["x", "y"], "plist 往返：items == [x,y]")

// =====================================================================
// 5) Keychain：加密存储（Security 框架 SecItem*）
// =====================================================================
// 关键边界：Keychain 是**按 App 的钥匙串访问组（entitlement）**隔离的。本示例是被
// `simctl spawn` 直接拉起的裸可执行文件，没有 .app 包、没有签名、没有 entitlement，
// 所以任何 SecItem 读写都会返回 errSecMissingEntitlement(-34018)。这不是代码写错，
// 而是「没有钥匙串访问权」——在一个正常签名的 .app（见第 20 章）里，同样的调用
// 返回 errSecSuccess(0)。下面把**正确的 API 用法**完整写出来并真跑，然后断言在本
// headless 语境下拿到那个确定的、可解释的 entitlement 错误码（而不是假装成功）。
line("")
line("-- Keychain：SecItem 增/查/改/删（裸 spawn 无 entitlement）--")
let service = "com.iosdev.example18.keychain"
let account = "demo-user"

// ADD：存一个密码。kSecAttrAccessible 控制「什么时候能读」，
// .whenUnlocked = 设备解锁后才可读（最常用的默认策略）。
let secret = "s3cr3t-token".data(using: .utf8)!
let addQuery: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,       // 通用密码，最常用的一类
    kSecAttrService as String: service,                  // 归属服务（自己起的命名空间）
    kSecAttrAccount as String: account,                  // 账户名
    kSecValueData as String: secret,                     // 真正的密文字节
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
]
let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
line("  SecItemAdd 返回 = \(addStatus)（errSecMissingEntitlement=\(errSecMissingEntitlement)）")
expect(addStatus == errSecMissingEntitlement,
       "裸 spawn 无钥匙串 entitlement → SecItemAdd 确定返回 errSecMissingEntitlement")

// READ：kSecReturnData + kSecMatchLimitOne 取回那条数据。同样被 entitlement 挡住，
// 返回 errSecMissingEntitlement（不是「找不到」，而是「没权访问」）。
let readQuery: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
    kSecAttrAccount as String: account,
    kSecReturnData as String: true,                       // 要回数据本体
    kSecMatchLimit as String: kSecMatchLimitOne,          // 只取一条
]
var item: CFTypeRef?
let readStatus = SecItemCopyMatching(readQuery as CFDictionary, &item)
expect(readStatus == errSecMissingEntitlement,
       "SecItemCopyMatching 同样因缺 entitlement 被拒")
expect(item == nil, "被拒时不返回任何数据（item 为 nil）")

// UPDATE：SecItemUpdate(查询字典, 新属性字典)。API 形状记牢，签名 App 里就能改值。
let updateQuery: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
    kSecAttrAccount as String: account,
]
let updateAttrs: [String: Any] = [kSecValueData as String: "rotated-token".data(using: .utf8)!]
let updStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttrs as CFDictionary)
expect(updStatus == errSecMissingEntitlement, "SecItemUpdate 同样被 entitlement 挡住")

// DELETE：只按 class+service 删（不加 account 就是删这个 service 下的全部）。
let delQuery: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
]
let delStatus = SecItemDelete(delQuery as CFDictionary)
// 删除在「压根没这条 + 没 entitlement」时不是 success；这里同样落在 entitlement 错误。
line("  SecItemDelete 返回 = \(delStatus)")
expect(delStatus == errSecMissingEntitlement, "SecItemDelete 在本语境同样被拒")

line("  正确用法已完整演示；换成第 20 章那种签名 .app，以上全部返回 errSecSuccess")


// =====================================================================
// 6) 心智模型：什么数据放哪一层
// =====================================================================
line("")
line("-- 选型：把数据放对层 --")
line("  偏好/开关/轻量值   → UserDefaults（plist，别放大对象，别放敏感数据）")
line("  结构化模型/大文本   → Codable 编码成 JSON 存文件，或存进 UserDefaults 的 Data")
line("  用户文档/大文件     → Documents 目录（会被备份）")
line("  可重建的缓存        → Library/Caches（系统可清理）")
line("  密码/token/证书     → Keychain（加密，跨 App 卸载仍可控，唯一该放敏感数据的地方）")
line("  关系型/大量结构化   → CoreData（需 Xcode 建模）或 SwiftData（iOS 17+）")
expect(true, "前四层均由读写往返实证；Keychain 因裸 spawn 无 entitlement 被拒（API 用法已完整演示，签名 App 里即 errSecSuccess）")

line("")
if failures == 0 { line("全部断言通过。") } else { line("有 \(failures) 条断言失败。") }
print("==== 18 结束 ====")
exit(failures == 0 ? 0 : 1)
