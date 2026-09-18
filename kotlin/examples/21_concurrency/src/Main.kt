// 21 · 并发与线程：JVM 的线程模型、锁、原子类、线程池、与协程的关系
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withContext

fun main() {
    println("== 21.2 Thread 的创建与汇合 ==")
    println("  当前线程: ${Thread.currentThread().name}")
    for (r in twoWorkers()) println("  $r")

    println("== 21.3 synchronized：互斥 ==")
    val sc = SyncCounter()
    val hits = hammer(sc)
    println("  4 线程 × 10000 次 @Synchronized bump = $hits（终值恒定）")
    // @Volatile 只保证可见性与顺序，不保证读改写原子——计数场景它救不了你

    println("== 21.4 原子类 CAS ==")
    val ac = AtomicCounter()
    val ts = (1..4).map { Thread { repeat(10_000) { ac.bump() } } }
    ts.forEach { it.start() }; ts.forEach { it.join() }
    println("  AtomicInteger 40000 次自增 = ${ac.value}")

    println("== 21.5 线程池：别裸起线程 ==")
    println("  3 线程池跑 5 个任务（平方排序）= ${poolWork()}")
    println("  poolWork 的 finally 里 shutdown——池要用完就还，长期池交给框架管")

    println("== 21.6 ThreadLocal：每线程一个副本 ==")
    val tid = ThreadId()
    println("  主线程默认值: ${tid.describe()}")
    tid.set("主线程的值")
    println("  设置后: ${tid.describe()}")
    val other = Thread { println("  （新线程）${tid.describe()}") }
    other.name = "demo-worker"              // 显式命名：JVM 默认的 Thread-N 编号不稳定
    other.start(); other.join()
    println("  新线程看到的还是自己的初始值——副本隔离")

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

    println("== 21.8 选型速查 ==")
    println("  阻塞 IO/长寿任务 → 线程池 | 高并发等待 → 协程 | 共享计数 → 原子类 | 复合临界区 → Mutex/锁")
}
