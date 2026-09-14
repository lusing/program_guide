#include <afxwin.h>

class CGraphicsWnd : public CFrameWnd {
public:
    CGraphicsWnd() {
        Create(NULL, _T("Graphics Demo"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 650, 420));
    }

    afx_msg void OnPaint() {
        CPaintDC dc(this);
        CRect client;
        GetClientRect(&client);

        dc.FillSolidRect(client, RGB(245, 245, 245));

        CBrush brush(RGB(70, 130, 180));
        dc.SelectObject(&brush);
        dc.Ellipse(60, 60, 240, 180);

        CPen pen(PS_SOLID, 3, RGB(255, 100, 0));
        dc.SelectObject(&pen);
        dc.Rectangle(300, 80, 520, 220);

        dc.SetTextColor(RGB(30, 30, 30));
        dc.TextOutW(80, 220, _T("MFC GDI 绘图"));
    }

    DECLARE_MESSAGE_MAP()
};

BEGIN_MESSAGE_MAP(CGraphicsWnd, CFrameWnd)
    ON_WM_PAINT()
END_MESSAGE_MAP()

class CGraphicsApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CGraphicsWnd();
        m_pMainWnd->ShowWindow(SW_SHOW);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CGraphicsApp theApp;
