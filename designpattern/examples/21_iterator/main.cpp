// 21 迭代器。
#include <array>
#include <cassert>
#include <print>
#include <ranges>
#include <vector>

#include "gen.hpp"
#include "tree.hpp"

int main() {
    using namespace dp;

    // ---- 乱序插入 7 个 int，中序遍历得到升序 ----
    Tree<int> tree;
    for (int v : {50, 30, 70, 20, 40, 60, 80}) tree.insert(v);
    assert(tree.size() == 7);

    std::vector<int> inorder;
    for (int v : tree) inorder.push_back(v);          // 范围 for：迭代器的消费端
    assert((inorder == std::vector<int>{20, 30, 40, 50, 60, 70, 80}));
    std::println("迭代器: 乱序插入 7 个，中序 = {}", "20 30 40 50 60 70 80");

    // ---- 哨兵结束比较有效 ----
    auto it = tree.begin();
    assert(it != std::default_sentinel);               // 未遍历完：不等于哨兵
    for (size_t i = 0; i < tree.size(); ++i) ++it;     // 消费完 7 个
    assert(it == std::default_sentinel);               // 栈空：等于哨兵
    std::println("迭代器: default_sentinel 哨兵比较有效");

    // ---- ranges 算法直接消费自定义迭代器 ----
    auto evens = tree | std::views::filter([](int v) { return v % 20 == 0; });
    std::vector<int> ev;
    for (int v : evens) ev.push_back(v);
    assert((ev == std::vector<int>{20, 40, 60, 80}));
    std::println("ranges: views::filter 串接自定义迭代器 -> 20 40 60 80");

    // ---- 现代对照：协程生成器——遍历逻辑写成顺序代码 ----
    std::vector<int> fibs;
    for (int v : fib_gen(8)) fibs.push_back(v);
    assert((fibs == std::vector<int>{0, 1, 1, 2, 3, 5, 8, 13}));
    std::println("生成器: fib 前 8 项 = 0 1 1 2 3 5 8 13");

    std::println("自检通过");
}
