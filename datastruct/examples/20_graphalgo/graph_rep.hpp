#ifndef DS_GRAPH_REP_HPP
#define DS_GRAPH_REP_HPP

#include <algorithm>
#include <cstddef>
#include <stdexcept>
#include <vector>

namespace ds {

// 内部"无边"哨兵。数值取 1e18：远大于任何合法路径长，
// 又小于 double 上溢阈值，相加时在 shortest_path.hpp 里先判半界再求和。
inline constexpr double kNoEdge = 1.0e18;

// ───────────────────────── 邻接矩阵 ─────────────────────────
// 把图压进 n×n 顺序存储：weight_[u*n+v] 是边权，无边为 kNoEdge。
class AdjMatrix {
public:
    AdjMatrix(int n, bool directed)
        : n_(n), directed_(directed),
          weight_(static_cast<size_t>(n) * static_cast<size_t>(n), kNoEdge) {
        for (int i = 0; i < n; ++i) {
            weight_[static_cast<size_t>(i) * static_cast<size_t>(n) + i] = 0.0;
        }
    }

    void add_edge(int u, int v, double w = 1.0) {
        check_vertex_(u);
        check_vertex_(v);
        weight_[static_cast<size_t>(u) * static_cast<size_t>(n_) + v] = w;
        if (!directed_) {
            weight_[static_cast<size_t>(v) * static_cast<size_t>(n_) + u] = w;
        }
    }

    [[nodiscard]] bool has_edge(int u, int v) const {
        check_vertex_(u);
        check_vertex_(v);
        return weight_[static_cast<size_t>(u) * static_cast<size_t>(n_) + v] < kNoEdge;
    }

    // 无边返回 kNoEdge；调用方据此判定，不依赖异常做算法分支。
    [[nodiscard]] double weight(int u, int v) const {
        check_vertex_(u);
        check_vertex_(v);
        return weight_[static_cast<size_t>(u) * static_cast<size_t>(n_) + v];
    }

    [[nodiscard]] int n() const noexcept { return n_; }
    [[nodiscard]] bool directed() const noexcept { return directed_; }

private:
    void check_vertex_(int v) const {
        if (v < 0 || v >= n_) {
            throw std::out_of_range("vertex index out of range");
        }
    }

    int n_;
    bool directed_;
    std::vector<double> weight_;
};

// ───────────────────────── 邻接表 ─────────────────────────
struct Edge {
    int to;
    double w;
};

// 每个顶点挂一条出边表。插入后出边表按 to 升序归位——
// 这样遍历邻点天然确定，算法输出可逐字节复现。
class AdjList {
public:
    AdjList(int n, bool directed)
        : n_(n), directed_(directed),
          adj_(static_cast<size_t>(n)) {}

    void add_edge(int u, int v, double w = 1.0) {
        check_vertex_(u);
        check_vertex_(v);
        insert_sorted_(adj_[static_cast<size_t>(u)], Edge{v, w});
        if (!directed_) {
            insert_sorted_(adj_[static_cast<size_t>(v)], Edge{u, w});
        }
    }

    [[nodiscard]] bool has_edge(int u, int v) const {
        check_vertex_(u);
        check_vertex_(v);
        return std::ranges::any_of(adj_[static_cast<size_t>(u)],
                                  [v](const Edge& e) { return e.to == v; });
    }

    [[nodiscard]] const std::vector<Edge>& out_edges(int u) const {
        check_vertex_(u);
        return adj_[static_cast<size_t>(u)];
    }

    [[nodiscard]] int n() const noexcept { return n_; }
    [[nodiscard]] bool directed() const noexcept { return directed_; }

private:
    static void insert_sorted_(std::vector<Edge>& edges, Edge e) {
        auto it = std::ranges::lower_bound(edges, e.to, {}, &Edge::to);
        edges.insert(it, e);
    }

    void check_vertex_(int v) const {
        if (v < 0 || v >= n_) {
            throw std::out_of_range("vertex index out of range");
        }
    }

    int n_;
    bool directed_;
    std::vector<std::vector<Edge>> adj_;
};

}  // namespace ds

#endif  // DS_GRAPH_REP_HPP
