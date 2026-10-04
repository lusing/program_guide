#include <cassert>
#include <cstddef>
#include <print>
#include <utility>
#include <vector>

#include "backtrack.hpp"

// 26 回溯：n 皇后、图着色、0/1 背包、子集和
// 全部枚举次序固定（行/顶点/物品序号升序、候选值升序），输出确定。

int main() {
    // ═══ n 皇后：解的个数（经典计数 4→2、8→92）═══
    {
        const int q4 = ds::queens(4);
        const int q8 = ds::queens(8);
        assert(q4 == 2);
        assert(q8 == 92);
        std::println("n 皇后：queens(4) = {}、queens(8) = {}", q4, q8);
    }

    // ═══ 图着色：三角形 3 色恰 3! = 6 种；无边图退化为 k^n（坑位演示）═══
    {
        const std::vector<std::pair<int, int>> triangle{{0, 1}, {1, 2}, {0, 2}};
        const int cnt = ds::colorings(3, triangle, 3);
        assert(cnt == 6);
        std::println("图着色：三角形 3 色方案数 = {}（= 3!）", cnt);

        const std::vector<std::pair<int, int>> no_edges;
        const int free_cnt = ds::colorings(3, no_edges, 2);
        assert(free_cnt == 9);
        std::println("图着色：无边 2 顶点 3 色方案数 = {}（= 3 的平方）", free_cnt);
    }

    // ═══ 0/1 背包：与第 25 章动态规划同数据互证 ═══
    {
        const std::vector<int> values{3, 4, 5, 6};
        const std::vector<int> weights{2, 3, 4, 5};
        const ds::KnapsackSol sol = ds::knapsack_bt(values, weights, 5);
        assert(sol.value == 7);
        assert((sol.items == std::vector<int>{0, 1}));
        std::print("0/1 背包回溯：最优价值 {}，物品下标", sol.value);
        for (int i : sol.items) std::print(" {}", i);
        std::println("（与 25 章 DP 一致）");
    }

    // ═══ 子集和：列出全部解（下标字典序）═══
    {
        const std::vector<int> nums{1, 2, 3, 4, 5};
        const auto lists = ds::subset_sum_lists(nums, 5);
        assert(lists.size() == 3);
        assert((lists[0] == std::vector<int>{0, 3}));  // 值 {1,4}
        assert((lists[1] == std::vector<int>{1, 2}));  // 值 {2,3}
        assert((lists[2] == std::vector<int>{4}));     // 值 {5}
        std::print("子集和（{{1,2,3,4,5}}，目标 5）：{} 组解", lists.size());
        for (const auto& idxs : lists) {
            std::print(" [");
            for (std::size_t k = 0; k < idxs.size(); ++k) {
                if (k > 0) std::print(",");
                std::print("{}", nums[static_cast<std::size_t>(idxs[k])]);
            }
            std::print("]");
        }
        std::println("");
    }

    std::println("自检通过");
}
