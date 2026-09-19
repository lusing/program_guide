// 09 · 协议——面向协议编程、extension 默认实现、some/any、标准库协议

import Foundation

// ═══ 9.1 纯函数区（供测试）
// 协议即契约：实现方必须提供什么
protocol Drawable {
    var label: String { get }
    func draw() -> String
}

// extension 默认实现：协议的"免费午餐"，实现方可覆盖
extension Drawable {
    func draw() -> String {
        "【\(label)】用默认画笔绘制"
    }

    func drawTwice() -> String {  // 完全由默认实现提供的能力
        draw() + " ×2"
    }
}

struct Circle: Drawable {
    let label = "圆"
    var radius: Double
    func draw() -> String { "◯ 半径 \(radius)" }
}

struct Square: Drawable {
    let label = "方"
    var side: Double
    // 不写 draw() → 用 extension 默认实现
}

func render(_ shapes: [some Drawable]) -> [String] {  // some：同一列表同一种具体类型
    shapes.map { $0.draw() }
}

func renderAny(_ shapes: [any Drawable]) -> [String] {  // any：异构列表各自类型
    shapes.map { $0.draw() }
}

// ═══ 9.2 标准库协议：Equatable / Hashable / CustomStringConvertible / Comparable
struct Book: Equatable, Hashable, Comparable, CustomStringConvertible {
    let title: String
    let year: Int

    var description: String { "《\(title)》(\(year))" }

    static func < (lhs: Book, rhs: Book) -> Bool {  // Comparable 只需 < 与 ==
        lhs.year < rhs.year
    }
}

func sortedByYear(_ books: [Book]) -> [Book] {
    books.sorted()
}

func dedup(_ books: [Book]) -> [Book] {
    var seen = Set<Book>()
    return books.filter { seen.insert($0).inserted }
}

func findBook(_ target: Book, in shelf: [Book]) -> Int? {
    shelf.firstIndex(of: target)
}

// ═══ 9.3 协议作为类型：多态不靠继承
func banner(of drawable: some Drawable) -> String {
    "──────\n\(drawable.drawTwice())\n──────"
}

// ═══ 9.4 演示输出
let circles = [Circle(radius: 1), Circle(radius: 2)]
let squares = [Square(side: 3), Square(side: 4)]
let mixed: [any Drawable] = [Circle(radius: 5), Square(side: 6)]

print("some 同构列表：\(render(circles))")
print("some 方块列表（默认实现）：\(render(squares))")
print("any 异构列表：\(renderAny(mixed))")
print(banner(of: Circle(radius: 9)))

precondition(render(circles) == ["◯ 半径 1.0", "◯ 半径 2.0"])
precondition(render(squares) == ["【方】用默认画笔绘制", "【方】用默认画笔绘制"])

// ═══ 9.5 标准库协议实战
let shelf = [
    Book(title: "C 程序设计语言", year: 1978), Book(title: "Swift 进阶", year: 2024),
    Book(title: "C 程序设计语言", year: 1978),
]
print("按年排序：\(sortedByYear(shelf).map(\.description))")
print("去重后 \(dedup(shelf).count) 本（原来 \(shelf.count) 本）")
if let index = findBook(Book(title: "Swift 进阶", year: 2024), in: shelf) {
    print("《Swift 进阶》在第 \(index + 1) 位")
}
precondition(dedup(shelf).count == 2)
precondition(findBook(Book(title: "无此书", year: 0), in: shelf) == nil)

print("==== 09 结束 ====")
