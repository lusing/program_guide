// 15_dpi_modern_window — Per-Monitor V2 DPI 感知 + Windows 11 现代视觉
//
// 对应教程：docs/05-GDI绘图与现代显示.md 第 5.6 / 5.7 节
//
// 演示要点：
//   1. SetProcessDpiAwarenessContext(PER_MONITOR_AWARE_V2)：声明每显示器 DPI 感知
//   2. WM_DPICHANGED：窗口拖到不同缩放的屏幕时，按系统建议矩形移动并重新布局
//   3. GetDpiForWindow：所有布局尺寸 = 基准像素 × (dpi / 96)，不写死像素
//   4. DwmSetWindowAttribute：Win11 圆角；老系统上调用失败即降级，程序照常运行

#include <windows.h>
#include <dwmapi.h>
#include <cstdio>

#pragma comment(lib, "user32.lib")
#pragma comment(lib, "gdi32.lib")
#pragma comment(lib, "dwmapi.lib")

constexpr int IDC_STATUS = 1001;

// 把"基准像素"换算成当前 DPI 下的真实像素：96 DPI = 100%
static int Scale(int basePx, UINT dpi) {
    return MulDiv(basePx, (int)dpi, 96);
}

static void ApplyRoundedCorners(HWND hwnd) {
    // Windows 11+：请求系统圆角。老系统返回错误码，忽略即可（可降级）。
    DWM_WINDOW_CORNER_PREFERENCE pref = DWMWCP_ROUND;
    DwmSetWindowAttribute(hwnd, DWMWA_WINDOW_CORNER_PREFERENCE,
                          &pref, sizeof(pref));
}

// 按当前 DPI 重新摆放控件（真实项目里布局越复杂，这个函数的价值越大）
static void LayoutControls(HWND hwnd, UINT dpi) {
    RECT rc;
    GetClientRect(hwnd, &rc);
    int margin = Scale(16, dpi);
    int h = Scale(28, dpi);
    MoveWindow(GetDlgItem(hwnd, IDC_STATUS),
               margin, rc.bottom - margin - h, rc.right - margin * 2, h, TRUE);
}

static void UpdateStatusText(HWND hwnd) {
    UINT dpi = GetDpiForWindow(hwnd);                 // Windows 10+
    wchar_t text[128];
    swprintf_s(text, L"当前窗口 DPI = %u（缩放 %.0f%%）——试试拖到另一个缩放不同的显示器",
               dpi, dpi / 96.0f * 100.0f);
    SetWindowTextW(GetDlgItem(hwnd, IDC_STATUS), text);
}

static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        HINSTANCE hInst = ((LPCREATESTRUCTW)lParam)->hInstance;
        CreateWindowExW(0, L"STATIC", L"", WS_CHILD | WS_VISIBLE | SS_LEFT,
                        0, 0, 100, 28, hwnd,
                        (HMENU)(UINT_PTR)IDC_STATUS, hInst, nullptr);

        ApplyRoundedCorners(hwnd);
        LayoutControls(hwnd, GetDpiForWindow(hwnd));
        UpdateStatusText(hwnd);
        return 0;
    }

    case WM_DPICHANGED: {
        // 仅 Per-Monitor V2 感知下收到。wParam 高 16 位 = 新 DPI；
        // lParam 指向系统建议的新窗口矩形（系统已按 DPI 换算好，直接采用）。
        UINT newDpi = HIWORD(wParam);
        const RECT* suggested = (const RECT*)lParam;
        SetWindowPos(hwnd, nullptr,
                     suggested->left, suggested->top,
                     suggested->right - suggested->left,
                     suggested->bottom - suggested->top,
                     SWP_NOZORDER | SWP_NOACTIVATE);

        LayoutControls(hwnd, newDpi);
        UpdateStatusText(hwnd);
        return 0;
    }

    case WM_SIZE:
        LayoutControls(hwnd, GetDpiForWindow(hwnd));
        return 0;

    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        RECT rc;
        GetClientRect(hwnd, &rc);
        SetBkMode(hdc, TRANSPARENT);
        HFONT font = CreateFontW(Scale(16, GetDpiForWindow(hwnd)),
                                 0, 0, 0, FW_NORMAL, FALSE, FALSE, FALSE,
                                 DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
                                 CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
                                 DEFAULT_PITCH | FF_SWISS, L"Microsoft YaHei UI");
        HFONT old = (HFONT)SelectObject(hdc, font);
        DrawTextW(hdc, L"DPI-aware Win32 window", -1, &rc,
                  DT_SINGLELINE | DT_CENTER | DT_VCENTER);
        SelectObject(hdc, old);
        DeleteObject(font);
        EndPaint(hwnd, &ps);
        return 0;
    }

    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInstance, HINSTANCE, PWSTR, int nCmdShow) {
    // ★ 必须在任何窗口创建之前调用。程序清单声明亦可，代码声明便于演示。
    SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

    const wchar_t CLASS_NAME[] = L"DpiModernWindowClass";

    WNDCLASSEXW wc = {};
    wc.cbSize        = sizeof(wc);
    wc.lpfnWndProc   = WndProc;
    wc.hInstance     = hInstance;
    wc.hCursor       = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = CLASS_NAME;
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, CLASS_NAME, L"DPI & Modern Visual Demo",
                                WS_OVERLAPPEDWINDOW,
                                CW_USEDEFAULT, CW_USEDEFAULT, 560, 320,
                                nullptr, nullptr, hInstance, nullptr);
    if (!hwnd) {
        return 1;
    }

    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);

    MSG msg = {};
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
