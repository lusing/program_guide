// 03_resources：使用 .rc 资源文件创建菜单、加速键和字符串表。
//
// 真实的 MFC 工程（VS 向导生成的）几乎都把菜单、对话框、图标放在 .rc
// 资源里，而不是代码里手工拼。本章演示资源如何进入 exe：
//
//   resource.h  --(被 .cpp 和 .rc 共同包含)--> 两边用同一套 ID
//   demo.rc     --rc.exe--> demo.res       --link--> 嵌进 exe
//
// 编译运行：.\build.ps1 -File 03_resources

#include "resource.h"
#include <afxwin.h>

class CMainWindow : public CFrameWnd {
public:
    CMainWindow() {
        // 第 6 个参数是菜单资源名：Create 会把它挂到窗口上
        Create(NULL, LoadText(IDS_APP_TITLE), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 680, 440), nullptr,
               MAKEINTRESOURCE(IDR_MAIN_MENU));
    }

    afx_msg void OnPaint() {
        CPaintDC dc(this);
        CRect rect;
        GetClientRect(&rect);
        rect.DeflateRect(24, 24);
        dc.SetBkMode(TRANSPARENT);
        dc.DrawText(LoadText(IDS_GREETING), -1, rect, DT_LEFT | DT_WORDBREAK);
    }

    // ---- 菜单命令处理：命令 ID -> 处理函数 ----
    afx_msg void OnFileNew()  { MessageBox(_T("命令：新建"), _T("Demo")); }
    afx_msg void OnFileOpen() { MessageBox(_T("命令：打开"), _T("Demo")); }
    afx_msg void OnFileSave() { MessageBox(_T("命令：保存"), _T("Demo")); }
    afx_msg void OnEditUndo() { MessageBox(_T("命令：撤销"), _T("Demo")); }
    afx_msg void OnFileExit() { PostMessage(WM_CLOSE); }
    afx_msg void OnHelpAbout() {
        MessageBox(_T("MFC 资源示例 1.0\n菜单 + 加速键 + 字符串表"),
                   _T("关于"), MB_OK | MB_ICONINFORMATION);
    }

    DECLARE_MESSAGE_MAP()

private:
    static CString LoadText(UINT id) {
        CString s;
        s.LoadString(id);
        return s;
    }
};

BEGIN_MESSAGE_MAP(CMainWindow, CFrameWnd)
    ON_WM_PAINT()
    ON_COMMAND(IDM_FILE_NEW, OnFileNew)
    ON_COMMAND(IDM_FILE_OPEN, OnFileOpen)
    ON_COMMAND(IDM_FILE_SAVE, OnFileSave)
    ON_COMMAND(IDM_EDIT_UNDO, OnEditUndo)
    ON_COMMAND(IDM_HELP_ABOUT, OnHelpAbout)
    ON_COMMAND(IDM_FILE_EXIT, OnFileExit)
END_MESSAGE_MAP()

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CMainWindow();
        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();

        // 加载加速键表，让 Ctrl+N 等组合键生效
        m_accel = ::LoadAccelerators(AfxGetInstanceHandle(),
                                     MAKEINTRESOURCE(IDR_MAIN_ACCEL));
        return TRUE;
    }

    // 把键盘消息交给加速键表翻译；翻译成命令就不再往下传
    BOOL PreTranslateMessage(MSG* pMsg) override {
        if (m_accel && m_pMainWnd &&
            ::TranslateAccelerator(m_pMainWnd->GetSafeHwnd(),
                                   m_accel, pMsg)) {
            return TRUE;
        }
        return CWinApp::PreTranslateMessage(pMsg);
    }

private:
    HACCEL m_accel = nullptr;
};

CMyApp theApp;
