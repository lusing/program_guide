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
#include <queue>
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

int main() {
    fw_demo();
    closure_demo();
    vs_dijkstra_demo();
    println("自检通过");
    return 0;
}
