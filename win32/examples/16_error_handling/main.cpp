// 16_error_handling — GetLastError / FormatMessageW / HRESULT / SEH 错误处理四件套
//
// 对应教程：docs/03-错误处理与调试.md
// 控制台程序（wmain），build.ps1 自动按 CONSOLE 子系统编译

#include <windows.h>
#include <stdio.h>
#include <locale.h>

// ── 演示 1：失败的 API + GetLastError + FormatMessageW ──────────────
static void DemoWin32Error() {
    wprintf(L"[1] Win32 错误码与消息\n");

    // 打开一个肯定不存在的文件
    HANDLE h = CreateFileW(L"C:\\__no_such_file__.tmp", GENERIC_READ, 0,
                           nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) {          // 文件句柄的失败判据是它，不是 nullptr！
        DWORD err = GetLastError();           // ★ 必须紧贴失败调用读取
        wprintf(L"    CreateFileW 失败，GetLastError() = %lu\n", err);

        LPWSTR msg = nullptr;                 // 把错误码翻译成人话
        DWORD n = FormatMessageW(
            FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
            FORMAT_MESSAGE_IGNORE_INSERTS,
            nullptr, err, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
            (LPWSTR)&msg, 0, nullptr);
        if (n > 0 && msg) {
            wprintf(L"    FormatMessageW: %s", msg);   // 系统消息自带换行
            LocalFree(msg);                           // ALLOCATE_BUFFER 的配对释放
        }
    } else {
        CloseHandle(h);
    }
}

// ── 演示 2：HRESULT——COM 世界的错误形态（第 22 章正式展开）──────────
static void DemoHresult() {
    wprintf(L"[2] HRESULT\n");
    DWORD err = ERROR_FILE_NOT_FOUND;         // = 2
    HRESULT hr = HRESULT_FROM_WIN32(err);     // 打包：0x80070002
    wprintf(L"    Win32 错误 %lu → HRESULT 0x%08lX\n", err, (unsigned long)hr);
    wprintf(L"    FAILED(hr) = %s\n", FAILED(hr) ? L"true" : L"false");
    wprintf(L"    SUCCEEDED(S_OK) = %s\n", SUCCEEDED(S_OK) ? L"true" : L"false");
}

// ── 演示 3：SEH——硬件级异常的兜底 ──────────────────────────────────
// ★ 含 __try 的函数里不能有需要析构的 C++ 对象（编译器 C2712），
//   所以 SEH 代码独立成函数、只放原始类型——这是工程上的真实约束。
static int DemoSehInner() {
    __try {
        volatile int* bad = nullptr;
        *bad = 42;                            // 写空指针 → ACCESS_VIOLATION
        return 0;                             // 执行不到
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        wprintf(L"    捕获异常 0x%08lX（EXCEPTION_ACCESS_VIOLATION）\n",
                (unsigned long)GetExceptionCode());
        return 1;
    }
}

static void DemoSeh() {
    wprintf(L"[3] SEH 结构化异常\n");
    wprintf(L"    __except 已兜底，程序继续运行（返回 %d）\n", DemoSehInner());
}

// ── 演示 4：OutputDebugStringW——写给调试器的留言 ────────────────────
static void DemoDebugOutput() {
    wprintf(L"[4] OutputDebugStringW（用 DebugView/调试器观察）\n");
    OutputDebugStringW(L"[16_error_handling] 这条消息只出现在调试器里\n");
}

int wmain() {
    _wsetlocale(LC_ALL, L"");
    wprintf(L"══ 16_error_handling：错误处理四件套 ══\n\n");
    DemoWin32Error();
    wprintf(L"\n");
    DemoHresult();
    wprintf(L"\n");
    DemoSeh();
    wprintf(L"\n");
    DemoDebugOutput();
    wprintf(L"\n演示结束，全部正常返回\n");
    return 0;
}
