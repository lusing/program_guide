// 08 · 密封类、枚举与 when：穷尽、智能转换、ADT

/** 枚举：带构造参数、属性、方法，甚至抽象方法 */
enum class Planet(val gravity: Double) {
    MERCURY(3.7), EARTH(9.81), MARS(3.71), JUPITER(24.79);

    /** 每个枚举常量自己的实现 */
    fun weightOn(earthKg: Double): Double = earthKg * gravity
    override fun toString(): String = "$name(g=$gravity)"
}

/** 枚举带抽象方法：每个常量给一份实现 */
enum class Ops {
    ADD { override fun apply(a: Int, b: Int) = a + b },
    SUB { override fun apply(a: Int, b: Int) = a - b },
    MUL { override fun apply(a: Int, b: Int) = a * b };

    abstract fun apply(a: Int, b: Int): Int
}

/** 密封继承体系：子类型封闭在本文件内 → when 可穷尽，加新子类型时漏分支会编译错 */
sealed interface Expr {
    data class Num(val v: Double) : Expr
    data class Add(val l: Expr, val r: Expr) : Expr
    data class Mul(val l: Expr, val r: Expr) : Expr
    data class Neg(val e: Expr) : Expr
    data object Zero : Expr                      // 2.2+：无状态单例用 data object
}

/** 穷尽 when：不需要 else；新增 Expr 子类型时这里编译错 */
fun eval(e: Expr): Double = when (e) {
    is Expr.Num -> e.v
    is Expr.Add -> eval(e.l) + eval(e.r)
    is Expr.Mul -> eval(e.l) * eval(e.r)
    is Expr.Neg -> -eval(e.e)
    Expr.Zero -> 0.0
}

/** 代数数据类型的经典收益：序列化/渲染永不漏分支 */
fun render(e: Expr): String = when (e) {
    is Expr.Num -> "${e.v}"
    is Expr.Add -> "(${render(e.l)} + ${render(e.r)})"
    is Expr.Mul -> "(${render(e.l)} × ${render(e.r)})"
    is Expr.Neg -> "(-${render(e.e)})"
    Expr.Zero -> "0"
}

/** 状态机：sealed + when 表驱动 */
sealed interface OrderState {
    data object Created : OrderState
    data class Paid(val amount: Int) : OrderState
    data class Shipped(val tracking: String) : OrderState
    data object Done : OrderState
}

fun nextAction(s: OrderState): String = when (s) {
    OrderState.Created -> "等待支付"
    is OrderState.Paid -> "已收款 ${s.amount}，安排发货"
    is OrderState.Shipped -> "运输中（${s.tracking}），等签收"
    OrderState.Done -> "订单完成，可归档"
}

fun main() {
    println("== 8.2 枚举 ==")
    println("行星: ${Planet.entries.joinToString(" | ")}")     // entries（1.9+）替代 values()
    println("60kg 在 EARTH = ${"%.1f".format(Planet.EARTH.weightOn(60.0))} N")
    println("60kg 在 MARS  = ${"%.1f".format(Planet.MARS.weightOn(60.0))} N")
    for (op in Ops.entries) println("6 ${op.name} 3 = ${op.apply(6, 3)}")

    println("== 8.3 when 的完整形态 ==")
    for (n in listOf(0, 3, 7)) {
        val desc = when (n) {
            0 -> "零"
            in 1..5 -> "1..5"
            6, 7 -> "六或七"
            else -> "更大"
        }
        print("n=$n→$desc ")
    }
    println()
    val withGuard = when (val n = 10) {
        in 1..100 if n % 2 == 0 -> "小偶数"      // 守卫条件（2.1+ 稳定）
        in 1..100 -> "小奇数"
        else -> "范围外"
    }
    println("守卫条件: $withGuard")

    println("== 8.4 密封继承：表达式求值 ==")
    val expr: Expr = Expr.Add(Expr.Num(1.0), Expr.Mul(Expr.Num(2.0), Expr.Neg(Expr.Num(3.5))))
    println("render = ${render(expr)}")
    println("eval   = ${eval(expr)}")

    println("== 8.5 状态机 ==")
    val states = listOf<OrderState>(
        OrderState.Created,
        OrderState.Paid(199),
        OrderState.Shipped("SF123456"),
        OrderState.Done,
    )
    for (s in states) println("  ${nextAction(s)}")

    println("== 8.6 对比：枚举 vs 密封 ==")
    println("枚举 = 值的固定集合（单例常量）；密封 = 类型的固定集合（可携带数据、可有多个实例）")
}
