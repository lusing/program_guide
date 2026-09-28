// 35_rebar_propsheet —— 第 10 章：Rebar 与属性页
// Rebar 双 band（工具栏 + 地址栏）/ chevron / 下拉按钮 / 内存模板属性表 / 三页向导
#include <windows.h>
#include <commctrl.h>
#include <wchar.h>

#pragma comment(lib, "comctl32.lib")

constexpr int IDC_REBAR   = 1001;
constexpr int IDC_TOOLBAR = 1002;
constexpr int IDC_ADDR    = 1003;
constexpr int IDM_PROPSHEET = 2001;
constexpr int IDM_WIZARD    = 2002;
constexpr int IDM_EXIT      = 2003;

// 页内控件 ID
constexpr int IDC_PG_EDIT1 = 3001;   // 常规页/向导页的编辑框
constexpr int IDC_PG_CHK   = 3002;
constexpr int IDC_PG_EDIT2 = 3003;   // 高级页编辑框

HWND g_rebar, g_toolbar;

// ---------- 内存对话框模板（PSP_DLGINDIRECT，免 .rc 文件） ----------
struct DlgBuilder {
    unsigned char buf[2048];
    int len = 0;
    void align4() { while (len % 4) buf[len++] = 0; }
    void w(unsigned short v) { buf[len++] = (unsigned char)(v & 0xFF); buf[len++] = (unsigned char)(v >> 8); }
    void dw(unsigned long v) { w((unsigned short)(v & 0xFFFF)); w((unsigned short)(v >> 16)); }
    void str(const wchar_t* s) { while (*s) w(*s++); w(0); }
};

// 生成一页模板：static/edit/check 的组合由参数决定
static void* MakePageTemplate(bool withEdit, const wchar_t* label1,
                              bool withCheck, const wchar_t* checkText) {
    static DlgBuilder b[4];
    static int which = 0;
    DlgBuilder* d = &b[which++ % 4];          // 多页并存，轮转缓冲

    d->len = 0;
    // DLGTEMPLATE：WS_CHILD|DS_CONTROL|DS_3DLOOK，页标题由 PSP_USETITLE 提供
    int nItems = withCheck ? 4 : 2;            // (label, edit) (+check, edit2)
    d->dw(WS_CHILD | DS_CONTROL | DS_3DLOOK); d->dw(0); d->w((unsigned short)nItems);
    d->w(0); d->w(0); d->w(200); d->w(80);     // x y cx cy（对话框单位）
    d->w(0); d->w(0);                          // menu / windowClass
    d->str(L"");                               // title

    // ① 静态标签
    d->align4();
    d->dw(WS_CHILD | WS_VISIBLE | SS_LEFT); d->dw(0);
    d->w(10); d->w(12); d->w(60); d->w(8); d->w((unsigned short)-1);
    d->w(0xFFFF); d->w(0x0082);                // Static
    d->str(label1); d->w(0);
    // ② 编辑框
    d->align4();
    d->dw(WS_CHILD | WS_VISIBLE | WS_TABSTOP | WS_BORDER | ES_AUTOHSCROLL); d->dw(0);
    d->w(75); d->w(10); d->w(110); d->w(12); d->w(IDC_PG_EDIT1);
    d->w(0xFFFF); d->w(0x0081);                // Edit
    d->str(L""); d->w(0);

    if (withCheck) {
        // ③ 复选框（Button 类自带文本）
        d->align4();
        d->dw(WS_CHILD | WS_VISIBLE | WS_TABSTOP | BS_AUTOCHECKBOX); d->dw(0);
        d->w(10); d->w(32); d->w(160); d->w(10); d->w(IDC_PG_CHK);
        d->w(0xFFFF); d->w(0x0080);            // Button
        d->str(checkText); d->w(0);
        // ④ 第二编辑框（高级页）
        d->align4();
        d->dw(WS_CHILD | WS_VISIBLE | WS_TABSTOP | WS_BORDER | ES_NUMBER); d->dw(0);
        d->w(75); d->w(48); d->w(110); d->w(12); d->w(IDC_PG_EDIT2);
        d->w(0xFFFF); d->w(0x0081);
        d->str(L"8080"); d->w(0);
    }
    return d->buf;
}

// ---------- 属性表页/向导页共用的对话框过程 ----------
static wchar_t g_userName[64] = L"admin";
static BOOL g_autoStart = FALSE;
static int   g_port = 8080;

INT_PTR CALLBACK PageProc(HWND hDlg, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_INITDIALOG: {
        // 属性页的 lParam 指向创建本页的 PROPSHEETPAGE 副本：向导步骤号从这里接线
        LPARAM lp = ((PROPSHEETPAGEW*)lParam)->lParam;   // 0=属性表页；100+i=向导第 i 页
        if (lp >= 100) {
            SetPropW(hDlg, L"WIZ", (HANDLE)1);
            SetPropW(hDlg, L"STEP", (HANDLE)(lp - 100));
        }
        SetDlgItemTextW(hDlg, IDC_PG_EDIT1, g_userName);
        if (GetDlgItem(hDlg, IDC_PG_CHK))   CheckDlgButton(hDlg, IDC_PG_CHK, g_autoStart ? BST_CHECKED : BST_UNCHECKED);
        return TRUE;
    }
    case WM_NOTIFY: {
        LPNMHDR nm = (LPNMHDR)lParam;
        switch (nm->code) {
        case PSN_SETACTIVE:                     // 向导：声明本页可用按钮
            if (GetPropW(hDlg, L"WIZ")) {
                int step = (int)(INT_PTR)GetPropW(hDlg, L"STEP");
                DWORD btns = (step == 1) ? PSWIZB_NEXT
                           : (step == 3) ? (PSWIZB_BACK | PSWIZB_FINISH)
                                         : (PSWIZB_BACK | PSWIZB_NEXT);
                PropSheet_SetWizButtons(hDlg, btns);
            }
            break;
        case PSN_KILLACTIVE:                    // 属性表：离开本页前校验
            SetWindowLongPtrW(hDlg, DWLP_MSGRESULT, FALSE);
            return TRUE;
        case PSN_WIZNEXT: {                     // 向导：第 2 页要求非空
            int step = (int)(INT_PTR)GetPropW(hDlg, L"STEP");
            if (step == 2) {
                wchar_t buf[64] = {};
                GetDlgItemTextW(hDlg, IDC_PG_EDIT1, buf, 64);
                if (!*buf) {
                    MessageBoxW(hDlg, L"项目名不能为空", L"向导", MB_ICONWARNING);
                    SetWindowLongPtrW(hDlg, DWLP_MSGRESULT, -1);   // 拒绝翻页
                    return TRUE;
                }
                lstrcpynW(g_userName, buf, 64);
            }
            break;
        }
        case PSN_APPLY:                         // 属性表：唯一提交点
            GetDlgItemTextW(hDlg, IDC_PG_EDIT1, g_userName, 64);
            g_autoStart = IsDlgButtonChecked(hDlg, IDC_PG_CHK) == BST_CHECKED;
            if (GetDlgItem(hDlg, IDC_PG_EDIT2))
                g_port = GetDlgItemInt(hDlg, IDC_PG_EDIT2, nullptr, FALSE);
            SetWindowLongPtrW(hDlg, DWLP_MSGRESULT, PSNRET_NOERROR);
            return TRUE;
        case PSN_WIZFINISH:
            MessageBoxW(hDlg, L"向导完成，配置已提交", L"向导", MB_OK);
            return TRUE;
        }
        break;
    }
    case WM_DESTROY:
        RemovePropW(hDlg, L"WIZ"); RemovePropW(hDlg, L"STEP");
        return 0;
    }
    return FALSE;
}

static void OpenPropSheet(HWND hwnd) {
    PROPSHEETPAGEW psp[2] = {};
    psp[0].dwSize = sizeof(psp[0]);
    psp[0].dwFlags = PSP_DEFAULT | PSP_USETITLE | PSP_DLGINDIRECT;
    psp[0].hInstance = GetModuleHandleW(nullptr);
    psp[0].pResource = (LPCDLGTEMPLATEW)MakePageTemplate(true, L"用户名：", true, L"开机自动启动");
    psp[0].pszTitle = L"常规";
    psp[0].pfnDlgProc = PageProc;

    psp[1] = psp[0];
    psp[1].pResource = (LPCDLGTEMPLATEW)MakePageTemplate(false, L"高级选项：", false, L"");
    psp[1].pszTitle = L"高级";

    PROPSHEETHEADERW psh = { .dwSize = sizeof(psh) };
    psh.dwFlags = PSH_PROPSHEETPAGE | PSH_NOCONTEXTHELP;
    psh.hwndParent = hwnd;
    psh.pszCaption = L"设置";
    psh.nPages = 2;
    psh.ppsp = psp;
    PropertySheetW(&psh);
}

static void OpenWizard(HWND hwnd) {
    PROPSHEETPAGEW psp[3] = {};
    for (int i = 0; i < 3; ++i) {
        psp[i].dwSize = sizeof(psp[0]);
        psp[i].dwFlags = PSP_DEFAULT | PSP_USETITLE | PSP_DLGINDIRECT;
        psp[i].hInstance = GetModuleHandleW(nullptr);
        psp[i].pfnDlgProc = PageProc;
    }
    psp[0].pResource = (LPCDLGTEMPLATEW)MakePageTemplate(false, L"欢迎使用向导", false, L"");
    psp[0].pszTitle = L"第 1 步";
    psp[1].pResource = (LPCDLGTEMPLATEW)MakePageTemplate(true, L"项目名：", false, L"");
    psp[1].pszTitle = L"第 2 步";
    psp[2].pResource = (LPCDLGTEMPLATEW)MakePageTemplate(false, L"即将完成", false, L"");
    psp[2].pszTitle = L"第 3 步";

    // 步骤号经 lParam 携带（100+i），PageProc 在 WM_INITDIALOG 里转成窗口属性
    for (int i = 0; i < 3; ++i) psp[i].lParam = (LPARAM)(100 + i + 1);

    PROPSHEETHEADERW psh = { .dwSize = sizeof(psh) };
    psh.dwFlags = PSH_PROPSHEETPAGE | PSH_WIZARD | PSH_NOCONTEXTHELP;
    psh.hwndParent = hwnd;
    psh.pszCaption = L"新建向导";
    psh.nPages = 3;
    psh.ppsp = psp;
    PropertySheetW(&psh);
}

// ---------- 主窗口 ----------
static void ShowHiddenByChevron(HWND hwnd, UINT uBand, RECT rcChevron) {
    // 参考库第 6.3.1 节算法的简化版：找出被 band 右边界挡住的按钮弹菜单
    RECT rcBand = {};
    SendMessageW(g_rebar, RB_GETRECT, uBand, (LPARAM)&rcBand);
    HMENU menu = CreatePopupMenu();
    int shown = 0;
    int count = (int)SendMessageW(g_toolbar, TB_BUTTONCOUNT, 0, 0);
    for (int i = 0; i < count; ++i) {
        RECT rcBtn = {};
        SendMessageW(g_toolbar, TB_GETITEMRECT, i, (LPARAM)&rcBtn);
        // 把按钮右缘换算到 rebar 坐标（band 左端 + 工具栏内偏移；夹具宽度用 20px 余量吸收）
        if (rcBand.left + rcBtn.right > rcBand.right - 20) {
            wchar_t txt[64] = {};
            TBBUTTONINFOW bi = { .cbSize = sizeof(bi), .dwMask = TBIF_TEXT | TBIF_COMMAND,
                                 .pszText = txt, .cchText = 64 };
            if (SendMessageW(g_toolbar, TB_GETBUTTONINFOW, i, (LPARAM)&bi) != -1) {
                AppendMenuW(menu, MF_STRING, bi.idCommand, txt[0] ? txt : L"(无标签)");
                ++shown;
            }
        }
    }
    if (!shown) AppendMenuW(menu, MF_STRING | MF_GRAYED, 0, L"（无被挡按钮）");
    POINT pt = { rcChevron.left, rcChevron.bottom };
    ClientToScreen(hwnd, &pt);
    TrackPopupMenu(menu, TPM_LEFTALIGN | TPM_TOPALIGN, pt.x, pt.y, 0, hwnd, nullptr);
    DestroyMenu(menu);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        HINSTANCE inst = ((LPCREATESTRUCTW)lParam)->hInstance;

        // ① Rebar 容器
        g_rebar = CreateWindowExW(WS_EX_TOOLWINDOW, REBARCLASSNAMEW, nullptr,
            WS_CHILD | WS_VISIBLE | WS_CLIPCHILDREN | WS_CLIPSIBLINGS
            | CCS_NODIVIDER | CCS_NOPARENTALIGN | RBS_BANDBORDERS | RBS_VARHEIGHT,
            0, 0, 0, 0, hwnd, (HMENU)(INT_PTR)IDC_REBAR, inst, nullptr);

        // ② band-1：平面工具栏（含一个下拉按钮）
        g_toolbar = CreateWindowExW(0, TOOLBARCLASSNAMEW, nullptr,
            WS_CHILD | WS_VISIBLE | TBSTYLE_FLAT | TBSTYLE_TOOLTIPS | CCS_NODIVIDER,
            0, 0, 0, 0, g_rebar, (HMENU)(INT_PTR)IDC_TOOLBAR, inst, nullptr);
        SendMessageW(g_toolbar, TB_BUTTONSTRUCTSIZE, sizeof(TBBUTTON), 0);
        SendMessageW(g_toolbar, TB_LOADIMAGES, IDB_STD_SMALL_COLOR, (LPARAM)HINST_COMMCTRL);
        TBBUTTON btns[] = {
            { STD_FILENEW,  11, TBSTATE_ENABLED, BTNS_BUTTON,   {}, 0, (INT_PTR)L"新建" },
            { STD_FILEOPEN, 12, TBSTATE_ENABLED, BTNS_BUTTON,   {}, 0, (INT_PTR)L"打开" },
            { STD_UNDO,     13, TBSTATE_ENABLED, BTNS_DROPDOWN, {}, 0, (INT_PTR)L"撤销（下拉）" },
        };
        SendMessageW(g_toolbar, TB_ADDBUTTONSW, 3, (LPARAM)btns);
        SendMessageW(g_toolbar, TB_AUTOSIZE, 0, 0);

        REBARBANDINFOW rbi = { .cbSize = sizeof(rbi) };
        rbi.fMask = RBBIM_STYLE | RBBIM_CHILD | RBBIM_CHILDSIZE | RBBIM_SIZE;
        rbi.fStyle = RBBS_GRIPPERALWAYS;
        rbi.hwndChild = g_toolbar;
        rbi.cxMinChild = 0; rbi.cyMinChild = 30; rbi.cx = 200;
        SendMessageW(g_rebar, RB_INSERTBANDW, (WPARAM)-1, (LPARAM)&rbi);

        // ③ band-2：地址栏（启用 chevron）
        HWND addr = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"about:blank",
            WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL,
            0, 0, 200, 24, g_rebar, (HMENU)(INT_PTR)IDC_ADDR, inst, nullptr);
        rbi.fMask = RBBIM_STYLE | RBBIM_CHILD | RBBIM_CHILDSIZE | RBBIM_SIZE | RBBIM_TEXT;
        rbi.fStyle = RBBS_GRIPPERALWAYS | RBBS_USECHEVRON;       // ★ 挤窄出 »
        rbi.hwndChild = addr;
        rbi.lpText = (LPWSTR)L"地址";
        rbi.cxMinChild = 60; rbi.cyMinChild = 24; rbi.cx = 220;
        SendMessageW(g_rebar, RB_INSERTBANDW, (WPARAM)-1, (LPARAM)&rbi);

        // ④ 菜单
        HMENU bar = CreateMenu(), m = CreatePopupMenu();
        AppendMenuW(m, MF_STRING, IDM_PROPSHEET, L"设置…（属性表）");
        AppendMenuW(m, MF_STRING, IDM_WIZARD, L"新建向导…");
        AppendMenuW(m, MF_SEPARATOR, 0, nullptr);
        AppendMenuW(m, MF_STRING, IDM_EXIT, L"退出");
        AppendMenuW(bar, MF_POPUP, (UINT_PTR)m, L"文件(&F)");
        SetMenu(hwnd, bar);
        return 0;
    }
    case WM_SIZE:
        SendMessageW(g_rebar, WM_SIZE, wParam, lParam);   // ★ 转发给 Rebar
        return 0;
    case WM_NOTIFY: {
        LPNMHDR nm = (LPNMHDR)lParam;
        if (nm->idFrom == IDC_TOOLBAR && nm->code == TBN_DROPDOWN) {
            NMTOOLBARW* nmtb = (NMTOOLBARW*)lParam;       // 下拉按钮 → 弹菜单
            HMENU menu = CreatePopupMenu();
            AppendMenuW(menu, MF_STRING, 21, L"撤销一步");
            AppendMenuW(menu, MF_STRING, 22, L"撤销全部");
            POINT pt = { nmtb->rcButton.left, nmtb->rcButton.bottom };
            ClientToScreen(g_toolbar, &pt);
            TrackPopupMenu(menu, TPM_LEFTALIGN | TPM_TOPALIGN, pt.x, pt.y, 0, hwnd, nullptr);
            DestroyMenu(menu);
            return TBDDRET_DEFAULT;
        }
        if (nm->idFrom == IDC_REBAR && nm->code == RBN_CHEVRONPUSHED) {
            NMREBARCHEVRON* chev = (NMREBARCHEVRON*)lParam;
            if (chev->uBand == 1)                          // 地址栏被挤窄
                MessageBoxW(hwnd, L"地址栏太窄——把内容缩短或拉宽窗口", L"Chevron", MB_OK);
            else
                ShowHiddenByChevron(hwnd, chev->uBand, chev->rc);
            return 0;
        }
        return 0;
    }
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDM_PROPSHEET: OpenPropSheet(hwnd); return 0;
        case IDM_WIZARD:    OpenWizard(hwnd);    return 0;
        case IDM_EXIT:      DestroyWindow(hwnd); return 0;
        case 11: case 12:
            MessageBoxW(hwnd, L"工具栏命令（与菜单同一 WM_COMMAND 通道）", L"命令", MB_OK);
            return 0;
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
        ICC_BAR_CLASSES | ICC_COOL_CLASSES | ICC_WIN95_CLASSES };
    InitCommonControlsEx(&icc);

    // 向导页的 lParam → 窗口属性（PageProc 里 GetProp 读回步骤号）
    // （PROPSHEETPAGE.lParam 会出现在 WM_INITDIALOG 的 lParam 指向的 PROPSHEETPAGE 副本中）

    WNDCLASSW wc = { .style = CS_HREDRAW | CS_VREDRAW, .lpfnWndProc = WndProc,
                     .hInstance = hInst, .hCursor = LoadCursorW(nullptr, IDC_ARROW),
                     .hbrBackground = (HBRUSH)(COLOR_WINDOW + 1),
                     .lpszClassName = L"RebarPropSheetDemo" };
    RegisterClassW(&wc);

    HWND hwnd = CreateWindowExW(0, wc.lpszClassName, L"Rebar 与属性页",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 560, 260,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nCmdShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
