// 28_control_bars：控制条家族 —— CDialogBar、CReBar、停靠体系。
//
// 书2 第2 章是全书的总纲（控制条），本示例对应其实例 10（对话条加菜单栏）/14（对话框控制条）：
//   1. CDialogBar：对话框模板做的控制条 —— 组合框/复选框/编辑框全都能塞
//   2. 控件的 WM_COMMAND 直接路由到框架：对话条是 CCmdTarget 链的一环
//   3. CReBar：把工具栏、对话条当作“带条”（band）编组，可拖的现代化停靠容器
//   4. EnableDocking / DockControlBar / FloatControlBar：经典停靠三件套（书2 2.4 节）
//   5. 状态栏自定义窗格：命令提示 + 选中内容回显
//
// 编译运行：.\build.ps1 -File 28_control_bars

#include "resource.h"
#include <afxwin.h>
#include <afxext.h>    // CDialogBar / CToolBar / CStatusBar / CReBar（afxext 拉齐控制条家族）

class CBarLabWnd : public CFrameWnd {
public:
    CBarLabWnd() {
        Create(nullptr, _T("第 28 章 · 控制条与停靠"), WS_OVERLAPPEDWINDOW,
               CRect(80, 80, 900, 580), nullptr, MAKEINTRESOURCE(IDR_MAIN_MENU));
    }

    afx_msg int OnCreate(LPCREATESTRUCT) {
        EnableDocking(CBRS_ALIGN_ANY);    // 框架先声明：四边都能停

        // —— ReBar：现代化容器，工具栏/对话条都以 band 身份挂进来 ——
        // 注意 Create 无标题参数：CReBar::Create(parent, 控件样式, 窗口样式, ID)
        if (!m_rebar.Create(this, RBS_BANDBORDERS,
                            WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS |
                            WS_CLIPCHILDREN | CBRS_TOP | CBRS_ALIGN_ANY))
            return -1;
        m_rebar.EnableDocking(CBRS_ALIGN_ANY);

        // —— 工具栏：放第一 band（文本按钮，无位图依赖）——
        if (!m_toolbar.CreateEx(this, TBSTYLE_FLAT,
                                WS_CHILD | WS_VISIBLE | CBRS_SIZE_DYNAMIC))
            return -1;
        UINT btns[] = { IDM_BAR_TOGGLE_DLG, IDM_BAR_FLOAT_DLG, IDM_BAR_TOGGLE_REBAR };
        m_toolbar.SetButtons(btns, _countof(btns));
        m_toolbar.SetButtonText(0, _T("对话条 开/关"));
        m_toolbar.SetButtonText(1, _T("浮动"));
        m_toolbar.SetButtonText(2, _T("ReBar 开/关"));
        CDC* pDC = GetDC();
        int w = 0;
        for (int i = 0; i < m_toolbar.GetCount(); i++) {
            CString t;
            m_toolbar.GetButtonText(i, t);
            w = max(w, pDC->GetTextExtent(t).cx);
        }
        ReleaseDC(pDC);
        m_toolbar.SetSizes(CSize(w + 16, 26), CSize(16, 15));

        m_rebar.AddBar(&m_toolbar, _T("命令"));
        m_toolbar.SetBarStyle(m_toolbar.GetBarStyle() |
                              CBRS_TOOLTIPS | CBRS_FLYBY | CBRS_SIZE_DYNAMIC);

        // —— 对话条：第二 band，模板 IDD_DIALOGBAR ——
        if (!m_dialogBar.Create(this, IDD_DIALOGBAR, CBRS_ALIGN_TOP | CBRS_ALIGN_BOTTOM,
                                IDD_DIALOGBAR))
            return -1;
        // 造好内容：组合框预填几项（对话条不自动做 DDX，内容自己管）
        CComboBox* pCombo = (CComboBox*)m_dialogBar.GetDlgItem(IDC_DB_COMBO);
        if (pCombo) {
            pCombo->AddString(_T("红色"));
            pCombo->AddString(_T("绿色"));
            pCombo->AddString(_T("蓝色"));
            pCombo->SetCurSel(0);
        }
        m_dialogBar.EnableDocking(CBRS_ALIGN_ANY);
        m_rebar.AddBar(&m_dialogBar, _T("属性"));    // 对话条作为 band 进 ReBar

        // ReBar 自己停到顶边（内部 bar 都归它管，不再单独 DockControlBar）
        DockControlBar(&m_rebar);

        // —— 状态栏：两格 —— 提示 + 当前选择
        if (!m_status.Create(this))
            return -1;
        UINT inds[] = { ID_SEPARATOR, ID_SEPARATOR };
        m_status.SetIndicators(inds, 2);
        m_status.SetPaneInfo(1, ID_SEPARATOR, SBPS_NORMAL, 200);
        m_status.SetPaneText(1, _T("（在对话条上选点什么）"));
        return 0;
    }

    // ============ 对话条控件 -> 框架：WM_COMMAND 直达 ============

    // 组合框选择：对话条控件的命令和菜单命令走同一条路由
    afx_msg void OnDbComboChange() {
        CComboBox* pCombo = (CComboBox*)m_dialogBar.GetDlgItem(IDC_DB_COMBO);
        if (!pCombo) return;
        CString sel;
        pCombo->GetLBText(pCombo->GetCurSel(), sel);
        m_color = ColorOf(sel);
        m_status.SetPaneText(1, _T("组合框选择：") + sel);
        Invalidate();
    }

    afx_msg void OnDbCheck() {
        m_bold = !m_bold;
        CString s = m_bold ? _T("复选框：粗体开") : _T("复选框：粗体关");
        m_status.SetPaneText(1, s);
        Invalidate();
    }

    afx_msg void OnDbButton() {
        CEdit* pEdit = (CEdit*)m_dialogBar.GetDlgItem(IDC_DB_EDIT);
        CString text;
        if (pEdit) pEdit->GetWindowText(text);
        if (text.IsEmpty()) text = _T("（空）");
        m_status.SetPaneText(1, _T("应用：") + text);
        m_note = text;
        Invalidate();
    }

    // EN_CHANGE：每敲一键都来 —— 内容型通知与命令型通知的区别
    afx_msg void OnDbEditChange() {
        CEdit* pEdit = (CEdit*)m_dialogBar.GetDlgItem(IDC_DB_EDIT);
        CString text;
        if (pEdit) pEdit->GetWindowText(text);
        m_status.SetPaneText(0, text.IsEmpty() ? _T("就绪") : _T("正在输入..."));
    }

    // ============ 停靠三件套 ============

    afx_msg void OnToggleDialogBar() {
        ShowControlBar(&m_dialogBar, !(m_dialogBar.GetStyle() & WS_VISIBLE), FALSE);
    }

    afx_msg void OnFloatDialogBar() {
        // FloatControlBar：把条拽出主框架，放在指定屏幕位置
        CPoint pt;
        GetCursorPos(&pt);
        FloatControlBar(&m_dialogBar, pt, CBRS_ALIGN_TOP);
    }

    afx_msg void OnToggleRebar() {
        ShowControlBar(&m_rebar, !(m_rebar.GetStyle() & WS_VISIBLE), FALSE);
    }

    afx_msg void OnUpdateToggleDlg(CCmdUI* p) {
        p->SetCheck((m_dialogBar.GetStyle() & WS_VISIBLE) != 0);
    }
    afx_msg void OnUpdateToggleRebar(CCmdUI* p) {
        p->SetCheck((m_rebar.GetStyle() & WS_VISIBLE) != 0);
    }

    afx_msg void OnPaint() {
        CPaintDC dc(this);
        CRect rc;
        GetClientRect(rc);
        rc.top += 76;
        rc.bottom -= 24;
        CFont font;
        font.CreatePointFont(m_bold ? 2400 : 1200, _T("Microsoft YaHei"));
        auto old = dc.SelectObject(&font);
        dc.FillSolidRect(rc, m_color);
        dc.SetBkMode(TRANSPARENT);
        dc.SetTextColor(RGB(255, 255, 255));
        dc.TextOut(rc.left + 24, rc.top + 24, _T("客户区：对话条的选择落在这里"));
        if (!m_note.IsEmpty())
            dc.TextOut(rc.left + 24, rc.top + 72, _T("应用过：") + m_note);
        dc.SelectObject(old);
    }

    afx_msg void OnExit() { PostMessage(WM_CLOSE); }

    DECLARE_MESSAGE_MAP()

    static COLORREF ColorOf(const CString& s) {
        if (s == _T("红色")) return RGB(178, 55, 50);
        if (s == _T("绿色")) return RGB(62, 132, 80);
        return RGB(53, 92, 167);
    }

private:
    CReBar      m_rebar;
    CToolBar    m_toolbar;
    CDialogBar  m_dialogBar;
    CStatusBar  m_status;
    COLORREF    m_color = RGB(53, 92, 167);
    bool        m_bold = false;
    CString     m_note;
};

BEGIN_MESSAGE_MAP(CBarLabWnd, CFrameWnd)
    ON_WM_CREATE()
    ON_WM_PAINT()
    ON_COMMAND(IDM_FILE_EXIT, OnExit)
    ON_CBN_SELCHANGE(IDC_DB_COMBO, OnDbComboChange)
    ON_BN_CLICKED(IDC_DB_CHECK, OnDbCheck)
    ON_BN_CLICKED(IDC_DB_BUTTON, OnDbButton)
    ON_EN_CHANGE(IDC_DB_EDIT, OnDbEditChange)
    ON_COMMAND(IDM_BAR_TOGGLE_DLG, OnToggleDialogBar)
    ON_COMMAND(IDM_BAR_FLOAT_DLG, OnFloatDialogBar)
    ON_COMMAND(IDM_BAR_TOGGLE_REBAR, OnToggleRebar)
    ON_UPDATE_COMMAND_UI(IDM_BAR_TOGGLE_DLG, OnUpdateToggleDlg)
    ON_UPDATE_COMMAND_UI(IDM_BAR_TOGGLE_REBAR, OnUpdateToggleRebar)
END_MESSAGE_MAP()

class CBarApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CBarLabWnd();
        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CBarApp theApp;
