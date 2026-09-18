// 21 · 并发与线程：Thread、synchronized、原子类、线程池、ThreadLocal、与协程的关系
// 输出确定性策略：并行结果"先收集再排序"，竞态用单线程协程模拟，计数用锁/原子保证终值

/** 两个线程各干各的，join 后汇总（结果排序 → 输出确定） */
fun twoWorkers(): List<String> {
    val results = java.util.Collections.synchronizedList(mutableListOf<String>())
    val t1 = Thread { results += "T1:1..100 求和=${(1..100).sum()}" }
    val t2 = Thread { results += "T2:a..z 共 ${('a'..'z').count()} 个字符" }
    t1.start(); t2.start()
    t1.join(); t2.join()
    return results.sorted()
}

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

/** 原子类：CAS 无锁原子 */
class AtomicCounter {
    private val n = java.util.concurrent.atomic.AtomicInteger()
    fun bump() { n.incrementAndGet() }
    val value: Int get() = n.get()
}

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

/** ThreadLocal：每线程一份副本 */
class ThreadId {
    private val local = ThreadLocal.withInitial { "初始" }
    fun set(v: String) { local.set(v) }
    fun get(): String = local.get()!!
    fun describe(): String = "线程 ${Thread.currentThread().name} 看到 ${local.get()}"
}
