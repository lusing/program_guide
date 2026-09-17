# 16 · 持久化：UserDefaults、plist、文件、本地化

> 示例：`examples/16_persistence/main.swift`
> 实测输出见 `build/16_persistence/stdout.clt.txt`

macOS 上「存数据」有五六个层次。本章从轻到重走一遍，
并重点讲那些**看着能工作其实有坑**的地方。

## 1) UserDefaults

```swift
let defaults = UserDefaults(suiteName: "dev.macosdev.demo")!
defaults.set("dark", forKey: "theme")
defaults.string(forKey: "theme")        // "dark"
```

### 类型化的取值会「编造」默认值

```
  ok   不存在的布尔读到 false（不是 nil）
  ok   不存在的整数读到 0
  ok   想区分「没设过」和「设成了 false」要用 object(forKey:)
```

`bool(forKey:)` 读不存在的值返回 `false`，`integer(forKey:)` 返回 `0` ——
**你无法区分「没设过」和「设成了 false/0」**。
要区分就用 `object(forKey:)`（返回 `Any?`）。

### register 不是「写进去」

```swift
defaults.register(defaults: ["lineNumbers": true])
defaults.bool(forKey: "lineNumbers")            // true
defaults.persistentDomain(forName: suite)?["lineNumbers"]   // nil！
```

实测：

```
  ok   register 提供默认值
  ok   register 之后 object(forKey:) 能读到
  ok   但持久域里没有它（register 不落盘）
```

`register(defaults:)` 只是往**注册域（NSRegistrationDomain）**里塞一份兜底值，
**不写磁盘**。所以：

- 每次启动都要重新 `register`
- 它**不能**用来「初始化一次然后不管」

### 域的层次

```
NSArgumentDomain        （命令行参数，优先级最高）
  ↓
Application domain      （你这个 app 的偏好，存在 ~/Library/Preferences）
  ↓
NSGlobalDomain          （系统级，所有 app 共享）
  ↓
NSRegistrationDomain    （register(defaults:) 放这，最低）
```

`object(forKey:)` 从上往下搜，**第一个有值的就返回**。

### 清空

```swift
defaults.removeObject(forKey: "theme")
defaults.removePersistentDomain(forName: suite)
```

> **坑**：`dictionaryRepresentation()` 合并了**全部域**
> （含系统级 NSGlobalDomain 等），所以它**几乎不可能为空**。
> 想确认自己这一域清干净了，用 `persistentDomain(forName:)`：

```
  ok   删掉整个持久域之后读不回来
```

### 什么该存在 UserDefaults

**只存偏好设置**（窗口位置、主题、最近文件列表）。
不要存：用户数据、大对象、密码（用 Keychain）。

## 2) plist

```swift
let data = try PropertyListSerialization.data(fromPropertyList: dict, format: .xml, options: 0)
let back = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
```

两种格式：

| 格式 | 特点 |
| --- | --- |
| `.xml` | 文本，可以直接看/diff，但大 |
| `.binary` | 二进制，小、快，人不可读 |

实测：

```
  ok   能序列化成 plist 数据
  ok   xml 格式是文本，能直接看
  ok   字符串按 XML 存
  ok   二进制格式也能写
  ok   这组类型对 binary 合法
```

**合法类型**：`NSString` `NSNumber` `NSDate` `NSData` `NSArray` `NSDictionary`
（以及 Swift 侧能桥接过去的 `String` `Int` `Double` `Bool` `Date` `Data` `[…]` `[…:…]`）。

放别的东西会在 `data(fromPropertyList:)` 时抛异常。

```
  ok   数字统一是 NSNumber
```

> **坑**：plist 里的数字全是 `NSNumber`，具体是 int 还是 double 由实现决定。
> 读回来不要依赖具体类型。

## 3) 文件读写

```swift
let dir = FileManager.default.temporaryDirectory.appendingPathComponent("demo-dir", isDirectory: true)
try fm.createDirectory(at: dir, withIntermediateDirectories: true)
try jsonData.write(to: dir.appendingPathComponent("prefs.json"))
let contents = try fm.contentsOfDirectory(atPath: dir.path)
```

实测：

```
== 文件读写 ==
  ok   JSON 文件写出来了
  ok   读回来和原值相等
  ok   plist 编解码也能往返
  ok   能读到文件大小
  ok   类型判断可用（实际 NSFileTypeRegular）
  目录内容 = prefs.json, prefs.plist
  ok   收尾删掉临时目录
```

该放哪：

| 用途 | 目录 |
| --- | --- |
| 应用支持文件（用户不该直接看的） | `~/Library/Application Support/<bundle-id>/` |
| 缓存（可重建） | `~/Library/Caches/<bundle-id>/` |
| 偏好 | `UserDefaults` |
| 用户文档 | 用户自己选的地方（或沙箱的 Documents） |
| 临时 | `FileManager.temporaryDirectory`（用 `NSTemporaryDirectory()` 拿也可以） |

用 `FileManager.SearchPathDirectory` 拿，别硬编码 `~/Library/...`：

```swift
let support = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask,
                         appropriateFor: nil, create: true)
```

## 4) Bundle 与 Info.plist

```
== Bundle ==
  ok   命令行工具的包就是可执行文件所在目录
  ok   有资源路径
  ok   命令行工具没有 bundle identifier
  ok   能读到 bundle identifier
  ok   能读到显示名
  ok   object(forInfoDictionaryKey:) 是读 Info.plist 的正路（它会做本地化替换）
```

> **坑**：读 Info.plist **一律用 `object(forInfoDictionaryKey:)`**，
> 不要直接翻 `infoDictionary`。前者会做**本地化变量替换**
> （把 `${PRODUCT_NAME}` 这类占位符替换成 `InfoPlist.strings` 里的翻译）。

## 5) 本地化

### NSLocalizedString

```swift
let text = NSLocalizedString("greeting", comment: "欢迎语")
```

找不到翻译时**返回 key 本身**：

```
  缺少 strings 文件 = no_such_key_anywhere
  ok   找不到翻译时返回 key 本身
```

所以 key 一般写成**英文原文**（这样没翻译时至少能看）。

### 带位置参数

不同语言里词序可能不同，用位置参数最稳：

```swift
String(format: NSLocalizedString("%1$@ has %2$d items", comment: ""), "收件箱", 5)
```

```
  带位置参数 = 收件箱 有 5 条
```

`%1$@` / `%2$d` 里的 `1$` `2$` 是**第几个参数**。
翻译成别的语言时只要调换 `%1$@` 和 `%2$d` 的先后顺序即可，代码不用动。

### 数字格式化要钉住 locale

```swift
let f = NumberFormatter()
f.locale = Locale(identifier: "en_US_POSIX")
f.numberStyle = .decimal
```

实测：

```
  12345.678 = 12345.678
  ok   钉住 locale 后能格式化出字符串
  读回来 = 12345.678
  ok   同一个 formatter 能读回来
```

> **坑**：`en_US_POSIX` 下的 `.decimal` **不带千位分隔符**
> （输出是 `12345.678`，不是 `12,345.678`）。
> 别照抄书上的例子 —— 具体有没有分隔符要实测。
>
> **坑**：不指定 `locale` 就跟着系统走，同一份代码在不同机器上输出不同。
> 写断言时要么钉住 locale，要么**只断言性质**（这里是「格式化 → 解析能回到原值」）。

## 6) 沙箱

Mac App Store 分发要求 App Sandbox。开启后：

- 只能读写自己的容器目录 + 用户显式授权的文件
- 需要权限要在 entitlements 里声明
  （`com.apple.security.files.user-selected.read-write` 等）
- **安全作用域书签**（security-scoped bookmark）用来持久化用户对某个目录的授权

```swift
let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil,
                                relativeTo: nil)
// 存起来；下次启动：
var stale = false
let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope,
                  relativeTo: nil, bookmarkDataIsStale: &stale)
url.startAccessingSecurityScopedResource()
defer { url.stopAccessingSecurityScopedResource() }
```

## 7) 坑清单

| 现象 | 原因 |
| --- | --- |
| 「没设过」和「设成 false」分不清 | 用了 `bool(forKey:)`；改用 `object(forKey:)` |
| register 的默认值下次启动没了 | register 不落盘，每次启动都要重新注册 |
| `dictionaryRepresentation()` 永远不空 | 它合并了全部域；用 `persistentDomain(forName:)` |
| plist 序列化抛异常 | 放了不合法类型（自定义对象、URL 等） |
| 数字读回来类型不对 | plist 里全是 NSNumber，int/double 由实现决定 |
| Info.plist 读到 `${PRODUCT_NAME}` | 直接翻了 `infoDictionary`；用 `object(forInfoDictionaryKey:)` |
| 数字格式在不同机器上不一样 | 没钉 `locale` |
| 沙箱下读不到文件 | 没声明 entitlement / 没有安全作用域书签 |

## 小结

- UserDefaults 只存偏好；`register` 不落盘；区分「没设过」用 `object(forKey:)`。
- plist 只有六种合法类型，数字统一是 NSNumber。
- 读 Info.plist 用 `object(forInfoDictionaryKey:)`。
- 格式化一定要钉 `locale`；多语言用 `%1$@` 位置参数。
- 沙箱下用安全作用域书签持久化目录授权。
