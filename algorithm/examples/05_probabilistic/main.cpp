// 05 概率分析与随机化算法（CLRS 第 5 章 + 附录 C 串联）。结构：
// 05.1 指示器随机变量（伯努利数组的期望） / 05.2 雇佣问题（期望雇佣数 = H_n）/
// 05.3 生日悖论（精确概率 + 指示器期望 + 模拟）/ 05.4 最长连续正面 /
// 05.5 RANDOMIZE-IN-PLACE 均匀性检验 vs 错误洗牌的偏倚。
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
#include <numeric>
#include <random>
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

int main() {
    indicator_demo();
    hiring_demo();
    birthday_demo();
    streaks_demo();
    shuffle_uniformity_demo();
    println("自检通过");
    return 0;
}
