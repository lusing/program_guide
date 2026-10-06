// 05 概率分析与随机化算法（CLRS 第 5 章 + 附录 C 串联）。结构：
// 05.1 指示器随机变量（伯努利数组的期望） / 05.2 雇佣问题（期望雇佣数 = H_n）/
// 05.3 生日悖论（精确概率 + 指示器期望 + 模拟）/ 05.4 最长连续正面 /
// 05.5 RANDOMIZE-IN-PLACE 均匀性检验 vs 错误洗牌的偏倚 /
// 05.6 最小割：随机收缩（Karger，多次试验取最小，最大流精确对账）。
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
#include <cmath>
#include <cstdint>
#include <limits>
#include <numeric>
#include <random>
#include <string>
#include <vector>

// 可移植随机（docs/01 纪律：mt19937 引擎可移植，分布算法不可移植）
static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    assert(n != 0);
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

// ═══ 05.1 指示器随机变量 ═══
// 引理 5.1：E[X] = Σ I{事件} 的期望 = Σ P(事件)。伯努利(p) 数组中 1 的个数
// 期望是 n·p——把「数个数」拆成 n 个 0/1 指示器再相加。
static void indicator_demo() {
    std::mt19937 rng{5489};
    const int n = 100000;
    const std::uint32_t p4 = 4; // p = 1/4：rand_below(rng,4)==0
    long long ones = 0;
    for (int i = 0; i < n; ++i) {
        if (rand_below(rng, p4) == 0) { ++ones; }
    }
    println("伯努利(1/4) 数组 n={}：1 的个数 {}（期望 n·p = {}）", n, ones, n / 4);
    // 期望的线性性 E[X+Y]=E[X]+E[Y] 不要求独立——这正是它能到处用的原因
}

// ═══ 05.2 雇佣问题 ═══
// HIRE-ASSISTANT：只录用比当前最好者更好的候选人。雇佣次数的期望：
// X = Σ_{i=1}^{n} I{第 i 人是前 i 人中最好}，P = 1/i，E[X] = Σ 1/i = H_n。
static void hiring_demo() {
    const int n = 20;
    // H_20（有理数精确值：分母最大公约数后打印小数）
    double h = 0.0;
    for (int i = 1; i <= n; ++i) { h += 1.0 / i; }
    println("雇佣问题 n={}：期望雇佣次数 H_n = {:.6f}（≈ ln n + 0.5772 = {:.6f}）",
            n, h, 2.9957 + 0.5772 /* ln 20 近似展示 */);
    // 固定种子模拟 5 次：每次生成 1..n 的随机排列（候选人资质排名）
    print("5 个固定种子的实际雇佣次数：");
    for (std::uint32_t seed = 1; seed <= 5; ++seed) {
        std::mt19937 rng{seed};
        std::vector<int> rank(n);
        std::iota(rank.begin(), rank.end(), 1);
        for (int i = n - 1; i > 0; --i) {   // 洗牌
            std::swap(rank[i], rank[rand_below(rng, static_cast<std::uint32_t>(i) + 1)]);
        }
        int hires = 0, best = 0;
        for (int i = 0; i < n; ++i) {
            if (rank[static_cast<std::size_t>(i)] > best) { best = rank[static_cast<std::size_t>(i)]; ++hires; }
        }
        print("{} ", hires);
    }
    println("（理论期望 {:.6f}）", h);
    // n=20 时最坏 20 次（严格递增资质），最好 1 次
}

// ═══ 05.3 生日悖论 ═══
// 精确概率：k 个人生日互异的概率 = Π_{i=1}^{k-1} (365−i)/365。
// 指示器期望（CLRS 用它给出直觉）：E[同生日对数] = C(k,2)/365。
static void birthday_demo() {
    // 找到最小的 k 使碰撞概率 > 1/2：P(k 人互异) = Π_{i=1}^{k-1} (365−i)/365
    double distinct = 1.0;   // P(1 人互异)
    int k = 1;
    while (k < 365) {
        const double next = distinct * (365.0 - k) / 365.0; // P(k+1 人互异)
        distinct = next;
        if (distinct <= 0.5) { break; }
        ++k;
    }
    println("生日悖论：k={} 人时碰撞概率 = {:.6f}（> 1/2 的最小 k）", k + 1, 1.0 - distinct);
    assert(k + 1 == 23);
    // 指示器期望视角：k=23 时期望同生日对数
    const double pairs = 23.0 * 22.0 / 2.0;
    println("指示器期望：k=23 时期望同生日对数 = C(23,2)/365 = 253/365 = {:.6f}",
            pairs / 365.0);
    // 模拟对账（固定种子）
    std::mt19937 rng{5489};
    const int trials = 20000;
    int hits = 0;
    for (int t = 0; t < trials; ++t) {
        std::array<bool, 365> seen{};
        bool collision = false;
        for (int i = 0; i < 23 && !collision; ++i) {
            auto b = rand_below(rng, 365);
            if (seen[b]) { collision = true; }
            seen[b] = true;
        }
        if (collision) { ++hits; }
    }
    println("模拟 20000 组 23 人生日：碰撞频率 = {:.6f}（理论 0.507297）",
            static_cast<double>(hits) / trials);
    assert(static_cast<double>(hits) / trials > 0.48 && static_cast<double>(hits) / trials < 0.53);
}

// ═══ 05.4 最长连续正面 ═══
// n 次抛硬币，最长连续正面的期望长度 ~ Θ(lg n)（CLRS 5.4.4 分析：
// ≥ k 连续正面的期望次数约 n/2^k；取 k = c·lg n 做阈值论证）。
static void streaks_demo() {
    const int experiments = 2000, flips = 100;
    std::mt19937 rng{5489};
    long long total = 0;
    int maxStreak = 0;
    for (int e = 0; e < experiments; ++e) {
        int cur = 0, best = 0;
        for (int i = 0; i < flips; ++i) {
            if (rand_below(rng, 2) == 1) { ++cur; best = std::max(best, cur); }
            else { cur = 0; }
        }
        total += best;
        maxStreak = std::max(maxStreak, best);
    }
    println("n=100 次抛硬币 × {} 组：平均最长正面 {:.4f}（~ lg 100 = 6.64），最大 {}",
            experiments, static_cast<double>(total) / experiments, maxStreak);
}

// ═══ 05.5 RANDOMIZE-IN-PLACE 的均匀性 vs 错误洗牌 ═══
// CLRS 伪代码（1 基）：for i = 1 to n: swap A[i] ↔ A[RANDOM(i, n)]
// —— 恰好产生 n! 个排列各以 1/n! 概率。
// 错误版本：swap A[i] ↔ A[RANDOM(1, n)]（每步全范围随机）——产生偏倚。
static void shuffle_uniformity_demo() {
    const int n = 3;
    const int trials = 270000;
    std::mt19937 rng{5489};

    // 正确版（CLRS 方向：i 从 0 到 n-1，j 从 i 到 n-1）
    std::vector<long long> count(6, 0); // 3! = 6 个排列
    for (int t = 0; t < trials; ++t) {
        std::array<int, 3> a{1, 2, 3};
        for (int i = 0; i < n; ++i) {
            int j = i + static_cast<int>(rand_below(rng, static_cast<std::uint32_t>(n - i)));
            std::swap(a[static_cast<std::size_t>(i)], a[static_cast<std::size_t>(j)]);
        }
        int idx = 0; // 排列 → 下标：字典序编码 012→0,021→1,102→2,120→3,201→4,210→5
        if (a[0] == 1 && a[1] == 2) { idx = 0; }
        else if (a[0] == 1 && a[1] == 3) { idx = 1; }
        else if (a[0] == 2 && a[1] == 1) { idx = 2; }
        else if (a[0] == 2 && a[1] == 3) { idx = 3; }
        else if (a[0] == 3 && a[1] == 1) { idx = 4; }
        else { idx = 5; }
        ++count[static_cast<std::size_t>(idx)];
    }
    println("RANDOMIZE-IN-PLACE × {}（n=3，期望每种 {}）：", trials, trials / 6);
    println("  六排列计数: {} {} {} {} {} {}", count[0], count[1], count[2],
            count[3], count[4], count[5]);
    // 均匀性断言：每种都在期望 ±5% 内
    for (auto c : count) {
        assert(c > trials / 6 * 95 / 100 && c < trials / 6 * 105 / 100);
    }

    // 错误洗牌（每步全范围交换）
    std::vector<long long> biased(6, 0);
    for (int t = 0; t < trials; ++t) {
        std::array<int, 3> a{1, 2, 3};
        for (int i = 0; i < n; ++i) {
            int j = static_cast<int>(rand_below(rng, static_cast<std::uint32_t>(n)));
            std::swap(a[static_cast<std::size_t>(i)], a[static_cast<std::size_t>(j)]);
        }
        int idx;
        if (a[0] == 1 && a[1] == 2) { idx = 0; }
        else if (a[0] == 1 && a[1] == 3) { idx = 1; }
        else if (a[0] == 2 && a[1] == 1) { idx = 2; }
        else if (a[0] == 2 && a[1] == 3) { idx = 3; }
        else if (a[0] == 3 && a[1] == 1) { idx = 4; }
        else { idx = 5; }
        ++biased[static_cast<std::size_t>(idx)];
    }
    println("错误洗牌（swap A[i]↔A[RANDOM(1,n)]）× {}：", trials);
    println("  六排列计数: {} {} {} {} {} {}", biased[0], biased[1], biased[2],
            biased[3], biased[4], biased[5]);
    // 偏倚断言：最大与最小计数差距显著（理论 27 条等概率 swap 路径映射到 6 排列不均）
    const auto lo = *std::ranges::min_element(biased);
    const auto hi = *std::ranges::max_element(biased);
    println("  偏倚：max={}，min={}，差 {}/{}（正确版应几乎无差）", hi, lo,
            hi - lo, trials / 6);
    assert(hi - lo > trials / 100); // 至少 1% 的显著偏倚
}

// ═══ 05.6 最小割：随机收缩（Karger 算法）═══
// 边割：删掉后使图不连通的边集；全局最小割 = 边数最少的那个。
struct KargerEdge { int u, v; };      // 多图：平行边允许重复出现

struct KCutResult {
    int size;                         // 割含有的边数
    std::vector<int> side;            // side[i]：原顶点 i 属于哪一侧（0/1）
};

// 一次试验：随机挑边、把边的两端点收缩成一个（平行边全部保留），直到只剩两个
// 超顶点；它们之间的边就是一个割。每条当前边被选中的概率相等。
static KCutResult karger_trial(const std::vector<KargerEdge>& input, int n,
                               std::mt19937& rng) {
    std::vector<KargerEdge> edges = input;
    std::vector<int> parent(n);
    std::iota(parent.begin(), parent.end(), 0);
    auto find = [&](int x) {
        while (parent[static_cast<std::size_t>(x)] != x) {
            parent[static_cast<std::size_t>(x)] =
                parent[static_cast<std::size_t>(parent[static_cast<std::size_t>(x)])];
            x = parent[static_cast<std::size_t>(x)];
        }
        return x;
    };
    int alive = n;
    while (alive > 2) {
        if (edges.empty()) { break; }   // 图本来就不连通
        const std::size_t pick = rand_below(
            rng, static_cast<std::uint32_t>(edges.size()));
        const int ru = find(edges[pick].u);
        const int rv = find(edges[pick].v);
        if (ru == rv) {                 // 自环：标准算法中直接丢弃，重抽
            edges[pick] = edges.back();
            edges.pop_back();
            continue;
        }
        parent[static_cast<std::size_t>(rv)] = ru;   // 收缩：ru 吸收 rv
        --alive;
    }
    // 统计两个超顶点之间的边（丢弃残余自环），并给原顶点标侧号
    int cut = 0;
    for (const KargerEdge& e : edges) {
        if (find(e.u) != find(e.v)) { ++cut; }
    }
    std::vector<int> side(n);
    std::vector<int> root_label(n, -1);
    int label = 0;
    for (int i = 0; i < n; ++i) {
        const int r = find(i);
        if (root_label[static_cast<std::size_t>(r)] == -1) {
            root_label[static_cast<std::size_t>(r)] = label++;
        }
        side[static_cast<std::size_t>(i)] = root_label[static_cast<std::size_t>(r)];
    }
    return {cut, std::move(side)};
}

// 全局最小割的精确值（小图对账用）：固定 s=0，最小割必把 s 与某个 t 分开，
// 故 min_{t≠0} 最大流(0,t) 就是答案。无向边按两条容量 1 的有向弧建模；平行
// 边各自计数。
struct EkArc { int to, rev, cap; };

static void ek_add(std::vector<std::vector<EkArc>>& g, int from, int to, int cap) {
    const int ri = static_cast<int>(g[static_cast<std::size_t>(to)].size());
    const int fi = static_cast<int>(g[static_cast<std::size_t>(from)].size());
    g[static_cast<std::size_t>(from)].push_back({to, ri, cap});
    g[static_cast<std::size_t>(to)].push_back({from, fi, 0});
}

static int edmonds_karp(std::vector<std::vector<EkArc>> g, int s, int t) {
    int flow = 0;
    const std::size_t n = g.size();
    for (;;) {
        std::vector<int> pv(n, -1), pe(n, -1);
        std::vector<int> queue(n);
        std::size_t head = 0, tail = 0;
        queue[tail++] = s;
        pv[static_cast<std::size_t>(s)] = s;
        while (head < tail && pv[static_cast<std::size_t>(t)] == -1) {
            const int u = queue[head++];
            for (std::size_t i = 0; i < g[static_cast<std::size_t>(u)].size(); ++i) {
                const EkArc& a = g[static_cast<std::size_t>(u)][i];
                if (a.cap > 0 && pv[static_cast<std::size_t>(a.to)] == -1) {
                    pv[static_cast<std::size_t>(a.to)] = u;
                    pe[static_cast<std::size_t>(a.to)] = static_cast<int>(i);
                    queue[tail++] = a.to;
                }
            }
        }
        if (pv[static_cast<std::size_t>(t)] == -1) { break; }
        int add = std::numeric_limits<int>::max();
        for (int v = t; v != s; v = pv[static_cast<std::size_t>(v)]) {
            add = std::min(add,
                g[static_cast<std::size_t>(pv[static_cast<std::size_t>(v)])]
                 [static_cast<std::size_t>(pe[static_cast<std::size_t>(v)])].cap);
        }
        for (int v = t; v != s; v = pv[static_cast<std::size_t>(v)]) {
            EkArc& a = g[static_cast<std::size_t>(pv[static_cast<std::size_t>(v)])]
                         [static_cast<std::size_t>(pe[static_cast<std::size_t>(v)])];
            a.cap -= add;
            g[static_cast<std::size_t>(v)][static_cast<std::size_t>(a.rev)].cap += add;
        }
        flow += add;
    }
    return flow;
}

static int exact_global_cut(const std::vector<KargerEdge>& edges, int n) {
    int best = std::numeric_limits<int>::max();
    for (int t = 1; t < n; ++t) {
        std::vector<std::vector<EkArc>> g(static_cast<std::size_t>(n));
        for (const KargerEdge& e : edges) {       // 无向边：正反两条容量 1 的弧
            ek_add(g, e.u, e.v, 1);
            ek_add(g, e.v, e.u, 1);
        }
        best = std::min(best, edmonds_karp(std::move(g), 0, t));
    }
    return best;
}

static void karger_demo() {
    println("=== 05.6 最小割：随机收缩（多次试验取最小）===");
    // 固定例：两个 4 顶点团用恰好 2 条边相连，最小割 = 2
    std::vector<KargerEdge> fixed;
    static const int left4[4]{0, 1, 2, 3};
    static const int right4[4]{4, 5, 6, 7};
    for (int i = 0; i < 4; ++i) {
        for (int j = i + 1; j < 4; ++j) {
            fixed.push_back({left4[i], left4[j]});
            fixed.push_back({right4[i], right4[j]});
        }
    }
    fixed.push_back({3, 4});
    fixed.push_back({1, 5});
    const int fixed_exact = exact_global_cut(fixed, 8);
    std::mt19937 rng{5489};
    int fixed_best = std::numeric_limits<int>::max();
    const int fixed_trials = 800;
    for (int i = 0; i < fixed_trials; ++i) {
        KCutResult r = karger_trial(fixed, 8, rng);
        fixed_best = std::min(fixed_best, r.size);
    }
    println("  固定例（双 K4 团 + 2 条桥接边）：{} 次试验最小割 {}，最大流精确值 {}",
            fixed_trials, fixed_best, fixed_exact);
    assert(fixed_best == fixed_exact && fixed_exact == 2);

    // 随机 600 个小图（n=4..8，按概率 p 加边，含不连通图）：每图 n² 次试验，
    // 逐图与精确值对账；同时统计「单次试验直接命中」的经验比例。
    int graph_mismatches = 0;
    long long total_trials = 0, hit_trials = 0;
    for (int gi = 0; gi < 600; ++gi) {
        const int n = 4 + static_cast<int>(rand_below(rng, 5));
        const int pct = 20 + static_cast<int>(rand_below(rng, 45));  // 边概率 20%~64%
        std::vector<KargerEdge> edges;
        for (int u = 0; u < n; ++u) {
            for (int v = u + 1; v < n; ++v) {
                if (static_cast<int>(rand_below(rng, 100)) < pct) {
                    edges.push_back({u, v});
                }
            }
        }
        const int exact = exact_global_cut(edges, n);
        const int trials = n * n;
        int best = std::numeric_limits<int>::max();
        for (int i = 0; i < trials; ++i) {
            KCutResult r = karger_trial(edges, n, rng);
            best = std::min(best, r.size);
            ++total_trials;
            hit_trials += (r.size == exact);
        }
        if (best != exact) { ++graph_mismatches; }
    }
    println("  随机 {} 个小图（n=4..8，每图 n² 次试验）：最佳值 vs 精确值不一致 {} 图",
            600, graph_mismatches);
    println("  单次试验命中率（经验）= {}/{} ≈ {:.4f}（理论下界 2/n²≈0.031~0.125）",
            hit_trials, total_trials,
            static_cast<double>(hit_trials) / static_cast<double>(total_trials));
    assert(graph_mismatches == 0);

    // 大例：n=60，两个 30 顶点完全图（半侧内部任何割都 ≥29 条边）之间只放
    // 3 条跨边，保证全局最小割恰好是植入的 3。
    const int n = 60;
    std::vector<KargerEdge> big;
    for (int u = 0; u < n; ++u) {
        for (int v = u + 1; v < n; ++v) {
            if ((u < 30) == (v < 30)) { big.push_back({u, v}); }
        }
    }
    big.push_back({10, 40});
    big.push_back({20, 50});
    big.push_back({29, 30});
    const int big_exact = exact_global_cut(big, n);
    const int big_trials = 4 * n * n;                     // 14400 次，理论失误 ≤ e⁻⁸
    int big_best = std::numeric_limits<int>::max();
    for (int i = 0; i < big_trials; ++i) {
        KCutResult r = karger_trial(big, n, rng);
        big_best = std::min(big_best, r.size);
    }
    println("  大例（n=60，m={}，植入割 3）：{} 次试验最小割 {}，精确值 {}",
            big.size(), big_trials, big_best, big_exact);
    assert(big_best == big_exact && big_exact == 3);
}

// ═══ 05.7 蒙特卡罗投点：用随机实验估算 π ═══
// 单位正方形内均匀投点，落入四分之一圆（x²+y²≤1）的比例 = 圆面积/方形
// 面积 = π/4 ⟹ π̂ = 4·命中/总数。每个点是一次独立伯努利试验。
static double rand_unit(std::mt19937& rng) {
    return std::ldexp(static_cast<double>(rng()), -32);   // [0,1)
}

static std::pair<long long, double> pi_trial(std::mt19937& rng, long long n) {
    long long hit = 0;
    for (long long i = 0; i < n; ++i) {
        const double x = rand_unit(rng), y = rand_unit(rng);
        if (x * x + y * y <= 1.0) { ++hit; }
    }
    return {hit, 4.0 * static_cast<double>(hit) / static_cast<double>(n)};
}

static void monte_carlo_pi_demo() {
    std::mt19937 rng{5489};
    println("蒙特卡罗投点估 π（单位方形内 1/4 圆）：");
    double prev_err = 0;
    const long long counts[] = {100, 10000, 1000000};
    for (long long n : counts) {
        const auto [hit, est] = pi_trial(rng, n);
        const double err = std::fabs(est - std::acos(-1.0));
        const double se = 1.6416 / std::sqrt(static_cast<double>(n)); // 理论标准误
        println("  n={:>8}：命中 {}，π̂ = {:.6f}，误差 {:.6f}（标准误 ≈ {:.6f}）",
                n, hit, est, err, se);
        if (prev_err != 0) {
            println("    点数 ×{}，误差 ÷{:.1f}（理论上 1/√n ⟹ 应 ÷10）",
                    n / (n / 100), prev_err / err);
        }
        prev_err = err;
    }
    // 独立估计的平均更准：4 个独立 25 万点估计的均值 vs 单个 25 万
    double sum = 0, single = 0;
    for (int k = 0; k < 4; ++k) {
        const auto [hit, est] = pi_trial(rng, 250000);
        sum += est;
        if (k == 0) { single = est; }
    }
    const double avg = sum / 4;
    println("  4 个独立 25 万点估计：单个 {:.6f}（误差 {:.5f}），"
            "均值 {:.6f}（误差 {:.5f}，平均的标准误减半）",
            single, std::fabs(single - std::acos(-1.0)),
            avg, std::fabs(avg - std::acos(-1.0)));
    assert(std::fabs(std::fabs(avg - std::acos(-1.0))) < 0.005);
}

// ═══ 05.8 排列的编号：Lehmer 码（阶乘进位制）═══
// n 个互异元素按字母序的排列，编号 0..n!−1。第 i 位的 Lehmer 数字 =
// 剩余元素中比当前元素小的个数；编号 = Σ cᵢ·(n−1−i)!。
static std::vector<long long> factorial_table(int n) {
    std::vector<long long> f(static_cast<std::size_t>(n) + 1);
    f[0] = 1;
    for (int k = 1; k <= n; ++k) { f[k] = f[k - 1] * k; }
    return f;
}

static long long perm_rank(const std::string& p) {
    const int n = static_cast<int>(p.size());
    const auto fact = factorial_table(n);
    long long rank = 0;
    for (int i = 0; i < n; ++i) {
        int smaller = 0;
        for (int j = i + 1; j < n; ++j) { if (p[j] < p[i]) { ++smaller; } }
        rank += static_cast<long long>(smaller) * fact[n - 1 - i];
    }
    return rank;
}

static std::string perm_unrank(long long rank, const std::string& sorted) {
    const int n = static_cast<int>(sorted.size());
    const auto fact = factorial_table(n);
    std::string avail = sorted;                 // 剩余元素（保持字母序）
    std::string out;
    out.reserve(n);
    for (int i = 0; i < n; ++i) {
        const long long f = fact[n - 1 - i];
        const auto pick = static_cast<std::size_t>(rank / f);
        rank %= f;
        out.push_back(avail[pick]);
        avail.erase(pick, 1);
    }
    return out;
}

static void lehmer_demo() {
    const std::string alpha = "abc";
    println("Lehmer 排列编号（abc 的 3!=6 个排列）：");
    for (long long k = 0; k < 6; ++k) {
        const std::string p = perm_unrank(k, alpha);
        println("  {:>2}  {}  （rank 反查 {}）", k, p, perm_rank(p));
        assert(perm_rank(p) == k);
    }

    // n≤8：全部 n! 个编号做 rank∘unrank / unrank∘rank 恒等检验
    for (int n = 1; n <= 8; ++n) {
        std::string sorted;
        for (int i = 0; i < n; ++i) { sorted.push_back(static_cast<char>('a' + i)); }
        const auto fact = factorial_table(n);
        for (long long k = 0; k < fact[n]; ++k) {
            const std::string p = perm_unrank(k, sorted);
            assert(perm_rank(p) == k);
        }
    }
    // n=9..12（12!=4.79×10⁹ 仍在 uint64 内）：2000 个随机排列对账
    std::mt19937 rng{5489};
    int bad = 0;
    for (int t = 0; t < 2000; ++t) {
        const int n = 9 + static_cast<int>(rand_below(rng, 4));
        std::string sorted;
        for (int i = 0; i < n; ++i) { sorted.push_back(static_cast<char>('a' + i)); }
        const auto fact = factorial_table(n);
        const long long k = static_cast<long long>(rand_below(
            rng, static_cast<std::uint32_t>(fact[n])));
        const std::string p = perm_unrank(k, sorted);
        if (perm_rank(p) != k) { ++bad; }
    }
    println("  n≤8 全编号 + n=9..12 随机 2000 例：恒等检验失败 {} 例", bad);
    assert(bad == 0);

    // 用「无偏随机编号」生成均匀随机排列：rand_below(n!) 拒绝法取编号
    // （直接 rng()%n! 有取模偏倚——n=4 时 2³² 不被 24 整除，各排列概率不等）。
    const int n = 4;
    const auto fact = factorial_table(n);
    std::array<long long, 24> counts{};
    for (int t = 0; t < 240000; ++t) {
        const long long k = static_cast<long long>(rand_below(
            rng, static_cast<std::uint32_t>(fact[n])));
        ++counts[static_cast<std::size_t>(k)];
    }
    long long lo = counts[0], hi = counts[0];
    for (long long c : counts) { lo = std::min(lo, c); hi = std::max(hi, c); }
    println("  无偏编号生成 n=4 排列 24 万次：最稀 {} 次、最频 {} 次"
            "（期望各 1 万，波动 <2%）", lo, hi);
    assert(hi - lo < 400);
}

int main() {
    indicator_demo();
    hiring_demo();
    birthday_demo();
    streaks_demo();
    shuffle_uniformity_demo();
    karger_demo();
    monte_carlo_pi_demo();
    lehmer_demo();
    println("自检通过");
    return 0;
}
