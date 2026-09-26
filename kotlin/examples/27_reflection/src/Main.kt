// 27 · 注解与反射：annotation class、元注解、使用处目标、KClass/KFunction/KProperty、泛型反射、迷你 @Test 框架
// 注：supertypes/annotations/typeParameters 在 2.4.20 是 KClass 成员（不用 import）；
//     declaredFunctions/findAnnotation/primaryConstructor 是 kotlin.reflect.full 扩展（要 import）
import kotlin.reflect.KClass
import kotlin.reflect.full.declaredFunctions
import kotlin.reflect.full.findAnnotation
import kotlin.reflect.full.hasAnnotation
import kotlin.reflect.full.primaryConstructor
import kotlin.reflect.jvm.javaMethod

// ---- 注解定义区 ----

/** 有默认值的注解参数 */
annotation class TestCase(val id: String, val shouldPass: Boolean = true)

/** 元注解示范（@Repeatable 在 JVM 侧会拆出 java/kotlin 两份、输出重复，教学示例略去——见文档表格） */
@Target(AnnotationTarget.FUNCTION, AnnotationTarget.CLASS)
@Retention(AnnotationRetention.RUNTIME)
@MustBeDocumented
annotation class Route(val path: String)

/** 数据库列名——演示使用处目标 */
annotation class Column(val name: String)

class Row(
    @param:Column("构造参数") val id: Int,
    @field:Column("幕后字段") val score: Int,
    @get:Column("getter") val level: Int,
    @Column("裸写") val name: String,          // 不加前缀 → 落到 param（param > property > field）
)

// ---- 被反射的目标类型 ----

fun isOdd(x: Int) = x % 2 != 0

data class P(val x: Int, val y: Int)

class Calc {
    fun twice(x: Int) = x * 2
    fun greet(name: String) = "hi $name"
}

class Box<T : Comparable<T>>(val value: T)

class StringList : ArrayList<String>()

// ---- 27.7 迷你测试框架 ----

class CalcCases {
    @TestCase("add") fun add() { check(1 + 1 == 2) }
    @TestCase("mul") fun mul() { check(3 * 3 == 9) }
    @TestCase("boom", shouldPass = false) fun boom() { error("预期失败演示") }
}

fun runTests(instance: Any): List<String> =
    instance::class.declaredFunctions
        .filter { it.hasAnnotation<TestCase>() }
        .sortedBy { it.findAnnotation<TestCase>()!!.id }
        .map { f ->
            val a = f.findAnnotation<TestCase>()!!
            try {
                f.call(instance)
                if (a.shouldPass) "${a.id}: PASS" else "${a.id}: FAIL(意外通过)"
            } catch (e: Exception) {
                if (a.shouldPass) "${a.id}: FAIL" else "${a.id}: XFAIL"
            }
        }

var counter = 41   // 顶层 var：演示属性引用

fun main() {
    println("== 27.1 声明注解 ==")
    val anno = CalcCases()::class.declaredFunctions
        .first { it.findAnnotation<TestCase>()?.id == "add" }
        .findAnnotation<TestCase>()!!
    println("注解实例字段直接访问: id=${anno.id}, shouldPass=${anno.shouldPass}")
    println("参数类型白名单: 基本类型/String/枚举/KClass/注解/数组；可空或自定义类直接编译不过")

    println("== 27.2 元注解四件套 ==")
    val meta = Route::class.annotations
    println("Route 上的元注解: ${meta.map { it.annotationClass.simpleName ?: "?" }.sorted()}")
    println("允许位置: ${meta.filterIsInstance<Target>().single().allowedTargets.joinToString()}")
    println("保留策略: ${meta.filterIsInstance<Retention>().single().value}（Kotlin 默认，Java 默认 CLASS——跨语言最常踩差异）")

    println("== 27.3 使用处目标 ==")
    val jc = Row::class.java
    fun Column.s() = name
    println("字段 id   上看到: ${jc.getDeclaredField("id").getDeclaredAnnotationsByType(Column::class.java).map { it.s() }}")
    println("字段 score上看到: ${jc.getDeclaredField("score").getDeclaredAnnotationsByType(Column::class.java).map { it.s() }}")
    println("getter level: ${jc.getDeclaredMethod("getLevel").getDeclaredAnnotationsByType(Column::class.java).map { it.s() }}")
    println("getter id  看到: ${jc.getDeclaredMethod("getId").getDeclaredAnnotationsByType(Column::class.java).map { it.s() }}（getter 没挂）")
    val ctorParams = jc.constructors.first().parameterAnnotations
    println("构造参数注解(按参数序): ${ctorParams.map { arr -> arr.map { (it as Column).name } }}")
    println("结论: @field: 挂字段、@get: 挂 getter、裸写落构造参数——库不生效先查挂点")

    println("== 27.4 ::class 与可调用引用 ==")
    val k: KClass<String> = String::class
    println("KClass=${k.simpleName}, 往返=${k.java.kotlin.simpleName}, javaClass=${"s".javaClass.simpleName}")
    println("::isOdd 当值传: ${listOf(1, 2, 3).filter(::isOdd)}")
    val f = ::isOdd
    println("函数引用即反射对象: name=${f.name}, params=${f.parameters.map { it.name }}, 返回=${f.returnType}")
    val up: () -> String = "kot"::uppercase
    println("绑定引用锁接收者: ${up()}（类型 () -> String，非 (String) -> String）")
    val ctor: (Int, Int) -> P = ::P
    println("构造器引用: ${ctor(3, 4)}")
    ::counter.set(42)
    println("属性引用可读可写: ::counter.get()=${::counter.get()}")

    println("== 27.5 反射 API ==")
    val kc = Calc::class
    println("declaredFunctions: ${kc.declaredFunctions.map { it.name }.sorted()}")
    println("primaryConstructor 调用造对象: ${P::class.primaryConstructor?.call(1, 2)}")
    val calc = Calc()
    val fn = kc.declaredFunctions.first { it.name == "twice" }
    println("反射调用 call: ${fn.call(calc, 21)}, javaMethod.invoke: ${fn.javaMethod?.invoke(calc, 21)}")

    println("== 27.6 泛型反射 ==")
    val tp = Box::class.typeParameters.single()
    println("Box 形参: name=${tp.name}, variance=${tp.variance}, isReified=${tp.isReified}, upperBounds=${tp.upperBounds}")
    val superWithArg = StringList::class.supertypes.first { it.classifier == ArrayList::class }
    println("StringList 继承链找回实参: $superWithArg -> ${superWithArg.arguments.first().type}")
    println("原理: 直接 Box<String>::class 拿不回 String（擦除），匿名子类把实参刻进父类签名")

    println("== 27.7 迷你 @Test 框架 ==")
    val results = runTests(CalcCases())
    results.forEach(::println)
    println("汇总: ${results.size} 例, ${results.count { it.endsWith("PASS") }} PASS, ${results.count { it.endsWith("XFAIL") }} XFAIL")
}
