#include <algorithm>
#include <cassert>
#include <cmath>
#include <print>
#include <string>
#include <vector>

#include "dp.hpp"

// 25 动态规划：0/1 背包（滚动数组+回溯）、矩阵链乘、凑硬币组合数、最优 BST

namespace {
// 把下标向量拼成 "[0 1]" 形式的确定字符串（手拼最稳，不依赖各实现的范围格式化）
std::string join_indices(const std::vector<int>& v) {
    std::string s = "[";
    for (std::size_t i = 0; i < v.size(); ++i) {
        if (i > 0) {
            s += ' ';
        }
        s += std::to_string(v[i]);
    }
    s += "]";
    return s;
}
}  // namespace

int main() {
    // ═══ 0/1 背包：values[3,4,5,6]，weights[2,3,4,5]，容量 5 ═══
    // 最优解：物品 0（值3重2）+ 物品 1（值4重3）= 价值 7、重量恰好 5
    {
        const std::vector<int> values{3, 4, 5, 6};
        const std::vector<int> weights{2, 3, 4, 5};
        const ds::KnapsackSol sol = ds::knapsack_dp(values, weights, 5);
        assert(sol.value == 7);
        std::vector<int> picked = sol.items;
        std::ranges::sort(picked);
        assert((picked == std::vector<int>{0, 1}));
        std::println("0/1 背包：容量 5，最优价值 {}，选中物品 {}",
                     sol.value, join_indices(picked));
    }

    // ═══ 矩阵链乘：A1(10×30) · A2(30×5) · A3(5×60) ═══
    // (A1·A2)·A3 = 10*30*5 + 10*5*60 = 1500 + 3000 = 4500，优于 A1·(A2·A3) 的 27000
    {
        const std::vector<int> dims{10, 30, 5, 60};
        const int cost = ds::matrix_chain(dims);
        assert(cost == 4500);
        std::println("矩阵链乘：最少标量乘法 {}（(A1·A2)·A3 括号法）", cost);
    }

    // ═══ 凑硬币组合数：面值 {1,2,5} 凑 5 元 ═══
    // 组合：{5}、{2,2,1}、{2,1,1,1}、{1,1,1,1,1}，共 4 种
    {
        const std::vector<int> coins{1, 2, 5};
        const int ways = ds::coin_change_ways(coins, 5);
        assert(ways == 4);
        std::println("凑硬币：金额 5 的组合方案数 {}（不计顺序）", ways);
    }

    // ═══ 最优 BST：CLRS 经典数据，n=5 ═══
    // 最优期望比较次数 2.75，根为键 k2（0-based 下标 1）
    {
        const std::vector<double> p{0.15, 0.10, 0.05, 0.10, 0.20};
        const std::vector<double> q{0.05, 0.10, 0.05, 0.05, 0.05, 0.10};
        const ds::BstCost bst = ds::optimal_bst(p, q);
        assert(std::fabs(bst.cost - 2.75) < 1e-9);
        assert(bst.root == 1);
        std::println("最优 BST：期望比较次数 {:.2f}，根为键 {}（0-based）",
                     bst.cost, bst.root);
    }

    std::println("自检通过");
}
