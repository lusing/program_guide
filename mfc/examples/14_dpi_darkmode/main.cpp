// 14_dpi_darkmode：Per-Monitor v2 DPI 感知 + 深色标题栏。
//
//   1. SetProcessDpiAwarenessContext —— 必须在任何窗口创建之前调用
//   2. Scale() + MulDiv —— 布局一律按 DPI 换算，不在 .rc 里写死像素
//   3. WM_DPICHANGED —— 换显示器/改缩放比例时跟随新 DPI 重排
//   4. DwmSetWindowAttribute —— 深色标题栏（只管非客户区）
//   5. WM_SETTINGCHANGE —— 系统主题切换时跟随
//
// 编译运行：.\build.ps1 -File 14_dpi_darkmode

#include "resource.h"
#include <afxwin.h>
#include <dwmapi.h>    // DwmSetWindowAttribute

// 旧版 SDK 头文件里没有这个常量（win10 1903 才加进 dwmapi.h），
// 带上 #ifndef 兜底，防止在旧工具链下编译失败
#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif

static bool IsSystemDark() {
    // 1 = 浅色，0 = 深色。默认按浅色算
    DWORD v = 1, size = sizeof(v);
    ::RegGetValue(HKEY_CURRENT_USER,
                  _T("Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize"),
                  _T("AppsUseLightTheme"), RRF_RT_REG_DWORD, nullptr, &v, &size);
    return v == 0;
}

// ------------------------------------------------- 示例面板：客户区自己画

// 深色模式 API 只改标题栏/边框这些"非客户区"。
// 客户区想跟着变黑，只能自己画 —— 这个面板就是干这个的。
class CSamplePanel : public CWnd {
public:
    BOOL Create(CWnd* parent, UINT id, const CRect& rc) {
        LPCTSTR cls = AfxRegisterWndClass(CS_HREDRAW | CS_VREDRAW,
                                          ::LoadCursor(NULL, IDC_ARROW),
                                          (HBRUSH)(COLOR_WINDOW + 1));
        return CWnd::CreateEx(WS_EX_CLIENTEDGE, cls, NULL,
                              WS_CHILD | WS_VISIBLE, rc, parent, id);
    }

    void SetDark(bool dark) {
        if (dark == m_dark)
            return;
        m_dark = dark;
        Invalidate();
    }

    afx_msg BOOL OnEraseBkgnd(CDC* pDC) {
        CRect rc;
        GetClientRect(&rc);
        pDC->FillSolidRect(rc, m_dark ? RGB(32, 32, 32) : RGB(250, 250, 250));
        return TRUE;
    }

    afx_msg void OnPaint() {
        CPaintDC dc(this);
        CRect rc;
        GetClientRect(&rc);
        rc.DeflateRect(10, 10);
        dc.SetBkMode(TRANSPARENT);
        dc.SetTextColor(m_dark ? RGB(220, 220, 220) : RGB(60, 60, 60));
        dc.DrawText(_T("客户区由程序自己画。\r\n")
                    _T("深色模式 API 只改标题栏和边框 —— 客户区想变黑得自己来。"),
                    rc, DT_LEFT | DT_WORDBREAK);
    }

    DECLARE_MESSAGE_MAP()

private:
    bool m_dark = false;
};

BEGIN_MESSAGE_MAP(CSamplePanel, CWnd)
    ON_WM_ERASEBKGND()
    ON_WM_PAINT()
END_MESSAGE_MAP()

// ------------------------------------------------- 主对话框

class CMainDlg : public CDialog {
public:
    CMainDlg() : CDialog(IDD_MAIN) {}

    BOOL OnInitDialog() override {
        CDialog::OnInitDialog();

        m_dpi = ::GetDpiForWindow(m_hWnd);   // 窗口所在显示器的 DPI

        // 子控件全部运行时创建（模板里没有控件）
        m_info.Create(_T(""), WS_CHILD | WS_VISIBLE | SS_LEFT,
                      CRect(0, 0, 0, 0), this, IDC_DPIINFO);
        m_btnDark.Create(_T("切换深色标题栏"),
                         WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_PUSHBUTTON,
                         CRect(0, 0, 0, 0), this, IDC_TOGGLEDARK);
        m_sample.Create(this, IDC_SAMPLE, CRect(0, 0, 0, 0));

        // 统一挂默认字体
        m_info.SendMessage(WM_SETFONT,
                           (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);
        m_btnDark.SendMessage(WM_SETFONT,
                              (WPARAM)::GetStockObject(DEFAULT_GUI_FONT), TRUE);

        m_dark = IsSystemDark();   // 启动时跟随系统主题
        ApplyDark();

        // 对话框自己的尺寸也按 DPI 换算（设计稿是 96 DPI 下的 420x320）
        SetWindowPos(nullptr, 100, 100, Scale(420), Scale(320),
                     SWP_NOZORDER | SWP_NOACTIVATE);
        Layout();
        return TRUE;
    }

    int Scale(int px) const {
        return MulDiv(px, static_cast<int>(m_dpi), 96);   // 96 DPI = 100%
    }

    // 所有布局走这一个函数：换 DPI 时整个重排，不搞局部补丁
    void Layout() {
        CRect rc;
        GetClientRect(&rc);
        const int m = Scale(12);                    // 统一 12px 边距（设计值）

        m_info.MoveWindow(m, m, rc.Width() - 2 * m, Scale(72));
        m_btnDark.MoveWindow(m, m + Scale(82), Scale(170), Scale(26));
        m_sample.MoveWindow(m, m + Scale(118), rc.Width() - 2 * m,
                            rc.bottom - m - (m + Scale(118)));
        UpdateInfo();
    }

    void UpdateInfo() {
        CString s;
        s.Format(_T("窗口所在显示器 DPI：%u（缩放 %d%%）\r\n")
                 _T("系统 DPI：%u\r\n")
                 _T("感知级别：Per-Monitor Aware v2"),
                 m_dpi, MulDiv(static_cast<int>(m_dpi), 100, 96),
                 ::GetDpiForSystem());
        m_info.SetWindowText(s);
    }

    void ApplyDark() {
        BOOL b = m_dark ? TRUE : FALSE;
        // 只影响非客户区（标题栏/边框）。客户区要自己重画。
        ::DwmSetWindowAttribute(m_hWnd, DWMWA_USE_IMMERSIVE_DARK_MODE,
                                &b, sizeof(b));
        m_sample.SetDark(m_dark);
    }

    // WM_DPICHANGED：MFC 消息映射没有现成的宏，只能用 ON_MESSAGE 手接。
    // 注意参数类型必须严格是 (WPARAM, LPARAM) —— 写成 UINT 会让
    // ON_MESSAGE 里的 static_cast 不再是常量表达式，报 C2737
    LRESULT OnDpiChanged(WPARAM wParam, LPARAM lParam) {
        m_dpi = HIWORD(wParam);     // 高 16 位 = X DPI，低 16 位 = Y DPI

        // lParam 是系统建议的新窗口矩形。必须照做 —— 不调的话窗口尺寸
        // 不跟随，系统会把旧尺寸的窗口拉伸到新屏上，位图模糊
        const RECT* prc = reinterpret_cast<const RECT*>(lParam);
        SetWindowPos(nullptr, prc->left, prc->top,
                     prc->right - prc->left, prc->bottom - prc->top,
                     SWP_NOZORDER | SWP_NOACTIVATE);

        Layout();                   // 按新 DPI 整体重排子控件
        return 0;
    }

    // 系统设置变化。主题切换时 lParam 是 "ImmersiveColorSet"
    afx_msg void OnSettingChange(UINT uFlags, LPCTSTR lpszSection) {
        if (lpszSection && lstrcmpi(lpszSection, _T("ImmersiveColorSet")) == 0) {
            m_dark = IsSystemDark();    // 跟随系统主题
            ApplyDark();
        }
        CDialog::OnSettingChange(uFlags, lpszSection);
    }

    afx_msg void OnToggleDark() {
        m_dark = !m_dark;
        ApplyDark();
    }

    DECLARE_MESSAGE_MAP()

private:
    CStatic      m_info;
    CButton      m_btnDark;
    CSamplePanel m_sample;
    UINT         m_dpi = 96;
    bool         m_dark = false;
};

BEGIN_MESSAGE_MAP(CMainDlg, CDialog)
    ON_BN_CLICKED(IDC_TOGGLEDARK, &CMainDlg::OnToggleDark)
    ON_MESSAGE(WM_DPICHANGED, &CMainDlg::OnDpiChanged)
    ON_WM_SETTINGCHANGE()
END_MESSAGE_MAP()

// ------------------------------------------------- 应用

class CDpiApp : public CWinApp {
public:
    BOOL InitInstance() override {
        // 必须在任何窗口创建之前调用。晚了/失败都不报错 ——
        // 表现只是"高 DPI 下模糊"，所以要检查返回值
        if (!::SetProcessDpiAwarenessContext(
                DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2)) {
            // 常见失败原因：清单里已经声明过感知级别，或之前已调过
            TRACE(_T("SetProcessDpiAwarenessContext 失败：%u\n"), ::GetLastError());
        }

        CMainDlg dlg;
        m_pMainWnd = &dlg;
        dlg.DoModal();
        return FALSE;
    }
};

CDpiApp theApp;
