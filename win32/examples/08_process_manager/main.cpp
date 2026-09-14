#include <windows.h>
#include <tlhelp32.h>
#include <stdio.h>

const int ID_BUTTON_ENUMERATE = 1001;
const int ID_LISTBOX = 1002;

void EnumerateProcesses(HWND listBox) {
    SendMessageW(listBox, LB_RESETCONTENT, 0, 0);

    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snapshot == INVALID_HANDLE_VALUE) {
        SendMessageW(listBox, LB_ADDSTRING, 0, (LPARAM)L"CreateToolhelp32Snapshot failed");
        return;
    }

    PROCESSENTRY32W pe = { sizeof(pe) };
    if (Process32FirstW(snapshot, &pe)) {
        do {
            wchar_t buffer[256];
            swprintf_s(buffer, L"%lu - %ls", static_cast<unsigned long>(pe.th32ProcessID), pe.szExeFile);
            SendMessageW(listBox, LB_ADDSTRING, 0, (LPARAM)buffer);
        } while (Process32NextW(snapshot, &pe));
    }

    CloseHandle(snapshot);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        RECT rc;
        GetClientRect(hwnd, &rc);

        CreateWindowExW(0, L"BUTTON", L"Enumerate Processes",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            20, 20, 180, 32, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(ID_BUTTON_ENUMERATE)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        CreateWindowExW(0, L"LISTBOX", L"",
            WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL | LBS_NOTIFY | LBS_HASSTRINGS,
            20, 70, rc.right - 40, rc.bottom - 90, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(ID_LISTBOX)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        EnumerateProcesses(GetDlgItem(hwnd, ID_LISTBOX));
        return 0;
    }
    case WM_COMMAND:
        if (LOWORD(wParam) == ID_BUTTON_ENUMERATE && HIWORD(wParam) == BN_CLICKED) {
            EnumerateProcesses(GetDlgItem(hwnd, ID_LISTBOX));
        }
        return 0;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int) {
    const wchar_t CLASS_NAME[] = L"ProcessManagerWindowClass";

    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = CLASS_NAME;

    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(
        0, CLASS_NAME, L"Process Manager",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 520, 420,
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
