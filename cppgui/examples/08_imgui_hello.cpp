// ============================================================
// 08_imgui_hello.cpp —— Dear ImGui 完整骨架：Win32 平台后端 + D3D11 渲染后端
//
// 即时模式范式导读：
//   保留模式（wx）：先建控件树，事件回调改状态，需要时重绘；
//   即时模式（imgui）：主循环每帧重新"执行"一遍界面代码，
//   控件状态（按钮是否按下、滑条新值）用【返回值】当场告诉你，
//   应用状态完全外置于你自己的变量——没有隐藏的控件对象。
// 后端 = 两个插拔点：平台后端（窗口/输入：imgui_impl_win32）
//   + 渲染后端（画三角形：imgui_impl_dx11）。换 SDL2/GL 只换这两点
//   （对照 08_imgui_hello_sdl2.cpp），业务 UI 代码一字不改。
// 三段式：初始化 → 主循环（消息→NewFrame→UI→Render→Present）→ 清理。
//
// 本地源码：G:/github/cpp/imgui（1.93.0 WIP master，无 docking/多视口）
// 官方骨架：examples/example_win32_directx11/main.cpp
// ============================================================
#include "imgui.h"
#include "imgui_impl_win32.h"  // 平台后端
#include "imgui_impl_dx11.h"   // 渲染后端
#include <d3d11.h>
#include <tchar.h>
#include <cstring>
#include <iostream>

// ---- D3D11 全局资源（简洁起见用全局，工程化可包成类）----
static ID3D11Device*           g_pd3dDevice = nullptr;
static ID3D11DeviceContext*    g_pd3dDeviceContext = nullptr;
static IDXGISwapChain*         g_pSwapChain = nullptr;
static bool                    g_SwapChainOccluded = false;
static UINT                    g_ResizeWidth = 0, g_ResizeHeight = 0;
static ID3D11RenderTargetView* g_mainRenderTargetView = nullptr;

bool CreateDeviceD3D(HWND hWnd);
void CleanupDeviceD3D();
void CreateRenderTarget();
void CleanupRenderTarget();
LRESULT WINAPI WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

int main(int argc, char** argv)
{
    const bool selftest = (argc > 1 && std::strcmp(argv[1], "--selftest") == 0);
    if (selftest) std::cout << "==== 08 ImGui 骨架（Win32+D3D11） 开始 ====\n";  // stdout

    // ---- 段一：初始化 -------------------------------------------
    // 1) DPI 感知 + 主显示器缩放系数
    ImGui_ImplWin32_EnableDpiAwareness();
    float main_scale = ImGui_ImplWin32_GetDpiScaleForMonitor(
        ::MonitorFromPoint(POINT{ 0, 0 }, MONITOR_DEFAULTTOPRIMARY));

    // 2) 原生 Win32 窗口（RegisterClass/CreateWindow，与纯 Win32 编程一致）
    WNDCLASSEXW wc = { sizeof(wc), CS_CLASSDC, WndProc, 0L, 0L,
                       GetModuleHandle(nullptr), nullptr, nullptr, nullptr, nullptr,
                       L"ImGui Example", nullptr };
    ::RegisterClassExW(&wc);
    HWND hwnd = ::CreateWindowW(wc.lpszClassName, L"08 - Dear ImGui + Win32 + D3D11",
        WS_OVERLAPPEDWINDOW, 100, 100,
        (int)(900 * main_scale), (int)(600 * main_scale),
        nullptr, nullptr, wc.hInstance, nullptr);

    // 3) D3D11 设备与交换链（硬件不行回退 WARP 软渲染）
    if (!CreateDeviceD3D(hwnd))
    {
        CleanupDeviceD3D();
        ::UnregisterClassW(wc.lpszClassName, wc.hInstance);
        return 1;
    }
    ::ShowWindow(hwnd, SW_SHOWDEFAULT);
    ::UpdateWindow(hwnd);

    // 4) ImGui 上下文 + 样式（DPI 缩放烘焙进 style）
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    ImGui::StyleColorsDark();
    ImGuiStyle& style = ImGui::GetStyle();
    style.ScaleAllSizes(main_scale);
    style.FontScaleDpi = main_scale;   // 1.93：字体 DPI 缩放字段

    // 5) 挂两个后端：平台（Win32）+ 渲染（D3D11）
    ImGui_ImplWin32_Init(hwnd);
    ImGui_ImplDX11_Init(g_pd3dDevice, g_pd3dDeviceContext);
    // 字体：默认嵌入了 ProggyClean 位图字体（仅 ASCII——中文要自载字体，
    // 见 12 章 docs/FONTS.md）；这里先显式装默认，演示字体入口。

    // ---- 应用状态：完全外置的普通变量（即时模式核心）----
    int   counter = 0;
    float f = 0.0f;
    bool  show_another = false;
    ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);

    // ---- 段二：主循环 -------------------------------------------
    bool done = false;
    int  frames = 0;
    while (!done)
    {
        // 1) Win32 消息泵（imgui 的输入经 WndProc 里的 handler 注入）
        MSG msg;
        while (::PeekMessage(&msg, nullptr, 0U, 0U, PM_REMOVE))
        {
            ::TranslateMessage(&msg);
            ::DispatchMessage(&msg);
            if (msg.message == WM_QUIT)
                done = true;
        }
        if (done) break;
        if (g_SwapChainOccluded && g_pSwapChain->Present(0, DXGI_PRESENT_TEST) == DXGI_STATUS_OCCLUDED)
        { ::Sleep(10); continue; }
        g_SwapChainOccluded = false;

        // 2) 处理窗口尺寸变化（WM_SIZE 里只记录，这里统一重建）
        if (g_ResizeWidth != 0 && g_ResizeHeight != 0)
        {
            CleanupRenderTarget();
            g_pSwapChain->ResizeBuffers(0, g_ResizeWidth, g_ResizeHeight, DXGI_FORMAT_UNKNOWN, 0);
            g_ResizeWidth = g_ResizeHeight = 0;
            CreateRenderTarget();
        }

        // 3) 新帧（顺序固定：渲染后端 → 平台后端 → NewFrame）
        ImGui_ImplDX11_NewFrame();
        ImGui_ImplWin32_NewFrame();
        ImGui::NewFrame();

        // 4) UI：每帧重新执行——注意读法："如果这一帧里按钮被按下，返回 true"
        {
            ImGui::Begin("Hello, imgui!");
            ImGui::Text("immediate mode: UI = plain code, state = plain vars");
            ImGui::SliderFloat("float", &f, 0.0f, 1.0f);
            ImGui::ColorEdit3("clear color", (float*)&clear_color);
            if (ImGui::Button("Button"))
                counter++;                      // 事件就是这一帧的返回值
            ImGui::SameLine();
            ImGui::Text("counter = %d", counter);
            ImGui::Checkbox("Another Window", &show_another);
            ImGui::End();
        }
        if (show_another)
        {
            ImGui::Begin("Another Window", &show_another);
            ImGui::Text("Hello from another window!");
            if (ImGui::Button("Close Me"))
                show_another = false;
            ImGui::End();
        }

        // 5) 渲染并呈现（vsync）
        ImGui::Render();
        const float cc[4] = { clear_color.x * clear_color.w, clear_color.y * clear_color.w,
                              clear_color.z * clear_color.w, clear_color.w };
        g_pd3dDeviceContext->OMSetRenderTargets(1, &g_mainRenderTargetView, nullptr);
        g_pd3dDeviceContext->ClearRenderTargetView(g_mainRenderTargetView, cc);
        ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
        g_SwapChainOccluded = (g_pSwapChain->Present(1, 0) == DXGI_STATUS_OCCLUDED);

        // selftest：跑满 40 帧即认为骨架健康，优雅退出
        if (selftest && ++frames >= 40)
            done = true;
    }

    // ---- 段三：清理（与初始化严格逆序）--------------------------
    ImGui_ImplDX11_Shutdown();
    ImGui_ImplWin32_Shutdown();
    ImGui::DestroyContext();
    CleanupDeviceD3D();
    ::DestroyWindow(hwnd);
    ::UnregisterClassW(wc.lpszClassName, wc.hInstance);

    if (selftest)
        std::cout << "D3D11 设备/交换链创建成功，主循环渲染 " << frames
                  << " 帧后按预期退出\n"
                  << "==== 08 ImGui 骨架（Win32+D3D11） 结束 ====\n";
    return 0;
}

// ---- D3D11 辅助：创建设备 + 交换链（失败回退 WARP 软件渲染）----
bool CreateDeviceD3D(HWND hWnd)
{
    DXGI_SWAP_CHAIN_DESC sd;
    ZeroMemory(&sd, sizeof(sd));
    sd.BufferCount = 2;
    sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    sd.BufferDesc.RefreshRate = { 60, 1 };
    sd.Flags = DXGI_SWAP_CHAIN_FLAG_ALLOW_MODE_SWITCH;
    sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    sd.OutputWindow = hWnd;
    sd.SampleDesc = { 1, 0 };
    sd.Windowed = TRUE;
    sd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

    UINT createDeviceFlags = 0;
    D3D_FEATURE_LEVEL featureLevel;
    const D3D_FEATURE_LEVEL featureLevelArray[2] = { D3D_FEATURE_LEVEL_11_0, D3D_FEATURE_LEVEL_10_0 };
    HRESULT res = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr,
        createDeviceFlags, featureLevelArray, 2, D3D11_SDK_VERSION,
        &sd, &g_pSwapChain, &g_pd3dDevice, &featureLevel, &g_pd3dDeviceContext);
    if (res == DXGI_ERROR_UNSUPPORTED)
        res = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_WARP, nullptr,
            createDeviceFlags, featureLevelArray, 2, D3D11_SDK_VERSION,
            &sd, &g_pSwapChain, &g_pd3dDevice, &featureLevel, &g_pd3dDeviceContext);
    if (res != S_OK)
        return false;
    CreateRenderTarget();
    return true;
}

void CleanupDeviceD3D()
{
    CleanupRenderTarget();
    if (g_pSwapChain) { g_pSwapChain->Release(); g_pSwapChain = nullptr; }
    if (g_pd3dDeviceContext) { g_pd3dDeviceContext->Release(); g_pd3dDeviceContext = nullptr; }
    if (g_pd3dDevice) { g_pd3dDevice->Release(); g_pd3dDevice = nullptr; }
}

void CreateRenderTarget()
{
    ID3D11Texture2D* pBackBuffer;
    g_pSwapChain->GetBuffer(0, IID_PPV_ARGS(&pBackBuffer));
    g_pd3dDevice->CreateRenderTargetView(pBackBuffer, nullptr, &g_mainRenderTargetView);
    pBackBuffer->Release();
}

void CleanupRenderTarget()
{
    if (g_mainRenderTargetView) { g_mainRenderTargetView->Release(); g_mainRenderTargetView = nullptr; }
}

// imgui_impl_win32.cpp 内部的消息处理器（转发输入事件给 ImGui）
extern IMGUI_IMPL_API LRESULT ImGui_ImplWin32_WndProcHandler(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam);

LRESULT WINAPI WndProc(HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam)
{
    if (ImGui_ImplWin32_WndProcHandler(hWnd, msg, wParam, lParam))
        return true;
    switch (msg)
    {
    case WM_SIZE:
        if (wParam == SIZE_MINIMIZED) return 0;
        g_ResizeWidth = (UINT)LOWORD(lParam);   // 只记录，主循环里统一重建
        g_ResizeHeight = (UINT)HIWORD(lParam);
        return 0;
    case WM_SYSCOMMAND:
        if ((wParam & 0xfff0) == SC_KEYMENU) return 0;  // 屏蔽 Alt 菜单
        break;
    case WM_DESTROY:
        ::PostQuitMessage(0);
        return 0;
    }
    return ::DefWindowProcW(hWnd, msg, wParam, lParam);
}
