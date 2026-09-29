// ============================================================
// 13_imgui_app.cpp —— 综合实战：迷你系统监视器
//
// 综合回收 08–12 全部技术：
//   双 PlotLines 滑动曲线（ring buffer）/ 可排序进程表（11 章）/
//   右侧设置 dock：主题切换 + 全局字号 + 帧率（09/10 章）/
//   底部日志窗自动滚底（10 章子窗口）/ 中文字体（12 章）
// 无头思路注记：imgui 有 example_null 后端（无窗口渲染到字符串），
// 适合把 UI 逻辑做成纯函数做单元测试——见 docs/EXAMPLES.md。
// ============================================================
#include "imgui_dx11_app.h"

#include <algorithm>
#include <cmath>
#include <cstring>
#include <deque>
#include <string>
#include <vector>

static const int kHist = 120;
static float g_cpu[kHist] = {};
static float g_mem[kHist] = {};
static int   g_histIdx = 0;

struct Proc { int pid; const char* name; float cpu; int mem; };
static std::vector<Proc> g_procs = {
    { 101, "systemd", 0.4f, 12 }, { 204, "explorer", 2.1f, 88 },
    { 313, "clang.exe", 45.7f, 720 }, { 409, "mspdbsrv", 0.0f, 36 },
    { 512, "game", 12.3f, 2048 }, { 777, "code", 8.9f, 1536 },
};
static int g_selectedPid = -1;

static int   g_theme = 0;             // 0=dark 1=light 2=classic
static float g_fontScale = 1.0f;
static std::deque<std::string> g_logs;
static int g_logCount = 0;

static void PushLog(const std::string& s) { g_logs.push_back(s); }

static void LoadFonts()
{
    ImGuiIO& io = ImGui::GetIO();
    ImFontConfig cfg; cfg.OversampleH = 2;
    if (!io.Fonts->AddFontFromFileTTF("C:/Windows/Fonts/msyh.ttc", 16.0f, &cfg,
                                      io.Fonts->GetGlyphRangesChineseSimplifiedCommon()))
    {
        io.Fonts->AddFontDefault();
        PushLog("[font] 未找到中文字体，回退 ASCII");
    }
    else
        PushLog("[font] 微软雅黑 16px 加载成功");
}

static void ApplyTheme()
{
    switch (g_theme)
    {
    case 0: ImGui::StyleColorsDark(); break;
    case 1: ImGui::StyleColorsLight(); break;
    case 2: ImGui::StyleColorsClassic(); break;
    }
}

static void Ui(int frame)
{
    ImGuiIO& io = ImGui::GetIO();

    // ---- 每帧产生模拟数据（随机游走 + 正弦）----
    float cpu = std::max(0.0f, std::min(1.0f,
        g_cpu[(g_histIdx + kHist - 1) % kHist] * 0.9f
        + 0.08f * sinf(frame * 0.05f) + 0.05f * ((frame % 7) - 3) * 0.05f));
    float mem = 0.5f + 0.15f * sinf(frame * 0.013f);
    g_cpu[g_histIdx % kHist] = cpu; g_mem[g_histIdx % kHist] = mem; ++g_histIdx;

    if (frame % 20 == 7)
        PushLog("采样: cpu=" + std::to_string((int)(cpu * 100)) + "%");

    // ================= 左上：曲线面板 =================
    ImGui::SetNextWindowPos(ImVec2(20, 20), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(430, 250), ImGuiCond_FirstUseEver);
    ImGui::Begin("监控", nullptr, ImGuiWindowFlags_NoCollapse);
    ImGui::Text("帧率 %.1f FPS (%.2f ms)", io.Framerate, 1000.0f / std::max(1.0f, io.Framerate));
    ImGui::PlotLines("##cpu", g_cpu, kHist, g_histIdx % kHist, "CPU", 0.0f, 1.0f, ImVec2(-1, 70));
    ImGui::PlotLines("##mem", g_mem, kHist, g_histIdx % kHist, "内存", 0.0f, 1.0f, ImVec2(-1, 70));
    ImGui::End();

    // ================= 左下：进程表（可排序/可选行）=================
    ImGui::SetNextWindowPos(ImVec2(20, 290), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(430, 260), ImGuiCond_FirstUseEver);
    ImGui::Begin("进程", nullptr, ImGuiWindowFlags_NoCollapse);
    ImGuiTableFlags tf = ImGuiTableFlags_RowBg | ImGuiTableFlags_Sortable
                       | ImGuiTableFlags_Resizable;
    if (ImGui::BeginTable("p", 3, tf))
    {
        ImGui::TableSetupColumn("PID", ImGuiTableColumnFlags_DefaultSort, 0, 'p');
        ImGui::TableSetupColumn("名称", ImGuiTableColumnFlags_WidthStretch, 0, 'n');
        ImGui::TableSetupColumn("CPU%", ImGuiTableColumnFlags_WidthFixed, 70, 'c');
        ImGui::TableHeadersRow();
        if (ImGuiTableSortSpecs* s = ImGui::TableGetSortSpecs())
        {
            if (s->SpecsDirty)
            {
                const auto& sp = s->Specs[0];
                std::stable_sort(g_procs.begin(), g_procs.end(), [&](const Proc& a, const Proc& b) {
                    int r = sp.ColumnUserID == 'p' ? a.pid - b.pid
                          : sp.ColumnUserID == 'c' ? (a.cpu < b.cpu ? -1 : a.cpu > b.cpu ? 1 : 0)
                          : std::strcmp(a.name, b.name);
                    return sp.SortDirection == ImGuiSortDirection_Ascending ? r < 0 : r > 0;
                });
                s->SpecsDirty = 0;
            }
        }
        for (auto& p : g_procs)
        {
            ImGui::TableNextRow();
            ImGui::TableSetColumnIndex(0);
            ImGui::Text("%d", p.pid);
            ImGui::TableSetColumnIndex(1);
            if (ImGui::Selectable(p.name, g_selectedPid == p.pid, ImGuiSelectableFlags_SpanAllColumns))
            {
                g_selectedPid = p.pid;
                PushLog(std::string("选中进程 ") + p.name);
            }
            ImGui::TableSetColumnIndex(2);
            ImGui::Text("%.1f", p.cpu);
        }
        ImGui::EndTable();
    }
    ImGui::End();

    // ================= 右侧：设置面板 =================
    ImGui::SetNextWindowPos(ImVec2(470, 20), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(300, 250), ImGuiCond_FirstUseEver);
    ImGui::Begin("设置", nullptr, ImGuiWindowFlags_NoCollapse);
    const char* themes[] = { "深色", "浅色", "经典" };
    if (ImGui::Combo("主题", &g_theme, themes, 3)) ApplyTheme();
    if (ImGui::SliderFloat("字号", &g_fontScale, 0.8f, 1.6f))
    { /* 拖动中每帧都进这里：即时模式下没有"提交"事件 */ }
    io.FontGlobalScale = g_fontScale;              // 全局字号缩放（每帧生效）
    ImGui::Separator();
    ImGui::Text("cur cpu=%.0f%% mem=%.0f%%", cpu * 100, mem * 100);
    ImGui::TextWrapped("技术回收：曲线(11)/表格排序(11)/主题与缩放(09)/"
                       "子窗口日志(10)/中文字体(12)");
    ImGui::End();

    // ================= 底部：日志窗（自动滚底）=================
    ImGui::SetNextWindowPos(ImVec2(470, 290), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(300, 260), ImGuiCond_FirstUseEver);
    ImGui::Begin("日志", nullptr, ImGuiWindowFlags_NoCollapse);
    if (ImGui::BeginChild("log", ImVec2(-1, -1), ImGuiChildFlags_Borders))
    {
        for (auto& l : g_logs)
            ImGui::TextUnformatted(l.c_str());
        if (ImGui::GetScrollY() >= ImGui::GetScrollMaxY() - 4)
            ImGui::SetScrollHereY(1.0f);            // 贴底时新内容自动跟随
    }
    ImGui::EndChild();
    ImGui::End();
}

int main(int argc, char** argv)
{
    const bool selftest = (argc > 1 && std::strcmp(argv[1], "--selftest") == 0);
    if (selftest) std::cout << "==== 13 ImGui 监视器应用 开始 ====\n";

    cppgui::ImguiAppConfig cfg;
    cfg.title = L"13 - mini task monitor";
    cfg.width = 820; cfg.height = 600;
    cfg.selftest = selftest;
    cfg.maxFrames = 50;
    cfg.ui = &Ui;
    cfg.onInit = &LoadFonts;
    cfg.onExit = [](int frames) {
        std::cout << "frames=" << frames << "; theme=" << g_theme
                  << "; logs=" << g_logs.size()
                  << "; last cpu=" << (int)(g_cpu[(g_histIdx + kHist - 1) % kHist] * 100) << "%\n"
                  << "==== 13 ImGui 监视器应用 结束 ====\n";
    };
    return cppgui::RunImguiApp(cfg);
}
