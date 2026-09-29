package guide.android.compose.jni

import android.graphics.Bitmap

/**
 * 第 32 章原生图形、音频与 NEON。
 * 镜像文件：cpp/native_media.cpp
 */
object MediaBridge {
    init {
        System.loadLibrary("guide_native")
    }

    /** JNI Graphics：AndroidBitmap_getInfo/lockPixels 直访像素（只吃软件位图） */
    external fun mediaBitmapInfo(bitmap: Bitmap): String

    /** NEON：vaddq_s16 一条指令 8 路 int16 加法（arm64 NEON 必备） */
    external fun mediaNeonAddShorts(a: ShortArray, b: ShortArray): ShortArray?

    /** OpenSL ES 引擎创建/销毁探测（API 34 起 deprecated，见教程校准节） */
    external fun mediaOpenSlProbe(): String

    /** EGL 显示连接初始化探测（版本串来自 eglQueryString） */
    external fun mediaEglProbe(): String
}
