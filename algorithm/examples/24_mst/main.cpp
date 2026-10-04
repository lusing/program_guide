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
#include <vector>

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
    println("自检通过");
    return 0;
}
