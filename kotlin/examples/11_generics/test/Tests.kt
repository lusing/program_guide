// 11 的测试：型变、约束、reified、擦除
import kotlin.test.assertEquals
import kotlin.test.assertTrue

fun testBox() {
    assertEquals(42, Box(42).get())
    assertEquals("Box(文本)", Box("文本").toString())
}

fun testVariance() {
    val p: Producer<Animal> = CatFarm(Cat())        // out 协变
    assertEquals("喵", p.produce().sound())
    val ac = AnyConsumer()
    val c: Consumer<Cat> = ac                        // in 逆变
    c.consume(Cat())
    assertEquals("喵", ac.last)
}

fun testCovariantList() {
    val animals: List<Animal> = listOf(Cat(), Dog())
    assertEquals(listOf("喵", "汪"), animals.map { it.sound() })
}

fun testWhere() {
    assertEquals("abc", longerOf("abc", "xy"))
    assertEquals("xyz", longerOf("ab", "xyz"))
    assertEquals(maxOf3(1, 9, 4), 9)
}

fun testReified() {
    val mixed: List<Any> = listOf(1, "a", 2, "b", 3.5)
    assertEquals(listOf(1, 2), mixed.pick<Int>())
    assertEquals(listOf("a", "b"), mixed.pick<String>())
    assertTrue(42.isA<Int>())
    assertTrue(!("x".isA<Int>()))
}

fun testErasure() {
    val li: List<Int> = listOf(1)
    val ls: List<String> = listOf("a")
    assertTrue(li::class == ls::class)               // 运行时类型相同
    val anyList: Any = li                            // 先放开静态类型，星投影检查才有信息量
    assertTrue(anyList is List<*>)
    assertTrue(anyList !is Set<*>)
}

fun testVarianceDetails() {
    val c = Refillable(1) { it + 10 }
    val asNumber: Refillable<Number> = c              // out 协变
    assertEquals(1, asNumber.get())
    assertEquals(11, c.advance())
    // 公开 set(v: T) 会编译错（out 违例）——见 Main 注释与文档 11.10
}

fun testErasedOverloads() {
    assertEquals(6, sum(listOf(1, 2, 3)))
    assertEquals("a-b", sum(listOf("a", "b")))
}

fun testReifiedWrapper() {
    assertEquals(42, "42".parseAs<Int>())
    assertEquals("hi", "\"hi\"".parseAs<String>())
    assertEquals(null, "x".parseAs<Long>())
    assertEquals(42L, parseOf("42", Long::class.javaObjectType))
}

fun main() {
    testBox()
    testVariance()
    testCovariantList()
    testWhere()
    testReified()
    testErasure()
    testVarianceDetails()
    testErasedOverloads()
    testReifiedWrapper()
    println("11_generics 全部测试通过")
}
