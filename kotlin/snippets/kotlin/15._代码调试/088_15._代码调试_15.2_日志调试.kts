// 使用 print 和 printStackTrace
fun processData() {
    try {
        // ... 代码
    } catch (e: Exception) {
        println("Error in processData: ${e.message}")
        e.printStackTrace()
    }
}

// 分层调试输出
fun debugTree(depth: Int = 0) {
    val indent = "  ".repeat(depth)
    println("${indent}Processing...")

    // 递归调用
    if (depth < 3) {
        debugTree(depth + 1)
    }

    println("${indent}Done")
}
