// 06 的测试：属性、校验、data class 语义、运算符
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertTrue

fun testRect() {
    assertEquals(12.0, Rect(3.0, 4.0).area)
    assertTrue(Rect(5.0, 5.0).isSquare)
    assertFalse(Rect(1.0, 2.0).isSquare)
}

fun testPriceClamp() {
    val p = Price(200)
    p.discount = 3.0
    assertEquals(1.0, p.discount)
    assertEquals(0.0, p.finalPrice)
    p.currency = "jpy"
    assertEquals("JPY", p.currency)
}

fun testPriceValidation() {
    assertFailsWith<IllegalArgumentException> { Price(-1) }
}

fun testSecondaryCtor() {
    assertEquals("未分配", Employee("张三").dept)
    assertEquals("研发", Employee("李四", "研发").dept)
}

fun testDataClass() {
    val a = Point(1, 2)
    val b = Point(1, 2)
    assertTrue(a == b)
    assertEquals(a.hashCode(), b.hashCode())
    assertEquals(Point(1, 99), a.copy(y = 99))
    assertEquals(a, a.copy())          // copy 无参 = 等值新实例
    val (x, y) = a
    assertEquals(1, x); assertEquals(2, y)
    assertEquals("Point(x=1, y=2)", a.toString())
}

fun testOperators() {
    val v = Vec2(1.0, 2.0) + Vec2(3.0, 4.0)
    assertEquals(Vec2(4.0, 6.0), v)
    assertEquals(Vec2(2.0, 4.0), Vec2(1.0, 2.0) * 2.0)
    assertEquals(Vec2(-1.0, -2.0), -Vec2(1.0, 2.0))
    assertEquals(4.0, v[0]); assertEquals(6.0, v[1])
    assertFailsWith<IndexOutOfBoundsException> { v[2] }
}

fun main() {
    testRect()
    testPriceClamp()
    testPriceValidation()
    testSecondaryCtor()
    testDataClass()
    testOperators()
    println("06_classes 全部测试通过")
}
