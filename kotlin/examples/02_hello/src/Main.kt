// 02 · 第一个程序：main 函数、println、字符串模板、函数初体验
// 编译运行见 docs/02-hello.md —— kotlinc 全流程

/** 最普通的函数：块体 + 显式返回类型 */
fun greet(name: String): String {
    return "你好, $name!"
}

/** 单表达式函数：等号即函数体，返回类型可推断（公共 API 建议显式写） */
fun repeatGreet(word: String, times: Int): String = word.repeat(times)

/** 演示 main 如何接收命令行参数：逻辑放进纯函数，测试才好写 */
fun renderArgs(args: Array<String>): String = buildString {
    appendLine("参数个数: ${args.size}")
    for ((i, a) in args.withIndex()) appendLine("参数[$i]: $a")
}

fun main() {
    println("== 2.2 第一个程序 ==")
    println("Hello, Kotlin!")

    println("== 2.3 字符串模板 ==")
    val a = 1
    val b = 2
    println("$a + $b = ${a + b}")          // $变量 与 ${表达式}
    val lang = "Kotlin"
    val ver = "2.4.20"
    println("你好, $lang $ver")
    println("花括号里还能调方法: ${lang.uppercase()}")

    println("== 2.4 函数初体验 ==")
    println("greet(\"世界\") = ${greet("世界")}")
    println("repeatGreet(\"哈\", 3) = ${repeatGreet("哈", 3)}")

    println("== 2.5 命令行参数（用固定参数演示）==")
    print(renderArgs(arrayOf("add", "42")))
}
