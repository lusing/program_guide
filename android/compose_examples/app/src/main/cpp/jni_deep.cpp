// 第 28 章：JNI 深入——字符串/数组/NIO/域/方法/异常/引用
// Kotlin 侧镜像：jni/JniDeepBridge.kt
#include <jni.h>
#include <cmath>
#include <cstring>
#include <string>

// ---------- 字符串 ----------

// 进：GetStringUTFChars 读入 + ReleaseStringUTFChars 配对释放；
// 出：std::string 自由加工，NewStringUTF 包装返回（返回值归 GC，勿手动释放）。
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativeGreet(JNIEnv* env, jobject, jstring name) {
    const char* nameChars = env->GetStringUTFChars(name, nullptr);
    if (nameChars == nullptr) {
        return env->NewStringUTF("OOM");
    }
    std::string greeting = std::string("你好，") + nameChars + "！这段话在 C++ 里拼好";
    env->ReleaseStringUTFChars(name, nameChars);
    return env->NewStringUTF(greeting.c_str());
}

// ---------- 数组：Region 拷贝路线 ----------
// GetIntArrayRegion 把 Java 数组的一段拷进 C 数组，用完不需要"释放"
// （栈上数组自己会死）——适合一次性读走。
extern "C" JNIEXPORT jlong JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativeSumIntArray(JNIEnv* env, jobject, jintArray arr) {
    const jsize len = env->GetArrayLength(arr);
    if (len == 0) {
        return 0;
    }
    // 教学场景直接开栈；真实代码大数组请用 std::vector，避免栈溢出
    jint buf[256];
    jsize take = len > 256 ? 256 : len;
    env->GetIntArrayRegion(arr, 0, take, buf);
    jlong sum = 0;
    for (jsize i = 0; i < take; i++) {
        sum += buf[i];
    }
    return sum;
}

// ---------- 数组：Elements 直接指针路线 ----------
// GetDoubleArrayElements 可能返回副本（isCopy），也可能直接指堆；
// Release 第三参数是释放模式：0 = 拷回并释放，JNI_COMMIT = 只拷回，
// JNI_ABORT = 只释放不拷回（只读场景用它最省）。
extern "C" JNIEXPORT void JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativeScaleArrayInPlace(
        JNIEnv* env, jobject, jdoubleArray arr, jdouble factor) {
    jboolean isCopy = JNI_FALSE;
    jdouble* elems = env->GetDoubleArrayElements(arr, &isCopy);
    if (elems == nullptr) {
        return;
    }
    const jsize len = env->GetArrayLength(arr);
    for (jsize i = 0; i < len; i++) {
        elems[i] *= factor;
    }
    // 0 模式：修改拷回 Java 数组并释放原生缓冲——"原地缩放"由此生效
    env->ReleaseDoubleArrayElements(arr, elems, 0);
    (void) isCopy;
}

// ---------- NIO 直接字节缓冲区 ----------
// 原生 malloc 的内存不在 GC 管辖内：谁 malloc 谁负责 free（nativeFreeDirectBuffer）。
static jobject make_direct_buffer(JNIEnv* env, jint capacity) {
    auto* raw = static_cast<unsigned char*>(malloc(capacity));
    if (raw == nullptr) {
        return nullptr;
    }
    memset(raw, 0, (size_t) capacity);
    return env->NewDirectByteBuffer(raw, (jlong) capacity);
}

extern "C" JNIEXPORT jobject JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativeMakeDirectBuffer(JNIEnv* env, jobject, jint capacity) {
    return make_direct_buffer(env, capacity);
}

extern "C" JNIEXPORT jlong JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativeDirectBufferSum(JNIEnv* env, jobject, jobject buf) {
    auto* raw = static_cast<unsigned char*>(env->GetDirectBufferAddress(buf));
    jlong capacity = env->GetDirectBufferCapacity(buf);
    if (raw == nullptr || capacity < 0) {
        return -1;
    }
    jlong sum = 0;
    for (jlong i = 0; i < capacity; i++) {
        sum += raw[i];
    }
    return sum;
}

extern "C" JNIEXPORT jboolean JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativeFreeDirectBuffer(JNIEnv* env, jobject, jobject buf) {
    auto* raw = static_cast<unsigned char*>(env->GetDirectBufferAddress(buf));
    if (raw == nullptr) {
        return JNI_FALSE;
    }
    free(raw);
    return JNI_TRUE;
}

// ---------- 访问域：GetObjectClass + GetFieldID + Get/SetIntField ----------
// 域 ID 用描述符 "I"（Int）定位字段；跨类复用 JniDeepBridge.JniCounter 实例。
extern "C" JNIEXPORT jint JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativeBumpCounter(JNIEnv* env, jobject, jobject counter) {
    jclass clazz = env->GetObjectClass(counter);
    jfieldID fieldId = env->GetFieldID(clazz, "count", "I");
    if (fieldId == nullptr) {
        env->ExceptionClear();
        return -1;
    }
    jint value = env->GetIntField(counter, fieldId);
    value += 1;
    env->SetIntField(counter, fieldId, value);
    env->DeleteLocalRef(clazz);
    return value;
}

// ---------- 调用方法：实例方法回调 Kotlin ----------
// thiz 就是 JniDeepBridge 单例本身；GetMethodID 的第三参数是方法描述符。
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativePingSelf(JNIEnv* env, jobject thiz, jstring tag) {
    jclass clazz = env->GetObjectClass(thiz);
    jmethodID methodId = env->GetMethodID(clazz, "pingFromKotlin", "(Ljava/lang/String;)Ljava/lang/String;");
    if (methodId == nullptr) {
        env->ExceptionClear();
        return env->NewStringUTF("找不到 pingFromKotlin");
    }
    // CallObjectMethod 会跑回 Kotlin 执行 pingFromKotlin，再带着结果回 native
    jstring reply = static_cast<jstring>(env->CallObjectMethod(thiz, methodId, tag));
    env->DeleteLocalRef(clazz);
    return reply;
}

// ---------- 调用方法：静态方法 ----------
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativeStaticInfo(JNIEnv* env, jobject thiz) {
    jclass clazz = env->GetObjectClass(thiz);
    jmethodID methodId = env->GetStaticMethodID(clazz, "staticInfo", "()Ljava/lang/String;");
    if (methodId == nullptr) {
        env->ExceptionClear();
        return env->NewStringUTF("找不到 staticInfo");
    }
    jstring reply = static_cast<jstring>(env->CallStaticObjectMethod(clazz, methodId));
    env->DeleteLocalRef(clazz);
    return reply;
}

// ---------- 异常：native 主动抛 ----------
// ThrowNew 只是"挂起"一个待处理异常，native 代码不会自动停止——
// 抛完必须自己收尾（释放资源、返回哨兵值），把控制权交回 Java 侧。
extern "C" JNIEXPORT jdouble JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativeCheckedSqrt(JNIEnv* env, jobject, jdouble x) {
    if (x < 0) {
        jclass clazz = env->FindClass("java/lang/IllegalArgumentException");
        if (clazz != nullptr) {
            env->ThrowNew(clazz, "nativeCheckedSqrt: 负数没有实平方根（异常从 C++ 抛出）");
            env->DeleteLocalRef(clazz);
        }
        return NAN;  // 哨兵值：Java 侧要么收到异常，要么收到 NaN
    }
    return sqrt(x);
}

// ---------- 异常：捕获 Kotlin 侧抛出的 ----------
// 调用的方法可能抛异常；ExceptionOccurred 查询后必须 ExceptionClear，
// 否则异常一路"挂"着，返回 Java 时炸在无关位置。
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativeCatchAndReport(JNIEnv* env, jobject thiz) {
    jclass clazz = env->GetObjectClass(thiz);
    jmethodID methodId = env->GetMethodID(clazz, "boom", "()Ljava/lang/String;");
    env->CallObjectMethod(thiz, methodId);  // Kotlin 侧 boom() 必抛 IllegalStateException
    jthrowable ex = env->ExceptionOccurred();
    if (ex != nullptr) {
        env->ExceptionClear();
        jclass throwableClazz = env->FindClass("java/lang/Throwable");
        jmethodID getMessage = env->GetMethodID(throwableClazz, "getMessage", "()Ljava/lang/String;");
        jstring message = static_cast<jstring>(env->CallObjectMethod(ex, getMessage));
        const char* chars = env->GetStringUTFChars(message, nullptr);
        std::string result = std::string("native 捕获并清除异常：") + chars;
        env->ReleaseStringUTFChars(message, chars);
        env->DeleteLocalRef(clazz);
        env->DeleteLocalRef(throwableClazz);
        env->DeleteLocalRef(ex);
        return env->NewStringUTF(result.c_str());
    }
    env->DeleteLocalRef(clazz);
    return env->NewStringUTF("没有异常发生？boom 应当抛异常");
}

// ---------- 引用三档：全局引用跨调用存活 ----------
static jstring g_rememberedTag = nullptr;  // 全局引用：显式 DeleteGlobalRef 前一直有效

extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativeRememberTag(JNIEnv* env, jobject, jstring tag) {
    if (g_rememberedTag != nullptr) {
        env->DeleteGlobalRef(g_rememberedTag);  // 记新的之前先放旧的，防泄漏
    }
    g_rememberedTag = static_cast<jstring>(env->NewGlobalRef(tag));
    return tag;
}

extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativeRecallTag(JNIEnv* env, jobject) {
    if (g_rememberedTag == nullptr) {
        return env->NewStringUTF("（还没有记住任何 tag，先点 Remember）");
    }
    return g_rememberedTag;  // 全局引用可直接返回，JVM 侧照常使用
}

extern "C" JNIEXPORT void JNICALL
Java_guide_android_compose_jni_JniDeepBridge_nativeForgetTag(JNIEnv* env, jobject) {
    if (g_rememberedTag != nullptr) {
        env->DeleteGlobalRef(g_rememberedTag);
        g_rememberedTag = nullptr;
    }
}
