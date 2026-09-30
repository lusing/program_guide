// ============================================================
// 15_ftxui_components.cpp —— 组件体系与事件循环
//
// 要点：
//   * App（原 ScreenInteractive，master 已改名——旧名只剩别名）：
//     Fullscreen/TerminalOutput/FitComponent 三种屏幕形态
//   * 内置组件：Input/Button/Checkbox/Radiobox/Menu/Slider/Toggle/
//     Dropdown——全是 Component，状态由你提供指针
//   * Container::Vertical/Horizontal 聚合 + Renderer 外壳包 Element
//   * 焦点环：Tab/Shift-Tab 循环（Focus 的组件才进环）
//   * CatchEvent 拦截：返回 true 吃掉事件；q/Escape 退出
//   * selftest：后台线程 PostEvent(Event::Custom)，CatchEvent 收到
//     后 Exit() 优雅退出（官方 examples/component/custom_loop.cpp 通路）
// 官方参考：examples/component/{button,input,checkbox,radiobox,menu,
//           slider,toggle,dropdown,focus,custom_loop}.cpp
// ============================================================
#include <chrono>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

#include "cppgui_jthread.hpp"            // std::jthread 兼容层（macOS 用）

#include "ftxui/component/app.hpp"       // App（= 旧 ScreenInteractive 的改名）
#include "ftxui/component/component.hpp"

int main(int argc, char** argv)
{
    using namespace ftxui;
    const bool selftest = (argc > 1 && std::string(argv[1]) == "--selftest");
    if (selftest) std::cout << "==== 15 FTXUI 组件与事件循环 开始 ====\n";

    // ---- 我们的状态（组件通过指针共享它）----
    std::string input_text = "hello";
    bool check1 = false, check2 = true;
    int  radio_sel = 1;
    int  menu_sel = 0;
    int  slider_val = 50;
    int  toggle_idx = 0;               // 【坑】Toggle 状态是 int(0/1)，不是 bool
    int  dropdown_sel = 0;
    int  button_clicks = 0;

    const std::vector<std::string> menu_entries = { "文件", "编辑", "视图", "帮助" };
    const std::vector<std::string> dropdown_entries = { "北京", "上海", "深圳" };
    const std::vector<std::string> radio_entries = { "低", "中", "高" };
    const std::vector<std::string> toggle_entries = { "关", "开" };

    auto screen = App::Fullscreen();

    // ---- 组件树：Container 聚合交互件，Renderer 提供外观 ----
    auto container = Container::Vertical({
        Input(&input_text, "输入…"),
        Button("点我 +1", [&] { button_clicks++; }),
        Container::Horizontal({
            Checkbox("选项 A", &check1),
            Checkbox("选项 B", &check2),
        }),
        Radiobox(&radio_entries, &radio_sel),
        Toggle(&toggle_entries, &toggle_idx),
        Menu(&menu_entries, &menu_sel),
        Dropdown(&dropdown_entries, &dropdown_sel),
        Slider("数值:", &slider_val, 0, 100, 1),
    });

    auto renderer = Renderer(container, [&] {
        return vbox({
            hbox({ text("输入: ") | color(Color::Yellow), text(input_text) }),
            hbox({ text("点击次数: "), text(std::to_string(button_clicks)) | color(Color::Green) }),
            separator(),
            text("radiobox 选择: " + radio_entries[radio_sel]),
            text("menu 选择: " + menu_entries[menu_sel]),
            text("dropdown 选择: " + dropdown_entries[dropdown_sel]),
            text("slider 值: " + std::to_string(slider_val)),
            hbox({ text("toggle 状态: "),
                   toggle_idx ? text("开") | color(Color::Green)
                              : text("关") | color(Color::Red) }),
            separator(),
            text("Tab/Shift+Tab 切焦点，q 或 Esc 退出") | dim,
        }) | border | size(WIDTH, LESS_THAN, 50);
    });

    // 事件拦截：q/Esc 退出；selftest 的 Event::Custom 退出
    auto app = CatchEvent(renderer, [&](Event e) {
        if (e == Event::Character('q') || e == Event::Escape)
        { screen.Exit(); return true; }
        if (e == Event::Custom && selftest)
        { screen.Exit(); return true; }
        return false;
    });

    if (selftest)
    {
        cppgui::jthread t([&screen] {
            std::this_thread::sleep_for(std::chrono::milliseconds(600));
            screen.PostEvent(Event::Custom);
        });
        screen.Loop(app);
        // jthread 析构自动 join
    }
    else
    {
        screen.Loop(app);
    }

    if (selftest)
        std::cout << "事件循环正常退出；末态 slider=" << slider_val << " toggle=" << toggle_idx
                  << " radio=" << radio_sel << " menu=" << menu_sel
                  << " dropdown=" << dropdown_sel << "\n"
                  << "==== 15 FTXUI 组件与事件循环 结束 ====\n";
    return 0;
}
