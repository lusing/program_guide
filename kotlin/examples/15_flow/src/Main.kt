// 15 · 协程进阶：Channel、Flow、SharedFlow、Mutex 与原子性
import kotlinx.coroutines.*
import kotlinx.coroutines.channels.*
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

/** Channel：协程间的"管道"。默认容量 0 = 会合点（发送方等接收方到场） */
suspend fun channelDemo(): List<String> = coroutineScope {
    val log = mutableListOf<String>()
    val ch = Channel<Int>()                        // capacity = 0：每次 send/receive 会合
    launch {                                       // 生产者
        for (i in 1..3) {
            ch.send(i)                             // 没人接收就挂起
            log += "send $i"
        }
        ch.close()                                 // 关闭管道——消费端的 for 会正常结束
    }
    for (x in ch) log += "recv $x"                // 挂起直到有值；close 后循环结束
    log
}

/** trySend/tryReceive：非阻塞版，不成功不挂起 */
suspend fun tryChannel(): String {
    val ch = Channel<Int>(capacity = 1)
    val r1 = ch.trySend(7)                        // 成功（有空位）
    val r2 = ch.trySend(8)                        // 失败（缓冲满）
    val got = ch.tryReceive()
    val empty = ch.tryReceive()
    return "trySend: $r1, $r2; tryReceive: $got / $empty"
}

/** Flow：冷流——每次 collect 都重新执行上游代码 */
fun ticker(): Flow<Int> = flow {
    println("  [flow] 上游开始执行")
    for (i in 1..3) {
        delay(1)
        emit(i)
    }
}

/** 操作符链：和集合管道一个手感，但每个元素流过整条管道 */
fun pipeline(src: Flow<Int>): Flow<String> =
    src.map { it * 10 }
        .filter { it >= 20 }
        .transform { emit("$it!"); if (it == 30) emit("三十!") }
        .take(3)

/** 异常处理：catch 操作符只捕上游，onCompletion 是 finally */
fun failingFlow(): Flow<Int> = (1..3).asFlow().onEach { if (it == 3) throw IllegalStateException("坏在第 $it 个") }

/** SharedFlow：热的多播——订阅者各自独立，晚来的只收新值（replay=0） */
suspend fun sharedDemo(): String = coroutineScope {
    val shared = MutableSharedFlow<Int>(replay = 0)
    val a = mutableListOf<String>()
    val b = mutableListOf<String>()
    val ja = launch { shared.collect { a += "A$it" } }   // 订阅者 A
    val jb = launch { shared.collect { b += "B$it" } }   // 订阅者 B
    delay(1)                                             // 让两个订阅先就位（到达第一个挂起点）
    shared.emit(1); shared.emit(2)                       // emit 等所有订阅者收完才返回
    ja.cancel(); jb.cancel()                             // collect 是无限的，取消收尾
    ja.join(); jb.join()
    "A收到: ${a.joinToString()} | B收到: ${b.joinToString()}"
}

/** 单线程模拟竞态：yield() 强制在"读-改-写"中间让出 → 丢失更新必然发生且数值确定 */
suspend fun simulatedRace(): Int = coroutineScope {
    var c = 0
    val jobs = (1..2).map {
        launch {
            repeat(100) {
                val t = c            // 读
                yield()              // ← 模拟线程切换恰好插在中间
                c = t + 1            // 写：覆盖了对方的结果
            }
        }
    }
    jobs.joinAll()                   // 确定性等待全部完成（不靠猜时间）
    c
}

/** Mutex：协程版互斥锁——withLock 保证读改写原子（即便中间让出） */
suspend fun mutexFix(): Int = coroutineScope {
    val mutex = Mutex()
    var c = 0
    val jobs = (1..2).map {
        launch {
            repeat(100) {
                mutex.withLock {
                    val t = c
                    yield()          // 持锁让出也不丢更新——别人进不来
                    c = t + 1
                }
            }
        }
    }
    jobs.joinAll()
    c
}

fun main() = runBlocking {
    println("== 15.2 Channel ==")
    for (l in channelDemo()) println("  $l")
    println("  ${tryChannel()}")

    println("== 15.3 Flow：冷流证据 ==")
    println("第一次 collect:")
    ticker().take(2).collect { println("  收到 $it") }
    println("第二次 collect（上游代码重新跑了一遍）:")
    ticker().take(1).collect { println("  收到 $it") }

    println("== 15.4 操作符管道 ==")
    pipeline((1..3).asFlow()).collect { println("  $it") }

    println("== 15.5 异常与完成 ==")
    val caught = failingFlow()
        .catch { e -> emit(-1) }              // 替换为哨兵值继续
        .toList()
    println("  catch 后: $caught")
    val done = mutableListOf<String?>()
    failingFlow().onEach { done += "值$it" }
        .catch { done += "捕:${it.message}" }
        .onCompletion { done += "完成(cause=${it?.message})" }
        .collect { }
    println("  onCompletion: $done")

    println("== 15.6 SharedFlow 多播 ==")
    println("  ${sharedDemo()}")

    println("== 15.7 竞态与 Mutex ==")
    val r1 = simulatedRace()
    println("  无锁（单线程模拟切换）: c = $r1   ← 200 次自增丢了 ${200 - r1} 次，更新被覆盖")
    val r2 = mutexFix()
    println("  Mutex 保护后: c = $r2")
}
