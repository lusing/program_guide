// 27 最大流（CLRS 第 26 章）。结构：27.1 流网络与残量网络 /
// 27.2 Edmonds-Karp（BFS 增广路径逐条追踪，图 26.1 数据）/
// 27.3 流的合法性验证（容量约束 + 流量守恒）/ 27.4 最小割验证（最大流
// 最小割定理）/ 27.5 推送-重贴标签对照 /
// 27.6 二部图匹配与最小点覆盖（König 定理；Kuhn 增广路）/
// 27.7 女孩与男孩：二部图最大独立集（染色取大 vs König；暴力对账）/
// 27.8 午餐：牛妞拆 in/out 两点的三方独占流（食物-饮料直接匹配的误报对照）/
// 27.9 最小费用最大流（残量边带单位费用，SPFA 逐次最短路，反向边费用取负）/
// 27.10 方格取数：棋盘染色构造最大权独立集（总权 − 最大流，残量可达性还原方案）。
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
#include <cstdlib>
#include <deque>
#include <numeric>
#include <random>
#include <utility>
#include <vector>

// 确定性伪随机：[0,n) 内均匀取一值。用乘法折半而非
// uniform_int_distribution——后者在各标准库实现下取值序列不同。
static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    return static_cast<std::uint32_t>((static_cast<std::uint64_t>(rng()) * n) >> 32);
}

// 自造 6 顶点流网络（CLRS 图 26.1 的图内数字不在 PDF 文本层，无法可靠
// 转写——改用本网络，最大流 = 最小割 = 23，可手算验证）：
// s→a 16, s→b 10, a→c 13, a→b 1, b→c 7, b→d 9, c→t 14, d→t 9
static const std::vector<std::vector<int>> kCap = {
    //  s   a   b   c   d   t
    {  0, 16, 10,  0,  0,  0 },   // s
    {  0,  0,  1, 13,  0,  0 },   // a
    {  0,  0,  0,  7,  9,  0 },   // b
    {  0,  0,  0,  0,  0, 14 },   // c
    {  0,  0,  0,  0,  0,  9 },   // d
    {  0,  0,  0,  0,  0,  0 }};  // t

static const std::array<const char*, 6> kNode{"s", "a", "b", "c", "d", "t"};

struct MaxFlowResult {
    std::vector<std::vector<int>> flow;   // f[u][v]（可为负 = 反向流）
    int value = 0;
    long long bfs = 0;                    // BFS 轮数（含最后一轮检测）
};

// Edmonds-Karp：BFS 找最短增广路径（残量 > 0），沿路增广。
// 定理 26.9? 26.8：O(V·E²)——最短路径长度单调不降，每条关键边至多
// V/2 次饱和。
static MaxFlowResult edmonds_karp(std::vector<std::vector<int>> cap, int s, int t,
                                  bool verbose = true) {
    const int n = static_cast<int>(cap.size());
    std::vector<std::vector<int>> flow(static_cast<std::size_t>(n),
                                       std::vector<int>(static_cast<std::size_t>(n), 0));
    int total = 0;
    long long bfs = 0;
    while (true) {
        // BFS on residual
        std::vector<int> parent(static_cast<std::size_t>(n), -1);
        std::deque<int> q{s};
        parent[static_cast<std::size_t>(s)] = s;
        while (!q.empty() && parent[static_cast<std::size_t>(t)] == -1) {
            const int u = q.front();
            q.pop_front();
            for (int v = 0; v < n; ++v) {
                if (parent[static_cast<std::size_t>(v)] == -1 &&
                    cap[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] -
                            flow[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] > 0) {
                    parent[static_cast<std::size_t>(v)] = u;
                    q.push_back(v);
                }
            }
        }
        ++bfs;
        if (parent[static_cast<std::size_t>(t)] == -1) { break; }   // 无增广路
        // 求瓶颈
        int bottleneck = INT32_MAX;
        for (int v = t; v != s; ) {
            const int u = parent[static_cast<std::size_t>(v)];
            bottleneck = std::min(bottleneck,
                cap[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] -
                flow[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)]);
            v = u;
        }
        // 增广（正向 +流，反向 −流）
        for (int v = t; v != s; ) {
            const int u = parent[static_cast<std::size_t>(v)];
            flow[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] += bottleneck;
            flow[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)] -= bottleneck;
            v = u;
        }
        total += bottleneck;
        if (verbose) {
            print("  增广路径 #{}（瓶颈 {}）: ", bfs, bottleneck);
            std::vector<int> path;
            for (int v = t; v != s; ) { path.push_back(v); v = parent[static_cast<std::size_t>(v)]; }
            path.push_back(s);
            for (std::size_t i = path.size(); i-- > 0;) {
                print("{}{}", kNode[static_cast<std::size_t>(path[i])], i == 0 ? "" : "→");
            }
            println("（累计流 {}）", total);
        }
    }
    return {flow, total, bfs};
}

// 流的合法性：0 ≤ f ≤ c（反对称含在 f[v][u] = −f[u][v]），中间点守恒
static bool validate_flow(const std::vector<std::vector<int>>& cap,
                          const std::vector<std::vector<int>>& flow, int s, int t, int value) {
    const int n = static_cast<int>(cap.size());
    for (int u = 0; u < n; ++u) {
        for (int v = 0; v < n; ++v) {
            if (flow[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] >
                cap[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)]) { return false; }
            if (flow[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] !=
                -flow[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)]) { return false; }
        }
    }
    for (int u = 0; u < n; ++u) {
        if (u == s || u == t) { continue; }
        int net = 0;
        for (int v = 0; v < n; ++v) { net += flow[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)]; }
        if (net != 0) { return false; }
    }
    int outS = 0;
    for (int v = 0; v < n; ++v) { outS += flow[static_cast<std::size_t>(s)][static_cast<std::size_t>(v)]; }
    return outS == value;
}

static void edmonds_karp_demo() {
    println("Edmonds-Karp（自造 6 顶点网络，BFS 最短增广路径）：");
    const auto r = edmonds_karp(kCap, 0, 5);
    println("  最大流 = {}（手算答案 23），共 {} 轮 BFS（1 轮检测终止）", r.value, r.bfs);
    assert(r.value == 23);
    assert(validate_flow(kCap, r.flow, 0, 5, r.value));
    println("  合法性：容量约束 / 反对称 / 中间点守恒 / 源出 = 流值 全部通过");

    // 最小割：残量图中 s 可达的点集 S；cap(S, V−S) == 最大流
    std::vector<char> reach(6, 0);
    reach[0] = 1;
    std::deque<int> q{0};
    while (!q.empty()) {
        const int u = q.front(); q.pop_front();
        for (int v = 0; v < 6; ++v) {
            if (!reach[static_cast<std::size_t>(v)] &&
                kCap[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] -
                        r.flow[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] > 0) {
                reach[static_cast<std::size_t>(v)] = 1;
                q.push_back(v);
            }
        }
    }
    int cut = 0;
    for (int u = 0; u < 6; ++u) {
        for (int v = 0; v < 6; ++v) {
            if (reach[static_cast<std::size_t>(u)] && !reach[static_cast<std::size_t>(v)]) {
                cut += kCap[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)];
            }
        }
    }
    print("  最小割：S = {{s");
    for (int v = 1; v < 6; ++v) {
        if (reach[static_cast<std::size_t>(v)]) { print(",{}", kNode[static_cast<std::size_t>(v)]); }
    }
    println("}}，割容量 = {}（= 最大流，最大流最小割定理验证）", cut);
    assert(cut == r.value);
}

// ═══ 27.5 推送-重贴标签（preflow-push，FIFO 选取）═══
static int push_relabel(std::vector<std::vector<int>> cap, int s, int t,
                        long long& pushes, long long& relabels) {
    const int n = static_cast<int>(cap.size());
    std::vector<std::vector<int>> flow(static_cast<std::size_t>(n),
                                       std::vector<int>(static_cast<std::size_t>(n), 0));
    std::vector<int> h(static_cast<std::size_t>(n), 0);
    std::vector<long long> excess(static_cast<std::size_t>(n), 0);
    // 预流：s 的出边全饱和，h[s] = n
    h[static_cast<std::size_t>(s)] = n;
    for (int v = 0; v < n; ++v) {
        const int c = cap[static_cast<std::size_t>(s)][static_cast<std::size_t>(v)];
        if (c > 0) {
            flow[static_cast<std::size_t>(s)][static_cast<std::size_t>(v)] = c;
            flow[static_cast<std::size_t>(v)][static_cast<std::size_t>(s)] = -c;
            excess[static_cast<std::size_t>(v)] += c;
            excess[static_cast<std::size_t>(s)] -= c;
            ++pushes;
        }
    }
    std::deque<int> active;
    std::vector<char> inQ(static_cast<std::size_t>(n), 0);
    for (int v = 0; v < n; ++v) {
        if (excess[static_cast<std::size_t>(v)] > 0 && v != t && v != s) {
            active.push_back(v);
            inQ[static_cast<std::size_t>(v)] = 1;
        }
    }
    while (!active.empty()) {
        const int u = active.front();
        active.pop_front();
        inQ[static_cast<std::size_t>(u)] = 0;
        while (excess[static_cast<std::size_t>(u)] > 0) {
            // 找一条可推送的邻边（残量>0 且 h 邻低）
            bool pushed = false;
            for (int v = 0; v < n && excess[static_cast<std::size_t>(u)] > 0; ++v) {
                if (cap[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] -
                        flow[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] > 0 &&
                    h[static_cast<std::size_t>(u)] == h[static_cast<std::size_t>(v)] + 1) {
                    const int d = static_cast<int>(std::min<long long>(
                        excess[static_cast<std::size_t>(u)],
                        cap[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] -
                        flow[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)]));
                    flow[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] += d;
                    flow[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)] -= d;
                    excess[static_cast<std::size_t>(u)] -= d;
                    excess[static_cast<std::size_t>(v)] += d;
                    ++pushes;
                    if (excess[static_cast<std::size_t>(v)] > 0 && !inQ[static_cast<std::size_t>(v)] &&
                        v != s && v != t) {
                        active.push_back(v);
                        inQ[static_cast<std::size_t>(v)] = 1;
                    }
                    pushed = true;
                }
            }
            if (!pushed) {
                // 重贴标签：h[u] = 1 + min(h[v]：残量>0)
                int minH = INT32_MAX;
                for (int v = 0; v < n; ++v) {
                    if (cap[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] -
                            flow[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] > 0) {
                        minH = std::min(minH, h[static_cast<std::size_t>(v)]);
                    }
                }
                h[static_cast<std::size_t>(u)] = minH + 1;
                ++relabels;
                if (minH == INT32_MAX) { break; }   // 无处可推也无邻——异常防御
            }
        }
    }
    return static_cast<int>(excess[static_cast<std::size_t>(t)]);
}

static void push_relabel_demo() {
    long long pushes = 0, relabels = 0;
    const int f = push_relabel(kCap, 0, 5, pushes, relabels);
    println("推送-重贴标签（同一网络，FIFO 选取）：流值 = {}（= Edmonds-Karp），"
            "推送 {} 次、重贴标签 {} 次", f, pushes, relabels);
    assert(f == 23);
}

// ═══ 27.6 二部图最大匹配与最小点覆盖（König 定理）═══
// 二部图 G = (L∪R, E)。匹配：两两不共端点的边集。点覆盖：与每条边都
// 相接的顶点子集。König 定理：二部图中 最大匹配边数 = 最小点覆盖点数。
struct BipartiteGraph {
    int nl = 0, nr = 0;
    std::vector<std::vector<int>> adj;             // adj[u]：u∈L 的邻点
    BipartiteGraph(int l, int r) : nl(l), nr(r),
        adj(static_cast<std::size_t>(l)) {}
    void add_edge(int u, int v) { adj[static_cast<std::size_t>(u)].push_back(v); }
};

// Kuhn 增广路：从 u 出发，DFS 试找一条「非匹配边/匹配边」交替、终点为
// 未匹配 R 点的路；找到则沿路翻转、匹配数 +1。seen 用时间戳，每次搜索
// 一个新 token，免去反复清空数组。
static bool kuhn_augment(const BipartiteGraph& g, int u, int token,
                         std::vector<int>& seen, std::vector<int>& match_r) {
    for (int v : g.adj[static_cast<std::size_t>(u)]) {
        if (seen[static_cast<std::size_t>(v)] == token) { continue; }
        seen[static_cast<std::size_t>(v)] = token;
        if (match_r[static_cast<std::size_t>(v)] < 0 ||
            kuhn_augment(g, match_r[static_cast<std::size_t>(v)], token, seen, match_r)) {
            match_r[static_cast<std::size_t>(v)] = u;
            return true;
        }
    }
    return false;
}

static int bipartite_max_matching(const BipartiteGraph& g, std::vector<int>& match_r) {
    match_r.assign(static_cast<std::size_t>(g.nr), -1);
    std::vector<int> seen(static_cast<std::size_t>(g.nr), 0);
    int size = 0, token = 0;
    for (int u = 0; u < g.nl; ++u) {
        ++token;
        if (kuhn_augment(g, u, token, seen, match_r)) { ++size; }
    }
    return size;
}

static int bipartite_max_matching(const BipartiteGraph& g) {
    std::vector<int> match_r;
    return bipartite_max_matching(g, match_r);
}

static std::vector<std::pair<int, int>> collect_edges(const BipartiteGraph& g) {
    std::vector<std::pair<int, int>> edges;
    for (int u = 0; u < g.nl; ++u) {
        for (int v : g.adj[static_cast<std::size_t>(u)]) { edges.emplace_back(u, v); }
    }
    return edges;
}

// 最大度贪婪点覆盖：每轮选当前度数最大的顶点（L、R 一起比），删其边。
// 只是一个可行覆盖，大小无最优保证——反例见 machine_schedule_demo。
static int greedy_vertex_cover(const BipartiteGraph& g) {
    std::vector<std::pair<int, int>> edges = collect_edges(g);
    int cover = 0;
    while (!edges.empty()) {
        std::vector<int> deg(static_cast<std::size_t>(g.nl + g.nr), 0);
        for (auto [u, v] : edges) {
            ++deg[static_cast<std::size_t>(u)];
            ++deg[static_cast<std::size_t>(g.nl + v)];
        }
        int best = 0;
        for (int z = 1; z < g.nl + g.nr; ++z) {
            if (deg[static_cast<std::size_t>(z)] > deg[static_cast<std::size_t>(best)]) {
                best = z;
            }
        }
        edges.erase(std::remove_if(edges.begin(), edges.end(),
            [&](const std::pair<int, int>& e) {
                return best < g.nl ? e.first == best
                                   : e.second == best - g.nl;
            }), edges.end());
        ++cover;
    }
    return cover;
}

// 暴力最小点覆盖：枚举至多 2^(nl+nr) 个顶点子集（仅供小图对账）
static int brute_vertex_cover(const BipartiteGraph& g) {
    const std::vector<std::pair<int, int>> edges = collect_edges(g);
    if (edges.empty()) { return 0; }
    const int vertices = g.nl + g.nr;
    int best = vertices;
    for (int mask = 1; mask < (1 << vertices); ++mask) {
        bool covers_all = true;
        for (auto [u, v] : edges) {
            if ((mask & (1 << u)) == 0 &&
                (mask & (1 << (g.nl + v))) == 0) { covers_all = false; break; }
        }
        if (covers_all) { best = std::min(best, std::popcount(static_cast<unsigned>(mask))); }
    }
    return best;
}

// ── 机器调度问题 ──
struct ScheduleJob {
    int id = 0, x = 0, y = 0;      // 可在 A 的 mode_x 或 B 的 mode_y 处理
};

// 最优解：两台机器开机即处于 mode_0，所以 x=0 或 y=0 的任务零重启完成；
// 其余任务在 L={A 的 mode_1..n−1}、R={B 的 mode_1..m−1} 间构成二部图，
// 选哪些模式开机 = 选点覆盖所有任务边。由 König 定理，最少重启数
// = 最小点覆盖 = 最大匹配。
static int machine_schedule_optimal(int n, int m,
                                    const std::vector<ScheduleJob>& jobs) {
    BipartiteGraph g(n - 1, m - 1);
    for (const ScheduleJob& j : jobs) {
        if (j.x == 0 || j.y == 0) { continue; }
        g.add_edge(j.x - 1, j.y - 1);
    }
    return bipartite_max_matching(g);
}

// 最大度贪婪版本：把每个模式看成任务集合，每轮在当前基数最大的模式开机。
// 注意它把第一轮的 mode_0 也计入重启——而机器本来就从 mode_0 开始。
static int machine_schedule_greedy(int n, int m,
                                   const std::vector<ScheduleJob>& jobs) {
    const int k = static_cast<int>(jobs.size());
    // in_mode[mode][j]：任务 j 是否属于该模式；A 模式下标 0..n−1，
    // B 模式下标 n..n+m−1
    std::vector<std::vector<char>> in_mode(
        static_cast<std::size_t>(n + m),
        std::vector<char>(static_cast<std::size_t>(k), 0));
    for (int j = 0; j < k; ++j) {
        in_mode[static_cast<std::size_t>(jobs[static_cast<std::size_t>(j)].x)]
               [static_cast<std::size_t>(j)] = 1;
        in_mode[static_cast<std::size_t>(n + jobs[static_cast<std::size_t>(j)].y)]
               [static_cast<std::size_t>(j)] = 1;
    }
    std::vector<char> done(static_cast<std::size_t>(k), 0);
    auto count_mode = [&](int mode) {
        int c = 0;
        for (int j = 0; j < k; ++j) {
            if (in_mode[static_cast<std::size_t>(mode)][static_cast<std::size_t>(j)] &&
                !done[static_cast<std::size_t>(j)]) { ++c; }
        }
        return c;
    };
    // 第一轮：mode[0] 与 mode[n]（两台机器各自的初始模式）取基数大者
    int chosen = count_mode(n) > count_mode(0) ? n : 0;
    int reboots = 0, remaining = k;
    while (remaining > 0) {
        ++reboots;
        for (int j = 0; j < k; ++j) {
            if (in_mode[static_cast<std::size_t>(chosen)][static_cast<std::size_t>(j)] &&
                !done[static_cast<std::size_t>(j)]) {
                done[static_cast<std::size_t>(j)] = 1;
                --remaining;
            }
        }
        if (remaining == 0) { break; }
        int best = 0, best_count = -1;
        for (int mode = 0; mode < n + m; ++mode) {
            const int c = count_mode(mode);
            if (c > best_count) { best_count = c; best = mode; }
        }
        chosen = best;
    }
    return reboots;
}

static void machine_schedule_demo() {
    println("二部图最大匹配与最小点覆盖（Kuhn 增广路；König 定理）：");
    const std::vector<ScheduleJob> jobs = {
        {0,0,0}, {1,0,1}, {2,0,2}, {3,0,3}, {4,1,0},
        {5,1,1}, {6,1,2}, {7,1,3}, {8,2,2}, {9,3,2}};
    int free_jobs = 0;
    for (const ScheduleJob& j : jobs) {
        if (j.x == 0 || j.y == 0) { ++free_jobs; }
    }
    const int optimal = machine_schedule_optimal(5, 5, jobs);
    const int greedy = machine_schedule_greedy(5, 5, jobs);
    println("  机器调度 10 个任务：x=0 或 y=0、开机即可处理的 {} 个", free_jobs);
    println("  剩余边 A1-B1,A1-B2,A1-B3,A2-B2,A3-B2；最大匹配"
            "（= 最小重启）= {}", optimal);
    println("  可行排法：开机先做 0..4；A 切 mode_1 做 5,6,7；"
            "B 切 mode_2 做 8,9 ⇒ 共 2 次重启");
    println("  最大度贪婪计数 = {}（把初始 mode_0 也算作一次重启，多 1 次）", greedy);
    assert(free_jobs == 5 && optimal == 2 && greedy == 3);

    // 贪婪点覆盖的通用反例（全枚举得到的最小图之一）：
    // L0 连 R0,R1；L1 连 R1；L2 连 R0。
    BipartiteGraph g3(3, 3);
    g3.add_edge(0, 0);
    g3.add_edge(0, 1);
    g3.add_edge(1, 1);
    g3.add_edge(2, 0);
    const int m3 = bipartite_max_matching(g3);
    const int c3 = greedy_vertex_cover(g3);
    println("  3×3 反例（L0:R0,R1；L1:R1；L2:R0）：最小覆盖 = {}，"
            "最大度贪婪 = {}", m3, c3);
    assert(m3 == 2 && c3 == 3);

    // 随机小图三方对账：匹配 vs 暴力覆盖必须相等；贪婪只统计其失败频率
    std::mt19937 rng{5489};
    int trials = 3000, mismatches = 0, greedy_losses = 0;
    for (int t = 0; t < trials; ++t) {
        const int nl = 1 + static_cast<int>(rand_below(rng, 4));
        const int nr = 1 + static_cast<int>(rand_below(rng, 4));
        BipartiteGraph g(nl, nr);
        for (int u = 0; u < nl; ++u) {
            for (int v = 0; v < nr; ++v) {
                if (rng() & 1u) { g.add_edge(u, v); }
            }
        }
        const int match = bipartite_max_matching(g);
        if (match != brute_vertex_cover(g)) { ++mismatches; }
        if (greedy_vertex_cover(g) > match) { ++greedy_losses; }
    }
    println("  随机 {} 个小二部图：匹配 vs 暴力最小覆盖 不一致 {} 例；"
            "贪婪严格更差 {} 例", trials, mismatches, greedy_losses);
    assert(mismatches == 0 && greedy_losses > 0);
}

// ═══ 27.7 女孩与男孩：二部图最大独立集 ═══
// 关系只存在于两性之间 ⟹ 图是二部图。求「两两无关系」的最大人数
// = 最大独立集。两种解法对账，再加 2ⁿ 暴力第三方法。

// 解法一（2-染色分量取大）：每个连通分量二染色，取人数较多的一色
//——同色者之间无边；各分量独立选取，求和。
static int independent_set_by_coloring(const std::vector<std::vector<int>>& adj) {
    const int n = static_cast<int>(adj.size());
    std::vector<int> color(static_cast<std::size_t>(n), -1);
    int answer = 0;
    for (int s = 0; s < n; ++s) {
        if (color[static_cast<std::size_t>(s)] != -1) { continue; }
        std::vector<int> cnt{0, 0};
        std::vector<int> q;
        q.push_back(s);
        color[static_cast<std::size_t>(s)] = 0;
        for (std::size_t qi = 0; qi < q.size(); ++qi) {
            const int u = q[qi];
            ++cnt[static_cast<std::size_t>(color[static_cast<std::size_t>(u)])];
            for (int v : adj[static_cast<std::size_t>(u)]) {
                if (color[static_cast<std::size_t>(v)] == -1) {
                    color[static_cast<std::size_t>(v)] =
                        color[static_cast<std::size_t>(u)] ^ 1;
                    q.push_back(v);
                }
            }
        }
        answer += std::max(cnt[0], cnt[1]);
    }
    return answer;
}

// 同一染色过程，额外返回颜色表（供解法二构造二部图）。
static int color_graph(const std::vector<std::vector<int>>& adj,
                       std::vector<int>& color) {
    const int n = static_cast<int>(adj.size());
    color.assign(static_cast<std::size_t>(n), -1);
    int answer = 0;
    for (int s = 0; s < n; ++s) {
        if (color[static_cast<std::size_t>(s)] != -1) { continue; }
        std::vector<int> cnt{0, 0};
        std::vector<int> q;
        q.push_back(s);
        color[static_cast<std::size_t>(s)] = 0;
        for (std::size_t qi = 0; qi < q.size(); ++qi) {
            const int u = q[qi];
            ++cnt[static_cast<std::size_t>(color[static_cast<std::size_t>(u)])];
            for (int v : adj[static_cast<std::size_t>(u)]) {
                if (color[static_cast<std::size_t>(v)] == -1) {
                    color[static_cast<std::size_t>(v)] =
                        color[static_cast<std::size_t>(u)] ^ 1;
                    q.push_back(v);
                }
            }
        }
        answer += std::max(cnt[0], cnt[1]);
    }
    return answer;
}

// 解法二（König）：α = n − τ = n − ν，ν 为最大匹配。
// 染色后把 color0 当左部、color1 当右部，边定向，跑 Kuhn。
static int independent_set_by_konig(const std::vector<std::vector<int>>& adj,
                                    int& matching_out) {
    const int n = static_cast<int>(adj.size());
    std::vector<int> color;
    color_graph(adj, color);
    std::vector<int> local(static_cast<std::size_t>(n), -1);
    int nl = 0, nr = 0;
    for (int u = 0; u < n; ++u) {
        if (color[static_cast<std::size_t>(u)] == 0) {
            local[static_cast<std::size_t>(u)] = nl++;
        } else {
            local[static_cast<std::size_t>(u)] = nr++;
        }
    }
    BipartiteGraph g(nl, nr);
    for (int u = 0; u < n; ++u) {
        if (color[static_cast<std::size_t>(u)] != 0) { continue; }
        for (int v : adj[static_cast<std::size_t>(u)]) {
            g.add_edge(local[static_cast<std::size_t>(u)],
                       local[static_cast<std::size_t>(v)]);
        }
    }
    matching_out = bipartite_max_matching(g);
    return n - matching_out;
}

// 暴力最大独立集：枚举 2ⁿ 个顶点子集，子集内无两端同选的边。
static int independent_set_brute(const std::vector<std::vector<int>>& adj) {
    const int n = static_cast<int>(adj.size());
    std::vector<std::pair<int, int>> edges;
    for (int u = 0; u < n; ++u)
        for (int v : adj[static_cast<std::size_t>(u)])
            if (u < v) { edges.emplace_back(u, v); }
    int best = 0;
    for (int mask = 0; mask < (1 << n); ++mask) {
        bool ok = true;
        for (auto [u, v] : edges) {
            if ((mask & (1 << u)) && (mask & (1 << v))) { ok = false; break; }
        }
        if (ok) { best = std::max(best, std::popcount(static_cast<unsigned>(mask))); }
    }
    return best;
}

static void girls_boys_demo() {
    println("女孩与男孩（二部图最大独立集：König n−匹配为正解，染色取大对照，暴力对账）：");
    struct Case {
        int n;
        std::vector<std::pair<int, int>> edges;
        int color_answer;     // 染色取大法给出的数（可能偏小）
        int optimum;          // 正确答案
    };
    const std::vector<Case> cases = {
        // 前两个是题面样例：两法恰好一致。
        {7, {{0,4},{0,5},{0,6},{1,4},{1,6}}, 5, 5},
        {3, {{0,1},{0,2}}, 2, 2},
        // Hall 反例（左 4 右 3，全连通但匹配只有 2）：
        // R0 与全部 4 个左点相邻，R1、R2 只与 L0 相邻。
        // 染色取大只给 4，最优独立集 {L1,L2,L3,R1,R2} 有 5 人。
        {7, {{0,4},{1,4},{2,4},{3,4},{0,5},{0,6}}, 4, 5}};
    for (std::size_t c = 0; c < cases.size(); ++c) {
        std::vector<std::vector<int>> adj(static_cast<std::size_t>(cases[c].n));
        for (auto [u, v] : cases[c].edges) {
            adj[static_cast<std::size_t>(u)].push_back(v);
            adj[static_cast<std::size_t>(v)].push_back(u);
        }
        const int by_color = independent_set_by_coloring(adj);
        int matching = 0;
        const int by_konig = independent_set_by_konig(adj, matching);
        const int brute = independent_set_brute(adj);
        println("  案例{}（{} 人）：染色取大 {}，König {}（{}−匹配 {}），暴力 {}",
                c + 1, cases[c].n, by_color, by_konig, cases[c].n, matching, brute);
        assert(by_color == cases[c].color_answer &&
               by_konig == cases[c].optimum && brute == cases[c].optimum);
    }
    // 随机二部图（左右顶点随机连边后整体随机重编号）：König 与暴力必须
    // 完全一致；染色取大只允许偏小，统计它偏小的频率。
    std::mt19937 rng{5489};
    int trials = 2000, mismatches = 0, color_losses = 0;
    for (int t = 0; t < trials; ++t) {
        const int nleft = 1 + static_cast<int>(rand_below(rng, 6));
        const int nright = 1 + static_cast<int>(rand_below(rng, 6));
        std::vector<std::pair<int, int>> raw;
        for (int i = 0; i < nleft; ++i)
            for (int j = 0; j < nright; ++j)
                if (rng() & 1u) { raw.emplace_back(i, nleft + j); }
        const int n = nleft + nright;
        std::vector<int> perm(static_cast<std::size_t>(n));
        std::iota(perm.begin(), perm.end(), 0);
        for (int i = n - 1; i > 0; --i) {
            const int j = static_cast<int>(rand_below(
                rng, static_cast<std::uint32_t>(i + 1)));
            std::swap(perm[static_cast<std::size_t>(i)],
                      perm[static_cast<std::size_t>(j)]);
        }
        std::vector<std::vector<int>> adj(static_cast<std::size_t>(n));
        for (auto [u, v] : raw) {
            const int uu = perm[static_cast<std::size_t>(u)];
            const int vv = perm[static_cast<std::size_t>(v)];
            adj[static_cast<std::size_t>(uu)].push_back(vv);
            adj[static_cast<std::size_t>(vv)].push_back(uu);   // 无向边两个方向都入表
        }
        const int a = independent_set_by_coloring(adj);
        int matching = 0;
        const int b = independent_set_by_konig(adj, matching);
        const int c = independent_set_brute(adj);
        if (b != c) { ++mismatches; }
        if (a < b) { ++color_losses; }
    }
    println("  随机 {} 例（n≤12，顶点随机重编号）：König vs 暴力 不一致 {} 例；"
            "染色取大严格偏小 {} 例", trials, mismatches, color_losses);
    assert(mismatches == 0 && color_losses > 0);
}

// ═══ 27.8 午餐：食物—牛妞—饮料的「双方独占」如何用流表达 ═══
struct DiningCase {
    int n = 0, f = 0, d = 0;
    std::vector<std::vector<int>> foods;    // 每头牛妞喜欢的食物（0 基）
    std::vector<std::vector<int>> drinks;   // 每头牛妞喜欢的饮料（0 基）
    int answer = 0;
};

// 节点布局：s | F 个食物 | 每头牛妞 in/out 两点 | D 个饮料 | t。
struct DiningNetwork {
    std::vector<std::vector<int>> cap;
    int s = 0, t = 0;
};

static DiningNetwork build_dining_network(const DiningCase& c) {
    const int nodes = 1 + c.f + 2 * c.n + c.d + 1;
    DiningNetwork net;
    net.s = 0;
    net.t = nodes - 1;
    net.cap.assign(static_cast<std::size_t>(nodes),
                   std::vector<int>(static_cast<std::size_t>(nodes), 0));
    const int food0 = 1;
    const int cow0 = food0 + c.f;
    const int drink0 = cow0 + 2 * c.n;
    auto add = [&](int u, int v, int w) {
        net.cap[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] = w;
    };
    for (int x = 0; x < c.f; ++x) { add(net.s, food0 + x, 1); }       // 食物唯一
    for (int i = 0; i < c.n; ++i) {
        const int cin = cow0 + 2 * i;
        const int cout = cin + 1;
        add(cin, cout, 1);                                            // 牛妞唯一
        for (int x : c.foods[static_cast<std::size_t>(i)]) {
            add(food0 + x, cin, 1);
        }
        for (int x : c.drinks[static_cast<std::size_t>(i)]) {
            add(cout, drink0 + x, 1);
        }
    }
    for (int x = 0; x < c.d; ++x) { add(drink0 + x, net.t, 1); }      // 饮料唯一
    return net;
}

// 贪心对照：按牛妞编号处理，能配出一对空闲的（食物，饮料）就占下。
// 贪心永远是可行分配，故其值 ≤ 最优值。
static int dining_greedy(const DiningCase& c) {
    std::vector<char> used_food(static_cast<std::size_t>(c.f), 0);
    std::vector<char> used_drink(static_cast<std::size_t>(c.d), 0);
    int satisfied = 0;
    for (int i = 0; i < c.n; ++i) {
        bool got = false;
        for (int fi : c.foods[static_cast<std::size_t>(i)]) {
            if (used_food[static_cast<std::size_t>(fi)]) { continue; }
            for (int di : c.drinks[static_cast<std::size_t>(i)]) {
                if (used_drink[static_cast<std::size_t>(di)]) { continue; }
                used_food[static_cast<std::size_t>(fi)] = 1;
                used_drink[static_cast<std::size_t>(di)] = 1;
                got = true;
                ++satisfied;
                break;
            }
            if (got) { break; }
        }
    }
    return satisfied;
}

// 暴力对账：每头牛妞的选项为「不满意」或 (喜欢的食物 × 喜欢的饮料)，
// 混合进制枚举全部组合，检查食物/饮料冲突后取最大满意数。仅用于小例。
static int dining_brute(const DiningCase& c) {
    std::vector<long long> radix(static_cast<std::size_t>(c.n));
    long long total = 1;
    for (int i = 0; i < c.n; ++i) {
        radix[static_cast<std::size_t>(i)] =
            1 + static_cast<long long>(c.foods[static_cast<std::size_t>(i)].size()) *
                    c.drinks[static_cast<std::size_t>(i)].size();
        total *= radix[static_cast<std::size_t>(i)];
    }
    int best = 0;
    for (long long code = 0; code < total; ++code) {
        long long rest = code;
        std::vector<char> used_food(static_cast<std::size_t>(c.f), 0);
        std::vector<char> used_drink(static_cast<std::size_t>(c.d), 0);
        int satisfied = 0;
        bool valid = true;
        for (int i = 0; i < c.n && valid; ++i) {
            const long long digit = rest % radix[static_cast<std::size_t>(i)];
            rest /= radix[static_cast<std::size_t>(i)];
            if (digit == 0) { continue; }    // 该牛妞放弃
            const long long pick = digit - 1;
            const int fi = c.foods[static_cast<std::size_t>(i)][
                static_cast<std::size_t>(pick / static_cast<long long>(
                    c.drinks[static_cast<std::size_t>(i)].size()))];
            const int di = c.drinks[static_cast<std::size_t>(i)][
                static_cast<std::size_t>(pick % static_cast<long long>(
                    c.drinks[static_cast<std::size_t>(i)].size()))];
            if (used_food[static_cast<std::size_t>(fi)] ||
                used_drink[static_cast<std::size_t>(di)]) {
                valid = false;
                break;
            }
            used_food[static_cast<std::size_t>(fi)] = 1;
            used_drink[static_cast<std::size_t>(di)] = 1;
            ++satisfied;
        }
        if (valid) { best = std::max(best, satisfied); }
    }
    return best;
}

// 错误模型的对照值：把食物与饮料直接当二部图两边、牛妞喜欢的搭配当边，
// 求最大匹配。它不约束「同一条牛妞不能被用两次」，故可能偏大。
static int food_drink_matching(const DiningCase& c) {
    // Kuhn 增广：左侧食物 → 右侧饮料。
    std::vector<std::vector<int>> adj(static_cast<std::size_t>(c.f));
    std::vector<char> edge_seen(static_cast<std::size_t>(c.f * c.d), 0);
    for (int i = 0; i < c.n; ++i) {
        for (int fi : c.foods[static_cast<std::size_t>(i)]) {
            for (int di : c.drinks[static_cast<std::size_t>(i)]) {
                const int key = fi * c.d + di;
                if (!edge_seen[static_cast<std::size_t>(key)]) {
                    edge_seen[static_cast<std::size_t>(key)] = 1;
                    adj[static_cast<std::size_t>(fi)].push_back(di);
                }
            }
        }
    }
    std::vector<int> match(static_cast<std::size_t>(c.d), -1);
    int size = 0;
    for (int u = 0; u < c.f; ++u) {
        std::vector<char> seen(static_cast<std::size_t>(c.d), 0);
        auto augment = [&](this auto&& self, int x) -> bool {
            for (int v : adj[static_cast<std::size_t>(x)]) {
                if (seen[static_cast<std::size_t>(v)]) { continue; }
                seen[static_cast<std::size_t>(v)] = 1;
                if (match[static_cast<std::size_t>(v)] == -1 ||
                    self(match[static_cast<std::size_t>(v)])) {
                    match[static_cast<std::size_t>(v)] = x;
                    return true;
                }
            }
            return false;
        };
        if (augment(u)) { ++size; }
    }
    return size;
}

static void dining_demo() {
    println("=== 27.8 午餐：食物—牛妞—饮料压进一条流路 ===");
    const std::vector<DiningCase> cases = {
        // 样例（4 牛妞 / 3 食物 / 3 饮料）。
        {4, 3, 3,
         {{0, 1}, {1, 2}, {0, 2}, {0, 2}},
         {{2, 0}, {0, 1}, {0, 1}, {2}},
         3},
        // 一头牛妞喜欢全部：食物-饮料直接匹配会数出 4 个配对。
        {1, 2, 2, {{0, 1}}, {{0, 1}}, 1},
        // 两头牛妞只接受同一对：谁先拿到谁满意。
        {2, 1, 1, {{0}, {0}}, {{0}, {0}}, 1}};
    int case_no = 0;
    for (const DiningCase& c : cases) {
        ++case_no;
        const DiningNetwork net = build_dining_network(c);
        const MaxFlowResult r =
            edmonds_karp(net.cap, net.s, net.t, /*verbose=*/false);
        const bool legal =
            validate_flow(net.cap, r.flow, net.s, net.t, r.value);
        const int greedy = dining_greedy(c);
        println("  案例{}（{} 牛妞 / {} 食物 / {} 饮料）：最大流 {}，贪心 {}，流合法 {}",
                case_no, c.n, c.f, c.d, r.value, greedy, legal);
        assert(r.value == c.answer && legal);
        assert(greedy <= r.value);
        if (case_no == 2) {
            const int wrong = food_drink_matching(c);
            println("    食物-饮料直接匹配误报 {}（两个配对同属一头牛妞，正解 {}）",
                    wrong, c.answer);
            assert(wrong == 2 && wrong > c.answer);
        }
    }

    std::mt19937 rng{5489};
    // 随机小例：最大流 vs 暴力枚举。
    const int small_trials = 2000;
    int mismatches = 0;
    for (int t = 0; t < small_trials; ++t) {
        DiningCase c;
        c.n = 1 + static_cast<int>(rand_below(rng, 4));
        c.f = 1 + static_cast<int>(rand_below(rng, 3));
        c.d = 1 + static_cast<int>(rand_below(rng, 3));
        c.foods.resize(static_cast<std::size_t>(c.n));
        c.drinks.resize(static_cast<std::size_t>(c.n));
        for (int i = 0; i < c.n; ++i) {
            for (int x = 0; x < c.f; ++x) {
                if (rand_below(rng, 2) != 0) {
                    c.foods[static_cast<std::size_t>(i)].push_back(x);
                }
            }
            if (c.foods[static_cast<std::size_t>(i)].empty()) {
                c.foods[static_cast<std::size_t>(i)].push_back(
                    static_cast<int>(rand_below(rng, static_cast<std::uint32_t>(c.f))));
            }
            for (int x = 0; x < c.d; ++x) {
                if (rand_below(rng, 2) != 0) {
                    c.drinks[static_cast<std::size_t>(i)].push_back(x);
                }
            }
            if (c.drinks[static_cast<std::size_t>(i)].empty()) {
                c.drinks[static_cast<std::size_t>(i)].push_back(
                    static_cast<int>(rand_below(rng, static_cast<std::uint32_t>(c.d))));
            }
        }
        const DiningNetwork net = build_dining_network(c);
        const int flow = edmonds_karp(net.cap, net.s, net.t, false).value;
        const int brute = dining_brute(c);
        if (flow != brute) { ++mismatches; }
    }
    println("  随机 {} 小例（n≤4，F,D≤3）：最大流 vs 暴力 不一致 {} 例",
            small_trials, mismatches);
    assert(mismatches == 0);

    // 随机大例：跑得起、答案有界、贪心不越界。
    const int big_trials = 300;
    int bound_violations = 0;
    int greedy_violations = 0;
    for (int t = 0; t < big_trials; ++t) {
        DiningCase c;
        c.n = 1 + static_cast<int>(rand_below(rng, 100));
        c.f = 1 + static_cast<int>(rand_below(rng, 100));
        c.d = 1 + static_cast<int>(rand_below(rng, 100));
        c.foods.resize(static_cast<std::size_t>(c.n));
        c.drinks.resize(static_cast<std::size_t>(c.n));
        for (int i = 0; i < c.n; ++i) {
            const int nf = 1 + static_cast<int>(rand_below(rng, 4));
            for (int k = 0; k < nf; ++k) {
                c.foods[static_cast<std::size_t>(i)].push_back(
                    static_cast<int>(rand_below(rng,
                                                static_cast<std::uint32_t>(c.f))));
            }
            const int nd = 1 + static_cast<int>(rand_below(rng, 4));
            for (int k = 0; k < nd; ++k) {
                c.drinks[static_cast<std::size_t>(i)].push_back(
                    static_cast<int>(rand_below(rng,
                                                static_cast<std::uint32_t>(c.d))));
            }
        }
        const DiningNetwork net = build_dining_network(c);
        const int flow = edmonds_karp(net.cap, net.s, net.t, false).value;
        const int greedy = dining_greedy(c);
        if (flow > std::min({c.n, c.f, c.d})) { ++bound_violations; }
        if (greedy > flow) { ++greedy_violations; }
    }
    println("  随机 {} 大例（n,F,D≤100）：答案上界违反 {} 次；贪心>最优违反 {} 次",
            big_trials, bound_violations, greedy_violations);
    assert(bound_violations == 0 && greedy_violations == 0);
}

// ════════════════════════════════════════════════════════════════════
// 27.9 最小费用最大流
// ════════════════════════════════════════════════════════════════════
// 每条边除容量外还有单位费用 cost：送 1 单位流经过它要付 cost。目标：
// 在流量达到最大值（或指定值 limit）的前提下总费用最小。
// 邻接表存边；反向残量边的容量为 0、费用为 −cost——退流时把之前付的
// 钱退回来，因此残量网络里会出现负权边，但永远没有负环（原始费用非负
// 时逐次最短路成立）。
struct McfEdge {
    int to;       // 终点
    int rev;      // 反向边在 g[to] 中的下标
    int cap;      // 残量容量
    int cost;     // 单位费用（反向边为负）
};

static void mcf_add_edge(std::vector<std::vector<McfEdge>>& g,
                         int from, int to, int cap, int cost) {
    const int rev_index = static_cast<int>(g[static_cast<std::size_t>(to)].size());
    const int fwd_index = static_cast<int>(g[static_cast<std::size_t>(from)].size());
    g[static_cast<std::size_t>(from)].push_back({to, rev_index, cap, cost});
    g[static_cast<std::size_t>(to)].push_back({from, fwd_index, 0, -cost});
}

struct McfResult {
    int flow;
    long long cost;
    long long rounds;      // SPFA 轮数（含最后一轮检测）
};

// 逐次最短路：每轮在残量网络上找 s→t 费用最小的增广路，尽量增广。
// SPFA = 队列化 Bellman-Ford，容忍反向边的负权。
static McfResult min_cost_flow(std::vector<std::vector<McfEdge>> g,
                               int s, int t, int limit, bool verbose) {
    const int n = static_cast<int>(g.size());
    int flow = 0;
    long long cost = 0;
    long long rounds = 0;
    while (flow < limit) {
        const long long INF = (1LL << 60);
        std::vector<long long> dist(static_cast<std::size_t>(n), INF);
        std::vector<int> prev_v(static_cast<std::size_t>(n), -1);
        std::vector<int> prev_e(static_cast<std::size_t>(n), -1);
        std::vector<char> in_queue(static_cast<std::size_t>(n), 0);
        std::deque<int> q;
        dist[static_cast<std::size_t>(s)] = 0;
        q.push_back(s);
        in_queue[static_cast<std::size_t>(s)] = 1;
        while (!q.empty()) {
            const int u = q.front();
            q.pop_front();
            in_queue[static_cast<std::size_t>(u)] = 0;
            for (int i = 0; i < static_cast<int>(g[static_cast<std::size_t>(u)].size()); ++i) {
                const McfEdge& e = g[static_cast<std::size_t>(u)][static_cast<std::size_t>(i)];
                if (e.cap > 0 &&
                    dist[static_cast<std::size_t>(u)] + e.cost <
                        dist[static_cast<std::size_t>(e.to)]) {
                    dist[static_cast<std::size_t>(e.to)] =
                        dist[static_cast<std::size_t>(u)] + e.cost;
                    prev_v[static_cast<std::size_t>(e.to)] = u;
                    prev_e[static_cast<std::size_t>(e.to)] = i;
                    if (!in_queue[static_cast<std::size_t>(e.to)]) {
                        in_queue[static_cast<std::size_t>(e.to)] = 1;
                        q.push_back(e.to);
                    }
                }
            }
        }
        ++rounds;
        if (dist[static_cast<std::size_t>(t)] == INF) { break; }  // 已达最大流
        int add = limit - flow;
        for (int v = t; v != s; v = prev_v[static_cast<std::size_t>(v)]) {
            add = std::min(add,
                g[static_cast<std::size_t>(prev_v[static_cast<std::size_t>(v)])]
                 [static_cast<std::size_t>(prev_e[static_cast<std::size_t>(v)])].cap);
        }
        if (verbose) {
            std::vector<int> path;
            for (int v = t; v != s; v = prev_v[static_cast<std::size_t>(v)]) {
                path.push_back(v);
            }
            path.push_back(s);
            print("    增广路 #{}（瓶颈 {}，单位费用 {}）: ", rounds, add, dist[t]);
            for (std::size_t i = path.size(); i-- > 0;) {
                print("{}{}", path[i], i == 0 ? "" : "→");
            }
            println("（本轮费用 {}）", add * dist[t]);
        }
        for (int v = t; v != s; v = prev_v[static_cast<std::size_t>(v)]) {
            McfEdge& e = g[static_cast<std::size_t>(prev_v[static_cast<std::size_t>(v)])]
                          [static_cast<std::size_t>(prev_e[static_cast<std::size_t>(v)])];
            e.cap -= add;
            g[static_cast<std::size_t>(v)][static_cast<std::size_t>(e.rev)].cap += add;
        }
        flow += add;
        cost += add * dist[static_cast<std::size_t>(t)];
    }
    return {flow, cost, rounds};
}

// 独立对账：把每条正向边的流量当整数变量直接枚举（0..cap），叶端检查
// 流量守恒，记录每个流量值 F 的最小费用。与逐次最短路完全独立。
struct McfBruteEdge { int u, v, cap, cost; };

static void mcf_brute_rec(const std::vector<McfBruteEdge>& edges, int idx,
                          std::vector<int>& net, long long spent,
                          int s, int t, std::vector<long long>& best) {
    if (idx == static_cast<int>(edges.size())) {
        for (int v = 0; v < static_cast<int>(net.size()); ++v) {
            if (v == s || v == t) { continue; }
            if (net[static_cast<std::size_t>(v)] != 0) { return; }
        }
        if (net[static_cast<std::size_t>(s)] > 0 ||
            net[static_cast<std::size_t>(t)] < 0 ||
            net[static_cast<std::size_t>(s)] + net[static_cast<std::size_t>(t)] != 0) {
            return;
        }
        const int f = -net[static_cast<std::size_t>(s)];
        best[static_cast<std::size_t>(f)] =
            std::min(best[static_cast<std::size_t>(f)], spent);
        return;
    }
    const McfBruteEdge& e = edges[static_cast<std::size_t>(idx)];
    for (int f = 0; f <= e.cap; ++f) {
        net[static_cast<std::size_t>(e.u)] -= f;
        net[static_cast<std::size_t>(e.v)] += f;
        mcf_brute_rec(edges, idx + 1, net, spent + 1LL * f * e.cost, s, t, best);
        net[static_cast<std::size_t>(e.u)] += f;
        net[static_cast<std::size_t>(e.v)] -= f;
    }
}

static std::vector<long long> mcf_brute(
        const std::vector<McfBruteEdge>& edges, int n, int s, int t, int max_f) {
    std::vector<int> net(static_cast<std::size_t>(n), 0);
    std::vector<long long> best(static_cast<std::size_t>(max_f) + 1, (1LL << 60));
    best[0] = 0;
    mcf_brute_rec(edges, 0, net, 0, s, t, best);
    return best;
}

static void min_cost_flow_demo() {
    println("");
    println("=== 27.9 最小费用最大流：残量网络逐次最短路（SPFA）===");
    // 案例 1：节点 0=s,1=a,2=b,3=t。两条独立路线：
    //   s→a cap3 cost4，a→t cap7 cost4（单位费用 8）
    //   s→b cap4 cost8，b→t cap4 cost8（单位费用 16）
    // 先推满便宜路线 3 个，再走贵路线 4 个。
    {
        const int n = 4, s = 0, t = 3;
        std::vector<std::vector<McfEdge>> g(static_cast<std::size_t>(n));
        mcf_add_edge(g, 0, 1, 3, 4);
        mcf_add_edge(g, 1, 3, 7, 4);
        mcf_add_edge(g, 0, 2, 4, 8);
        mcf_add_edge(g, 2, 3, 4, 8);
        println("  案例1（两条独立路线，便宜路 s→a→t 单位 8/容量 3，贵路单位 16/容量 4）：");
        const McfResult r = min_cost_flow(g, s, t, INT32_MAX, true);
        println("    结果：流量 {}，最小费用 {}（手算 3×8 + 4×16 = 88）", r.flow, r.cost);
        assert(r.flow == 7 && r.cost == 88 && r.rounds == 3);
    }
    // 案例 2：退流改道。s→1(1,费用1)，s→2(1,费用4)，1→2(1,费用1)，
    // 1→t(1,费用100)，2→t(1,费用2)。
    // 第 1 单位走 s→1→2→t（费用 4），把 2→t 占满；第 2 单位只能
    // s→2，再沿反向边 2→1（费用 −1）退流改道，让先前那单位改走 1→t：
    // 费用 4−1+100 = 103。等价于最优分配 s→1→t(101) + s→2→t(6) = 107。
    {
        const int n = 4, s = 0, t = 3;
        std::vector<std::vector<McfEdge>> g(static_cast<std::size_t>(n));
        mcf_add_edge(g, 0, 1, 1, 1);
        mcf_add_edge(g, 0, 2, 1, 4);
        mcf_add_edge(g, 1, 2, 1, 1);
        mcf_add_edge(g, 1, 3, 1, 100);
        mcf_add_edge(g, 2, 3, 1, 2);
        println("  案例2（退流改道：反向边费用 −1 把先前支付的费用退回）：");
        const McfResult r = min_cost_flow(g, s, t, INT32_MAX, true);
        println("    结果：流量 {}，最小费用 {}（手算 101 + 6 = 107）", r.flow, r.cost);
        assert(r.flow == 2 && r.cost == 107);
    }

    // 随机对账：4 个节点（s、2 中间点、t），随机边/容量/费用。
    std::mt19937 rng{5489};
    const int trials = 2000;
    int mismatches = 0;
    for (int trial = 0; trial < trials; ++trial) {
        const int n = 4, s = 0, t = 3;
        std::vector<std::vector<int>> cap(static_cast<std::size_t>(n),
            std::vector<int>(static_cast<std::size_t>(n), 0));
        std::vector<std::vector<int>> cost(static_cast<std::size_t>(n),
            std::vector<int>(static_cast<std::size_t>(n), 0));
        std::vector<McfBruteEdge> edges;
        for (int u = 0; u < n; ++u) {
            for (int v = u + 1; v < n; ++v) {
                if (u != s && rand_below(rng, 2) == 0) { continue; }
                if (rand_below(rng, 2) == 0) {
                    const int c = 1 + static_cast<int>(rand_below(rng, 4));
                    const int w = static_cast<int>(rand_below(rng, 10));
                    cap[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] = c;
                    cost[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] = w;
                    edges.push_back({u, v, c, w});
                }
            }
        }
        const int fmax = edmonds_karp(cap, s, t, false).value;
        if (fmax == 0) { continue; }
        std::vector<std::vector<McfEdge>> g(static_cast<std::size_t>(n));
        for (const McfBruteEdge& e : edges) {
            mcf_add_edge(g, e.u, e.v, e.cap, e.cost);
        }
        const std::vector<long long> best = mcf_brute(edges, n, s, t, fmax);
        // 对每个目标流量 F 分别求最小费用，逐点对账。
        for (int f = 1; f <= fmax; ++f) {
            const McfResult r = min_cost_flow(g, s, t, f, false);
            if (r.flow != f || r.cost != best[static_cast<std::size_t>(f)]) {
                ++mismatches;
            }
        }
    }
    println("  随机 {} 例（4 节点）：逐流量 SPFA vs 边流量枚举 不一致 {} 例",
            trials, mismatches);
    assert(mismatches == 0);

    // 大例：50 节点随机费用网络，SPFA 增广仍然很快。
    {
        const int n = 50, s = 0, t = n - 1;
        std::vector<std::vector<McfEdge>> g(static_cast<std::size_t>(n));
        int edges_added = 0;
        for (int u = 0; u < n; ++u) {
            for (int v = u + 1; v < n; ++v) {
                if (rand_below(rng, 3) == 0) {
                    mcf_add_edge(g, u, v, 1 + static_cast<int>(rand_below(rng, 20)),
                                 static_cast<int>(rand_below(rng, 50)));
                    ++edges_added;
                }
            }
        }
        const McfResult r = min_cost_flow(g, s, t, INT32_MAX, false);
        // 无费用约束时的最大流（对账流量值）：
        std::vector<std::vector<int>> cap(static_cast<std::size_t>(n),
            std::vector<int>(static_cast<std::size_t>(n), 0));
        for (int u = 0; u < n; ++u) {
            for (const McfEdge& e : g[static_cast<std::size_t>(u)]) {
                if (e.cost >= 0) {   // 只数正向边
                    cap[static_cast<std::size_t>(u)][static_cast<std::size_t>(e.to)] = e.cap;
                }
            }
        }
        const int fmax = edmonds_karp(cap, s, t, false).value;
        println("  大例（50 节点 / {} 正向边）：最大流 {}，最小费用 {}；流量与无费用最大流一致 = {}",
                edges_added, r.flow, r.cost, r.flow == fmax);
        assert(r.flow == fmax);
    }
}

// ════════════════════════════════════════════════════════════════════
// 27.10 方格取数：最大权独立集
// ════════════════════════════════════════════════════════════════════
// m×n 方格每格有一个权值，选若干格使任意两个被选格不共边（上/下/左/右
// 相邻），求权值和最大。棋盘天然二部：(x+y) 偶的格染黑、奇的染白，每条
// 共边关系都跨颜色。构造流网络：源→黑格容量=该格权值；白格→汇容量=权
// 值；黑格→每个相邻白格容量=∞。任何割都不会切断 ∞ 边（割容 ≤ 总权），
// 所以割两侧的取法恰好给出一个合法方案：
//   割容 = 被弃黑格的权 + 被选白格的权？—— 直接用 总权−最大流 = 最优权。
// 方案还原：残量网络中从源可达的黑格入选；不可达的白格入选。
struct GridChoice {
    int value;
    std::vector<std::pair<int, int>> cells;
};

static GridChoice grid_select(const std::vector<std::vector<int>>& w) {
    const int rows = static_cast<int>(w.size());
    const int cols = static_cast<int>(w[0].size());
    const int cells_n = rows * cols;
    const int s = cells_n, t = cells_n + 1, total_nodes = cells_n + 2;
    int total = 0;
    for (const auto& row : w) {
        for (int v : row) { total += v; }
    }
    std::vector<std::vector<int>> cap(static_cast<std::size_t>(total_nodes),
        std::vector<int>(static_cast<std::size_t>(total_nodes), 0));
    auto id = [cols](int x, int y) { return x * cols + y; };
    static const int dx[4]{0, 1, 0, -1};
    static const int dy[4]{1, 0, -1, 0};
    const int INF = total + 1;   // 任何有限割都 ≤ total，∞ 边必不被切
    for (int x = 0; x < rows; ++x) {
        for (int y = 0; y < cols; ++y) {
            const int u = id(x, y);
            if ((x + y) % 2 == 0) {
                cap[static_cast<std::size_t>(s)][static_cast<std::size_t>(u)] =
                    w[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)];
                for (int d = 0; d < 4; ++d) {
                    const int nx = x + dx[d], ny = y + dy[d];
                    if (0 <= nx && nx < rows && 0 <= ny && ny < cols) {
                        cap[static_cast<std::size_t>(u)]
                           [static_cast<std::size_t>(id(nx, ny))] = INF;
                    }
                }
            } else {
                cap[static_cast<std::size_t>(u)][static_cast<std::size_t>(t)] =
                    w[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)];
            }
        }
    }
    const MaxFlowResult r = edmonds_karp(cap, s, t, false);
    // 残量可达性
    std::vector<char> reach(static_cast<std::size_t>(total_nodes), 0);
    std::deque<int> q;
    reach[static_cast<std::size_t>(s)] = 1;
    q.push_back(s);
    while (!q.empty()) {
        const int u = q.front();
        q.pop_front();
        for (int v = 0; v < total_nodes; ++v) {
            if (!reach[static_cast<std::size_t>(v)] &&
                cap[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] -
                    r.flow[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] > 0) {
                reach[static_cast<std::size_t>(v)] = 1;
                q.push_back(v);
            }
        }
    }
    GridChoice ans;
    ans.value = total - r.value;
    for (int x = 0; x < rows; ++x) {
        for (int y = 0; y < cols; ++y) {
            const bool chosen = (x + y) % 2 == 0
                ? reach[static_cast<std::size_t>(id(x, y))] != 0
                : reach[static_cast<std::size_t>(id(x, y))] == 0;
            if (chosen) { ans.cells.push_back({x, y}); }
        }
    }
    return ans;
}

// 暴力：枚举全部 2^N 个子集，过滤相邻冲突。
static int grid_brute(const std::vector<std::vector<int>>& w) {
    const int rows = static_cast<int>(w.size());
    const int cols = static_cast<int>(w[0].size());
    const int n = rows * cols;
    int best = 0;
    for (int mask = 0; mask < (1 << n); ++mask) {
        bool ok = true;
        int sum = 0;
        for (int x = 0; x < rows && ok; ++x) {
            for (int y = 0; y < cols; ++y) {
                const int bit = x * cols + y;
                if ((mask & (1 << bit)) == 0) { continue; }
                sum += w[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)];
                if (y + 1 < cols && (mask & (1 << (x * cols + y + 1)))) { ok = false; }
                if (x + 1 < rows && (mask & (1 << ((x + 1) * cols + y)))) { ok = false; }
            }
        }
        if (ok) { best = std::max(best, sum); }
    }
    return best;
}

static void grid_pick_demo() {
    println("");
    println("=== 27.10 方格取数：棋盘染色 + 最小割（总权 − 最大流）===");
    // 3×3 例：
    //    75 250  21
    //    34  70   5
    //    75  15  58
    std::vector<std::vector<int>> w = {
        {75, 250, 21},
        {34, 70, 5},
        {75, 15, 58}};
    const GridChoice ans = grid_select(w);
    const int brute = grid_brute(w);
    int total = 0;
    for (const auto& row : w) {
        for (int v : row) { total += v; }
    }
    println("  3×3 方格（总权 {}）：最大权 = {}（2^9 子集枚举 {}），选中格子：",
            total, ans.value, brute);
    std::vector<std::string> overlay = {
        std::string(3, '.'), std::string(3, '.'), std::string(3, '.')};
    for (auto [x, y] : ans.cells) {
        overlay[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)] = '*';
    }
    for (const std::string& row : overlay) { println("    {}", row); }
    int picked_sum = 0;
    for (auto [x, y] : ans.cells) {
        picked_sum += w[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)];
    }
    println("    选中格权值核对 = {}；方案合法性（无共边对）见随机对账", picked_sum);
    assert(ans.value == 383 && brute == 383 && picked_sum == 383);
    assert(ans.cells.size() == 3);

    // 随机对账：≤9 格的随机棋盘，流构造 vs 全子集枚举；同时核验方案。
    std::mt19937 rng{5489};
    const int trials = 2000;
    int value_mismatches = 0;
    int invalid_schemes = 0;
    for (int trial = 0; trial < trials; ++trial) {
        const int rows = 2 + static_cast<int>(rand_below(rng, 2));
        const int cols = 2 + static_cast<int>(rand_below(rng, 2));
        std::vector<std::vector<int>> a(static_cast<std::size_t>(rows),
            std::vector<int>(static_cast<std::size_t>(cols)));
        for (int x = 0; x < rows; ++x) {
            for (int y = 0; y < cols; ++y) {
                a[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)] =
                    1 + static_cast<int>(rand_below(rng, 99));
            }
        }
        const GridChoice got = grid_select(a);
        const int expect = grid_brute(a);
        if (got.value != expect) { ++value_mismatches; }
        int sum = 0;
        bool valid = true;
        for (std::size_t i = 0; i < got.cells.size(); ++i) {
            auto [x1, y1] = got.cells[i];
            sum += a[static_cast<std::size_t>(x1)][static_cast<std::size_t>(y1)];
            for (std::size_t j = i + 1; j < got.cells.size(); ++j) {
                auto [x2, y2] = got.cells[j];
                if (std::abs(x1 - x2) + std::abs(y1 - y2) == 1) { valid = false; }
            }
        }
        if (!valid || sum != got.value) { ++invalid_schemes; }
    }
    println("  随机 {} 例（2~3 行 × 2~3 列）：最优值不一致 {} 例；方案非法/权值不符 {} 例",
            trials, value_mismatches, invalid_schemes);
    assert(value_mismatches == 0 && invalid_schemes == 0);

    // 大例：40×40，用推送-重贴标签求流（Edmonds-Karp 对该规模偏慢）。
    // 这里只验证规模可解性与答案上下界。
    const int rows = 40, cols = 40;
    std::vector<std::vector<int>> big(static_cast<std::size_t>(rows),
        std::vector<int>(static_cast<std::size_t>(cols)));
    int big_total = 0;
    for (int x = 0; x < rows; ++x) {
        for (int y = 0; y < cols; ++y) {
            big[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)] =
                1 + static_cast<int>(rand_below(rng, 999));
            big_total += big[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)];
        }
    }
    const GridChoice big_ans = grid_select(big);
    // 合法方案必然满足 0 ≤ 答案 ≤ 总权；另一个可行解：所有黑格。
    int black_sum = 0;
    for (int x = 0; x < rows; ++x) {
        for (int y = 0; y < cols; ++y) {
            if ((x + y) % 2 == 0) {
                black_sum += big[static_cast<std::size_t>(x)][static_cast<std::size_t>(y)];
            }
        }
    }
    println("  大例（40×40，总权 {}）：最大权 {}，≥ 单色可行解 {}，方案格数 {}",
            big_total, big_ans.value, black_sum, big_ans.cells.size());
    assert(big_ans.value >= black_sum && big_ans.value <= big_total);
}

// ═══ 27.11 慈善捐款：运输问题的最大流建模 ═══
// n 位捐款人、k 家孤儿院：人 i 总额上限 d_i、对院 j 的指定上限 c_ij、
// 院 j 接受总额上限 o_j，最大化总捐款。
// 建网：S→人（d_i）、人→院（c_ij）、院→T（o_j），最大流即答案。
// 「公平上限」天然由容量表达——这正是流的母语。
struct DonationCase {
    int n = 0, k = 0;
    std::vector<int> donor_cap, home_cap;
    std::vector<std::vector<int>> pair_cap;
};

static std::vector<std::vector<int>> donation_network(const DonationCase& c) {
    const int N = c.n + c.k + 2;
    std::vector<std::vector<int>> cap(
        static_cast<std::size_t>(N), std::vector<int>(static_cast<std::size_t>(N), 0));
    for (int i = 0; i < c.n; ++i) {
        cap[0][1 + i] = c.donor_cap[static_cast<std::size_t>(i)];
    }
    for (int i = 0; i < c.n; ++i) {
        for (int j = 0; j < c.k; ++j) {
            cap[1 + i][1 + c.n + j] =
                c.pair_cap[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)];
        }
    }
    for (int j = 0; j < c.k; ++j) {
        cap[1 + c.n + j][N - 1] = c.home_cap[static_cast<std::size_t>(j)];
    }
    return cap;
}

// 独立对账：枚举全部 S-T 割（中间点二分为源侧/汇侧），最小割 ==
// 最大流（定理 26.6? max-flow min-cut）。中间点 ≤ 12 可行。
static int donation_min_cut_brute(const DonationCase& c) {
    const int mid = c.n + c.k;
    int best = INT32_MAX;
    for (int mask = 0; mask < (1 << mid); ++mask) {
        int cut = 0;
        for (int i = 0; i < c.n; ++i) {
            if (!(mask >> i & 1)) { cut += c.donor_cap[static_cast<std::size_t>(i)]; }
        }
        for (int j = 0; j < c.k; ++j) {
            if (mask >> (c.n + j) & 1) { cut += c.home_cap[static_cast<std::size_t>(j)]; }
        }
        for (int i = 0; i < c.n; ++i) {
            if (!(mask >> i & 1)) { continue; }
            for (int j = 0; j < c.k; ++j) {
                if (!(mask >> (c.n + j) & 1)) {
                    cut += c.pair_cap[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)];
                }
            }
        }
        best = std::min(best, cut);
    }
    return best;
}

static void donation_demo() {
    println("");
    println("=== 27.11 慈善捐款：运输问题的最大流（S→人→院→T）===");
    const DonationCase fx{
        3, 2,
        {10, 10, 10},                       // 三人各至多捐 10
        {8, 12},                            // 两院各至多收 8 / 12
        {{6, 4}, {0, 8}, {5, 0}},           // 指定上限：甲只肯给两院 6/4 …
    };
    const auto net = donation_network(fx);
    const MaxFlowResult r = edmonds_karp(net, 0, fx.n + fx.k + 1, false);
    println("  固定例（3 人 2 院，人额 10×3、院额 8+12）：最大总捐款 {}（= 两院饱和）",
            r.value);
    assert(r.value == 20);
    assert(validate_flow(net, r.flow, 0, fx.n + fx.k + 1, r.value));
    println("  分配方案（人→院 : 额度）：");
    for (int i = 0; i < fx.n; ++i) {
        for (int j = 0; j < fx.k; ++j) {
            const int f = r.flow[static_cast<std::size_t>(1 + i)][static_cast<std::size_t>(1 + fx.n + j)];
            if (f > 0) { println("    人{}→院{} : {}", i + 1, j + 1, f); }
        }
    }
    println("  （容量/守恒/反对称合法性 = 1；逐人不超额、逐院不超额见下）");
    // 逐人、逐院额度复核（守恒之外的口径检查）
    for (int i = 0; i < fx.n; ++i) {
        int gave = 0;
        for (int j = 0; j < fx.k; ++j) {
            gave += std::max(0, r.flow[static_cast<std::size_t>(1 + i)][static_cast<std::size_t>(1 + fx.n + j)]);
        }
        assert(gave <= fx.donor_cap[static_cast<std::size_t>(i)]);
    }
    for (int j = 0; j < fx.k; ++j) {
        int got = 0;
        for (int i = 0; i < fx.n; ++i) {
            got += std::max(0, r.flow[static_cast<std::size_t>(1 + i)][static_cast<std::size_t>(1 + fx.n + j)]);
        }
        assert(got <= fx.home_cap[static_cast<std::size_t>(j)]);
    }

    // 随机 200 例（n,k ≤ 4）：最大流 vs 最小割枚举（定理互证）
    std::mt19937 rng{5489};
    int bad = 0;
    for (int t = 0; t < 200; ++t) {
        const int n = 1 + static_cast<int>(rand_below(rng, 4));
        const int k = 1 + static_cast<int>(rand_below(rng, 4));
        DonationCase c;
        c.n = n; c.k = k;
        c.donor_cap.assign(static_cast<std::size_t>(n), 0);
        c.home_cap.assign(static_cast<std::size_t>(k), 0);
        c.pair_cap.assign(static_cast<std::size_t>(n),
                          std::vector<int>(static_cast<std::size_t>(k), 0));
        for (int& d : c.donor_cap) { d = static_cast<int>(rand_below(rng, 10)); }
        for (int& o : c.home_cap) { o = static_cast<int>(rand_below(rng, 10)); }
        for (auto& row : c.pair_cap) {
            for (int& v : row) { v = static_cast<int>(rand_below(rng, 8)); }
        }
        const auto nn = donation_network(c);
        const MaxFlowResult rr = edmonds_karp(nn, 0, n + k + 1, false);
        if (rr.value != donation_min_cut_brute(c)) { ++bad; }
    }
    println("  随机 200 例（n,k≤4）：最大流 vs 最小割枚举不一致 {} 例", bad);
    assert(bad == 0);

    // 大例：60 人 40 院，只跑 EK + 合法性 + 上下界
    DonationCase big;
    big.n = 60; big.k = 40;
    big.donor_cap.assign(60, 0);
    big.home_cap.assign(40, 0);
    big.pair_cap.assign(60, std::vector<int>(40, 0));
    long long sum_d = 0, sum_o = 0;
    for (int& d : big.donor_cap) { d = 1 + static_cast<int>(rand_below(rng, 50)); sum_d += d; }
    for (int& o : big.home_cap) { o = 1 + static_cast<int>(rand_below(rng, 60)); sum_o += o; }
    for (auto& row : big.pair_cap) {
        for (int& v : row) { v = static_cast<int>(rand_below(rng, 30)); }
    }
    const auto bn = donation_network(big);
    const MaxFlowResult br = edmonds_karp(bn, 0, 101, false);
    println("  大例（60 人 40 院）：最大总捐款 {}（供 {} 需 {}，上界 {}）",
            br.value, sum_d, sum_o, std::min(sum_d, sum_o));
    assert(br.value <= std::min(sum_d, sum_o));
    assert(validate_flow(bn, br.flow, 0, 101, br.value));
}

int main() {
    edmonds_karp_demo();
    push_relabel_demo();
    machine_schedule_demo();
    girls_boys_demo();
    dining_demo();
    min_cost_flow_demo();
    grid_pick_demo();
    donation_demo();
    println("自检通过");
    return 0;
}
