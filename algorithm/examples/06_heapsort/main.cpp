// 06 堆排序（CLRS 第 6 章）。结构：06.1 堆的数组表示与树形打印 /
// 06.2 MAX-HEAPIFY 逐步追踪 / 06.3 BUILD-MAX-HEAP（自底向上）/
// 06.4 HEAPSORT 与计数 / 06.5 优先队列四操作（对照 std::priority_queue）。
#ifdef ALGO_NO_PRINT
#include <cstdio>
#include <format>
template <class... A> void print(std::format_string<A...> f, A&&... a) {
    std::printf("%s", std::format(f, std::forward<A>(a)...).c_str()); }
template <class... A> void println(std::format_string<A...> f, A&&... a) {
    std::printf("%s\n", std::format(f, std::forward<A>(a)...).c_str()); }
#else
#include <print>
using std::print;
using std::println;
#endif

#include <algorithm>
#include <cassert>
#include <cstdint>
#include <limits>
#include <queue>
#include <random>
#include <span>
#include <string>
#include <string_view>
#include <vector>

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

struct Counters { long long compares = 0; long long swaps = 0; };

// CLRS 用 1 基下标：PARENT(i)=⌊i/2⌋, LEFT(i)=2i, RIGHT(i)=2i+1。
// C++ 惯用 0 基：parent=(i-1)/2, left=2i+1, right=2i+2 —— 数学上同构，
// 只是偏移 1。本例用 0 基。
static std::size_t parent(std::size_t i) { return (i - 1) / 2; }
static std::size_t left(std::size_t i) { return 2 * i + 1; }
static std::size_t right(std::size_t i) { return 2 * i + 2; }

// ═══ 06.1 数组表示与树形打印 ═══
// CLRS 图 6.1 的最大堆（0 基）：
static const std::vector<int> kFig61{15, 13, 9, 5, 12, 8, 7, 4, 0, 6, 2, 1};

static void print_heap_tree(std::span<const int> a, std::string_view title) {
    println("{}（数组视图）: {}", title, [&] {
        std::string s = "[";
        for (std::size_t i = 0; i < a.size(); ++i) {
            s += (i == 0 ? "" : " ");
            s += std::to_string(a[i]);
        }
        return s + "]";
    }());
    // 树形打印（每层一行，宽度对齐是确定性的）
    std::size_t level = 0, levelStart = 0;
    while (levelStart < a.size()) {
        const std::size_t levelEnd = std::min(a.size(), levelStart + (std::size_t(1) << level));
        print("  深度 {}: ", level);
        for (std::size_t i = levelStart; i < levelEnd; ++i) {
            print("{} ", a[i]);
        }
        println("");
        levelStart = levelEnd;
        ++level;
    }
}

static void heap_layout_demo() {
    print_heap_tree(kFig61, "图 6.1 的最大堆");
    assert(std::ranges::is_heap(kFig61)); // std::ranges 自带堆性质检查
    // 父子下标关系抽查
    assert(parent(1) == 0 && parent(2) == 0);
    assert(left(0) == 1 && right(0) == 2);
    assert(parent(5) == 2 && left(2) == 5 && right(2) == 6);
    println("下标关系：parent(i)=(i-1)/2, left=2i+1, right=2i+2（0 基版 CLRS PARENT/LEFT/RIGHT）");
}

// ═══ 06.2 MAX-HEAPIFY ═══
// 前提：i 的左右子树都是最大堆，只有 i 可能违反。让 a[i]「下沉」。
// CLRS 图 6.2 的例子（1 基改 0 基）：i=0 违反。
static void max_heapify(std::span<int> a, std::size_t i, Counters& c) {
    while (true) {
        std::size_t largest = i;
        const std::size_t l = left(i), r = right(i);
        if (l < a.size()) {
            ++c.compares;
            if (a[l] > a[largest]) { largest = l; }
        }
        if (r < a.size()) {
            ++c.compares;
            if (a[r] > a[largest]) { largest = r; }
        }
        if (largest == i) { break; }
        std::swap(a[i], a[largest]);
        ++c.swaps;
        i = largest; // 迭代下沉（CLRS 递归版的循环等价物）
    }
}

static void heapify_demo() {
    std::vector<int> a{16, 4, 10, 14, 7, 9, 3, 2, 8, 1}; // 图 6.2 数据
    Counters c{};
    println("MAX-HEAPIFY 追踪（图 6.2 数据 [16,4,10,14,7,9,3,2,8,1]，i=1 的 4 违反）：");
    max_heapify(a, 1, c);
    print_heap_tree(a, "  修复后");
    assert(std::ranges::is_heap(a));
    println("  下沉比较 {} 次，交换 {} 次（4 的下沉路径：换 14，再换 8，成为叶）",
            c.compares, c.swaps);
    // 手工核：4 与孩子 14/7 比（2 次）换 14；4 与孩子 8/2 比（2 次）换 8；4 成叶停
    assert(c.compares == 4 && c.swaps == 2);
}

// ═══ 06.3 BUILD-MAX-HEAP ═══
// 自底向上：叶已是平凡堆，从最后一个内部节点（⌊n/2⌋-1，0 基）倒着 heapify。
static void build_max_heap(std::span<int> a, Counters& c) {
    for (std::size_t i = a.size() / 2; i-- > 0;) {
        max_heapify(a, i, c);
    }
}

static void build_demo() {
    std::vector<int> a{4, 1, 3, 2, 16, 9, 10, 14, 8, 7}; // 图 6.3
    Counters c{};
    println("BUILD-MAX-HEAP（图 6.3 数据 [4,1,3,2,16,9,10,14,8,7]）：");
    build_max_heap(a, c);
    print_heap_tree(a, "  建堆结果");
    assert(std::ranges::is_heap(a));
    assert(a[0] == 16);
    println("  建堆比较 {} 次，交换 {} 次（≤ O(n) 的紧例：倒序输入在建堆时几乎不交换）",
            c.compares, c.swaps);
}

// ═══ 06.4 HEAPSORT ═══
static void heapsort(std::span<int> a, Counters& c) {
    build_max_heap(a, c);
    for (std::size_t end = a.size() - 1; end > 0; --end) {
        std::swap(a[0], a[end]); // 最大值就位
        ++c.swaps;
        max_heapify(a.first(end), 0, c); // 堆缩小后修复根
    }
}

static void heapsort_demo() {
    std::vector<int> a{4, 1, 3, 2, 16, 9, 10, 14, 8, 7};
    Counters c{};
    heapsort(a, c);
    print("HEAPSORT 排序结果: ");
    for (auto v : a) { print("{} ", v); }
    println("");
    assert(std::ranges::is_sorted(a));

    // 与插入排序的计数对比（固定随机排列）
    const int n = 1000;
    std::vector<int> v(n);
    for (int i = 0; i < n; ++i) { v[static_cast<std::size_t>(i)] = i; }
    std::mt19937 rng{5489};
    for (int i = n - 1; i > 0; --i) {
        std::swap(v[static_cast<std::size_t>(i)],
                  v[static_cast<std::size_t>(rand_below(rng, static_cast<std::uint32_t>(i) + 1))]);
    }
    auto v2 = v;
    Counters ch{}, ci{};
    heapsort(v, ch);
    // 插入排序（第 2 章）
    for (std::size_t j = 1; j < v2.size(); ++j) {
        int key = v2[j];
        std::size_t i = j;
        while (i > 0 && (++ci.compares, v2[i - 1] > key)) {
            v2[i] = v2[i - 1];
            --i;
        }
        v2[i] = key;
    }
    assert(v == v2);
    println("n={} 随机排列：heapsort 比较 {}（~2n·lg n = {}），插入排序比较 {}",
            n, ch.compares, 2LL * n * 10, ci.compares);
}

// ═══ 06.5 优先队列 ═══
// 四操作：HEAP-MAXIMUM / HEAP-EXTRACT-MAX / HEAP-INCREASE-KEY / MAX-HEAP-INSERT
struct MaxPriorityQueue {
    std::vector<int> heap;
    Counters c{};

    int top() const { return heap.front(); }

    int extract_max() {
        assert(!heap.empty());
        const int max = heap.front();
        heap.front() = heap.back();
        heap.pop_back();
        if (!heap.empty()) { max_heapify(heap, 0, c); }
        return max;
    }

    void increase_key(std::size_t i, int key) {
        assert(heap[i] <= key);
        heap[i] = key;
        while (i > 0 && (++c.compares, heap[parent(i)] < heap[i])) {
            std::swap(heap[i], heap[parent(i)]);
            ++c.swaps;
            i = parent(i);
        }
    }

    void insert(int key) {
        heap.push_back(std::numeric_limits<int>::min());
        increase_key(heap.size() - 1, key);
    }
};

static void pq_demo() {
    MaxPriorityQueue q;
    for (int v : {4, 1, 3, 2, 16, 9, 10, 14, 8, 7}) { q.insert(v); }
    assert(std::ranges::is_heap(q.heap));
    println("优先队列：插入 4 1 3 2 16 9 10 14 8 7 后堆顶 = {}", q.top());

    // 先定位值 8 的下标（insert 序列决定的堆布局不是肉眼可推的）
    const auto pos8 = static_cast<std::size_t>(
        std::ranges::find(q.heap, 8) - q.heap.begin());
    q.increase_key(pos8, 20); // 把值 8 提升为 20
    assert(std::ranges::is_heap(q.heap));
    println("increase-key(值 8 → 20) 后堆顶 = {}（20 上浮）", q.top());

    // 与 std::priority_queue 同操作序列对账（弹出顺序必须一致）
    std::priority_queue<int> ref;
    for (int v : {4, 1, 3, 2, 16, 9, 10, 14, 8, 7}) { ref.push(v); }
    // ref 侧复现 increase_key(值 8 → 20)：std::priority_queue 不支持，
    // 用「移除再插入」模拟（弹出序列等价）
    {
        std::vector<int> buf;
        bool removed = false;
        while (!ref.empty()) {
            int t = ref.top();
            ref.pop();
            if (!removed && t == 8) { removed = true; continue; }
            buf.push_back(t);
        }
        for (int t : buf) { ref.push(t); }
        ref.push(20);
    }
    print("弹出顺序: ");
    std::vector<int> mine, theirs;
    while (!q.heap.empty()) {
        mine.push_back(q.extract_max());
        print("{} ", mine.back());
    }
    println("");
    while (!ref.empty()) { theirs.push_back(ref.top()); ref.pop(); }
    assert(mine == theirs);
    println("与 std::priority_queue 弹出序列逐元素一致 = 1");
}

int main() {
    heap_layout_demo();
    heapify_demo();
    build_demo();
    heapsort_demo();
    pq_demo();
    println("自检通过");
    return 0;
}
