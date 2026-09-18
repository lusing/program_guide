// 22 · 函数式编程：惰性 Sequence、纯函数、组合、柯里化、Either、不可变数据

/** 集合管道（急切）：每个操作立刻物化出新集合 */
fun eagerPipeline(): List<Int> {
    println("  [集合] 开始")
    val r = (1..5).toList()
        .map { println("  [集合] map $it"); it * 10 }
        .filter { println("  [集合] filter $it"); it > 20 }
        .take(2)
    return r
}

/** 序列管道（惰性）：逐元素流过全管道，take(2) 提前终止上游 */
fun lazyPipeline(): List<Int> {
    println("  [序列] 开始")
    val r = (1..5).asSequence()
        .map { println("  [序列] map $it"); it * 10 }
        .filter { println("  [序列] filter $it"); it > 20 }
        .take(2)
        .toList()
    return r
}

/** 函数组合：compose(f, g)(x) = f(g(x)) */
fun <A, B, C> compose(f: (B) -> C, g: (A) -> B): (A) -> C = { f(g(it)) }

/** 柯里化：多元函数 → 一元函数链 */
fun add3(a: Int, b: Int, c: Int): Int = a + b + c
fun curry3(f: (Int, Int, Int) -> Int): (Int) -> (Int) -> (Int) -> Int = { a -> { b -> { c -> f(a, b, c) } } }

/** 部分应用：先固定几个参数 */
fun <A, B, C> partial2(f: (A, B) -> C, a: A): (B) -> C = { b -> f(a, b) }

/** Either：用密封类型表达"成功或失败"，不用异常 */
sealed interface Either<L, R> {
    data class Left<L, R>(val value: L) : Either<L, R>
    data class Right<L, R>(val value: R) : Either<L, R>
}

inline fun <L, R, R2> Either<L, R>.map(f: (R) -> R2): Either<L, R2> = when (this) {
    is Either.Left -> Either.Left(value)          // 重建而非返回 this——类型才对得上
    is Either.Right -> Either.Right(f(value))
}

inline fun <L, R, R2> Either<L, R>.flatMap(f: (R) -> Either<L, R2>): Either<L, R2> = when (this) {
    is Either.Left -> Either.Left(value)
    is Either.Right -> f(value)
}

inline fun <L, R, T> Either<L, R>.fold(onLeft: (L) -> T, onRight: (R) -> T): T = when (this) {
    is Either.Left -> onLeft(value)
    is Either.Right -> onRight(value)
}

/** 依纯函数组合的解析链：解析 → 校验 → 计算，失败短路 */
fun parseAge2(s: String): Either<String, Int> =
    s.toIntOrNull()?.let { Either.Right(it) } ?: Either.Left("'$s' 不是数字")

fun checkAdult(age: Int): Either<String, Int> =
    if (age >= 18) Either.Right(age) else Either.Left("未成年: $age")

fun ticketPrice(age: Int): Either<String, String> =
    Either.Right(if (age >= 65) "半价 ¥50" else "全价 ¥100")

fun pipeline(s: String): Either<String, String> =
    parseAge2(s).flatMap(::checkAdult).flatMap(::ticketPrice)

/** 纯函数 vs 副作用：把"现在几点"注入进来，函数就能测了 */
interface Clock { fun nowMs(): Long }
class FakeClock(private var t: Long) : Clock {
    override fun nowMs(): Long = t
    fun advance(ms: Long) { t += ms }
}
fun isExpired(createdAt: Long, ttl: Long, clock: Clock): Boolean = clock.nowMs() - createdAt > ttl

fun main() {
    println("== 22.2 惰性求值：List vs Sequence ==")
    println("急切结果: ${eagerPipeline()}")
    println("惰性结果: ${lazyPipeline()}")
    println("→ 序列算到第 4 个元素就把 take(2) 攒够提前收工；集合把 5 个全算完才开始过滤")

    println("== 22.3 组合与柯里化 ==")
    val f = compose(String::uppercase, String::trim)
    println("compose(uppercase, trim)(\"  hi \") = ${f("  hi ")}")
    val addC = curry3(::add3)
    println("curry3(add3)(1)(2)(3) = ${addC(1)(2)(3)}")
    val add10 = partial2(::add2, 10)
    println("partial2(加法, 10)(5) = ${add10(5)}")

    println("== 22.4 Either：不用异常的错误传播 ==")
    for (s in listOf("70", "15", "x")) {
        println("  pipeline(\"$s\") = ${pipeline(s).fold({ "失败: $it" }, { "票: $it" })}")
    }

    println("== 22.5 纯函数：依赖注入时间 ==")
    val clock = FakeClock(1_000)
    println("  t=1000 创建, ttl=5000: 过期=${isExpired(1_000, 5_000, clock)}")
    clock.advance(6_000)
    println("  前进 6000 后: 过期=${isExpired(1_000, 5_000, clock)}   ← 测试无需真等 6 秒")

    println("== 22.6 不可变数据的『修改』 ==")
    data class Config2(val host: String, val port: Int, val debug: Boolean)
    val prod = Config2("api.x.io", 443, false)
    val debugCfg = prod.copy(debug = true, port = 8443)
    println("  prod = $prod")
    println("  debug = $debugCfg（copy 产出新值，原值不动）")

    println("== 22.7 递归与尾调用 ==")
    tailrec fun sumTo(n: Int, acc: Int = 0): Int = if (n == 0) acc else sumTo(n - 1, acc + n)
    println("  sumTo(100000) = ${sumTo(100_000)}（tailrec 编译成循环，不爆栈）")
}

fun add2(a: Int, b: Int): Int = a + b
