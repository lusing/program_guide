// 08_toolbar_statusbar：工具栏 + 状态栏 + 命令 UI 更新。
//
// 演示：
//   1. CToolBar 的组装：CreateEx -> SetButtons -> 图标位图 -> SetButtonText
//      （图标用内存绘制的彩色块代替 .bmp 资源，重点在流程不在美术）
//   2. CStatusBar：自定义窗格 + 文本更新
//   3. ON_UPDATE_COMMAND_UI：菜单和工具栏状态（可用/禁用）统一由
//      一处代码维护 —— 这是 MFC 命令架构最省心的特性
//
// 编译运行：.\build.ps1 -File 08_toolbar_statusbar

#include "resource.h"
#include <afxwin.h>
#include <afxext.h>    // CToolBar / CStatusBar
#include <afxcmn.h>    // CToolBarCtrl
#include <afxdlgs.h>

class CEditorWnd : public CFrameWnd {
public:
    CEditorWnd() {
        Create(NULL, _T("工具栏与状态栏演示"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 720, 480), nullptr,
               MAKEINTRESOURCE(IDR_MAIN_MENU));
    }

    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        if (CFrameWnd::OnCreate(lpCreateStruct) == -1)
            return -1;

        CreateToolbar();
        CreateStatusBar();

        m_edit.Create(WS_CHILD | WS_VISIBLE | WS_VSCROLL | ES_MULTILINE |
                          ES_AUTOVSCROLL | ES_WANTRETURN,
                      CRect(0, 0, 0, 0), this, IDC_EDIT);
        m_edit.SendMessage(WM_SETFONT,
                           (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);
        return 0;
    }

    afx_msg void OnSize(UINT nType, int cx, int cy) {
        CFrameWnd::OnSize(nType, cx, cy);
        if (!m_edit.GetSafeHwnd())
            return;
        // RepositionBars(…, reposQuery) 先让工具栏/状态栏占好位置，
        // 返回的 rect 是剩余给普通子控件的客户区
        CRect rect;
        RepositionBars(AFX_IDW_CONTROLBAR_FIRST, AFX_IDW_CONTROLBAR_LAST,
                       0, reposQuery, &rect);
        m_edit.MoveWindow(rect);
    }

    afx_msg void OnFileOpen() {
        CFileDialog dlg(TRUE, _T("txt"), nullptr, OFN_FILEMUSTEXIST,
                        _T("文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*||"), this);
        if (dlg.DoModal() != IDOK)
            return;
        m_filePath = dlg.GetFileName();
        m_statusBar.SetPaneText(m_statusBar.CommandToIndex(ID_INDICATOR_FILE),
                                m_filePath);
        m_edit.SetWindowText(_T(""));
        Invalidate();
    }

    afx_msg void OnFileSave() {
        MessageBox(_T("保存成功"), _T("Demo"));
    }

    afx_msg void OnFileExit() { PostMessage(WM_CLOSE); }

    afx_msg void OnFmtColor() {
        CColorDialog dlg;
        dlg.DoModal();
    }

    // ---- 命令 UI 更新：框架在空闲时调用，统一决定菜单/按钮的可用状态 ----
    afx_msg void OnUpdateFileSave(CCmdUI* pCmdUI) {
        pCmdUI->Enable(!m_filePath.IsEmpty());  // 没打开文件就禁用保存
    }

    DECLARE_MESSAGE_MAP()

private:
    void CreateToolbar() {
        if (!m_toolbar.CreateEx(this, TBSTYLE_FLAT,
                                WS_CHILD | WS_VISIBLE | CBRS_TOP |
                                    CBRS_TOOLTIPS | CBRS_FLYBY))
            return;
        // SetButtons 按数组建立按钮，ID_SEPARATOR 生成竖直分隔条
        if (!m_toolbar.SetButtons(m_toolbarIds, _countof(m_toolbarIds)))
            return;

        // 图标：16x15 是传统工具栏图标尺寸。真实项目里用 LoadBitmap 加载
        // .bmp 资源；这里在内存里画彩色块代替，重点在流程。
        CDC screenDc;
        screenDc.CreateCompatibleDC(nullptr);
        m_toolbarBmp.CreateCompatibleBitmap(&screenDc, 48, 15);  // 3 格
        CDC memDc;
        memDc.CreateCompatibleDC(nullptr);
        CBitmap* oldBmp = memDc.SelectObject(&m_toolbarBmp);
        memDc.FillSolidRect(0, 0, 48, 15, RGB(0, 128, 128));
        memDc.FillSolidRect(3, 3, 10, 9, RGB(255, 255, 255));    // 打开
        memDc.FillSolidRect(19, 3, 10, 9, RGB(30, 30, 200));     // 保存
        CBrush brush(RGB(200, 30, 30));
        memDc.SelectObject(&brush);
        memDc.Ellipse(34, 2, 46, 14);                            // 颜色
        memDc.SelectObject(oldBmp);
        m_toolbar.GetToolBarCtrl().AddBitmap(3, &m_toolbarBmp);

        // 文字标签：按钮下方的文本（SetSizes 前调用）
        m_toolbar.SetButtonText(0, _T("打开"));
        m_toolbar.SetButtonText(1, _T("保存"));
        m_toolbar.SetButtonText(3, _T("颜色"));  // 2 是分隔条
        m_toolbar.SetSizes(CSize(54, 42), CSize(16, 15));
    }

    void CreateStatusBar() {
        // 第一个 ID_SEPARATOR 是弹性主窗格；其余按此数组顺序排列
        static UINT indicators[] = {
            ID_SEPARATOR,
            ID_INDICATOR_FILE,
            ID_INDICATOR_POS,
        };
        m_statusBar.Create(this);
        m_statusBar.SetIndicators(indicators, _countof(indicators));
        m_statusBar.SetPaneText(m_statusBar.CommandToIndex(ID_INDICATOR_FILE),
                                _T("未打开文件"));
    }

    // 在内存里画一个 3 格位图当工具栏图标（真实项目里用 .bmp 或 PNG 资源）
    enum { IDC_EDIT = 101 };

    // 工具栏按钮布局：打开 | 保存 | 分隔 | 颜色
    static const UINT m_toolbarIds[4];

    CEdit m_edit;
    CToolBar m_toolbar;
    CStatusBar m_statusBar;
    CBitmap m_toolbarBmp;   // 位图必须活得比 AddBitmap 后的第一次绘制久
    CString m_filePath;
};

const UINT CEditorWnd::m_toolbarIds[] = {
    IDM_FILE_OPEN, IDM_FILE_SAVE, ID_SEPARATOR, IDM_FMT_COLOR
};

BEGIN_MESSAGE_MAP(CEditorWnd, CFrameWnd)
    ON_WM_CREATE()
    ON_WM_SIZE()
    ON_COMMAND(IDM_FILE_OPEN, OnFileOpen)
    ON_COMMAND(IDM_FILE_SAVE, OnFileSave)
    ON_COMMAND(IDM_FMT_COLOR, OnFmtColor)
    ON_COMMAND(IDM_FILE_EXIT, OnFileExit)
    ON_UPDATE_COMMAND_UI(IDM_FILE_SAVE, OnUpdateFileSave)
END_MESSAGE_MAP()

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CEditorWnd();
        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
