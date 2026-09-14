#include <windows.h>
#include <stdio.h>

const int ID_BUTTON_CREATE = 1001;
const int ID_BUTTON_LIST = 1002;
const int ID_LISTBOX = 1003;

void WriteDemoFile() {
    wchar_t currentDir[MAX_PATH];
    if (GetCurrentDirectoryW(MAX_PATH, currentDir) == 0) {
        return;
    }

    wchar_t filePath[MAX_PATH];
    swprintf_s(filePath, L"%ls\\win32_file_demo.txt", currentDir);

    HANDLE file = CreateFileW(filePath,
        GENERIC_WRITE,
        0,
        nullptr,
        CREATE_ALWAYS,
        FILE_ATTRIBUTE_NORMAL,
        nullptr);

    if (file == INVALID_HANDLE_VALUE) {
        return;
    }

    const char data[] = "This file was created by Win32 API file management demo.\r\n";
    DWORD written = 0;
    WriteFile(file, data, static_cast<DWORD>(strlen(data)), &written, nullptr);
    CloseHandle(file);
}

void ListFiles(HWND listBox) {
    SendMessageW(listBox, LB_RESETCONTENT, 0, 0);

    wchar_t currentDir[MAX_PATH];
    if (GetCurrentDirectoryW(MAX_PATH, currentDir) == 0) {
        SendMessageW(listBox, LB_ADDSTRING, 0, (LPARAM)L"GetCurrentDirectoryW failed");
        return;
    }

    wchar_t searchPattern[MAX_PATH];
    swprintf_s(searchPattern, L"%ls\\*", currentDir);

    WIN32_FIND_DATAW fileData;
    HANDLE findHandle = FindFirstFileW(searchPattern, &fileData);
    if (findHandle == INVALID_HANDLE_VALUE) {
        SendMessageW(listBox, LB_ADDSTRING, 0, (LPARAM)L"No files found");
        return;
    }

    do {
        if ((fileData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) == 0) {
            SendMessageW(listBox, LB_ADDSTRING, 0, (LPARAM)fileData.cFileName);
        }
    } while (FindNextFileW(findHandle, &fileData));

    FindClose(findHandle);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        RECT rc;
        GetClientRect(hwnd, &rc);

        CreateWindowExW(0, L"BUTTON", L"Create Demo File",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            20, 20, 180, 32, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(ID_BUTTON_CREATE)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        CreateWindowExW(0, L"BUTTON", L"List Files",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            220, 20, 180, 32, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(ID_BUTTON_LIST)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        CreateWindowExW(0, L"LISTBOX", L"",
            WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL | LBS_NOTIFY | LBS_HASSTRINGS,
            20, 70, rc.right - 40, rc.bottom - 90, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(ID_LISTBOX)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        ListFiles(GetDlgItem(hwnd, ID_LISTBOX));
        return 0;
    }
    case WM_COMMAND:
        if (LOWORD(wParam) == ID_BUTTON_CREATE && HIWORD(wParam) == BN_CLICKED) {
            WriteDemoFile();
            ListFiles(GetDlgItem(hwnd, ID_LISTBOX));
        }
        else if (LOWORD(wParam) == ID_BUTTON_LIST && HIWORD(wParam) == BN_CLICKED) {
            ListFiles(GetDlgItem(hwnd, ID_LISTBOX));
        }
        return 0;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int) {
    const wchar_t CLASS_NAME[] = L"FileManagerWindowClass";

    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = CLASS_NAME;

    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(
        0, CLASS_NAME, L"File Manager",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 620, 420,
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
