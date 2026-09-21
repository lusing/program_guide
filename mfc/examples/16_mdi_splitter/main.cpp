// 16_mdi_splitter：MDI 多文档 + CSplitterWnd 左右分栏。
//
// 与第 15 章 SDI 的三个差别：
//   1. 模板换成 CMultiDocTemplate，框架类换成 CMDIFrameWnd / CMDIChildWnd
//   2. 资源分两套：IDR_MAINFRAME（外壳菜单/标题）+ IDR_MDITYPE（文档类型的
//      菜单/加速键/9 字段串），子窗口激活时框架自动切换菜单
//   3. 子框架在 OnCreateClient 里用 CSplitterWnd 分出左右两个视图，
//      两个视图共享同一份文档 —— 左边列表选条目，右边编辑详情
//
// 数据流（视图各自不存数据，同步唯一入口是文档广播）：
//   左视图选中 ──► doc.m_sel ──► UpdateAllViews(this, HINT_SEL)
//                                        │ 广播（排除发送者自己）
//                                        ▼
//                            右视图 OnUpdate ──► 从文档读选中条目的详情
//   右视图编辑 ──► doc.detail ──► UpdateAllViews(this, HINT_DETAIL)
//                                        └──► 左视图忽略（与列表无关）
//
// 编译运行：.\build.ps1 -File 16_mdi_splitter

#include "resource.h"
#include <afxwin.h>
#include <afxext.h>     // CSplitterWnd
#include <afxtempl.h>   // CArray

// OnUpdate 的 lHint 提示值：文档广播时带上，各视图按提示决定刷新范围
enum { HINT_SEL = 1, HINT_DETAIL = 2 };

// ---------- 文档：只管数据 ----------
struct Item {
    CString name;     // 列表里显示的名字
    CString detail;   // 右侧编辑的详情
};

class CMdiDoc : public CDocument {
public:
    DECLARE_DYNCREATE(CMdiDoc)

    CArray<Item, Item&> m_items;
    int m_sel = -1;   // 当前选中下标（视图的"UI 状态"放文档里，多个视图共享）

    // Serialize 暂未实现 —— 本例菜单没有打开/保存，第 17 章补上。
    // CDocument::Serialize 是带空实现的虚函数，不写也能编译。
    BOOL OnNewDocument() override {
        if (!CDocument::OnNewDocument())
            return FALSE;
        m_items.RemoveAll();
        static const TCHAR* kNames[] = {
            _T("条目一"), _T("条目二"), _T("条目三"), _T("条目四"), _T("条目五")
        };
        for (int i = 0; i < 5; ++i) {
            Item it;
            it.name = kNames[i];
            it.detail.Format(_T("这是%s的详情。\r\n")
                             _T("在这里编辑，内容会写回文档并标脏。"), kNames[i]);
            m_items.Add(it);
        }
        m_sel = 0;
        SetModifiedFlag(FALSE);   // 新建 ≠ 脏
        return TRUE;
    }
};

IMPLEMENT_DYNCREATE(CMdiDoc, CDocument)

// ---------- 左视图：条目列表，负责"选谁" ----------
class CLeftView : public CView {
public:
    DECLARE_DYNCREATE(CLeftView)

    void OnDraw(CDC* /*pDC*/) override {}   // CView 纯虚函数；显示交给 m_list

    CMdiDoc* GetDoc() const {
        return static_cast<CMdiDoc*>(m_pDocument);
    }

    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        if (CView::OnCreate(lpCreateStruct) == -1)
            return -1;
        m_list.Create(WS_CHILD | WS_VISIBLE | WS_VSCROLL | LBS_NOTIFY,
                      CRect(0, 0, 0, 0), this, IDC_ITEMLIST);
        m_list.SendMessage(WM_SETFONT,
                           (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);
        return 0;
    }

    afx_msg void OnSize(UINT nType, int cx, int cy) {
        CView::OnSize(nType, cx, cy);
        if (m_list.GetSafeHwnd())
            m_list.MoveWindow(0, 0, cx, cy);
    }

    void OnInitialUpdate() override {
        CView::OnInitialUpdate();
        RefillList();
    }

    // 只处理全量刷新（新建/打开文档时框架触发，lHint == 0）。
    // HINT_SEL 不会到达这里：选择变化只发生在左视图，而广播排除了发送者；
    // HINT_DETAIL 与列表无关，直接忽略。
    void OnUpdate(CView* /*pSender*/, LPARAM lHint, CObject* /*pHint*/) override {
        if (!GetDoc() || lHint != 0)
            return;
        RefillList();
    }

    afx_msg void OnSelChange() {
        if (!GetDoc())
            return;
        int i = m_list.GetCurSel();
        if (i < 0)
            return;
        GetDoc()->m_sel = i;
        // 广播排除发送者 —— 右视图收到 HINT_SEL 后去读新选中项
        GetDoc()->UpdateAllViews(this, HINT_SEL);
    }

    DECLARE_MESSAGE_MAP()

private:
    CListBox m_list;

    void RefillList() {
        m_list.ResetContent();
        CMdiDoc* pDoc = GetDoc();
        if (!pDoc)
            return;
        for (int i = 0; i < pDoc->m_items.GetSize(); ++i)
            m_list.AddString(pDoc->m_items[i].name);
        if (pDoc->m_sel >= 0)
            m_list.SetCurSel(pDoc->m_sel);   // SetCurSel 不发 LBN_SELCHANGE，无回环
    }
};

IMPLEMENT_DYNCREATE(CLeftView, CView)

BEGIN_MESSAGE_MAP(CLeftView, CView)
    ON_WM_CREATE()
    ON_WM_SIZE()
    ON_LBN_SELCHANGE(IDC_ITEMLIST, &CLeftView::OnSelChange)
END_MESSAGE_MAP()

// ---------- 右视图：详情编辑，负责"显示/编辑谁" ----------
class CRightView : public CView {
public:
    DECLARE_DYNCREATE(CRightView)

    void OnDraw(CDC* /*pDC*/) override {}

    CMdiDoc* GetDoc() const {
        return static_cast<CMdiDoc*>(m_pDocument);
    }

    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        if (CView::OnCreate(lpCreateStruct) == -1)
            return -1;
        m_edit.Create(WS_CHILD | WS_VISIBLE | WS_VSCROLL | ES_MULTILINE |
                          ES_AUTOVSCROLL | ES_WANTRETURN,
                      CRect(0, 0, 0, 0), this, IDC_DETAIL);
        m_edit.SendMessage(WM_SETFONT,
                           (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);
        return 0;
    }

    afx_msg void OnSize(UINT nType, int cx, int cy) {
        CView::OnSize(nType, cx, cy);
        if (m_edit.GetSafeHwnd())
            m_edit.MoveWindow(0, 0, cx, cy);
    }

    // HINT_SEL（换选中项）和全量刷新都走这里：从文档把详情搬进编辑框。
    // 注意 HINT_DETAIL 永远到不了 —— 那是自己发出的广播，UpdateAllViews(this)
    // 会排除发送者，编辑时不会自己刷新自己。
    void OnUpdate(CView* /*pSender*/, LPARAM /*lHint*/, CObject* /*pHint*/) override {
        if (!GetDoc())
            return;
        m_updating = true;   // SetWindowText 触发 EN_CHANGE，挡住回环
        int sel = GetDoc()->m_sel;
        if (sel >= 0 && sel < GetDoc()->m_items.GetSize())
            m_edit.SetWindowText(GetDoc()->m_items[sel].detail);
        else
            m_edit.SetWindowText(_T(""));
        m_updating = false;
    }

    // 用户编辑 -> 文档（编辑 -> 数据方向的同步）
    afx_msg void OnEditChange() {
        if (m_updating || !GetDoc())
            return;
        int sel = GetDoc()->m_sel;
        if (sel < 0 || sel >= GetDoc()->m_items.GetSize())
            return;
        m_edit.GetWindowText(GetDoc()->m_items[sel].detail);
        GetDoc()->SetModifiedFlag();   // 标题加 *，关闭时询问保存
        GetDoc()->UpdateAllViews(this, HINT_DETAIL);   // 左视图会忽略
    }

    DECLARE_MESSAGE_MAP()

private:
    CEdit m_edit;
    bool m_updating = false;
};

IMPLEMENT_DYNCREATE(CRightView, CView)

BEGIN_MESSAGE_MAP(CRightView, CView)
    ON_WM_CREATE()
    ON_WM_SIZE()
    ON_EN_CHANGE(IDC_DETAIL, &CRightView::OnEditChange)
END_MESSAGE_MAP()

// ---------- 子框架：一个 MDI 子窗口 = 一个文档 + 一对视图 ----------
class CChildFrame : public CMDIChildWnd {
public:
    DECLARE_DYNCREATE(CChildFrame)

    CChildFrame() = default;

    // 框架创建子窗口后回调这里，pContext 携带"文档 <-> 视图"的绑定关系。
    // 必须把这个参数原样传给 CreateView —— 自己传 NULL 的话，
    // 视图里 GetDocument() 返回 NULL，一访问就崩。
    BOOL OnCreateClient(LPCREATESTRUCT lpcs, CCreateContext* pContext) override {
        if (!m_split.CreateStatic(this, 1, 2))     // 1 行 2 列的静态分割
            return FALSE;
        if (!m_split.CreateView(0, 0, RUNTIME_CLASS(CLeftView),
                                CSize(200, 0), pContext))
            return FALSE;
        if (!m_split.CreateView(0, 1, RUNTIME_CLASS(CRightView),
                                CSize(0, 0), pContext))
            return FALSE;
        // 理想宽度 220px、最小 100px（CreateView 的 CSize 只给初始值，
        // 想设最小值/精确调整要用 SetColumnInfo + RecalcLayout）
        m_split.SetColumnInfo(0, 220, 100);
        m_split.RecalcLayout();
        return TRUE;
    }

    CSplitterWnd m_split;
};

IMPLEMENT_DYNCREATE(CChildFrame, CMDIChildWnd)

// ---------- 主框架：MDI 外壳 ----------
class CMainFrame : public CMDIFrameWnd {
public:
    DECLARE_DYNCREATE(CMainFrame)

    CMainFrame() = default;

    // LoadFrame 从 IDR_MAINFRAME 加载外壳菜单、加速键和标题
    BOOL LoadFrame(UINT nIDResource,
                   DWORD dwDefaultStyle = WS_OVERLAPPEDWINDOW | FWS_ADDTOTITLE,
                   CWnd* pParentWnd = nullptr,
                   CCreateContext* pContext = nullptr) {
        return CMDIFrameWnd::LoadFrame(nIDResource, dwDefaultStyle,
                                       pParentWnd, pContext);
    }
};

IMPLEMENT_DYNCREATE(CMainFrame, CMDIFrameWnd)

// ---------- 应用：装配模板 + 外壳 + 第一个文档 ----------
class CMdiApp : public CWinApp {
public:
    BOOL InitInstance() override {
        // 模板第 4 个参数是"默认视图类"——本例子框架重写了 OnCreateClient
        // 自己分栏，这个参数实际不被用到；没重写时框架拿它创建整个客户区视图
        auto* pTemplate = new CMultiDocTemplate(
            IDR_MDITYPE,
            RUNTIME_CLASS(CMdiDoc),
            RUNTIME_CLASS(CChildFrame),
            RUNTIME_CLASS(CLeftView));
        AddDocTemplate(pTemplate);

        // MDI 的主窗口是外壳，先创建并显示它
        auto* pFrame = new CMainFrame;
        m_pMainWnd = pFrame;
        if (!pFrame->LoadFrame(IDR_MAINFRAME))
            return FALSE;
        pFrame->ShowWindow(m_nCmdShow);
        pFrame->UpdateWindow();

        // 再创建第一个文档（New 时框架按模板链创建文档+子框架+视图；
        // 只有一个模板时不需要用户选择）。没有命令行打开文件的需求，
        // 就不走 SDI 那套 ProcessShellCommand
        OnFileNew();
        return TRUE;
    }
};

CMdiApp theApp;
