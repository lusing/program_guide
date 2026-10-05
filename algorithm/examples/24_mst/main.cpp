// 24 最小生成树（CLRS 第 23 章）。结构：24.1 图 23.1 数据与 MST 存在性 /
// 24.2 Kruskal（排序 + 并查集，弃边计数）/ 24.3 Prim（键值数组版）/
// 24.4 双解对账（同为 37、同为生成树、边集可不同）。
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
#include <cassert>
#include <cstdint>
#include <numeric>
#include <random>
#include <vector>

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

// CLRS 图 23.1 的无向带权图：9 顶点 14 边
struct Edge { int u, v, w; };

static const std::vector<Edge> kEdges{
    {0, 1, 4}, {0, 7, 8}, {1, 7, 11}, {1, 2, 8}, {2, 8, 2}, {2, 3, 7},
    {2, 5, 4}, {3, 4, 9}, {3, 5, 14}, {4, 5, 10}, {5, 6, 2}, {6, 7, 1},
    {6, 8, 6}, {7, 8, 7}};

static const std::array<const char*, 9> kName{"a", "b", "c", "d", "e", "f", "g", "h", "i"};

// ═══ 24.2 Kruskal：按权排序 + 并查集弃环 ═══
struct Dsu {
    std::vector<int> p, r;
    explicit Dsu(int n) : p(static_cast<std::size_t>(n)), r(static_cast<std::size_t>(n), 0) {
        std::iota(p.begin(), p.end(), 0);
    }
    int find(int x) { while (p[static_cast<std::size_t>(x)] != x) { p[static_cast<std::size_t>(x)] = p[static_cast<std::size_t>(p[static_cast<std::size_t>(x)])]; x = p[static_cast<std::size_t>(x)]; } return x; }
    bool unite(int a, int b) {
        a = find(a); b = find(b);
        if (a == b) { return false; }
        if (r[static_cast<std::size_t>(a)] < r[static_cast<std::size_t>(b)]) { std::swap(a, b); }
        p[static_cast<std::size_t>(b)] = a;
        if (r[static_cast<std::size_t>(a)] == r[static_cast<std::size_t>(b)]) { ++r[static_cast<std::size_t>(a)]; }
        return true;
    }
};

static std::vector<Edge> kruskal(long long& weight, long long& rejected) {
    auto edges = kEdges;
    std::ranges::sort(edges, {}, &Edge::w);
    Dsu dsu(9);
    std::vector<Edge> tree;
    weight = 0; rejected = 0;
    for (auto&& e : edges) {
        if (dsu.unite(e.u, e.v)) {
            tree.push_back(e);
            weight += e.w;
        } else {
            ++rejected;
        }
    }
    return tree;
}

// ═══ 24.3 Prim：键值数组 + 已选集合 ═══
static std::vector<Edge> prim(int src, long long& weight) {
    const int n = 9;
    std::vector<std::vector<std::pair<int, int>>> adj(static_cast<std::size_t>(n));
    for (auto&& e : kEdges) {
        adj[static_cast<std::size_t>(e.u)].emplace_back(e.v, e.w);
        adj[static_cast<std::size_t>(e.v)].emplace_back(e.u, e.w);
    }
    std::vector<int> key(static_cast<std::size_t>(n), INT32_MAX);
    std::vector<int> parent(static_cast<std::size_t>(n), -1);
    std::vector<char> inTree(static_cast<std::size_t>(n), 0);
    key[static_cast<std::size_t>(src)] = 0;
    weight = 0;
    std::vector<Edge> tree;
    for (int iter = 0; iter < n; ++iter) {
        int u = -1, best = INT32_MAX;
        for (int v = 0; v < n; ++v) {
            if (!inTree[static_cast<std::size_t>(v)] && key[static_cast<std::size_t>(v)] < best) {
                best = key[static_cast<std::size_t>(v)]; u = v;
            }
        }
        assert(u != -1);                        // 图连通
        inTree[static_cast<std::size_t>(u)] = 1;
        if (parent[static_cast<std::size_t>(u)] != -1) {
            tree.push_back({parent[static_cast<std::size_t>(u)], u, best});
            weight += best;
        }
        for (auto [v, w] : adj[static_cast<std::size_t>(u)]) {
            if (!inTree[static_cast<std::size_t>(v)] && w < key[static_cast<std::size_t>(v)]) {
                key[static_cast<std::size_t>(v)] = w;
                parent[static_cast<std::size_t>(v)] = u;
            }
        }
    }
    return tree;
}

// 生成树合法性：n−1 条边、全连通（用并查集验）、总权一致
static bool is_spanning_tree(const std::vector<Edge>& tree) {
    if (tree.size() != 8) { return false; }
    Dsu d(9);
    for (auto&& e : tree) {
        if (!d.unite(e.u, e.v)) { return false; }
    }
    return d.find(0) == d.find(8);   // 连通代表
}

// ═══ 24.5 物以类聚：MST 边权序列上的分组阈值 ═══
// N 个点（属性 a,b），距离 = 曼哈顿距离。要分成 K 组，使每个组内的
// 成员（除组内唯一者外）至少有一个「距离不超过 X」的伙伴；求最小 X。
struct ClusterPoint {
    int a = 0, b = 0;
};

static int manhattan(const ClusterPoint& p, const ClusterPoint& q) {
    return std::abs(p.a - q.a) + std::abs(p.b - q.b);
}

// 阈值直接判定法：保留权 ≤ X 的边，DSU 分量数 ≤ K 即可行。
// （分量 ≥2 者每人都有 ≤X 的伙伴；孤立分量自成一组，条件真空成立。）
static int cluster_threshold_brute(const std::vector<ClusterPoint>& pts, int k) {
    const int n = static_cast<int>(pts.size());
    std::vector<Edge> edges;
    for (int i = 0; i < n; ++i)
        for (int j = i + 1; j < n; ++j)
            edges.push_back({i, j, manhattan(pts[static_cast<std::size_t>(i)],
                                             pts[static_cast<std::size_t>(j)])});
    std::ranges::sort(edges, {}, &Edge::w);
    std::vector<int> weights;
    for (const Edge& e : edges) {
        if (weights.empty() || weights.back() != e.w) { weights.push_back(e.w); }
    }
    for (const int x : weights) {
        Dsu dsu(n);
        for (const Edge& e : edges) {
            if (e.w > x) { break; }
            dsu.unite(e.u, e.v);
        }
        int components = 0;
        for (int i = 0; i < n; ++i)
            if (dsu.find(i) == i) { ++components; }
        if (components <= k) { return x; }
    }
    return -1;
}

// MST 法：Kruskal 接受边的权序列升序，第 N−K 次合并（0 基下标 N−K−1）
// 使分量数首次降到 K，该边权即最小阈值。
static int cluster_threshold_mst(const std::vector<ClusterPoint>& pts, int k) {
    const int n = static_cast<int>(pts.size());
    std::vector<Edge> edges;
    for (int i = 0; i < n; ++i)
        for (int j = i + 1; j < n; ++j)
            edges.push_back({i, j, manhattan(pts[static_cast<std::size_t>(i)],
                                             pts[static_cast<std::size_t>(j)])});
    std::ranges::sort(edges, {}, &Edge::w);
    Dsu dsu(n);
    int components = n;
    std::vector<int> tree_weights;
    for (const Edge& e : edges) {
        if (dsu.unite(e.u, e.v)) {
            tree_weights.push_back(e.w);
            if (--components == k) { return e.w; }
        }
    }
    return tree_weights[static_cast<std::size_t>(n - k - 1)]; // k==1
}

static void clustering_demo() {
    println("物以类聚（曼哈顿距离完全图；MST 边权序列上的分组阈值）：");
    const std::vector<ClusterPoint> sample{
        {1, 2}, {2, 3}, {2, 2}, {3, 4}, {4, 3}, {3, 1}};
    const int k = 2;
    const int by_mst = cluster_threshold_mst(sample, k);
    const int by_enum = cluster_threshold_brute(sample, k);
    // 打印样例 MST 边权升序（5 条：1 1 2 2 2）。
    std::vector<Edge> edges;
    for (std::size_t i = 0; i < sample.size(); ++i)
        for (std::size_t j = i + 1; j < sample.size(); ++j)
            edges.push_back({static_cast<int>(i), static_cast<int>(j),
                            manhattan(sample[i], sample[j])});
    std::ranges::sort(edges, {}, &Edge::w);
    Dsu dsu(static_cast<int>(sample.size()));
    std::vector<int> tree_weights;
    for (const Edge& e : edges)
        if (dsu.unite(e.u, e.v)) { tree_weights.push_back(e.w); }
    print("  6 点的 MST 边权升序：");
    for (int w : tree_weights) { print("{} ", w); }
    println("");
    println("  分 {} 组：MST 法阈值 {}（首次降到 {} 个分量），逐阈值枚举 {}（样例答案 2）",
            k, by_mst, k, by_enum);
    assert(by_mst == 2 && by_enum == 2);

    std::mt19937 rng{5489};
    int trials = 1500, mismatches = 0;
    for (int t = 0; t < trials; ++t) {
        const int n = 2 + static_cast<int>(rand_below(rng, 11));
        std::vector<ClusterPoint> pts(static_cast<std::size_t>(n));
        for (ClusterPoint& p : pts) {
            p.a = static_cast<int>(rand_below(rng, 20));
            p.b = static_cast<int>(rand_below(rng, 20));
        }
        const int kk = 1 + static_cast<int>(rand_below(
            rng, static_cast<std::uint32_t>(n - 1)));
        if (cluster_threshold_mst(pts, kk) !=
            cluster_threshold_brute(pts, kk)) { ++mismatches; }
    }
    println("  随机 {} 例（N≤12，坐标 ≤19）：MST 法 vs 逐阈值枚举 不一致 {} 例",
            trials, mismatches);
    assert(mismatches == 0);
}

int main() {
    println("最小生成树（图 23.1 的 9 顶点 14 边无向带权图）：");
    // Kruskal
    long long w1 = 0, rej = 0;
    const auto t1 = kruskal(w1, rej);
    print("  Kruskal 边集: ");
    for (auto&& e : t1) { print("{}{} ", kName[static_cast<std::size_t>(e.u)], kName[static_cast<std::size_t>(e.v)]); }
    println("");
    println("  总权 = {}，弃边 {} 条（成环检测）", w1, rej);
    assert(w1 == 37 && t1.size() == 8 && rej == 6);
    // Prim（从 a 出发）
    long long w2 = 0;
    const auto t2 = prim(0, w2);
    print("  Prim(a) 边集: ");
    for (auto&& e : t2) { print("{}{} ", kName[static_cast<std::size_t>(e.u)], kName[static_cast<std::size_t>(e.v)]); }
    println("");
    println("  总权 = {}", w2);
    assert(w2 == 37 && t2.size() == 8);
    // 双解对账
    assert(is_spanning_tree(t1) && is_spanning_tree(t2));
    println("  两解都是 8 条边的连通生成树，总权同为 37（与 CLRS 图 23.4 的 MST 一致）");
    clustering_demo();
    println("自检通过");
    return 0;
}
