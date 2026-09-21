// 09_docview：SDI Doc/View 全流程。
//
// 核心思想：把"框架窗口 + 文档数据 + 显示视图"交给 CSingleDocTemplate 组装，
// 框架免费提供新建/打开/保存（菜单命令 ID_FILE_* 由 MFC 标准实现处理），
// 你只需要写两个函数：文档的 Serialize 和视图的 OnDraw/数据同步。
//
// 数据流：
//   CEdit 输入 --EN_CHANGE--> CDocument（SetModifiedFlag 标脏）
//   文件打开  --Serialize-->  CDocument --UpdateAllViews--> CView 刷新
//
// 编译运行：.\build.ps1 -File 09_docview

#include "resource.h"
#include <afxwin.h>

// ---------- 文档：只管数据 ----------
class CNoteDoc : public CDocument {
public:
    DECLARE_DYNCREATE(CNoteDoc)

    CString m_text;   // 文档的全部内容

    // 文档 <-> 文件的唯一通道。打开和保存都会走到这里。
    // 注意 CArchive << CString 写的是 MFC 二进制格式；为了让记事本能
    // 打开，这里手动写成 UTF-8（带 BOM）。
    void Serialize(CArchive& ar) override {
        CFile* f = ar.GetFile();

        if (ar.IsStoring()) {
            CT2A utf8(m_text, CP_UTF8);
            const BYTE bom[] = { 0xEF, 0xBB, 0xBF };
            f->Write(bom, sizeof(bom));
            f->Write((LPCSTR)utf8, (UINT)strlen((LPCSTR)utf8));
        } else {
            UINT len = (UINT)f->GetLength();
            if (len == 0) {
                m_text.Empty();
                return;
            }
            CByteArray bytes;
            bytes.SetSize(len);
            f->Read(bytes.GetData(), len);

            UINT codePage = CP_ACP;
            const BYTE* data = bytes.GetData();
            int offset = 0;
            if (len >= 3 && data[0] == 0xEF && data[1] == 0xBB &&
                data[2] == 0xBF) {
                codePage = CP_UTF8;
                offset = 3;
            } else if (len >= 2 && data[0] == 0xFF && data[1] == 0xFE) {
                m_text = CString(reinterpret_cast<const wchar_t*>(data + 2),
                                 (len - 2) / 2);
                return;
            }
            int wlen = MultiByteToWideChar(
                codePage, 0,
                reinterpret_cast<const char*>(data + offset), len - offset,
                nullptr, 0);
            MultiByteToWideChar(codePage, 0,
                                reinterpret_cast<const char*>(data + offset),
                                len - offset, m_text.GetBuffer(wlen), wlen);
            m_text.ReleaseBuffer(wlen);
        }
    }
};

IMPLEMENT_DYNCREATE(CNoteDoc, CDocument)

// ---------- 视图：只管显示和编辑 ----------
class CNoteView : public CView {
public:
    DECLARE_DYNCREATE(CNoteView)

    CNoteView() = default;

    // CView 的纯虚函数，必须实现。本例的显示交给子控件 m_edit，
    // 所以留空；绘图型视图（如画板）的数据渲染写在这里。
    void OnDraw(CDC* /*pDC*/) override {}

    CNoteDoc* GetDoc() const {
        return static_cast<CNoteDoc*>(m_pDocument);  // CView 的保护成员
    }

    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        if (CView::OnCreate(lpCreateStruct) == -1)
            return -1;
        m_edit.Create(WS_CHILD | WS_VISIBLE | WS_VSCROLL | WS_HSCROLL |
                          ES_MULTILINE | ES_AUTOVSCROLL | ES_AUTOHSCROLL,
                      CRect(0, 0, 0, 0), this, IDC_NOTE_EDIT);
        m_edit.SendMessage(WM_SETFONT,
                           (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);
        return 0;
    }

    afx_msg void OnSize(UINT nType, int cx, int cy) {
        CView::OnSize(nType, cx, cy);
        if (m_edit.GetSafeHwnd())
            m_edit.MoveWindow(0, 0, cx, cy);
    }

    // 文档被打开/新建/修改通知时调用：把文档内容同步到编辑框
    void OnUpdate(CView* pSender, LPARAM lHint, CObject* pHint) override {
        if (!GetDoc())
            return;
        m_updating = true;   // SetWindowText 会触发 EN_CHANGE，挡住回环
        m_edit.SetWindowText(GetDoc()->m_text);
        m_updating = false;
    }

    // 用户输入 -> 文档（编辑 -> 数据方向的同步）
    afx_msg void OnEditChange() {
        if (m_updating || !GetDoc())
            return;
        m_edit.GetWindowText(GetDoc()->m_text);
        GetDoc()->SetModifiedFlag();  // 标脏后：标题出现 *，关闭时会提示保存
    }

    DECLARE_MESSAGE_MAP()

private:
    CEdit m_edit;
    bool m_updating = false;
};

IMPLEMENT_DYNCREATE(CNoteView, CView)

BEGIN_MESSAGE_MAP(CNoteView, CView)
    ON_WM_CREATE()
    ON_WM_SIZE()
    ON_EN_CHANGE(IDC_NOTE_EDIT, OnEditChange)
END_MESSAGE_MAP()

// ---------- 主框架：SDI 下由框架实例化 ----------
class CMainFrame : public CFrameWnd {
public:
    DECLARE_DYNCREATE(CMainFrame)

    CMainFrame() = default;

    // LoadFrame 从 IDR_MAINFRAME 资源加载菜单、加速键和标题字符串
    BOOL LoadFrame(UINT nIDResource, DWORD dwDefaultStyle = WS_OVERLAPPEDWINDOW | FWS_ADDTOTITLE,
                   CWnd* pParentWnd = nullptr, CCreateContext* pContext = nullptr) {
        return CFrameWnd::LoadFrame(nIDResource, dwDefaultStyle,
                                    pParentWnd, pContext);
    }
};

IMPLEMENT_DYNCREATE(CMainFrame, CFrameWnd)

// ---------- 应用：把三类对象绑进 Doc 模板 ----------
class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        // 模板把 资源ID、文档类、框架类、视图类 四者绑定
        auto* pTemplate = new CSingleDocTemplate(
            IDR_MAINFRAME,
            RUNTIME_CLASS(CNoteDoc),
            RUNTIME_CLASS(CMainFrame),
            RUNTIME_CLASS(CNoteView));
        AddDocTemplate(pTemplate);

        // 处理命令行（拖文件到 exe 图标上会直接打开该文件）
        CCommandLineInfo cmdInfo;
        ParseCommandLine(cmdInfo);
        if (!ProcessShellCommand(cmdInfo))
            return FALSE;

        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
