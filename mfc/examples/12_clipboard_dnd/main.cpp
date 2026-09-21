// 12_clipboard_dnd：系统剪贴板 + OLE 拖放。
//
//   1. 文本剪贴板   —— CF_UNICODETEXT 的写与读（GlobalAlloc + 所有权移交）
//   2. 拖入         —— COleDropTarget 四个回调，接收 CF_HDROP（从资源管理器拖文件）
//   3. 拖出         —— COleDataSource + CacheGlobalData + DoDragDrop
//
// 编译运行：.\build.ps1 -File 12_clipboard_dnd

#include "resource.h"
#include <afxwin.h>
#include <afxdlgs.h>
#include <afxole.h>    // COleDataSource / COleDropTarget / COleDataObject
                       // 它内部 include 了 afxdisp.h，AfxOleInit 也从这里来

// ------------------------------------------------- 剪贴板：RAII 锁

// 剪贴板是全局唯一资源，同一时刻只有一个进程能打开它。
// 用 RAII 保证任何分支（包括提前 return）都会 CloseClipboard。
class CClipboardLock {
public:
    explicit CClipboardLock(HWND owner = nullptr) {
        // 别的进程可能正占着剪贴板，重试几次再放弃
        for (int i = 0; i < 10; ++i) {
            if (::OpenClipboard(owner)) {
                m_open = true;
                return;
            }
            ::Sleep(20);
        }
    }
    ~CClipboardLock() {
        if (m_open)
            ::CloseClipboard();
    }
    bool IsOpen() const { return m_open; }

    CClipboardLock(const CClipboardLock&) = delete;
    CClipboardLock& operator=(const CClipboardLock&) = delete;

private:
    bool m_open = false;
};

// 写文本到剪贴板
static bool SetClipboardText(HWND owner, const CString& text) {
    CClipboardLock lock(owner);
    if (!lock.IsOpen())
        return false;

    ::EmptyClipboard();   // 清掉所有旧格式 —— 不只是文本

    // 必须用 GMEM_MOVEABLE：系统接管后要能移动这个内存块
    const size_t bytes = (static_cast<size_t>(text.GetLength()) + 1) * sizeof(wchar_t);
    HGLOBAL h = ::GlobalAlloc(GMEM_MOVEABLE, bytes);
    if (!h)
        return false;

    void* p = ::GlobalLock(h);
    if (!p) {
        ::GlobalFree(h);
        return false;
    }
    memcpy(p, static_cast<LPCWSTR>(text), bytes);
    ::GlobalUnlock(h);

    if (!::SetClipboardData(CF_UNICODETEXT, h)) {
        ::GlobalFree(h);   // 只有失败时这块内存还属于我们
        return false;
    }
    // 成功之后所有权移交给系统，绝不能再 GlobalFree（那是双重释放）
    return true;
}

// 从剪贴板读文本
static bool GetClipboardText(CString& out) {
    if (!::IsClipboardFormatAvailable(CF_UNICODETEXT))
        return false;

    CClipboardLock lock;
    if (!lock.IsOpen())
        return false;

    HANDLE h = ::GetClipboardData(CF_UNICODETEXT);
    if (!h)
        return false;

    const wchar_t* p = static_cast<const wchar_t*>(::GlobalLock(h));
    if (!p)
        return false;
    out = p;
    ::GlobalUnlock(h);   // 剪贴板上的数据不归我们，只解锁不释放
    return true;
}

// ------------------------------------------------- 拖放接收区

// 一块自己画的子窗口，当拖放目标的可视区域。
class CDropZone : public CWnd {
public:
    BOOL Create(CWnd* parent, UINT id, const CRect& rc) {
        LPCTSTR cls = AfxRegisterWndClass(CS_HREDRAW | CS_VREDRAW,
                                          ::LoadCursor(NULL, IDC_ARROW),
                                          (HBRUSH)(COLOR_WINDOW + 1));
        return CWnd::CreateEx(0, cls, NULL, WS_CHILD | WS_VISIBLE | WS_BORDER,
                              rc, parent, id);
    }

    // 拖拽悬停时高亮，给用户"这里能放"的即时反馈
    void SetHot(bool hot) {
        if (hot == m_hot)
            return;
        m_hot = hot;
        Invalidate();
    }

    afx_msg BOOL OnEraseBkgnd(CDC* pDC) {
        CRect rc;
        GetClientRect(&rc);
        pDC->FillSolidRect(rc, m_hot ? RGB(228, 248, 228) : RGB(250, 250, 250));
        return TRUE;   // 背景已处理，别让系统再擦一遍
    }

    afx_msg void OnPaint() {
        CPaintDC dc(this);
        CRect rc;
        GetClientRect(&rc);
        dc.SetBkMode(TRANSPARENT);
        dc.SetTextColor(m_hot ? RGB(20, 110, 20) : RGB(130, 130, 130));
        dc.DrawText(m_hot ? _T("松手即接收") : _T("（拖放接收区）"),
                    rc, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
    }

    DECLARE_MESSAGE_MAP()

private:
    bool m_hot = false;
};

BEGIN_MESSAGE_MAP(CDropZone, CWnd)
    ON_WM_ERASEBKGND()
    ON_WM_PAINT()
END_MESSAGE_MAP()

// ------------------------------------------------- COleDropTarget

// 四个回调的返回值不一样，这是最容易写错的地方：
//   OnDragEnter / OnDragOver / OnDragLeave -> DROPEFFECT（"允许什么操作"）
//   OnDrop                                 -> BOOL      （"我处理了没有"）
// OnDrop 写成 DROPEFFECT 会直接报 C2555。
class CDropTarget : public COleDropTarget {
public:
    // 拖放过程中要更新界面，所以持有一个接收区和一个"往哪写状态文字"的目标
    void SetUI(CDropZone* zone, CWnd* statusTarget, UINT statusId) {
        m_zone = zone;
        m_statusTarget = statusTarget;
        m_statusId = statusId;
    }

    DROPEFFECT OnDragEnter(CWnd*, COleDataObject* pData, DWORD, CPoint) override {
        // 只接文件。返回 DROPEFFECT_NONE，光标会变成"禁止"图标。
        const BOOL ok = pData->IsDataAvailable(CF_HDROP);
        SetHot(ok != FALSE);
        Status(ok ? _T("可以放下") : _T("这里只接收文件"));
        return ok ? DROPEFFECT_COPY : DROPEFFECT_NONE;
    }

    DROPEFFECT OnDragOver(CWnd*, COleDataObject* pData, DWORD, CPoint) override {
        return pData->IsDataAvailable(CF_HDROP) ? DROPEFFECT_COPY
                                                : DROPEFFECT_NONE;
    }

    void OnDragLeave(CWnd*) override {
        SetHot(false);
        Status(_T("拖拽已离开"));
    }

    BOOL OnDrop(CWnd*, COleDataObject* pData, DROPEFFECT, CPoint) override {
        SetHot(false);
        if (!pData->IsDataAvailable(CF_HDROP))
            return FALSE;

        HGLOBAL h = pData->GetGlobalData(CF_HDROP);
        if (!h)
            return FALSE;

        HDROP hDrop = static_cast<HDROP>(h);
        const UINT n = ::DragQueryFile(hDrop, 0xFFFFFFFF, nullptr, 0);  // 取个数

        CString msg;
        msg.Format(_T("收到 %u 个文件："), n);
        for (UINT i = 0; i < n; ++i) {
            TCHAR path[MAX_PATH] = { 0 };
            ::DragQueryFile(hDrop, i, path, MAX_PATH);
            msg += _T("\r\n  ");
            msg += path;
        }

        ::GlobalFree(h);   // GetGlobalData 返回的句柄归调用方
        Status(msg);
        return TRUE;       // 已处理
    }

private:
    void SetHot(bool hot) {
        if (m_zone)
            m_zone->SetHot(hot);
    }
    void Status(const CString& s) {
        if (m_statusTarget)
            m_statusTarget->SetDlgItemText(m_statusId, s);
    }

    CDropZone* m_zone = nullptr;
    CWnd* m_statusTarget = nullptr;
    UINT m_statusId = 0;
};

// ------------------------------------------------- 主对话框

class CMainDlg : public CDialog {
public:
    CMainDlg() : CDialog(IDD_MAIN) {}

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();

        // 占位静态框 -> 真正的拖放接收区
        CWnd* placeholder = GetDlgItem(IDC_DROPZONE);
        CRect rc;
        placeholder->GetWindowRect(&rc);
        ScreenToClient(&rc);
        placeholder->DestroyWindow();
        m_zone.Create(this, IDC_DROPZONE, rc);

        // 注册拖放目标。AfxOleInit() 没调过的话这里会失败。
        m_drop.SetUI(&m_zone, this, IDC_STATUS);
        if (!m_drop.Register(&m_zone))
            SetStatus(_T("拖放注册失败：InitInstance 里漏了 AfxOleInit()"));
        else
            SetStatus(_T("就绪"));

        SetDlgItemText(IDC_EDIT,
                       _T("选中这段文字，点「复制到剪贴板」，清空后再点「从剪贴板粘贴」。\r\n")
                       _T("也可以点「拖出去」，按住鼠标把它拖到记事本或别的程序里。"));
        return TRUE;
    }

    void SetStatus(const CString& s) { SetDlgItemText(IDC_STATUS, s); }

    afx_msg void OnCopy() {
        CString text;
        GetDlgItemText(IDC_EDIT, text);
        SetStatus(SetClipboardText(GetSafeHwnd(), text)
                      ? _T("已写入剪贴板（CF_UNICODETEXT）")
                      : _T("写入剪贴板失败：可能被别的进程占着"));
    }

    afx_msg void OnPaste() {
        CString text;
        if (GetClipboardText(text)) {
            SetDlgItemText(IDC_EDIT, text);
            SetStatus(_T("已从剪贴板读入"));
        } else {
            SetStatus(_T("剪贴板上没有 CF_UNICODETEXT 格式的数据"));
        }
    }

    afx_msg void OnDragOut() {
        CString text;
        GetDlgItemText(IDC_EDIT, text);
        if (text.IsEmpty()) {
            SetStatus(_T("没有可拖出的内容"));
            return;
        }

        const size_t bytes =
            (static_cast<size_t>(text.GetLength()) + 1) * sizeof(wchar_t);
        HGLOBAL h = ::GlobalAlloc(GMEM_MOVEABLE, bytes);
        if (!h)
            return;
        if (void* p = ::GlobalLock(h)) {
            memcpy(p, static_cast<LPCWSTR>(text), bytes);
            ::GlobalUnlock(h);
        }

        COleDataSource src;
        // CacheGlobalData 把句柄存进数据源的缓存（pUnkForRelease = NULL），
        // 数据源析构时 ReleaseStgMedium 会 GlobalFree 它 —— 之后我们不能再碰 h。
        src.CacheGlobalData(CF_UNICODETEXT, h);

        SetStatus(_T("拖拽进行中…"));
        // DoDragDrop 是阻塞的：它自己跑一个消息循环，返回时拖放已经结束
        const DROPEFFECT de = src.DoDragDrop(DROPEFFECT_COPY);
        SetStatus(de == DROPEFFECT_NONE ? _T("对方没有接收")
                                        : _T("对方已接收（复制）"));
    }

    DECLARE_MESSAGE_MAP()

private:
    CDropZone   m_zone;
    CDropTarget m_drop;   // 成员变量：必须活得比窗口久
};

BEGIN_MESSAGE_MAP(CMainDlg, CDialog)
    ON_BN_CLICKED(IDC_COPY, &CMainDlg::OnCopy)
    ON_BN_CLICKED(IDC_PASTE, &CMainDlg::OnPaste)
    ON_BN_CLICKED(IDC_DRAGOUT, &CMainDlg::OnDragOut)
END_MESSAGE_MAP()

// ------------------------------------------------- 应用

class CClipApp : public CWinApp {
public:
    BOOL InitInstance() override {
        // 拖放（COleDropTarget / COleDataSource）必须先初始化 OLE。
        // 忘了这一步，Register() 会失败，拖放完全不工作且不报错。
        if (!AfxOleInit())
            return FALSE;

        CMainDlg dlg;
        m_pMainWnd = &dlg;
        dlg.DoModal();
        return FALSE;
    }
};

CClipApp theApp;
