// 27 最大流（CLRS 第 26 章）。结构：27.1 流网络与残量网络 /
// 27.2 Edmonds-Karp（BFS 增广路径逐条追踪，图 26.1 数据）/
// 27.3 流的合法性验证（容量约束 + 流量守恒）/ 27.4 最小割验证（最大流
// 最小割定理）/ 27.5 推送-重贴标签对照 /
// 27.6 二部图匹配与最小点覆盖（König 定理；Kuhn 增广路）。
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
#include <deque>
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
static MaxFlowResult edmonds_karp(std::vector<std::vector<int>> cap, int s, int t) {
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
        print("  增广路径 #{}（瓶颈 {}）: ", bfs, bottleneck);
        std::vector<int> path;
        for (int v = t; v != s; ) { path.push_back(v); v = parent[static_cast<std::size_t>(v)]; }
        path.push_back(s);
        for (std::size_t i = path.size(); i-- > 0;) {
            print("{}{}", kNode[static_cast<std::size_t>(path[i])], i == 0 ? "" : "→");
        }
        println("（累计流 {}）", total);
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

int main() {
    edmonds_karp_demo();
    push_relabel_demo();
    machine_schedule_demo();
    println("自检通过");
    return 0;
}
