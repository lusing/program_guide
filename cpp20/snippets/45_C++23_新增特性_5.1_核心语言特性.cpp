#include <mdspan>

std::mdspan<int, std::extents<int, 3, 4, 5>> matrix;

// 使用多维下标访问
matrix[1, 2, 3] = 42;

// 遍历多维数组
for (int i = 0; i < 3; ++i) {
    for (int j = 0; j < 4; ++j) {
        for (int k = 0; k < 5; ++k) {
            matrix[i, j, k] = i + j + k;
        }
    }
}
