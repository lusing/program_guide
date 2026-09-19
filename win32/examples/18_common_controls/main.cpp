// 18_common_controls — 工具栏 / 状态栏 / 进度条 / Tab / RichEdit 五件套
//
// 对应教程：docs/07-更多通用控件.md
#include <windows.h>
#include <commctrl.h>
#include <richedit.h>
#include <stdio.h>

#define IDC_TOOL    1101
#define IDC_STATUS  1102
#define IDC_PROG    1103
#define IDC_TAB     1104
#define IDC_RICH    1105
#define IDC_PAGE1   1106
#define IDC_PAGE2   1107
#define IDM_OPEN    2001
#define IDM_SAVE    2002
#define IDM_PRINT   2003
#define TIMER_PROGRESS 1

static HWND g_tool, g_status, g_prog, g_tab, g_rich, g_page1, g_page2;
static HMODULE g_richedDll;

static void StatusText(int part, const wchar_t* text) {
    SendMessageW(g_status, SB_SETTEXTW, part, (LPARAM)text);
}

static void Layout(HWND hwnd) {
    RECT rc; GetClientRect(hwnd, &rc);
    RECT tb;  GetWindowRect(g_tool, &tb);   int toolH = tb.bottom - tb.top;
    RECT sb;  GetWindowRect(g_status, &sb); int statH = sb.bottom - sb.top;
    MoveWindow(g_prog, 10, toolH + 8, 200, 18, TRUE);
    MoveWindow(g_tab, 10, toolH + 34, 300, rc.bottom - statH - toolH - 44, TRUE);
    MoveWindow(g_rich, 320, toolH + 34, rc.right - 330,
               rc.bottom - statH - toolH - 44, TRUE);
    RECT tabRc; GetClientRect(g_tab, &tabRc);
    SendMessageW(g_tab, TCM_ADJUSTRECT, FALSE, (LPARAM)&tabRc);  // 客户区扣掉标签头
    MapWindowPoints(g_tab, hwnd, (LPPOINT)&tabRc, 2);
    int w = tabRc.right - tabRc.left, h = tabRc.bottom - tabRc.top;
    MoveWindow(g_page1, tabRc.left, tabRc.top, w, h, TRUE);
    MoveWindow(g_page2, tabRc.left, tabRc.top, w, h, TRUE);
    SendMessageW(g_status, WM_SIZE, 0, 0);   // 状态栏收到 WM_SIZE 自动重排
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        CREATESTRUCTW* cs = (CREATESTRUCTW*)lParam;

        // ── 工具栏：加载系统标准图库，零资源起步 ──
        g_tool = CreateWindowExW(0, TOOLBARCLASSNAMEW, nullptr,
            WS_CHILD | WS_VISIBLE | TBSTYLE_TOOLTIPS,
            0, 0, 0, 0, hwnd, (HMENU)(INT_PTR)IDC_TOOL, cs->hInstance, nullptr);
        SendMessageW(g_tool, TB_BUTTONSTRUCTSIZE, sizeof(TBBUTTON), 0);
        // HINST_COMMCTRL + IDB_STD_SMALL_COLOR = comctl32 内置的标准图标集
        SendMessageW(g_tool, TB_LOADIMAGES, IDB_STD_SMALL_COLOR, (LPARAM)HINST_COMMCTRL);
        TBBUTTON btns[] = {
            { STD_FILEOPEN, IDM_OPEN,  TBSTATE_ENABLED, BTNS_BUTTON, {}, 0, (INT_PTR)L"打开" },
            { STD_FILESAVE, IDM_SAVE,  TBSTATE_ENABLED, BTNS_BUTTON, {}, 0, (INT_PTR)L"保存" },
            { 0, 0, TBSTATE_ENABLED, BTNS_SEP, {}, 0, 0 },            // 分隔线
            { STD_PRINT,    IDM_PRINT, TBSTATE_ENABLED, BTNS_BUTTON, {}, 0, (INT_PTR)L"打印" },
        };
        SendMessageW(g_tool, TB_ADDBUTTONSW, 4, (LPARAM)btns);
        SendMessageW(g_tool, TB_AUTOSIZE, 0, 0);

        // ── 状态栏：三栏 ──
        g_status = CreateWindowExW(0, STATUSCLASSNAMEW, nullptr,
            WS_CHILD | WS_VISIBLE | SBARS_SIZEGRIP,
            0, 0, 0, 0, hwnd, (HMENU)(INT_PTR)IDC_STATUS, cs->hInstance, nullptr);
        int parts[] = { 220, 420, -1 };
        SendMessageW(g_status, SB_SETPARTS, 3, (LPARAM)parts);
        StatusText(0, L"就绪");
        StatusText(2, L"共 5 个控件");

        // ── 进度条：定时器驱动 ──
        g_prog = CreateWindowExW(0, PROGRESS_CLASSW, nullptr,
            WS_CHILD | WS_VISIBLE | PBS_SMOOTH,
            10, 40, 200, 18, hwnd, (HMENU)(INT_PTR)IDC_PROG, cs->hInstance, nullptr);
        SendMessageW(g_prog, PBM_SETRANGE32, 0, 100);
        SetTimer(hwnd, TIMER_PROGRESS, 100, nullptr);

        // ── Tab：两个子页（切换 = 显隐切换）──
        g_tab = CreateWindowExW(0, WC_TABCONTROL, nullptr,
            WS_CHILD | WS_VISIBLE | WS_CLIPSIBLINGS,
            10, 66, 300, 200, hwnd, (HMENU)(INT_PTR)IDC_TAB, cs->hInstance, nullptr);
        TCITEMW ti = { .mask = TCIF_TEXT };
        ti.pszText = (LPWSTR)L"第一页"; SendMessageW(g_tab, TCM_INSERTITEMW, 0, (LPARAM)&ti);
        ti.pszText = (LPWSTR)L"第二页"; SendMessageW(g_tab, TCM_INSERTITEMW, 1, (LPARAM)&ti);
        g_page1 = CreateWindowExW(0, L"STATIC", L"这是第一页的内容",
            WS_CHILD | WS_VISIBLE | SS_CENTER, 20, 46, 260, 150,
            g_tab, (HMENU)(INT_PTR)IDC_PAGE1, cs->hInstance, nullptr);
        g_page2 = CreateWindowExW(0, L"EDIT", L"这是第二页的输入框",
            WS_CHILD | WS_BORDER | ES_AUTOHSCROLL, 20, 46, 260, 24,
            g_tab, (HMENU)(INT_PTR)IDC_PAGE2, cs->hInstance, nullptr);

        // ── RichEdit：必须先 LoadLibrary 才能用 ──
        g_richedDll = LoadLibraryW(L"msftedit.dll");   // RichEdit 4.1
        if (g_richedDll) {
            g_rich = CreateWindowExW(WS_EX_CLIENTEDGE, L"RICHEDIT50W",
                L"RichEdit 编辑区：\r\n支持复杂文本格式、无限撤销、查找替换。\r\n（普通 EDIT 的能力天花板见第 05 章）",
                WS_CHILD | WS_VISIBLE | ES_MULTILINE | WS_VSCROLL | ES_AUTOVSCROLL,
                320, 66, 340, 250, hwnd, (HMENU)(INT_PTR)IDC_RICH, cs->hInstance, nullptr);
            CHARFORMAT2W cf = { sizeof(cf) };
            cf.dwMask = CFM_FACE | CFM_SIZE;
            cf.yHeight = 320;                    // 字号单位是 twips：320 = 16pt
            lstrcpynW(cf.szFaceName, L"微软雅黑", LF_FACESIZE);
            SendMessageW(g_rich, EM_SETCHARFORMAT, SCF_ALL, (LPARAM)&cf);
        }
        return 0;
    }
    case WM_TIMER:
        if (wParam == TIMER_PROGRESS) {
            int pos = (int)SendMessageW(g_prog, PBM_GETPOS, 0, 0) + 1;
            if (pos > 100) pos = 0;
            SendMessageW(g_prog, PBM_SETPOS, pos, 0);
            wchar_t buf[64]; swprintf_s(buf, L"进度 %d%%", pos);
            StatusText(1, buf);
        }
        return 0;
    case WM_NOTIFY: {
        LPNMHDR nm = (LPNMHDR)lParam;
        if (nm->idFrom == IDC_TAB && nm->code == TCN_SELCHANGE) {
            int cur = (int)SendMessageW(g_tab, TCM_GETCURSEL, 0, 0);
            ShowWindow(g_page1, cur == 0 ? SW_SHOW : SW_HIDE);
            ShowWindow(g_page2, cur == 1 ? SW_SHOW : SW_HIDE);
        }
        return 0;
    }
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDM_OPEN:  StatusText(0, L"打开（通用对话框见第 10 章）"); return 0;
        case IDM_SAVE:  StatusText(0, L"保存"); return 0;
        case IDM_PRINT: StatusText(0, L"打印"); return 0;
        }
        break;
    case WM_SIZE:
        Layout(hwnd);
        return 0;
    case WM_DESTROY:
        KillTimer(hwnd, TIMER_PROGRESS);
        if (g_richedDll) FreeLibrary(g_richedDll);
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nShow) {
    INITCOMMONCONTROLSEX icc = { sizeof(icc),
        ICC_BAR_CLASSES | ICC_TAB_CLASSES | ICC_WIN95_CLASSES };
    InitCommonControlsEx(&icc);

    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"CommonCtrlsClass";
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, L"CommonCtrlsClass", L"通用控件五件套",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 720, 420,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
