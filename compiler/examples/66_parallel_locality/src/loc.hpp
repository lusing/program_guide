// file: src/loc.hpp
// 第 66 章配套：仿射循环变换的合法性与缓存收益。
#ifndef TIP_LOC_HPP
#define TIP_LOC_HPP

#include <string>
#include <vector>

namespace tip {

struct GcdInfo {
    int gcd = 1;
    bool dependent = true;
};

// GCD 检验：i1*i − i2*j = c 有整数解 ⟺ gcd(i1,i2) | c
GcdInfo gcdDep(int i1, int i2, int c);

// 交换合法性：方向向量不含 "<"（即没有“后面的迭代读前面”的逆序依赖）
bool directionLegal(const std::vector<int> &dir);

// 演示用方向向量（写 a[i][j]、读 a[i-k][j]）：(<,=)
std::vector<int> directionOf(int k);
std::string showDir(const std::vector<int> &d);

enum class Order { RowMajor, ColMajor, Tiled };

struct CacheReport {
    int reads = 0, writes = 0, misses = 0;
};

// 直接映射缓存模拟：N×N 矩阵按三种顺序访问，行大小与缓存槽数可调。
CacheReport cacheSim(int N, Order ord, int lineSize, int cacheLines);

}  // namespace tip

#endif  // TIP_LOC_HPP
