// 07 抽象工厂。
#include <cassert>
#include <print>

#include "abstract_factory.hpp"

int main() {
    using namespace dp;

    // 两族产品各自配套，draw_dialog 只认抽象工厂
    std::string win = draw_dialog(WinFactory{});
    std::string linux = draw_dialog(LinuxFactory{});
    assert(win == "win-button+win-border");
    assert(linux == "linux-button+linux-border");
    std::println("抽象工厂: {}", win);
    std::println("抽象工厂: {}", linux);

    // concepts 约束在编译期把关：两个工厂都满足，缺一半产品的类型不满足
    static_assert(WidgetFactoryLike<WinFactory>);
    static_assert(WidgetFactoryLike<LinuxFactory>);

    // 混族是"能编译但荒谬"的设计：WinFactory 造按钮、LinuxFactory 造边框
    // 的工厂不满足任何一致的视觉族——所以 draw_dialog 只给整族工厂。
    // 若有人写出这样的类型，concept 会在实例化点拒绝它：
    //   struct Broken { std::unique_ptr<Button> make_button() const; };
    //   draw_dialog_requires_factory(Broken{});   // 缺 make_border，编译失败
    std::println("自检通过");
}
