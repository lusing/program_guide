// 09 · object、companion 与委托：单例、伴生、类委托、委托属性（lazy/observable/自定义）

import kotlin.properties.Delegates
import kotlin.reflect.KProperty

/** object 声明 = 立即创建的单例（类声明 + 唯一实例） */
object Registry {
    private val items = mutableMapOf<String, Int>()
    var probes = 0
    fun register(name: String) { probes++; items[name] = items.getOrDefault(name, 0) + 1 }
    fun snapshot(): Map<String, Int> = items.toMap()
}

/** companion object：类的"静态"成员与工厂函数 */
class User2 private constructor(val name: String) {
    companion object {
        const val MAX_LEN = 12                       // 编译期常量
        private var created = 0
        fun of(name: String): User2 {                // 工厂函数（主构造私有，统一入口）
            require(name.length <= MAX_LEN) { "名字过长: $name" }
            created++
            return User2(name)
        }
        fun createdCount() = created
    }
    fun describe() = "User2($name)"
}

/** 类委托：List 的所有方法转发给 items，一行实现"只读包装" */
class Box<T>(private val items: List<T>) : List<T> by items {
    override fun toString() = "Box(${items.joinToString()})"
    fun countWhere(pred: (T) -> Boolean) = items.count(pred)   // 只补想要的新方法
}

/** 委托属性 1：lazy——首次访问才计算，之后缓存（默认线程安全） */
val heavyConfig: Map<String, String> by lazy {
    println("  [lazy] heavyConfig 只算这一次！")
    mapOf("host" to "localhost", "port" to "8080")
}

/** 委托属性 2：observable——赋值回调；vetoable——还能否决赋值 */
class Temperature {
    var celsius: Double by Delegates.observable(20.0) { _, old, new ->
        println("  [observable] $old ℃ → $new ℃")
    }
    var safeRange: Double by Delegates.vetoable(20.0) { _, _, new -> new in -50.0..60.0 }
}

/** 委托属性 3：自定义委托——TrimEvery 每次读值都做 trim */
class Trimmed(private var raw: String) {
    operator fun getValue(thisRef: Any?, prop: KProperty<*>): String = raw.trim()
    operator fun setValue(thisRef: Any?, prop: KProperty<*>, v: String) { raw = v }
}
class Form { var title: String by Trimmed("  默认标题  ") }

/** 委托属性 4：Map 委托——配置项直接当属性访问 */
class Conf(private val map: Map<String, Any?>) {
    val host: String by map
    val port: Int by map
    val debug: Boolean by map
}

/** lateinit vs lazy 的选型在 docs/09-delegation.md 有对照表 */

fun main() {
    println("== 9.2 object 单例 ==")
    Registry.register("a"); Registry.register("b"); Registry.register("a")
    println("Registry: ${Registry.snapshot()}（probes=${Registry.probes}）")

    println("== 9.3 companion object ==")
    val u = User2.of("张三")
    val v = User2.of("李四")
    println("${u.describe()}, ${v.describe()}, 共创建 ${User2.createdCount()} 个（MAX_LEN=${User2.MAX_LEN}）")

    println("== 9.4 类委托 by ==")
    val box = Box(listOf(1, 2, 3, 4, 5))
    println("box.size = ${box.size}, box[2] = ${box[2]}          // List 接口全部转发")
    println("box.countWhere{偶数} = ${box.countWhere { it % 2 == 0 }}    // 自己加的新能力")

    println("== 9.5 lazy ==")
    println("第一次读 heavyConfig:")
    println("  host=${heavyConfig["host"]}")
    println("第二次读 heavyConfig:")
    println("  port=${heavyConfig["port"]}（没有再打印 [lazy] 日志——已缓存）")

    println("== 9.6 observable / vetoable ==")
    val t = Temperature()
    t.celsius = 25.5
    t.celsius = 30.0
    t.safeRange = 45.0
    t.safeRange = 999.0
    println("safeRange 最终 = ${t.safeRange}（999 被否决）")

    println("== 9.7 自定义委托 ==")
    val f = Form()
    println("title 初始 = '${f.title}'（读值时 trim）")
    f.title = "  新标题  "
    println("title 赋值后 = '${f.title}'")

    println("== 9.8 Map 委托 ==")
    val conf = Conf(mapOf("host" to "db.local", "port" to 5432, "debug" to true))
    println("${conf.host}:${conf.port} debug=${conf.debug}")
}
