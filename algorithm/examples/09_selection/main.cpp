// 09 中位数与顺序统计量（CLRS 第 9 章）。结构：09.1 同时取最小最大
//（成对处理 3⌈n/2⌉−2）/ 09.2 RANDOMIZED-SELECT 期望线性 /
// 09.3 BFPRT（中位数的中位数）确定性线性 + 分组可视化 + 期望的经验验证 /
// 09.4 找坏蛋：天平上的修剪与搜索（书式二分 vs 三分最优）。
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

// ═══ 09.4 找坏蛋：天平上的修剪与搜索 ═══
// n 颗蛋中恰有一颗坏蛋（较轻），天平只能比较两盘等数蛋，结果三态：
// 左盘轻（坏蛋在左）/ 右盘轻 / 平衡（坏蛋在未上秤的余组）。
enum class PanTilt { LeftLight, RightLight, Balanced };
struct EggHunt { int weighings; int found; };

// 一次称量的模拟：候选段 [offset, offset+s)，两盘各取 a 颗（左盘
// [0,a)、右盘 [a,2a)），目标坏蛋绝对编号 target。
static PanTilt egg_weigh(int offset, int s, int a, int target) {
    (void)s;
    if (target < offset + a) { return PanTilt::LeftLight; }
    if (target < offset + 2 * a) { return PanTilt::RightLight; }
    return PanTilt::Balanced;
}

// 书式策略（迭代版）：每轮对半，a = ⌊s/2⌋；奇数时余组恰 1 颗——平衡即
// 坏蛋。最坏称量数满足 W(1)=0、W(s)=1+W(⌊s/2⌋) = ⌊log₂ s⌋。
static EggHunt find_bad_half(int n, int target, bool trace) {
    int lo = 0, s = n, w = 0;
    while (s > 1) {
        const int a = s / 2;
        const PanTilt r = egg_weigh(lo, s, a, target);
        if (trace) {
            static const char* tn[] = {"左盘轻", "右盘轻", "平衡"};
            println("  第 {} 次：候选 {} 颗，称 {} vs {}（余 {}）→ {}",
                    w + 1, s, a, a, s - 2 * a, tn[static_cast<int>(r)]);
        }
        ++w;
        if (r == PanTilt::LeftLight) { /* lo 不变 */ }
        else if (r == PanTilt::RightLight) { lo += a; }
        else { lo += 2 * a; }
        s = (r == PanTilt::Balanced) ? (s - 2 * a) : a;
    }
    return {w, lo};
}

// 三分策略（独立递归实现）：两盘各 a = ⌈s/3⌉ = (s+1)/3 颗，余组 b=s−2a。
// 三态各把候选缩到约 1/3；最坏 W(1)=0、W(s)=1+W(⌈s/3⌉) = ⌈log₃ s⌉，
// 达到「三态天平 k 次至多区分 3ᵏ 颗」的信息论下界。
static EggHunt find_bad_third(int s, int offset, int target) {
    if (s == 1) { return {0, offset}; }
    const int a = (s + 1) / 3;
    const PanTilt r = egg_weigh(offset, s, a, target);
    EggHunt sub;
    if (r == PanTilt::LeftLight) {
        sub = find_bad_third(a, offset, target);
    } else if (r == PanTilt::RightLight) {
        sub = find_bad_third(a, offset + a, target);
    } else {
        sub = find_bad_third(s - 2 * a, offset + 2 * a, target);
    }
    return {1 + sub.weighings, sub.found};
}

static int ceil_log3(long long n) {
    int k = 0;
    long long p = 1;                    // 3^k
    while (p < n) { p *= 3; ++k; }
    return k;
}

static void bad_egg_demo() {
    println("=== 09.4 找坏蛋：天平上的修剪与搜索 ===");
    // 固定例 n=10，打印书式二分称量轨迹（坏蛋固定在第 8 号，0 基 7）
    println("  n=10，坏蛋在第 8 颗（1 基）——对半策略称量过程：");
    const EggHunt h10 = find_bad_half(10, 7, true);
    const EggHunt t10 = find_bad_third(10, 0, 7);
    println("  对半：{} 次称出第 {} 颗；三分：{} 次", h10.weighings,
            h10.found + 1, t10.weighings);
    assert(h10.found == 7 && t10.found == 7);

    // 全量对账：n=1..80，坏蛋遍历每个位置；两策略都必须找对
    int checked = 0;
    for (int n = 1; n <= 80; ++n) {
        int worst_h = 0, worst_t = 0;
        for (int target = 0; target < n; ++target) {
            const EggHunt h = find_bad_half(n, target, false);
            const EggHunt t = find_bad_third(n, 0, target);
            assert(h.found == target && t.found == target);
            // 实际称量数不超过最坏情况闭式：⌊log₂ n⌋ 与 ⌈log₃ n⌉
            // （坏蛋恰在余组时当轮即可锁定，用次数会少于最坏值）
            int lb2 = 0; { int p = 1; while (p * 2 <= n) { p *= 2; ++lb2; } }
            assert(h.weighings <= lb2 && t.weighings <= ceil_log3(n));
            worst_h = std::max(worst_h, h.weighings);
            worst_t = std::max(worst_t, t.weighings);
            ++checked;
        }
        // 最坏位置上的计数必须恰好顶到闭式（公式是紧的）
        int lb2 = 0; { int p = 1; while (p * 2 <= n) { p *= 2; ++lb2; } }
        assert(worst_h == lb2 && worst_t == ceil_log3(n));
    }
    println("  全量核对 n≤80、坏蛋遍历全部位置（共 {} 例）：两策略全部找对；"
            "最坏计数恰为闭式", checked);

    // 最坏称量数对照表 n=3..20（具体目标可能更少）
    print("  n:            ");
    for (int n = 3; n <= 20; ++n) { print("{:4}", n); }
    println("");
    print("  对半 ⌊log₂n⌋: ");
    for (int n = 3; n <= 20; ++n) {
        int lb2 = 0; { int p = 1; while (p * 2 <= n) { p *= 2; ++lb2; } }
        print("{:4}", lb2);
    }
    println("");
    print("  三分 ⌈log₃n⌉: ");
    for (int n = 3; n <= 20; ++n) { print("{:4}", ceil_log3(n)); }
    println("");

    // 大例：n=10¹⁸——只维护候选区间大小与偏移，无需真造蛋
    const long long big_n = 1000000000000000000LL;
    const long long target = 123456789012345678LL;
    // 大 n 下对半策略递归口径相同，直接按闭式报数
    int lb2 = 0; { long long p = 1; while (p <= big_n / 2) { p *= 2; ++lb2; } }
    println("  大例 n=10¹⁸：对半最坏 {} 次，三分最坏 {} 次（⌈log₃ 10¹⁸⌉）",
            lb2, ceil_log3(big_n));
    // 用小步模拟验证三分在大 n 上的可执行性（区间计数版）
    long long s = big_n, lo = 0, w = 0;
    while (s > 1) {
        const long long a = (s + 1) / 3;
        ++w;
        if (target < lo + a) { s = a; }
        else if (target < lo + 2 * a) { lo += a; s = a; }
        else { lo += 2 * a; s -= 2 * a; }
    }
    println("  三分区间模拟：{} 次称出，坏蛋位置与设定一致 = {}", w, lo == target);
    assert(lo == target && w == ceil_log3(big_n));
}

int main() {
    minmax_demo();
    randomized_select_demo();
    bfprt_demo();
    bad_egg_demo();
    println("自检通过");
    return 0;
}
