// 20 · Codable——JSON 编解码全流程、自定义 CodingKey、日期与键策略、容错

import Foundation

// ═══ 20.1 纯函数区（供测试）
struct Book: Codable, Equatable {
    let title: String
    let author: String
    let year: Int
    let tags: [String]
}

/// 自定义 CodingKeys：字段名 ↔ JSON 键名解耦
struct Article: Codable, Equatable {
    let id: Int
    let headline: String
    let publishedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case headline = "title"  // Swift 字段 headline，JSON 里叫 title
        case publishedAt = "published_at"  // snake_case 键映射
    }
}

/// 手写 encode/decode：完全接管序列化格式
struct Point: Equatable {
    var x: Double
    var y: Double
}

extension Point: Codable {
    private enum CodingKeys: String, CodingKey {
        case coordinate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let raw = try container.decode(String.self, forKey: .coordinate)  // "3.0,4.0"
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
        try container.encode("\(x),\(y)", forKey: .coordinate)  // 编成单个字符串
    }
}

/// 嵌套结构 + 可选字段 + 数组
struct Library: Codable, Equatable {
    let name: String
    var books: [Book]
    var founded: Int?
}

enum Coding {
    static func encodeJSON<T: Encodable>(_ value: T, pretty: Bool = true) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = pretty ? [.prettyPrinted, .sortedKeys] : []
        encoder.dateEncodingStrategy = .secondsSince1970
        let data = try encoder.encode(value)
        return String(data: data, encoding: .utf8)!
    }

    static func decodeJSON<T: Decodable>(_ type: T.Type, from text: String) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return try decoder.decode(type, from: Data(text.utf8))
    }

    static func roundtrip<T: Codable & Equatable>(_ value: T) throws -> T {
        try decodeJSON(T.self, from: encodeJSON(value))
    }
}

// ═══ 20.2 基本往返：Swift 值 → JSON 文本 → Swift 值
let swiftBook = Book(title: "Swift 进阶", author: "某作者", year: 2024, tags: ["语言", "进阶"])
let json = try Coding.encodeJSON(swiftBook)
print("① 编码：")
print(json)
let decoded = try Coding.decodeJSON(Book.self, from: json)
precondition(decoded == swiftBook)
print("② 解码往返：一致 ✓")

// ═══ 20.3 自定义键名 + 日期策略
let epoch = Date(timeIntervalSince1970: 1_735_689_600)  // 固定时刻：确定性纪律
let article = Article(id: 7, headline: "Swift 6 发布", publishedAt: epoch)
let articleJSON = try Coding.encodeJSON(article, pretty: false)
print("③ 键名映射：\(articleJSON)")
precondition(articleJSON.contains("\"title\""))
precondition(articleJSON.contains("\"published_at\":1735689600"))
let articleBack = try Coding.roundtrip(article)  // precondition 的自动闭包不吃 try，先求值
precondition(articleBack == article)

// ═══ 20.4 手写编解码：字符串坐标
let point = Point(x: 3, y: 4)
let pointJSON = try Coding.encodeJSON(point, pretty: false)
print("④ 自定义格式：\(pointJSON)")
precondition(pointJSON.contains("\"coordinate\":\"3.0,4.0\""))
let pointBack = try Coding.roundtrip(point)
precondition(pointBack == point)

// ═══ 20.5 嵌套与可选字段
var library = Library(name: "城市图书馆", books: [swiftBook, swiftBook], founded: nil)
let libraryJSON = try Coding.encodeJSON(library)
print("⑤ 嵌套编码（\(library.books.count) 本书，founded 省略）：")
print(libraryJSON)
precondition(!libraryJSON.contains("founded"))
library.founded = 1998
let back = try Coding.roundtrip(library)
precondition(back.founded == 1998 && back.books.count == 2)

// ═══ 20.6 容错：字段类型错误给出可定位的 DecodingError
let badJSON = #"{ "title": 42, "author": "x", "year": 2020, "tags": [] }"#
do {
    _ = try Coding.decodeJSON(Book.self, from: badJSON)
    precondition(false, "应当抛错")
} catch let error as DecodingError {
    print("⑥ 类型不匹配被拦截：\(error)")
}
do {
    _ = try Coding.decodeJSON(Book.self, from: "{ }")
} catch DecodingError.keyNotFound(let key, _) {
    print("⑦ 缺字段被拦截：缺 \(key.stringValue)")
}

print("==== 20 结束 ====")
