#pragma once
#include <algorithm>
#include <span>
#include <vector>

namespace ds {

// ── 装载问题（货箱装船，Sahni 例 13-2）─────────────────────────────────
// n 个等体积货箱，重量各不相同；船容量 cap。目标：装最多的箱数。
// 贪婪准则：每次选"最轻的还没装的箱"。前提：weights 全为正数、cap ≥ 0。
// 事后：返回装入箱数的最大值（按箱数最优，不保证用满容量）。
inline int container_loading(std::span<const int> weights, int cap) {
    std::vector<int> sorted(weights.begin(), weights.end());
    std::sort(sorted.begin(), sorted.end());
    int count = 0;
    int used  = 0;
    for (const int w : sorted) {
        if (used + w > cap) {
            break;  // 更重的只会更装不下，后面全部淘汰
        }
        used += w;
        ++count;
    }
    return count;
}

// ── 部分背包（分数背包，可拆分物品）───────────────────────────────────
// 物品 i 重 weights[i]、价值 values[i]，可以只装一部分。容量 cap。
// 贪婪准则：单位价值 values[i]/weights[i] 最高的先装，装不下就装一部分。
// 前提：weights 全为正数、cap ≥ 0、两 span 等长。
// 事后：返回可达的最大总价值（精确可分时贪婪是最优的）。
inline double fractional_knapsack(std::span<const double> values,
                                  std::span<const double> weights, const double cap) {
    const std::size_t n = values.size();
    std::vector<std::size_t> idx(n);
    for (std::size_t i = 0; i < n; ++i) {
        idx[i] = i;
    }
    std::sort(idx.begin(), idx.end(), [&](const std::size_t a, const std::size_t b) {
        return values[a] / weights[a] > values[b] / weights[b];
    });
    double total  = 0.0;
    double remain = cap;
    for (const std::size_t i : idx) {
        if (weights[i] <= remain) {
            total += values[i];
            remain -= weights[i];
        } else {
            total += values[i] * (remain / weights[i]);
            break;  // 背包已满
        }
    }
    return total;
}

// ── 任务调度（单机带截止时间的利润最大化）─────────────────────────────
// 每项任务耗 1 个单位时间，deadline 前完成可得 profit；时间槽 1..max(deadline)。
// 贪婪准则：利润高的先排，且尽量排在其截止日（给低利润任务留早的空位）。
// 前提：每个 Job 的 deadline ≥ 1。
struct Job {
    int deadline;
    int profit;
};

inline int job_sequencing(std::span<const Job> jobs) {
    std::vector<Job> sorted(jobs.begin(), jobs.end());
    std::sort(sorted.begin(), sorted.end(), [](const Job& a, const Job& b) {
        if (a.profit != b.profit) {
            return a.profit > b.profit;
        }
        return a.deadline < b.deadline;  // 平局：截止日早者先，保证确定性
    });
    int max_deadline = 0;
    for (const Job& j : sorted) {
        max_deadline = std::max(max_deadline, j.deadline);
    }
    std::vector<bool> used(static_cast<std::size_t>(max_deadline) + 1, false);
    int total = 0;
    for (const Job& j : sorted) {
        for (int slot = j.deadline; slot >= 1; --slot) {
            if (!used[static_cast<std::size_t>(slot)]) {
                used[static_cast<std::size_t>(slot)] = true;
                total += j.profit;
                break;
            }
        }
    }
    return total;
}

}  // namespace ds
