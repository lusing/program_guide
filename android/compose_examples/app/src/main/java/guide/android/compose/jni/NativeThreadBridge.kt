package guide.android.compose.jni

/**
 * 第 23 章原生线程与同步。
 * 镜像文件：cpp/native_threads.cpp（回调方法在 JNI_OnLoad 里预取并缓存）
 */
object NativeThreadBridge {
    init {
        System.loadLibrary("guide_native")
    }

    /** pthread_create + mutex + condvar：worker 线程算 1..n 求和 */
    external fun threadSpawnSum(n: Int): Long

    /** AttachCurrentThread：原生线程附着到虚拟机后回调 [onNativeMessage] */
    external fun threadNotifyBack(value: Int): String

    /** 信号量两线程乒乓 count 个来回，返回完成的回合数 */
    external fun threadSemPingpong(count: Int): Int

    /** 调度策略与优先级现实探测（SCHED_OTHER 恒 0） */
    external fun threadSchedInfo(): String

    /** 原生线程回调的落点；threadNotifyBack 返回前已完成 join，读它没有竞态 */
    @JvmField
    var lastNativeMessage: String? = null

    @JvmStatic
    fun onNativeMessage(message: String) {
        lastNativeMessage = message
    }
}
