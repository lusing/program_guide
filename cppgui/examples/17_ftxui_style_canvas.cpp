// ============================================================
// 17_ftxui_style_canvas.cpp —— 样式系统与 Canvas 画布
//
// 要点：
//   * 颜色三代：调色板命名色(Color::Red) / 256 色(Color256(n)) /
//     真彩 RGB / HSV——终端能力不同则自动降级
//   * 前景 color() / 背景 bgcolor()
//   * 文字装饰：bold/dim/inverted/blink/underlined/strikethrough/
//     hyperlink（真 ANSI 转义——渲染到字符串里能看到 \x1b[..m）
//   * Canvas：像素级画布（列x2 行x4 的块分辨率）：
//     SetPixel/DrawPointLine/DrawBlockLine——曲线/图形用
//   * linear_gradient：水平/垂直线性渐变
// 本例主体渲染到字符串：输出确定；ANSI 转义原样可见（教学点）。
// 官方参考：examples/dom/{color_*,style_*,canvas,linear_gradient}.cpp、
//           examples/component/canvas_animated.cpp
// ============================================================
#include <cmath>
#include <iostream>
#include <string>

#include "ftxui/dom/canvas.hpp"
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
    std::cout << "==== 17 FTXUI 样式与画布 开始 ====\n";

    // -- 1. 命名色 / 256 色 / 真彩 RGB / HSV -------------------------
    // 【坑】256 色没有 Color256() 工厂——用 Palette256 枚举（可隐式转 Color）
    {
        auto doc = vbox({
            hbox({
                text(" 命名色 ") | color(Color::Red) | bgcolor(Color::GrayDark),
                text(" 256色 ") | color(Color::Palette256(208)) | bgcolor(Color::Palette256(17)),
                text(" RGB ") | color(Color::RGB(12, 200, 120)),
                text(" HSV ") | color(Color::HSV(200, 80, 90)),  // hue 是 uint8_t：280 会回绕成 24
            }),
            separator(),
            text("真彩在老终端自动降级到 256 色或 16 色"),
        });
        std::cout << "-- 1) 颜色四代 --\n" << RenderToString(doc) << "\n";
    }

    // -- 2. 文字装饰全家 -------------------------------------------
    {
        auto doc = vbox({
            text("bold 粗体") | bold,
            text("dim 变暗") | dim,
            text("inverted 反白") | inverted,
            text("underlined 下划线") | underlined,
            text("strikethrough 删除线") | strikethrough,
            text("blink 闪烁") | blink,
            text("链接") | hyperlink("https://example.com") | color(Color::Blue) | underlined,
        });
        std::cout << "-- 2) 装饰（ANSI 转义在字符串里可见）--\n"
                  << RenderToString(doc, 30) << "\n";
    }

    // -- 3. Canvas：像素画布（块分辨率 2x4）------------------------
    {
        auto c = Canvas(50, 12);
        // 网格参考线
        for (int x = 0; x < 50; x += 10)
            c.DrawPointLine(x, 0, x, 11, Color::GrayLight);
        // 正弦曲线（点线）
        for (int x = 0; x < 50; ++x)
        {
            float y = 5.5f + 4.5f * std::sin(x * 2 * 3.14159f / 49);
            c.DrawPoint(x, (int)y, Color::Red);
        }
        // 块线（粗）
        c.DrawBlockLine(0, 11, 49, 6, Color::Blue);
        // 圆（Canvas 没有画圆 API——参数方程手画）
        for (float a = 0; a < 6.2832f; a += 0.05f)
            c.DrawPoint(25 + (int)(4 * std::cos(a) * 2), 6 + (int)(4 * std::sin(a)),
                        Color::Green);
        auto doc = canvas(std::move(c)) | border;
        std::cout << "-- 3) canvas --\n" << RenderToString(doc, 54) << "\n";
    }

    // -- 4. LinearGradient 渐变（builder 式：角度 + 多个 Stop）------
    {
        auto doc = hbox({
            text(" 渐变文字 ") | center | size(WIDTH, EQUAL, 30)
                | bgcolor(LinearGradient().Angle(90)
                              .Stop(Color::DeepPink1).Stop(Color::DeepSkyBlue1)),
        });
        std::cout << "-- 4) LinearGradient --\n" << RenderToString(doc, 34) << "\n";
    }

    // -- 5. 动画思路（交互模式跑，selftest 跳过）--------------------
    if (selftest)
        std::cout << "-- 5) canvas 动画：交互模式演示（thread + PostEvent 每帧重绘）--\n";

    std::cout << "==== 17 FTXUI 样式与画布 结束 ====\n";
    return 0;
}
