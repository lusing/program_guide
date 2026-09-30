// ============================================================
// 19_ftxui_app.cpp —— 综合实战：交互式待办管理器
//
// 回收 14–18 全部技术：Menu 分类 / Checkbox 完成 / Input+Button
// 新增 / Container::Tab 双视图 / Modal 确认清空 / Maybe 空列表占位 /
// 后台线程 Post 时钟 / CatchEvent 退出。
// 状态模型：vector<Task>{文本, 完成}——组件都拿指针共享它。
// ============================================================
#include <chrono>
#include <iostream>
#include <string>
#include <thread>
#include <vector>

#include "ftxui/component/app.hpp"
#include "ftxui/component/component.hpp"
#include "ftxui/component/event.hpp"
#include "ftxui/dom/elements.hpp"
#include "ftxui/screen/screen.hpp"

using namespace ftxui;

struct TodoItem { std::string text; bool done; };   // 避开 ftxui::Task（variant）

struct Category { std::string name; std::vector<TodoItem> tasks; };

static std::vector<std::string> split(const std::string& s, char sep)
{
    std::vector<std::string> out;
    size_t a = 0;
    while (true)
    {
        size_t b = s.find(sep, a);
        out.push_back(s.substr(a, b - a));
        if (b == std::string::npos) return out;
        a = b + 1;
    }
}
static std::string Snap(ftxui::Element document, int width)
{
    auto screen = ftxui::Screen::Create(
        ftxui::Dimension::Fixed(width), ftxui::Dimension::Fit(document));
    ftxui::Render(screen, document);
    return screen.ToString();
}

int main(int argc, char** argv)
{
    const bool selftest = (argc > 1 && std::string(argv[1]) == "--selftest");
    if (selftest) std::cout << "==== 19 FTXUI 待办管理器 开始 ====\n";

    std::vector<Category> cats = {
        { "工作", { { "写周报", false }, { "评审 PR", true } } },
        { "生活", { { "买牛奶", false } } },
        { "学习", { { "读 FTXUI 源码", false }, { "写小结", false } } },
    };
    int cat_sel = 0;
    std::string input_text;
    bool show_confirm = false;
    int tab = 0;
    int clock_ticks = 0;                 // 后台线程驱动（不进输出，保持确定）

    auto screen = App::Fullscreen();
    auto& tasks = cats;                  // 别名：回调里按 cat_sel 取

    // ---- 右侧任务行：Checkbox + 删除 ----
    auto task_row = Container::Vertical({});
    auto refresh_rows = [&] {
        task_row->DetachAllChildren();
        for (size_t i = 0; i < tasks[cat_sel].tasks.size(); ++i)
        {
            auto& t = tasks[cat_sel].tasks[i];
            auto idx = i;
            auto row = Container::Horizontal({
                Checkbox(t.text, &t.done),
                Button("删", [&, idx] { tasks[cat_sel].tasks.erase(tasks[cat_sel].tasks.begin() + idx); }),
            });
            task_row->Add(row);
        }
    };

    // ---- 左侧分类菜单 ----
    std::vector<std::string> cat_names;
    for (auto& c : cats) cat_names.push_back(c.name);
    auto menu = Menu(&cat_names, &cat_sel);
    menu |= CatchEvent([&](Event) { refresh_rows(); return false; });

    // ---- 底部输入 + 新增 ----
    auto input = Input(&input_text, "新任务…");
    auto add_btn = Button("新增", [&] {
        if (!input_text.empty())
        {
            tasks[cat_sel].tasks.push_back({ input_text, false });
            input_text.clear();
            refresh_rows();
        }
    });
    auto clear_btn = Button("清空当前分类", [&] { show_confirm = true; });
    auto bottom = Container::Horizontal({ input, add_btn, clear_btn });

    // ---- Tab：列表视图 / 统计视图 ----
    auto list_view = Renderer(Container::Vertical({ menu, task_row, bottom }), [&] {
        refresh_rows();                          // 每帧同步（演示从简）
        auto& cat = tasks[cat_sel];
        size_t done_n = 0;
        for (auto& t : cat.tasks) done_n += t.done;
        auto empty_hint = Renderer([] {
            return text("（空）按下方输入框新增任务") | dim | center;
        });
        auto list_body = cat.tasks.empty()
            ? empty_hint->Render()
            : task_row->Render();
        return hbox({
            // 左：分类菜单
            window(text("分类"), menu->Render()) | size(WIDTH, EQUAL, 16),
            separator(),
            // 右：任务列表 + 底部输入
            vbox({
                window(text(cat.name + " (" + std::to_string(done_n) + "/"
                            + std::to_string(cat.tasks.size()) + ")"), list_body) | flex,
                hbox({ text("> "), input->Render(), add_btn->Render(), clear_btn->Render() }),
            }) | flex,
        });
    });

    auto stats_view = Renderer([&] {
        size_t total = 0, done = 0;
        std::vector<Element> rows;
        for (auto& c : cats)
        {
            size_t d = 0;
            for (auto& t : c.tasks) d += t.done;
            total += c.tasks.size(); done += d;
            rows.push_back(hbox({
                text(c.name) | size(WIDTH, EQUAL, 8),
                gauge(float(d) / std::max<size_t>(1, c.tasks.size())),
                text(" " + std::to_string(d) + "/" + std::to_string(c.tasks.size())),
            }));
        }
        rows.push_back(separator());
        rows.push_back(text("总计: " + std::to_string(done) + "/" + std::to_string(total)));
        return vbox(std::move(rows)) | border | size(WIDTH, LESS_THAN, 50);
    });

    auto tabs = Container::Tab({ list_view, stats_view }, &tab);
    auto main = Renderer(tabs, [&] {
        return vbox({
            hbox({
                text(tab == 0 ? " [列表] " : "  列表  "),
                text(tab == 1 ? " [统计] " : "  统计  "),
                text("（Tab 键切换；a 新增焦点在输入框）") | dim | flex,
                text("异步时钟运行中") | dim,   // 后台线程在跑（帧内不显时序数据：保输出确定）
            }),
            separator(),
            tabs->Render(),
        });
    });

    // ---- 模态确认 ----
    auto confirm = Renderer([] { return text("确认清空？(y/n)"); });
    auto modal_box = Renderer(confirm, [=] {
        return confirm->Render() | border | color(Color::Red) | center;
    });
    auto app = Modal(main, modal_box, &show_confirm);

    auto guarded = CatchEvent(app, [&](Event e) {
        if (e == Event::Character('q') || e == Event::Escape)
        { screen.Exit(); return true; }
        if (show_confirm && e == Event::Character('y'))
        { tasks[cat_sel].tasks.clear(); show_confirm = false; return true; }
        if (show_confirm && e == Event::Character('n'))
        { show_confirm = false; return true; }
        if (e == Event::Custom && selftest)
        { screen.Exit(); return true; }
        return false;
    });

    // 后台时钟：每 500ms Post 闭包回主循环安全地改状态。
    // 【实测坑位】selftest 不启动它——Post 会触发重绘，重绘次数随时序
    // 漂移，stdout 两跑一致性判定必炸（异步机制的交互演示见交互模式）。
    std::jthread clock_thread;
    if (!selftest)
        clock_thread = std::jthread([&screen, &clock_ticks] {
            for (int i = 0; i < 100; ++i)
            {
                std::this_thread::sleep_for(std::chrono::milliseconds(500));
                screen.Post(Task{ Closure{ [&clock_ticks] { ++clock_ticks; } } });
            }
        });

    if (selftest)
    {
        // 【实测坑位】不进终端循环：Input 光标闪烁定时器会周期性触发整帧
        // 重绘，退出边界上"多一帧/少一帧"是时序竞态——管道输出两跑必然
        // 漂移（循环通路本身已由 15 章实证）。这里改无头驱动：手动喂事件
        // + 渲染快照，逻辑覆盖反而更完整。
        tasks[0].tasks.push_back({ "selftest 任务", false });
        tasks[0].tasks.back().done = true;

        // 模态流：打开确认 → 'y' 清空"生活"分类
        cat_sel = 1;
        show_confirm = true;
        guarded->OnEvent(Event::Character('y'));
        std::cout << "modal y 后生活分类任务数=" << tasks[1].tasks.size() << "\n";

        // 新增流：输入文本 → 触发新增回调
        cat_sel = 2;
        input_text = "无头新增";
        guarded->OnEvent(Event::Character('x'));   // 任意键走一遍事件链
        add_btn->OnEvent(Event::Return);           // Button 的触发事件
        std::cout << "新增后学习分类任务数=" << tasks[2].tasks.size() << "\n";

        // 双视图快照
        tab = 0;
        auto snap1 = Snap(guarded->Render(), 64);
        tab = 1;
        auto snap2 = Snap(guarded->Render(), 64);
        std::cout << "-- 统计视图快照 --\n" << snap2 << "\n";
    }
    else
    {
        screen.Loop(guarded);
    }

    if (selftest)
    {
        size_t total = 0, done = 0;
        for (auto& c : cats)
            for (auto& t : c.tasks) { ++total; done += t.done; }
        std::cout << "退出；任务总数=" << total << " 已完成=" << done
                  << " 分类数=" << cats.size() << "\n"
                  << "==== 19 FTXUI 待办管理器 结束 ====\n";
    }
    return 0;
}
