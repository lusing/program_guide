#ifndef DS_SPARSE_MATRIX_HPP
#define DS_SPARSE_MATRIX_HPP

#include <algorithm>
#include <cstddef>
#include <initializer_list>
#include <span>
#include <stdexcept>
#include <vector>

namespace ds {

struct Triple {
    int r;
    int c;
    double v;
};

// 稀疏矩阵的三元组顺序表（COO, coordinate list）：只存非零项，
// 内部恒按 (r,c) 字典序升序维护——顺序性是转置与归并相加的前提。
class SparseMatrix {
public:
    SparseMatrix(int rows, int cols, std::initializer_list<Triple> entries)
        : rows_(rows), cols_(cols), t_(entries) {
        normalize_();
    }

    int rows() const noexcept {
        return rows_;
    }

    int cols() const noexcept {
        return cols_;
    }

    std::span<const Triple> triples() const noexcept {
        return t_;
    }

    // 转置：行列互换，(r,c,v) 变为 (c,r,v)，再按 (r,c) 排序。
    // 不能只换两个下标而不重排：顺序不变量会被破坏。
    SparseMatrix transpose() const {
        SparseMatrix z(cols_, rows_, {});
        z.t_.reserve(t_.size());
        for (const Triple& x : t_) {
            z.t_.push_back(Triple{x.c, x.r, x.v});
        }
        z.normalize_();
        return z;
    }

    // 同型矩阵相加：两份有序三元组做双路归并；同位置求和，
    // 结果恰为 0 的项不存入（稀疏性可能上升）。
    SparseMatrix operator+(const SparseMatrix& rhs) const {
        if (rows_ != rhs.rows_ || cols_ != rhs.cols_) {
            throw std::invalid_argument("SparseMatrix::operator+: shape mismatch");
        }
        SparseMatrix z(rows_, cols_, {});
        size_t i = 0;
        size_t j = 0;
        while (i < t_.size() || j < rhs.t_.size()) {
            Triple pick;
            if (j == rhs.t_.size()
                || (i < t_.size() && less_(t_[i], rhs.t_[j]))) {
                pick = t_[i++];
            } else if (i == t_.size() || less_(rhs.t_[j], t_[i])) {
                pick = rhs.t_[j++];
            } else {
                pick = Triple{t_[i].r, t_[i].c, t_[i].v + rhs.t_[j].v};
                ++i;
                ++j;
            }
            if (pick.v != 0.0) {
                z.t_.push_back(pick);
            }
        }
        return z;
    }

private:
    static bool less_(const Triple& a, const Triple& b) {
        return a.r != b.r ? a.r < b.r : a.c < b.c;
    }

    // 构造后整理：校验范围 → 排序 → 查重 → 剔除零项。
    void normalize_() {
        for (const Triple& x : t_) {
            if (x.r < 0 || x.r >= rows_ || x.c < 0 || x.c >= cols_) {
                throw std::invalid_argument("SparseMatrix: triple out of range");
            }
        }
        std::sort(t_.begin(), t_.end(), less_);
        for (size_t i = 1; i < t_.size(); ++i) {
            if (!less_(t_[i - 1], t_[i])) {
                throw std::invalid_argument("SparseMatrix: duplicate cell");
            }
        }
        std::erase_if(t_, [](const Triple& x) { return x.v == 0.0; });
    }

    int rows_;
    int cols_;
    std::vector<Triple> t_;
};

}  // namespace ds

#endif  // DS_SPARSE_MATRIX_HPP
