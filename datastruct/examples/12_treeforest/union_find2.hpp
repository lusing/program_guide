#ifndef DS_UNION_FIND2_HPP
#define DS_UNION_FIND2_HPP

#include <numeric>
#include <stdexcept>
#include <vector>

namespace ds {

// 并查集加强版：按秩合并（union by rank）+ 路径压缩（path compression）。
//
// 与第 06 章按大小合并版的区别：这里的 rank_ 是"树高上界"。两棵秩相同的
// 树合并时新根的秩才加一，其余情况秩不变；find 沿路把节点直接改挂到根下。
// 两种优化叠加后，单次操作接近常数（逆 Ackermann 级）。
class UnionFind2 {
public:
    explicit UnionFind2(int n) {
        if (n < 0) {
            throw std::length_error{"元素个数不能为负"};
        }
        parent_.resize(static_cast<std::size_t>(n));
        rank_.assign(static_cast<std::size_t>(n), 0);
        std::iota(parent_.begin(), parent_.end(), 0);
        count_ = n;
    }

    // 返回 i 的根，并做路径压缩：递归回程把沿途节点直接挂到根下。
    int find(int i) {
        check_(i);
        int& parent = parent_[static_cast<std::size_t>(i)];
        if (parent != i) {
            parent = find(parent);
        }
        return parent;
    }

    // 合并 a、b；本就同集返回 false。
    // 按秩：矮树挂高树；同秩时 b 的根挂到 a 的根下、a 根秩加一
    //（平局固定方向，任何机器结果一致）。
    bool unite(int a, int b) {
        int ra = find(a);
        int rb = find(b);
        if (ra == rb) {
            return false;
        }
        int& rank_a = rank_[static_cast<std::size_t>(ra)];
        int& rank_b = rank_[static_cast<std::size_t>(rb)];
        if (rank_a < rank_b) {
            std::swap(ra, rb);
        } else if (rank_a == rank_b) {
            ++rank_a;  // 同秩合并，被保留的根（a 侧）秩加一
        }
        parent_[static_cast<std::size_t>(rb)] = ra;
        --count_;
        return true;
    }

    // 根的秩（树高上界）。
    [[nodiscard]] int rank_of(int i) const {
        check_(i);
        int root = i;
        while (parent_[static_cast<std::size_t>(root)] != root) {
            root = parent_[static_cast<std::size_t>(root)];
        }
        return rank_[static_cast<std::size_t>(root)];
    }

    // i 沿父指针走到根的实际步数（压缩前/后的深度）。
    [[nodiscard]] int depth_of(int i) const {
        check_(i);
        int depth = 0;
        while (parent_[static_cast<std::size_t>(i)] != i) {
            i = parent_[static_cast<std::size_t>(i)];
            ++depth;
        }
        return depth;
    }

    // 秩界 sanity：按秩合并下，秩为 r 的根至少挂着 2^r 个节点，
    // 故全体最大秩不超过 floor(log2 n)（这里用计划约定的 +1 宽松界）。
    [[nodiscard]] bool rank_sanity() const {
        int max_rank = 0;
        for (std::size_t i = 0; i < parent_.size(); ++i) {
            if (parent_[i] == static_cast<int>(i) && rank_[i] > max_rank) {
                max_rank = rank_[i];
            }
        }
        int bound = 1;
        int log2 = 0;
        while (bound * 2 <= static_cast<int>(parent_.size())) {
            bound *= 2;
            ++log2;
        }
        return max_rank <= log2 + 1;
    }

    [[nodiscard]] int count() const noexcept { return count_; }

private:
    void check_(int i) const {
        if (i < 0 || static_cast<std::size_t>(i) >= parent_.size()) {
            throw std::out_of_range{"元素编号越界"};
        }
    }

    std::vector<int> parent_;
    std::vector<int> rank_;
    int count_ = 0;
};

}  // namespace ds

#endif  // DS_UNION_FIND2_HPP
