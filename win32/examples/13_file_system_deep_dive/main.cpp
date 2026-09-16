#include <windows.h>
#include <stdio.h>

const int ID_BUTTON_SCAN = 1001;
const int ID_LISTBOX = 1002;

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
        return 0;
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
