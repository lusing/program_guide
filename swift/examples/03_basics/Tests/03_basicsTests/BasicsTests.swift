// 03_basics 的 swift-testing 测试
import Testing

@testable import Ch03Basics

@Test func clamp夹取() {
    #expect(clamp(3.7, low: 0, high: 1) == 1.0)
    #expect(clamp(-0.5, low: 0, high: 1) == 0.0)
    #expect(clamp(0.42, low: 0, high: 1) == 0.42)
}

@Test func minMax正常与空数组() {
    #expect(minMax(of: [3, 1, 4, 1, 5, 9, 2, 6])?.min == 1)
    #expect(minMax(of: [3, 1, 4, 1, 5, 9, 2, 6])?.max == 9)
    #expect(minMax(of: [42])! == (min: 42, max: 42))
    #expect(minMax(of: []) == nil)
}

@Test func hexByte两位大写() {
    #expect(hexByte(0) == "00")
    #expect(hexByte(10) == "0A")
    #expect(hexByte(255) == "FF")
}

@Test func 回绕运算() {
    #expect(UInt8.max &+ 1 == 0)
    #expect(UInt8.max &- UInt8.max == 0)
    let zero: Int = 0
    #expect(zero &- 1 == -1)  // Int 宽度充足，0 &- 1 正常得 -1
}

@Test func 字面量等值() {
    #expect(0b1010 == 10)
    #expect(0o17 == 15)
    #expect(0xFF == 255)
    #expect(1_000_000 == 1_000_000)
    #expect(1.25e3 == 1250.0)
}
