// 26_com_file_dialog — CoInitializeEx + ComPtr + IFileOpenDialog 实战
//
// 对应教程：docs/23-COM实战.md
#include <windows.h>
#include <shobjidl_core.h>     // IFileOpenDialog、CLSID_FileOpenDialog
#include <wrl/client.h>        // Microsoft::WRL::ComPtr
#include <stdio.h>

#define IDC_OPEN 1301
#define IDC_PATH 1302

using Microsoft::WRL::ComPtr;

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_CREATE: {
        CREATESTRUCTW* cs = (CREATESTRUCTW*)lParam;
        CreateWindowExW(0, L"BUTTON", L"打开文件（COM 对话框）",
            WS_CHILD | WS_VISIBLE, 10, 10, 220, 36, hwnd,
            (HMENU)(INT_PTR)IDC_OPEN, cs->hInstance, nullptr);
        CreateWindowExW(0, L"STATIC", L"（点击按钮选择文件）",
            WS_CHILD | WS_VISIBLE, 10, 64, 560, 24, hwnd,
            (HMENU)(INT_PTR)IDC_PATH, cs->hInstance, nullptr);
        return 0;
    }
    case WM_COMMAND:
        if (LOWORD(wParam) == IDC_OPEN) {
            ComPtr<IFileOpenDialog> dlg;
            HRESULT hr = CoCreateInstance(CLSID_FileOpenDialog, nullptr,
                                          CLSCTX_INPROC_SERVER,
                                          IID_PPV_ARGS(&dlg));
            if (FAILED(hr)) return 0;

            FILEOPENDIALOGOPTIONS opts = 0;
            dlg->GetOptions(&opts);
            dlg->SetOptions(opts | FOS_FORCEFILESYSTEM | FOS_ALLOWMULTISELECT);

            hr = dlg->Show(hwnd);              // 模态：内部自转消息循环
            if (FAILED(hr)) {
                if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
                    SetWindowTextW(GetDlgItem(hwnd, IDC_PATH), L"（用户取消）");
                }
                return 0;
            }
            ComPtr<IShellItem> item;
            if (SUCCEEDED(dlg->GetResult(&item))) {
                PWSTR path = nullptr;
                item->GetDisplayName(SIGDN_FILESYSPATH, &path);
                SetWindowTextW(GetDlgItem(hwnd, IDC_PATH), path ? path : L"?");
                CoTaskMemFree(path);           // COM 内存统一走 IMalloc/CoTaskMem
            }
            return 0;
        }
        break;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

int WINAPI wWinMain(HINSTANCE hInst, HINSTANCE, PWSTR, int nShow) {
    // COM 使用前初始化（每线程一次），配对 CoUninitialize——一切 COM 程序的开场白
    if (FAILED(CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED))) return 1;

    WNDCLASSEXW wc = { sizeof(wc) };
    wc.lpfnWndProc = WndProc;
    wc.hInstance = hInst;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    wc.hbrBackground = (HBRUSH)(COLOR_WINDOW + 1);
    wc.lpszClassName = L"ComDialogClass";
    RegisterClassExW(&wc);

    HWND hwnd = CreateWindowExW(0, L"ComDialogClass", L"IFileOpenDialog 演示",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 620, 150,
        nullptr, nullptr, hInst, nullptr);
    ShowWindow(hwnd, nShow);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    CoUninitialize();
    return (int)msg.wParam;
}
