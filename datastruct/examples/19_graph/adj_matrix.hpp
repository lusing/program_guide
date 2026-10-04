#ifndef DS_ADJ_MATRIX_HPP
#define DS_ADJ_MATRIX_HPP

#include <cstddef>
#include <limits>
#include <stdexcept>
#include <utility>
#include <vector>

namespace ds {

// 图的邻接矩阵表示：n×n 的权值表，无边用 +∞ 占位。
// 无向图只存下半个对称面，add_edge 时两个方向都登记。
class AdjMatrix {
public:
    static constexpr double NO_EDGE = std::numeric_limits<double>::infinity();

    AdjMatrix(int n, bool directed = false)
        : n_(n), directed_(directed),
          w_(static_cast<size_t>(n) * n, NO_EDGE), edges_(0) {}

    // 加边 (u,v)，权 w 默认 1；顶点越界属编程错误，抛异常。
    // 重复加边按更新权值处理，不重复计边数。
    void add_edge(int u, int v, double weight = 1.0) {
        check_(u);
        check_(v);
        if (!has_edge(u, v)) {
            ++edges_;
        }
        at_(u, v) = weight;
        if (!directed_) {
            at_(v, u) = weight;
        }
    }

    void remove_edge(int u, int v) {
        check_(u);
        check_(v);
        if (!has_edge(u, v)) {
            return;
        }
        at_(u, v) = NO_EDGE;
        if (!directed_) {
            at_(v, u) = NO_EDGE;
        }
        --edges_;
    }

    [[nodiscard]] bool has_edge(int u, int v) const {
        check_(u);
        check_(v);
        return at_(u, v) != NO_EDGE;
    }

    [[nodiscard]] double weight(int u, int v) const {
        if (!has_edge(u, v)) {
            throw std::runtime_error("AdjMatrix::weight: edge does not exist");
        }
        return at_(u, v);
    }

    // v 的全部邻点 (顶点, 权)；按下标 0..n 扫描，天然按顶点升序。
    [[nodiscard]] std::vector<std::pair<int, double>> neighbors(int v) const {
        check_(v);
        std::vector<std::pair<int, double>> result;
        for (int u = 0; u < n_; ++u) {
            if (at_(v, u) != NO_EDGE) {
                result.emplace_back(u, at_(v, u));
            }
        }
        return result;
    }

    [[nodiscard]] int n() const noexcept { return n_; }
    [[nodiscard]] bool directed() const noexcept { return directed_; }
    [[nodiscard]] int edge_count() const noexcept { return edges_; }

private:
    int n_;
    bool directed_;
    std::vector<double> w_;
    int edges_;

    void check_(int v) const {
        if (v < 0 || v >= n_) {
            throw std::out_of_range("AdjMatrix: vertex out of range");
        }
    }

    double& at_(int u, int v) {
        return w_[static_cast<size_t>(u) * static_cast<size_t>(n_) +
                  static_cast<size_t>(v)];
    }
    const double& at_(int u, int v) const {
        return w_[static_cast<size_t>(u) * static_cast<size_t>(n_) +
                  static_cast<size_t>(v)];
    }
};

}  // namespace ds

#endif  // DS_ADJ_MATRIX_HPP
