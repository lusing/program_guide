// 08 线性时间排序（CLRS 第 8 章）。结构：08.1 决策树下界 lg(n!) /
// 08.2 计数排序（零比较 + 稳定性证明级断言）/ 08.3 基数排序（图 8.3 三趟追踪）/
// 08.4 桶排序（图 8.4 数据 + 期望线性实证）。
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
#include <random>
#include <vector>

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

struct Counters { long long compares = 0; };

// ═══ 08.1 决策树下界 ═══
// 比较排序 = 二叉决策树；n! 种排列至少要有 n! 个叶 → 树高 ≥ ⌈lg n!⌉。
// 斯特林：lg n! = n lg n − 1.4427n + Θ(lg n)。
// 归并排序的最坏比较恰为 n·⌈lg n⌉ − 2^⌈lg n⌉ + 1（n 为 2 的幂时
// n lg n − n + 1），非常贴近下界；插入排序最坏 n(n−1)/2 远高。
static void lower_bound_demo() {
    println("决策树下界 vs 各排序最坏比较：");
    for (int n : {4, 8, 16}) {
        // n! 精确算（64 位内 n≤20），⌈lg n!⌉ 用 bit_width
        unsigned long long fact = 1;
        for (int i = 2; i <= n; ++i) { fact *= static_cast<unsigned long long>(i); }
        const int lgFact = std::bit_width(fact - 1); // ⌈lg m⌉ = bit_width(m-1)
        // 归并最坏（n 为 2 的幂）：n lg n − n + 1
        const int lg = std::bit_width(static_cast<unsigned>(n)) - 1;
        const long long mergeWorst = static_cast<long long>(n) * lg - n + 1;
        const long long insertWorst = static_cast<long long>(n) * (n - 1) / 2;
        println("  n={:>2}：⌈lg n!⌉={}，归并最坏={}，插入最坏={}", n, lgFact,
                mergeWorst, insertWorst);
        assert(mergeWorst >= lgFact && insertWorst >= lgFact);
    }
    // n=8 验算：8! = 40320，lg = 15.30 → ⌈⌉ = 16；归并 17 只差 1
}

// ═══ 08.2 计数排序 ═══
// 前提：键是小整数 ∈ [0, k]。零次比较——用「数个数」绕过比较模型，
// 这就是它能突破 lg n! 下界的原因（模型换了，下界不再适用）。
// 稳定性：输出位置从 C[x] 的**倒序**分配保证。
struct Elem { int key; int id; }; // id 用于验证稳定性

static std::vector<Elem> counting_sort(const std::vector<Elem>& a, int k, long long& ops) {
    std::vector<int> c(static_cast<std::size_t>(k) + 1, 0);
    for (auto&& e : a) { ++c[static_cast<std::size_t>(e.key)]; ++ops; }
    for (std::size_t i = 1; i < c.size(); ++i) { c[i] += c[i - 1]; ++ops; }
    std::vector<Elem> out(a.size());
    for (std::size_t i = a.size(); i-- > 0;) {   // 倒序 → 稳定
        out[static_cast<std::size_t>(--c[static_cast<std::size_t>(a[i].key)])] = a[i];
        ++ops;
    }
    return out;
}

static void counting_demo() {
    // CLRS 图 8.2 的数据：A = ⟨2,5,3,0,2,3,0,3⟩，k = 5
    const std::vector<int> keys{2, 5, 3, 0, 2, 3, 0, 3};
    std::vector<Elem> a;
    for (std::size_t i = 0; i < keys.size(); ++i) {
        a.push_back({keys[i], static_cast<int>(i)});
    }
    long long ops = 0;
    const auto out = counting_sort(a, 5, ops);
    print("计数排序（图 8.2 数据）: ");
    for (auto&& e : out) { print("{} ", e.key); }
    println("");
    // 稳定性断言：同 key 的 id 顺序保持
    for (std::size_t i = 1; i < out.size(); ++i) {
        assert(!(out[i - 1].key == out[i].key && out[i - 1].id > out[i].id));
    }
    println("比较次数 = 0（比较模型之外），基本操作 {} 次；同键 id 顺序保持（稳定）", ops);
    // 键 0 的两个 id（原下标 3、6）应按原顺序出现
    assert(out[0].id == 3 && out[1].id == 6);
    // 键 2 的两个 id（原下标 0、4）同理
    assert(out[2].id == 0 && out[3].id == 4);
}

// ═══ 08.3 基数排序 ═══
// CLRS 图 8.3 数据：7 个三位数，从最低位到最高位逐位稳定排序。
static std::vector<int> radix_pass(const std::vector<int>& a, int digit) {
    const int k = 9;
    std::vector<int> c(k + 1, 0);
    for (int v : a) { ++c[static_cast<std::size_t>(v / digit % 10)]; }
    for (std::size_t i = 1; i < c.size(); ++i) { c[i] += c[i - 1]; }
    std::vector<int> out(a.size());
    for (std::size_t i = a.size(); i-- > 0;) {
        out[static_cast<std::size_t>(--c[static_cast<std::size_t>(a[i] / digit % 10)])] = a[i];
    }
    return out;
}

static void radix_demo() {
    std::vector<int> a{329, 457, 657, 839, 436, 720, 355}; // 图 8.3
    println("基数排序（图 8.3 数据，三位十进制，低位优先）：");
    print("  输入:       ");
    for (int v : a) { print("{} ", v); }
    println("");
    for (int digit : {1, 10, 100}) {
        a = radix_pass(a, digit);
        print("  按 {} 位排序: ", digit == 1 ? "个" : digit == 10 ? "十" : "百");
        for (int v : a) { print("{} ", v); }
        println("");
    }
    assert(std::ranges::is_sorted(a));
    assert((a == std::vector<int>{329, 355, 436, 457, 657, 720, 839}));
}

// ═══ 08.4 桶排序 ═══
// 输入均匀分布于 [0,1)：n 个桶，桶内插入排序。期望 O(n)。
// 图 8.4 数据：.78 .17 .39 .26 .72 .94 .21 .12 .23 .68
static void bucket_demo() {
    const std::vector<double> input{0.78, 0.17, 0.39, 0.26, 0.72,
                                    0.94, 0.21, 0.12, 0.23, 0.68};
    const std::size_t n = input.size();
    std::vector<std::vector<double>> buckets(n);
    for (double x : input) {
        buckets[static_cast<std::size_t>(x * static_cast<double>(n))].push_back(x);
    }
    println("桶排序（图 8.4 数据，n=10 个桶）：");
    for (std::size_t i = 0; i < n; ++i) {
        if (buckets[i].empty()) { continue; }
        // 桶内插入排序（CLRS 就是用插入排序）
        for (std::size_t j = 1; j < buckets[i].size(); ++j) {
            double key = buckets[i][j];
            std::size_t p = j;
            while (p > 0 && buckets[i][p - 1] > key) {
                buckets[i][p] = buckets[i][p - 1];
                --p;
            }
            buckets[i][p] = key;
        }
        print("  桶 {}: ", i);
        for (double v : buckets[i]) { print("{:.2f} ", v); }
        println("");
    }
    std::vector<double> out;
    for (auto&& b : buckets) { out.insert(out.end(), b.begin(), b.end()); }
    assert(std::ranges::is_sorted(out));
    // 期望线性的直觉：均匀输入下每桶期望 1 个元素，桶内插入是 O(1) 级
    long long totalChain = 0;
    for (auto&& b : buckets) { totalChain += static_cast<long long>(b.size()) * (static_cast<long long>(b.size()) + 1) / 2; }
    println("Σ 桶内元素对（桶大小的平方级工作量）= {}（n=10，均匀时期望 ~ 2n 量级）",
            totalChain);
}

// ═══ 08.5 模型边界：三算法比较次数总账 ═══
static void summary_demo() {
    // 固定随机大数组（键 0..99），三算法排序同一数据
    const int n = 10000;
    std::vector<int> v(n);
    std::mt19937 rng{5489};
    for (int i = 0; i < n; ++i) { v[static_cast<std::size_t>(i)] = static_cast<int>(rand_below(rng, 100)); }
    // 计数排序（k=99）
    std::vector<Elem> e;
    for (int i = 0; i < n; ++i) { e.push_back({v[static_cast<std::size_t>(i)], i}); }
    long long ops = 0;
    const auto out = counting_sort(e, 99, ops);
    // std::sort（introsort）作对照——只验证正确性，不计数
    auto v2 = v;
    std::ranges::sort(v2);
    bool same = true;
    for (std::size_t i = 0; i < v2.size(); ++i) {
        if (v2[i] != out[i].key) { same = false; }
    }
    println("n={} 键域 0..99：计数排序操作 {} 次（~2n+k），结果与 std::sort 一致 = {}",
            n, ops, same ? 1 : 0);
    assert(same);
}

int main() {
    lower_bound_demo();
    counting_demo();
    radix_demo();
    bucket_demo();
    summary_demo();
    println("自检通过");
    return 0;
}
