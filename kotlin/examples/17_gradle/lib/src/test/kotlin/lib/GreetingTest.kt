package lib

import kotlin.test.Test
import kotlin.test.assertEquals

class GreetingTest {
    @Test
    fun greetingInsertsName() {
        assertEquals("Hello, Kotlin!", greeting("Kotlin"))
    }

    @Test
    fun wordFreqCountsAndSorts() {
        assertEquals(
            listOf("a" to 2, "b" to 1),
            wordFreq("a b a"),
        )
    }
}
