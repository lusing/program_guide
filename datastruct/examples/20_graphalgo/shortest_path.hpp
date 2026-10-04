#ifndef DS_SHORTEST_PATH_HPP
#define DS_SHORTEST_PATH_HPP

#include <cstddef>
#include <functional>
#include <queue>
#include <stdexcept>
#include <utility>
#include <vector>

#include "graph_rep.hpp"

namespace ds {

// Dijkstra 单源最短路（邻接表 + 最小堆）。
//
// 合同：所有边权必须非负；出现负边即抛 invalid_argument（负权下
// "已出堆即定距"不再成立，正确工具是 Bellman-Ford）。返回每个顶点
// 相对 s 的最短距离；不可达为 kNoEdge。
inline std::vector<double> dijkstra(const AdjList& g, int s) {
    const int n = g.n();
    if (s < 0 || s >= n) {
        throw std::out_of_range("dijkstra: source out of range");
    }

    std::vector<double> dist(static_cast<size_t>(n), kNoEdge);
    dist[static_cast<size_t>(s)] = 0.0;

    // 堆元素 (当前距离, 顶点)，最小堆。邻点按编号升序插入，
    // 同距离候选出堆顺序也确定。
    using Candidate = std::pair<double, int>;
    std::priority_queue<Candidate, std::vector<Candidate>, std::greater<Candidate>> pq;
    pq.emplace(0.0, s);

    while (!pq.empty()) {
        const auto [d, u] = pq.top();
        pq.pop();
        if (d != dist[static_cast<size_t>(u)]) {
            continue;  // 过期候选：该顶点已用更小距离出堆
        }
        for (const Edge& e : g.out_edges(u)) {
            if (e.w < 0.0) {
                throw std::invalid_argument("dijkstra: negative-weight edge");
            }
            const double nd = d + e.w;
            if (nd < dist[static_cast<size_t>(e.to)]) {
                dist[static_cast<size_t>(e.to)] = nd;
                pq.emplace(nd, e.to);
            }
        }
    }
    return dist;
}

// Floyd 全源最短路的结果：n*n 行主矩阵，不可达为 kNoEdge。
struct DistMatrix {
    int n = 0;
    std::vector<double> d;

    [[nodiscard]] double at(int i, int j) const {
        return d[static_cast<size_t>(i) * static_cast<size_t>(n) + j];
    }
};

// Floyd-Warshall：逐个允许"途经顶点 k"，用三角松弛 d[i][j] ≤ d[i][k]+d[k][j]。
inline DistMatrix floyd(const AdjMatrix& g) {
    const int n = g.n();
    DistMatrix result;
    result.n = n;
    result.d.resize(static_cast<size_t>(n) * static_cast<size_t>(n));

    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            result.d[static_cast<size_t>(i) * static_cast<size_t>(n) + j] = g.weight(i, j);
        }
    }

    for (int k = 0; k < n; ++k) {
        for (int i = 0; i < n; ++i) {
            const double dik = result.at(i, k);
            if (dik >= kNoEdge / 2.0) {
                continue;  // i 到 k 本就不通，松弛无意义，也防 kNoEdge+kNoEdge 溢出式失真
            }
            for (int j = 0; j < n; ++j) {
                const double dkj = result.at(k, j);
                if (dkj >= kNoEdge / 2.0) {
                    continue;
                }
                const double nd = dik + dkj;
                double& dij = result.d[static_cast<size_t>(i) * static_cast<size_t>(n) + j];
                if (nd < dij) {
                    dij = nd;
                }
            }
        }
    }
    return result;
}

}  // namespace ds

#endif  // DS_SHORTEST_PATH_HPP
