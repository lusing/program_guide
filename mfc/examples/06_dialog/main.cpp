// 06_dialog：对话框两种形态 + DDX 数据绑定。
//
// 模态（DoModal）：阻塞调用方，适合必须先回答的输入（登录、设置）。
// 非模态（Create + ShowWindow）：和主窗口共存，适合面板、监视窗。
//
// DDX（Dialog Data Exchange）：控件值 <-> C++ 成员变量自动同步，
// DDV（Dialog Data Validation）：自动校验取值范围。
//
// 编译运行：.\build.ps1 -File 06_dialog

#include "resource.h"
#include <afxwin.h>
#include <afxext.h>

// 非模态对话框销毁时通知主窗口的消息
#define WM_APP_INFO_CLOSED  (WM_APP + 1)

// ---------- 模态登录对话框 ----------
class CLoginDialog : public CDialog {
public:
    // DDX 绑定的成员变量：对话框打开时把控件值拷进来，
    // 点确定时把控件值拷出去 —— 调用方直接读这些成员即可。
    CString m_user;
    CString m_pass;
    BOOL m_remember = FALSE;

    enum { IDD = IDD_LOGIN };
    CLoginDialog(CWnd* parent = nullptr) : CDialog(IDD_LOGIN, parent) {}

protected:
    void DoDataExchange(CDataExchange* pDX) override {
        CDialog::DoDataExchange(pDX);
        DDX_Text(pDX, IDC_USER, m_user);
        DDX_Text(pDX, IDC_PASS, m_pass);
        DDX_Check(pDX, IDC_REMEMBER, m_remember);
        DDV_MaxChars(pDX, m_user, 32);   // 用户名最多 32 字符
        DDV_MaxChars(pDX, m_pass, 32);
    }

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();
        // “记住用户名”逻辑：如果调用方预先填了 m_user，勾上复选框
        m_remember = !m_user.IsEmpty();
        return TRUE;  // 返回 TRUE 表示焦点交给第一个 WS_TABSTOP 控件
    }

    // OnOK 覆写是自定义校验的挂点：校验不过就不关对话框
    void OnOK() override {
        // DoDataExchange(pDX, TRUE) 把控件值同步到成员变量（DDX_Save）
        UpdateData(TRUE);
        if (m_user.IsEmpty()) {
            MessageBox(_T("用户名不能为空"), _T("校验失败"), MB_ICONWARNING);
            GetDlgItem(IDC_USER)->SetFocus();
            return;  // 不调用 EndDialog，对话框保持打开
        }
        // 已经 UpdateData 过，这里直接 EndDialog
        EndDialog(IDOK);
    }
};

// ---------- 非模态信息窗口 ----------
// 非模态对话框有三个和模态不同的生死规则：
//   1. 用 Create() 而不是 DoModal()
//   2. 关闭要走 DestroyWindow()，而不是 EndDialog()
//   3. 堆上分配的要在 PostNcDestroy 里 delete this（CDialog 默认不删）
class CInfoDialog : public CDialog {
public:
    enum { IDD = IDD_INFO };
    explicit CInfoDialog(CWnd* parent) : CDialog(IDD_INFO, parent) {}

    BOOL Create(CWnd* parent) {
        return CDialog::Create(IDD_INFO, parent);
    }

    // 关闭（点 X / OnCancel）→ 销毁窗口；窗口销毁完 → delete this
    void OnCancel() override { DestroyWindow(); }
    void PostNcDestroy() override {
        // 先让主窗口把指针清空，再自我了断，避免悬挂指针
        if (GetOwner())
            GetOwner()->PostMessage(WM_APP_INFO_CLOSED);
        delete this;
    }

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();
        SetTimer(1, 1000, nullptr);  // 每秒刷新一次运行秒数
        return TRUE;
    }

    void OnTimer(UINT_PTR id) {  // afx_msg 消息处理函数，非虚函数
        if (id == 1) {
            __time64_t t = _time64(nullptr) - m_start;
            SetDlgItemInt(IDC_UPTIME, (UINT)t, FALSE);
        }
    }

private:
    __time64_t m_start = _time64(nullptr);

    DECLARE_MESSAGE_MAP()
};

BEGIN_MESSAGE_MAP(CInfoDialog, CDialog)
    ON_WM_TIMER()
END_MESSAGE_MAP()

// ---------- 主窗口 ----------
class CMainWindow : public CFrameWnd {
public:
    CMainWindow() {
        Create(NULL, _T("对话框演示"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 660, 420), nullptr,
               MAKEINTRESOURCE(IDR_MAIN_MENU));
    }

    ~CMainWindow() override {
        // 程序退出时若信息窗还开着：DestroyWindow 会触发
        // PostNcDestroy -> delete this，所以这里不直接 delete
        if (m_info)
            m_info->DestroyWindow();
    }

    afx_msg void OnDlgLogin() {
        CLoginDialog dlg(this);
        dlg.m_user = m_lastUser;          // 预填上次记住的用户名
        if (dlg.DoModal() != IDOK)
            return;                       // 取消：什么都不做

        if (dlg.m_remember)
            m_lastUser = dlg.m_user;
        else
            m_lastUser.Empty();

        CString msg;
        msg.Format(_T("用户 %s 已登录（密码长度 %d，记住用户名：%s）"),
                   dlg.m_user, dlg.m_pass.GetLength(),
                   dlg.m_remember ? _T("是") : _T("否"));
        MessageBox(msg, _T("登录结果"));
    }

    afx_msg void OnDlgInfo() {
        if (m_info) {              // 已经打开就置顶，避免重复创建
            m_info->SetForegroundWindow();
            return;
        }
        m_info = new CInfoDialog(this);
        if (m_info->Create(this)) {
            m_info->ShowWindow(SW_SHOW);
        } else {
            delete m_info;         // 创建失败要自己回收
            m_info = nullptr;
        }
    }

    // 非模态对话框销毁时通知主窗口清空指针
    afx_msg LRESULT OnInfoClosed(WPARAM, LPARAM) {
        m_info = nullptr;
        return 0;
    }

    DECLARE_MESSAGE_MAP()

private:
    CString m_lastUser;
    CInfoDialog* m_info = nullptr;
};

BEGIN_MESSAGE_MAP(CMainWindow, CFrameWnd)
    ON_COMMAND(IDM_DLG_LOGIN, OnDlgLogin)
    ON_COMMAND(IDM_DLG_INFO, OnDlgInfo)
END_MESSAGE_MAP()

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CMainWindow();
        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
