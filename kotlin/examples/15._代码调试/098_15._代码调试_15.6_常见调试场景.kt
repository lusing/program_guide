import kotlinx.coroutines.*

// 全局异常处理器
val handler = CoroutineExceptionHandler { context, exception ->
    println("GlobalExceptionHandler: $exception")
    println("Context: $context")
}

fun main() = runBlocking {
    // 方式1: 使用 CoroutineExceptionHandler
    val job = launch(handler) {
        throw RuntimeException("Test exception")
    }

    // 方式2: 使用 coroutineScope 捕获
    try {
        coroutineScope {
            launch {
                delay(100)
                throw IllegalStateException("Scope exception")
            }
        }
    } catch (e: Exception) {
        println("Caught in scope: $e")
    }

    // 方式3: 使用 async + await
    val deferred = async(handler) {
        delay(100)
        throw ArithmeticException("Division by zero")
    }

    try {
        deferred.await()
    } catch (e: Exception) {
        println("Async exception: ${e.message}")
    }
}

// 协程调试工具函数
fun <T> safeLaunch(
    scope: CoroutineScope,
    block: suspend () -> T
): Job {
    return scope.launch {
        try {
            block()
        } catch (e: Exception) {
            println("Launch failed: ${e.message}")
            e.printStackTrace()
        }
    }
}
