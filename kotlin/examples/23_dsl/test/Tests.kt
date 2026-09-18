// 23 的测试：builder 产物、DslMarker、中缀断言、invoke
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

fun testHtmlBuilder() {
    val page = html {
        attr("lang", "zh")
        body {
            h1 { text = "标题" }
            div {
                p { text = "段落" }
            }
        }
    }
    assertEquals(
        """<html lang="zh"><body><h1>标题</h1><div><p>段落</p></div></body></html>""",
        page.render(),
    )
}

fun testEmptyTag() {
    val page = html { body { div { } } }
    assertEquals("<html><body><div/></body></html>", page.render())
}

fun testInfixAssert() {
    42 should 42
    40 eq 40
    assertFailsWith<IllegalStateException> { 1 eq 2 }
    val e = assertFailsWith<IllegalStateException> { "a" should "b" }
    assertTrue("断言失败" in (e.message ?: ""))
}

fun testInvoke() {
    val r = Router()
    assertEquals("已注册 /a（累计 1 条）", r("/a"))
    assertEquals("已注册 /b（累计 2 条）", r("/b"))
}

fun testDeps() {
    val deps = dependencies {
        implementation("kotlinx-coroutines")
        testImplementation("kotlin-test")
    }
    assertEquals(listOf("implementation: kotlinx-coroutines", "test: kotlin-test"), deps)
}

fun main() {
    testHtmlBuilder()
    testEmptyTag()
    testInfixAssert()
    testInvoke()
    testDeps()
    println("23_dsl 全部测试通过")
}
