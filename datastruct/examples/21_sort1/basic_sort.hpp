#ifndef DS_BASIC_SORT_HPP
#define DS_BASIC_SORT_HPP

#include <algorithm>
#include <compare>
#include <concepts>
#include <functional>
#include <span>
#include <utility>

namespace ds {

// 插入排序：每步把第 i 个元素插入前方已排序段的正确位置。
// 不变量：外层第 i 轮之后，a[0..i] 是 a[0..i] 初始元素的一个有序排列。
// 模板化以便用自定义比较器演示稳定性（对 pair 只按 first 比较）。
template <std::copyable T, class Compare = std::less<T>>
void insertion_sort(std::span<T> a, Compare cmp = Compare{}) {
    for (std::ptrdiff_t i = 1; i < std::ssize(a); ++i) {
        T current = std::move(a[static_cast<std::size_t>(i)]);
        std::ptrdiff_t j = i - 1;
        // 注意是严格 cmp(...)：相等元素不后移，原相对次序得以保留（稳定）。
        while (j >= 0 && cmp(current, a[static_cast<std::size_t>(j)])) {
            a[static_cast<std::size_t>(j + 1)] = std::move(a[static_cast<std::size_t>(j)]);
            --j;
        }
        a[static_cast<std::size_t>(j + 1)] = std::move(current);
    }
}

// 折半插入排序：在已排序段内用二分查找定位，再一次性后移。
// 比较次数降到 O(log n) 每轮，但移动次数不变，总体仍是 O(n^2)。
// 不变量同插入排序：第 i 轮后 a[0..i] 有序。
inline void binary_insertion_sort(std::span<int> a) {
    for (std::ptrdiff_t i = 1; i < std::ssize(a); ++i) {
        const int current = a[static_cast<std::size_t>(i)];
        // 在 a[0..i-1] 中找第一个 >= current 的位置；
        // 下界用 lower_bound 口径（严格小于推进），相等元素插在其后 → 保持稳定。
        std::ptrdiff_t lo = 0;
        std::ptrdiff_t hi = i;
        while (lo < hi) {
            const std::ptrdiff_t mid = lo + (hi - lo) / 2;
            if (a[static_cast<std::size_t>(mid)] < current) {
                lo = mid + 1;
            } else {
                hi = mid;
            }
        }
        const std::ptrdiff_t pos = lo;
        for (std::ptrdiff_t j = i; j > pos; --j) {
            a[static_cast<std::size_t>(j)] = a[static_cast<std::size_t>(j - 1)];
        }
        a[static_cast<std::size_t>(pos)] = current;
    }
}

// 冒泡排序：每轮从头到尾相邻比较，逆序则交换，最大值像气泡一样浮到末尾。
// 不变量：第 k 轮之后，末尾 k 个元素已是全局最大的 k 个且按非降序就位。
template <std::copyable T, class Compare = std::less<T>>
void bubble_sort(std::span<T> a, Compare cmp = Compare{}) {
    const std::ptrdiff_t n = std::ssize(a);
    for (std::ptrdiff_t end = n - 1; end > 0; --end) {
        bool swapped = false;  // 提前结束：一整轮无交换说明已经有序
        for (std::ptrdiff_t j = 0; j < end; ++j) {
            // cmp(a[j+1], a[j]) 成立意味着次序反了；相等不交换 → 稳定。
            if (cmp(a[static_cast<std::size_t>(j + 1)],
                    a[static_cast<std::size_t>(j)])) {
                std::swap(a[static_cast<std::size_t>(j)],
                          a[static_cast<std::size_t>(j + 1)]);
                swapped = true;
            }
        }
        if (!swapped) {
            break;
        }
    }
}

// 选择排序：每轮从未排序段选出最小者，与段首交换。
// 不变量：第 i 轮之后，a[0..i-1] 是全局最小的 i 个元素且已就位。
// 交换发生在相距很远的位置，会改变相等元素的相对次序 → 不稳定。
inline void selection_sort(std::span<int> a) {
    const std::ptrdiff_t n = std::ssize(a);
    for (std::ptrdiff_t i = 0; i < n - 1; ++i) {
        std::ptrdiff_t min_index = i;
        for (std::ptrdiff_t j = i + 1; j < n; ++j) {
            if (a[static_cast<std::size_t>(j)] <
                a[static_cast<std::size_t>(min_index)]) {
                min_index = j;
            }
        }
        if (min_index != i) {
            std::swap(a[static_cast<std::size_t>(i)],
                      a[static_cast<std::size_t>(min_index)]);
        }
    }
}

namespace detail {

// Lomuto 划分：取中段元素为枢轴（换至段尾），扫一遍把小于枢轴的换到左侧。
// 返回枢轴最终位置 p：a[lo..p-1] < 枢轴 <= a[p+1..hi]。
// 取中段而非首元素，使"输入已排序"这一最常见情形划分仍然均衡。
inline std::ptrdiff_t partition(std::span<int> a,
                                std::ptrdiff_t lo,
                                std::ptrdiff_t hi) {
    const std::ptrdiff_t mid = lo + (hi - lo) / 2;
    std::swap(a[static_cast<std::size_t>(mid)],
              a[static_cast<std::size_t>(hi)]);
    const int pivot = a[static_cast<std::size_t>(hi)];
    std::ptrdiff_t store = lo;
    for (std::ptrdiff_t j = lo; j < hi; ++j) {
        if (a[static_cast<std::size_t>(j)] < pivot) {
            std::swap(a[static_cast<std::size_t>(store)],
                      a[static_cast<std::size_t>(j)]);
            ++store;
        }
    }
    std::swap(a[static_cast<std::size_t>(store)],
              a[static_cast<std::size_t>(hi)]);
    return store;
}

inline void quick_sort_rec(std::span<int> a,
                           std::ptrdiff_t lo,
                           std::ptrdiff_t hi) {
    if (lo >= hi) {
        return;
    }
    const std::ptrdiff_t p = partition(a, lo, hi);
    quick_sort_rec(a, lo, p - 1);
    quick_sort_rec(a, p + 1, hi);
}

}  // namespace detail

// 快速排序：划分后枢轴一次就位，左右两段递归，是平均最快的比较排序。
inline void quick_sort(std::span<int> a) {
    if (a.size() < 2) {
        return;
    }
    detail::quick_sort_rec(a, 0, std::ssize(a) - 1);
}

}  // namespace ds

#endif  // DS_BASIC_SORT_HPP
