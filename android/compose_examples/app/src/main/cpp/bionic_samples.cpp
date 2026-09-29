// 第 29 章：Bionic libc 与 C++ 标准库
// Kotlin 侧镜像：jni/BionicBridge.kt
#include <jni.h>
#include <cerrno>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>
#include <algorithm>
#include <typeinfo>

#include <unistd.h>     // sysconf / getuid
#include <pwd.h>        // getpwuid
#include <sys/system_properties.h>  // __system_property_get（Bionic 扩展）

// ---------- 系统配置：sysconf ----------
extern "C" JNIEXPORT jint JNICALL
Java_guide_android_compose_jni_BionicBridge_bionicPageSize(JNIEnv* env, jobject) {
    long page = sysconf(_SC_PAGESIZE);  // _SC_PAGESIZE 是 POSIX 名，Linux 上同 _SC_PAGE_SIZE
    return (jint) page;
}

extern "C" JNIEXPORT jint JNICALL
Java_guide_android_compose_jni_BionicBridge_bionicCpuCount(JNIEnv* env, jobject) {
    return (jint) sysconf(_SC_NPROCESSORS_CONF);
}

// ---------- 系统属性：Bionic 的 __system_property_get ----------
// ro.* 属性是只读的系统事实（SDK 版本、机型、ABI）；getprop 命令读的同一来源。
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_BionicBridge_bionicSdkProp(JNIEnv* env, jobject) {
    char value[PROP_VALUE_MAX] = {0};
    int len = __system_property_get("ro.build.version.sdk", value);
    if (len <= 0) {
        return env->NewStringUTF("读取失败");
    }
    return env->NewStringUTF(value);
}

// ---------- 用户与组：每个 app 一个 UID（沙箱） ----------
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_BionicBridge_bionicUidInfo(JNIEnv* env, jobject) {
    uid_t uid = getuid();
    gid_t gid = getgid();
    struct passwd* pw = getpwuid(uid);  // Bionic 实现；查不到时返回 nullptr
    char buf[256];
    if (pw != nullptr) {
        snprintf(buf, sizeof(buf), "uid=%u gid=%u 用户名=%s", uid, gid, pw->pw_name);
    } else {
        snprintf(buf, sizeof(buf), "uid=%u gid=%u（getpwuid 查不到用户名）", uid, gid);
    }
    return env->NewStringUTF(buf);
}

// ---------- 标准 C 文件 I/O：FILE* 全家桶 ----------
// 与 Kotlin 的 File API 是两个世界；path 由 Kotlin 侧传应用内部存储路径
//（第 09 章的 filesDir），native 无权限也不应该碰应用沙箱之外。
extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_BionicBridge_bionicFileRoundTrip(
        JNIEnv* env, jobject, jstring path, jstring content) {
    const char* pathChars = env->GetStringUTFChars(path, nullptr);
    const char* contentChars = env->GetStringUTFChars(content, nullptr);
    std::string result;

    FILE* out = fopen(pathChars, "wb");
    if (out != nullptr) {
        size_t written = fwrite(contentChars, 1, strlen(contentChars), out);
        fclose(out);
        FILE* in = fopen(pathChars, "rb");
        if (in != nullptr) {
            char buf[512];
            size_t got = fread(buf, 1, sizeof(buf) - 1, in);
            buf[got] = '\0';
            fclose(in);
            result = std::string("写入 ") + std::to_string(written) + " 字节，回读 " +
                     std::to_string(got) + " 字节：" + buf;
        }
    } else {
        result = std::string("fopen 失败: ") + strerror(errno);
    }

    env->ReleaseStringUTFChars(content, contentChars);
    env->ReleaseStringUTFChars(path, pathChars);
    return env->NewStringUTF(result.c_str());
}

// ---------- C++ 标准库：容器 + 算法 ----------
// NDK 现役运行库 c++_shared/c++_static 都带完整 STL；
// 当年的 GAbi++/STLport/GNU STL 已全部退役（教程 29 章校准表）。
extern "C" JNIEXPORT jdoubleArray JNICALL
Java_guide_android_compose_jni_BionicBridge_bionicSortDoubles(JNIEnv* env, jobject, jdoubleArray arr) {
    const jsize len = env->GetArrayLength(arr);
    std::vector<jdouble> v((size_t) len);
    env->GetDoubleArrayRegion(arr, 0, len, v.data());
    std::sort(v.begin(), v.end());
    jdoubleArray out = env->NewDoubleArray(len);
    env->SetDoubleArrayRegion(out, 0, len, v.data());
    return out;
}

// ---------- C++ 特性开关：异常与 RTTI 都默认可用 ----------
// 当年要 Application.mk 里 APP_GNUSTL_FORCE_CPP_FEATURES 显式打开；
// 现代 NDK（c++_static/c++_shared）默认 -fexceptions -frtti。
struct Base { virtual ~Base() = default; };
struct Derived : Base {};

extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_BionicBridge_bionicCppFeatures(JNIEnv* env, jobject) {
    std::string report;
    try {
        throw std::string("异常已启用");  // 抛字符串足够证明 -fexceptions 生效
    } catch (const std::string& what) {
        report = what;
    }
    Derived d;
    Base* b = &d;
    if (dynamic_cast<Derived*>(b) != nullptr) {  // dynamic_cast 证明 -frtti 生效
        report += "，RTTI 已启用（dynamic_cast 成功）";
    }
    report += "，typeid 名：";
    report += typeid(*b).name();
    return env->NewStringUTF(report.c_str());
}
