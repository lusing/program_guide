#include <afxwin.h>

class CMyDocument : public CDocument {
public:
    CString m_text = _T("Hello Doc/View");

    void Serialize(CArchive& ar) override {
        if (ar.IsStoring()) {
            ar << m_text;
        } else {
            ar >> m_text;
        }
    }
};

class CMyView : public CView {
public:
    DECLARE_DYNCREATE(CMyView)

    CMyView() = default;

    void OnDraw(CDC* pDC) override {
        CString msg = _T("Doc/View Demo");
        pDC->TextOutW(20, 20, msg);
    }

    void OnInitialUpdate() override {
        CView::OnInitialUpdate();
    }

    void Serialize(CArchive& ar) override {
        GetDocument()->Serialize(ar);
    }
};

IMPLEMENT_DYNCREATE(CMyView, CView)

class CMyFrame : public CFrameWnd {
public:
    CMyFrame() {
        Create(NULL, _T("Doc/View Demo"), WS_OVERLAPPEDWINDOW,
               CRect(120, 120, 700, 500));
    }
};

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CMyFrame();
        m_pMainWnd->ShowWindow(SW_SHOW);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
