// 28 · inline 进阶：内联原理、非局部返回、noinline/crossinline、@PublishedApi、inline 属性、自造控制流

/** 28.1 计时扩展：函数体与 lambda 一起拷到调用点（返回纳秒差，数值不进快照） */
inline fun printExecutionTime(block: () -> Unit): Long {
    val start = System.nanoTime()
    block()
    return System.nanoTime() - start
}

/** 28.2 非局部返回：inline 的 forEach 里裸 return 退出的是外层函数 */
fun firstNegative(xs: List<Int>): Int? {
    xs.forEach { if (it < 0) return it }
    return null
}

/** 28.2 对照组：非内联版本——裸 return 编译不过，只能 return@eachSlow */
fun <T> eachSlow(xs: List<T>, f: (T) -> Unit) { for (x in xs) f(x) }

/** 28.3 自造控制流一：重复执行直到抛 IllegalStateException，返回成功次数 */
inline fun repeatUntilError(block: () -> Unit): Int {
    var n = 0
    try { while (true) { block(); n++ } }
    catch (e: IllegalStateException) { return n }
}

/** 28.3 自造控制流二：最多试 maxAttempts 次，返回实际尝试次数 */
inline fun tryFewTimes(maxAttempts: Int, block: (attempt: Int) -> Boolean): Int {
    var a = 0
    while (a < maxAttempts) { a++; if (block(a)) return a }
    return a
}

/** 28.4 noinline：block 要当对象返回（延迟执行），onRegister 照常内联——两者共存才不触发 K2 告警 */
inline fun later(noinline block: () -> String, onRegister: (String) -> Unit = {}): () -> String {
    onRegister("已注册")
    return block
}

/** 28.5 crossinline：lambda 被包进另一个（非内联）Runnable——承诺不做非局部返回 */
inline fun runAsTask(crossinline block: () -> Unit): Runnable = Runnable { block() }

/** 28.6 事实公开的内部实现：@PublishedApi 让 public inline 壳可以引用它 */
@PublishedApi
internal fun internalHelper(): String = "内部实现（@PublishedApi = 承诺当公开对待）"

// 注意：public inline 壳若没有函数类型参数，K2 会告警"inlining 影响甚微"——带上一个（默认值）既过编译又保语义
inline fun publicInlineApi(transform: (String) -> String = { it }): String = transform(internalHelper())

/** 28.7 inline 属性：无幕后字段，getter 拷到访问点 */
inline val tag: String get() = "无幕后字段的内联属性"

/** 28.7 reified 只能配 inline（11 章铁律在此闭环） */
inline fun <reified T> typeName(): String? = T::class.simpleName

fun main() {
    println("== 28.1 内联原理 ==")
    val e = printExecutionTime { (1..1000).sum() }
    println("printExecutionTime 返回纳秒差: e>=0 -> ${e >= 0}（数值不进快照）")
    println("收益: lambda 不装箱成 Function 对象 + 非局部返回；代价: 调用点字节码膨胀")

    println("== 28.2 非局部返回 ==")
    println("firstNegative(listOf(3, 7, -2, 9)) = ${firstNegative(listOf(3, 7, -2, 9))}")
    println("firstNegative(listOf(1, 2)) = ${firstNegative(listOf(1, 2))}")
    val visited = mutableListOf<Int>()
    eachSlow(listOf(1, -2, 3)) {
        visited.add(it)
        if (it < 0) return@eachSlow     // 非 inline 版只能标签返回（裸 return 编译不过）
    }
    println("eachSlow 标签返回: visited=$visited（-2 后停当轮，3 仍会访问）")
    eachSlow(listOf(1, -2, 3)) { if (it > 0) visited.add(it * 100) }
    println("再跑一轮累计: $visited")

    println("== 28.3 自造控制流 ==")
    var cursor = 0; val data = listOf("a", "b", "c")
    val reads = repeatUntilError {
        if (cursor >= data.size) error("EOF") else cursor++
    }
    println("repeatUntilError 读了 $reads 条后收到 EOF")
    println("tryFewTimes(5){ it >= 3 } = ${tryFewTimes(5) { it >= 3 }}（第 3 次成功）")
    println("tryFewTimes(5){ false } = ${tryFewTimes(5) { false }}（始终失败用满 5 次）")

    println("== 28.4 noinline ==")
    val registered = mutableListOf<String>()
    val saved = later({ "延迟求值" }) { registered.add(it) }
    println("注册期回调(onRegister 内联展开): $registered")
    println("later 返回的 lambda 对象: saved()=${saved()}")

    println("== 28.5 crossinline ==")
    val logs = mutableListOf<String>()
    runAsTask { logs.add("任务体执行（Runnable.run 同步触发）") }.run()
    println("logs=$logs")
    println("crossinline 里裸 return 编译不过——只能 return@runAsTask（Android runOnUiThread 同形状）")

    println("== 28.6 @PublishedApi ==")
    println("publicInlineApi() = ${publicInlineApi()}, 加变换 = ${publicInlineApi { it.uppercase() }}")
    println("不加 @PublishedApi 会编译错: public inline 不能引用 internal——防止私有实现内联泄漏到模块外")

    println("== 28.7 inline 属性与 reified ==")
    println("tag = $tag")
    println("typeName<List<Int>>() = ${typeName<List<Int>>()}, typeName<String>() = ${typeName<String>()}")
}
