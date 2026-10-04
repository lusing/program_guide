// 03 里氏替换 + 依赖倒置。
#include <cassert>
#include <print>

#include "dip.hpp"
#include "lsp.hpp"

int main() {
    using namespace dp;

    // ---- LSP：同一个"resize 后取面积"的调用，两种结果 ----
    RectL r;
    int rect_area = area_after_resize(r);
    SquareL s;
    int square_area = area_after_resize(s);
    assert(rect_area == 20);    // 长方形合同：5*4
    assert(square_area == 16);  // 被偷偷改成 4*4 —— 这就是坏味道
    std::println("LSP: RectL 得 {}, SquareL 得 {}（后者违反合同）", rect_area,
                 square_area);

    // ---- DIP：高层 Switch 依赖抽象，低层可替换 ----
    Light light;
    Switch ls(light);
    ls.toggle();
    assert(ls.is_on() && light.state() == "light-on");
    ls.toggle();
    assert(!ls.is_on() && light.state() == "light-off");

    Fan fan;
    Switch fs(fan);          // 同一个 Switch，接上另一个设备照常工作
    fs.toggle();
    assert(fs.is_on() && fan.state() == "fan-on");
    std::println("DIP: light.state={}, fan.state={}", light.state(),
                 fan.state());

    std::println("自检通过");
}
