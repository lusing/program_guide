#ifndef DS_UNION_FIND_HPP
#define DS_UNION_FIND_HPP

#include <numeric>
#include <stdexcept>
#include <vector>

namespace ds {

// 并查集（本章快速版：按大小合并）。
// 管理 n 个元素的等价类：find(i) 给出 i 所在集合的代表元（根），
// unite(a,b) 合并两个集合。两棵树同高时的平局约定：b 并入 a，
// 即 a 的根继续作根 —— 保证任何机器上结果一致。
class UnionFind {
public:
    explicit UnionFind(int n) {
        if (n < 0) {
            throw std::length_error{"元素个数不能为负"};
        }
        parent_.resize(static_cast<std::size_t>(n));
        size_.resize(static_cast<std::size_t>(n), 1);
        std::iota(parent_.begin(), parent_.end(), 0);  // 起初各自成集
        count_ = n;
    }

    // 返回 i 所在集合的根。本章版不做路径压缩（留给第 12 章加强版）。
    int find(int i) const {
        check_(i);
        int root = i;
        while (parent_[static_cast<std::size_t>(root)] != root) {
            root = parent_[static_cast<std::size_t>(root)];
        }
        return root;
    }

    // 合并 a、b 所在集合；本就同集返回 false。
    // 小树挂到大树下（按大小合并），平局时 a 的根作根。
    bool unite(int a, int b) {
        int ra = find(a);
        int rb = find(b);
        if (ra == rb) {
            return false;
        }
        if (size_[static_cast<std::size_t>(ra)] <
            size_[static_cast<std::size_t>(rb)]) {
            std::swap(ra, rb);  // 保证 ra 是较大（平局时仍是 a）的一方
        }
        parent_[static_cast<std::size_t>(rb)] = ra;
        size_[static_cast<std::size_t>(ra)] +=
            size_[static_cast<std::size_t>(rb)];
        --count_;
        return true;
    }

    // i 所在集合的元素个数。
    int size(int i) const { return size_[static_cast<std::size_t>(find(i))]; }

    [[nodiscard]] int count() const noexcept { return count_; }

private:
    void check_(int i) const {
        if (i < 0 || static_cast<std::size_t>(i) >= parent_.size()) {
            throw std::out_of_range{"元素编号越界"};
        }
    }

    std::vector<int> parent_;
    std::vector<int> size_;
    int count_ = 0;
};

}  // namespace ds

#endif  // DS_UNION_FIND_HPP
