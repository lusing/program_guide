#pragma once
#include <array>
#include <cstddef>
#include <span>
#include <stdexcept>
#include <utility>

// 24 分而治之：残缺棋盘铺 tromino、成对分治 min-max、快速选择
namespace ds {

using Board = std::array<std::array<int, 4>, 4>;

struct MM {
    int min;
    int max;
    int comparisons;
};

namespace detail {

// 在左上角 (top,left)、边长 size 的子棋盘上铺块；(mr,mc) 是该子棋盘的缺格。
// 不变量：进入时缺格恰有一个；先在中心放一块 L 形 tromino 覆盖三个
// "无真缺格" 子棋盘的相邻格，使四个子棋盘各带一个缺格，再分别递归。
inline void tromino_rec(Board& b, int top, int left, int size,
                        int mr, int mc, int& next) {
    if (size == 1) {
        return;  // 1x1 子棋盘只剩缺格本身，无需铺块
    }
    const int s = size / 2;
    const int cr = top + s;   // 上/下象限分界行
    const int cc = left + s;  // 左/右象限分界列
    const bool tl = (mr < cr) && (mc < cc);
    const bool tr = (mr < cr) && (mc >= cc);
    const bool bl = (mr >= cr) && (mc < cc);
    const bool br = (mr >= cr) && (mc >= cc);
    const int t = next++;  // 中心 L 形铺块编号
    if (!tl) { b[cr - 1][cc - 1] = t; }
    if (!tr) { b[cr - 1][cc] = t; }
    if (!bl) { b[cr][cc - 1] = t; }
    if (!br) { b[cr][cc] = t; }
    // 四个子棋盘各带一个缺格（真的或中心块人造的）继续递归
    tromino_rec(b, top, left, s, tl ? mr : cr - 1, tl ? mc : cc - 1, next);
    tromino_rec(b, top, cc, s, tr ? mr : cr - 1, tr ? mc : cc, next);
    tromino_rec(b, cr, left, s, bl ? mr : cr, bl ? mc : cc - 1, next);
    tromino_rec(b, cr, cc, s, br ? mr : cr, br ? mc : cc, next);
}

// 闭区间 [lo,hi] 上的分治 min-max；comps 累计元素间的比较次数
inline std::pair<int, int> minmax_rec(const std::span<const int> a, int lo,
                                      int hi, int& comps) {
    if (lo == hi) {
        return {a[lo], a[lo]};  // 单元素：0 次比较
    }
    if (hi - lo == 1) {
        ++comps;  // 两元素：1 次比较同时定下 min 与 max
        if (a[lo] < a[hi]) {
            return {a[lo], a[hi]};
        }
        return {a[hi], a[lo]};
    }
    const int mid = lo + (hi - lo) / 2;
    const std::pair<int, int> lhs = minmax_rec(a, lo, mid, comps);
    const std::pair<int, int> rhs = minmax_rec(a, mid + 1, hi, comps);
    ++comps;  // 合并：两个局部 min 比一次
    ++comps;  // 合并：两个局部 max 比一次
    const int mn = lhs.first < rhs.first ? lhs.first : rhs.first;
    const int mx = lhs.second > rhs.second ? lhs.second : rhs.second;
    return {mn, mx};
}

// Lomuto 划分，固定取 a[lo] 为枢轴；返回枢轴最终下标
inline int partition_first(const std::span<int> a, int lo, int hi) {
    const int pivot = a[lo];
    int i = lo;
    for (int j = lo + 1; j <= hi; ++j) {
        if (a[j] < pivot) {
            ++i;
            std::swap(a[i], a[j]);
        }
    }
    std::swap(a[lo], a[i]);
    return i;
}

inline int quickselect_rec(const std::span<int> a, int lo, int hi, int k) {
    const int p = partition_first(a, lo, hi);
    if (k == p) {
        return a[p];
    }
    if (k < p) {
        return quickselect_rec(a, lo, p - 1, k);
    }
    return quickselect_rec(a, p + 1, hi, k);
}

}  // namespace detail

// 4x4 残缺棋盘铺 tromino：缺格 (mr,mc) 保持 0，其余以 1..5 编号（每块 3 格）。
// 前提：0 <= mr,mc < 4，违规抛 std::out_of_range。
inline Board tromino(int mr, int mc) {
    if (mr < 0 || mr >= 4 || mc < 0 || mc >= 4) {
        throw std::out_of_range("tromino: 缺格坐标越界");
    }
    Board b{};  // 全 0 初始化；除缺格外每格在递归中恰被赋值一次
    int next = 1;
    detail::tromino_rec(b, 0, 0, 4, mr, mc, next);
    return b;
}

// 成对分治 min-max：返回最小值、最大值与实际比较次数（偶数 n 为 3n/2-2，
// 奇数 n 为 3(n-1)/2）。前提：a 非空，违规抛 std::invalid_argument。
inline MM min_max(const std::span<const int> a) {
    if (a.empty()) {
        throw std::invalid_argument("min_max: 空区间");
    }
    int comps = 0;
    const std::pair<int, int> r =
        detail::minmax_rec(a, 0, static_cast<int>(a.size()) - 1, comps);
    return MM{r.first, r.second, comps};
}

// 快速选择：返回第 k 小（0-based），只递归划分后包含 k 的一侧。
// 前提：0 <= k < a.size()，违规抛 std::out_of_range。
// 注意：划分会重排 a 中的元素（与第 21 章 quick_sort 的划分同手法）。
inline int quickselect(const std::span<int> a, int k) {
    if (k < 0 || static_cast<std::size_t>(k) >= a.size()) {
        throw std::out_of_range("quickselect: k 越界");
    }
    return detail::quickselect_rec(a, 0, static_cast<int>(a.size()) - 1, k);
}

}  // namespace ds
