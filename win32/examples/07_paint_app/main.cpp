#include <windows.h>

const wchar_t CLASS_NAME[] = L"PaintAppWindow";
const int IDC_DRAW = 1001;

struct PaintState {
    bool drawing = false;
    POINT lastPoint{};
};

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    static PaintState state;

    switch (msg) {
    case WM_LBUTTONDOWN: {
        state.drawing = true;
        state.lastPoint.x = LOWORD(lParam);
        state.lastPoint.y = HIWORD(lParam);
        SetCapture(hwnd);
        return 0;
    }
    case WM_LBUTTONUP: {
        state.drawing = false;
        ReleaseCapture();
        return 0;
    }
    case WM_MOUSEMOVE: {
        if (state.drawing) {
            HDC hdc = GetDC(hwnd);
            MoveToEx(hdc, state.lastPoint.x, state.lastPoint.y, nullptr);
            LineTo(hdc, LOWORD(lParam), HIWORD(lParam));
            ReleaseDC(hwnd, hdc);
            state.lastPoint.x = LOWORD(lParam);
            state.lastPoint.y = HIWORD(lParam);
        }
        return 0;
    }
    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        EndPaint(hwnd, &ps);
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
    wc.hCursor = LoadCursor(nullptr, IDC_CROSS);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = CLASS_NAME;

    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, CLASS_NAME, L"Paint App",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 800, 600,
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
