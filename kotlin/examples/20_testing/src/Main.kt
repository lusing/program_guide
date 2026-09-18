// 20 · 测试演示：断言画廊、表驱动、边界、随机可复现
import kotlin.random.Random
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

fun main() {
    println("== 20.2 断言画廊 ==")
    assertEquals(4, 2 + 2, "普通相等（带失败消息）")
    assertTrue("kotlin".startsWith("kot"))
    assertContains(listOf(1, 2, 3), 2)
    assertContains("hello world", "wor")
    println("  assertEquals / assertTrue / assertContains / assertNull 全家——见 test/Tests.kt")
    val e = assertFailsWith<IllegalArgumentException> { grade(101) }
    println("  assertFailsWith: ${e.message}")

    println("== 20.3 表驱动 ==")
    val table = listOf(
        1 to "1", 3 to "Fizz", 5 to "Buzz", 15 to "FizzBuzz", 98 to "98",
    )
    for ((input, want) in table) {
        assertEquals(want, fizzbuzz(input), "fizzbuzz($input)")
        println("  fizzbuzz($input) = $want ✓")
    }

    println("== 20.4 边界值 ==")
    // grade 的四个边界：59/60 79/80 89/90 以及两端 0/100
    for ((s, g) in listOf(0 to 'D', 59 to 'D', 60 to 'C', 79 to 'C', 80 to 'B', 89 to 'B', 90 to 'A', 100 to 'A')) {
        assertEquals(g, grade(s), "grade($s)")
        println("  grade($s) = $g ✓")
    }

    println("== 20.5 固定种子的『随机』 ==")
    val rng = Random(42)
    val rolls = List(5) { rollDie(rng) }
    println("  Random(42) 的 5 次掷骰: $rolls（每次运行都一样——可复现测试）")
    val again = Random(42)                        // 同种子的新实例 → 同序列
    assertEquals(rolls, List(5) { rollDie(again) }, "同种子同序列")

    println("== 20.6 行为验证：用假实现观察副作用 ==")
    val store = InMemoryStore()
    val id1 = store.add("写教程")
    val id2 = store.add("改示例")
    store.complete(id1)
    println("  all() = ${store.all()}")
    assertEquals(listOf(true, false), store.all().map { it.done })
    assertEquals(false, store.complete(99), "完成不存在的 id 返回 false")
    println("  complete(99) = false ✓")
}
