// ============================================================
// 09_imgui_widgets.cpp —— 基本控件全集与即时模式语义（ID 机制）
//
// 核心读法：每个控件函数【每帧都调】；"事件"就是这个函数在某一帧
// 的返回值 true——没有回调、没有监听器、没有控件对象。状态全在
// 你自己的变量里（对照 wx 的"状态住在控件里"）。
// ID 机制：imgui 用"窗口名+控件标签"当 ID；两同名控件冲突时用
// PushID/PopID 或 "##后缀" 消歧——本例演示两种解法。
// 官方参考：imgui_demo.cpp 的 Widgets 节（活字典）。
// 注意：默认字体是 ASCII 位图（中文渲染见 12 章），故 UI 文本用英文。
// 骨架：imgui_dx11_app.h（= 08 章三段式的复用头）
// ============================================================
#include "imgui_dx11_app.h"

#include <cstdio>
#include <cstring>

// ---- 应用状态：全部外置的普通变量（即时模式核心）----
static bool  g_check1 = false, g_check2 = true;
static int   g_radio = 1;
static float g_slider = 0.5f;
static int   g_slidint = 3;
static char  g_input[128] = "hello";
static int   g_combo = 1;
static float g_color[3] = { 0.2f, 0.6f, 0.9f };
static int   g_clicks = 0;
static float g_progress = 0.35f;

static void Ui(int /*frame*/)
{
    ImGui::SetNextWindowPos(ImVec2(30, 30), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(430, 440), ImGuiCond_FirstUseEver);
    ImGui::Begin("widgets", nullptr);

    // -- 返回值即事件：所有控件都包在 if 里 --
    if (ImGui::Checkbox("enable A", &g_check1)) { /* 本帧被切换 */ }
    ImGui::SameLine();
    if (ImGui::Checkbox("enable B", &g_check2)) { }
    if (ImGui::RadioButton("low", &g_radio, 0)) { }
    ImGui::SameLine();
    if (ImGui::RadioButton("mid", &g_radio, 1)) { }
    ImGui::SameLine();
    if (ImGui::RadioButton("high", &g_radio, 2)) { }

    ImGui::SeparatorText("numeric input");
    if (ImGui::SliderFloat("float", &g_slider, 0.0f, 1.0f)) { }
    if (ImGui::SliderInt("int", &g_slidint, 0, 10)) { }
    if (ImGui::InputText("text", g_input, sizeof(g_input))) { }  // 每次编辑返回 true

    ImGui::SeparatorText("selection");
    const char* items[] = { "apple", "banana", "cherry" };
    if (ImGui::Combo("combo", &g_combo, items, IM_ARRAYSIZE(items))) { }
    if (ImGui::ColorEdit3("color", g_color)) { }

    ImGui::SeparatorText("buttons & progress");
    if (ImGui::Button("click me")) g_clicks++;
    ImGui::SameLine();
    ImGui::Text("clicks = %d", g_clicks);
    ImGui::ProgressBar(g_progress, ImVec2(-1, 0), "loading");

    ImGui::SeparatorText("ID disambiguation");
    // 【坑】两个同名 Button 且无消歧 → imgui 报 ID collision 告警、
    // hover/active 态互相串扰。解法一："##id" 后缀：显示文本一致、ID 不同。
    if (ImGui::Button("reset##a")) g_clicks = 0;
    ImGui::SameLine();
    if (ImGui::Button("reset##b")) g_clicks = 100;
    // 解法二：PushID/PopID 给一段控件加整数前缀（循环生成同名控件必用）
    for (int i = 0; i < 3; ++i)
    {
        ImGui::PushID(i);
        if (ImGui::Button("X")) g_clicks -= 1;
        ImGui::PopID();
        ImGui::SameLine();
    }
    ImGui::NewLine();

    ImGui::Text("state: slider=%.2f slidint=%d combo=%d", g_slider, g_slidint, g_combo);
    ImGui::End();

    // 对照说明窗口
    ImGui::SetNextWindowPos(ImVec2(480, 30), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(240, 180), ImGuiCond_FirstUseEver);
    bool open = true;
    ImGui::Begin("id-collision", &open);
    ImGui::TextWrapped("Two widgets with the same label inside one window "
                       "share the same ID: imgui logs 'ID collision' and their "
                       "hover/active states interfere. Fix with ##suffix or "
                       "PushID/PopID (see left).");
    ImGui::End();
}

int main(int argc, char** argv)
{
    const bool selftest = (argc > 1 && std::strcmp(argv[1], "--selftest") == 0);
    if (selftest) std::cout << "==== 09 ImGui 控件与 ID 开始 ====\n";

    cppgui::ImguiAppConfig cfg;
    cfg.title = L"09 - widgets & ID";
    cfg.selftest = selftest;
    cfg.ui = &Ui;
    cfg.onExit = [](int frames) {
        std::cout << frames << " frames rendered; final slider=" << g_slider
                  << " combo=" << g_combo << " clicks=" << g_clicks << "\n"
                  << "==== 09 ImGui 控件与 ID 结束 ====\n";
    };
    return cppgui::RunImguiApp(cfg);
}
