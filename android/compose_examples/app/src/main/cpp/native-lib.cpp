// 第 20 章：JNI 最小闭环 + 原生日志 + JNI_OnLoad
// Kotlin 侧镜像：jni/GuideNativeBridge.kt
#include <jni.h>
#include <string>
#include <unistd.h>

#include <android/log.h>

// 第 23 章 native_threads.cpp 使用：JNI_OnLoad 时缓存 JavaVM。
// JNIEnv 是线程局部的，不能缓存跨线程使用；JavaVM 是进程级的，可以。
// （JNI_OnLoad 全库只定义一次，在 native_threads.cpp，那里顺带预取回调类）
JavaVM* g_guideJavaVm = nullptr;

extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_GuideNativeBridge_stringFromJNI(JNIEnv* env, jobject) {
    std::string message = "hello from C++ JNI";
    return env->NewStringUTF(message.c_str());
}

// 原生日志：printf 在 Android 上没有控制台可去，标准输出是空的；
// native 世界的"打印"出口是 logcat（教程 20 章第 8 节）。
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_GuideNativeBridge_logFromNative(JNIEnv* env, jobject, jstring tag) {
    const char* tagChars = env->GetStringUTFChars(tag, nullptr);
    if (tagChars == nullptr) {
        return env->NewStringUTF("GetStringUTFChars 失败（OOM 时返回 null）");
    }
    __android_log_print(ANDROID_LOG_INFO, tagChars, "hello from native code, tid=%d", (int) gettid());
    std::string result = std::string("已写入 logcat（tag=") + tagChars + "）";
    env->ReleaseStringUTFChars(tag, tagChars);
    return env->NewStringUTF(result.c_str());
}
