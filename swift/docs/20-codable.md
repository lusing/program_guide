# 20 · Codable

> 对应示例：`examples/20_codable/`

## 20.1 一行 conform，双向编解码

```swift
struct Book: Codable, Equatable {
    let title: String
    let author: String
    let year: Int
    let tags: [String]
}

let json = try JSONEncoder().encode(book)        // Swift → JSON 字节
let book2 = try JSONDecoder().decode(Book.self, from: data)   // JSON → Swift
```

`Codable = Encodable & Decodable`。conform 之后编译器合成两个协议的要求：

- `encode(to: Encoder)`：逐字段写进编码容器；
- `init(from: Decoder)`：逐字段读出并构造。

**合成条件**：所有存储属性的类型都 Codable（String/Int/Double/Bool/Data/URL/Date
全家 + 数组/字典/Optional/自定义 Codable 的组合）。90% 的场景一个 `: Codable` 就完事。

## 20.2 编解码器配置：输出与日期

```swift
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]   // 缩进 + 键排序（输出确定）
encoder.dateEncodingStrategy = .secondsSince1970            // 日期 → Unix 秒

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970            // 两边策略必须一致！
```

常用配置位：

| 配置 | 常用值 |
|---|---|
| `outputFormatting` | `.prettyPrinted`（缩进）、`.sortedKeys`（键序确定——**测试友好**） |
| `dateEncodingStrategy` | `.secondsSince1970`、`.iso8601`、`.millisecondsSince1970`、`.deferredToDate`（默认，双精度秒） |
| `keyEncodingStrategy` | `.convertToSnakeCase`（Swift camelCase ↔ JSON snake_case，全字段批量） |

`sortedKeys` 让同样的值永远编出同样的文本——**往返断言、快照测试的前提**
（示例 `Coding.encodeJSON` 的默认配置）。

## 20.3 自定义键名：CodingKeys

```swift
struct Article: Codable, Equatable {
    let id: Int
    let headline: String
    let publishedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case headline = "title"                // Swift 字段名 ≠ JSON 键名
        case publishedAt = "published_at"
    }
}
```

CodingKeys 枚举做"字段 ↔ 键"的对照表：`case 字段名 = "json键名"`，不写的用字段名
本身。单字段改名用它；全字段 snake_case 用 20.2 的 keyEncodingStrategy（别双用）。

**注意**：一旦写 CodingKeys，**所有**要参与编解码的字段都得列出——漏一个，那个
字段既不编也不解（可选字段可省略编码，但解不出值）。

## 20.4 手写编解码：完全接管格式

```swift
extension Point: Codable {
    private enum CodingKeys: String, CodingKey { case coordinate }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decode(String.self, forKey: .coordinate)   // "3.0,4.0"
        let parts = raw.split(separator: ",").compactMap { Double($0) }
        guard parts.count == 2 else {
            throw DecodingError.dataCorruptedError(
                forKey: .coordinate, in: container,
                debugDescription: "坐标格式应为 \"x,y\"：\(raw)")
        }
        x = parts[0]
        y = parts[1]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(x),\(y)", forKey: .coordinate)
    }
}
```

手写的三个时机：**格式不由你**（遗留 API 的 `"x,y"` 字符串）、**派生字段**（编 age
存出生年）、**校验**（解码即验证）。容器三兄弟：

- `keyedBy`：对象（键值）——最常用；
- `unkeyed`：数组（按下标顺序）；
- `singleValue`：整个值就是一个标量。

`DecodingError.dataCorruptedError(forKey:in:debugDescription:)` 抛出带上下文的错误
——比"解不开就返回 nil"的旧时代强一个代际。

## 20.5 嵌套、数组与可选字段

```swift
struct Library: Codable, Equatable {
    let name: String
    var books: [Book]     // 嵌套自动递归
    var founded: Int?     // 可选字段
}
```

- 嵌套结构递归编解码（Book 也 Codable 即可）；
- `nil` 可选字段**编码时省略**（不输出 `"founded": null`）；
- 解码时 JSON 缺这个键 → 可选字段得 nil（不报错）；非可选字段缺键 →
  `DecodingError.keyNotFound`。

## 20.6 容错：DecodingError 是可编程的

```swift
catch DecodingError.keyNotFound(let key, _) {
    print("缺字段：\(key.stringValue)")
}
```

四种错误各带定位信息：`keyNotFound`（缺键）、`typeMismatch`（类型不对，含期望与
实际）、`valueNotFound`（显式 null 给非可选）、`dataCorrupted`（手写解码的自定义
错误）。**别把 JSON 当可信输入**：解析失败是常态业务（12 章分层的又一案例）。

## 20.7 坑位清单（含实测）

1. **`precondition(try ...)` / `precondition(await ...)` 编译不过**（autoclosure 不
   吃 try/await，20 章实测）：先 `let back = try roundtrip(x)` 求值再断言——本章
   出现频率最高的坑。
2. **默认日期策略是"双精度秒"**：编出的 `1735689600.0` 不带引号但有小数尾巴——
   服务器对接显式选 `.secondsSince1970` 或 `.iso8601`，**编解码两侧必须同策略**
   （往返测试是唯一可信保证）。
3. **写 CodingKeys 必须列全字段**：漏列 = 静默不参与编解码（decode 后字段是默认
   逻辑的产物，最难查）。
4. **可选 nil 编码省略 ≠ 输出 null**：需要显式 null 的 API 用 `encodeIfPresent`
   的反向操作或自定义。
5. **`let` 字段改不了**（实测）：示例要演示"founded 先 nil 后 1998"——struct 声明
   成 `var founded: Int?` 才能赋值。
6. **Codable 的多态**：`[any Codable]` 不存在（existential 不 conform 自身）——
   "基类数组/带类型标签的联合"要么枚举建模（08 章的 JSON enum），要么手写解码。

上一章：[19 · 文件与 IO](19-files.md) ｜ 下一章：[21 · 测试](21-testing.md) ｜ 返回：[README](../README.md)
