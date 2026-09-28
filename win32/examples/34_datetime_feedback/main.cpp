// 34_datetime_feedback —— 第 9 章：日期时间与反馈控件
// DTP / 月历(日状态加粗) / 动画(无声 AVI) / 工具提示(静态文本 + 动态回叫)
#include <windows.h>
#include <commctrl.h>
#include <shlwapi.h>
#include <wchar.h>
#include <stdio.h>

#pragma comment(lib, "comctl32.lib")

constexpr int IDC_DTP     = 1001;
constexpr int IDC_MC      = 1002;
constexpr int IDC_ANIM    = 1003;
constexpr int IDC_PLAY    = 1004;   // 播放/停止
constexpr int IDC_BOOK    = 1005;   // "预约"按钮（挂动态提示）
constexpr int IDC_MC_LBL  = 1006;

HWND g_dtp, g_mc, g_anim, g_play, g_book, g_mcLbl, g_tip;
wchar_t g_aviPath[MAX_PATH] = L"";

static bool AviExists(const wchar_t* p) { return p && *p && GetFileAttributesW(p) != INVALID_FILE_ATTRIBUTES; }

static void ResolveAviPath() {
    // 依次尝试：exe 旁 → 源码目录（build\..\examples\34_datetime_feedback\）
    wchar_t dir[MAX_PATH];
    GetModuleFileNameW(nullptr, dir, MAX_PATH);
    wchar_t* slash = wcsrchr(dir, L'\\');
    if (slash) *slash = 0;
    swprintf_s(g_aviPath, MAX_PATH, L"%s\\demo.avi", dir);
    if (AviExists(g_aviPath)) return;
    swprintf_s(g_aviPath, MAX_PATH, L"%s\\..\\examples\\34_datetime_feedback\\demo.avi", dir);
    if (!AviExists(g_aviPath)) g_aviPath[0] = 0;
}

static void UpdateMcLabel() {
    SYSTEMTIME st = {};
    if (SendMessageW(g_mc, MCM_GETCURSEL, 0, (LPARAM)&st)) {
        wchar_t b[64];
        const wchar_t* wd[] = { L"日", L"一", L"二", L"三", L"四", L"五", L"六" };
        swprintf_s(b, 64, L"选中：%d-%02d-%02d（周%s）", st.wYear, st.wMonth, st.wDay, wd[st.wDayOfWeek]);
        SetWindowTextW(g_mcLbl, b);
    }
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        HINSTANCE inst = ((LPCREATESTRUCTW)lParam)->hInstance;

        // ① DTP：数据模型就是 SYSTEMTIME
        CreateWindowExW(0, L"STATIC", L"预约日期（检出器）：",
            WS_CHILD | WS_VISIBLE, 30, 20, 190, 20, hwnd, nullptr, inst, nullptr);
        g_dtp = CreateWindowExW(0, DATETIMEPICK_CLASSW, nullptr,
            WS_CHILD | WS_VISIBLE | DTS_SHORTDATEFORMAT,
            30, 44, 170, 26, hwnd, (HMENU)(INT_PTR)IDC_DTP, inst, nullptr);

        // ② 月历：日状态由 MCN_GETDAYSTATE 供给
        g_mc = CreateWindowExW(0, MONTHCAL_CLASSW, nullptr,
            WS_CHILD | WS_VISIBLE | MCS_NOTODAYCIRCLE,
            240, 20, 191, 160, hwnd, (HMENU)(INT_PTR)IDC_MC, inst, nullptr);
        g_mcLbl = CreateWindowExW(0, L"STATIC", L"选中：",
            WS_CHILD | WS_VISIBLE, 30, 78, 200, 20,
            hwnd, (HMENU)(INT_PTR)IDC_MC_LBL, inst, nullptr);
        UpdateMcLabel();

        // ③ 动画：无声 AVI（ffmpeg 生成的 rawvideo 测试片）
        CreateWindowExW(0, L"STATIC", L"动画（无声 AVI）：",
            WS_CHILD | WS_VISIBLE, 30, 120, 190, 20, hwnd, nullptr, inst, nullptr);
        g_anim = CreateWindowExW(0, ANIMATE_CLASSW, nullptr,
            WS_CHILD | WS_VISIBLE | ACS_CENTER | ACS_TRANSPARENT | ACS_AUTOPLAY,
            30, 144, 70, 60, hwnd, (HMENU)(INT_PTR)IDC_ANIM, inst, nullptr);
        ResolveAviPath();
        if (*g_aviPath) {
            if (!SendMessageW(g_anim, ACM_OPENW, 0, (LPARAM)g_aviPath))
                MessageBoxW(hwnd, L"AVI 打开失败（检查文件是否无声）", L"动画", MB_ICONWARNING);
        } else {
            MessageBoxW(hwnd, L"未找到 demo.avi", L"动画", MB_ICONWARNING);
        }
        g_play = CreateWindowExW(0, L"BUTTON", L"停止",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, 120, 160, 70, 26,
            hwnd, (HMENU)(INT_PTR)IDC_PLAY, inst, nullptr);

        // ④ 工具提示：静态文本 + 动态回叫两种
        g_book = CreateWindowExW(0, L"BUTTON", L"预约",
            WS_CHILD | WS_VISIBLE | BS_PUSHBUTTON, 30, 220, 90, 30,
            hwnd, (HMENU)(INT_PTR)IDC_BOOK, inst, nullptr);

        g_tip = CreateWindowExW(WS_EX_TOPMOST, TOOLTIPS_CLASSW, nullptr,
            WS_POPUP | TTS_NOPREFIX | TTS_ALWAYSTIP,
            0, 0, 0, 0, hwnd, nullptr, inst, nullptr);
        SendMessageW(g_tip, TTM_SETMAXTIPWIDTH, 0, 300);   // 允许多行

        TOOLINFOW ti = { .cbSize = sizeof(ti) };
        ti.uFlags = TTF_SUBCLASS | TTF_IDISHWND;           // 寄生：自己子类化目标取鼠标消息
        ti.hwnd = hwnd;

        ti.uId = (UINT_PTR)g_play;                         // 工具一：固定文本
        ti.lpszText = (LPWSTR)L"播放 / 停止 AVI 动画";
        SendMessageW(g_tip, TTM_ADDTOOLW, 0, (LPARAM)&ti);

        ti.uId = (UINT_PTR)g_book;                         // 工具二：动态回叫
        ti.lpszText = LPSTR_TEXTCALLBACK;
        SendMessageW(g_tip, TTM_ADDTOOLW, 0, (LPARAM)&ti);

        ti.uId = (UINT_PTR)g_dtp;                          // 工具三：动态回叫
        ti.lpszText = LPSTR_TEXTCALLBACK;
        SendMessageW(g_tip, TTM_ADDTOOLW, 0, (LPARAM)&ti);
        return 0;
    }
    case WM_NOTIFY: {
        LPNMHDR nm = (LPNMHDR)lParam;
        if (nm->idFrom == IDC_DTP && nm->code == (UINT)DTN_DATETIMECHANGE) {
            NMDATETIMECHANGE* ch = (NMDATETIMECHANGE*)lParam;
            if (ch->dwFlags == GDT_VALID)                     // GDT_NONE = 被清空
                SendMessageW(g_mc, MCM_SETCURSEL, 0, (LPARAM)&ch->st);
        }
        if (nm->idFrom == IDC_MC && nm->code == (UINT)MCN_GETDAYSTATE) {
            NMDAYSTATE* ds = (NMDAYSTATE*)lParam;             // 控件来问：每月 5、19 日加粗
            for (DWORD i = 0; i < ds->cDayState; ++i)
                ds->prgDayState[i] = (1u << 4) | (1u << 18);
            return TRUE;
        }
        if (nm->idFrom == IDC_MC && nm->code == (UINT)MCN_SELCHANGE)
            UpdateMcLabel();
        if (nm->hwndFrom == g_tip && nm->code == (UINT)TTN_GETDISPINFOW) {
            NMTTDISPINFOW* di = (NMTTDISPINFOW*)lParam;        // 动态文本：显示时现算
            if (di->hdr.idFrom == (UINT_PTR)g_book) {
                lstrcpynW(di->szText, L"确认预约（提示文本由 TTN_GETDISPINFO 现场提供）", 80);
            } else {
                SYSTEMTIME st = {};
                SendMessageW(g_dtp, DTM_GETSYSTEMTIME, 0, (LPARAM)&st);
                swprintf_s(di->szText, 80, L"当前检出器值：%d-%02d-%02d",
                           st.wYear, st.wMonth, st.wDay);
            }
            return TRUE;
        }
        return 0;
    }
    case WM_COMMAND:
        if (HIWORD(wParam) == ACN_START || HIWORD(wParam) == ACN_STOP) {
            // 动画控件的通知走 WM_COMMAND（与 WM_NOTIFY 族不同）
            SetWindowTextW(g_play, HIWORD(wParam) == ACN_START ? L"停止" : L"播放");
            return 0;
        }
        if (LOWORD(wParam) == IDC_PLAY && HIWORD(wParam) == BN_CLICKED) {
            static bool playing = true;
            if (playing) SendMessageW(g_anim, ACM_STOP, 0, 0);
            else         SendMessageW(g_anim, ACM_PLAY, (WPARAM)-1, MAKELONG(0, (WORD)-1));
            playing = !playing;
        }
        if (LOWORD(wParam) == IDC_BOOK && HIWORD(wParam) == BN_CLICKED) {
            SYSTEMTIME a = {}, b = {};
            SendMessageW(g_dtp, DTM_GETSYSTEMTIME, 0, (LPARAM)&a);
            SendMessageW(g_mc, MCM_GETCURSEL, 0, (LPARAM)&b);
            wchar_t buf[160];
            swprintf_s(buf, 160, L"预约（检出器）：%d-%02d-%02d\n选中（月历）：%d-%02d-%02d\n（每月 5、19 日为加粗日）",
                       a.wYear, a.wMonth, a.wDay, b.wYear, b.wMonth, b.wDay);
            MessageBoxW(hwnd, buf, L"预约摘要", MB_OK);
        }
        return 0;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nCmdShow) {
    INITCOMMONCONTROLSEX icc = { sizeof(icc),
        ICC_DATE_CLASSES | ICC_ANIMATE_CLASS | ICC_BAR_CLASSES };
    InitCommonControlsEx(&icc);

    WNDCLASSW wc = { .style = CS_HREDRAW | CS_VREDRAW, .lpfnWndProc = WndProc,
                     .hInstance = hInst, .hCursor = LoadCursorW(nullptr, IDC_ARROW),
                     .hbrBackground = (HBRUSH)(COLOR_WINDOW + 1),
                     .lpszClassName = L"DatetimeFeedbackDemo" };
    RegisterClassW(&wc);

    HWND hwnd = CreateWindowExW(0, wc.lpszClassName, L"日期时间与反馈控件",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 480, 320,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nCmdShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
