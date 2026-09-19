// 17_listview_treeview — ListView 报表视图 + TreeView 层级 + ImageList 共享
//
// 对应教程：docs/06-ListView与TreeView.md
#include <windows.h>
#include <commctrl.h>
#include <stdio.h>

#define IDC_LIST 1001
#define IDC_TREE 1002

struct Item { const wchar_t* name; const wchar_t* size; const wchar_t* type; };
static const Item kFiles[] = {
    { L"readme.md",  L"2 KB",   L"Markdown" },
    { L"build.ps1",  L"4 KB",   L"脚本"     },
    { L"win32.exe",  L"64 KB",  L"应用程序" },
    { L"笔记.txt",   L"1 KB",   L"文本文档" },
};

static HIMAGELIST g_icons;

static void CreateList(HWND parent, HINSTANCE inst) {
    HWND lv = CreateWindowExW(0, WC_LISTVIEWW, nullptr,
        WS_CHILD | WS_VISIBLE | WS_BORDER | LVS_REPORT | LVS_SHOWSELALWAYS,
        10, 10, 380, 300, parent, (HMENU)(INT_PTR)IDC_LIST, inst, nullptr);

    // 报表视图第一步：插列
    LVCOLUMNW col = { .mask = LVCF_TEXT | LVCF_WIDTH };
    const wchar_t* titles[] = { L"名称", L"大小", L"类型" };
    const int widths[] = { 180, 80, 100 };
    for (int i = 0; i < 3; ++i) {
        col.pszText = (LPWSTR)titles[i];
        col.cx = widths[i];
        SendMessageW(lv, LVM_INSERTCOLUMNW, i, (LPARAM)&col);
    }
    // 整行选中（报表视图的现代惯例）
    SendMessageW(lv, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, LVS_EX_FULLROWSELECT);

    // 图像列表：挂到 LVSIL_SMALL 后，LVIF_IMAGE 的 iImage 才生效
    g_icons = ImageList_Create(16, 16, ILC_COLOR32 | ILC_MASK, 0, 4);
    ImageList_AddIcon(g_icons, LoadIconW(nullptr, IDI_APPLICATION));
    ImageList_AddIcon(g_icons, LoadIconW(nullptr, IDI_INFORMATION));
    SendMessageW(lv, LVM_SETIMAGELIST, LVSIL_SMALL, (LPARAM)g_icons);

    // 行 = LVIF_IMAGE 的主项；列 = iSubItem 的子项
    for (int i = 0; i < 4; ++i) {
        LVITEMW it = { .mask = LVIF_TEXT | LVIF_IMAGE, .iItem = i, .iImage = i % 2 };
        it.pszText = (LPWSTR)kFiles[i].name;
        int idx = (int)SendMessageW(lv, LVM_INSERTITEMW, 0, (LPARAM)&it);

        for (int sub = 1; sub <= 2; ++sub) {
            LVITEMW si = { .mask = LVIF_TEXT, .iItem = idx, .iSubItem = sub };
            si.pszText = (LPWSTR)(sub == 1 ? kFiles[i].size : kFiles[i].type);
            SendMessageW(lv, LVM_SETITEMW, 0, (LPARAM)&si);
        }
    }
}

static HTREEITEM InsertTreeItem(HWND tv, const wchar_t* text, int img, HTREEITEM parent) {
    TVINSERTSTRUCTW ins = {};
    ins.hParent = parent;
    ins.item.mask = TVIF_TEXT | TVIF_IMAGE | TVIF_SELECTEDIMAGE;
    ins.item.pszText = (LPWSTR)text;
    ins.item.iImage = img;
    ins.item.iSelectedImage = img;
    return (HTREEITEM)SendMessageW(tv, TVM_INSERTITEMW, 0, (LPARAM)&ins);
}

static void CreateTree(HWND parent, HINSTANCE inst) {
    HWND tv = CreateWindowExW(0, WC_TREEVIEWW, nullptr,
        WS_CHILD | WS_VISIBLE | WS_BORDER | TVS_HASLINES | TVS_HASBUTTONS |
        TVS_LINESATROOT | TVS_SHOWSELALWAYS,
        400, 10, 230, 300, parent, (HMENU)(INT_PTR)IDC_TREE, inst, nullptr);
    SendMessageW(tv, TVM_SETIMAGELIST, TVSIL_NORMAL, (LPARAM)g_icons);  // 与列表共享

    HTREEITEM fruit = InsertTreeItem(tv, L"水果", 0, nullptr);  // 根节点
    InsertTreeItem(tv, L"苹果", 1, fruit);
    InsertTreeItem(tv, L"梨",   1, fruit);
    HTREEITEM veg = InsertTreeItem(tv, L"蔬菜", 0, nullptr);
    InsertTreeItem(tv, L"白菜", 1, veg);
    SendMessageW(tv, TVM_EXPAND, TVE_EXPAND, (LPARAM)fruit);
}

static void ShowSelection(HWND hwnd) {
    wchar_t text[128];
    HWND lv = GetDlgItem(hwnd, IDC_LIST);
    int sel = (int)SendMessageW(lv, LVM_GETNEXTITEM, (WPARAM)-1, LVNI_SELECTED);
    if (sel >= 0) {
        LVITEMW it = { .mask = LVIF_TEXT, .iItem = sel, .pszText = text, .cchTextMax = 128 };
        SendMessageW(lv, LVM_GETITEMW, 0, (LPARAM)&it);
    }
    HWND tv = GetDlgItem(hwnd, IDC_TREE);
    HTREEITEM hItem = (HTREEITEM)SendMessageW(tv, TVM_GETNEXTITEM, TVGN_CARET, 0);
    wchar_t treeText[128] = L"（无）";
    if (hItem) {
        TVITEMW ti = { .mask = TVIF_TEXT, .hItem = hItem, .pszText = treeText, .cchTextMax = 128 };
        SendMessageW(tv, TVM_GETITEMW, 0, (LPARAM)&ti);
    }
    wchar_t title[256];
    swprintf_s(title, L"列表选中：%s ｜ 树选中：%s",
               sel >= 0 ? text : L"（无）", treeText);
    SetWindowTextW(hwnd, title);
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_NOTIFY: {
        LPNMHDR nm = (LPNMHDR)lParam;
        // LVN_ITEMCHANGED 会成对触发（取消旧选中 + 选中新选中各一次），
        // 只在"新状态含选中"时刷新标题，避免重复
        if (nm->idFrom == IDC_LIST && nm->code == LVN_ITEMCHANGED) {
            LPNMLISTVIEW nlv = (LPNMLISTVIEW)lParam;
            if (nlv->uNewState & LVIS_SELECTED) ShowSelection(hwnd);
        }
        if (nm->idFrom == IDC_TREE && nm->code == TVN_SELCHANGEDW) {
            ShowSelection(hwnd);
        }
        return 0;
    }
    case WM_SIZE:
        MoveWindow(GetDlgItem(hwnd, IDC_LIST), 10, 10, 380, HIWORD(lParam) - 20, TRUE);
        MoveWindow(GetDlgItem(hwnd, IDC_TREE), 400, 10, LOWORD(lParam) - 410, HIWORD(lParam) - 20, TRUE);
        return 0;
    case WM_DESTROY:
        if (g_icons) ImageList_Destroy(g_icons);   // 图像列表要销毁
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nShow) {
    INITCOMMONCONTROLSEX icc = { sizeof(icc), ICC_LISTVIEW_CLASSES | ICC_TREEVIEW_CLASSES };
    InitCommonControlsEx(&icc);   // 通用控件（comctl32）必须先注册

    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"ListTreeClass";
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, L"ListTreeClass", L"ListView 与 TreeView",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 680, 400,
        nullptr, nullptr, hInst, nullptr);
    CreateList(hwnd, hInst);
    CreateTree(hwnd, hInst);
    ShowWindow(hwnd, nShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}
