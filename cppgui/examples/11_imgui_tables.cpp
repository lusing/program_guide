// ============================================================
// 11_imgui_tables.cpp —— Tables API / 排序 / Plot 曲线
//
// 要点：
//   * BeginTable/TableSetupColumn/TableHeadersRow/TableNextRow——
//     列是"注册"出来的（名字+标志），行是循环推进的
//   * 常用列标志：WidthStretch(按权重分宽)/WidthFixed(固定)；
//     表级标志：Resizable(可拖列宽)/Sortable(点表头排序)/RowBg(隔行底色)
//   * 排序：TableGetSortSpecs 拿到"用户点的那一列+方向"，
//     自己把数据排好再画——imgui 不碰你的数据
//   * 行选择：Selectable 包整行 + BeginPopup 上下文菜单
//   * PlotLines/PlotHistogram：滑动数据窗的内置迷你图（每帧喂指针+长度）
//   * docking/多视口注记：本地 imgui 1.93 master 无此特性
//     （imgui.h 中无 ViewportsEnable，实测 0 处命中）——那是
//     docking 分支的功能，见 docs/FAQ.md "docking branch"。
// 官方参考：imgui_demo.cpp 的 Tables/Plots 节
// ============================================================
#include "imgui_dx11_app.h"

#include <algorithm>
#include <cstring>
#include <vector>

struct ProcRow
{
    int    pid;
    char   name[24];
    float  cpu;      // %
    int    mem;      // MB
};

static std::vector<ProcRow> g_procs = {
    { 101, "systemd",   0.4f,  12 },
    { 204, "explorer",  2.1f,  88 },
    { 313, "clang.exe", 45.7f, 720 },
    { 409, "mspdbsrv",  0.0f,  36 },
    { 512, "game",      12.3f, 2048 },
};
static ImGuiTableSortSpecs* g_sortSpecs = nullptr;
static int  g_selectedRow = -1;
static float g_history[90] = {};
static int   g_histIdx = 0;

// 按 SortSpecs 排数据（stable 保同键次序稳定）
static void SortProcs()
{
    if (!g_sortSpecs || !g_sortSpecs->SpecsDirty) return;
    const auto& s = g_sortSpecs->Specs[0];
    std::stable_sort(g_procs.begin(), g_procs.end(), [&](const ProcRow& a, const ProcRow& b) {
        int r = 0;
        switch (s.ColumnUserID)
        {
        case 'pid':  r = a.pid - b.pid; break;
        case 'name': r = std::strcmp(a.name, b.name); break;
        case 'cpu':  r = (a.cpu < b.cpu) ? -1 : (a.cpu > b.cpu) ? 1 : 0; break;
        case 'mem':  r = a.mem - b.mem; break;
        }
        return s.SortDirection == ImGuiSortDirection_Ascending ? r < 0 : r > 0;
    });
    g_sortSpecs->SpecsDirty = 0;              // 告诉 imgui：数据已按此排好
}

static void Ui(int frame)
{
    ImGui::SetNextWindowPos(ImVec2(30, 30), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(520, 420), ImGuiCond_FirstUseEver);
    ImGui::Begin("tables", nullptr, ImGuiWindowFlags_NoSavedSettings);

    // ---------------- 可排序表格 ----------------
    ImGuiTableFlags tf = ImGuiTableFlags_Resizable | ImGuiTableFlags_Sortable
                       | ImGuiTableFlags_RowBg | ImGuiTableFlags_BordersOuter;
    if (ImGui::BeginTable("procs", 4, tf))
    {
        // 列用 UserID 给排序回调传键（'pid'/'cpu'... 单字符常量够用）
        ImGui::TableSetupColumn("PID",   ImGuiTableColumnFlags_DefaultSort, 0, 'pid');
        ImGui::TableSetupColumn("Name",  ImGuiTableColumnFlags_WidthStretch, 0, 'name');
        ImGui::TableSetupColumn("CPU%",  ImGuiTableColumnFlags_WidthFixed, 80.0f, 'cpu');
        ImGui::TableSetupColumn("MemMB", ImGuiTableColumnFlags_WidthFixed, 80.0f, 'mem');
        ImGui::TableHeadersRow();              // 表头行（可点击排序）

        g_sortSpecs = ImGui::TableGetSortSpecs();   // 排序意图
        SortProcs();

        for (int row = 0; row < (int)g_procs.size(); ++row)
        {
            ImGui::TableNextRow();
            const ProcRow& p = g_procs[row];
            ImGui::TableSetColumnIndex(0);
            ImGui::Text("%d", p.pid);
            ImGui::TableSetColumnIndex(1);
            // 行选择：Selectable spanAllColumns + 右键上下文菜单
            if (ImGui::Selectable(p.name, g_selectedRow == row,
                                  ImGuiSelectableFlags_SpanAllColumns))
                g_selectedRow = row;
            if (ImGui::BeginPopupContextItem())     // 右键该项
            {
                if (ImGui::MenuItem("kill")) { /* 教学示意 */ }
                ImGui::EndPopup();
            }
            ImGui::TableSetColumnIndex(2);
            ImGui::Text("%.1f", p.cpu);
            if (p.cpu > 30.0f) ImGui::SameLine(), ImGui::TextColored(ImVec4(1, 0.4f, 0.4f, 1), "!");
            ImGui::TableSetColumnIndex(3);
            ImGui::Text("%d", p.mem);
        }
        ImGui::EndTable();
    }

    ImGui::SeparatorText("plots");
    // ---------------- 迷你曲线：每帧推一个点，画滑动窗 ----------------
    float v = 0.4f + 0.3f * sinf(frame * 0.07f) + 0.1f * sinf(frame * 0.31f);
    g_history[g_histIdx % 90] = v; ++g_histIdx;
    ImGui::PlotLines("cpu history", g_history, 90, g_histIdx % 90,
                     nullptr, 0.0f, 1.0f, ImVec2(-1, 70));
    ImGui::PlotHistogram("mem dist", g_history, 90, 0, nullptr, 0.0f, 1.0f, ImVec2(-1, 50));

    ImGui::SeparatorText("note");
    ImGui::TextWrapped("multi-viewport & docking: NOT in master (1.93, "
                       "no ViewportsEnable in imgui.h) - docking branch only.");
    ImGui::End();
}

int main(int argc, char** argv)
{
    const bool selftest = (argc > 1 && std::strcmp(argv[1], "--selftest") == 0);
    if (selftest) std::cout << "==== 11 ImGui 表格与曲线 开始 ====\n";

    cppgui::ImguiAppConfig cfg;
    cfg.title = L"11 - tables & plots";
    cfg.selftest = selftest;
    cfg.ui = &Ui;
    cfg.onExit = [](int frames) {
        std::cout << frames << " frames; rows=" << g_procs.size()
                  << "; selected=" << g_selectedRow
                  << "; sort col dirty=0; last sample=" << g_history[(g_histIdx + 89) % 90] << "\n"
                  << "==== 11 ImGui 表格与曲线 结束 ====\n";
    };
    return cppgui::RunImguiApp(cfg);
}
