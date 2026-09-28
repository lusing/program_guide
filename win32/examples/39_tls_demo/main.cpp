// 39_tls_demo —— 第 22 章：线程本地存储（TLS）两种机制对照
// 动态：TlsAlloc/TlsSetValue/TlsGetValue/TlsFree（槽位号全进程共享，值每线程独立）
// 静态：__declspec(thread)（链接器安排 .tls 段）
#include <windows.h>
#include <stdio.h>

struct Ctx { wchar_t name[8]; int counter; };

static DWORD g_slot = TLS_OUT_OF_INDEXES;      // 动态 TLS 槽位号（全进程共享）

// ---------- 动态 TLS 的线程体 ----------
static DWORD WINAPI DynamicWorker(LPVOID param) {
    Ctx ctx;
    swprintf_s(ctx.name, 8, L"线程%ld", (long)(INT_PTR)param);
    ctx.counter = 0;
    TlsSetValue(g_slot, &ctx);                 // 本线程的槽里放"我的"上下文

    for (int i = 0; i < 3; ++i) {
        Sleep(50);                             // 制造交错
        auto* mine = (Ctx*)TlsGetValue(g_slot);// 读回的一定是自己的那份
        ++mine->counter;
        printf("[动态 TLS] 线程%ld 第 %d 次：计数器=%d（ctx 地址 %p）\n",
               (long)(INT_PTR)param, i + 1, mine->counter, (void*)mine);
    }
    return 0;                                  // 栈上的 ctx 随线程结束失效——真实代码用堆+统一回收
}

// ---------- 静态 TLS 的线程体 ----------
static __declspec(thread) int t_counter = 0;    // 每线程一份，带初始化
static __declspec(thread) wchar_t t_name[8] = {};

static DWORD WINAPI StaticWorker(LPVOID param) {
    swprintf_s(t_name, 8, L"线程%ld", (long)(INT_PTR)param);   // 写的是自己那份
    for (int i = 0; i < 3; ++i) {
        Sleep(50);
        ++t_counter;
        printf("[静态 TLS] 线程%ld 第 %d 次：计数器=%d（t_counter 地址 %p）\n",
               (long)(INT_PTR)param, i + 1, t_counter, (void*)&t_counter);
    }
    return 0;
}

int wmain() {
    setvbuf(stdout, nullptr, _IONBF, 0);

    g_slot = TlsAlloc();                       // 租槽（64 个，用完要还）
    if (g_slot == TLS_OUT_OF_INDEXES) { printf("TlsAlloc 失败\n"); return 1; }

    printf("=== 动态 TLS（TlsAlloc 槽 %lu）：三个线程各看各的 ===\n", g_slot);
    HANDLE t[3];
    for (int i = 0; i < 3; ++i) t[i] = CreateThread(nullptr, 0, DynamicWorker, (LPVOID)(INT_PTR)(i + 1), 0, nullptr);
    WaitForMultipleObjects(3, t, TRUE, INFINITE);
    for (int i = 0; i < 3; ++i) CloseHandle(t[i]);

    printf("\n=== 静态 TLS（__declspec(thread)）：同一行代码，每线程一份 ===\n");
    printf("主线程的 t_counter 地址 = %p（对照下面线程们的地址）\n", (void*)&t_counter);
    for (int i = 0; i < 3; ++i) t[i] = CreateThread(nullptr, 0, StaticWorker, (LPVOID)(INT_PTR)(i + 1), 0, nullptr);
    WaitForMultipleObjects(3, t, TRUE, INFINITE);
    for (int i = 0; i < 3; ++i) CloseHandle(t[i]);
    printf("主线程自己的 t_counter 仍是 %d——别人的自增从不影响我\n", t_counter);

    TlsFree(g_slot);                           // 还槽（DLL 场景在 DLL_PROCESS_DETACH 里做）
    printf("\n要点：两种机制殊途同归；显式加载的 DLL 用静态 TLS 在老系统有坑（22.4）\n");
    return 0;
}
