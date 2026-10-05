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
#include <string>
#include <utility>
#include <vector>

struct DiGraph {
    int n;
    std::vector<std::vector<std::pair<int, int>>> adj;   // (to, w)
    explicit DiGraph(int n_) : n(n_), adj(static_cast<std::size_t>(n_)) {}
    void add(int u, int v, int w) { adj[static_cast<std::size_t>(u)].emplace_back(v, w); }
};

constexpr int INF = INT32_MAX;
constexpr long long INF64 = (1LL << 62);   // 时间依赖部分的「无穷大」

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

// ═══ 25.5 时间依赖最短路：时刻表、候车与 FIFO 性质 ═══
//
// 普通最短路的边权 w(u,v) 是**常数**；公交/地铁场景里它是**出发时间的
// 单调不减函数** f(t)：「你在时刻 t 位于 u，最早何时到达 v」。
//   步行边： f(t) = t + w            （常数时间，随时可走）
//   车行边： f(t) = min{ t_j + S_{x+1} : t_j + S_x ≥ t }
//                    （S_x = 该线路从起点累计到第 x 站的行驶时间）
//
// **FIFO 性质**：f 单调不减，即「到得早从不更差」。这正是 Dijkstra 的贪心
// 证明（25.3）能照搬的前提——早到的状态支配晚到的状态。没有 FIFO，Dijkstra
// 失效：见下面 non_fifo_counterexample()。
//
// **班次表不要展开**：朴素做法把「每趟车的每一段」都建成一个节点，节点数
// Θ(K·k·h)（K 条线 × k 趟车 × h 段），K=50,k=1000,h=1000 时是 5·10⁷ 个节点。
// 正确做法：每条线路只存「发车时刻数组 t[0..k)」（全线路共享）+ 每段的
// 累计行驶时间 S_x。查询「在 p_x 时刻 τ 能上哪班车」= 在 t 里找
//   t_j + S_x ≥ τ  ⟺  t_j ≥ τ − S_x  ⟺  lower_bound(t, τ − S_x)
// Θ(log k)，空间 Θ(K(h+k))。
//
// **连续乘坐免费**：把线路拆成相邻站点边、并把累计行驶时间 S_x 编码进班次
// 时刻后，「坐过站」的代价自动为 0——因为在 p_{x+1} 时刻，该班车在 p_{x+1}
// 的「发车时刻」就是 t_j + S_{x+1}，恰好等于我们的到达时刻 ⟹ lower_bound
// 正好命中它 ⟹ 候车时间 = 0。换乘则自然付出真实等待。

struct BusLine {
    // 站点下标按行驶顺序；stations.size() = h
    std::vector<int> stations;
    // segPref[x] = 从 stations[0] 累计行驶到 stations[x] 的时间（segPref[0] = 0）
    std::vector<long long> segPref;
    std::vector<long long> departures;      // 起点站的发车时刻（严格递增）
    std::size_t segCount() const { return stations.size() - 1; }
};

// 从 p_x（seg 段的起点）出发、当前时刻 tau，最早到达 p_{x+1} 的时刻。
// 返回 INF_TIME 表示这趟车已经全发完了。
long long arrive_next(const BusLine& ln, std::size_t seg, long long tau) {
    const long long Sx = ln.segPref[seg];
    // 需要 t_j ≥ tau − Sx
    const auto it = std::lower_bound(ln.departures.begin(), ln.departures.end(), tau - Sx);
    if (it == ln.departures.end()) { return INF64; }
    return *it + ln.segPref[seg + 1];          // 到达 p_{x+1} 的绝对时刻
}

struct TimetableNet {
    int n = 0;                                        // 地点数
    std::vector<std::vector<std::pair<int, int>>> walk;  // (to, 分钟)
    std::vector<std::vector<std::pair<int, std::size_t>>> segOf;  // (to, 线路下标)
    std::vector<BusLine> lines;
    // segEdge[u] = 该点出发的「乘车段」列表（seg 起点在 u）
    std::vector<std::vector<std::pair<int, std::pair<std::size_t, std::size_t>>>> outSeg;
};

static TimetableNet build_net() {
    TimetableNet net;
    net.n = 6;                                   // 0..5
    net.walk.assign(6, {});
    net.segOf.assign(6, {});
    net.outSeg.assign(6, {});
    // L1: 0 → 1 → 2 → 3，段耗时 5, 7, 3；发车时刻 0, 20, 40, 60, 80
    {
        BusLine l;
        l.stations = {0, 1, 2, 3};
        l.segPref = {0, 5, 12, 15};
        l.departures = {0, 20, 40, 60, 80};
        net.lines.push_back(l);
    }
    // L2: 1 → 4 → 5，段耗时 6, 9；发车时刻 0, 30, 60
    {
        BusLine l;
        l.stations = {1, 4, 5};
        l.segPref = {0, 6, 15};
        l.departures = {0, 30, 60};
        net.lines.push_back(l);
    }
    // 步行边（双向）
    net.walk[0] = {{1, 12}, {3, 30}};
    net.walk[1] = {{0, 12}, {2, 9}};
    net.walk[2] = {{1, 9}, {3, 14}};
    net.walk[3] = {{2, 14}, {0, 30}};
    net.walk[4] = {{5, 8}};
    net.walk[5] = {{4, 8}};
    // 登记乘车段
    for (std::size_t li = 0; li < net.lines.size(); ++li) {
        const auto& ln = net.lines[li];
        for (std::size_t x = 0; x < ln.segCount(); ++x) {
            const int u = ln.stations[x];
            const int v = ln.stations[x + 1];
            net.outSeg[static_cast<std::size_t>(u)].emplace_back(
                v, std::pair<std::size_t, std::size_t>{li, x});
        }
    }
    return net;
}

// FIFO 的 Dijkstra：d[u] 存**绝对时刻**（不是耗时），d[s] = S。
static std::vector<long long> td_dijkstra(const TimetableNet& net, int s, long long start,
                                          long long& segQueries) {
    std::vector<long long> d(static_cast<std::size_t>(net.n), INF64);
    d[static_cast<std::size_t>(s)] = start;
    using Q = std::pair<long long, int>;
    std::priority_queue<Q, std::vector<Q>, std::greater<Q>> pq;
    pq.push({start, s});
    segQueries = 0;
    while (!pq.empty()) {
        const auto [du, u] = pq.top();
        pq.pop();
        if (du > d[static_cast<std::size_t>(u)]) { continue; }   // lazy 删除
        // 步行边：常数边权
        for (auto [v, w] : net.walk[static_cast<std::size_t>(u)]) {
            if (du + w < d[static_cast<std::size_t>(v)]) {
                d[static_cast<std::size_t>(v)] = du + w;
                pq.push({d[static_cast<std::size_t>(v)], v});
            }
        }
        // 乘车段：边权是出发时间的函数 f(du)
        for (auto [v, ref] : net.outSeg[static_cast<std::size_t>(u)]) {
            const long long arr = arrive_next(net.lines[ref.first], ref.second, du);
            ++segQueries;
            if (arr < d[static_cast<std::size_t>(v)]) {
                d[static_cast<std::size_t>(v)] = arr;
                pq.push({arr, v});
            }
        }
    }
    return d;
}

static void timetable_demo() {
    const TimetableNet net = build_net();
    const long long S = 4;                     // 出发时刻（故意选非班次时刻，考察候车）
    long long segQueries = 0;
    const std::vector<long long> d = td_dijkstra(net, 0, S, segQueries);

    println("=== 25.5 时间依赖最短路：时刻表、候车与 FIFO 性质 ===");
    println("  线路（发车时刻存在**起点站**，S_x = 累计行驶时间）：");
    println("    L1: 站点 0→1→2→3，段耗时 [5,7,3]，S = [0,5,12,15]，"
            "发车时刻 [0,20,40,60,80]");
    println("    L2: 站点 1→4→5，段耗时 [6,9]，S = [0,6,15]，发车时刻 [0,30,60]");
    println("  步行边（分钟）: 0↔1=12, 0↔3=30, 1↔2=9, 2↔3=14, 4↔5=8");
    println("  从站点 0、时刻 S = {} 出发，各点最早到达时刻（耗时 = 时刻 − S）：", S);
    for (int v = 0; v < net.n; ++v) {
        const long long t = d[static_cast<std::size_t>(v)];
        if (t == INF64) {
            println("    站点 {}: 不可达", v);
        } else {
            println("    站点 {}: 时刻 {}（耗时 {}）", v, t, t - S);
        }
    }
    // 逐点核算（S = 4 赶不上 L1 的 0 点那趟，公交全部改乘 20 点那趟）：
    //   d[1] = 4 + 12 = 16   步行；公交要到 20+5 = 25，更晚
    //   d[2] = 4 + 12 + 9 = 25  步行 0→1→2；公交 20+12 = 32，更晚
    //   d[3] = 4 + 30 = 34   步行直达 0→3；公交 20+15 = 35、步行 0→1→2→3 = 39，都更晚
    //   d[4] = 30 + 6 = 36    L2 的 0 点那趟在站 1 时刻 0 发出，但站 0→站 1 步行
    //                        要到 16 才到站 1，赶不上 ⟹ 改乘 30 点那趟
    //   d[5] = 36 + 8 = 44    步行 4→5；L2 第二段要 30+15 = 45，更晚
    assert(d[0] == S);
    assert(d[1] == 16);
    assert(d[2] == 25);
    assert(d[3] == 34);
    assert(d[4] == 36);
    assert(d[5] == 44);
    println("  班次查询次数 = {}（每条乘车段被松弛一次 ⟹ Θ(M_edges)，"
            "每次 lower_bound Θ(log k)）", segQueries);

    // 「连续乘坐候车时间为 0」的验证：L1 第 0 趟 0 出发，5 到站 1，12 到站 2。
    // 若人在时刻 5 位于站点 1，arrive_next 应当正好命中同一班车（等待 0）。
    const long long arr1 = arrive_next(net.lines[0], 0, 0);
    const long long arr2 = arrive_next(net.lines[0], 1, arr1);
    println("  连续乘坐验证：时刻 0 上 L1 → 站 1 时刻 {} → 站 2 时刻 {}（两段衔接处候车 = {}）",
            arr1, arr2, arr2 - arr1 - (net.lines[0].segPref[2] - net.lines[0].segPref[1]));
    assert(arr1 == 5 && arr2 == 12);
    assert(arr2 - arr1 == net.lines[0].segPref[2] - net.lines[0].segPref[1]);   // 纯行驶时间

    // 候车成本的验证：在站 1 时刻 6（错过了 0 点那趟）⟹ 等 20 点那趟
    const long long late = arrive_next(net.lines[0], 1, 6);
    println("  候车验证：时刻 6 才到站 1（L1 第 2 段）⟹ 最早到站 2 时刻 {}（改乘 20 点那趟，"
            "等 {} 分）", late, (net.lines[0].departures[1] + net.lines[0].segPref[1]) - 6);
    assert(late == 32);

    // 规模对账：本例 K={} 条线，班次总数 = {}，总段数 = {}
    long long runs = 0, segs = 0, perSegRuns = 0;
    for (const auto& ln : net.lines) {
        runs += static_cast<long long>(ln.departures.size());
        segs += static_cast<long long>(ln.segCount());
        perSegRuns += static_cast<long long>(ln.departures.size())
                    * static_cast<long long>(ln.segCount());
    }
    println("  规模对账：本例 K={} 条线，班次总数 = {}，总段数 = {}", net.lines.size(), runs, segs);
    println("    朴素展开：每趟车 × 每段建一个带时刻的节点 = {} 个节点（= Σ 班次 × 段数）",
            perSegRuns);
    println("    时刻表表示：每线只存 h 个 S_x + 全线共享的 k 个发车时刻 = {} 个数", segs + runs);
    println("    按题面规模 K=50, k=1000, h=1000：朴素 = 5.0×10⁷ 节点，"
            "时刻表 = 1.0×10⁵ 个数（差 500 倍）");
    // L1: 5 趟 × 3 段 = 15；L2: 3 趟 × 2 段 = 6 ⟹ 朴素 21 个节点
    assert(perSegRuns == 21);
    assert(segs + runs == 13);   // 5 个 S + 5 个发车时刻 + 3 个 S + 3 个发车时刻
}

// 没有 FIFO 时 Dijkstra 失效的最小反例。
// 边 s→t 有两条通道：慢船 10 小时直达；快船要「先到 p 站等 1 小时才能坐」。
// 早到 s 的人（时刻 0）只能坐慢船 ⟹ 到达 10；晚到 s 的人（时刻 5）坐快船 ⟹ 到达 6。
// f(0) = 10 > f(5) = 6，f **不是**单调不减 ⟹ FIFO 破坏。
static void non_fifo_counterexample() {
    // 用一个 3 点图手算：s(0) --通道A--> t(2)；s --通道B--> t
    // 通道 A：任何时刻出发，10 小时后到（f_A(t) = t + 10）
    // 通道 B：只在 t ≥ 5 时可用，1 小时后到（f_B(t) = t + 1 for t ≥ 5, else ∞）
    // FIFO 要求 f_A(0) = 10 ≤ f_B(0) = ∞ ？不成立的可比性要用 f 本身。
    // 取 f(0) = min(10, ∞) = 10，f(5) = min(15, 6) = 6 ⟹ f(5) < f(0)，单调性破坏。
    const auto f = [](long long t) {
        const long long a = t + 10;                       // 慢船：随时可走
        const long long b = (t >= 5) ? t + 1 : INF64;    // 快船：5 时刻才开
        return std::min(a, b);
    };
    const long long f0 = f(0);
    const long long f5 = f(5);
    println("  非 FIFO 反例：慢船 f_A(t) = t + 10；快船 f_B(t) = t + 1（仅 t ≥ 5 可用）");
    println("    f(0) = {}（只能坐慢船），f(5) = {}（能坐快船）⟹ f(5) < f(0)，单调不减性破坏",
            f0, f5);
    println("    「早到从不更差」失效 ⟹ Dijkstra 的贪心定型承诺不成立，"
            "先定型的点会被后到的路径反超");
    assert(f0 == 10 && f5 == 6 && f5 < f0);
}

int main() {
    bellman_ford_demo();
    dijkstra_demo();
    negative_cycle_demo();
    timetable_demo();
    non_fifo_counterexample();
    println("自检通过");
    return 0;
}
