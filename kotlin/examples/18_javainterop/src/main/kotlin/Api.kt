// Kotlin 侧的 API：Java 会调用它（kotlinc 编译后，javac -cp 引用）
// @file:JvmMultifileClass：允许 More.kt 等其他文件的同名门面类合并进 StrKit（两份文件都要标）
@file:JvmName("StrKit")
@file:JvmMultifileClass

/** @JvmStatic：让 companion/object 里的函数以真正的静态方法暴露给 Java */
object MathKit {
    @JvmStatic
    fun square(x: Int): Int = x * x

    @JvmStatic
    @JvmOverloads                       // 为默认参数生成全部重载：f(a), f(a, b)
    fun scale(x: Int, k: Int = 2): Int = x * k
}

/** @JvmField：把属性编译成真字段（没有 getter/setter） */
class Meter(@JvmField var value: Int) {
    /** 默认参数方法：Java 侧必须全量传参，除非标 @JvmOverloads */
    fun show(unit: String = "m") = "$value$unit"

    /** @Throws：让 Java 调用方在签名里看到受检异常（Kotlin 没有 checked exception） */
    @Throws(IllegalArgumentException::class)
    fun requirePositive() {
        if (value < 0) throw IllegalArgumentException("负数: $value")
    }
}

/** @JvmName（函数级）：改 JVM 方法名，常用于扩展函数（否则编译名是 upperShout 加尾巴） */
@JvmName("shout")
fun String.upperShout(): String = uppercase() + "!"

/** 可空参数：Java 的 null 可以传进来，Kotlin 在边界上守住 */
fun safeLen(s: String?): Int = s?.length ?: 0
