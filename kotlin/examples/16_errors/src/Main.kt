// 16 · 异常与错误处理：try 表达式、Nothing、require/check、runCatching/Result、use、密封错误类型

/** 自定义异常层级：业务错误一个根，子类按域分 */
sealed class AppError(message: String) : Exception(message) {
    class NotFound(val key: String) : AppError("找不到: $key")
    class Invalid(val why: String) : AppError("非法输入: $why")
}

/** 域层：抛异常版 */
class Store1 {
    private val data = mutableMapOf("a" to 1)
    fun get(k: String): Int = data[k] ?: throw AppError.NotFound(k)
}

/** 域层：返回 Result 版——调用方被迫处理失败可能 */
class Store2 {
    private val data = mutableMapOf("a" to 1)
    fun get(k: String): Result<Int> =
        data[k]?.let { Result.success(it) } ?: Result.failure(AppError.NotFound(k))
}

/** try 是表达式：有值 */
fun parseLen(s: String): Int = try { s.length } catch (e: Exception) { -1 }

/** 标准库的内置校验：require(参数) / check(状态) / error(直接抛) */
fun shrink(s: String, n: Int): String {
    require(n >= 0) { "n 不能为负（参数校验）: $n" }    // IllegalArgumentException
    check(s.length >= n) { "串太短（状态校验）" }       // IllegalStateException
    return s.take(n)
}

/** throw 是 Nothing 型表达式——可以出现在任何需要值的地方 */
val fallback: Int = try { throw AppError.Invalid("demo") } catch (e: AppError.Invalid) { 0 }
fun boom(): Nothing = throw AppError.Invalid("必炸")

fun main() {
    println("== 16.2 try 是表达式 ==")
    val a = try { "42".toInt() } catch (e: NumberFormatException) { null }
    val b = try { "x".toInt() } catch (e: NumberFormatException) { null }
    println("parse: a=$a, b=$b")
    println("parseLen(\"abc\") = ${parseLen("abc")}")

    println("== 16.3 自定义异常 ==")
    val s1 = Store1()
    println("get(\"a\") = ${s1.get("a")}")
    try {
        s1.get("zzz")
    } catch (e: AppError.NotFound) {
        println("捕获 NotFound: ${e.message}")
    } catch (e: AppError) {
        println("捕获 AppError: ${e.message}")          // sealed → 有穷分支，else 都不用
    }

    println("== 16.4 require / check / error ==")
    println(shrink("kotlin", 3))
    try { shrink("kt", -1) } catch (e: IllegalArgumentException) { println("require: ${e.message}") }
    try { shrink("kt", 5) } catch (e: IllegalStateException) { println("check: ${e.message}") }

    println("== 16.5 runCatching 与 Result 链 ==")
    val r1 = runCatching { "42".toInt() }
    val r2 = runCatching { "x".toInt() }
    println("成功: getOrNull=${r1.getOrNull()}, isFailure=${r1.isFailure}")
    println("失败: getOrElse={${r2.getOrElse { -1 }}}")
    println("map: ${r1.map { it * 2 }.getOrNull()}, recoverCatching: ${r2.recoverCatching { 0 }.getOrNull()}")
    r1.fold({ println("fold 成功分支: $it") }, { println("fold 失败分支: $it") })
    r2.fold({ println("不会到这") }, { println("fold 失败分支: ${it.message}") })
    val chained = runCatching { "8" }
        .mapCatching { it.toInt() }
        .mapCatching { it * 100 }
    println("mapCatching 链: ${chained.getOrDefault(-1)}")

    println("== 16.6 Result 版领域函数 ==")
    val s2 = Store2()
    s2.get("a").fold({ println("成功: $it") }, { println("失败: ${it.message}") })
    s2.get("zz").fold({ println("成功: $it") }, { println("失败: ${it.message}") })

    println("== 16.7 Nothing：永不返回的类型 ==")
    println("throw 也是表达式: fallback=$fallback")
    val list = listOf(1)
    val first = list.firstOrNull() ?: boom()     // elvis 右侧 Nothing → first: Int
    println("Nothing 参与 elvis: first=$first")

    println("== 16.8 use：自动关闭（try-with-resources）==")
    "第一行\n第二行".reader().use { r ->
        println("读出字符数: ${r.readText().length}")
    }   // use 结束自动 close

    println("== 16.9 策略选型 ==")
    println("  编程错误/调用方 bug → require/throw 快速失败 | 可预期的业务失败 → Result/sealed 返回值")
    println("  混合用法：内部 throw，边界 runCatching 转 Result——26 行的 Store1/Store2 是两种风格")
}
