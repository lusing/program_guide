// 32_ui_threads：UI 线程与线程间通信 —— 书2 第14 章 实例56-59。
//
//   1. CWinThread 派生 UI 线程：自己的 InitInstance/ExitInstance/消息循环，
//      还能建自己的窗口（书2 实例56“工作线程”与 57“用户界面线程”的分野）
//   2. 线程间消息：PostThreadMessage —— 对“线程”发而不是对“窗口”发（实例58）
//   3. 数据竞争：两个 worker 对同一计数各自加一万次，无锁必丢；CMutex+CSingleLock 修正（实例59）
//   4. 优先级：SetThreadPriority 的可见效果（短任务差异小，用计数放大）
//   5. 干净收摊：PostThreadMessage(WM_QUIT) + 等句柄，绝不 TerminateThread
//
// 编译运行：.\build.ps1 -File 32_ui_threads

#include "resource.h"
#include <afxwin.h>
#include <afxmt.h>     // CMutex / CSingleLock
#include <atomic>
#include <memory>

// 线程私有消息（发给“线程”本身，窗口句柄是 NULL）
static const UINT WM_THREAD_TASK = WM_APP + 3;      // 主线程 -> UI 线程派活
static const UINT WM_THREAD_TICK = WM_APP + 4;      // UI 线程 -> 主窗口回报
static const UINT WM_RACE_DONE  = WM_APP + 5;       // 竞争实验完成

// ============ UI 线程自有的窗口：一个动画监视器 ============

class CMonitorWnd : public CWnd {
    DECLARE_MESSAGE_MAP()
public:
    BOOL Create() {
        static const wchar_t cls[] = L"MfcGuide32Monitor";
        WNDCLASS wc = {};
        wc.lpfnWndProc = ::DefWindowProc;
        wc.hInstance = AfxGetInstanceHandle();
        wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
        wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
        wc.lpszClassName = cls;
        AfxRegisterClass(&wc);
        return CWnd::Create(cls, _T("UI 线程的窗口"),
                            WS_OVERLAPPED | WS_CAPTION | WS_SYSMENU | WS_MINIMIZEBOX,
                            CRect(0, 0, 320, 200), nullptr, 0);
    }

    void Note(const CString& s) {
        m_lines.Add(s);
        if (m_lines.GetCount() > 8)
            m_lines.RemoveAt(0);
        Invalidate();
    }

private:
    afx_msg void OnPaint() {
        CPaintDC dc(this);
        CRect rc;
        GetClientRect(rc);
        // 脉冲条：UI 线程自己的定时器在驱动它
        int phase = (int)(GetTickCount64() / 60 % rc.Width());
        dc.FillSolidRect(rc, RGB(24, 32, 44));
        for (int y = 12; y < rc.Height() - 8; y += 26) {
            int w = 60 + (int)((rc.Width() - 90) *
                     (0.5 + 0.5 * sin((GetTickCount64() / 300.0) + y)));
            dc.FillSolidRect(12, y, w, 12, RGB(70, 160, 230));
        }
        dc.SetBkMode(TRANSPARENT);
        dc.SetTextColor(RGB(240, 240, 240));
        int y = rc.bottom - 14 * (int)m_lines.GetCount() - 8;
        for (INT_PTR i = 0; i < m_lines.GetCount(); i++, y += 14)
            dc.TextOut(12, y, m_lines[(int)i]);
        (void)phase;
    }

    afx_msg void OnTimer(UINT_PTR) {
        Invalidate(FALSE);       // 定时器属于本线程的消息循环 —— UI 线程活着的证据
    }

    afx_msg void OnDestroy() {
        KillTimer(1);
        CWnd::OnDestroy();
    }

    CStringArray m_lines;   // Add/GetAt/operator[] 都在（CStringList 是链表，没有这些）
};

BEGIN_MESSAGE_MAP(CMonitorWnd, CWnd)
    ON_WM_PAINT()
    ON_WM_TIMER()
    ON_WM_DESTROY()
END_MESSAGE_MAP()

// ============ UI 线程本体 ============

class CMonitorThread : public CWinThread {
    DECLARE_DYNCREATE(CMonitorThread)
public:
    // 线程的“InitInstance”：建窗口、起定时器。返回 FALSE 线程立刻退出
    BOOL InitInstance() override {
        if (!m_wnd.Create())
            return FALSE;
        m_wnd.ShowWindow(SW_SHOW);
        m_wnd.UpdateWindow();
        m_wnd.SetTimer(1, 120, nullptr);      // 定时器消息进本线程的队列

        // 告诉主窗口我来了（m_hNotifyWnd 由创建方塞进来）
        if (m_hNotifyWnd)
            ::PostMessage(m_hNotifyWnd, WM_THREAD_TICK, 0, (LPARAM)m_nThreadID);
        return TRUE;                           // 之后进 Run() 的消息循环
    }

    // 线程专属消息：PostThreadMessage 直达这里（不经过任何窗口）
    afx_msg void OnThreadTask(WPARAM wParam, LPARAM) {
        CString s;
        s.Format(_T("收到任务 #%lu，本线程执行"), (unsigned long)wParam);
        m_wnd.Note(s);
        if (m_hNotifyWnd)
            ::PostMessage(m_hNotifyWnd, WM_THREAD_TICK, 1, (LPARAM)m_nThreadID);
        // ON_THREAD_MESSAGE 的处理函数签名是 void(WPARAM, LPARAM)
    }

    int ExitInstance() override {
        if (m_hNotifyWnd)
            ::PostMessage(m_hNotifyWnd, WM_THREAD_TICK, 2, (LPARAM)m_nThreadID);
        return CWinThread::ExitInstance();
    }

    HWND m_hNotifyWnd = nullptr;    // 弱引用：只借 HWND（进程级），绝不存 CWnd*

    DECLARE_MESSAGE_MAP()
private:
    CMonitorWnd m_wnd;
};

IMPLEMENT_DYNCREATE(CMonitorThread, CWinThread)

BEGIN_MESSAGE_MAP(CMonitorThread, CWinThread)
    ON_THREAD_MESSAGE(WM_THREAD_TASK, OnThreadTask)
END_MESSAGE_MAP()

// ============ 主对话框 ============

class CThreadDlg : public CDialog {
    DECLARE_MESSAGE_MAP()
public:
    CThreadDlg() : CDialog(IDD_MAIN) {}

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();
        CenterWindow();
        m_log.SubclassDlgItem(IDC_EDIT_LOG, this);
        Append(_T("就绪。先“启动 UI 线程”，会多出一个由它拥有的窗口。\r\n"));
        return TRUE;
    }

    // ---------- 1/2/5. UI 线程生命周期 ----------

    void OnStartUiThread() {
        if (m_pMonitor) {
            Append(_T("[UI线程] 已在跑\r\n"));
            return;
        }
        // AfxBeginThread(RUNTIME_CLASS) 默认 m_bAutoDelete=TRUE：对象自己删。
        // 要等它退、要 PostThreadMessage，就得 FALSE 自己管 —— 教学与稳健两全
        m_pMonitor = AfxBeginThread(RUNTIME_CLASS(CMonitorThread),
                                     THREAD_PRIORITY_NORMAL,
                                     0, CREATE_SUSPENDED);
        m_pMonitor->m_bAutoDelete = FALSE;
        static_cast<CMonitorThread*>(m_pMonitor)->m_hNotifyWnd = GetSafeHwnd();
        m_pMonitor->ResumeThread();
    }

    void OnStopUiThread() {
        if (!m_pMonitor) {
            Append(_T("[UI线程] 没在跑\r\n"));
            return;
        }
        // 优雅收摊：PostThreadMessage(WM_QUIT) 让消息循环自己退，
        // 然后等句柄（m_bAutoDelete=FALSE 时对象还在，Handle 仍有效）
        m_pMonitor->PostThreadMessageW(WM_QUIT, 0, 0);
        HANDLE h = m_pMonitor->m_hThread;
        DWORD wait = WaitForSingleObject(h, 3000);
        if (wait == WAIT_OBJECT_0) {
            Append(_T("[UI线程] 已干净退出（WM_QUIT + 等句柄）\r\n"));
        } else {
            Append(_T("[UI线程] 3 秒还没退！泄漏处理留给作业：对象不再 delete，防悬空\r\n"));
        }
        if (wait == WAIT_OBJECT_0)
            delete m_pMonitor;       // m_bAutoDelete=FALSE 的代价：自己收尸
        m_pMonitor = nullptr;
    }

    void OnPostTask() {
        if (!m_pMonitor) {
            Append(_T("[UI线程] 先启动 UI 线程\r\n"));
            return;
        }
        // PostThreadMessage：发给“线程”（窗口句柄 NULL），线程消息循环接
        m_taskSeq++;
        if (!m_pMonitor->PostThreadMessageW(WM_THREAD_TASK, (WPARAM)m_taskSeq, 0))
            Append(_T("[UI线程] 投递失败（线程可能刚退）\r\n"));
    }

    // ---------- 3. 数据竞争与修正 ----------

    struct RaceJob {
        std::atomic<long>* counter;
        bool useLock;
        CMutex* mutex;            // useLock 时有效
        int increments;
        HWND hReport;
    };

    static UINT RaceProc(LPVOID p) {
        std::unique_ptr<RaceJob> job((RaceJob*)p);
        for (int i = 0; i < job->increments; i++) {
            if (job->useLock) {
                CSingleLock lock(job->mutex);
                lock.Lock();
                job->counter->fetch_add(1);
                // 竞争实验里故意不加“工作”：只演示锁对计数的正确性
            } else {
                // 无锁版本：load + store 两步，两个线程交错必丢更新
                long v = job->counter->load();
                job->counter->store(v + 1);
            }
        }
        ::PostMessage(job->hReport, WM_RACE_DONE, (WPARAM)job->useLock, 0);
        return 0;
    }

    void RunRace(bool useLock) {        const int kPerThread = 100000;
        m_raceCounter = 0;
        m_raceExpect = kPerThread * 2;
        m_raceDone = 0;
        if (useLock)
            m_raceMutex.reset(new CMutex(FALSE));
        for (int i = 0; i < 2; i++) {
            RaceJob* job = new RaceJob{ &m_raceCounter, useLock, m_raceMutex.get(),
                                        kPerThread, GetSafeHwnd() };
            AfxBeginThread(RaceProc, job);
        }
        CString tag = useLock ? _T("[加锁]") : _T("[无锁]");
        Append(tag + _T(" 两线程各加 100000，等结果...\r\n"));
    }

    void OnRaceOn()  { RunRace(false); }
    void OnRaceOff() { RunRace(true); }

    afx_msg LRESULT OnRaceDone(WPARAM useLock, LPARAM) {
        m_raceDone++;
        if (m_raceDone < 2)
            return 0;
        CString tag = useLock ? _T("[加锁]") : _T("[无锁]");
        CString msg;
        msg.Format(_T("%s 结果：%ld / 期望 %d —— %s\r\n"), tag, m_raceCounter.load(),
                   m_raceExpect,
                   m_raceCounter == m_raceExpect ? _T("一毫不差")
                                                 : _T("丢了更新（load/store 被交错）"));
        Append(msg);
        return 0;
    }

    // ---------- 4. 优先级 ----------

    struct PrioJob {
        std::atomic<long>* counter;
        int milliseconds;
        HWND hReport;
    };

    static UINT PrioProc(LPVOID p) {
        std::unique_ptr<PrioJob> job((PrioJob*)p);
        ULONGLONG until = GetTickCount64() + job->milliseconds;
        while (GetTickCount64() < until)
            job->counter->fetch_add(1);
        ::PostMessage(job->hReport, WM_THREAD_TICK, 3, 0);
        return 0;
    }

    void OnPriority() {
        const int kMs = 600;
        m_prioHigh = 0;
        m_prioNormal = 0;
        m_prioReports = 0;
        Append(_T("[优先级] 两线程空转计数 600ms：一个 ABOVE_NORMAL 一个 NORMAL\r\n"));
        // AfxBeginThread 第三个参数就是优先级：起跑即生效，不用事后再 Set
        PrioJob* jHigh = new PrioJob{ &m_prioHigh, kMs, GetSafeHwnd() };
        AfxBeginThread(PrioProc, jHigh, THREAD_PRIORITY_ABOVE_NORMAL);
        PrioJob* jNorm = new PrioJob{ &m_prioNormal, kMs, GetSafeHwnd() };
        AfxBeginThread(PrioProc, jNorm, THREAD_PRIORITY_NORMAL);
    }

    afx_msg LRESULT OnThreadTick(WPARAM what, LPARAM tid) {
        switch (what) {
        case 0: {
            CString s;
            s.Format(_T("[UI线程] 已启动（tid=%lu），它的窗口应已出现\r\n"), (unsigned long)tid);
            Append(s);
            break;
        }
        case 1: {
            CString s;
            s.Format(_T("[UI线程] 任务完成回执（tid=%lu）\r\n"), (unsigned long)tid);
            Append(s);
            break;
        }
        case 2:
            Append(_T("[UI线程] ExitInstance 报告：正在收摊\r\n"));
            break;
        case 3: {
            m_prioReports++;
            if (m_prioReports == 2) {
                CString s;
                s.Format(_T("[优先级] 高优先级计了 %ld 万次，普通 %ld 万次 —— 差 %.1f 倍\r\n"),
                         m_prioHigh.load() / 10000, m_prioNormal.load() / 10000,
                         m_prioNormal ? (double)m_prioHigh / m_prioNormal : 0.0);
                Append(s);
                m_prioReports = 0;
            }
            break;
        }
        }
        return 0;
    }

    void Append(const CString& line) {
        int len = m_log.GetWindowTextLength();
        m_log.SetSel(len, len);
        m_log.ReplaceSel(line);
    }

    CEdit   m_log;
    CWinThread* m_pMonitor = nullptr;
    int     m_taskSeq = 0;

    std::atomic<long> m_raceCounter{ 0 };
    int     m_raceExpect = 0;
    int     m_raceDone = 0;
    std::unique_ptr<CMutex> m_raceMutex;

    std::atomic<long> m_prioHigh{ 0 };
    std::atomic<long> m_prioNormal{ 0 };
    int     m_prioReports = 0;
};

BEGIN_MESSAGE_MAP(CThreadDlg, CDialog)
    ON_BN_CLICKED(IDC_BTN_START_UI, OnStartUiThread)
    ON_BN_CLICKED(IDC_BTN_STOP_UI, OnStopUiThread)
    ON_BN_CLICKED(IDC_BTN_POST_THREAD, OnPostTask)
    ON_BN_CLICKED(IDC_BTN_RACE_ON, OnRaceOn)
    ON_BN_CLICKED(IDC_BTN_RACE_OFF, OnRaceOff)
    ON_MESSAGE(WM_THREAD_TICK, OnThreadTick)
    ON_MESSAGE(WM_RACE_DONE, OnRaceDone)
END_MESSAGE_MAP()

class CThreadApp : public CWinApp {
public:
    BOOL InitInstance() override {
        CThreadDlg dlg;
        m_pMainWnd = &dlg;
        dlg.DoModal();
        return FALSE;
    }
};

CThreadApp theApp;
