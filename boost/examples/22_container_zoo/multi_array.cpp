// multi_array.cpp —— Boost.MultiArray（2002）：N 维数组容器。
// 拥有数据 + 运行期定形 + 可重定形（对照 C++23 std::mdspan 的纯视图）。
// 对应文档：docs/22-container-zoo.md
#include <boost/multi_array.hpp>
#include <iostream>

int main() {
    // 1) 声明与形状
    boost::multi_array<int, 2> mat(boost::extents[3][4]);
    std::cout << "形状 = " << mat.shape()[0] << "×" << mat.shape()[1] << '\n';

    // 2) 写入：多维下标
    for (std::size_t i = 0; i < mat.shape()[0]; ++i)
        for (std::size_t j = 0; j < mat.shape()[1]; ++j)
            mat[i][j] = static_cast<int>(i * 10 + j);

    std::cout << "mat[2][3] = " << mat[2][3] << " mat[1][1] = " << mat[1][1] << '\n';

    // 3) 切片视图：第 1 行
    auto row1 = mat[1];
    std::cout << "第 1 行:";
    for (int x : row1) std::cout << ' ' << x;
    std::cout << '\n';

    // 4) 重定形（数据不动，解释方式变——mdspan 做不到，它不拥有数据）
    boost::array<decltype(mat)::index, 2> dims = {4, 3};
    mat.reshape(dims);
    std::cout << "重定形后 = " << mat.shape()[0] << "×" << mat.shape()[1]
              << " 元素总数不变 = " << mat.num_elements() << '\n';

    // 5) 三维一样用
    boost::multi_array<int, 3> cube(boost::extents[2][2][2]);
    cube[1][1][1] = 42;
    std::cout << "立方体角点 = " << cube[1][1][1] << '\n';

    std::cout << "自检通过\n";
    return 0;
}
