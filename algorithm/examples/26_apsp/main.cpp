// 26 所有顶点对最短路（CLRS 第 25 章）。结构：26.1 Floyd-Warshall 的
// DP 结构与逐步 D^(k) 表（图 25.1 数据）/ 26.2 路径重构（前驱矩阵 π）/
// 26.3 传递闭包 / 26.4 与 Dijkstra 逐点对账（非负图上两法一致）。
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
#include <format>
#include <numeric>
#include <queue>
#include <random>
#include <string_view>
#include <utility>
#include <vector>

constexpr int INF = 1000000;

// CLRS 图 25.1 的 5 顶点权重矩阵（0 = 对角；INF = 无边）
static const std::vector<std::vector<int>> kW = {
    {0, 3, 8, INF, -4},
    {INF, 0, INF, 1, 7},
    {INF, 4, 0, INF, INF},
    {2, INF, -5, 0, INF},
    {INF, INF, INF, 6, 0}};

using Mat = std::vector<std::vector<int>>;

static void print_mat(const Mat& m, std::string_view title) {
    println("{}", title);
    for (auto& row : m) {
        print("  ");
        for (int v : row) {
            if (v >= INF) { print("  ∞"); }
            else { print(" {:>2}", v); }
        }
        println("");
    }
}

// ═══ 26.1 Floyd-Warshall ═══
// d^(k)[i][j] = 只允许中转点 ∈ {1..k} 的 i→j 最短路
// 递推：d^(k) = min(d^(k-1)[i][j], d^(k-1)[i][k] + d^(k-1)[k][j])
struct FwResult { Mat d; Mat next; };

static FwResult floyd_warshall(const Mat& w, bool verbose) {
    const int n = static_cast<int>(w.size());
    Mat d = w;
    Mat nxt(static_cast<std::size_t>(n),
            std::vector<int>(static_cast<std::size_t>(n), -1));
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) {
            if (i != j && w[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] < INF) {
                nxt[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] = j;
            }
        }
    }
    for (int k = 0; k < n; ++k) {
        for (int i = 0; i < n; ++i) {
            for (int j = 0; j < n; ++j) {
                const int dik = d[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)];
                const int dkj = d[static_cast<std::size_t>(k)][static_cast<std::size_t>(j)];
                // 无穷卫哨：INF + w 可能溢出下穿 INF（负权时 INF−4 < INF！）
                if (dik >= INF || dkj >= INF) { continue; }
                if (dik + dkj < d[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)]) {
                    d[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] = dik + dkj;
                    nxt[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] =
                        nxt[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)];
                }
            }
        }
        if (verbose && (k == 0 || k == 4)) {
            print_mat(d, std::format("  D^({})（中转点 ⊆ {{1..{}}}）:", k + 1, k + 1));
        }
    }
    return {d, nxt};
}

static void fw_demo() {
    println("Floyd-Warshall（图 25.1 的 5 顶点带负权图）：");
    print_mat(kW, "  D^(0)（权重矩阵 W）：");
    const auto r = floyd_warshall(kW, true);
    print_mat(r.d, "  D^(5)（最终全源距离矩阵）：");
    // CLRS 图 25.4 的答案
    const Mat expect = {
        {0, 1, -3, 2, -4},
        {3, 0, -4, 1, -1},
        {7, 4, 0, 5, 3},
        {2, -1, -5, 0, -2},
        {8, 5, 1, 6, 0}};
    assert(r.d == expect);
    println("  与 CLRS 图 25.4 的 D^(5) 逐格一致 = 1");
    // 路径重构：1→4（0 基）的路径 1→2? 用 next 链走
    std::vector<int> path{0};
    while (path.back() != 4) {
        path.push_back(r.next[static_cast<std::size_t>(path.back())][4]);
    }
    print("  1→5 的最短路（next 链）: ");
    for (std::size_t i = 0; i < path.size(); ++i) {
        print("{}{}", i == 0 ? "" : "→", path[i] + 1);
    }
    println("（长度 {}）", r.d[0][4]);
    assert(r.d[0][4] == -4 && path.size() == 2);   // 1→5 直达（权 −4）
}

// ═══ 26.3 传递闭包 ═══
static void closure_demo() {
    // t^(k)[i][j] = i→j 是否可达（中转 ⊆ {1..k}），按位运算的 FW
    const int n = 4;
    std::vector<std::vector<char>> t{
        {1, 1, 0, 1}, {0, 1, 1, 0}, {0, 0, 1, 1}, {0, 1, 0, 1}};
    for (int k = 0; k < n; ++k) {
        for (int i = 0; i < n; ++i) {
            for (int j = 0; j < n; ++j) {
                t[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] =
                    static_cast<char>(t[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] |
                    (t[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)] &
                     t[static_cast<std::size_t>(k)][static_cast<std::size_t>(j)]));
            }
        }
    }
    // 闭包结果：0 可达全部（0→1→2→3）；1/2/3 互达但谁都到不了 0
    const std::vector<std::vector<char>> expect{
        {1, 1, 1, 1}, {0, 1, 1, 1}, {0, 1, 1, 1}, {0, 1, 1, 1}};
    bool ok = t == expect;
    println("传递闭包（4 顶点示例，FW 的按位版）：0 可达全部、1/2/3 互达而到不了 0 = {}",
            ok ? 1 : 0);
    assert(ok);
}

// ═══ 26.4 与 Dijkstra 对账 ═══
static void vs_dijkstra_demo() {
    // 同一张非负图跑两法，全源距离必须一致
    const int n = 5;
    // Dijkstra 只在非负图合法（图 25.1 有负权），这里构造小非负图对照
    const Mat w2 = {
        {0, 2, 9, INF, INF},
        {INF, 0, 3, 1, INF},
        {INF, INF, 0, INF, 4},
        {2, INF, INF, 0, 2},
        {INF, INF, INF, INF, 0}};
    const auto fw = floyd_warshall(w2, false);
    // Dijkstra from each source
    for (int s = 0; s < n; ++s) {
        std::vector<int> d(static_cast<std::size_t>(n), INF);
        d[static_cast<std::size_t>(s)] = 0;
        using Q = std::pair<int, int>;
        std::priority_queue<Q, std::vector<Q>, std::greater<Q>> pq;
        pq.push({0, s});
        while (!pq.empty()) {
            const auto [du, u] = pq.top(); pq.pop();
            if (du > d[static_cast<std::size_t>(u)]) { continue; }
            for (int v = 0; v < n; ++v) {
                const int wv = w2[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)];
                if (wv < INF && d[static_cast<std::size_t>(u)] + wv < d[static_cast<std::size_t>(v)]) {
                    d[static_cast<std::size_t>(v)] = d[static_cast<std::size_t>(u)] + wv;
                    pq.push({d[static_cast<std::size_t>(v)], v});
                }
            }
        }
        for (int v = 0; v < n; ++v) {
            assert(d[static_cast<std::size_t>(v)] == fw.d[static_cast<std::size_t>(s)][static_cast<std::size_t>(v)]);
        }
    }
    println("对账：同一非负图上 Floyd-Warshall 与逐源 Dijkstra 的 5×5 距离矩阵逐格一致 = 1");
}

// ═══ 26.5 图的中心：离心距最小的顶点 ═══
// 顶点 v 的离心距 e(v)=max_u d(v,u)；图半径 r=min_v e(v)；
// 中心 ={v | e(v)=r}。连通图才有定义。
struct CenterInfo {
    bool connected = true;
    int radius = 0;
    std::vector<int> centers;
    std::vector<int> ecc;
};

static CenterInfo graph_center(const Mat& w) {
    const int n = static_cast<int>(w.size());
    const FwResult fw = floyd_warshall(w, false);
    CenterInfo ci;
    ci.ecc.assign(static_cast<std::size_t>(n), 0);
    for (int v = 0; v < n; ++v) {
        int e = 0;
        for (int u = 0; u < n; ++u) {
            const int d = fw.d[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)];
            if (d >= INF) { ci.connected = false; return ci; }
            e = std::max(e, d);
        }
        ci.ecc[static_cast<std::size_t>(v)] = e;
    }
    ci.radius = *std::ranges::min_element(ci.ecc);
    for (int v = 0; v < n; ++v) {
        if (ci.ecc[static_cast<std::size_t>(v)] == ci.radius) { ci.centers.push_back(v); }
    }
    return ci;
}

// 无权图的逐源 BFS 距离矩阵（独立口径，零共享 Floyd 代码）
static Mat bfs_all_pairs(const std::vector<std::vector<int>>& adj) {
    const int n = static_cast<int>(adj.size());
    Mat d(static_cast<std::size_t>(n),
          std::vector<int>(static_cast<std::size_t>(n), INF));
    for (int s = 0; s < n; ++s) {
        d[static_cast<std::size_t>(s)][static_cast<std::size_t>(s)] = 0;
        std::queue<int> q;
        q.push(s);
        while (!q.empty()) {
            const int u = q.front(); q.pop();
            for (int v : adj[static_cast<std::size_t>(u)]) {
                if (d[static_cast<std::size_t>(s)][static_cast<std::size_t>(v)] == INF) {
                    d[static_cast<std::size_t>(s)][static_cast<std::size_t>(v)] =
                        d[static_cast<std::size_t>(s)][static_cast<std::size_t>(u)] + 1;
                    q.push(v);
                }
            }
        }
    }
    return d;
}

// 树上的经典结论：反复剥叶，剩 1 或 2 个顶点即树中心；
// 半径 = ⌈直径/2⌉。
static CenterInfo tree_center_leaf_peel(const std::vector<std::vector<int>>& adj) {
    const int n = static_cast<int>(adj.size());
    std::vector<int> deg(static_cast<std::size_t>(n));
    std::vector<char> alive(static_cast<std::size_t>(n), 1);
    for (int v = 0; v < n; ++v) {
        deg[static_cast<std::size_t>(v)] =
            static_cast<int>(adj[static_cast<std::size_t>(v)].size());
    }
    int left = n;
    while (left > 2) {
        std::vector<int> leaves;
        for (int v = 0; v < n; ++v) {
            if (alive[static_cast<std::size_t>(v)] &&
                deg[static_cast<std::size_t>(v)] <= 1) { leaves.push_back(v); }
        }
        for (int v : leaves) {
            alive[static_cast<std::size_t>(v)] = 0;
            --left;
            for (int u : adj[static_cast<std::size_t>(v)]) {
                if (alive[static_cast<std::size_t>(u)]) { --deg[static_cast<std::size_t>(u)]; }
            }
        }
    }
    CenterInfo ci;
    for (int v = 0; v < n; ++v) {
        if (alive[static_cast<std::size_t>(v)]) { ci.centers.push_back(v); }
    }
    return ci;
}

static std::uint32_t center_rand(std::mt19937& rng, std::uint32_t n) {
    return static_cast<std::uint32_t>(
        (static_cast<std::uint64_t>(rng()) * n) >> 32);
}

static void center_demo() {
    println("");
    println("=== 26.5 图的中心：e(v)=max d(v,u)，半径与中心点 ===");
    // 固定例（7 顶点）：D 为唯一中心、半径 2；A 的离心距 4
    const int n = 7;
    std::vector<std::vector<int>> adj(static_cast<std::size_t>(n));
    const std::pair<int, int> edges[] = {
        {0, 1}, {1, 3}, {1, 2}, {3, 2}, {3, 4},
        {2, 5}, {4, 6}};
    for (auto [u, v] : edges) {
        adj[static_cast<std::size_t>(u)].push_back(v);
        adj[static_cast<std::size_t>(v)].push_back(u);
    }
    Mat w(static_cast<std::size_t>(n),
          std::vector<int>(static_cast<std::size_t>(n), INF));
    for (int v = 0; v < n; ++v) {
        w[static_cast<std::size_t>(v)][static_cast<std::size_t>(v)] = 0;
        for (int u : adj[static_cast<std::size_t>(v)]) {
            w[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)] = 1;
        }
    }
    const CenterInfo ci = graph_center(w);
    print("  各点离心距: ");
    for (int v = 0; v < n; ++v) {
        print("{}{}:{}", v == 0 ? "" : " ", static_cast<char>('A' + v),
              ci.ecc[static_cast<std::size_t>(v)]);
    }
    println("");
    print("  中心点: ");
    for (int c : ci.centers) { print("{} ", static_cast<char>('A' + c)); }
    println("；半径 {}", ci.radius);
    assert(ci.connected && ci.radius == 2 &&
           ci.centers.size() == 1 && ci.centers[0] == 3 &&
           ci.ecc[0] == 4);

    // BFS 独立口径：距离矩阵与 Floyd 一致、中心一致
    const Mat bd = bfs_all_pairs(adj);
    assert(bd == floyd_warshall(w, false).d);

    // 随机 200 个连通图：BFS 矩阵 vs Floyd 矩阵、两法中心一致
    std::mt19937 rng{5489};
    int mism = 0;
    for (int t = 0; t < 200; ++t) {
        const int m = 4 + static_cast<int>(center_rand(rng, 12));
        std::vector<std::vector<int>> ga(static_cast<std::size_t>(m));
        // 先撒一条随机生成树保连通
        std::vector<int> perm(static_cast<std::size_t>(m));
        std::iota(perm.begin(), perm.end(), 0);
        for (int i = 1; i < m; ++i) {
            const int j = static_cast<int>(center_rand(rng,
                static_cast<std::uint32_t>(i)));
            const int u = perm[static_cast<std::size_t>(i)], v = perm[static_cast<std::size_t>(j)];
            ga[static_cast<std::size_t>(u)].push_back(v);
            ga[static_cast<std::size_t>(v)].push_back(u);
        }
        // 再随机补边
        const int extra = static_cast<int>(center_rand(rng,
            static_cast<std::uint32_t>(m)));
        for (int k = 0; k < extra; ++k) {
            const int u = static_cast<int>(center_rand(rng, m));
            const int v = static_cast<int>(center_rand(rng, m));
            if (u == v || std::ranges::find(ga[static_cast<std::size_t>(u)], v)
                != ga[static_cast<std::size_t>(u)].end()) { continue; }
            ga[static_cast<std::size_t>(u)].push_back(v);
            ga[static_cast<std::size_t>(v)].push_back(u);
        }
        Mat gm(static_cast<std::size_t>(m),
               std::vector<int>(static_cast<std::size_t>(m), INF));
        for (int v = 0; v < m; ++v) {
            gm[static_cast<std::size_t>(v)][static_cast<std::size_t>(v)] = 0;
            for (int u : ga[static_cast<std::size_t>(v)]) {
                gm[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)] = 1;
            }
        }
        const Mat bm = bfs_all_pairs(ga);
        if (bm != floyd_warshall(gm, false).d) { ++mism; continue; }
        // 由 BFS 矩阵另算离心距，中心必须一致
        std::vector<int> be(static_cast<std::size_t>(m), 0);
        for (int v = 0; v < m; ++v) {
            for (int u = 0; u < m; ++u) {
                be[static_cast<std::size_t>(v)] = std::max(
                    be[static_cast<std::size_t>(v)],
                    bm[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)]);
            }
        }
        const CenterInfo gc = graph_center(gm);
        for (int v = 0; v < m; ++v) {
            assert((be[static_cast<std::size_t>(v)] == gc.ecc[static_cast<std::size_t>(v)]));
        }
    }
    println("  随机 200 个连通图：BFS vs Floyd 距离/中心不一致 {} 例", mism);
    assert(mism == 0);

    // 随机树 100 棵：剥叶中心 vs Floyd 中心；半径=⌈直径/2⌉
    int tree_bad = 0;
    for (int t = 0; t < 100; ++t) {
        const int m = 2 + static_cast<int>(center_rand(rng, 30));
        std::vector<std::vector<int>> ta(static_cast<std::size_t>(m));
        for (int i = 1; i < m; ++i) {
            const int j = static_cast<int>(center_rand(rng,
                static_cast<std::uint32_t>(i)));
            ta[static_cast<std::size_t>(i)].push_back(j);
            ta[static_cast<std::size_t>(j)].push_back(i);
        }
        Mat tm(static_cast<std::size_t>(m),
               std::vector<int>(static_cast<std::size_t>(m), INF));
        for (int v = 0; v < m; ++v) {
            tm[static_cast<std::size_t>(v)][static_cast<std::size_t>(v)] = 0;
            for (int u : ta[static_cast<std::size_t>(v)]) {
                tm[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)] = 1;
            }
        }
        const CenterInfo tc = graph_center(tm);
        const CenterInfo lp = tree_center_leaf_peel(ta);
        // 直径从 BFS 精确取
        const Mat tdist = bfs_all_pairs(ta);
        int diameter = 0;
        for (int a = 0; a < m; ++a) {
            for (int b = 0; b < m; ++b) {
                diameter = std::max(diameter,
                    tdist[static_cast<std::size_t>(a)][static_cast<std::size_t>(b)]);
            }
        }
        if (tc.centers != lp.centers ||
            tc.radius != (diameter + 1) / 2) { ++tree_bad; }
    }
    println("  随机树 100 棵：剥叶中心/半径与 Floyd 口径不一致 {} 例", tree_bad);
    assert(tree_bad == 0);

    // 不连通图：graph_center 必须报 connected=false，不能吐出假中心
    Mat disc{{0, INF}, {INF, 0}};
    assert(!graph_center(disc).connected);

    // 大例 n=400 随机连通图：逐源 BFS O(n(n+m))，核对中心性质
    const int big = 400;
    std::vector<std::vector<int>> ga(static_cast<std::size_t>(big));
    for (int i = 1; i < big; ++i) {
        const int j = static_cast<int>(center_rand(rng,
            static_cast<std::uint32_t>(i)));
        ga[static_cast<std::size_t>(i)].push_back(j);
        ga[static_cast<std::size_t>(j)].push_back(i);
    }
    for (int k = 0; k < 800; ++k) {
        const int u = static_cast<int>(center_rand(rng, big));
        const int v = static_cast<int>(center_rand(rng, big));
        if (u == v || std::ranges::find(ga[static_cast<std::size_t>(u)], v)
            != ga[static_cast<std::size_t>(u)].end()) { continue; }
        ga[static_cast<std::size_t>(u)].push_back(v);
        ga[static_cast<std::size_t>(v)].push_back(u);
    }
    const Mat bdist = bfs_all_pairs(ga);
    std::vector<int> be(static_cast<std::size_t>(big), 0);
    for (int v = 0; v < big; ++v) {
        for (int u = 0; u < big; ++u) {
            be[static_cast<std::size_t>(v)] = std::max(
                be[static_cast<std::size_t>(v)],
                bdist[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)]);
        }
    }
    const int br = *std::ranges::min_element(be);
    int ncenters = 0;
    for (int v = 0; v < big; ++v) {
        if (be[static_cast<std::size_t>(v)] == br) {
            ++ncenters;
            for (int u = 0; u < big; ++u) {
                assert(bdist[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)] <= br);
            }
        }
    }
    println("  大例（n=400 随机连通图）：半径 {}，中心 {} 个（中心到每点 ≤半径已逐点核）",
            br, ncenters);
}

int main() {
    fw_demo();
    closure_demo();
    vs_dijkstra_demo();
    center_demo();
    println("自检通过");
    return 0;
}
