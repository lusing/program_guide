// ============================================================
// 10_imgui_windows.cpp —— 窗口系统 / 子窗口 / 标签页 / 布局推进
//
// 要点：
//   * Begin/End 对：返回值 = 本帧是否展开（非 collapsed）——注意
//     End 必须无条件调用（与 Begin 配对，即使窗口折叠了）
//   * SetNextWindowPos/Size + ImGuiCond（FirstUseEver/Appearing/Always）
//   * 窗口标志：NoResize/NoCollapse/AlwaysAutoResize/NoSavedSettings……
//     组合出"工具面板/子弹窗/固定窗口"等形态
//   * ChildWindow（BeginChild）：窗口内的独立滚动区，宽度自动适配
//   * 布局推进模型：控件函数"推进光标"——SameLine/Spacing/Indent/
//     Separator 是唯一排版手段（没有绝对定位、没有布局管理器——
//     想要自由排版用 12 章的 DrawList）
//   * ini 持久化：imgui.ini 自动记住窗口位置（NoSavedSettings 关掉）
// 官方参考：imgui_demo.cpp 的 Window/Layout 节
// ============================================================
#include "imgui_dx11_app.h"

#include <cstring>
#include <cstdio>
#include <string>

static bool g_showA = true, g_showB = true;
static float g_posx = 40, g_posy = 60;
static int  g_childScrollItem = 0;
static char g_iniBackup[64] = "(default: imgui.ini in cwd)";

static void Ui(int /*frame*/)
{
    // ---------- 主窗口：布局推进演示 ----------
    ImGui::SetNextWindowPos(ImVec2(30, 30), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(420, 430), ImGuiCond_FirstUseEver);
    ImGui::Begin("layout-cursor", &g_showA, ImGuiWindowFlags_NoCollapse);

    ImGui::TextWrapped("cursor layout: widgets advance a cursor. "
                       "SameLine/Spacing/Indent are your only layout tools.");
    ImGui::Separator();

    ImGui::Text("normal flow");
    ImGui::SameLine();                       // 折回行首右侧
    ImGui::Text("after SameLine");
    ImGui::Spacing(); ImGui::Spacing();      // 垂直留白
    ImGui::Indent(20.0f);                    // 右缩进
    ImGui::Text("indented by 20");
    ImGui::Unindent(20.0f);

    ImGui::SeparatorText("columns (legacy)");
    ImGui::Columns(3, "cols", true);         // 老式列（表格见 11 章）
    for (int r = 0; r < 2; ++r)
        for (int c = 0; c < 3; ++c)
        {
            ImGui::Text("cell %d-%d", r, c);
            ImGui::NextColumn();
        }
    ImGui::Columns(1);                       // 结束列模式

    ImGui::SeparatorText("child window");
    // ChildWindow：带独立滚动条的子区域；宽度 -1 = 撑满，高度固定 120
    if (ImGui::BeginChild("scrollbox", ImVec2(-1, 120), ImGuiChildFlags_Borders))
    {
        for (int i = 0; i < 30; ++i)
            if (ImGui::Selectable(std::to_string(i).c_str(), g_childScrollItem == i))
                g_childScrollItem = i;
    }
    ImGui::EndChild();                       // 与 BeginChild 严格配对
    ImGui::Text("selected: %d", g_childScrollItem);
    ImGui::End();

    // ---------- 窗口标志对照窗口 ----------
    ImGui::SetNextWindowPos(ImVec2(480, 30), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(280, 240), ImGuiCond_FirstUseEver);
    ImGui::Begin("flags-demo", &g_showB, ImGuiWindowFlags_AlwaysAutoResize);
    ImGui::Text("AlwaysAutoResize: 窗口随内容自适应");
    ImGui::BulletText("try drag/collapse me");
    ImGui::End();

    // ---------- SetNextWindowPos 动态控制的窗口 ----------
    ImGui::SetNextWindowPos(ImVec2(g_posx, g_posy), ImGuiCond_Always);   // Always=每帧
    ImGui::SetNextWindowSize(ImVec2(220, 110), ImGuiCond_Always);
    ImGui::Begin("pinned", nullptr, ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoCollapse
                                   | ImGuiWindowFlags_NoSavedSettings);
    ImGui::SliderFloat("x", &g_posx, 0, 600);
    ImGui::SliderFloat("y", &g_posy, 0, 400);
    ImGui::Text("NoResize+NoCollapse+NoSavedSettings");
    ImGui::End();

    // ---------- 标签页 ----------
    ImGui::SetNextWindowPos(ImVec2(480, 290), ImGuiCond_FirstUseEver);
    ImGui::Begin("tabs", nullptr, ImGuiWindowFlags_NoSavedSettings);
    if (ImGui::BeginTabBar("main"))
    {
        if (ImGui::BeginTabItem("one"))
        {
            ImGui::Text("first tab content");
            ImGui::EndTabItem();
        }
        if (ImGui::BeginTabItem("two"))
        {
            ImGui::Text("second tab content");
            ImGui::EndTabItem();
        }
        ImGui::EndTabBar();
    }
    ImGui::Text("ini: %s", g_iniBackup);
    ImGui::End();
}

int main(int argc, char** argv)
{
    const bool selftest = (argc > 1 && std::strcmp(argv[1], "--selftest") == 0);
    if (selftest) std::cout << "==== 10 ImGui 窗口系统 开始 ====\n";

    cppgui::ImguiAppConfig cfg;
    cfg.title = L"10 - windows & layout";
    cfg.width = 800; cfg.height = 560;
    cfg.selftest = selftest;
    cfg.ui = &Ui;
    cfg.onExit = [](int frames) {
        std::cout << frames << " frames; child selected=" << g_childScrollItem
                  << "; pinned pos=" << g_posx << "," << g_posy << "\n"
                  << "==== 10 ImGui 窗口系统 结束 ====\n";
    };
    return cppgui::RunImguiApp(cfg);
}
