cmake_minimum_required(VERSION 3.22.1)
project(guide_native)

# 一个 .so 对应第 27–32 章全部原生示例：
#   native-lib.cpp      第 27 章：JNI 最小闭环 + 原生日志 + JNI_OnLoad 缓存 JavaVM
#   jni_deep.cpp        第 28 章：字符串/数组/NIO/域/方法/异常/引用
#   bionic_samples.cpp  第 29 章：Bionic libc 与 C++ 标准库
#   native_threads.cpp  第 30 章：pthread/互斥/条件变量/信号量/AttachCurrentThread
#   native_sockets.cpp  第 31 章：TCP/UDP/UNIX domain socket 回环 echo
#   native_media.cpp    第 32 章：Bitmap 直访/OpenSL ES/EGL 探测/NEON
add_library(
    guide_native
    SHARED
    native-lib.cpp
    jni_deep.cpp
    bionic_samples.cpp
    native_threads.cpp
    native_sockets.cpp
    native_media.cpp
)

# log          —— __android_log_print（第 27 章）
# jnigraphics  —— AndroidBitmap_*（第 32 章）
# OpenSLES     —— slCreateEngine（第 32 章，API 34 起 deprecated，教学探测用）
# EGL          —— eglGetDisplay/eglInitialize（第 32 章）
find_library(log-lib log)
target_link_libraries(
    guide_native
    ${log-lib}
    jnigraphics
    OpenSLES
    EGL
)
