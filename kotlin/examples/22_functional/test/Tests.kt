// 22 的测试：惰性、组合、Either 链、依赖注入、不可变更新
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

fun testLaziness() {
    // 惰性的副作用验证：take(1) 只应触发第一个元素的 map
    var mapped = 0
    val r = (1..10).asSequence().onEach { mapped++ }.map { it * 2 }.take(1).toList()
    assertEquals(listOf(2), r)
    assertEquals(1, mapped)                    // 只消费了 1 个元素
}

fun testCompose() {
    val f = compose<Int, Int, String>({ "v=$it" }, { it * 2 })   // (String)->C ∘ (A)->String
    assertEquals("v=84", f(42))
}

fun testCurryPartial() {
    assertEquals(6, curry3(::add3)(1)(2)(3))
    assertEquals(15, partial2(::add2, 10)(5))
}

fun testEither() {
    assertEquals(Either.Right(42), parseAge2("42"))
    assertTrue(parseAge2("x") is Either.Left)
    assertEquals("票: 半价 ¥50", pipeline("70").fold({ "失败: $it" }, { "票: $it" }))
    assertEquals("失败: 未成年: 15", pipeline("15").fold({ "失败: $it" }, { "票: $it" }))
    assertEquals("失败: 'x' 不是数字", pipeline("x").fold({ "失败: $it" }, { "票: $it" }))
    // map 只作用于 Right
    assertEquals(Either.Right(43), parseAge2("42").map { it + 1 })
    assertTrue(parseAge2("q").map { it + 1 } is Either.Left)
}

fun testInjectClock() {
    val clock = FakeClock(0)
    assertFalse(isExpired(0, 1_000, clock))
    clock.advance(1_001)
    assertTrue(isExpired(0, 1_000, clock))
}

fun testImmutableCopy() {
    data class C(val host: String, val port: Int, val debug: Boolean)
    val a = C("h", 80, false)
    val b = a.copy(port = 443)
    assertEquals(C("h", 443, false), b)
    assertEquals(C("h", 80, false), a)          // 原值不动
}

fun main() {
    testLaziness()
    testCompose()
    testCurryPartial()
    testEither()
    testInjectClock()
    testImmutableCopy()
    println("22_functional 全部测试通过")
}
