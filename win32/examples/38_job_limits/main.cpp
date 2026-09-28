// 38_job_limits —— 第 16 章：Job 对象的限额强杀与统计回读
// 双模式：无参数 = 父进程（建 Job、收编两个子进程、限 CPU 时间、看统计）；
//         "child" = 子进程（纯忙循环，约 1.5 秒 CPU 后被作业强杀）
#include <windows.h>
#include <stdio.h>

static volatile LONG g_sink = 0;

static int RunChild() {
    LONG i = 0;
    while (1) g_sink += i++ & 1;        // 纯烧 CPU：把限额吃满，等系统来收
    return 0;                            // 不会执行到——CPU 限额到点进程被终止
}

int wmain(int argc, wchar_t** argv) {
    setvbuf(stdout, nullptr, _IONBF, 0);

    if (argc > 1 && wcscmp(argv[1], L"child") == 0) return RunChild();

    // ---------- 父进程 ----------
    constexpr ULONGLONG CPU_LIMIT_100NS = 15'000'000 / 10;   // 1.5 秒 CPU（100ns 单位）
    printf("=== Job 限额实验：两个忙循环子进程，单进程 CPU 上限 1.5 秒 ===\n\n");

    HANDLE hJob = CreateJobObjectW(nullptr, nullptr);

    JOBOBJECT_EXTENDED_LIMIT_INFORMATION li = {};
    li.BasicLimitInformation.PerProcessUserTimeLimit.QuadPart = CPU_LIMIT_100NS;
    li.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_PROCESS_TIME;
    if (!SetInformationJobObject(hJob, JobObjectExtendedLimitInformation, &li, sizeof(li))) {
        printf("SetInformationJobObject 失败 %lu\n", GetLastError()); return 1;
    }

    wchar_t exe[MAX_PATH]; GetModuleFileNameW(nullptr, exe, MAX_PATH);
    wchar_t cmd[MAX_PATH + 16];
    swprintf_s(cmd, MAX_PATH + 16, L"\"%s\" child", exe);    // ★ 命令行须可写缓冲（16.2）

    STARTUPINFOW si = { sizeof(si) };
    PROCESS_INFORMATION pi[2] = {};
    for (int i = 0; i < 2; ++i) {
        if (!CreateProcessW(nullptr, cmd, nullptr, nullptr, FALSE,
                            CREATE_NO_WINDOW, nullptr, nullptr, &si, &pi[i])) {
            printf("CreateProcess 失败 %lu\n", GetLastError()); return 1;
        }
        AssignProcessToJobObject(hJob, pi[i].hProcess);      // 收编（16.5）
        CloseHandle(pi[i].hThread);                          // 不等主线程就先还（16.2）
    }
    printf("两个子进程已收编（CREATE_NO_WINDOW，后台烧 CPU）\n");

    for (int i = 0; i < 2; ++i) {
        DWORD code = 0;
        if (WaitForSingleObject(pi[i].hProcess, 15000) == WAIT_OBJECT_0)
            GetExitCodeProcess(pi[i].hProcess, &code);
        printf("子进程 %d 已结束，退出码 %08lX%s\n", i, code,
               code == 0xC0000044 ? L"（STATUS_QUOTA_EXCEEDED：CPU 限额强杀）" : L"");
        CloseHandle(pi[i].hProcess);
    }

    printf("\n=== 统计回读：QueryInformationJobObject ===\n");
    JOBOBJECT_BASIC_AND_IO_ACCOUNTING_INFORMATION acc = {};
    if (QueryInformationJobObject(hJob, JobObjectBasicAndIoAccountingInformation,
                                  &acc, sizeof(acc), nullptr)) {
        printf("曾经入组进程数 TotalProcesses     : %lu\n", acc.BasicInfo.TotalProcesses);
        printf("当前组内进程数 ActiveProcesses    : %lu\n", acc.BasicInfo.ActiveProcesses);
        printf("被限额终止的进程数 TotalTerminated: %lu\n", acc.BasicInfo.TotalTerminatedProcesses);
        printf("整组 user time: %.0f ms（≈ 2 × 1.5s 限额上限）\n",
               acc.BasicInfo.TotalUserTime.QuadPart / 10000.0);
    }
    CloseHandle(hJob);
    return 0;
}
