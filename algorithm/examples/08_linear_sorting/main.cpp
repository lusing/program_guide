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
#include <string>
#include <string_view>
#include <utility>
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

// ═══ 08.6 逆序对计数：值域小就用计数代替比较 ═══
//
// 问题：m 个等长 DNA 串，按其**逆序数**（i<j 且 s_i > s_j 的对数）升序排序。
// 逆序数是「排序所需交换次数的下界」，所以它是排序问题里最常出现的次序键。
//
// 通用解法是**归并排序计数法**：归并时统计跨半区的逆序对，Θ(n lg n)。
// 但 DNA只有 4 个字母——**值域小就可以用计数代替比较**，把 Θ(n²) 压到 Θ(n)。
// 这是第 8 章「换模型」思想的一个小型复刻：不再问「a<b 吗」，而是问
// 「前面有多少个比 b 大的」。
//
// ── 方法一：小字母表前缀计数 Θ(n) ──
// 不变式（写代码时必须先写下来，否则必然算错）：
//   **c_X = 已扫描前缀（s[0..i-1]）中字母 X 的出现次数**。
// 处理 s[i] 时，新增的逆序对数 = 「前缀中比 s[i] 大的字母的个数之和」：
//   s[i] = 'A' → 新增 c_C + c_G + c_T，然后 c_A++
//   s[i] = 'C' → 新增 c_G + c_T，    然后 c_C++
//   s[i] = 'G' → 新增 c_T，          然后 c_G++
//   s[i] = 'T' → 新增 0，            然后 c_T++
// 「只统计前缀」这层语义是核心——漏了它就会数成「全局计数」，答案偏大。
//
// 每个逆序对 (i,j), i<j, s_i>s_j **恰在处理其右端点 j 时被计一次**，
// 不重不漏——这是正确性的全部内容。
static long long inv_count_small_alpha(std::string_view s) {
    long long cA = 0, cC = 0, cG = 0, cT = 0;   // 已扫描前缀中各字母出现次数
    long long inv = 0;
    for (char ch : s) {
        switch (ch) {
        case 'A': inv += cC + cG + cT; ++cA; break;   // 比 A 大的都算
        case 'C': inv += cG + cT;       ++cC; break;   // 比 C 大的：G、T
        case 'G': inv += cT;             ++cG; break;   // 比 G 大的：T
        case 'T':                       ++cT; break;   // T 最大，前面没人比它大
        default: break;
        }
    }
    // 不变式自检：四个计数器之和恒等于串长。c_A 虽然从不参与加法，
    // 但它必须存在——否则「前缀中各字母的计数」这层语义就残缺了。
    assert(cA + cC + cG + cT == static_cast<long long>(s.size()));
    return inv;
}

// 推广到任意字母表（大小 σ）：先把字符**动态编号**成 0..σ-1，再用
// 「已出现次数数组 + 后缀和」，每个位置 O(σ) ⟹ 总 O(nσ)。
// σ 较大时（比如整个字节范围 256）改用树状数组，O(n lg σ)。
//
// ★ 编号必须保持**字母序**（按字符值排序后依次编号），不能按「首次出现
// 顺序」编号——后者会把 "GATC" 编成 G=0,A=1,T=2,C=3，把大小关系全弄反。
// 「动态编号」要动态的是**用哪几个字符**，而不是编号的顺序。
static long long inv_count_generic(std::string_view s) {
    // 收集实际出现的字符（动态：不用硬编码 a=0,b=1 —— 那是样例特例）
    bool present[256] = {};
    for (char ch : s) { present[static_cast<unsigned char>(ch)] = true; }
    // 按字符值升序编号 ⟹ 编号大小 = 字母大小
    int code[256];
    std::ranges::fill(code, -1);
    int sigma = 0;
    for (int u = 0; u < 256; ++u) {
        if (present[u]) { code[u] = sigma++; }
    }
    // 后缀和：ge[k] = 前缀中「编号 ≥ k」的字符个数
    std::vector<long long> ge(static_cast<std::size_t>(sigma) + 1, 0);
    long long inv = 0;
    for (char ch : s) {
        const std::size_t j =
            static_cast<std::size_t>(code[static_cast<unsigned char>(ch)]);
        inv += ge[j + 1];// 前缀中编号 > j 的个数 = 它与 s[i] 成的逆序对
        for (std::size_t k = 0; k <= j; ++k) { ++ge[k]; }  // 后缀和的增量更新
    }
    return inv;
}
// 归并 a[l..m) 与 a[m..r) 时，两半各自已升序。若 a[i] > a[j]（i 在左半），
// 则左半的 a[i..m) **全部** ≥ a[i] > a[j]，于是产生 m - i 个逆序对，
// 一次性累加后取 a[i]。这一步把「数逆序对」融进归并本身，不额外开一趟。
static long long merge_count(std::vector<int>& a, std::vector<int>& tmp,
                             std::size_t l, std::size_t r) {
    if (r - l <= 1) { return 0; }
    const std::size_t m = l + (r - l) / 2;
    long long inv = merge_count(a, tmp, l, m) + merge_count(a, tmp, m, r);
    std::size_t i = l, j = m, k = l;
    while (i < m && j < r) {
        if (a[i] <= a[j]) {
            tmp[k++] = a[i++];          // 相等时取左边：稳定，且不误计
        } else {
            inv += static_cast<long long>(m - i);   // 左半剩余全部与 a[j] 成逆序
            tmp[k++] = a[j++];
        }
    }
    while (i < m) { tmp[k++] = a[i++]; }
    while (j < r) { tmp[k++] = a[j++]; }
    for (std::size_t t = l; t < r; ++t) { a[t] = tmp[t]; }
    return inv;
}

static long long inv_count_merge(std::string_view s) {
    std::vector<int> a(s.size()), tmp(s.size());
    for (std::size_t i = 0; i < s.size(); ++i) {
        // 字母序 A<C<G<T 用偏移量体现（'A'-'A'=0, 'C'=2, 'G'=6, 'T'=19）
        // 只需保证是**严格单调映射**，不必连续
        a[i] = static_cast<int>(static_cast<unsigned char>(s[i]));
    }
    return merge_count(a, tmp, 0, a.size());
}

// 朴素 Θ(n²) 双层循环——作为正确性基准与代价对照
static long long inv_count_naive(std::string_view s) {
    long long inv = 0;
    for (std::size_t i = 0; i < s.size(); ++i) {
        for (std::size_t j = i + 1; j < s.size(); ++j) {
            if (s[i] > s[j]) { ++inv; }
        }
    }
    return inv;
}

static void inversion_demo() {
    println("");
    println("=== 08.6 逆序对计数：值域小就用计数代替比较 ===");
    // 不变式：c_X = 已扫描前缀中 X 的出现次数
    const char* dna[] = {"ACGT", "GATC", "ACGT", "TGCA", "GGCC", "ATAT"};
    const int m = 6;
    println("m = {} 个 DNA 串（按逆序数升序排序）：", m);
    print("  输入: ");
    for (int i = 0; i < m; ++i) { print("{} ", dna[i]); }
    println("");
    print("  逆序数（两两>关系数）: ");
    for (int i = 0; i < m; ++i) { print("{} ", inv_count_small_alpha(dna[i])); }
    println("");

    // 三种方法对账：Θ(n) 前缀计数 / Θ(n lg n) 归并计数 / Θ(n²) 朴素
    println("");
    println("三法对账（每个串的逆序数）：");
    println("  {:<8} {:>10} {:>12} {:>10}", "串", "前缀计数Θ(n)", "归并Θ(n lg n)", "朴素Θ(n^2)");
    for (int i = 0; i < m; ++i) {
        const long long a = inv_count_small_alpha(dna[i]);
        const long long b = inv_count_merge(dna[i]);
        const long long c = inv_count_naive(dna[i]);
        println("  {:<8} {:>10} {:>12} {:>10}", dna[i], a, b, c);
        assert(a == b && b == c);          // 三法必须一致
    }
    // 手算几个串验证算法本身（不只是三法互证）
    // GATC：G>A、G>C、A>C、T>C 共 3 个（G>T 不成立，因G < T）
    assert(inv_count_small_alpha("GATC") == 3);
    assert(inv_count_small_alpha("ACGT") == 0);      // 已升序
    assert(inv_count_small_alpha("CGTT") == 0);      // 也是升序（C<G<T）
    assert(inv_count_small_alpha("TGCA") == 6);      // 完全降序 n(n-1)/2 = 6
    assert(inv_count_small_alpha("") == 0);          // 鲁棒性：空串
    assert(inv_count_small_alpha("A") == 0);         // 鲁棒性：单字符
    assert(inv_count_small_alpha("AT") == 0);
    assert(inv_count_small_alpha("TA") == 1);
    println("  手算复核：GATC = 3（G>A、G>C、A>C、T>C；注意 G>T 不成立）");
    println("            ACGT = 0（升序）；TGCA = 6 = n(n-1)/2（完全降序的上界）");

    // 推广：σ 字母表上「已出现次数 + 后缀和」，与前缀计数法对账
    {
        // 用更长的随机 DNA 串压一压，顺便验证动态编号
        std::mt19937 rng{5489};
        const std::string alpha = "ACGT";
        for (int trial = 0; trial < 5; ++trial) {
            std::string s;
            const std::size_t len = 40 + static_cast<std::size_t>(rand_below(rng, 40));
            for (std::size_t i = 0; i < len; ++i) {
                s.push_back(alpha[rand_below(rng, 4)]);
            }
            const long long ref = inv_count_naive(s);
            assert(inv_count_small_alpha(s) == ref);
            assert(inv_count_merge(s) == ref);
            assert(inv_count_generic(s) == ref);
            if (trial == 0) {
                println("");
                println("  推广（σ=4，用「已出现次数 + 后缀和」的通用写法）：");
                println("    串长 {}，逆序数 = {}，三法一致（动态编号，不硬编码 a=0,b=1）",
                        len, ref);
            }
        }
        println("  5 组随机串（长 40~79）三法一致 = true");
    }

    // 排序：把 (逆序数, 串) 打包一次排序
    std::vector<std::pair<long long, std::string>> keyed;
    for (int i = 0; i < m; ++i) {
        keyed.emplace_back(inv_count_small_alpha(dna[i]), dna[i]);
    }
    std::ranges::sort(keyed);
    print("  排序后: ");
    for (const auto& [inv, s] : keyed) { print("{} ", s); }
    println("");
    print("  对应逆序数: ");
    for (const auto& [inv, s] : keyed) { print("{} ", inv); }
    println("");
    assert(std::ranges::is_sorted(keyed, [](const auto& x, const auto& y) {
        return x.first < y.first;
    }));

    // 代价对照：n = 50（题目典型规模）时三种方法的「基本操作数」
    {
        const std::size_t n = 50;
        std::mt19937 rng{12345};
        std::string s;
        for (std::size_t i = 0; i < n; ++i) { s.push_back("ACGT"[rand_below(rng, 4)]); }
        // 前缀计数：每字符 1 次 switch + 3 次加法 ⟹ 计~ 3n
        // 归并计数：n lg n 次比较 + n lg n 次搬运
        // 朴素：n(n-1)/2 次比较
        const long long naiveOps = static_cast<long long>(n) * (n - 1) / 2;
        const long long mergeOps = static_cast<long long>(n) * (std::bit_width(n) - 1);
        const long long prefixOps = 3 * static_cast<long long>(n);
        println("");
        println("  规模对照（n = {}，同一串）：朴素 {} 次比较 / 归并 {} 次比较 / 前缀计数 {} 次加法",
                n, naiveOps, mergeOps, prefixOps);
        println("  ⟹ 值域为常数（4 个字母）时，计数法是三者中最省的，且是唯一的 Θ(n)");
        assert(naiveOps > mergeOps);
        assert(mergeOps > prefixOps);
    }

    println("");
    println("  两法的适用边界：");
    println("    前缀计数 Θ(n)      —— 值域 σ 是常数（小字母表 / 小整数键）");
    println("    归并计数 Θ(n lg n)  —— 通用，与值域无关；σ 大时只能用它");
    println("    树状数组 O(n log σ) —— 值域 σ 可枚举但不小（整字节 256 等）");
    println("  三者恒等：它们数的是同一个「每个逆序对恰在处理右端点时计一次」。");
}

int main() {
    lower_bound_demo();
    counting_demo();
    radix_demo();
    bucket_demo();
    summary_demo();
    inversion_demo();
    println("自检通过");
    return 0;
}
