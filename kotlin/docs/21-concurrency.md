# 21 · 并发与线程

> 对应示例：`examples/21_concurrency/`——`src/Concurrency.kt` 是全部可复用的演示函数与类，`src/Main.kt` 逐节调用并打印，`test/Tests.kt` 用断言把并发行为钉死，`expected.txt` 是 27 行逐字快照。
>
> 14–16 章把协程讲透了，这一章回到 JVM 的地基：**平台线程**。协程不是取代线程，而是把线程降级为"调度资源"——理解了线程的成本与脾气，才知道挂起为什么便宜、锁为什么在 suspend 函数里是危险品。本章把 JVM 并发五件套（Thread、synchronized、原子类、线程池、ThreadLocal）各过一遍，最后与协程世界对齐。

并发代码最大的测试难题是**不确定性**：线程谁先跑完、谁抢到锁，每次运行都可能不同。本章示例的应对策略就写在 `Concurrency.kt` 的头两行注释里，这也是全章的暗线：

```kotlin
// 21 · 并发与线程：Thread、synchronized、原子类、线程池、ThreadLocal、与协程的关系
// 输出确定性策略：并行结果"先收集再排序"，竞态用单线程协程模拟，计数用锁/原子保证终值
```

记住这三招——**排序消灭顺序不确定、锁/原子消灭终值不确定、显式命名消灭线程名不确定**——并发代码一样可以进快照测试。21.10 会逐条回收。

## 21.1 线程：JVM 并发的最小单位

**进程是资源的容器，线程是执行的单位。** 同一进程里的所有线程共享堆内存（对象、静态字段），各自独享一个调用栈。JVM 的平台线程（platform thread）按 [JDK 21 的 Thread 文档](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Thread.html)说法"typically mapped 1:1 to kernel threads"——每根线程对应一个操作系统内核调度实体，创建销毁都要进出内核，每根默认预留约 1MB 栈空间。

先建立一个数量级直觉：一万根平台线程 ≈ 10GB 栈预留，还没算内核调度的压力。所以"一个连接一根线程"的模型在万级并发下必然崩溃——这就是 21.5 线程池和 21.7 协程存在的理由。

每个 JVM 程序出生时已经有一根线程在跑 `main` 函数，它就叫 `main`。本章 `Main.kt` 的第一行输出就是它的自我介绍：

```kotlin
println("  当前线程: ${Thread.currentThread().name}")
```

`Thread.currentThread()` 返回当前正在执行的线程对象——并发调试时它是你的"我在哪"。快照里对应的输出：

```
== 21.2 Thread 的创建与汇合 ==
  当前线程: main
```

## 21.2 Thread 的创建与汇合

开线程、收结果、等结束，是并发编程的"Hello World"。示例把它封装成一个函数：

```kotlin
/** 两个线程各干各的，join 后汇总（结果排序 → 输出确定） */
fun twoWorkers(): List<String> {
    val results = java.util.Collections.synchronizedList(mutableListOf<String>())
    val t1 = Thread { results += "T1:1..100 求和=${(1..100).sum()}" }
    val t2 = Thread { results += "T2:a..z 共 ${('a'..'z').count()} 个字符" }
    t1.start(); t2.start()
    t1.join(); t2.join()
    return results.sorted()
}
```

逐行拆解，每一行都有讲究：

1. **`Thread { ... }`**：这是 [java.lang.Thread](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/Thread.html) 的构造器调用，实参类型是 `Runnable`。Kotlin 对 Java 接口做 SAM 转换（18 章的规则），所以 lambda 可以直接当 `Runnable` 传——构造即绑定任务，但此刻**线程还没有运行**。
2. **`start()` 才开线程**：它向操作系统注册新的执行流，然后立即返回；任务在新线程里并发执行。千万注意：如果误调 `run()`，任务会在**当前线程**里同步执行，一个"没开线程的多线程程序"就诞生了——这是最低级也最常见的并发错误。
3. **`join()` 等线程结束**：阻塞当前线程，直到目标线程的 `run()` 跑完。不 join 的线程是"失联线程"——main 跑完、JVM 开始关闭时，它可能还没算出结果。join 还有一个隐藏福利：**建立 happens-before 关系**，被 join 线程的所有写入，对 join 返回后的线程保证可见。21.10 的测试靠这一点读跨线程写入的变量。
4. **共享集合必须线程安全**：两个线程并发写普通 `MutableList`（底层 ArrayList）可能丢数据甚至损坏内部结构。[Collections.synchronizedList](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Collections.html) 返回一个"每个方法都持锁"的包装器，`results += "..."`（即 `add`）因此是原子的。注意它只保**单个方法**的原子性——先查后加、迭代遍历这类复合操作仍需外部同步。
5. **`sorted()` 消灭顺序不确定**：t1 和 t2 谁先写完由操作系统调度决定，`results` 里的顺序每次都可能不同。在函数出口处排序，不确定性被关在函数内部，返回值永远相同。这就是头注说的"先收集再排序"。

main 里的调用与输出（`expected.txt` 第 1–4 行）：

```kotlin
println("== 21.2 Thread 的创建与汇合 ==")
println("  当前线程: ${Thread.currentThread().name}")
for (r in twoWorkers()) println("  $r")
```

```
== 21.2 Thread 的创建与汇合 ==
  当前线程: main
  T1:1..100 求和=5050
  T2:a..z 共 26 个字符
```

`T1` 排在 `T2` 前不是因为它先跑完，而是 `sorted()` 的字典序。5050 是高斯求和 `(1..100).sum()`，26 是 `('a'..'z').count()`——两个 CharRange/IntRange 的标准库小练习被塞进了线程任务里。

顺提一句：标准库还有一个更顺手的 [kotlin.concurrent.thread](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.concurrent/thread.html) 助手，`thread(start = true, name = "demo-worker") { ... }` 一行完成创建、命名、启动。本例故意用裸构造器，是为了把 start/join 这两个动作摆到明面上。

## 21.3 synchronized：互斥

上一节的两个线程各写各的字符串，互不干扰。真正的麻烦出现在**多个线程改同一个变量**时。`hits++` 看起来是一步，编译成字节码却是四步：读字段（getfield）、压入 1、相加、写字段（putfield）。两个线程交错执行这四步，就会互相覆盖对方的增量——4 个线程各加 10000 次，理论终值 40000，实测几乎必然小于它，而且每次运行丢多少都不一样。这叫**竞态（race condition）**。

修复方案一：把"读-改-写"关进互斥的临界区。示例中的计数器与压力函数：

```kotlin
/** synchronized 方法：计数终值确定 */
class SyncCounter {
    @Synchronized
    fun bump() { hits++ }        // 读改写三步，锁保证原子
    var hits = 0
        private set
}

/** 无锁的共享自增会丢更新——真实多线程下每次结果都不同，所以这里"只测有锁版" */
fun hammer(c: SyncCounter, threads: Int = 4, per: Int = 10_000): Int {
    val ts = (1..threads).map { Thread { repeat(per) { c.bump() } } }
    ts.forEach { it.start() }; ts.forEach { it.join() }
    return c.hits
}
```

要点：

- **`@Synchronized`**：[kotlin.jvm.Synchronized](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.jvm/-synchronized/index.html) 注解让生成的 JVM 方法带上 `ACC_SYNCHRONIZED` 标志——线程进入方法前必须先获得**该实例**（`this`）的监视器锁，方法退出（包括异常退出）时自动释放。同一时刻只有一个线程能待在 `bump()` 里，读-改-写重新变成原子的。锁的粒度是实例：两个不同的 `SyncCounter` 对象互不阻塞。
- **`hammer` 把竞态参数化**：线程数和每人次数都是带默认值的参数，测试里既能跑 4×10000 也能跑 2×5000（21.10）。终值 40000、10000 与线程调度完全无关——这就是互斥换来的**确定性**。
- 头注里"竞态用单线程协程模拟"指的是 15 章的做法：在单线程协程里用 `yield` 人为制造交错，让丢更新**确定可见**（结果恒 100）。本章不重复演示无锁版——真实多线程下它每次结果都不同，没法进快照，所以 hammer 的注释明说"只测有锁版"。

main 里的调用与输出（`expected.txt` 第 5–6 行）：

```kotlin
println("== 21.3 synchronized：互斥 ==")
val sc = SyncCounter()
val hits = hammer(sc)
println("  4 线程 × 10000 次 @Synchronized bump = $hits（终值恒定）")
// @Volatile 只保证可见性与顺序，不保证读改写原子——计数场景它救不了你
```

```
== 21.3 synchronized：互斥 ==
  4 线程 × 10000 次 @Synchronized bump = 40000（终值恒定）
```

**@Volatile 的真相**（源码里那行注释值得背下来）：`@Volatile` 只保证两件事——一个线程的写入对其他线程立即可见（可见性）、禁止相关指令重排（有序性）。它**不保证复合操作的原子性**：`@Volatile var hits` 上的 `hits++` 照样是读-改-写三步，照样丢更新。它的正确用法是"一写多读"的标志位（如 `running`、`shutdownRequested`），不是计数器。

协程世界的对照表（15 章详述 Mutex）：

| | synchronized / 锁 | Mutex（协程） |
|---|---|---|
| 等待方式 | 阻塞线程（线程干等） | 挂起协程（线程去干别的） |
| 可重入 | ✓ 同线程可重进 | ✘ 同协程二次 `lock()` 即死锁 |
| 适用 | 阻塞世界、JVM API | suspend 函数 |

规则只有一条：**suspend 函数里永远用 Mutex 或原子类**。挂起点上持 synchronized 锁，等于把调度线程锁死，协程"轻量"的优势归零。

## 21.4 原子类：CAS 无锁

锁是"悲观"的：先假设一定有人抢，进门就锁门。计数这种单变量场景还有一条"乐观"路线——**原子类**：

```kotlin
/** 原子类：CAS 无锁原子 */
class AtomicCounter {
    private val n = java.util.concurrent.atomic.AtomicInteger()
    fun bump() { n.incrementAndGet() }
    val value: Int get() = n.get()
}
```

main 里的打法与 SyncCounter 完全对称（`expected.txt` 第 7–8 行）：

```kotlin
println("== 21.4 原子类 CAS ==")
val ac = AtomicCounter()
val ts = (1..4).map { Thread { repeat(10_000) { ac.bump() } } }
ts.forEach { it.start() }; ts.forEach { it.join() }
println("  AtomicInteger 40000 次自增 = ${ac.value}")
```

```
== 21.4 原子类 CAS ==
  AtomicInteger 40000 次自增 = 40000
```

[AtomicInteger](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/atomic/AtomicInteger.html) 的 `incrementAndGet()` 底层是 **CAS（compare-and-swap）**：硬件级"比较并交换"指令，写入前先确认值没被别人动过，被动过就重读重试。它不需要内核态互斥，单变量场景下比锁轻量，终值同样确定——40000 次自增一次不丢。

两点提醒：**无锁 ≠ 无等待**，竞争激烈时 CAS 会自旋重试，烧的是 CPU；**单变量才有原子类**，`n++` 配 `m++` 必须同生共死时，还得回到锁/Mutex。计数器竞争极高（几十线程以上）时，JDK 提供分段思想的 [LongAdder](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/atomic/LongAdder.html)，吞吐更好——本例 4 线程的量级，`AtomicInteger` 绰绰有余。

## 21.5 线程池：别裸起线程

21.1 算过账：平台线程 ≈ 1MB 栈 + 一个内核调度实体，创建销毁都贵。任务又短命又多时，正确姿势是**池化复用**——预先造好几根线程，任务来了领一根，干完还回去：

```kotlin
/** 线程池：任务结果取回后排序 */
fun poolWork(): List<Int> {
    val pool = java.util.concurrent.Executors.newFixedThreadPool(3)
    try {
        val futures = (1..5).map { i -> pool.submit<Int> { i * i } }
        return futures.map { it.get() }.sorted()
    } finally {
        pool.shutdown()
    }
}
```

- **`Executors.newFixedThreadPool(3)`**：[Executors](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/Executors.html) 是线程池工厂，`newFixedThreadPool` 造定长池——3 根线程跑 5 个任务，必然有任务排队等位，这正是"复用"的含义。
- **`pool.submit<Int> { i * i }`**：提交的是 `Callable<Int>`（有返回值的 `Runnable`），又一次 SAM 转换。返回值是 [Future](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/concurrent/Future.html)——一张"未来兑现的支票"。
- **`futures.map { it.get() }.sorted()`**：`Future.get()` 阻塞等待对应任务完成并取回结果。5 个任务的完成顺序不确定，照旧先收集再 `sorted()`，输出 `[1, 4, 9, 16, 25]`。
- **`finally { pool.shutdown() }`**：池里的线程是**非守护线程**，不 shutdown 它们会一直等任务，JVM 进程永不退出。"池要用完就还"必须写成肌肉记忆。（JDK 19 起 `ExecutorService` 实现了 `AutoCloseable`，新代码也可以 `pool.use { ... }`。）

main 里的输出（`expected.txt` 第 9–11 行）：

```
== 21.5 线程池：别裸起线程 ==
  3 线程池跑 5 个任务（平方排序）= [1, 4, 9, 16, 25]
  poolWork 的 finally 里 shutdown——池要用完就还，长期池交给框架管
```

JDK 21 还给了第三条路：**虚拟线程**（virtual threads，JEP 444）。`Executors.newVirtualThreadPerTaskExecutor()` 为每个任务创建一根虚拟线程，由 JVM 把它挂载到少量载体线程上调度，阻塞时自动卸载——思路和协程神似，但让现存的阻塞式 Java 代码无痛获得高并发能力。Kotlin 社区主线仍是协程（结构化、可取消、Flow 生态），知道虚拟线程的存在是为了看懂 JDK 21 时代的 Java 代码。

## 21.6 ThreadLocal：每线程一个副本

前面的主题都是"多线程共享一份数据，如何不出错"。[ThreadLocal](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/lang/ThreadLocal.html) 反其道而行：**每个线程各持一份副本，天然零竞争**：

```kotlin
/** ThreadLocal：每线程一份副本 */
class ThreadId {
    private val local = ThreadLocal.withInitial { "初始" }
    fun set(v: String) { local.set(v) }
    fun get(): String = local.get()!!
    fun describe(): String = "线程 ${Thread.currentThread().name} 看到 ${local.get()}"
}
```

- **`withInitial { "初始" }`**：每个线程**第一次** `get()` 时，惰性执行这个 lambda 初始化自己的副本。之后各线程的 set/get 互不可见。
- **`local.get()!!`**：`ThreadLocal.get()` 来自 Java，对 Kotlin 是平台类型 `String!`（18 章的概念）。`withInitial` 保证了初始值非空，所以 `!!` 是安全的——但如果你 `set(null)`，它就会炸，别这么干。
- **`describe()` 把线程名也打印出来**：副本是谁的，一眼可见。

main 里的演示（`expected.txt` 第 12–16 行）：

```kotlin
println("== 21.6 ThreadLocal：每线程一个副本 ==")
val tid = ThreadId()
println("  主线程默认值: ${tid.describe()}")
tid.set("主线程的值")
println("  设置后: ${tid.describe()}")
val other = Thread { println("  （新线程）${tid.describe()}") }
other.name = "demo-worker"              // 显式命名：JVM 默认的 Thread-N 编号不稳定
other.start(); other.join()
println("  新线程看到的还是自己的初始值——副本隔离")
```

```
== 21.6 ThreadLocal：每线程一个副本 ==
  主线程默认值: 线程 main 看到 初始
  设置后: 线程 main 看到 主线程的值
  （新线程）线程 demo-worker 看到 初始
  新线程看到的还是自己的初始值——副本隔离
```

主线程把自己的副本改成 `"主线程的值"`，新线程 `describe()` 看到的仍是 `"初始"`——**副本隔离**是 ThreadLocal 的全部意义。典型用途：traceId、事务上下文、线程不安全的 `SimpleDateFormat` 缓存。

两个细节都值得学。其一，`other.name = "demo-worker"`：Kotlin 属性语法调用 `setName()`（18 章的实例 setter 合成规则）。JVM 默认线程名 `Thread-N` 的 N 是**全局递增编号**，同一次运行内受创建顺序影响，进快照必然翻车——本章头注的第三招"显式命名"就落地在这行。其二，**线程池 + ThreadLocal = 串味**：池线程被复用，上一个任务留下的副本还在，下一个任务会读到。池化场景用完必须 `remove()`（最好放 finally）。

协程世界的对应物是 `ThreadContextElement`：协程在挂起恢复后可能换一根线程跑，ThreadLocal 不会跟着走——请求级上下文请放进 `coroutineContext`，别放进 ThreadLocal。

## 21.7 协程与线程：M:N

现在可以把两个世界叠起来看了。main 里的演示（`expected.txt` 第 17–19 行）：

```kotlin
println("== 21.7 协程与线程：M:N ==")
runBlocking {
    var poolName = ""
    withContext(Dispatchers.Default) {
        poolName = Thread.currentThread().name
    }
    // 具体落在哪根 worker 线程每次可能不同——快照测试不打印原始名字，只打印稳定事实
    println("  withContext(Default) 落在池线程? ${poolName.startsWith("DefaultDispatcher-worker")}")
    println("  100k 协程 vs 100k 线程：协程 ≈ 轻量对象，线程 ≈ 1MB 栈预留")
}
```

```
== 21.7 协程与线程：M:N ==
  withContext(Default) 落在池线程? true
  100k 协程 vs 100k 线程：协程 ≈ 轻量对象，线程 ≈ 1MB 栈预留
```

- **`withContext(Dispatchers.Default)`**（[官方文档](https://kotlinlang.org/api/kotlinx.coroutines/kotlinx-coroutines-core/kotlinx.coroutines/with-context.html)）把代码块调度到共享后台池执行，池线程名形如 `DefaultDispatcher-worker-N`。具体落在哪根 worker，每次运行可能不同——所以快照**不打印原始线程名**，只断言 `startsWith("DefaultDispatcher-worker")` 这个稳定事实。这和 21.6 的"显式命名"是同一思想的另一面：**不稳定的信息要么消灭，要么降维成稳定断言**。
- **M:N 调度**：N 个协程跑在 M 根池线程上（Default 池的 M ≈ CPU 核数）。协程挂起时不占线程，线程被释放去跑别的协程；恢复时可能换一根线程继续。线程从"任务本身"降格为"调度资源"——这就是本章开头说的"线程是资源、协程是调度单位"。
- **数量级对比**：100k 个协程 ≈ 100k 个普通对象（每个带一个续体状态机）；100k 根平台线程 ≈ 100GB 栈预留，先 OOM 再说。并发单位从 MB 级降到 KB 级，就是"降维"。
- **代价与纪律**：阻塞调用（JDBC、同步 HTTP 客户端、`Thread.sleep`）不会挂起，只会把脚下那根调度线程**占死**——Default 池被占满，所有协程一起饿死。所以阻塞代码必须用 `withContext(Dispatchers.IO)` 赶到专门为大阻塞池准备的 IO 调度器上（15 章的 flowOn/withContext 详述）。

## 21.8 kotlin.concurrent.atomics：多平台原子类

21.4 的 `AtomicInteger` 好用，但它是 `java.util.concurrent.atomic` 的类——**Kotlin/JS、Kotlin/Wasm 上没有 java.util.concurrent**。标准库在 [kotlin.concurrent.atomics](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.concurrent.atomics/) 给出了多平台答案（2.1 引入，目前仍是 `@ExperimentalAtomicApi` 实验性 API）。`Concurrency.kt` 的封装：

```kotlin
import kotlin.concurrent.atomics.AtomicInt
import kotlin.concurrent.atomics.ExperimentalAtomicApi
import kotlin.concurrent.atomics.asJavaAtomic
import kotlin.concurrent.atomics.incrementAndFetch
import kotlin.concurrent.atomics.plusAssign

/** 与 java.util.concurrent.atomic.AtomicInteger 语义相同，但它是 expect/actual 的**公共 API**：
 *  Native 上是 volatile + 原子指令，JVM 上直接桥到 java 的 AtomicInteger，
 *  JS/Wasm 没有真线程，实现是 trivial 的（单线程下语义正确）。 */
@OptIn(ExperimentalAtomicApi::class)
class KotlinAtomicCounter {
    private val n = AtomicInt(0)

    fun bump() { n.incrementAndFetch() }             // 扩展函数：与 java 的 incrementAndGet 同名同义
    fun add(delta: Int) { n += delta }               // plusAssign 扩展：a += n
    fun fetchAndAdd(delta: Int): Int = n.fetchAndAdd(delta)   // 成员函数：加完返回**旧值**
    fun cas(expect: Int, update: Int): Boolean = n.compareAndSet(expect, update)
    val value: Int get() = n.load()

    /** JVM 专属桥：需要把 Kotlin 的原子量交给只认 java API 的库时用它 */
    fun asJavaAtomic(): java.util.concurrent.atomic.AtomicInteger = n.asJavaAtomic()
}
```

先看 import 清单——**四个扩展函数必须逐个显式 import**：`incrementAndFetch`、`plusAssign`、`asJavaAtomic` 都不是 `AtomicInt` 的成员，而是包级扩展（19.11 的 `90.seconds` 是同一课：扩展不导入就 unresolved）。而 `fetchAndAdd`、`compareAndSet`、`load` 是真正的成员函数。这个"成员/扩展混编"的设计初看别扭，实际给了平台实现自由：JVM 上直接桥到 `java` 的 `AtomicInteger`，Native 上是 volatile + 原子指令，没有真线程的 JS/Wasm 上实现是 trivial 的（单线程下语义依然正确）——这是源码注释里写明的话，也是 `AtomicInt` 与 `java.util.concurrent.atomic.AtomicInteger` 的本质差别：前者是 expect/actual 的公共 API，后者是 JVM 专属实现。

演示（`src/Main.kt` 第 51-60 行）与输出（`expected.txt` 第 20–25 行）：

```kotlin
println("== 21.8 kotlin.concurrent.atomics：多平台原子类 ==")
val kc = KotlinAtomicCounter()
val kts = (1..4).map { Thread { repeat(10_000) { kc.bump() } } }
kts.forEach { it.start() }; kts.forEach { it.join() }
println("  AtomicInt 40000 次 incrementAndFetch = ${kc.value}（终值同样确定）")
println("  fetchAndAdd(10) 返回旧值 ${kc.fetchAndAdd(10)}，现值 ${kc.value}")
val before = kc.value
println("  compareAndSet($before, 999) = ${kc.cas(before, 999)} → 现值 ${kc.value}")
println("  compareAndSet(1, 2) = ${kc.cas(1, 2)} → 现值不变 ${kc.value}")
println("  asJavaAtomic() 底层 = ${kc.asJavaAtomic()::class.simpleName}（JVM 桥；JS/Wasm 无真线程，实现 trivial）")
```

```
== 21.8 kotlin.concurrent.atomics：多平台原子类 ==
  AtomicInt 40000 次 incrementAndFetch = 40000（终值同样确定）
  fetchAndAdd(10) 返回旧值 40000，现值 40010
  compareAndSet(40010, 999) = true → 现值 999
  compareAndSet(1, 2) = false → 现值不变 999
  asJavaAtomic() 底层 = AtomicInteger（JVM 桥；JS/Wasm 无真线程，实现 trivial）
```

- **终值同样确定**：40000 次 `incrementAndFetch` 一次不丢——和 21.4 的 `AtomicInteger` 结论一致，验证的也是同一套 CAS 语义。
- **`fetchAndAdd` 返回旧值**：输出里"返回旧值 40000，现值 40010"——"fetch-and-add"的语义就是先把旧值交出来再加。测试 `testKotlinAtomics` 把三个数全钉住：`assertEquals(40_000, kc.fetchAndAdd(10))` 后现值 `40_010`。
- **`compareAndSet` 成功与失败各演一遍**：期望值对得上就写入并返回 `true`（40010 → 999）；对不上**什么都不做**返回 `false`（期望 1，现值 999，拒绝写入）。CAS 的"比较成功才交换"在这一行上看得很直观。
- **`asJavaAtomic()` 是单向桥**：Kotlin 原子量 → Java `AtomicInteger`，给只认 java API 的库（如某些指标库）用。注意它返回的是**快照视图还是活桥**取决于实现，别依赖它的返回值语义做并发决策——示例只打印底层类型名这个稳定事实。
- **opt-in 位置**：标在类上（`@OptIn(ExperimentalAtomicApi::class) class KotlinAtomicCounter`），类体内所有用法都被覆盖；调用方（`Main.kt` 的 main）**不需要**再标——与 19.12 的 Uuid 相反，那里因为 main 直接用了 API 才要标。规律：**opt-in 标在"直接书写该 API 符号"的声明处**，经封装转一手就不用。

什么场景选它而不是 `java.util.concurrent.atomic`：**多平台代码（common 模块）**。纯 JVM 项目两者等价，用哪个都不亏；写 Kotlin Multiplatform 的 common 代码时，`AtomicInt` 是唯一选项（那时 `asJavaAtomic` 在 jvmMain 里还能按需降级）。

## 21.9 选型速查

main 的最后一行输出把全章浓缩成一句话（`expected.txt` 第 26–27 行）：

```
== 21.8 选型速查 ==
  阻塞 IO/长寿任务 → 线程池 | 高并发等待 → 协程 | 共享计数 → 原子类 | 复合临界区 → Mutex/锁
```

展开成决策表：

| 需求 | 选择 | 理由 |
|---|---|---|
| 高并发等待型（网络 IO） | 协程 + `Dispatchers.IO` | 挂起不占用线程 |
| CPU 密集并行计算 | 协程 + `Dispatchers.Default` / 定长线程池 | 并行度 ≈ 核数 |
| 阻塞 IO / 长寿任务 | 线程池 | 线程本来就是干这个的 |
| 单变量共享计数 | 原子类（竞争激烈换 `LongAdder`） | 无锁 CAS，最轻 |
| 多平台（common）原子计数 | `kotlin.concurrent.atomics.AtomicInt` | JVM 原子类在 JS/Wasm 不存在 |
| 多变量复合临界区 | `Mutex`（协程）/ `synchronized`（阻塞） | 互斥保证一致性 |
| 调用阻塞库 | `withContext(Dispatchers.IO)` 包住 | 不占调度线程 |
| 一写多读标志位 | `@Volatile` | 要的是可见性不是原子性 |
| 请求级上下文（traceId） | 协程：`coroutineContext` / 阻塞：`ThreadLocal` | 跟随执行流走 |

## 21.10 测试：把不确定驯化成确定

并发测试不是"跑几次没挂就算过"，而是**用确定性来源替代运气**。`test/Tests.kt` 全文：

```kotlin
// 21 的测试：终值确定性（锁/原子），线程池结果，ThreadLocal 隔离，kotlin 原子类
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

fun testTwoWorkers() {
    assertEquals(listOf("T1:1..100 求和=5050", "T2:a..z 共 26 个字符"), twoWorkers())
}

fun testSyncCounter() {
    assertEquals(40_000, hammer(SyncCounter(), threads = 4, per = 10_000))
    assertEquals(10_000, hammer(SyncCounter(), threads = 2, per = 5_000))
}

fun testAtomicCounter() {
    val ac = AtomicCounter()
    val ts = (1..4).map { Thread { repeat(10_000) { ac.bump() } } }
    ts.forEach { it.start() }; ts.forEach { it.join() }
    assertEquals(40_000, ac.value)
}

fun testKotlinAtomics() {
    val kc = KotlinAtomicCounter()
    val ts = (1..4).map { Thread { repeat(10_000) { kc.bump() } } }
    ts.forEach { it.start() }; ts.forEach { it.join() }
    assertEquals(40_000, kc.value)
    assertEquals(40_000, kc.fetchAndAdd(10))       // fetchAndAdd 返回旧值
    assertEquals(40_010, kc.value)
    assertTrue(kc.cas(40_010, 999))                // CAS 成功：现值与期望一致
    assertFalse(kc.cas(1, 2))                      // CAS 失败：期望对不上，不写
    assertEquals(999, kc.value)
}

fun testPoolWork() {
    assertEquals(listOf(1, 4, 9, 16, 25), poolWork())
}

fun testThreadLocal() {
    val tid = ThreadId()
    assertEquals("初始", tid.get())
    tid.set("主")
    assertEquals("主", tid.get())
    var seen = ""
    val t = Thread { seen = tid.get() }
    t.start(); t.join()
    assertEquals("初始", seen)            // 新线程拿的是自己的副本
    assertTrue(tid.get() == "主")          // 主线程副本不受影响
}

fun main() {
    testTwoWorkers()
    testSyncCounter()
    testAtomicCounter()
    testKotlinAtomics()
    testPoolWork()
    testThreadLocal()
    println("21_concurrency 全部测试通过")
}
```

头注三招在这里逐条回收：

1. **终值确定**：`testSyncCounter` 断言 40000 与 10000——锁保证终值与线程数、调度顺序无关；`testAtomicCounter` 与 `testKotlinAtomics` 各断言 40000，两种原子实现结论一致。注意第二组断言换了参数（2 线程 × 5000），证明确定性不是"恰好蒙对"。
2. **顺序确定**：`testTwoWorkers` 和 `testPoolWork` 断言的都是**排过序**的列表——字典序 `T1` 在 `T2` 前、平方数 `1, 4, 9, 16, 25`，和任务实际完成顺序无关。
3. **可见性确定**：`testThreadLocal` 里 `var seen` 由新线程写入、主线程读取。跨线程的普通变量读写本来是数据竞争（读到旧值也合法），但 `t.join()` 建立了 happens-before：join 返回后，新线程的写入对主线程**保证可见**。这一行测试能稳定通过，靠的不是运气，是 Java 内存模型的承诺。

`testKotlinAtomics` 还示范了 **CAS 的双向断言**：成功路径 `assertTrue(kc.cas(40_010, 999))` 与失败路径 `assertFalse(kc.cas(1, 2))` 都要测——只测成功等于没测"比较"这一步。`fetchAndAdd` 的返回值与加完后的现值分成两行断言（40000 / 40010），"返回旧值"的语义才被真正钉住。

ThreadLocal 的测试还埋了一组对称断言：新线程读到 `"初始"`（副本隔离）、主线程再读仍是 `"主"`（互不干扰）——两个方向都钉住，隔离性才算被测到。

main 跑通后打印 `21_concurrency 全部测试通过`，与 `expected.txt` 一起构成本章的完整验证链。

## 21.11 坑位清单

1. **`run()` 当 `start()` 用**：任务在当前线程同步执行，线程根本没开。线程只有 `start()` 一种启动方式。
2. **join 不可省**：没人 join 的线程在 JVM 开始关闭时被直接抛弃，结果丢失；同时 join 还是跨线程可见性的来源。
3. **@Volatile ≠ 线程安全计数**：只管可见性与有序，读-改-写照样丢更新。标志位用它，计数器别用。
4. **线程池忘记 `shutdown()`**：池线程是非守护线程，JVM 永不退出。`finally { shutdown() }` 或 `use {}`。
5. **`Future.get()` 无限期等**：任务挂死就永远阻塞，生产代码用 `get(3, TimeUnit.SECONDS)` 带超时。
6. **线程池里 ThreadLocal 串味**：线程复用导致上个任务的残留被下个任务读到——用完 `remove()`，最好放 finally。
7. **`Thread-N` 编号进快照**：N 是全局递增编号，每次运行可能不同。要打印线程名，先显式命名（`other.name = "demo-worker"`）；协程池线程名同理，只断言稳定前缀。
8. **suspend 函数里用 synchronized**：挂起点持锁 = 调度线程被锁死 = 其他协程饿死。协程世界用 Mutex/原子类。
9. **synchronizedList 不是万能**：它只保证单个方法原子，迭代、先查后加等复合操作仍需外部同步（本例在 join 之后才读，所以安全）。
10. **kotlin 原子类的扩展不 import 就用不了**：`incrementAndFetch`/`plusAssign`/`asJavaAtomic` 是包级扩展，漏一个就 unresolved；成员函数（`fetchAndAdd`/`compareAndSet`/`load`）反而不用。
11. **`@ExperimentalAtomicApi` 要 opt-in**：标在直接书写 API 的声明处（类/函数）；经封装转一手后调用方不用再标。纯 JVM 项目可以继续用 `java.util.concurrent.atomic`，多平台 common 代码才必须 `AtomicInt`。
12. **`fetchAndAdd` 返回旧值**：名字里的 fetch 是"取旧值"，与 `addAndGet` 语义相反——断言时把返回值与加完后的现值分两行写，别混。

---

上一章：[20 测试 ⭐](20-testing.md) · 下一章：[22 函数式](22-functional.md)
