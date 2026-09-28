// 30_ipc：进程间通信四件套 —— 书2 第3 章的主菜（实例38-40）。
//
//   1. WM_COPYDATA：跨进程搬一块内存，系统代拷（书2 3.12“客户机/服务器”数据调用）
//   2. 邮槽 mailslot：单向广播（书2 3.3）—— 一写多读，报文小、不保序
//   3. 命名管道 named pipe：双向流式、可跨机（书2 3.4）—— echo 服务端线程 + 客户端
//   4. 共享内存 + 文件映射 + 命名互斥体：最快的共享通道（书2 3.10/3.11）
//
// 设计：所有“服务端”都在本进程的 worker 线程里跑（第 20 章的 PostMessage 回传套路），
// 一个 exe 自演自收；WM_COPYDATA 面向“另一个实例”，开两个程序互发体验最真。
//
// 编译运行：.\build.ps1 -File 30_ipc   （建议开两个实例玩 WM_COPYDATA）

#include "resource.h"
#include <afxwin.h>
#include <afxmt.h>     // CMutex / CSingleLock

// ============ 约定的通道名（跨进程靠字符串碰头） ============
static const wchar_t kCopyDataStamp[] = L"MFC-GUIDE-IPC-30";    // COPYDATASTRUCT.dwData 校验戳
static const wchar_t kMailslotName[]  = L"\\\\.\\mailslot\\mfc_guide_30";
static const wchar_t kPipeName[]      = L"\\\\.\\pipe\\mfc_guide_30";
static const wchar_t kShmName[]       = L"Local\\mfc_guide_30_shm";
static const wchar_t kMutexName[]     = L"Local\\mfc_guide_30_mutex";

// 自定义窗口消息：worker 线程 -> UI 的回传通道（第 20 章的老朋友）
static const UINT WM_IPC_LOG = WM_APP + 1;

class CIpcDlg : public CDialog {
    DECLARE_MESSAGE_MAP()
public:
    CIpcDlg() : CDialog(IDD_MAIN) {}

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();
        CenterWindow();

        wchar_t exe[MAX_PATH] = {};
        GetModuleFileNameW(nullptr, exe, MAX_PATH);
        CString cap;
        cap.Format(_T("第 30 章 · IPC（PID=%lu）"), GetCurrentProcessId());
        SetWindowText(cap);

        m_log.SubclassDlgItem(IDC_EDIT_LOG, this);
        CString init;
        init.Format(_T("PID %lu 就绪。WM_COPYDATA 请开两个实例互发。\r\n"), GetCurrentProcessId());
        Append(init);
        return TRUE;
    }

    CString GetSendText() {
        CString s;
        GetDlgItemText(IDC_EDIT_SEND, s);
        return s.IsEmpty() ? CString(_T("默认报文")) : s;
    }

    // ================= 1. WM_COPYDATA =================

    void OnCopyData() {
        // 找“其他实例”：EnumWindows 里按窗口类+标题前缀过滤
        CString text = GetSendText();
        m_cdPayload = text;               // 回调里读，lambda 无捕获、经 lp 传 this
        m_cdSentCount = 0;
        EnumWindows([](HWND hwnd, LPARAM lp) -> BOOL {
            CIpcDlg* self = (CIpcDlg*)lp;
            wchar_t cls[64] = {};
            GetClassNameW(hwnd, cls, 64);
            if (wcscmp(cls, L"#32770") != 0)      // 标准对话框类
                return TRUE;
            wchar_t cap[128] = {};
            ::GetWindowTextW(hwnd, cap, 128);
            if (wcsncmp(cap, L"第 30 章 · IPC", 10) == 0 && hwnd != self->GetSafeHwnd()) {
                COPYDATASTRUCT cds = {};
                cds.dwData = (ULONG_PTR)0x49504330;               // 'IPC0'：接收端先验这个
                cds.cbData = (DWORD)((self->m_cdPayload.GetLength() + 1) * sizeof(wchar_t));
                cds.lpData = (PVOID)(LPCTSTR)self->m_cdPayload;
                // SendMessage 同步拷贝；对方返回 FALSE 就是拒收（全局 API，避开成员函数重载）
                DWORD_PTR ok = 0;
                ::SendMessageTimeoutW(hwnd, WM_COPYDATA,
                            (WPARAM)self->GetSafeHwnd(), (LPARAM)&cds,
                            SMTO_BLOCK, 800, &ok);
                if (ok) self->m_cdSentCount++;
            }
            return TRUE;
        }, (LPARAM)this);

        m_cdPayload.Empty();
        if (m_cdSentCount > 0) {
            CString msg;
            msg.Format(_T("[COPYDATA] 已发给 %d 个实例：%s\r\n"), m_cdSentCount, (LPCTSTR)text);
            Append(msg);
        } else {
            Append(_T("[COPYDATA] 没找到别的实例（本窗口除外）。再启动一个本程序试试。\r\n"));
        }
    }

    // 接收端：WM_COPYDATA 只能由窗口收，数据由系统代拷——收完即用，不许存 lpData 指针
    afx_msg BOOL OnCopyData(CWnd* pWnd, COPYDATASTRUCT* pcd) {
        if (pcd->dwData != 0x49504330) {
            Append(_T("[COPYDATA] 收到陌生 dwData，拒收\r\n"));
            return FALSE;                       // 戳不对：恶意/无关发送方，不碰 lpData
        }
        CString text((const wchar_t*)pcd->lpData, pcd->cbData / sizeof(wchar_t) - 1);
        CString msg;
        msg.Format(_T("[COPYDATA] 收到（来自 PID %lu）：%s\r\n"),
                   ::GetWindowThreadProcessId(pWnd->GetSafeHwnd(), nullptr), (LPCTSTR)text);
        Append(msg);
        return TRUE;
    }

    // ================= 2. 邮槽 =================

    void OnMailslot() {
        if (!m_slotThreadRunning) {
            StartMailslotServer();
            Sleep(200);    // 给服务线程一拍创建邮槽（真实代码用事件等就绪）
        }
        // 客户端：像打开文件一样写邮槽
        HANDLE h = CreateFileW(kMailslotName, GENERIC_WRITE, FILE_SHARE_READ,
                               nullptr, OPEN_EXISTING, 0, nullptr);
        if (h == INVALID_HANDLE_VALUE) {
            Append(_T("[邮槽] 打开失败：服务端还没就绪？\r\n"));
            return;
        }
        CString text = GetSendText();
        DWORD written = 0;
        CStringW msg(text);
        WriteFile(h, (LPCWSTR)msg, (DWORD)(msg.GetLength() + 1) * sizeof(wchar_t), &written, nullptr);
        CloseHandle(h);
        CString log;
        log.Format(_T("[邮槽] 已投递 %lu 字节：%s\r\n"), written, (LPCTSTR)text);
        Append(log);
    }

    void StartMailslotServer() {
        m_slotThreadRunning = true;
        // 邮槽服务端也走 worker 线程：ReadFile 阻塞等报文
        HANDLE hThread = CreateThread(nullptr, 0, [](LPVOID lp) -> DWORD {
            CIpcDlg* self = (CIpcDlg*)lp;
            HANDLE slot = CreateMailslotW(kMailslotName, 0, 2000, nullptr); // 2 秒读超时
            if (slot == INVALID_HANDLE_VALUE) {
                self->PostLog(_T("[邮槽] 服务端创建失败\r\n"));
                return 0;
            }
            self->PostLog(_T("[邮槽] 服务端已开（\\\\.\\mailslot\\mfc_guide_30）\r\n"));
            for (;;) {
                DWORD msgSize = 0, nextSize = 0, msgCount = 0;
                DWORD br = 0;
                if (!GetMailslotInfo(slot, nullptr, &nextSize, &msgCount, nullptr) || msgCount == 0) {
                    if (WaitForSingleObject(self->m_stopEvent, 0) == WAIT_OBJECT_0)
                        break;
                    continue;                      // 超时空转，查停止标志
                }
                wchar_t buf[256] = {};
                if (!ReadFile(slot, buf, sizeof(buf) - sizeof(wchar_t), &br, nullptr) || br == 0)
                    continue;
                CString text(buf, br / sizeof(wchar_t) - 1);
                CString log;
                log.Format(_T("[邮槽] 收到 %lu 字节：%s\r\n"), br, (LPCTSTR)text);
                self->PostLog(log);
            }
            CloseHandle(slot);
            return 0;
        }, this, 0, nullptr);
        CloseHandle(hThread);
    }

    // ================= 3. 命名管道 =================

    void OnPipe() {
        if (!m_pipeRunning) {
            StartPipeServer();
            Sleep(250);
        }
        // 客户端：连管道 -> 写一行 -> 读回声
        HANDLE h = CreateFileW(kPipeName, GENERIC_READ | GENERIC_WRITE, 0, nullptr,
                               OPEN_EXISTING, 0, nullptr);
        if (h == INVALID_HANDLE_VALUE) {
            Append(_T("[管道] 连接失败（服务端没就绪？）\r\n"));
            return;
        }
        DWORD mode = PIPE_READMODE_MESSAGE;
        SetNamedPipeHandleState(h, &mode, nullptr, nullptr);

        CString text = GetSendText();
        CStringW msg(text);
        DWORD written = 0, read = 0;
        wchar_t echo[256] = {};
        WriteFile(h, (LPCWSTR)msg, (DWORD)((msg.GetLength() + 1) * sizeof(wchar_t)), &written, nullptr);
        ReadFile(h, echo, sizeof(echo) - sizeof(wchar_t), &read, nullptr);
        CloseHandle(h);
        CString back(echo, read / sizeof(wchar_t) - 1);
        CString log;
        log.Format(_T("[管道] 发送“%s”，回声“%s”\r\n"), (LPCTSTR)text, (LPCTSTR)back);
        Append(log);
    }

    void StartPipeServer() {
        m_pipeRunning = true;
        HANDLE hThread = CreateThread(nullptr, 0, [](LPVOID lp) -> DWORD {
            CIpcDlg* self = (CIpcDlg*)lp;
            for (;;) {
                HANDLE pipe = CreateNamedPipeW(kPipeName,
                                               PIPE_ACCESS_DUPLEX,
                                               PIPE_TYPE_MESSAGE | PIPE_READMODE_MESSAGE |
                                               PIPE_WAIT,
                                               1,                    // 单实例：一问一答轮流来
                                               4096, 4096, 0, nullptr);
                if (pipe == INVALID_HANDLE_VALUE) {
                    self->PostLog(_T("[管道] 服务端创建失败\r\n"));
                    return 0;
                }
                self->PostLog(_T("[管道] 服务端就绪，等待连接...\r\n"));
                if (ConnectNamedPipe(pipe, nullptr) || GetLastError() == ERROR_PIPE_CONNECTED) {
                    wchar_t buf[256] = {};
                    DWORD br = 0;
                    while (ReadFile(pipe, buf, sizeof(buf) - sizeof(wchar_t), &br, nullptr) && br > 0) {
                        CString text(buf, br / sizeof(wchar_t) - 1);
                        CString log;
                        log.Format(_T("[管道] 服务端收到“%s”，原样回声\r\n"), (LPCTSTR)text);
                        self->PostLog(log);
                        CString echo = _T("回声: ") + text;
                        DWORD bw = 0;
                        WriteFile(pipe, (LPCWSTR)echo,
                                  (DWORD)((echo.GetLength() + 1) * sizeof(wchar_t)), &bw, nullptr);
                    }
                    FlushFileBuffers(pipe);
                }
                DisconnectNamedPipe(pipe);
                CloseHandle(pipe);
                if (WaitForSingleObject(self->m_stopEvent, 0) == WAIT_OBJECT_0)
                    break;
            }
            return 0;
        }, this, 0, nullptr);
        CloseHandle(hThread);
    }

    // ================= 4. 共享内存 + 命名互斥体 =================

    struct ShmBlock {
        DWORD writerPid;
        DWORD seq;             // 写一次 +1：读端看得见对方在动
        wchar_t text[112];
    };

    void OnSharedMem() {
        // 文件映射到 INVALID_HANDLE_VALUE = 纯内存段（书2 3.11 文件映射的内存特例）
        HANDLE map = CreateFileMappingW(INVALID_HANDLE_VALUE, nullptr, PAGE_READWRITE,
                                        0, sizeof(ShmBlock), kShmName);
        if (!map) {
            Append(_T("[共享] CreateFileMapping 失败\r\n"));
            return;
        }
        // 第二个实例拿到的是已存在的那块（GetLastError == ERROR_ALREADY_EXISTS）
        bool first = GetLastError() != ERROR_ALREADY_EXISTS;
        ShmBlock* blk = (ShmBlock*)MapViewOfFile(map, FILE_MAP_ALL_ACCESS, 0, 0, sizeof(ShmBlock));

        // 命名互斥体：两个进程拿的是同一个内核对象，跨进程锁
        CMutex mutex(FALSE, kMutexName);
        CSingleLock lock(&mutex, FALSE);

        CString text = GetSendText();
        if (lock.Lock(2000)) {                 // 限时加锁：对方崩了也不至于卡死 UI
            blk->writerPid = GetCurrentProcessId();
            blk->seq = blk->seq + 1;
            lstrcpyn(blk->text, text, 112);
            CString w;
            w.Format(_T("[共享] 写入 seq=%lu：%s（%s）\r\n"), blk->seq, blk->text,
                     first ? _T("新建段") : _T("复用已有段"));
            Append(w);

            // 读回来证明共享（另一个实例读到的也是这块）
            CString r;
            r.Format(_T("[共享] 当前段内：PID %lu, seq %lu, “%s”\r\n"),
                     blk->writerPid, blk->seq, blk->text);
            Append(r);
            lock.Unlock();
        } else {
            Append(_T("[共享] 加锁超时：另一进程正占着？\r\n"));
        }
        UnmapViewOfFile(blk);
        CloseHandle(map);
    }

    // ================= 基础设施 =================

    void PostLog(const CString& line) {
        // 分配一份堆字符串跨线程传递（UI 线程收后 delete —— 经典做法）
        wchar_t* p = new wchar_t[line.GetLength() + 1];
        lstrcpyn(p, line, line.GetLength() + 1);
        PostMessage(WM_IPC_LOG, 0, (LPARAM)p);
    }

    afx_msg LRESULT OnIpcLog(WPARAM, LPARAM lp) {
        wchar_t* p = (wchar_t*)lp;
        Append(p);
        delete[] p;
        return 0;
    }

    void Append(const CString& line) {
        int len = m_log.GetWindowTextLength();
        m_log.SetSel(len, len);
        m_log.ReplaceSel(line);
    }

    BOOL DestroyWindow() override {
        SetEvent(m_stopEvent);
        Sleep(50);      // 给服务线程一拍退出（真实代码等线程句柄）
        return CDialog::DestroyWindow();
    }

    CEdit   m_log;
    HANDLE  m_stopEvent = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    bool    m_slotThreadRunning = false;
    bool    m_pipeRunning = false;
    int     m_cdSentCount = 0;
    CString m_cdPayload;
};

BEGIN_MESSAGE_MAP(CIpcDlg, CDialog)
    ON_BN_CLICKED(IDC_BTN_COPYDATA, OnCopyData)
    ON_BN_CLICKED(IDC_BTN_MAILSLOT, OnMailslot)
    ON_BN_CLICKED(IDC_BTN_PIPE, OnPipe)
    ON_BN_CLICKED(IDC_BTN_SHAREDMEM, OnSharedMem)
    ON_MESSAGE(WM_IPC_LOG, OnIpcLog)
    ON_WM_COPYDATA()
END_MESSAGE_MAP()

class CIpcApp : public CWinApp {
public:
    BOOL InitInstance() override {
        CIpcDlg dlg;
        m_pMainWnd = &dlg;
        dlg.DoModal();
        return FALSE;
    }
};

CIpcApp theApp;
