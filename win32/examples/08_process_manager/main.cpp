#include <windows.h>
#include <tlhelp32.h>
#include <stdio.h>

const int ID_BUTTON_ENUMERATE = 1001;
const int ID_BUTTON_LAUNCH = 1002;
const int ID_BUTTON_TERMINATE = 1003;
const int ID_LISTBOX = 1004;

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

void LaunchNotepad(HWND hwnd) {
    wchar_t commandLine[] = L"notepad.exe";
    STARTUPINFOW si = { sizeof(si) };
    PROCESS_INFORMATION pi = {};

    if (!CreateProcessW(nullptr, commandLine, nullptr, nullptr, FALSE, 0, nullptr, nullptr, &si, &pi)) {
        wchar_t msg[128];
        swprintf_s(msg, L"CreateProcessW failed: 0x%08X", GetLastError());
        MessageBoxW(hwnd, msg, L"Process API", MB_OK | MB_ICONERROR);
        return;
    }

    wchar_t msg[128];
    swprintf_s(msg, L"Launched notepad.exe, PID = %lu", static_cast<unsigned long>(pi.dwProcessId));
    MessageBoxW(hwnd, msg, L"Process API", MB_OK | MB_ICONINFORMATION);

    CloseHandle(pi.hThread);
    CloseHandle(pi.hProcess);
}

void TerminateSelectedProcess(HWND hwnd) {
    HWND listBox = GetDlgItem(hwnd, ID_LISTBOX);
    int index = (int)SendMessageW(listBox, LB_GETCURSEL, 0, 0);
    if (index == LB_ERR) {
        MessageBoxW(hwnd, L"Please select a process", L"Process API", MB_OK | MB_ICONWARNING);
        return;
    }

    int textLen = (int)SendMessageW(listBox, LB_GETTEXTLEN, index, 0);
    if (textLen <= 0) {
        return;
    }

    wchar_t* buffer = new wchar_t[textLen + 1];
    SendMessageW(listBox, LB_GETTEXT, index, (LPARAM)buffer);

    DWORD pid = 0;
    if (swscanf_s(buffer, L"%lu", &pid) != 1) {
        delete[] buffer;
        MessageBoxW(hwnd, L"Unable to parse PID", L"Process API", MB_OK | MB_ICONERROR);
        return;
    }

    HANDLE process = OpenProcess(PROCESS_TERMINATE | SYNCHRONIZE, FALSE, pid);
    if (process == nullptr) {
        delete[] buffer;
        wchar_t err[128];
        swprintf_s(err, L"OpenProcess failed: 0x%08X", GetLastError());
        MessageBoxW(hwnd, err, L"Process API", MB_OK | MB_ICONERROR);
        return;
    }

    if (TerminateProcess(process, 1)) {
        MessageBoxW(hwnd, L"Process terminated", L"Process API", MB_OK | MB_ICONINFORMATION);
    } else {
        wchar_t err[128];
        swprintf_s(err, L"TerminateProcess failed: 0x%08X", GetLastError());
        MessageBoxW(hwnd, err, L"Process API", MB_OK | MB_ICONERROR);
    }

    CloseHandle(process);
    delete[] buffer;
    EnumerateProcesses(listBox);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        RECT rc;
        GetClientRect(hwnd, &rc);

        CreateWindowExW(0, L"BUTTON", L"Enumerate",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            20, 20, 120, 32, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(ID_BUTTON_ENUMERATE)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        CreateWindowExW(0, L"BUTTON", L"Launch Notepad",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            160, 20, 140, 32, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(ID_BUTTON_LAUNCH)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        CreateWindowExW(0, L"BUTTON", L"Terminate Selected",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            320, 20, 150, 32, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(ID_BUTTON_TERMINATE)),
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
        } else if (LOWORD(wParam) == ID_BUTTON_LAUNCH && HIWORD(wParam) == BN_CLICKED) {
            LaunchNotepad(hwnd);
            EnumerateProcesses(GetDlgItem(hwnd, ID_LISTBOX));
        } else if (LOWORD(wParam) == ID_BUTTON_TERMINATE && HIWORD(wParam) == BN_CLICKED) {
            TerminateSelectedProcess(hwnd);
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
        CW_USEDEFAULT, CW_USEDEFAULT, 620, 450,
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
