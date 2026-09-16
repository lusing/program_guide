// 10_gdi：GDI 绘图与双缓冲。
//
// 演示：
//   1. OnPaint + CPaintDC 的标准绘图流程
//   2. CPen / CBrush / CFont 的创建与选入 DC（SelectObject 配对归还）
//   3. 鼠标拖动画线（WM_LBUTTONDOWN / WM_MOUSEMOVE / WM_LBUTTONUP）
//   4. 双缓冲：先画到内存 DC，再一次性拷到屏幕 —— 消除闪烁
//   5. OnEraseBkgnd 返回 TRUE，把擦除时机也收进双缓冲
//
// 编译运行：.\build.ps1 -File 10_gdi

#include <afxwin.h>
#include <vector>

// 一条笔画 = 鼠标从按下到抬起经过的点集
struct Stroke {
    COLORREF color;
    std::vector<CPoint> points;
};

class CDrawingWnd : public CFrameWnd {
public:
    CDrawingWnd() {
        Create(NULL, _T("GDI 画板（左键拖动画线，C 键清空）"),
               WS_OVERLAPPEDWINDOW, CRect(100, 100, 760, 520));
    }

    // 标准 WM_PAINT 流程
    afx_msg void OnPaint() {
        CPaintDC screenDc(this);
        CRect rect;
        GetClientRect(&rect);

        // ---- 双缓冲第一步：在内存位图上画 ----
        CDC memDc;
        memDc.CreateCompatibleDC(&screenDc);

        CBitmap buffer;
        buffer.CreateCompatibleBitmap(&screenDc, rect.Width(), rect.Height());
        CBitmap* oldBmp = memDc.SelectObject(&buffer);

        DrawScene(&memDc, rect);

        // ---- 第二步：整块拷到屏幕 ----
        screenDc.BitBlt(0, 0, rect.Width(), rect.Height(), &memDc, 0, 0,
                        SRCCOPY);
        memDc.SelectObject(oldBmp);
    }  // buffer、memDc 析构时自动释放，无需手工 DeleteObject

    // 背景擦除也走双缓冲，否则内存里画完又被白底擦一下，闪一下
    afx_msg BOOL OnEraseBkgnd(CDC* /*pDC*/) {
        return TRUE;  // 告诉框架：我自己处理了（在 DrawScene 里填背景）
    }

    // ---- 鼠标交互 ----
    afx_msg void OnLButtonDown(UINT nFlags, CPoint point) {
        SetCapture();  // 拖出窗口也能继续收 MOUSEMOVE
        m_drawing = true;
        Stroke s;
        s.color = m_colors[m_colorIndex % 3];
        s.points.push_back(point);
        m_strokes.push_back(std::move(s));
    }

    afx_msg void OnMouseMove(UINT nFlags, CPoint point) {
        if (!m_drawing)
            return;
        if ((nFlags & MK_LBUTTON) == 0) {  // 按键中途松开
            EndStroke();
            return;
        }
        m_strokes.back().points.push_back(point);
        Invalidate(FALSE);  // FALSE：不擦背景，避免闪
    }

    afx_msg void OnLButtonUp(UINT nFlags, CPoint point) {
        if (m_drawing)
            EndStroke();
    }

    afx_msg void OnChar(UINT nChar, UINT, UINT) {
        if (nChar == _T('c') || nChar == _T('C')) {
            m_strokes.clear();
            Invalidate();
        }
    }

    // 右键：切换下一支画笔颜色
    afx_msg void OnRButtonDown(UINT nFlags, CPoint point) {
        ++m_colorIndex;
        CString title;
        title.Format(_T("GDI 画板（当前颜色 #%d）"), m_colorIndex % 3 + 1);
        SetWindowText(title);
    }

    DECLARE_MESSAGE_MAP()

private:
    void EndStroke() {
        ReleaseCapture();
        m_drawing = false;
        Invalidate(FALSE);
    }

    // 场景绘制：内存 DC 上完成全部绘制，含背景
    void DrawScene(CDC* dc, const CRect& rect) {
        // 背景：白纸 + 顶部说明条
        dc->FillSolidRect(rect, RGB(255, 255, 255));
        dc->FillSolidRect(0, 0, rect.Width(), 36, RGB(45, 45, 48));

        CFont font;
        font.CreatePointFont(90, _T("微软雅黑"));
        CFont* oldFont = dc->SelectObject(&font);
        dc->SetTextColor(RGB(240, 240, 240));
        dc->SetBkMode(TRANSPARENT);
        dc->TextOutW(10, 8, _T("左键拖动画线 | C 键清空"));
        dc->SelectObject(oldFont);

        // 示例图形：画笔 + 画刷的标准用法
        {
            CPen pen(PS_SOLID, 2, RGB(70, 130, 180));
            CBrush brush(RGB(70, 130, 180));
            dc->SelectObject(&pen);
            dc->SelectObject(&brush);
            dc->Ellipse(rect.right - 60, 46, rect.right - 20, 86);  // 右上角圆点
        }

        // 用户笔画
        CPen* oldPen = dc->GetCurrentPen();

        for (const auto& s : m_strokes) {
            if (s.points.size() < 2)
                continue;
            CPen strokePen(PS_SOLID, 3, s.color);
            dc->SelectObject(&strokePen);
            dc->MoveTo(s.points[0]);
            for (size_t i = 1; i < s.points.size(); ++i)
                dc->LineTo(s.points[i]);
        }
        dc->SelectObject(oldPen);
    }

    enum { COLOR_RED = 0, COLOR_GREEN = 1, COLOR_BLUE = 2 };
    COLORREF m_colors[3] = { RGB(200, 40, 40), RGB(30, 140, 60),
                             RGB(40, 80, 200) };
    int m_colorIndex = 0;

    std::vector<Stroke> m_strokes;
    bool m_drawing = false;
};

BEGIN_MESSAGE_MAP(CDrawingWnd, CFrameWnd)
    ON_WM_PAINT()
    ON_WM_ERASEBKGND()
    ON_WM_LBUTTONDOWN()
    ON_WM_MOUSEMOVE()
    ON_WM_LBUTTONUP()
    ON_WM_RBUTTONDOWN()
    ON_WM_CHAR()
END_MESSAGE_MAP()

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CDrawingWnd();
        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
