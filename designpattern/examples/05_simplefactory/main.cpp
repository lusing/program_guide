// 05 简单工厂。
#include <cassert>
#include <print>

#include "registry_factory.hpp"
#include "simple_factory.hpp"

int main() {
    using namespace dp;

    // ---- 三段演化的第一段：if-else 简单工厂 ----
    auto s = create_shape("circle");
    assert(s.has_value() && (*s)->name() == "circle");

    auto bad = create_shape("hex");          // 未知名 → expected 错误，不抛异常
    assert(!bad.has_value() && bad.error() == "未知形状: hex");
    std::println("简单工厂: circle ok, hex -> {}", bad.error());

    // ---- 第二段：注册表工厂，加形状不再改工厂代码 ----
    auto& reg = ShapeRegistry::instance();
    reg.add("circle", [] { return std::make_unique<Circle>(); });
    reg.add("square", [] { return std::make_unique<Square>(); });
    assert(reg.size() == 2);

    auto r1 = reg.make("square");
    assert(r1.has_value() && (*r1)->name() == "square");
    auto r2 = reg.make("hex");
    assert(!r2.has_value() && r2.error() == "未注册形状: hex");
    std::println("注册表: size={}, hex -> {}", reg.size(), r2.error());

    std::println("自检通过");
}
