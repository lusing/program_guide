// ============================================================
// 16_ftxui_layout.cpp —— 布局进阶：size/Flexbox/Gridbox/flow/dbox
//
// 要点：
//   * size(WIDTH|HEIGHT, EQUAL|LESS_THAN|GREATER_THAN, n)：尺寸约束
//   * Flexbox：CSS flex 布局器（gap/justify/align/wrap）
//   * Gridbox：二维网格（行内元素用 hbox 组织，行间自动等高）
//   * hflow/vflow：按内容自动折行
//   * dbox：叠放层（背景+前景）
//   * window(title, body)：带标题栏的窗框（TUI 的"窗口"）
//   * ResizableSplit：交互式分割条（鼠标拖动）——交互件，附演示
// 本例主体用「渲染到字符串」形态：输出确定、可直接进文档。
// 官方参考：examples/component/flexbox_gallery.cpp、examples/dom/
//           {gridbox,vflow}.cpp、examples/component/{resizable_split,window}.cpp
// ============================================================
#include <iostream>
#include <string>

#include "ftxui/component/component.hpp"   // ResizableSplit 等
#include "ftxui/component/event.hpp"
#include "ftxui/component/app.hpp"
#include "ftxui/dom/elements.hpp"
#include "ftxui/screen/screen.hpp"

using namespace ftxui;

static std::string RenderToString(Element document, int width = 64)
{
    auto screen = Screen::Create(Dimension::Fixed(width), Dimension::Fit(document));
    Render(screen, document);
    return screen.ToString();
}

int main(int argc, char** argv)
{
    const bool selftest = (argc > 1 && std::string(argv[1]) == "--selftest");
    std::cout << "==== 16 FTXUI 布局进阶 开始 ====\n";

    // -- 1. size 约束：EQUAL 固定 / LESS_THAN 上限 -------------------
    // 【坑】master 的 Constraint 只有 LESS_THAN/EQUAL/GREATER_THAN，
    // 没有 PERCENT（老教程里的百分比写法已删）——按比例用 flex 权重。
    {
        auto doc = vbox({
            hbox({
                text("w10") | size(WIDTH, EQUAL, 10) | border,
                text("w20") | size(WIDTH, EQUAL, 20) | border,
                text("上限6") | size(WIDTH, LESS_THAN, 6) | border,
            }),
            hbox({
                text("高 3") | size(HEIGHT, EQUAL, 3) | border,
                text("高 5") | size(HEIGHT, EQUAL, 5) | border,
            }),
        });
        std::cout << "-- 1) size 约束 --\n" << RenderToString(doc) << "\n";
    }

    // -- 2. Flexbox：CSS 式布局器（gap/justify/align）----------------
    {
        FlexboxConfig config;
        config.gap_x = 1;                  // 元素横向间隙 1 列
        config.gap_y = 0;
        config.justify_content = FlexboxConfig::JustifyContent::SpaceBetween;
        auto doc = flexbox({
            text("A") | border,
            text("B") | border,
            text("C") | border,
        }, config);
        std::cout << "-- 2) flexbox SpaceBetween --\n" << RenderToString(doc, 40) << "\n";
    }

    // -- 3. Gridbox：二维网格（行=hbox，格自动对齐）-------------------
    {
        auto cell = [](const char* t) { return text(t) | border | size(WIDTH, EQUAL, 8); };
        auto doc = gridbox({
            { cell("r1c1"), cell("r1c2"), cell("r1c3") },
            { cell("r2c1"), cell("r2c2"), text("跨行内容") | border },
        }) | size(WIDTH, EQUAL, 36);
        std::cout << "-- 3) gridbox --\n" << RenderToString(doc) << "\n";
    }

    // -- 4. hflow：自动折行（窗口变窄时换行）--------------------------
    {
        auto tag = [](int i) { return text(" 标签" + std::to_string(i)) | border; };
        Elements tags;
        for (int i = 1; i <= 6; ++i) tags.push_back(tag(i));
        auto doc = hflow(std::move(tags));
        std::cout << "-- 4) hflow（宽 40 内自动折行）--\n" << RenderToString(doc, 40) << "\n";
    }

    // -- 5. dbox：叠放（背景层+前景层）-------------------------------
    {
        auto bg = [] {
            Elements e;
            for (int i = 0; i < 5; ++i) e.push_back(text("████████████████████████"));
            return vbox(std::move(e)) | color(Color::Blue);
        }();
        auto fg = vbox({
            text(""),
            text("  前景层叠在背景上  ") | bgcolor(Color::GrayDark) | color(Color::White),
        });
        auto doc = dbox({ bg, fg });
        std::cout << "-- 5) dbox 叠放 --\n" << RenderToString(doc, 30) << "\n";
    }

    // -- 6. window：带标题的窗框（TUI 的窗口隐喻）---------------------
    {
        auto doc = window(text("会话"),
            vbox({ text("alice: 你好"), text("bob: 在吗"), text("alice: …") }));
        std::cout << "-- 6) window --\n" << RenderToString(doc, 30) << "\n";
    }

    // -- 7. ResizableSplit：交互分割条（交互演示段，selftest 跳过）----
    if (!selftest)
    {
        auto screen = App::FitComponent();
        int left_size = 20;
        auto left = Renderer([&] { return text("左面板") | border | ftxui::color(Color::Cyan); });
        auto right = Renderer([&] { return text("右面板（拖中间的 | 调整）") | border; });
        auto split = ResizableSplitLeft(left, right, &left_size);
        auto app = CatchEvent(split, [&](Event e) {
            if (e == Event::Character('q') || e == Event::Escape) { screen.Exit(); return true; }
            return false;
        });
        screen.Loop(app);
    }
    else
    {
        std::cout << "-- 7) ResizableSplit：交互组件，selftest 跳过实跑 --\n";
    }

    std::cout << "==== 16 FTXUI 布局进阶 结束 ====\n";
    return 0;
}
