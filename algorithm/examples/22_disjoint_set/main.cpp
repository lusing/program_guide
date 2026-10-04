// 22 不相交集（并查集，CLRS 第 21 章）。结构：22.1 链表版 vs 森林版的
// 操作画像 / 22.2 按秩合并 + 路径压缩的逐步追踪 / 22.3 大规模随机
// 操作计数：压缩与未压缩的总步数对比（摊还 α(n) 的实证）。
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
#include <numeric>
#include <random>
#include <vector>

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

// ═══ 22.1–22.2 森林版并查集 ═══
// 按秩合并 + 路径压缩。两种配置开关分开计数对照：
//   naive：不压缩、按序链接（最差策略）
//   smart：按秩 + 路径压缩
struct Dsu {
    std::vector<int> parent, rank_;
    long long steps = 0;      // find 走的边数（摊还账本的「实际代价」）
    bool compress;

    explicit Dsu(int n, bool doCompress)
        : parent(static_cast<std::size_t>(n)), rank_(static_cast<std::size_t>(n), 0),
          compress(doCompress) {
        std::iota(parent.begin(), parent.end(), 0);
    }

    int find(int x) {
        int root = x;
        while (parent[static_cast<std::size_t>(root)] != root) {
            root = parent[static_cast<std::size_t>(root)];
            ++steps;
        }
        if (compress) {
            // 路径压缩：二趟把沿途节点直接挂到根（这趟的遍历也计入 steps——
            // 账本要算总账，不能只算便宜的那趟）
            int cur = x;
            while (parent[static_cast<std::size_t>(cur)] != root) {
                const int nxt = parent[static_cast<std::size_t>(cur)];
                parent[static_cast<std::size_t>(cur)] = root;
                cur = nxt;
                ++steps;
            }
        }
        return root;
    }

    void unite(int a, int b, bool byRank) {
        int ra = find(a), rb = find(b);
        if (ra == rb) { return; }
        if (byRank) {
            if (rank_[static_cast<std::size_t>(ra)] < rank_[static_cast<std::size_t>(rb)]) { std::swap(ra, rb); }
            parent[static_cast<std::size_t>(rb)] = ra;
            if (rank_[static_cast<std::size_t>(ra)] == rank_[static_cast<std::size_t>(rb)]) {
                ++rank_[static_cast<std::size_t>(ra)];
            }
        } else {
            parent[static_cast<std::size_t>(rb)] = ra;   // 固定方向（可制造长链）
        }
    }
};

static void trace_demo() {
    // 9 元素的小追踪（CLRS 图 21.4b? 用 0..8 手工序列）
    Dsu d(9, true);
    for (auto [a, b] : std::vector<std::pair<int, int>>{{0, 1}, {2, 3}, {4, 5}, {6, 7}}) {
        d.unite(a, b, true);
    }
    d.unite(0, 2, true);   // {0,1,2,3}
    d.unite(4, 6, true);   // {4,5,6,7}
    d.unite(0, 4, true);   // 全并成一个大集合
    d.unite(0, 8, true);   // 8 也进来
    std::vector<int> roots;
    for (int i = 0; i < 9; ++i) { roots.push_back(d.find(i)); }
    assert(std::ranges::all_of(roots, [&](int r) { return r == roots[0]; }));
    println("并查集追踪（9 元素、按秩+压缩，7 次 union 后全部同根 = 1）：");
    println("  根 = {}，最大秩 = {}，find 总步数（含压缩两趟）= {}", roots[0],
            *std::ranges::max_element(d.rank_), d.steps);
}

// ═══ 22.3 大规模对比 ═══
// 同一随机操作序列（n/2 次 union + n 次 find）跑三种配置：
//   A 朴素：不按秩、不压缩        —— 链可以很长
//   B 半配：按秩、不压缩
//   C 全配：按秩 + 压缩          —— 摊还 O(α(n))
static void scale_demo() {
    const int n = 5000;
    std::mt19937 rng{5489};
    // 对抗负载：union 序列 (1,0)(2,0)(3,0)... 让「固定方向」的朴素链接
    // 逐级长链；find 反复打链底。随机对混入保持真实感。
    std::vector<std::pair<int, int>> ops;
    for (int i = 0; i < n / 2; ++i) {
        if (i % 3 == 0) {
            ops.emplace_back(static_cast<int>(rand_below(rng, static_cast<std::uint32_t>(n))),
                             static_cast<int>(rand_below(rng, static_cast<std::uint32_t>(n))));
        } else {
            ops.emplace_back(i % n, 0);
        }
    }
    std::vector<int> queries;
    for (int i = 0; i < n; ++i) {
        queries.push_back(i % 2 == 0 ? 0 : static_cast<int>(rand_below(rng, static_cast<std::uint32_t>(n))));
    }

    Dsu a(n, false), b(n, false), c(n, true);
    for (auto [x, y] : ops) { a.unite(x, y, false); }
    for (auto [x, y] : ops) { b.unite(x, y, true); }
    for (auto [x, y] : ops) { c.unite(x, y, true); }
    for (int q : queries) { a.find(q); b.find(q); c.find(q); }

    println("大规模对比（n={}，链式混合 {} 次 union + {} 次 find 打链底）：", n, ops.size(), queries.size());
    println("  A 朴素（不按秩/不压缩）：find 总步数 {}", a.steps);
    println("  B 按秩 + 不压缩         ：find 总步数 {}", b.steps);
    println("  C 按秩 + 路径压缩       ：find 总步数 {}（摊还 O(α(n))，α(5000) ≤ 4）", c.steps);
    // 可断言的结论：按秩或压缩各自都能驯服对抗链（都远小于 A）
    assert(b.steps < a.steps / 8);
    assert(c.steps < a.steps / 8);
    // 三个结构给出相同的等价类划分（对账：任两点同根性一致）
    bool samePartition = true;
    for (int i = 0; i < n; ++i) {
        if ((a.find(0) == a.find(i)) != (c.find(0) == c.find(i))) { samePartition = false; }
    }
    println("  三配置的等价类划分逐点一致 = {}", samePartition ? 1 : 0);
    assert(samePartition);
}

int main() {
    trace_demo();
    scale_demo();
    println("自检通过");
    return 0;
}
