package guide.android.compose.jni

object GuideNativeBridge {
    init {
        System.loadLibrary("guide_native")
    }

    external fun stringFromJNI(): String

    /** 第 20 章：把日志写进 logcat（native 世界的"打印"出口），返回描述 */
    external fun logFromNative(tag: String): String
}
