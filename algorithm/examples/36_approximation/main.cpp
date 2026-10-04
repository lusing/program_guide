// 36 近似算法（CLRS 第 35 章）。结构：36.1 顶点覆盖的 2-近似
//（极大匹配贪心 vs 暴力最优）/ 36.2 度量 TSP 的 2-近似（MST 先行序
// vs 暴力最优）/ 36.3 集合覆盖的贪心（ln 近似的实测比值）。
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
#include <array>
#include <bit>
#include <cassert>
#include <cstdint>
#include <numeric>
#include <vector>

// ═══ 36.1 顶点覆盖 2-近似 ═══
// APPROX-VERTEX-COVER：反复任取一条未覆盖边，把两端都放进覆盖。
// 极大匹配 ≥ OPT/2（每条匹配边至少要一个端点入最优覆盖）⇒ 2-近似。
static std::vector<int> approx_vertex_cover(int n,
                                            const std::vector<std::pair<int, int>>& edges) {
    std::vector<char> covered(edges.size(), 0);
    std::vector<char> inCover(static_cast<std::size_t>(n), 0);
    std::vector<int> cover;
    for (std::size_t i = 0; i < edges.size(); ++i) {
        if (covered[i]) { continue; }
        const auto [u, v] = edges[i];
        for (auto x : {u, v}) {
            if (!inCover[static_cast<std::size_t>(x)]) {
                inCover[static_cast<std::size_t>(x)] = 1;
                cover.push_back(x);
            }
        }
        // 与 (u,v) 相邻的边全部标记已覆盖
        for (std::size_t j = 0; j < edges.size(); ++j) {
            if (edges[j].first == u || edges[j].second == u ||
                edges[j].first == v || edges[j].second == v) {
                covered[j] = 1;
            }
        }
    }
    return cover;
}

static int brute_vertex_cover(int n, const std::vector<std::pair<int, int>>& edges) {
    const int full = 1 << n;
    int best = n;
    for (int mask = 0; mask < full; ++mask) {
        bool ok = true;
        for (auto [u, v] : edges) {
            if (!((mask >> u) & 1) && !((mask >> v) & 1)) { ok = false; break; }
        }
        if (ok) {
            best = std::min(best, std::popcount(static_cast<unsigned>(mask)));
        }
    }
    return best;
}

static void vertex_cover_demo() {
    // 7 顶点小图
    const std::vector<std::pair<int, int>> edges{
        {0, 1}, {0, 2}, {1, 3}, {2, 3}, {2, 4}, {3, 5}, {4, 5}, {4, 6}};
    const auto cover = approx_vertex_cover(7, edges);
    // 验证它真是覆盖
    bool isCover = true;
    for (auto [u, v] : edges) {
        const bool in = (std::ranges::find(cover, u) != cover.end()) ||
                        (std::ranges::find(cover, v) != cover.end());
        if (!in) { isCover = false; }
    }
    const int opt = brute_vertex_cover(7, edges);
    println("顶点覆盖 2-近似（8 边 7 点图）：贪心覆盖 {} 点（合法性 = {}），暴力最优 = {}，"
            "比值 = {:.2f}（≤ 2 保证）",
            cover.size(), isCover ? 1 : 0, opt,
            static_cast<double>(cover.size()) / opt);
    assert(isCover);
    assert(static_cast<int>(cover.size()) <= 2 * opt);
}

// ═══ 36.2 度量 TSP 的 2-近似 ═══
// APPROX-TSP-TOUR：MST 先根先序走一遍。代价 ≤ 2·OPT
//（先序走 = MST 每边走两次的捷径化；度量性保证捷径不增）。
// 距离取曼哈顿（L1）：满足三角不等式（2-近似的证明前提）且全程整数
//——平方欧氏不是度量，不能用于本断言（数值纪律 + 正确性纪律双重要求）。
struct Pt { long long x, y; };
static long long d2(Pt a, Pt b) {
    const long long dx = a.x > b.x ? a.x - b.x : b.x - a.x;
    const long long dy = a.y > b.y ? a.y - b.y : b.y - a.y;
    return dx + dy;
}

// MST（Prim）+ 顶点 0 先序
static std::vector<int> mst_preorder(const std::vector<Pt>& pts) {
    const int n = static_cast<int>(pts.size());
    std::vector<char> inTree(static_cast<std::size_t>(n), 0);
    std::vector<long long> key(static_cast<std::size_t>(n), INT64_MAX);
    std::vector<int> parent(static_cast<std::size_t>(n), -1);
    key[0] = 0;
    for (int it = 0; it < n; ++it) {
        int u = -1;
        for (int v = 0; v < n; ++v) {
            if (!inTree[static_cast<std::size_t>(v)] &&
                (u == -1 || key[static_cast<std::size_t>(v)] < key[static_cast<std::size_t>(u)])) {
                u = v;
            }
        }
        inTree[static_cast<std::size_t>(u)] = 1;
        for (int v = 0; v < n; ++v) {
            if (!inTree[static_cast<std::size_t>(v)]) {
                const long long w = d2(pts[static_cast<std::size_t>(u)], pts[static_cast<std::size_t>(v)]);
                if (w < key[static_cast<std::size_t>(v)]) {
                    key[static_cast<std::size_t>(v)] = w;
                    parent[static_cast<std::size_t>(v)] = u;
                }
            }
        }
    }
    // 先序（孩子表 DFS）
    std::vector<std::vector<int>> ch(static_cast<std::size_t>(n));
    for (int v = 1; v < n; ++v) { ch[static_cast<std::size_t>(parent[static_cast<std::size_t>(v)])].push_back(v); }
    std::vector<int> order;
    auto dfs = [&](this auto&& self, int u) -> void {
        order.push_back(u);
        for (int c : ch[static_cast<std::size_t>(u)]) { self(c); }
    };
    dfs(0);
    return order;
}

static long long tour_len(const std::vector<Pt>& pts, const std::vector<int>& order) {
    long long total = 0;
    for (std::size_t i = 0; i < order.size(); ++i) {
        total += d2(pts[static_cast<std::size_t>(order[i])],
                    pts[static_cast<std::size_t>(order[(i + 1) % order.size()])]);
    }
    return total;
}

static long long brute_tsp(const std::vector<Pt>& pts) {
    const int n = static_cast<int>(pts.size());
    std::vector<int> perm(static_cast<std::size_t>(n));
    std::iota(perm.begin(), perm.end(), 0);
    long long best = INT64_MAX;
    do {
        best = std::min(best, tour_len(pts, perm));
    } while (std::next_permutation(perm.begin() + 1, perm.end()));
    return best;
}

static void tsp_demo() {
    const std::vector<Pt> pts{{0, 0}, {4, 1}, {6, 5}, {2, 6}, {1, 3}};
    const auto tour = mst_preorder(pts);
    const long long approxLen = tour_len(pts, tour);
    const long long optLen = brute_tsp(pts);
    println("度量 TSP 2-近似（5 点平面图，曼哈顿距离口径）：");
    print("  近似先序: ");
    for (int v : tour) { print("{} ", v); }
    println("");
    println("  近似长 {} vs 暴力最优 {}，比值 = {:.2f}（≤ 2 保证）",
            approxLen, optLen, static_cast<double>(approxLen) / static_cast<double>(optLen));
    assert(approxLen <= 2 * optLen);
    assert(tour.size() == pts.size());
}

// ═══ 36.3 集合覆盖贪心 ═══
// 每轮选覆盖新元素最多的集合；H_n 近似（ln n）。与暴力最优对比。
static void set_cover_demo() {
    // 全域 {0..11}，6 个集合
    const std::vector<std::vector<int>> sets{
        {0, 1, 2, 3}, {2, 4, 5}, {1, 6, 7, 8}, {3, 9}, {8, 10, 11}, {5, 9, 10}};
    const int universe = 12;
    std::vector<char> covered(static_cast<std::size_t>(universe), 0);
    std::vector<int> chosen;
    int coveredCount = 0;
    while (coveredCount < universe) {
        int bestSet = -1, bestGain = 0;
        for (std::size_t s = 0; s < sets.size(); ++s) {
            if (std::ranges::find(chosen, static_cast<int>(s)) != chosen.end()) { continue; }
            int gain = 0;
            for (int e : sets[s]) {
                if (!covered[static_cast<std::size_t>(e)]) { ++gain; }
            }
            if (gain > bestGain) { bestGain = gain; bestSet = static_cast<int>(s); }
        }
        assert(bestSet >= 0);   // 全域可覆盖
        chosen.push_back(bestSet);
        for (int e : sets[static_cast<std::size_t>(bestSet)]) {
            if (!covered[static_cast<std::size_t>(e)]) { covered[static_cast<std::size_t>(e)] = 1; ++coveredCount; }
        }
    }
    // 暴力最优：枚举子集
    const int m = static_cast<int>(sets.size());
    int opt = m;
    for (int mask = 1; mask < (1 << m); ++mask) {
        std::vector<char> cov(static_cast<std::size_t>(universe), 0);
        int cnt = 0;
        for (int s = 0; s < m; ++s) {
            if ((mask >> s) & 1) {
                for (int e : sets[static_cast<std::size_t>(s)]) {
                    if (!cov[static_cast<std::size_t>(e)]) { cov[static_cast<std::size_t>(e)] = 1; ++cnt; }
                }
            }
        }
        if (cnt == universe) { opt = std::min(opt, std::popcount(static_cast<unsigned>(mask))); }
    }
    println("集合覆盖贪心（全域 12 元素，6 集合）：贪心选 {} 个，暴力最优 = {}，"
            "H_6 ≈ 2.45 为理论界",
            chosen.size(), opt);
    assert(static_cast<int>(chosen.size()) <= opt * 245 / 100);   // ln 界的整化
}

int main() {
    vertex_cover_demo();
    tsp_demo();
    set_cover_demo();
    println("自检通过");
    return 0;
}
