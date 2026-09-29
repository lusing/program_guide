// ============================================================
// 12_imgui_drawlist_fonts.cpp —— DrawList 自绘与字体图集（中文渲染）
//
// 要点：
//   * ImDrawList：imgui 的一切最终都是它画的（文字/圆角矩形/曲线）。
//     GetWindowDrawList() 拿当前窗口的表——坐标是【屏幕绝对坐标】，
//     排版光标 GetCursorScreenPos 可作参照
//   * 原语：AddLine/AddRect/AddCircleFilled/AddTriangleFilled/
//     AddBezierQuadratic/AddText；PushClipRect 裁剪
//   * 字体：默认是嵌入的 ASCII 位图（ProggyClean）——中文必须自载：
//     AddFontFromFileTTF + GetGlyphRangesChineseSimplifiedFull
//   * 【坑】改字体要在首帧 NewFrame 之前；运行中换字体需重建图集
//     （backend 会在 NewFrame 检测 Fonts->TexID 变化自动重建 D3D 纹理）
// 官方参考：docs/FONTS.md（必读）、imgui_demo.cpp 的 Custom Rendering 节
// ============================================================
#include "imgui_dx11_app.h"

#include <cmath>
#include <cstring>
#include <cstdio>

static bool g_cnFontOk = false;      // 中文字体是否加载成功
static float g_t = 0.0f;
static int  g_glyphs = 0;            // 首帧烘焙后的字形计数

// 载入中文字体（微软雅黑，简体全字形范围）。失败回退默认 ASCII。
static void LoadFonts()
{
    ImGuiIO& io = ImGui::GetIO();
    const char* candidates[] = {
        "C:/Windows/Fonts/msyh.ttc",       // 微软雅黑
        "C:/Windows/Fonts/simhei.ttf",     // 黑体（兜底）
    };
    for (const char* path : candidates)
    {
        ImFontConfig cfg;
        cfg.OversampleH = 2;               // 横向过采样：中文笔画更平滑
        // 2500 常用简体字形（ChineseFull=21000 全集，烘焙慢）
        ImFont* f = io.Fonts->AddFontFromFileTTF(
            path, 18.0f, &cfg, io.Fonts->GetGlyphRangesChineseSimplifiedCommon());
        if (f) { g_cnFontOk = true; std::cout << "font loaded: " << path << "\n"; return; }
    }
    io.Fonts->AddFontDefault();            // 兜底：至少能跑
    std::cout << "WARN: no CJK font found, fallback to default\n";
}

static void Ui(int frame)
{
    g_t = frame * 0.05f;

    ImGui::SetNextWindowPos(ImVec2(30, 30), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(430, 470), ImGuiCond_FirstUseEver);
    ImGui::Begin("drawlist", nullptr, ImGuiWindowFlags_NoSavedSettings);

    if (g_cnFontOk)
        ImGui::Text("中文渲染 OK（微软雅黑 + 简体全字形范围）");
    else
        ImGui::Text("CJK font missing - ASCII fallback");

    // ---------------- DrawList：绝对坐标自绘 ----------------
    ImVec2 p = ImGui::GetCursorScreenPos();     // 排版光标（屏幕坐标）
    ImDrawList* dl = ImGui::GetWindowDrawList();
    const ImVec2 c = ImVec2(p.x + 100, p.y + 90);   // 圆心

    dl->AddCircleFilled(c, 60.0f, IM_COL32(90, 120, 200, 255), 32);
    dl->AddCircle(c, 60.0f, IM_COL32(255, 255, 255, 255), 48, 2.0f);
    dl->AddLine(ImVec2(c.x - 60, c.y + 60), ImVec2(c.x + 180, c.y - 40),
                IM_COL32(255, 160, 60, 255), 3.0f);
    dl->AddTriangleFilled(
        ImVec2(c.x + 150, c.y + 30), ImVec2(c.x + 200, c.y + 80),
        ImVec2(c.x + 120, c.y + 70), IM_COL32(200, 80, 200, 200));
    dl->AddBezierQuadratic(
        ImVec2(c.x - 40, c.y + 100), ImVec2(c.x + 60, c.y + 150),
        ImVec2(c.x + 160, c.y + 60), IM_COL32(80, 220, 120, 255), 2.0f);

    // 动画：随帧旋转的三点
    for (int i = 0; i < 3; ++i)
    {
        float a = g_t + i * 2.0944f;
        dl->AddCircleFilled(ImVec2(c.x + cosf(a) * 45, c.y + sinf(a) * 45),
                            5.0f, IM_COL32(255, 230, 90, 255));
    }

    // DrawList 上的文字（用当前字体）
    dl->AddText(ImVec2(p.x + 230, p.y + 130), IM_COL32(240, 240, 240, 255),
                "drawlist text");

    // 裁剪：矩形外的不画
    dl->PushClipRect(ImVec2(p.x + 230, p.y + 150), ImVec2(p.x + 330, p.y + 190), true);
    dl->AddRectFilled(ImVec2(p.x + 220, p.y + 140), ImVec2(p.x + 360, p.y + 200),
                      IM_COL32(60, 60, 80, 128));
    dl->AddText(ImVec2(p.x + 230, p.y + 155), IM_COL32(255, 255, 255, 255),
                "clipped 中文裁剪演示长文本");
    dl->PopClipRect();

    ImGui::Dummy(ImVec2(0, 210));               // 占位：给上面让出空间

    ImGui::SeparatorText("字体与缩放");
    if (frame == 0)
        g_glyphs = ImGui::GetFontBaked()->Glyphs.Size;   // 1.93：字形数在 baked 层
    ImGui::Text("fontsize=%.0f fonts=%d glyphs(baked)=%d",
                ImGui::GetFontSize(), ImGui::GetIO().Fonts->Fonts.Size, g_glyphs);
    if (ImGui::Button("push font 26px"))
    {
        ImGui::PushFont(ImGui::GetIO().Fonts->Fonts[0]);   // 演示入口（尺寸在载入时定）
        ImGui::Text("PushFont 切换的文本");
        ImGui::PopFont();
    }
    ImGui::TextWrapped("字形范围：GetGlyphRangesChineseSimplifiedFull "
                       "覆盖常用简体+标点（docs/FONTS.md 有全表）。"
                       "图集是运行时烘焙的纹理，backend 自动上传/重建。");
    ImGui::End();
}

int main(int argc, char** argv)
{
    const bool selftest = (argc > 1 && std::strcmp(argv[1], "--selftest") == 0);
    if (selftest) std::cout << "==== 12 ImGui 自绘与字体 开始 ====\n";

    cppgui::ImguiAppConfig cfg;
    cfg.title = L"12 - drawlist & fonts";   // 窗口标题是 Win32 层的（Unicode 原生）
    cfg.selftest = selftest;
    cfg.ui = &Ui;
    // 注意顺序：字体必须在 CreateContext 之后、首帧 NewFrame 之前配置
    // （onInit 钩子正好在这个时机——直接在 main 里调 GetIO() 会空上下文崩溃）
    cfg.onInit = &LoadFonts;
    cfg.onExit = [](int frames) {
        std::cout << "frames=" << frames << "; cnfont=" << (g_cnFontOk ? 1 : 0)
                  << "; glyphs=" << g_glyphs << "\n"
                  << "==== 12 ImGui 自绘与字体 结束 ====\n";
    };
    return cppgui::RunImguiApp(cfg);
}
