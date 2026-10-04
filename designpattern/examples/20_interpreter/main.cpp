// 20 解释器。
#include <array>
#include <cassert>
#include <memory>
#include <print>
#include <span>
#include <utility>
#include <vector>

#include "interp.hpp"
#include "variant_interp.hpp"

int main() {
    using namespace dp;

    // ---- 表达式树：v0 and (not v1) or v2 ----
    // 文法树：(or (and v0 (not v1)) v2)
    auto expr = std::make_unique<Or>(
        std::make_unique<And>(
            std::make_unique<Var>(0),
            std::make_unique<Not>(std::make_unique<Var>(1))),
        std::make_unique<Var>(2));

    // ---- 8 组真值组合与手算表穷举比对 ----
    // 手算：v0 && !v1 || v2
    std::vector<bool> expected;      // 按 (v0,v1,v2) 二进制序
    for (int bits = 0; bits < 8; ++bits) {
        bool v0 = bits & 1, v1 = bits & 2, v2 = bits & 4;
        expected.push_back((v0 && !v1) || v2);
    }
    for (int bits = 0; bits < 8; ++bits) {
        std::array<bool, 3> env{static_cast<bool>(bits & 1),
                                static_cast<bool>(bits & 2),
                                static_cast<bool>(bits & 4)};
        bool got = expr->eval(env);
        assert(got == expected[bits]);           // 树求值 == 手算表
        std::println("组合{}: v0={} v1={} v2={} -> {}", bits, env[0], env[1],
                     env[2], got);
    }

    // ---- variant 版：同一表达式，8 组逐项同值 ----
    auto vexpr = make_or(
        make_and(make_var(0), make_not(make_var(1))),
        make_var(2));
    for (int bits = 0; bits < 8; ++bits) {
        std::array<bool, 3> env{static_cast<bool>(bits & 1),
                                static_cast<bool>(bits & 2),
                                static_cast<bool>(bits & 4)};
        assert(veval(*vexpr, env) == expected[bits]);
    }
    std::println("variant: 8 组真值与继承版逐项同值");

    // ---- 化简：not not v0 -> v0 ----
    auto doubled = make_not(make_not(make_var(0)));
    auto simp = vsimplify(*doubled);
    std::array<bool, 3> probe{true, false, false};
    assert(veval(*simp, probe) == probe[0]);     // 化简后语义等价于 v0 本身
    std::println("化简: not not v0 -> v0（语义保持）");

    std::println("自检通过");
}
