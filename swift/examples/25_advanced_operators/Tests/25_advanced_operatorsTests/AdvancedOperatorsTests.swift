// 25_advanced_operators 的 swift-testing 测试
import Testing

@testable import Ch25AdvancedOperators

@Test func 按位取反() {
    #expect(~UInt8(0b0000_1111) == 0b1111_0000)
    #expect(~UInt8(0) == UInt8.max)
    #expect(~UInt8.max == 0)
}

@Test func 按位与或异或() {
    #expect((0b1111_1100 as UInt8) & 0b0011_1111 == 0b0011_1100)
    #expect((0b1011_0010 as UInt8) | 0b0101_1110 == 0b1111_1110)
    #expect((0b0001_0100 as UInt8) ^ 0b0000_0101 == 0b0001_0001)
}

@Test func 异或两次还原() {
    let data: [UInt8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F]
    let key: UInt8 = 0x5A
    let once = data.map { $0 ^ key }
    #expect(once != data)
    #expect(once.map { $0 ^ key } == data)
}

@Test func 移位与RGB拆分() {
    #expect((4 as UInt8) << 1 == 8)
    #expect((4 as UInt8) << 2 == 16)
    #expect((4 as UInt8) >> 2 == 1)
    let pink: UInt32 = 0xCC6699
    #expect((pink & 0xFF_0000) >> 16 == 0xCC)
    #expect((pink & 0x00_FF00) >> 8 == 0x66)
    #expect(pink & 0x00_00FF == 0x99)
}

@Test func 有符号算术右移保持符号() {
    #expect((-4 as Int8) >> 1 == -2)
    #expect((-4 as Int8) << 1 == -8)
    #expect((4 as Int8) >> 1 == 2)
}

@Test func 溢出回绕() {
    #expect(UInt8.max &+ 1 == 0)
    #expect(UInt8.min &- 1 == UInt8.max)
    #expect(Int8.min &- 1 == Int8.max)
    #expect(Int8.max &+ 1 == Int8.min)
}

@Test func 优先级结合性() {
    #expect(2 + 3 * 4 % 5 == 4)  // 2 + ((3*4) % 5) = 2 + 2
}

@Test func 向量加减与取反() {
    let a = Vector2D(x: 3, y: 1)
    let b = Vector2D(x: 2, y: 4)
    #expect(a + b == Vector2D(x: 5, y: 5))
    #expect(-a == Vector2D(x: -3, y: -1))
    var c = Vector2D(x: 1, y: 2)
    c += Vector2D(x: 3, y: 4)
    #expect(c == Vector2D(x: 4, y: 6))
}

@Test func 自定义运算符() {
    #expect(Vector2D(x: 1, y: 2) +- Vector2D(x: 3, y: 4) == Vector2D(x: 4, y: -2))
    #expect(Vector2D(x: 2, y: 3) ** Vector2D(x: 5, y: 7) == Vector2D(x: 10, y: 21))
}
