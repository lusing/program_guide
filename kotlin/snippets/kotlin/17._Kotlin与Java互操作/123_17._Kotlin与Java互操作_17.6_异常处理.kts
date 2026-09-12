// Kotlin 调用 - 可以不处理异常
val content = readFile("/path/to/file")

// 或显式处理
try {
    val content = readFile("/path/to/file")
} catch (e: IOException) {
    println("Error: ${e.message}")
}
