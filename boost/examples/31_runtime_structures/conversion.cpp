// conversion.cpp —— Boost.Conversion（ polymorphic_cast 家族）：
// 多态转型的三个兄弟与各自适用场景。
// 对应文档：docs/31-runtime-structures.md
#include <boost/cast.hpp>
#include <iostream>
#include <memory>
#include <string>

struct Base { virtual ~Base() = default; virtual const char* kind() const { return "Base"; } };
struct Left : Base { const char* kind() const override { return "Left"; } };
struct Right : Base { const char* kind() const override { return "Right"; } };

int main() {
    std::unique_ptr<Base> p = std::make_unique<Left>();

    // 1) polymorphic_cast：dynamic_cast 的"抛异常"版（失败抛 bad_cast 而非返空）
    try {
        auto* l = boost::polymorphic_cast<Left*>(p.get());   // 指针进指针出
        std::cout << "转 Left 成功: " << l->kind() << '\n';
        auto* r = boost::polymorphic_cast<Right*>(p.get());  // 实际是 Left → 抛
        (void)r;
    } catch (const std::bad_cast&) {
        std::cout << "转 Right 抛 bad_cast（不是返空）\n";
    }

    // 2) polymorphic_downcast：debug 断言 + release 直转（快）
    //    约定：你**确信**是下行时的最优解（debug 有 dynamic_cast 校验）
    auto* l2 = boost::polymorphic_downcast<Left*>(p.get());
    std::cout << "downcast: " << l2->kind() << '\n';

    // 3) numeric_cast 见 24 章（同库的数值分支）

    // 4) 选型对照：
    //    dynamic_cast  — 标准通用（失败返空，指针/引用语义不同）
    //    polymorphic_cast — 统一成异常语义（引用风格更顺）
    //    polymorphic_downcast — 确信场景 + debug 校验（零成本发布）
    std::cout << "自检通过\n";
    return 0;
}
