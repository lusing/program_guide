// 09 中位数与顺序统计量（CLRS 第 9 章）。结构：09.1 同时取最小最大
//（成对处理 3⌈n/2⌉−2）/ 09.2 RANDOMIZED-SELECT 期望线性 /
// 09.3 BFPRT（中位数的中位数）确定性线性 + 分组可视化 + 期望的经验验证。
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
#include <cassert>
#include <cstdint>
#include <random>
#include <span>
#include <vector>

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

// ═══ 09.1 同时取最小与最大：成对处理 ═══
// 朴素：每个元素与 min、max 各比一次 → 2(n−1) 次。
// 成对：两两先互比（小者只挑战 min、大者只挑战 max）→ 每两元素 3 次，
// 总计 3⌈n/2⌉ − 2。
struct MinMax { int mn, mx; long long compares; };

static MinMax minmax_naive(std::span<const int> a) {
    int mn = a[0], mx = a[0];
    long long c = 0;
    for (std::size_t i = 1; i < a.size(); ++i) {
        if (++c, a[i] < mn) { mn = a[i]; }
        if (++c, a[i] > mx) { mx = a[i]; }
    }
    return {mn, mx, c};
}

static MinMax minmax_pairs(std::span<const int> a) {
    int mn = a[0], mx = a[0];
    long long c = 0;
    std::size_t i = 1;
    if (a.size() % 2 == 0) {          // 偶数个：先收编 a[1]，再从 2 起配对
        if (++c, a[1] < mn) { mn = a[1]; }
        if (++c, a[1] > mx) { mx = a[1]; }
        i = 2;
    }
    for (; i + 1 < a.size(); i += 2) {
        if (++c, a[i] < a[i + 1]) {   // 元素对内互比 1 次：小者挑战 min，大者挑战 max
            if (++c, a[i] < mn)     { mn = a[i]; }
            if (++c, a[i + 1] > mx) { mx = a[i + 1]; }
        } else {
            if (++c, a[i + 1] < mn) { mn = a[i + 1]; }
            if (++c, a[i] > mx)     { mx = a[i]; }
        }
    }
    return {mn, mx, c};
}

static void minmax_demo() {
    std::mt19937 rng{5489};
    const int n = 101; // 奇数个：公式 3⌈n/2⌉−2 = 151
    std::vector<int> v(n);
    for (int i = 0; i < n; ++i) { v[static_cast<std::size_t>(i)] = static_cast<int>(rand_below(rng, 1000)); }
    const MinMax r1 = minmax_naive(v);
    const MinMax r2 = minmax_pairs(v);
    assert(r1.mn == r2.mn && r1.mx == r2.mx);
    assert(r1.mn == *std::ranges::min_element(v) && r1.mx == *std::ranges::max_element(v));
    // 精确值：奇数 n → 3(n−1)/2；偶数 n → 3n/2 − 2（CLRS 9.1 的界 3⌊n/2⌋）
    const long long exactPairs = (n % 2 == 0) ? 3LL * n / 2 - 2 : 3LL * (n - 1) / 2;
    println("n={}：朴素 2(n-1) = {} 次比较；成对精确值 {}（实测 {}，界 3⌊n/2⌋ = {}）",
            n, 2 * (n - 1), exactPairs, r2.compares, 3 * (n / 2));
    assert(r2.compares == exactPairs);
    assert(r1.compares == 2 * (n - 1));
}

// ═══ 09.2 选择问题的公共分区（把 a[pIdx] 换到末尾做 Lomuto）═══
static std::size_t partition_at(std::span<int> a, std::size_t pIdx, long long& c) {
    std::swap(a[pIdx], a[a.size() - 1]);
    const int pivot = a[a.size() - 1];
    std::size_t k = 0;
    for (std::size_t j = 0; j + 1 < a.size(); ++j) {
        if (++c, a[j] <= pivot) { std::swap(a[k], a[j]); ++k; }
    }
    std::swap(a[k], a[a.size() - 1]);
    return k;
}

// RANDOMIZED-SELECT（CLRS p.216，0 基版）：分区后只递归一侧。
// 期望 ≤ 4n 次比较（定理 9.2 的系），最坏 Θ(n²)。
static int randomized_select(std::span<int> a, std::size_t i, std::mt19937& rng, long long& c) {
    if (a.size() == 1) { return a[0]; }
    const std::size_t q = partition_at(a, rand_below(rng, static_cast<std::uint32_t>(a.size())), c);
    if (i == q) { return a[q]; }
    if (i < q)  { return randomized_select(a.first(q), i, rng, c); }
    return randomized_select(a.subspan(q + 1), i - q - 1, rng, c);
}

static void randomized_select_demo() {
    const int n = 1001;
    std::mt19937 rng{5489};
    std::vector<int> base(n);
    for (int k = 0; k < n; ++k) { base[static_cast<std::size_t>(k)] = k; }
    for (int k = n - 1; k > 0; --k) {
        std::swap(base[static_cast<std::size_t>(k)],
                  base[static_cast<std::size_t>(rand_below(rng, static_cast<std::uint32_t>(k) + 1))]);
    }
    auto sorted = base;
    std::ranges::sort(sorted);

    auto v = base;
    long long c = 0;
    const int med = randomized_select(v, 500, rng, c);
    assert(med == sorted[500]);
    println("RANDOMIZED-SELECT n={} 找第 500 小 = {}（与排序后对账一致），比较 {} 次（期望 ≤ 4n = {}）",
            n, med, c, 4 * n);

    // 期望的经验验证：100 个固定种子的排列，各自找中位数
    long long total = 0, best = 1LL << 62, worstC = 0;
    for (int t = 0; t < 100; ++t) {
        std::mt19937 r{static_cast<std::uint32_t>(5489 + t)};
        auto w = base;
        for (int k = static_cast<int>(w.size()) - 1; k > 0; --k) {
            std::swap(w[static_cast<std::size_t>(k)],
                      w[static_cast<std::size_t>(rand_below(r, static_cast<std::uint32_t>(k) + 1))]);
        }
        long long cc = 0;
        const int m = randomized_select(w, static_cast<std::size_t>(n / 2), r, cc);
        assert(m == sorted[n / 2]);
        total += cc;
        best = std::min(best, cc);
        worstC = std::max(worstC, cc);
    }
    println("期望验证：100 个固定种子找中位数：平均比较 {}（~2n = {}），最少 {} / 最多 {}",
            total / 100, 2 * n, best, worstC);
    assert(total / 100 < 4 * n);
}

// ═══ 09.3 BFPRT：中位数的中位数（确定性线性）═══
// 1) ⌈n/5⌉ 组每组 5 个，插入排序取组内中位数 → Θ(n)
// 2) 递归取这些中位数的中位数 x → T(n/5)
// 3) 以 x 为轴分区：x 保证两侧各 ≥ 3·⌊n/10⌋ 个元素 → 递归侧 ≤ 7n/10+6
// T(n) = T(n/5) + T(7n/10+6) + Θ(n) = Θ(n)——没有随机数，没有期望。
static int median_of_group(std::span<int> g, long long& c) {
    for (std::size_t j = 1; j < g.size(); ++j) {   // 插入排序（≤10 次比较）
        const int key = g[j];
        std::size_t p = j;
        while (p > 0 && (++c, g[p - 1] > key)) { g[p] = g[p - 1]; --p; }
        g[p] = key;
    }
    return g[g.size() / 2];
}

static int bfprt(std::span<int> a, std::size_t i, long long& c) {
    if (a.size() <= 5) {
        std::ranges::sort(a);
        return a[i];
    }
    std::vector<int> meds;
    meds.reserve(a.size() / 5 + 1);
    for (std::size_t s = 0; s < a.size(); s += 5) {
        auto g = a.subspan(s, std::min<std::size_t>(5, a.size() - s));
        meds.push_back(median_of_group(g, c));
    }
    const int x = bfprt(meds, meds.size() / 2, c);
    std::size_t pIdx = 0;
    for (std::size_t k = 0; k < a.size(); ++k) {
        if (++c, a[k] == x) { pIdx = k; break; }
    }
    const std::size_t q = partition_at(a, pIdx, c);
    if (i == q) { return a[q]; }
    if (i < q)  { return bfprt(a.first(q), i, c); }
    return bfprt(a.subspan(q + 1), i - q - 1, c);
}

static void bfprt_demo() {
    // 分组可视化：15 个数，3 组各 5 个
    std::vector<int> groups{7, 2, 9, 4, 11, 3, 8, 1, 12, 6, 10, 5, 0, 13, 14};
    long long c0 = 0;
    std::vector<int> meds;
    for (std::size_t s = 0; s < groups.size(); s += 5) {
        auto g = std::span<int>{groups}.subspan(s, 5);
        meds.push_back(median_of_group(g, c0));
    }
    std::ranges::sort(meds);
    println("BFPRT 分组示例：15 个数按 5 一组，组内中位数 {}、{}、{}；中位数的中位数 = {}",
            meds[0], meds[1], meds[2], meds[1]);

    // 大数组：确定性线性 + 计数
    const int n = 10001;
    std::mt19937 rng{5489};
    std::vector<int> v(n);
    for (int k = 0; k < n; ++k) { v[static_cast<std::size_t>(k)] = static_cast<int>(rand_below(rng, 1000000)); }
    auto sorted = v;
    std::ranges::sort(sorted);
    long long c = 0;
    const int mid = bfprt(v, static_cast<std::size_t>(n / 2), c);
    assert(mid == sorted[n / 2]);
    println("BFPRT n={} 找中位数 = {}（与排序对账一致），比较 {} 次（比值 比较数/n = {:.2f}）",
            n, mid, c, static_cast<double>(c) / n);
    assert(c < 22 * n); // 理论常数级；实测通常 ~5-6n，这里给宽松上界
}

int main() {
    minmax_demo();
    randomized_select_demo();
    bfprt_demo();
    println("自检通过");
    return 0;
}
