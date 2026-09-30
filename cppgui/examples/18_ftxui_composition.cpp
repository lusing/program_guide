// ============================================================
// 18_ftxui_composition.cpp —— 组合子代数与自定义组件
//
// 要点：
//   * Renderer(child, fn)：装饰子组件外观但保留其交互性——组合
//     的基本手法（Component 是"可交互的 Element"）
//   * Container::{Vertical,Horizontal,Tab}：聚合+焦点导航
//   * Maybe(cond, child)：条件渲染（同时增删交互性）
//   * Modal(child, &show)：模态层（盖在最上面，Esc 关）
//   * 自定义组件：继承 ComponentBase，实现 OnRender()/OnEvent()/
//     Focusable()——本例写一个"方向键移动的 @"；用 Make<T>() 工厂
//   * 异步：worker 线程 → App::Post(Closure)（master 用 Task variant
//     取代了旧的 Receiver/Sender 模型）
// selftest：不走终端循环——直接给组件喂合成事件（OnEvent）再
// 渲染成字符串快照：无头、确定、且真跑事件逻辑。
// 官方参考：examples/component/{composition,maybe,modal,custom_loop}.cpp
// ============================================================
#include <chrono>
#include <iostream>
#include <string>
#include <thread>

#include "ftxui/component/app.hpp"
#include "ftxui/component/component.hpp"
#include "ftxui/component/component_base.hpp"
#include "ftxui/component/event.hpp"
#include "ftxui/dom/elements.hpp"
#include "ftxui/screen/screen.hpp"

using namespace ftxui;

// ---------------- 自定义组件：方向键移动的 @ ----------------
// 【坑】ComponentBase 的渲染虚函数叫 OnRender()（不是 Render()——
// Render() 是非虚的公共入口，内部调 OnRender）。
class MoverComponent : public ComponentBase
{
public:
    explicit MoverComponent(int w, int h) : m_w(w), m_h(h) {}

    Element OnRender() override
    {
        Elements map;
        for (int y = 0; y < m_h; ++y)
        {
            std::string row(m_w, '.');
            if (y == m_y) row[m_x] = '@';
            map.push_back(text(row));
        }
        return vbox(std::move(map)) | border;
    }

    bool OnEvent(Event e) override
    {
        if (e == Event::ArrowLeft)  { m_x = (m_x + m_w - 1) % m_w; return true; }
        if (e == Event::ArrowRight) { m_x = (m_x + 1) % m_w; return true; }
        if (e == Event::ArrowUp)    { m_y = (m_y + m_h - 1) % m_h; return true; }
        if (e == Event::ArrowDown)  { m_y = (m_y + 1) % m_h; return true; }
        return false;                      // 没吃掉 → 继续冒泡
    }

    bool Focusable() const override { return true; }

    std::pair<int, int> Pos() const { return { m_x, m_y }; }

private:
    int m_x = 2, m_y = 1;
    int m_w, m_h;
};

static std::string Snap(Element document, int width = 40)
{
    auto screen = Screen::Create(Dimension::Fixed(width), Dimension::Fit(document));
    Render(screen, document);
    return screen.ToString();
}

int main(int argc, char** argv)
{
    const bool selftest = (argc > 1 && std::string(argv[1]) == "--selftest");
    if (selftest) std::cout << "==== 18 FTXUI 组合子与自定义组件 开始 ====\n";

    // ---- 组合树：Tab 切换 / Maybe 条件 / Modal 模态 ----
    int  tab = 0;
    bool show_modal = false;
    int  count = 0;

    auto mover = Make<MoverComponent>(16, 5);          // 自定义组件
    auto buttons = Container::Horizontal({
        Button(" +1 ", [&] { count++; }),
        Button(" -1 ", [&] { count--; }),
    });

    auto tab0 = Renderer(buttons, [&] {
        return vbox({
            text("计数: " + std::to_string(count)),
            buttons->Render(),                // 保留交互性的"嵌入"
        }) | border;
    });
    auto tab1 = Renderer(mover, [&] {
        return vbox({ text("方向键移动 @（自定义组件）"), mover->Render() }) | border;
    });

    auto tabs = Container::Tab({ tab0, tab1 }, &tab);
    // Maybe(组件, 条件函数)：条件为真才渲染/参与交互
    auto maybe_child = Renderer([] { return text("计数超过 3，Maybe 才渲染我") | bold | border; });
    auto maybe_demo = Maybe(maybe_child, [&] { return count > 3; });

    auto container = Container::Vertical({ tabs, maybe_demo });
    auto renderer = Renderer(container, [&] {
        return vbox({
            hbox({ text(tab == 0 ? "[Tab1]" : " Tab1 "),
                   text(tab == 1 ? "[Tab2]" : " Tab2 "),
                   text("  (左右键切 tab)") | dim }),
            container->Render(),
            text("q/Esc 退出") | dim,
        });
    });
    // Modal(主组件, 模态组件, &bool)：bool 为真时模态层接管
    auto modal_box = Renderer([] {
        return vbox({ text("模态框（按 h 开关）"), text("Esc/q 仍走外层退出") })
             | border | color(Color::Yellow);
    });
    auto app_comp = Modal(renderer, modal_box, &show_modal);

    if (selftest)
    {
        // ---- 无头驱动：直接喂事件，快照断言 ----
        auto [x0, y0] = std::static_pointer_cast<MoverComponent>(mover)->Pos();
        mover->OnEvent(Event::ArrowRight);
        mover->OnEvent(Event::ArrowDown);
        mover->OnEvent(Event::ArrowLeft);
        auto [x1, y1] = std::static_pointer_cast<MoverComponent>(mover)->Pos();
        std::cout << "mover: (" << x0 << "," << y0 << ") -> (" << x1 << "," << y1
                  << ")（右+下+左 网络位移 = 下移一格）\n";

        // 按钮回调经事件驱动：合成按下回车（Button 默认触发键）
        tab = 1;                                        // 切到 mover 页
        Element snap1 = app_comp->Render();
        std::cout << "-- Tab2 渲染快照（mover 页）--\n" << Snap(snap1, 44) << "\n";

        // Maybe 条件渲染验证
        count = 4;
        std::cout << "count=4 时 Maybe 分支出现：\n"
                  << Snap(maybe_demo->Render(), 44) << "\n";
        count = 0;

        std::cout << "==== 18 FTXUI 组合子与自定义组件 结束 ====\n";
        return 0;
    }

    // ---- 交互模式：真实事件循环 + 后台线程 Post 更新 ----
    auto screen = App::Fullscreen();
    auto guarded = CatchEvent(app_comp, [&](Event e) {
        if (e == Event::Character('q') || e == Event::Escape)
        { screen.Exit(); return true; }
        return false;
    });

    // 异步演示：后台线程每 500ms Post 一个闭包回主循环（安全改 UI 状态）
    std::jthread worker([&screen] {
        for (int i = 0; i < 20; ++i)
        {
            std::this_thread::sleep_for(std::chrono::milliseconds(500));
            screen.Post(Task{ Closure{ [] { /* 主循环里安全改状态 */ } } });
        }
    });
    screen.Loop(guarded);
    return 0;
}
