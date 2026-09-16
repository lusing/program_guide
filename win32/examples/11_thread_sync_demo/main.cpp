#include <windows.h>
#include <cstdio>
#include <cstdlib>

constexpr UINT WM_APP_THREAD_UPDATE = WM_APP + 1;

constexpr int IDC_STATUS = 1001;
constexpr int IDC_START = 1002;
constexpr int IDC_STOP = 1003;

struct DemoState {
    CRITICAL_SECTION criticalSection;
    LONG counter;
    HWND hwnd;
    HANDLE threadHandle;
    HANDLE doneEvent;
    bool started;
};

DWORD WINAPI WorkerThread(LPVOID param) {
    auto* state = static_cast<DemoState*>(param);

    for (int i = 1; i <= 5; ++i) {
        Sleep(250);

        EnterCriticalSection(&state->criticalSection);
        LONG value = ++state->counter;
        LeaveCriticalSection(&state->criticalSection);

        wchar_t buffer[128];
        swprintf_s(buffer, L"Worker tick %d -> counter = %ld", i, value);
        PostMessageW(state->hwnd, WM_APP_THREAD_UPDATE, 0, reinterpret_cast<LPARAM>(_wcsdup(buffer)));
    }

    SetEvent(state->doneEvent);
    // 注意：不在这里改 state->started——它只由 UI 线程读写，避免跨线程竞态；
    // UI 线程在"Wait for completion"里 join 线程后才复位它。
    return 0;
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        auto* state = new DemoState{};
        state->counter = 0;
        state->hwnd = hwnd;
        state->threadHandle = nullptr;
        state->doneEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
        state->started = false;
        InitializeCriticalSection(&state->criticalSection);

        SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(state));

        CreateWindowExW(
            0, L"STATIC", L"Thread synchronization demo",
            WS_CHILD | WS_VISIBLE | SS_LEFT,
            20, 20, 360, 28, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(IDC_STATUS)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        CreateWindowExW(
            0, L"BUTTON", L"Start worker",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            20, 70, 140, 36, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(IDC_START)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        CreateWindowExW(
            0, L"BUTTON", L"Wait for completion",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
            180, 70, 180, 36, hwnd,
            reinterpret_cast<HMENU>(static_cast<UINT_PTR>(IDC_STOP)),
            ((LPCREATESTRUCT)lParam)->hInstance, nullptr);

        SetWindowTextW(GetDlgItem(hwnd, IDC_STATUS), L"Idle");
        return 0;
    }

    case WM_COMMAND: {
        if (HIWORD(wParam) != BN_CLICKED) {
            return 0;
        }

        auto* state = reinterpret_cast<DemoState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
        const int id = LOWORD(wParam);

        if (id == IDC_START) {
            if (state->started) {   // started 只由 UI 线程读写，无需加锁
                MessageBoxW(hwnd, L"Worker is already running.", L"Win32 Thread Demo", MB_OK | MB_ICONINFORMATION);
                return 0;
            }

            ResetEvent(state->doneEvent);
            state->counter = 0;
            state->started = true;
            SetWindowTextW(GetDlgItem(hwnd, IDC_STATUS), L"Worker is running...");

            state->threadHandle = CreateThread(nullptr, 0, WorkerThread, state, 0, nullptr);
            if (state->threadHandle == nullptr) {
                state->started = false;
                SetWindowTextW(GetDlgItem(hwnd, IDC_STATUS), L"CreateThread failed");
                MessageBoxW(hwnd, L"CreateThread failed.", L"Win32 Thread Demo", MB_OK | MB_ICONERROR);
            }
            return 0;
        }

        if (id == IDC_STOP) {
            bool completed = false;
            if (state->threadHandle != nullptr) {
                WaitForSingleObject(state->threadHandle, INFINITE);   // join：等线程真正结束
                CloseHandle(state->threadHandle);
                state->threadHandle = nullptr;
                completed = true;
            }
            state->started = false;   // UI 线程内复位，之后再点 Start 可以重新运行

            if (completed && WaitForSingleObject(state->doneEvent, 0) == WAIT_OBJECT_0) {
                SetWindowTextW(GetDlgItem(hwnd, IDC_STATUS), L"Worker completed successfully");
            } else {
                SetWindowTextW(GetDlgItem(hwnd, IDC_STATUS), L"Worker waiting or not started");
            }
            return 0;
        }

        return 0;
    }

    case WM_APP_THREAD_UPDATE: {
        auto* text = reinterpret_cast<wchar_t*>(lParam);
        if (text != nullptr) {
            SetWindowTextW(GetDlgItem(hwnd, IDC_STATUS), text);
            free(text);
        }
        return 0;
    }

    case WM_DESTROY: {
        auto* state = reinterpret_cast<DemoState*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
        if (state != nullptr) {
            if (state->threadHandle != nullptr) {
                WaitForSingleObject(state->threadHandle, INFINITE);
                CloseHandle(state->threadHandle);
            }
            CloseHandle(state->doneEvent);
            DeleteCriticalSection(&state->criticalSection);
            delete state;
        }
        PostQuitMessage(0);
        return 0;
    }
    }

    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int) {
    const wchar_t CLASS_NAME[] = L"ThreadSyncDemoClass";

    WNDCLASSEXW wc = {};
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInstance;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_WINDOW + 1);
    wc.lpszClassName = CLASS_NAME;

    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(
        0, CLASS_NAME, L"Win32 Thread Sync Demo",
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT, CW_USEDEFAULT, 460, 200,
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
