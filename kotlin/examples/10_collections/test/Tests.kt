// 10 的测试：集合操作行为（含排序陷阱、fold/reduce 边界）
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

fun testWordCount() {
    assertEquals(mapOf("a" to 2, "b" to 1), wordCount("A b a"))
    assertEquals(emptyMap(), wordCount(" !!! "))
}

fun testGroupByGrade() {
    val g = groupByGrade(listOf("张三" to 90, "李四" to 50))
    assertEquals(listOf("张三"), g['P'])
    assertEquals(listOf("李四"), g['F'])
}

fun testAdultsIn() {
    val people = listOf(
        Person("Alice", 30, "北京"), Person("Bob", 17, "北京"),
        Person("Carol", 25, "北京"), Person("Dave", 41, "深圳"),
    )
    assertEquals("Alice(30)、Carol(25)", adultsIn(people, "北京"))
    assertEquals("", adultsIn(people, "南京"))
}

fun testChecksum() {
    // 手算验证: (1*31+1)=32 → (32*31+2)=994 → (994*31+3)=30817
    assertEquals(30817, checksum(listOf(1, 2, 3)))
    assertEquals(1, checksum(emptyList()))          // fold 有初值，空集合安全
    // reduce 无初值：空集合抛 UnsupportedOperationException
    assertFailsWith<UnsupportedOperationException> { emptyList<Int>().reduce { a, b -> a + b } }
}

fun testZipChunk() {
    assertEquals(listOf(11, 22, 33), zipSums(listOf(1, 2, 3), listOf(10, 20, 30)))
    assertEquals(listOf(1), zipSums(listOf(1, 2, 3), listOf(0)))    // zip 按短的截断
    assertEquals(listOf(listOf(0, 1), listOf(2, 3), listOf(4, 5)), (0..5).toList().chunked(2))
}

fun testSortTrap() {
    assertEquals("src=[3, 1, 2], copy=[1, 2, 3]", sortDemo())   // sorted 不动原列表
}

fun testSetOps() {
    assertEquals(setOf(1, 2, 3, 4), setOf(1, 2, 3) + setOf(3, 4))
    assertEquals(setOf(3), setOf(1, 2, 3) intersect setOf(3, 4))
    assertEquals(setOf(1, 2), setOf(1, 2, 3) - setOf(3, 4))
    assertTrue(listOf(1, 2, 2, 3).distinct() == listOf(1, 2, 3))
}

fun testMapOps() {
    val m = mutableMapOf("a" to 1)
    assertEquals(3, m.getOrPut("c") { 3 })
    assertEquals(3, m["c"])
    assertEquals(mapOf("a" to 10), mapOf("a" to 1).mapValues { it.value * 10 })
}

fun main() {
    testWordCount()
    testGroupByGrade()
    testAdultsIn()
    testChecksum()
    testZipChunk()
    testSortTrap()
    testSetOps()
    testMapOps()
    println("10_collections 全部测试通过")
}
