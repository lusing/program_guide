// 17_serialize：可序列化的自定义类 + 版本化文件格式。
//
// 演示三层版本机制怎么配合：
//   1. 文档级 WORD 头（kFileVer）—— 整个文件格式的闸门，程序太旧打不开
//      新格式时在这里拒绝，而不是读到一半崩掉
//   2. 对象级 schema（IMPLEMENT_SERIAL 的版本号）—— CObject* 写入时
//      MFC 自动记录类名 + schema 号，CItem 自己在 Serialize 里用
//      GetObjectSchema() 查询，v1 文件没有 m_note 字段就跳过
//   3. ar << p / ar >> p —— 按类名反射创建，读代码不用认识具体类
//
// 文件布局：
//   [WORD kFileVer][int 条数][CItem* ×N]
//   每个 CItem* = [类名+schema][name][qty][price][note(仅 schema>=2)]
//
// 编译运行：.\build.ps1 -File 17_serialize

#include "resource.h"
#include <afxwin.h>
#include <afxtempl.h>

// ---------- 可序列化的自定义类 ----------
class CItem : public CObject {
    DECLARE_SERIAL(CItem)
public:
    // 反射创建必须走默认构造：ReadObject 先 new 再让对象自己 Serialize
    CItem() = default;
    CItem(LPCTSTR name, int qty, double price, LPCTSTR note)
        : m_name(name), m_qty(qty), m_price(price), m_note(note) {}

    void Serialize(CArchive& ar) override;

    CString m_name;
    int     m_qty   = 0;
    double  m_price = 0.0;
    CString m_note;   // v2 新增字段：旧文件里没有，读入时给默认值
};

// 末参是 schema 版本号。改成 2 表示"当前写出的是 v2 格式"；
// 读文件时流里记录的是"写文件那天的版本号"，两者都到得了 GetObjectSchema
IMPLEMENT_SERIAL(CItem, CObject, 2)

void CItem::Serialize(CArchive& ar) {
    CObject::Serialize(ar);          // 惯例：先调基类
    if (ar.IsStoring()) {
        ar << m_name << m_qty << m_price << m_note;
    } else {
        ar >> m_name >> m_qty >> m_price;
        // 只有读 CObject* 时 schema 才有效，且只能查一次。
        // v1 文件的流里没有 m_note，硬读会把后面的字节当字符串吞掉
        if (ar.GetObjectSchema() >= 2)
            ar >> m_note;
        else
            m_note = _T("（v1 文件，无备注）");
    }
}

// ---------- 文档：条目数组 + 文件头 ----------
class CShopDoc : public CDocument {
public:
    DECLARE_DYNCREATE(CShopDoc)

    static const WORD kFileVer = 2;   // 本程序能读写的最高文件格式版本

    CArray<CItem*, CItem*> m_items;
    int m_nextId = 1;

    // 框架在新建/打开/关闭文档前都会调 DeleteContents ——
    // 归文档所有的对象在这里释放，失败路径上也不会漏
    void DeleteContents() override {
        for (int i = 0; i < m_items.GetSize(); ++i)
            delete m_items[i];
        m_items.RemoveAll();
        m_nextId = 1;
    }

    BOOL OnNewDocument() override {
        if (!CDocument::OnNewDocument())
            return FALSE;
        SetModifiedFlag(FALSE);
        return TRUE;
    }

    // 条目数组的序列化：写个数 + 循环 ar << p。
    // ar << (CItem*)p 走 WriteObject：额外写类名和 schema 号，
    // 读回来时按类名反查 CRuntimeClass 再 new —— 读代码不用认识 CItem
    void Serialize(CArchive& ar) override {
        if (ar.IsStoring()) {
            ar << kFileVer;
            ar << (int)m_items.GetSize();
            for (int i = 0; i < m_items.GetSize(); ++i)
                ar << m_items[i];
        } else {
            WORD ver = 0;
            ar >> ver;
            if (ver > kFileVer)   // 文件比程序新：字段布局未知，趁早拒绝
                AfxThrowArchiveException(CArchiveException::badSchema);
            int n = 0;
            ar >> n;
            for (int i = 0; i < n; ++i) {
                CObject* p = nullptr;
                ar >> p;   // 注意：operator>> 只有 CObject*& 版本，
                           // 派生类指针要先放进 CObject* 再 static_cast
                m_items.Add(static_cast<CItem*>(p));
            }
        }
    }

    void AddSampleItem() {
        int n = m_nextId++;
        CString name;
        name.Format(_T("条目 %d"), n);
        m_items.Add(new CItem(name, (n * 7) % 20 + 1,
                              (n * 13 % 900) / 10.0 + 1.5, _T("")));
        SetModifiedFlag();
        UpdateAllViews(nullptr);
    }

    void ClearItems() {
        DeleteContents();   // 所有权在文档，清理也走同一个入口
        SetModifiedFlag();
        UpdateAllViews(nullptr);
    }
};

IMPLEMENT_DYNCREATE(CShopDoc, CDocument)

// ---------- 视图：列表显示条目 ----------
class CShopView : public CView {
public:
    DECLARE_DYNCREATE(CShopView)

    void OnDraw(CDC* /*pDC*/) override {}

    CShopDoc* GetDoc() const {
        return static_cast<CShopDoc*>(m_pDocument);
    }

    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        if (CView::OnCreate(lpCreateStruct) == -1)
            return -1;
        m_list.Create(WS_CHILD | WS_VISIBLE | WS_VSCROLL | LBS_NOINTEGRALHEIGHT,
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

    // 新建/打开/添加/清空全部汇聚到 OnUpdate 全量刷新 —— 列表很小，不值得精准刷新
    void OnUpdate(CView* /*pSender*/, LPARAM /*lHint*/, CObject* /*pHint*/) override {
        if (!GetDoc())
            return;
        m_list.ResetContent();
        for (int i = 0; i < GetDoc()->m_items.GetSize(); ++i) {
            const CItem* it = GetDoc()->m_items[i];
            CString line;
            line.Format(_T("%-10s  数量 %3d  单价 %8.2f  %s"),
                        (LPCTSTR)it->m_name, it->m_qty, it->m_price,
                        it->m_note.IsEmpty() ? _T("-") : (LPCTSTR)it->m_note);
            m_list.AddString(line);
        }
    }

    afx_msg void OnItemAdd() {
        if (GetDoc())
            GetDoc()->AddSampleItem();
    }

    afx_msg void OnItemClear() {
        if (GetDoc())
            GetDoc()->ClearItems();
    }

    DECLARE_MESSAGE_MAP()

private:
    CListBox m_list;
};

IMPLEMENT_DYNCREATE(CShopView, CView)

BEGIN_MESSAGE_MAP(CShopView, CView)
    ON_WM_CREATE()
    ON_WM_SIZE()
    ON_COMMAND(ID_ITEM_ADD, &CShopView::OnItemAdd)
    ON_COMMAND(ID_ITEM_CLEAR, &CShopView::OnItemClear)
END_MESSAGE_MAP()

// ---------- 主框架与应用：与第 15 章 SDI 相同的装配 ----------
class CMainFrame : public CFrameWnd {
public:
    DECLARE_DYNCREATE(CMainFrame)

    CMainFrame() = default;
};

IMPLEMENT_DYNCREATE(CMainFrame, CFrameWnd)

class CSerializeApp : public CWinApp {
public:
    BOOL InitInstance() override {
        auto* pTemplate = new CSingleDocTemplate(
            IDR_MAINFRAME,
            RUNTIME_CLASS(CShopDoc),
            RUNTIME_CLASS(CMainFrame),
            RUNTIME_CLASS(CShopView));
        AddDocTemplate(pTemplate);

        CCommandLineInfo cmdInfo;
        ParseCommandLine(cmdInfo);
        if (!ProcessShellCommand(cmdInfo))
            return FALSE;

        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CSerializeApp theApp;
