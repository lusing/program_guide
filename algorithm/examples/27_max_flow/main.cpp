// 27 最大流（CLRS 第 26 章）。结构：27.1 流网络与残量网络 /
// 27.2 Edmonds-Karp（BFS 增广路径逐条追踪，图 26.1 数据）/
// 27.3 流的合法性验证（容量约束 + 流量守恒）/ 27.4 最小割验证（最大流
// 最小割定理）/ 27.5 推送-重贴标签对照。
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
#include <vector>

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

int main() {
    edmonds_karp_demo();
    push_relabel_demo();
    println("自检通过");
    return 0;
}
