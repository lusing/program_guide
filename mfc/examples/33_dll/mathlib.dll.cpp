// mathlib.dll.cpp：普通 Win32 DLL（文件名 *.dll.cpp 是 build.ps1 的 DLL 目标约定）。
// 只导出 C 接口（extern "C"），不碰 MFC/CRT 的跨边界对象 ——
// 这是最稳的 DLL 形态：任何语言、任何运行时都能加载。
//
// 书1 第15章 例82/例83：静态/动态链接 C/C++ 库
#include <windows.h>
#include <stdio.h>
#include <wchar.h>
#include <string.h>

// 模块带一个 DllMain，挂接时留一条调试输出（DbgView / VS 输出窗口可见）
static HANDLE g_heap = nullptr;

BOOL APIENTRY DllMain(HMODULE hModule, DWORD reason, LPVOID) {
    switch (reason) {
    case DLL_PROCESS_ATTACH:
        // 自己的堆：DLL 分配的东西从 DLL 的堆上拿，
        // 与宿主用哪个 CRT 无关（谁来分配谁来释放的纪律之外再上一道保险）
        g_heap = HeapCreate(0, 0, 0);
        OutputDebugStringW(L"[mathlib.dll] DLL_PROCESS_ATTACH\n");
        DisableThreadLibraryCalls(hModule);
        break;
    case DLL_PROCESS_DETACH:
        if (g_heap) { HeapDestroy(g_heap); g_heap = nullptr; }
        OutputDebugStringW(L"[mathlib.dll] DLL_PROCESS_DETACH\n");
        break;
    default:
        break;
    }
    return TRUE;
}

extern "C" {

__declspec(dllexport) int Add(int a, int b) {
    return a + b;
}

__declspec(dllexport) int Multiply(int a, int b) {
    return a * b;
}

// 返回字符串的规矩：调用方给缓冲区，DLL 只往里写 —— 不把指针扔过模块边界
__declspec(dllexport) void GetGreeting(wchar_t* buf, int cch) {
    wcsncpy_s(buf, (size_t)cch, L"你好，来自 mathlib.dll（x64）", _TRUNCATE);
}

// 用 DLL 自己的堆分配，配套 ExportFree 释放：展示“谁分配谁释放”的显式协议
__declspec(dllexport) wchar_t* AllocReport(int value) {
    wchar_t msg[64];
    swprintf_s(msg, L"mathlib 报告：0x%08X", (unsigned)value);
    size_t bytes = (wcslen(msg) + 1) * sizeof(wchar_t);
    wchar_t* p = (wchar_t*)HeapAlloc(g_heap, 0, bytes);
    if (p) memcpy(p, msg, bytes);
    return p;
}

__declspec(dllexport) void ExportFree(void* p) {
    if (p && g_heap) HeapFree(g_heap, 0, p);
}

} // extern "C"
