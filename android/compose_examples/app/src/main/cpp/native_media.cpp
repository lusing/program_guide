// 第 25 章：原生图形、音频与 NEON——Bitmap 直访/OpenSL ES/EGL 探测/NEON intrinsics
// Kotlin 侧镜像：jni/MediaBridge.kt
#include <jni.h>
#include <cstdio>
#include <string>

#include <android/bitmap.h>
#include <arm_neon.h>      // arm64 上 NEON 必备（32 位 armv7 才需要运行时探测）
#include <EGL/egl.h>
#include <SLES/OpenSLES.h>

// ---------- JNI Graphics：AndroidBitmap_* 直访像素 ----------
// 这是 NDK 的稳定 API（libjnigraphics）；只适用于软件位图
//（Bitmap.Config.ARGB_8888/RGB_565 等，硬件位图须先转软件）。
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_MediaBridge_mediaBitmapInfo(JNIEnv* env, jobject, jobject bitmap) {
    AndroidBitmapInfo info{};
    if (AndroidBitmap_getInfo(env, bitmap, &info) != ANDROID_BITMAP_RESULT_SUCCESS) {
        return env->NewStringUTF("AndroidBitmap_getInfo 失败");
    }
    const char* formatName = "未知";
    switch (info.format) {
        case ANDROID_BITMAP_FORMAT_RGBA_8888: formatName = "RGBA_8888"; break;
        case ANDROID_BITMAP_FORMAT_RGB_565:   formatName = "RGB_565";   break;
        case ANDROID_BITMAP_FORMAT_RGBA_4444: formatName = "RGBA_4444"; break;
        case ANDROID_BITMAP_FORMAT_A_8:       formatName = "A_8";       break;
        default: break;
    }
    void* pixels = nullptr;
    bool locked = AndroidBitmap_lockPixels(env, bitmap, &pixels) == ANDROID_BITMAP_RESULT_SUCCESS;
    if (locked) {
        AndroidBitmap_unlockPixels(env, bitmap);  // lock/unlock 必须配对
    }
    char buf[256];
    snprintf(buf, sizeof(buf), "%dx%d，格式 %s，stride=%u 字节，像素%s直访（%s）",
             info.width, info.height, formatName, info.stride,
             locked ? "可" : "不可",
             locked ? "lockPixels 成功后可整帧读写" : "lockPixels 失败");
    return env->NewStringUTF(buf);
}

// ---------- NEON intrinsics：128 位向量一次加 8 个 short ----------
extern "C" JNIEXPORT jshortArray JNICALL
Java_guide_android_compose_jni_MediaBridge_mediaNeonAddShorts(
        JNIEnv* env, jobject, jshortArray a, jshortArray b) {
    const jsize len = env->GetArrayLength(a);
    jshortArray out = env->NewShortArray(len);
    // 取 8 的倍数做向量化段，尾巴逐个处理（NEON 寄存器 128 位 = 8 × int16）
    jsize vecLen = len / 8 * 8;

    jshort bufA[8], bufB[8];
    jsize i = 0;
    for (; i + 8 <= vecLen; i += 8) {
        env->GetShortArrayRegion(a, i, 8, bufA);
        env->GetShortArrayRegion(b, i, 8, bufB);
        int16x8_t va = vld1q_s16(bufA);      // 载入 128 位
        int16x8_t vb = vld1q_s16(bufB);
        int16x8_t sum = vaddq_s16(va, vb);   // 一条指令完成 8 路加法
        vst1q_s16(bufA, sum);
        env->SetShortArrayRegion(out, i, 8, bufA);
    }
    for (; i < len; i++) {                   // 标量尾巴
        jshort xa = 0, xb = 0;
        env->GetShortArrayRegion(a, i, 1, &xa);
        env->GetShortArrayRegion(b, i, 1, &xb);
        jshort s = (jshort) (xa + xb);
        env->SetShortArrayRegion(out, i, 1, &s);
    }
    return out;
}

// ---------- OpenSL ES：引擎创建/销毁探测 ----------
// API 34 起官方标记 deprecated（接班的是 AAudio，API 26+）；大量存量代码仍在用，
// 这里只做"能建引擎、能销毁"的探测，教学定位。
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_MediaBridge_mediaOpenSlProbe(JNIEnv* env, jobject) {
    SLObjectItf engineObject = nullptr;
    // 六参：引擎出参 / 选项数 / 选项 / 接口数 / 接口 ID 数组 / 必选标志数组
    SLresult result = slCreateEngine(&engineObject, 0, nullptr, 0, nullptr, nullptr);
    if (result != SL_RESULT_SUCCESS || engineObject == nullptr) {
        return env->NewStringUTF("slCreateEngine 失败");
    }
    result = (*engineObject)->Realize(engineObject, SL_BOOLEAN_FALSE);
    std::string report = (result == SL_RESULT_SUCCESS)
            ? "OpenSL ES 引擎创建并 Realize 成功（已销毁）"
            : "引擎 Realize 失败";
    (*engineObject)->Destroy(engineObject);
    return env->NewStringUTF(report.c_str());
}

// ---------- EGL：显示连接初始化探测 ----------
// 应用层常规路径是 GLSurfaceView（教程 25 章校准节）；EGL 原生 API
// 属于"自己管 GL 上下文"的场景（引擎/播放器内嵌渲染）。
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_MediaBridge_mediaEglProbe(JNIEnv* env, jobject) {
    EGLDisplay display = eglGetDisplay(EGL_DEFAULT_DISPLAY);
    if (display == EGL_NO_DISPLAY) {
        return env->NewStringUTF("eglGetDisplay 失败（无默认显示连接）");
    }
    EGLint major = 0, minor = 0;
    if (!eglInitialize(display, &major, &minor)) {
        return env->NewStringUTF("eglInitialize 失败");
    }
    const char* version = eglQueryString(display, EGL_VERSION);
    std::string report = std::string("EGL 初始化成功，版本 ") + (version ? version : "?") +
                         "（已终止连接）";
    eglTerminate(display);
    return env->NewStringUTF(report.c_str());
}
