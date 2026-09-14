#include <windows.h>
#include <stdio.h>

const int ID_BUTTON_REFRESH = 1001;
const int ID_LISTBOX = 1002;

void RefreshMemoryInfo(HWND listBox) {
    SendMessageW(listBox, LB_RESETCONTENT, 0, 0);

    MEMORYSTATUSEX mem = { sizeof(mem) };
    if (!GlobalMemoryStatusEx(&mem)) {
        SendMessageW(listBox, LB_ADDSTRING, 0, (LPARAM)L"GlobalMemoryStatusEx failed");
        return;
    }

    wchar_t buffer[256];
    swprintf_s(buffer, L"Total physical memory: %llu MB", mem.ullTotalPhys / (1024ULL * 1024ULL));
    SendMessageW(listBox, LB_ADDSTRING, 0, (LPARAM)buffer);

    swprintf_s(buffer, L"Available physical memory: %llu MB", mem.ullAvailPhys / (1024ULL * 1024ULL));
    SendMessageW(listBox, LB_ADDSTRING, 0, (LPARAM)buffer);

    swprintf_s(buffer, L"Total virtual memory: %llu MB", mem.ullTotalVirtual / (1024ULL * 1024ULL));
    SendMessageW(listBox, LB_ADDSTRING, 0, (LPARAM)buffer);

    swprintf_s(buffer, L"Available virtual memory: %llu MB", mem.ullAvailVirtual / (1024ULL * 1024ULL));
    SendMessageW(listBox, LB_ADDSTRING, 0, (LPARAM)buffer);

    SIZE_T bytes = 1024ULL * 1024ULL;
    void* p = VirtualAlloc(nullptr, bytes, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    if (p) {
        swprintf_s(buffer, L"VirtualAlloc success: %llu bytes allocated", static_cast<unsigned long long>(bytes));
        SendMessageW(listBox, LB_ADDSTRING, 0, (LPARAM)buffer);
        ZeroMemory(p, bytes);
        VirtualFree(p, 0, MEM_RELEASE);
    } else {
        swprintf_s(buffer, L"VirtualAlloc failed: 0x%08X", GetLastError());
        SendMessageW(listBox, LB_ADDSTRING, 0, (LPARAM)buffer);
    }
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        RECT rc;
        GetClientRect(hwnd, &rc);

        CreateWindowExW(0, L"BUTTON", L"Refresh Memory",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            20, 20, 180, 32, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(ID_BUTTON_REFRESH)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        CreateWindowExW(0, L"LISTBOX", L"",
            WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL | LBS_NOTIFY | LBS_HASSTRINGS,
            20, 70, rc.right - 40, rc.bottom - 90, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(ID_LISTBOX)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        RefreshMemoryInfo(GetDlgItem(hwnd, ID_LISTBOX));
        return 0;
    }
    case WM_COMMAND:
        if (LOWORD(wParam) == ID_BUTTON_REFRESH && HIWORD(wParam) == BN_CLICKED) {
            RefreshMemoryInfo(GetDlgItem(hwnd, ID_LISTBOX));
        }
        return 0;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int) {
    const wchar_t CLASS_NAME[] = L"MemoryMonitorWindowClass";

    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = CLASS_NAME;

    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(
        0, CLASS_NAME, L"Memory Monitor",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 560, 420,
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
