// ============================================================
// 14_ftxui_dom.cpp —— FTXUI DOM 基础：声明式元素树与「渲染到字符串」
//
// 范式：FTXUI 把界面描述成一棵不可变的元素树（Element），
// 每帧整棵重建、经 Render 与旧屏 diff 后只输出变化部分——
// 与 imgui 的即时模式殊途同归，但 FTXUI 是纯函数式的声明树。
// 本例全部用「渲染到字符串再打印」的形态：输出确定、可进文档。
// ============================================================
#include <cmath>
#include <iostream>
#include <string>
#include <vector>

#include "ftxui/dom/elements.hpp"   // text/vbox/hbox/border/gauge/graph/...
#include "ftxui/screen/screen.hpp"  // Screen/Render/Dimension

using namespace ftxui;

// 把元素树渲染成字符串：固定宽度 64，高度按内容适配。
// 固定宽度保证输出确定（不随终端宽度漂移），可直接写进文档。
static std::string RenderToString(Element document, int width = 64) {
    auto screen = Screen::Create(Dimension::Fixed(width), Dimension::Fit(document));
    Render(screen, document);
    return screen.ToString();
}

int main(int argc, char** argv) {
    const bool selftest = (argc > 1 && std::string(argv[1]) == "--selftest");
    std::cout << "==== 14 FTXUI DOM 基础 开始 ====\n";

    // -- 1. 基本元素：text（UTF-8，支持 \n）、border、center ------------
    {
        auto doc = text("你好，FTXUI！\n声明式 TUI：\n界面 = 一棵不可变元素树") | border | center;
        std::cout << "-- 1) text/border/center --\n" << RenderToString(doc) << "\n";
    }

    // -- 2. 盒式布局：vbox/hbox + filler 弹性占位 ------------------------
    {
        auto doc = vbox({
            hbox({text("north-west"), filler(), text("north-east")}),
            filler(),
            hbox({filler(), text("center"), filler()}),
            filler(),
            hbox({text("south-west"), filler(), text("south-east")}),
        }) | border;
        std::cout << "-- 2) vbox/hbox/filler --\n" << RenderToString(doc) << "\n";
    }

    // -- 3. gauge 进度条与分隔线 ----------------------------------------
    {
        auto doc = vbox({
            hbox({text("下载:"), gauge(0.42f) | flex, text(" 42%")}),
            separator(),
            hbox({text("上传:"), gauge(0.87f) | flex, text(" 87%")}),
            separatorDouble(),
            text("separator / separatorDouble 分隔线"),
        }) | border;
        std::cout << "-- 3) gauge/separator --\n" << RenderToString(doc) << "\n";
    }

    // -- 4. graph：把函数画成终端曲线 -----------------------------------
    // GraphFunction = vector<int>(int width, int height)：
    // 给定画布宽高，返回每列的"填充高度"（行数），graph 据此画出柱状曲线。
    {
        auto sine = [](int width, int height) {
            std::vector<int> output(width);
            for (int i = 0; i < width; ++i)
                output[i] = static_cast<int>((std::sin(i * 2 * 3.14159f / width) * 0.5f + 0.5f) * (height - 1));
            return output;
        };
        auto doc = vbox({
            text("graph(sine)："),
            graph(sine) | size(HEIGHT, EQUAL, 7),
        }) | border;
        std::cout << "-- 4) graph --\n" << RenderToString(doc) << "\n";
    }

    // -- 5. 综合小面板：一棵树的嵌套组合 --------------------------------
    {
        auto doc = vbox({
            hbox({
                vbox({text("[F1] 帮助"), text("[F2] 保存"), text("[F10] 退出")}) | border,
                filler(),
                vbox({
                    text("磁盘"),
                    gauge(0.3f),
                    text("内存"),
                    gauge(0.6f),
                }) | border | size(WIDTH, EQUAL, 30),
            }),
        });
        std::cout << "-- 5) 综合面板 --\n" << RenderToString(doc) << "\n";
    }

    std::cout << "==== 14 FTXUI DOM 基础 结束 ====\n";
    return selftest ? 0 : 0;  // 纯输出型示例：selftest 与正常运行同路
}
