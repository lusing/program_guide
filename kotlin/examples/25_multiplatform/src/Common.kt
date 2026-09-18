// 25 章共享代码：同一份逻辑编到 JS / Native / Wasm(WasmGC) 四个目标。
// 本文件不含任何平台 API——"common"源集的缩影。
// expect 声明在 common，actual 实现在各平台目录（js/ native/ wasm/）。

expect fun platformName(): String      // 平台标识（进快照：字面常量，确定性）
expect fun platformProbe(): String     // 平台探针（不进快照：环境相关，只验证形状）

/** 纯 Kotlin 算法一：矩阵乘法——三重循环 + 二维数组，任何目标都该算出同一结果。 */
fun matMul(a: Array<IntArray>, b: Array<IntArray>): Array<IntArray> {
    val n = a.size
    val m = b[0].size
    val k = b.size
    require(a[0].size == k) { "形状不合法：a 的列数 $k != b 的行数 ${a[0].size}" }
    val out = Array(n) { IntArray(m) }
    for (i in 0 until n) {
        for (j in 0 until m) {
            var acc = 0
            for (p in 0 until k) acc += a[i][p] * b[p][j]
            out[i][j] = acc
        }
    }
    return out
}

/** 纯 Kotlin 算法二：词频统计——列表管道 + 分组计数，检验各目标标准库行为一致。 */
fun wordFreq(text: String): List<Pair<String, Int>> =
    text.lowercase().split(Regex("[^a-z0-9']+")).filter { it.isNotBlank() }
        .groupBy { it }.map { it.key to it.value.size }
        .sortedWith(compareByDescending<Pair<String, Int>> { it.second }.thenBy { it.first })

/** 纯 Kotlin 算法三：迭代斐波那契——Long 溢出行为跨目标必须一致（JS 的 Long 是双 32 位拼的）。 */
fun fib(n: Int): Long {
    var a = 0L
    var b = 1L
    repeat(n) { val t = a + b; a = b; b = t }
    return a
}

/** 纯 Kotlin 算法四：FNV-1a 哈希——位运算跨目标一致性（JS 目标会把 Int 运算截到 32 位）。 */
fun fnv1a(data: String): UInt {
    var h = 0x811c9dc5u
    for (c in data) {
        h = h xor c.code.toUInt()
        h = h * 0x01000193u
    }
    return h
}

fun main() {
    println("== Kotlin Multiplatform Probe ==")
    println("platform : ${platformName()}")
    println("kotlin   : ${KotlinVersion.CURRENT}")

    // 共享算法：四目标必须逐字节一致的部分
    val a = arrayOf(intArrayOf(1, 2), intArrayOf(3, 4), intArrayOf(5, 6))
    val b = arrayOf(intArrayOf(7, 8, 9), intArrayOf(10, 11, 12))
    println("matMul   : ${matMul(a, b).joinToString("|") { it.joinToString(",") }}")

    val text = "the quick brown fox jumps over the lazy dog the end"
    println("wordFreq : " + wordFreq(text).take(4).joinToString(" ") { "${it.first}:${it.second}" })

    println("fib 90   : ${fib(90)}")
    println("fnv1a    : ${fnv1a("kotlin-multiplatform").toString(16)}")

    // 平台探针：环境相关（引擎版本/用户名），值不进快照——只断言非空，打印定性 ok
    val probe = platformProbe()
    check(probe.isNotBlank()) { "platformProbe 不能为空" }
    check(probe.length >= 8) { "探针值短得可疑：${probe.length} 字符" }
    println("probe    : ok (host-dependent, redacted)")

    // 自检断言 = 非 JVM 目标的"L2 测试层"：任何目标上失败都直接崩、exit != 0
    checkSelf()
    println("self-check: OK")
}

fun checkSelf() {
    check(matMul(a = arrayOf(intArrayOf(2, 0), intArrayOf(0, 2)), b = arrayOf(intArrayOf(1, 2), intArrayOf(3, 4)))
        .contentDeepEquals(arrayOf(intArrayOf(2, 4), intArrayOf(6, 8)))) { "matMul 单位阵乘法错" }
    check(wordFreq("a b a").first() == ("a" to 2)) { "wordFreq 排序错" }
    check(fib(10) == 55L) { "fib(10) 应为 55" }
    check(fib(90) == 2880067194370816120L) { "fib(90) Long 溢出前终值错——各目标必须一致" }
    check(fnv1a("") == 0x811c9dc5u) { "FNV offset basis 错" }
}
