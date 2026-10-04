// 01 开篇：23 个 GoF 模式的三分法清单 + 三书分工 + 标准档自证。
#include <cassert>
#include <print>

namespace dp {
// 三分法只是记忆的抽屉，不是使用时的顺序——先记住有哪几个，后面 38 章再逐个打开。
struct Group {
    int count;
    const char* kind;
    const char* names;
};
}  // namespace dp

int main() {
    using namespace dp;

    // 断言 1：三分法总数必须恰好 23（创建 5 + 结构 7 + 行为 11）。
    constexpr int creational = 5;
    constexpr int structural = 7;
    constexpr int behavioral = 11;
    static_assert(creational + structural + behavioral == 23,
                  "GoF 模式总数应为 23");

    // 断言 2：本教程要求 C++23 档（MSVC 用 _MSVC_LANG，clang 用 __cplusplus）。
#if defined(_MSVC_LANG)
    static_assert(_MSVC_LANG >= 202302L, "需要 C++23");
#else
    static_assert(__cplusplus >= 202302L, "需要 C++23");
#endif

    constexpr Group groups[] = {
        {5, "创建型(5)", "抽象工厂 建造者 工厂方法 原型 单例"},
        {7, "结构型(7)", "适配器 桥 组合 装饰 外观 享元 代理"},
        {11, "行为型(11)", "职责链 命令 解释器 迭代器 中介者 备忘录 观察者 状态 策略 模板方法 访问者"},
    };
    int total = 0;
    for (const auto& g : groups) {
        std::println("{}: {}", g.kind, g.names);
        total += g.count;
    }
    assert(total == 23);

    std::println("三书分工: 之禅=叙事 | 刘伟=定义/角色表 | GoF=出处/经典实现");
    std::println("本教程主线: 每模式 = 经典写法 + C++23 现代写法 + 取舍结论");
    std::println("自检通过");
}
