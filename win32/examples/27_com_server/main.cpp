// 27_com_server 消费者 — 注册 → CoCreateInstance → 使用 → 注销 全链路
//
// 对应教程：docs/24-COM实现.md
// 本示例由 27_com_server/build.ps1 构建（server dll + 本 exe 三步）
#include "calc.h"
#include <windows.h>
#include <stdio.h>
#include <locale.h>

typedef HRESULT (STDAPICALLTYPE* PfnDllServer)(void);

int wmain() {
    _wsetlocale(LC_ALL, L"");

    // 1. 手动注册：LoadLibrary + GetProcAddress 调 DllRegisterServer
    //    （regsvr32 干的就是这件事——第 20 章显式链接的又一课）
    HMODULE dll = LoadLibraryW(L"calcdll.dll");      // 裸名：exe 目录搜索
    if (!dll) {
        wprintf(L"加载 calcdll.dll 失败 %lu\n", GetLastError());
        return 1;
    }
    PfnDllServer reg =
        (PfnDllServer)GetProcAddress(dll, "DllRegisterServer");
    if (reg && SUCCEEDED(reg())) {
        wprintf(L"[1] DllRegisterServer → 已注册到 HKCU\\Software\\Classes\n");
    }

    // 2. COM 大门：初始化 + 创建
    if (FAILED(CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED))) return 1;

    ICalc* calc = nullptr;
    HRESULT hr = CoCreateInstance(CLSID_Calc, nullptr, CLSCTX_INPROC_SERVER,
                                  IID_ICalc, (void**)&calc);
    if (FAILED(hr)) {
        wprintf(L"[2] CoCreateInstance 失败 0x%08lX\n", (unsigned long)hr);
        CoUninitialize();
        return 1;
    }
    wprintf(L"[2] CoCreateInstance 成功（COM 替你 LoadLibrary 了我们刚注册的 DLL）\n");

    // 3. 调接口方法
    int sum = 0, diff = 0;
    calc->Add(20, 22, &sum);
    calc->Sub(50, 8, &diff);
    wprintf(L"[3] Add(20,22) = %d，Sub(50,8) = %d\n", sum, diff);

    // 4. 引用计数现场观察
    ULONG n = calc->AddRef();
    wprintf(L"[4] AddRef 后引用计数 = %lu（Release 归位）\n", (unsigned long)n);
    calc->Release();

    // 5. 释放与注销——环境还原
    calc->Release();          // 归零 → 组件自毁
    CoUninitialize();
    PfnDllServer unreg =
        (PfnDllServer)GetProcAddress(dll, "DllUnregisterServer");
    if (unreg && SUCCEEDED(unreg())) {
        wprintf(L"[5] DllUnregisterServer → 注册表已清理\n");
    }
    FreeLibrary(dll);
    wprintf(L"全链路完成\n");
    return 0;
}
