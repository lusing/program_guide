// 31_winsock：Windows 套接字 —— 书2 第3.5 节 + 实例51/52。
//
//   1. CSocket 阻塞模型：服务端线程 Listen/Accept/Receive，客户端 Connect/Send
//      —— 教学首选：代码像读伪代码，事件模型（CAsyncSocket）先知道有这回事
//   2. CSocketFile + CArchive：给 socket 套上 CArchive，CObject 序列化直接上网
//      —— 书2 实例52“使用串行化 I/O 的套接字”，两本 MFC 书里最惊艳的一手
//   3. UDP 数据报：CSocket::Create(0, SOCK_DGRAM) + SendTo/ReceiveFrom
//   4. AfxSocketInit 是 MFC 套接字的前置条件（忘了它 Create 必失败）
//
// 网络字节序、主机字节序的经典坑在本例不用碰——端口/地址都由 API 结构体托管。
//
// 编译运行：.\build.ps1 -File 31_winsock

#include "resource.h"
#include <afxwin.h>
#include <afxsock.h>    // CSocket / CSocketFile（afxsock.h 自动带 ws2_32）

static const UINT PORT_TCP = 31530;   // 文本回声通道
static const UINT PORT_TCP2 = 31532;  // 对象序列化通道（书2 实例52 的专用车道）
static const UINT PORT_UDP = 31531;
static const UINT WM_SOCK_LOG = WM_APP + 2;

// ============ 跨 socket 序列化的消息对象（书2 实例52 的核心角色） ============

class CNetMessage : public CObject {
    DECLARE_SERIAL(CNetMessage)
public:
    CString  m_from;       // 谁发的
    CString  m_text;       // 说什么
    CTime    m_at;         // 何时

    void Serialize(CArchive& ar) override {
        if (ar.IsStoring())
            ar << m_from << m_text << (int)m_at.GetTime();
        else {
            int t = 0;
            ar >> m_from >> m_text >> t;
            m_at = CTime((time_t)t);
        }
    }
};
IMPLEMENT_SERIAL(CNetMessage, CObject, 1)

// ============ 服务端：阻塞 CSocket 跑在 worker 线程里 ============

class CSockDlg : public CDialog {
    DECLARE_MESSAGE_MAP()
public:
    CSockDlg() : CDialog(IDD_MAIN) {}

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();
        CenterWindow();
        m_log.SubclassDlgItem(IDC_EDIT_LOG, this);
        Append(_T("就绪。流程：先“启动服务端”，再“TCP 连接并发送”。\r\n"));
        return TRUE;
    }

    CString GetSendText() {
        CString s;
        GetDlgItemText(IDC_EDIT_SEND, s);
        return s.IsEmpty() ? CString(_T("hello socket")) : s;
    }

    void PostLog(const CString& line) {
        wchar_t* p = new wchar_t[line.GetLength() + 1];
        lstrcpyn(p, line, line.GetLength() + 1);
        PostMessage(WM_SOCK_LOG, 0, (LPARAM)p);
    }

    afx_msg LRESULT OnSockLog(WPARAM, LPARAM lp) {
        wchar_t* p = (wchar_t*)lp;
        Append(p);
        delete[] p;
        return 0;
    }

    // ---------- 1. TCP 文本回声 ----------

    void OnStartServer() {
        if (m_srvRunning) {
            Append(_T("[TCP] 服务端已在跑\r\n"));
            return;
        }
        m_srvRunning = true;
        ResetEvent(m_stopEvt);

        // worker 线程里跑阻塞 CSocket —— CSocket 在非创建线程里也能用，
        // 但一个 socket 一个用途：本线程独占 listener + accepted
        HANDLE h = CreateThread(nullptr, 0, [](LPVOID lp) -> DWORD {
            CSockDlg* self = (CSockDlg*)lp;
            CSocket listener;
            if (!listener.Create(PORT_TCP)) {                  // 绑定 + 监听一步到位
                self->PostLog(_T("[TCP] Create 失败（AfxSocketInit 忘了调？）\r\n"));
                return 0;
            }
            if (!listener.Listen(4)) {
                self->PostLog(_T("[TCP] Listen 失败\r\n"));
                return 0;
            }
            {
                CString log;
                log.Format(_T("[TCP] 服务端监听 127.0.0.1:%u，等待连接...\r\n"), PORT_TCP);
                self->PostLog(log);
            }
            for (;;) {
                CSocket client;
                if (!listener.Accept(client)) {                 // 阻塞：直到有连接进来
                    break;                                      // socket 关闭/出错
                }
                self->PostLog(_T("[TCP] 接受一个连接\r\n"));

                wchar_t buf[256] = {};
                int n = 0;
                // Receive 阻塞收满一“段”就返回（TCP 是流，没有消息边界——教学单发单收不粘包）
                while ((n = client.Receive(buf, sizeof(buf) - sizeof(wchar_t))) > 0) {
                    CString text(buf, n / sizeof(wchar_t));
                    CString log;
                    log.Format(_T("[TCP] 服务端收到“%s”\r\n"), (LPCTSTR)text);
                    self->PostLog(log);

                    CString echo = _T("回声: ") + text;
                    client.Send((LPCWSTR)echo, (int)((echo.GetLength() + 1) * sizeof(wchar_t)));
                }
                client.Close();
                if (WaitForSingleObject(self->m_stopEvt, 0) == WAIT_OBJECT_0)
                    break;
            }
            listener.Close();
            return 0;
        }, this, 0, nullptr);
        CloseHandle(h);
    }

    void OnConnect() {
        CSocket sock;
        if (!sock.Create()) {                 // 客户端：系统分配端口
            Append(_T("[TCP] 客户端 Create 失败\r\n"));
            return;
        }
        if (!sock.Connect(_T("127.0.0.1"), PORT_TCP)) {
            Append(_T("[TCP] 连接失败：先启动服务端\r\n"));
            return;
        }
        CString text = GetSendText();
        sock.Send((LPCWSTR)text, (int)((text.GetLength() + 1) * sizeof(wchar_t)));
        // 收回声（服务端原样回）
        sock.ShutDown(1);                     // 1 = SD_SEND：我不再发了，半关闭
        wchar_t buf[256] = {};
        int n = sock.Receive(buf, sizeof(buf) - sizeof(wchar_t));
        if (n > 0) {
            CString echo(buf, n / sizeof(wchar_t));
            Append(_T("[TCP] 客户端收到：") + echo + _T("\r\n"));
        }
        sock.Close();
    }

    // ---------- 2. 序列化通道：CSocketFile + CArchive（书2 实例52） ----------
    // 服务端线程跑专用端口 PORT_TCP2：accept 后包 CSocketFile、架 CArchive，
    // 收发都是 CNetMessage 对象 —— “socket 长出了 Serialize 的脸”

    void StartObjectServer() {
        if (m_objRunning) return;
        m_objRunning = true;
        HANDLE h = CreateThread(nullptr, 0, [](LPVOID lp) -> DWORD {
            CSockDlg* self = (CSockDlg*)lp;
            CSocket listener;
            if (!listener.Create(PORT_TCP2) || !listener.Listen(2)) {
                self->PostLog(_T("[序列化] 服务端起不来（端口被占？）\r\n"));
                return 0;
            }
            self->PostLog(_T("[序列化] 服务端就绪，等 CNetMessage...\r\n"));
            for (;;) {
                CSocket client;
                if (!listener.Accept(client))
                    break;
                CSocketFile file(&client);
                CArchive arIn(&file, CArchive::load);     // 双向通道：一对 archive 各管一方向
                CArchive arOut(&file, CArchive::store);
                try {
                    CObject* pRaw = nullptr;
                    arIn >> pRaw;                          // 读 CObject*：类名+schema+字段全在流里
                    if (pRaw) {
                        CNetMessage* pMsg = dynamic_cast<CNetMessage*>(pRaw);
                        if (pMsg) {
                            CString log;
                            log.Format(_T("[序列化] 收到 CNetMessage：from=%s text=%s at=%s\r\n"),
                                       (LPCTSTR)pMsg->m_from, (LPCTSTR)pMsg->m_text,
                                       (LPCTSTR)pMsg->m_at.Format(_T("%H:%M:%S")));
                            self->PostLog(log);

                            CNetMessage ack;
                            ack.m_from = _T("服务端");
                            ack.m_text = _T("对象已收到");
                            ack.m_at = CTime::GetCurrentTime();
                            arOut << &ack;
                            arOut.Flush();                 // 不 Flush 对端收不到（缓冲没走）
                        }
                        delete pRaw;
                    }
                } catch (CArchiveException* e) {
                    TCHAR msg[128] = {};
                    e->GetErrorMessage(msg, 128);
                    CString log;
                    log.Format(_T("[序列化] 异常：%s\r\n"), msg);
                    self->PostLog(log);
                    e->Delete();
                }
                client.Close();
                if (WaitForSingleObject(self->m_stopEvt, 0) == WAIT_OBJECT_0)
                    break;
            }
            return 0;
        }, this, 0, nullptr);
        CloseHandle(h);
    }

    void OnSerializedExchange() {
        StartObjectServer();
        Sleep(200);
        CSocket sock;
        if (!sock.Create() || !sock.Connect(_T("127.0.0.1"), PORT_TCP2)) {
            Append(_T("[序列化] 连接失败\r\n"));
            return;
        }
        CSocketFile file(&sock);
        CArchive arOut(&file, CArchive::store);
        CArchive arIn(&file, CArchive::load);

        CNetMessage msg;
        msg.m_from = _T("客户端");
        msg.m_text = GetSendText();
        msg.m_at = CTime::GetCurrentTime();
        arOut << &msg;           // 走 CArchive 的 CObject* 通道：连类名带字段一起序列化
        arOut.Flush();           // 关键：把缓冲推到 socket，否则对端干等

        CObject* pBack = nullptr;
        arIn >> pBack;
        if (pBack) {
            CNetMessage* pAck = dynamic_cast<CNetMessage*>(pBack);
            if (pAck)
                Append(_T("[序列化] 客户端收到回执：") + pAck->m_text + _T("\r\n"));
            delete pBack;
        }
        sock.Close();
    }

    // ---------- 3. UDP 数据报 ----------

    void OnUdp() {
        // UDP 服务端一次性内联起：单独端口，收一个报一个
        static HANDLE udpThread = nullptr;
        if (!udpThread) {
            udpThread = CreateThread(nullptr, 0, [](LPVOID lp) -> DWORD {
                CSockDlg* self = (CSockDlg*)lp;
                CSocket udp;
                if (!udp.Create(PORT_UDP, SOCK_DGRAM)) {
                    self->PostLog(_T("[UDP] 服务端 Create 失败\r\n"));
                    return 0;
                }
                self->PostLog(_T("[UDP] 服务端就绪（SOCK_DGRAM）\r\n"));
                for (;;) {
                    wchar_t buf[256] = {};
                    CString fromIp;
                    UINT fromPort = 0;
                    int n = udp.ReceiveFrom(buf, sizeof(buf) - sizeof(wchar_t),
                                            fromIp, fromPort);
                    if (n <= 0)
                        break;
                    CString text(buf, n / sizeof(wchar_t));
                    CString log;
                    log.Format(_T("[UDP] 收到来自 %s:%u：“%s”\r\n"),
                               (LPCTSTR)fromIp, fromPort, (LPCTSTR)text);
                    self->PostLog(log);
                    udp.SendTo((LPCWSTR)text, (int)((text.GetLength() + 1) * sizeof(wchar_t)),
                               fromPort, fromIp);
                    if (WaitForSingleObject(self->m_stopEvt, 0) == WAIT_OBJECT_0)
                        break;
                }
                return 0;
            }, this, 0, nullptr);
        }
        Sleep(150);
        CSocket udp;
        if (!udp.Create(0, SOCK_DGRAM)) {
            Append(_T("[UDP] 客户端 Create 失败\r\n"));
            return;
        }
        CString text = GetSendText();
        udp.SendTo((LPCWSTR)text, (int)((text.GetLength() + 1) * sizeof(wchar_t)),
                   PORT_UDP, _T("127.0.0.1"));
        wchar_t buf[256] = {};
        int n = udp.Receive(buf, sizeof(buf) - sizeof(wchar_t));
        if (n > 0) {
            CString echo(buf, n / sizeof(wchar_t));
            Append(_T("[UDP] 客户端收到回声：") + echo + _T("\r\n"));
        }
        udp.Close();
    }

    void Append(const CString& line) {
        int len = m_log.GetWindowTextLength();
        m_log.SetSel(len, len);
        m_log.ReplaceSel(line);
    }

    BOOL DestroyWindow() override {
        SetEvent(m_stopEvt);
        Sleep(100);
        return CDialog::DestroyWindow();
    }

    CEdit   m_log;
    HANDLE  m_stopEvt = CreateEventW(nullptr, TRUE, FALSE, nullptr);
    bool    m_srvRunning = false;
    bool    m_objRunning = false;
};

BEGIN_MESSAGE_MAP(CSockDlg, CDialog)
    ON_BN_CLICKED(IDC_BTN_STARTSRV, OnStartServer)
    ON_BN_CLICKED(IDC_BTN_CONNECT, OnConnect)
    ON_BN_CLICKED(IDC_BTN_SERIALEX, OnSerializedExchange)
    ON_BN_CLICKED(IDC_BTN_UDP, OnUdp)
    ON_MESSAGE(WM_SOCK_LOG, OnSockLog)
END_MESSAGE_MAP()

class CSockApp : public CWinApp {
public:
    BOOL InitInstance() override {
        // MFC 套接字的地基：不开它，CSocket::Create 直接失败
        if (!AfxSocketInit())
            return FALSE;
        CSockDlg dlg;
        m_pMainWnd = &dlg;
        dlg.DoModal();
        return FALSE;
    }
};

CSockApp theApp;
