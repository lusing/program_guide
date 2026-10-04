// 23 基本图算法（CLRS 第 22 章）。结构：23.1 邻接表表示与度统计 /
// 23.2 BFS（图 22.3：距离与 BFS 树）/ 23.3 DFS 时间戳与边分类
//（图 22.4/22.5）/ 23.4 拓扑排序（DAG）/ 23.5 强连通分量（图 22.9）。
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
#include <deque>
#include <numeric>
#include <string>
#include <utility>
#include <vector>

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

int main() {
    representation_demo();
    bfs_demo();
    dfs_demo();
    topo_demo();
    scc_demo();
    println("自检通过");
    return 0;
}
