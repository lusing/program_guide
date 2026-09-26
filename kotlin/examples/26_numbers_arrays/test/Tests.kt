// 26 的测试：转换、溢出、装箱身份、原语数组、无符号
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

fun testConversions() {
    assertEquals(1, 257.toByte())
    assertEquals(1000, 1000.toShort())
    assertEquals('A', 65.toChar())
    assertEquals(65, 'A'.code)
    assertEquals(42L, 42.toLong())
    assertEquals(3, 3.9.toInt())
    assertEquals("ff", 255.toString(16))
    assertEquals(255, "ff".toInt(16))
    assertEquals(10, "1010".toInt(2))
}

fun testOverflowAndBits() {
    val max = Int.MAX_VALUE
    assertEquals(Int.MIN_VALUE, max + 1)          // 回绕
    assertEquals(1024, 1 shl 10)
    assertEquals(-4, (-8) shr 1)
    assertEquals(0x7FFFFFFC, (-8) ushr 1)
    assertEquals(15, 0xFF and 0x0F)
    assertEquals(-1, 0.inv())
    // 017 编译不过（前导零禁止）——不放进测试，见 Main 输出说明
}

fun testBoxingIdentity() {
    val a: Int? = 1000; val b: Int? = 1000
    assertEquals(1000, a!!); assertTrue(a == b)    // == 恒安全
    assertFalse((a as Any) === (b as Any))         // 缓存外不同盒（HotSpot 默认，JLS 允许缓存更多）
    val x: Int? = 100; val y: Int? = 100
    assertTrue((x as Any) === (y as Any))          // JLS 强制缓存 -128..127
    assertTrue(box(1000) == box(1000))
}

fun testArrays() {
    assertEquals(listOf(0, 1, 4, 9, 16), Array(5) { it * it }.toList())
    assertEquals(12, intArrayOf(2, 4, 6).sum())
    assertEquals(listOf(2, 4, 6), arrayOf(2, 4, 6).toIntArray().toList())
    assertEquals(listOf(2, 4, 6), intArrayOf(2, 4, 6).toTypedArray().toList())
    assertEquals(3, arrayOfNulls<String>(3).size)
    assertTrue(null in arrayOfNulls<String>(1).toList())
}

@OptIn(ExperimentalUnsignedTypes::class)   // uintArrayOf 仍标实验（类型本身已转正）
fun testUnsigned() {
    assertEquals(255u, 255u)
    assertEquals("ff", 255u.toString(16))
    assertEquals(4294967295u, UInt.MAX_VALUE)
    assertEquals(16u, 1u shl 4)
    assertEquals(15u, 255u and 0x0Fu)
    assertEquals(listOf(1u, 2u, 3u), uintArrayOf(3u, 1u, 2u).sorted())
    assertEquals(4_000_000_000u, 4_000_000_000u)   // Int 放不下，UInt 放得下
}

fun testBenchmarkSums() {
    val n = 1_000_000
    val raw = IntArray(n) { it }
    val boxed = Array(n) { it }
    assertEquals(raw.sum(), boxed.sum())           // 结果恒等（性能结论见 Main）
}

fun main() {
    testConversions()
    testOverflowAndBits()
    testBoxingIdentity()
    testArrays()
    testUnsigned()
    testBenchmarkSums()
    println("26_numbers_arrays 全部测试通过")
}
