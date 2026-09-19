// 28_direct2d_hello — Direct2D 渐变/抗锯齿图形 + DirectWrite 文本 + resize/重建
//
// 对应教程：docs/25-Direct2D与DirectWrite.md
#include <windows.h>
#include <d2d1.h>
#include <d2d1helper.h>
#include <dwrite.h>

template <class T> void SafeRelease(T** p) {
    if (*p) { (*p)->Release(); *p = nullptr; }
}

static ID2D1Factory*             g_factory = nullptr;
static IDWriteFactory*           g_dw      = nullptr;
static ID2D1HwndRenderTarget*    g_target  = nullptr;
static ID2D1SolidColorBrush*     g_solid   = nullptr;
static ID2D1LinearGradientBrush* g_grad    = nullptr;
static IDWriteTextFormat*        g_format  = nullptr;

static const wchar_t kText[] =
    L"Direct2D + DirectWrite\n硬件加速 · 抗锯齿 · 设备无关像素";

static void CreateDeviceResources(HWND hwnd) {
    if (g_target) return;
    RECT rc; GetClientRect(hwnd, &rc);
    g_factory->CreateHwndRenderTarget(
        D2D1::RenderTargetProperties(),
        D2D1::HwndRenderTargetProperties(
            hwnd, D2D1::SizeU(rc.right - rc.left, rc.bottom - rc.top)),
        &g_target);

    g_target->CreateSolidColorBrush(D2D1::ColorF(D2D1::ColorF::White), &g_solid);

    ID2D1GradientStopCollection* stops = nullptr;
    D2D1_GRADIENT_STOP gs[] = {
        { 0.0f, D2D1::ColorF(D2D1::ColorF::CornflowerBlue)   },
        { 1.0f, D2D1::ColorF(D2D1::ColorF::MediumVioletRed)  },
    };
    g_target->CreateGradientStopCollection(gs, 2, &stops);
    g_target->CreateLinearGradientBrush(
        D2D1::LinearGradientBrushProperties(
            D2D1::Point2F(0, 0), D2D1::Point2F(700, 0)),
        stops, &g_grad);
    stops->Release();
}

static void DiscardDeviceResources() {
    // 画刷是"设备相关资源"，绑定在 target 上：先画刷后 target
    SafeRelease(&g_solid);
    SafeRelease(&g_grad);
    SafeRelease(&g_target);
}

static void Draw() {
    g_target->BeginDraw();
    g_target->Clear(D2D1::ColorF(0.09f, 0.10f, 0.14f));       // 深色底

    D2D1_SIZE_F size = g_target->GetSize();
    g_target->FillRoundedRectangle(                            // 抗锯齿圆角矩形
        D2D1::RoundedRect(
            D2D1::RectF(60, 60, size.width - 60, size.height - 60), 18, 18),
        g_grad);
    g_target->DrawEllipse(                                     // 抗锯齿圆
        D2D1::Ellipse(D2D1::Point2F(170, 190), 70, 70), g_solid, 2.0f);
    g_target->DrawTextW(                                       // DirectWrite 文本
        kText, (UINT32)lstrlenW(kText), g_format,
        D2D1::RectF(280, 140, size.width - 80, 260), g_solid);

    if (g_target->EndDraw() == (HRESULT)D2DERR_RECREATE_TARGET) {
        DiscardDeviceResources();   // 设备丢失（锁屏/驱动重置）：释放待重建
    }
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_PAINT:
        ValidateRect(hwnd, nullptr);   // D2D 自己管理脏区；这行只是安抚 GDI 体系
        CreateDeviceResources(hwnd);
        Draw();
        return 0;
    case WM_SIZE:
        if (g_target) {
            D2D1_SIZE_U s = D2D1::SizeU(LOWORD(lParam), HIWORD(lParam));
            g_target->Resize(s);       // 渲染目标跟窗口走
            InvalidateRect(hwnd, nullptr, FALSE);
        }
        return 0;
    case WM_ERASEBKGND:
        return 1;                      // 不让 GDI 擦背景——防闪
    case WM_DESTROY:
        DiscardDeviceResources();
        SafeRelease(&g_format);
        SafeRelease(&g_dw);
        SafeRelease(&g_factory);
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nShow) {
    // 两个工厂：D2D 管"怎么画"，DWrite 管"文字"
    D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &g_factory);
    DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory),
                        (IUnknown**)&g_dw);
    g_dw->CreateTextFormat(L"微软雅黑", nullptr, DWRITE_FONT_WEIGHT_NORMAL,
                           DWRITE_FONT_STYLE_NORMAL, DWRITE_FONT_STRETCH_NORMAL,
                           26.0f, L"zh-CN", &g_format);

    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.lpszClassName = L"D2DHelloClass";
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, L"D2DHelloClass", L"Direct2D + DirectWrite",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 760, 420,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
