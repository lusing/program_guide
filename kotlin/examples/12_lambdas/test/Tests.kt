// 12 的测试：函数类型、引用、闭包、接收者 lambda、作用域函数、inline
import kotlin.test.assertEquals
import kotlin.test.assertNull
import kotlin.test.assertTrue

fun testFunctionTypes() {
    assertEquals(25, operate(5, 5) { a, b -> a * b })
    assertEquals(6, operate(9, 3) { a, b -> a - b })
    assertEquals(6, operate(6, 3, ::maxOf))
}

fun testCurryLike() {
    val f = multiplier(7)
    assertEquals(21, f(3))
    assertEquals(70, multiplier(10)(7))
}

fun testClosure() {
    var n = 0
    val inc = { n++; n }
    inc(); inc()
    assertEquals(2, n)
    assertEquals(3, inc())
}

fun testReceiverLambda() {
    assertEquals("[平方] 100", 10.printlned("平方") { (this * this).toString() })
}

fun testMyFilter() {
    assertEquals(listOf(2, 4), myFilter((1..5).toList()) { it % 2 == 0 })
    assertEquals(emptyList(), myFilter(listOf(1)) { false })
    assertTrue(myFilter(listOf("ab", "abc")) { it.length == 3 } == listOf("abc"))
}

fun testNonLocalReturn() {
    fun firstNegative(xs: List<Int>): Int? {
        xs.forEach { if (it < 0) return it }
        return null
    }
    assertEquals(-7, firstNegative(listOf(3, -7, 9)))
    assertNull(firstNegative(listOf(1, 2)))
}

fun testScopeFunctions() {
    val p = Player("Ada", 10).apply { score = 99 }
    assertEquals(99, p.score)
    val name = p.let { it.name }
    assertEquals("Ada", name)
    with(p) { score += 1 }
    assertEquals(100, p.score)
    val same = p.also { }
    assertTrue(same === p)                // also 返回同一实例（引用相等）
}

fun main() {
    testFunctionTypes()
    testCurryLike()
    testClosure()
    testReceiverLambda()
    testMyFilter()
    testNonLocalReturn()
    testScopeFunctions()
    println("12_lambdas 全部测试通过")
}
