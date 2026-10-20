# 14 · 协程基础 ⭐

> 对应示例：`examples/14_coroutines/`（`src/Main.kt` 演示 + `test/Tests.kt` 断言 + `expected.txt` 输出快照）
>
> suspend、runBlocking、launch/async、结构化并发、取消、超时——
> 用顺序代码的写法拿到并发的性能。协程库用 Kotlin 发行版 `lib/` 自带的
> `kotlinx-coroutines-core-jvm.jar`，无需额外下载。

## 14.1 心智模型：协程是什么

异步编程的老问题是"回调地狱"和"线程太贵"：回调把逻辑拆得七零八落，线程一个就要吃掉 MB 级栈内存、切换还要进内核。协程（coroutine）给的答案是：**挂起（suspend）而不是阻塞（block）**。

一个协程可以理解成"带暂停点的代码块"：执行到挂起点（比如 [delay](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/delay.html)）时，它**让出所占线程**，把续体（剩下要执行的代码）登记好就离开；等条件满足（时间到了、数据到了），调度器再找一条空闲线程从断点继续。线程在协程挂起期间可以去跑别的协程——于是几千个协程共用几条线程就够了。

语法上只有三个核心概念：

1. **`suspend` 函数**：声明了 `suspend` 的函数体内允许出现挂起点；它只能被另一个 suspend 函数或协程调用——这条"传染性"规则保证了挂起链完整。
2. **协程构建器**（`launch`/`async`/`runBlocking`）：在普通世界和协程世界之间搭桥，或在协程里再开新协程。
3. **结构化并发**：每个协程都属于某个作用域（scope），作用域等所有孩子结束才结束，取消和异常沿作用域树传播——没有"野协程"。

示例文件头部有一句关键的确定性说明：

```kotlin
// 确定性说明：runBlocking 的子协程默认在当前线程的事件循环上按挂起点交错——顺序确定
```

这解释了为什么本章（和 15 章）的输出可以做成逐字节快照：runBlocking 的子协程默认跑在主线程的事件循环上，谁先谁后由挂起点决定，顺序是可复现的。

## 14.2 第一个协程：launch 与 join

普通函数（比如 `main`）不能直接调 suspend 函数，需要一个"桥"。[runBlocking](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/run-blocking.html) 就是桥：**阻塞当前线程**，直到它体内的协程树全部结束。示例的 main 整个包在 runBlocking 里：

```kotlin
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
```

输出：

```text
== 14.2 第一个协程：launch 与 join ==
launch 立刻返回（协程体还没跑）
  协程体运行在线程 main
  delay 之后继续
join 之后
```

四行输出的顺序就是协程语义的教科书：

1. [launch](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/launch.html) **立刻返回**——它只是把协程登记进事件循环，协程体还没开始跑，所以先打印 `launch 立刻返回`；
2. 当前协程（runBlocking 体）执行到 `job.join()` 挂起，事件循环才轮到 launch 的协程体——它跑在 **main 线程**上（默认调度行为），打印第一行；
3. 协程体遇到 `delay(1)` 挂起让出线程，1ms 后恢复，打印 `delay 之后继续`——注意 delay 是**非阻塞**的，换成 `Thread.sleep` 会把整个 main 线程睡死；
4. 协程体结束，`join` 返回，打印 `join 之后`。

`launch` 返回一个 [Job](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-job/index.html) 句柄，常用操作就三个：`join()`（挂起等完成）、`cancel()`（取消，14.5 节）、`isActive`（查状态）。

## 14.3 挂起函数与串行

协程体稍长就该拆函数——拆出来的就是 suspend 函数。示例的 `work` 和 `sequential`：

```kotlin
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
```

main 里调用：

```kotlin
    println("== 14.3 挂起函数与串行 ==")
    for (line in sequential()) println("  $line")
```

输出：

```text
== 14.3 挂起函数与串行 ==
  A1 A2
  B1 B2
```

`sequential` 里两个调用**没有** `launch`/`async`，就是普通的顺序调用：A 跑完（A1 A2）才轮到 B（B1 B2）。这是协程最被低估的优点——**默认就是顺序代码**，读法和同步代码一模一样；想要并发才需要显式写出来（下一节）。测试断言了这个结果：`assertEquals(listOf("A1 A2", "B1 B2"), sequential())`。

## 14.4 async/await 并行

要并行，用 [async](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/async.html)——和 launch 一样是构建器，但它返回 [Deferred](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-deferred/index.html)（"未来会有值的 Job"），用 `await()` 取结果：

```kotlin
/** async 并行：两个任务同时挂起等待，总时长 ≈ max 而不是 sum */
suspend fun parallelSum(): Pair<Long, Long> = coroutineScope {
    val x = async { delay(60); 21L }   // "耗时" 60ms
    val y = async { delay(40); 21L }   // "耗时" 40ms
    x.await() to y.await()
}
```

```kotlin
    println("== 14.4 async/await 并行 ==")
    val (x, y) = parallelSum()
    println("  并行结果: $x + $y = ${x + y}（总耗时≈60ms 而非 100ms）")
```

输出：

```text
== 14.4 async/await 并行 ==
  并行结果: 21 + 21 = 42（总耗时≈60ms 而非 100ms）
```

两个 async 登记的协程**同时**进入等待：60ms 的和 40ms 的重叠进行，总耗时约等于 max(60, 40)=60ms，而不是串行的 100ms——这就是"并行分解"。

注意外层包了 [coroutineScope](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/coroutine-scope.html)：suspend 函数里要开子协程，必须有一个作用域来"收养"它们。coroutineScope 的作用：**等体内所有子协程结束才返回**，并且孩子出事（异常/取消）会传播给父亲——这就是结构化并发的最小单元。测试验证结果值：`assertEquals(21L to 21L, parallelSum())`。

## 14.5 结构化并发与取消

协程的取消是**协作式**的：`cancel()` 只是打个标记，协程要在挂起点才会真正停下（挂起函数如 delay 会检查取消标记，抛 [CancellationException](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-cancellation-exception/index.html)）。示例造了一棵两层协程树来演示：

```kotlin
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
```

输出（顺序由测试固化）：

```text
== 14.5 结构化并发与取消 ==
  子协程启动
  子协程清理（finally 保证执行）
  父协程收尾
```

三件事值得记住：

1. **取消在挂起点生效**。子协程的 `delay(10_000)` 只睡了 5ms 就被父亲的 `child.cancel()` 打断——`子协程干完了（不该看到）` 果然没出现。
2. **`finally` 保证执行**。取消以 CancellationException 的形式穿过协程体，`try/finally` 里的清理代码照常跑（`子协程清理`）。释放资源就靠它；注意 finally 里默认**不能再挂起**（协程已死），要用 `withContext(NonCancellable)` 才行。
3. **`cancel(); join()` 是惯用对**。cancel 只是发信号，join 挂起等它真的收尾完，然后父亲才打印 `父协程收尾`。只 cancel 不 join 是竞态的常见来源。

测试把整个日志序列钉死：

```kotlin
    assertEquals(listOf("子协程启动", "子协程清理（finally 保证执行）", "父协程收尾"), log)
```

还有一条对称的规则：父亲被取消时，**所有孩子一起取消**（子协程不需要自己知道）。整个作用域树同生共死，这就是"结构化"的含义。

## 14.6 异常传播

结构化并发的另一面：孩子抛异常，**整个作用域跟着取消**，异常向父亲传播：

```kotlin
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
```

输出：

```text
== 14.6 异常传播 ==
  捕获: 炸了（整个作用域被取消）
```

10ms 后第二个孩子抛出 `IllegalStateException`，coroutineScope 立刻取消另一个孩子（它要 delay 100ms，没机会跑完），然后异常从 coroutineScope 重新抛出，被外层 catch 接住——`没炸` 永远不会返回。这个"一损俱损"是默认行为，也是大多数业务想要的：并行分解的子任务里一个失败，其余的继续做已经没有意义。

想要"孩子各管各、一个炸了不影响兄弟"，用 `supervisorScope`（14.8 节，15 章演示）。另外记住异常的类型边界：CancellationException 是**控制信号**不是错误，catch 时要么不碰它、要么接住了重新抛出——吞掉它会让协程无法停止。

## 14.7 超时

"最多等 X 毫秒"是网络/IO 代码的刚需，kotlinx 把它做成一个函数：[withTimeoutOrNull](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/with-timeout-or-null.html)：

```kotlin
    println("== 14.7 超时 ==")
    val fast = withTimeoutOrNull(50) { delay(5); "快任务完成" }
    val slow = withTimeoutOrNull(10) { delay(60); "慢任务完成" }
    println("  快: $fast")
    println("  慢: $slow（超时返回 null）")
```

输出：

```text
== 14.7 超时 ==
  快: 快任务完成
  慢: null（超时返回 null）
```

快任务 5ms 完成，远低于 50ms 限额，正常返回；慢任务要 60ms，10ms 时限一到就被取消，整个表达式返回 `null`——所以输出是 `慢: null`。姊妹函数 [withTimeout](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/with-timeout.html) 超时则**抛** `TimeoutCancellationException`：能把超时当数据处理的选 OrNull 版（免去 try/catch），超时即错误的选抛异常版。测试两个版本的核心行为都覆盖了。

## 14.8 作用域构建器选型

四个名字容易混，示例把它们打印成了一张备忘单：

```kotlin
    println("== 14.8 作用域构建器选型 ==")
    println("  runBlocking=测试/桥接阻塞世界 | coroutineScope=并行分解等全部 | supervisorScope=孩子互不影响(15章)")
    println("  GlobalScope=逃生舱，基本别用（脱离结构化并发，泄漏无感知）")
```

输出：

```text
== 14.8 作用域构建器选型 ==
  runBlocking=测试/桥接阻塞世界 | coroutineScope=并行分解等全部 | supervisorScope=孩子互不影响(15章)
  GlobalScope=逃生舱，基本别用（脱离结构化并发，泄漏无感知）
```

展开讲：

- **runBlocking**：阻塞当前线程等协程树结束。只该出现在两处——`main` 函数这种"阻塞世界到协程世界"的桥接处，以及单元测试（本章 Tests.kt 每个测试都是 `fun testXxx() = runBlocking { ... }`，注释提到第 20 章会讲更专业的 `runTest`）。**别在协程里或服务器请求处理路径上调它**——那等于把异步又堵回同步。
- **coroutineScope**：suspend 函数内做并行分解的标准工具，等全部孩子、异常向上传（14.4、14.6 节都在用它）。
- **supervisorScope**：形状相同但孩子是" supervisor 模式"——一个失败不连坐兄弟，15 章 SharedFlow 场景会用到。
- **GlobalScope**：全局作用域，挂在上面的协程不属于任何树——父亲结束它不死、应用退出没人取消它，泄漏了无感知。注释的定位很准："逃生舱，基本别用"。

## 14.9 协程 vs 线程

为什么费这么大劲学协程？看数量级：

```kotlin
    println("== 14.9 协程 vs 线程 ==")
    var done = 0
    val jobs = (1..1000).map { i ->
        launch { delay(1); done++ }     // 1000 个协程轻松起
    }
    jobs.joinAll()
    println("  1000 个协程全部完成: done=$done（1000 个线程会先耗尽内存）")
```

输出：

```text
== 14.9 协程 vs 线程 ==
  1000 个协程全部完成: done=1000（1000 个线程会先耗尽内存）
```

1000 个协程在一个 main 线程上顺序交错跑完（它们挂起时长一样、共享单线程，所以 `done++` 没有竞态），总共只花几毫秒。[joinAll](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/join-all.html) 一把等完全部 Job。换成 1000 个线程：每个默认栈 1MB 就是约 1GB 内存，还没算上下文切换的开销。

测试把这个实验推到极致——**一万个**协程：

```kotlin
fun testManyCoroutines() = runBlocking {
    var done = 0
    (1..10_000).map { launch { done++ } }.joinAll()
    assertEquals(10_000, done)
}
```

协程的轻量来自两个设计：挂起不占线程（14.1 节），以及协程对象本身只是堆上的小对象（续体状态机），没有内核栈。

## 14.10 调度器：协程跑在哪条线程上

本章示例全部跑在默认行为下：runBlocking 的事件循环直接用 main 线程（14.2 节的输出 `协程体运行在线程 main` 是证据）。真实项目里要用 [Dispatchers](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/-dispatchers/index.html) 显式选线程池：

- `Dispatchers.Default`——CPU 密集计算（大小 = CPU 核数）；
- `Dispatchers.IO`——文件、网络等阻塞 IO（弹性扩容的大池子）；
- `Dispatchers.Main`——UI 框架提供的主线程（Android/JavaFX）。

切调度器用 `withContext(Dispatchers.IO) { ... }`：挂起当前协程、换池子执行、完成后切回来。原则一句话：**默认 Default，碰阻塞 IO 切 IO，UI 更新回 Main**——剩下的交给结构化并发。

## 14.11 坑位清单

1. **在协程里调 `Thread.sleep`**——睡死的是整条线程，池子瞬间被占满。挂起等待永远用 `delay`。
2. **在请求处理路径上调 runBlocking**——把异步堵回同步，吞吐量直接塌方。runBlocking 只属于 main 和测试。
3. **吞掉 CancellationException**——`catch (e: Exception)` 一把抓会让协程取消失灵。要么不 catch 它，要么接住后重新抛出。
4. **只 `cancel()` 不 `join()`**——cancel 只是发信号，协程体可能还在 finally 里跑；需要"确定已停"就 `cancel(); join()`。
5. **取消是协作式的**——纯 CPU 死循环里没有挂起点，cancel 永远生效不了；长计算要穿插 `yield()`/`ensureActive()` 给取消一个机会。
6. **以为 launch 的异常会被外层 try/catch 接住**——launch 的异常沿作用域树传播（14.6），不是沿调用栈；想要"各管各"用 supervisorScope。
7. **滥用 GlobalScope**——脱离结构化并发的协程没人取消、没人等，泄漏无感知；先找该挂的作用域，实在没有再想逃生舱。
8. **共享 `var` 给多个协程**——本章示例安全是因为全部协程挤在单线程事件循环上；一旦切到多线程调度器，`done++` 就是竞态（15.7 节演示并给出 Mutex 解法）。

## 本章验证

本章示例通过四层验证（与本教程所有章节一致）：`kotlinc -Werror` 零告警编译 → `kotlin.test` 断言全过（Tests.kt 共 7 组测试，覆盖串行、并行、取消、异常传播、超时、万级协程）→ 程序运行退出码 0 → stdout 与 `expected.txt` 逐字节一致。工具链：Kotlin 2.4.21（K2 编译器）+ JDK 21 + 发行版自带 `kotlinx-coroutines-core-jvm.jar`。

---

上一章：[13 ⭐扩展](13-extensions.md) · 下一章：[15 ⭐Channel与Flow](15-flow.md)
