// 13 的测试：扩展函数、扩展属性、静态解析、可空接收者
import kotlin.test.assertEquals
import kotlin.test.assertNull

fun testStringExts() {
    assertEquals("A.L.B.", "Ada Lovelace Byron".initials())
    assertEquals("A.L.", "Ada Lovelace".initials())
    assertEquals("kotlin-编程-指南", "Kotlin 编程 指南".toSlug())
    assertEquals("kotlin", "  Kotlin  ".toSlug())
}

fun testIntExt() {
    assertEquals("哈哈哈", 3.timesRepeat("哈"))
    assertEquals("", 0.timesRepeat("x"))
}

fun testExtProperties() {
    assertEquals(4, "hey".shoutLen)
    assertEquals(2, listOf(1, 2, 3).secondOrNullExt)
    assertNull(listOf(1).secondOrNullExt)
}

fun testNullableReceiver() {
    assertEquals("—", null.orDash())
    assertEquals("有值", "有值".orDash())
    val s: String? = null
    assertEquals("—", s.orDash())
}

fun testStaticResolution() {
    val a: Animal2 = Dog2()
    assertEquals("[A]", a.tag())          // 声明类型决定扩展
    assertEquals("[D]", Dog2().tag())
    assertEquals("Dog2", a.who())         // 虚方法看运行时类型
}

fun testMemberPriority() {
    assertEquals("成员渲染: t", Doc("t").render())
}

fun testCompanionExt() {
    assertEquals(300, Money.ofYuan(3).cents)
    assertEquals(250, Money.Companion.ofCents(250).cents)
}

fun main() {
    testStringExts()
    testIntExt()
    testExtProperties()
    testNullableReceiver()
    testStaticResolution()
    testMemberPriority()
    testCompanionExt()
    println("13_extensions 全部测试通过")
}
