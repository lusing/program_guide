#pragma once
#include <algorithm>
#include <cstddef>
#include <span>
#include <stdexcept>
#include <utility>
#include <vector>

namespace ds {

// ── 26 回溯法 ────────────────────────────────────────────────────────────────
// 回溯 = 解空间树上的深度优先枚举 + 约束/限界剪枝。
// 四个问题共享同一骨架：做选择 → 递归 → 撤销选择。
// 每处枚举次序都固定（按行/按顶点/按物品序号升序，候选值升序，
// 背包先"装"后"不装"），保证结果与输出逐字节确定。

struct KnapsackSol {
    int value = 0;           // 最优总价值
    std::vector<int> items;  // 选中的物品下标（升序；等值多解取字典序最小）
};

// ── n 皇后：解的个数 ────────────────────────────────────────────────────────
// 按行枚举（第 row 行放一个皇后），列 0..n-1 升序尝试。
// 三个占用数组把"同列/同对角线"判定降为 O(1)：
//   col[c]       —— 列 c 已占用；
//   diag1[r+c]   —— 沿 r+c 为常数的反对角线；
//   diag2[r-c+n] —— 沿 r-c 为常数的主对角线，+n 平移避免负下标。
inline int queens(int n) {
    if (n <= 0) return 0;
    std::vector<char> col(n, 0), diag1(2 * n, 0), diag2(2 * n, 0);
    int count = 0;
    auto dfs = [&](auto&& self, int row) -> void {
        if (row == n) { ++count; return; }  // n 行全部放下：找到一个解
        for (int c = 0; c < n; ++c) {       // 候选列升序 → 解的枚举次序固定
            if (col[c] || diag1[row + c] || diag2[row - c + n]) continue;  // 约束剪枝
            col[c] = diag1[row + c] = diag2[row - c + n] = 1;              // 做选择
            self(self, row + 1);
            col[c] = diag1[row + c] = diag2[row - c + n] = 0;              // 撤销选择
        }
    };
    dfs(dfs, 0);
    return count;
}

// ── 图着色：方案数 ──────────────────────────────────────────────────────────
// 顶点 0..n-1 按编号顺序逐一着色，颜色 0..colors-1 升序尝试；
// 约束：与任何已着色的相邻顶点颜色不同。
inline int colorings(int colors, std::span<const std::pair<int, int>> edges, int n) {
    if (colors < 0) throw std::invalid_argument("颜色数不能为负");
    std::vector<std::vector<char>> adj(n, std::vector<char>(n, 0));
    for (const auto& [u, v] : edges) {
        if (u < 0 || v < 0 || u >= n || v >= n)
            throw std::invalid_argument("边的端点越界");
        adj[u][v] = adj[v][u] = 1;
    }
    std::vector<int> color(n, -1);
    int count = 0;
    auto dfs = [&](auto&& self, int v) -> void {
        if (v == n) { ++count; return; }  // 全部顶点着色成功：一个方案
        for (int c = 0; c < colors; ++c) {
            bool ok = true;
            for (int u = 0; u < n; ++u) {
                if (adj[v][u] && color[u] == c) { ok = false; break; }
            }
            if (!ok) continue;  // 约束剪枝：与相邻已着色顶点同色
            color[v] = c;       // 做选择
            self(self, v + 1);
            color[v] = -1;      // 撤销选择
        }
    };
    dfs(dfs, 0);
    return count;
}

// ── 0/1 背包：回溯求最优 ────────────────────────────────────────────────────
// 物品按序号 0..n-1 逐一决定"装/不装"，先装后不装（枚举次序固定）。
// 可行性剪枝：装入超过容量 → 该分支不存在。
// 限界剪枝：剩余物品全装的总价值仍严格低于当前最优 → 整枝剪掉。
// 取 < 而非 <=：等值子树仍要探索，等值多解时才能取到字典序最小的物品表。
// 前提：values、weights 等长且元素均非负。
inline KnapsackSol knapsack_bt(std::span<const int> values,
                               std::span<const int> weights, int cap) {
    if (values.size() != weights.size())
        throw std::invalid_argument("价值与重量数组长度不一致");
    const int n = static_cast<int>(values.size());
    std::vector<int> suffix(n + 1, 0);  // suffix[i] = 第 i..n-1 件价值之和
    for (int i = n - 1; i >= 0; --i) suffix[i] = suffix[i + 1] + values[i];

    KnapsackSol best;
    std::vector<int> cur;  // 当前路径：已装入的物品下标（升序）
    auto dfs = [&](auto&& self, int i, int w, int v) -> void {
        if (i == n) {
            if (v > best.value) {
                best.value = v;
                best.items = cur;
            } else if (v == best.value && cur < best.items) {
                best.items = cur;  // 等值平局：按下标字典序取先者
            }
            return;
        }
        if (w + weights[i] <= cap) {  // 分支一：装入（可行性剪枝在前）
            cur.push_back(i);         // 做选择
            self(self, i + 1, w + weights[i], v + values[i]);
            cur.pop_back();           // 撤销选择
        }
        if (v + suffix[i] >= best.value) {  // 分支二：不装（严格劣才剪）
            self(self, i + 1, w, v);
        }
    };
    dfs(dfs, 0, 0, 0);
    return best;
}

// ── 子集和：列出全部解 ──────────────────────────────────────────────────────
// 下标 0..n-1 升序、"从 start 起取下一个"的 DFS 生成组合（不重复计数），
// 解按物品下标字典序输出。
// 元素均非负时可剪枝：部分和已超 target 或再加即超 → 整枝放弃；
// 含负元素时部分和可能回落，自动退化为完整枚举（无剪枝仍正确）。
inline std::vector<std::vector<int>> subset_sum_lists(std::span<const int> a, int target) {
    const bool has_negative =
        std::any_of(a.begin(), a.end(), [](int x) { return x < 0; });
    std::vector<std::vector<int>> results;
    std::vector<int> cur;  // 当前子集的下标序列（升序）
    auto dfs = [&](auto&& self, int start, int sum) -> void {
        if (sum == target) {
            results.push_back(cur);     // 每条恰等路径都是一个解
            if (!has_negative) return;  // 非负元素下再深入只会更大
        } else if (sum > target && !has_negative) {
            return;                     // 剪枝：非负元素下部分和不会回落
        }
        for (int j = start; j < static_cast<int>(a.size()); ++j) {
            if (!has_negative && sum + a[j] > target) continue;  // 剪枝：选 j 必超
            cur.push_back(j);  // 做选择
            self(self, j + 1, sum + a[j]);
            cur.pop_back();    // 撤销选择
        }
    };
    dfs(dfs, 0, 0);
    return results;
}

}  // namespace ds
