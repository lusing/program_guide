// 16 的测试：异常层级、Result 链、require/check、Nothing、use
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull
import kotlin.test.assertTrue

fun testExceptions() {
    val s = Store1()
    assertEquals(1, s.get("a"))
    val e = assertFailsWith<AppError.NotFound> { s.get("zzz") }   // 精确子类
    assertEquals("找不到: zzz", e.message)
    // sealed 根：catch (e: AppError) 一个分支就能覆盖全部子类（Main 里演示）
}

fun testRequireCheck() {
    assertEquals("kot", shrink("kotlin", 3))
    assertFailsWith<IllegalArgumentException> { shrink("kt", -1) }
    assertFailsWith<IllegalStateException> { shrink("kt", 5) }
}

fun testResultChain() {
    val ok = runCatching { "42".toInt() }
    val bad = runCatching { "x".toInt() }
    assertEquals(42, ok.getOrNull())
    assertNull(bad.getOrNull())
    assertEquals(84, ok.map { it * 2 }.getOrNull())
    assertEquals(-1, bad.getOrElse { -1 })
    assertEquals(800, runCatching { "8" }.mapCatching { it.toInt() }.mapCatching { it * 100 }.getOrDefault(-1))
    assertEquals(-1, runCatching { "8x" }.mapCatching { it.toInt() }.getOrDefault(-1))
}

fun testStore2() {
    val s = Store2()
    assertEquals(1, s.get("a").getOrDefault(-1))
    assertTrue(s.get("zz").isFailure)
    val msg = s.get("zz").exceptionOrNull()?.message
    assertEquals("找不到: zz", msg)
}

fun testNothing() {
    assertEquals(0, fallback)
    assertEquals(1, listOf(1).firstOrNull() ?: boom())
}

fun testUse() {
    var closed = false
    class Res : AutoCloseable { override fun close() { closed = true } }
    Res().use { assertEquals(true, !closed) }    // use 里还没关
    assertTrue(closed)                            // use 返回后必关
}

fun main() {
    testExceptions()
    testRequireCheck()
    testResultChain()
    testStore2()
    testNothing()
    testUse()
    println("16_errors 全部测试通过")
}
