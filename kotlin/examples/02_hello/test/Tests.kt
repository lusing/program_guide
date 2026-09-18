// 02 的测试：kotlin.test 断言 + 极简 main 入口（无 JUnit runner）
// 真实工程里用 JUnit5 跑 @Test —— 见 17_gradle 与 docs/20-testing.md
import kotlin.test.assertEquals

fun testGreet() {
    assertEquals("你好, Kotlin!", greet("Kotlin"))
    assertEquals("你好, 世界!", greet("世界"))
}

fun testRepeatGreet() {
    assertEquals("哈哈哈", repeatGreet("哈", 3))
    assertEquals("", repeatGreet("哈", 0))
}

fun testRenderArgs() {
    val out = renderArgs(arrayOf("add", "42"))
    // 注意：Kotlin 的 appendLine 追加 '\n'，不是平台的 lineSeparator——测试期望也要用 '\n'
    assertEquals("参数个数: 2\n参数[0]: add\n参数[1]: 42\n", out)
    assertEquals(0, renderArgs(emptyArray()).lines().first().filter { it.isDigit() }.toInt())
}

fun main() {
    testGreet()
    testRepeatGreet()
    testRenderArgs()
    println("02_hello 全部测试通过")
}
