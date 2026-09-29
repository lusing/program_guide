// ============================================================
// 08_imgui_hello_sdl2.cpp —— 后端插拔对照：SDL2 平台 + OpenGL3 渲染
//
// 与 08_imgui_hello.cpp 的 UI 代码【完全相同】（同一个计数器窗口），
// 只换了两样东西：
//   平台后端：imgui_impl_win32 → imgui_impl_sdl2
//   渲染后端：imgui_impl_dx11  → imgui_impl_opengl3
// 消息泵从 Win32 GetMessage 换成 SDL_PollEvent，呈现从
// SwapChain->Present 换成 glClear + SDL_GL_SwapWindow。
// 这就是 imgui 的可移植性：后端矩阵（docs/BACKENDS.md）负责
// "窗口与输入"、"画三角形"两件脏活，业务 UI 代码平台无关。
//
// SDL2 来自 scoop（G:/scoop/apps/sdl2），不带 CMake config，
// 由根 CMakeLists 的 IMPORTED 目标直连；动态链接需 SDL2.dll。
// ============================================================
#define SDL_MAIN_HANDLED  // 我们自己写 main，不要 SDL_main 代理
#include "imgui.h"
#include "imgui_impl_sdl2.h"
#include "imgui_impl_opengl3.h"
#include <SDL.h>
#include <SDL_opengl.h>
#include <cstdio>
#include <cstring>
#include <iostream>

int main(int argc, char** argv)
{
    const bool selftest = (argc > 1 && std::strcmp(argv[1], "--selftest") == 0);
    if (selftest) std::cout << "==== 08 ImGui 骨架（SDL2+OpenGL3 变体） 开始 ====\n";

    SDL_SetMainReady();                       // 配合 SDL_MAIN_HANDLED
#ifdef _WIN32
    ::SetProcessDPIAware();
#endif
    if (SDL_Init(SDL_INIT_VIDEO | SDL_INIT_TIMER | SDL_INIT_GAMECONTROLLER) != 0)
    {
        std::cout << "SDL_Init 失败: " << SDL_GetError() << "\n";
        return 1;
    }

    // GL 3.0 Core + GLSL 130（Windows 常规档）
    const char* glsl_version = nullptr;
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_FLAGS, 0);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 0);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
    SDL_GL_SetAttribute(SDL_GL_STENCIL_SIZE, 8);
#ifdef SDL_HINT_IME_SHOW_UI
    SDL_SetHint(SDL_HINT_IME_SHOW_UI, "1");    // 2.0.18+：原生 IME
#endif

    float main_scale = ImGui_ImplSDL2_GetContentScaleForDisplay(0);
    SDL_WindowFlags window_flags = (SDL_WindowFlags)(
        SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE | SDL_WINDOW_ALLOW_HIGHDPI);
    SDL_Window* window = SDL_CreateWindow("08 - Dear ImGui + SDL2 + OpenGL3",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        (int)(900 * main_scale), (int)(600 * main_scale), window_flags);
    if (window == nullptr)
    {
        std::cout << "SDL_CreateWindow 失败: " << SDL_GetError() << "\n";
        return 1;
    }
    SDL_GLContext gl_context = SDL_GL_CreateContext(window);
    SDL_GL_MakeCurrent(window, gl_context);
    SDL_GL_SetSwapInterval(1);                 // vsync

    // ---- ImGui 上下文 + 后端（与 dx11 版唯一的"结构性"差异区）----
    IMGUI_CHECKVERSION();
    ImGui::CreateContext();
    ImGuiIO& io = ImGui::GetIO(); (void)io;
    io.ConfigFlags |= ImGuiConfigFlags_NavEnableKeyboard;
    ImGui::StyleColorsDark();
    ImGuiStyle& style = ImGui::GetStyle();
    style.ScaleAllSizes(main_scale);
    style.FontScaleDpi = main_scale;

    ImGui_ImplSDL2_InitForOpenGL(window, gl_context);   // 平台后端
    ImGui_ImplOpenGL3_Init(glsl_version);               // 渲染后端

    // ---- 应用状态与 UI 代码：与 Win32+D3D11 版逐字相同 ----
    int   counter = 0;
    float f = 0.0f;
    bool  show_another = false;
    ImVec4 clear_color = ImVec4(0.45f, 0.55f, 0.60f, 1.00f);

    bool done = false;
    int  frames = 0;
    while (!done)
    {
        SDL_Event event;
        while (SDL_PollEvent(&event))
        {
            ImGui_ImplSDL2_ProcessEvent(&event);        // 输入喂给 imgui
            if (event.type == SDL_QUIT) done = true;
            if (event.type == SDL_WINDOWEVENT && event.window.event == SDL_WINDOWEVENT_CLOSE
                && event.window.windowID == SDL_GetWindowID(window))
                done = true;
        }
        if (SDL_GetWindowFlags(window) & SDL_WINDOW_MINIMIZED)
        { SDL_Delay(10); continue; }

        ImGui_ImplOpenGL3_NewFrame();
        ImGui_ImplSDL2_NewFrame();
        ImGui::NewFrame();

        {
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
        }
        if (show_another)
        {
            ImGui::Begin("Another Window", &show_another);
            ImGui::Text("Hello from another window!");
            if (ImGui::Button("Close Me"))
                show_another = false;
            ImGui::End();
        }

        ImGui::Render();
        glViewport(0, 0, (int)io.DisplaySize.x, (int)io.DisplaySize.y);
        glClearColor(clear_color.x * clear_color.w, clear_color.y * clear_color.w,
                     clear_color.z * clear_color.w, clear_color.w);
        glClear(GL_COLOR_BUFFER_BIT);
        ImGui_ImplOpenGL3_RenderDrawData(ImGui::GetDrawData());
        SDL_GL_SwapWindow(window);

        if (selftest && ++frames >= 40)
            done = true;
    }

    // 清理逆序（注意：imgui 的 io.IniFilename 默认会写 imgui.ini 到 cwd）
    ImGui_ImplOpenGL3_Shutdown();
    ImGui_ImplSDL2_Shutdown();
    ImGui::DestroyContext();
    SDL_GL_DeleteContext(gl_context);
    SDL_DestroyWindow(window);
    SDL_Quit();

    if (selftest)
        std::cout << "SDL2 窗口/GL 上下文创建成功，主循环渲染 " << frames
                  << " 帧后按预期退出\n"
                  << "==== 08 ImGui 骨架（SDL2+OpenGL3 变体） 结束 ====\n";
    return 0;
}
