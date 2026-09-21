// 04_frame_layout：框架窗口与子窗口布局。
//
// 要点：
//   1. OnCreate 里创建子控件（此时窗口框架已建好、尚未显示）
//   2. WM_SIZE 里做自适应布局 —— 拉伸窗口时子控件跟随
//   3. 控件用 new 分配 + 子窗口身份，MFC 在窗口销毁时自动 delete 子控件
//
// 这是所有“手工布局”的 MFC 程序的基本套路，理解它可以看懂任何
// 用向导生成的 MFC 工程里的 CMainFrame。
//
// 编译运行：.\build.ps1 -File 04_frame_layout

#include <afxwin.h>

class CLayoutWnd : public CFrameWnd {
public:
    CLayoutWnd() {
        Create(NULL, _T("窗口布局演示（试着拉伸窗口）"),
               WS_OVERLAPPEDWINDOW, CRect(100, 100, 760, 500));
    }

    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        if (CFrameWnd::OnCreate(lpCreateStruct) == -1)
            return -1;  // 基类失败则终止窗口创建

        // 顶部输入区
        m_edit.Create(WS_CHILD | WS_VISIBLE | WS_BORDER | ES_AUTOHSCROLL,
                      CRect(0, 0, 0, 0), this, IDC_INPUT);
        SetGuiFont(m_edit);

        // 中部日志区（多行只读）
        m_log.Create(WS_CHILD | WS_VISIBLE | WS_BORDER | WS_VSCROLL |
                         ES_MULTILINE | ES_AUTOVSCROLL | ES_READONLY,
                     CRect(0, 0, 0, 0), this, IDC_LOG);
        SetGuiFont(m_log);

        // 底部按钮
        m_btn.Create(_T("添加日志"), WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                     CRect(0, 0, 0, 0), this, IDC_ADD);
        SetGuiFont(m_btn);

        Log(_T("窗口已创建。每行日志对应一次按钮点击。"));

        // 注意：这里返回 0 表示继续创建；返回 -1 会销毁窗口
        return 0;
    }

    // 拉伸窗口时重新布置子控件 —— 手工布局的核心
    afx_msg void OnSize(UINT nType, int cx, int cy) {
        CFrameWnd::OnSize(nType, cx, cy);
        if (m_edit.GetSafeHwnd() == nullptr)
            return;  // OnCreate 之前也可能收到 WM_SIZE，控件还没建

        const int margin = 12;
        const int editH = 28, btnW = 100, btnH = 30, gap = 8;

        int y = margin;
        m_edit.MoveWindow(margin, y, cx - 2 * margin, editH);
        y += editH + gap;

        int logBottom = cy - margin - btnH;
        m_log.MoveWindow(margin, y, cx - 2 * margin, logBottom - y);

        m_btn.MoveWindow(cx - margin - btnW, cy - margin - btnH, btnW, btnH);
    }

    afx_msg void OnClickedAdd() {
        CString input;
        m_edit.GetWindowText(input);
        if (input.IsEmpty()) {
            MessageBox(_T("先在上面输入点内容"), _T("提示"), MB_ICONWARNING);
            m_edit.SetFocus();
            return;
        }
        Log(input);
        m_edit.SetWindowText(_T(""));
        m_edit.SetFocus();
    }

    DECLARE_MESSAGE_MAP()

private:
    // 控件默认字体很老（System 字体），换成系统 GUI 字体更美观
    static void SetGuiFont(CWnd& wnd) {
        wnd.SendMessage(WM_SETFONT,
                        (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);
    }

    void Log(const CString& line) {
        // 获取多行编辑框已有内容，追加一行
        CString text;
        m_log.GetWindowText(text);
        if (!text.IsEmpty())
            text += _T("\r\n");
        CTime now = CTime::GetCurrentTime();
        text += now.Format(_T("[%H:%M:%S] ")) + line;
        m_log.SetWindowText(text);
        m_log.LineScroll(m_log.GetLineCount());  // 滚到最底部
    }

    enum { IDC_INPUT = 101, IDC_LOG = 102, IDC_ADD = 103 };

    CEdit m_edit;
    CEdit m_log;
    CButton m_btn;
};

BEGIN_MESSAGE_MAP(CLayoutWnd, CFrameWnd)
    ON_WM_CREATE()
    ON_WM_SIZE()
    ON_BN_CLICKED(IDC_ADD, OnClickedAdd)
END_MESSAGE_MAP()

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CLayoutWnd();
        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
