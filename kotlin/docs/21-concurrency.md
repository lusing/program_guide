# 21 · 并发与线程

> 对应示例：`examples/21_concurrency/`（Thread、synchronized、原子类、线程池、ThreadLocal）
>
> JVM 的线程模型是协程的地基：理解"线程是资源、协程是调度单位"，
> 才知道 14 章的挂起为什么"便宜"。

## 21.1 线程的创建与汇合

```kotlin
val results = java.util.Collections.synchronizedList(mutableListOf<String>())
val t1 = Thread { results += "T1:${(1..100).sum()}" }   // 裸线程
val t2 = Thread { results += "..." }
t1.start(); t2.start()
t1.join(); t2.join()                                     // 等两个都结束
```

`Thread { lambda }`：构造即给任务（lambda 是 `Runnable` SAM）。`join()` 等线程结束——**不 join 的线程叫"失联线程"**，进程退出前它可能还没跑完。

多线程写共享集合必须用**线程安全容器**（synchronizedList）——普通 MutableList 并发写会 ConcurrentModificationException 甚至数据损坏。

## 21.2 竞态：读-改-写不是原子的

```kotlin
var hits = 0
4 个线程各 10000 次 hits++      // 结果 ≤ 40000，几乎必然丢更新
```

`hits++` 是三步（读/加/写），两线程交错就互相覆盖。15 章用协程 + yield 让这个交错**确定可见**（结果恒 100）。修复按成本排序：

```kotlin
// 1) 锁：临界区互斥
class SyncCounter {
    @Synchronized fun bump() { hits++ }      // 方法级 synchronized(this)
}
// 2) CAS 原子类：无锁
val n = AtomicInteger(); n.incrementAndGet()
// 3) 不共享：每线程局部累计，最后合并（fork-join 思路）
```

**@Volatile 的真相**：只保证可见性（一个线程写立刻对别线程可见）与指令顺序，**不保证复合操作原子**——计数场景 @Volatile 救不了。它是"一写多读"的标志位场景工具。

Kotlin 的 `@Synchronized`/`@Volatile` 注解编译成 JVM 的对应关键字/修饰符；同步块写法 `synchronized(lock) { ... }` 是标准库函数。

## 21.3 synchronized vs Mutex（15 章）

| | synchronized / 锁 | Mutex（协程） |
|---|---|---|
| 等待方式 | 阻塞线程 | 挂起协程（线程释放） |
| 可重入 | ✓（同线程可重进） | ✘（同协程二次 lock = 死锁） |
| 场景 | 阻塞世界、JVM API | 协程世界 |

规则：**suspend 函数里永远用 Mutex/原子类**，别用 synchronized（把调度线程锁死 = 协程优势归零）。

## 21.4 线程池：别裸起线程

```kotlin
val pool = java.util.concurrent.Executors.newFixedThreadPool(3)
try {
    val futures = (1..5).map { i -> pool.submit<Int> { i * i } }
    val sorted = futures.map { it.get() }.sorted()      // Future.get() 阻塞收账
} finally {
    pool.shutdown()                                      // 用完必还
}
```

线程是昂贵资源（~1MB 栈 + 内核调度实体）——池化复用。`ExecutorService` 家族：`newFixedThreadPool`（定长）/`newCachedThreadPool`（弹性）/`newVirtualThreadPerTaskExecutor`（JDK 21+ 虚拟线程，21.7）。

Kotlin 协程的 `Dispatchers.IO` 底层就是一个弹性线程池——**协程世界你几乎不直接碰 ExecutorService**，知道它的存在是为了看懂旧代码。

## 21.5 ThreadLocal：每线程一个副本

```kotlin
class ThreadId {
    private val local = ThreadLocal.withInitial { "初始" }
    fun describe() = "线程 ${Thread.currentThread().name} 看到 ${local.get()}"
}
// 主线程 set("主") 后，新线程看到的仍是自己的"初始" —— 副本隔离
```

用途：traceId、事务上下文、SimpleDateFormat 缓存。坑：**线程池里 ThreadLocal 会串**（线程复用，上个任务的残留还在）——用完要 `remove()`。协程世界对应物是 `ThreadContextElement`（coroutineContext 的一部分），协程切换线程不带 ThreadLocal——上下文请放 coroutineContext。

## 21.6 协程与线程：M:N

```kotlin
withContext(Dispatchers.Default) {
    // 运行在 DefaultDispatcher-worker-N —— 具体哪根每次可能不同
}
```

- N 个协程跑在 M 个池线程上（M = CPU 核数或 IO 池更大）。
- **阻塞调用（JDBC/OkHttp 同步）会占住一根调度线程**——用 `Dispatchers.IO` 包裹（15 章 flowOn/withContext）。
- 100k 协程 ≈ 100k 对象；100k 线程 = 先 OOM。这就是"并发单位降维"。

## 21.7 虚拟线程一瞥（JDK 21+）

```java
Executors.newVirtualThreadPerTaskExecutor()   // 每任务一虚拟线程，JVM 挂载到载体线程
```

Java 21 的虚拟线程与协程解决同一问题（阻塞式代码的高并发），路线不同：**虚拟线程 = 让阻塞代码自动变"便宜"；协程 = 显式挂起 + 结构化并发**。Kotlin 代码跑在 JVM 21 上两者可混用，但 Kotlin 社区主线是协程（结构化、可取消、Flow 生态）。

## 21.8 选型速查

| 需求 | 选择 |
|---|---|
| 高并发等待型（网络 IO） | 协程 + Dispatchers.IO |
| CPU 密集并行计算 | 协程 + Dispatchers.Default / 线程池 |
| 简单计数 | 原子类 |
| 复合临界区（多变量一致） | Mutex（协程）/ synchronized（阻塞） |
| 阻塞库调用 | withContext(Dispatchers.IO) 包住 |
| 一写多读标志 | @Volatile |
| 请求级上下文（traceId） | 协程: coroutineContext / 阻塞: ThreadLocal |

## 21.9 坑位清单

1. **join 不可省**——不等待的线程在 JVM 退出时直接死，结果丢失。
2. **@Volatile 不等于线程安全计数**——只管可见性；`++` 照样丢更新。
3. **线程池忘记 shutdown** → 线程泄漏、JVM 不退出；`finally { shutdown() }` 是肌肉记忆。
4. **Future.get() 无限等**——生产代码带超时 `get(3, TimeUnit.SECONDS)`。
5. 线程池 + ThreadLocal = 残留串味——finally 里 remove。
6. 线程名（Thread-N）带全局编号——**输出进测试快照前必须显式命名**（本教程 21 章示例实测：Thread-10 每次运行不同，命名后稳定）。
7. suspend 函数里禁止 synchronized 阻塞——挂起点持锁 = 其他协程饿死；换 Mutex。
