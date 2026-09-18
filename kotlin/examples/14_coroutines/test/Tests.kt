// 14 的测试：挂起函数、并行、取消、超时、异常传播
import kotlinx.coroutines.*
import kotlin.test.assertEquals

fun testSequential() = runBlocking {
    assertEquals(listOf("A1 A2", "B1 B2"), sequential())
}

fun testParallelSum() = runBlocking {
    assertEquals(21L to 21L, parallelSum())
}

fun testStructuredCancel() = runBlocking {
    val log = structuredCancel()
    assertEquals(listOf("子协程启动", "子协程清理（finally 保证执行）", "父协程收尾"), log)
}

fun testFailurePropagates() = runBlocking {
    assertEquals("捕获: 炸了（整个作用域被取消）", failurePropagates())
}

fun testTimeout() = runBlocking {
    assertEquals("快任务完成", withTimeoutOrNull(50) { delay(1); "快任务完成" })
    assertEquals(null, withTimeoutOrNull(10) { delay(60); "慢" })
}

fun testManyCoroutines() = runBlocking {
    var done = 0
    (1..10_000).map { launch { done++ } }.joinAll()
    assertEquals(10_000, done)
}

fun testSuspendFromTest() = runBlocking {
    // 挂起函数可以直接在 runBlocking 里测——协程测试的最朴素形态（20 章讲 runTest）
    val r = work("T", 1)
    assertEquals("T1", r.trim())
}

fun main() {
    testSequential()
    testParallelSum()
    testStructuredCancel()
    testFailurePropagates()
    testTimeout()
    testManyCoroutines()
    testSuspendFromTest()
    println("14_coroutines 全部测试通过")
}
