// 04 · 空安全：类型系统里的 null、?.、!!、Elvis、let、as?、lateinit、takeIf

/** 模拟一条用户记录：两个字段都可为空 */
data class User(val name: String?, val email: String?)

/** 安全调用链 + Elvis 默认值 */
fun displayName(u: User?): String = u?.name?.trim()?.ifEmpty { null } ?: "匿名"

/** 解析失败返回 null（不抛异常的解析） */
fun parseAge(s: String): Int? = s.trim().toIntOrNull()

fun safeUpper(s: String?): String = s?.uppercase() ?: "（空）"

/** 安全转换：不是目标类型就得到 null，而不是抛 ClassCastException */
fun lengthIfText(x: Any): Int? = (x as? String)?.length

/** takeIf：谓词为真返回接收者，否则 null——配合 Elvis 做"过滤 + 默认" */
fun classifyAge(age: Int?): String {
    val a = age ?: return "年龄缺失"
    return when {
        a >= 60 -> "老年"
        else -> a.takeIf { it < 18 }?.let { "未成年($a)" } ?: "成年($a)"
    }
}

class Config {
    lateinit var endpoint: String          // 延迟初始化（非空但不立刻有值）
    fun ready() = ::endpoint.isInitialized
}

fun main() {
    println("== 4.2 类型即空安全 ==")
    val s: String = "abc"
    // val bad: String = null              // ← 编译错：null 不是 String
    val t: String? = null                  // 可空是另一种类型 String?
    println("s.length = ${s.length}, t = $t")
    // println(t.length)                   // ← 编译错：t 可能是 null，编译器拦住

    println("== 4.3 安全调用 ?. 与 Elvis ?: ==")
    val u1 = User(" 张三 ", "z@ex.io")
    val u2 = User(null, null)
    val u3: User? = null
    println(displayName(u1)); println(displayName(u2)); println(displayName(u3))
    println("u1.email?.length = ${u1.email?.length}")
    val host = u1.email?.substringAfter('@') ?: "无域名"
    println("host = $host")
    // Elvis 右侧还能抛异常/return：age ?: error("必须有年龄")

    println("== 4.4 let：对非空值执行一段逻辑 ==")
    val email = u1.email
    if (email != null) println("if 判空后智能转换: ${email.uppercase()}")
    email?.let { println("let 版（非空才进来）: ${it.uppercase()}") }
    // 多级判空的组合拳：?.let 嵌套会缩进地狱，配合 Elvis 提前返回更好（见 classifyAge）

    println("== 4.5 !! 操作符：断言非空，错了就 NPE ==")
    val forced = u2.name?.length
    println("u2.name?.length = $forced")
    try {
        val npe = u2.name!!
        println("不会到这: $npe")
    } catch (e: NullPointerException) {
        println("u2.name!! 抛出 NPE —— !! 只用于你比编译器更懂的时刻")
    }

    println("== 4.6 安全转换 as? ==")
    println("lengthIfText(\"kotlin\") = ${lengthIfText("kotlin")}")
    println("lengthIfText(42) = ${lengthIfText(42)}")

    println("== 4.7 可空与集合 ==")
    val ages = listOf("18", "x", "", "33").map { parseAge(it) }   // List<Int?>
    println("原始解析结果: $ages")
    println("过滤掉 null: ${ages.filterNotNull()}")                // List<Int>
    val map = mapOf("a" to 1, "b" to null)
    println("map 值里的 null: $map, b = ${map["b"]}")

    println("== 4.8 takeIf / takeUnless ==")
    println(classifyAge(12)); println(classifyAge(30)); println(classifyAge(null))
    val even = 4.takeIf { it % 2 == 0 }
    val odd = 3.takeIf { it % 2 == 0 }
    println("takeIf: 4→$even, 3→$odd")

    println("== 4.9 lateinit：非空但要晚点才初始化 ==")
    val cfg = Config()
    println("初始化前 ready = ${cfg.ready()}")
    cfg.endpoint = "https://api.example.com"
    println("初始化后 ready = ${cfg.ready()}, endpoint = ${cfg.endpoint}")
    // 在初始化前访问 cfg.endpoint 会抛 UninitializedPropertyAccessException
}
