// 07 · 继承与接口：默认 final、open/override、abstract、接口默认实现、嵌套 vs 内部、智能转换

/** Kotlin 类默认 final：要被继承必须显式 open */
open class Shape(val name: String) {
    open val area: Double get() = 0.0          // 属性也能 open
    open fun describe() = "$name: 面积 = ${"%,.2f".format(area)}"
}

class Circle(val radius: Double) : Shape("圆") {
    override val area: Double get() = Math.PI * radius * radius
}

class Rect2(val w: Double, val h: Double) : Shape("矩形") {
    override val area: Double get() = w * h
    override fun describe() = super.describe() + "（宽 $w × 高 $h）"   // 复用父类实现
}

/** 抽象类：不能实例化，成员可以是抽象的 */
abstract class Storage {
    abstract fun save(key: String, value: String)
    fun dump() = "Storage@${this::class.simpleName}"     // ::class 拿运行时类型
}

class MemoryStorage : Storage() {
    val data = mutableMapOf<String, String>()
    override fun save(key: String, value: String) { data[key] = value }
}

/** 接口：可有默认实现与抽象属性——多实现解决"钻石"问题 */
interface Area { val area: Double }
interface Named { val name: String
    fun label() = "[$name]" }                 // 默认实现
class Square2(val side: Double, override val name: String) : Area, Named {
    override val area: Double get() = side * side
    // label() 直接继承默认实现；要覆写也行
}

/** 嵌套类（static）vs 内部类（inner，持外部引用） */
class Outer(val tag: String) {
    class Nested(val info: String) {          // 嵌套：不持有 Outer 实例
        fun show() = "Nested($info)"
    }
    inner class Inner {                       // inner：能访问 this@Outer
        fun show() = "Inner(属于 ${this@Outer.tag})"
    }
}

/** 可见性：private 只在本类；internal 同模块（教程所有示例同一次编译=同模块）*/
class Counter2 {
    private var hits = 0
    internal fun bump() { hits++ }            // internal：模块内可见
    fun report() = "hits = $hits"
}

fun render(s: Shape): String = when (s) {     // when + is + 智能转换（不用强转）
    is Circle -> "圆，半径 ${s.radius}，精确面积 ${"%,.4f".format(s.area)}"
    is Rect2  -> s.describe()
    else      -> s.describe()
}

fun main() {
    println("== 7.2 默认 final 与 open ==")
    val shapes: List<Shape> = listOf(Circle(1.0), Rect2(3.0, 4.0))
    for (s in shapes) println(render(s))
    // 注意：Shape 是 open 的具体类，可以实例化 Shape("x")；要禁止实例化用 abstract
    println("矩形覆写并复用父类: ${Rect2(3.0, 4.0).describe()}")

    println("== 7.3 抽象类 ==")
    val st: Storage = MemoryStorage()
    st.save("lang", "kotlin")
    println("${st.dump()} -> ${(st as MemoryStorage).data}")   // as 强转（确定类型时用）

    println("== 7.4 接口与多实现 ==")
    val sq: Named = Square2(2.0, "方块")
    println("${sq.label()}, area = ${(sq as Square2).area}")   // 接口引用上调实现类成员
    val area2: Area = Square2(3.0, "方块")
    println("面积 = ${area2.area}")

    println("== 7.5 类型检查与智能转换 ==")
    val objs: List<Any> = listOf(Circle(0.5), "文本", 42, Rect2(1.0, 1.0))
    for (o in objs) {
        val msg = when (o) {
            is Shape -> "形状（${if (o is Circle) "圆" else "矩形"}，area=${"%,.2f".format(o.area)}）"
            is String -> "字符串 '${o.take(4)}'"
            is Int -> if (o >= 0) "非负整数 $o" else "负整数 $o"
            else -> "其他: $o"
        }
        println("  $msg")
    }

    println("== 7.6 嵌套 vs 内部 ==")
    println(Outer.Nested("静态嵌套，无需 Outer 实例").show())
    println(Outer("外层").Inner().show())

    println("== 7.7 可见性 ==")
    val c = Counter2()
    c.bump(); c.bump(); c.bump()
    println(c.report())
    // c.hits                // ← 编译错：private 成员外部不可见
}
