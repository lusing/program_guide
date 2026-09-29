// 44_nt_native —— 第 36 章：NT 层一瞥——越过 Win32 边界的四个实验
// ① NtQuerySystemInformation 枚举进程（16 章说"别用"的那位，今天看清它长什么样）
// ② TEB/PEB 自读：BeingDebugged、进程命令行真身、映像基址
// ③ 对象命名空间：NtQueryDirectoryObject 列 \BaseNamedObjects——Local\/Global\ 的谜底
// ④ 设备也是文件：CreateFile 打开 \\.\CONOUT$ 写一行字；DeviceIoControl 问物理硬盘规格
// 验证：控制台直接运行，四段输出与 36 章各节一一对应。
#define WIN32_NO_STATUS          // 先不让 ntstatus 的常量污染 windows.h
#include <windows.h>
#include <stdio.h>
#include <winternl.h>            // PEB/TEB、NtQuerySystemInformation、OBJECT_ATTRIBUTES（部分定义）
#undef WIN32_NO_STATUS
#include <ntstatus.h>            // STATUS_* 常量
#pragma comment(lib, "ntdll.lib")// winternl.h 里 NTAPI 声明对应的导入库（SDK 自带）

// ---------- winternl.h 没给全的，自己补（WDK 里同名结构的子集） ----------
#ifndef DIRECTORY_QUERY
#define DIRECTORY_QUERY 0x0001
#endif
typedef struct _OBJECT_DIRECTORY_INFORMATION {   // NtQueryDirectoryObject 的产出单元
    UNICODE_STRING Name;
    UNICODE_STRING TypeName;
} OBJECT_DIRECTORY_INFORMATION;

// SystemProcessInformation(=5) 的条目布局（WDK/Process Hacker 同款；x64 偏移已对齐）
typedef struct _SYSTEM_PROCESS_INFORMATION_NT {
    ULONG NextEntryOffset;
    ULONG NumberOfThreads;
    LARGE_INTEGER WorkingSetPrivateSize;
    ULONG HardFaultCount;
    ULONG NumberOfThreadsHighWatermark;
    ULONGLONG CycleTime;
    LARGE_INTEGER CreateTime;
    LARGE_INTEGER UserTime;
    LARGE_INTEGER KernelTime;
    UNICODE_STRING ImageName;
    LONG BasePriority;
    HANDLE UniqueProcessId;
    HANDLE InheritedFromUniqueProcessId;
    ULONG HandleCount;
    ULONG SessionId;
    ULONG_PTR UniqueProcessKey;
    SIZE_T PeakVirtualSize;
    SIZE_T VirtualSize;
    ULONG PageFaultCount;
    SIZE_T PeakWorkingSetSize;
    SIZE_T WorkingSetSize;
    SIZE_T QuotaPeakPagedPoolUsage;
    SIZE_T QuotaPagedPoolUsage;
    SIZE_T QuotaPeakNonPagedPoolUsage;
    SIZE_T QuotaNonPagedPoolUsage;
    SIZE_T PagefileUsage;
    SIZE_T PeakPagefileUsage;
    SIZE_T PrivatePageCount;
    LARGE_INTEGER ReadOperationCount;
    LARGE_INTEGER WriteOperationCount;
    LARGE_INTEGER OtherOperationCount;
    LARGE_INTEGER ReadTransferCount;
    LARGE_INTEGER WriteTransferCount;
    LARGE_INTEGER OtherTransferCount;
} SYSTEM_PROCESS_INFORMATION_NT;

// 宽串(UNICODE_STRING 不保证 \0 结尾)→UTF-8 窄串：42 例的同款手法
static void U8Len(const wchar_t* w, size_t n, char* out, size_t outSize) {
    int m = WideCharToMultiByte(CP_UTF8, 0, w, (int)(n / sizeof(wchar_t)), out, (int)outSize - 1, nullptr, nullptr);
    out[m > 0 ? m : 0] = '\0';
}

static int RunProcessEnum() {
    printf("=== ① NtQuerySystemInformation(SystemProcessInformation)：一次调用拿全系统进程 ===\n");
    printf("    （官方契约止步于 EnumProcesses/Toolhelp；它是 psapi 背后的同一份内核数据）\n\n");

    // 动态解析：21 章 RtlGetVersion 的同款姿势——ntdll 没给完整的导入承诺
    typedef NTSTATUS(NTAPI* NtQSI_t)(ULONG, PVOID, ULONG, PULONG);
    NtQSI_t NtQSI = (NtQSI_t)GetProcAddress(GetModuleHandleW(L"ntdll.dll"), "NtQuerySystemInformation");
    if (!NtQSI) { printf("解析 NtQuerySystemInformation 失败\n"); return 1; }

    // 缓冲区重试循环：这是调用它的标准形态（INFO_LENGTH_MISMATCH = 再大点）
    ULONG size = 1 << 20;
    void* buf = nullptr;
    NTSTATUS st;
    for (;;) {
        buf = HeapAlloc(GetProcessHeap(), 0, size);
        st = NtQSI(5 /*SystemProcessInformation*/, buf, size, nullptr);
        if (st != STATUS_INFO_LENGTH_MISMATCH) break;   // 0xC0000004：缓冲不够，翻倍重来
        HeapFree(GetProcessHeap(), 0, buf);
        size *= 2;
    }
    if (st != 0) { printf("NtQuerySystemInformation 失败 0x%08lX\n", (unsigned long)st); return 1; }

    DWORD myPid = GetCurrentProcessId();
    int nProc = 0; ULONG nThread = 0;
    char name[256];
    SYSTEM_PROCESS_INFORMATION_NT* e = (SYSTEM_PROCESS_INFORMATION_NT*)buf;
    printf("    %-28s %6s %8s %10s\n", "进程", "线程", "句柄", "工作集KB");
    for (;;) {
        if (e->ImageName.Length)
            U8Len(e->ImageName.Buffer, e->ImageName.Length, name, sizeof(name));
        else
            strcpy_s(name, "System Idle Process");       // 第一项没有名字
        nProc++; nThread += e->NumberOfThreads;
        DWORD pid = (DWORD)(ULONG_PTR)e->UniqueProcessId;
        if (nProc <= 8 || pid == myPid)
            printf("    %-28s %6lu %8lu %10zu%s\n", name, e->NumberOfThreads, e->HandleCount,
                   e->WorkingSetSize / 1024, pid == myPid ? "   ← 本进程" : "");
        if (e->NextEntryOffset == 0) break;               // 链表走到头的标志
        e = (SYSTEM_PROCESS_INFORMATION_NT*)((BYTE*)e + e->NextEntryOffset);
    }
    printf("    共 %d 个进程、%lu 个线程——一次系统调用，无快照句柄、无逐个 OpenProcess。\n\n",
           nProc, nThread);
    HeapFree(GetProcessHeap(), 0, buf);
    return 0;
}

static int RunPebTour() {
    printf("=== ② TEB/PEB：线程与进程的\"自我档案\"（每线程一份 TEB，每进程一份 PEB） ===\n\n");
    PTEB teb = NtCurrentTeb();                       // winnt.h 声明；fs/gs 段寄存器直达
    PPEB peb = teb->ProcessEnvironmentBlock;         // TEB 里最常用的指针

    printf("    TEB @ %p，PEB @ %p\n", (void*)teb, (void*)peb);
    printf("    PEB.BeingDebugged = %d   ← IsDebuggerPresent() 读的就是这一个字节（反调试第一课）\n",
           peb->BeingDebugged);
    // winternl.h 的 PEB 把映像基址藏在 Reserved3[1]（偏移 0x10，WDK 里叫 ImageBaseAddress）
    printf("    PEB 映像基址     = %p   ← 对照 GetModuleHandle(nullptr) = %p\n",
           peb->Reserved3[1], (void*)GetModuleHandleW(nullptr));

    char cmd[1024];
    PRTL_USER_PROCESS_PARAMETERS pp = peb->ProcessParameters;   // CRT 的 argv 就是解析它来的
    if (pp->CommandLine.Length)
        U8Len(pp->CommandLine.Buffer, pp->CommandLine.Length, cmd, sizeof(cmd));
    else
        strcpy_s(cmd, "(空)");
    printf("    命令行真身       = %s   ← GetCommandLineW() 返回的就是这块内存\n", cmd);
    printf("    （PEB 还有加载器链表 Ldr——22 章\"进程里 DLL 怎么来的\"的档案库）\n\n");
    return 0;
}

static int RunObjectNamespace() {
    printf("=== ③ 对象命名空间：Local\\ 与 Global\\ 的谜底（17/20 章埋的梗在这揭） ===\n\n");

    // 先种两个命名对象：一个 Local\（会话私有）、一个 Global\（全局共享）
    CreateMutexW(nullptr, FALSE, L"Local\\Win32TutorialDemo");
    CreateMutexW(nullptr, FALSE, L"Global\\Win32TutorialDemo");
    printf("    已创建命名互斥体 Local\\Win32TutorialDemo 与 Global\\Win32TutorialDemo\n");

    typedef NTSTATUS(NTAPI* NtOpenDir_t)(PHANDLE, ACCESS_MASK, POBJECT_ATTRIBUTES);
    typedef NTSTATUS(NTAPI* NtQueryDir_t)(HANDLE, PVOID, ULONG, BOOLEAN, BOOLEAN, PULONG, PULONG);
    HMODULE nt = GetModuleHandleW(L"ntdll.dll");
    NtOpenDir_t NtOpenDir = (NtOpenDir_t)GetProcAddress(nt, "NtOpenDirectoryObject");
    NtQueryDir_t NtQueryDir = (NtQueryDir_t)GetProcAddress(nt, "NtQueryDirectoryObject");

    DWORD sid = 0;
    ProcessIdToSessionId(GetCurrentProcessId(), &sid);
    const wchar_t* dirs[2] = { L"\\BaseNamedObjects", nullptr };
    wchar_t sess[64]; swprintf_s(sess, L"\\Sessions\\%lu\\BaseNamedObjects", sid);
    dirs[1] = sess;

    for (int d = 0; d < 2; ++d) {
        UNICODE_STRING uname = { (USHORT)(wcslen(dirs[d]) * 2), (USHORT)(wcslen(dirs[d]) * 2 + 2), (PWSTR)dirs[d] };
        OBJECT_ATTRIBUTES oa = { sizeof(oa), nullptr, &uname, 0, nullptr, nullptr };
        HANDLE h = nullptr;
        NTSTATUS st = NtOpenDir ? NtOpenDir(&h, DIRECTORY_QUERY, &oa) : STATUS_ENTRYPOINT_NOT_FOUND;
        printf("    打开 %ls：%s\n", dirs[d], st == 0 ? "成功" : "失败");
        if (st != 0) continue;

        BYTE buf[4096]; ULONG ctx = 0, got = 0;
        int total = 0, found = 0, shown = 0; BOOL restart = TRUE;
        printf("      %-30s %s\n", "名称（前 8 个 + 我们种的）", "类型");
        for (;;) {
            st = NtQueryDir(h, buf, sizeof(buf), FALSE, restart, &ctx, &got);
            restart = FALSE;
            if (st == STATUS_NO_MORE_ENTRIES) break;
            if (st < 0) break;   // NTSTATUS 负值才是错误；0x105(STATUS_MORE_ENTRIES)=成功级"还有更多"
            for (ULONG off = 0; off + sizeof(OBJECT_DIRECTORY_INFORMATION) <= got; ) {
                OBJECT_DIRECTORY_INFORMATION* oi = (OBJECT_DIRECTORY_INFORMATION*)(buf + off);
                if (oi->Name.Length == 0) break;
                ++total;
                char n[128], t[64];
                U8Len(oi->Name.Buffer, oi->Name.Length, n, sizeof(n));
                U8Len(oi->TypeName.Buffer, oi->TypeName.Length, t, sizeof(t));
                bool mine = strstr(n, "Win32TutorialDemo") != nullptr;
                if (mine) ++found;
                if (shown < 8 || mine) {
                    printf("      %-30s %s%s\n", n, t, mine ? "   ← 我们种的" : "");
                    ++shown;
                }
                off += sizeof(OBJECT_DIRECTORY_INFORMATION);
            }
            if (total > 4000) break;                    // 保险丝
        }
        printf("      （共 %d 个命名对象，其中 Win32TutorialDemo 命中 %d 个）\n\n", total, found);
        CloseHandle(h);
    }
    printf("    谜底：Local\\ 落进本会话目录 \\Sessions\\%lu\\BaseNamedObjects，Global\\ 落进全局 \\BaseNamedObjects。\n", sid);
    printf("    服务（30 章）在会话 0，想跟用户会话互斥就得 Global\\——第 20 章的结论现在有了实感。\n\n");
    return 0;
}

static int RunDeviceTalk() {
    printf("=== ④ 设备也是文件：\\\\.\\ 前缀、DeviceIoControl 与 IOCTL ===\n\n");

    // ④-1 控制台输出设备：写它 = 写屏幕
    HANDLE hCon = CreateFileW(L"\\\\.\\CONOUT$", GENERIC_READ | GENERIC_WRITE,
                              FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_EXISTING, 0, nullptr);
    if (hCon != INVALID_HANDLE_VALUE) {
        const char* msg = "    （这一行是 WriteFile 写到设备 \\\\.\\CONOUT$ 上的——printf 的终点站）\n";
        DWORD n = 0;
        WriteFile(hCon, msg, (DWORD)strlen(msg), &n, nullptr);
        CloseHandle(hCon);
        printf("    WriteFile(\\\\.\\CONOUT$) 成功——控制台本身就是个设备驱动（condrv）。\n");
    } else {
        printf("    打开 \\\\.\\CONOUT$ 失败 %lu（重定向运行时没有控制台设备）\n", GetLastError());
    }

    // ④-2 物理硬盘：DeviceIoControl + IOCTL_STORAGE_QUERY_PROPERTY（两段问尺寸，19 章模式再现）
    HANDLE hDisk = CreateFileW(L"\\\\.\\PhysicalDrive0", 0,   // 0 权限：只问不读
                               FILE_SHARE_READ | FILE_SHARE_WRITE, nullptr, OPEN_EXISTING, 0, nullptr);
    if (hDisk != INVALID_HANDLE_VALUE) {
        STORAGE_PROPERTY_QUERY q = {};
        q.PropertyId = StorageDeviceProperty;
        q.QueryType = PropertyStandardQuery;
        BYTE out[1024] = {};
        DWORD got = 0;
        if (DeviceIoControl(hDisk, IOCTL_STORAGE_QUERY_PROPERTY,
                            &q, sizeof(q), out, sizeof(out), &got, nullptr)) {
            STORAGE_DEVICE_DESCRIPTOR* d = (STORAGE_DEVICE_DESCRIPTOR*)out;
            const char* vendor = d->VendorIdOffset ? (const char*)out + d->VendorIdOffset : "";
            const char* product = d->ProductIdOffset ? (const char*)out + d->ProductIdOffset : "";
            printf("    \\\\.\\PhysicalDrive0：厂商 %s 产品 %s 总线类型 %lu（7=USB 11=SATA 17=NVMe）\n",
                   vendor, product, (unsigned long)d->BusType);
        } else {
            printf("    IOCTL_STORAGE_QUERY_PROPERTY 失败 %lu\n", GetLastError());
        }
        CloseHandle(hDisk);
    } else {
        printf("    打开 \\\\.\\PhysicalDrive0 失败 %lu（权限不够正是常态——0 权限也受完整性级别管）\n", GetLastError());
    }

    // ④-3 不存在的设备：驱动没加载时的错误码
    HANDLE hNone = CreateFileW(L"\\\\.\\NoSuchDriverDemo0", 0, 0, nullptr, OPEN_EXISTING, 0, nullptr);
    printf("    打开不存在的 \\\\.\\NoSuchDriverDemo0：%lu（ERROR_FILE_NOT_FOUND——符号链接不在 \\?? 里）\n",
           hNone == INVALID_HANDLE_VALUE ? GetLastError() : 0);
    if (hNone != INVALID_HANDLE_VALUE) CloseHandle(hNone);
    printf("\n    一条链记住：\\\\.\\X 经对象管理器翻译成 \\??\\X → 符号链接 → \\Device\\X → CreateFile 变 IRP_MJ_CREATE。\n");
    printf("    WriteFile/ReadFile/DeviceIoControl 分别变成 IRP_MJ_WRITE / IRP_MJ_READ / IRP_MJ_DEVICE_CONTROL。\n");
    return 0;
}

int wmain() {
    setvbuf(stdout, nullptr, _IONBF, 0);
    RunProcessEnum();
    RunPebTour();
    RunObjectNamespace();
    RunDeviceTalk();
    printf("=== 四个实验完：Win32 之下还有一层，契约未承诺但一直都在 ===\n");
    return 0;
}
