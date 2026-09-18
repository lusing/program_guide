// 04 的测试：空安全各操作符的行为
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

fun testDisplayName() {
    assertEquals("张三", displayName(User(" 张三 ", "z@ex.io")))
    assertEquals("匿名", displayName(User(null, "z@ex.io")))
    assertEquals("匿名", displayName(User("   ", null)))   // 空串经 ifEmpty { null } 归一为匿名
    assertEquals("匿名", displayName(null))
}

fun testParseAge() {
    assertEquals(18, parseAge("18"))
    assertEquals(33, parseAge(" 33 "))
    assertNull(parseAge("x"))
    assertNull(parseAge(""))
}

fun testSafeCast() {
    assertEquals(6, lengthIfText("kotlin"))
    assertNull(lengthIfText(42))
}

fun testClassifyAge() {
    assertEquals("未成年(12)", classifyAge(12))
    assertEquals("成年(30)", classifyAge(30))
    assertEquals("老年", classifyAge(60))
    assertEquals("年龄缺失", classifyAge(null))
}

fun testBangBang() {
    val u = User(null, null)
    assertFailsWith<NullPointerException> { u.name!! }
}

fun testLateinit() {
    class C { lateinit var v: String; fun ok() = ::v.isInitialized }
    val c = C()
    assertFalse(c.ok())
    assertFailsWith<UninitializedPropertyAccessException> { c.v }
    c.v = "x"
    assertTrue(c.ok())
    assertEquals("x", c.v)
}

fun main() {
    testDisplayName()
    testParseAge()
    testSafeCast()
    testClassifyAge()
    testBangBang()
    testLateinit()
    println("04_nullsafety 全部测试通过")
}
