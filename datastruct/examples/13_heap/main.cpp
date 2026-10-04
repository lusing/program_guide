#include <cassert>
#include <functional>
#include <print>
#include <vector>

#include "binary_heap.hpp"

// 13 堆：逐插入与堆序检查、heapify 后出队序列、堆排序

int main() {
    // ═══ 最小堆逐插入：每步插入后堆序都必须成立 ═══
    {
        ds::BinaryHeap<int> heap;
        const int inputs[] = {5, 3, 8, 1, 9, 2, 7};
        for (int x : inputs) {
            heap.push(x);
            assert(heap.is_heap());
        }
        assert(heap.size() == 7);
        assert(heap.top() == 1);
        std::println("逐插入 7 个元素：每次插入后 is_heap 成立，堆顶为 {}", heap.top());

        // 空堆 top/pop 属于编程错误，应抛异常
        bool threw = false;
        try {
            ds::BinaryHeap<int> empty;
            empty.pop();
        } catch (const std::runtime_error&) {
            threw = true;
        }
        assert(threw);
        std::println("空堆 pop 抛出异常");
    }

    // ═══ heapify 批量构造，出队序列必须恰为 9,6,5,4,3,2,1,1 ═══
    {
        const int items[] = {3, 1, 4, 1, 5, 9, 2, 6};
        ds::BinaryHeap<int, std::greater<int>> heap{
            std::span<const int>(items)};  // 最大堆
        assert(heap.is_heap());
        assert(heap.top() == 9);

        const int expected[] = {9, 6, 5, 4, 3, 2, 1, 1};
        std::print("最大堆逐个出队：");
        for (int want : expected) {
            assert(heap.top() == want);
            std::print("{} ", heap.top());
            heap.pop();
        }
        assert(heap.empty());
        std::println("");
    }

    // ═══ 堆排序：固定乱序数组升序；再以降序夹具验证 ═══
    {
        int a[] = {3, 1, 4, 1, 5, 9, 2, 6, -3, 0};
        ds::heap_sort(a);
        const int want[] = {-3, 0, 1, 1, 2, 3, 4, 5, 6, 9};
        for (size_t i = 0; i < std::size(a); ++i) {
            assert(a[i] == want[i]);
        }
        std::println("堆排序（乱序夹具）：-3 0 1 1 2 3 4 5 6 9");

        int desc[] = {9, 7, 5, 3, 1, -2};  // 全降序：最大堆已天然成立
        ds::heap_sort(desc);
        const int want2[] = {-2, 1, 3, 5, 7, 9};
        for (size_t i = 0; i < std::size(desc); ++i) {
            assert(desc[i] == want2[i]);
        }
        std::println("堆排序（降序夹具）：-2 1 3 5 7 9");
    }

    std::println("自检通过");
}
