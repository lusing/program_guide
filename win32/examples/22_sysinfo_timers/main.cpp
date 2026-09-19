// 22_sysinfo_timers — 版本 / 处理器内存 / 环境 / 时间 / QPC / 可等待定时器 / 电源
//
// 对应教程：docs/18-系统信息与定时器.md
#include <windows.h>
#include <stdio.h>
#include <locale.h>

typedef LONG(WINAPI* RtlGetVersionFn)(void*);   // ntdll!RtlGetVersion

int wmain() {
    _wsetlocale(LC_ALL, L"");

    // ── 1. 版本：绕过 manifest 谎言的诚实问法 ─────────────────────
    HMODULE ntdll = GetModuleHandleW(L"ntdll.dll");
    RtlGetVersionFn rtlGetVersion =
        (RtlGetVersionFn)GetProcAddress(ntdll, "RtlGetVersion");
    OSVERSIONINFOW vi = { sizeof(vi) };
    rtlGetVersion(&vi);
    wprintf(L"[1] 真实版本：Windows %lu.%lu build %lu\n",
            (unsigned long)vi.dwMajorVersion,
            (unsigned long)vi.dwMinorVersion,
            (unsigned long)vi.dwBuildNumber);

    // ── 2. 处理器与内存 ──────────────────────────────────────────
    SYSTEM_INFO si = {};
    GetSystemInfo(&si);
    wprintf(L"[2] 逻辑处理器 %lu 个，页面 %lu KB\n",
            (unsigned long)si.dwNumberOfProcessors,
            (unsigned long)si.dwPageSize / 1024);
    MEMORYSTATUSEX ms = { sizeof(ms) };
    GlobalMemoryStatusEx(&ms);
    wprintf(L"    物理内存占用 %lu%%（共 %llu MB）\n",
            (unsigned long)ms.dwMemoryLoad,
            (unsigned long long)ms.ullTotalPhys / (1024 * 1024));

    // ── 3. 环境变量 ──────────────────────────────────────────────
    wchar_t temp[MAX_PATH];
    ExpandEnvironmentStringsW(L"%TEMP%", temp, MAX_PATH);
    wprintf(L"[3] TEMP 展开为：%s\n", temp);
    LPWCH env = GetEnvironmentStringsW();       // 块内 NUL 分隔，空串收尾
    int shown = 0;
    for (LPWCH p = env; *p && shown < 3; p += lstrlenW(p) + 1, ++shown) {
        wprintf(L"    %s\n", p);
    }
    FreeEnvironmentStringsW(env);

    // ── 4. 时间：本地 / UTC / FILETIME 三种形态 ───────────────────
    SYSTEMTIME local = {}, utc = {};
    GetLocalTime(&local);
    GetSystemTime(&utc);
    wprintf(L"[4] 本地 %04d-%02d-%02d %02d:%02d:%02d ｜ UTC %02d:%02d\n",
            local.wYear, local.wMonth, local.wDay,
            local.wHour, local.wMinute, local.wSecond,
            utc.wHour, utc.wMinute);
    FILETIME ft = {};
    GetSystemTimeAsFileTime(&ft);
    ULARGE_INTEGER big = { .LowPart = ft.dwLowDateTime,
                           .HighPart = ft.dwHighDateTime };
    wprintf(L"    FILETIME（1601 纪元，100ns 单位）= %llu\n",
            (unsigned long long)big.QuadPart);

    // ── 5. 高精度计时：QPC 秒表 ──────────────────────────────────
    LARGE_INTEGER freq = {}, t0 = {}, t1 = {};
    QueryPerformanceFrequency(&freq);
    QueryPerformanceCounter(&t0);
    Sleep(100);
    QueryPerformanceCounter(&t1);
    wprintf(L"[5] QPC 测得 Sleep(100) 实际 %.1f ms\n",
            (t1.QuadPart - t0.QuadPart) * 1000.0 / freq.QuadPart);

    // ── 6. 可等待定时器：1 秒后变有信号 ──────────────────────────
    HANDLE timer = CreateWaitableTimerW(nullptr, FALSE, nullptr);
    LARGE_INTEGER due = {};
    due.QuadPart = -10'000'000;                 // 负 = 相对；100ns 单位 → 1 秒
    SetWaitableTimer(timer, &due, 0, nullptr, nullptr, FALSE);
    WaitForSingleObject(timer, INFINITE);
    wprintf(L"[6] 可等待定时器：1 秒已到\n");
    CloseHandle(timer);

    // ── 7. 电源 ──────────────────────────────────────────────────
    SYSTEM_POWER_STATUS ps = {};
    GetSystemPowerStatus(&ps);
    wprintf(L"[7] 电源：%s，电量 %lu%%\n",
            ps.ACLineStatus == 1 ? L"交流电" : L"电池/未知",
            (unsigned long)ps.BatteryLifePercent);
    return 0;
}
