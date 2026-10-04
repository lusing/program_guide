#ifndef DS_PERF_HPP
#define DS_PERF_HPP

#include <span>

namespace ds {

// 循环累加 1+2+…+n。执行的基本操作次数与 n 成正比：n 次加法、n 次自增、n 次比较。
long long sum_loop(int n) {
    long long total = 0;
    for (int i = 1; i <= n; ++i) {
        total += i;
    }
    return total;
}

// 公式法 n(n+1)/2。无论 n 多大，操作次数恒定 —— 与 n 无关。
constexpr long long sum_formula(int n) {
    return static_cast<long long>(n) * (n + 1) / 2;
}

// 计次用的元素：每被拷贝一次，copies 就加一，用来观察排序的搬运成本。
struct Counter {
    int value;
    int copies;
};

// 直接插入排序，并返回比较次数。完全逆序时比较次数取到上界 n(n-1)/2。
void insertion_sort_with_count(std::span<Counter> a, long long& comparisons) {
    comparisons = 0;
    for (size_t i = 1; i < a.size(); ++i) {
        Counter key = a[i];
        ++key.copies;
        size_t j = i;
        while (j > 0) {
            ++comparisons;
            if (a[j - 1].value <= key.value) {
                break;
            }
            a[j] = a[j - 1];
            --j;
        }
        a[j] = key;
    }
}

}  // namespace ds

#endif  // DS_PERF_HPP
