#include <array>
#include <cassert>
#include <print>
#include <vector>

#include "recursion.hpp"

// 03 递归：阶乘、斐波那契、二分查找、汉诺塔

int main() {
    // ═══ 阶乘 ═══
    assert(ds::fact(5) == 120);
    std::println("5! = {}", ds::fact(5));

    // ═══ 斐波那契：朴素版与备忘录版结果一致，工作量天差地别（正文量化）═══
    assert(ds::fib(10) == 55);
    assert(ds::fib_memo(10) == ds::fib(10));
    std::println("F(10) = {}（朴素递归与备忘录版结果相同）", ds::fib(10));

    // ═══ 递归二分查找：命中与未命中 ═══
    constexpr std::array<int, 7> sorted{1, 3, 5, 7, 9, 11, 13};
    assert(ds::binary_search_rec(sorted, 7));
    assert(!ds::binary_search_rec(sorted, 8));
    std::println("二分查找：7 命中，8 未命中");

    // ═══ 汉诺塔：3 个盘恰好 7 步。n 为奇数时首步与末步都是最小盘 from→to，
    //     故这里断言完整 7 步序列（手工推演见正文）══════════════
    std::vector<ds::Move> moves;
    ds::hanoi(3, 'A', 'B', 'C', moves);
    const std::vector<ds::Move> expected{
        {'A', 'C'}, {'A', 'B'}, {'C', 'B'}, {'A', 'C'},
        {'B', 'A'}, {'B', 'C'}, {'A', 'C'},
    };
    assert(moves == expected);
    std::println("汉诺塔 3 盘共 {} 步：", moves.size());
    for (size_t i = 0; i < moves.size(); ++i) {
        std::println("  {}. {} → {}", i + 1, moves[i].first, moves[i].second);
    }

    std::println("自检通过");
}
