// 测试覆盖率配置
// Run → Edit Configurations →.coverage

// 测试所有分支
data class Result<out T> {
    data class Success<T>(val data: T) : Result<T>()
    data class Error<T>(val message: String) : Result<T>()
}

fun handleResult(result: Result<String>) = when (result) {
    is Result.Success -> "Success: ${result.data}"
    is Result.Error -> "Error: ${result.message}"
}

// 测试
@Test
fun testSuccessResult() {
    val result = Result.Success("Hello")
    val output = handleResult(result)
    assertEquals("Success: Hello", output)
}

@Test
fun testErrorResult() {
    val result = Result.Error("Something went wrong")
    val output = handleResult(result)
    assertEquals("Error: Something went wrong", output)
}
