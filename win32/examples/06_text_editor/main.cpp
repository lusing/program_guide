#include <windows.h>
#include <commctrl.h>
#include <stdio.h>

#pragma comment(lib, "comctl32.lib")

const wchar_t CLASS_NAME[] = L"TextEditorWindow";
const int IDC_EDIT = 1001;

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        RECT rc;
        GetClientRect(hwnd, &rc);
        CreateWindowExW(0, L"EDIT", L"",
            WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL |
            ES_MULTILINE | ES_AUTOVSCROLL | ES_WANTRETURN | WS_TABSTOP,
            0, 0, rc.right - rc.left, rc.bottom - rc.top,
            hwnd, reinterpret_cast<HMENU>(static_cast<UINT_PTR>(IDC_EDIT)), ((LPCREATESTRUCT)lParam)->hInstance, nullptr);
        return 0;
    }
    case WM_SIZE: {
        HWND edit = GetDlgItem(hwnd, IDC_EDIT);
        if (edit) {
            RECT rc;
            GetClientRect(hwnd, &rc);
            MoveWindow(edit, 0, 0, LOWORD(lParam), HIWORD(lParam), TRUE);
        }
        return 0;
    }
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int) {
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

    ShowWindow(hwnd, SW_SHOWDEFAULT);
    UpdateWindow(hwnd);

    MSG msg = {};
    while (GetMessageW(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return 0;
}
