#ifndef DS_BINARY_HEAP_HPP
#define DS_BINARY_HEAP_HPP

#include <concepts>
#include <cstddef>
#include <functional>
#include <span>
#include <stdexcept>
#include <utility>
#include <vector>

namespace ds {

// 二叉堆：用数组隐式表示的完全二叉树实现优先队列。
// Compare comp 给出"优先权更高"的方向：
//   std::less<T>   → 最小堆，top() 是最小元素；
//   std::greater<T> → 最大堆。
// 不变量：对每个非根节点 i，均有 comp(data_[i], data_[parent]) == false，
// 即任何节点都不比它的父节点"优先权更高"。
template <std::totally_ordered T, class Compare = std::less<T>>
class BinaryHeap {
public:
    BinaryHeap() = default;

    // 批量构造：先全部放入数组，再自底向上下沉调整（heapify），总成本 O(n)。
    explicit BinaryHeap(std::span<const T> items)
        : data_(items.begin(), items.end()) {
        heapify_();
    }

    [[nodiscard]] bool empty() const noexcept { return data_.empty(); }
    [[nodiscard]] size_t size() const noexcept { return data_.size(); }

    // 入队：放到数组末尾（完全树最后一个位置），再上浮到应处位置。
    void push(const T& value) {
        data_.push_back(value);
        sift_up_(data_.size() - 1);
    }

    // 查看优先权最高的元素但不移除。空堆属于编程错误，抛异常。
    [[nodiscard]] const T& top() const {
        if (data_.empty()) {
            throw std::runtime_error("BinaryHeap::top: heap is empty");
        }
        return data_.front();
    }

    // 出队：根与末元素交换后移除末元素，新根下沉。空堆抛异常。
    void pop() {
        if (data_.empty()) {
            throw std::runtime_error("BinaryHeap::pop: heap is empty");
        }
        data_.front() = std::move(data_.back());
        data_.pop_back();
        if (!data_.empty()) {
            sift_down_(0);
        }
    }

    // 堆序自检：任意节点都不比父节点优先权更高。
    [[nodiscard]] bool is_heap() const {
        for (size_t i = 1; i < data_.size(); ++i) {
            if (comp_(data_[i], data_[parent_(i)])) {
                return false;
            }
        }
        return true;
    }

private:
    std::vector<T> data_;
    Compare comp_{};

    // 0-based 下标公式：父 (i-1)/2；左孩子 2i+1；右孩子 2i+2
    [[nodiscard]] static size_t parent_(size_t i) noexcept { return (i - 1) / 2; }
    [[nodiscard]] static size_t left_(size_t i) noexcept { return 2 * i + 1; }
    [[nodiscard]] static size_t right_(size_t i) noexcept { return 2 * i + 2; }

    void sift_up_(size_t i) {
        while (i > 0) {
            const size_t p = parent_(i);
            if (!comp_(data_[i], data_[p])) {
                break;  // 新元素不比父亲优先权更高，堆序已恢复
            }
            std::swap(data_[i], data_[p]);
            i = p;
        }
    }

    void sift_down_(size_t i) {
        const size_t n = data_.size();
        while (true) {
            size_t best = i;
            const size_t l = left_(i);
            const size_t r = right_(i);
            if (l < n && comp_(data_[l], data_[best])) {
                best = l;
            }
            if (r < n && comp_(data_[r], data_[best])) {
                best = r;
            }
            if (best == i) {
                break;  // 两个孩子都不比自己优先权更高
            }
            std::swap(data_[i], data_[best]);
            i = best;
        }
    }

    void heapify_() {
        // 从最后一个非叶节点起向前下沉；叶子占一半以上、本就满足堆序。
        for (size_t i = data_.size() / 2; i-- > 0;) {
            sift_down_(i);
        }
    }
};

// 堆排序：就地、O(n log n)。先把数组建成最大堆，再反复把根（当前最大值）
// 换到未排序区末尾。全程只需交换用的临时变量，额外空间 O(1)。
inline void heap_sort(std::span<int> a) {
    auto sift = [&](size_t i, size_t n) {
        while (true) {
            size_t best = i;
            const size_t l = 2 * i + 1;
            const size_t r = 2 * i + 2;
            if (l < n && a[l] > a[best]) {
                best = l;
            }
            if (r < n && a[r] > a[best]) {
                best = r;
            }
            if (best == i) {
                break;
            }
            std::swap(a[i], a[best]);
            i = best;
        }
    };

    // 建最大堆：自最后一个非叶节点向前
    for (size_t i = a.size() / 2; i-- > 0;) {
        sift(i, a.size());
    }
    // 根与未排序区末位交换，未排序区缩小 1，根在缩小后的区间内下沉
    for (size_t n = a.size(); n > 1; --n) {
        std::swap(a[0], a[n - 1]);
        sift(0, n - 1);
    }
}

}  // namespace ds

#endif  // DS_BINARY_HEAP_HPP
