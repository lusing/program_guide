// 03 · 变量、类型与控制流：val/var、数值类型、字符串、if/when 表达式、循环与标签

/** when 分支里用 2.1+ 的守卫条件（`in ... if ...`） */
fun describe(n: Int): String = when (n) {
    0 -> "零"
    1, 2, 3 -> "小"
    in 4..9 -> "中"
    else -> "大"
}

/** 无主体的 when：分支就是布尔表达式 */
fun sign(n: Int): String = when {
    n > 0 -> "正"
    n < 0 -> "负"
    else -> "零"
}

fun sumRange(from: Int, to: Int): Int {
    var s = 0
    for (i in from..to) s += i
    return s
}

/** 标签跳转：找到第一对和为 target 的组合就退出双层循环 */
fun firstPairSum(target: Int): String {
    for (i in 1..5) {
        for (j in 1..5) {
            if (i + j == target) return "($i, $j)"
        }
    }
    return "无"
}

fun main() {
    println("== 3.2 val 与 var ==")
    val pi = 3.14159            // 推断为 Double
    var counter = 0             // var 才能重新赋值
    counter++; counter++; counter++
    println("pi = $pi, counter = $counter")
    // pi = 3.14                // ← 编译错：val 不能重新赋值
    val list = mutableListOf(1) // val 锁的是"引用"，内容仍可变
    list.add(2)
    println("val 的 MutableList 仍可 add: $list")

    println("== 3.3 数值类型：无隐式加宽 ==")
    println("Int.MAX_VALUE = ${Int.MAX_VALUE}, Long.MAX_VALUE = ${Long.MAX_VALUE}")
    val million = 1_000_000     // 下划线分组
    println("1_000_000 = $million, 0xFF = ${0xFF}, 0b1010 = ${0b1010}")
    val a: Int = 100
    val b: Long = a.toLong()    // Int → Long 必须显式转换（没有隐式加宽！）
    val bytes: Byte = 42
    println("Int $a → Long $b；Byte $bytes → Int ${bytes.toInt()}")
    val x = 1_000_000_000_000   // 超出 Int 范围自动推断为 Long
    println("大整数字面量推断为 Long: $x")
    println("3 / 2 = ${3 / 2}, 3.0 / 2 = ${3.0 / 2}, 7 % 3 = ${7 % 3}")
    // println(a + bytes)       // ← 编译错：Int + Byte 不会自动提升

    println("== 3.4 字符与布尔 ==")
    val c: Char = 'K'
    println("'$c' 的码点 = ${c.code}, 'm' in 'a'..'z' = ${'m' in 'a'..'z'}")
    println("true && false = ${true && false}, !true = ${!true}")

    println("== 3.5 字符串 ==")
    val s = "Kotlin"
    println("长度 ${s.length}, 大写 ${s.uppercase()}, 前 3 个 ${s.take(3)}")
    val raw = """
        三引号原始字符串：
            缩进会被保留，
        trimIndent() 后对齐到最短行。""".trimIndent()
    println(raw)
    for (ch in "kot") print("$ch.")
    println()

    println("== 3.6 if 是表达式 ==")
    fun maxOf(x: Int, y: Int) = if (x > y) x else y
    println("maxOf(3, 9) = ${maxOf(3, 9)}")

    println("== 3.7 when 表达式 ==")
    println("describe(0) = ${describe(0)}, describe(2) = ${describe(2)}, describe(6) = ${describe(6)}, describe(99) = ${describe(99)}")
    println("sign(-7) = ${sign(-7)}, sign(0) = ${sign(0)}, sign(7) = ${sign(7)}")
    val anyVal: Any = "文本"
    val kind = when (anyVal) {               // when + is + 智能转换
        is Int -> "整数 ${anyVal + 1}"
        is String -> "字符串，长度 ${anyVal.length}"
        else -> "其他"
    }
    println("anyVal 的类型: $kind")

    println("== 3.8 循环与区间 ==")
    println("1..5 求和 = ${sumRange(1, 5)}")
    print("10 downTo 1 step 3: ")
    for (i in 10 downTo 1 step 3) print("$i ")
    println()
    print("0 until 3: ")
    for (i in 0 until 3) print("$i ")
    println()
    val map = mapOf("a" to 1, "b" to 2)
    for ((k, v) in map) println("map[$k] = $v")

    println("== 3.9 return 直接当标签用 ==")
    println("firstPairSum(7) = ${firstPairSum(7)}")
    outer@ for (i in 1..3) {
        for (j in 1..3) {
            if (i * j > 2) {
                println("首个乘积 > 2 的组合: ($i, $j) = ${i * j}")
                break@outer
            }
        }
    }
}
