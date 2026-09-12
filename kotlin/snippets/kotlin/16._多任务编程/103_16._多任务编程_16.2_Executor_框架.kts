import java.util.concurrent.*

// 创建线程池
val executor = Executors.newFixedThreadPool(4)
val cachedExecutor = Executors.newCachedThreadPool()

// 提交任务
val future: Future<Int> = executor.submit {
    Thread.sleep(1000)
    42
}

// 批量执行
val tasks = listOf(
    Callable { "Task 1" },
    Callable { "Task 2" }
)
val results: List<Future<String>> = executor.invokeAll(tasks)

// 关闭线程池
executor.shutdown()
executor.awaitTermination(5, TimeUnit.SECONDS)
