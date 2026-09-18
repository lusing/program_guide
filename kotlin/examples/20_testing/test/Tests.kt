// 20 的测试：领域逻辑 + 表驱动 + 边界 + 异常 + 可复现随机
import kotlin.random.Random
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

fun testStoreBasics() {
    val s = InMemoryStore()
    val id = s.add("任务")
    assertEquals(1, id)
    assertEquals(1, s.all().size)
    assertEquals(Task2(1, "任务"), s.all().first())
}

fun testStoreComplete() {
    val s = InMemoryStore()
    val a = s.add("A"); s.add("B")
    assertTrue(s.complete(a))
    assertFalse(s.complete(999))
    assertEquals(listOf(true, false), s.all().map { it.done })
}

fun testStoreValidation() {
    assertFailsWith<IllegalArgumentException> { InMemoryStore().add("   ") }
}

fun testFizzbuzzTable() {
    val table = mapOf(1 to "1", 3 to "Fizz", 5 to "Buzz", 7 to "7", 10 to "Buzz", 15 to "FizzBuzz", 30 to "FizzBuzz")
    for ((n, want) in table) assertEquals(want, fizzbuzz(n), "n=$n")
}

fun testGradeBoundaries() {
    // 等价类划分 + 边界：D:0-59 C:60-79 B:80-89 A:90-100
    for ((s, g) in listOf(0 to 'D', 59 to 'D', 60 to 'C', 79 to 'C', 80 to 'B', 89 to 'B', 90 to 'A', 100 to 'A')) {
        assertEquals(g, grade(s), "score=$s")
    }
    assertFailsWith<IllegalArgumentException> { grade(-1) }
    assertFailsWith<IllegalArgumentException> { grade(101) }
}

fun testSeededRandom() {
    val r1 = List(10) { rollDie(Random(42)) }
    val r2 = List(10) { rollDie(Random(42)) }
    assertEquals(r1, r2)                       // 同种子 → 同序列
    assertContains(1..6, r1.first())           // 值域内
    assertTrue(r1.all { it in 1..6 })
}

fun testAssertGallery() {
    assertNull(null)
    assertEquals(1.0 / 3.0 + 1.0 / 3.0 + 1.0 / 3.0, 1.0, 1e-9)   // 浮点用误差容限
    val names = listOf("ada", "bob")
    assertContains(names, "ada")
}

fun main() {
    testStoreBasics()
    testStoreComplete()
    testStoreValidation()
    testFizzbuzzTable()
    testGradeBoundaries()
    testSeededRandom()
    testAssertGallery()
    println("20_testing 全部测试通过")
}
