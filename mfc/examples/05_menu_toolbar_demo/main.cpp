#include <afxwin.h>
#include <afxext.h>

#define IDM_FILE_NEW  1001
#define IDM_FILE_OPEN 1002
#define IDM_FILE_SAVE 1003
#define IDM_FILE_EXIT 1004

class CMenuToolbarWnd : public CFrameWnd {
public:
    CMenuToolbarWnd() {
        Create(NULL, _T("Menu and Toolbar Demo"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 720, 500));
    }

    int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        CFrameWnd::OnCreate(lpCreateStruct);

        CMenu menu;
        menu.CreateMenu();
        menu.AppendMenu(MF_STRING, IDM_FILE_NEW, _T("新建(&N)"));
        menu.AppendMenu(MF_STRING, IDM_FILE_OPEN, _T("打开(&O)"));
        menu.AppendMenu(MF_STRING, IDM_FILE_SAVE, _T("保存(&S)"));
        menu.AppendMenu(MF_SEPARATOR);
        menu.AppendMenu(MF_STRING, IDM_FILE_EXIT, _T("退出(&X)"));
        SetMenu(&menu);

        if (!m_toolbar.CreateEx(this, TBSTYLE_FLAT, WS_CHILD | WS_VISIBLE | CBRS_TOP | CBRS_TOOLTIPS,
                                CRect(0, 0, 0, 0), 0x9999)) {
            return -1;
        }

        UINT buttons[] = { IDM_FILE_NEW, IDM_FILE_OPEN, IDM_FILE_SAVE, IDM_FILE_EXIT };
        m_toolbar.SetButtons(buttons, _countof(buttons));
        m_toolbar.EnableWindow(TRUE);
        return 0;
    }

    afx_msg void OnFileNew() { AfxMessageBox(_T("新建命令")); }
    afx_msg void OnFileOpen() { AfxMessageBox(_T("打开命令")); }
    afx_msg void OnFileSave() { AfxMessageBox(_T("保存命令")); }
    afx_msg void OnFileExit() { PostMessage(WM_CLOSE); }

    DECLARE_MESSAGE_MAP()

private:
    CToolBar m_toolbar;
};

BEGIN_MESSAGE_MAP(CMenuToolbarWnd, CFrameWnd)
    ON_WM_CREATE()
    ON_COMMAND(IDM_FILE_NEW, OnFileNew)
    ON_COMMAND(IDM_FILE_OPEN, OnFileOpen)
    ON_COMMAND(IDM_FILE_SAVE, OnFileSave)
    ON_COMMAND(IDM_FILE_EXIT, OnFileExit)
END_MESSAGE_MAP()

class CMenuToolbarApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CMenuToolbarWnd();
        m_pMainWnd->ShowWindow(SW_SHOW);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMenuToolbarApp theApp;
