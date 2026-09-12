// 使用 assertWithMessage
fun testComplicatedCalculation() {
    val result = complexFunction()
    assert(result > 0) { "Result should be positive, but was $result" }
    assert(result < 1000) { "Result should be less than 1000, but was $result" }
}

// 测试异常
fun testException() {
    val exception = assertThrows<IllegalArgumentException> {
        validateAge(-1)
    }
    assertEquals("Age cannot be negative", exception.message)
}

// 使用 tempdir (KotlinTest)
import io.kotest.core.tempdir

class FileTest : FunSpec({
    test("write to temp file") {
        val dir = tempdir()
        val file = dir.resolve("test.txt")
        file.writeText("Hello")
        file.exists() shouldBe true
    }
})

// 本地测试配置
fun main() {
    val config = object : AbstractProjectSpec() {
        override fun isolationMode() = IsolationMode.InstancePerLeaf
    }
    io.kotest.core.config.Configuration.registerProjectConfiguration(config)
}
