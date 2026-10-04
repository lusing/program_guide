#ifndef DS_ADJ_LIST_HPP
#define DS_ADJ_LIST_HPP

#include <algorithm>
#include <cstddef>
#include <span>
#include <stdexcept>
#include <vector>

namespace ds {

struct Edge {
    int to;
    double w;
};

// 图的邻接表表示：每个顶点挂一条边表。
// 不变量：每条边表始终按目标顶点编号升序排列 —— 遍历类算法因此
// 不必每次排序，且"邻点按编号升序访问"的约定自动成立。
class AdjList {
public:
    AdjList(int n, bool directed = false)
        : n_(n), directed_(directed),
          a_(static_cast<size_t>(n)), edges_(0) {}

    // 加边；重复边按更新权值处理。插入位置用 lower_bound 找，
    // 以维持边表按 to 升序的不变量。
    void add_edge(int u, int v, double weight = 1.0) {
        check_(u);
        check_(v);
        auto& list = a_[static_cast<size_t>(u)];
        auto it = std::ranges::lower_bound(list, v, {}, &Edge::to);
        if (it != list.end() && it->to == v) {
            it->w = weight;
        } else {
            list.insert(it, Edge{v, weight});
            ++edges_;
        }
        if (!directed_) {
            auto& rev = a_[static_cast<size_t>(v)];
            auto rit = std::ranges::lower_bound(rev, u, {}, &Edge::to);
            if (rit == rev.end() || rit->to != u) {
                rev.insert(rit, Edge{u, weight});
            }
        }
    }

    void remove_edge(int u, int v) {
        check_(u);
        check_(v);
        auto& list = a_[static_cast<size_t>(u)];
        auto it = std::ranges::find(list, v, &Edge::to);
        if (it == list.end()) {
            return;
        }
        list.erase(it);
        --edges_;
        if (!directed_) {
            auto& rev = a_[static_cast<size_t>(v)];
            auto rit = std::ranges::find(rev, u, &Edge::to);
            if (rit != rev.end()) {
                rev.erase(rit);
            }
        }
    }

    [[nodiscard]] bool has_edge(int u, int v) const {
        check_(u);
        check_(v);
        const auto& list = a_[static_cast<size_t>(u)];
        return std::ranges::binary_search(list, v, {}, &Edge::to);
    }

    [[nodiscard]] std::span<const Edge> neighbors(int v) const {
        check_(v);
        return a_[static_cast<size_t>(v)];
    }

    [[nodiscard]] int n() const noexcept { return n_; }
    [[nodiscard]] bool directed() const noexcept { return directed_; }
    [[nodiscard]] int edge_count() const noexcept { return edges_; }

private:
    int n_;
    bool directed_;
    std::vector<std::vector<Edge>> a_;
    int edges_;

    void check_(int v) const {
        if (v < 0 || v >= n_) {
            throw std::out_of_range("AdjList: vertex out of range");
        }
    }
};

}  // namespace ds

#endif  // DS_ADJ_LIST_HPP
