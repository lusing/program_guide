import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AppTest {
    @Test
    fun reportContainsGreetings() {
        val r = renderReport(listOf("A", "B"), "a a b")
        assertTrue(r.contains("Hello, A!"))
        assertTrue(r.contains("Hello, B!"))
    }

    @Test
    fun reportEndsWithCallerCount() {
        val r = renderReport(listOf("A", "B", "C"), "x")
        assertTrue(r.trimEnd().endsWith("来自 3 位调用者"))
        assertEquals(3, r.lineSequence().count { it.startsWith("Hello,") })
    }
}
