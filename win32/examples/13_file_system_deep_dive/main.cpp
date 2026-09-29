#include <windows.h>
#include <stdio.h>

const int ID_BUTTON_SCAN = 1001;
const int ID_LISTBOX = 1002;
const int ID_BUTTON_WATCH = 1003;
#define WM_APP_WATCHLINE (WM_APP + 1)   // 监视线程回传一行文本（wParam=字符串指针，接收方负责释放）
#define WM_APP_WATCHDONE (WM_APP + 2)   // 监视演示结束，重新启用按钮

struct WatchCtx {
    HWND hwnd;
    wchar_t dir[MAX_PATH];
};

void AppendLine(HWND listBox, const wchar_t* text);   // 定义在下方

// 变更者线程：在临时目录里按节拍制造 新建/追加/改名/删除/建删子目录（19.7 的活教材）
static DWORD WINAPI MutatorThread(LPVOID p) {
    WatchCtx* ctx = (WatchCtx*)p;
    wchar_t p1[MAX_PATH], p2[MAX_PATH], sub[MAX_PATH];
    swprintf_s(p1, L"%ls\\note.txt", ctx->dir);
    swprintf_s(p2, L"%ls\\renamed.txt", ctx->dir);
    swprintf_s(sub, L"%ls\\subdir", ctx->dir);
    DeleteFileW(p1); DeleteFileW(p2); RemoveDirectoryW(sub);   // 清场，重跑也干净

    Sleep(400);
    HANDLE h = CreateFileW(p1, GENERIC_WRITE, 0, nullptr, CREATE_ALWAYS, 0, nullptr);
    if (h != INVALID_HANDLE_VALUE) { DWORD w; WriteFile(h, "hello", 5, &w, nullptr); CloseHandle(h); }
    Sleep(400);
    h = CreateFileW(p1, FILE_APPEND_DATA, 0, nullptr, OPEN_EXISTING, 0, nullptr);
    if (h != INVALID_HANDLE_VALUE) { DWORD w; WriteFile(h, "more", 4, &w, nullptr); CloseHandle(h); }
    Sleep(400);
    MoveFileW(p1, p2);
    Sleep(400);
    DeleteFileW(p2);
    Sleep(400);
    CreateDirectoryW(sub, nullptr);
    Sleep(400);
    RemoveDirectoryW(sub);
    return 0;
}

// 监视者线程：ReadDirectoryChangesW 异步挂起 + 限时等待（★ 句柄必须 FILE_FLAG_OVERLAPPED，
// 否则系统无视 OVERLAPPED 直接同步阻塞——变更还没发生就死等）
static DWORD WINAPI WatcherThread(LPVOID p) {
    WatchCtx* ctx = (WatchCtx*)p;
    HWND hwnd = ctx->hwnd;

    HANDLE hDir = CreateFileW(ctx->dir, FILE_LIST_DIRECTORY,
                              FILE_SHARE_READ | FILE_SHARE_WRITE | FILE_SHARE_DELETE,
                              nullptr, OPEN_EXISTING,
                              FILE_FLAG_BACKUP_SEMANTICS | FILE_FLAG_OVERLAPPED, nullptr);
    if (hDir == INVALID_HANDLE_VALUE) {
        PostMessageW(hwnd, WM_APP_WATCHLINE, 0, 0);
        PostMessageW(hwnd, WM_APP_WATCHDONE, 0, 0);
        return 1;
    }
    OVERLAPPED ov = {};
    ov.hEvent = CreateEventW(nullptr, FALSE, FALSE, nullptr);  // 自动复位

    for (int round = 1; round <= 12; ++round) {
        DWORD bytes = 0;
        BYTE buf[4096];
        if (!ReadDirectoryChangesW(hDir, buf, sizeof(buf), FALSE,   // FALSE=不含子目录
                FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_DIR_NAME |
                FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_SIZE,
                &bytes, &ov, nullptr))
            break;
        if (WaitForSingleObject(ov.hEvent, 800) != WAIT_OBJECT_0) { // 超时=变更者演完了
            CancelIo(hDir);
            break;
        }
        if (!GetOverlappedResult(hDir, &ov, &bytes, FALSE)) break;

        FILE_NOTIFY_INFORMATION* fni = (FILE_NOTIFY_INFORMATION*)buf;
        for (;;) {
            wchar_t name[260];
            size_t n = fni->FileNameLength / 2;
            memcpy(name, fni->FileName, n * 2); name[n] = L'\0';
            const wchar_t* act =
                fni->Action == FILE_ACTION_ADDED ? L"新建" :
                fni->Action == FILE_ACTION_REMOVED ? L"删除" :
                fni->Action == FILE_ACTION_MODIFIED ? L"修改" :
                fni->Action == FILE_ACTION_RENAMED_OLD_NAME ? L"改名前" : L"改名后";
            wchar_t* line = new wchar_t[400];
            swprintf_s(line, 400, L"监听：%s  %s", act, name);
            PostMessageW(hwnd, WM_APP_WATCHLINE, 0, (LPARAM)line);
            if (fni->NextEntryOffset == 0) break;
            fni = (FILE_NOTIFY_INFORMATION*)((BYTE*)fni + fni->NextEntryOffset);
        }
    }
    CloseHandle(ov.hEvent);
    CloseHandle(hDir);
    PostMessageW(hwnd, WM_APP_WATCHDONE, 0, 0);
    return 0;
}

static void StartWatchDemo(HWND hwnd, HWND listBox) {
    SendMessageW(listBox, LB_RESETCONTENT, 0, 0);
    AppendLine(listBox, L"=== 目录监视演示：临时目录里将发生 新建/修改/改名/删除/建删子目录 ===");

    WatchCtx* ctx = new WatchCtx;
    ctx->hwnd = hwnd;
    wchar_t tmp[MAX_PATH];
    GetTempPathW(MAX_PATH, tmp);
    swprintf_s(ctx->dir, L"%lswin32_watch_demo", tmp);
    CreateDirectoryW(ctx->dir, nullptr);      // 已存在也无妨

    // 监视者先挂起、变更者再开工：RDCW 只报告"挂起期间"发生的变化
    CreateThread(nullptr, 0, WatcherThread, ctx, 0, nullptr);
    CreateThread(nullptr, 0, MutatorThread, ctx, 0, nullptr);
    // ctx 由线程带走；演示短命，泄漏一个结构可接受（真实程序应传递并等待线程收尾）
}


void CreateDemoFile() {
    wchar_t currentDir[MAX_PATH];
    if (GetCurrentDirectoryW(MAX_PATH, currentDir) == 0) {
        return;
    }

    wchar_t filePath[MAX_PATH];
    swprintf_s(filePath, L"%ls\\win32_ntfs_demo.txt", currentDir);

    HANDLE hFile = CreateFileW(
        filePath,
        GENERIC_READ | GENERIC_WRITE,
        FILE_SHARE_READ | FILE_SHARE_WRITE,
        nullptr,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        nullptr);

    if (hFile == INVALID_HANDLE_VALUE) {
        return;
    }

    const char text[] = "Windows NTFS file metadata demo\r\n";
    DWORD written = 0;
    WriteFile(hFile, text, static_cast<DWORD>(strlen(text)), &written, nullptr);

    BY_HANDLE_FILE_INFORMATION info = {};
    if (GetFileInformationByHandle(hFile, &info)) {
        ULARGE_INTEGER fileSize;                 // ★ 大小要拼 High/Low 两个 32 位字段
        fileSize.LowPart = info.nFileSizeLow;
        fileSize.HighPart = info.nFileSizeHigh;
        wchar_t infoText[512];
        swprintf_s(infoText,
            L"Created file: %ls | attrs=0x%08X | size=%llu bytes",
            filePath,
            info.dwFileAttributes,
            static_cast<unsigned long long>(fileSize.QuadPart));
        // The file is intentionally kept small in this demo; metadata is still collected above.
    }

    CloseHandle(hFile);
}

void AppendLine(HWND listBox, const wchar_t* text) {
    SendMessageW(listBox, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(text));
}

void ScanFiles(HWND listBox) {
    SendMessageW(listBox, LB_RESETCONTENT, 0, 0);

    wchar_t currentDir[MAX_PATH];
    if (GetCurrentDirectoryW(MAX_PATH, currentDir) == 0) {
        AppendLine(listBox, L"GetCurrentDirectoryW failed");
        return;
    }

    wchar_t pattern[MAX_PATH];
    swprintf_s(pattern, L"%ls\\*", currentDir);

    WIN32_FIND_DATAW fd = {};
    HANDLE hFind = FindFirstFileW(pattern, &fd);
    if (hFind == INVALID_HANDLE_VALUE) {
        AppendLine(listBox, L"No files found in current directory");
        return;
    }

    do {
        if (fd.cFileName[0] == L'.') {           // 跳过 "." 与 ".."
            continue;
        }

        ULARGE_INTEGER fileSize;                 // ★ nFileSizeHigh/Low 拼成 64 位
        fileSize.LowPart = fd.nFileSizeLow;
        fileSize.HighPart = fd.nFileSizeHigh;

        wchar_t line[512];
        swprintf_s(line,
            L"%ls | attrs=0x%08X | size=%llu | dir=%s",
            fd.cFileName,
            fd.dwFileAttributes,
            static_cast<unsigned long long>(fileSize.QuadPart),
            ((fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) ? L"yes" : L"no");
        AppendLine(listBox, line);
    } while (FindNextFileW(hFind, &fd));

    FindClose(hFind);

    wchar_t filePath[MAX_PATH];
    swprintf_s(filePath, L"%ls\\win32_ntfs_demo.txt", currentDir);

    HANDLE hFile = CreateFileW(filePath, GENERIC_READ, FILE_SHARE_READ, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (hFile != INVALID_HANDLE_VALUE) {
        wchar_t finalPath[MAX_PATH];
        DWORD len = GetFinalPathNameByHandleW(hFile, finalPath, MAX_PATH, FILE_NAME_NORMALIZED);
        if (len > 0) {
            wchar_t line[512];
            swprintf_s(line, L"Full path: %ls", finalPath);
            AppendLine(listBox, line);
        }

        BY_HANDLE_FILE_INFORMATION info = {};
        if (GetFileInformationByHandle(hFile, &info)) {
            wchar_t meta[512];
            swprintf_s(meta,
                L"Volume serial: 0x%08X | index: 0x%08X%08X | attrs: 0x%08X",
                info.dwVolumeSerialNumber,
                info.nFileIndexHigh,
                info.nFileIndexLow,
                info.dwFileAttributes);
            AppendLine(listBox, meta);
        }

        CloseHandle(hFile);
    }
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        RECT rc;
        GetClientRect(hwnd, &rc);

        CreateWindowExW(0, L"BUTTON", L"Create + Scan",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            20, 20, 180, 32, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(ID_BUTTON_SCAN)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        CreateWindowExW(0, L"BUTTON", L"Watch Demo (ReadDirectoryChangesW)",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            210, 20, 380, 32, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(ID_BUTTON_WATCH)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        CreateWindowExW(0, L"LISTBOX", L"",
            WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL | LBS_NOTIFY | LBS_HASSTRINGS,
            20, 70, rc.right - 40, rc.bottom - 90, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(ID_LISTBOX)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        CreateDemoFile();
        ScanFiles(GetDlgItem(hwnd, ID_LISTBOX));
        return 0;
    }
    case WM_COMMAND:
        if (LOWORD(wParam) == ID_BUTTON_SCAN && HIWORD(wParam) == BN_CLICKED) {
            CreateDemoFile();
            ScanFiles(GetDlgItem(hwnd, ID_LISTBOX));
        }
        if (LOWORD(wParam) == ID_BUTTON_WATCH && HIWORD(wParam) == BN_CLICKED) {
            EnableWindow((HWND)lParam, FALSE);      // 演示期间防重入，结束消息里恢复
            StartWatchDemo(hwnd, GetDlgItem(hwnd, ID_LISTBOX));
        }
        return 0;
    case WM_APP_WATCHLINE:
        if (lParam) {
            AppendLine(GetDlgItem(hwnd, ID_LISTBOX), (const wchar_t*)lParam);
            delete[] (wchar_t*)lParam;              // 接收方释放（PostMessage 跨线程送字符串的纪律）
        }
        return 0;
    case WM_APP_WATCHDONE: {
        HWND btn = GetDlgItem(hwnd, ID_BUTTON_WATCH);
        if (btn) EnableWindow(btn, TRUE);
        AppendLine(GetDlgItem(hwnd, ID_LISTBOX), L"=== 监视结束（事件序列：新建→修改→改名→删除→建删子目录；缓冲有合并可能） ===");
        return 0;
    }
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int) {
    const wchar_t CLASS_NAME[] = L"FileSystemDeepDiveWindowClass";

    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
    wc.lpszClassName = CLASS_NAME;

    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(
        0, CLASS_NAME, L"Win32 File System Deep Dive",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 620, 480,
        nullptr, nullptr, hInstance, nullptr);

    if (!hwnd) {
        return 1;
    }

    ShowWindow(hwnd, SW_SHOWDEFAULT);
    UpdateWindow(hwnd);

    MSG msg = {};
    while (GetMessageW(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }

    return 0;
}
