#pragma once
#include <cstddef>
#include <limits>
#include <span>
#include <stdexcept>
#include <vector>

namespace ds {

struct KnapsackSol {
    int value;               // 最优总价值
    std::vector<int> items;  // 选中物品下标（回溯自然产生降序，调用方按需排序）
};

// 0/1 背包：滚动数组求值 + 逐层快照回溯选品。
// 前提：values 与 weights 等长、weights 非负、cap >= 0，否则抛 std::invalid_argument。
// 转移：dp_i[c] = max(dp_{i-1}[c], dp_{i-1}[c-w_i] + v_i)。
// 本实现逐层存档 dp 数组：转移本身仍是"一维滚动数组、容量倒序"，存档只为回溯选品。
inline KnapsackSol knapsack_dp(std::span<const int> values,
                               std::span<const int> weights, int cap) {
    if (weights.size() != values.size()) {
        throw std::invalid_argument("knapsack_dp: values 与 weights 长度不一致");
    }
    if (cap < 0) {
        throw std::invalid_argument("knapsack_dp: 容量不能为负");
    }
    for (const int w : weights) {
        if (w < 0) {
            throw std::invalid_argument("knapsack_dp: 物品重量不能为负");
        }
    }
    const std::size_t n = values.size();
    const std::size_t cols = static_cast<std::size_t>(cap) + 1;
    // snapshot[i] = 只考虑前 i 件物品时各容量的最优价值；snapshot[0] 恒为全零
    std::vector<std::vector<int>> snapshot(n + 1, std::vector<int>(cols, 0));
    for (std::size_t i = 0; i < n; ++i) {
        std::vector<int>& cur = snapshot[i + 1];
        cur = snapshot[i];  // 基线：一律先"不选第 i 件"
        for (int c = cap; c >= weights[i]; --c) {  // 容量倒序：每件物品至多用一次
            const std::size_t ci = static_cast<std::size_t>(c);
            const int take = snapshot[i][ci - static_cast<std::size_t>(weights[i])]
                           + values[i];
            if (take > cur[ci]) {
                cur[ci] = take;
            }
        }
    }
    // 回溯：从最后一件往前看，容量 c 处价值相对上一层发生变化 ⇔ 第 i-1 件必选
    KnapsackSol sol;
    sol.value = snapshot[n][static_cast<std::size_t>(cap)];
    int c = cap;
    for (std::size_t i = n; i > 0; --i) {
        const std::size_t ci = static_cast<std::size_t>(c);
        if (snapshot[i][ci] != snapshot[i - 1][ci]) {
            sol.items.push_back(static_cast<int>(i - 1));
            c -= weights[i - 1];
        }
    }
    return sol;
}

// 矩阵链乘：dims 长 n+1，第 i 个矩阵为 dims[i] × dims[i+1]；返回最少标量乘法次数。
inline int matrix_chain(std::span<const int> dims) {
    if (dims.size() < 2) {
        return 0;  // 连一对维度都凑不齐，没有乘法可做
    }
    const std::size_t n = dims.size() - 1;  // 矩阵个数
    // dp[i][j] = 把 A_i..A_j 乘起来所需的最少标量乘法；长度 1 时为 0
    std::vector<std::vector<int>> dp(n, std::vector<int>(n, 0));
    for (std::size_t len = 2; len <= n; ++len) {        // 区间长度从小到大
        for (std::size_t i = 0; i + len <= n; ++i) {
            const std::size_t j = i + len - 1;
            int best = std::numeric_limits<int>::max();
            for (std::size_t k = i; k < j; ++k) {       // 括号位置：最后一步在 k 与 k+1 之间
                const int cost = dp[i][k] + dp[k + 1][j]
                               + dims[i] * dims[k + 1] * dims[j + 1];
                if (cost < best) {
                    best = cost;
                }
            }
            dp[i][j] = best;
        }
    }
    return dp[0][n - 1];
}

// 凑硬币组合数：每种硬币可用任意多枚，凑出 amount 的组合（不计顺序）数。
// 外层硬币、内层金额升序 → 组合数；两层循环对调 → 排列数。
inline int coin_change_ways(std::span<const int> coins, int amount) {
    if (amount < 0) {
        throw std::invalid_argument("coin_change_ways: 金额不能为负");
    }
    std::vector<int> dp(static_cast<std::size_t>(amount) + 1, 0);
    dp[0] = 1;  // 凑出 0 元的方案恰有一种：一枚都不选
    for (const int coin : coins) {
        for (int a = coin; a <= amount; ++a) {
            const std::size_t ai = static_cast<std::size_t>(a);
            dp[ai] += dp[ai - static_cast<std::size_t>(coin)];
        }
    }
    return dp[static_cast<std::size_t>(amount)];
}

struct BstCost {
    double cost;  // 最优期望比较次数（含失配虚键）
    int root;     // 全树根的键下标（0-based）；平局取最左（最小）根
};

// 最优二叉搜索树（CLRS 口径）：p 为 n 个键的命中概率，q 为 n+1 个虚键的失配概率。
// e[i][j] = min_r { e[i][r-1] + e[r+1][j] } + w(i,j)，空子树代价即其虚键 q。
// w(i,j) = Σp[i..j] + Σq[i..j+1]，用前缀和 O(1) 取出。
inline BstCost optimal_bst(std::span<const double> p, std::span<const double> q) {
    const std::size_t n = p.size();
    if (n == 0 || q.size() != n + 1) {
        throw std::invalid_argument("optimal_bst: 要求 p 非空且 q 恰有 n+1 个元素");
    }
    // 前缀和：P[k] = Σ_{t<k} p[t]；Q[k] = Σ_{t<k} q[t]（q 有 n+1 个，前缀长 n+2）
    std::vector<double> pre_p(n + 1, 0.0);
    std::vector<double> pre_q(n + 2, 0.0);
    for (std::size_t t = 0; t < n; ++t) {
        pre_p[t + 1] = pre_p[t] + p[t];
    }
    for (std::size_t t = 0; t <= n; ++t) {
        pre_q[t + 1] = pre_q[t] + q[t];
    }
    const auto w = [&](std::size_t i, std::size_t j) {
        return (pre_p[j + 1] - pre_p[i]) + (pre_q[j + 2] - pre_q[i]);
    };
    std::vector<std::vector<double>> e(n, std::vector<double>(n, 0.0));
    std::vector<std::vector<int>> root(n, std::vector<int>(n, -1));
    for (std::size_t len = 1; len <= n; ++len) {
        for (std::size_t i = 0; i + len <= n; ++i) {
            const std::size_t j = i + len - 1;
            double best = std::numeric_limits<double>::max();
            int best_r = -1;
            for (std::size_t r = i; r <= j; ++r) {
                // 空左子树（r == i）代价为虚键 q[i]；空右子树（r == j）为 q[r+1]
                const double left = (r == i) ? q[i] : e[i][r - 1];
                const double right = (r == j) ? q[r + 1] : e[r + 1][j];
                const double cost = left + right;
                if (cost < best) {  // 严格小于：平局保留最左根，结果确定
                    best = cost;
                    best_r = static_cast<int>(r);
                }
            }
            e[i][j] = best + w(i, j);
            root[i][j] = best_r;
        }
    }
    return BstCost{e[0][n - 1], root[0][n - 1]};
}

}  // namespace ds
