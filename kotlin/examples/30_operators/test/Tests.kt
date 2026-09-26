// 30 的测试：复数运算、BigDecimal 陷阱、约定五连、rem/mod
import java.math.BigDecimal
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

fun testComplex() {
    val z1 = Complex(1.0, 2.0); val z2 = Complex(3.0, 4.0)
    assertEquals(Complex(4.0, 6.0), z1 + z2)
    assertEquals(Complex(-2.0, -2.0), z1 - z2)
    assertEquals(Complex(-5.0, 10.0), z1 * z2)
    assertEquals(Complex(-1.0, -2.0), -z1)
    assertEquals(5.0, z2.modulus)
    assertTrue(z1 + z2 - z2 == z1)
}

fun testBigDecimal() {
    assertEquals("0.3", (BigDecimal("0.1") + BigDecimal("0.2")).toString())
    val x = BigDecimal("2.0"); val y = BigDecimal("2.00")
    assertFalse(x == y)                    // equals 含 scale
    assertEquals(0, x.compareTo(y))        // 数值相等
    assertFalse(x < y); assertFalse(x > y)
}

fun testConventions() {
    val m = Matrix2(doubleArrayOf(1.0, 2.0, 3.0, 4.0))
    assertEquals(2.0, m[0, 1])
    m[1, 1] = 40.0
    assertEquals(40.0, m[1, 1])
    assertTrue(2.0 in m); assertFalse(99.0 in m)
    assertEquals("你好, Kotlin!", Greeter("你好")("Kotlin"))
    val collected = mutableListOf<Int>()
    for (i in Countdown(3)) collected.add(i)
    assertEquals(listOf(3, 2, 1), collected)
}

fun testRemMod() {
    assertEquals(-3, -7 % 4)
    assertEquals(1, (-7).mod(4))
    assertEquals(3, 7 % -4)
    assertEquals(-1, 7.mod(-4))
    assertEquals(0.5, (-7.5).mod(2.0))
}

fun main() {
    testComplex()
    testBigDecimal()
    testConventions()
    testRemMod()
    println("30_operators 全部测试通过")
}
