// 14 数据结构扩张（CLRS 第 14 章）。结构：14.1 扩张方法论三步 /
// 14.2 顺序统计树（size 扩张的 BST：OS-SELECT/OS-RANK 追踪与对账）/
// 14.3 区间树（max 扩张：INTERVAL-SEARCH 与暴力对账）/
// 14.4 三维 Fenwick：点更新 O(lg³n)、盒求和（前缀容差八顶点）。
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
#include <random>
#include <utility>
#include <vector>

// 可移植随机（docs/01 的纪律：不用 uniform_int_distribution）
static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

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

// ═══ 14.4 三维 Fenwick：点更新与盒求和 ═══
// 一维 Fenwick 的每个下标管一段「lowbit 区间」；前缀和沿 i−=i&−i 收拢。
// 三维就是三套下标各走各的 lowbit：点更新影响 O(lg³n) 个格子，
// 前缀和同样 O(lg³n)。任意盒 [x1..x2]×[y1..y2]×[z1..z2] 的和由八个
// 前缀容差得到（0 坐标的前缀天然为 0，循环不执行）。
struct Fenwick3D {
    int side;                       // n
    int stride;                     // n+1：行/层跨度（下标从 1 起）
    std::vector<long long> tree;

    explicit Fenwick3D(int n) : side(n), stride(n + 1) {
        tree.assign(static_cast<std::size_t>(stride) * stride * stride, 0);
    }
    std::size_t at(int i, int j, int k) const {
        return (static_cast<std::size_t>(i) * stride + j) * stride + k;
    }

    void add(int x, int y, int z, long long delta) {
        for (int i = x; i <= side; i += i & -i)
            for (int j = y; j <= side; j += j & -j)
                for (int k = z; k <= side; k += k & -k) {
                    tree[at(i, j, k)] += delta;
                }
    }

    // [1..x]×[1..y]×[1..z] 的和；含 0 的坐标直接贡献空区间
    long long prefix(int x, int y, int z) const {
        long long sum = 0;
        for (int i = x; i > 0; i -= i & -i)
            for (int j = y; j > 0; j -= j & -j)
                for (int k = z; k > 0; k -= k & -k) {
                    sum += tree[at(i, j, k)];
                }
        return sum;
    }

    long long box(int x1, int y1, int z1, int x2, int y2, int z2) const {
        // 八顶点容差：奇数次 (−1) 前缀取负，偶数次取正
        return prefix(x2, y2, z2)
             - prefix(x1 - 1, y2, z2) - prefix(x2, y1 - 1, z2)
             - prefix(x2, y2, z1 - 1)
             + prefix(x1 - 1, y1 - 1, z2) + prefix(x1 - 1, y2, z1 - 1)
             + prefix(x2, y1 - 1, z1 - 1)
             - prefix(x1 - 1, y1 - 1, z1 - 1);
    }
};

// 稠密 3D 数组暴力版（只用于小 n 对账）
struct Dense3D {
    int side;
    std::vector<long long> a;
    explicit Dense3D(int n) : side(n),
        a(static_cast<std::size_t>(n + 1) * (n + 1) * (n + 1), 0) {}
    long long& at(int i, int j, int k) {
        return a[(static_cast<std::size_t>(i) * (side + 1) + j) *
                 (side + 1) + k];
    }
    void add(int x, int y, int z, long long d) { at(x, y, z) += d; }
    long long box(int x1, int y1, int z1, int x2, int y2, int z2) {
        long long s = 0;
        for (int i = x1; i <= x2; ++i)
            for (int j = y1; j <= y2; ++j)
                for (int k = z1; k <= z2; ++k) { s += at(i, j, k); }
        return s;
    }
};

static void fenwick3d_demo() {
    println("三维 Fenwick（2-2）：点更新 O(lg^3 n)，盒求和八顶点容差：");
    Fenwick3D fw(10);
    // 书内样例的指令流
    fw.add(1, 1, 4, 5);
    fw.add(2, 5, 4, 5);
    long long q1 = fw.box(1, 1, 1, 10, 10, 10);
    fw.add(3, 4, 5, -34);
    long long q2 = fw.box(1, 1, 1, 10, 10, 10);
    println("  两次加法后整盒：{}；再减 34 后：{}（样例答案 10、-24）", q1, q2);
    assert(q1 == 10 && q2 == -24);

    // 随机对账：小立方体上的稠密版 vs Fenwick
    std::mt19937 rng{5489};
    const int n = 14;
    Fenwick3D fast(n);
    Dense3D brute(n);
    int mismatches = 0;
    for (int t = 0; t < 3000; ++t) {
        const bool isUpdate = rand_below(rng, 2) == 0;
        if (isUpdate) {
            const int x = 1 + static_cast<int>(rand_below(rng, n));
            const int y = 1 + static_cast<int>(rand_below(rng, n));
            const int z = 1 + static_cast<int>(rand_below(rng, n));
            const long long d =
                static_cast<long long>(rand_below(rng, 21)) - 10;
            fast.add(x, y, z, d);
            brute.add(x, y, z, d);
        } else {
            int x1 = 1 + static_cast<int>(rand_below(rng, n));
            int y1 = 1 + static_cast<int>(rand_below(rng, n));
            int z1 = 1 + static_cast<int>(rand_below(rng, n));
            int x2 = 1 + static_cast<int>(rand_below(rng, n));
            int y2 = 1 + static_cast<int>(rand_below(rng, n));
            int z2 = 1 + static_cast<int>(rand_below(rng, n));
            if (x1 > x2) { std::swap(x1, x2); }
            if (y1 > y2) { std::swap(y1, y2); }
            if (z1 > z2) { std::swap(z1, z2); }
            if (fast.box(x1, y1, z1, x2, y2, z2) !=
                brute.box(x1, y1, z1, x2, y2, z2)) { ++mismatches; }
        }
    }
    println("  随机 3000 操作（更新/盒查询混合）对账：不一致 {} 例", mismatches);
    assert(mismatches == 0);
}

int main() {
    os_tree_demo();
    interval_demo();
    fenwick3d_demo();
    println("自检通过");
    return 0;
}
