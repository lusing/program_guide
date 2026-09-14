#include <windows.h>
#include <psapi.h>
#include <stdio.h>

const int ID_BUTTON_REFRESH = 1001;
const int ID_LISTBOX = 1002;

void AppendLine(HWND listBox, const wchar_t* text) {
    SendMessageW(listBox, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(text));
}

void RefreshMemoryInfo(HWND listBox) {
    SendMessageW(listBox, LB_RESETCONTENT, 0, 0);

    SYSTEM_INFO sysInfo = {};
    GetSystemInfo(&sysInfo);

    wchar_t buffer[256];
    swprintf_s(buffer, L"Page size: %lu bytes", static_cast<unsigned long>(sysInfo.dwPageSize));
    AppendLine(listBox, buffer);

    MEMORYSTATUSEX mem = { sizeof(mem) };
    if (GlobalMemoryStatusEx(&mem)) {
        swprintf_s(buffer, L"Total physical: %llu MB", mem.ullTotalPhys / (1024ULL * 1024ULL));
        AppendLine(listBox, buffer);

        swprintf_s(buffer, L"Available physical: %llu MB", mem.ullAvailPhys / (1024ULL * 1024ULL));
        AppendLine(listBox, buffer);

        swprintf_s(buffer, L"Total virtual: %llu MB", mem.ullTotalVirtual / (1024ULL * 1024ULL));
        AppendLine(listBox, buffer);

        swprintf_s(buffer, L"Available virtual: %llu MB", mem.ullAvailVirtual / (1024ULL * 1024ULL));
        AppendLine(listBox, buffer);
    } else {
        AppendLine(listBox, L"GlobalMemoryStatusEx failed");
    }

    PROCESS_MEMORY_COUNTERS pmc = { sizeof(pmc) };
    if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
        swprintf_s(buffer, L"Working set: %llu KB", pmc.WorkingSetSize / 1024ULL);
        AppendLine(listBox, buffer);

        swprintf_s(buffer, L"Peak working set: %llu KB", pmc.PeakWorkingSetSize / 1024ULL);
        AppendLine(listBox, buffer);
    } else {
        AppendLine(listBox, L"GetProcessMemoryInfo failed");
    }

    const SIZE_T allocBytes = 1024ULL * 1024ULL;
    void* memory = VirtualAlloc(nullptr, allocBytes, MEM_RESERVE | MEM_COMMIT, PAGE_READWRITE);
    if (memory) {
        swprintf_s(buffer, L"VirtualAlloc succeeded: %llu bytes", static_cast<unsigned long long>(allocBytes));
        AppendLine(listBox, buffer);

        DWORD oldProtect = 0;
        if (VirtualProtect(memory, allocBytes, PAGE_READONLY, &oldProtect)) {
            AppendLine(listBox, L"VirtualProtect changed memory to PAGE_READONLY");
            VirtualProtect(memory, allocBytes, PAGE_READWRITE, &oldProtect);
        } else {
            AppendLine(listBox, L"VirtualProtect failed");
        }

        ZeroMemory(memory, allocBytes);
        VirtualFree(memory, 0, MEM_RELEASE);
    } else {
        swprintf_s(buffer, L"VirtualAlloc failed: 0x%08X", GetLastError());
        AppendLine(listBox, buffer);
    }

    HANDLE heap = GetProcessHeap();
    void* heapBlock = HeapAlloc(heap, HEAP_ZERO_MEMORY, 4096);
    if (heapBlock) {
        strcpy_s(static_cast<char*>(heapBlock), 4096, "HeapAlloc demo");
        AppendLine(listBox, L"HeapAlloc succeeded");
        HeapFree(heap, 0, heapBlock);
    } else {
        AppendLine(listBox, L"HeapAlloc failed");
    }

    HANDLE mapping = CreateFileMappingW(INVALID_HANDLE_VALUE, nullptr, PAGE_READWRITE, 0, 4096, L"Local\\Win32MemoryDemoMap");
    if (mapping) {
        void* view = MapViewOfFile(mapping, FILE_MAP_ALL_ACCESS, 0, 0, 4096);
        if (view) {
            const char text[] = "Mapped file memory";
            memcpy(view, text, sizeof(text));
            AppendLine(listBox, L"MapViewOfFile succeeded");
            UnmapViewOfFile(view);
        } else {
            AppendLine(listBox, L"MapViewOfFile failed");
        }
        CloseHandle(mapping);
    } else {
        swprintf_s(buffer, L"CreateFileMappingW failed: 0x%08X", GetLastError());
        AppendLine(listBox, buffer);
    }
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        RECT rc;
        GetClientRect(hwnd, &rc);

        CreateWindowExW(0, L"BUTTON", L"Refresh Memory",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            20, 20, 170, 32, hwnd,
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
    const wchar_t CLASS_NAME[] = L"MemoryDeepDiveWindowClass";

    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
    wc.lpszClassName = CLASS_NAME;

    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(
        0, CLASS_NAME, L"Win32 Memory Deep Dive",
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
