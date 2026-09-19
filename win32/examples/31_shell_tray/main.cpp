// 31_shell_tray — 托盘图标 + 右键菜单 + 气泡通知 + Explorer 重启恢复
//
// 对应教程：docs/28-Shell集成.md
#include <windows.h>
#include <shellapi.h>

#define WM_TRAYICON (WM_APP + 1)
#define IDM_SHOW    1
#define IDM_NOTIFY  2
#define IDM_EXIT    3

static UINT g_taskbarCreatedMsg;         // Explorer 重启广播的消息号
static NOTIFYICONDATAW g_nid;

static void AddTrayIcon(HWND hwnd) {
    g_nid = {};
    g_nid.cbSize = sizeof(g_nid);
    g_nid.hWnd = hwnd;
    g_nid.uID = 1;
    g_nid.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
    g_nid.uCallbackMessage = WM_TRAYICON;                    // 事件路由到它
    g_nid.hIcon = LoadIconW(nullptr, IDI_APPLICATION);
    lstrcpynW(g_nid.szTip, L"托盘演示（右键菜单/双击显示）", 128);
    Shell_NotifyIconW(NIM_ADD, &g_nid);
}

static void ShowBalloon(const wchar_t* text) {
    g_nid.uFlags = NIF_INFO;                                 // 只动气泡字段
    lstrcpynW(g_nid.szInfo, text, 256);
    lstrcpynW(g_nid.szInfoTitle, L"来自托盘图标", 64);
    g_nid.dwInfoFlags = NIIF_INFO;
    Shell_NotifyIconW(NIM_MODIFY, &g_nid);
}

static void ShowMenu(HWND hwnd) {
    POINT pt; GetCursorPos(&pt);
    HMENU menu = CreatePopupMenu();
    AppendMenuW(menu, MF_STRING, IDM_SHOW,   L"显示窗口");
    AppendMenuW(menu, MF_STRING, IDM_NOTIFY, L"发个通知");
    AppendMenuW(menu, MF_SEPARATOR, 0, nullptr);
    AppendMenuW(menu, MF_STRING, IDM_EXIT,   L"退出");
    // 托盘菜单标准姿势：不先 SetForegroundWindow，点菜单外不会收起
    SetForegroundWindow(hwnd);
    TrackPopupMenu(menu, TPM_RIGHTBUTTON, pt.x, pt.y, 0, hwnd, nullptr);
    DestroyMenu(menu);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE:
        AddTrayIcon(hwnd);
        return 0;
    case WM_TRAYICON:
        if (lParam == WM_RBUTTONUP)          ShowMenu(hwnd);
        else if (lParam == WM_LBUTTONDBLCLK) ShowWindow(hwnd, SW_SHOW);
        return 0;
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDM_SHOW:
            ShowWindow(hwnd, SW_SHOW);
            SetForegroundWindow(hwnd);
            return 0;
        case IDM_NOTIFY:
            ShowBalloon(L"这是气泡通知。现代替代是 WinRT Toast（第 26 章）——"
                        L"它需要应用身份，见该章 26.7。");
            return 0;
        case IDM_EXIT:
            DestroyWindow(hwnd);
            return 0;
        }
        break;
    case WM_SIZE:
        if (wParam == SIZE_MINIMIZED) {
            ShowWindow(hwnd, SW_HIDE);       // 最小化进托盘：藏窗口留图标
            return 0;
        }
        break;
    case WM_DESTROY:
        Shell_NotifyIconW(NIM_DELETE, &g_nid);   // 图标必须收走，否则留"幽灵"
        PostQuitMessage(0);
        return 0;
    default:
        if (msg == g_taskbarCreatedMsg) {
            AddTrayIcon(hwnd);               // Explorer 重启：重挂图标
            return 0;
        }
        break;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nShow) {
    g_taskbarCreatedMsg = RegisterWindowMessageW(L"TaskbarCreated");

    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"TrayDemoClass";
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, L"TrayDemoClass", L"托盘演示（最小化藏进托盘）",
        WS_OVERLAPPEDWINDOW | WS_MINIMIZEBOX, CW_USEDEFAULT, CW_USEDEFAULT, 480, 200,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
