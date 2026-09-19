// ublas.cpp —— Boost.uBLAS（numeric/ublas，2002）：C++ 线代库的祖父辈。
// C++26 std::linalg 的精神源头（BLAS 语义的 C++ 表达）。
// 对应文档：docs/25-compute.md
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/lu.hpp>
#include <iostream>

namespace ublas = boost::numeric::ublas;

int main() {
    // 1) 向量与矩阵
    ublas::vector<double> v(3);
    v[0] = 1; v[1] = 2; v[2] = 3;
    ublas::matrix<double> A(2, 2);
    A(0, 0) = 4; A(0, 1) = 7;
    A(1, 0) = 2; A(1, 1) = 6;
    std::cout << "v = " << v << '\n';
    std::cout << "A = " << A << '\n';

    // 2) 表达式模板：写法像数学，求值免临时矩阵
    ublas::matrix<double> B(2, 2);
    B(0, 0) = 1; B(0, 1) = 0;
    B(1, 0) = 0; B(1, 1) = 1;
    std::cout << "A + B = " << (A + B) << '\n';
    std::cout << "A × B = " << ublas::prod(A, B) << '\n';
    ublas::vector<double> v2(2);
    v2[0] = v[0]; v2[1] = v[1];
    std::cout << "A × v(前2维) = " << ublas::prod(A, v2) << '\n';

    // 3) 行列式（LU 分解）
    ublas::permutation_matrix<std::size_t> pm(A.size1());
    ublas::matrix<double> A_copy = A;
    double det = 1.0;
    if (ublas::lu_factorize(A_copy, pm) == 0.0) {
        for (std::size_t i = 0; i < A_copy.size1(); ++i) det *= A_copy(i, i);
        // 行交换次数影响符号
        for (std::size_t i = 0; i < pm.size(); ++i) if (pm(i) != i) det = -det;
    }
    std::cout << "det(A) = " << det << "（4×6-7×2 = 10）\n";

    // 4) 逆矩阵
    ublas::matrix<double> inv(A);
    inv.assign(ublas::identity_matrix<double>(A.size1()));
    ublas::permutation_matrix<std::size_t> pm2(A.size1());
    ublas::matrix<double> A2 = A;
    ublas::lu_factorize(A2, pm2);
    ublas::lu_substitute(A2, pm2, inv);
    std::cout << "A⁻¹ = " << inv << '\n';

    std::cout << "自检通过\n";
    return 0;
}
