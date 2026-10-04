// 07 快速排序（CLRS 第 7 章）。结构：07.1 PARTITION 追踪（图 7.1）/
// 07.2 确定性最坏 vs 随机化主元 / 07.3 Hoare 分区（练习 7.1）/
// 07.4 期望比较数的经验验证（~1.39 n ln n）/ 07.5 递归深度：尾循环消除 /
// 07.6 三路分区：重复元素的救场（思考题 7-2）。
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
#include <utility>
#include <vector>

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

struct Counters { long long compares = 0; long long swaps = 0; long long maxDepth = 1; };

static void print_arr(std::string_view label, std::span<const int> a) {
    print("{}", label);
    for (auto v : a) { print("{} ", v); }
    println("");
}

// ═══ 07.1 PARTITION（CLRS p.171，0 基化：主元取末元素）═══
// 不变式（对任意 j' ∈ [0, j)）：
//   a[0..i) ≤ pivot < a[i..j') ；a[j'..n-1) 未见。终止时主元落位 i。
static std::size_t partition(std::span<int> a, Counters& c) {
    const int pivot = a[a.size() - 1];
    std::size_t i = 0;
    for (std::size_t j = 0; j + 1 < a.size(); ++j) {
        if (++c.compares, a[j] <= pivot) {
            if (i != j) { std::swap(a[i], a[j]); ++c.swaps; }
            ++i;
        }
    }
    std::swap(a[i], a[a.size() - 1]);
    ++c.swaps;
    return i;
}

static void partition_demo() {
    std::vector<int> a{2, 8, 7, 1, 3, 5, 6, 4}; // CLRS 图 7.1
    Counters c{};
    println("PARTITION 追踪（图 7.1 数组，主元 = 4）：");
    // 逐元素视角：j 扫过 2,8,7,1,3,5,6，≤4 者依次进左区
    const std::size_t q = partition(a, c);
    print_arr("  分区后: ", a);
    println("  主元 4 落位下标 q={}（图 7.1 同款：左侧 {{2,1,3}} ≤ 4，右侧 {{7,5,6,8}} ≥ 4）", q);
    assert(q == 3 && a[q] == 4);
    // PARTITION 只保证「左段 ≤ 主元 ≤ 右段」，不保证左右各自有序（左段
    // [2,1,3] 恰好无序——这是分区与排序的分界线）
    assert(*std::ranges::max_element(std::span{a}.first(q)) <= 4);
    assert(*std::ranges::min_element(std::span{a}.subspan(q + 1)) >= 4);
}

// ═══ 07.2 快排 + 随机化主元 ═══
static void quicksort_det(std::span<int> a, Counters& c, std::size_t depth = 1) {
    c.maxDepth = std::max(c.maxDepth, static_cast<long long>(depth));
    if (a.size() < 2) { return; }
    const std::size_t q = partition(a, c);
    quicksort_det(a.first(q), c, depth + 1);
    quicksort_det(a.subspan(q + 1), c, depth + 1);
}

static void randomized_quicksort(std::span<int> a, std::mt19937& rng, Counters& c,
                                 std::size_t depth = 1) {
    c.maxDepth = std::max(c.maxDepth, static_cast<long long>(depth));
    if (a.size() < 2) { return; }
    // RANDOMIZED-PARTITION：先随机选一个元素与末元素交换，再分区
    std::swap(a[a.size() - 1], a[rand_below(rng, static_cast<std::uint32_t>(a.size()))]);
    const std::size_t q = partition(a, c);
    randomized_quicksort(a.first(q), rng, c, depth + 1);
    randomized_quicksort(a.subspan(q + 1), rng, c, depth + 1);
}

static void worst_vs_random_demo() {
    const int n = 512;
    std::vector<int> sorted(n);
    for (int i = 0; i < n; ++i) { sorted[static_cast<std::size_t>(i)] = i; }
    // 确定性（末元素主元）在已序输入上：主元恒为最大 → 分区 (n-1, 0) 最坏
    auto a1 = sorted;
    Counters c1{};
    quicksort_det(a1, c1);
    assert(std::ranges::is_sorted(a1));
    const long long worst = static_cast<long long>(n) * (n - 1) / 2;
    // 随机化主元：同一输入，期望 ~1.39 n lg n
    auto a2 = sorted;
    std::mt19937 rng{5489};
    Counters c2{};
    randomized_quicksort(a2, rng, c2);
    assert(std::ranges::is_sorted(a2));
    println("已序输入 n={}：确定性(末元素主元) 比较 {}（最坏 n(n-1)/2={}，递归深度 {}）",
            n, c1.compares, worst, c1.maxDepth);
    println("已序输入 n={}：随机化主元       比较 {}（期望上界 2n·ln n = {:.0f}），递归深度 {}",
            n, c2.compares, 2.0 * n * 6.2383 /* ln 512 */, c2.maxDepth);
    assert(c1.compares == worst);
    assert(c1.maxDepth == n);
    assert(c2.compares > n * 9 && c2.compares < worst / 4);
}

// ═══ 07.3 Hoare 分区（练习 7.1）═══
// 双指针从两端夹逼；返回的 j 满足：递归调 quicksort_hoare(lo..j) 与 (j+1..hi)。
static std::size_t hoare_partition(std::span<int> a, Counters& c) {
    const int x = a[0];
    std::ptrdiff_t i = -1;
    std::ptrdiff_t j = static_cast<std::ptrdiff_t>(a.size());
    while (true) {
        do { --j; ++c.compares; } while (a[j] > x);
        do { ++i; ++c.compares; } while (a[i] < x);
        if (i < j) {
            std::swap(a[static_cast<std::size_t>(i)], a[static_cast<std::size_t>(j)]);
            ++c.swaps;
        } else {
            return static_cast<std::size_t>(j);
        }
    }
}

static void quicksort_hoare(std::span<int> a, Counters& c) {
    if (a.size() < 2) { return; }
    const std::size_t p = hoare_partition(a, c);
    quicksort_hoare(a.first(p + 1), c);
    quicksort_hoare(a.subspan(p + 1), c);
}

static void hoare_demo() {
    std::mt19937 rng{5489};
    const int n = 512;
    std::vector<int> v(n);
    for (int i = 0; i < n; ++i) { v[static_cast<std::size_t>(i)] = i; }
    for (int i = n - 1; i > 0; --i) {
        std::swap(v[static_cast<std::size_t>(i)],
                  v[static_cast<std::size_t>(rand_below(rng, static_cast<std::uint32_t>(i) + 1))]);
    }
    auto v1 = v;
    Counters ch{}, cl{};
    quicksort_hoare(v1, ch);
    quicksort_det(v, cl);
    assert(std::ranges::is_sorted(v1) && v1 == v);
    println("Hoare 分区 vs CLRS(Lomuto) 分区（n=512 同一随机排列）：");
    println("  Hoare ：比较 {}，交换 {}", ch.compares, ch.swaps);
    println("  Lomuto：比较 {}，交换 {}", cl.compares, cl.swaps);
}

// ═══ 07.4 期望比较数的经验验证 ═══
// CLRS §7.4：随机输入（或随机化主元）下 E[比较] ≤ 2n·ln n ≈ 1.39·n·lg n。
static void expectation_demo() {
    const int n = 512, trials = 200;
    long long total = 0;
    long long best = 1LL << 62, worstC = 0;
    for (int t = 0; t < trials; ++t) {
        std::mt19937 rng{5489 + static_cast<std::uint32_t>(t)};
        std::vector<int> v(n);
        for (int i = 0; i < n; ++i) { v[static_cast<std::size_t>(i)] = i; }
        for (int i = n - 1; i > 0; --i) {
            std::swap(v[static_cast<std::size_t>(i)],
                      v[static_cast<std::size_t>(rand_below(rng, static_cast<std::uint32_t>(i) + 1))]);
        }
        Counters c{};
        quicksort_det(v, c); // 已洗牌的输入 = 随机排列
        assert(std::ranges::is_sorted(v));
        total += c.compares;
        best = std::min(best, c.compares);
        worstC = std::max(worstC, c.compares);
    }
    // ln 512 = 6.2383；CLRS 定理：E[比较] ≤ 2n·ln n（≈ 1.39·n·lg n）
    println("快排期望验证：n=512 × {} 个固定种子随机排列：", trials);
    println("  平均比较 {}（信息论下界 ~n·lg n = {}，CLRS 期望上界 2n·ln n = {:.0f}）",
            total / trials, n * 9, 2.0 * n * 6.2383);
    println("  最少 {} / 最多 {}（期望的波动范围）", best, worstC);
    assert(total / trials > n * 9 && total / trials < 6388);
}

// ═══ 07.5 尾循环消除：递归深度 O(lg n) ═══
// QUICKSORT'（CLRS p.188 练习 7-4? 实为 7.2.2 尾递归优化思想）：
// 递归进较小的一半，另一半用循环继续——栈深度保证 ≤ lg n + 1。
static void quicksort_tail(std::span<int> a, Counters& c, std::size_t depth = 1) {
    c.maxDepth = std::max(c.maxDepth, static_cast<long long>(depth));
    while (a.size() > 1) {
        const std::size_t q = partition(a, c);
        if (q + 1 > a.size() - q - 1) {          // 左半更大：递归右半
            quicksort_tail(a.subspan(q + 1), c, depth + 1);
            a = a.first(q);
        } else {                                  // 右半更大（或相等）：递归左半
            quicksort_tail(a.first(q), c, depth + 1);
            a = a.subspan(q + 1);
        }
    }
}

static void depth_demo() {
    const int n = 512;
    std::vector<int> sorted(n);
    for (int i = 0; i < n; ++i) { sorted[static_cast<std::size_t>(i)] = i; }
    auto a1 = sorted;
    Counters c1{};
    quicksort_det(a1, c1);              // 朴素版在已序输入：深度 = n
    auto a2 = sorted;
    Counters c2{};
    quicksort_tail(a2, c2);             // 尾循环版在已序输入：深度 ≤ lg n + 1
    assert(std::ranges::is_sorted(a1) && std::ranges::is_sorted(a2));
    println("递归深度（已序输入 n={}）：朴素版 {}（= n），尾循环消除版 {}（≤ lg n + 1 = {}）",
            n, c1.maxDepth, c2.maxDepth, 10);
    assert(c1.maxDepth == n);
    assert(c2.maxDepth <= 11);
}

// ═══ 07.6 三路分区：重复元素的救场（思考题 7-2）═══
// Lomuto/Lomuto 化的两路分区在大量重复元素下退化（相等元素全被算进一侧，
// 全相等时照样 n²）。三路分区把 ==pivot 的段一次切掉。
struct Range { std::size_t lt, gt; }; // a[0..lt) < pivot，a[gt+1..n) > pivot

static Range three_way_partition(std::span<int> a, Counters& c) {
    const int pivot = a[a.size() - 1];
    std::size_t lt = 0, i = 0;
    std::size_t gt = a.size() - 1; // a[gt+1..n) > pivot 待收尾
    while (i < gt + 1) {
        if (++c.compares, a[i] < pivot) {
            std::swap(a[lt], a[i]); ++lt; ++i;
        } else if (++c.compares, a[i] > pivot) {
            std::swap(a[i], a[gt]); --gt; // i 不动：换来的还没看
        } else {
            ++i;
        }
    }
    // 此处 a[lt..gt] == pivot（原主元元素也已在区间内）
    return {lt, gt};
}

static void quicksort_3way(std::span<int> a, Counters& c) {
    if (a.size() < 2) { return; }
    const Range r = three_way_partition(a, c);
    quicksort_3way(a.first(r.lt), c);
    quicksort_3way(a.subspan(r.gt + 1), c);
}

static void three_way_demo() {
    // 全相等数组：两路 Lomuto 直接退化成最坏 n(n-1)/2
    const int n = 2048;
    std::vector<int> allSame(n, 7);
    auto a1 = allSame;
    Counters c1{};
    quicksort_det(a1, c1);
    auto a2 = allSame;
    Counters c2{};
    quicksort_3way(a2, c2);
    assert(std::ranges::is_sorted(a1) && std::ranges::is_sorted(a2));
    println("全相等数组 n={}：两路分区比较 {}（= n(n-1)/2 退化），三路分区比较 {}（~n 一次切平）",
            n, c1.compares, c2.compares);
    assert(c1.compares == static_cast<long long>(n) * (n - 1) / 2);
    assert(c2.compares <= 2 * n); // 全相等时每元素恰好 2 次比较（< pivot? > pivot?）
    // 三值域随机数组：重复率中等，三路仍显著省
    std::mt19937 rng{5489};
    std::vector<int> tri(10000);
    for (auto& v : tri) { v = static_cast<int>(rand_below(rng, 3)); }
    auto b1 = tri;
    Counters d1{}, d2{};
    quicksort_det(b1, d1);
    quicksort_3way(tri, d2);
    assert(std::ranges::is_sorted(b1) && b1 == tri);
    println("三值域随机数组 n=10000：两路比较 {}，三路比较 {}（比值 {:.2f}）",
            d1.compares, d2.compares,
            static_cast<double>(d1.compares) / static_cast<double>(d2.compares));
}

int main() {
    partition_demo();
    worst_vs_random_demo();
    hoare_demo();
    expectation_demo();
    depth_demo();
    three_way_demo();
    println("自检通过");
    return 0;
}
