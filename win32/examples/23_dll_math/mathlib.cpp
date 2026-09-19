// mathlib.cpp — DLL 侧实现（编译时定义 MATHLIB_EXPORTS）
#include "mathlib.h"
#include <windows.h>

static wchar_t g_version[] = L"mathlib 1.0 (MSVC x64)";

extern "C" MATHLIB_API int Math_Add(int a, int b) { return a + b; }
extern "C" MATHLIB_API int Math_Mul(int a, int b) { return a * b; }
extern "C" MATHLIB_API const wchar_t* Math_Version(void) { return g_version; }

BOOL APIENTRY DllMain(HMODULE hinst, DWORD reason, LPVOID) {
    if (reason == DLL_PROCESS_ATTACH) {
        DisableThreadLibraryCalls(hinst);   // 不关心线程事件就关掉
    }
    return TRUE;
}
