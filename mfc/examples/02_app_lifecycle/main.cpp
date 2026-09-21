// 02_app_lifecycle —— 把 CWinApp 的回调时序可视化
//
// 窗口客户区里是一个只读编辑框，程序运行过程中每经过一个生命周期节点
// 就往里追加一行。退出阶段窗口已经销毁，所以同一份日志同时写进 exe 同
// 目录的 lifecycle.log —— 关闭窗口后打开那个文件，能看到完整的时序。

#include "resource.h"
#include <afxwin.h>

class CMainFrame;

static CMainFrame* g_pFrame  = nullptr;
static CString     g_logPath;

void AppendLog(LPCTSTR text);   // 前向声明，供下面的类成员调用

// ---------------------------------------------------------------------------
// 主窗口：一个框架窗口 + 一个填满客户区的只读编辑框
// ---------------------------------------------------------------------------
class CMainFrame : public CFrameWnd {
public:
    CMainFrame() {
        g_pFrame = this;                       // 让 AppendLog 能同步到编辑框
        AppendLog(_T("4. CMainFrame 构造函数（Create 之前）"));
        Create(NULL, _T("MFC 应用骨架时序 —— 关闭窗口后看 lifecycle.log"),
               WS_OVERLAPPEDWINDOW, CRect(120, 120, 780, 580));
    }

    // 把一行追加到编辑框末尾并滚动到底
    void AppendToEdit(LPCTSTR line) {
        if (!::IsWindow(m_edit.GetSafeHwnd())) return;
        int len = m_edit.GetWindowTextLength();
        m_edit.SetSel(len, len);
        m_edit.ReplaceSel(line);
    }

    afx_msg int  OnCreate(LPCREATESTRUCT cs);
    afx_msg void OnSize(UINT nType, int cx, int cy);
    afx_msg void OnClose();
    afx_msg void OnDestroy();

    DECLARE_MESSAGE_MAP()

private:
    CEdit m_edit;
};

// ---------------------------------------------------------------------------
// 日志：一行写文件 + 一行进编辑框
// ---------------------------------------------------------------------------
void AppendLog(LPCTSTR text)
{
    SYSTEMTIME st;
    ::GetLocalTime(&st);

    CString line;
    line.Format(_T("[%02d:%02d:%02d.%03d] %s\r\n"),
                st.wHour, st.wMinute, st.wSecond, st.wMilliseconds, text);

    CStdioFile f;
    if (f.Open(g_logPath,
               CFile::modeCreate | CFile::modeNoTruncate | CFile::modeWrite | CFile::typeText))
    {
        f.SeekToEnd();
        f.WriteString(line);
        f.Close();
    }

    if (g_pFrame) g_pFrame->AppendToEdit(line);
}

// ---------------------------------------------------------------------------
// CMainFrame 实现
// ---------------------------------------------------------------------------
BEGIN_MESSAGE_MAP(CMainFrame, CFrameWnd)
    ON_WM_CREATE()
    ON_WM_SIZE()
    ON_WM_CLOSE()
    ON_WM_DESTROY()
END_MESSAGE_MAP()

int CMainFrame::OnCreate(LPCREATESTRUCT cs)
{
    if (CFrameWnd::OnCreate(cs) == -1) return -1;

    // 子控件在 OnCreate 里创建：此时父窗口已存在，但还没显示
    m_edit.Create(WS_CHILD | WS_VISIBLE | WS_VSCROLL | ES_MULTILINE |
                      ES_READONLY | ES_AUTOVSCROLL,
                  CRect(0, 0, 0, 0), this, IDC_LOG);

    AppendLog(_T("5. CMainFrame::OnCreate —— 窗口已建，子控件在这里创建"));
    return 0;
}

void CMainFrame::OnSize(UINT nType, int cx, int cy)
{
    CFrameWnd::OnSize(nType, cx, cy);
    // 最小化时 cx/cy 为 0，必须提前返回，否则控件被压成 0 尺寸
    if (nType == SIZE_MINIMIZED || !::IsWindow(m_edit.GetSafeHwnd())) return;
    m_edit.MoveWindow(0, 0, cx, cy);
}

void CMainFrame::OnClose()
{
    AppendLog(_T("8. WM_CLOSE —— 用户点了关闭，框架将调 DestroyWindow"));
    CFrameWnd::OnClose();
}

void CMainFrame::OnDestroy()
{
    AppendLog(_T("9. WM_DESTROY —— 窗口正在销毁，CFrameWnd 随后 PostQuitMessage"));
    CFrameWnd::OnDestroy();   // 主窗口走到这里会发 WM_QUIT，消息循环随之退出
}

// ---------------------------------------------------------------------------
// 应用对象
// ---------------------------------------------------------------------------
class CLifecycleApp : public CWinApp {
public:
    CLifecycleApp() {
        // 日志文件放在 exe 同目录，每次启动清空
        TCHAR exePath[MAX_PATH] = { 0 };
        ::GetModuleFileName(NULL, exePath, MAX_PATH);
        g_logPath = exePath;
        int slash = g_logPath.ReverseFind(_T('\\'));
        if (slash >= 0) g_logPath = g_logPath.Left(slash + 1);
        g_logPath += _T("lifecycle.log");
        ::DeleteFile(g_logPath);

        AppendLog(_T("1. CLifecycleApp 构造函数 —— 全局对象，在 main 之前"));
    }

    BOOL InitApplication() override {
        BOOL ok = CWinApp::InitApplication();
        AppendLog(_T("2. InitApplication() —— 注册窗口类等全局资源，每个程序一次"));
        return ok;
    }

    BOOL InitInstance() override {
        AppendLog(_T("3. InitInstance() 进入 —— 唯一必须重写的函数"));
        if (!CWinApp::InitInstance()) return FALSE;

        g_pFrame = new CMainFrame();
        if (!g_pFrame->GetSafeHwnd()) {          // Create 失败
            delete g_pFrame;
            g_pFrame = nullptr;
            return FALSE;
        }
        m_pMainWnd = g_pFrame;

        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        AppendLog(_T("6. InitInstance() 返回 TRUE —— 马上进入消息循环 Run()"));
        return TRUE;
    }

    BOOL OnIdle(LONG lCount) override {
        if (lCount == 0 && !m_idleLogged) {
            m_idleLogged = true;
            AppendLog(_T("7. OnIdle(0) —— 消息队列空了；界面刷新、状态栏更新都在这个时机"));
        }
        return CWinApp::OnIdle(lCount);
    }

    int ExitInstance() override {
        AppendLog(_T("10. ExitInstance() —— Run() 已返回，消息循环结束"));
        int rc = CWinApp::ExitInstance();
        AppendLog(_T("11. ExitInstance() 返回，主窗口对象由框架负责销毁"));
        return rc;
    }

    ~CLifecycleApp() override {
        AppendLog(_T("12. ~CLifecycleApp() —— 全局对象析构，进程即将结束"));
    }

private:
    bool m_idleLogged = false;
};

CLifecycleApp theApp;
