// 06 · 类与属性：主构造、init、属性 vs 字段、getter/setter、data class、运算符重载

/** 主构造直接声明属性：val 只读、var 可写——Kotlin 的"字段"默认是属性 */
class Rect(val width: Double, val height: Double) {
    val area: Double                       // 无 backing field：每次现算
        get() = width * height

    val isSquare: Boolean get() = width == height
}

/** init 块 + 参数校验：主构造的代码体 */
class Price(var value: Int) {
    init {
        require(value >= 0) { "价格不能为负: $value" }
    }
    var currency: String = "CNY"           // 类体内声明的属性（带默认值）
        set(v) {                           // 自定义 setter：归一化存储
            field = v.uppercase()          // field = 真正的字段
        }
    var discount: Double = 0.0             // 0.0 ~ 1.0
        set(v) {
            field = v.coerceIn(0.0, 1.0)   // setter 里做钳制
        }
    val finalPrice: Double get() = value * (1 - discount)
}

/** 次构造函数：委托主构造（primary 必须先跑） */
class Employee(val name: String) {
    var dept: String
    constructor(name: String, dept: String) : this(name) {   // 次构造必须委托 this(...)
        this.dept = dept
    }
    init { dept = "未分配" }               // init 在主构造后、次构造体前执行
    override fun toString() = "Employee($name @ $dept)"
}

/** data class：编译器生成 equals/hashCode/toString/copy/解构 */
data class Point(val x: Int, val y: Int) {
    fun moveBy(dx: Int, dy: Int) = copy(x = x + dx, y = y + dy)   // copy 只改部分字段
}

/** 运算符重载：operator 关键字 + 固定函数名 */
data class Vec2(val x: Double, val y: Double) {
    operator fun plus(o: Vec2) = Vec2(x + o.x, y + o.y)
    operator fun times(k: Double) = Vec2(x * k, y * k)     // 数乘
    operator fun unaryMinus() = Vec2(-x, -y)
    operator fun get(i: Int): Double = when (i) { 0 -> x; 1 -> y; else -> throw IndexOutOfBoundsException("i=$i") }
}

fun main() {
    println("== 6.2 主构造与属性 ==")
    val r = Rect(3.0, 4.0)
    println("Rect(3,4): area=${r.area}, isSquare=${r.isSquare}")
    val sq = Rect(5.0, 5.0)
    println("Rect(5,5): area=${sq.area}, isSquare=${sq.isSquare}")

    println("== 6.3 init 块与参数校验 ==")
    val p = Price(100)
    p.currency = "usd"                     // setter 归一化
    p.discount = 1.5                       // setter 钳制到 1.0
    println("Price: value=${p.value}, currency=${p.currency}, discount=${p.discount}, final=${p.finalPrice}")
    try {
        Price(-1)
    } catch (e: IllegalArgumentException) {
        println("Price(-1) 拒绝: ${e.message}")
    }

    println("== 6.4 次构造函数 ==")
    println(Employee("张三"))
    println(Employee("李四", "研发"))

    println("== 6.5 data class 三件套 ==")
    val a = Point(1, 2)
    val b = Point(1, 2)
    println("a == b（值相等）: ${a == b}  —— data class 按值比较；普通 class 按引用比较")
    println("a.toString(): $a")
    println("a.hashCode() == b.hashCode(): ${a.hashCode() == b.hashCode()}")
    val c = a.copy(y = 99)
    println("a.copy(y=99): $c（原对象不动: $a）")
    val (x, y) = a                          // 解构声明 = componentN()
    println("解构: x=$x, y=$y")
    println("moveBy(10,20): ${a.moveBy(10, 20)}")

    println("== 6.6 运算符重载 ==")
    val v = Vec2(1.0, 2.0) + Vec2(10.0, 20.0) * 2.0
    println("Vec2(1,2) + Vec2(10,20)*2 = $v")
    println("-v = ${-v}")
    println("v[0]=${v[0]}, v[1]=${v[1]}")
}
