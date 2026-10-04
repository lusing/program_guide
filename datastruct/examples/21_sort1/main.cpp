#include <algorithm>
#include <cassert>
#include <functional>
#include <print>
#include <span>
#include <utility>
#include <vector>

#include "basic_sort.hpp"

// 21 排序（上）：插入/折半插入/冒泡/选择/快速，五种基础排序的固定夹具自检

namespace {

using SortFn = void (*)(std::span<int>);

// 对给定算法和夹具：拷贝一份排序，与 std::sort 的参照结果逐元素比对。
void check_against_std(const std::vector<int>& fixture,
                       SortFn sort_fn,
                       const char* name) {
    std::vector<int> actual = fixture;
    std::vector<int> expected = fixture;
    sort_fn(actual);
    std::ranges::sort(expected);
    assert(actual == expected);
    std::println("  {}：与 std::sort 结果一致", name);
}

void print_pairs(std::span<const std::pair<int, int>> pairs) {
    std::print("    ");
    for (std::size_t i = 0; i < pairs.size(); ++i) {
        if (i != 0) {
            std::print(",");
        }
        std::print("({},{})", pairs[i].first, pairs[i].second);
    }
    std::println();
}

}  // namespace

int main() {
    const std::vector<int> main_fixture{3, 1, 4, 1, 5, 9, 2, 6, -3, 0};
    const std::vector<std::pair<const char*, SortFn>> algorithms{
        {"插入排序", [](std::span<int> a) { ds::insertion_sort(a); }},
        {"折半插入排序", ds::binary_insertion_sort},
        {"冒泡排序", [](std::span<int> a) { ds::bubble_sort(a); }},
        {"选择排序", ds::selection_sort},
        {"快速排序", ds::quick_sort},
    };

    std::println("主夹具 {{3,1,4,1,5,9,2,6,-3,0}}：");
    for (const auto& [name, fn] : algorithms) {
        check_against_std(main_fixture, fn, name);
    }

    const std::vector<int> sorted_fixture{1, 2, 3, 4, 5};
    const std::vector<int> single_fixture{42};
    const std::vector<int> equal_fixture{7, 7, 7, 7};
    for (const auto* fixture : {&sorted_fixture, &single_fixture, &equal_fixture}) {
        for (const auto& [name, fn] : algorithms) {
            std::vector<int> actual = *fixture;
            std::vector<int> expected = *fixture;
            fn(actual);
            std::ranges::sort(expected);
            assert(actual == expected);
        }
    }
    std::println("边界夹具（已排序/单元素/全相等）：五种排序结果全部正确");

    // 稳定性演示：元素为 (key, 初始编号)，比较器只看 key。
    // 若算法稳定，相等 key 的 (1,1) 必须排在 (1,2) 前面。
    using Keyed = std::pair<int, int>;
    const auto by_first = [](const Keyed& x, const Keyed& y) {
        return x.first < y.first;
    };
    const std::vector<Keyed> pairs_seed{
        {2, 0}, {1, 1}, {1, 2}, {0, 3},
    };
    const std::vector<Keyed> stable_expected{
        {0, 3}, {1, 1}, {1, 2}, {2, 0},
    };

    std::println("稳定性演示（仅按 pair.first 比较），初始序列：");
    std::vector<Keyed> to_print = pairs_seed;
    print_pairs(to_print);

    std::vector<Keyed> inserted = pairs_seed;
    ds::insertion_sort(std::span<Keyed>(inserted), by_first);
    assert(inserted == stable_expected);
    std::println("  插入排序后：");
    print_pairs(inserted);

    std::vector<Keyed> bubbled = pairs_seed;
    ds::bubble_sort(std::span<Keyed>(bubbled), by_first);
    assert(bubbled == stable_expected);
    std::println("  冒泡排序后：");
    print_pairs(bubbled);

    // 快速排序另测一个固定数组
    std::vector<int> quick_fixture{5, -2, 8, 0, 3};
    ds::quick_sort(quick_fixture);
    const std::vector<int> quick_expected{-2, 0, 3, 5, 8};
    assert(quick_fixture == quick_expected);
    std::print("快速排序固定数组 {{5,-2,8,0,3}} →");
    for (int x : quick_fixture) {
        std::print(" {}", x);
    }
    std::println();

    std::println("自检通过");
    return 0;
}
