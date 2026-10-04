#include <cassert>
#include <print>
#include <vector>

#include "greedy.hpp"

// 23 贪婪算法：装载问题、部分背包、任务调度

int main() {
    // ═══ 装载问题：cap=50，箱重 [10,20,30]，升序装入最多 2 箱 ═══
    {
        const std::vector<int> weights{10, 20, 30};
        const int boxes = ds::container_loading(weights, 50);
        assert(boxes == 2);
        std::println("装载问题（cap=50）：箱重 [10,20,30] 最多装 {} 箱（10+20=30，再装 30 超载）",
                     boxes);
    }

    // ═══ 装载问题边界：空输入、容量刚好、容量为 0 ═══
    {
        const std::vector<int> none{};
        assert(ds::container_loading(none, 100) == 0);
        const std::vector<int> tight{50, 40};
        assert(ds::container_loading(tight, 90) == 2);
        const std::vector<int> any{1, 2};
        assert(ds::container_loading(any, 0) == 0);
        std::println("装载问题边界：空输入得 0；cap=90 装 [50,40] 恰好 2 箱；cap=0 一箱不装");
    }

    // ═══ 部分背包：经典三物品例，最优 240.0 ═══
    {
        const std::vector<double> values{60.0, 100.0, 120.0};
        const std::vector<double> weights{10.0, 20.0, 30.0};
        const double best = ds::fractional_knapsack(values, weights, 50.0);
        assert(best == 240.0);  // 60+100 全装，剩余容量 20 装 1/3 × 120=80，浮点精确
        std::println("部分背包（cap=50）：最优价值 {:.1f}（单位价值 6>5>4 依次装）", best);
    }

    // ═══ 部分背包边界：空输入、容量 0 ═══
    {
        const std::vector<double> none{};
        assert(ds::fractional_knapsack(none, none, 10.0) == 0.0);
        const std::vector<double> v{5.0};
        const std::vector<double> w{2.0};
        assert(ds::fractional_knapsack(v, w, 0.0) == 0.0);
        std::println("部分背包边界：空输入与 cap=0 均得 0.0");
    }

    // ═══ 任务调度：经典五任务例，最大利润 142 ═══
    {
        const std::vector<ds::Job> jobs{{2, 100}, {1, 19}, {2, 27}, {1, 25}, {3, 15}};
        const int profit = ds::job_sequencing(jobs);
        assert(profit == 142);
        std::println("任务调度：最大利润 {}（day1=27、day2=100、day3=15；利润 25/19 被挤出）",
                     profit);
    }

    // ═══ 任务调度边界：空输入、全部截止日为 1 ═══
    {
        const std::vector<ds::Job> none{};
        assert(ds::job_sequencing(none) == 0);
        const std::vector<ds::Job> clash{{1, 30}, {1, 50}, {1, 40}};
        assert(ds::job_sequencing(clash) == 50);  // 只有一个时间槽，留给利润最高的
        std::println("任务调度边界：空输入得 0；三个任务挤 day1 只能完成利润最高的 50");
    }

    std::println("自检通过");
}
