// 32_clipboard_dnd — 剪贴板 CF_UNICODETEXT 全链路 + WM_DROPFILES + 手写 IDropTarget
//
// 对应教程：docs/29-剪贴板与拖放.md
// OLE 拖放要求用 OleInitialize（不能用 CoInitialize）
#include <windows.h>
#include <oleidl.h>

#define IDC_SRC      1401
#define IDC_DST      1402
#define IDC_COPY     1403
#define IDC_PASTE    1404
#define IDC_DROPLIST 1405

static HWND g_src, g_dst, g_dropList;

// ── 剪贴板：写（四步协议：开→清→设→关）────────────────────────
static bool CopyToClipboard(HWND hwnd, const wchar_t* text) {
    if (!OpenClipboard(hwnd)) return false;      // 独占打开
    EmptyClipboard();                            // 清空并取得所有权
    size_t bytes = (lstrlenW(text) + 1) * sizeof(wchar_t);
    HGLOBAL mem = GlobalAlloc(GMEM_MOVEABLE, bytes);   // 必须可移动内存
    if (!mem) { CloseClipboard(); return false; }
    CopyMemory(GlobalLock(mem), text, bytes);
    GlobalUnlock(mem);
    SetClipboardData(CF_UNICODETEXT, mem);       // 所有权交给剪贴板：不再 GlobalFree！
    CloseClipboard();
    return true;
}

// ── 剪贴板：读 ──────────────────────────────────────────────
static bool PasteFromClipboard(HWND hwnd, wchar_t* buf, size_t cap) {
    if (!OpenClipboard(hwnd)) return false;
    bool ok = false;
    HANDLE h = GetClipboardData(CF_UNICODETEXT);
    if (h) {
        const wchar_t* p = (const wchar_t*)GlobalLock(h);
        if (p) {
            lstrcpynW(buf, p, (int)cap);
            GlobalUnlock(h);
            ok = true;
        }
    }
    CloseClipboard();
    return ok;
}

// ── 手写 COM 接口：IDropTarget（第 24 章知识的第二次实战）──────
class DropTarget : public IDropTarget {
    LONG m_ref = 1;
public:
    STDMETHODIMP QueryInterface(REFIID riid, void** ppv) override {
        if (riid == IID_IUnknown || riid == IID_IDropTarget) {
            *ppv = static_cast<IDropTarget*>(this);
            AddRef();
            return S_OK;
        }
        *ppv = nullptr;
        return E_NOINTERFACE;
    }
    STDMETHODIMP_(ULONG) AddRef() override { return InterlockedIncrement(&m_ref); }
    STDMETHODIMP_(ULONG) Release() override {
        ULONG n = InterlockedDecrement(&m_ref);
        if (n == 0) delete this;
        return n;
    }
    STDMETHODIMP DragEnter(IDataObject* obj, DWORD, POINTL, DWORD* effect) override {
        FORMATETC fmt = { CF_HDROP, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL };
        *effect = (obj->QueryGetData(&fmt) == S_OK) ? DROPEFFECT_COPY
                                                    : DROPEFFECT_NONE;
        return S_OK;
    }
    STDMETHODIMP DragOver(DWORD, POINTL, DWORD* effect) override {
        *effect = DROPEFFECT_COPY;
        return S_OK;
    }
    STDMETHODIMP DragLeave() override { return S_OK; }
    STDMETHODIMP Drop(IDataObject* obj, DWORD, POINTL, DWORD* effect) override {
        *effect = DROPEFFECT_COPY;
        FORMATETC fmt = { CF_HDROP, nullptr, DVASPECT_CONTENT, -1, TYMED_HGLOBAL };
        STGMEDIUM medium = {};
        if (SUCCEEDED(obj->GetData(&fmt, &medium))) {
            HDROP hDrop = (HDROP)GlobalLock(medium.hGlobal);
            if (hDrop) {
                UINT n = DragQueryFileW(hDrop, 0xFFFFFFFF, nullptr, 0);
                for (UINT i = 0; i < n && i < 8; ++i) {
                    wchar_t path[MAX_PATH];
                    DragQueryFileW(hDrop, i, path, MAX_PATH);
                    SendMessageW(g_dropList, LB_ADDSTRING, 0, (LPARAM)path);
                }
                GlobalUnlock(medium.hGlobal);
            }
            ReleaseStgMedium(&medium);       // StgMedium 必须释放
        }
        return S_OK;
    }
};

static DropTarget* g_drop = nullptr;

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        CREATESTRUCTW* cs = (CREATESTRUCTW*)lParam;
        g_src = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"这段文字可以复制到剪贴板",
            WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL, 10, 10, 360, 26, hwnd,
            (HMENU)(UINT_PTR)IDC_SRC, cs->hInstance, nullptr);
        CreateWindowExW(0, L"BUTTON", L"复制",
            WS_CHILD | WS_VISIBLE, 380, 10, 70, 26, hwnd,
            (HMENU)(UINT_PTR)IDC_COPY, cs->hInstance, nullptr);
        g_dst = CreateWindowExW(WS_EX_CLIENTEDGE, L"EDIT", L"粘贴到这里",
            WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL, 10, 46, 360, 26, hwnd,
            (HMENU)(UINT_PTR)IDC_DST, cs->hInstance, nullptr);
        CreateWindowExW(0, L"BUTTON", L"粘贴",
            WS_CHILD | WS_VISIBLE, 380, 46, 70, 26, hwnd,
            (HMENU)(UINT_PTR)IDC_PASTE, cs->hInstance, nullptr);
        g_dropList = CreateWindowExW(WS_EX_CLIENTEDGE, L"LISTBOX", nullptr,
            WS_CHILD | WS_VISIBLE | LBS_NOTIFY, 10, 90, 440, 180, hwnd,
            (HMENU)(UINT_PTR)IDC_DROPLIST, cs->hInstance, nullptr);

        DragAcceptFiles(hwnd, TRUE);          // 姿势一：WM_DROPFILES（窗口级）
        g_drop = new DropTarget();            // 姿势二：OLE 拖放（列表框级）
        RegisterDragDrop(g_dropList, g_drop);
        return 0;
    }
    case WM_DROPFILES: {
        HDROP hDrop = (HDROP)wParam;
        UINT n = DragQueryFileW(hDrop, 0xFFFFFFFF, nullptr, 0);
        for (UINT i = 0; i < n && i < 8; ++i) {
            wchar_t path[MAX_PATH];
            DragQueryFileW(hDrop, i, path, MAX_PATH);
            SendMessageW(g_dropList, LB_ADDSTRING, 0, (LPARAM)path);
        }
        DragFinish(hDrop);
        return 0;
    }
    case WM_COMMAND:
        switch (LOWORD(wParam)) {
        case IDC_COPY: {
            wchar_t text[256];
            GetWindowTextW(g_src, text, 256);
            CopyToClipboard(hwnd, text);
            return 0;
        }
        case IDC_PASTE: {
            wchar_t text[256] = L"";
            if (PasteFromClipboard(hwnd, text, 256)) {
                SetWindowTextW(g_dst, text);
            }
            return 0;
        }
        }
        break;
    case WM_DESTROY:
        RevokeDragDrop(g_dropList);
        if (g_drop) g_drop->Release();
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nShow) {
    if (FAILED(OleInitialize(nullptr))) return 1;   // OLE 拖放专用初始化

    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"ClipDndClass";
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, L"ClipDndClass", L"剪贴板与拖放（往列表框拖文件试试）",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 480, 320,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    OleUninitialize();
    return (int)msg.wParam;
}
