// 13 · 扩展：扩展函数、扩展属性、静态解析、可空接收者、伴生对象扩展

/** 扩展函数：给已有类型"外挂"新方法——不改源码、无继承 */
fun String.initials(): String =
    split(Regex("\\s+")).filter { it.isNotBlank() }.joinToString("") { it.take(1).uppercase() + "." }

fun String.toSlug(): String = trim().lowercase().replace(Regex("\\s+"), "-")

fun Int.timesRepeat(s: String): String = s.repeat(this)

/** 扩展属性：没有 backing field，必须现算 */
val String.shoutLen: Int get() = length + 1
val <T> List<T>.secondOrNullExt: T? get() = getOrNull(1)

/** 可空接收者：接收者本身就是 String? —— 04 章空安全 × 扩展 */
fun String?.orDash(): String = this ?: "—"

/** 泛型扩展：对所有 List 生效 */
fun <T> List<T>.interspersed(sep: String): String = joinToString(sep)

/** 伴生对象扩展：给"类的静态侧"挂函数（工厂 ofYuan 在类内，ofCents 在类外） */
class Money(val cents: Long) {
    companion object { fun ofYuan(y: Long) = Money(y * 100) }
}
fun Money.Companion.ofCents(c: Long): Money = Money(c)

/** 成员与扩展同名：成员优先（编译器会警告 EXTENSION_SHADOWED_BY_MEMBER——这里故意演示） */
class Doc(val title: String) {
    fun render() = "成员渲染: $title"
}
@Suppress("EXTENSION_SHADOWED_BY_MEMBER")   // 教学演示专用；真实代码里这就是"删掉扩展"的信号
fun Doc.render() = "扩展渲染: ${title.uppercase()}"

/** 扩展是静态解析的关键证据：调用哪个扩展看"声明的类型"，不看运行时类型 */
open class Animal2 { open fun who() = "Animal2" }
class Dog2 : Animal2() { override fun who() = "Dog2" }
fun Animal2.tag() = "[A]"
fun Dog2.tag() = "[D]"

fun main() {
    println("== 13.2 扩展函数 ==")
    println("\"Ada Lovelace Byron\".initials() = ${"Ada Lovelace Byron".initials()}")
    println("\"  Kotlin 编程 指南 \".toSlug() = '${"  Kotlin 编程 指南 ".toSlug()}'")
    println("3.timesRepeat(\"哈\") = ${3.timesRepeat("哈")}")

    println("== 13.3 扩展属性 ==")
    println("\"hey!\".shoutLen = ${"hey!".shoutLen}")
    println("listOf(1,2,3).secondOrNullExt = ${listOf(1, 2, 3).secondOrNullExt}")
    println("listOf(1).secondOrNullExt = ${listOf(1).secondOrNullExt}")

    println("== 13.4 可空接收者 ==")
    val s: String? = null
    println("null.orDash() = ${s.orDash()}")
    println("\"有值\".orDash() = ${"有值".orDash()}")

    println("== 13.5 泛型扩展 ==")
    println("interspersed = ${listOf("a", "b", "c").interspersed(" · ")}")

    println("== 13.6 伴生对象扩展 ==")
    val m1 = Money.ofYuan(3)
    val m2 = Money.Companion.ofCents(250)   // 也能写 Money.ofCents(250)
    println("ofYuan(3) → ${m1.cents} 分；ofCents(250) → ${m2.cents} 分")

    println("== 13.7 成员优先于扩展 ==")
    println(Doc("t").render())       // 成员渲染胜出；要调扩展得用全限定名

    println("== 13.8 静态解析：扩展不分发 ==")
    val a: Animal2 = Dog2()
    println("a.who() = ${a.who()}        // 虚方法：运行时类型 Dog2")
    println("a.tag() = ${a.tag()}        // 扩展：编译期类型 Animal2 决定 [A]")

    println("== 13.9 标准库本身就是扩展大展 ==")
    // let/run/also/apply、String.toIntOrNull、各种集合管道——全是扩展函数
    println("\"42\".toIntOrNull() = ${"42".toIntOrNull()}  ← String 的扩展")
    println("listOf(1,2).map{it+1} = ${listOf(1, 2).map { it + 1 }}  ← Iterable 的扩展")
}
