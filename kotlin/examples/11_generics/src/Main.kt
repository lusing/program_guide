// 11 · 泛型：型变（out/in）、星投影、约束、reified 与类型擦除

/** 简单泛型容器 */
class Box<T>(private val item: T) {
    fun get(): T = item
    override fun toString() = "Box($item)"
}

/** out 协变：只生产 T（只出现在"返回值"位置）→ Box<Cat> 可当 Box<Animal> 用 */
interface Producer<out T> { fun produce(): T }

/** in 逆变：只消费 T（只出现在"参数"位置）→ Comparator<Animal> 可当 Comparator<Cat> 用 */
interface Consumer<in T> { fun consume(x: T) }

open class Animal { open fun sound() = "..." }
class Cat : Animal() { override fun sound() = "喵" }
class Dog : Animal() { override fun sound() = "汪" }

class CatFarm(private val cat: Cat) : Producer<Cat> {
    override fun produce(): Cat = cat
}

class AnyConsumer : Consumer<Animal> {
    var last: String = "（空）"
    override fun consume(x: Animal) { last = x.sound() }
}

/** 多重约束：where 子句——T 既有 length 又能互相比较 */
fun <T> longerOf(a: T, b: T): T where T : CharSequence, T : Comparable<T> =
    if (a.length >= b.length) a else b

/** 泛型函数 + 上界约束 */
fun <T : Comparable<T>> maxOf3(a: T, b: T, c: T): T = maxOf(a, maxOf(b, c))

/** 泛型 + 默认类型参数（与接口/委托组合的常见姿势见 09） */
class Repo<T : Any>(private val initial: List<T> = emptyList()) {
    private val items = initial.toMutableList()
    fun add(x: T) = items.add(x)
    fun all(): List<T> = items.toList()
    fun <R> map(f: (T) -> R): List<R> = items.map(f)
}

/** reified：inline 才能保留类型实参，做运行时过滤不需要传 Class 对象 */
inline fun <reified T> List<Any>.pick(): List<T> = filterIsInstance<T>()

/** out 类里的 private 成员不受型变位置限制——内部可变、外部只读（协变与可变性的和解） */
class Refillable<out T>(private var current: T, private val next: (T) -> T) {
    fun get(): T = current
    fun advance(): T { current = next(current); return current }
    // fun set(v: T) { current = v }   // ✗ 公开消费位：out 违例编译错（文档 11.10）
}

/** 同名重载擦除后 JVM 签名相同 → platform declaration clash 编译错；@JvmName 区分后共存 */
@JvmName("sumInts")
fun sum(xs: List<Int>): Int = xs.sum()
@JvmName("sumStrs")
fun sum(xs: List<String>): String = xs.joinToString("-")

/** 旧式"吃 Class<T>"的 API（Gson.fromJson 同形状） */
@Suppress("UNCHECKED_CAST")
fun <T : Any> parseOf(raw: String, cls: Class<T>): T? = when (cls) {
    Int::class.javaObjectType -> raw.toIntOrNull()
    Long::class.javaObjectType -> raw.toLongOrNull()
    String::class.javaObjectType -> raw.trim('"')
    else -> null
} as T?

/** reified 工程化：包装成无参泛型扩展——调用方再也不传 Class */
inline fun <reified T : Any> String.parseAs(): T? = parseOf(this, T::class.javaObjectType)

inline fun <reified T> Any?.isA(): Boolean = this is T

fun main() {
    println("== 11.2 泛型类与泛型函数 ==")
    println(Box(42)); println(Box("文本"))
    println("maxOf3(1,5,3) = ${maxOf3(1, 5, 3)}, maxOf3('b','a','c') = ${maxOf3('b', 'a', 'c')}")
    // val b: Box<Int> = Box(1L)   // ← 编译错：类型实参必须严格匹配

    println("== 11.3 型变：Java 数组协变之坑 vs Kotlin List ==")
    val ints = arrayOf(1, 2, 3)
    // Java: Object[] o = ints; o[0] = "x"; → ArrayStoreException（数组运行时记得元素类型）
    // Kotlin 的 Array<Int> 不允许赋给 Array<Any>，但 List<out E> 声明处协变：
    val animals: List<Animal> = listOf(Cat(), Dog())   // List<Cat>/List<Dog> 都是 List<Animal>
    println("协变读取: ${animals.map { it.sound() }}")
    val p: Producer<Animal> = CatFarm(Cat())           // out：Producer<Cat> → Producer<Animal>
    println("Producer<Animal>.produce().sound() = ${p.produce().sound()}")
    val ac = AnyConsumer()
    val c: Consumer<Cat> = ac                          // in：Consumer<Animal> → Consumer<Cat>
    c.consume(Cat())
    println("逆变消费后 last = ${ac.last}")

    println("== 11.4 星投影：类型实参未知时仍能安全使用 ==")
    val unknown: List<*> = listOf(1, "二", 3.0)
    println("List<*> 大小 = ${unknown.size}（能读出 Any?）")
    val first: Any? = unknown.first()
    println("第一个元素 = $first")
    fun printSize(xs: List<*>) = println("printSize: 共 ${xs.size} 个元素")
    printSize(unknown)

    println("== 11.5 约束与 where ==")
    println("longerOf(\"abc\", \"xy\") = ${longerOf("abc", "xy")}   // String 同时满足两个约束")
    println("longerOf(\"ab\", \"xyz\") = ${longerOf("ab", "xyz")}")
    val repo = Repo(listOf(1, 2))
    repo.add(3)
    println("Repo.all() = ${repo.all()}, map翻倍 = ${repo.map { it * 2 }}")

    println("== 11.6 reified：把泛型实参带进运行时 ==")
    val mixed: List<Any> = listOf(1, "a", 2, "b", 3.5)
    println("mixed.pick<Int>() = ${mixed.pick<Int>()}")
    println("mixed.pick<String>() = ${mixed.pick<String>()}")
    println("42.isA<Int>() = ${42.isA<Int>()}, \"x\".isA<Int>() = ${"x".isA<Int>()}")

    println("== 11.7 类型擦除：泛型只活在编译期 ==")
    val li: List<Int> = listOf(1)
    val ls: List<String> = listOf("a")
    println("li::class == ls::class → ${li::class == ls::class}   // 运行时都是同一个 ArrayList")
    println("li::class.java.name = ${li::class.java.name}   // .java 是通往 JVM Class 的逃生舱")
    // if (li is List<Int>) {}    // ← 编译错：无法在运行时检查被擦除的类型参数
    val anyList: Any = li
    println("静态类型时检查恒真（警告），先转 Any 再查星投影: ${anyList is List<*>}")

    println("== 11.8 与其他语言对照 ==")
    println("Kotlin: 声明处型变（out/in）+ reified；Java: 使用处通配符 ? extends；C#：out/in；Rust：所有泛型单态化")

    println("== 11.9 型变细则、签名冲突与 reified 工程化 ==")
    val counter: Refillable<Int> = Refillable(1) { it + 10 }
    val asNumber: Refillable<Number> = counter        // out：Int 生产者可当 Number 生产者
    println("Refillable: get=${asNumber.get()}, advance=${counter.advance()}（private var 内部可变，外部只读）")
    println("同名 sum 重载: Int 版=${sum(listOf(1, 2, 3))}, String 版=${sum(listOf("a", "b"))}（@JvmName 消除擦除冲突）")
    println("旧式传 Class: ${parseOf("42", Int::class.javaObjectType)}")
    println("reified 包装: \"42\".parseAs<Int>()=${"42".parseAs<Int>()}, \"hi\".parseAs<String>()=${"\"hi\"".parseAs<String>()}, \"x\".parseAs<Long>()=${"x".parseAs<Long>()}")
}
