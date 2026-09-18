// 15 的测试：Channel、冷流、管道、异常处理、竞态与互斥
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.test.assertEquals
import kotlin.test.assertTrue

fun testChannel() = runBlocking {
    // 会合点的恢复顺序：接收方先拿到值继续跑（recv 2 先于 send 2 打印），发送方稍后被恢复
    assertEquals(
        listOf("send 1", "recv 1", "recv 2", "send 2", "send 3", "recv 3"),
        channelDemo(),
    )
}

fun testPipeline() = runBlocking {
    assertEquals(listOf("20!", "30!", "三十!"), pipeline((1..3).asFlow()).toList())
}

fun testColdFlow() = runBlocking {
    var upstreamRuns = 0
    val f = flow { upstreamRuns++; emit(1); emit(2) }
    assertEquals(0, upstreamRuns)                    // 没人 collect 就不执行
    assertEquals(listOf(1, 2), f.toList())
    assertEquals(1, upstreamRuns)
    assertEquals(listOf(1, 2), f.toList())           // 再收集一次：上游再执行一次
    assertEquals(2, upstreamRuns)
}

fun testCatch() = runBlocking {
    assertEquals(listOf(1, 2, -1), failingFlow().catch { emit(-1) }.toList())
}

fun testShared() = runBlocking {
    assertEquals("A收到: A1, A2 | B收到: B1, B2", sharedDemo())
}

fun testRaceAndMutex() = runBlocking {
    val r = simulatedRace()
    assertTrue(r in 100..199, "无锁必丢更新: got $r")  // 单线程切换下的确定区间
    assertEquals(200, mutexFix())
}

fun testMutexNested() = runBlocking {
    // Mutex 是协程级锁：挂起友好；同一协程重复 lock 会挂起（不是可重入锁！）
    val m = Mutex()
    var hit = false
    m.withLock {
        // 此处再 m.withLock 会死锁——教程不演示死锁，只验证正常路径
        hit = true
    }
    assertTrue(hit)
}

fun main() {
    testChannel()
    testPipeline()
    testColdFlow()
    testCatch()
    testShared()
    testRaceAndMutex()
    testMutexNested()
    println("15_flow 全部测试通过")
}
