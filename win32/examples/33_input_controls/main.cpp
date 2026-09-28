// 33_input_controls —— 第 8 章：输入与调节控件五件套
// 轨迹条 / 增减数(+buddy) / 热键 / IP 地址 / 扩展组合框
#include <windows.h>
#include <commctrl.h>
#include <wchar.h>
#include <stdio.h>

#pragma comment(lib, "comctl32.lib")

constexpr int IDC_TRACK   = 1001;   // 轨迹条
constexpr int IDC_LABEL   = 1002;   // 轨迹条读数
constexpr int IDC_AGE     = 1003;   // 增减数的 buddy 编辑框
constexpr int IDC_AGE_UD  = 1004;   // 增减数
constexpr int IDC_HOTKEY  = 1005;   // 热键
constexpr int IDC_IP      = 1006;   // IP 地址
constexpr int IDC_CBX     = 1007;   // 扩展组合框
constexpr int IDC_REPORT  = 1008;   // "汇报"按钮
constexpr int IDC_LBL2    = 1009;   // 增减数读数

HWND g_track, g_label, g_age, g_ud, g_hotkey, g_ip, g_cbex, g_lbl2, g_report;
HIMAGELIST g_imgs;

static void Layout(HWND hwnd) {
    int w, h; RECT rc; GetClientRect(hwnd, &rc); w = rc.right; h = rc.bottom;
    MoveWindow(g_track, 30, 40, w - 120, 36, TRUE);
    MoveWindow(g_label, w - 80, 48, 70, 24, TRUE);
    MoveWindow(g_lbl2, 220, 100, 140, 20, TRUE);
    MoveWindow(g_hotkey, 30, 140, 150, 24, TRUE);
    MoveWindow(g_ip, 220, 140, 150, 24, TRUE);
    MoveWindow(g_cbex, 30, 185, 220, 200, TRUE);
    MoveWindow(g_report, w - 110, 185, 80, 28, TRUE);
}

static void Report(HWND hwnd) {
    wchar_t buf[256];
    int vol = (int)SendMessageW(g_track, TBM_GETPOS, 0, 0);
    int age = (int)SendMessageW(g_ud, UDM_GETPOS32, 0, 0);

    DWORD hk = (DWORD)SendMessageW(g_hotkey, HKM_GETHOTKEY, 0, 0);
    BYTE vk = LOBYTE(hk), mods = HIBYTE(hk);
    wchar_t key[64] = L"（未设置）";
    if (vk) {
        wchar_t keyName[32] = {};
        UINT scan = MapVirtualKeyW(vk, MAPVK_VK_TO_VSC);
        LONG lp = (scan << 16);
        if (GetKeyNameTextW(lp, keyName, 32) > 0)
            swprintf_s(key, 64, L"%s%s%s%s",
                       (mods & HOTKEYF_CONTROL) ? L"Ctrl+" : L"",
                       (mods & HOTKEYF_SHIFT)   ? L"Shift+" : L"",
                       (mods & HOTKEYF_ALT)     ? L"Alt+" : L"", keyName);
    }

    DWORD addr = 0;
    int fields = (int)SendMessageW(g_ip, IPM_GETADDRESS, 0, (LPARAM)&addr);
    wchar_t ipText[24] = L"（未填完）";
    if (fields == 4)
        swprintf_s(ipText, 24, L"%u.%u.%u.%u", FIRST_IPADDRESS(addr),
                   SECOND_IPADDRESS(addr), THIRD_IPADDRESS(addr), FOURTH_IPADDRESS(addr));

    int sel = (int)SendMessageW(g_cbex, CB_GETCURSEL, 0, 0);
    wchar_t item[64] = L"（无）";
    if (sel >= 0) {
        wchar_t txt[64] = {};
        COMBOBOXEXITEMW ci = { .mask = CBEIF_TEXT, .iItem = sel,
                               .pszText = txt, .cchTextMax = 64 };
        SendMessageW(g_cbex, CBEM_GETITEMW, 0, (LPARAM)&ci);
        lstrcpynW(item, txt, 64);
    }

    swprintf_s(buf, 256,
        L"音量：%d\n年龄：%d\n热键：%s\nIP：%s\n项目：%s",
        vol, age, key, ipText, item);
    MessageBoxW(hwnd, buf, L"当前值汇报", MB_OK);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        HINSTANCE inst = ((LPCREATESTRUCTW)lParam)->hInstance;

        // ① 轨迹条：注意 TBM_SETRANGE 的 lParam 用 MAKELONG 打包两端
        g_track = CreateWindowExW(0, TRACKBAR_CLASSW, nullptr,
            WS_CHILD | WS_VISIBLE | TBS_HORZ | TBS_AUTOTICKS | TBS_ENABLESELRANGE,
            30, 40, 300, 36, hwnd, (HMENU)(INT_PTR)IDC_TRACK, inst, nullptr);
        SendMessageW(g_track, TBM_SETRANGE, TRUE, MAKELONG(0, 100));
        SendMessageW(g_track, TBM_SETTICFREQ, 10, 0);
        SendMessageW(g_track, TBM_SETPOS, TRUE, 30);

        CreateWindowExW(0, L"STATIC", L"音量：",
            WS_CHILD | WS_VISIBLE | SS_RIGHT, 410, 22, 80, 20,
            hwnd, nullptr, inst, nullptr);
        g_label = CreateWindowExW(0, L"STATIC", L"30",
            WS_CHILD | WS_VISIBLE | SS_RIGHT, 490, 22, 60, 20,
            hwnd, (HMENU)(INT_PTR)IDC_LABEL, inst, nullptr);

        // ② 增减数 + buddy 编辑框
        CreateWindowExW(0, L"STATIC", L"年龄（上限被拦在 100）：",
            WS_CHILD | WS_VISIBLE, 30, 96, 190, 20, hwnd, nullptr, inst, nullptr);
        g_age = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"25",
            WS_CHILD | WS_VISIBLE | ES_NUMBER, 30, 118, 70, 24,
            hwnd, (HMENU)(INT_PTR)IDC_AGE, inst, nullptr);
        g_ud = CreateWindowExW(0, UPDOWN_CLASSW, nullptr,
            WS_CHILD | WS_VISIBLE | UDS_SETBUDDYINT | UDS_ALIGNRIGHT
            | UDS_ARROWKEYS | UDS_WRAP,
            0, 0, 0, 0, hwnd, (HMENU)(INT_PTR)IDC_AGE_UD, inst, nullptr);
        SendMessageW(g_ud, UDM_SETBUDDY, (WPARAM)g_age, 0);
        SendMessageW(g_ud, UDM_SETRANGE32, 0, 120);      // 32 位范围
        SendMessageW(g_ud, UDM_SETPOS32, 0, 25);
        g_lbl2 = CreateWindowExW(0, L"STATIC", L"位置：25",
            WS_CHILD | WS_VISIBLE, 220, 100, 140, 20,
            hwnd, (HMENU)(INT_PTR)IDC_LBL2, inst, nullptr);

        // ③ 热键
        CreateWindowExW(0, L"STATIC", L"热键（点进去按组合键）：",
            WS_CHILD | WS_VISIBLE, 30, 140 - 20, 190, 20, hwnd, nullptr, inst, nullptr);
        g_hotkey = CreateWindowExW(0, HOTKEY_CLASSW, nullptr,
            WS_CHILD | WS_VISIBLE, 30, 140, 150, 24,
            hwnd, (HMENU)(INT_PTR)IDC_HOTKEY, inst, nullptr);
        SendMessageW(g_hotkey, HKM_SETHOTKEY, MAKEWORD('K', HOTKEYF_CONTROL | HOTKEYF_ALT), 0);

        // ④ IP 地址
        CreateWindowExW(0, L"STATIC", L"IP 地址：",
            WS_CHILD | WS_VISIBLE, 220, 140 - 20, 120, 20, hwnd, nullptr, inst, nullptr);
        g_ip = CreateWindowExW(WS_EX_CLIENTEDGE, WC_IPADDRESSW, nullptr,
            WS_CHILD | WS_VISIBLE, 220, 140, 150, 24,
            hwnd, (HMENU)(INT_PTR)IDC_IP, inst, nullptr);
        SendMessageW(g_ip, IPM_SETADDRESS, 0, MAKEIPADDRESS(192, 168, 1, 1));

        // ⑤ 扩展组合框（图标 + 缩进）
        CreateWindowExW(0, L"STATIC", L"项目（带图标与缩进）：",
            WS_CHILD | WS_VISIBLE, 30, 185 - 20, 190, 20, hwnd, nullptr, inst, nullptr);
        g_cbex = CreateWindowExW(0, WC_COMBOBOXEXW, nullptr,
            WS_CHILD | WS_VISIBLE | CBS_DROPDOWNLIST, 30, 185, 220, 200,
            hwnd, (HMENU)(INT_PTR)IDC_CBX, inst, nullptr);
        g_imgs = ImageList_Create(16, 16, ILC_COLOR32, 0, 4);
        ImageList_AddIcon(g_imgs, LoadIconW(nullptr, IDI_APPLICATION));
        ImageList_AddIcon(g_imgs, LoadIconW(nullptr, IDI_INFORMATION));
        SendMessageW(g_cbex, CBEM_SETIMAGELIST, 0, (LPARAM)g_imgs);
        const wchar_t* items[] = { L"水果", L"苹果", L"红富士", L"打印机" };
        int imgs[]  = { 0, 0, 1, 0 };
        int indents[] = { 0, 1, 2, 0 };
        for (int i = 0; i < 4; ++i) {
            COMBOBOXEXITEMW ci = { .mask = CBEIF_TEXT | CBEIF_IMAGE | CBEIF_INDENT | CBEIF_SELECTEDIMAGE,
                                   .iItem = -1, .pszText = (LPWSTR)items[i],
                                   .iImage = imgs[i], .iSelectedImage = imgs[i],
                                   .iIndent = indents[i] };
            SendMessageW(g_cbex, CBEM_INSERTITEMW, 0, (LPARAM)&ci);
        }
        SendMessageW(g_cbex, CB_SETCURSEL, 0, 0);

        g_report = CreateWindowExW(0, L"BUTTON", L"汇报",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, 440, 185, 80, 28,
            hwnd, (HMENU)(INT_PTR)IDC_REPORT, inst, nullptr);
        return 0;
    }
    case WM_HSCROLL:                       // 轨迹条：唯一走 WM_HSCROLL 的通用控件
        if ((HWND)lParam == g_track) {
            wchar_t b[16];
            swprintf_s(b, 16, L"%d", (int)SendMessageW(g_track, TBM_GETPOS, 0, 0));
            SetWindowTextW(g_label, b);
        }
        return 0;
    case WM_NOTIFY: {
        LPNMHDR nm = (LPNMHDR)lParam;
        if (nm->idFrom == IDC_AGE_UD && nm->code == (UINT)UDN_DELTAPOS) {
            NMUPDOWN* p = (NMUPDOWN*)lParam;
            wchar_t b[32];
            swprintf_s(b, 32, L"位置：%d（增量 %d）", p->iPos, p->iDelta);
            SetWindowTextW(g_lbl2, b);
            if (p->iPos + p->iDelta > 100) return 1;   // 演示拦截：上限 100（范围虽是 120）
        }
        if (nm->idFrom == IDC_IP && nm->code == (UINT)IPN_FIELDCHANGED) {
            SendMessageW(g_ip, IPM_GETADDRESS, 0, 0);  // 示意：字段变化时可即时校验
        }
        return 0;
    }
    case WM_COMMAND:
        if (LOWORD(wParam) == IDC_REPORT && HIWORD(wParam) == BN_CLICKED)
            Report(hwnd);
        return 0;
    case WM_SIZE:
        Layout(hwnd);
        return 0;
    case WM_DESTROY:
        if (g_imgs) ImageList_Destroy(g_imgs);
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nCmdShow) {
    INITCOMMONCONTROLSEX icc = { sizeof(icc),
        ICC_BAR_CLASSES | ICC_UPDOWN_CLASS | ICC_HOTKEY_CLASS
        | ICC_INTERNET_CLASSES | ICC_USEREX_CLASSES };
    InitCommonControlsEx(&icc);

    WNDCLASSW wc = { .style = CS_HREDRAW | CS_VREDRAW, .lpfnWndProc = WndProc,
                     .hInstance = hInst, .hCursor = LoadCursorW(nullptr, IDC_ARROW),
                     .hbrBackground = (HBRUSH)(COLOR_WINDOW + 1),
                     .lpszClassName = L"InputControlsDemo" };
    RegisterClassW(&wc);

    HWND hwnd = CreateWindowExW(0, wc.lpszClassName, L"输入与调节控件五件套",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 560, 280,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nCmdShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
