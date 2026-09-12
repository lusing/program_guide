// 调试协程延迟
suspend fun processWithDelays() {
    println("Step 1 started")
    delay(100)
    println("Step 1 completed")

    println("Step 2 started")
    delay(200)
    println("Step 2 completed")
}

// 使用 suspendCoroutine 捕获调用栈
import kotlin.coroutines.resume

fun <T> debugSuspend(block: suspend () -> T): suspend () -> T {
    return {
        println("Starting debug for: ${Thread.currentThread().stackTrace.size} frames")
        block()
    }
}

// 协程状态监控
class DebuggableScope : CoroutineScope {
    override val coroutineContext = SupervisorJob() + Dispatchers.Default

    fun <T> launchDebug(
        block: suspend CoroutineScope.() -> T
    ): Job {
        return launch {
            println("[COROUTINE] Started")
            try {
                val result = block()
                println("[COROUTINE] Completed with: $result")
            } catch (e: Exception) {
                println("[COROUTINE] Failed: ${e.message}")
                e.printStackTrace()
            }
        }
    }
}
