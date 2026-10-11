// 25 · 位运算、溢出与运算符重载——按位取反/与/或/异或/移位、& 溢出家族、
//    自定义运算符函数（+、-、+=、==、<）、自定义中置运算符（优先级 + 结合性）

import Foundation

// ═══ 25.1 按位取反 ~：0 变 1，1 变 0（前置，操作数之间不要加空格）
let initialBits: UInt8 = 0b0000_1111  // 十进制 15
let invertedBits = ~initialBits       // 0b1111_0000 = 240
print("~0b00001111 = 0b\(String(invertedBits, radix: 2)) = \(invertedBits)")
precondition(invertedBits == 0b1111_0000)

// ═══ 25.2 按位与 &：两位都是 1 才得 1（掩码提取：清掉指定位之外的位）
let firstSixBits: UInt8 = 0b1111_1100
let lastSixBits: UInt8 = 0b0011_1111
let middleFourBits = firstSixBits & lastSixBits  // 0b0011_1100 = 60
print("0b11111100 & 0b00111111 = 0b\(String(middleFourBits, radix: 2)) = \(middleFourBits)")
precondition(middleFourBits == 0b0011_1100)

// ═══ 25.3 按位或 |：任一位是 1 就得 1（合并标志位）
let someBits: UInt8 = 0b1011_0010
let moreBits: UInt8 = 0b0101_1110
let combinedBits = someBits | moreBits  // 0b1111_1110 = 254
print("0b10110010 | 0b01011110 = 0b\(String(combinedBits, radix: 2)) = \(combinedBits)")
precondition(combinedBits == 0b1111_1110)

// ═══ 25.4 按位异或 ^：两位不同得 1，相同得 0（无进位加法 / 翻转指定位）
let firstBits: UInt8 = 0b0001_0100
let otherBits: UInt8 = 0b0000_0101
let outputBits = firstBits ^ otherBits  // 0b0001_0001 = 17
print("0b00010100 ^ 0b00000101 = 0b\(String(outputBits, radix: 2)) = \(outputBits)")
precondition(outputBits == 0b0001_0001)

// 异或的实用性质：a ^ b ^ b == a（同一个值异或两次还原）——简易"加密"
func xorCipher(_ data: [UInt8], key: UInt8) -> [UInt8] {
    data.map { $0 ^ key }
}
let secret: [UInt8] = [0x48, 0x65, 0x6C, 0x6C, 0x6F]  // "Hello"
let ciphered = xorCipher(secret, key: 0x5A)
let recovered = xorCipher(ciphered, key: 0x5A)
print("异或两次还原：\(recovered == secret)")
precondition(recovered == secret)

// ═══ 25.5 移位 << >>：左移乘 2，右移除 2；无符号数空位补 0（逻辑移位）
let shiftBits: UInt8 = 4  // 0b0000_0100
print("4 << 1 = \(shiftBits << 1)（×2）  4 << 2 = \(shiftBits << 2)（×4）")
print("4 >> 2 = \(shiftBits >> 2)（÷4）  1 << 7 = \(UInt8(1) << 7)（= 128）")
precondition((shiftBits << 1) == 8 && (shiftBits << 2) == 16 && (shiftBits >> 2) == 1)

// 经典用法：从打包的颜色值里拆 RGB 分量（掩码 + 移位）
let pink: UInt32 = 0xCC6699
let redComponent = (pink & 0xFF_0000) >> 16   // 0xCC = 204
let greenComponent = (pink & 0x00_FF00) >> 8  // 0x66 = 102
let blueComponent = pink & 0x00_00FF          // 0x99 = 153
print("0xCC6699 → R=\(redComponent) G=\(greenComponent) B=\(blueComponent)")
precondition(redComponent == 0xCC && greenComponent == 0x66 && blueComponent == 0x99)

// 有符号数右移：空位按符号位填充（算术移位），负数右移保持符号
let negative: Int8 = -4           // 0b1111_1100（补码）
let shiftedNegative = negative >> 1  // 0b1111_1110 = -2
print("-4 >> 1 = \(shiftedNegative)（仍是负数，向 0 靠近）")
precondition(shiftedNegative == -2)

// ═══ 25.6 溢出运算符 &+ &- &* &/ &%：默认溢出会 trap，& 家族显式回绕
// var tooBig: UInt8 = UInt8.max + 1   // ❌ 编译期报错
// var trap: UInt8 = 250; trap += 10   // ❌ 运行期 trap
var willOverflow = UInt8.max
willOverflow = willOverflow &+ 1  // 上溢出：255 + 1 → 0
print("UInt8.max &+ 1 = \(willOverflow)")
precondition(willOverflow == 0)

var willUnderflow = UInt8.min
willUnderflow = willUnderflow &- 1  // 下溢出：0 - 1 → 255
print("UInt8.min &- 1 = \(willUnderflow)")
precondition(willUnderflow == 255)

var signedUnderflow = Int8.min
signedUnderflow = signedUnderflow &- 1  // -128 - 1 → 127（符号位翻转）
print("Int8.min &- 1 = \(signedUnderflow)")
precondition(signedUnderflow == 127)

// 注意：&/ 与 &% 在 Swift 3 已移除（SE-0007）——除零没有"安全版本"，
// 需要容错就用可选绑定或 12 章错误处理，别指望运算符兜底。

// ═══ 25.7 优先级与结合性：为什么 2 + 3 * 4 % 5 == 4
// * 与 % 同优先级、左结合，高于 +：
//   2 + ((3 * 4) % 5) = 2 + (12 % 5) = 2 + 2 = 4
let precedenceDemo = 2 + 3 * 4 % 5
print("2 + 3 * 4 % 5 = \(precedenceDemo)")
precondition(precedenceDemo == 4)

// ═══ 25.8 运算符函数：让自定义类型支持内置运算符（全局 static func）
struct Vector2D: Equatable, CustomStringConvertible {
    var x = 0.0
    var y = 0.0

    var description: String { "(\(x), \(y))" }

    // 中置二元运算符 +：两个向量对应分量相加
    static func + (left: Vector2D, right: Vector2D) -> Vector2D {
        Vector2D(x: left.x + right.x, y: left.y + right.y)
    }

    // 前置一元运算符 -：两个分量取反
    static prefix func - (vector: Vector2D) -> Vector2D {
        Vector2D(x: -vector.x, y: -vector.y)
    }

    // 组合赋值 +=：左参数必须 inout（原地改）
    static func += (left: inout Vector2D, right: Vector2D) {
        left = left + right  // 复用已定义的 +
    }

    // 等值 ==：Equatable 要求（!= 由标准库默认实现自动获得）
    static func == (left: Vector2D, right: Vector2D) -> Bool {
        left.x == right.x && left.y == right.y
    }
}

let vector = Vector2D(x: 3.0, y: 1.0)
let anotherVector = Vector2D(x: 2.0, y: 4.0)
let combinedVector = vector + anotherVector
print("\(vector) + \(anotherVector) = \(combinedVector)")
precondition(combinedVector == Vector2D(x: 5.0, y: 5.0))

let positive = Vector2D(x: 3.0, y: 4.0)
let negativeVec = -positive
print("-\(positive) = \(negativeVec)")
precondition(negativeVec == Vector2D(x: -3.0, y: -4.0))

var toIncrement = Vector2D(x: 1.0, y: 2.0)
toIncrement += Vector2D(x: 3.0, y: 4.0)
print("+= 之后 = \(toIncrement)")
precondition(toIncrement == Vector2D(x: 4.0, y: 6.0))

// ═══ 25.9 自定义运算符：operator 声明 + precedencegroup 声明优先级/结合性
// 新运算符只能使用 / = - + * % < > ! & | ^ . ~ 这些字符组合
infix operator +-: AdditionPrecedence  // 复用加法优先级组（左结合）

extension Vector2D {
    static func +- (left: Vector2D, right: Vector2D) -> Vector2D {
        Vector2D(x: left.x + right.x, y: left.y - right.y)
    }
}

let firstVec = Vector2D(x: 1.0, y: 2.0)
let secondVec = Vector2D(x: 3.0, y: 4.0)
let plusMinusResult = firstVec +- secondVec  // (4.0, -2.0)
print("\(firstVec) +- \(secondVec) = \(plusMinusResult)")
precondition(plusMinusResult == Vector2D(x: 4.0, y: -2.0))

// 自定义 precedencegroup：右结合、指定优先级数值（高于乘法 150）
precedencegroup RightMultiplyPrecedence {
    higherThan: MultiplicationPrecedence
    associativity: right
}
infix operator **: RightMultiplyPrecedence

extension Vector2D {
    static func ** (left: Vector2D, right: Vector2D) -> Vector2D {
        Vector2D(x: left.x * right.x, y: left.y * right.y)
    }
}

let powResult = Vector2D(x: 2, y: 3) ** Vector2D(x: 5, y: 7)
print("(2,3) ** (5,7) = \(powResult)")
precondition(powResult == Vector2D(x: 10, y: 21))

print("==== 25 结束 ====")
