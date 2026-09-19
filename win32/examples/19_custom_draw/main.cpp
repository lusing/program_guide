// 19_custom_draw — Owner Draw 按钮 + Custom Draw 隔行变色 + 子类化大写输入
//
// 对应教程：docs/08-自绘与子类化.md
#include <windows.h>
#include <commctrl.h>
#include <stdio.h>

#define IDC_ODBTN 1201
#define IDC_LIST  1202
#define IDC_EDIT  1203

// ── 子类化：拦截编辑框的 WM_CHAR，小写自动转大写 ────────────────────
LRESULT CALLBACK SubEditProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam,
                             UINT_PTR uIdSubclass, DWORD_PTR) {
    if (msg == WM_CHAR && wParam >= L'a' && wParam <= L'z') {
        wParam -= L'a' - L'A';      // 改写参数再交给原过程——子类化的本质
    }
    return DefSubclassProc(hwnd, msg, wParam, lParam);   // 原过程只收四个参数
}

static void CreateList(HWND parent, HINSTANCE inst) {
    HWND lv = CreateWindowExW(0, WC_LISTVIEWW, nullptr,
        WS_CHILD | WS_VISIBLE | WS_BORDER | LVS_REPORT | LVS_SHOWSELALWAYS,
        10, 60, 400, 240, parent, (HMENU)(INT_PTR)IDC_LIST, inst, nullptr);
    LVCOLUMNW col = { .mask = LVCF_TEXT | LVCF_WIDTH, .cx = 380 };
    col.pszText = (LPWSTR)L"条目（隔行变色由 Custom Draw 绘制）";
    SendMessageW(lv, LVM_INSERTCOLUMNW, 0, (LPARAM)&col);
    SendMessageW(lv, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT);
    for (int i = 0; i < 6; ++i) {
        wchar_t buf[64]; swprintf_s(buf, L"第 %d 行：底色不是系统的，是我们画的", i + 1);
        LVITEMW it = { .mask = LVIF_TEXT, .iItem = i, .pszText = buf };
        SendMessageW(lv, LVM_INSERTITEMW, 0, (LPARAM)&it);
    }
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        CREATESTRUCTW* cs = (CREATESTRUCTW*)lParam;
        // 自绘按钮：样式声明"我要自己画"，绘制发生在父窗口的 WM_DRAWITEM
        CreateWindowExW(0, L"BUTTON", L"",
            WS_CHILD | WS_VISIBLE | BS_OWNERDRAW,
            10, 10, 160, 40, hwnd, (HMENU)(INT_PTR)IDC_ODBTN, cs->hInstance, nullptr);
        CreateList(hwnd, cs->hInstance);
        HWND edit = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"在这里输入小写字母试试",
            WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL,
            10, 320, 400, 26, hwnd, (HMENU)(INT_PTR)IDC_EDIT, cs->hInstance, nullptr);
        SetWindowSubclass(edit, SubEditProc, 1, 0);   // 现代子类化（comctl32）
        return 0;
    }
    case WM_DRAWITEM: {
        // Owner Draw 事件：系统已备好 DC 和区域，我们只管画
        DRAWITEMSTRUCT* dis = (DRAWITEMSTRUCT*)lParam;
        if (dis->CtlID != IDC_ODBTN) break;
        COLORREF bg = (dis->itemState & ODS_SELECTED) ? RGB(0x7A, 0x1F, 0xC8)
                                                      : RGB(0x2B, 0x7B, 0xD5);
        HBRUSH brush = CreateSolidBrush(bg);
        FillRect(dis->hDC, &dis->rcItem, brush);
        DeleteObject(brush);
        SetBkMode(dis->hDC, TRANSPARENT);
        SetTextColor(dis->hDC, RGB(255, 255, 255));
        DrawTextW(dis->hDC, L"自绘按钮（按下变色）", -1, &dis->rcItem,
                  DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        return TRUE;   // 已处理
    }
    case WM_NOTIFY: {
        LPNMHDR nm = (LPNMHDR)lParam;
        if (nm->idFrom == IDC_LIST && nm->code == NM_CUSTOMDRAW) {
            LPNMLVCUSTOMDRAW cd = (LPNMLVCUSTOMDRAW)lParam;
            switch (cd->nmcd.dwDrawStage) {
            case CDDS_PREPAINT:
                return CDRF_NOTIFYITEMDRAW;   // 第一阶段：申请逐项通知
            case CDDS_ITEMPREPAINT: {          // 第二阶段：逐项绘制前改颜色
                int row = (int)cd->nmcd.dwItemSpec;
                cd->clrTextBk = (row % 2) ? RGB(0xE4, 0xEF, 0xFB) : RGB(255, 255, 255);
                return CDRF_NEWFONT;           // 声明"颜色我改了"
            }
            }
        }
        break;
    }
    case WM_DESTROY: {
        HWND edit = GetDlgItem(hwnd, IDC_EDIT);
        if (edit) RemoveWindowSubclass(edit, SubEditProc, 1);
        PostQuitMessage(0);
        return 0;
    }
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nShow) {
    INITCOMMONCONTROLSEX icc = { sizeof(icc), ICC_LISTVIEW_CLASSES };
    InitCommonControlsEx(&icc);

    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"CustomDrawClass";
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, L"CustomDrawClass", L"自绘与子类化",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 440, 400,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
