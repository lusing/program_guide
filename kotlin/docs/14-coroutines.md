# 14 · 协程基础 ⭐

> 对应示例：`examples/14_coroutines/`
>
> 协程 = **可挂起的计算**。suspend 函数遇到等待就让出线程，等到了再继续；
> 每个协程长在一棵**作用域树**上，父取消孩子全停。这两点理解了，
> 剩下的都是 API 细节。

## 14.1 心智模型：挂起不是阻塞

```kotlin
suspend fun work(name: String, steps: Int): String = buildString {
    for (i in 1..steps) {
        delay(1)                       // 挂起点：让出线程，1ms 后被调度回来
        append("$name$i ")
    }
}
```

- `Thread.sleep(1000)`：线程原地干等 1 秒，什么都不干占着线程。
- `delay(1000)`：协程"暂停"，**线程被释放去跑别的协程**，1 秒后任意线程恢复它。

协程 ≈ 用户态轻量线程：创建成本 ≈ 一个对象；切换成本 ≈ 保存几个寄存器（不陷内核）。百万级协程轻松。

**`suspend` 只能在协程或 suspend 函数里调**——编译器沿调用链强制标注（像 async/await，但 await 变成了隐式）。

## 14.2 入口与构建器

```kotlin
fun main() = runBlocking {            // 阻塞主线程，直到协程树结束（测试/main 专用）
    val job = launch {                // 起"发射后不管"的子协程
        delay(1)
        println("done")
    }
    job.join()                        // 等它完成
}
```

| 构建器 | 语义 | 用途 |
|---|---|---|
| `runBlocking` | 阻塞当前线程等结果 | main / 单元测试边界 |
| `launch` | 返回 Job（无结果） | 后台任务、触发型 |
| `async` | 返回 Deferred<T>（有结果） | 并行分解，`await()` 收账 |
| `coroutineScope` | 等所有子完成，异常向上传 | 并行分解的作用域 |
| `supervisorScope` | 孩子失败不连坐 | 15 章 |

## 14.3 串行与并行

```kotlin
suspend fun sequential() {                 // 顺序：B 等 A 干完
    val a = work("A", 2); val b = work("B", 2)
}

suspend fun parallelSum(): Pair<Long, Long> = coroutineScope {
    val x = async { delay(60); 21L }      // 两个 async 同时挂起等待
    val y = async { delay(40); 21L }      // 总耗时 ≈ max(60, 40)，不是 100
    x.await() to y.await()                // await 收结果
}
```

`coroutineScope {}` 的契约：**等全部孩子完成才返回**——忘记 await 的孩子也跑得完（不丢任务）。

## 14.4 结构化并发：一棵树管到底

```
runBlocking (根作用域)
 ├── launch A
 │    └── launch A1
 └── launch B
```

规则（这是 Kotlin 协程与 goroutine 最大的分野）：

1. **父取消 → 子全部取消**（递归）。
2. **子失败 → 父取消 → 兄弟也取消**（fail-fast，coroutineScope 语义；supervisorScope 除外）。
3. 父必须等所有子结束才能结束。

```kotlin
suspend fun structuredCancel(): List<String> = coroutineScope {
    val log = mutableListOf<String>()
    val parent = launch {
        val child = launch {
            try { delay(10_000); }                       // "长任务"
            finally { log += "清理（finally 保证执行）" }  // 取消时清理
        }
        delay(5)
        child.cancel(); child.join()
    }
    parent.join()
    log
}
```

被取消的协程在**挂起点抛 CancellationException**——`try/finally` 照常工作（释放资源放 finally，15 章讲 suspend 清理的正确姿势）。

**GlobalScope**（"活在整个进程"的作用域）是逃生舱不是默认：脱离树 = 泄漏无感知 + 生命周期没人管。Android 有 viewModelScope、服务端有框架 scope——永远找一棵"活得刚刚好"的树挂上去。

## 14.5 超时

```kotlin
val fast = withTimeoutOrNull(50) { delay(5); "快任务完成" }   // "快任务完成"
val slow = withTimeoutOrNull(10) { delay(60); "慢" }          // null
```

超时 = 取消的一种：`withTimeout` 抛 `TimeoutCancellationException`，`withTimeoutOrNull` 返回 null。

## 14.6 调度器与线程

```kotlin
withContext(Dispatchers.Default) { /* CPU 密集 */ }      // 计算池
withContext(Dispatchers.IO) { /* 阻塞 IO */ }            // IO 池（可扩到 64+ 线程）
withContext(Dispatchers.Main) { /* UI（Android/Swing）*/ }
delay(1)                                                 // 单线程上下文里也只让出、不换线程
```

协程**默认不指定调度器就跑在当前上下文**（runBlocking = 调用线程的事件循环）——所以本教程示例的输出顺序全可预测。需要真并行时切 `Dispatchers.Default`（21 章讲协程与线程的 M:N 关系）。

切换用 `withContext(d) { ... }`（切换并返回），别手动 new 线程。

## 14.7 一千个协程

```kotlin
val jobs = (1..1000).map { launch { delay(1); done++ } }
jobs.joinAll()
```

1000 个线程 ≈ 1GB 栈预留 + 大量内核调度；1000 个协程 ≈ 1000 个对象。**并发单位从线程换成协程**，是这个模型最大的实践红利。

## 14.8 坑位清单

1. **runBlocking 别进生产代码**——它是阻塞桥，只该活在 main/测试的边界。嵌套 runBlocking 死锁高发。
2. **GlobalScope.launch 十有八九是 bug**——没有生命周期管理的协程 = 泄漏 + 取消不了。
3. `delay` 的参数是最小等待，不是精确延时——别拿协程做硬实时。
4. 取消是**协作式**的：不检查挂起点的死循环（`while(true) { x++ }`）取消不掉——循环里要有 `delay/yield/ensureActive`。
5. `async` 里抛的异常在 `await()` 之前就会取消兄弟（coroutineScope 语义）——想要"各自失败各自报"用 supervisorScope + async（15 章）。
6. 顺序敏感的逻辑别默认"自动并行"：`async` 才并行，顺序调用就是顺序执行——示例 sequential 的输出顺序是确定的。
