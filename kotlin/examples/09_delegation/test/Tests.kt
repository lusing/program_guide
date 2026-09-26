// 09 的测试：单例、companion、类委托、lazy/observable/自定义委托
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

fun testRegistry() {
    Registry.register("x")
    val before = Registry.snapshot().getValue("x")
    Registry.register("x")
    assertEquals(before + 1, Registry.snapshot().getValue("x"))
}

fun testCompanion() {
    val u = User2.of("张三")
    assertEquals("User2(张三)", u.describe())
    assertFailsWith<IllegalArgumentException> { User2.of("这个名字超过十二个字符真的不行") }
}

fun testClassDelegation() {
    val box = Box(listOf(1, 2, 3, 4, 5))
    assertEquals(5, box.size)
    assertEquals(3, box[2])
    assertEquals(2, box.countWhere { it % 2 == 0 })
    assertEquals(listOf(2, 4), box.filter { it % 2 == 0 })   // 转发来的方法照常可用
}

fun testLazyCached() {
    var computed = 0
    val x: Int by lazy { computed++; 7 }
    assertEquals(0, computed)          // 没访问前不计算
    assertEquals(7, x); assertEquals(1, computed)
    assertEquals(7, x + 0); assertEquals(1, computed)   // 再访问也不重算
}

fun testVetoable() {
    val t = Temperature()
    t.safeRange = 10.0
    assertEquals(10.0, t.safeRange)
    t.safeRange = 100.0
    assertEquals(10.0, t.safeRange)    // 越界被否决
}

fun testCustomDelegate() {
    val f = Form()
    assertEquals("默认标题", f.title)
    f.title = "  A B  "
    assertEquals("A B", f.title)
}

fun testMapDelegate() {
    val c = Conf(mapOf("host" to "h", "port" to 1, "debug" to false))
    assertEquals("h", c.host); assertEquals(1, c.port); assertEquals(false, c.debug)
    // 缺 key 在读值时抛异常
    class C2(val map: Map<String, Any?>) { val missing: String by map }
    assertFailsWith<Exception> { C2(emptyMap()).missing }
    assertTrue(true)
}

fun testNotNullAndObservableEdge() {
    val s = Service()
    assertFailsWith<IllegalStateException> { s.name }     // 读前未赋值
    s.name = "svc"
    assertEquals("svc", s.name)
    val b = Basket()
    b.fruits.add("梨")
    assertEquals(0, b.changes.size)                       // 内部改动不触发
    b.fruits = mutableListOf("苹果", "梨", "西瓜")
    assertEquals(1, b.changes.size)                       // 换引用才触发
    assertEquals("[苹果, 梨] → [苹果, 梨, 西瓜]", b.changes.single())
}

fun main() {
    testRegistry()
    testCompanion()
    testClassDelegation()
    testLazyCached()
    testVetoable()
    testCustomDelegate()
    testMapDelegate()
    testNotNullAndObservableEdge()
    println("09_delegation 全部测试通过")
}
