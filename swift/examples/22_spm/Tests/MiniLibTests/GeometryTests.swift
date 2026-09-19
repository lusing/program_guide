// MiniLib 的 swift-testing 测试：库的测试与库同住一个包
import Testing

@testable import MiniLib

@Test func 面积与周长() {
    let rect = Rect(width: 3, height: 4)
    #expect(rect.area == 12)
    #expect(rect.perimeter == 14)
    #expect(!rect.isSquare)
    #expect(Rect(width: 5, height: 5).isSquare)
}

@Test func 负尺寸抛错() {
    #expect(throws: GeometryError.negativeDimension(name: "width")) {
        try makeRect(width: -1, height: 1)
    }
    #expect(throws: GeometryError.negativeDimension(name: "height")) {
        try makeRect(width: 1, height: -2)
    }
}

@Test(arguments: [
    (Rect(width: 1, height: 1), 1.0),
    (Rect(width: 2, height: 3), 6.0),
    (Rect(width: 10, height: 10), 100.0),
])
func 合计面积(rect: Rect, expected: Double) {
    #expect(totalArea([rect]) == expected)
}
