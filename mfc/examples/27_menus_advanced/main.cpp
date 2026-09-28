// 27_menus_advanced：菜单深入 —— 运行时才发生的一切。
//
// 书1 第6 章的例14-21 + 书2 实例11（位图菜单）的现代版：
//   1. 复选/单选/禁用：ON_UPDATE_COMMAND_UI 三板斧（例15/16/17）
//   2. 动态构造整张弹出菜单：CMenu 临时栈对象 + CreatePopupMenu（例18/21）
//   3. 上下文菜单：客户区右键，TrackPopupMenu（例21）
//   4. 系统菜单：GetSystemMenu 追加“关于”，WM_SYSCOMMAND 拦截（例19）
//   5. owner-draw 颜色菜单：MF_OWNERDRAW + WM_MEASUREITEM/WM_DRAWITEM
//      —— 书2 实例11 位图菜单同一条路线，只是画的内容不同
//
// 编译运行：.\build.ps1 -File 27_menus_advanced

#include "resource.h"
#include <afxwin.h>
#include <afxext.h>     // CToolBar / CStatusBar

// owner-draw 项的自定义数据：菜单系统回调时原样奉还 dwItemData
struct OdColorItem {
    COLORREF clr;
    wchar_t  label[32];
};

// 本示例的颜色色板（动态段与 owner-draw 段共用）
static const COLORREF kSwatch[] = {
    RGB(200, 60, 55), RGB(230, 145, 55), RGB(220, 200, 60), RGB(70, 150, 90),
    RGB(60, 105, 190), RGB(140, 80, 160)
};

class CMenuLabWnd : public CFrameWnd {
public:
    CMenuLabWnd() {
        Create(nullptr, _T("第 27 章 · 菜单深入"), WS_OVERLAPPEDWINDOW,
               CRect(90, 90, 860, 560), nullptr, MAKEINTRESOURCE(IDR_MAIN_MENU));
        LoadAccelTable(MAKEINTRESOURCE(IDR_MAIN_MENU));
    }

    afx_msg int OnCreate(LPCREATESTRUCT) {
        // —— 状态栏：给“复选”实验一个真实对象 ——
        if (!m_wndStatus.Create(this))
            return -1;
        UINT inds[] = { ID_SEPARATOR, ID_SEPARATOR };
        m_wndStatus.SetIndicators(inds, 2);
        m_wndStatus.SetPaneText(1, _T("右键客户区试上下文菜单"));

        // —— 工具栏：没有位图资源，用文本按钮手工搭（第 11 章的 LoadToolBar 路线见彼章）——
        if (!m_wndBar.CreateEx(this, TBSTYLE_FLAT,
                               WS_CHILD | WS_VISIBLE | CBRS_ALIGN_TOP |
                               CBRS_TOOLTIPS | CBRS_FLYBY | CBRS_SIZE_DYNAMIC))
            return -1;
        UINT btns[] = { IDM_TEST_DYNAMIC, ID_SEPARATOR, IDM_VIEW_STATUS, IDM_VIEW_TOOL,
                        ID_SEPARATOR, IDM_COLOR_RED, IDM_COLOR_GREEN, IDM_COLOR_BLUE };
        m_wndBar.SetButtons(btns, _countof(btns));
        m_wndBar.SetButtonText(0, _T("动态菜单"));
        m_wndBar.SetButtonText(2, _T("状态栏"));
        m_wndBar.SetButtonText(3, _T("工具栏"));
        m_wndBar.SetButtonText(5, _T("红"));
        m_wndBar.SetButtonText(6, _T("绿"));
        m_wndBar.SetButtonText(7, _T("蓝"));
        // 文本按钮的尺寸：宽 = 文本 + 余量，高统一
        CSize sz(0, 0);
        CDC* pDC = GetDC();
        for (int i = 0; i < m_wndBar.GetCount(); i++) {
            CString t;
            m_wndBar.GetButtonText(i, t);
            if (!t.IsEmpty())
                sz.cx = max(sz.cx, pDC->GetTextExtent(t).cx);
        }
        ReleaseDC(pDC);
        sz.cx = max(sz.cx + 14, 44);
        sz.cy = pDC ? 24 : 24;
        m_wndBar.SetSizes(sz, CSize(16, 15));
        return 0;
    }

    // ============ 1. 复选 / 单选 ============

    void OnViewStatus() { ToggleBar(m_showStatus, &m_wndStatus); }
    void OnViewTool()   { ToggleBar(m_showTool, &m_wndBar); }
    void ToggleBar(bool& flag, CControlBar* pBar) {
        flag = !flag;
        pBar->ShowWindow(flag ? SW_SHOW : SW_HIDE);
        RecalcLayout(TRUE);     // 控制条显隐后重排客户区，框架白送
    }

    void OnUpdateViewStatus(CCmdUI* p) { p->SetCheck(m_showStatus); }
    void OnUpdateViewTool(CCmdUI* p)   { p->SetCheck(m_showTool); }

    void OnColor(UINT id) {
        m_color = ColorOfCommand(id);
        Invalidate();
    }
    void OnUpdateColor(CCmdUI* p) {
        p->SetRadio(ColorOfCommand(p->m_nID) == m_color);
        p->Enable(TRUE);
    }

    static COLORREF ColorOfCommand(UINT id) {
        switch (id) {
        case IDM_COLOR_RED:   return RGB(200, 60, 55);
        case IDM_COLOR_GREEN: return RGB(70, 150, 90);
        case IDM_COLOR_BLUE:  return RGB(60, 105, 190);
        }
        return RGB(60, 60, 60);
    }

    // ============ 2. 动态构造弹出菜单 ============

    void OnTestDynamic() {
        CMenu popup;
        if (!popup.CreatePopupMenu())
            return;
        // 全 API 化构造：AppendMenu / CheckMenuItem / EnableMenuItem / 默认项
        for (int i = 0; i < IDM_DYN_LAST - IDM_DYN_FIRST + 1; i++) {
            CString text;
            text.Format(_T("动态项 %d"), i + 1);
            popup.AppendMenu(MF_STRING, IDM_DYN_FIRST + i, text);
        }
        popup.CheckMenuItem(IDM_DYN_FIRST, MF_BYCOMMAND | MF_CHECKED);
        popup.EnableMenuItem(IDM_DYN_FIRST + 1, MF_BYCOMMAND | MF_GRAYED);
        ::SetMenuDefaultItem(popup.GetSafeHmenu(), IDM_DYN_FIRST + 2, TRUE);

        // owner-draw 颜色段：dwItemData 挂自备结构，菜单回调时奉还
        popup.AppendMenu(MF_SEPARATOR);
        for (int i = 0; i < _countof(kSwatch); i++) {
            OdColorItem* od = new OdColorItem{ kSwatch[i] };
            swprintf_s(od->label, _T("颜色 %02X%02X%02X"),
                       GetRValue(kSwatch[i]), GetGValue(kSwatch[i]), GetBValue(kSwatch[i]));
            m_odItems.Add(od);    // 生命周期挂窗口：取消/选中都不泄漏
            popup.AppendMenu(MF_OWNERDRAW, ODM_COLOR_FIRST + i, (LPCTSTR)od);
        }

        CPoint pt;
        GetCursorPos(&pt);
        int cmd = popup.TrackPopupMenu(TPM_RIGHTBUTTON | TPM_RETURNCMD | TPM_NONOTIFY,
                                       pt.x, pt.y, this);
        DispatchPopupCommand(cmd);
    }

    // ============ 3. 上下文菜单（右键客户区） ============

    afx_msg void OnContextMenu(CWnd*, CPoint pt) {
        CMenu popup;
        popup.CreatePopupMenu();
        popup.AppendMenu(MF_STRING | (m_showStatus ? MF_CHECKED : 0),
                         IDM_VIEW_STATUS, _T("切换状态栏"));
        popup.AppendMenu(MF_STRING, IDM_VIEW_TOOL, _T("切换工具栏"));
        popup.AppendMenu(MF_SEPARATOR);
        popup.AppendMenu(MF_STRING, IDM_COLOR_RED, _T("变红"));
        popup.AppendMenu(MF_STRING, IDM_COLOR_GREEN, _T("变绿"));
        popup.AppendMenu(MF_STRING, IDM_COLOR_BLUE, _T("变蓝"));
        int cmd = popup.TrackPopupMenu(TPM_RIGHTBUTTON | TPM_RETURNCMD, pt.x, pt.y, this);
        if (cmd)
            PostMessage(WM_COMMAND, cmd);   // 借主菜单的路由：一处逻辑两处入口
    }

    // ============ 4. 系统菜单 ============

    void OnTestSysCmd() {
        CMenu* pSys = GetSystemMenu(FALSE);   // FALSE = 取现有菜单（TRUE 是重置成默认）
        if (!pSys)
            return;
        if (pSys->GetMenuState(IDM_SYS_ABOUT, MF_BYCOMMAND) == (UINT)-1) {
            pSys->AppendMenu(MF_SEPARATOR);
            pSys->AppendMenu(MF_STRING, IDM_SYS_ABOUT, _T("关于菜单实验(&A)..."));
        }
        m_wndStatus.SetPaneText(1, _T("点标题栏左上角图标试试（WM_SYSCOMMAND）"));
    }

    afx_msg void OnSysCommand(UINT id, LPARAM) {
        // 系统菜单命令走 WM_SYSCOMMAND，不进 WM_COMMAND 路由，得在这接。
        // 系统用低 4 位做内部标记，比较前必须 & 0xFFF0（SDK 文档明文规定）
        if ((id & 0xFFF0) == IDM_SYS_ABOUT) {
            MessageBox(_T("系统菜单项触发。\r\n注意 id 低 4 位由系统使用，比较前要 & 0xFFF0。"),
                       _T("关于"), MB_OK | MB_ICONINFORMATION);
            return;
        }
        CFrameWnd::OnSysCommand(id, 0);
    }

    // ============ 5. 命令段回调 / owner-draw 绘制 ============

    void OnDynRange(UINT id) {
        CString msg;
        msg.Format(_T("动态菜单命令 #%lu（ON_COMMAND_RANGE 一网打尽）"),
                   (unsigned long)(id - IDM_DYN_FIRST + 1));
        m_wndStatus.SetPaneText(1, msg);
    }

    void OnOdColor(UINT id) {
        m_color = kSwatch[id - ODM_COLOR_FIRST];
        Invalidate();
    }

    void DispatchPopupCommand(int cmd) {
        if (cmd == 0)
            return;                          // 用户取消
        if (cmd >= IDM_DYN_FIRST && cmd <= IDM_DYN_LAST)
            OnDynRange(cmd);
        else if (cmd >= ODM_COLOR_FIRST && cmd <= ODM_COLOR_LAST)
            OnOdColor(cmd);
    }

    afx_msg void OnMeasureItem(int nIDCtl, LPMEASUREITEMSTRUCT pm) {
        if (nIDCtl != 0 || !pm || pm->CtlType != ODT_MENU)
            return;                          // 只管菜单的 owner-draw
        OdColorItem* od = reinterpret_cast<OdColorItem*>(pm->itemData);
        CDC* pDC = GetDC();
        CSize sz = pDC->GetTextExtent(od->label, (int)wcslen(od->label));
        ReleaseDC(pDC);
        pm->itemWidth = sz.cx + 48;          // 色块 24 + 间距 + 文本 + 余量
        pm->itemHeight = max(sz.cy + 6, 22);
    }

    afx_msg void OnDrawItem(int nIDCtl, LPDRAWITEMSTRUCT pd) {
        if (nIDCtl != 0 || !pd || pd->CtlType != ODT_MENU)
            return;
        CDC dc;
        dc.Attach(pd->hDC);
        CRect rc = pd->rcItem;
        OdColorItem* od = reinterpret_cast<OdColorItem*>(pd->itemData);

        bool selected = (pd->itemState & ODS_SELECTED) != 0;
        dc.FillSolidRect(rc, GetSysColor(selected ? COLOR_HIGHLIGHT : COLOR_MENU));
        // 色块
        CRect sw = rc;
        sw.left += 8; sw.top += 4; sw.bottom -= 4; sw.right = sw.left + 24;
        CBrush brush(od->clr);
        CPen pen(PS_SOLID, 1, RGB(60, 60, 60));
        auto ob = dc.SelectObject(&brush);
        auto op = dc.SelectObject(&pen);
        dc.Rectangle(sw);
        dc.SelectObject(ob);
        dc.SelectObject(op);
        // 文本
        dc.SetBkMode(TRANSPARENT);
        dc.SetTextColor(GetSysColor(selected ? COLOR_HIGHLIGHTTEXT : COLOR_MENUTEXT));
        dc.TextOut(rc.left + 40, rc.top + (rc.Height() - dc.GetTextExtent(od->label).cy) / 2,
                   od->label);
        dc.Detach();
    }

    afx_msg void OnPaint() {
        CPaintDC dc(this);
        CRect rc;
        GetClientRect(rc);
        rc.top += 64;                        // 给工具栏留地
        rc.bottom -= 24;                     // 给状态栏留地
        CBrush brush(m_color);
        auto old = dc.SelectObject(&brush);
        dc.Rectangle(rc);
        dc.SelectObject(old);
        dc.SetBkMode(TRANSPARENT);
        dc.SetTextColor(RGB(255, 255, 255));
        dc.TextOut(rc.left + 20, rc.top + 20,
                   _T("菜单实验：右键 / Ctrl+D 动态菜单 / Ctrl+S 系统菜单"));
    }

    afx_msg void OnExit() { PostMessage(WM_CLOSE); }

    BOOL DestroyWindow() override {
        for (INT_PTR i = 0; i < m_odItems.GetSize(); i++)
            delete (OdColorItem*)m_odItems[(int)i];
        m_odItems.RemoveAll();
        return CFrameWnd::DestroyWindow();
    }

    DECLARE_MESSAGE_MAP()

private:
    CStatusBar m_wndStatus;
    CToolBar  m_wndBar;
    CPtrArray  m_odItems;
    bool m_showStatus = true;
    bool m_showTool = true;
    COLORREF m_color = RGB(60, 105, 190);
};

BEGIN_MESSAGE_MAP(CMenuLabWnd, CFrameWnd)
    ON_WM_CREATE()
    ON_WM_CONTEXTMENU()
    ON_WM_SYSCOMMAND()
    ON_WM_MEASUREITEM()
    ON_WM_DRAWITEM()
    ON_WM_PAINT()
    ON_COMMAND(IDM_FILE_EXIT, OnExit)
    ON_COMMAND(IDM_TEST_DYNAMIC, OnTestDynamic)
    ON_COMMAND(IDM_TEST_SYSCMD, OnTestSysCmd)
    ON_COMMAND_RANGE(IDM_DYN_FIRST, IDM_DYN_LAST, OnDynRange)
    ON_COMMAND_RANGE(ODM_COLOR_FIRST, ODM_COLOR_LAST, OnOdColor)
    ON_COMMAND(IDM_VIEW_STATUS, OnViewStatus)
    ON_COMMAND(IDM_VIEW_TOOL, OnViewTool)
    ON_UPDATE_COMMAND_UI(IDM_VIEW_STATUS, OnUpdateViewStatus)
    ON_UPDATE_COMMAND_UI(IDM_VIEW_TOOL, OnUpdateViewTool)
    ON_COMMAND_RANGE(IDM_COLOR_RED, IDM_COLOR_BLUE, OnColor)
    ON_UPDATE_COMMAND_UI_RANGE(IDM_COLOR_RED, IDM_COLOR_BLUE, OnUpdateColor)
END_MESSAGE_MAP()

class CMenuApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CMenuLabWnd();
        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMenuApp theApp;
