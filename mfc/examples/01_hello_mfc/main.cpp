// 01_hello_mfc：最小的 MFC 程序。
//
// 一个 MFC 程序最少只需要三样东西：
//   1. 一个 CWinApp 派生类的全局对象（框架入口）
//   2. 一个主窗口（这里用 CFrameWnd）
//   3. InitInstance() 中创建并显示主窗口
//
// 编译运行：在 mfc 目录执行 .\build.ps1 -File 01_hello_mfc
// 产物：build\01_hello_mfc.exe

#include <afxwin.h>

// 主窗口：CFrameWnd 封装了一个带标题栏、可缩放的框架窗口。
class CMainWindow : public CFrameWnd {
public:
    CMainWindow() {
        // Create(类名, 标题, 样式, 位置大小)
        // 传 NULL 表示使用 MFC 注册的默认窗口类。
        Create(NULL, _T("MFC Hello"), WS_OVERLAPPEDWINDOW,
               CRect(100, 100, 640, 420));
    }

    // 响应 WM_PAINT：窗口需要重绘时由框架调用。
    afx_msg void OnPaint() {
        CPaintDC dc(this);
        dc.SetTextColor(RGB(30, 30, 30));
        dc.SetBkMode(TRANSPARENT);

        CRect rect;
        GetClientRect(&rect);

        CFont font;
        font.CreatePointFont(180, _T("微软雅黑"));
        CFont* oldFont = dc.SelectObject(&font);

        CRect textRect = rect;
        textRect.DeflateRect(24, 24);
        dc.DrawText(_T("Hello, MFC!\n最小可运行的 MFC 窗口程序。"),
                    -1, textRect, DT_LEFT | DT_WORDBREAK);

        dc.SelectObject(oldFont);  // GDI 对象用完要选回旧的，避免泄漏
    }

    // 声明消息映射：把 Windows 消息连接到上面的处理函数。
    DECLARE_MESSAGE_MAP()
};

// 消息映射的实现：WM_PAINT -> OnPaint
BEGIN_MESSAGE_MAP(CMainWindow, CFrameWnd)
    ON_WM_PAINT()
END_MESSAGE_MAP()

// 应用对象：整个程序只有一个，全局构造时向 MFC 框架注册自己。
class CMyApp : public CWinApp {
public:
    // InitInstance 是程序入口：窗口创建、显示都发生在这里。
    // 返回 FALSE 会直接退出程序。
    BOOL InitInstance() override {
        m_pMainWnd = new CMainWindow();      // 框架接管该指针的生命周期
        m_pMainWnd->ShowWindow(m_nCmdShow);  // 用命令行参数决定初始显示状态
        m_pMainWnd->UpdateWindow();
        return TRUE;
    }
};

CMyApp theApp;  // 全局应用对象，MFC 程序的真正入口
