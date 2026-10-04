#ifndef DS_COMPRESSED_MATRIX_HPP
#define DS_COMPRESSED_MATRIX_HPP

#include <cstddef>
#include <stdexcept>
#include <vector>

namespace ds {

// 对称矩阵的压缩存储：只存下三角（含对角线），上三角元素映射到对称位置。
// n×n 矩阵从 n² 个位置降到 n(n+1)/2 个。
class SymmetricMatrix {
public:
    explicit SymmetricMatrix(int n) : n_(n) {
        if (n < 0) {
            throw std::invalid_argument("SymmetricMatrix: n < 0");
        }
        data_.assign(static_cast<size_t>(n) * static_cast<size_t>(n + 1) / 2, 0.0);
    }

    // 下标 0-based。r>=c 时槽号 r(r+1)/2+c；r<c 时映射到对称点 c(c+1)/2+r。
    double& at(int r, int c) {
        check_(r, c);
        if (r < c) {
            int t = r;
            r = c;
            c = t;
        }
        return data_[static_cast<size_t>(r) * static_cast<size_t>(r + 1) / 2
                     + static_cast<size_t>(c)];
    }

    // const 版本同逻辑，独立实现以免用 const_cast 破坏只读承诺。
    double at(int r, int c) const {
        check_(r, c);
        if (r < c) {
            int t = r;
            r = c;
            c = t;
        }
        return data_[static_cast<size_t>(r) * static_cast<size_t>(r + 1) / 2
                     + static_cast<size_t>(c)];
    }

    int order() const noexcept {
        return n_;
    }

    // 实际存放的位置数（压缩后），非矩阵大小。
    size_t stored() const noexcept {
        return data_.size();
    }

private:
    void check_(int r, int c) const {
        if (r < 0 || r >= n_ || c < 0 || c >= n_) {
            throw std::out_of_range("SymmetricMatrix::at: index out of range");
        }
    }

    int n_;
    std::vector<double> data_;
};

}  // namespace ds

#endif  // DS_COMPRESSED_MATRIX_HPP
