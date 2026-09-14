#include <afxwin.h>

class CMyDialog : public CDialog {
public:
    enum { IDD = 1000 };

    explicit CMyDialog(UINT templateId = IDD) : CDialog(templateId) {}

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();
        SetWindowText(_T("MFC Dialog Demo"));
        return TRUE;
    }
};

class CMainWindow : public CFrameWnd {
public:
    CMainWindow() {
        Create(NULL, _T("MFC Dialog Demo"), WS_OVERLAPPEDWINDOW,
               CRect(150, 150, 620, 420));
    }

    afx_msg void OnFileOpen() {
        CMyDialog dialog;
        dialog.DoModal();
    }

    DECLARE_MESSAGE_MAP()
};

BEGIN_MESSAGE_MAP(CMainWindow, CFrameWnd)
    ON_COMMAND(ID_FILE_OPEN, OnFileOpen)
END_MESSAGE_MAP()

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
