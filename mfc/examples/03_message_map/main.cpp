// 02_message_map：消息映射机制详解。
//
// 演示三类最常见的消息：
//   1. Windows 标准消息  WM_*   -> ON_WM_*      （OnPaint / OnLButtonDown ...）
//   2. 自定义消息        WM_APP -> ON_MESSAGE    （跨窗口/线程通知的正规手段）
//   3. 命令消息          菜单等 -> ON_COMMAND    （第 03 章的资源示例再展开）
//
// 同时展示消息处理函数的标准签名和 afx_msg 的含义。
//
// 编译运行：.\build.ps1 -File 02_message_map

#include <afxwin.h>

// 自定义消息。用 WM_APP + n 保证不会撞上系统消息；
// 跨进程则应改用 RegisterWindowMessage。
#define WM_APP_TICK     (WM_APP + 1)

class CMainWindow : public CFrameWnd {
public:
    CMainWindow() : m_clicks(0) {
        Create(NULL, _T("MFC 消息映射演示"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 660, 440));
    }

    // ---- 标准消息：参数由 MFC 从 WPARAM/LPARAM 拆好递给你 ----

    afx_msg void OnPaint() {
        CPaintDC dc(this);
        CRect rect;
        GetClientRect(&rect);
        rect.DeflateRect(24, 24);
        dc.SetBkMode(TRANSPARENT);

        CString text;
        text.Format(_T("鼠标已点击 %d 次\n\n操作提示：\n  - 左键单击客户区 -> WM_LBUTTONDOWN\n  - 双击客户区     -> WM_LBUTTONDBLCLK\n  - 任意按键       -> WM_CHAR\n  - 拉伸窗口       -> WM_SIZE / WM_PAINT"), m_clicks);
        dc.DrawText(text, -1, rect, DT_LEFT | DT_WORDBREAK);
    }

    afx_msg void OnLButtonDown(UINT nFlags, CPoint point) {
        ++m_clicks;
        // 参数说明：nFlags 是按键修饰符，point 是客户区坐标
        if (nFlags & MK_CONTROL) {
            CString msg;
            msg.Format(_T("Ctrl+点击，位置 (%d, %d)"), point.x, point.y);
            MessageBox(msg, _T("带修饰键的点击"));
        }
        Invalidate(FALSE);  // 请求重绘 -> 产生 WM_PAINT
    }

    afx_msg void OnLButtonDblClk(UINT nFlags, CPoint point) {
        // 给自己发一条自定义消息，演示 PostMessage + ON_MESSAGE
        PostMessage(WM_APP_TICK, m_clicks, point.x);
    }

    afx_msg void OnChar(UINT nChar, UINT nRepCnt, UINT nFlags) {
        CString msg;
        msg.Format(_T("按键字符：%c"), nChar);
        SetWindowText(msg);
    }

    afx_msg void OnSize(UINT nType, int cx, int cy) {
        CFrameWnd::OnSize(nType, cx, cy);  // 基类处理要先调用
        Invalidate(FALSE);
    }

    // ---- 自定义消息：WPARAM/LPARAM 需要自己解释 ----
    afx_msg LRESULT OnAppTick(WPARAM wParam, LPARAM lParam) {
        CString msg;
        msg.Format(_T("收到 WM_APP_TICK：wParam=%u（点击数），lParam=%ld（x 坐标）"),
                   wParam, lParam);
        MessageBox(msg, _T("自定义消息"));
        return 0;  // ON_MESSAGE 的返回值就是消息处理结果
    }

    DECLARE_MESSAGE_MAP()

private:
    int m_clicks;
};

BEGIN_MESSAGE_MAP(CMainWindow, CFrameWnd)
    ON_WM_PAINT()
    ON_WM_LBUTTONDOWN()
    ON_WM_LBUTTONDBLCLK()
    ON_WM_CHAR()
    ON_WM_SIZE()
    ON_MESSAGE(WM_APP_TICK, OnAppTick)
END_MESSAGE_MAP()

class CMyApp : public CWinApp {
public:
    BOOL InitInstance() override {
        m_pMainWnd = new CMainWindow();
        m_pMainWnd->ShowWindow(m_nCmdShow);
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;
