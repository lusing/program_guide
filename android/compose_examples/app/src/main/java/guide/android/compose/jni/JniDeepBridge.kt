package guide.android.compose.jni

import java.nio.ByteBuffer

/**
 * 第 21 章 JNI 深入：字符串/数组/NIO/域/方法/异常/引用。
 * 镜像文件：cpp/jni_deep.cpp——改方法名/签名时两边必须同步。
 */
object JniDeepBridge {
    init {
        System.loadLibrary("guide_native")
    }

    /** 供 nativeBumpCounter 演示"访问域"：一个带实例字段 count 的普通类 */
    class JniCounter {
        var count: Int = 0
    }

    /** 字符串进出：GetStringUTFChars 读入 → C++ 加工 → NewStringUTF 返回 */
    external fun nativeGreet(name: String): String

    /** 数组 Region 路线：GetIntArrayRegion 一次拷贝读走求和（超过 256 个只取前 256） */
    external fun nativeSumIntArray(arr: IntArray): Long

    /** 数组 Elements 路线：GetDoubleArrayElements 直接指针，原地缩放后拷回 */
    external fun nativeScaleArrayInPlace(arr: DoubleArray, factor: Double)

    /** NIO：malloc 一块 native 内存包装成直接 ByteBuffer（不归 GC 管！） */
    external fun nativeMakeDirectBuffer(capacity: Int): ByteBuffer?

    /** NIO：GetDirectBufferAddress 直读缓冲区求和 */
    external fun nativeDirectBufferSum(buf: ByteBuffer): Long

    /** NIO：手动释放 nativeMakeDirectBuffer 的内存——谁 malloc 谁负责 free */
    external fun nativeFreeDirectBuffer(buf: ByteBuffer): Boolean

    /** 访问域：GetObjectClass + GetFieldID("count","I") + Get/SetIntField */
    external fun nativeBumpCounter(counter: JniCounter): Int

    /** 调用实例方法：native 经 GetMethodID 回调本对象的 pingFromKotlin */
    external fun nativePingSelf(tag: String): String

    /** 调用静态方法：GetStaticMethodID + CallStaticObjectMethod */
    external fun nativeStaticInfo(): String

    /** native 主动抛异常：负数时 ThrowNew IllegalArgumentException */
    external fun nativeCheckedSqrt(x: Double): Double

    /** native 捕获异常：调用会抛异常的 boom()，ExceptionClear 后报告消息 */
    external fun nativeCatchAndReport(): String

    /** 全局引用：NewGlobalRef 把局部引用提升为跨调用存活 */
    external fun nativeRememberTag(tag: String): String

    /** 全局引用跨调用存活：上次 Remember 的值仍可取回 */
    external fun nativeRecallTag(): String

    /** DeleteGlobalRef 显式释放；弱全局引用见教程 21 章第 8 节 */
    external fun nativeForgetTag()

    // ---- 供 native 回调的方法（描述符见 cpp 注释）----

    fun pingFromKotlin(tag: String): String = "Kotlin 收到 ping：$tag（这行字是 native 调回 Java 世界执行的）"

    /** 会被 nativeCatchAndReport 调用并抛异常 */
    @Suppress("RedundantNullableReturnType")
    fun boom(): String = throw IllegalStateException("boom！这颗雷是 native 引爆后自己接住的")

    /** object 成员标 @JvmStatic 即生成真静态方法，native 侧 GetStaticMethodID 可见 */
    @JvmStatic
    fun staticInfo(): String = "staticInfo 由 CallStaticObjectMethod 调用"
}
