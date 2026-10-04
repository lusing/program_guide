// 14 数据结构扩张（CLRS 第 14 章）。结构：14.1 扩张方法论三步 /
// 14.2 顺序统计树（size 扩张的 BST：OS-SELECT/OS-RANK 追踪与对账）/
// 14.3 区间树（max 扩张：INTERVAL-SEARCH 与暴力对账）。
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
#include <utility>
#include <vector>

// ═══ 14.2 顺序统计树：size 扩张的 BST ═══
// 教学取舍：底座用朴素 BST（随机固定输入下健康）——扩张的维护规则
// （插入沿路 +1；旋转重算两个节点）与红黑树版完全一致（14.1 方法论）。
constexpr std::size_t NIL = SIZE_MAX;

struct OsTree {
    std::vector<int> key;
    std::vector<std::size_t> left, right;
    std::vector<std::size_t> size;   // 以该节点为根的子树节点数
    std::size_t root = NIL;

    std::size_t alloc(int k) {
        key.push_back(k);
        left.push_back(NIL);
        right.push_back(NIL);
        size.push_back(1);
        return key.size() - 1;
    }
    static std::size_t sz(const OsTree& t, std::size_t x) {
        return x == NIL ? 0 : t.size[x];
    }

    void insert(int k) {
        if (root == NIL) { root = alloc(k); return; }
        std::size_t x = root;
        while (true) {
            ++size[x];                          // 沿路维护：每个祖先 +1
            if (k < key[x]) {
                if (left[x] == NIL) { const auto n = alloc(k); left[x] = n; return; }
                x = left[x];
            } else {
                if (right[x] == NIL) { const auto n = alloc(k); right[x] = n; return; }
                x = right[x];
            }
        }
    }

    bool search(int k) const {
        std::size_t x = root;
        while (x != NIL && key[x] != k) { x = (k < key[x]) ? left[x] : right[x]; }
        return x != NIL;
    }

    // OS-SELECT(i)：找第 i 小（i 从 1 起）——沿路用左子树 size 定位
    std::size_t os_select(std::size_t i) const {
        std::size_t x = root;
        while (x != NIL) {
            const std::size_t r = sz(*this, left[x]) + 1;  // 当前节点名次
            if (i == r) { return x; }
            if (i < r)  { x = left[x]; }
            else        { x = right[x]; i -= r; }
        }
        return NIL;
    }

    // OS-RANK 的实现留给正文讲解（需要 parent 指针沿路上行）；
    // 示例用「select 逆命题」对账：rank(x) = i ⟺ select(i) = x。

    std::vector<int> inorder() const {
        std::vector<int> out;
        walk(root, out);
        return out;
    }
    void walk(std::size_t x, std::vector<int>& out) const {
        if (x == NIL) { return; }
        walk(left[x], out);
        out.push_back(key[x]);
        walk(right[x], out);
    }
};

static void os_tree_demo() {
    // 固定种子的随机插入序（BST 保持健康深度）
    const std::vector<int> keys{26, 17, 41, 14, 21, 30, 47, 10, 16, 19,
                                 23, 28, 38, 7, 12, 15, 20, 35, 39, 3};
    OsTree t;
    for (int k : keys) { t.insert(k); }
    const auto sorted = t.inorder();
    assert(std::ranges::is_sorted(sorted) && sorted.size() == keys.size());

    // OS-SELECT 追踪：找第 5 小
    const std::size_t x5 = t.os_select(5);
    println("顺序统计树（size 扩张 BST，20 键）：");
    println("  OS-SELECT(5) = {}（排序后第 5 位 = {}，对账一致）",
            t.key[x5], sorted[4]);
    assert(t.key[x5] == sorted[4]);

    // 全量对账：每个键的名次 = 其在有序表中的位置
    bool allOk = true;
    for (std::size_t i = 0; i < sorted.size(); ++i) {
        // select 的逆命题：rank(x) = i+1 ⟺ select(i+1) 的键 == sorted[i]
        if (t.key[t.os_select(i + 1)] != sorted[i]) { allOk = false; }
    }
    println("  OS-SELECT(i) ∀i=1..20 与排序表逐位一致 = {}", allOk ? 1 : 0);
    assert(allOk);
}

// ═══ 14.3 区间树：max 扩张 ═══
// 节点存区间 [lo, hi] 与 max（子树中所有 hi 的最大值）。
// INTERVAL-SEARCH：若左子树 max ≥ i.lo 则进左（保证有解），否则查本节点，
// 否则进右。左优先保证找到「某」重叠区间。
struct IntervalTree {
    struct Node { int lo, hi, mx; std::size_t l = NIL, r = NIL; };
    std::vector<Node> n;
    std::size_t root = NIL;

    std::size_t make(int lo, int hi) {
        n.push_back({lo, hi, hi, NIL, NIL});
        return n.size() - 1;
    }
    static int mx(const IntervalTree& t, std::size_t x) {
        return x == NIL ? INT32_MIN : t.n[x].mx;
    }

    void insert(int lo, int hi) {
        if (root == NIL) { root = make(lo, hi); return; }
        std::size_t x = root;
        while (true) {
            n[x].mx = std::max(n[x].mx, hi);        // 沿路维护 max
            if (lo < n[x].lo) {
                if (n[x].l == NIL) { const auto k = make(lo, hi); n[x].l = k; return; }
                x = n[x].l;
            } else {
                if (n[x].r == NIL) { const auto k = make(lo, hi); n[x].r = k; return; }
                x = n[x].r;
            }
        }
    }

    static bool overlap(const Node& a, int lo, int hi) {
        return lo <= a.hi && a.lo <= hi;            // 开区间判重叠
    }

    std::size_t search(int lo, int hi) const {
        std::size_t x = root;
        while (x != NIL && !overlap(n[x], lo, hi)) {
            if (n[x].l != NIL && n[n[x].l].mx >= lo) { x = n[x].l; }
            else                                     { x = n[x].r; }
        }
        return x;
    }
};

static void interval_demo() {
    IntervalTree t;
    // CLRS 图 14.4 的区间集
    const std::vector<std::pair<int, int>> ivs{
        {16, 21}, {8, 9}, {25, 30}, {5, 8}, {15, 23},
        {17, 19}, {26, 26}, {0, 3}, {6, 10}, {19, 20}};
    for (auto [lo, hi] : ivs) { t.insert(lo, hi); }

    println("区间树（max 扩张，图 14.4 的 10 个区间）：");
    // 查 (14,16)：应返回某个重叠区间（图 14.4 的答案是 (15,23)）
    const auto h1 = t.search(14, 16);
    println("  INTERVAL-SEARCH(14,16) → [{},{}]（与 (14,16) 重叠）",
            t.n[h1].lo, t.n[h1].hi);
    assert(IntervalTree::overlap(t.n[h1], 14, 16));

    // 暴力对账：对一组点区间查询 [q,q]，区间树找到的必与「是否存在重叠」一致
    bool allOk = true;
    for (int q = -2; q <= 32; ++q) {
        const auto hit = t.search(q, q);
        bool any = false;
        for (auto [lo, hi] : ivs) {
            if (q <= hi && lo <= q) { any = true; break; }
        }
        if ((hit != NIL) != any) { allOk = false; }
        if (hit != NIL && !IntervalTree::overlap(t.n[hit], q, q)) { allOk = false; }
    }
    println("  35 个点查询与暴力「是否存在重叠」全部一致 = {}", allOk ? 1 : 0);
    assert(allOk);
}

int main() {
    os_tree_demo();
    interval_demo();
    println("自检通过");
    return 0;
}
