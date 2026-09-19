// mdspan.cpp —— std::mdspan（C++23）：多维数组视图的标准化。
// Boost 1.92 没有收录 mdspan（Kokkos 谱系），但 multi_array（22 章）是
// 它的远亲——本例用 std::mdspan 对照"裸内存上的多维视图"三件套。
// 对应文档：docs/17-cpp23.md
#include <mdspan>
#include <iostream>
#include <vector>

int main() {
    // 1) 把一维裸数组"看成" 3×4 的二维矩阵（零拷贝、零分配）
    std::vector<int> data{1,  2,  3,  4,
                          5,  6,  7,  8,
                          9, 10, 11, 12};
    std::mdspan mat(data.data(), 3, 4);

    std::cout << "维度 = " << mat.extent(0) << "×" << mat.extent(1) << '\n';
    std::cout << "mat[2,3] = " << mat[std::array{2, 3}] << "（C++23 逗号下标）\n";
    std::cout << "mat[1,1] = " << mat[std::array{1, 1}] << '\n';

    // 2) 遍历：layout_right 按行主序
    long sum = 0;
    for (std::size_t i = 0; i < mat.extent(0); ++i)
        for (std::size_t j = 0; j < mat.extent(1); ++j)
            sum += mat[std::array{i, j}];
    std::cout << "全元素和 = " << sum << '\n';

    // 3) 切片视图：submdspan（部分标准库暂缺，用首元素指针的手工切片示意）
    std::mdspan row1(data.data() + 4, 4);       // 第 1 行当一维看
    std::cout << "第 1 行首元素 = " << row1[0] << '\n';

    // 4) 对照 boost::multi_array（22 章）：multi_array 拥有数据 + 可重定形；
    //    mdspan 只是视图（不拥有）——配套关系像 string/string_view
    std::cout << "选型：拥有数据 multi_array / 仅视图 mdspan\n";

    std::cout << "自检通过\n";
    return 0;
}
