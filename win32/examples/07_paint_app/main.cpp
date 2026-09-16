// 07_paint_app — 会重绘的绘图板：状态-绘制分离
//
// 对应教程：docs/05-GDI绘图与现代显示.md 第 5.1 / 5.5 节
//
// 演示要点：
//   1. 界面内容 = 状态数据（线段列表）。WM_PAINT 全量重画，遮挡/缩放后内容不丢
//   2. 状态变化时调 InvalidateRect 标脏，而不是自己直接画
//   3. SetCapture / ReleaseCapture：拖出窗口边界也能持续收到鼠标消息
//   4. GDI 画笔的"创建→选中→换回→删除"四步纪律

#include <windows.h>
#include <windowsx.h>
#include <vector>

const wchar_t CLASS_NAME[] = L"PaintAppWindow";

struct Segment {
    POINT from;
    POINT to;
};

// ★ 状态：全部已画线段。删掉这个列表，重绘就无从谈起
static std::vector<Segment> g_strokes;
static bool g_drawing = false;
static POINT g_last{};

static void DrawAllStrokes(HDC hdc) {
    HPEN pen = CreatePen(PS_SOLID, 2, RGB(30, 30, 30));
    HPEN oldPen = (HPEN)SelectObject(hdc, pen);
    for (const Segment& s : g_strokes) {
        MoveToEx(hdc, s.from.x, s.from.y, nullptr);
        LineTo(hdc, s.to.x, s.to.y);
    }
    SelectObject(hdc, oldPen);
    DeleteObject(pen);
}

static LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_LBUTTONDOWN:
        g_drawing = true;
        g_last = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };
        SetCapture(hwnd);                       // 拖出窗口也继续收鼠标消息
        return 0;

    case WM_LBUTTONUP:
        g_drawing = false;
        ReleaseCapture();                       // 与 SetCapture 成对
        return 0;

    case WM_MOUSEMOVE:
        if (g_drawing) {
            POINT now = { GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam) };
            g_strokes.push_back({ g_last, now });
            g_last = now;
            InvalidateRect(hwnd, nullptr, FALSE);   // ★ 标脏即可，绘制交给 WM_PAINT
        }
        return 0;

    case WM_PAINT: {
        PAINTSTRUCT ps;
        HDC hdc = BeginPaint(hwnd, &ps);
        DrawAllStrokes(hdc);                    // 全量重画：内容随时可重建
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

    ShowWindow(hwnd, nCmdShow);
    UpdateWindow(hwnd);

    MSG msg = {};
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
