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

fun main() {
    testTwoWorkers()
    testSyncCounter()
    testAtomicCounter()
    testKotlinAtomics()
    testPoolWork()
    testThreadLocal()
    println("21_concurrency 全部测试通过")
}
