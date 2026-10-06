// 23 基本图算法（CLRS 第 22 章）。结构：23.1 邻接表表示与度统计 /
// 23.2 BFS（图 22.3：距离与 BFS 树）/ 23.3 DFS 时间戳与边分类
//（图 22.4/22.5）/ 23.4 拓扑排序（DAG）/ 23.5 强连通分量（图 22.9）……
// 23.13 图的两个计数问题：握手定理判谎（1-9）、状态空间 BFS（1-6）/
// 23.14 旅程（树上 2W−最远目标距离，就近贪心对照）/
// 23.15 循序（全体拓扑序字典序枚举，位置区间误法对照）/
// 23.16 最优工程布线（网格 BFS、围墙技巧与路径逆向重建）/
// 23.17 八数字谜题：隐式图 BFS（状态编码、逆序对可解性、IDA* 对账）。
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
#include <cmath>
#include <cstdlib>
#include <deque>
#include <functional>
#include <limits>
#include <numeric>
#include <queue>
#include <random>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

// 可移植随机（docs/01 的纪律：不用 uniform_int_distribution）
static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    return static_cast<std::uint32_t>(
        (static_cast<std::uint64_t>(rng()) * n) >> 32);
}

// 图 22.3 的无向图：顶点 r s t u v w x y（映射为 0..7）
// 边：r-s r-v s-v s-w w-t w-x t-x t-u u-x u-y x-y
struct Graph {
    int n;
    std::vector<std::vector<int>> adj;
    explicit Graph(int n_, const std::vector<std::pair<int, int>>& edges)
        : n(n_), adj(static_cast<std::size_t>(n_)) {
        for (auto [a, b] : edges) {
            adj[static_cast<std::size_t>(a)].push_back(b);
            adj[static_cast<std::size_t>(b)].push_back(a); // 无向
        }
    }
};

static const std::array<const char*, 8> kName{"r", "s", "t", "u", "v", "w", "x", "y"};

static Graph fig223() {
    return Graph(8, {{0, 1}, {0, 4}, {1, 4}, {1, 5}, {5, 2}, {5, 6},
                     {2, 6}, {2, 3}, {3, 6}, {3, 7}, {6, 7}});
}

static void representation_demo() {
    const Graph g = fig223();
    println("邻接表表示（图 22.3 的 8 顶点 11 边无向图）：");
    for (int v = 0; v < g.n; ++v) {
        print("  {}: ", kName[static_cast<std::size_t>(v)]);
        for (int u : g.adj[static_cast<std::size_t>(v)]) { print("{} ", kName[static_cast<std::size_t>(u)]); }
        println("");
    }
    // 度统计：图 22.3 的握手定理 Σdeg = 2|E| = 22
    long long deg = 0;
    for (int v = 0; v < g.n; ++v) { deg += static_cast<long long>(g.adj[static_cast<std::size_t>(v)].size()); }
    println("Σ度 = {}（握手定理 = 2|E| = 22）", deg);
    assert(deg == 22);
}

// ═══ 23.2 BFS ═══
struct BfsResult { std::vector<int> dist, parent; };

static BfsResult bfs(const Graph& g, int s) {
    BfsResult r;
    r.dist.assign(static_cast<std::size_t>(g.n), -1);
    r.parent.assign(static_cast<std::size_t>(g.n), -1);
    r.dist[static_cast<std::size_t>(s)] = 0;
    std::deque<int> q{s};
    while (!q.empty()) {
        const int u = q.front();
        q.pop_front();
        for (int v : g.adj[static_cast<std::size_t>(u)]) {
            if (r.dist[static_cast<std::size_t>(v)] == -1) {
                r.dist[static_cast<std::size_t>(v)] = r.dist[static_cast<std::size_t>(u)] + 1;
                r.parent[static_cast<std::size_t>(v)] = u;
                q.push_back(v);
            }
        }
    }
    return r;
}

static void bfs_demo() {
    const Graph g = fig223();
    const auto r = bfs(g, 1);   // CLRS 从 s 出发
    println("BFS（从 s 出发，图 22.3 的距离场）：");
    print("  dist: ");
    for (int v = 0; v < g.n; ++v) { print("{}={} ", kName[static_cast<std::size_t>(v)], r.dist[static_cast<std::size_t>(v)]); }
    println("");
    // 图 22.3 的答案：r=1 s=0 t=2 u=3 v=2 w=1 x=2 y=3
    assert((r.dist == std::vector<int>{1, 0, 2, 3, 1, 1, 2, 3}));
    // BFS 树路径：s→w→x→y
    std::vector<int> path;
    for (int v = 7; v != -1; v = r.parent[static_cast<std::size_t>(v)]) { path.push_back(v); }
    std::ranges::reverse(path);
    print("  s→y 的 BFS 树路径: ");
    for (int v : path) { print("{} ", kName[static_cast<std::size_t>(v)]); }
    println("");
    assert((path == std::vector<int>{1, 5, 6, 7}));   // s→w→x→y
}

// ═══ 23.3 DFS 时间戳与边分类 ═══
struct DfsResult {
    std::vector<int> disc, finish, parent;
    long long time = 0;
    std::vector<std::pair<int, int>> treeEdges, backEdges, fwdCross;
};

static void dfs_visit(const Graph& g, int u, DfsResult& r) {
    r.disc[static_cast<std::size_t>(u)] = static_cast<int>(++r.time);
    for (int v : g.adj[static_cast<std::size_t>(u)]) {
        if (r.disc[static_cast<std::size_t>(v)] == -1) {
            r.parent[static_cast<std::size_t>(v)] = u;
            r.treeEdges.emplace_back(u, v);
            dfs_visit(g, v, r);
        } else if (v == r.parent[static_cast<std::size_t>(u)]) {
            // 无向图：树边的反向弧（回到父亲）跳过——不算后向边
        } else if (r.finish[static_cast<std::size_t>(v)] == -1) {
            r.backEdges.emplace_back(u, v);       // 灰色 = 后向边（成环）
        } else {
            // 黑色相遇：无向图里这是「某条已记为后向边的边」的反向弧
            //（先探索的一侧当时看到灰色）——去重，不再记录
        }
    }
    r.finish[static_cast<std::size_t>(u)] = static_cast<int>(++r.time);
}

static DfsResult dfs(const Graph& g) {
    DfsResult r;
    r.disc.assign(static_cast<std::size_t>(g.n), -1);
    r.finish.assign(static_cast<std::size_t>(g.n), -1);
    r.parent.assign(static_cast<std::size_t>(g.n), -1);
    for (int u = 0; u < g.n; ++u) {
        if (r.disc[static_cast<std::size_t>(u)] == -1) { dfs_visit(g, u, r); }
    }
    return r;
}

static void dfs_demo() {
    const Graph g = fig223();
    const auto r = dfs(g);
    println("DFS（图 22.3 无向图，括号化时间戳）：");
    print("  disc/finish: ");
    for (int v = 0; v < g.n; ++v) {
        print("{}={}/{} ", kName[static_cast<std::size_t>(v)], r.disc[static_cast<std::size_t>(v)],
              r.finish[static_cast<std::size_t>(v)]);
    }
    println("");
    // 括号化定理：任意两点的区间要么嵌套要么不相交
    bool nested = true;
    for (int a = 0; a < g.n; ++a) {
        for (int b = 0; b < g.n; ++b) {
            if (a == b) { continue; }
            const int da = r.disc[static_cast<std::size_t>(a)], fa = r.finish[static_cast<std::size_t>(a)];
            const int db = r.disc[static_cast<std::size_t>(b)], fb = r.finish[static_cast<std::size_t>(b)];
            const bool interleave = (da < db && db < fa && fa < fb) || (db < da && da < fb && fb < fa);
            if (interleave) { nested = false; }
        }
    }
    println("  括号化定理（区间嵌套或不相交）= {}", nested ? 1 : 0);
    assert(nested);
    // 无向图的边分类：树边 + 后向边（无向图没有交叉/前向）
    println("  树边 {} 条（生成树），后向边 {} 条（成环判据：11 边 − 7 树边 = 4）",
            r.treeEdges.size(), r.backEdges.size());
    assert(r.treeEdges.size() == 7 && r.backEdges.size() == 4 && r.fwdCross.empty());
}

// ═══ 23.4 拓扑排序 ═══
// 小型 DAG：穿衣顺序的缩影（内裤→裤子→鞋；袜子→鞋；衬衣→腰带→外套）
static void topo_demo() {
    // 0=内裤 1=裤子 2=袜子 3=鞋 4=衬衣 5=腰带 6=外套
    const std::vector<std::pair<int, int>> dagEdges{
        {0, 1}, {1, 3}, {2, 3}, {4, 5}, {5, 6}, {1, 5}};
    const int n = 7;
    std::vector<std::vector<int>> adj(static_cast<std::size_t>(n));
    std::vector<int> indeg(static_cast<std::size_t>(n), 0);
    for (auto [a, b] : dagEdges) {
        adj[static_cast<std::size_t>(a)].push_back(b);
        ++indeg[static_cast<std::size_t>(b)];
    }
    // Kahn 算法（练习 22.4-2）：反复摘零入度点
    std::vector<int> order;
    std::deque<int> q;
    for (int i = 0; i < n; ++i) {
        if (indeg[static_cast<std::size_t>(i)] == 0) { q.push_back(i); }
    }
    while (!q.empty()) {
        const int u = q.front();
        q.pop_front();
        order.push_back(u);
        for (int v : adj[static_cast<std::size_t>(u)]) {
            if (--indeg[static_cast<std::size_t>(v)] == 0) { q.push_back(v); }
        }
    }
    assert(static_cast<int>(order.size()) == n);   // DAG ⇨ 全部排出
    println("拓扑排序（穿衣 DAG，Kahn 零入度法）：");
    println("  序列（0 内裤 1 裤子 2 袜子 3 鞋 4 衬衣 5 腰带 6 外套）: "
            "{} {} {} {} {} {} {}", order[0], order[1], order[2], order[3], order[4], order[5], order[6]);
    // 验证每条边 u→v 都满足 u 在 v 前
    bool valid = true;
    std::vector<int> pos(static_cast<std::size_t>(n));
    for (std::size_t i = 0; i < order.size(); ++i) { pos[static_cast<std::size_t>(order[i])] = static_cast<int>(i); }
    for (auto [a, b] : dagEdges) {
        if (pos[static_cast<std::size_t>(a)] >= pos[static_cast<std::size_t>(b)]) { valid = false; }
    }
    assert(valid);
    println("  全部 6 条边 u→v 均满足 pos(u) < pos(v) = 1");
}

// ═══ 23.5 强连通分量（图 22.9）═══
// 顶点 a b c d e f g h = 0..7；边（图 22.9(a)）：
// a→b b→c b→e b→f c→d c→g d→c d→h e→a e→f f→g g→f g→h h→h? (h 无自环)
// SCC：{a,b,e} {c,d} {f,g} {h}
static std::vector<std::vector<int>> fig229() {
    std::vector<std::vector<int>> adj(8);
    auto add = [&](int a, int b) { adj[static_cast<std::size_t>(a)].push_back(b); };
    add(0, 1); add(1, 2); add(1, 4); add(1, 5); add(2, 3); add(2, 6);
    add(3, 2); add(3, 7); add(4, 0); add(4, 5); add(5, 6); add(6, 5); add(6, 7);
    return adj;
}

// Kosaraju：DFS 取完成时间倒序，在转置图上下一次 DFS，每棵树一个 SCC
static std::vector<std::vector<int>> kosaraju(const std::vector<std::vector<int>>& adj) {
    const int n = static_cast<int>(adj.size());
    std::vector<int> finish(static_cast<std::size_t>(n), -1);
    std::vector<char> seen(static_cast<std::size_t>(n), 0);
    long long time = 0;
    auto dfs1 = [&](this auto&& self, int u) -> void {
        seen[static_cast<std::size_t>(u)] = 1;
        for (int v : adj[static_cast<std::size_t>(u)]) {
            if (!seen[static_cast<std::size_t>(v)]) { self(v); }
        }
        finish[static_cast<std::size_t>(u)] = static_cast<int>(time++);
    };
    for (int u = 0; u < n; ++u) {
        if (!seen[static_cast<std::size_t>(u)]) { dfs1(u); }
    }
    // 转置图
    std::vector<std::vector<int>> radj(static_cast<std::size_t>(n));
    for (int u = 0; u < n; ++u) {
        for (int v : adj[static_cast<std::size_t>(u)]) { radj[static_cast<std::size_t>(v)].push_back(u); }
    }
    std::vector<int> order(static_cast<std::size_t>(n));
    std::iota(order.begin(), order.end(), 0);
    std::ranges::sort(order, [&](int a, int b) {
        return finish[static_cast<std::size_t>(a)] > finish[static_cast<std::size_t>(b)];
    });
    std::vector<std::vector<int>> sccs;
    std::vector<char> vis(static_cast<std::size_t>(n), 0);
    auto dfs2 = [&](this auto&& self, int u, std::vector<int>& comp) -> void {
        vis[static_cast<std::size_t>(u)] = 1;
        comp.push_back(u);
        for (int v : radj[static_cast<std::size_t>(u)]) {
            if (!vis[static_cast<std::size_t>(v)]) { self(v, comp); }
        }
    };
    for (int u : order) {
        if (!vis[static_cast<std::size_t>(u)]) {
            sccs.emplace_back();
            dfs2(u, sccs.back());
        }
    }
    return sccs;
}

static void scc_demo() {
    static const std::array<const char*, 8> abc{"a", "b", "c", "d", "e", "f", "g", "h"};
    const auto adj = fig229();
    auto sccs = kosaraju(adj);
    for (auto& c : sccs) { std::ranges::sort(c); }
    std::ranges::sort(sccs, [](auto& a, auto& b) { return a.front() < b.front(); });
    println("强连通分量（图 22.9，Kosaraju 两遍 DFS）：");
    print("  ");
    for (auto& c : sccs) {
        print("{{");
        for (std::size_t i = 0; i < c.size(); ++i) {
            print("{}{}", i == 0 ? "" : ",", abc[static_cast<std::size_t>(c[i])]);
        }
        print("}} ");
    }
    println("");
    assert(sccs.size() == 4);
    assert((sccs[0] == std::vector<int>{0, 1, 4}));   // a b e
    assert((sccs[1] == std::vector<int>{2, 3}));       // c d
    assert((sccs[2] == std::vector<int>{5, 6}));       // f g
    assert((sccs[3] == std::vector<int>{7}));          // h
    println("  四个 SCC 与图 22.9 一致：{{a,b,e}} {{c,d}} {{f,g}} {{h}}");
}

// ════════════════════════════════════════════════════════════════════
// 23.6 割点与桥：一次 Tarjan 搞定（迭代版 + 边 id 判父边）
// ════════════════════════════════════════════════════════════════════
// 无向图（允许重边）。adj[u] 存 {邻居, 边 id}——边 id 是判父边的唯一
// 正确依据，顶点颜色/父顶点都不行。
struct MGraph {
    int n = 0;
    std::vector<std::vector<std::pair<int, int>>> adj;   // {v, edgeId}
    std::vector<std::pair<int, int>> ends;                // edgeId -> {u, v}
    MGraph() = default;
    MGraph(int n_, std::vector<std::pair<int, int>> es) : n(n_), adj(static_cast<std::size_t>(n_)) {
        for (auto [a, b] : es) { addEdge(a, b); }
    }
    void addEdge(int a, int b) {
        const int id = static_cast<int>(ends.size());
        ends.emplace_back(a, b);
        adj[static_cast<std::size_t>(a)].emplace_back(b, id);
        adj[static_cast<std::size_t>(b)].emplace_back(a, id);
    }
    void sortAdjByEdgeId() {   // 字典序最小欧拉回路的前提
        for (auto& lst : adj) {
            std::ranges::sort(lst, [](const auto& x, const auto& y) { return x.second < y.second; });
        }
    }
    MGraph withoutVertex(int ban) const {
        MGraph h(n, {});
        for (auto [a, b] : ends) {
            if (a != ban && b != ban) { h.addEdge(a, b); }
        }
        return h;
    }
};

struct BccResult {
    std::vector<int> d, low, parent, parentEdge, childCnt, depth;
    std::vector<char> isArt;       // 按顶点
    std::vector<char> isBridge;    // 按边 id
    int bridges = 0;
    int timer = 0;
};

// 迭代 Tarjan：显式栈 + 游标 cur[] 模拟递归回溯。n = 10^5 也不会爆栈。
static BccResult tarjanBcc(const MGraph& g) {
    const std::size_t n = static_cast<std::size_t>(g.n);
    BccResult r;
    r.d.assign(n, 0);
    r.low.assign(n, 0);
    r.parent.assign(n, -1);
    r.parentEdge.assign(n, -1);
    r.childCnt.assign(n, 0);
    r.depth.assign(n, 0);
    r.isArt.assign(n, 0);
    r.isBridge.assign(g.ends.size(), 0);
    std::vector<std::size_t> cur(n, 0);
    std::vector<int> stk;
    stk.reserve(n);
    for (int s = 0; s < g.n; ++s) {
        const std::size_t su = static_cast<std::size_t>(s);
        if (r.d[su] != 0) { continue; }
        r.d[su] = r.low[su] = ++r.timer;
        r.depth[su] = 1;
        stk.push_back(s);
        while (!stk.empty()) {
            const int u = stk.back();
            const std::size_t suu = static_cast<std::size_t>(u);
            if (cur[suu] < g.adj[suu].size()) {          // 还没扫完邻域：下潜
                const auto [v, eid] = g.adj[suu][cur[suu]++];
                const std::size_t sv = static_cast<std::size_t>(v);
                if (eid == r.parentEdge[suu]) { continue; }   // ★ 判父边用边 id
                if (r.d[sv] == 0) {
                    r.parent[sv] = u;
                    r.parentEdge[sv] = eid;
                    ++r.childCnt[suu];
                    r.depth[sv] = r.depth[suu] + 1;
                    r.d[sv] = r.low[sv] = ++r.timer;
                    stk.push_back(v);
                } else {
                    r.low[suu] = std::min(r.low[suu], r.d[sv]);
                }
            } else {                                     // 邻域扫完：回溯
                stk.pop_back();
                if (r.parent[suu] != -1) {
                    const std::size_t sp = static_cast<std::size_t>(r.parent[suu]);
                    r.low[sp] = std::min(r.low[sp], r.low[suu]);
                    // 割点用 ≥，且只对非根生效（根另有判据）
                    if (r.low[suu] >= r.d[sp] && r.parent[sp] != -1) { r.isArt[sp] = 1; }
                    // 桥用 > ：连 u 都回不去
                    if (r.low[suu] > r.d[sp]) {
                        r.isBridge[static_cast<std::size_t>(r.parentEdge[suu])] = 1;
                        ++r.bridges;
                    }
                }
            }
        }
    }
    for (int s = 0; s < g.n; ++s) {   // 根的特殊判定：孩子数 ≥ 2
        const std::size_t ss = static_cast<std::size_t>(s);
        if (r.parent[ss] == -1 && r.childCnt[ss] >= 2) { r.isArt[ss] = 1; }
    }
    return r;
}

// 错误直觉版：判父边用「父顶点相等」。重边一出现就错。
static int naiveBridgeCountByParentVertex(const MGraph& g) {
    const std::size_t n = static_cast<std::size_t>(g.n);
    std::vector<int> d(n, 0), low(n, 0), parent(n, -1), childCnt(n, 0);
    std::vector<std::size_t> cur(n, 0);
    std::vector<int> stk;
    int timer = 0, bridges = 0;
    for (int s = 0; s < g.n; ++s) {
        const std::size_t su = static_cast<std::size_t>(s);
        if (d[su] != 0) { continue; }
        d[su] = low[su] = ++timer;
        stk.push_back(s);
        while (!stk.empty()) {
            const int u = stk.back();
            const std::size_t suu = static_cast<std::size_t>(u);
            if (cur[suu] < g.adj[suu].size()) {
                const auto [v, eid] = g.adj[suu][cur[suu]++];
                const std::size_t sv = static_cast<std::size_t>(v);
                (void)eid;
                if (v == parent[suu]) { continue; }   // ✘ 错在这里：把重边也当父边丢了
                if (d[sv] == 0) {
                    parent[sv] = u; ++childCnt[suu];
                    d[sv] = low[sv] = ++timer;
                    stk.push_back(v);
                } else {
                    low[suu] = std::min(low[suu], d[sv]);
                }
            } else {
                stk.pop_back();
                if (parent[suu] != -1) {
                    const std::size_t sp = static_cast<std::size_t>(parent[suu]);
                    low[sp] = std::min(low[sp], low[suu]);
                    if (low[suu] > d[sp]) { ++bridges; }
                }
            }
        }
    }
    return bridges;
}

static void tarjan_demo() {
    // 「蝴蝶结 + 尾巴」：0-1-2-0 与 3-4-5-3 两个三角形经 (2,3) 相连，再挂 5-6。
    // 割点 = {2, 3, 5}，桥 = {(2,3), (5,6)}。
    const MGraph g(7, {{0, 1}, {1, 2}, {2, 0}, {2, 3}, {3, 4}, {4, 5}, {5, 3}, {5, 6}});
    const BccResult r = tarjanBcc(g);
    println("Tarjan 割点与桥（迭代版：显式栈 + 游标）：");
    print("  d[]/low[]: ");
    for (int v = 0; v < g.n; ++v) {
        print("{}=[{}, {}] ", v, r.d[static_cast<std::size_t>(v)], r.low[static_cast<std::size_t>(v)]);
    }
    println("");
    print("  割点（low[w] ≥ d[u] 或根孩子数 ≥ 2）: ");
    for (int v = 0; v < g.n; ++v) {
        if (r.isArt[static_cast<std::size_t>(v)]) { print("{} ", v); }
    }
    println("");
    print("  桥（low[v] > d[u]）: ");
    for (std::size_t e = 0; e < g.ends.size(); ++e) {
        if (r.isBridge[e]) { print("({}, {}) ", g.ends[e].first, g.ends[e].second); }
    }
    println("");
    println("  桥数 = {}", r.bridges);
    assert(r.bridges == 2);
    {
        std::vector<int> art;
        for (int v = 0; v < g.n; ++v) {
            if (r.isArt[static_cast<std::size_t>(v)]) { art.push_back(v); }
        }
        assert((art == std::vector<int>{2, 3, 5}));
    }
    // ≥ 与 > 的分水岭：顶点 3 与树孩子 4。low[4] = 4 = d[3]，回边 5→3 只回到 3 自身。
    println("  ≥ 与 > 的分水岭：low[4] = {} = d[3] —— 边 (3,4) 不成桥（> 不成立），"
            "但 3 是割点（≥ 成立）", r.low[4]);

    // 重边坑：0-1 有两条平行边 + 1-2。正确答案 1 条桥；按父顶点判父边会得 2。
    const MGraph mg(3, {{0, 1}, {0, 1}, {1, 2}});
    const BccResult mr = tarjanBcc(mg);
    const int wrong = naiveBridgeCountByParentVertex(mg);
    println("  重边坑（0-1 两条平行边 + 1-2）：边 id 判父边 = {} 条桥，"
            "父顶点判父边 = {} 条桥（多算一条）", mr.bridges, wrong);
    assert(mr.bridges == 1);
    assert(wrong == 2);

    // 栈深度安全：160 000 个点的全连通网格，递归必爆栈，迭代版照跑。
    const int big = 400;
    MGraph grid(big * big, {});
    for (int rIdx = 0; rIdx < big; ++rIdx) {
        for (int c = 0; c < big; ++c) {
            const int u = rIdx * big + c;
            if (c + 1 < big) { grid.addEdge(u, u + 1); }
            if (rIdx + 1 < big) { grid.addEdge(u, u + big); }
        }
    }
    const BccResult gr = tarjanBcc(grid);
    println("  栈安全：{} 顶点 {} 边的网格，迭代 Tarjan 桥数 = {}（深度 {} 的链），"
            "递归版在 10^5 量级必爆栈", big * big, grid.ends.size(), gr.bridges, gr.timer);
    assert(gr.timer == big * big);
    assert(gr.bridges == 0);
}

// ════════════════════════════════════════════════════════════════════
// 23.7 欧拉回路：Hierholzer 与无向边的有向化
// ════════════════════════════════════════════════════════════════════
// 弧集上的 Hierholzer（迭代）。adj[u] = {v, arcId}，arcId ∈ [0, arcCount)。
// 返回走弧的 id 序列（长度 = 成功时 arcCount），失败（起终点不同）时长度 < arcCount。
static std::vector<int> hierholzerArc(const std::vector<std::vector<std::pair<int, int>>>& adj,
                                      int arcCount, int start) {
    std::vector<std::size_t> cur(adj.size(), 0);
    std::vector<char> used(static_cast<std::size_t>(arcCount), 0);
    std::vector<int> vstk;    // 顶点栈
    std::vector<int> astk;    // 与 vstk 同步：进入该顶点所用的弧
    std::vector<int> out;
    vstk.push_back(start);
    astk.push_back(-1);
    while (!vstk.empty()) {
        const int u = vstk.back();
        const std::size_t su = static_cast<std::size_t>(u);
        while (cur[su] < adj[su].size() && used[static_cast<std::size_t>(adj[su][cur[su]].second)]) { ++cur[su]; }
        if (cur[su] == adj[su].size()) {
            out.push_back(astk.back());          // 逆序出栈
            vstk.pop_back();
            astk.pop_back();
        } else {
            const auto [v, aid] = adj[su][cur[su]++];
            used[static_cast<std::size_t>(aid)] = 1;
            vstk.push_back(v);
            astk.push_back(aid);
        }
    }
    std::ranges::reverse(out);                    // ★ 逆序出栈才是回路顺序
    if (!out.empty() && out.front() == -1) { out.erase(out.begin()); }
    return out;
}

static std::vector<int> hierholzerUndirected(const MGraph& g, int start) {
    return hierholzerArc(g.adj, static_cast<int>(g.ends.size()), start);
}

// 朴素走法：每次取编号最小的未用边，走到无路可走就停。
// 这在有桥的图上会「半途卡死」——它给出的不是欧拉回路。
static std::vector<int> naiveWalk(const MGraph& g, int start) {
    std::vector<char> used(g.ends.size(), 0);
    std::vector<int> walk;
    int u = start;
    for (;;) {
        int picked = -1;
        for (auto [v, eid] : g.adj[static_cast<std::size_t>(u)]) {
            if (!used[static_cast<std::size_t>(eid)]) { picked = eid; break; }
        }
        if (picked == -1) { break; }
        used[static_cast<std::size_t>(picked)] = 1;
        const auto [a, b] = g.ends[static_cast<std::size_t>(picked)];
        u = (u == a) ? b : a;
        walk.push_back(picked);
    }
    return walk;
}

// 暴力枚举全部欧拉回路，返回字典序最小的那条（仅用于小图对账）。
static std::vector<int> bruteLexMinEuler(const MGraph& g, int start) {
    const std::size_t m = g.ends.size();
    std::vector<char> used(m, 0);
    std::vector<int> cur;
    std::vector<int> best;
    long long budget = 2000000;   // 剪枝：枚举量爆炸就放弃对账
    std::function<void(int)> dfs = [&](int u) {
        if (budget <= 0) { return; }
        if (cur.size() == m) {
            --budget;
            if (best.empty() || cur < best) { best = cur; }
            return;
        }
        for (auto [v, eid] : g.adj[static_cast<std::size_t>(u)]) {
            if (used[static_cast<std::size_t>(eid)]) { continue; }
            used[static_cast<std::size_t>(eid)] = 1;
            cur.push_back(eid);
            dfs(v);
            cur.pop_back();
            used[static_cast<std::size_t>(eid)] = 0;
        }
    };
    dfs(start);
    return best;
}

static void euler_demo() {
    // 0-1-2-0 三角形 + 1-3-4-1 三角形，共 6 条边（边号 1..6），起点取 1 号边较小端点 = 0。
    MGraph g(5, {{0, 1}, {1, 2}, {2, 0}, {1, 3}, {3, 4}, {4, 1}});
    std::vector<int> deg;
    bool allEven = true;
    for (int v = 0; v < g.n; ++v) {
        const int d = static_cast<int>(g.adj[static_cast<std::size_t>(v)].size());
        deg.push_back(d);
        if (d % 2 != 0) { allEven = false; }
    }
    println("欧拉回路（无向图：连通 + 每点度偶）：");
    print("  5 顶点 6 边，每点度 = ");
    for (int d : deg) { print("{} ", d); }
    println("—— 度偶条件{}", allEven ? "成立" : "不成立");
    assert((deg == std::vector<int>{2, 4, 2, 2, 2}));
    assert(allEven);

    // ① 任意欧拉回路：按邻接表的插入序取边
    const std::vector<int> any = hierholzerUndirected(g, 0);
    print("  任意回路（插入序取边）边号: ");
    for (int e : any) { print("{} ", e + 1); }
    println("");
    assert(any.size() == g.ends.size());

    // ② 字典序最小：邻接表按边 id 升序 + 同样的 Hierholzer（回溯时才体现「升序」的价值）
    MGraph gh = g;
    gh.sortAdjByEdgeId();
    const std::vector<int> lex = hierholzerUndirected(gh, 0);
    print("  字典序最小回路（升序选边）边号: ");
    for (int e : lex) { print("{} ", e + 1); }
    println("");
    assert(lex.size() == g.ends.size());
    // 逐边对账：从 0 出发按该序列走，必须回到 0 且每条边恰好一次
    {
        int cur = 0;
        std::vector<char> seen(g.ends.size(), 0);
        for (int e : lex) {
            const auto [a, b] = g.ends[static_cast<std::size_t>(e)];
            assert(cur == a || cur == b);
            cur = (cur == a) ? b : a;
            assert(!seen[static_cast<std::size_t>(e)]);
            seen[static_cast<std::size_t>(e)] = 1;
        }
        assert(cur == 0);
        const std::vector<int> lexRef{0, 3, 4, 5, 1, 2};
        assert(lex == lexRef);
    }
    // 升序选边确实给出字典序最小 ⟹ 暴力枚举全部欧拉回路对账
    {
        const std::vector<int> bf = bruteLexMinEuler(gh, 0);
        println("  暴力枚举全部欧拉回路，字典序最小者: ");
        for (int e : bf) { print("{} ", e + 1); }
        println("");
        assert(!bf.empty());
        assert(lex == bf);
    }

    // ③ 「一路走到卡死」的朴素走法：有桥的图上一定失败。
    //    0-1-2 成环 + 桥 2-3 + 3-4 成环，起点 0。
    const MGraph t(5, {{0, 1}, {1, 2}, {2, 0}, {2, 3}, {3, 4}});
    MGraph th = t;
    th.sortAdjByEdgeId();
    const std::vector<int> naive = naiveWalk(th, 0);
    const std::vector<int> hz = hierholzerUndirected(th, 0);
    println("  有桥图上对比：朴素走到卡死用了 {} 条边（剩 {} 条没用），Hierholzer 用满 {} 条",
            naive.size(), t.ends.size() - naive.size(), hz.size());
    assert(naive.size() < t.ends.size());   // 朴素法确实卡在半路
    assert(hz.size() == t.ends.size());     // Hierholzer 靠回溯把子回路拼上

    // ④ 双欧拉回路：每条无向边拆成两条反向有向弧 ⟹ 任何连通无向图都有解。
    //    端点度为奇的路径图连单回路都不存在，双回路却恒有解。
    const MGraph path(4, {{0, 1}, {1, 2}, {2, 3}});
    std::vector<std::vector<std::pair<int, int>>> dAdj(4);
    std::vector<std::pair<int, int>> dEnds;
    for (auto [a, b] : path.ends) {
        const int id = static_cast<int>(dEnds.size());
        dEnds.emplace_back(a, b);
        dAdj[static_cast<std::size_t>(a)].emplace_back(b, id);
        const int id2 = static_cast<int>(dEnds.size());
        dEnds.emplace_back(b, a);
        dAdj[static_cast<std::size_t>(b)].emplace_back(a, id2);
    }
    const std::vector<int> dbl = hierholzerArc(dAdj, static_cast<int>(dEnds.size()), 0);
    int vcur = 0;
    std::vector<int> dblVerts{0};
    for (int aid : dbl) {
        const auto [a, b] = dEnds[static_cast<std::size_t>(aid)];
        vcur = (vcur == a) ? b : a;
        dblVerts.push_back(vcur);
    }
    println("  双欧拉回路（每条边走两次，{} 边路径图，端点度为奇）顶点数 = {}，终点 = {}：",
            path.ends.size(), dblVerts.size(), vcur);
    for (int v : dblVerts) { print("{} ", v); }
    println("");
    assert(dblVerts.size() == 2 * path.ends.size() + 1);
    assert(vcur == 0);
    {   // 每条无向边恰好被走两次
        std::vector<int> cnt(path.ends.size(), 0);
        for (std::size_t i = 1; i < dblVerts.size(); ++i) {
            for (std::size_t e = 0; e < path.ends.size(); ++e) {
                const auto [a, b] = path.ends[e];
                if ((dblVerts[i - 1] == a && dblVerts[i] == b) ||
                    (dblVerts[i - 1] == b && dblVerts[i] == a)) { ++cnt[e]; }
            }
        }
        for (int c : cnt) { assert(c == 2); }
    }
}

// ── 半定向图（单行道 + 双行道方向待定）的线性判定 ──
struct Street { int u, v; bool twoWay; };

static bool tourPossible(int m, const std::vector<Street>& streets, std::string& reason) {
    std::vector<int> delta(static_cast<std::size_t>(m), 0);   // indeg - outdeg（只算单行道）
    std::vector<int> two(static_cast<std::size_t>(m), 0);     // 关联的双行道条数
    std::vector<std::vector<int>> und(static_cast<std::size_t>(m));
    for (const auto& s : streets) {
        und[static_cast<std::size_t>(s.u)].push_back(s.v);
        und[static_cast<std::size_t>(s.v)].push_back(s.u);
        if (s.twoWay) {
            ++two[static_cast<std::size_t>(s.u)];
            ++two[static_cast<std::size_t>(s.v)];
        } else {
            ++delta[static_cast<std::size_t>(s.v)];
            --delta[static_cast<std::size_t>(s.u)];
        }
    }
    for (int u = 0; u < m; ++u) {
        const int d = (delta[static_cast<std::size_t>(u)] >= 0) ? delta[static_cast<std::size_t>(u)]
                                                               : -delta[static_cast<std::size_t>(u)];
        const int a = two[static_cast<std::size_t>(u)];
        if (a < d) {
            reason = "顶点 " + std::to_string(u) + "：双行道 " + std::to_string(a) +
                     " < |Δ| = " + std::to_string(d) + "，补不齐差额";
            return false;
        }
        if ((a - d) % 2 != 0) {
            reason = "顶点 " + std::to_string(u) + "：a − Δ = " + std::to_string(a - d) +
                     " 为奇数，剩下的双行道无法两两成对地一进一出";
            return false;
        }
    }
    std::vector<char> seen(static_cast<std::size_t>(m), 0);
    std::deque<int> q{0};
    seen[0] = 1;
    int cnt = 1;
    while (!q.empty()) {
        const int u = q.front();
        q.pop_front();
        for (int v : und[static_cast<std::size_t>(u)]) {
            if (!seen[static_cast<std::size_t>(v)]) { seen[static_cast<std::size_t>(v)] = 1; ++cnt; q.push_back(v); }
        }
    }
    if (cnt != m) {
        reason = "忽略方向的无向底图不连通（" + std::to_string(cnt) + " / " +
                 std::to_string(m) + " 个路口可达）";
        return false;
    }
    reason = "两条充要条件 + 连通性全部满足";
    return true;
}

static void semidirected_demo() {
    println("半定向图判定（Δ 只算单行道，a = 双行道条数）：");
    struct Case { const char* name; int m; std::vector<Street> streets; bool expect; };
    const std::vector<Case> cases{
        {"双向 0-1 + 单行 1→2 + 双向 2-3 + 单行 3→0（有解，定向成 0→1→2→3→0）",
         4, {{0, 1, true}, {1, 2, false}, {2, 3, true}, {3, 0, false}}, true},
        {"双向 0-1 + 单行 0→2（顶点 1 处 a − Δ = 1 为奇数，无解）",
         3, {{0, 1, true}, {0, 2, false}}, false},
        {"双向 0-1 + 单行 2→0 + 单行 2→1（顶点 2 处 a = 0 < Δ = 2，无解）",
         3, {{0, 1, true}, {2, 0, false}, {2, 1, false}}, false},
    };
    for (const auto& c : cases) {
        std::string reason;
        const bool ok = tourPossible(c.m, c.streets, reason);
        println("  [{}] {}", ok ? "有解" : "无解", c.name);
        println("       判定依据：{}", reason);
        assert(ok == c.expect);
    }
}

// ════════════════════════════════════════════════════════════════════
// 23.8 网格 flood fill（免建图）+ 函数迭代的环检测（Floyd / Brent）
// ════════════════════════════════════════════════════════════════════
struct FloodResult { int components = 0; int largest = 0; long long pushes = 0; };

// 直接在网格上迭代 flood fill：in-place 把访问过的 '*' 改成 '.'，每格只入栈一次 ⟹ Θ(WH)。
static FloodResult floodFill(std::vector<std::string>& grid) {
    const int H = static_cast<int>(grid.size());
    const int W = static_cast<int>(grid[0].size());
    FloodResult res;
    std::vector<int> stk;                       // 显式栈：最坏深度 8 万，递归必爆栈
    stk.reserve(static_cast<std::size_t>(H) * static_cast<std::size_t>(W));
    for (int r0 = 0; r0 < H; ++r0) {
        for (int c0 = 0; c0 < W; ++c0) {
            if (grid[static_cast<std::size_t>(r0)][static_cast<std::size_t>(c0)] != '*') { continue; }
            ++res.components;
            grid[static_cast<std::size_t>(r0)][static_cast<std::size_t>(c0)] = '.';
            stk.push_back(r0 * W + c0);
            int size = 0;
            while (!stk.empty()) {
                const int code = stk.back();
                stk.pop_back();
                ++size;
                ++res.pushes;
                const int r = code / W;
                const int c = code % W;
                const int dr[4] = {-1, 1, 0, 0};
                const int dc[4] = {0, 0, -1, 1};
                for (int k = 0; k < 4; ++k) {
                    const int nr = r + dr[k];
                    const int nc = c + dc[k];
                    if (nr < 0 || nr >= H || nc < 0 || nc >= W) { continue; }
                    if (grid[static_cast<std::size_t>(nr)][static_cast<std::size_t>(nc)] != '*') { continue; }
                    grid[static_cast<std::size_t>(nr)][static_cast<std::size_t>(nc)] = '.';   // 入栈即标记
                    stk.push_back(nr * W + nc);
                }
            }
            res.largest = std::max(res.largest, size);
        }
    }
    return res;
}

struct CycleResult { long long mu = 0; long long lambda = 0; long long steps = 0; };

// Floyd 快慢指针：相遇 → 求 λ → 求 μ，三段各走一遍，共 O(μ + λ) 步、O(1) 空间。
//
// 三段的不变式（第三段最易写错）：
//   ① 相遇：slow 走一步、fast 走**两步**。步数 t 满足 t ≥ μ 且 t ≡ 0 (mod λ) 时首次相遇，
//      相遇点必在环上。
//   ② 求 λ：把一个指针钉在相遇点，另一个绕环一圈数步数。λ 至少为 1，所以计数器从 0
//      开始、每次移动后自增——从 1 起会多算一格。
//   ③ 求 μ：slow 复位到 x0，fast 留在相遇点，两者**都走一步**。它们第一次同时落在
//      x_μ 上 ⟹ 计数器就是 μ。切勿把 fast 也复位成 x0（那会让 μ 恒为 0）。
static CycleResult floydCycle(const std::vector<int>& next, int x0) {
    auto f = [&](int x) { return next[static_cast<std::size_t>(x)]; };
    int slow = f(x0);
    int fast = f(f(x0));
    long long steps = 1;
    while (slow != fast) { slow = f(slow); fast = f(f(fast)); ++steps; }
    const int meet = slow;
    long long lambda = 0;
    fast = meet;
    do { fast = f(fast); ++lambda; } while (fast != meet);
    long long mu = 0;
    slow = x0;                       // fast 留在相遇点
    while (slow != fast) { slow = f(slow); fast = f(fast); ++mu; }
    return {mu, lambda, steps};
}

// Brent：倍增的「 Tortoise/Hare 」，只用一个指针，步数更少。
static CycleResult brentCycle(const std::vector<int>& next, int x0) {
    auto f = [&](int x) { return next[static_cast<std::size_t>(x)]; };
    int power = 1;
    long long lambda = 1;
    int tort = x0;
    int hare = f(x0);
    long long steps = 1;
    while (tort != hare) {
        if (power == lambda) { tort = hare; power *= 2; lambda = 0; }
        hare = f(hare);
        ++lambda;
        ++steps;
    }
    int tort2 = x0;
    int hare2 = x0;
    for (long long i = 0; i < lambda; ++i) { hare2 = f(hare2); }
    long long mu = 0;
    while (tort2 != hare2) { tort2 = f(tort2); hare2 = f(hare2); ++mu; }
    return {mu, lambda, steps};
}

// 参照实现：抽屉原理的直接实现（O(N) 空间），用来对账。
static CycleResult bruteCycle(const std::vector<int>& next, int x0) {
    std::vector<int> first(next.size(), -1);
    int x = x0;
    long long k = 0;
    while (first[static_cast<std::size_t>(x)] == -1) {
        first[static_cast<std::size_t>(x)] = static_cast<int>(k);
        ++k;
        x = next[static_cast<std::size_t>(x)];
    }
    return {first[static_cast<std::size_t>(x)], k - first[static_cast<std::size_t>(x)], k};
}

static void floodfill_demo() {
    std::vector<std::string> grid{
        "*.*....",
        "..*.*..",
        "*...*..",
        "....*.*",
        ".*.....",
    };
    long long stars = 0;
    for (const auto& row : grid) {
        for (char ch : row) { if (ch == '*') { ++stars; } }
    }
    const FloodResult r = floodFill(grid);
    println("网格 flood fill（不显式建图，迭代 + in-place 标记）：");
    println("  5×7 网格共 {} 个 '*'，4-连通块数 = {}，最大块 = {}，总入栈次数 = {}",
            stars, r.components, r.largest, r.pushes);
    assert(stars == 9);
    assert(r.components == 6);
    assert(r.largest == 3);
    assert(r.pushes == stars);   // 每格只入栈一次 ⟹ Θ(WH)

    // 规模对照：160 000 格全连通。显式建图要先两两判相邻，Θ(n²) ≈ 1.28×10^10 次比较。
    const int big = 400;
    std::vector<std::string> bigGrid(static_cast<std::size_t>(big), std::string(static_cast<std::size_t>(big), '*'));
    const FloodResult rb = floodFill(bigGrid);
    const long long n = static_cast<long long>(big) * big;
    const long long pairs = n * (n - 1) / 2;
    println("  规模对照：{}×{} 全 '*' 网格 —— flood fill 入栈 {} 次（Θ(WH)），"
            "先建图要两两判相邻 {} ≈ {:.2}×10^10 次（Θ(n²)）",
            big, big, rb.pushes, pairs, static_cast<double>(pairs) / 1e10);
    assert(rb.pushes == n);
    assert(rb.largest == static_cast<int>(n));

    // ── 函数迭代的环检测 ──
    // 8 个状态上的 f：7→0→1→2→3→4→5→6→3，尾长 μ = 4（7,0,1,2），环长 λ = 4（3,4,5,6）。
    const std::vector<int> next{1, 2, 3, 4, 5, 6, 3, 0};
    std::vector<int> iterPath{7};
    for (int i = 0; i < 9; ++i) { iterPath.push_back(next[static_cast<std::size_t>(iterPath.back())]); }
    print("  迭代轨道 x0 = 7: ");
    for (int v : iterPath) { print("{} ", v); }
    println("");
    const CycleResult bf = bruteCycle(next, 7);
    const CycleResult fl = floydCycle(next, 7);
    const CycleResult br = brentCycle(next, 7);
    println("  抽屉原理：N = 8 个状态，x0..x8 这 9 项必有两项相等 ⟹ 轨道至多含 N 个不同状态，"
            "即 μ + λ ≤ N = 8");
    println("  参照（first[] 数组，O(N) 空间）: μ = {}, λ = {}，访问了 {} 个不同状态", bf.mu, bf.lambda, bf.steps);
    println("  Floyd 快慢指针: μ = {}, λ = {}（相遇阶段 {} 步）", fl.mu, fl.lambda, fl.steps);
    println("  Brent 倍增:     μ = {}, λ = {}（相遇阶段 {} 步）", br.mu, br.lambda, br.steps);
    assert(bf.mu == 4 && bf.lambda == 4);
    assert(fl.mu == 4 && fl.lambda == 4);
    assert(br.mu == 4 && br.lambda == 4);
    assert(bf.steps == 8);          // μ + λ = 8 = N，抽屉原理取到等号
    assert(bf.mu + bf.lambda <= 8);
    // 3→4→5→6→3 的环长也顺手对一下
    {
        int v = 3;
        int len = 0;
        do { v = next[static_cast<std::size_t>(v)]; ++len; } while (v != 3);
        assert(len == 4);
    }
}

// ════════════════════════════════════════════════════════════════════
// 23.9 拓扑排序的两条应用
// ════════════════════════════════════════════════════════════════════
struct DiscResult { int switches = 0; int answer = 0; std::vector<int> order; };

// 最小换碟：闭包贪心「当前介质上还有可装包就继续装」，每条边只处理一次 ⟹ O(V+E)。
static DiscResult minDiscSwitches(int n1, int n2, const std::vector<std::pair<int, int>>& deps) {
    const int n = n1 + n2;
    std::vector<std::vector<int>> succ(static_cast<std::size_t>(n));
    std::vector<int> remaining(static_cast<std::size_t>(n), 0);
    for (auto [x, y] : deps) { succ[static_cast<std::size_t>(x)].push_back(y); ++remaining[static_cast<std::size_t>(y)]; }
    std::vector<int> avail[2];
    for (int v = 0; v < n; ++v) {
        if (remaining[static_cast<std::size_t>(v)] == 0) { avail[v < n1 ? 0 : 1].push_back(v); }
    }
    DiscResult res;
    res.order.reserve(static_cast<std::size_t>(n));
    int cur = 0;
    while (static_cast<int>(res.order.size()) < n) {
        if (avail[cur].empty()) {
            // 当前介质一枚可装包都没有 ⟹ 任何方案都不得不换碟（贪心给出下界）
            if (avail[1 - cur].empty()) { return {-1, -1, {}}; }   // 有环
            cur = 1 - cur;
            ++res.switches;
            continue;
        }
        const int u = avail[cur].back();
        avail[cur].pop_back();
        res.order.push_back(u);
        for (int v : succ[static_cast<std::size_t>(u)]) {
            if (--remaining[static_cast<std::size_t>(v)] == 0) { avail[v < n1 ? 0 : 1].push_back(v); }
        }
    }
    res.answer = res.switches + 2;   // 插入首片计 1 + 取出末片计 1
    return res;
}

// 枚举全部拓扑排序：位掩码 + 升序 DFS ⟹ 输出天然字典序。
static std::vector<std::vector<int>> allTopoOrders(int n, const std::vector<std::pair<int, int>>& edges) {
    assert(n <= 20);
    std::vector<std::uint32_t> pre(static_cast<std::size_t>(n), 0);
    for (auto [a, b] : edges) { pre[static_cast<std::size_t>(b)] |= (std::uint32_t{1} << a); }
    const std::uint32_t full = (std::uint32_t{1} << n) - 1u;
    std::vector<std::vector<int>> out;
    std::vector<int> cur;
    cur.reserve(static_cast<std::size_t>(n));
    std::function<void(std::uint32_t)> dfs = [&](std::uint32_t mask) {
        if (mask == full) { out.push_back(cur); return; }
        for (int i = 0; i < n; ++i) {           // ★ 升序 ⟹ 字典序
            const std::uint32_t bit = std::uint32_t{1} << i;
            const bool done = (mask & bit) != 0;
            const bool ready = (pre[static_cast<std::size_t>(i)] & ~mask) == 0;   // 所有前驱都已输出
            if (done || !ready) { continue; }
            cur.push_back(i);
            dfs(mask | bit);
            cur.pop_back();
        }
    };
    dfs(0);
    return out;
}

static void topo_app_demo() {
    // ── 应用一：最小换碟 ──
    // 3 + 2 = 5 个包（0,1,2 在碟 1；3,4 在碟 2），依赖 3→0、0→2、1→4。
    const std::vector<std::pair<int, int>> deps{{3, 0}, {0, 2}, {1, 4}};
    const DiscResult d = minDiscSwitches(3, 2, deps);
    // 换碟次数 = 相邻异色段数 − 1，段数与段内顺序无关（对账）
    int segs = 1;
    for (std::size_t i = 1; i < d.order.size(); ++i) {
        if ((d.order[i] < 3) != (d.order[i - 1] < 3)) { ++segs; }
    }
    println("拓扑排序应用一：最小换碟（闭包贪心，O(V+E)）：");
    print("  安装序列（0-2 在碟 1，3-4 在碟 2）: ");
    for (int v : d.order) { print("{}{} ", v, v < 3 ? "[1]" : "[2]"); }
    println("");
    println("  换碟次数 = {}，答案 = 换碟 {} + 插入首片 1 + 取出末片 1 = {}", d.switches, d.switches, d.answer);
    assert(d.switches == 2);
    assert(d.answer == 4);
    assert(segs - 1 == d.switches);
    println("  对账：异色段数 {} − 1 = 换碟次数 {}", segs, segs - 1);

    // ── 应用二：枚举全部拓扑排序 ──
    // 4 个变量 a b c d，约束 a<c、b<c、b⟹d（边 0→2、1→2、1→3）。
    const std::vector<std::pair<int, int>> edges{{0, 2}, {1, 2}, {1, 3}};
    const std::vector<std::vector<int>> all = allTopoOrders(4, edges);
    println("拓扑排序应用二：枚举全部拓扑排序（位掩码 + 升序 DFS）：");
    println("  约束 0→2、1→2、1→3，全部拓扑序共 {} 个：", all.size());
    for (const auto& o : all) {
        print("   ");
        for (int v : o) { print("{} ", static_cast<char>('a' + v)); }
        println("");
    }
    assert(all.size() == 5);
    assert((all[0] == std::vector<int>{0, 1, 2, 3}));
    assert((all[1] == std::vector<int>{0, 1, 3, 2}));
    assert((all[4] == std::vector<int>{1, 3, 0, 2}));
    {   // 合法性 + 字典序 + 互不重复，逐项断言
        for (const auto& o : all) {
            for (auto [a, b] : edges) {
                const auto ia = std::ranges::find(o, a);
                const auto ib = std::ranges::find(o, b);
                assert(ia < ib);
            }
        }
        assert(std::ranges::is_sorted(all));
        assert(std::ranges::adjacent_find(all) == all.end());
        // 参照：暴力枚举 4! = 24 个排列数一遍合法者
        std::vector<int> p{0, 1, 2, 3};
        int cnt = 0;
        do {
            std::vector<std::size_t> pos(4);
            for (std::size_t i = 0; i < p.size(); ++i) { pos[static_cast<std::size_t>(p[i])] = i; }
            bool ok = true;
            for (auto [a, b] : edges) { if (pos[static_cast<std::size_t>(a)] > pos[static_cast<std::size_t>(b)]) { ok = false; } }
            if (ok) { ++cnt; }
        } while (std::ranges::next_permutation(p).found);
        assert(cnt == static_cast<int>(all.size()));
        println("  4! 暴力枚举对账：合法排列 {} 个 = 位掩码 DFS 的答案数", cnt);
    }
}

// ════════════════════════════════════════════════════════════════════
// 23.10 割点对计数（分离对）
// ════════════════════════════════════════════════════════════════════
static long long separatingPairsBrute(const MGraph& g) {
    long long total = 0;
    for (int a = 0; a < g.n; ++a) {
        for (int b = a + 1; b < g.n; ++b) {
            // 删掉 a、b 后数连通块
            std::vector<char> seen(static_cast<std::size_t>(g.n), 0);
            int comps = 0;
            for (int s = 0; s < g.n; ++s) {
                if (s == a || s == b || seen[static_cast<std::size_t>(s)]) { continue; }
                ++comps;
                std::deque<int> q{s};
                seen[static_cast<std::size_t>(s)] = 1;
                while (!q.empty()) {
                    const int u = q.front();
                    q.pop_front();
                    for (auto [v, eid] : g.adj[static_cast<std::size_t>(u)]) {
                        (void)eid;
                        if (v == a || v == b || seen[static_cast<std::size_t>(v)]) { continue; }
                        seen[static_cast<std::size_t>(v)] = 1;
                        q.push_back(v);
                    }
                }
            }
            if (comps >= 2) { ++total; }
        }
    }
    return total;
}

// 完整算法 O(n(n+m))，分两部分互不重叠地计数：
//
// 【第一部分】至少含一个割点的点对。
//   设割点集合 A（|A| = m）。"a ∈ A 且 b ≠ a ⟹ G−{a,b} 不连通" 并非无条件成立，
//   唯一的反例是 b 在 G−a 中恰好独占一个连通块，即 deg(b) = 1 且 N(b) = {a}——
//   b 是挂在 a 上的一片叶子。把 a 摘掉本来把 b 隔离了，再把 b 自己也摘掉，隔离就白做了。
//   （连通图中不存在相邻的两个度 1 顶点，所以这些例外点对不会互相重复计数。）
//   于是计数 = m·(n−1) − C(m,2) − |L|，其中 L = { 度 1 且唯一邻居是割点的顶点 }。
//
// 【第二部分】两个端点都不是割点的点对。
//   只要 G−u 连通，就有 "G−{u,v} 不连通 ⟺ v 是 G−u 的割点"（因为 G−u = (G−{u,v}) ∪ {v}，
//   v 在 G−u 里有邻居，所以删 v 恰好把 G−u 切成 (G−{u,v}) 的那些块）。
//   u 不是割点 ⟹ G−u 连通 ⟹ 条件成立。对每个非割点 u 跑一次 Tarjan(G−u)，
//   数出「v 是 G−u 的割点 且 v 也不是 G 的割点」，最后除以 2（无序点对被两个端点各数一次）。
static long long separatingPairs(const MGraph& g) {
    const BccResult r = tarjanBcc(g);
    // ── 第一部分 ──
    long long m = 0;
    for (int v = 0; v < g.n; ++v) { if (r.isArt[static_cast<std::size_t>(v)]) { ++m; } }
    long long total = 0;
    if (m >= 1) {
        long long leaves = 0;   // |L|
        for (int v = 0; v < g.n; ++v) {
            if (g.adj[static_cast<std::size_t>(v)].size() != 1) { continue; }
            const int nb = g.adj[static_cast<std::size_t>(v)].front().first;
            if (r.isArt[static_cast<std::size_t>(nb)]) { ++leaves; }
        }
        total = m * (g.n - 1) - m * (m - 1) / 2 - leaves;
    }
    // ── 第二部分 ──
    long long both = 0;
    for (int u = 0; u < g.n; ++u) {
        if (r.isArt[static_cast<std::size_t>(u)]) { continue; }   // 已由第一部分覆盖
        const MGraph h = g.withoutVertex(u);
        const BccResult hr = tarjanBcc(h);
        for (int v = 0; v < h.n; ++v) {
            if (v != u && !r.isArt[static_cast<std::size_t>(v)] && hr.isArt[static_cast<std::size_t>(v)]) { ++both; }
        }
    }
    return total + both / 2;
}

static void sep_pair_demo() {
    // 情况 A：图有割点 {2,3,5}，n = 7。6 是挂在 5 上的叶子 ⟹ 它是公式的例外点。
    // m·(n−1) − C(m,2) − |L| = 3·6 − 3 − 1 = 14。
    const MGraph a(7, {{0, 1}, {1, 2}, {2, 0}, {2, 3}, {3, 4}, {4, 5}, {5, 3}, {5, 6}});
    const long long ansA = separatingPairs(a);
    const long long refA = separatingPairsBrute(a);
    println("分离对计数（删掉一对顶点后图分裂成 ≥ 2 块）：");
    println("  情况 A（含割点）：割点 3 个（2,3,5），叶子例外 |L| = 1（顶点 6 挂在 5 上）"
            " ⟹ 3×6 − C(3,2) − 1 = {}，暴力对账 {}", ansA, refA);
    assert(ansA == 14);
    assert(ansA == refA);
    // 「m·n − m(m+1)/2 = 15」多算了 {5,6}：摘掉 5 把 6 隔离了，再摘掉 6 隔离就白做了
    {
        const long long naive = 3 * 7 - 3 * 4 / 2;
        println("  错误公式 m·n − m(m+1)/2 = {} —— 多算 {{5,6}}（6 是 5 的叶子）", naive);
        assert(naive == 15);
        assert(naive != refA);
    }
    // 情况 B：K_{{2,3}} 无割点（2-连通但无哈密顿回路）⟹ 只有 {0,1} 一对可分离。
    const MGraph b(5, {{0, 2}, {0, 3}, {0, 4}, {1, 2}, {1, 3}, {1, 4}});
    const long long ansB = separatingPairs(b);
    const long long refB = separatingPairsBrute(b);
    println("  情况 B（K_{{2,3}} 无割点，2-连通但无哈密顿回路）：枚举 u 求 G−u 的割点 = {}，"
            "暴力对账 {}", ansB, refB);
    assert(ansB == 1);
    assert(ansB == refB);
}

// ════════════════════════════════════════════════════════════════════
// 23.11 最小割视角下的桥：Tarjan × 倍增 LCA × 树上差分
// ════════════════════════════════════════════════════════════════════
struct BridgeWatch {
    int n = 0;
    int root = 0;
    int log = 1;
    std::vector<int> parent, parentEdge, depth;
    std::vector<std::vector<int>> up;    // up[k][v] = v 的 2^k 级祖先
    std::vector<char> alive;             // alive[v]：树边 (parent[v], v) 还是桥吗（根是哨兵，恒 1）
    std::vector<char> w;                 // 树边 (parent[v], v) 的原始权（根为 0，供前缀和用）
    std::vector<int> skip;               // 路径压缩的「最近活祖先」指针
    std::vector<long long> pref;         // 原始桥权在根路径上的前缀和
    long long cnt = 0;                   // 当前桥数
};

static BridgeWatch buildWatch(const MGraph& g) {
    const BccResult r = tarjanBcc(g);
    BridgeWatch w;
    w.n = g.n;
    w.root = 0;
    while ((1 << w.log) <= g.n) { ++w.log; }
    const std::size_t n = static_cast<std::size_t>(g.n);
    w.parent = r.parent;
    w.parentEdge = r.parentEdge;
    w.depth = r.depth;
    w.up.assign(static_cast<std::size_t>(w.log), std::vector<int>(n, 0));
    w.alive.assign(n, 0);
    w.w.assign(n, 0);
    w.pref.assign(n, 0);
    w.skip.resize(n);
    for (int v = 0; v < g.n; ++v) {
        const std::size_t sv = static_cast<std::size_t>(v);
        if (r.parent[sv] == -1) {
            w.alive[sv] = 1;                       // 根哨兵：永远「活」，永不失效
            w.w[sv] = 0;                            // 根没有父边，权为 0
            w.pref[sv] = 0;
            w.skip[sv] = v;
            w.up[0][sv] = v;
        } else {
            w.alive[sv] = r.isBridge[static_cast<std::size_t>(r.parentEdge[sv])] ? 1 : 0;
            w.w[sv] = w.alive[sv];
            w.cnt += w.alive[sv];
            w.pref[sv] = w.pref[static_cast<std::size_t>(r.parent[sv])] + w.w[sv];
            w.skip[sv] = r.parent[sv];             // 跳指针初始指向父亲
            w.up[0][sv] = r.parent[sv];
        }
    }
    for (int k = 1; k < w.log; ++k) {
        for (int v = 0; v < g.n; ++v) {
            w.up[static_cast<std::size_t>(k)][static_cast<std::size_t>(v)] =
                w.up[static_cast<std::size_t>(k) - 1]
                 [static_cast<std::size_t>(w.up[static_cast<std::size_t>(k) - 1][static_cast<std::size_t>(v)])];
        }
    }
    return w;
}

static int lcaOf(const BridgeWatch& w, int u, int v) {
    if (w.depth[static_cast<std::size_t>(u)] < w.depth[static_cast<std::size_t>(v)]) { std::swap(u, v); }
    int diff = w.depth[static_cast<std::size_t>(u)] - w.depth[static_cast<std::size_t>(v)];
    for (int k = 0; k < w.log; ++k) {
        if ((diff >> k) & 1) { u = w.up[static_cast<std::size_t>(k)][static_cast<std::size_t>(u)]; }
    }
    if (u == v) { return u; }
    for (int k = w.log - 1; k >= 0; --k) {
        if (w.up[static_cast<std::size_t>(k)][static_cast<std::size_t>(u)] !=
            w.up[static_cast<std::size_t>(k)][static_cast<std::size_t>(v)]) {
            u = w.up[static_cast<std::size_t>(k)][static_cast<std::size_t>(u)];
            v = w.up[static_cast<std::size_t>(k)][static_cast<std::size_t>(v)];
        }
    }
    return w.parent[static_cast<std::size_t>(u)];
}

static long long treeDist(const BridgeWatch& w, int u, int v) {
    const int a = lcaOf(w, u, v);
    return static_cast<long long>(w.depth[static_cast<std::size_t>(u)]) +
           w.depth[static_cast<std::size_t>(v)] -
           2LL * w.depth[static_cast<std::size_t>(a)];
}

// 原始桥在 P(u,v) 上的条数（前缀和 + LCA，O(log N)）。
static long long bridgesOnPath(const BridgeWatch& w, int u, int v) {
    const int a = lcaOf(w, u, v);
    const std::size_t sa = static_cast<std::size_t>(a);
    return w.pref[static_cast<std::size_t>(u)] + w.pref[static_cast<std::size_t>(v)] -
           2LL * w.pref[sa] + w.w[sa];
}

// 找 v 的（含自身）最近「父边仍活」的祖先，标准并查集跳指针 + 路径压缩。
// 不变量：skip[v] 永远指向 v 的某个严格祖先；根的 alive 恒为 1 ⟹ 循环必然终止。
static int findSkip(BridgeWatch& w, int v) {
    int r = v;
    while (!w.alive[static_cast<std::size_t>(r)]) { r = w.skip[static_cast<std::size_t>(r)]; }
    int x = v;
    while (x != r) {
        const int nx = w.skip[static_cast<std::size_t>(x)];
        w.skip[static_cast<std::size_t>(x)] = r;
        x = nx;
    }
    return r;
}

// 加边 (u,v) 后，把两端到 LCA 路径上仍为桥的树边全部「杀死」，返回本次失效数。
// 桥只减不增 ⟹ 每条桥最多被处理一次 ⟹ 全部查询的更新总量 O(N α(N))。
static long long addEdgeKillPath(BridgeWatch& w, int u, int v) {
    const int a = lcaOf(w, u, v);
    const int dl = w.depth[static_cast<std::size_t>(a)];
    long long killed = 0;
    for (int side = 0; side < 2; ++side) {
        int x = findSkip(w, side == 0 ? u : v);
        while (w.depth[static_cast<std::size_t>(x)] > dl) {
            w.alive[static_cast<std::size_t>(x)] = 0;   // 树边 (parent[x], x) 失效
            --w.cnt;
            ++killed;
            x = findSkip(w, w.parent[static_cast<std::size_t>(x)]);
        }
    }
    return killed;
}

// 参照：每次加边后重跑一次完整 Tarjan。
static long long bridgeCountBrute(MGraph g, const std::vector<std::pair<int, int>>& extra) {
    for (auto [a, b] : extra) { g.addEdge(a, b); }
    return tarjanBcc(g).bridges;
}

static void bridge_watch_demo() {
    // 初始图：0-1-2-3-4-5 一条链（5 条边全是桥），再加一条弦 0-4 使 0-1-2-3-4 成环。
    MGraph g(6, {{0, 1}, {1, 2}, {2, 3}, {3, 4}, {4, 5}, {0, 4}});
    const std::vector<std::pair<int, int>> queries{{0, 2}, {1, 3}, {0, 5}, {2, 5}};
    BridgeWatch w = buildWatch(g);
    long long running = w.cnt;
    std::vector<std::pair<int, int>> added;
    println("桥的在线维护（一次 Tarjan + 倍增 LCA + 树上差分）：");
    println("  初始：6 顶点 6 边，桥数 = {}（0-1-2-3-4 已成环，只有 4-5 还是桥）", w.cnt);
    assert(w.cnt == 1);
    long long sumDist = 0;
    for (const auto& [u, v] : queries) {
        sumDist += treeDist(w, u, v);
        const long long onPath = bridgesOnPath(w, u, v);
        const long long killed = addEdgeKillPath(w, u, v);
        running -= killed;
        added.emplace_back(u, v);
        println("  加边 ({}, {})：树上距离 = {}，路径上原有桥 {} 条，本次失效 {} 条，"
                "当前桥数 = {}（重跑 Tarjan = {}）",
                u, v, treeDist(w, u, v), onPath, killed, running, bridgeCountBrute(g, added));
        assert(running == bridgeCountBrute(g, added));
    }
    println("  Σ dist(u,v) = {}（问题 8-9 的答案形式）", sumDist);
    assert(sumDist == 2 + 2 + 5 + 3);
    assert(running == 0);
    // 静态前缀和版：路径上「原始桥」条数与动态查询互不干扰
    assert(bridgesOnPath(w, 4, 5) == 1);
    assert(bridgesOnPath(w, 0, 5) == 1);
}

// ═══ 23.13 图的两个计数问题 ═══

// ── 问题 1-9 聚会游戏：握手定理判谎 ──
// N 人聚会（含主持人 Robin），各报认识的人数（认识互相）。把人当顶点、
// 认识当边：Σd(v) = 2|E| 必为**偶数**（握手定理）。有人报的度数之和为奇
// ⟹ 必有说谎。Robin 认识所有人 ⟹ 他的度恰为 N−1（并要求其余各人 ≥ 1）。
// 奇偶只是**必要**条件：偶和的度序列也可能不可图——此时只能说「Maybe
// truth」。Havel–Hakimi 贪心消解可以补上充分性判定（小 n 可行）。
static bool havel_hakimi(std::vector<int> d) {
    while (!d.empty() && d.back() == 0) { d.pop_back(); }
    while (!d.empty()) {
        std::ranges::sort(d, std::ranges::greater{});
        const int x = d.front();          // 取最大度数
        d.erase(d.begin());
        if (x > static_cast<int>(d.size())) { return false; }   // 连不完
        for (int i = 0; i < x; ++i) {
            if (--d[static_cast<std::size_t>(i)] < 0) { return false; }
        }
        while (!d.empty() && d.back() == 0) { d.pop_back(); }
    }
    return true;
}

static void party_game_demo() {
    println("");
    println("=== 23.13a 聚会游戏（1-9）：握手定理判谎 ===");
    struct Case { std::vector<int> reports; const char* expect; };
    const Case cases[]{
        {{5, 4, 2, 3, 2, 5}, "Lie absolutely"},
        {{3, 4, 2, 2, 2, 3}, "Maybe truth"},
    };
    for (const Case& tc : cases) {
        const std::size_t n = tc.reports.size() + 1;      // + 主持人
        const int robin = static_cast<int>(n) - 1;        // Robin 认识所有人
        long long sum = robin;
        for (int d : tc.reports) { sum += d; }
        const bool parityOk = sum % 2 == 0;
        std::vector<int> seq(tc.reports);
        seq.push_back(robin);
        const bool graphical = parityOk && havel_hakimi(seq);
        print("  N={}：报到 ", n);
        for (int d : tc.reports) { print("{} ", d); }
        println("+ 主持人 {} ⟹ Σ度 = {}（{}）⟹ {}", robin, sum,
                parityOk ? "偶" : "奇",
                parityOk ? (graphical ? "Maybe truth（Havel–Hakimi 可图）"
                                      : "Lie absolutely")
                         : "Lie absolutely");
        assert(sum % 2 == 1 || graphical);
    }
    // 偶和也可能不可图：{2,2,0,0} —— 奇偶只是必要条件
    {
        const std::vector<int> seq{2, 2, 0, 0};
        const long long sum = std::accumulate(seq.begin(), seq.end(), 0LL);
        println("  偶和不可图例 {}：Σ度 = {}（偶）但 Havel–Hakimi 可图 = {}",
                "{2,2,0,0}", sum, havel_hakimi(seq) ? 1 : 0);
        assert(sum % 2 == 0 && !havel_hakimi(seq));
    }
}

// ── 问题 1-6 找到牛妞：BFS 的一般化——状态空间不止网格 ──
// 农夫在数轴点 N，牛在点 K（0..100000）。每分钟可走 ±1 或飞跃 ×2。
// 把「位置」当顶点、三种移动当边（隐式建图，不存边表），BFS 一遍即最少
// 分钟数。状态空间不一定是网格或显式图——**任何**「状态 + 转移」都行。
static std::pair<int, std::vector<int>> bfs_cow(int n, int k) {
    constexpr int kMaxP = 100000;
    std::vector<int> dist(static_cast<std::size_t>(kMaxP) + 1, -1);
    std::vector<int> par(static_cast<std::size_t>(kMaxP) + 1, -1);
    std::vector<int> queue;
    queue.reserve(static_cast<std::size_t>(kMaxP) + 1);
    dist[static_cast<std::size_t>(n)] = 0;
    queue.push_back(n);
    for (std::size_t head = 0; head < queue.size(); ++head) {
        const int u = queue[head];
        if (u == k) { break; }
        const int nexts[3] = {u - 1, u + 1, u * 2};
        for (int w : nexts) {
            if (w < 0 || w > kMaxP) { continue; }
            if (dist[static_cast<std::size_t>(w)] == -1) {
                dist[static_cast<std::size_t>(w)] =
                    dist[static_cast<std::size_t>(u)] + 1;
                par[static_cast<std::size_t>(w)] = u;
                queue.push_back(w);
            }
        }
    }
    std::vector<int> path;                       // 回溯父指针得路径
    for (int v = k; v != -1; v = par[static_cast<std::size_t>(v)]) {
        path.push_back(v);
    }
    std::ranges::reverse(path);
    return {dist[static_cast<std::size_t>(k)], path};
}

// 原书的六方案数学法：走到 2^t / 2^{t+1}，飞到 2^p / 2^{p+1} 附近，共 6 式取最小
static long long cow_formula(long long n, long long k) {
    if (n >= k) { return n - k; }                // 只能倒着走
    long long q = 0;
    while ((1LL << (q + 1)) * n <= k) { ++q; }   // 2^q·n ≤ k < 2^{q+1}·n
    if ((1LL << q) * n == k) { return q; }       // 恰好飞到
    long long t = 0;
    while ((1LL << (t + 1)) <= n) { ++t; }       // 2^t ≤ n
    long long p = 0;
    while ((1LL << (p + 1)) <= k) { ++p; }       // 2^p ≤ k
    const long long a = q + k - (1LL << q) * n;
    const long long b = q + 1 + (1LL << (q + 1)) * n - k;
    const long long c = (n - (1LL << t)) + (p - t) + (k - (1LL << p));
    const long long d = (n - (1LL << t)) + (p - t + 1) + ((1LL << (p + 1)) - k);
    const long long e = ((1LL << (t + 1)) - n) + (p - t + 1) + (k - (1LL << p));
    const long long f = ((1LL << (t + 1)) - n) + (p - t) + ((1LL << (p + 1)) - k);
    return std::min({a, b, c, d, e, f});
}

static void catch_cow_demo() {
    println("");
    println("=== 23.13b 找到牛妞（1-6）：状态空间 BFS ===");
    const auto [d1, p1] = bfs_cow(5, 17);
    const auto [d2, p2] = bfs_cow(3, 21);
    auto printPath = [](const std::vector<int>& p) {
        for (std::size_t i = 0; i < p.size(); ++i) {
            print("{}{}", i == 0 ? "" : "→", p[i]);
        }
    };
    print("  N=5 → K=17：{} 分钟（", d1); printPath(p1);
    println("：先走回 4=2² 再飞）");
    assert(d1 == 4);
    print("  N=3 → K=21：{} 分钟（", d2); printPath(p2);
    println("：走两步到 5 再连飞两次）");
    println("    —— 原书样例给 6，是六方案公式的值：它数不出这条「任意点起飞」路");
    assert(d2 == 5);
    // 六方案数学法 vs BFS 全对账
    long long mismatches = 0;
    for (int n = 1; n <= 150; ++n) {
        for (int k = 0; k <= 150; ++k) {
            const int truth = bfs_cow(n, k).first;
            if (cow_formula(n, k) != truth) { ++mismatches; }
        }
    }
    println("  书式六方案 vs BFS（1≤N≤150, 0≤K≤150 全对账）：不一致 {} 组",
            mismatches);
    // 经典反例：先走回 13（非 2 的幂）再起飞
    {
        const auto [d, p] = bfs_cow(15, 100);
        print("  反例 N=15, K=100：BFS = {} 分钟（", d); printPath(p);
        println("），书式 = {} —— 六方案漏了「走回任意点再起飞」", cow_formula(15, 100));
        assert(d == 6 && cow_formula(15, 100) == 23);
    }
    println("  ⟹ 构造式数学法的方案枚举未必齐全；BFS 的「穷举所有状态」");
    println("     恰是它的对照组——先把 BFS 写对，数学法拿 BFS 当裁判。");
}

// ════════════════════════════════════════════════════════════════════
// 23.14 旅程：树上覆盖目标点的最短步行
// ════════════════════════════════════════════════════════════════════
struct WeightedEdge {
    int to = 0;
    int weight = 0;
};

struct JourneyStats {
    long long subtree_weight = 0;   // 连接 k 与全部目标的最小子树边权和 W
    long long farthest = 0;         // k 到最远目标的距离
    long long answer = 0;           // 2W − farthest
};

// 根树（k）→ 父节点/父边权/k-距离/遍历序；逆序判定 needed 子树并累计 W。
static JourneyStats shortest_journey(
    const std::vector<std::vector<WeightedEdge>>& adj, int k,
    const std::vector<char>& target) {
    const int n = static_cast<int>(adj.size());
    std::vector<int> parent(static_cast<std::size_t>(n), -1);
    std::vector<long long> parent_w(static_cast<std::size_t>(n), 0);
    std::vector<long long> dist(static_cast<std::size_t>(n), 0);
    std::vector<int> order;
    order.reserve(static_cast<std::size_t>(n));
    std::deque<int> q;
    q.push_back(k);
    parent[static_cast<std::size_t>(k)] = k;
    while (!q.empty()) {
        const int u = q.front();
        q.pop_front();
        order.push_back(u);
        for (const WeightedEdge& e : adj[static_cast<std::size_t>(u)]) {
            if (e.to == parent[static_cast<std::size_t>(u)]) { continue; }
            parent[static_cast<std::size_t>(e.to)] = u;
            parent_w[static_cast<std::size_t>(e.to)] = e.weight;
            dist[static_cast<std::size_t>(e.to)] =
                dist[static_cast<std::size_t>(u)] + e.weight;
            q.push_back(e.to);
        }
    }
    std::vector<char> needed = target;
    long long weight = 0;
    for (std::size_t i = order.size(); i-- > 0;) {
        const int v = order[i];
        if (v == k || !needed[static_cast<std::size_t>(v)]) { continue; }
        needed[static_cast<std::size_t>(parent[static_cast<std::size_t>(v)])] = 1;
        weight += parent_w[static_cast<std::size_t>(v)];
    }
    long long farthest = 0;
    for (int v = 0; v < n; ++v) {
        if (target[static_cast<std::size_t>(v)]) {
            farthest = std::max(farthest, dist[static_cast<std::size_t>(v)]);
        }
    }
    return {weight, farthest, 2 * weight - farthest};
}

// 就近贪心对照：从当前位置每次走到（树上）最近的未访问目标。
static long long nearest_target_greedy(
    const std::vector<std::vector<WeightedEdge>>& adj, int k,
    std::vector<char> remaining) {
    const int n = static_cast<int>(adj.size());
    int pos = k;
    long long total = 0;
    int left = 0;
    for (char x : remaining) { left += x ? 1 : 0; }
    while (left > 0) {
        // 从 pos 做树上 BFS 求各点距离，取编号最小的最近未访问目标。
        std::vector<long long> dist(static_cast<std::size_t>(n), -1);
        std::deque<int> q;
        q.push_back(pos);
        dist[static_cast<std::size_t>(pos)] = 0;
        int nearest = -1;
        while (!q.empty()) {
            const int u = q.front();
            q.pop_front();
            if (remaining[static_cast<std::size_t>(u)] && u != pos) {
                if (nearest == -1 ||
                    dist[static_cast<std::size_t>(u)] <
                        dist[static_cast<std::size_t>(nearest)]) {
                    nearest = u;
                }
            }
            for (const WeightedEdge& e :
                 adj[static_cast<std::size_t>(u)]) {
                if (dist[static_cast<std::size_t>(e.to)] != -1) { continue; }
                dist[static_cast<std::size_t>(e.to)] =
                    dist[static_cast<std::size_t>(u)] + e.weight;
                q.push_back(e.to);
            }
        }
        assert(nearest != -1);
        total += dist[static_cast<std::size_t>(nearest)];
        remaining[static_cast<std::size_t>(nearest)] = 0;
        pos = nearest;
        --left;
    }
    return total;
}

// 暴力对账：状态 (位置, 目标掩码) 上按边转移，Dijkstra 求最短步行长度。
// 掩码只增不减，但距离仍要按权松弛——这就是带权状态空间最短路。
static long long journey_brute(
    const std::vector<std::vector<WeightedEdge>>& adj, int k,
    const std::vector<int>& targets) {
    const int n = static_cast<int>(adj.size());
    const int j = static_cast<int>(targets.size());
    const int masks = 1 << j;
    const long long inf = (1LL << 62);
    std::vector<long long> d(static_cast<std::size_t>(n * masks), inf);
    d[static_cast<std::size_t>(k * masks)] = 0;
    using State = std::pair<long long, int>;   // (距离, u*masks+m)
    std::priority_queue<State, std::vector<State>, std::greater<State>> pq;
    pq.push({0, k * masks});
    while (!pq.empty()) {
        const auto [du, code] = pq.top();
        pq.pop();
        if (du != d[static_cast<std::size_t>(code)]) { continue; }
        const int u = code / masks;
        const int m = code % masks;
        for (const WeightedEdge& e :
             adj[static_cast<std::size_t>(u)]) {
            int nm = m;
            for (int t = 0; t < j; ++t) {
                if (targets[static_cast<std::size_t>(t)] == e.to) {
                    nm |= (1 << t);
                }
            }
            const int ncode = e.to * masks + nm;
            if (du + e.weight < d[static_cast<std::size_t>(ncode)]) {
                d[static_cast<std::size_t>(ncode)] = du + e.weight;
                pq.push({du + e.weight, ncode});
            }
        }
    }
    long long best = inf;
    for (int u = 0; u < n; ++u) {
        best = std::min(best,
                        d[static_cast<std::size_t>(u * masks + masks - 1)]);
    }
    return best;
}

static void journey_demo() {
    println("");
    println("=== 23.14 旅程：2×连接子树 − 最远目标距离 ===");
    struct Case {
        int n, k;
        std::vector<std::tuple<int, int, int>> edges;
        std::vector<int> targets;
        int answer;
    };
    const std::vector<Case> cases = {
        {4, 1,
         {{0, 1, 1}, {3, 1, 2}, {1, 2, 3}},
         {0, 2}, 5},
        {9, 0,
         {{0, 1, 3}, {1, 2, 1}, {2, 3, 1}, {2, 4, 1}, {1, 5, 1},
          {5, 6, 1}, {6, 7, 1}, {5, 8, 1}},
         {6, 7, 8}, 8},
        {5, 0,
         {{0, 1, 1}, {0, 2, 2}, {2, 3, 1}, {3, 4, 2}},
         {2, 3}, 3}};
    int case_no = 0;
    for (const Case& c : cases) {
        ++case_no;
        std::vector<std::vector<WeightedEdge>> adj(
            static_cast<std::size_t>(c.n));
        for (auto [u, v, w] : c.edges) {
            adj[static_cast<std::size_t>(u)].push_back({v, w});
            adj[static_cast<std::size_t>(v)].push_back({u, w});
        }
        std::vector<char> target(static_cast<std::size_t>(c.n), 0);
        for (int v : c.targets) { target[static_cast<std::size_t>(v)] = 1; }
        const JourneyStats s = shortest_journey(adj, c.k, target);
        const long long greedy = nearest_target_greedy(adj, c.k, target);
        println("  案例{}（{} 城，起点 {}，{} 目标）：W={}，最远 {} ⟹ 2·{}−{} = {}；就近贪心 {}",
                case_no, c.n, c.k + 1, static_cast<int>(c.targets.size()),
                s.subtree_weight, s.farthest, s.subtree_weight,
                s.farthest, s.answer, greedy);
        assert(s.answer == c.answer);
        assert(greedy >= s.answer);
    }
    // 就近贪心的反例：k 处分叉——A 支干 a1 距 2、纵深 a2 距 100；B 支 b 距 3。
    {
        const int n = 4, k = 0;
        std::vector<std::vector<WeightedEdge>> adj(
            static_cast<std::size_t>(n));
        auto add_edge = [&](int u, int v, int w) {
            adj[static_cast<std::size_t>(u)].push_back({v, w});
            adj[static_cast<std::size_t>(v)].push_back({u, w});
        };
        add_edge(0, 1, 2);     // a1
        add_edge(1, 2, 98);    // a2：距 k 为 100
        add_edge(0, 3, 3);     // b
        std::vector<char> target{0, 1, 1, 1};
        const JourneyStats s = shortest_journey(adj, k, target);
        const long long greedy = nearest_target_greedy(adj, k, target);
        println("  就近贪心反例（a1=2、a2=100、b=3，目标 {{a1,a2,b}}）：公式 {}，就近贪心 {}",
                s.answer, greedy);
        assert(s.answer == 106 && greedy == 110);
    }

    std::mt19937 rng{5489};
    // 随机小例：公式 vs 状态图最短路。
    const int small_trials = 3000;
    int mismatches = 0;
    for (int t = 0; t < small_trials; ++t) {
        const int n = 2 + static_cast<int>(rand_below(rng, 7));
        std::vector<std::vector<WeightedEdge>> adj(
            static_cast<std::size_t>(n));
        for (int v = 1; v < n; ++v) {
            const int u = static_cast<int>(rand_below(
                rng, static_cast<std::uint32_t>(v)));
            const int w = 1 + static_cast<int>(rand_below(rng, 10));
            adj[static_cast<std::size_t>(u)].push_back({v, w});
            adj[static_cast<std::size_t>(v)].push_back({u, w});
        }
        const int k = static_cast<int>(rand_below(
            rng, static_cast<std::uint32_t>(n)));
        const int jmax = std::min(5, n - 1);
        const int j = 1 + static_cast<int>(rand_below(
            rng, static_cast<std::uint32_t>(jmax)));
        std::vector<int> pool;
        for (int v = 0; v < n; ++v) { if (v != k) pool.push_back(v); }
        // Fisher 洗牌后取前 j：保证目标互不相同。
        for (std::size_t i = pool.size(); i-- > 1;) {
            const std::size_t p = static_cast<std::size_t>(rand_below(
                rng, static_cast<std::uint32_t>(i + 1)));
            std::swap(pool[i], pool[p]);
        }
        std::vector<int> targets(pool.begin(),
                                 pool.begin() + j);
        std::vector<char> mask_target(static_cast<std::size_t>(n), 0);
        for (int v : targets) { mask_target[static_cast<std::size_t>(v)] = 1; }
        const long long formula = shortest_journey(adj, k, mask_target).answer;
        const long long brute = journey_brute(adj, k, targets);
        if (formula != brute) { ++mismatches; }
    }
    println("  随机 {} 小例（n≤8）：公式 vs 状态图最短路 不一致 {} 例",
            small_trials, mismatches);
    assert(mismatches == 0);

    // 随机大例：公式可算且答案落在 [W, 2W]。
    const int big_trials = 200;
    int bound_violations = 0;
    for (int t = 0; t < big_trials; ++t) {
        const int n = 1000 + static_cast<int>(rand_below(rng, 49001));
        std::vector<std::vector<WeightedEdge>> adj(
            static_cast<std::size_t>(n));
        for (int v = 1; v < n; ++v) {
            const int u = static_cast<int>(rand_below(
                rng, static_cast<std::uint32_t>(v)));
            const int w = 1 + static_cast<int>(rand_below(rng, 1000));
            adj[static_cast<std::size_t>(u)].push_back({v, w});
            adj[static_cast<std::size_t>(v)].push_back({u, w});
        }
        const int k = static_cast<int>(rand_below(
            rng, static_cast<std::uint32_t>(n)));
        std::vector<char> target(static_cast<std::size_t>(n), 0);
        for (int v = 0; v < n; ++v) {
            if (v != k && rand_below(rng, 10) == 0) {
                target[static_cast<std::size_t>(v)] = 1;
            }
        }
        if (std::find(target.begin(), target.end(), 1) == target.end()) {
            target[static_cast<std::size_t>((k + 1) % n)] = 1;
        }
        const JourneyStats s = shortest_journey(adj, k, target);
        if (s.answer < s.subtree_weight || s.answer > 2 * s.subtree_weight) {
            ++bound_violations;
        }
    }
    println("  随机 {} 大例（n≤50000）：W ≤ 答案 ≤ 2W 违反 {} 次",
            big_trials, bound_violations);
    assert(bound_violations == 0);
}

// ════════════════════════════════════════════════════════════════════
// 23.15 循序：全体拓扑序按字典序输出
// ════════════════════════════════════════════════════════════════════

// 错误对照：用「直接入度/出度计数」划定每变量允许的位置区间，回溯时
// 只查重复、不查约束。直接计数连传递闭包都不是，会产出违例序列。
static std::vector<std::string> bound_orders_no_check(
    const std::string& vars,
    const std::vector<std::pair<int, int>>& edges) {
    const int n = static_cast<int>(vars.size());
    std::vector<int> before(static_cast<std::size_t>(n), 0);
    std::vector<int> after(static_cast<std::size_t>(n), 0);
    for (auto [a, b] : edges) {
        ++before[static_cast<std::size_t>(b)];
        ++after[static_cast<std::size_t>(a)];
    }
    // cand[pos]：位置 pos 可放哪些变量。
    std::vector<std::vector<int>> cand(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) {
        for (int pos = before[static_cast<std::size_t>(i)];
             pos <= n - 1 - after[static_cast<std::size_t>(i)]; ++pos) {
            cand[static_cast<std::size_t>(pos)].push_back(i);
        }
    }
    std::vector<std::string> out;
    std::string placed(static_cast<std::size_t>(n), '?');
    std::function<void(int)> dfs = [&](int pos) {
        if (pos == n) { out.push_back(placed); return; }
        for (int i : cand[static_cast<std::size_t>(pos)]) {
            bool duplicate = false;
            for (int p = 0; p < pos; ++p) {
                if (placed[static_cast<std::size_t>(p)] ==
                    vars[static_cast<std::size_t>(i)]) {
                    duplicate = true;
                }
            }
            if (duplicate) { continue; }
            placed[static_cast<std::size_t>(pos)] =
                vars[static_cast<std::size_t>(i)];
            dfs(pos + 1);
        }
    };
    dfs(0);
    return out;
}

// 全排列过滤：小例的第三方裁判（与位掩码 DFS 算法不同、只依赖约束检查）。
static int count_orders_by_permutations(
    int n, const std::vector<std::pair<int, int>>& edges) {
    std::vector<int> p(static_cast<std::size_t>(n));
    std::iota(p.begin(), p.end(), 0);
    int count = 0;
    do {
        std::vector<int> at(static_cast<std::size_t>(n));
        for (int i = 0; i < n; ++i) {
            at[static_cast<std::size_t>(p[static_cast<std::size_t>(i)])] = i;
        }
        bool ok = true;
        for (auto [a, b] : edges) {
            if (at[static_cast<std::size_t>(a)] >
                at[static_cast<std::size_t>(b)]) {
                ok = false;
            }
        }
        if (ok) { ++count; }
    } while (std::ranges::next_permutation(p).found);
    return count;
}

static void following_orders_demo() {
    println("");
    println("=== 23.15 循序：全体拓扑序按字典序输出 ===");
    struct Case {
        std::string vars;                                  // 已排序
        std::vector<std::pair<int, int>> edges;
        std::vector<std::string> expected;
    };
    const std::vector<Case> cases = {
        {"abfg", {{0, 1}, {1, 2}},
         {"abfg", "abgf", "agbf", "gabf"}},
        {"vwxyz", {{0, 3}, {2, 0}, {4, 0}, {1, 0}},
         {"wxzvy", "wzxvy", "xwzvy", "xzwvy", "zwxvy", "zxwvy"}}};
    int case_no = 0;
    for (const Case& c : cases) {
        ++case_no;
        const std::vector<std::vector<int>> orders =
            allTopoOrders(static_cast<int>(c.vars.size()), c.edges);
        std::vector<std::string> joined;
        joined.reserve(orders.size());
        for (const auto& o : orders) {
            std::string s;
            for (int v : o) {
                s.push_back(c.vars[static_cast<std::size_t>(v)]);
            }
            joined.push_back(s);
        }
        println("  案例{}（变量 {}，{} 条约束）：共 {} 个拓扑序",
                case_no, c.vars, c.edges.size(), joined.size());
        for (const std::string& s : joined) {
            println("    {}", s);
        }
        assert(joined == c.expected);
        assert(std::ranges::is_sorted(joined));

        // 直接计数、无终检的位置区间法：在链 a<b<c<d 上会吐出违例序列。
        if (case_no == 1) {
            const std::string chain = "abcd";
            const std::vector<std::pair<int, int>> chain_edges{
                {0, 1}, {1, 2}, {2, 3}};
            const std::vector<std::string> bad =
                bound_orders_no_check(chain, chain_edges);
            print("    对照（链 a<b<c<d，直接计数位置区间、无终检）给出 ");
            for (std::size_t i = 0; i < bad.size(); ++i) {
                print("{}{}", bad[i], i + 1 == bad.size() ? "" : " ");
            }
            println("：acbd 违反 b<c——该法不可用");
            assert(bad == (std::vector<std::string>{"abcd", "acbd"}));
        }
    }

    // 随机：变量为字母表任意子集，约束只从小编号指向大编号（保证无圈）。
    std::mt19937 rng{5489};
    const int trials = 2000;
    int mismatches = 0;
    for (int t = 0; t < trials; ++t) {
        // 先选字母子集，再在子集内部按索引连边。
        const int alphabet = 26;
        const int n = 2 + static_cast<int>(rand_below(rng, 7));
        std::vector<int> letters(static_cast<std::size_t>(alphabet));
        std::iota(letters.begin(), letters.end(), 0);
        for (std::size_t i = letters.size(); i-- > 1;) {
            const std::size_t p = static_cast<std::size_t>(rand_below(
                rng, static_cast<std::uint32_t>(i + 1)));
            std::swap(letters[i], letters[p]);
        }
        letters.resize(static_cast<std::size_t>(n));
        std::ranges::sort(letters);
        std::string vars;
        for (int x : letters) {
            vars.push_back(static_cast<char>('a' + x));
        }
        std::vector<std::pair<int, int>> edges;
        for (int a = 0; a < n; ++a) {
            for (int b = a + 1; b < n; ++b) {
                if (rand_below(rng, 3) == 0) {
                    edges.push_back({a, b});
                }
            }
        }
        if (edges.empty()) { edges.push_back({0, 1}); }
        const std::vector<std::vector<int>> orders = allTopoOrders(n, edges);
        const int brute = count_orders_by_permutations(n, edges);
        if (static_cast<int>(orders.size()) != brute) { ++mismatches; }
        for (const auto& o : orders) {
            for (auto [a, b] : edges) {
                const auto ia = std::ranges::find(o, a);
                const auto ib = std::ranges::find(o, b);
                assert(ia < ib);
            }
        }
    }
    println("  随机 {} 例（变量≤8）：位掩码 DFS vs 全排列过滤 不一致 {} 例",
            trials, mismatches);
    assert(mismatches == 0);
}

// ════════════════════════════════════════════════════════════════════
// 23.16 最优工程布线：网格图上的 BFS
// ════════════════════════════════════════════════════════════════════
// m×n 方格，'#' 格被封锁，只能沿上下左右走，求 s 到 e 经过格子最少的
// 布线。每个格子是一个顶点，可通行的相邻格之间连边，边权全为 1 —— 无权
// 最短路，BFS 一遍求出。围墙技巧：网格四周补一圈封锁格，扩展邻居时永远
// 不会踏出数组，省掉全部边界判断。距离表 dist：-2 封锁、-1 未访问、
// ≥0 距起点的格子数。
struct WirePos { int x, y; };

static std::vector<WirePos> wire_route(const std::vector<std::string>& board,
                                       WirePos s, WirePos e) {
    const int m = static_cast<int>(board.size());
    const int n = static_cast<int>(board[0].size());
    // (m+2)×(n+2)：下标 0、m+1 为围墙；真实格 (x,y) 存在 (x+1,y+1)。
    std::vector<std::vector<int>> dist(
        static_cast<std::size_t>(m) + 2,
        std::vector<int>(static_cast<std::size_t>(n) + 2, -1));
    for (std::size_t x = 0; x < dist.size(); ++x) {
        dist[x][0] = -2;
        dist[x][static_cast<std::size_t>(n) + 1] = -2;
    }
    for (std::size_t y = 0; y < dist[0].size(); ++y) {
        dist[0][y] = -2;
        dist[static_cast<std::size_t>(m) + 1][y] = -2;
    }
    for (int x = 0; x < m; ++x) {
        for (int y = 0; y < n; ++y) {
            if (board[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)] == '#') {
                dist[static_cast<std::size_t>(x) + 1][static_cast<std::size_t>(y) + 1] = -2;
            }
        }
    }
    static const int dx[4]{0, 1, 0, -1};   // 右、下、左、上
    static const int dy[4]{1, 0, -1, 0};
    std::deque<WirePos> q;
    dist[static_cast<std::size_t>(s.x) + 1][static_cast<std::size_t>(s.y) + 1] = 0;
    q.push_back(s);
    while (!q.empty()) {
        const WirePos cur = q.front();
        q.pop_front();
        if (cur.x == e.x && cur.y == e.y) { break; }
        for (int d = 0; d < 4; ++d) {
            const int nx = cur.x + dx[d], ny = cur.y + dy[d];
            int& cell = dist[static_cast<std::size_t>(nx) + 1][static_cast<std::size_t>(ny) + 1];
            if (cell == -1) {                 // 未访问的可通行格
                cell = dist[static_cast<std::size_t>(cur.x) + 1][static_cast<std::size_t>(cur.y) + 1] + 1;
                q.push_back({nx, ny});
            }
        }
    }
    const int target =
        dist[static_cast<std::size_t>(e.x) + 1][static_cast<std::size_t>(e.y) + 1];
    if (target < 0) { return {}; }            // 不可达
    // 逆向重建：从 e 反复走向「距离恰小 1」的邻居，直到 s。
    std::vector<WirePos> path;
    WirePos cur = e;
    path.push_back(cur);
    while (cur.x != s.x || cur.y != s.y) {
        const int dcur =
            dist[static_cast<std::size_t>(cur.x) + 1][static_cast<std::size_t>(cur.y) + 1];
        for (int d = 0; d < 4; ++d) {
            const int nx = cur.x + dx[d], ny = cur.y + dy[d];
            if (dist[static_cast<std::size_t>(nx) + 1][static_cast<std::size_t>(ny) + 1] == dcur - 1) {
                cur = {nx, ny};
                path.push_back(cur);
                break;
            }
        }
    }
    std::reverse(path.begin(), path.end());
    return path;
}

// Floyd-Warshall 对账：把可通行格当一般加权图（边权 1），全源最短路
// O(V³)。与 BFS 代码路径完全独立，仅用于小棋盘。
static int wire_floyd(const std::vector<std::string>& board,
                      WirePos s, WirePos e) {
    const int m = static_cast<int>(board.size());
    const int n = static_cast<int>(board[0].size());
    const int v = m * n;
    std::vector<std::vector<int>> d(static_cast<std::size_t>(v),
        std::vector<int>(static_cast<std::size_t>(v), INT32_MAX / 4));
    for (int x = 0; x < m; ++x) {
        for (int y = 0; y < n; ++y) {
            if (board[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)] == '#') { continue; }
            d[static_cast<std::size_t>(x * n + y)][static_cast<std::size_t>(x * n + y)] = 0;
            static const int dx[4]{0, 1, 0, -1};
            static const int dy[4]{1, 0, -1, 0};
            for (int k = 0; k < 4; ++k) {
                const int nx = x + dx[k], ny = y + dy[k];
                if (nx < 0 || nx >= m || ny < 0 || ny >= n) { continue; }
                if (board[static_cast<std::size_t>(nx)][static_cast<std::size_t>(ny)] == '#') { continue; }
                d[static_cast<std::size_t>(x * n + y)][static_cast<std::size_t>(nx * n + ny)] = 1;
            }
        }
    }
    for (int k = 0; k < v; ++k)
        for (int i = 0; i < v; ++i)
            for (int j = 0; j < v; ++j) {
                if (d[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)] +
                    d[static_cast<std::size_t>(k)][static_cast<std::size_t>(j)] <
                    d[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)]) {
                    d[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] =
                        d[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)] +
                        d[static_cast<std::size_t>(k)][static_cast<std::size_t>(j)];
                }
            }
    return d[static_cast<std::size_t>(s.x * n + s.y)]
            [static_cast<std::size_t>(e.x * n + e.y)];
}

static void wiring_demo() {
    println("");
    println("=== 23.16 最优工程布线：网格 BFS（围墙技巧，逆向重建路径）===");
    struct Case {
        std::vector<std::string> board;
        WirePos s, e;
        bool reachable;
    };
    const std::vector<Case> cases = {
        {{// 5×6 带障碍板
           ".....#",
           ".###..",
           "..#...",
           "#..##.",
           "...#.."},
          {0, 0}, {4, 5}, true},
        {{// 四角全被封住：不可达
           ".#",
           "#."},
          {0, 0}, {1, 1}, false},
        {{// 起点即终点：长度 0
           "..."},
          {0, 0}, {0, 0}, true}};
    int case_no = 0;
    for (const Case& c : cases) {
        ++case_no;
        const std::vector<WirePos> path = wire_route(c.board, c.s, c.e);
        const int floyd = wire_floyd(c.board, c.s, c.e);
        if (c.reachable) {
            // 在板上把路径覆盖成 *
            std::vector<std::string> overlay = c.board;
            for (WirePos p : path) {
                overlay[static_cast<std::size_t>(p.x)][static_cast<std::size_t>(p.y)] = '*';
            }
            println("  案例{}（{}×{}）：最短布线经过 {} 个格子（Floyd-Warshall 对账 {}）",
                    case_no, c.board.size(), c.board[0].size(), path.size(),
                    floyd == INT32_MAX / 4 ? -1 : floyd + 1);
            for (const std::string& row : overlay) { println("    {}", row); }
            assert(static_cast<int>(path.size()) == floyd + 1);
            // 路径必须从 s 连续走到 e
            assert(path.front().x == c.s.x && path.front().y == c.s.y);
            assert(path.back().x == c.e.x && path.back().y == c.e.y);
            for (std::size_t i = 1; i < path.size(); ++i) {
                const int manhattan =
                    std::abs(path[static_cast<std::size_t>(i)].x - path[i - 1].x) +
                    std::abs(path[static_cast<std::size_t>(i)].y - path[i - 1].y);
                assert(manhattan == 1);
            }
        } else {
            println("  案例{}（{}×{}）：不可达，布线 {}；Floyd-Warshall 距离 = {}",
                    case_no, c.board.size(), c.board[0].size(),
                    path.empty() ? "为空" : "非空", floyd);
            assert(path.empty() && floyd == INT32_MAX / 4);
        }
    }

    // 随机对账：4×4 以内随机障碍板，BFS 路径长度 vs Floyd-Warshall。
    std::mt19937 rng{5489};
    const int trials = 3000;
    int mismatches = 0;
    for (int t = 0; t < trials; ++t) {
        const int m = 2 + static_cast<int>(rand_below(rng, 3));
        const int n = 2 + static_cast<int>(rand_below(rng, 3));
        std::vector<std::string> board(static_cast<std::size_t>(m),
                                      std::string(static_cast<std::size_t>(n), '.'));
        for (int x = 0; x < m; ++x) {
            for (int y = 0; y < n; ++y) {
                if (rand_below(rng, 4) == 0) {
                    board[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)] = '#';
                }
            }
        }
        // 在可通行格中选两个不同的点
        std::vector<WirePos> open;
        for (int x = 0; x < m; ++x) {
            for (int y = 0; y < n; ++y) {
                if (board[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)] == '.') {
                    open.push_back({x, y});
                }
            }
        }
        if (open.size() < 2) { continue; }
        const WirePos s = open[static_cast<std::size_t>(rand_below(
            rng, static_cast<std::uint32_t>(open.size())))];
        WirePos e = s;
        for (int guard = 0; guard < 10 && e.x == s.x && e.y == s.y; ++guard) {
            e = open[static_cast<std::size_t>(rand_below(
                rng, static_cast<std::uint32_t>(open.size())))];
        }
        if (e.x == s.x && e.y == s.y) { continue; }
        const std::vector<WirePos> path = wire_route(board, s, e);
        const int floyd = wire_floyd(board, s, e);
        const bool agree = floyd == INT32_MAX / 4
            ? path.empty()
            : static_cast<int>(path.size()) == floyd + 1;
        if (!agree) { ++mismatches; }
    }
    println("  随机 {} 例（≤4×4 随机障碍）：BFS vs Floyd-Warshall 不一致 {} 例",
            trials, mismatches);
    assert(mismatches == 0);

    // 大例：100×100 随机障碍板，BFS 仍然瞬时。
    const int big = 100;
    std::vector<std::string> board(static_cast<std::size_t>(big),
                                  std::string(static_cast<std::size_t>(big), '.'));
    for (int x = 0; x < big; ++x) {
        for (int y = 0; y < big; ++y) {
            if (rand_below(rng, 5) == 0) {
                board[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)] = '#';
            }
        }
    }
    board[0][0] = '.';
    board[big - 1][big - 1] = '.';
    const std::vector<WirePos> path =
        wire_route(board, {0, 0}, {big - 1, big - 1});
    println("  大例（100×100，20% 障碍）：对角最短布线 {} 个格子；无障碍下界 {}，不可达则为 0",
            path.size(), 2 * big - 1);
}

// ═══ 23.17 八数字谜题：隐式图上的 BFS ═══
// 3×3 棋盘上有数字 1..8 和一个空格（用 0 表示）；一步 = 空格与上下左右相邻数字
// 交换。给定初态，求到达目标态
//   1 2 3
//   4 5 6
//   7 8 _
// 的最少步数。棋盘格局是「顶点」，一次合法交换是「边」——问题就是隐式图上的 BFS。
using PuzzleCode = std::uint64_t;

static PuzzleCode puzzle_encode(const std::array<int, 9>& t) {
    PuzzleCode code = 0;
    for (int i = 0; i < 9; ++i) { code |= static_cast<PuzzleCode>(t[static_cast<std::size_t>(i)]) << (4 * i); }
    return code;
}

static std::array<int, 9> puzzle_decode(PuzzleCode code) {
    std::array<int, 9> t{};
    for (int i = 0; i < 9; ++i) { t[static_cast<std::size_t>(i)] = static_cast<int>((code >> (4 * i)) & 0xF); }
    return t;
}

static const PuzzleCode kPuzzleGoal = [] {
    std::array<int, 9> g{1, 2, 3, 4, 5, 6, 7, 8, 0};
    return puzzle_encode(g);
}();

// 空格相邻位置：行/列都相邻（pos 线性下标 0..8）
static std::array<int, 4> puzzle_neighbors(int pos, int& count) {
    std::array<int, 4> nb{-1, -1, -1, -1};
    count = 0;
    const int r = pos / 3, c = pos % 3;
    static const int dr[4]{-1, 1, 0, 0}, dc[4]{0, 0, -1, 1};
    for (int k = 0; k < 4; ++k) {
        const int nr = r + dr[k], nc = c + dc[k];
        if (0 <= nr && nr < 3 && 0 <= nc && nc < 3) {
            nb[static_cast<std::size_t>(count++)] = nr * 3 + nc;
        }
    }
    return nb;
}

struct PuzzleResult {
    int moves;
    long long explored;                   // BFS 登记进 visited 的格局数
    std::vector<PuzzleCode> path;         // 初态 → 目标态
};

static PuzzleResult puzzle_bfs(PuzzleCode start) {
    std::unordered_map<PuzzleCode, PuzzleCode> parent;
    parent.reserve(200000);
    std::deque<PuzzleCode> queue;
    queue.push_back(start);
    parent.emplace(start, start);
    while (!queue.empty()) {
        const PuzzleCode cur = queue.front();
        queue.pop_front();
        if (cur == kPuzzleGoal) { break; }
        const std::array<int, 9> t = puzzle_decode(cur);
        int blank = 0;
        while (t[static_cast<std::size_t>(blank)] != 0) { ++blank; }
        int cnt = 0;
        const std::array<int, 4> nb = puzzle_neighbors(blank, cnt);
        for (int k = 0; k < cnt; ++k) {
            std::array<int, 9> nt = t;
            std::swap(nt[static_cast<std::size_t>(blank)],
                      nt[static_cast<std::size_t>(nb[static_cast<std::size_t>(k)])]);
            if (const PuzzleCode nc = puzzle_encode(nt);
                parent.emplace(nc, cur).second) {
                queue.push_back(nc);
            }
        }
    }
    // 重建：从目标沿 parent 回到初态，再反转
    std::vector<PuzzleCode> path;
    if (!parent.contains(kPuzzleGoal)) { return {-1, static_cast<long long>(parent.size()), path}; }
    for (PuzzleCode c = kPuzzleGoal;; c = parent[c]) {
        path.push_back(c);
        if (c == start) { break; }
    }
    std::ranges::reverse(path);
    return {static_cast<int>(path.size()) - 1, static_cast<long long>(parent.size()),
            std::move(path)};
}

// 可解性：把九格按行展开、去掉空格后数逆序对。每次水平/竖直交换都会让逆序对数
// 的奇偶保持不变（竖直交换等价于数字跨两位移动，逆序对改变数为偶数），而目标
// 态逆序对数为 0（偶数）——逆序对为奇数的初态永远不可解。
static bool puzzle_solvable(const std::array<int, 9>& t) {
    int inv = 0;
    for (int i = 0; i < 9; ++i) {
        if (t[static_cast<std::size_t>(i)] == 0) { continue; }
        for (int j = i + 1; j < 9; ++j) {
            if (t[static_cast<std::size_t>(j)] != 0 &&
                t[static_cast<std::size_t>(j)] < t[static_cast<std::size_t>(i)]) { ++inv; }
        }
    }
    return inv % 2 == 0;
}

// 独立对账：IDA* —— 曼哈顿距离之和是可采纳启发式（每步每个数字至多接近目标格
// 1，故实际步数 ≥ h）。迭代加深搜索第一次到达目标的深度就是最短步数；算法与
// BFS 完全独立，结果必须一致。
static int puzzle_manhattan(const std::array<int, 9>& t) {
    int h = 0;
    for (int i = 0; i < 9; ++i) {
        const int tile = t[static_cast<std::size_t>(i)];
        if (tile == 0) { continue; }
        const int goal_pos = tile - 1;
        h += std::abs(i / 3 - goal_pos / 3) + std::abs(i % 3 - goal_pos % 3);
    }
    return h;
}

static int ida_dfs(std::array<int, 9> t, int blank, int g, int bound,
                   long long& nodes) {
    ++nodes;
    const int f = g + puzzle_manhattan(t);
    if (f > bound) { return f; }
    if (puzzle_manhattan(t) == 0) { return -1; }   // 到达目标
    int smallest = std::numeric_limits<int>::max();
    int cnt = 0;
    const std::array<int, 4> nb = puzzle_neighbors(blank, cnt);
    for (int k = 0; k < cnt; ++k) {
        const int nbp = nb[static_cast<std::size_t>(k)];
        std::swap(t[static_cast<std::size_t>(blank)],
                  t[static_cast<std::size_t>(nbp)]);
        const int r = ida_dfs(t, nbp, g + 1, bound, nodes);
        if (r == -1) { return -1; }
        smallest = std::min(smallest, r);
        std::swap(t[static_cast<std::size_t>(blank)],
                  t[static_cast<std::size_t>(nbp)]);
    }
    return smallest;
}

static int ida_star(PuzzleCode start, long long& nodes) {
    std::array<int, 9> t = puzzle_decode(start);
    int blank = 0;
    while (t[static_cast<std::size_t>(blank)] != 0) { ++blank; }
    int bound = puzzle_manhattan(t);
    nodes = 0;
    for (;;) {
        const int r = ida_dfs(t, blank, 0, bound, nodes);
        if (r == -1) { return bound; }
        bound = r;
    }
}

static void print_puzzle_board(const std::array<int, 9>& t) {
    for (int r = 0; r < 3; ++r) {
        print("    ");
        for (int c = 0; c < 3; ++c) {
            const int v = t[static_cast<std::size_t>(r * 3 + c)];
            if (v == 0) { print("_ "); } else { print("{} ", v); }
        }
        println("");
    }
}

static void puzzle_demo() {
    println("=== 23.17 八数字谜题：隐式图 BFS（最少步数 + 路径重建）===");
    // 从目标态做 6 次随机「退步」构造一个确定的、保证可解的初态
    std::mt19937 rng{5489};
    std::array<int, 9> t{1, 2, 3, 4, 5, 6, 7, 8, 0};
    int blank = 8;
    int prev = -1;
    for (int s = 0; s < 6; ++s) {
        int cnt = 0;
        std::array<int, 4> nb = puzzle_neighbors(blank, cnt);
        int choices[4], nch = 0;
        for (int k = 0; k < cnt; ++k) {
            if (nb[static_cast<std::size_t>(k)] != prev) { choices[nch++] = nb[k]; }
        }
        const int pick = choices[rand_below(rng, static_cast<std::uint32_t>(nch))];
        std::swap(t[static_cast<std::size_t>(blank)], t[static_cast<std::size_t>(pick)]);
        prev = blank;
        blank = pick;
    }
    const PuzzleCode start = puzzle_encode(t);
    const PuzzleResult r = puzzle_bfs(start);
    long long ida_nodes = 0;
    const int ida_dist = ida_star(start, ida_nodes);
    println("  案例：随机退步 6 步的初态，BFS 最少 {} 步，IDA* = {} 步", r.moves, ida_dist);
    assert(r.moves == ida_dist && r.moves <= 6);
    // 打印完整解路径；逐步核对：相邻格局恰差一次合法交换
    for (std::size_t i = 0; i < r.path.size(); ++i) {
        println("  第 {} 步：", i);
        print_puzzle_board(puzzle_decode(r.path[i]));
        if (i > 0) {
            const std::array<int, 9> a = puzzle_decode(r.path[i - 1]);
            const std::array<int, 9> b = puzzle_decode(r.path[i]);
            int diff = 0, blankswap = 0;
            for (int k = 0; k < 9; ++k) {
                if (a[static_cast<std::size_t>(k)] != b[static_cast<std::size_t>(k)]) {
                    ++diff;
                    blankswap += (a[static_cast<std::size_t>(k)] == 0 ||
                                  b[static_cast<std::size_t>(k)] == 0);
                }
            }
            assert(diff == 2 && blankswap == 2);
        }
    }
    assert(r.path.front() == start && r.path.back() == kPuzzleGoal);

    // 不可解案例：把目标态的 1 和 2 对调，逆序对 = 1（奇数）
    const std::array<int, 9> unsolvable{2, 1, 3, 4, 5, 6, 7, 8, 0};
    println("  不可解初态（1/2 对调）：逆序对判据可解 = {}，不发起搜索",
            puzzle_solvable(unsolvable));
    assert(!puzzle_solvable(unsolvable));

    // 随机 500 例：从目标退步 1..22 步，BFS 距离必须等于 IDA* 距离，且不超过
    // 退步长度（退步路径是可行解，最优只会更短）。
    int mismatches = 0;
    for (int gi = 0; gi < 500; ++gi) {
        const int walk = 1 + static_cast<int>(rand_below(rng, 22));
        std::array<int, 9> st{1, 2, 3, 4, 5, 6, 7, 8, 0};
        int bl = 8, pv = -1;
        for (int s = 0; s < walk; ++s) {
            int cnt = 0;
            const std::array<int, 4> nb = puzzle_neighbors(bl, cnt);
            int choices[4], nch = 0;
            for (int k = 0; k < cnt; ++k) {
                if (nb[static_cast<std::size_t>(k)] != pv) { choices[nch++] = nb[k]; }
            }
            const int pick = choices[rand_below(rng, static_cast<std::uint32_t>(nch))];
            std::swap(st[static_cast<std::size_t>(bl)], st[static_cast<std::size_t>(pick)]);
            pv = bl;
            bl = pick;
        }
        const PuzzleCode code = puzzle_encode(st);
        const PuzzleResult pr = puzzle_bfs(code);
        long long nodes = 0;
        if (pr.moves != ida_star(code, nodes) || pr.moves > walk) { ++mismatches; }
    }
    println("  随机 {} 例（退步 1..22 步）：BFS vs IDA* 距离不一致 / 超过可行上界 {} 例",
            500, mismatches);
    assert(mismatches == 0);

    // 大例：已知最远格局之一（31 步），从它做整层 BFS：可达格局恰为
    // 9!/2 = 181440 个，BFS 层数直径 31。
    const std::array<int, 9> hard{8, 6, 7, 2, 5, 4, 3, 0, 1};
    assert(puzzle_solvable(hard));
    const PuzzleResult hr = puzzle_bfs(puzzle_encode(hard));
    println("  大例（最远格局之一）：最少 {} 步；BFS 共登记 {} 个可达格局（= 9!/2）",
            hr.moves, hr.explored);
    assert(hr.moves == 31);
    assert(hr.explored == 181440);
}

int main() {
    representation_demo();
    bfs_demo();
    dfs_demo();
    topo_demo();
    scc_demo();
    tarjan_demo();
    euler_demo();
    semidirected_demo();
    floodfill_demo();
    topo_app_demo();
    sep_pair_demo();
    bridge_watch_demo();
    party_game_demo();
    catch_cow_demo();
    journey_demo();
    following_orders_demo();
    wiring_demo();
    puzzle_demo();
    println("自检通过");
    return 0;
}
