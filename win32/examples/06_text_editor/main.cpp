// 06_text_editor — 带菜单与文件打开/保存的 RichEdit 文本编辑器
//
// 对应教程：docs/10-菜单对话框与资源.md（10.2/10.6 节）、docs/11-综合应用三例.md
//
// 演示要点：
//   1. 纯代码创建菜单（CreateMenu / AppendMenu / SetMenu），命令 ID 统一进 WM_COMMAND
//   2. GetOpenFileNameW / GetSaveFileNameW 通用文件对话框（comdlg32）
//   3. CreateFileW / GetFileSizeEx / ReadFile / WriteFile 的标准读写三段式
//   4. 多字节（UTF-8）与宽字符互转：MultiByteToWideChar / WideCharToMultiByte
//   5. RichEdit 4.1（RICHEDIT50W）：必须先 LoadLibraryW(L"msftedit.dll")；
//      Get/SetWindowTextW 与 EN_* 通知对 RichEdit 同样有效——升级零迁移成本
//   6. 编辑区铺满客户区，WM_SIZE 重新布局

#include <windows.h>
#include <commdlg.h>
#include <richedit.h>
#include <stdio.h>
#include <vector>
#include <string>

#pragma comment(lib, "comdlg32.lib")

constexpr int IDM_OPEN = 101;
constexpr int IDM_SAVE = 102;
constexpr int IDM_EXIT = 103;
constexpr int IDC_EDIT = 1001;

const wchar_t CLASS_NAME[] = L"TextEditorWindow";

static HMODULE g_richedDll = nullptr;   // RichEdit 4.1 的 DLL 句柄（退出时释放）

// ---------- 菜单 ----------

static void BuildMenu(HWND hwnd) {
    HMENU hFile = CreatePopupMenu();
    AppendMenuW(hFile, MF_STRING, IDM_OPEN, L"打开(&O)...");
    AppendMenuW(hFile, MF_STRING, IDM_SAVE, L"保存(&S)...");
    AppendMenuW(hFile, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(hFile, MF_STRING, IDM_EXIT, L"退出(&X)");

    HMENU hBar = CreateMenu();
    AppendMenuW(hBar, MF_POPUP | MF_STRING, (UINT_PTR)hFile, L"文件(&F)");
    SetMenu(hwnd, hBar);
}

// ---------- 文件对话框 ----------

static bool PromptPath(HWND hwnd, bool forSave, wchar_t* path, DWORD cap) {
    OPENFILENAMEW ofn = {};
    ofn.lStructSize = sizeof(ofn);
    ofn.hwndOwner   = hwnd;
    ofn.lpstrFilter = L"文本文件 (*.txt)\0*.txt\0所有文件 (*.*)\0*.*\0";
    ofn.lpstrFile   = path;
    ofn.nMaxFile    = cap;
    ofn.Flags       = OFN_HIDEREADONLY | (forSave ? OFN_OVERWRITEPROMPT
                                                  : OFN_FILEMUSTEXIST);
    return forSave ? GetSaveFileNameW(&ofn) : GetOpenFileNameW(&ofn);
}

// ---------- 文件 I/O（标准三段式：打开 → 循环读写 → 关闭） ----------

static void LoadFileToEdit(HWND hwnd, const wchar_t* path) {
    HANDLE h = CreateFileW(path, GENERIC_READ, FILE_SHARE_READ,
                           nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) {
        wchar_t msg[256];
        FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                       nullptr, GetLastError(), 0, msg, 256, nullptr);
        MessageBoxW(hwnd, msg, L"打开失败", MB_OK | MB_ICONERROR);
        return;
    }

    LARGE_INTEGER size = {};
    GetFileSizeEx(h, &size);

    std::vector<char> raw((size_t)size.QuadPart + 1, 0);
    DWORD total = 0;
    while (total < (DWORD)size.QuadPart) {          // ★ 循环读：不保证一次读完
        DWORD got = 0;
        if (!ReadFile(h, raw.data() + total, (DWORD)size.QuadPart - total, &got, nullptr)
            || got == 0) {
            break;
        }
        total += got;
    }
    CloseHandle(h);

    // 文件按 UTF-8 假设 → 转宽字符给 EDIT 控件
    int wlen = MultiByteToWideChar(CP_UTF8, 0, raw.data(), (int)total, nullptr, 0);
    std::wstring text(wlen, L'\0');
    MultiByteToWideChar(CP_UTF8, 0, raw.data(), (int)total, text.data(), wlen);

    SetWindowTextW(GetDlgItem(hwnd, IDC_EDIT), text.c_str());
}

static void SaveEditToFile(HWND hwnd, const wchar_t* path) {
    int len = GetWindowTextLengthW(GetDlgItem(hwnd, IDC_EDIT));
    std::wstring text(len + 1, L'\0');
    GetWindowTextW(GetDlgItem(hwnd, IDC_EDIT), text.data(), len + 1);

    int bytes = WideCharToMultiByte(CP_UTF8, 0, text.c_str(), -1,
                                    nullptr, 0, nullptr, nullptr);
    std::vector<char> raw((size_t)bytes);
    WideCharToMultiByte(CP_UTF8, 0, text.c_str(), -1,
                        raw.data(), bytes, nullptr, nullptr);   // ★ 真正的转换

    HANDLE h = CreateFileW(path, GENERIC_WRITE, 0,
                           nullptr, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    if (h == INVALID_HANDLE_VALUE) {
        wchar_t msg[256];
        FormatMessageW(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                       nullptr, GetLastError(), 0, msg, 256, nullptr);
        MessageBoxW(hwnd, msg, L"保存失败", MB_OK | MB_ICONERROR);
        return;
    }

    DWORD written = 0;
    WriteFile(h, raw.data(), (DWORD)(bytes - 1), &written, nullptr);
    CloseHandle(h);
}

// ---------- 窗口过程 ----------

static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        BuildMenu(hwnd);
        HWND hEdit = CreateWindowExW(WS_EX_CLIENTEDGE, L"RICHEDIT50W", L"",
            WS_CHILD | WS_VISIBLE | WS_VSCROLL | WS_TABSTOP
            | ES_MULTILINE | ES_AUTOVSCROLL | ES_WANTRETURN,
            0, 0, 100, 100, hwnd,
            (HMENU)(UINT_PTR)IDC_EDIT,
            ((LPCREATESTRUCTW)lParam)->hInstance, nullptr);
        // 默认字体：Consolas 12pt（CHARFORMAT2W 的 yHeight 单位是 twips：12*20=240）
        CHARFORMAT2W cf = { sizeof(cf) };
        cf.dwMask = CFM_FACE | CFM_SIZE;
        cf.yHeight = 240;
        lstrcpynW(cf.szFaceName, L"Consolas", LF_FACESIZE);
        SendMessageW(hEdit, EM_SETCHARFORMAT, SCF_ALL, (LPARAM)&cf);
        return 0;
    }
    case WM_SIZE:
        MoveWindow(GetDlgItem(hwnd, IDC_EDIT),
                   0, 0, LOWORD(lParam), HIWORD(lParam), TRUE);
        return 0;
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDM_OPEN: {
            wchar_t path[MAX_PATH] = L"";
            if (PromptPath(hwnd, false, path, MAX_PATH)) {
                LoadFileToEdit(hwnd, path);
                SetWindowTextW(hwnd, path);
            }
            return 0;
        }
        case IDM_SAVE: {
            wchar_t path[MAX_PATH] = L"";
            if (PromptPath(hwnd, true, path, MAX_PATH)) {
                SaveEditToFile(hwnd, path);
                SetWindowTextW(hwnd, path);
            }
            return 0;
        }
        case IDM_EXIT:
            DestroyWindow(hwnd);
            return 0;
        }
        return 0;
    case WM_DESTROY:
        if (g_richedDll) {
            FreeLibrary(g_richedDll);    // RichEdit DLL 用完释放
        }
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int nCmdShow) {
    g_richedDll = LoadLibraryW(L"msftedit.dll");   // RichEdit 4.1：必须先加载
    if (!g_richedDll) {
        MessageBoxW(nullptr, L"加载 msftedit.dll 失败", L"错误", MB_ICONERROR);
        return 1;
    }

    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = CLASS_NAME;

    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, CLASS_NAME, L"Text Editor",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 640, 480,
        nullptr, nullptr, hInstance, nullptr);

    if (!hwnd) { return 1; }

    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);

    MSG msg = {};
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
