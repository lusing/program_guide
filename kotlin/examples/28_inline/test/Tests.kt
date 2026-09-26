// 28 的测试：非局部返回、自造控制流、noinline/crossinline、@PublishedApi、inline 属性
import kotlin.test.assertEquals
import kotlin.test.assertTrue

fun testNonLocalReturn() {
    assertEquals(-2, firstNegative(listOf(3, 7, -2, 9)))
    assertEquals(null, firstNegative(listOf(1, 2)))
    assertEquals(null, firstNegative(emptyList()))
}

fun testEachSlowLabelReturn() {
    val visited = mutableListOf<Int>()
    eachSlow(listOf(1, -2, 3)) { v -> if (v >= 0) visited.add(v) }
    assertEquals(listOf(1, 3), visited)   // 标签返回只跳过当轮
}

fun testRepeatUntilError() {
    var cursor = 0
    val data = listOf("a", "b", "c")
    assertEquals(3, repeatUntilError { if (cursor >= data.size) error("EOF") else cursor++ })
    assertEquals(0, repeatUntilError { error("立刻失败") })
}

fun testTryFewTimes() {
    assertEquals(3, tryFewTimes(5) { it >= 3 })
    assertEquals(5, tryFewTimes(5) { false })
    assertEquals(1, tryFewTimes(5) { true })
}

fun testNoinline() {
    val registered = mutableListOf<String>()
    val saved = later({ "延迟" + "求值" }) { registered.add(it) }
    assertEquals(listOf("已注册"), registered)
    assertEquals("延迟求值", saved())
    assertEquals("延迟求值", saved())      // 可反复调用——它是真对象
}

fun testCrossinline() {
    val logs = mutableListOf<String>()
    runAsTask { logs.add("ok") }.run()
    assertEquals(listOf("ok"), logs)
}

fun testPublishedApi() {
    assertEquals("内部实现（@PublishedApi = 承诺当公开对待）", publicInlineApi())
    assertEquals("内部实现（@PublishedApi = 承诺当公开对待）", publicInlineApi { it })
}

fun testInlinePropAndReified() {
    assertEquals("无幕后字段的内联属性", tag)
    assertEquals("List", typeName<List<Int>>())
    assertEquals("String", typeName<String>())
    val e = printExecutionTime { (1..10).sum() }
    assertTrue(e >= 0)
}

fun main() {
    testNonLocalReturn()
    testEachSlowLabelReturn()
    testRepeatUntilError()
    testTryFewTimes()
    testNoinline()
    testCrossinline()
    testPublishedApi()
    testInlinePropAndReified()
    println("28_inline 全部测试通过")
}
