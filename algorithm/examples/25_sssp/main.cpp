// 25 单源最短路（CLRS 第 24 章）。结构：25.1 松弛框架与三角不等式 /
// 25.2 Bellman-Ford（图 24.4 的负权边例，V·E 逐轮表）/ 25.3 Dijkstra
//（图 24.6 的非负图，逐出队表）/ 25.4 负环检测。
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
#include <limits>
#include <queue>
#include <utility>
#include <vector>

struct DiGraph {
    int n;
    std::vector<std::vector<std::pair<int, int>>> adj;   // (to, w)
    explicit DiGraph(int n_) : n(n_), adj(static_cast<std::size_t>(n_)) {}
    void add(int u, int v, int w) { adj[static_cast<std::size_t>(u)].emplace_back(v, w); }
};

constexpr int INF = INT32_MAX;

// ═══ 25.1–25.2 Bellman-Ford ═══
// V−1 轮全边松弛（第 V 轮检测负环）。正确性路径长 ≤ V−1 条边。
struct BfResult { std::vector<int> d; bool negCycle; long long relaxOps; };

static BfResult bellman_ford(const DiGraph& g, int s) {
    std::vector<int> d(static_cast<std::size_t>(g.n), INF);
    d[static_cast<std::size_t>(s)] = 0;
    long long ops = 0;
    for (int round = 1; round < g.n; ++round) {
        bool changed = false;
        for (int u = 0; u < g.n; ++u) {
            if (d[static_cast<std::size_t>(u)] == INF) { continue; }
            for (auto [v, w] : g.adj[static_cast<std::size_t>(u)]) {
                ++ops;
                if (d[static_cast<std::size_t>(u)] + w < d[static_cast<std::size_t>(v)]) {
                    d[static_cast<std::size_t>(v)] = d[static_cast<std::size_t>(u)] + w;
                    changed = true;
                }
            }
        }
        if (!changed) { break; }   // 提前收敛（实测常见）
    }
    bool neg = false;
    for (int u = 0; u < g.n && !neg; ++u) {
        if (d[static_cast<std::size_t>(u)] == INF) { continue; }
        for (auto [v, w] : g.adj[static_cast<std::size_t>(u)]) {
            if (d[static_cast<std::size_t>(u)] + w < d[static_cast<std::size_t>(v)]) { neg = true; break; }
        }
    }
    return {d, neg, ops};
}

// 图 24.4 的负权图：s t x y z = 0..4
// s→t 6, s→y 7, t→x 5, t→y 8, t→z −4, x→t −2, y→x −3, y→z 9, z→s 2, z→x 7
static DiGraph fig244() {
    DiGraph g(5);
    g.add(0, 1, 6); g.add(0, 3, 7); g.add(1, 2, 5); g.add(1, 3, 8);
    g.add(1, 4, -4); g.add(2, 1, -2); g.add(3, 2, -3); g.add(3, 4, 9);
    g.add(4, 0, 2); g.add(4, 2, 7);
    return g;
}

static void bellman_ford_demo() {
    const auto g = fig244();
    const auto r = bellman_ford(g, 0);
    static const std::array<const char*, 5> nm{"s", "t", "x", "y", "z"};
    print("Bellman-Ford（图 24.4 负权图，源 s）d 值: ");
    for (int i = 1; i < 5; ++i) { print("{}={} ", nm[static_cast<std::size_t>(i)], r.d[static_cast<std::size_t>(i)]); }
    println("");
    assert(!r.negCycle);
    // CLRS 图 24.4 答案：t=2（s→y→x→t: 7−3−2=2），x=4，y=7，z=−2
    assert((r.d == std::vector<int>{0, 2, 4, 7, -2}));
    println("  负权边（t→z=−4, x→t=−2, y→x=−3）下正确：z=−2；负环 = {}，松弛操作 {} 次",
            r.negCycle ? 1 : 0, r.relaxOps);
}

// ═══ 25.3 Dijkstra ═══
// 图 24.6 的非负图：s t x y z = 0..4
// s→t 10, s→y 5, t→x 1, t→y 2, x→z 4, y→t 3, y→x 9, y→z 2, z→x 6, z→s 7
static void dijkstra_demo() {
    DiGraph g(5);
    g.add(0, 1, 10); g.add(0, 3, 5); g.add(1, 2, 1); g.add(1, 3, 2);
    g.add(2, 4, 4); g.add(3, 1, 3); g.add(3, 2, 9); g.add(3, 4, 2);
    g.add(4, 2, 6); g.add(4, 0, 7);
    // 标准实现：小顶堆 + lazy 删除（过期条目跳过）
    std::vector<int> d(5, INF);
    d[0] = 0;
    using Q = std::pair<int, int>;
    std::priority_queue<Q, std::vector<Q>, std::greater<Q>> pq;
    pq.push({0, 0});
    long long pops = 0, skipped = 0;
    std::vector<int> extractOrder;
    while (!pq.empty()) {
        const auto [du, u] = pq.top();
        pq.pop();
        ++pops;
        if (du > d[static_cast<std::size_t>(u)]) { ++skipped; continue; }  // 过期条目
        extractOrder.push_back(u);
        for (auto [v, w] : g.adj[static_cast<std::size_t>(u)]) {
            if (d[static_cast<std::size_t>(u)] + w < d[static_cast<std::size_t>(v)]) {
                d[static_cast<std::size_t>(v)] = d[static_cast<std::size_t>(u)] + w;
                pq.push({d[static_cast<std::size_t>(v)], v});
            }
        }
    }
    static const std::array<const char*, 5> nm{"s", "t", "x", "y", "z"};
    print("Dijkstra（图 24.6 非负图，源 s）d 值: ");
    for (int i = 1; i < 5; ++i) { print("{}={} ", nm[static_cast<std::size_t>(i)], d[static_cast<std::size_t>(i)]); }
    println("");
    // CLRS 图 24.6 答案：t=8, x=9, y=5, z=7
    assert((d == std::vector<int>{0, 8, 9, 5, 7}));
    print("  出队序（贪心近者先出）: ");
    for (int u : extractOrder) { print("{} ", nm[static_cast<std::size_t>(u)]); }
    println("");
    assert((extractOrder == std::vector<int>{0, 3, 4, 1, 2}));   // s y z t x
    println("  堆操作 {} 次弹出（{} 次过期跳过——lazy 删除的代价与简单）",
            pops, skipped);
}

// ═══ 25.4 负环检测 ═══
static void negative_cycle_demo() {
    // a→b 1, b→c −3, c→a 1：环权 −1
    DiGraph g(3);
    g.add(0, 1, 1); g.add(1, 2, -3); g.add(2, 0, 1);
    const auto r = bellman_ford(g, 0);
    println("负环检测（a→b 1, b→c −3, c→a 1，环权 −1）：第 V 轮仍可松弛 = {}",
            r.negCycle ? 1 : 0);
    assert(r.negCycle);
}

int main() {
    bellman_ford_demo();
    dijkstra_demo();
    negative_cycle_demo();
    println("自检通过");
    return 0;
}
