// 11_threads：后台线程与 UI 的配合。
//
// 规则：凡是可能超过 0.1 秒的计算都不要在 UI 线程里做——界面会卡死、
// 无法重绘、无法响应。正确做法是 worker 线程算数，PostMessage 回 UI 线程。
//
// 演示：
//   1. AfxBeginThread 创建 worker 线程（MFC 对 CreateThread 的封装）
//   2. 进度通过自定义消息回传（线程里绝不能直接摸 UI 控件）
//   3. std::atomic 取消标志：线程自己主动退出，绝不 TerminateThread
//   4. 线程对象 m_bAutoDelete 生命周期陷阱
//
// 任务：统计 [2, N] 里的素数个数（够慢，能看清进度条走动）。
//
// 编译运行：.\build.ps1 -File 11_threads

#include <afxwin.h>
#include <afxcmn.h>
#include <atomic>
#include <vector>

#define WM_APP_PROGRESS (WM_APP + 1)  // wParam=百分比
#define WM_APP_DONE     (WM_APP + 2)  // wParam=找到的素数个数, lParam=是否被取消

UINT CountPrimesThread(LPVOID pParam);  // 定义在 CThreadsWnd 之后

class CThreadsWnd : public CFrameWnd {
public:
    CThreadsWnd() {
        Create(NULL, _T("后台线程演示"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 660, 320));
    }

    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        if (CFrameWnd::OnCreate(lpCreateStruct) == -1)
            return -1;
        MakeFont(m_font);

        m_progress.Create(WS_CHILD | WS_VISIBLE | PBS_SMOOTH,
                          CRect(0, 0, 0, 0), this, IDC_PROGRESS);
        m_progress.SetRange(0, 100);

        m_status.Create(_T("就绪。N = 2,000,000"),
                        WS_CHILD | WS_VISIBLE | SS_LEFT,
                        CRect(0, 0, 0, 0), this, IDC_STATUS);
        m_status.SetFont(&m_font);

        m_btnStart.Create(_T("开始计算"), WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                          CRect(0, 0, 0, 0), this, IDC_START);
        m_btnStart.SetFont(&m_font);

        m_btnCancel.Create(_T("取消"), WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON |
                               WS_DISABLED,
                           CRect(0, 0, 0, 0), this, IDC_CANCEL);
        m_btnCancel.SetFont(&m_font);
        return 0;
    }

    afx_msg void OnSize(UINT nType, int cx, int cy) {
        CFrameWnd::OnSize(nType, cx, cy);
        if (!m_progress.GetSafeHwnd())
            return;

        const int m = 16, h = 28, gap = 10;
        int y = cy - m * 2 - h * 2 - gap;
        m_status.MoveWindow(m, y, cx - 2 * m, h);
        y += h + gap;
        m_progress.MoveWindow(m, y, cx - 2 * m, h);
        y += h + gap;
        m_btnStart.MoveWindow(m, y, 120, h);
        m_btnCancel.MoveWindow(m + 130, y, 120, h);
    }

    afx_msg void OnClickedStart() {
        if (m_thread)   // 已在计算中
            return;

        m_cancel = false;
        m_progress.SetPos(0);

        // 创建 worker 线程。m_bAutoDelete 默认 TRUE：
        // 线程函数返回后 MFC 自动 delete 这个 CWinThread 对象，
        // 所以我们存指针只为了判断“在跑”，绝不能手动 delete 它。
        m_thread = AfxBeginThread(CountPrimesThread, this);
        m_btnStart.EnableWindow(FALSE);
        m_btnCancel.EnableWindow(TRUE);
        m_status.SetWindowText(_T("计算中..."));
    }

    afx_msg void OnClickedCancel() {
        m_cancel = true;   // 只设标志，线程在安全点自己退出
    }

    // 关窗口时如果线程还在算：先等它退出，否则线程里残留的 this
    // 和 PostMessage 会踩进已销毁的窗口
    afx_msg void OnClose() {
        if (m_thread) {
            if (MessageBox(_T("还有计算在进行，取消并退出吗？"),
                           _T("确认"), MB_YESNO | MB_ICONQUESTION) != IDYES)
                return;
            m_cancel = true;
            WaitForSingleObject(m_doneEvent, INFINITE);
        }
        CFrameWnd::OnClose();
    }

    // ---- 以下两个函数跑在 UI 线程：可以放心操作所有控件 ----
    afx_msg LRESULT OnProgress(WPARAM wParam, LPARAM /*lParam*/) {
        m_progress.SetPos((int)wParam);
        return 0;
    }

    afx_msg LRESULT OnDone(WPARAM wParam, LPARAM lParam) {
        m_thread = nullptr;
        m_btnStart.EnableWindow(TRUE);
        m_btnCancel.EnableWindow(FALSE);

        CString msg;
        msg.Format(_T("%s共找到 %u 个素数"),
                   lParam ? _T("已取消。") : _T(""), wParam);
        m_status.SetWindowText(msg);
        return 0;
    }

    // worker 线程调用（由线程入口转发），全部是纯计算 + PostMessage
    UINT DoCount() {
        const UINT N = 2000000;
        UINT found = 0;
        std::vector<bool> composite(N + 1, false);

        for (UINT i = 2; i <= N; ++i) {
            if (m_cancel)   // 安全点检查取消标志
                break;

            if (!composite[i]) {
                ++found;
                for (UINT j = i * 2; j <= N; j += i)
                    composite[j] = true;
            }

            if (i % (N / 100) == 0)  // 每 1% 报一次进度
                PostMessage(WM_APP_PROGRESS, i * 100 / N);
        }

        PostMessage(WM_APP_DONE, found, m_cancel ? 1 : 0);
        SetEvent(m_doneEvent);  // 通知：线程真正要结束了（见 OnClose）
        return 0;   // 返回后 MFC 自动清理线程对象
    }

    DECLARE_MESSAGE_MAP()

private:
    static void MakeFont(CFont& font) {
        font.CreatePointFont(100, _T("微软雅黑"));
    }

    enum { IDC_PROGRESS = 401, IDC_STATUS = 402, IDC_START = 403,
           IDC_CANCEL = 404 };

    CProgressCtrl m_progress;
    CStatic m_status;
    CButton m_btnStart;
    CButton m_btnCancel;
    CFont m_font;

    CWinThread* m_thread = nullptr;
    std::atomic<bool> m_cancel{ false };  // 跨线程标志必须用 atomic
    HANDLE m_doneEvent = ::CreateEvent(nullptr, TRUE, FALSE, nullptr);
};

// worker 线程入口。签名固定：UINT (CALLBACK*)(LPVOID)
UINT CountPrimesThread(LPVOID pParam) {
    auto* self = static_cast<CThreadsWnd*>(pParam);
    return self->DoCount();
}

BEGIN_MESSAGE_MAP(CThreadsWnd, CFrameWnd)
    ON_WM_CREATE()
    ON_WM_SIZE()
    ON_WM_CLOSE()
    ON_BN_CLICKED(IDC_START, OnClickedStart)
    ON_BN_CLICKED(IDC_CANCEL, OnClickedCancel)
    ON_MESSAGE(WM_APP_PROGRESS, OnProgress)
    ON_MESSAGE(WM_APP_DONE, OnDone)
END_MESSAGE_MAP()

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CThreadsWnd();
        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
