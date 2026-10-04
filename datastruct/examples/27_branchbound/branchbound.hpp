#ifndef DS_BRANCHBOUND_HPP
#define DS_BRANCHBOUND_HPP

#include <algorithm>
#include <cassert>
#include <cstddef>
#include <cstdint>
#include <queue>
#include <span>
#include <stdexcept>
#include <utility>
#include <vector>

namespace ds {

// 分支限界法：与第 26 章回溯同族，都在解空间树上搜索；
// 区别在于——回溯用 DFS 只剪去非法/劣于已知的分支，
// 分支限界用 BFS 或"最优优先"（本文件用后者）+ 限界函数抢先砍枝：
// 每次总是展开"当前最有希望"的活节点，一旦限界表明某子树不可能
// 超过已知最优解，整棵子树被一次性丢弃。

// ═════════════════════════ 0/1 背包：最大收益分支限界 ═════════════════════════

struct BnBSol {
    int value;           // 最优装载总价值
    int nodes_expanded;  // 被展开（弹出并生成孩子）的节点数，用于与纯枚举对照
};

namespace bnb_detail {

// 背包活节点：解空间树第 level 层（前 level 个"预排后"物品已做 0/1 决策）。
struct KnapNode {
    double uprofit;  // 上界：该子树中任一叶子的收益都不超过它
    int profit;      // 已决策物品的实际收益
    int weight;      // 已决策物品的实际重量
    int level;       // 下一个待决策的物品下标（预排后序列中）
    int seq;         // 生成序号，平局兜底，保证扩展次序完全确定
};

// 优先队列次序（越大越先出队）：上界大者优先；上界相同层号大者优先
// （更深节点离叶更近、更快得到完整解）；仍相同按生成序号小者优先。
struct KnapGreater {
    bool operator()(const KnapNode& a, const KnapNode& b) const {
        if (a.uprofit != b.uprofit) return a.uprofit < b.uprofit;
        if (a.level != b.level) return a.level < b.level;
        return a.seq > b.seq;
    }
};

}  // namespace bnb_detail

// 0/1 背包的最大收益分支限界。
// 前提：weights 全部 >= 1（否则抛 std::invalid_argument），values >= 0。
// 预处理：按单位价值（value/weight）降序预排下标，平局按原下标升序——
// 这让"贪心填充"的上界尽可能紧。内部重排不影响返回的 value。
// 上界函数：当前收益 + 剩余容量按单位价值序贪心填充（最后一件允许装入
// 分数部分）。它对"子树最优收益"是乐观估计（只高不低），因此
// "上界 <= 当前最优" 时剪掉该子树是安全的——这正是剪枝合法性的根基。
BnBSol knapsack_bnb(std::span<const int> values,
                    std::span<const int> weights, int cap) {
    const std::ptrdiff_t n = std::ssize(values);
    if (n != std::ssize(weights)) {
        throw std::invalid_argument("values 与 weights 长度不一致");
    }
    if (cap < 0) {
        throw std::invalid_argument("容量不能为负");
    }
    for (const int w : weights) {
        if (w < 1) {
            throw std::invalid_argument("物品重量必须 >= 1");
        }
    }

    // 单位价值降序预排：交叉相乘比较 v_i/w_i 与 v_j/w_j，避免浮点误差与平局歧义。
    std::vector<int> order(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) {
        order[static_cast<std::size_t>(i)] = i;
    }
    std::ranges::sort(order, [&](int a, int b) {
        const long long lhs = static_cast<long long>(values[static_cast<std::size_t>(a)])
                            * weights[static_cast<std::size_t>(b)];
        const long long rhs = static_cast<long long>(values[static_cast<std::size_t>(b)])
                            * weights[static_cast<std::size_t>(a)];
        if (lhs != rhs) return lhs > rhs;
        return a < b;  // 平局按原下标升序，保证确定性
    });

    // 上界：从第 lvl 件（预排序）开始，用剩余容量贪心装满（最后一件可装分数）。
    // 不变量：返回值 >= 以"已装 profit/weight、还剩 lvl..n-1 可决策"为根的子树
    // 中任何叶子的收益。
    const auto bound = [&](int lvl, int profit, int weight) {
        double up = static_cast<double>(profit);
        int room = cap - weight;
        for (int i = lvl; i < n; ++i) {
            const int w = weights[static_cast<std::size_t>(order[static_cast<std::size_t>(i)])];
            const int v = values[static_cast<std::size_t>(order[static_cast<std::size_t>(i)])];
            if (w <= room) {
                up += static_cast<double>(v);
                room -= w;
            } else {
                up += static_cast<double>(v) * static_cast<double>(room)
                    / static_cast<double>(w);
                break;  // 背包已满，后面单位价值更低，不必再看
            }
        }
        return up;
    };

    std::priority_queue<bnb_detail::KnapNode,
                        std::vector<bnb_detail::KnapNode>,
                        bnb_detail::KnapGreater> pq;
    int best = 0;
    int seq = 0;
    int expanded = 0;
    pq.push({bound(0, 0, 0), 0, 0, 0, seq++});

    // 主循环：总弹出上界最大的活节点。最优值有两个来源：可行左孩子
    // 立即刷新 best；叶节点（level == n）出队时其收益不小于队列中
    // 任何节点的上界，直接定为最优。队列空时 best 即全局最优。
    while (!pq.empty()) {
        const bnb_detail::KnapNode node = pq.top();
        pq.pop();
        if (node.level == n) {  // 第一个出队的叶子即最优
            best = node.profit;
            break;
        }
        ++expanded;  // 只统计非叶节点的展开

        // 左孩子：装入第 node.level 件（预排序）
        const int idx = order[static_cast<std::size_t>(node.level)];
        const int w = weights[static_cast<std::size_t>(idx)];
        const int v = values[static_cast<std::size_t>(idx)];
        if (node.weight + w <= cap) {
            const int np = node.profit + v;
            const int nw = node.weight + w;
            if (np > best) best = np;  // 可行左孩子立刻刷新最优
            pq.push({bound(node.level + 1, np, nw), np, nw, node.level + 1, seq++});
        }
        // 右孩子：不装第 node.level 件。仅当其上界仍优于已知最优才保留，
        // 否则整棵右子树被一次性剪掉——这是与纯枚举拉开差距的关键。
        const double up = bound(node.level + 1, node.profit, node.weight);
        if (up > static_cast<double>(best)) {
            pq.push({up, node.profit, node.weight, node.level + 1, seq++});
        }
    }
    return {best, expanded};
}

// ═════════════════════════ 旅行商：最小耗费分支限界 ═════════════════════════

namespace bnb_detail {

// TSP 活节点：从城市 0 出发的一条部分路径。起点固定为 0 以消除回路旋转对称。
struct TspNode {
    int bound;              // 下界：已走代价 + 未离开城市的行最小出边之和
    int cost;               // 已走代价
    std::vector<int> path;  // 0 出发的路径，末位即当前所在城市
    int seq;
};

// 优先队列次序（越小越先出队）：下界小者优先（最小耗费分支限界）；
// 下界相同按路径字典序小者优先——扩展次序完全确定。
struct TspCloser {
    bool operator()(const TspNode& a, const TspNode& b) const {
        if (a.bound != b.bound) return a.bound > b.bound;
        return a.path > b.path;
    }
};

}  // namespace bnb_detail

// 旅行商的最小耗费分支限界。
// 输入 flat_matrix 为行优先 n×n 邻接矩阵（对角线值不使用）。
// 前提：n >= 2（否则抛 std::invalid_argument）。
// 下界函数（行最小出边）：每座城市在完整回路中恰好离开一次，离开所走的边
// 不小于该城市行内最小边权，故任何以当前部分路径为前缀的完整回路的代价
// >= 已走代价 + Σ(需要离开的城市的行最小出边)。需要离开的城市 =
// 当前城市 + 全部未访问城市（回程边计入城市 0 的入边，不参与求和，
// 因而下界略松但永远成立）。
int tsp_bnb(std::span<const int> flat_matrix, int n) {
    if (n < 2) {
        throw std::invalid_argument("TSP 至少需要 2 座城市");
    }
    const auto at = [&](int i, int j) {
        return flat_matrix[static_cast<std::size_t>(i) * static_cast<std::size_t>(n)
                         + static_cast<std::size_t>(j)];
    };
    // row_min[i]：城市 i 的行最小出边（j != i）
    std::vector<int> row_min(static_cast<std::size_t>(n), INT32_MAX);
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            if (j != i) {
                row_min[static_cast<std::size_t>(i)]
                    = std::min(row_min[static_cast<std::size_t>(i)], at(i, j));
            }
        }
    }

    std::priority_queue<bnb_detail::TspNode,
                        std::vector<bnb_detail::TspNode>,
                        bnb_detail::TspCloser> pq;
    int best = INT32_MAX;
    int seq = 0;
    // 根下界：起点必须离开 + 全部城市各离开一次的行最小出边之和
    int root_bound = 0;
    for (const int r : row_min) root_bound += r;
    pq.push({root_bound, 0, {0}, seq++});

    // 最小耗费分支限界：下界最小的活节点先出队；第一个完整回路出队即最优，
    // 因为队列中其余节点的下界都不小于该回路的真实代价。
    while (!pq.empty()) {
        const bnb_detail::TspNode node = pq.top();
        pq.pop();
        const int cur = node.path.back();
        if (node.bound >= best) {  // 限界剪枝：整棵子树不可能更优
            continue;
        }
        if (static_cast<int>(node.path.size()) == n) {  // 只差回程边
            const int total = node.cost + at(cur, 0);
            if (total < best) best = total;
            continue;  // 完整回路不展开；继续收队确认没有更优者
        }

        // 下一城市按编号升序生成（平局次序由此确定）
        for (int next = 0; next < n; ++next) {
            if (next == cur) continue;
            const bool visited = std::ranges::find(node.path, next) != node.path.end();
            if (visited) continue;
            const int ncost = node.cost + at(cur, next);
            // 新下界 = 新已走代价 + Σ(仍需离开城市的行最小出边)。
            // 孩子节点中仍需离开的城市：next（成为新的当前城市）
            // 以及全部未访问城市；原当前城市的离开边已实际确定，
            // 其行最小项被真实边权（已计入 ncost）替换。
            int rest = row_min[static_cast<std::size_t>(next)];
            for (int i = 0; i < n; ++i) {
                if (i == next) continue;
                const bool visited = std::ranges::find(node.path, i) != node.path.end();
                if (!visited) {
                    rest += row_min[static_cast<std::size_t>(i)];
                }
            }
            pq.push({ncost + rest, ncost,
                     [&] { auto p = node.path; p.push_back(next); return p; }(), seq++});
        }
    }
    assert(best != INT32_MAX);
    return best;
}

}  // namespace ds

#endif  // DS_BRANCHBOUND_HPP
