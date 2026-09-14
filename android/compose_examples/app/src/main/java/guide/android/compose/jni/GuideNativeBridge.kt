package guide.android.compose.jni

object GuideNativeBridge {
    init {
        System.loadLibrary("guide_native")
    }

    external fun stringFromJNI(): String
}
