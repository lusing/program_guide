#ifndef DS_MST_HPP
#define DS_MST_HPP

#include <algorithm>
#include <cstddef>
#include <numeric>
#include <stdexcept>
#include <utility>
#include <vector>

#include "graph_rep.hpp"

namespace ds {

struct MstResult {
    double total = 0.0;
    std::vector<std::pair<int, int>> edges;  // 每条边小编号端点在前
};

namespace detail {

// Kruskal 用的最小并查集（算法局部实现，不跨文件依赖）。
struct Dsu {
    std::vector<int> parent;
    std::vector<int> rankv;

    explicit Dsu(int n)
        : parent(static_cast<size_t>(n)), rankv(static_cast<size_t>(n), 0) {
        std::iota(parent.begin(), parent.end(), 0);
    }

    int find(int x) {
        if (parent[static_cast<size_t>(x)] != x) {
            parent[static_cast<size_t>(x)] = find(parent[static_cast<size_t>(x)]);
        }
        return parent[static_cast<size_t>(x)];
    }

    bool unite(int a, int b) {
        a = find(a);
        b = find(b);
        if (a == b) {
            return false;
        }
        if (rankv[static_cast<size_t>(a)] < rankv[static_cast<size_t>(b)]) {
            std::swap(a, b);
        }
        parent[static_cast<size_t>(b)] = a;
        if (rankv[static_cast<size_t>(a)] == rankv[static_cast<size_t>(b)]) {
            ++rankv[static_cast<size_t>(a)];
        }
        return true;
    }
};

}  // namespace detail

// Prim：从 s 生长一棵树，每步把"连接树内与树外的最轻边"收入。
// 实现用 key 数组：key[v] 是 v 到当前树的最轻跨边，顶点入树后松弛其邻点。
// 平局取编号最小的顶点，输出确定。
inline MstResult prim(const AdjMatrix& g, int s) {
    if (g.directed()) {
        throw std::invalid_argument("MST requires an undirected graph");
    }
    const int n = g.n();
    if (s < 0 || s >= n) {
        throw std::out_of_range("prim: source out of range");
    }

    std::vector<double> key(static_cast<size_t>(n), kNoEdge);
    std::vector<int> parent(static_cast<size_t>(n), -1);
    std::vector<char> in_tree(static_cast<size_t>(n), false);
    key[static_cast<size_t>(s)] = 0.0;

    MstResult result;

    for (int step = 0; step < n; ++step) {
        int u = -1;
        double best = kNoEdge;
        for (int v = 0; v < n; ++v) {
            if (!in_tree[static_cast<size_t>(v)] && key[static_cast<size_t>(v)] < best) {
                best = key[static_cast<size_t>(v)];
                u = v;
            }
        }
        if (u < 0) {
            throw std::invalid_argument("prim: graph is not connected");
        }

        in_tree[static_cast<size_t>(u)] = true;
        if (u != s) {
            const int p = parent[static_cast<size_t>(u)];
            const int a = std::min(p, u);
            const int b = std::max(p, u);
            result.edges.emplace_back(a, b);
            result.total += best;
        }
        for (int v = 0; v < n; ++v) {
            if (in_tree[static_cast<size_t>(v)]) {
                continue;
            }
            const double w = g.weight(u, v);
            if (w < key[static_cast<size_t>(v)]) {
                key[static_cast<size_t>(v)] = w;
                parent[static_cast<size_t>(v)] = u;
            }
        }
    }

    std::ranges::sort(result.edges);
    return result;
}

// Kruskal：全部边按权排序，依次收入"两端尚不在同一集合"的边。
// 边序键为 (权, 小端点, 大端点)，平局完全确定。
inline MstResult kruskal(const AdjMatrix& g) {
    if (g.directed()) {
        throw std::invalid_argument("MST requires an undirected graph");
    }
    const int n = g.n();

    struct Cand {
        double w;
        int u;
        int v;
    };
    std::vector<Cand> candidates;
    for (int u = 0; u < n; ++u) {
        for (int v = u + 1; v < n; ++v) {
            const double w = g.weight(u, v);
            if (w < kNoEdge) {
                candidates.push_back({w, u, v});
            }
        }
    }
    std::ranges::sort(candidates, [](const Cand& a, const Cand& b) {
        if (a.w != b.w) {
            return a.w < b.w;
        }
        if (a.u != b.u) {
            return a.u < b.u;
        }
        return a.v < b.v;
    });

    detail::Dsu dsu(n);
    MstResult result;
    for (const Cand& c : candidates) {
        if (dsu.unite(c.u, c.v)) {
            result.edges.emplace_back(c.u, c.v);
            result.total += c.w;
        }
    }

    if (static_cast<int>(result.edges.size()) != n - 1) {
        throw std::invalid_argument("kruskal: graph is not connected");
    }
    std::ranges::sort(result.edges);
    return result;
}

}  // namespace ds

#endif  // DS_MST_HPP
