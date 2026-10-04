// 03 函数的增长（CLRS 第 3 章）。结构：03.1 Θ/O/Ω 定义的机器检验 /
// 03.2 常用函数恒等式（取整/对数/斐波那契/调和级数）/ 03.3 增长速度实测
//（复用第 2 章排序的比较计数）/ 03.4 溢出与时间估算表。
// 纪律：全整数运算 + 有理数除法（IEEE 确定性），不用 log/pow——
// 它们的尾数跨标准库实现可能不同。
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
#include <bit>
#include <cassert>
#include <cstdint>
#include <random>
#include <span>
#include <vector>

struct Counters { long long compares = 0; long long shifts = 0; };

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

static void insertion_sort(std::span<int> a, Counters& c) {
    for (std::size_t j = 1; j < a.size(); ++j) {
        int key = a[j];
        std::size_t i = j;
        while (i > 0 && (++c.compares, a[i - 1] > key)) {
            a[i] = a[i - 1];
            ++c.shifts;
            --i;
        }
        a[i] = key;
    }
}

static void merge_sort_impl(std::span<int> a, std::span<int> buf, Counters& c) {
    if (a.size() < 2) { return; }
    const std::size_t mid = a.size() / 2;
    merge_sort_impl(a.first(mid), buf.first(mid), c);
    merge_sort_impl(a.subspan(mid), buf.subspan(mid), c);
    std::copy(a.begin(), a.end(), buf.begin());
    std::size_t i = 0, j = mid, k = 0;
    while (i < mid && j < a.size()) {
        if (++c.compares, buf[i] <= buf[j]) { a[k++] = buf[i++]; }
        else                               { a[k++] = buf[j++]; }
    }
    while (i < mid)      { a[k++] = buf[i++]; }
    while (j < a.size()) { a[k++] = buf[j++]; }
}

static void merge_sort(std::span<int> a, Counters& c) {
    std::vector<int> buf(a.size());
    merge_sort_impl(a, buf, c);
}

// 固定种子生成 n 元素的伪随机排列（确定性「平均样本」）
static std::vector<int> random_permutation(int n) {
    std::vector<int> v(n);
    for (int i = 0; i < n; ++i) { v[i] = i; }
    std::mt19937 rng{5489};
    for (int i = n - 1; i > 0; --i) {
        std::swap(v[i], v[rand_below(rng, static_cast<std::uint32_t>(i) + 1)]);
    }
    return v;
}

// ═══ 03.1 Θ/O/Ω 定义的机器检验 ═══
// 定义（CLRS p.44-45）：
//   Θ(g) = { f : 存在正常数 c1, c2, n0，使 0 ≤ c1·g(n) ≤ f(n) ≤ c2·g(n)
//            对一切 n ≥ n0 成立 }
// 取 f(n) = n²，g(n) = 2n²+3n：验证 c1=1/4、c2=1、n0=8 使定义成立。
// 两个不等式分开验，正好对应 Θ 的「夹逼」语义。
static long long g_of(int n) { return 2LL * n * n + 3LL * n; }

static void theta_definition_check() {
    const long long c1_num = 1, c1_den = 4; // c1 = 1/4（用整数比避免浮点）
    const long long c2 = 1;
    const int n0 = 8;
    bool lower = true, upper = true;
    for (int n = n0; n <= 100000; ++n) {
        const long long f = 1LL * n * n;
        const long long g = g_of(n);
        // c1·g ≤ f  ⇔  c1_num·g ≤ c1_den·f（c1_den 为正，不等号方向不变）
        if (c1_num * g > c1_den * f) { lower = false; }
        if (f > c2 * g)              { upper = false; }
    }
    println("f=n^2 ∈ Θ(2n^2+3n)：下界 c1=1/4 成立 = {}，上界 c2=1 成立 = {}（n0={}..100000 全验）",
            lower ? 1 : 0, upper ? 1 : 0, n0);
    // 小 o 检验：n ∈ o(n²) ⇔ 对任意常数 k（=1/c），k·n ≤ n² 对一切 n ≥ k 成立
    bool littleOh = true;
    for (int k = 1; k <= 1000; ++k) {
        for (int n = k; n <= 1000; ++n) {
            if (static_cast<long long>(k) * n > static_cast<long long>(n) * n) {
                littleOh = false; // 只在 k > n 时触发——循环域内不可能
            }
        }
    }
    println("n ∈ o(n^2)（存在 c<1 使 n ≤ c·n^2 对大 n 成立）= {}", littleOh ? 1 : 0);
    assert(lower && upper && littleOh);
}

// ═══ 03.2 常用函数与恒等式 ═══
static void function_identities() {
    // 取整恒等式（CLRS p.54）：⌊n/2⌋ + ⌈n/2⌉ = n
    bool floorCeil = true;
    for (int n = 0; n <= 1000; ++n) {
        if (n / 2 + (n + 1) / 2 != n) { floorCeil = false; }
    }
    println("恒等式 ⌊n/2⌋+⌈n/2⌉ = n（n=0..1000 全验）= {}", floorCeil ? 1 : 0);

    // ⌊lg n⌋ = bit_width(n) - 1（C++20 <bit>；n ≥ 1）
    bool bw = true;
    for (long long n = 1; n <= 1000000; ++n) {
        long long lg = 0;
        long long v = n;
        while (v > 1) { v /= 2; ++lg; }
        if (lg + 1 != std::bit_width(static_cast<unsigned long long>(n))) { bw = false; }
    }
    println("恒等式 ⌊lg n⌋ = bit_width(n)-1（n=1..10^6 全验）= {}", bw ? 1 : 0);

    // 换底公式的整数版检查：lg(n) = log₂(n)；2^⌈lg n⌉ ≥ n
    bool pow2 = true;
    for (long long n = 1; n <= 100000; ++n) {
        int w = std::bit_width(static_cast<unsigned long long>(n));
        if ((1LL << w) < n) { pow2 = false; } // 2^w = 2^(⌊lg n⌋+1) ≥ n
    }
    println("恒等式 2^(⌊lg n⌋+1) ≥ n > 2^⌊lg n⌋（n=1..10^5 全验）= {}", pow2 ? 1 : 0);

    // 斐波那契（CLRS p.56）：F_0=0, F_1=1, F_n=F_{n-1}+F_{n-2}；
    // 相邻比收敛到黄金分割 φ=(1+√5)/2 ≈ 1.618（比值的 IEEE 除法是确定的）
    long long f0 = 0, f1 = 1;
    print("斐波那契前 12 项: 0 1");
    for (int i = 2; i <= 11; ++i) {
        long long f2 = f0 + f1;
        print(" {}", f2);
        f0 = f1; f1 = f2;
    }
    println("");
    println("F_30 = {}（F_45 = {} 超过 int32 上限的临界在 F_47）",
            [] { long long a = 0, b = 1; for (int i = 2; i <= 30; ++i) { long long c = a + b; a = b; b = c; } return b; }(),
            [] { long long a = 0, b = 1; for (int i = 2; i <= 45; ++i) { long long c = a + b; a = b; b = c; } return b; }());
    double ratio = 1.0;
    long long a = 0, b = 1;
    for (int i = 0; i < 40; ++i) { long long c = a + b; a = b; b = c; ratio = static_cast<double>(b) / static_cast<double>(a); }
    println("F_41/F_40 = {:.6f}（→ 黄金分割 1.618034）", ratio);

    // 调和级数（附录 A.2 与 3.2 节）：H_n = Σ 1/k ~ ln n。
    // 逐项求和顺序固定 → IEEE 双精度确定。打印 H_10 / H_100 / H_10^6。
    double h = 0.0;
    for (int k = 1; k <= 10; ++k) { h += 1.0 / k; }
    println("H_10 = {:.6f}", h);
    double h2 = 0.0;
    for (int k = 1; k <= 100; ++k) { h2 += 1.0 / k; }
    println("H_100 = {:.6f}", h2);
    double h3 = 0.0;
    for (int k = 1; k <= 1000000; ++k) { h3 += 1.0 / k; }
    println("H_1000000 = {:.6f}（~ ln 10^6 = 13.8155）", h3);
    assert(floorCeil && bw && pow2);
}

// ═══ 03.3 增长速度实测：常数藏在比值里 ═══
static void growth_experiment() {
    println("插入排序（随机排列）比较数与 c·n^2 的拟合：");
    for (int n : {100, 1000, 10000}) {
        auto v = random_permutation(n);
        Counters c{};
        insertion_sort(v, c);
        assert(std::ranges::is_sorted(v));
        const double fit = static_cast<double>(c.compares) /
                           (1.0 * n * n);
        println("  n={:>6}：比较 {:>12}，c = 比较/n^2 = {:.4f}", n, c.compares, fit);
    }
    println("归并排序（随机排列）比较数与 c·n·lg n 的拟合：");
    for (int n : {100, 1000, 10000}) {
        auto v = random_permutation(n);
        Counters c{};
        merge_sort(v, c);
        assert(std::ranges::is_sorted(v));
        const int lg = std::bit_width(static_cast<unsigned>(n)) - 1;
        const double fit = static_cast<double>(c.compares) /
                           (1.0 * n * (lg + 1)); // 用 ⌈lg n⌉=lg+1（100/1000 非 2 的幂）
        println("  n={:>6}：比较 {:>10}，c = 比较/(n·⌈lg n⌉) = {:.4f}", n, c.compares, fit);
    }
}

// ═══ 03.4 溢出与「时间估算表」 ═══
static void overflow_and_time_table() {
    // n(n-1)/2 在 n=65536 时约 2.1×10^9 —— 已超 int32（2.15×10^9 临界），
    // n=100000 时必超。用 int 会绕回负数（UB），必须 long long。
    const long long n = 100000;
    const long long safe = n * (n - 1) / 2;
    println("n=100000 的 n(n-1)/2 = {}（> INT_MAX=2147483647，必须 64 位）", safe);
    assert(safe == 4999950000LL);

    // RAM 时间估算（每秒 10^9 次操作，纯整数算术 + 确定性除法）
    println("时间估算表（10^9 次操作/秒）：");
    println("  {:>8} {:>18} {:>18} {:>18}", "n", "lg n 操作数", "n·lg n 操作数", "n^2 操作数");
    for (long long m : {1000000LL, 10000000LL, 100000000LL}) {
        const int lg = std::bit_width(static_cast<unsigned long long>(m)) - 1;
        println("  {:>8} {:>18} {:>18} {:>18}", m, lg, m * (lg + 1), m * m);
    }
    println("换算：n=10^8 时 n·lg n ≈ 2.7×10^9 步 ≈ {:.2f} 秒；n^2 = 10^16 步 ≈ {:.0f} 天",
            100000000.0 * 27 / 1e9, 1e16 / 1e9 / 86400.0);
}

int main() {
    theta_definition_check();
    function_identities();
    growth_experiment();
    overflow_and_time_table();
    println("自检通过");
    return 0;
}
