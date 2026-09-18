// 03 的测试：覆盖 describe/sign/sumRange/firstPairSum 与数值转换
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith

fun testDescribe() {
    assertEquals("零", describe(0))
    assertEquals("小", describe(3))
    assertEquals("中", describe(9))
    assertEquals("大", describe(10))
}

fun testSign() {
    assertEquals("正", sign(5))
    assertEquals("负", sign(-5))
    assertEquals("零", sign(0))
}

fun testSumRange() {
    assertEquals(15, sumRange(1, 5))
    assertEquals(0, sumRange(5, 1))       // 空区间：from > to 时一次都不进循环
    assertEquals(7, sumRange(3, 4))
}

fun testFirstPair() {
    assertEquals("(2, 5)", firstPairSum(7))
    assertEquals("(1, 1)", firstPairSum(2))
    assertEquals("无", firstPairSum(100))
}

fun testConversions() {
    // 数值转换必须显式；越界转换按位截断，不是饱和
    assertEquals(100L, 100.toLong())
    assertEquals(-24, 1000.toByte().toInt())          // 0x3E8 → 低 8 位 0xE8 = 补码 -24
    assertEquals(44, 300.toByte().toInt())            // 0x12C → 低 8 位 0x2C = 44
    assertEquals(255, (-1).toByte().toInt() and 0xFF) // 位掩码还原无符号值
    assertFailsWith<NumberFormatException> { "12x".toInt() }
}

fun main() {
    testDescribe()
    testSign()
    testSumRange()
    testFirstPair()
    testConversions()
    println("03_basics 全部测试通过")
}
