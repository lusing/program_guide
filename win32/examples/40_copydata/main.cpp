// 40_copydata —— 第 4 章：WM_COPYDATA 跨进程传数据
// 双实例演示：先启动接收实例（默认模式），再带 -send 参数启动发送实例。
//   .\40_copydata.exe            → 接收方：显示收到的消息
//   .\40_copydata.exe -send 文本  → 发送方：把文本投给接收方后退出
#include <windows.h>
#include <wchar.h>
#include <stdio.h>

constexpr UINT WM_APP_NEWMSG = WM_APP + 1;      // 收到 COPYDATA 后的自定义通知（发给自己，刷标题栏）
constexpr wchar_t CLASS_NAME[] = L"CopyDataDemoWnd";

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    switch (msg) {
    case WM_COPYDATA: {                          // ★ 系统已把数据深拷贝进本进程，直接读
        auto* cds = (COPYDATASTRUCT*)lParam;
        wchar_t text[256] = {};
        MultiByteToWideChar(CP_UTF8, 0, (char*)cds->lpData, (int)cds->cbData,
                            text, 255);
        wchar_t title[320];
        swprintf_s(title, 320, L"收到 %zu 字节：%s（第 %lu 条）",
                   cds->cbData, text, (unsigned long)cds->dwData);
        SetWindowTextW(hwnd, title);             // 标题栏就是消息面板
        return TRUE;                             // 告诉发送方：处理成功
    }
    case WM_APP_NEWMSG:
        InvalidateRect(hwnd, nullptr, TRUE);
        return 0;
    case WM_DESTROY:
        PostQuitMessage(0);
        return 0;
    }
    return DefWindowProcW(hwnd, msg, wParam, lParam);
}

static int RunReceiver(HINSTANCE inst) {
    WNDCLASSW wc = { .lpfnWndProc = WndProc, .hInstance = inst,
                     .hCursor = LoadCursorW(nullptr, IDC_ARROW),
                     .hbrBackground = (HBRUSH)(COLOR_WINDOW + 1),
                     .lpszClassName = CLASS_NAME };
    RegisterClassW(&wc);
    HWND hwnd = CreateWindowExW(0, CLASS_NAME,
        L"WM_COPYDATA 接收方——启动发送方：40_copydata.exe -send 你好",
        WS_OVERLAPPEDWINDOW, CW_USEDEFAULT, CW_USEDEFAULT, 520, 160,
        nullptr, nullptr, inst, nullptr);
    ShowWindow(hwnd, SW_SHOW);

    MSG msg;
    while (GetMessageW(&msg, nullptr, 0, 0) > 0) {
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
    return (int)msg.wParam;
}

static int RunSender(const wchar_t* text) {
    HWND target = FindWindowW(CLASS_NAME, nullptr);   // 按类名找接收方
    if (!target) { printf("未找到接收方（先启动 40_copydata.exe）\n"); return 1; }

    char utf8[512];
    int n = WideCharToMultiByte(CP_UTF8, 0, text, -1, utf8, sizeof(utf8), nullptr, nullptr);

    static DWORD seq = 0;                              // dwData 带序号
    COPYDATASTRUCT cds = { .dwData = ++seq, .cbData = (DWORD)n, .lpData = utf8 };
    LRESULT ok = SendMessageW(target, WM_COPYDATA, (WPARAM)GetDesktopWindow(), (LPARAM)&cds);
    printf("已发送 %d 字节（第 %lu 条），接收方返回 %s\n",
           n, seq, ok ? "TRUE" : "FALSE");
    return 0;
}

int wmain(int argc, wchar_t** argv) {
    if (argc > 1 && wcscmp(argv[1], L"-send") == 0)
        return RunSender(argc > 2 ? argv[2] : L"hello from sender");
    return RunReceiver(GetModuleHandleW(nullptr));
}
