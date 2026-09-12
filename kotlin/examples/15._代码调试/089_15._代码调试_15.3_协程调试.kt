import kotlinx.coroutines.*
import kotlin.coroutines.*

// 启用协程调试
fun main() {
    System.setProperty("kotlinx.coroutines.debug", "on")

    runBlocking {
        launch {
            delay(1000)
            println("Job 1 done")
        }

        launch {
            delay(2000)
            println("Job 2 done")
        }
    }
}

// 自定义 CoroutineContext
val debugContext = SupervisorJob() + Dispatchers.Default +
    CoroutineName("MainDispatcher")

suspend fun debugScope() = coroutineScope {
    launch(debugContext + CoroutineName("worker-1")) {
        delay(1000)
        println("Worker 1 completed")
    }
}

// 获取协程信息
fun showCoroutineInfo() {
    val job = Job()
    val scope = CoroutineScope(debugContext + job)

    println("Job: $job")
    println("Context: ${scope.coroutineContext}")
}
