#include <afxwin.h>

class CMainWindow : public CFrameWnd {
public:
    CMainWindow() {
        Create(NULL, _T("MFC Hello"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 540, 360));
    }
};

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CMainWindow();
        m_pMainWnd->ShowWindow(SW_SHOW);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
