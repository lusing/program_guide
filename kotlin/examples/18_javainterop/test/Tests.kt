// 18 的测试：双向互操作行为
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

fun testKotlinCallsJava() {
    assertEquals("[kt]", Lib.nick("kt"))
    assertEquals("备用", Lib.firstNonEmpty("", "备用"))
    assertEquals("主", Lib.firstNonEmpty("主", "备"))
    assertNull(Lib.firstNonEmpty("", null))
    assertEquals(50, Lib.runOp(5) { it * 10 })
    Lib.base = 7
    assertEquals(7, Lib.base)
    Lib.setBase2(3)                                  // 静态 get/set 不合成属性
    assertEquals(3, Lib.getBase2())
}

fun testJavaCallsKotlin() {
    val out = Caller.demo()
    assertTrue("MathKit.square(7) = 49" in out, out)
    assertTrue("MathKit.scale(5) = 10" in out)          // @JvmOverloads 默认参数
    assertTrue("Meter.value = 9" in out)                 // @JvmField
    assertTrue("StrKit.shout(\"hey\") = HEY!" in out)    // @JvmName ×2
    assertTrue("safeLen(null) = 0" in out)
    assertTrue("负数: -1" in out)                         // @Throws
    assertTrue("Lib.runOp(6, x -> x * 3) = 18" in out)
    assertTrue("Lib.base=7, Lib.base2=11" in out)
}

fun testJvmStatics() {
    // @JvmStatic 的效果：不用 MathKit.INSTANCE.square 也能从 Java 调（Caller 已验证）；
    // Kotlin 侧调用形式不变
    assertEquals(49, MathKit.square(7))
    assertEquals(10, MathKit.scale(5))
    assertEquals(50, MathKit.scale(5, 10))
}

fun main() {
    testKotlinCallsJava()
    testJavaCallsKotlin()
    testJvmStatics()
    assertNotNull(Lib.firstNonEmpty("x", null))
    println("18_javainterop 全部测试通过")
}
