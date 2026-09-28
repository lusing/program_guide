// 26_views_family：视图家族 —— 同一份文档，四种视图，运行时切换。
//
// CView 的四个常用派生（书1 第8 章）：
//   CScrollView   自带滚动条与虚拟画布（例32）
//   CFormView     对话框模板即视图，DDX 直接可用（例35 窗体视图）
//   CListView     内嵌 CListCtrl，报表视图一屏看全（例36 列表视图）
//   CRichEditView 内嵌 CRichEditCtrl，带格式的文本视图（书2 第12 章 RTF 编辑器的基础）
//
// 运行时切换视图的经典三步（SDI）：
//   1. 用 CCreateContext(m_pCurrentDoc) + CreateObject() 造新视图
//   2. SetActiveView 切过去
//   3. DestroyWindow 销毁旧视图（OnDestroy 里自动 RemoveView，文档计数不漏）
//
// 编译运行：.\build.ps1 -File 26_views_family

#include "resource.h"
#include <afxwin.h>      // CScrollView
#include <afxcview.h>    // CListView / CTreeView
#include <afxrich.h>     // CRichEditView
#include <afxext.h>      // CFormView

// ---------- 文档：一列“条目名 + 分值” ----------
struct Item {
    CString name;
    int points;
};

class CItemsDoc : public CDocument {
public:
    DECLARE_DYNCREATE(CItemsDoc)

    CArray<Item, const Item&> m_items;

    void AddItem(const CString& name, int points) {
        Item it{ name, points };
        m_items.Add(it);
        SetModifiedFlag();
        UpdateAllViews(nullptr);
    }

    // 简单的逐字段序列化（第 17 章深挖 CArchive，这里够用就行）
    void Serialize(CArchive& ar) override {
        if (ar.IsStoring()) {
            ar << (INT_PTR)m_items.GetCount();
            for (INT_PTR i = 0; i < m_items.GetCount(); i++) {
                ar << CString(m_items[(int)i].name);
                ar << (LONG)m_items[(int)i].points;
            }
        } else {
            INT_PTR n = 0;
            ar >> n;
            m_items.SetSize((INT_PTR)n);
            for (INT_PTR i = 0; i < n; i++) {
                ar >> m_items[(int)i].name;
                LONG pts = 0;
                ar >> pts;
                m_items[(int)i].points = (int)pts;
            }
        }
    }

    void DeleteContents() override {
        m_items.RemoveAll();
        CDocument::DeleteContents();
    }
};
IMPLEMENT_DYNCREATE(CItemsDoc, CDocument)

// ---------- 视图一：滚动视图（虚拟画布 1200x900，画大表格） ----------
class CItemScrollView : public CScrollView {
public:
    DECLARE_DYNCREATE(CItemScrollView)

    void OnInitialUpdate() override {
        CScrollView::OnInitialUpdate();
        SetScrollSizes(MM_TEXT, CSize(1200, 900));   // 虚拟画布：逻辑坐标
    }

    void OnDraw(CDC* pDC) override {
        CItemsDoc* pDoc = GetDocument();
        pDC->FillSolidRect(0, 0, 1200, 900, RGB(250, 250, 245));

        CFont font;
        font.CreatePointFont(140, _T("Microsoft YaHei"));
        CGdiObject* old = pDC->SelectObject(&font);

        pDC->SetTextColor(RGB(40, 40, 40));
        pDC->TextOut(30, 30, _T("CScrollView：整张虚拟画布 1200×900，拖滚动条看画布外的内容"));
        pDC->MoveTo(30, 70); pDC->LineTo(1170, 70);

        int y = 100;
        for (INT_PTR i = 0; i < pDoc->m_items.GetCount(); i++) {
            const Item& it = pDoc->m_items[(int)i];
            CString line;
            line.Format(_T("%03d   %s   %d 分"), (int)i + 1, (LPCTSTR)it.name, it.points);
            // 分值越大颜色越暖 —— 滚动视图自由绘制的例子
            int heat = min(255, 80 + it.points * 8);
            pDC->SetTextColor(RGB(40, 40, heat));
            pDC->TextOut(60, y, line);
            y += 34;
        }
        pDC->SelectObject(old);
    }

    void OnUpdate(CView* pSender, LPARAM, CObject*) override {
        Invalidate(FALSE);        // 文档变了：只重绘客户区，不擦背景防闪烁
    }

    CItemsDoc* GetDocument() const {
        return static_cast<CItemsDoc*>(m_pDocument);
    }
};
IMPLEMENT_DYNCREATE(CItemScrollView, CScrollView)

// ---------- 视图二：窗体视图（对话框模板 + DDX） ----------
class CItemFormView : public CFormView {
public:
    DECLARE_DYNCREATE(CItemFormView)

    CItemFormView() : CFormView(IDD_FORM_VIEW) {}

    void DoDataExchange(CDataExchange* pDX) override {
        CFormView::DoDataExchange(pDX);
        DDX_Text(pDX, IDC_FORM_NAME, m_name);
        DDX_Text(pDX, IDC_FORM_POINTS, m_points);
        DDV_MinMaxInt(pDX, m_points, 0, 100);
    }

    void OnAdd() {
        if (!UpdateData(TRUE))    // DDX 校验失败（分值越界）时 MFC 已弹提示
            return;
        if (m_name.IsEmpty())
            return;
        GetDocument()->AddItem(m_name, m_points);
        m_name.Empty();
        m_points = 10;
        UpdateData(FALSE);
    }

    void OnInitialUpdate() override {
        CFormView::OnInitialUpdate();
        GetParentFrame()->RecalcLayout();
        ResizeParentToFit(FALSE);   // 窗体视图的经典动作：让框架适配模板尺寸
    }

    CItemsDoc* GetDocument() const {
        return static_cast<CItemsDoc*>(m_pDocument);
    }

    CString m_name;
    int m_points = 10;

    DECLARE_MESSAGE_MAP()
};
IMPLEMENT_DYNCREATE(CItemFormView, CFormView)

BEGIN_MESSAGE_MAP(CItemFormView, CFormView)
    ON_BN_CLICKED(IDC_FORM_ADD, OnAdd)
END_MESSAGE_MAP()

// ---------- 视图三：列表视图（内嵌 CListCtrl，报表样式） ----------
class CItemListView : public CListView {
public:
    DECLARE_DYNCREATE(CItemListView)

    void OnInitialUpdate() override {
        CListView::OnInitialUpdate();
        CListCtrl& lc = GetListCtrl();
        lc.SetExtendedStyle(lc.GetExtendedStyle() | LVS_EX_FULLROWSELECT |
                            LVS_EX_GRIDLINES | LVS_EX_DOUBLEBUFFER);
        lc.InsertColumn(0, _T("#"), LVCFMT_RIGHT, 48);
        lc.InsertColumn(1, _T("条目"), LVCFMT_LEFT, 200);
        lc.InsertColumn(2, _T("分值"), LVCFMT_RIGHT, 70);
        FillList();
    }

    void OnUpdate(CView* pSender, LPARAM lHint, CObject* pHint) override {
        FillList();    // 任何视图改了文档都会走到这（还有窗体视图的“添加”）
    }

    CItemsDoc* GetDocument() const {
        return static_cast<CItemsDoc*>(m_pDocument);
    }

private:
    void FillList() {
        CListCtrl& lc = GetListCtrl();
        lc.DeleteAllItems();
        CItemsDoc* pDoc = GetDocument();
        for (INT_PTR i = 0; i < pDoc->m_items.GetCount(); i++) {
            const Item& it = pDoc->m_items[(int)i];
            CString idx;
            idx.Format(_T("%d"), (int)i + 1);
            lc.InsertItem((int)i, idx);
            lc.SetItemText((int)i, 1, it.name);
            CString pts;
            pts.Format(_T("%d"), it.points);
            lc.SetItemText((int)i, 2, pts);
        }
    }
};
IMPLEMENT_DYNCREATE(CItemListView, CListView)

// ---------- 视图四：富文本视图（彩色统计报告） ----------
class CItemRichView : public CRichEditView {
public:
    DECLARE_DYNCREATE(CItemRichView)

    void OnInitialUpdate() override {
        CRichEditView::OnInitialUpdate();
        Rebuild();
    }

    void OnUpdate(CView*, LPARAM, CObject*) override {
        Rebuild();
    }

    CItemsDoc* GetDocument() const {
        return static_cast<CItemsDoc*>(m_pDocument);
    }

private:
    void Rebuild() {
        CItemsDoc* pDoc = GetDocument();
        CRichEditCtrl& re = GetRichEditCtrl();

        // CHARFORMAT2 上色：标题蓝、统计绿、条目黑
        CHARFORMAT2 cf = {};
        cf.cbSize = sizeof(cf);
        cf.dwMask = CFM_COLOR | CFM_BOLD | CFM_SIZE | CFM_FACE | CFM_CHARSET;
        cf.dwEffects = CFE_BOLD;
        cf.yHeight = 260;
        cf.crTextColor = RGB(31, 78, 146);
        cf.bCharSet = GB2312_CHARSET;
        lstrcpyn(cf.szFaceName, _T("Microsoft YaHei"), LF_FACESIZE);

        re.SetWindowText(_T(""));
        SetFormat(cf);
        re.ReplaceSel(_T("CRichEditView：条目统计报告\r\n\r\n"));

        cf.dwEffects = 0;
        cf.yHeight = 200;
        cf.crTextColor = RGB(24, 120, 90);
        SetFormat(cf);
        CString stat;
        stat.Format(_T("共 %d 条，总分 %d，平均 %.1f 分\r\n\r\n"),
                    (int)pDoc->m_items.GetCount(), TotalPoints(), Average());
        re.ReplaceSel(stat);

        cf.crTextColor = RGB(50, 50, 50);
        SetFormat(cf);
        for (INT_PTR i = 0; i < pDoc->m_items.GetCount(); i++) {
            const Item& it = pDoc->m_items[(int)i];
            CString line;
            line.Format(_T("• %s —— %d 分\r\n"), (LPCTSTR)it.name, it.points);
            re.ReplaceSel(line);
        }
        // 只读报告：锁编辑（RichEditView 的 SetReadOnly 走控制条状态，直接对控件设）
        GetRichEditCtrl().SetReadOnly(TRUE);
    }

    void SetFormat(CHARFORMAT2& cf) {
        GetRichEditCtrl().SetSel(0, -1);          // 全选后再设才稳定
        GetRichEditCtrl().SetSelectionCharFormat(cf);
        GetRichEditCtrl().SetSel(-1, -1);         // 光标移到末尾，ReplaceSel 追加
    }

    int TotalPoints() const {
        int t = 0;
        CItemsDoc* pDoc = GetDocument();
        for (INT_PTR i = 0; i < pDoc->m_items.GetCount(); i++)
            t += pDoc->m_items[(int)i].points;
        return t;
    }

    double Average() const {
        INT_PTR n = GetDocument()->m_items.GetCount();
        return n ? (double)TotalPoints() / n : 0.0;
    }
};
IMPLEMENT_DYNCREATE(CItemRichView, CRichEditView)

// ---------- 框架：持着“当前视图索引”，负责切换 ----------
class CMainFrame : public CFrameWnd {
public:
    static constexpr int kViewCount = 4;
    static CRuntimeClass* const kViewClasses[kViewCount];

    CMainFrame() {
        Create(nullptr, nullptr, WS_OVERLAPPEDWINDOW, CRect(80, 80, 900, 640),
               nullptr, MAKEINTRESOURCE(IDR_MAINFRAME));
    }

    // 运行时切换：文档不动，只换“看它的方式”
    void SwitchToView(int idx) {
        if (idx == m_curView || idx < 0 || idx >= kViewCount)
            return;
        CView* pOld = GetActiveView();
        if (!pOld)
            return;

        CCreateContext cx;
        cx.m_pNewViewClass = kViewClasses[idx];
        cx.m_pCurrentDoc = pOld->GetDocument();

        CView* pNew = static_cast<CView*>(kViewClasses[idx]->CreateObject());
        if (!pNew)
            return;

        // AFX_IDW_PANE_FIRST：视图在框架里的标准 ID（切分窗口 pane 0 用的也是它）
        if (!pNew->Create(nullptr, nullptr, AFX_WS_DEFAULT_VIEW, CRect(0, 0, 0, 0),
                          this, AFX_IDW_PANE_FIRST, &cx)) {
            pNew->DestroyWindow();
            return;
        }
        // CView::OnCreate 已经按 create context 调过 AddView；这里补初始更新
        pNew->OnInitialUpdate();
        SetActiveView(pNew);
        pOld->DestroyWindow();     // OnDestroy -> RemoveView，文档引用数不泄漏
        RecalcLayout();
        m_curView = idx;
    }

    afx_msg void OnViewScroll() { SwitchToView(0); }
    afx_msg void OnViewForm()   { SwitchToView(1); }
    afx_msg void OnViewList()   { SwitchToView(2); }
    afx_msg void OnViewRich()   { SwitchToView(3); }

    // 单选打点：一个 ON_UPDATE_COMMAND_UI 同时管四项
    afx_msg void OnUpdateViewMode(CCmdUI* pCmdUI) {
        int idx = pCmdUI->m_nID == ID_VIEW_SCROLLVIEW ? 0
                : pCmdUI->m_nID == ID_VIEW_FORMVIEW   ? 1
                : pCmdUI->m_nID == ID_VIEW_LISTVIEW   ? 2 : 3;
        pCmdUI->SetRadio(idx == m_curView);
        pCmdUI->Enable(TRUE);
    }

    DECLARE_MESSAGE_MAP()
private:
    int m_curView = 0;
};

CRuntimeClass* const CMainFrame::kViewClasses[] = {
    RUNTIME_CLASS(CItemScrollView), RUNTIME_CLASS(CItemFormView),
    RUNTIME_CLASS(CItemListView),   RUNTIME_CLASS(CItemRichView),
};

BEGIN_MESSAGE_MAP(CMainFrame, CFrameWnd)
    ON_COMMAND(ID_VIEW_SCROLLVIEW, OnViewScroll)
    ON_COMMAND(ID_VIEW_FORMVIEW, OnViewForm)
    ON_COMMAND(ID_VIEW_LISTVIEW, OnViewList)
    ON_COMMAND(ID_VIEW_RICHVIEW, OnViewRich)
    ON_UPDATE_COMMAND_UI(ID_VIEW_SCROLLVIEW, OnUpdateViewMode)
    ON_UPDATE_COMMAND_UI(ID_VIEW_FORMVIEW, OnUpdateViewMode)
    ON_UPDATE_COMMAND_UI(ID_VIEW_LISTVIEW, OnUpdateViewMode)
    ON_UPDATE_COMMAND_UI(ID_VIEW_RICHVIEW, OnUpdateViewMode)
END_MESSAGE_MAP()

// ---------- 应用：SDI 模板以滚动视图启动 ----------
class CViewsApp : public CWinApp {
public:
    BOOL InitInstance() override {
        AfxInitRichEdit2();     // CRichEditView 的前置条件，忘了它富文本视图一片空白

        CSingleDocTemplate* pDoc = new CSingleDocTemplate(
            IDR_MAINFRAME, RUNTIME_CLASS(CItemsDoc), RUNTIME_CLASS(CMainFrame),
            RUNTIME_CLASS(CItemScrollView));
        AddDocTemplate(pDoc);

        OnFileNew();
        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CViewsApp theApp;
