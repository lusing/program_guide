// 37 数学背景速览与全书收束（CLRS 附录 A–D + 全书总账）。结构：
// 37.1 求和公式机器验证（算术/几何/调和/平方和）/ 37.2 计数与鸽笼 /
// 37.3 概率的频率验证 / 37.4 矩阵恒等式 / 37.5 全书复杂度总表与
// 验证统计。
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
#include <random>
#include <vector>

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

// ═══ 37.1 求和（附录 A）═══
static void summations() {
    const int n = 1000;
    long long s1 = 0, s2 = 0;
    for (int k = 1; k <= n; ++k) { s1 += k; s2 += static_cast<long long>(k) * k; }
    println("求和公式（n={}，机器验证）：", n);
    println("  Σk = {} = n(n+1)/2 = {}", s1, static_cast<long long>(n) * (n + 1) / 2);
    assert(s1 == static_cast<long long>(n) * (n + 1) / 2);
    println("  Σk² = {} = n(n+1)(2n+1)/6 = {}", s2,
            static_cast<long long>(n) * (n + 1) * (2 * n + 1) / 6);
    assert(s2 == static_cast<long long>(n) * (n + 1) * (2 * n + 1) / 6);
    long long geo = 0;
    for (int k = 0; k <= 10; ++k) { geo += 1LL << k; }
    println("  Σ2^k (k=0..10) = {} = 2^11−1 = {}", geo, (1LL << 11) - 1);
    assert(geo == (1LL << 11) - 1);
    // 调和级数：H_10000 与 ln 10000 的差 → 欧拉常数 0.5772（第 3 章同款）
    double h = 0.0;
    for (int k = 1; k <= 10000; ++k) { h += 1.0 / k; }
    println("  H_10000 = {:.6f}（ln 10000 + γ = 9.2103 + 0.5772 = 9.7875）", h);
    assert(h > 9.78 && h < 9.80);
}

// ═══ 37.2 计数与鸽笼（附录 C.2? B）═══
static void counting() {
    // 排列组合的小验算：C(10,3) = 120
    long long c = 1;
    for (int i = 0; i < 3; ++i) { c = c * (10 - i) / (i + 1); }
    println("计数：C(10,3) = {}（10·9·8/3!）", c);
    assert(c == 120);
    // 鸽笼：13 人中必有两人同月生日
    println("鸽笼：13 人 → 必有同月生日（12 个「鸽笼」）；"
            "决策树下界 n! 个叶需高度 ⌈lg n!⌉（第 8 章）同源");
}

// ═══ 37.3 概率频率验证（附录 C）═══
static void probability() {
    // 双骰和为 7 的概率 6/36 = 1/6；固定种子模拟
    std::mt19937 rng{5489};
    const int trials = 120000;
    long long hits = 0;
    for (int i = 0; i < trials; ++i) {
        const int a = static_cast<int>(rand_below(rng, 6)) + 1;
        const int b = static_cast<int>(rand_below(rng, 6)) + 1;
        if (a + b == 7) { ++hits; }
    }
    println("概率：双骰和=7 的频率 = {:.6f}（理论 6/36 = 0.166667）",
            static_cast<double>(hits) / trials);
    assert(std::abs(static_cast<double>(hits) / trials - 1.0 / 6.0) < 0.005);
}

// ═══ 37.4 矩阵恒等式（附录 D）═══
static void matrices() {
    const std::array<std::array<long long, 2>, 2> A{{{1, 2}, {3, 4}}};
    // (AB)^T = B^T A^T 的数值验证（用 A 和它的转置）
    using M = std::array<std::array<long long, 2>, 2>;
    auto mul = [](const M& x, const M& y) -> M {
        return {{{x[0][0]*y[0][0] + x[0][1]*y[1][0], x[0][0]*y[0][1] + x[0][1]*y[1][1]},
                 {x[1][0]*y[0][0] + x[1][1]*y[1][0], x[1][0]*y[0][1] + x[1][1]*y[1][1]}}};
    };
    auto transpose = [](const M& x) -> M {
        return {{{x[0][0], x[1][0]}, {x[0][1], x[1][1]}}};
    };
    const M B{{{5, 6}, {7, 8}}};
    const M lhs = transpose(mul(A, B));
    const M rhs = mul(transpose(B), transpose(A));
    bool eq = true;
    for (int i = 0; i < 2; ++i) {
        for (int j = 0; j < 2; ++j) { if (lhs[i][j] != rhs[i][j]) { eq = false; } }
    }
    println("矩阵：(AB)^T = B^T·A^T 数值验证 = {}（附录 D 的恒等式抽样）", eq ? 1 : 0);
    assert(eq);
}

// ═══ 37.5 全书复杂度总表（静态印刷——收束章的「地图」）═══
static void complexity_map() {
    println("全书复杂度总表（37 章 → CLRS 35 章 + 附录，精选）：");
    println("  02 插入排序 Θ(n²) / 归并排序 Θ(n lg n)          06 堆排序 Θ(n lg n)");
    println("  07 快速排序 期望 Θ(n lg n)（最坏 Θ(n²)）        08 计数/基数 Θ(n+k)/Θ(d(n+r))");
    println("  09 选择 期望/确定性 Θ(n)                        11 散列 期望 Θ(1)");
    println("  13 红黑树 最坏 Θ(lg n)                          17 Huffman O(n lg n)");
    println("  18 摊还分析（vector/计数器 O(1) 摊还）           19 B 树 Θ(log_t n)");
    println("  20 斐波那契堆 摊还 O(1) 降键                     21 vEB O(lg lg u)");
    println("  22 并查集 摊还 O(α(n))                          24 MST O(E lg V)");
    println("  25 Dijkstra O((V+E) lg V) / BF O(VE)            26 Floyd-Warshall Θ(V³)");
    println("  27 最大流 EK O(VE²) / 推送重贴 O(V³)            28 并行 T_p ≤ T1/P + T∞");
    println("  29 LUP Θ(n³) 一次 + Θ(n²) 求解                  30 单纯形 指数最坏/实践快");
    println("  31 FFT Θ(n lg n)                                32 Miller-Rabin k 轮 4^-k");
    println("  33 KMP Θ(n+m)                                   34 凸包 O(n lg n) / 最近对 O(n lg n)");
    println("  35 NPC：归约链的传播                            36 近似：VC 2 / TSP 2 / SC ln n");
}

int main() {
    summations();
    counting();
    probability();
    matrices();
    complexity_map();
    println("自检通过");
    return 0;
}
