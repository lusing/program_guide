// 14 · 协程基础：suspend、runBlocking、launch/async、结构化并发、取消、超时
// 确定性说明：runBlocking 的子协程默认在当前线程的事件循环上按挂起点交错——顺序确定
import kotlinx.coroutines.*

/** 挂起函数：挂起点让出线程，恢复后继续——"能暂停的函数" */
suspend fun work(name: String, steps: Int): String = buildString {
    for (i in 1..steps) {
        delay(1)                       // 非阻塞等待（Thread.sleep 是阻塞整个线程）
        append("$name$i ")
    }
}

/** 串行调用：挂起点之间单线程交替，顺序确定 */
suspend fun sequential(): List<String> {
    val a = work("A", 2)
    val b = work("B", 2)
    return listOf(a.trim(), b.trim())
}

/** async 并行：两个任务同时挂起等待，总时长 ≈ max 而不是 sum */
suspend fun parallelSum(): Pair<Long, Long> = coroutineScope {
    val x = async { delay(60); 21L }   // "耗时" 60ms
    val y = async { delay(40); 21L }   // "耗时" 40ms
    x.await() to y.await()
}

/** 结构化并发：父作用域取消 → 子协程全部停止 */
suspend fun structuredCancel(): List<String> = coroutineScope {
    val log = mutableListOf<String>()
    val parent = launch {
        val child = launch {
            try {
                log += "子协程启动"
                delay(10_000)          // "长活"
                log += "子协程干完了（不该看到）"
            } finally {
                log += "子协程清理（finally 保证执行）"
            }
        }
        delay(5)
        child.cancel()                 // 主动取消孩子
        child.join()
        log += "父协程收尾"
    }
    parent.join()
    log
}

/** 协程抛异常 → 同一作用域的其他协程一起完蛋（结构化） */
suspend fun failurePropagates(): String = try {
    coroutineScope {
        launch { delay(100); }         // 没机会跑完
        launch { delay(10); throw IllegalStateException("炸了") }
    }
    "没炸"
} catch (e: IllegalStateException) {
    "捕获: ${e.message}（整个作用域被取消）"
}

fun main() = runBlocking {             // 桥接：阻塞主线程直到协程树结束
    println("== 14.2 第一个协程：launch 与 join ==")
    val job = launch {
        println("  协程体运行在线程 ${Thread.currentThread().name}")
        delay(1)
        println("  delay 之后继续")
    }
    println("launch 立刻返回（协程体还没跑）")
    job.join()                         // 等它完成
    println("join 之后")

    println("== 14.3 挂起函数与串行 ==")
    for (line in sequential()) println("  $line")

    println("== 14.4 async/await 并行 ==")
    val (x, y) = parallelSum()
    println("  并行结果: $x + $y = ${x + y}（总耗时≈60ms 而非 100ms）")

    println("== 14.5 结构化并发与取消 ==")
    for (line in structuredCancel()) println("  $line")

    println("== 14.6 异常传播 ==")
    println("  ${failurePropagates()}")

    println("== 14.7 超时 ==")
    val fast = withTimeoutOrNull(50) { delay(5); "快任务完成" }
    val slow = withTimeoutOrNull(10) { delay(60); "慢任务完成" }
    println("  快: $fast")
    println("  慢: $slow（超时返回 null）")

    println("== 14.8 作用域构建器选型 ==")
    println("  runBlocking=测试/桥接阻塞世界 | coroutineScope=并行分解等全部 | supervisorScope=孩子互不影响(15章)")
    println("  GlobalScope=逃生舱，基本别用（脱离结构化并发，泄漏无感知）")

    println("== 14.9 协程 vs 线程 ==")
    var done = 0
    val jobs = (1..1000).map { i ->
        launch { delay(1); done++ }     // 1000 个协程轻松起
    }
    jobs.joinAll()
    println("  1000 个协程全部完成: done=$done（1000 个线程会先耗尽内存）")
}
