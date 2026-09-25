// plugin_greeter.cpp —— 编译成 DLL（build.ps1 的 plugin_* 约定），
// 供 dll.cpp 宿主例程加载。用 C 导出（避免名字修饰）。
// 导出符号的写法三家不同，用宏统一（别 #if 掉一侧）：
//   MSVC / MinGW  __declspec(dllexport)
//   clang / GCC   __attribute__((visibility("default")))
// Unix 侧这行看着多余（默认就是可见的），但一旦宿主用 -fvisibility=hidden
// 编译库，缺它就会在 dlopen 后 dlsym 失败——写上是把意图固定下来。
#include <string>

#if defined(_MSC_VER) || defined(__MINGW32__)
#  define PLUGIN_EXPORT __declspec(dllexport)
#else
#  define PLUGIN_EXPORT __attribute__((visibility("default")))
#endif

extern "C" PLUGIN_EXPORT const char* greet(const char* who) {
    static std::string result;
    result = std::string("你好, ") + who + "!";
    return result.c_str();
}

extern "C" PLUGIN_EXPORT int add(int a, int b) {
    return a + b;
}
