#ifndef DS_SIMULATION_HPP
#define DS_SIMULATION_HPP

#include <climits>
#include <cstddef>
#include <queue>
#include <span>
#include <utility>
#include <vector>

namespace ds {

struct SimResult {
    double avg_wait;
    int max_wait;
    int served;
};

// 单窗口银行排队模拟（整数离散事件）。
//
// 时间轴约定：同一时刻先处理服务结束、再让等待队首开始、最后处理新到达，
// 于是恰好在窗口空闲瞬间到达的顾客不必等待，服务次序保持 FIFO。
//
// 等待时间口径（排队论标准定义）：每位顾客的等待 = 开始服务时刻 − 到达时刻，
// 以时间单位计整数。立即开始者等待 0。最后对全部顾客取平均、取最长。
inline SimResult bank_simulation(std::span<const int> arrivals,
                                 std::span<const int> services) {
    // 等待队记录 (到达时刻, 顾客编号)；开始服务时才能用当前时刻减到达时刻
    std::queue<std::pair<int, int>> waiting;
    int serving = -1;                 // 正被服务的顾客编号，-1 表示窗口空闲
    int busy_until = 0;               // 当前服务结束时刻
    size_t next_arr = 0;              // 下一个待处理到达事件的下标
    int served = 0;
    int total_wait = 0;
    int max_wait = 0;

    const int customers = static_cast<int>(arrivals.size());

    // 让某位顾客在时刻 t 开始服务：登记她的等待时间
    auto start_service = [&](int idx, int arrival, int t) {
        serving = idx;
        busy_until = t + services[idx];
        const int wait = t - arrival;
        total_wait += wait;
        if (wait > max_wait) {
            max_wait = wait;
        }
    };

    while (served < customers) {
        const int t_arr = (next_arr < arrivals.size()) ? arrivals[next_arr] : INT_MAX;
        const int t_dep = (serving >= 0) ? busy_until : INT_MAX;
        const int t = (t_dep <= t_arr) ? t_dep : t_arr;

        if (serving >= 0 && t == busy_until) {
            ++served;
            serving = -1;
        }
        if (serving < 0 && !waiting.empty()) {
            const auto [arrival, idx] = waiting.front();
            waiting.pop();
            start_service(idx, arrival, t);
        }
        while (next_arr < arrivals.size() && arrivals[next_arr] == t) {
            const int idx = static_cast<int>(next_arr++);
            if (serving < 0) {
                start_service(idx, t, t);    // 到达即开始：等待 0
            } else {
                waiting.emplace(t, idx);
            }
        }
    }

    return {
        static_cast<double>(total_wait) / customers,
        max_wait,
        served,
    };
}

// 约瑟夫环：n 个人 1..n 围成圈，从 1 开始报数，数到第 k 个淘汰，
// 返回最后剩下的人的编号。用数组直接模拟淘汰过程。
inline int josephus(int n, int k) {
    std::vector<int> people(static_cast<size_t>(n));
    for (int i = 0; i < n; ++i) {
        people[static_cast<size_t>(i)] = i + 1;
    }
    size_t pos = 0;
    while (people.size() > 1) {
        pos = (pos + static_cast<size_t>(k) - 1) % people.size();
        people.erase(people.begin() + static_cast<std::ptrdiff_t>(pos));
    }
    return people.front();
}

}  // namespace ds

#endif  // DS_SIMULATION_HPP
