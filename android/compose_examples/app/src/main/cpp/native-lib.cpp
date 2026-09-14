#include <jni.h>
#include <string>

extern "C" JNIEXPORT jstring JNICALL
Java_guide_android_compose_jni_GuideNativeBridge_stringFromJNI(JNIEnv* env, jobject) {
    std::string message = "hello from C++ JNI";
    return env->NewStringUTF(message.c_str());
}

