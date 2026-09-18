// 12 · 高阶函数与 Lambda：函数类型、引用、闭包、带接收者的 lambda、作用域函数、inline

/** 函数类型：(Int, Int) -> Int；参数可以是函数，返回值也可以是函数 */
fun operate(a: Int, b: Int, op: (Int, Int) -> Int): Int = op(a, b)

/** 返回函数的高阶函数（柯里化的雏形，22 章细讲） */
fun multiplier(k: Int): (Int) -> Int = { it * k }

/** 带接收者的函数类型：T.() -> R——lambda 里的 this 就是 T */
fun <T> T.printlned(tag: String, block: T.() -> String): String = "[$tag] ${block()}"

/** 高阶函数自定义：像标准库 filter 一样工作 */
fun <T> myFilter(items: List<T>, pred: (T) -> Boolean): List<T> {
    val out = mutableListOf<T>()
    for (x in items) if (pred(x)) out.add(x)
    return out
}

data class Player(val name: String, var score: Int)

fun main() {
    println("== 12.2 lambda 基本形 ==")
    val square: (Int) -> Int = { x -> x * x }
    val cube = { x: Int -> x * x * x }              // 类型写在参数上，变量省略声明
    println("square(5) = ${square(5)}, cube(3) = ${cube(3)}")
    val sum2: (Int, Int) -> Int = { a, b -> a + b }
    println("sum2(3, 4) = ${sum2(3, 4)}")

    println("== 12.3 it：单参数 lambda 的隐式名 ==")
    val isEven: (Int) -> Boolean = { it % 2 == 0 }
    println("isEven(4) = ${isEven(4)}")
    // it 只在单参数时可用；多参数必须命名；不用的参数可以叫 _

    println("== 12.4 把函数当值传递 ==")
    println("operate(6, 3, { a, b -> a * b }) = ${operate(6, 3, { a, b -> a * b })}")
    println("operate(6, 3) { a, b -> a - b } = ${operate(6, 3) { a, b -> a - b }}   // 尾随 lambda")
    println("operate(6, 3, ::maxOf) = ${operate(6, 3, ::maxOf)}")   // 函数引用 ::
    // ::minOf 重载太多，放进集合时给个明确的函数类型帮编译器选 minOf(Int, Int)
    val ops: List<(Int, Int) -> Int> = listOf(::minOf, ::maxOf)
    println("函数也能进集合: ${ops.joinToString { it(2, 9).toString() }}")
    val triple = multiplier(3)
    println("multiplier(3)(7) = ${triple(7)}        // 返回的函数带着自己的 k")

    println("== 12.5 闭包：lambda 捕获外部变量 ==")
    var calls = 0
    val counted = { calls++; calls * 10 }
    println(counted()); println(counted()); println(counted())
    println("calls 被闭包改到 = $calls")
    // Java 里 lambda 只能捕获 effectively final；Kotlin 能捕获 var——这是真闭包

    println("== 12.6 带接收者的 lambda：T.() -> R ==")
    println(10.printlned("平方") { (this * this).toString() })
    println("kotlin".printlned("长度") { "$length（this=$this）" })

    println("== 12.7 作用域函数五件套 ==")
    val p: Player? = Player("Ada", 90)
    // let：对可空值做"非空才执行"，it 是值
    p?.let { println("let: ${it.name} 得分 ${it.score}") }
    // run：对象 + 计算结果，this 是对象
    val ada = p!!                                   // !! 断言一次，之后智能转换为非空
    val bonus = ada.run { score * 2 }
    println("run: bonus = $bonus")
    // with：显式传对象，this 是对象（不是扩展）
    with(ada) { score += 5; println("with: 修改后 ${this.name}=${score}") }
    // apply：配置对象并返回对象本身（this 是对象，返回 this）
    val p2 = Player("Bob", 0).apply { score = 50; println("apply: 配置中 name=$name") }
    println("apply 产物: $p2")
    // also：做点副作用（打印/日志/校验）并返回对象本身（it 是值）
    val p3 = Player("Carol", 60).also { println("also: 创建了 ${it.name}") }
    println("also 产物: $p3")

    println("== 12.8 inline 与非局部返回 ==")
    val found = listOf(1, 2, 3, 4).firstOrNull { it > 2 }
    println("firstOrNull { >2 } = $found            // forEach/firstOrNull 都是 inline")
    // inline lambda 里 return 直接退出外层函数（非局部返回）：
    fun firstNegative(xs: List<Int>): Int? {
        xs.forEach { if (it < 0) return it }        // return 出的是 firstNegative！
        return null
    }
    println("firstNegative = ${firstNegative(listOf(3, -7, 9))}")
    // 非 inline 的高阶函数里 lambda 不能非局部返回：
    // myFilter(listOf(1)) { return }  ← 编译错（myFilter 非 inline）

    println("== 12.9 自己写高阶函数 ==")
    println("myFilter(1..10, 偶数) = ${myFilter((1..10).toList()) { it % 2 == 0 }}")
    val names = listOf("ada", "bob", "carol")
    println("myFilter(名字长度>3) = ${myFilter(names) { it.length > 3 }}")
}
