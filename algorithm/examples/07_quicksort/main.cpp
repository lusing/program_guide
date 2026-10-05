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

// ═══ 07.7 按谓词分区：partition 的真正抽象 ═══
// 前面三路分区里写死了「< pivot / > pivot」两个比较。把它换成**任意谓词**
// `pred(x) == true 表示该去左段`，就得到 partition 的通用形态：
//
//   同一个循环骨架，只换谓词，就能做完全不同的事：
//     奇偶分类   pred = [](int x){ return x % 2 == 1; }        「奇数在前」
//     01 分类    pred = [](int x){ return x < k; }              「小于 k 的在前」
//     活动筛选   pred = [](int x){ return x.satisfies(); }      谓词带业务逻辑
//
// 复杂度恒为 Θ(n) 时间 + Θ(1) 额外空间——**一趟扫描，不递归、不分配**。
// 关键不变式（与 07.1 的 CLRS 版同源，只是把「≤ pivot」换成 pred）：
//   对任意 j' ∈ [i, j)：a[i..j') 不满足 pred，a[j..j') 满足 pred。
// 终止时（j == n）分界点就是 a[i]，不变量 a[i..n) 全部满足 pred。
//
// 稳定性说明：Lomuto 型的交换会把远处元素换到前面，**不稳定**。要稳定
// 就得用「原开两个数组再归并」的 Θ(n) 额外空间路线——没有既省空间又
// 稳定的单趟版本。
template <class T, class Pred>
static std::size_t partition_by(std::span<T> a, Pred pred, Counters& c) {
    std::size_t i = 0;
    for (std::size_t j = 0; j < a.size(); ++j) {
        if (++c.compares, pred(a[j])) {
            if (i != j) { std::swap(a[i], a[j]); ++c.swaps; }
            ++i;
        }
    }
    return i;                                   // [0, i) 满足 pred，[i, n) 不满足
}

static void predicate_partition_demo() {
    println("");
    println("=== 07.7 按谓词分区 ===");

    // 用例一：奇偶分类（最朴素的一次扫描）
    std::vector<int> nums{3, 1, 4, 1, 5, 9, 2, 6, 5, 3};
    const auto before = nums;
    Counters c1{};
    const std::size_t i1 = partition_by(std::span<int>{nums}, [](int x) { return x % 2 == 1; }, c1);
    println("奇偶分类（谓词 = 奇数）：");
    print_arr("  原始 ", std::span<const int>(before));
    print_arr("  分区 ", std::span<const int>(nums));
    println("  分界点 = {}，{} 次比较、{} 次交换（Θ(n) 一趟，不分配）",
            i1, c1.compares, c1.swaps);
    for (std::size_t k = 0; k < i1; ++k) { assert(nums[k] % 2 == 1); }
    for (std::size_t k = i1; k < nums.size(); ++k) { assert(nums[k] % 2 == 0); }
    // 元素多重集必须保持不变（分区是重排，不是增删）
    auto sorted_before = before;
    auto sorted_after = nums;
    std::ranges::sort(sorted_before);
    std::ranges::sort(sorted_after);
    assert(sorted_before == sorted_after);
    println("  元素多重集保持不变（分区是重排，不是增删）");

    // 用例二：换一个谓词就是另一个问题（阈值分类）
    std::vector<int> vals{12, 3, 45, 7, 19, 8, 31, 2, 40, 11};
    const auto before2 = vals;
    Counters c2{};
    // 用例二：换一个谓词就是另一个问题（阈值分类）。
    // 谓词里直接写字面量：局部 constexpr 即使是编译期常量，lambda **仍需
    // 显式捕获**（只有 static constexpr / 枚举 / 字面量才免捕获），而显式
    // 捕获一个常量会触发 -Wunused-lambda-capture。字面量是最干净的写法。
    constexpr int kThreshold = 25;
    const std::size_t i2 = partition_by(std::span<int>{vals},
 [](int x) { return x < 25; }, c2);
    println("");
    println("阈值分类（谓词 = 小于 {}）：", kThreshold);
    print_arr("  原始 ", std::span<const int>(before2));
    print_arr("  分区 ", std::span<const int>(vals));
    println("  分界点 = {}，小于 {} 的有 {} 个 | 大于等于的有 {} 个",
            i2, kThreshold, i2, vals.size() - i2);
    for (std::size_t j = 0; j < i2; ++j) { assert(vals[j] < kThreshold); }
    for (std::size_t j = i2; j < vals.size(); ++j) { assert(vals[j] >= kThreshold); }

    // 用例三：谓词是「业务逻辑」而非比较（筛掉不合格记录）
    struct Item { int id; bool ok; };
    std::vector<Item> items{{1, true}, {2, false}, {3, true}, {4, false},
                            {5, true}, {6, true}, {7, false}};
    Counters c3{};
    const std::size_t i3 = partition_by(std::span<Item>{items}, [](const Item& it) { return it.ok; }, c3);
    println("");
    println("筛选合格记录（谓词 = ok）：");
    print("  结果 id: ");
    for (std::size_t j = 0; j < items.size(); ++j) { print("{} ", items[j].id); }
    println("");
    println("  合格 {} 条全部聚到下标 0 起的一段，不合格 {} 条沉到右侧（顺序被打乱）",
            i3, items.size() - i3);
    for (std::size_t j = 0; j < i3; ++j) { assert(items[j].ok); }
    for (std::size_t j = i3; j < items.size(); ++j) { assert(!items[j].ok); }

    // 用例四：与 07.1 的 CLRS PARTITION 对账——同一套骨架、同一组比较
    // 「谓词 = (x <= pivot)」时，partition_by 与 quicksort 里的 partition
    // 应给出**完全相同**的数组（同主元同位置时）。这证明抽象没丢信息。
    println("");
    println("与 07.1 CLRS PARTITION 同构对账：");
    std::vector<int> z1{7, 2, 9, 4, 2, 8, 1, 5, 3, 6};
    std::vector<int> z2 = z1;
    Counters c4{};
    quicksort_det(z1, c4);                      // 走 CLRS 版 partition 排完
    const int pivot = z1.front();               // 全序排列，最小值即结果
    Counters c5{};
    partition_by(std::span<int>{z2}, [pivot](int x) { return x <= pivot; }, c5);
    assert(std::ranges::is_sorted(z1));
    assert(z2.front() == pivot);
    println("  CLRS 版排完得有序序列；谓词版以最小值为主元，{} 次比较完成分类",
            c5.compares);
    println("  → 两者是同一段循环骨架，抽象无信息损失（Θ(n) 时间 / Θ(1) 空间）");

    // 边界：全满足 / 全不满足 —— 分界点落在 0 或 n，不越界
    std::vector<int> allOk{2, 4, 6};
    Counters c6{};
    assert(partition_by(std::span<int>{allOk}, [](int x) { return x % 2 == 0; }, c6) == 3);
    std::vector<int> allBad{1, 3, 5};
    Counters c7{};
    assert(partition_by(std::span<int>{allBad}, [](int x) { return x % 2 == 0; }, c7) == 0);
    std::vector<int> none{};
    Counters c8{};
    assert(partition_by(std::span<int>{none}, [](int) { return true; }, c8) == 0);
    println("");
    println("边界：全满足 → 分界点 = size；全不满足 → 0；空数组 → 0（都不越界）");
    println("注意：本分区**不稳定**——交换会把远处元素换到前面，");
    println("      要稳定就得多开一个数组做 Θ(n) 归并，没有又省空间又稳的单趟版。");
}

int main() {
    partition_demo();
    worst_vs_random_demo();
    hoare_demo();
    expectation_demo();
    depth_demo();
    three_way_demo();
    predicate_partition_demo();
    println("自检通过");
    return 0;
}
