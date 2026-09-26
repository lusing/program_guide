// 30 · 运算符与约定全景：plus 家族、rem/mod、Complex、BigDecimal 陷阱、get/set/invoke/iterator
import java.math.BigDecimal
import kotlin.math.sqrt

// ---- 30.4 复数 ----

data class Complex(val re: Double, val im: Double) {
    operator fun plus(o: Complex) = Complex(re + o.re, im + o.im)
    operator fun minus(o: Complex) = Complex(re - o.re, im - o.im)
    operator fun times(o: Complex) = Complex(re * o.re - im * o.im, re * o.im + im * o.re)
    operator fun unaryMinus() = Complex(-re, -im)
    val modulus: Double get() = sqrt(re * re + im * im)
    override fun toString(): String = if (im >= 0) "$re+${im}i" else "$re${im}i"
}

// ---- 30.6 约定五连 ----

class Matrix2(values: DoubleArray) {
    private val d = values.copyOf()
    operator fun get(r: Int, c: Int): Double = d[r * 2 + c]
    operator fun set(r: Int, c: Int, v: Double) { d[r * 2 + c] = v }
    operator fun contains(v: Double): Boolean = d.any { it == v }
    override fun toString(): String = "[${d.joinToString()}]"
}

class Greeter(val greeting: String) {
    operator fun invoke(name: String) = "$greeting, $name!"
}

class Countdown(val start: Int) {
    operator fun iterator() = object : IntIterator() {
        var cur = start
        override fun hasNext() = cur > 0
        override fun nextInt() = cur--
    }
}

fun main() {
    println("== 30.1/30.2 约定全景与不可重载 ==")
    println("a+b→plus | a+=b→plusAssign 或 plus 二选一（都有=歧义编译错）| in→contains（接收者反转）")
    println("a[i]→get/set（下标任意元） | a()→invoke | <..→compareTo | for→iterator/next/hasNext")
    println("不可重载: && || ?:(短路/空安全语义没法用函数保证), === !==(身份原语), =(赋值), ==(只能 override equals)")

    println("== 30.3 rem 与 mod ==")
    println("-7 % 4 = ${-7 % 4}（rem：符号随被除数，同 Java/C）")
    println("(-7).mod(4) = ${(-7).mod(4)}（mod：符号随除数，数学模）")
    println("7 % -4 = ${7 % -4} vs 7.mod(-4) = ${7.mod(-4)}")
    println("mod 不是 infix：'7 mod -4' 编译不过——只能写 7.mod(-4)；哈希桶/环形缓冲用 mod")

    println("== 30.4 复数四则 ==")
    val z1 = Complex(1.0, 2.0); val z2 = Complex(3.0, 4.0)
    println("z1+z2 = ${z1 + z2}, z1-z2 = ${z1 - z2}")
    println("z1*z2 = ${z1 * z2}（(1+2i)(3+4i) = -5+10i）")
    println("-z1 = ${-z1}, |z2| = ${"%.2f".format(z2.modulus)}")
    println("data class equals: (z1+z2)-z2 == z1 -> ${z1 + z2 - z2 == z1}")
    println("无全序不实现 Comparable——要按模排序用 sortedBy")

    println("== 30.5 BigDecimal ==")
    println("0.1 + 0.2 (Double)   = ${0.1 + 0.2}")
    println("0.1 + 0.2 (BigDecimal) = ${BigDecimal("0.1") + BigDecimal("0.2")}")
    val x = BigDecimal("2.0"); val y = BigDecimal("2.00")
    println("2.0 == 2.00 -> ${x == y}（equals 含 scale！）；x<y=${x < y}, x>y=${x > y}（compareTo 说相等）")
    println("x.compareTo(y) = ${x.compareTo(y)} —— 金额比较一律 compareTo")

    println("== 30.6 约定五连 ==")
    val m = Matrix2(doubleArrayOf(1.0, 2.0, 3.0, 4.0))
    println("m[0,1] = ${m[0, 1]}, m[1,0] = ${m[1, 0]}")
    m[0, 0] = 9.0
    println("m[0,0]=9.0 后 m = $m")
    println("2.0 in m -> ${2.0 in m}, 99.0 in m -> ${99.0 in m}")
    val hi = Greeter("你好")
    println("invoke: hi(\"Kotlin\") = ${hi("Kotlin")}")
    print("Countdown(3) for: "); for (i in Countdown(3)) print("$i "); println()
}
