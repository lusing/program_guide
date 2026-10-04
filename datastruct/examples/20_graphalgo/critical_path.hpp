#ifndef DS_CRITICAL_PATH_HPP
#define DS_CRITICAL_PATH_HPP

#include <algorithm>
#include <cstddef>
#include <optional>
#include <queue>
#include <utility>
#include <vector>

#include "graph_rep.hpp"

namespace ds {

struct CritResult {
    int length = 0;                              // 总工期（最早完工期）
    std::vector<std::pair<int, int>> activities; // 时差为 0 的活动（边）
};

// AOE 网络关键路径。
//
// 合同：g 必须是有向无环图；检测到环返回 nullopt。流程：
//   ① Kahn 求拓扑序（初始可入队顶点按编号升序扫描，出边表也有序，结果确定）；
//   ② 前向求最早时刻 ve：ve[v] = max(ve[u] + 活动时长)；
//   ③ 以最大 ve 为总工期，反向求最迟时刻 vl：vl[u] = min(vl[v] - 时长)；
//   ④ 活动 (u,v) 时差 = vl[v] - ve[u] - w；恰为 0 即关键活动。
inline std::optional<CritResult> critical_path(const AdjList& g) {
    if (!g.directed()) {
        throw std::invalid_argument("critical_path: AOE graph must be directed");
    }
    const int n = g.n();

    std::vector<int> indegree(static_cast<size_t>(n), 0);
    for (int u = 0; u < n; ++u) {
        for (const Edge& e : g.out_edges(u)) {
            ++indegree[static_cast<size_t>(e.to)];
        }
    }

    std::queue<int> ready;
    for (int v = 0; v < n; ++v) {
        if (indegree[static_cast<size_t>(v)] == 0) {
            ready.push(v);
        }
    }

    std::vector<int> topo;
    topo.reserve(static_cast<size_t>(n));
    while (!ready.empty()) {
        const int u = ready.front();
        ready.pop();
        topo.push_back(u);
        for (const Edge& e : g.out_edges(u)) {
            if (--indegree[static_cast<size_t>(e.to)] == 0) {
                ready.push(e.to);  // 出边表按 to 升序，入队保持升序
            }
        }
    }
    if (static_cast<int>(topo.size()) != n) {
        return std::nullopt;  // 有环
    }

    std::vector<int> ve(static_cast<size_t>(n), 0);
    for (int u : topo) {
        for (const Edge& e : g.out_edges(u)) {
            const int t = ve[static_cast<size_t>(u)] + static_cast<int>(e.w);
            ve[static_cast<size_t>(e.to)] =
                std::max(ve[static_cast<size_t>(e.to)], t);
        }
    }

    const int length = *std::ranges::max_element(ve);

    std::vector<int> vl(static_cast<size_t>(n), length);
    for (auto it = topo.rbegin(); it != topo.rend(); ++it) {
        const int u = *it;
        for (const Edge& e : g.out_edges(u)) {
            const int t = vl[static_cast<size_t>(e.to)] - static_cast<int>(e.w);
            vl[static_cast<size_t>(u)] = std::min(vl[static_cast<size_t>(u)], t);
        }
    }

    CritResult result;
    result.length = length;
    for (int u = 0; u < n; ++u) {
        for (const Edge& e : g.out_edges(u)) {
            const int slack = vl[static_cast<size_t>(e.to)]
                            - ve[static_cast<size_t>(u)]
                            - static_cast<int>(e.w);
            if (slack == 0) {
                result.activities.emplace_back(u, e.to);
            }
        }
    }
    std::ranges::sort(result.activities);
    return result;
}

}  // namespace ds

#endif  // DS_CRITICAL_PATH_HPP
