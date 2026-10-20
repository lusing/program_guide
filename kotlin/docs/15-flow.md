# 15 · Channel 与 Flow ⭐

> 对应示例：`examples/15_flow/`（`src/Main.kt` 演示 + `test/Tests.kt` 断言 + `expected.txt` 输出快照）
>
> Channel、冷 Flow、操作符管道、catch/onCompletion、SharedFlow 热流、
> 竞态与 Mutex——协程之间的"通信"与"数据流"，以及共享状态的正确姿势。

## 15.1 从"并发执行"到"协程间传数据"

第 14 章解决的是"怎么让多段代码并发地跑"（launch/async/结构化并发）。但并发体之间几乎总要**交换数据**：生产者把结果交给消费者，UI 订阅数据源的推送，多个协程累计同一份计数。本章的三件武器各管一段：

- **Channel**：协程间的**管道**，一次一值、一对一（或多对一）传递，偏"通信原语"；
- **Flow**：声明式的**异步数据流**，一条冷流 + 一串操作符 = 一条数据加工管道，偏"数据流编程"；
- **SharedFlow / StateFlow**：热的**多播流**，一个源、多个订阅者，偏"事件总线 / 状态容器"。

最后 15.7 节回到最原始的问题：多个协程改同一个变量——竞态怎么发生、Mutex 怎么修。

## 15.2 Channel：会合点与 trySend

[Channel](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.channels/-channel/index.html) 的概念和阻塞队列类似，但 send/receive 是**挂起**函数而不是阻塞函数。默认容量 0，叫**会合点（rendezvous）**：发送方挂起等接收方到场，一手交一手接：

```kotlin
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
```

输出（顺序被测试固化）：

```text
== 15.2 Channel ==
  send 1
  recv 1
  recv 2
  send 2
  send 3
  recv 3
```

这个交错顺序值得细读：`send 1` 后发送方挂起等接收 → 消费端 `recv 1` → 消费端循环回来取下一个值时把等待中的 `2` 取走（`recv 2`），发送方随后被恢复才打印 `send 2`——测试注释点明了原因："接收方先拿到值继续跑，发送方稍后被恢复"。顺序不是猜的，是会合点 + 单线程事件循环的确定结果：

```kotlin
    assertEquals(
        listOf("send 1", "recv 1", "recv 2", "send 2", "send 3", "recv 3"),
        channelDemo(),
    )
```

两个关键 API：[close](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.channels/-send-channel/close.html) 之后消费端的 `for (x in ch)` 正常结束（不抛异常）——"关闭"是 Channel 的终止信号；[send](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.channels/-send-channel/send.html) 在没人接收时挂起，这就是**背压（backpressure）**：快生产者天然被慢消费者拖住，不会撑爆内存。

不想要"挂起等"的场合，有非阻塞版本 trySend/tryReceive：

```kotlin
/** trySend/tryReceive：非阻塞版，不成功不挂起 */
suspend fun tryChannel(): String {
    val ch = Channel<Int>(capacity = 1)
    val r1 = ch.trySend(7)                        // 成功（有空位）
    val r2 = ch.trySend(8)                        // 失败（缓冲满）
    val got = ch.tryReceive()
    val empty = ch.tryReceive()
    return "trySend: $r1, $r2; tryReceive: $got / $empty"
}
```

输出：

```text
  trySend: Value(kotlin.Unit), Value(Failed); tryReceive: Value(7) / Value(Failed)
```

容量 1 的缓冲：第一个 trySend 进槽成功，第二个撞满直接失败；tryReceive 取走 7 后再取就是空失败。返回值是 `ChannelResult`，成功时 `Value(...)`、失败时 `Failed`——不挂起，成败立刻见分晓。容量还有两种特殊取值：`Channel.CONFLATED`（只留最新值，旧值被覆盖）、`Channel.UNLIMITED`（无限缓冲，小心内存）。

## 15.3 Flow：冷流证据

[Flow](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/-flow/index.html) 是"异步版的 Sequence"：**冷流**——构造一个 Flow 对象什么都不会发生，每次 `collect` 才把上游代码从头跑一遍。示例的 `ticker` 故意在上游放了一行打印当证据：

```kotlin
/** Flow：冷流——每次 collect 都重新执行上游代码 */
fun ticker(): Flow<Int> = flow {
    println("  [flow] 上游开始执行")
    for (i in 1..3) {
        delay(1)
        emit(i)
    }
}
```

main 里对同一个 `ticker()` collect 两次：

```kotlin
    println("== 15.3 Flow：冷流证据 ==")
    println("第一次 collect:")
    ticker().take(2).collect { println("  收到 $it") }
    println("第二次 collect（上游代码重新跑了一遍）:")
    ticker().take(1).collect { println("  收到 $it") }
```

输出：

```text
== 15.3 Flow：冷流证据 ==
第一次 collect:
  [flow] 上游开始执行
  收到 1
  收到 2
第二次 collect（上游代码重新跑了一遍）:
  [flow] 上游开始执行
  收到 1
```

两处证据：**`[flow] 上游开始执行` 出现了两次**——每次 collect 上游都重跑；`take(2)` 拿到两个值后整条流就停了（第三个 emit 没发生）——下游说"够了"，上游就地取消。

测试用计数器把"冷"钉得更死：

```kotlin
fun testColdFlow() = runBlocking {
    var upstreamRuns = 0
    val f = flow { upstreamRuns++; emit(1); emit(2) }
    assertEquals(0, upstreamRuns)                    // 没人 collect 就不执行
    assertEquals(listOf(1, 2), f.toList())
    assertEquals(1, upstreamRuns)
    assertEquals(listOf(1, 2), f.toList())           // 再收集一次：上游再执行一次
    assertEquals(2, upstreamRuns)
}
```

`assertEquals(0, upstreamRuns)` 是冷流的定义性证据：**只定义不 collect，一行上游代码都不会执行**。冷的意义：每个收集者拿到独立、完整的数据序列，互不干扰——这正是它适合"一次性数据查询/加载"的原因。

## 15.4 操作符管道

Flow 的操作符和集合操作一个手感，但语义是"每个元素**流过**整条管道"而不是"每一步处理完整个集合"：

```kotlin
/** 操作符链：和集合管道一个手感，但每个元素流过整条管道 */
fun pipeline(src: Flow<Int>): Flow<String> =
    src.map { it * 10 }
        .filter { it >= 20 }
        .transform { emit("$it!"); if (it == 30) emit("三十!") }
        .take(3)
```

```kotlin
    println("== 15.4 操作符管道 ==")
    pipeline((1..3).asFlow()).collect { println("  $it") }
```

输出：

```text
== 15.4 操作符管道 ==
  20!
  30!
  三十!
```

走一遍数据：(1..3).asFlow() 产出 1、2、3 → [map](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/map.html) 变成 10、20、30 → filter 留下 20、30 → [transform](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/transform.html) 对每个值先 `emit("$it!")`，值是 30 时再补一个 `emit("三十!")`（transform 是"一进可多出"的万能操作符）→ [take](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/take.html)(3) 收满三个就切断上游。最终 `20!`、`30!`、`三十!`——测试断言一致。

和集合管道的本质差别在"逐元素流动 + 挂起友好"：元素之间可以 delay、可以等网络，管道本身不会一次性把所有中间结果物化成大列表。

## 15.5 异常与完成

流中间炸了怎么办？**别在流外用 try/catch 包 collect**（那是命令式思维），用声明式操作符。示例造了一条"发到第三个就炸"的流：

```kotlin
/** 异常处理：catch 操作符只捕上游，onCompletion 是 finally */
fun failingFlow(): Flow<Int> = (1..3).asFlow().onEach { if (it == 3) throw IllegalStateException("坏在第 $it 个") }
```

第一种处理：[catch](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/catch.html) 操作符接住后 emit 一个哨兵值顶替：

```kotlin
    println("== 15.5 异常与完成 ==")
    val caught = failingFlow()
        .catch { e -> emit(-1) }              // 替换为哨兵值继续
        .toList()
    println("  catch 后: $caught")
```

第二种：catch 记录 + [onCompletion](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/on-completion.html) 收尾：

```kotlin
    val done = mutableListOf<String?>()
    failingFlow().onEach { done += "值$it" }
        .catch { done += "捕:${it.message}" }
        .onCompletion { done += "完成(cause=${it?.message})" }
        .collect { }
    println("  onCompletion: $done")
```

输出：

```text
== 15.5 异常与完成 ==
  catch 后: [1, 2, -1]
  onCompletion: [值1, 值2, 捕:坏在第 3 个, 完成(cause=null)]
```

第一行：1、2 正常流过，第 3 个炸在 onEach 里，catch 接住并 emit -1——所以列表是 `[1, 2, -1]`。第二行细看有讲究：`[值1, 值2, 捕:坏在第 3 个, 完成(cause=null)]`——注意 `cause=null`！onCompletion 的参数是"上游是否以异常结束"，而它排在 catch **之后**：catch 已经把异常吃掉，下游看来流是正常完成的。把 onCompletion 挪到 catch 之前，`cause` 就会变成那个 IllegalStateException——**操作符的顺序即语义**。

两条铁律：**catch 只捕上游**（catch 之后的操作符里炸的异常它管不着）；**onCompletion 是流的 finally**（无论正常、异常还是被取消都会执行，适合释放资源）。

## 15.6 SharedFlow 多播

冷 Flow 每个 collect 重跑上游——那"一个事件源、多个订阅者各自接收"（UI 事件、消息广播）怎么办？用热的 [SharedFlow](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/-shared-flow/index.html)：

```kotlin
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
```

输出：

```text
== 15.6 SharedFlow 多播 ==
  A收到: A1, A2 | B收到: B1, B2
```

[MutableSharedFlow](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/-mutable-shared-flow/index.html)`(replay = 0)` 的关键参数是 **replay**：新订阅者来晚时能补看几个历史值。replay=0 意味着"只收订阅之后的新值"——所以示例必须先 `delay(1)` 让两个订阅协程就位再 emit，否则值会丢给空气。emit 本身是挂起的：等**所有**订阅者收完才返回（订阅者慢会拖住发布者，这是 SharedFlow 的背压）。最后两个订阅协程的 collect 是无限循环，只能 cancel 收尾——注意 `cancel(); join()` 惯用对又出现了。

姊妹类型 [StateFlow](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.flow/-state-flow/index.html) = "replay=1 + 必须有初始值 + 只保留最新值"的 SharedFlow，读 `.value` 随时拿到当前状态——它是"可观察的状态容器"（UI 状态、配置项）的标准答案，而 SharedFlow 偏"一次性事件"。

## 15.7 竞态与 Mutex

回到最底层的问题：多协程改同一个变量。`c++` 不是原子的，是"读-改-写"三步——两个协程交错就丢更新。示例用 [yield](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/yield.html) 把"线程切换恰好插在中间"**确定性地**模拟出来：

```kotlin
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
```

修复版：同一结构，只是读改写裹进 [Mutex](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.sync/-mutex/index.html) 的 [withLock](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines.sync/with-lock.html)：

```kotlin
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
```

输出：

```text
== 15.7 竞态与 Mutex ==
  无锁（单线程模拟切换）: c = 100   ← 200 次自增丢了 100 次，更新被覆盖
  Mutex 保护后: c = 200
```

无锁版：两个协程各 repeat(100)，每次"读→yield→写"，yield 保证对方插在中间把同样的旧值读走，于是每次交错都丢一次更新——200 次自增只剩 100。这不是小概率事故，是**必然**（测试断言了确定区间 `r in 100..199`）。

Mutex 版：`withLock` 保证临界区同一时刻只有一个协程——哪怕持锁者在 `yield()` 让出，别人也进不来，读改写不可分割，结果必然 200。Mutex 是**协程级**锁：抢锁失败是挂起而不是阻塞线程，对调度器友好。

但有一个和 Java `synchronized`/`ReentrantLock` 不同的致命细节：**Mutex 不可重入**。同一个协程在 withLock 里再调一次 withLock，会**自己把自己挂死**（等自己放锁，永远不发生）。测试文件专门写了注释提醒：

```kotlin
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
```

更根本的建议放在最后：能用**限定符隔离**（把可变状态关在一个协程里，外界用 Channel/actor 通信）就别共享；必须共享才上 Mutex。锁是兜底，不是首选。

## 15.8 选型：Channel / Flow / SharedFlow / StateFlow

| 场景 | 武器 | 理由 |
|---|---|---|
| 协程间点对点传值、生产者-消费者 | Channel | 会合/缓冲/背压齐全，close 即终止信号 |
| 一次性的异步数据序列 + 加工管道 | 冷 Flow | 每个收集者独立重跑，操作符声明式组合 |
| 事件广播、多订阅者 | SharedFlow | 热多播，replay 控制补发历史 |
| 可观察的"当前状态"（UI 状态、配置） | StateFlow | 永远有当前值，`.value` 同步可读 |
| 多协程共享可变状态 | 先隔离，不得已再 Mutex | 锁保证原子性，但不可重入、易死锁 |

记忆锚点：**Channel 是通信，Flow 是数据流，SharedFlow/StateFlow 是广播，Mutex 是兜底**。

## 15.9 坑位清单

1. **以为 Flow 定义了就跑了**——冷流不 collect 一行上游代码都不执行（15.3 的 `upstreamRuns == 0` 断言）。
2. **用 try/catch 包 collect 捕流内异常**——异常沿管道传，用 `catch` 操作符；记住 catch 只捕**上游**。
3. **onCompletion 的 cause 判断失误**——它排在 catch 之后时异常已被吃掉，`cause` 恒 null；要看真实失败原因就放在 catch 之前。
4. **SharedFlow 没订阅者就 emit**——replay=0 时值直接丢给空气；要么先确认订阅就位，要么调 replay。
5. **StateFlow 和 SharedFlow 用混**——"状态"（有当前值、新来先看最新）用 StateFlow；"事件"（一次性、每个都重要）用 SharedFlow。
6. **Channel 忘了 close**——消费端 `for (x in ch)` 永远等下一个值，协程泄漏；生产者路径（含异常分支）都要保证 close。
7. **Mutex 里再 withLock**——不可重入，同协程二次加锁 = 死锁；把临界区拆小，别嵌套。
8. **在持锁临界区里做慢 IO**——锁粒度内所有协程排队等你；锁内只做内存操作，IO 挪到锁外。

## 本章验证

本章示例通过四层验证（与本教程所有章节一致）：`kotlinc -Werror` 零告警编译 → `kotlin.test` 断言全过（Tests.kt 共 7 组测试，覆盖会合顺序、冷流重跑、管道、catch、SharedFlow、竞态区间与 Mutex）→ 程序运行退出码 0 → stdout 与 `expected.txt` 逐字节一致。工具链：Kotlin 2.4.21（K2 编译器）+ JDK 21 + 发行版自带 `kotlinx-coroutines-core-jvm.jar`。

---

上一章：[14 ⭐协程基础](14-coroutines.md) · 下一章：[16 错误处理](16-errors.md)
