// plugin_greeter.cpp —— 编译成 DLL（build.ps1 的 plugin_* 约定），
// 供 dll.cpp 宿主例程加载。用 C 导出（避免名字修饰）。
#include <string>

extern "C" __declspec(dllexport) const char* greet(const char* who) {
    static std::string result;
    result = std::string("你好, ") + who + "!";
    return result.c_str();
}

extern "C" __declspec(dllexport) int add(int a, int b) {
    return a + b;
}
