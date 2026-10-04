#ifndef DS_ADVANCED_SORT_HPP
#define DS_ADVANCED_SORT_HPP

#include <algorithm>
#include <array>
#include <cstddef>
#include <queue>
#include <span>
#include <stdexcept>
#include <utility>
#include <vector>

namespace ds {

// 本章的六个算法共享同一个排序合同：输入一个可写（或只读）区间，
// 输出一个按 operator< 非降序排列的同元素多重集；长度严格守恒。
// 前四个比较排序只依赖 operator<；基数排序要求元素是非负无符号整数。

// ── 希尔排序：缩小增量插入排序 ──────────────────────────────────────────
// 增量序列 n/2, n/4, ..., 1。每轮对相距 gap 的元素做插入排序，
// 于是大跨步地把小元素前移、大元素后移；最后一轮 gap=1 就是普通
// 插入排序，此时序列已"基本有序"，插入排序接近 O(n)。
inline void shell_sort(std::span<int> a) {
    const std::size_t n = a.size();
    for (std::size_t gap = n / 2; gap > 0; gap /= 2) {
        // 不变量：本轮结束后，序列对 gap 有序——
        // 任意 i 都有 a[i] <= a[i+gap]（在两者都存在时）。
        for (std::size_t i = gap; i < n; ++i) {
            const int value = a[i];
            std::size_t j = i;
            while (j >= gap && value < a[j - gap]) {
                a[j] = a[j - gap];
                j -= gap;
            }
            a[j] = value;
        }
    }
}

// ── 堆排序：就地、最坏情况也有保证 ──────────────────────────────────────
// 先自底向上下沉建成最大堆；再反复把堆顶（当前最大值）与未排序区
// 末位交换，未排序区缩小 1，新堆顶在缩小后的区间内下沉。
// 全程只用交换用的临时变量，额外空间 O(1)。
inline void heap_sort(std::span<int> a) {
    const std::size_t n = a.size();
    if (n <= 1) {
        return;
    }

    // 0-based 下标：父 (i-1)/2；左孩子 2i+1；右孩子 2i+2。
    auto sift_down = [&](std::size_t i, std::size_t limit) {
        const int value = a[i];
        while (true) {
            std::size_t child = 2 * i + 1;  // 先看左孩子
            if (child >= limit) {
                break;
            }
            // 与右孩子比较，取两者中更大的
            if (child + 1 < limit && a[child] < a[child + 1]) {
                ++child;
            }
            if (value >= a[child]) {
                break;  // value 已不小于最大的孩子，落位
            }
            a[i] = a[child];
            i = child;
        }
        a[i] = value;
    };

    // 建初始最大堆：从最后一个非叶节点向前下沉
    for (std::size_t i = n / 2; i-- > 0;) {
        sift_down(i, n);
    }
    // 堆顶换到未排序区末尾，堆顶在缩小 1 的区间内重新下沉
    for (std::size_t limit = n; limit > 1; --limit) {
        std::swap(a[0], a[limit - 1]);
        sift_down(0, limit - 1);
    }
}

// ── 归并排序：分治 + 有序表合并 ─────────────────────────────────────────
namespace detail {

inline void merge_sort_rec(std::span<int> a, std::span<int> buffer) {
    if (a.size() <= 1) {
        return;
    }
    const std::size_t mid = a.size() / 2;
    merge_sort_rec(a.first(mid), buffer.first(mid));
    merge_sort_rec(a.subspan(mid), buffer.subspan(mid));

    // 两半各自有序；把它们稳定地并入 buffer 前缀，再抄回 a。
    std::size_t i = 0;
    std::size_t j = mid;
    std::size_t k = 0;
    while (i < mid && j < a.size()) {
        if (a[i] <= a[j]) {
            buffer[k++] = a[i++];
        } else {
            buffer[k++] = a[j++];
        }
    }
    while (i < mid) {
        buffer[k++] = a[i++];
    }
    while (j < a.size()) {
        buffer[k++] = a[j++];
    }
    std::copy_n(buffer.begin(), a.size(), a.begin());
}

}  // namespace detail

inline void merge_sort(std::span<int> a) {
    if (a.size() <= 1) {
        return;
    }
    std::vector<int> buffer(a.size());
    detail::merge_sort_rec(a, std::span<int>{buffer});
}

// ── 基数排序：LSD，不比较元素大小 ───────────────────────────────────────
// 从最低位开始，每轮按该位十进制数字稳定地分配进 10 个桶再收集。
// 稳定性是关键：本轮分配不得打乱上一轮在更高……（更低位）上建立的次序。
inline void radix_sort(std::span<unsigned int> a) {
    if (a.size() <= 1) {
        return;
    }
    unsigned int max_value = 0;
    for (unsigned int x : a) {
        max_value = std::max(max_value, x);
    }

    std::array<std::vector<unsigned int>, 10> buckets;
    // 用 64 位承载 exp：exp 超过 max_value 即停，避免 32 位回绕到 0。
    for (unsigned long long exp = 1; max_value >= exp; exp *= 10) {
        for (auto& bucket : buckets) {
            bucket.clear();
        }
        for (unsigned int x : a) {
            buckets[(static_cast<unsigned long long>(x) / exp) % 10].push_back(x);
        }
        std::size_t out = 0;
        for (auto& bucket : buckets) {
            for (unsigned int x : bucket) {
                a[out++] = x;
            }
        }
    }
}

// ── 桶排序：均匀分布假设下的线性期望时间 ────────────────────────────────
// 值域 [lo, hi] 等宽划分为 bucket_count_v 个桶；落入同桶的元素再用
// std::sort 排序。若输入在 [lo, hi] 上近似均匀，每桶只摊到常数个元素。
inline constexpr int bucket_count_v = 5;

inline int bucket_index_of(int value, int lo, int hi) {
    const int range = hi - lo + 1;
    int index = static_cast<int>(
        static_cast<long long>(value - lo) * bucket_count_v / range);
    index = std::clamp(index, 0, bucket_count_v - 1);
    return index;
}

inline void bucket_sort(std::span<int> a, int lo, int hi) {
    if (hi < lo) {
        throw std::invalid_argument("bucket_sort: hi < lo");
    }
    if (a.size() <= 1) {
        return;
    }

    std::array<std::vector<int>, bucket_count_v> buckets;
    for (int x : a) {
        buckets[bucket_index_of(x, lo, hi)].push_back(x);
    }
    // 不变量：桶 i 的值域整体位于桶 i+1 之左（边界等宽划分），
    // 故各桶分别排序后按桶号拼接即为全局有序。
    std::size_t out = 0;
    for (auto& bucket : buckets) {
        std::sort(bucket.begin(), bucket.end());
        for (int x : bucket) {
            a[out++] = x;
        }
    }
}

// 观察函数：按与 bucket_sort 完全相同的划分统计各桶元素数，
// 供演示程序打印确定性的桶分布。
inline std::array<int, bucket_count_v> bucket_distribution(
    std::span<const int> a, int lo, int hi) {
    if (hi < lo) {
        throw std::invalid_argument("bucket_distribution: hi < lo");
    }
    std::array<int, bucket_count_v> counts{};
    for (int x : a) {
        ++counts[bucket_index_of(x, lo, hi)];
    }
    return counts;
}

// ── 外部排序模拟：数据不假设一次装入内存，核心代价是 I/O ───────────────
// 第一段把输入切成 run_size 大小的初始归并段并各自排序；
// 第二段用最小堆做 k 路归并。返回长度与输入相同的有序序列。
inline std::vector<int> external_sort_sim(
    std::span<const int> input, std::size_t run_size) {
    if (run_size == 0) {
        throw std::invalid_argument("external_sort_sim: run_size must be >= 1");
    }
    const std::size_t n = input.size();
    if (n == 0) {
        return {};
    }

    const std::size_t run_count = (n + run_size - 1) / run_size;
    std::vector<std::vector<int>> runs(run_count);
    for (std::size_t r = 0; r < run_count; ++r) {
        const std::size_t begin = r * run_size;
        const std::size_t end = std::min(n, begin + run_size);
        runs[r].assign(input.begin() + static_cast<std::ptrdiff_t>(begin),
                       input.begin() + static_cast<std::ptrdiff_t>(end));
        std::sort(runs[r].begin(), runs[r].end());
    }

    // k 路归并：堆顶是全体段首元素中的最小者；平局按段号，
    // 保证输出与跨运行复现一致。
    struct Entry {
        int value;
        std::size_t run;
    };
    const auto entry_greater = [](const Entry& lhs, const Entry& rhs) {
        if (lhs.value != rhs.value) {
            return lhs.value > rhs.value;
        }
        return lhs.run > rhs.run;
    };
    std::priority_queue<Entry, std::vector<Entry>, decltype(entry_greater)> heap(
        entry_greater);

    std::vector<std::size_t> positions(run_count, 0);
    for (std::size_t r = 0; r < run_count; ++r) {
        heap.push({runs[r][0], r});
    }

    std::vector<int> output;
    output.reserve(n);
    while (!heap.empty()) {
        const Entry top = heap.top();
        heap.pop();
        output.push_back(top.value);
        std::size_t& pos = positions[top.run];
        ++pos;
        if (pos < runs[top.run].size()) {
            heap.push({runs[top.run][pos], top.run});
        }
    }
    return output;
}

}  // namespace ds

#endif  // DS_ADVANCED_SORT_HPP
