#ifndef DS_TOPO_HPP
#define DS_TOPO_HPP

#include <cstddef>
#include <optional>
#include <queue>
#include <vector>

#include "adj_list.hpp"

namespace ds {

// 拓扑排序（Kahn 算法）：反复取出入度为 0 的顶点，删其出边。
// 取顶点时用最小堆、每步选编号最小者，于是结果唯一确定。
// 图中存在有向环时无法取完全部顶点，返回 nullopt。
inline std::optional<std::vector<int>> topo_sort(const AdjList& g) {
    const int n = g.n();
    std::vector<int> indeg(static_cast<size_t>(n), 0);
    for (int v = 0; v < n; ++v) {
        for (const Edge& e : g.neighbors(v)) {
            ++indeg[static_cast<size_t>(e.to)];
        }
    }

    std::priority_queue<int, std::vector<int>, std::greater<int>> ready;
    for (int v = 0; v < n; ++v) {
        if (indeg[static_cast<size_t>(v)] == 0) {
            ready.push(v);
        }
    }

    std::vector<int> order;
    order.reserve(n);
    while (!ready.empty()) {
        const int v = ready.top();
        ready.pop();
        order.push_back(v);
        for (const Edge& e : g.neighbors(v)) {
            if (--indeg[static_cast<size_t>(e.to)] == 0) {
                ready.push(e.to);
            }
        }
    }

    if (static_cast<int>(order.size()) != n) {
        return std::nullopt;  // 剩余顶点互相成环
    }
    return order;
}

}  // namespace ds

#endif  // DS_TOPO_HPP
