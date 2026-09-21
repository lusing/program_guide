// 19_printing：打印与打印预览。
//
// 核心思想：打印 = 在打印机 DC 上重放一遍绘制逻辑。
// 把绘制抽成纯函数 DrawPage(CDC&, CRect, page)（只读数据、只画、无副作用），
// 屏幕绘制和打印分页就都调它：
//
//   OnDraw （屏幕）  ──► DrawPage(dc, 客户区, 1)
//   OnPrint（打印/预览，每页一次）──► DrawPage(dc, m_rectDraw, m_nCurPage)
//
// 框架的打印时序（CPrintInfo 串起来）：
//   OnPreparePrinting（弹打印对话框）
//     → OnBeginPrinting（建打印字体 + 算总页数 SetMaxPage）
//       → OnPrint × N（m_nCurPage = 1..N，逐页画）
//         → OnEndPrinting（释放打印字体）
//
// ID_FILE_PRINT / ID_FILE_PRINT_PREVIEW / ID_FILE_PRINT_SETUP 由
// CView 和 CWinApp 的标准实现处理，菜单摆上 ID 即可。
//
// 编译运行：.\build.ps1 -File 19_printing

#include "resource.h"
#include <afxwin.h>
#include <afxext.h>   // CPrintInfo（afxwin.h 里只有前置声明）

// ---------- 文档：报表数据 ----------
class CReportDoc : public CDocument {
public:
    DECLARE_DYNCREATE(CReportDoc)

    CStringArray m_rows;

    BOOL OnNewDocument() override {
        if (!CDocument::OnNewDocument())
            return FALSE;
        m_rows.RemoveAll();
        for (int i = 1; i <= 57; ++i) {   // 57 行：屏幕一页放不下，打印必分页
            CString line;
            line.Format(_T("记录 %03d      数量 %4d      金额 %10.2f"),
                        i, (i * 7) % 90 + 10, (i * 131 % 9000) / 100.0 + 5.0);
            m_rows.Add(line);
        }
        SetModifiedFlag(FALSE);
        return TRUE;
    }
};

IMPLEMENT_DYNCREATE(CReportDoc, CDocument)

// ---------- 视图：屏幕绘制 + 打印 ----------
class CReportView : public CView {
public:
    DECLARE_DYNCREATE(CReportView)

    CReportView() = default;

    CReportDoc* GetDoc() const {
        return static_cast<CReportDoc*>(m_pDocument);
    }

    // ---- 每页行数：标题占 1 行 + 页脚占 1 行，行高 = 1/4 英寸 ----
    // 屏幕和打印机 DC 各自知道自己的 DPI（GetDeviceCaps），
    // 同一个函数在两边算出各自正确的值 —— 这是不写死像素的关键
    static int RowsPerPage(CDC& dc, int pageH) {
        const int rowH = dc.GetDeviceCaps(LOGPIXELSY) / 4;
        return rowH > 0 ? (pageH - 2 * rowH) / rowH : 0;
    }

    // ---- 共用绘制函数：唯一的绘制实现，屏幕/打印/预览都走这里 ----
    // 纪律：只读文档数据、只往 dc 画，不改任何状态 —— 预览会反复调它
    void DrawPage(CDC& dc, const CRect& rc, int page) {
        CReportDoc* pDoc = GetDoc();
        if (!pDoc)
            return;
        const int rowH = dc.GetDeviceCaps(LOGPIXELSY) / 4;

        CFont* oldFont = dc.SelectObject(dc.IsPrinting() && m_pPrintFont
                                             ? m_pPrintFont
                                             : &m_screenFont);
        dc.SetBkMode(TRANSPARENT);

        // 标题：屏幕用彩色，打印用黑白（打印机多半是黑白的）
        if (dc.IsPrinting())
            dc.SetTextColor(RGB(0, 0, 0));
        else
            dc.SetTextColor(RGB(0, 90, 160));
        CString title;
        title.Format(_T("销售报表 —— 第 %d 页"), page);
        dc.TextOut(rc.left + rowH / 4, rc.top + rowH / 4, title);

        dc.SetTextColor(RGB(0, 0, 0));

        // 表格行：第 page 页的数据行
        const int rowsPerPage = RowsPerPage(dc, rc.Height());
        const int first = (page - 1) * rowsPerPage;
        int y = rc.top + rowH;      // 标题行之下
        for (int i = 0; i < rowsPerPage; ++i) {
            const int idx = first + i;
            if (idx >= pDoc->m_rows.GetSize())
                break;
            dc.TextOut(rc.left + rowH / 4, y, pDoc->m_rows[idx]);
            y += rowH;
        }

        // 页脚
        const int total = (static_cast<int>(pDoc->m_rows.GetSize()) + rowsPerPage - 1) / rowsPerPage;
        CString foot;
        foot.Format(_T("第 %d 页，共 %d 页"), page, total);
        dc.TextOut(rc.left + rowH / 4, rc.bottom - rowH, foot);

        dc.SelectObject(oldFont);
    }

    // ---- 屏幕：画第 1 页（完整分页看打印预览）----
    void OnDraw(CDC* pDC) override {
        CRect rc;
        GetClientRect(&rc);
        if (rc.IsRectEmpty())
            return;
        DrawPage(*pDC, rc, 1);
    }

    // ---- 打印五重写点 ----

    // ① 弹打印对话框、创建打印机 DC。忘了 return DoPreparePrinting，
    //    对话框根本不弹，后续流程全不走
    BOOL OnPreparePrinting(CPrintInfo* pInfo) override {
        return DoPreparePrinting(pInfo);
    }

    // ② 打印开始：建打印专用字体（用打印机 DC 定字号）+ 算总页数。
    //    此时才第一次有打印机 DC，所以分页计算放这里，不是 OnPrint
    void OnBeginPrinting(CDC* pDC, CPrintInfo* pInfo) override {
        m_pPrintFont = new CFont;
        m_pPrintFont->CreatePointFont(90, _T("宋体"), pDC);   // 9 磅，按打印机 DPI 换算

        const int nRows  = static_cast<int>(GetDoc()->m_rows.GetSize());
        const int perPage = RowsPerPage(*pDC, pDC->GetDeviceCaps(VERTRES));
        const int pages  = (nRows + perPage - 1) / perPage;
        pInfo->SetMaxPage(pages ? pages : 1);   // 不设的话只打一页
    }

    // ③ 每页一次：m_rectDraw 是该页可打印区域，m_nCurPage 是当前页号
    void OnPrint(CDC* pDC, CPrintInfo* pInfo) override {
        DrawPage(*pDC, pInfo->m_rectDraw, pInfo->m_nCurPage);
    }

    // ④ 打印结束：释放 ② 建的资源
    void OnEndPrinting(CDC* /*pDC*/, CPrintInfo* /*pInfo*/) override {
        delete m_pPrintFont;
        m_pPrintFont = nullptr;
    }

    afx_msg int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        if (CView::OnCreate(lpCreateStruct) == -1)
            return -1;
        // 屏幕字体：CreatePointFont 不传 DC 时按屏幕 DPI 换算
        m_screenFont.CreatePointFont(90, _T("宋体"));
        return 0;
    }

    DECLARE_MESSAGE_MAP()

private:
    CFont  m_screenFont;      // 屏幕用
    CFont* m_pPrintFont = nullptr;   // 打印用：OnBeginPrinting 建，OnEndPrinting 删
};

IMPLEMENT_DYNCREATE(CReportView, CView)

BEGIN_MESSAGE_MAP(CReportView, CView)
    ON_WM_CREATE()
    // ID_FILE_PRINT / ID_FILE_PRINT_PREVIEW 不用映射 —— CView 的消息映射
    // 自带这两个命令（和 ID_FILE_PRINT_DIRECT）的标准处理
END_MESSAGE_MAP()

// ---------- 主框架与应用 ----------
class CMainFrame : public CFrameWnd {
public:
    DECLARE_DYNCREATE(CMainFrame)

    CMainFrame() = default;
};

IMPLEMENT_DYNCREATE(CMainFrame, CFrameWnd)

class CPrintApp : public CWinApp {
public:
    BOOL InitInstance() override {
        auto* pTemplate = new CSingleDocTemplate(
            IDR_MAINFRAME,
            RUNTIME_CLASS(CReportDoc),
            RUNTIME_CLASS(CMainFrame),
            RUNTIME_CLASS(CReportView));
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

CPrintApp theApp;
