// 26 · 数值与数组：无隐式加宽、溢出回绕、装箱身份、原语数组、无符号、装箱微基准

/** 运行期装箱（模拟从外部拿进来的可空 Int） */
fun box(v: Int): Int? = v

fun main() {
    println("== 26.1 无隐式加宽与转换函数族 ==")
    val i: Int = 42
    val l: Long = i.toLong()
    println("42.toLong() = $l, 3.9.toInt() = ${3.9.toInt()}, 257.toByte() = ${257.toByte()}")
    println("65.toChar() = ${65.toChar()}, 'A'.code = ${'A'.code}")
    println("255.toString(16) = ${255.toString(16)}, \"ff\".toInt(16) = ${"ff".toInt(16)}")
    println("\"1010\".toInt(2) = ${"1010".toInt(2)}")

    println("== 26.2 字面值、边界与位运算 ==")
    val dec = 1_000_000; val hex = 0xFF; val bin = 0b1010
    println("dec=$dec, hex=$hex, bin=$bin, L=${1_000_000_000_000L}")
    println("017 编译不过（leading zeros are not allowed）——八进制陷阱堵死在源头")
    val max = Int.MAX_VALUE
    println("max+1 = ${max + 1}（静默回绕；常量表达式才编译期报错）")
    println("1 shl 10 = ${1 shl 10}, (-8) shr 1 = ${(-8) shr 1}, (-8) ushr 1 = ${(-8) ushr 1}")
    println("0xFF and 0x0F = ${0xFF and 0x0F}, 0xF0 xor 0xFF = ${0xF0 xor 0xFF}, 0.inv() = ${0.inv()}")
    println("'A'+1 要写 ('A'.code + 1).toChar() = ${('A'.code + 1).toChar()}（Char 不是数字）")

    println("== 26.3 装箱身份：Integer 缓存陷阱 ==")
    val x: Int? = 100; val y: Int? = 100
    val a: Int? = 1000; val b: Int? = 1000
    println("== 恒安全: 1000==1000 -> ${a == b}")
    println("(100 as Any) === (100 as Any) -> ${(x as Any) === (y as Any)}（缓存内，同一对象）")
    println("(1000 as Any) === (1000 as Any) -> ${(a as Any) === (b as Any)}（缓存外，各装各的）")
    println("运行期装箱同样: box(100)=${(box(100) as Any) === (box(100) as Any)}, box(1000)=${(box(1000) as Any) === (box(1000) as Any)}")
    println("K2 直接禁止 a === b（装箱身份比较）——编译器替你踩坑")

    println("== 26.4 数组三件套与原语数组 ==")
    val refs = arrayOf(1, 2, 3)
    val nulls = arrayOfNulls<String>(3)
    val sq = Array(5) { it * it }
    println("arrayOf=${refs.joinToString()}, arrayOfNulls=${nulls.joinToString { it ?: "null" }}")
    println("Array(5){it*it} = ${sq.joinToString()}（it 是下标）")
    val ia = intArrayOf(2, 4, 6)
    val ib = IntArray(5) { it * 2 }
    println("intArrayOf=${ia.joinToString()}, IntArray(5){it*2}=${ib.joinToString()}, ia.sum()=${ia.sum()}")
    println("互转: ${ia.toTypedArray().joinToString()} / ${arrayOf(2, 4, 6).toIntArray().joinToString()}")
    println("无继承: Array<Int> 与 IntArray 互不相关，只能显式互转")

    println("== 26.5 无符号家族 ==")
    val u: UInt = 255u
    val bigU = 4_000_000_000u
    println("255u.toString(16) = ${u.toString(16)}, 4_000_000_000u = $bigU（Int 放不下）")
    println("UInt.MAX_VALUE = ${UInt.MAX_VALUE}, 1u shl 4 = ${1u shl 4}, 255u and 0x0Fu = ${255u and 0x0Fu}")
    println("uintArrayOf/sorted 等部分 API 仍标实验（类型已转正）——要用得 @OptIn(ExperimentalUnsignedTypes)")
    println("排序改用稳定区: listOf(3u, 1u, 2u).sorted() = ${listOf(3u, 1u, 2u).sorted()}")

    println("== 26.6 装箱开销微基准 ==")
    val n = 10_000_000
    val raw = IntArray(n) { it }
    val boxed = Array(n) { it }
    val rounds = 3
    var bestRaw = Long.MAX_VALUE; var bestBoxed = Long.MAX_VALUE
    for (r in 0 until rounds) {
        val t0 = System.nanoTime()
        val s1 = raw.sum()
        val t1 = System.nanoTime()
        val s2 = boxed.sum()
        val t2 = System.nanoTime()
        check(s1 == s2)   // 结果必须恒等
        bestRaw = minOf(bestRaw, t1 - t0)
        bestBoxed = minOf(bestBoxed, t2 - t1)
    }
    check(bestRaw <= bestBoxed)   // 方向性结论：原语数组不慢于装箱版
    println("n=$n, ${rounds}轮取最优: 两种数组总和一致；IntArray 不慢于装箱版（实测显著更快，倍率随机器漂移已隐去）")
    println("内存: int 4 字节 vs Integer 盒子 16 字节——热路径数值集合选原语数组")
}
