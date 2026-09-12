import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.*

class CalculatorTest : FunSpec({
    test("addition should work") {
        val result = Calculator().add(2, 3)
        result shouldBe 5
    }

    test("division by zero should throw") {
        intercept<ArithmeticException> {
            Calculator().divide(10, 0)
        }
    }
})

// JUnit 5
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.Assertions.*

class MathTest {
    @Test
    fun testMathOperations() {
        val a = 10
        val b = 5
        assertEquals(15, a + b)
        assertEquals(5, a - b)
        assertEquals(50, a * b)
        assertEquals(2, a / b)
    }

    @Test
    fun `test with description`() {
        val result = calculate()
        assertTrue(result > 0)
        assertNotNull(result)
    }
}
