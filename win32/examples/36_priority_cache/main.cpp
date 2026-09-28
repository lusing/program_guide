// 36_priority_cache —— 第 17 章：调度、优先级与伪共享
// 控制台三段实验：A) 优先级对比（GetThreadTimes 计量） B) 饥饿保护观察 C) 伪共享实测
#include <windows.h>
#include <stdio.h>

static volatile LONG g_sink = 0;
static volatile LONG g_run = 1;                     // 实验窗口开关

// 忙循环线程：窗口期内烧 user time（volatile 累加防止被优化掉）
static DWORD WINAPI BusyThread(LPVOID) {
    LONG i = 0;
    while (g_run) g_sink += i++ & 1;
    return 0;
}

// 伪共享实验：两个线程各写各的计数器（bad 版两计数器同缓存行，good 版各占一行）
struct alignas(64) Padded { volatile LONG v; };
struct SharedBad  { volatile LONG a; volatile LONG b; };
struct SharedGood { Padded a; Padded b; };

static DWORD WINAPI Bump(LPVOID p) {
    auto* v = (volatile LONG*)p;
    for (int i = 0; i < 200'000'000; ++i) ++(*v);
    return 0;
}

static double Ms(const LARGE_INTEGER& a, const LARGE_INTEGER& b) {
    return (b.QuadPart - a.QuadPart) * 1000.0 / [] { LARGE_INTEGER f; QueryPerformanceFrequency(&f); return f.QuadPart; }();
}

int wmain() {
    printf("=== 实验 A：优先级与饥饿（约 5 秒） ===\n");
    SYSTEM_INFO si; GetSystemInfo(&si);
    int cores = (int)si.dwNumberOfProcessors;
    printf("先把全部 %d 个逻辑核用 NORMAL 线程填满（制造竞争），再加 1 个 IDLE 线程\n", cores);
    printf("——优先级只在竞争时起作用：核全被占住，IDLE 线程只能靠饥饿保护捡漏\n\n");

    // ① n 个 NORMAL 忙线程吃满所有核
    HANDLE* norm = (HANDLE*)HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, cores * sizeof(HANDLE));
    for (int i = 0; i < cores; ++i)
        norm[i] = CreateThread(nullptr, 0, BusyThread, nullptr, 0, nullptr);

    // ② 1 个 IDLE 线程（17.2 的"先建后调"：挂起时设置优先级）
    HANDLE hIdle = CreateThread(nullptr, 0, BusyThread, nullptr, CREATE_SUSPENDED, nullptr);
    SetThreadPriority(hIdle, THREAD_PRIORITY_IDLE);
    ResumeThread(hIdle);

    Sleep(5000);                                          // 实验窗口：主线程睡着不抢 CPU
    g_run = 0;                                            // 关窗口，收线程
    WaitForSingleObject(hIdle, INFINITE);
    for (int i = 0; i < cores; ++i) WaitForSingleObject(norm[i], INFINITE);

    FILETIME c,e,k,uIdle, u;
    GetThreadTimes(hIdle, &c,&e,&k,&uIdle);
    double normTotal = 0;
    for (int i = 0; i < cores; ++i) {
        GetThreadTimes(norm[i], &c,&e,&k,&u);
        ULARGE_INTEGER v{ u.dwLowDateTime, u.dwHighDateTime };
        normTotal += v.QuadPart / 10000.0;
        CloseHandle(norm[i]);
    }
    ULARGE_INTEGER vi{ uIdle.dwLowDateTime, uIdle.dwHighDateTime };
    printf("NORMAL %d 线程合计 user time: %8.0f ms\n", cores, normTotal);
    printf("IDLE    1  线程合计 user time: %8.0f ms  <- 被压到捡零头\n", vi.QuadPart / 10000.0);
    printf("（IDLE 不是 0：系统约每 3~4 秒的饥饿保护把它提到 15 放行双倍时间片）\n\n");
    CloseHandle(hIdle); HeapFree(GetProcessHeap(), 0, norm);

    printf("=== 实验 B：伪共享（各 2 亿次自增，同缓存行 vs 对齐隔离） ===\n");
    LARGE_INTEGER t0, t1;
    HANDLE t[2];

    static SharedBad bad;
    QueryPerformanceCounter(&t0);
    t[0] = CreateThread(nullptr, 0, Bump, (LPVOID)&bad.a, 0, nullptr);
    t[1] = CreateThread(nullptr, 0, Bump, (LPVOID)&bad.b, 0, nullptr);
    WaitForMultipleObjects(2, t, TRUE, INFINITE);
    QueryPerformanceCounter(&t1);
    double msBad = Ms(t0, t1);
    CloseHandle(t[0]); CloseHandle(t[1]);

    static SharedGood good;
    QueryPerformanceCounter(&t0);
    t[0] = CreateThread(nullptr, 0, Bump, (LPVOID)&good.a.v, 0, nullptr);
    t[1] = CreateThread(nullptr, 0, Bump, (LPVOID)&good.b.v, 0, nullptr);
    WaitForMultipleObjects(2, t, TRUE, INFINITE);
    QueryPerformanceCounter(&t1);
    double msGood = Ms(t0, t1);
    CloseHandle(t[0]); CloseHandle(t[1]);

    printf("共享缓存行（bad） : %8.0f ms\n", msBad);
    printf("alignas(64)（good）: %8.0f ms\n", msGood);
    printf("比值: %.2f 倍（多核机器上 bad 明显更慢——核间缓存行来回失效）\n", msBad / msGood);
    return 0;
}
