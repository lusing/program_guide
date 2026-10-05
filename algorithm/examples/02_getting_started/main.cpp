// 02 入门：插入排序、循环不变式与归并排序（CLRS 第 2 章）。结构：
// 02.1 插入排序逐步追踪（图 2.2）/ 02.2 循环不变式机器检查 /
// 02.3 最好/最坏/平均的分析实验 / 02.4 MERGE 过程追踪（图 2.3）与递归归并 /
// 02.5 归并排序递归树（图 2.4）/ 02.6 计数问题两例（累积计数、周期取模）/
// 02.7 能量转换（带「不前进」检测与溢出预判的模拟）。
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
#include <format>
#include <random>
#include <span>
#include <string_view>
#include <vector>

// 可移植随机（docs/01 的纪律：不用 uniform_int_distribution）
static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

// 比较次数计数器：本教程用「逻辑计数」代替墙上时钟（见 docs/01）。
struct Counters { long long compares = 0; long long shifts = 0; };

static void print_span(std::string_view label, std::span<const int> a) {
    print("{}", label);
    for (std::size_t i = 0; i < a.size(); ++i) {
        print("{}{}", (i == 0 ? "" : " "), a[i]);
    }
    println("]");
}

// ═══ 02.1 插入排序 + 逐步追踪 ═══
// CLRS INSERTION-SORT（p.18）：对 j = 2..n，把 A[j] 插入已排序的
// A[1..j-1]。C++ 版本：0 基下标 + std::span 视图（不拷贝、不改所有权）。
static void insertion_sort(std::span<int> a, Counters& c) {
    for (std::size_t j = 1; j < a.size(); ++j) {
        int key = a[j];                    // 待插入元素
        std::size_t i = j;                 // 从有序前缀的尾部往左找位置
        while (i > 0 && (++c.compares, a[i - 1] > key)) {
            a[i] = a[i - 1];               // 右移一格
            ++c.shifts;
            --i;
        }
        a[i] = key;                        // 插入
    }
}

// ═══ 02.2 循环不变式的机器检查 ═══
// 不变式（CLRS p.19）：每轮 for 迭代开始时，A[1..j-1] 是原数组前 j-1 个
// 元素组成的**有序**序列。证明分三步走（初始化/保持/终止）；代码里用
// is_sorted + is_permutation 对每一趟做「可执行抽样」。
static void invariant_checked_insertion(std::span<int> a, Counters& c) {
    std::vector<int> prefix{};
    for (std::size_t j = 1; j < a.size(); ++j) {
        // 不变式应在此时成立：A[0..j-1) 有序且是原前缀的排列
        prefix.assign(a.begin(), a.begin() + static_cast<std::ptrdiff_t>(j));
        std::ranges::sort(prefix);
        assert(std::ranges::is_sorted(a.first(j)));
        assert(std::ranges::is_permutation(a.first(j), prefix));

        int key = a[j];
        std::size_t i = j;
        while (i > 0 && (++c.compares, a[i - 1] > key)) {
            a[i] = a[i - 1];
            ++c.shifts;
            --i;
        }
        a[i] = key;
        print_span(std::format("第 {} 趟后 j={}: [", j, j), a);
    }
    assert(std::ranges::is_sorted(a));
}

// ═══ 02.3 最好/最坏/平均 ═══
static void analysis_experiment() {
    const int n = 16;
    Counters cb{}, cw{}, ca{};

    std::vector<int> best(n);
    for (int i = 0; i < n; ++i) { best[i] = i + 1; }   // 已序：每趟只比较 1 次
    insertion_sort(best, cb);

    std::vector<int> worst(n);
    for (int i = 0; i < n; ++i) { worst[i] = n - i; }  // 逆序：每趟比较到底
    insertion_sort(worst, cw);

    // 平均情形：固定种子的伪随机排列（确定性的「平均样本」）
    std::vector<int> avg(n);
    for (int i = 0; i < n; ++i) { avg[i] = i + 1; }
    std::mt19937 rng{5489};
    for (int i = n - 1; i > 0; --i) {                  // Fisher-Yates 洗牌
        std::swap(avg[i], avg[rand_below(rng, static_cast<std::uint32_t>(i) + 1)]);
    }
    insertion_sort(avg, ca);

    println("n={}：最好(已序)比较 {}（理论 n-1={}）", n, cb.compares, n - 1);
    println("n={}：最坏(逆序)比较 {}（理论 n(n-1)/2={}）", n, cw.compares,
            static_cast<long long>(n) * (n - 1) / 2);
    println("n={}：随机排列比较 {}（理论期望 ~n^2/4={}）", n, ca.compares,
            static_cast<long long>(n) * n / 4);
}

// ═══ 02.4 MERGE 过程追踪 + 递归归并排序 ═══
// CLRS MERGE（p.31）用哨兵 ∞；C++ 版本用下标边界判断——不需要「魔法值」，
// 也不要求元素类型有最大值。两者比较次数完全一致（每归并一个元素至多一次
// 比较，两边都非空时才比较）。
static void merge_sort_impl(std::span<int> a, std::span<int> buf, Counters& c) {
    if (a.size() < 2) { return; }
    const std::size_t mid = a.size() / 2;
    merge_sort_impl(a.first(mid), buf.first(mid), c);
    merge_sort_impl(a.subspan(mid), buf.subspan(mid), c);
    std::copy(a.begin(), a.end(), buf.begin());
    std::size_t i = 0, j = mid, k = 0;
    while (i < mid && j < a.size()) {
        if (++c.compares, buf[i] <= buf[j]) {          // ≤：相等取左（稳定性）
            a[k++] = buf[i++];
        } else {
            a[k++] = buf[j++];
        }
    }
    while (i < mid)      { a[k++] = buf[i++]; }        // 剩余直接搬
    while (j < a.size()) { a[k++] = buf[j++]; }
}

static void merge_sort(std::span<int> a, Counters& c) {
    std::vector<int> buf(a.size());
    merge_sort_impl(a, buf, c);
}

// ═══ 02.5 递归树打印 ═══
// CLRS 图 2.4：T(n) = 2T(n/2) + cn 的树形分解。深度 = lg n，每层合并代价
// 共 cn，总代价 cn·lg n。打印 n=8 的树结构 + 各层合并计数。
static void recursion_tree(int n) {
    assert(n == 8);
    println("归并排序递归树（n={}，深度 lg n = {}）：", n, 3);
    println("                [整棵 n={}]  本层合并代价 c·{}", n, n);
    println("              /            \\", n);
    println("        [n={}]            [n={}]      每层两半，共 c·{}", n / 2, n / 2, n);
    println("       /      \\          /      \\", n);
    println("    [n={}]  [n={}]   [n={}]  [n={}]   共 c·{}", n / 4, n / 4, n / 4, n / 4, n);
    println("    叶子 8 个（n=1，不再合并）           深度 lg 8 = 3 层 × c·8");
    // 递归计数对账：n=8 的归并排序总比较次数（本实现、固定输入下确定）
    std::vector<int> v{5, 2, 4, 7, 1, 3, 2, 6};   // CLRS 图 2.4 的数组
    Counters c{};
    merge_sort(v, c);
    print_span("图 2.4 数组排序结果[", v);
    println("归并比较次数 = {}（≤ n·lg n = 8×3 = 24）", c.compares);
    assert(std::ranges::is_sorted(v));
}

// ═══ 02.6 两个计数问题：累积计数与周期取模 ═══
// 问题 1-1 骑士的金币：第 1 天 1 枚，接下来 2 天每天 2 枚，接下来 3 天每天
// 3 枚……问第 N 天累计多少枚。这是「累积计数」的原型：一个计数器走天数，
// 一个计数器攒金币，循环不变式是「days 天时 coins = 已到期各段贡献之和」。
static long long golden_coins(long long n) {
    long long coins = 0, k = 1, days = 0;
    while (days + k <= n) {          // 还装得下一整个「k 枚段」
        coins += k * k;              // 该段 k 天、每天 k 枚
        days += k;
        ++k;
    }
    coins += k * (n - days);         // 尾段：剩 n−days 天，每天 k 枚
    return coins;
}

// 问题 1-7 公交调度：每路车按给定的间隔序列**循环**发车，周期 T = Σ间隔。
// 到达时刻 arrival 与「圈内的哪一班车最近」只通过 arrival mod T 有关——
// 取模把无穷时间轴压回一个周期内；再用前缀和找到圈内第一个 ≥ R 的发车点。
static void counting_problems() {
    println("金币问题（1-1）：连续 k 天每天 k 枚，天数与金币总数：");
    const long long cases[]{10, 6, 7, 11, 100, 10000};
    for (long long n : cases) {
        const long long coins = golden_coins(n);
        // 闭式对账：找 k 使 k(k+1)/2 ≤ n，则金币 = Σ_{i≤k} i² + (k+1)·j，
        // 其中 j = n − k(k+1)/2；Σi² 的闭式是 k(k+1)(2k+1)/6。
        long long k = 0, tri = 0;    // tri = k(k+1)/2
        while (tri + k + 1 <= n) { ++k; tri += k; }
        const long long j = n - tri;
        const long long closed = k * (k + 1) * (2 * k + 1) / 6 + (k + 1) * j;
        assert(coins == closed);
        println("  N={:5}：金币 {:6}（= Σi^2 闭式 k(k+1)(2k+1)/6 + (k+1)·{}）",
                n, coins, j);
    }

    println("公交调度（1-7）：周期取模 + 前缀和扫描：");
    // 三路车，发车间隔构成循环周期；乘客 arrival=1000 时刻到站
    const std::vector<std::vector<long long>> routes{
        {100, 200, 300}, {400, 500, 600}, {700, 800, 900}};
    const long long arrival = 1000;
    long long best = -1;
    for (std::size_t i = 0; i < routes.size(); ++i) {
        long long period = 0;                       // T = 一圈的总时长
        for (long long d : routes[i]) { period += d; }
        const long long r = arrival % period;       // 本周期内已过的时刻
        long long wait = period - r;                // 最坏：等到下一圈头一班车
        long long prefix = 0;                       // 前缀和 = 圈内发车时刻
        for (long long d : routes[i]) {
            prefix += d;
            if (prefix >= r) { wait = prefix - r; break; }  // 第一班 ≥ r
        }
        println("  第 {} 路：周期 T={}，arrival mod T = {} ⟹ 等待 {}",
                i + 1, period, r, wait);
        if (best < 0 || wait < best) { best = wait; }
    }
    println("  最短等待 = {}（arrival={} 取模后只需看圈内的第 {} 个时间单位）",
            best, arrival, arrival % 600);
    assert(best == 200);
}

// ═══ 02.7 能量转换：先预判、后乘法的模拟 ═══
// 转换规则 A ← (A−V)·K。三类失败：① M≥N 不用转；② M<V 连一次都做不了；
// ③ 转换不增（(A−V)·K ≤ A，K=1（V=0 时持平）/ K=0 / 能量太低时都可能）。
// 关键纪律：**先判断乘积是否已达标，达标就直接返回，不做乘法**——
// 因为一旦 (A−V)·K ≥ N 这一步就是答案；而不提前返回时乘积严格小于 N，
// 全程算术被 N（题面 ≤1e8）钳住，根本不存在溢出。
static long long energy_conversions(long long n, long long m, long long v,
                                    long long k) {
    if (m >= n) { return 0; }                    // ①
    if (m < v) { return -1; }                    // ②
    long long a = m, count = 0;
    while (true) {
        const long long gain = a - v;
        // 「这一步就够」等价于 gain·k ≥ n；不做乘法的判法：
        // gain ≥ ⌈n/k⌉，k=0 时右边无意义（必然不前进，交给下面的判定）。
        if (k > 0 && gain >= (n + k - 1) / k) { return count + 1; }
        const long long next = gain * k;         // 此处必有 next < n，安全
        if (next <= a) { return -1; }            // ③ 不前进：永远没戏
        a = next;
        ++count;
    }
}

// BFS 对账（小值域）：把能量值 0..N 当状态，转换是有向边；跳跃 ≥N 即开门。
// 与模拟版的区别是它不依赖「贪心每次必转」的直觉——本题转换唯一，
// BFS 只是给模拟的正确性背书。
static long long energy_conversions_bfs(long long n, long long m, long long v,
                                        long long k) {
    if (m >= n) { return 0; }
    std::vector<int> dist(static_cast<std::size_t>(n), -1);
    std::vector<long long> q;
    q.push_back(m);
    dist[static_cast<std::size_t>(m)] = 0;
    for (std::size_t head = 0; head < q.size(); ++head) {
        const long long a = q[head];
        if (a < v) { continue; }
        const long long b = (a - v) * k;
        if (b >= n) { return dist[static_cast<std::size_t>(a)] + 1; }
        if (dist[static_cast<std::size_t>(b)] < 0) {
            dist[static_cast<std::size_t>(b)] =
                dist[static_cast<std::size_t>(a)] + 1;
            q.push_back(b);
        }
    }
    return -1;
}

static void energy_conversion_demo() {
    println("能量转换（1-3）：A ← (A−V)·K，求最少转换次数：");
    struct Case { long long n, m, v, k, want; };
    const Case cases[]{{10, 3, 1, 2, 3}, {10, 2, 1, 2, -1},
                       {10, 9, 7, 3, -1}, {10, 10, 10000, 0, 0}};
    for (const Case& c : cases) {
        const long long r = energy_conversions(c.n, c.m, c.v, c.k);
        println("  N={} M={} V={} K={} ⟹ {} 次", c.n, c.m, c.v, c.k, r);
        assert(r == c.want);
        assert(r == energy_conversions_bfs(c.n, c.m, c.v, c.k));
    }
    // 大值域：一次跳满。先预判的写法全程不出现 ≥N 的中间积。
    const long long big = energy_conversions(100000000, 2, 1, 100000000);
    println("  N=1e8 M=2 V=1 K=1e8 ⟹ {} 次（预判命中，无中间乘积）", big);
    assert(big == 1);

    // 随机小例：模拟版 vs BFS 版，全一致才算对。
    std::mt19937 rng{5489};
    int mismatches = 0;
    for (int t = 0; t < 3000; ++t) {
        const long long n = 1 + rand_below(rng, 60);
        const long long m = rand_below(rng, static_cast<std::uint32_t>(n) + 1);
        const long long v = rand_below(rng, 10);
        const long long k = rand_below(rng, 5);
        const long long r1 = energy_conversions(n, m, v, k);
        const long long r2 = energy_conversions_bfs(n, m, v, k);
        if (r1 != r2) { ++mismatches; }
    }
    println("  随机 {} 例模拟 vs BFS：不一致 {} 例", 3000, mismatches);
    assert(mismatches == 0);
}

int main() {
    // 02.1 图 2.2 的数组：逐步追踪
    std::vector<int> fig22{5, 2, 4, 6, 1, 3};
    print_span("初始数组      [", fig22);
    Counters ci{};
    invariant_checked_insertion(fig22, ci);
    println("插入排序共比较 {} 次、移位 {} 次", ci.compares, ci.shifts);
    assert(fig22 == std::vector<int>({1, 2, 3, 4, 5, 6}));

    // 02.3 分析实验
    analysis_experiment();

    // 02.4 图 2.3 的 MERGE 追踪：⟨2,4,5,7⟩ 与 ⟨1,2,3,6⟩
    std::vector<int> fig23{2, 4, 5, 7, 1, 2, 3, 6};
    Counters cm{};
    std::vector<int> buf(fig23.size());
    println("MERGE 追踪（CLRS 图 2.3 的两个子数组）：");
    // 只演示单次 MERGE：手工把两个有序子数组合并（mid=4）
    {
        std::copy(fig23.begin(), fig23.end(), buf.begin());
        std::size_t i = 0, j = 4, k = 0;
        while (i < 4 && j < fig23.size()) {
            if (++cm.compares, buf[i] <= buf[j]) {
                println("  取左 {}（比较 #{}）", buf[i], cm.compares);
                fig23[k++] = buf[i++];
            } else {
                println("  取右 {}（比较 #{}）", buf[j], cm.compares);
                fig23[k++] = buf[j++];
            }
        }
        while (i < 4)              { fig23[k++] = buf[i++]; }
        while (j < fig23.size())   { fig23[k++] = buf[j++]; }
        print_span("MERGE 结果[", fig23);
        println("单次 MERGE 比较实测 {}（理论 ≤ 左+右-1 = 4+4-1 = 7）", cm.compares);
        assert(cm.compares == 7);
        assert(std::ranges::is_sorted(fig23));
    }

    // 02.5 递归树
    recursion_tree(8);

    // 02.6 计数问题两例
    counting_problems();

    // 02.7 能量转换
    energy_conversion_demo();

    println("自检通过");
    return 0;
}
