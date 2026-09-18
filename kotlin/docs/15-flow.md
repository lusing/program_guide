# 15 · 协程进阶：Channel 与 Flow ⭐

> 对应示例：`examples/15_flow/`
>
> 协程之间怎么传数据？**Channel**（热的、一对一管道）与 **Flow**（冷的、
> 异步版 Sequence）是两把主力工具，外加并发安全的共享状态原语。

## 15.1 Channel：会合的管道

```kotlin
suspend fun channelDemo(): List<String> = coroutineScope {
    val log = mutableListOf<String>()
    val ch = Channel<Int>()                    // capacity = 0：会合点
    launch {                                   // 生产者
        for (i in 1..3) { ch.send(i); log += "send $i" }   // 没人收就挂起
        ch.close()                             // 关闭 → 消费端 for 正常结束
    }
    for (x in ch) log += "recv $x"             // 空了就挂起；close 后退出
    log                                        // [send 1, recv 1, recv 2, send 2, ...]
}
```

容量语义：

| 构造 | 行为 |
|---|---|
| `Channel()` | **会合点**（0 缓冲）：send 挂起直到 receiver 到场 |
| `Channel(2)` | 缓冲 2：满了 send 才挂起 |
| `Channel(Channel.UNLIMITED)` | 无限缓冲（送快递柜） |
| `Channel(Channel.CONFLATED)` | 只留最新值（旧值被覆盖） |

**关闭协议**：生产完 `close()`，消费端 `for (x in ch)` 自然结束——不关就永远挂着（结构化并发下表现为泄漏等待）。`trySend/tryReceive` 是非阻塞版（失败返回失败结果而不是挂起）。

实测细节（golden 里能看）：会合点交接后**接收方先恢复**（`recv 2` 打在 `send 2` 前）——恢复顺序的确定性来自单线程事件循环。

## 15.2 Flow：冷流

```kotlin
fun ticker(): Flow<Int> = flow {
    println("上游开始执行")            // 这行每次 collect 都会跑！
    for (i in 1..3) { delay(1); emit(i) }
}

ticker().take(2).collect { println(it) }     // collect 1：跑一遍上游
ticker().take(1).collect { }                 // collect 2：再跑一遍上游
```

**冷 = 没有收集者就不执行；每个收集者独立一份执行**（对照 Sequence 的惰性，22 章有同构对比）。`flow { }` 是构建器，`emit` 发射；中间操作符全部惰性，`collect` 是终点。

```kotlin
fun pipeline(src: Flow<Int>): Flow<String> =
    src.map { it * 10 }                       // 惰性：元素逐个流过
       .filter { it >= 20 }
       .transform { emit("$it!"); if (it == 30) emit("三十!") }   // 一进多出
       .take(3)
```

常用家族：`map/filter/take/scan/onEach/transform`（中间）+ `toList/first/count/collect`（终端）+ `flowOf/asFlow/sequence` 来源。**普通 Flow 里禁止切线程**（异常裸抛，操作符间上下文固定）——要用 `flowOn(d)` 改变上游上下文。

## 15.3 异常与完成

```kotlin
failingFlow()
    .catch { e -> emit(-1) }              // 只捕上游异常，替换为哨兵继续
    .toList()                             // [1, 2, -1]

failingFlow()
    .onEach { ... }
    .catch { ... }
    .onCompletion { cause -> ... }        // finally：cause 非空 = 有异常
    .collect { }
```

`catch` 位置敏感：只救它**上游**的操作符——放管道中间就是"从这里重启"。这比 try/catch 包住整个 collect 精确。

## 15.4 SharedFlow / StateFlow：热流

```kotlin
val shared = MutableSharedFlow<Int>(replay = 0)   // 事件总线
launch { shared.collect { a += "A$it" } }          // 订阅者 A
launch { shared.collect { b += "B$it" } }          // 订阅者 B
shared.emit(1); shared.emit(2)                     // 广播给所有在场订阅者
```

| | Flow | SharedFlow | StateFlow |
|---|---|---|---|
| 温度 | 冷（一对一） | 热（多播） | 热（多播 + 永远有当前值） |
| 订阅前的事件 | 不存在 | replay=n 才补发 | 总能拿到最新值 |
| 典型 | 请求-响应管道 | 事件总线 | 状态holder（UI state） |

StateFlow = "带初值的变量 + 变更通知"，是 MVVM 状态的事实标准；SharedFlow 是事件流。`Flow.stateIn/shareIn` 能把冷流提升为热流（需要 scope——热流有生命周期）。

## 15.5 共享状态：竞态与 Mutex

协程不加锁改共享 var 一样丢更新。示例用**单线程 + yield 模拟线程切换**，让丢更新变得确定可见：

```kotlin
var c = 0
val jobs = (1..2).map { launch {
    repeat(100) {
        val t = c
        yield()               // ← 读和写之间让出：对方也读到同一个 t
        c = t + 1             // 覆盖对方的更新
    }
} }
jobs.joinAll()                // c = 100 —— 200 次自增只剩一半！
```

修复三件套：

```kotlin
val mutex = Mutex()
mutex.withLock { c = c + 1 }            // 1) 协程互斥锁（挂起友好）
val atomic = AtomicInt.incrementAndGet() // 2) CAS 原子类（21 章）
val state = MutableStateFlow(0)          // 3) 用消息/状态流代替共享变量（首选）
```

**Mutex vs synchronized**：Mutex 挂起而不是阻塞线程（池不被占死）；但它**不可重入**——同一协程 lock 两次 = 死锁。协程世界的优先序：**先想"能不能用 Channel/Flow 通信代替共享"**（CSP 思路），确要共享再上原子/Mutex。

## 15.6 坑位清单

1. **Channel 忘 close** → 消费端永远挂起；生产完必须 `close()`（或用 `produce { }` 构建器自动关）。
2. `for (x in ch)` 之外的 `receive()` 在关闭后抛 `ClosedReceiveChannelException`——先关后收要小心。
3. **冷流重复执行副作用**：`flow { 打日志/发请求 }` 每个 collect 都来一遍——这是特性，但 surprise 高发。
4. `catch` 只救上游；管道尾部的异常（collect 里）它管不到——那要用 `onCompletion` 或外层 try。
5. **普通 Flow 不线程安全于 emit**——不要在 `flow {}` 里 launch 别的协程来 emit（用 channelFlow）。
6. Mutex **不可重入**；`withLock` 里再 `withLock` 同一把锁 = 死锁（21 章 synchronized 是可重入的——语义相反，别混记）。
7. SharedFlow 默认 replay=0：晚到的订阅者收不到历史——要"新订阅者也补课"就设 replay。
