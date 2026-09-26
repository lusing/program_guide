// 27 的测试：注解读取、使用处目标、可调用引用、反射调用、泛型反射、迷你框架
import kotlin.reflect.full.declaredFunctions
import kotlin.reflect.full.findAnnotation
import kotlin.reflect.full.hasAnnotation
import kotlin.reflect.full.primaryConstructor
import kotlin.reflect.jvm.javaMethod
import kotlin.test.assertEquals
import kotlin.test.assertTrue

fun testAnnotationInstance() {
    val addFn = CalcCases()::class.declaredFunctions.first { it.findAnnotation<TestCase>()?.id == "add" }
    val a = addFn.findAnnotation<TestCase>()!!
    assertEquals("add", a.id)
    assertTrue(a.shouldPass)
    val boom = CalcCases()::class.declaredFunctions.first { it.findAnnotation<TestCase>()?.id == "boom" }
    assertEquals(false, boom.findAnnotation<TestCase>()!!.shouldPass)
}

fun testUseSiteTargets() {
    val jc = Row::class.java
    assertEquals("构造参数", jc.constructors.single().parameterAnnotations[0]
        .map { (it as Column).name }.single())          // @param: 落构造参数
    assertEquals("幕后字段", jc.getDeclaredField("score")
        .getDeclaredAnnotationsByType(Column::class.java).single().name)   // @field:
    assertEquals("getter", jc.getDeclaredMethod("getLevel")
        .getDeclaredAnnotationsByType(Column::class.java).single().name)   // @get:
    assertEquals(0, jc.getDeclaredField("id").getDeclaredAnnotationsByType(Column::class.java).size)  // id 只挂了 param
    assertEquals("裸写", jc.constructors.single().parameterAnnotations[3]
        .map { (it as Column).name }.single())          // 裸写默认落 param
}

fun testReferences() {
    assertEquals(listOf(1, 3), listOf(1, 2, 3).filter(::isOdd))
    assertEquals("isOdd", (::isOdd).name)
    val up: () -> String = "kot"::uppercase
    assertEquals("KOT", up())
    val ctor: (Int, Int) -> P = ::P
    assertEquals(P(3, 4), ctor(3, 4))
    ::counter.set(7)
    assertEquals(7, ::counter.get())
    ::counter.set(41)                                    // 复位，Main 里还要用
}

fun testReflectionCall() {
    val kc = Calc::class
    assertEquals(listOf("greet", "twice"), kc.declaredFunctions.map { it.name }.sorted())
    val calc = Calc()
    val fn = kc.declaredFunctions.first { it.name == "twice" }
    assertEquals(42, fn.call(calc, 21))
    assertEquals(42, fn.javaMethod!!.invoke(calc, 21))
    assertEquals(P(1, 2), P::class.primaryConstructor!!.call(1, 2))
}

fun testGenericReflection() {
    val tp = Box::class.typeParameters.single()
    assertEquals("T", tp.name)
    assertEquals(false, tp.isReified)
    assertEquals(1, tp.upperBounds.size)
    val superWithArg = StringList::class.supertypes.first { it.classifier == ArrayList::class }
    assertEquals("kotlin.String", superWithArg.arguments.first().type.toString())
}

fun testMiniFramework() {
    val results = runTests(CalcCases())
    assertEquals(3, results.size)
    assertEquals(listOf("add: PASS", "boom: XFAIL", "mul: PASS"), results)
}

fun main() {
    testAnnotationInstance()
    testUseSiteTargets()
    testReferences()
    testReflectionCall()
    testGenericReflection()
    testMiniFramework()
    println("27_reflection 全部测试通过")
}
