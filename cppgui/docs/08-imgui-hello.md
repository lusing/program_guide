# 08 · Dear ImGui 骨架：即时模式与双后端

> 对应示例：[examples/08_imgui_hello.cpp](../examples/08_imgui_hello.cpp)（Win32+D3D11 主线）· [examples/08_imgui_hello_sdl2.cpp](../examples/08_imgui_hello_sdl2.cpp)（SDL2+OpenGL3 对照变体）

## 8.1 本部分范式导读：即时模式 vs 保留模式

第二部分（08–13）换范式：从 wxWidgets 的保留模式进入 Dear ImGui 的即时模式。01 章说保留模式是"先建一棵常驻控件树、事件回调改状态"；即时模式反其道而行——**没有常驻控件树，UI 是主循环里每帧重新执行的普通代码**：

| 维度 | 保留模式（wx，01–07） | 即时模式（imgui，08–13） |
|---|---|---|
| 控件存在性 | 常驻对象树，Frame 挂子控件 | 无对象，只有每帧调用的函数 |
| 状态住在哪 | 控件内部（`GetValue()/SetValue()`） | 你自己的变量（控件函数传指针进去） |
| 事件如何到达 | 回调/事件表，框架择机调用 | 函数返回值，当帧即知 |
| UI 代码执行时机 | 建树一次，之后事件驱动 | 每帧全量重跑 |
| 谁负责重绘 | 框架（脏标记/重绘事件） | 你的主循环（每帧必画） |

这个差异落在代码上只有一行，却是整个范式的开关：

```cpp
// ═══ 8.1 返回值即事件 ═══
if (ImGui::Button("Button"))
    counter++;                      // 事件就是这一帧的返回值
```

`Button()` 这一帧既画按钮、又检测点击，被按下就返回 true——绘制与交互是同一次调用。对照 01 章的 `EVT_MENU(Minimal_Quit, MyFrame::OnQuit)`：那里"接线"发生在建树时、只接一次；这里"接线"每帧重演，所以 UI 代码永远能读到最新状态。代价是每帧全量执行（imgui 靠裁剪跳过屏幕外/折叠窗口的实际绘制来兜底），换来状态单源、没有控件与应用数据的同步问题——这是 imgui 统治调试工具与引擎编辑器领域的原因。

imgui 本体只负责"把 UI 变成顶点"，它不创建窗口、也不懂键盘鼠标。窗口与输入交给**平台后端**（本章主线用 `imgui_impl_win32`），把顶点画到屏幕交给**渲染后端**（本章主线用 `imgui_impl_dx11`）——两个独立插拔点，官方维护横跨 Win32/SDL/GLFW 与 D3D11/D3D12/OpenGL/Metal/Vulkan 的后端矩阵（本地源码 `docs/BACKENDS.md`）。本教程本地 imgui 源码为 1.93.0 WIP master，不含 docking/多视口（11 章有注记）。整个程序是固定三段式：**初始化 → 主循环（消息→NewFrame→UI→Render→Present）→ 清理**，本章逐段走读。

## 8.2 段一（上）：DPI、原生窗口与 D3D11 设备

```cpp
// ═══ 8.2 DPI 感知与 Win32 窗口创建 ═══
ImGui_ImplWin32_EnableDpiAwareness();
float main_scale = ImGui_ImplWin32_GetDpiScaleForMonitor(
    ::MonitorFromPoint(POINT{ 0, 0 }, MONITOR_DEFAULTTOPRIMARY));

WNDCLASSEXW wc = { sizeof(wc), CS_CLASSDC, WndProc, ... };
::RegisterClassExW(&wc);
HWND hwnd = ::CreateWindowW(wc.lpszClassName, L"08 - Dear ImGui + Win32 + D3D11",
    WS_OVERLAPPEDWINDOW, 100, 100,
    (int)(900 * main_scale), (int)(600 * main_scale), ...);
```

窗口就是普通 Win32 窗口：注册类、`CreateWindowW`，与第四部分 tvision 之前的原生写法没有区别——imgui 不接管窗口，只往你给的 HWND 上"贴"UI。DPI 缩放系数从主显示器取，乘进初始尺寸。

```cpp
// ═══ 8.3 D3D11 设备 + 交换链：硬件失败回退 WARP 软渲染 ═══
HRESULT res = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_HARDWARE, ...);
if (res == DXGI_ERROR_UNSUPPORTED)
    res = D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_WARP, ...);
if (res != S_OK)
    return false;
```

D3D11 侧要建三样：设备（`ID3D11Device`）、立即上下文（`ID3D11DeviceContext`）、交换链（`IDXGISwapChain`）。硬件驱动不可用时（远程桌面/无显卡虚拟机）回退 WARP 软件渲染，保证骨架在任何机器上都能起。后缓冲再包一层 `ID3D11RenderTargetView` 作为每帧 Clear 的目标。

## 8.3 段一（下）：上下文、样式与两个后端

```cpp
// ═══ 8.4 上下文 + 样式 + 后端初始化（顺序即依赖）═══
IMGUI_CHECKVERSION();
ImGui::CreateContext();
ImGuiIO& io = ImGui::GetIO(); (void)io;
io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
ImGui::StyleColorsDark();
ImGuiStyle& style = ImGui::GetStyle();
style.ScaleAllSizes(main_scale);
style.FontScaleDpi = main_scale;   // 1.93：字体 DPI 缩放字段

ImGui_ImplWin32_Init(hwnd);
ImGui_ImplDX11_Init(g_pd3dDevice, g_pd3dDeviceContext);
```

`ImGui::CreateContext()` 建立全局上下文（所有 `ImGui::` 函数的隐含前提）；两个后端各自认领自己的"资产"：平台后端拿 HWND 挂消息钩子，渲染后端拿 D3D11 设备准备着色器与顶点缓冲。字体此处先不配——默认嵌入了 ProggyClean 位图字体，**只覆盖 ASCII**（中文要自载字体，12 章专门讲）。

## 8.4 段二：主循环——消息、NewFrame、UI、呈现

```cpp
// ═══ 8.5 主循环骨架：五步一帧 ═══
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

    // 2) 窗口尺寸变化：WM_SIZE 里只记录，这里统一重建
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

    // 4) UI：每帧重新执行
    ImGui::Begin("Hello, imgui!");
    ImGui::Text("immediate mode: UI = plain code, state = plain vars");
    ImGui::SliderFloat("float", &f, 0.0f, 1.0f);
    ImGui::ColorEdit3("clear color", (float*)&clear_color);
    if (ImGui::Button("Button"))
        counter++;
    ImGui::SameLine();
    ImGui::Text("counter = %d", counter);
    ImGui::Checkbox("Another Window", &show_another);
    ImGui::End();

    // 5) 渲染并呈现（vsync）
    ImGui::Render();
    const float cc[4] = { clear_color.x * clear_color.w, ... };
    g_pd3dDeviceContext->OMSetRenderTargets(1, &g_mainRenderTargetView, nullptr);
    g_pd3dDeviceContext->ClearRenderTargetView(g_mainRenderTargetView, cc);
    ImGui_ImplDX11_RenderDrawData(ImGui::GetDrawData());
    g_SwapChainOccluded = (g_pSwapChain->Present(1, 0) == DXGI_STATUS_OCCLUDED);

    // selftest：跑满 40 帧即认为骨架健康，优雅退出
    if (selftest && ++frames >= 40)
        done = true;
}
```

读这段的要点：**UI 代码（第 4 步）被夹在 NewFrame 与 Render 之间**，这是即时模式的"帧槽位"；`SliderFloat` 直接写你的 `f`，`ColorEdit3` 直接写 `clear_color`，第 5 步立刻用它清屏——改与用之间零跳转。`Present(1, 0)` 开 vsync 限帧；selftest 模式下帧计数器满 40 就置 `done`，走**与用户关窗相同的退出路径**（自然滑出循环），随后段三严格按初始化逆序清理：两个后端 Shutdown → `DestroyContext` → D3D 资源 → 销窗。

## 8.5 WndProc：输入的进水管

```cpp
// ═══ 8.6 消息先喂 imgui，再自己处理 ═══
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
```

键盘鼠标不是轮询的：平台后端在 `WndProc` 里装一个 handler，每条消息先问 imgui"吃不吃"。注意 `ImGui_ImplWin32_WndProcHandler` 是 `imgui_impl_win32.cpp` 内部的全局符号，使用方须在**命名空间外** extern 声明（09–13 的骨架头因此专门注释了这一点）。

## 8.6 双后端对照：换 SDL2+OpenGL3 只换两个插拔点

`08_imgui_hello_sdl2.cpp` 与主线的 **UI 代码逐字相同**（同一个计数器窗口），只换了两样东西：

| 插拔点 | 主线 | SDL2 变体 |
|---|---|---|
| 平台后端（窗口/输入） | `imgui_impl_win32` | `imgui_impl_sdl2` |
| 渲染后端（呈现） | `imgui_impl_dx11` | `imgui_impl_opengl3` |
| 窗口创建 | `RegisterClassExW/CreateWindowW` | `SDL_CreateWindow`（GL 3.0 Core 属性） |
| 消息泵 | `PeekMessage` 循环 | `SDL_PollEvent` 循环 |
| 呈现 | `ClearRenderTargetView + Present` | `glClear + SDL_GL_SwapWindow` |
| 尺寸变化 | `WM_SIZE` 记录 + `ResizeBuffers` | 后端自动（`ALLOW_HIGHDPI`） |

```cpp
// ═══ 8.7 SDL2 变体唯一"结构性"差异区（UI 代码零改动）═══
ImGui_ImplSDL2_InitForOpenGL(window, gl_context);   // 平台后端
ImGui_ImplOpenGL3_Init(glsl_version);               // 渲染后端
...
while (SDL_PollEvent(&event))
{
    ImGui_ImplSDL2_ProcessEvent(&event);        // 输入喂给 imgui
    if (event.type == SDL_QUIT) done = true;
}
```

两个变体并存本身就是本章论点的证据：后端矩阵负责"窗口与输入"、"画三角形"两件脏活，**业务 UI 代码平台无关**——这正是 09–13 章敢把全部精力放在 UI 上的前提。顺带注意 `#define SDL_MAIN_HANDLED` 与 `SDL_SetMainReady()`：Windows 上 SDL 默认把 `main` 宏化成代理入口，我们要自己写 main 就得先摘掉它。

## 8.7 运行与输出

```bash
cd cppgui
pwsh build.ps1 -Example 08_imgui_hello         # Win32+D3D11 主线
pwsh build.ps1 -Example 08_imgui_hello_sdl2    # SDL2+OpenGL3 变体
```

与 wx 部分不同，imgui 示例链接为**控制台子系统**，selftest 的证据直接写 stdout（无需 sidecar 文件）。判定标准不变：退出码 0 + 起止标记齐全 + stderr 为空 + 连跑两次逐字节一致。

主线实测输出（`build/docs-ref/08_imgui_hello.out`）：

```text
==== 08 ImGui 骨架（Win32+D3D11） 开始 ====
D3D11 设备/交换链创建成功，主循环渲染 40 帧后按预期退出
==== 08 ImGui 骨架（Win32+D3D11） 结束 ====
```

SDL2 变体实测输出（`build/docs-ref/08_imgui_hello_sdl2.out`）：

```text
==== 08 ImGui 骨架（SDL2+OpenGL3 变体） 开始 ====
SDL2 窗口/GL 上下文创建成功，主循环渲染 40 帧后按预期退出
==== 08 ImGui 骨架（SDL2+OpenGL3 变体） 结束 ====
```

三行覆盖完整生命周期：设备/上下文创建成功 → 40 帧渲染（UI 代码每帧重跑）→ 按预期退出、清理无崩溃。

## 坑位清单

- **NewFrame 三步顺序固定**：`ImGui_ImplDX11_NewFrame()` → `ImGui_ImplWin32_NewFrame()` → `ImGui::NewFrame()`，渲染后端在前、平台后端在后（SDL2 版同构：OpenGL3 在前）。顺序颠倒会让帧时间、输入、显示尺寸的采集错位，出现首帧闪烁或鼠标偏移。
- **WM_SIZE 里不能直接 ResizeBuffers**：交换链重建必须等设备上下文空闲，窗口过程里直接调是 D3D11 经典死法。正道是 `WM_SIZE` 只记录 `LOWORD/HIWORD` 到全局变量，主循环统一执行 Cleanup→ResizeBuffers→CreateRenderTarget；`SIZE_MINIMIZED` 直接 return 0 避免拿 0 尺寸重建。
- **最小化后必须降速**：窗口不可见时 `Present` 仍全速跑，CPU 白烧。主线用 `Present(0, DXGI_PRESENT_TEST)` 检测 `DXGI_STATUS_OCCLUDED` 后 `Sleep(10)` 跳帧；SDL2 版对应检查 `SDL_WINDOW_MINIMIZED` 标志 + `SDL_Delay(10)`。
- **WndProc 先喂 imgui，且要屏蔽 Alt 菜单**：handler 返回非 0 表示消息已被 imgui 消费，必须先判它再走自己的 switch；不拦截 `SC_KEYMENU`，用户按 Alt 会弹出系统菜单抢走键盘焦点。
- **SDL2 的 main 代理坑**：Windows 下 `SDL.h` 默认把 `main` 宏替换成 `SDL_main`，不写 `#define SDL_MAIN_HANDLED`（必须在 include 之前）+ `SDL_SetMainReady()` 就找不到入口。另：scoop 装的 SDL2 不带 CMake config，`find_package` 找不到，本工程由根 CMakeLists 用 IMPORTED 目标直连，动态链接还要后置拷贝 `SDL2.dll`。
- **io.IniFilename 默认写 imgui.ini 到 cwd**：imgui 自动把窗口位置/尺寸持久化到工作目录，演示目录会莫名多出文件、位置状态跨进程残留——10 章讲怎么关。

---

上一章：[07 · 文档/视图与线程](07-wx-docview-thread.md) ｜ 下一章：[09 · 控件全集与 ID 机制](09-imgui-widgets.md) ｜ 返回：[README](../README.md)
