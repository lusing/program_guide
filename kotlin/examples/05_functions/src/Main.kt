// 05 · 函数：默认/具名参数、vararg、infix、tailrec、局部函数、顶层函数

/** 默认参数：调用方可省略，比 Java 的重载瀑布干净 */
fun connect(host: String, port: Int = 8080, useTls: Boolean = false, timeoutMs: Long = 3000): String =
    "${if (useTls) "https" else "http"}://$host:$port (timeout=${timeoutMs}ms)"

/** vararg：可变参数就是数组，展开用 *（spread） */
fun sum(vararg nums: Int): Int {
    var s = 0
    for (n in nums) s += n
    return s
}

/** 中缀函数：infix 修饰，调用时可省略点号和括号 */
infix fun Int.pow(n: Int): Int {
    var r = 1
    repeat(n) { r *= this }
    return r
}

/** 尾递归优化：tailrec 让递归编译成循环，不怕栈溢出 */
tailrec fun factorial(n: Long, acc: Long = 1L): Long = if (n <= 1) acc else factorial(n - 1, acc * n)

tailrec fun fib(n: Int, a: Long = 0, b: Long = 1): Long = when (n) {
    0 -> a
    else -> fib(n - 1, b, a + b)
}

/** 局部函数：只在一个函数内部有用的逻辑收进去，能访问外部参数 */
fun validateForm(name: String, email: String, age: Int): List<String> {
    fun err(field: String, why: String) = "$field 无效: $why"    // 闭包捕获
    val problems = mutableListOf<String>()
    if (name.isBlank()) problems += err("姓名", "为空")
    if (!email.contains('@')) problems += err("邮箱", "缺少 @")
    if (age !in 1..150) problems += err("年龄", "超出范围")
    return problems
}

/** 泛型函数 + 约束：13 章扩展、11 章泛型的预告 */
fun <T : Comparable<T>> maxOf3(a: T, b: T, c: T): T = maxOf(a, maxOf(b, c))

fun main() {
    println("== 5.2 默认参数与具名参数 ==")
    println(connect("api.example.com"))
    println(connect("api.example.com", 443, true))
    println(connect("db.example.com", port = 5432, timeoutMs = 10_000))   // 具名参数随便换顺序
    println(connect(timeoutMs = 500, host = "cdn.example.com"))

    println("== 5.3 vararg 与展开 ==")
    println("sum(1,2,3) = ${sum(1, 2, 3)}")
    println("sum() = ${sum()}")
    val nums = intArrayOf(10, 20, 30)
    println("sum(*nums) = ${sum(*nums, 5)}")          // spread 展开 + 追加
    println("nums 是数组，直接传要写 sum(*nums)")

    println("== 5.4 中缀调用 ==")
    println("2 pow 10 = ${2 pow 10}")                  // infix 调用
    println("等价写法 = ${2.pow(10)}")

    println("== 5.5 尾递归 ==")
    println("20! = ${factorial(20)}")
    println("fib(90) = ${fib(90)}")                    // Long 范围内的最大斐波那契

    println("== 5.6 局部函数 ==")
    println("合法表单: ${validateForm("张三", "z@ex.io", 30)}")
    println("问题清单: ${validateForm("", "zex.io", 300)}")

    println("== 5.7 泛型函数预览 ==")
    println("maxOf3(3, 9, 7) = ${maxOf3(3, 9, 7)}")
    println("maxOf3('a','z','m') = ${maxOf3('a', 'z', 'm')}")
    println("maxOf3(\"kotlin\",\"zig\",\"rust\") = ${maxOf3("kotlin", "zig", "rust")}")
}
