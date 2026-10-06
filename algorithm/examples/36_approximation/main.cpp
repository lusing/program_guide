// 36 近似算法（CLRS 第 35 章）。结构：36.1 顶点覆盖的 2-近似
//（极大匹配贪心 vs 暴力最优）/ 36.2 度量 TSP 的 2-近似（MST 先行序
// vs 暴力最优）/ 36.3 集合覆盖的贪心（ln 近似的实测比值）/
// 36.4 装箱：First-Fit / FFD / Best-Fit（与 DFS 精确最优对账）。
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
#include <random>
#include <set>
#include <vector>

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    return static_cast<std::uint32_t>(
        (static_cast<std::uint64_t>(rng()) * n) >> 32);
}

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

// ═══ 36.4 装箱 ═══
// n 件物品（尺寸 1..C），容量 C 的箱子，求最少箱子数。NP 难——本节给
// 三个在线/离线贪心和一个小规模精确解。
static constexpr int kCap = 100;

// First-Fit（原序）：线性扫描已有箱子，第一个放得下就放；都放不下开新箱。
static int first_fit(const std::vector<int>& items, std::vector<int>& bins) {
    std::vector<int> rem;                 // 每箱剩余容量
    bins.assign(1, -1);                   // 每箱首件（演示用）
    for (int s : items) {
        std::size_t b = 0;
        for (; b < rem.size(); ++b) { if (rem[b] >= s) { break; } }
        if (b == rem.size()) { rem.push_back(kCap - s); bins.push_back(s); }
        else { rem[b] -= s; }
    }
    return static_cast<int>(rem.size());
}

// FFD：降序后 First-Fit。经典保证 FFD ≤ (11/9)OPT + 6/9。
static int first_fit_decreasing(std::vector<int> items) {
    std::ranges::sort(items, std::greater<int>{});
    std::vector<int> bins;
    return first_fit(items, bins);
}

// Best-Fit：放进「剩余容量最小但放得下」的箱子——multiset 对剩余容量
// lower_bound(s)，O(log 箱数) 一次，整体 O(n log n)。
static int best_fit(const std::vector<int>& items) {
    std::multiset<int> rem;
    for (int s : items) {
        auto it = rem.lower_bound(s);
        if (it == rem.end()) { rem.insert(kCap - s); }
        else {
            const int left = *it - s;
            rem.erase(it);
            rem.insert(left);
        }
    }
    return static_cast<int>(rem.size());
}

// 精确解：箱子数下界 k0=⌈Σ/C⌉ 起逐个试，DFS 把物品分进 k 个箱子。
// 对称破缺：新物品优先放进已有箱子，空箱只试第一个。n≤12 足够快。
static bool pack_dfs(const std::vector<int>& items, int k, int idx,
                     std::vector<int>& rem) {
    if (idx == static_cast<int>(items.size())) { return true; }
    const int s = items[static_cast<std::size_t>(idx)];
    int prev_rem = -1;                    // 相同剩余容量的箱子只试一次
    for (int b = 0; b < k; ++b) {
        if (rem[b] < s || rem[b] == prev_rem) { continue; }
        prev_rem = rem[b];
        rem[b] -= s;
        if (pack_dfs(items, k, idx + 1, rem)) { return true; }
        rem[b] += s;
        if (rem[b] == kCap) { break; }    // 空箱放过就别再试后面的空箱
    }
    return false;
}

static int bin_packing_optimal(const std::vector<int>& items) {
    int total = 0;
    for (int s : items) { total += s; }
    int k = (total + kCap - 1) / kCap;
    while (true) {
        std::vector<int> rem(k, kCap);
        if (pack_dfs(items, k, 0, rem)) { return k; }
        ++k;
    }
}

static void bin_packing_demo() {
    println("=== 36.4 装箱：FF / FFD / Best-Fit 与精确最优 ===");
    // 固定例：原序让 FF 浪费一箱（40 与 50 先挤一箱导致 30 落单）
    const std::vector<int> items{40, 50, 60, 30, 20};
    std::vector<int> bins;
    const int ff = first_fit(items, bins);
    const int ffd = first_fit_decreasing(items);
    const int bf = best_fit(items);
    const int opt = bin_packing_optimal(items);
    println("  物品 40/50/60/30/20（容量 100）：FF {} 箱，FFD {} 箱，"
            "Best-Fit {} 箱（先 40+50 挤成碎片），精确最优 {} 箱",
            ff, ffd, bf, opt);
    assert(ff == 3 && ffd == 2 && bf == 3 && opt == 2);

    // 随机 1500 例（n≤12，尺寸 15..85）：三贪心与精确解对账
    std::mt19937 rng{5489};
    int mismatches = 0, ratio_violations = 0;
    for (int t = 0; t < 1500; ++t) {
        const int n = 2 + static_cast<int>(rand_below(rng, 11));
        std::vector<int> g;
        g.reserve(n);
        for (int i = 0; i < n; ++i) {
            g.push_back(15 + static_cast<int>(rand_below(rng, 71)));
        }
        const int o = bin_packing_optimal(g);
        const int a = first_fit_decreasing(g);
        if (a != o && a != o + 1) { ++mismatches; }   // 实测至多差 1
        // 定理：FFD·9 ≤ 11·OPT + 6
        if (9 * a > 11 * o + 6) { ++ratio_violations; }
        assert(a >= o && best_fit(g) >= o);
    }
    println("  随机 {} 例（n≤12）：FFD 超出最优 1 箱以上的 {} 例；"
            "11/9+6/9 定理违反 {} 例", 1500, mismatches, ratio_violations);
    assert(mismatches == 0 && ratio_violations == 0);

    // 大例：10 万件 1..100——Best-Fit multiset 版；下界 ⌈总量/100⌉
    std::vector<int> big;
    big.reserve(100000);
    long long total = 0;
    for (int i = 0; i < 100000; ++i) {
        const int s = 1 + static_cast<int>(rand_below(rng, 100));
        big.push_back(s);
        total += s;
    }
    const int used = best_fit(big);
    const long long lb = (total + kCap - 1) / kCap;
    println("  大例（10 万件，容量 100）：Best-Fit {} 箱，总量下界 {}，"
            "比值 {:.3}（碎片分摊后略高于下界）", used, lb,
            static_cast<double>(used) / static_cast<double>(lb));
    assert(used >= lb);
    assert(static_cast<long long>(used) * 100 <= lb * 120);  // 经验比值 ≤1.20
}

// ═══ 36.5 k-中心：最远点贪心（最远优先遍历，2-近似）═══
// 选 k 个中心（须为输入点），最小化所有点到最近中心的距离。
// 贪心：任取起点，此后每轮加入「距已选中心集最远」的点。
// 2-近似证明：贪心停止时全体点距中心 ≤ r_g；若 r_g > 2r*，取第 k+1
// 轮的最远点 p（距 k 个中心均 > 2r*）——已选的 k 个中心与 p 共 k+1
// 个点两两距 > 2r*？只需：p 与每个中心 > 2r*（成立）；OPT 的 k 个
// 中心由鸽笼必同时覆盖其中两点，而任一 OPT 中心到其覆盖点 ≤ r*，
// 三角不等式给出这两点距 ≤ 2r*，矛盾。
struct KCenResult { std::vector<int> centers; long long radius; };

static long long kcenter_cost(const std::vector<Pt>& pts,
                              const std::vector<int>& centers) {
    long long worst = 0;
    for (const Pt& p : pts) {
        long long best = INT64_MAX;
        for (int c : centers) {
            best = std::min(best, d2(p, pts[static_cast<std::size_t>(c)]));
        }
        worst = std::max(worst, best);
    }
    return worst;
}

static KCenResult farthest_first(const std::vector<Pt>& pts, int k) {
    const int n = static_cast<int>(pts.size());
    std::vector<char> chosen(static_cast<std::size_t>(n), 0);
    std::vector<long long> dist(static_cast<std::size_t>(n), INT64_MAX);
    KCenResult res;
    res.centers.push_back(0);
    chosen[0] = 1;
    for (int i = 0; i < n; ++i) {
        dist[static_cast<std::size_t>(i)] =
            d2(pts[static_cast<std::size_t>(i)], pts[0]);
    }
    while (static_cast<int>(res.centers.size()) < k) {
        int far = -1;
        for (int i = 0; i < n; ++i) {
            if (!chosen[static_cast<std::size_t>(i)] &&
                (far == -1 ||
                 dist[static_cast<std::size_t>(i)] >
                     dist[static_cast<std::size_t>(far)])) {
                far = i;
            }
        }
        if (far == -1) { break; }               // k > n：全体已选
        res.centers.push_back(far);
        chosen[static_cast<std::size_t>(far)] = 1;
        for (int i = 0; i < n; ++i) {
            dist[static_cast<std::size_t>(i)] =
                std::min(dist[static_cast<std::size_t>(i)],
                         d2(pts[static_cast<std::size_t>(i)],
                            pts[static_cast<std::size_t>(far)]));
        }
    }
    res.radius = kcenter_cost(pts, res.centers);
    return res;
}

// 独立真值：C(n,k) 枚举全部中心子集（n≤9 时瞬时）
static KCenResult kcenter_brute(const std::vector<Pt>& pts, int k) {
    const int n = static_cast<int>(pts.size());
    std::vector<int> mask(static_cast<std::size_t>(n), 0);
    for (int i = n - k; i < n; ++i) { mask[static_cast<std::size_t>(i)] = 1; }
    KCenResult best;
    best.radius = INT64_MAX;
    do {
        std::vector<int> centers;
        for (int i = 0; i < n; ++i) {
            if (mask[static_cast<std::size_t>(i)]) { centers.push_back(i); }
        }
        const long long r = kcenter_cost(pts, centers);
        if (r < best.radius) { best.radius = r; best.centers = centers; }
    } while (std::next_permutation(mask.begin(), mask.end()));
    return best;
}

static void kcenter_demo() {
    println("");
    println("=== 36.5 k-中心：最远点贪心 2-近似（曼哈顿口径）===");
    const std::vector<Pt> sq{{0, 0}, {0, 2}, {2, 0}, {2, 2}};
    const KCenResult sq1 = kcenter_brute(sq, 1);
    const KCenResult sq2g = farthest_first(sq, 2);
    const KCenResult sq2 = kcenter_brute(sq, 2);
    println("  正方形 4 点：k=1 最优半径 {}；k=2 贪心 {} vs 最优 {}（对角两点即最优）",
            sq1.radius, sq2g.radius, sq2.radius);
    assert(sq1.radius == 4 && sq2.radius == 2 && sq2g.radius == 2);

    const std::vector<Pt> line{{0, 0}, {1, 0}, {2, 0}, {3, 0}, {10, 0}};
    const KCenResult lg = farthest_first(line, 2);
    const KCenResult lb = kcenter_brute(line, 2);
    println("  数线例（0,1,2,3,10，k=2）：贪心半径 {}（中心 0 与 10），最优 {}，比值 {:.2f}（≤ 2 保证）",
            lg.radius, lb.radius,
            static_cast<double>(lg.radius) / static_cast<double>(lb.radius));
    assert(lg.radius == 3 && lb.radius == 2);

    // 随机 300 例：贪心 vs 精确最优——定理界与命中率
    std::mt19937 rng{5489};
    int bad = 0, hit = 0;
    for (int t = 0; t < 300; ++t) {
        const int n = 4 + static_cast<int>(rand_below(rng, 6));   // 4..9
        std::vector<Pt> pts;
        pts.reserve(static_cast<std::size_t>(n));
        for (int i = 0; i < n; ++i) {
            pts.push_back({static_cast<long long>(rand_below(rng, 20)),
                           static_cast<long long>(rand_below(rng, 20))});
        }
        const int k = 1 + static_cast<int>(rand_below(rng, 3));   // 1..3
        const KCenResult g = farthest_first(pts, k);
        const KCenResult b = kcenter_brute(pts, k);
        if (g.radius > 2 * b.radius) { ++bad; }
        if (g.radius == b.radius) { ++hit; }
    }
    println("  随机 300 例（n≤9，k≤3）：贪心命中最优 {} 例；比值 > 2 的 {} 例", hit, bad);
    assert(bad == 0);

    // 大例：2000 点、k=25；独立全量复算半径一致
    std::vector<Pt> big;
    big.reserve(2000);
    for (int i = 0; i < 2000; ++i) {
        big.push_back({static_cast<long long>(rand_below(rng, 1000)),
                       static_cast<long long>(rand_below(rng, 1000))});
    }
    const KCenResult bg = farthest_first(big, 25);
    long long worst = 0;
    for (const Pt& p : big) {
        long long best = INT64_MAX;
        for (int c : bg.centers) {
            best = std::min(best, d2(p, big[static_cast<std::size_t>(c)]));
        }
        worst = std::max(worst, best);
    }
    println("  大例（2000 点，k=25）：贪心半径 {}（独立全量复算一致 = 1）",
            bg.radius);
    assert(bg.radius == worst);
}

int main() {
    vertex_cover_demo();
    tsp_demo();
    set_cover_demo();
    bin_packing_demo();
    kcenter_demo();
    println("自检通过");
    return 0;
}
