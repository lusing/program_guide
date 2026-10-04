#include <cassert>
#include <cstdint>
#include <print>
#include <span>
#include <stdexcept>
#include <vector>

#include "branchbound.hpp"

// 27 分支限界：0/1 背包的最大收益分支限界与旅行商的最小耗费分支限界。
// 背包数据与第 25 章（动态规划）、第 26 章（回溯）完全相同，最优值 7 三法互证。

namespace {

// 纯枚举对照：遍历全部 2^n 个子集，返回最优值并把"展开节点数"记入计数器
// （每个非叶子集对应解空间树的一次展开：n=4 时内部决策节点共 2^4-1+... 本例
// 采用与 27.6 节一致的口径——枚举器对每个被访问的"决策节点"计数）。
int knapsack_naive(std::span<const int> values,
                   std::span<const int> weights, int cap, int& nodes) {
    const std::size_t n = values.size();
    int best = 0;
    nodes = 0;
    // 解空间树的内部节点 = 全部长度为 0..n 的前缀决策序列，用位掩码逐层枚举。
    // 这里直接枚举 2^n 个完整子集，计数器按"每生成一个子集记 1 次"累计，
    // 与分支限界的 nodes_expanded（展开的活节点数）同量级对照。
    for (std::uint64_t mask = 0; mask < (std::uint64_t{1} << n); ++mask) {
        ++nodes;
        int value = 0;
        int weight = 0;
        for (std::size_t i = 0; i < n; ++i) {
            if ((mask >> i) & 1U) {
                value += values[i];
                weight += weights[i];
            }
        }
        if (weight <= cap && value > best) best = value;
    }
    return best;
}

}  // namespace

int main() {
    // ═══ 0/1 背包：与 DP（25 章）、回溯（26 章）同数据，最优值三法互证 ═══
    {
        const std::vector<int> values{3, 4, 5, 6};
        const std::vector<int> weights{2, 3, 4, 5};
        constexpr int cap = 5;
        const ds::BnBSol r = ds::knapsack_bnb(values, weights, cap);
        assert(r.value == 7);

        int naive_nodes = 0;
        const int naive_best = knapsack_naive(values, weights, cap, naive_nodes);
        assert(naive_best == 7);
        assert(naive_nodes == 16);              // 2^4 个子集逐一枚举
        assert(r.nodes_expanded < naive_nodes); // 限界剪枝严格更少
        std::println("0/1 背包（cap=5）：分支限界最优值 {}，展开节点 {}；"
                     "纯枚举访问子集 {} 个——严格更少",
                     r.value, r.nodes_expanded, naive_nodes);
    }

    // ═══ TSP 四城市经典例：最优回路 0→1→3→2→0 = 10+25+30+15 = 80 ═══
    {
        const std::vector<int> matrix{
            0, 10, 15, 20,
            10, 0, 35, 25,
            15, 35, 0, 30,
            20, 25, 30, 0,
        };
        const int best = ds::tsp_bnb(matrix, 4);
        // 手工核对最优回路代价：0→1(10) + 1→3(25) + 3→2(30) + 2→0(15) = 80
        const int hand = matrix[0 * 4 + 1] + matrix[1 * 4 + 3]
                       + matrix[3 * 4 + 2] + matrix[2 * 4 + 0];
        assert(hand == 80);
        assert(best == 80);
        std::println("TSP 4 城市：最小回路长 {}（最优回路 0→1→3→2→0）", best);
    }

    // ═══ 合同检查：前提违规抛标准异常 ═══
    {
        bool threw_weight = false;
        try {
            const std::vector<int> v{1};
            const std::vector<int> w{0};  // 重量必须 >= 1
            (void)ds::knapsack_bnb(v, w, 5);
        } catch (const std::invalid_argument&) {
            threw_weight = true;
        }
        bool threw_city = false;
        try {
            const std::vector<int> m{0, 1, 1, 0};
            (void)ds::tsp_bnb(m, 1);  // 至少 2 座城市
        } catch (const std::invalid_argument&) {
            threw_city = true;
        }
        assert(threw_weight);
        assert(threw_city);
        std::println("前提违规：重量 0 与城市数 1 均抛 std::invalid_argument");
    }

    std::println("自检通过");
}
