#include <afxwin.h>
#include <afxcmn.h>

class CControlDemoWnd : public CFrameWnd {
public:
    CControlDemoWnd() {
        Create(NULL, _T("MFC Controls Demo"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 700, 500));
    }

    int OnCreate(LPCREATESTRUCT lpCreateStruct) {
        CFrameWnd::OnCreate(lpCreateStruct);

        CStatic* label = new CStatic();
        label->Create(_T("用户名："), WS_CHILD | WS_VISIBLE | SS_LEFT,
                      CRect(20, 20, 120, 40), this, 1001);

        CEdit* edit = new CEdit();
        edit->Create(WS_CHILD | WS_VISIBLE | WS_BORDER | ES_AUTOHSCROLL,
                     CRect(130, 20, 260, 40), this, 1002);

        CButton* btn = new CButton();
        btn->Create(_T("确认"), WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON,
                    CRect(270, 20, 340, 42), this, 1003);

        CComboBox* combo = new CComboBox();
        combo->Create(WS_CHILD | WS_VISIBLE | CBS_DROPDOWNLIST,
                      CRect(20, 70, 180, 150), this, 1004);
        combo->AddString(_T("Windows"));
        combo->AddString(_T("MFC"));
        combo->AddString(_T("Doc/View"));
        combo->SetCurSel(0);

        CListBox* list = new CListBox();
        list->Create(WS_CHILD | WS_VISIBLE | LBS_NOTIFY,
                     CRect(200, 70, 360, 180), this, 1005);
        list->AddString(_T("Button"));
        list->AddString(_T("Edit"));
        list->AddString(_T("ListBox"));

        CSliderCtrl* slider = new CSliderCtrl();
        slider->Create(WS_CHILD | WS_VISIBLE | TBS_HORZ,
                      CRect(20, 210, 260, 240), this, 1006);

        CProgressCtrl* progress = new CProgressCtrl();
        progress->Create(WS_CHILD | WS_VISIBLE | PBS_SMOOTH,
                         CRect(20, 250, 260, 280), this, 1007);
        progress->SetRange(0, 100);
        progress->SetPos(65);

        return 0;
    }

    afx_msg void OnClickedButton() {
        AfxMessageBox(_T("确认按钮已点击"));
    }

    DECLARE_MESSAGE_MAP()
};

BEGIN_MESSAGE_MAP(CControlDemoWnd, CFrameWnd)
    ON_WM_CREATE()
    ON_BN_CLICKED(1003, OnClickedButton)
END_MESSAGE_MAP()

class CControlApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CControlDemoWnd();
        m_pMainWnd->ShowWindow(SW_SHOW);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CControlApp theApp;
