# 18 · 数据持久化：UserDefaults / 文件 / Codable / plist / Keychain

> 示例：`examples/18_persistence/main.swift`
> 实测输出见 `build/18_persistence/stdout.debug.txt`

App 一退，内存里的东西全没了。「存下来、下次还在」在 iOS 上分几层，按**数据大小**和
**敏感度**选：轻量偏好用 `UserDefaults`，模型和文档用**文件 + Codable**，密码/token 用
**Keychain**。本章把每一层都真跑一遍——写进去什么、读出来什么，全是确定断言。

> **headless 隔离**：所有读写都落在隔离命名空间——`UserDefaults` 用自定义 `suiteName`，
> 文件写在 `FileManager.temporaryDirectory` 下的唯一子目录，跑完主动清理，绝不留脏数据。

## 1) UserDefaults：轻量键值

`UserDefaults` 本质是一个 **property-list 字典**落成的 plist 文件，只放
`Int/Double/Bool/String/Data/Array/Dictionary/Date` 这几类。适合偏好、开关、上次的位置。

```swift
// 自定义 suite 名 → 独立 plist，不污染 App 标准 defaults，方便整块清理
let suiteName = "com.iosdev.example18.prefs"
UserDefaults.standard.removePersistentDomain(forName: suiteName)   // 幂等起点
let defaults = UserDefaults(suiteName: suiteName)!

defaults.set(42, forKey: "launchCount")
defaults.set(true, forKey: "onboarded")
defaults.set("深色", forKey: "theme")
defaults.set(Data([1, 2, 3]), forKey: "blob")
```

```
-- UserDefaults：suiteName 隔离的键值存储 --
  ok   Int 往返一致（42）
  ok   Bool 往返一致（true）
  ok   String 往返一致（深色）
  ok   Data 往返一致（[1,2,3]）
  ok   synchronize() 返回 true（成功刷盘）
  ok   不存在的键 object(forKey:) 为 nil
  ok   重开同 suite 仍能读到 42（已持久化）
  ok   removePersistentDomain 后数据已清空
```

三个要点：

- **类型化取值**：`integer(forKey:)`/`bool(forKey:)`/`string(forKey:)`/`data(forKey:)`。
  不存在的键，`integer`/`bool` 返回 **0/false**，而 `object(forKey:)` 返回 **nil**——想区分
  「没设过」和「设成了 0」，用 `object(forKey:)`。
- **`synchronize()`**：把内存改动强制刷盘。现代 iOS 会自动异步落盘，一般不用手调；示例里
  调一次是为了让「写完立刻从磁盘读」这件事确定发生（返回 `true`）。
- **持久性可验**：另开一个指向**同 suite** 的 `UserDefaults` 实例仍能读到 42，证明数据真的
  落盘了，不是只活在第一个实例的内存里。
- **`removePersistentDomain(forName:)`**：一次删掉整个 suite，是自测的自清场手段。

> **别拿它当数据库**：`UserDefaults` 会为每次读把整个 plist 载入内存，放大对象（图片、
> 大数组）会拖慢启动。它也**不加密**，敏感数据一律走 Keychain。

## 2) 文件系统：三类目录

iOS 沙盒里有三个标准落盘位置，用途不同：

| 目录 | 放什么 | 会被备份吗 | 系统会清吗 |
| --- | --- | --- | --- |
| `Documents/` | 用户数据、不可重建的内容 | 会（iCloud/iTunes） | 不会 |
| `Library/Caches/` | 可重建的缓存 | 不 | 磁盘紧张时可能 |
| `tmp/` | 临时文件 | 不 | App 不运行时随时可能 |

```swift
let fm = FileManager.default
let workDir = fm.temporaryDirectory.appendingPathComponent("example18-\(UUID().uuidString)")
try fm.createDirectory(at: workDir, withIntermediateDirectories: true)

let filePath = workDir.appendingPathComponent("note.txt")
try "你好，文件系统".data(using: .utf8)!.write(to: filePath)   // 原子写
let readBack = try Data(contentsOf: filePath)
```

```
-- 文件：Documents/Library/tmp 三类目录，写 Data 再读回 --
  temporaryDirectory 存在 : true
  ok   tmp 目录存在
  ok   createDirectory 建出了唯一工作目录
  ok   write(to:) 之后文件存在
  ok   读回的 Data 与写入逐字节相同
  ok   解码回原字符串
  文件大小 = 21 字节
  ok   attributesOfItem 报告的大小 == 写入字节数
  ok   contentsOfDirectory 列出了唯一一个文件
  ok   moveItem 之后：新路径在、旧路径没了
  ok   removeItem 递归删掉了整个工作目录
```

常用 API：`createDirectory(withIntermediateDirectories:)` 建目录、`write(to:)` /
`Data(contentsOf:)` 读写、`attributesOfItem` 取大小（示例里 21 字节 == 写入字节数，是确定值）、
`contentsOfDirectory` 枚举、`moveItem` / `removeItem` 移动与递归删除。

> **`write(to:)` 默认原子**：先写临时文件再改名，进程中途被杀不会留下写坏一半的文件。
> 需要额外保证可传 `.atomic` 选项（`write(to:options:)`）。

## 3) Codable：模型 ↔ JSON

`Codable` 是 struct/class 与 `Data` 之间的双向桥。存文件、存 `UserDefaults`、发网络都靠它。

```swift
struct Profile: Codable, Equatable {
    var name: String; var age: Int; var tags: [String]; var createdAt: Date
}

let encoder = JSONEncoder()
encoder.outputFormatting = [.sortedKeys]        // 关键：键排序 → 字节稳定
encoder.dateEncodingStrategy = .iso8601         // Date ↔ "2023-11-14T22:13:20Z"
let jsonData = try encoder.encode(profile)

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
let decoded = try decoder.decode(Profile.self, from: jsonData)   // == profile
```

```
-- Codable：模型与 JSON 双向转换 --
  JSON = {"age":30,"createdAt":"2023-11-14T22:13:20Z","name":"小明","tags":["b","a"]}
  ok   .sortedKeys：age 排在 createdAt 之前
  ok   数组顺序被保留（tags 不排序，只排字典键）
  ok   decode(encode(x)) == x（含 Date 的完整往返）
  ok   Codable→Data→UserDefaults→Data→Codable 全链路往返一致
```

两个易踩的点：

- **`.sortedKeys`**：JSON 对象的键顺序**默认不保证**。要做逐字节比对（或稳定哈希、稳定缓存
  key），必须开 `.sortedKeys`。注意它只排**字典键**，数组元素顺序**原样保留**（`tags` 仍是
  `["b","a"]`）。
- **Date 策略**：`Date` 默认编码成一个浮点数（参考日期起的秒数），可读性差。`.iso8601` 让它
  变成 `"2023-11-14T22:13:20Z"`。编解码两端的策略必须一致，否则解不回来。

存进 `UserDefaults` 的套路：`encode` 成 `Data` → `set(_:forKey:)`；取回时 `data(forKey:)` →
`decode`。示例走完了这条全链路并验证往返一致。

## 4) plist：PropertyListSerialization

`UserDefaults`、`Info.plist` 底层都是 **property list** 格式。`PropertyListSerialization`
让你在字典/数组和 plist 字节之间转换，可选 **XML** 或 **二进制** 两种格式。

```swift
let dict: [String: Any] = ["version": 3, "name": "配置文件", "enabled": true, "items": ["x","y"]]
PropertyListSerialization.propertyList(dict, isValidFor: .xml)   // 先校验能否序列化

let xmlData = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
let binData = try PropertyListSerialization.data(fromPropertyList: dict, format: .binary, options: 0)

var fmt = PropertyListSerialization.PropertyListFormat.xml
let back = try PropertyListSerialization.propertyList(from: xmlData, options: [], format: &fmt)
```

```
-- plist：字典 ↔ XML/二进制 plist --
  ok   字典是合法的 property list（isValidFor:.xml == true）
  XML plist 开头 = <?xml version="1.0" encoding="UTF-8"?> <!DOCTYPE plist PUBLI
  ok   xml 格式以 <?xml 声明开头
  ok   二进制 plist 以魔数 bplist 开头
  二进制比 XML 小 : 106 < 386
  ok   同一份数据：二进制 plist 比 XML 更省空间
  ok   format 输出参数报告解析出的是 xml
  ok   plist 往返：version == 3
  ok   plist 往返：name == 配置文件
  ok   plist 往返：items == [x,y]
```

- **`isValidFor:`**：不是所有 `Any` 都能进 plist——只有那几类 property-list 类型。先校验再序列化。
- **两种格式**：XML 可读、以 `<?xml` 开头；二进制以魔数 `bplist` 开头，**更省空间**（示例里
  106 < 386 字节）也更快。`Info.plist` 发布版通常转成二进制。
- **`format:` 是 `inout`**：反解时它作为输出参数告诉你解析出的是哪种格式。

## 5) Keychain：加密存储，以及一个诚实的边界

密码、token、证书这类敏感数据**只能**放 Keychain——它加密落盘，且访问被 App 的
**钥匙串访问组（entitlement）**隔离。API 是 Security 框架的 `SecItem*` 四件套：

```swift
// 增：kSecValueData 放密文字节，kSecAttrAccessible 控制「何时可读」
let addQuery: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrService as String: service,
    kSecAttrAccount as String: account,
    kSecValueData as String: secret,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,   // 解锁后才可读
]
SecItemAdd(addQuery as CFDictionary, nil)

// 查：kSecReturnData + kSecMatchLimitOne
var item: CFTypeRef?
SecItemCopyMatching([…, kSecReturnData as String: true,
                     kSecMatchLimit as String: kSecMatchLimitOne] as CFDictionary, &item)

// 改：SecItemUpdate(查询字典, 新属性字典)   删：SecItemDelete(查询字典)
```

```
-- Keychain：SecItem 增/查/改/删（裸 spawn 无 entitlement）--
  SecItemAdd 返回 = -34018（errSecMissingEntitlement=-34018）
  ok   裸 spawn 无钥匙串 entitlement → SecItemAdd 确定返回 errSecMissingEntitlement
  ok   SecItemCopyMatching 同样因缺 entitlement 被拒
  ok   被拒时不返回任何数据（item 为 nil）
  ok   SecItemUpdate 同样被 entitlement 挡住
  SecItemDelete 返回 = -34018
  ok   SecItemDelete 在本语境同样被拒
  正确用法已完整演示；换成第 20 章那种签名 .app，以上全部返回 errSecSuccess
```

> **为什么不返回 success？** 本示例是被 `simctl spawn` 直接拉起的**裸可执行文件**：没有
> `.app` 包、没有签名、没有 `keychain-access-groups` entitlement。Keychain 按 entitlement
> 隔离访问，所以任何 `SecItem*` 调用都确定返回 **`errSecMissingEntitlement`(-34018)**——
> 这不是代码写错，而是「这个进程没有钥匙串访问权」。在一个**正常签名的 `.app`**（第 20 章）
> 里，上面同样的四段调用会全部返回 `errSecSuccess(0)`。
>
> 教程在这里**不假装成功**：完整写出正确 API 用法并真跑，然后断言拿到那个**确定的、可解释的**
> entitlement 错误码。这与第 16 章「裸 spawn 下 `sendActions` 不触发 target-action」是同一种
> 处理方式——把 headless 的真实边界讲清楚，而不是伪造一个绿灯。

`kSecAttrAccessible` 常用值：`.whenUnlocked`（解锁后可读，默认首选）、
`.afterFirstUnlock`（重启后首次解锁起可读，适合后台任务）、`.whenUnlockedThisDeviceOnly`
（同前但不随备份迁移到新设备）。

## 6) 选型：把数据放对层

```
-- 选型：把数据放对层 --
  偏好/开关/轻量值   → UserDefaults（plist，别放大对象，别放敏感数据）
  结构化模型/大文本   → Codable 编码成 JSON 存文件，或存进 UserDefaults 的 Data
  用户文档/大文件     → Documents 目录（会被备份）
  可重建的缓存        → Library/Caches（系统可清理）
  密码/token/证书     → Keychain（加密，跨 App 卸载仍可控，唯一该放敏感数据的地方）
  关系型/大量结构化   → CoreData（需 Xcode 建模）或 SwiftData（iOS 17+）
```

### CoreData / SwiftData 为什么没在这里跑

- **CoreData** 需要 `.xcdatamodeld` 模型文件，由 Xcode 工程在编译期生成 `NSManagedObject`
  子类——它不是一个能在单文件命令行示例里 headless 演示的东西。定位：对象图管理 + 持久化 +
  变更追踪，适合大量结构化、有关系的数据。
- **SwiftData** 是 CoreData 的现代 Swift 封装（`@Model` 宏、纯 Swift、无建模文件），但要
  **iOS 17+**。本教程部署目标钉在 **15.0**，故只在文档里点出，不编译。

轻中量数据用「Codable + 文件」往往就够了；真的需要查询、关系、增量更新时再上 CoreData/SwiftData。

## 心智模型小结

```
UserDefaults = 落盘的 plist 字典，轻量键值；不加密、别放大对象
文件 = Documents(备份)/Caches(可清)/tmp(临时)；write(to:) 原子写
Codable = 模型 ↔ JSON；.sortedKeys 保字节稳定，Date 用 .iso8601
plist = UserDefaults/Info.plist 的底层格式；二进制比 XML 省
Keychain = 唯一加密层，按 entitlement 隔离；裸 spawn 无 entitlement 必被拒
```

## 坑清单

| 现象 | 原因 |
| --- | --- |
| `integer(forKey:)` 拿不到「没设过」和「设成 0」的区别 | 不存在时返回 0；要区分用 `object(forKey:) == nil` |
| 启动变慢 | 往 `UserDefaults` 塞了大对象；改存文件 |
| JSON 字节每次不一样，比对失败 | 键顺序不保证；开 `outputFormatting = [.sortedKeys]` |
| `Date` 编解码对不上 | 编解码两端的 `dateEncodingStrategy` 必须一致（都用 `.iso8601`） |
| plist 序列化崩 | 字典里有非 property-list 类型；先 `isValidFor:` 校验 |
| `SecItemAdd` 返回 -34018 | 进程无 `keychain-access-groups` entitlement（如裸 spawn）；需签名 .app |
| 敏感数据泄漏 | 存进了 `UserDefaults`/文件；敏感数据只能进 Keychain |

## 小结

- **`UserDefaults`**：轻量键值，本质是落盘 plist；类型化取值，不存在键 `object(forKey:)` 为 nil。
- **文件**：`Documents`（备份）/`Caches`（可清）/`tmp`（临时）；`FileManager` + `Data.write(to:)`
  原子写，跑完自清场。
- **`Codable`**：模型 ↔ JSON；`.sortedKeys` 让字节稳定，`.iso8601` 处理 `Date`，往返可完整验证。
- **plist**：`PropertyListSerialization` 在字典与 XML/二进制 plist 间转换，二进制更省。
- **Keychain**：唯一加密层，`SecItem*` 四件套；裸 spawn 无 entitlement 必返回 `-34018`，
  签名 App（第 20 章）里才 `errSecSuccess`——教程如实演示边界，不伪造成功。
- 下一章讲**权限 / 通知 / 设备能力**（Info.plist 用途说明、`UNUserNotificationCenter`、授权状态）。
