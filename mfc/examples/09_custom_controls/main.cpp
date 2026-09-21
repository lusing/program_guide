// 09_custom_controls：四条自绘 / 定制路线。
//
//   1. Owner-draw 按钮   —— BS_OWNERDRAW + DrawItem，控件把画布全交给你
//   2. Custom draw 列表  —— NM_CUSTOMDRAW，控件自己画，你只改属性（斑马纹）
//   3. 完全自绘控件      —— CWnd 派生 + 自己注册窗口类 + OnPaint 画仪表盘
//   4. 子类化            —— SetWindowSubclass 给现成编辑框加"只收数字"行为
//
// 编译运行：.\build.ps1 -File 09_custom_controls

#include "resource.h"
#include <afxwin.h>
#include <afxcmn.h>   // 公共控件 + commctrl.h（SetWindowSubclass 在这里）
#include <cmath>
#include <tchar.h>

static const double kPi = 3.14159265358979323846;

// ------------------------------------------------- 1) Owner-draw 按钮

class COwnerDrawButton : public CButton {
public:
    // 控件收到 WM_DRAWITEM 后，MFC 会路由到这里。
    // dis 里装齐了"画什么、画在哪、当前什么状态"。
    void DrawItem(LPDRAWITEMSTRUCT dis) override {
        CDC* pDC = CDC::FromHandle(dis->hDC);   // 把 HDC 包成 CDC 好调 MFC 接口
        CRect rc(dis->rcItem);

        const bool pressed = (dis->itemState & ODS_SELECTED) != 0;
        const bool focused = (dis->itemState & ODS_FOCUS) != 0;
        const bool disabled = (dis->itemState & ODS_DISABLED) != 0;

        // 三种状态三种配色：按下时底色变深、文字下移一格
        COLORREF face = disabled ? RGB(230, 230, 230)
                                 : (pressed ? RGB(60, 120, 200) : RGB(90, 155, 235));
        COLORREF text = disabled ? RGB(150, 150, 150) : RGB(255, 255, 255);

        pDC->FillSolidRect(rc, face);
        pDC->Draw3dRect(rc, RGB(255, 255, 255), RGB(40, 80, 140));

        CString caption;
        GetWindowText(caption);
        pDC->SetBkMode(TRANSPARENT);
        pDC->SetTextColor(text);
        if (pressed)
            rc.OffsetRect(1, 1);   // 按下时文字下沉，做出"被按进去"的错觉
        pDC->DrawText(caption, rc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);

        // 键盘用户看不到鼠标位置，焦点框必须自己画 —— 漏了这条，
        // 用 Tab 键切换到这个按钮时界面上完全没有提示。
        if (focused) {
            CRect f = rc;
            f.DeflateRect(3, 3);
            pDC->DrawFocusRect(f);
        }
    }
};

// ------------------------------------------------- 2) 自绘控件：仪表盘

class CGaugeCtrl : public CWnd {
public:
    BOOL Create(CWnd* parent, UINT id, const CRect& rc) {
        // 自己注册一个窗口类：类样式决定"尺寸变了要不要重画"（CS_HREDRAW|CS_VREDRAW），
        // 背景刷给 NULL_BRUSH —— 背景我们自己涂，系统别插手。
        LPCTSTR cls = AfxRegisterWndClass(
            CS_HREDRAW | CS_VREDRAW,
            ::LoadCursor(NULL, IDC_ARROW),
            (HBRUSH)::GetStockObject(NULL_BRUSH));
        return CWnd::Create(cls, NULL, WS_CHILD | WS_VISIBLE, rc, parent, id);
    }

    void SetValue(int percent) {
        percent = max(0, min(100, percent));
        if (percent == m_percent)
            return;
        m_percent = percent;
        Invalidate();   // 标脏，等系统发 WM_PAINT；不要在这里直接画
    }

    int GetValue() const { return m_percent; }

    // 绘制逻辑抽成一个纯函数式的 Draw(CDC&, CRect)：不依赖成员状态以外的东西，
    // 将来想画到内存 DC / 打印机上都直接复用。
    void Draw(CDC& dc, const CRect& rc) {
        dc.FillSolidRect(rc, RGB(248, 250, 252));

        CRect box = rc;
        box.DeflateRect(10, 10);
        // 取正方形，让半圆是正圆的一半
        int side = min(box.Width(), box.Height() * 2);
        int left = box.left + (box.Width() - side) / 2;
        int top  = box.top;
        CRect circle(left, top, left + side, top + side);

        const int cx = circle.CenterPoint().x;
        const int cy = circle.bottom;              // 圆心在半圆底边中点
        const int r  = side / 2;

        // 底色半圆：从左侧 (left, cy) 画到右侧 (right, cy)
        CPen penBack(PS_SOLID, 10, RGB(210, 216, 224));
        CPen* pOldPen = dc.SelectObject(&penBack);
        dc.Arc(circle.left, circle.top, circle.right, circle.bottom,
               circle.left, cy, circle.right, cy);

        // 数值对应的指针角度：0% → 180°，100% → 0°
        double ang = kPi * (1.0 - m_percent / 100.0);
        int nx = cx + static_cast<int>(r * std::cos(ang));
        int ny = cy - static_cast<int>(r * std::sin(ang));

        // 已达成部分：用一段彩色弧盖在底色上
        CPen penValue(PS_SOLID, 10, m_percent >= 80 ? RGB(220, 70, 70)
                                                    : RGB(70, 160, 90));
        dc.SelectObject(&penValue);
        int vx = cx - r, vy = cy;   // 起点：最左
        dc.Arc(circle.left, circle.top, circle.right, circle.bottom,
               vx, vy, nx, ny);

        // 指针
        CPen penNeedle(PS_SOLID, 2, RGB(40, 44, 52));
        dc.SelectObject(&penNeedle);
        dc.MoveTo(cx, cy);
        dc.LineTo(nx, ny);
        dc.SelectObject(pOldPen);

        // 圆心轴 + 百分比文字
        CBrush brush(RGB(40, 44, 52));
        CBrush* pOldBrush = dc.SelectObject(&brush);
        dc.Ellipse(cx - 5, cy - 5, cx + 5, cy + 5);
        dc.SelectObject(pOldBrush);

        CString s;
        s.Format(_T("%d%%"), m_percent);
        dc.SetBkMode(TRANSPARENT);
        dc.SetTextColor(RGB(40, 44, 52));
        CRect textRc(cx - 40, cy + 4, cx + 40, cy + 24);
        dc.DrawText(s, textRc, DT_CENTER | DT_SINGLELINE);
    }

    afx_msg void OnPaint() {
        CPaintDC dc(this);
        CRect rc;
        GetClientRect(&rc);
        Draw(dc, rc);
    }

    // 返回 TRUE = "背景我已经处理了，系统别再擦一遍"。
    // 不写这个，每帧都会先用背景刷清一遍再画，闪得厉害。
    afx_msg BOOL OnEraseBkgnd(CDC*) { return TRUE; }

    DECLARE_MESSAGE_MAP()

private:
    int m_percent = 0;
};

BEGIN_MESSAGE_MAP(CGaugeCtrl, CWnd)
    ON_WM_PAINT()
    ON_WM_ERASEBKGND()
END_MESSAGE_MAP()

// ------------------------------------------------- 4) 子类化：只收数字的编辑框

static LRESULT CALLBACK NumEditProc(HWND hWnd, UINT msg, WPARAM wParam,
                                    LPARAM lParam, UINT_PTR /*uIdSubclass*/,
                                    DWORD_PTR /*dwRefData*/) {
    if (msg == WM_CHAR) {
        // 只放行数字和退格；其余一律吃掉（返回 0 表示"已处理，别再往下传"）
        if (!_istdigit(static_cast<TCHAR>(wParam)) && wParam != VK_BACK)
            return 0;
    }
    // 其余消息必须交给 DefSubclassProc 往下传，否则控件等于废了
    return DefSubclassProc(hWnd, msg, wParam, lParam);
}

// ------------------------------------------------- 主对话框

class CCustomDlg : public CDialog {
public:
    CCustomDlg() : CDialog(IDD_MAIN) {}

    // 模板里的控件必须和 C++ 对象"挂上钩"，成员方法才操作得到真实控件。
    // DDX_Control 就是干这个的：它在 DoModal 过程中把控件子类化成我们的对象。
    void DoDataExchange(CDataExchange* pDX) override {
        CDialog::DoDataExchange(pDX);
        DDX_Control(pDX, IDC_OWNERDRAW_BTN, m_btn);   // 绑上后 WM_DRAWITEM 才会走到 DrawItem
        DDX_Control(pDX, IDC_SLIDER, m_slider);
        DDX_Control(pDX, IDC_LIST, m_list);
        DDX_Control(pDX, IDC_NUMEDIT, m_edit);
    }

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();

        // ---- 自绘仪表盘：量出占位静态框的矩形，销毁它，原位换成自绘控件 ----
        CWnd* placeholder = GetDlgItem(IDC_GAUGE);
        CRect rc;
        placeholder->GetWindowRect(&rc);
        ScreenToClient(&rc);
        placeholder->DestroyWindow();
        m_gauge.Create(this, IDC_GAUGE, rc);
        m_gauge.SetValue(35);

        // ---- 滑块联动仪表盘 ----
        m_slider.SetRange(0, 100);
        m_slider.SetPos(35);

        // ---- 斑马纹列表 ----
        m_list.SetExtendedStyle(LVS_EX_FULLROWSELECT | LVS_EX_GRIDLINES);
        m_list.InsertColumn(0, _T("阶段"), LVCFMT_LEFT, 80);
        m_list.InsertColumn(1, _T("结果"), LVCFMT_LEFT, 60);
        for (int i = 0; i < 8; ++i) {
            CString stage;
            stage.Format(_T("第 %d 步"), i + 1);
            int row = m_list.InsertItem(i, stage);
            m_list.SetItemText(row, 1, (i % 3 == 0) ? _T("跳过") : _T("完成"));
        }

        // ---- 子类化编辑框：装上"只收数字"的过滤器 ----
        // SetWindowSubclass 是推荐做法：可以叠加多层，窗口销毁时自动摘钩。
        SetWindowSubclass(m_edit.GetSafeHwnd(), NumEditProc, 1, 0);

        m_edit.SetWindowText(_T("123"));
        return TRUE;
    }

    afx_msg void OnHScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar) {
        if (pScrollBar && pScrollBar->GetSafeHwnd() == m_slider.GetSafeHwnd())
            m_gauge.SetValue(m_slider.GetPos());
        CDialog::OnHScroll(nSBCode, nPos, pScrollBar);
    }

    // Custom draw：控件自己画，只在特定阶段插一脚改属性。
    // 关键是两阶段握手 —— PREPAINT 阶段返回 CDRF_NOTIFYITEMDRAW，
    // 控件才会在每一行要画之前再叫你一次（ITEMPPREPAINT）。
    afx_msg void OnCustomDraw(NMHDR* pNMHDR, LRESULT* pResult) {
        auto* pLVCD = reinterpret_cast<NMLVCUSTOMDRAW*>(pNMHDR);
        *pResult = CDRF_DODEFAULT;

        switch (pLVCD->nmcd.dwDrawStage) {
        case CDDS_PREPAINT:
            *pResult = CDRF_NOTIFYITEMDRAW;   // 声明：逐行画时还要叫我
            break;
        case CDDS_ITEMPREPAINT:
            // nmcd.dwItemSpec 在报表视图里就是行号
            if (pLVCD->nmcd.dwItemSpec % 2 == 1)
                pLVCD->clrTextBk = RGB(238, 245, 255);   // 斑马纹
            *pResult = CDRF_NEWFONT;   // 告诉控件：颜色我改了，按我的来
            break;
        default:
            break;
        }
    }

    DECLARE_MESSAGE_MAP()

private:
    COwnerDrawButton m_btn;
    CGaugeCtrl       m_gauge;
    CSliderCtrl      m_slider;
    CListCtrl        m_list;
    CEdit            m_edit;
};

BEGIN_MESSAGE_MAP(CCustomDlg, CDialog)
    ON_WM_HSCROLL()
    ON_NOTIFY(NM_CUSTOMDRAW, IDC_LIST, OnCustomDraw)
END_MESSAGE_MAP()

// ------------------------------------------------- 应用

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        CCustomDlg dlg;
        m_pMainWnd = &dlg;
        dlg.DoModal();
        return FALSE;
    }
};

CMyApp theApp;
