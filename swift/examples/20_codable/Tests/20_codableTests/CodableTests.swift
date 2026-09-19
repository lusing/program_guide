import Foundation
// 20_codable 的 swift-testing 测试
import Testing

@testable import Ch20Codable

@Test func book往返() throws {
    let book = Book(title: "T", author: "A", year: 2020, tags: ["x"])
    #expect(try Coding.roundtrip(book) == book)
    let json = try Coding.encodeJSON(book, pretty: false)
    #expect(json.contains("\"title\":\"T\""))
}

@Test func 键名映射与日期() throws {
    let epoch = Date(timeIntervalSince1970: 0)
    let article = Article(id: 1, headline: "H", publishedAt: epoch)
    let json = try Coding.encodeJSON(article, pretty: false)
    #expect(json.contains("\"title\":\"H\""))
    #expect(json.contains("\"published_at\":0"))
    #expect(!json.contains("headline"))
    #expect(try Coding.roundtrip(article) == article)
}

@Test func 自定义坐标格式() throws {
    let p = Point(x: 3, y: 4)
    let json = try Coding.encodeJSON(p, pretty: false)
    #expect(json.contains("\"coordinate\":\"3.0,4.0\""))
    #expect(try Coding.roundtrip(p) == p)
    #expect(
        try Coding.decodeJSON(Point.self, from: #"{"coordinate":"-1.5,2"}"#) == Point(x: -1.5, y: 2)
    )
}

@Test func 坏坐标抛数据损坏() {
    #expect(throws: DecodingError.self) {
        _ = try Coding.decodeJSON(Point.self, from: #"{"coordinate":"abc"}"#)
    }
}

@Test func 嵌套与可选() throws {
    let book = Book(title: "T", author: "A", year: 2000, tags: [])
    let lib = Library(name: "L", books: [book], founded: nil)
    let json = try Coding.encodeJSON(lib)
    #expect(!json.contains("founded"))
    var withDate = lib
    withDate.founded = 1998
    #expect(try Coding.roundtrip(withDate).founded == 1998)
    #expect(try Coding.roundtrip(withDate).books == [book])
}

@Test func 类型不匹配与缺字段() {
    #expect(throws: DecodingError.self) {
        _ = try Coding.decodeJSON(
            Book.self, from: #"{ "title": 42, "author": "x", "year": 1, "tags": [] }"#)
    }
    #expect(throws: DecodingError.self) {
        _ = try Coding.decodeJSON(Book.self, from: "{ }")
    }
}
