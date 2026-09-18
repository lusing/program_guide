// 07 的测试：继承、接口、智能转换、嵌套/内部类
import kotlin.test.assertEquals
import kotlin.test.assertTrue

fun testInheritance() {
    val c: Shape = Circle(1.0)
    assertEquals(Math.PI, c.area, 1e-9)
    assertTrue(Rect2(3.0, 4.0).describe().startsWith("矩形"))
    assertEquals(12.0, Rect2(3.0, 4.0).area)
}

fun testAbstract() {
    val st = MemoryStorage()
    st.save("a", "1"); st.save("b", "2")
    assertEquals(mapOf("a" to "1", "b" to "2"), st.data)
}

fun testInterfaces() {
    val sq = Square2(2.0, "方块")
    assertEquals("[方块]", (sq as Named).label())
    assertEquals(4.0, sq.area)
}

fun testSmartCast() {
    assertTrue(render(Circle(1.0)).startsWith("圆，半径 1.0"))
    assertTrue(render(Rect2(3.0, 4.0)).contains("宽 3.0"))
}

fun testNestedInner() {
    assertEquals("Nested(信息)", Outer.Nested("信息").show())
    assertEquals("Inner(属于 X)", Outer("X").Inner().show())
}

fun testVisibility() {
    val c = Counter2()
    c.bump()
    assertEquals("hits = 1", c.report())
}

fun main() {
    testInheritance()
    testAbstract()
    testInterfaces()
    testSmartCast()
    testNestedInner()
    testVisibility()
    println("07_inheritance 全部测试通过")
}
