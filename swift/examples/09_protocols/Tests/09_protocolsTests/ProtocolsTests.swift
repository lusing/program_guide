// 09_protocols 的 swift-testing 测试
import Testing

@testable import Ch09Protocols

@Test func 默认实现可用可覆盖() {
    #expect(Circle(radius: 1).draw() == "◯ 半径 1.0")
    #expect(Square(side: 3).draw() == "【方】用默认画笔绘制")
    #expect(Square(side: 3).drawTwice() == "【方】用默认画笔绘制 ×2")
}

@Test func some与any列表() {
    let circles = [Circle(radius: 1), Circle(radius: 2)]
    #expect(render(circles) == ["◯ 半径 1.0", "◯ 半径 2.0"])
    let mixed: [any Drawable] = [Circle(radius: 5), Square(side: 6)]
    #expect(renderAny(mixed) == ["◯ 半径 5.0", "【方】用默认画笔绘制"])
}

@Test func 协议参数多态() {
    #expect(banner(of: Square(side: 1)) == "──────\n【方】用默认画笔绘制 ×2\n──────")
    #expect(banner(of: Circle(radius: 9)).contains("◯ 半径 9.0"))
}

@Test func equatable与firstIndex() {
    let shelf = [Book(title: "A", year: 2000), Book(title: "B", year: 1990)]
    #expect(findBook(Book(title: "B", year: 1990), in: shelf) == 1)
    #expect(findBook(Book(title: "C", year: 2000), in: shelf) == nil)
}

@Test func comparable排序() {
    let books = [Book(title: "新", year: 2024), Book(title: "旧", year: 1978)]
    #expect(sortedByYear(books).map(\.title) == ["旧", "新"])
}

@Test func hashable去重() {
    let books = [Book(title: "X", year: 1), Book(title: "X", year: 1), Book(title: "Y", year: 2)]
    #expect(dedup(books).count == 2)
}

@Test func customStringConvertible() {
    #expect(Book(title: "Z", year: 2000).description == "《Z》(2000)")
}
