// multi_array.cpp —— Boost.MultiArray（2002）：N 维数组容器。
// 拥有数据 + 运行期定形 + 可重定形（对照 C++23 std::mdspan 的纯视图）。
// 对应文档：docs/22-container-zoo.md
#include <boost/multi_array.hpp>
#include <iostream>

using mat_t = boost::multi_array<int, 2>;
using idx = mat_t::index;

int main() {
    // ── 1) 声明、形状与两种下标 ──
    mat_t mat(boost::extents[3][4]);              // extents：维度生成器
    std::cout << "形状 = " << mat.shape()[0] << "×" << mat.shape()[1]
              << " 维数 = " << mat.num_dimensions()
              << " 元素 = " << mat.num_elements() << '\n';
    for (idx i = 0; i < 3; ++i)
        for (idx j = 0; j < 4; ++j)
            mat[i][j] = static_cast<int>(i * 4 + j);   // 裸下标：C 数组姿势
    // 也可以一组索引走 operator()（某些场景更快）——用 boost::array 打包
    boost::array<idx, 2> iv{{2, 3}};
    std::cout << "mat[2][3] = " << mat[2][3] << " == mat(iv)? "
              << (mat(iv) == mat[2][3]) << '\n';

    // ── 2) 子视图：indices + index_range 圈一块（可带步长）──
    using range = mat_t::index_range;
    auto view = mat[boost::indices[range(0, 2)][range(0, 4, 2)]];  // 行 0-1，列 0/2
    std::cout << "子视图(2×2, 列步长2):";
    for (idx i = 0; i < 2; ++i) {
        std::cout << " [";
        for (idx j = 0; j < 2; ++j) std::cout << view[i][j] << ' ';
        std::cout << ']';
    }
    std::cout << '\n';
    // 切片：给某维一个**整数**而不是区间 → 降一维
    auto row1 = mat[boost::indices[1][range()]];         // 第 1 行 → 一维
    std::cout << "切片(第 1 行降维):";
    for (int x : row1) std::cout << ' ' << x;
    std::cout << '\n';

    // ── 3) 重定形（数据不动，解释方式变）与 resize ──
    mat_t reshaped = mat;
    boost::array<idx, 2> dims43{{4, 3}};
    reshaped.reshape(dims43);                             // 3×4 → 4×3（积不变）
    std::cout << "reshape 后 = " << reshaped.shape()[0] << "×" << reshaped.shape()[1]
              << " [2][2]=" << reshaped[2][2] << "（原 [3][1] 的值）\n";
    mat_t grown = mat;
    grown.resize(boost::extents[2][9]);                  // 3×4 → 2×9
    std::cout << "resize 后 = " << grown.shape()[0] << "×" << grown.shape()[1]
              << " 元素 = " << grown.num_elements() << "（新元素零初始化）\n";

    // ── 4) 索引基数：不用 0 起数 ──
    // extent_range：第一维 1..4，第三维 -2..1 的三维写法（书例）：
    {
        using m3 = boost::multi_array<int, 3>;
        using er = m3::extent_range;
        m3 weird(boost::extents[er(1, 5)][4][er(-2, 2)]);
        weird[1][0][-2] = 10;                            // 第一个元素
        std::cout << "索引基数: [1][0][-2] = " << weird[1][0][-2]
                  << " 基 = " << weird.index_bases()[0] << '/'
                  << weird.index_bases()[2] << '\n';
        weird.reindex(1);                                // 所有维改 1 起
        std::cout << "reindex(1) 后首元素在 [1][1][1]? "
                  << (weird[1][1][1] == 10) << '\n';
    }

    // ── 5) 适配既有内存：multi_array_ref / const_multi_array_ref ──
    // 【实测坑】multi_array_ref 的构造函数**只吃维度序列**（array/vector），
    // 不认 extents 表达式——这和 multi_array 正相反（两个都认）。
    int raw[6] = {0, 1, 2, 3, 4, 5};
    boost::array<idx, 2> dims23{{2, 3}}, dims32{{3, 2}};
    boost::multi_array_ref<int, 2> ref(raw, dims23);
    const boost::const_multi_array_ref<int, 2> cref(raw, dims32);
    ref[1][2] = 99;                                      // 可写（操纵原内存）
    std::cout << "ref 改写原内存: raw[5] = " << raw[5]
              << " 只读视图 [2][1] = " << cref[2][1] << '\n';

    // ── 6) 三维与 origin/data：连续内存视角 ──
    boost::multi_array<int, 3> cube(boost::extents[2][2][2]);
    cube[1][1][1] = 42;
    std::cout << "立方体角点 = " << cube[1][1][1]
              << " data 连续? " << (cube.data() == cube.origin()) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
