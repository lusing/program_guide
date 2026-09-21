// 22_modern_drawing：GDI+ 与 Direct2D 两条现代绘图路线。
//
//   空格键 / 切换按钮：在两套渲染之间切 ——
//     GDI+ 路线：Graphics g(dc) + 抗锯齿 + 线性渐变 + 半透明高光
//     D2D  路线：CreateFactory → CreateHwndRenderTarget → BeginDraw →
//                Clear/FillEllipse/DrawText(DWrite) → EndDraw
//                （EndDraw 返回 D2DERR_RECREATE_TARGET 时重建渲染目标）
//
// GDI+ 需要 GdiplusStartup/Shutdown 配对（InitInstance/ExitInstance）；
// D2D/DWrite 的库（gdiplus.lib d2d1.lib dwrite.lib）由 build.ps1 的
// extraLibsByExample 白名单链接 —— MFC 的 afx.h 不自动链它们。
//
// 编译运行：.\build.ps1 -File 22_modern_drawing

#include "resource.h"
#include <afxwin.h>
#include <gdiplus.h>
#include <d2d1.h>
#include <dwrite.h>

// ---------- 主框架：同一个客户区，两套渲染 ----------
class CDrawFrame : public CFrameWnd {
public:
    ~CDrawFrame() override { ReleaseD2D(); }

    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        if (CFrameWnd::OnCreate(lpCreateStruct) == -1)
            return -1;

        // D2D/DWrite 工厂：进程级创建一次
        D2D1CreateFactory(D2D1_FACTORY_TYPE_SINGLE_THREADED, &m_d2dFactory);
        DWriteCreateFactory(DWRITE_FACTORY_TYPE_SHARED, __uuidof(IDWriteFactory),
                            reinterpret_cast<IUnknown**>(&m_dwFactory));
        if (m_dwFactory) {
            m_dwFactory->CreateTextFormat(
                L"微软雅黑", nullptr,
                DWRITE_FONT_WEIGHT_NORMAL, DWRITE_FONT_STYLE_NORMAL,
                DWRITE_FONT_STRETCH_NORMAL, 24.0f, L"zh-CN", &m_textFormat);
        }
        if (m_textFormat)
            m_textFormat->SetParagraphAlignment(DWRITE_PARAGRAPH_ALIGNMENT_CENTER);

        // 切换按钮（运行时创建，本章不搞资源脚本）
        m_btn.Create(_T("切换 GDI+ / Direct2D（或按空格）"),
                     WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                     CRect(12, 12, 320, 44), this, IDC_TOGGLE);
        m_btn.SendMessage(WM_SETFONT,
                          (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);
        return 0;
    }

    afx_msg BOOL OnEraseBkgnd(CDC*) {
        return TRUE;    // 背景并入绘制函数（同第 18 章双缓冲纪律）
    }

    afx_msg void OnPaint() {
        CPaintDC dc(this);
        CRect rc;
        GetClientRect(&rc);
        if (rc.IsRectEmpty())
            return;
        if (m_useD2D)
            DrawWithD2D();
        else
            DrawWithGdiplus(dc, rc);
    }

    // D2D 渲染目标绑定的是像素尺寸 —— 窗口变了要 Resize
    afx_msg void OnSize(UINT nType, int cx, int cy) {
        CFrameWnd::OnSize(nType, cx, cy);
        if (m_rt && cx > 0 && cy > 0)
            m_rt->Resize(D2D1::SizeU(static_cast<UINT32>(cx),
                                     static_cast<UINT32>(cy)));
    }

    afx_msg void OnToggle() {
        m_useD2D = !m_useD2D;
        Invalidate(FALSE);
    }

    afx_msg void OnKeyDown(UINT nChar, UINT nRepCnt, UINT nFlags) {
        if (nChar == VK_SPACE)
            OnToggle();
        CFrameWnd::OnKeyDown(nChar, nRepCnt, nFlags);
    }

    DECLARE_MESSAGE_MAP()

private:
    // ---------- GDI+ 路线 ----------
    void DrawWithGdiplus(CDC& dc, const CRect& rc) {
        Gdiplus::Graphics g(dc.GetSafeHdc());
        g.SetSmoothingMode(Gdiplus::SmoothingModeAntiAlias);
        g.SetTextRenderingHint(Gdiplus::TextRenderingHintAntiAlias);

        // 线性渐变背景（GDI 做不到的第二件事：平滑过渡）
        Gdiplus::LinearGradientBrush bg(
            Gdiplus::Rect(0, 0, rc.Width(), rc.Height()),
            Gdiplus::Color(255, 30, 60, 120),
            Gdiplus::Color(255, 120, 200, 255), 90.0f);
        g.FillRectangle(&bg, 0, 0, rc.Width(), rc.Height());

        // 半透明高光（alpha 通道：80/255 的白，GDI 完全画不出来）
        Gdiplus::SolidBrush glow(Gdiplus::Color(80, 255, 255, 255));
        g.FillEllipse(&glow, rc.Width() * 0.15f, rc.Height() * 0.2f,
                      rc.Width() * 0.7f, rc.Height() * 0.35f);

        // 抗锯齿描边圆
        Gdiplus::Pen pen(Gdiplus::Color(255, 255, 255), 3.0f);
        g.DrawEllipse(&pen, rc.Width() * 0.3f, rc.Height() * 0.35f,
                      rc.Width() * 0.4f, rc.Height() * 0.4f);

        Gdiplus::Font font(L"微软雅黑", 18.0f);
        Gdiplus::SolidBrush white(Gdiplus::Color(255, 255, 255));
        g.DrawString(L"GDI+：抗锯齿 + 渐变 + 半透明", -1, &font,
                     Gdiplus::PointF(20.0f, static_cast<Gdiplus::REAL>(rc.Height() - 60)), &white);
    }

    // ---------- D2D 路线 ----------
    void EnsureRenderTarget() {
        if (m_rt)
            return;
        if (!m_d2dFactory)
            return;
        CRect rc;
        GetClientRect(&rc);
        const HRESULT hr = m_d2dFactory->CreateHwndRenderTarget(
            D2D1::RenderTargetProperties(),
            D2D1::HwndRenderTargetProperties(
                m_hWnd, D2D1::SizeU(static_cast<UINT32>(rc.Width()),
                                    static_cast<UINT32>(rc.Height()))),
            &m_rt);
        if (SUCCEEDED(hr) && m_textFormat)
            m_textFormat->SetReadingDirection(DWRITE_READING_DIRECTION_LEFT_TO_RIGHT);
    }

    void ReleaseD2D() {
        if (m_rt) { m_rt->Release(); m_rt = nullptr; }
    }

    void DrawWithD2D() {
        EnsureRenderTarget();
        if (!m_rt)
            return;

        CRect rc;
        GetClientRect(&rc);
        const float w = static_cast<float>(rc.Width());
        const float h = static_cast<float>(rc.Height());

        m_rt->BeginDraw();
        m_rt->Clear(D2D1::ColorF(0x1A1A2E));

        // 半透明填充圆（D2D 颜色第 4 位就是 alpha）
        ID2D1SolidColorBrush* brush = nullptr;
        m_rt->CreateSolidColorBrush(D2D1::ColorF(D2D1::ColorF::White), &brush);
        if (brush) {
            brush->SetColor(D2D1::ColorF(0.16f, 0.47f, 1.0f, 0.9f));
            m_rt->FillEllipse(D2D1::Ellipse(D2D1::Point2F(w * 0.5f, h * 0.55f),
                                            w * 0.22f, w * 0.22f), brush);
            brush->SetColor(D2D1::ColorF(0.0f, 0.9f, 0.6f, 0.6f));
            m_rt->DrawEllipse(D2D1::Ellipse(D2D1::Point2F(w * 0.5f, h * 0.55f),
                                            w * 0.28f, w * 0.28f), brush, 4.0f,
                              nullptr);

            // 文字走 DirectWrite
            if (m_textFormat) {
                brush->SetColor(D2D1::ColorF(D2D1::ColorF::White));
                D2D1_RECT_F layout = D2D1::RectF(20, h - 80, w - 20, h - 20);
                m_rt->DrawText(L"Direct2D：GPU 加速 + DirectWrite 文字",
                               static_cast<UINT32>(wcslen(
                                   L"Direct2D：GPU 加速 + DirectWrite 文字")),
                               m_textFormat, layout, brush);
            }
            brush->Release();
        }

        const HRESULT hr = m_rt->EndDraw();
        // 设备丢失（切显示器/休眠恢复/驱动重置）：下帧重建渲染目标
        if (hr == D2DERR_RECREATE_TARGET)
            ReleaseD2D();
    }

    CButton               m_btn;             // 子窗口由框架销毁，值成员即可
    ID2D1Factory*         m_d2dFactory = nullptr;
    ID2D1HwndRenderTarget* m_rt = nullptr;
    IDWriteFactory*       m_dwFactory = nullptr;
    IDWriteTextFormat*    m_textFormat = nullptr;
    bool                  m_useD2D = true;
};

BEGIN_MESSAGE_MAP(CDrawFrame, CFrameWnd)
    ON_WM_CREATE()
    ON_WM_PAINT()
    ON_WM_ERASEBKGND()
    ON_WM_SIZE()
    ON_WM_KEYDOWN()
    ON_BN_CLICKED(IDC_TOGGLE, &CDrawFrame::OnToggle)
END_MESSAGE_MAP()

// ---------- 应用：GdiplusStartup/Shutdown 配对 ----------
class CDrawApp : public CWinApp {
public:
    BOOL InitInstance() override {
        // 必须在任何 GDI+ 对象（Graphics/Font/Brush）出生前调用
        Gdiplus::GdiplusStartupInput gsi;
        Gdiplus::GdiplusStartup(&m_gdiplusToken, &gsi, NULL);

        auto* pFrame = new CDrawFrame;
        m_pMainWnd = pFrame;
        pFrame->Create(nullptr, _T("现代绘图：GDI+ 与 Direct2D"));
        pFrame->ShowWindow(m_nCmdShow);
        pFrame->UpdateWindow();
        return TRUE;
    }

    int ExitInstance() override {
        // 与 Startup 配对；窗口（及其 D2D 接口）已经销毁
        Gdiplus::GdiplusShutdown(m_gdiplusToken);
        return CWinApp::ExitInstance();
    }

private:
    ULONG_PTR m_gdiplusToken = 0;
};

CDrawApp theApp;
