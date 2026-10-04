#include <array>
#include <cassert>
#include <print>
#include <vector>

#include "perf.hpp"

// 02 程序性能：用固定数据观察"操作步数"的差别

int main() {
    constexpr int n = 100;

    // ═══ 同一个求和问题，两种算法的步数量级 ═══
    const long long by_loop = ds::sum_loop(n);
    const long long by_formula = ds::sum_formula(n);
    assert(by_loop == 5050);
    assert(by_loop == by_formula);
    std::println("1+…+{} = {}：循环法步数与 n 成正比（{} 次加法），公式法步数恒定（1 次）",
                 n, by_loop, n);

    // ═══ 插入排序：逆序数据触发最多比较，次数恰为 n(n-1)/2 ═══
    std::array<ds::Counter, 8> a{{
        {8, 0}, {7, 0}, {6, 0}, {4, 0}, {5, 0}, {3, 0}, {2, 0}, {1, 0},
    }};
    // 特意让 value 序列在第 3、4 位上也是严格下降：构造全逆序
    a = {{
        {8, 0}, {7, 0}, {6, 0}, {5, 0}, {4, 0}, {3, 0}, {2, 0}, {1, 0},
    }};
    long long comparisons = 0;
    ds::insertion_sort_with_count(a, comparisons);
    assert(comparisons == 8LL * 7 / 2);  // 28
    for (size_t i = 1; i < a.size(); ++i) {
        assert(a[i - 1].value <= a[i].value);
    }
    std::println("8 元素全逆序插入排序：比较 {} 次（最坏情形 n(n-1)/2），排序后有序",
                 comparisons);

    std::println("自检通过");
}
