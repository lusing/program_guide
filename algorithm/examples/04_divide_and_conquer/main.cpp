// 04 分治策略（CLRS 第 4 章）。结构：04.1 最大子数组（暴力/分治/Kadane）/
// 04.2 Strassen 矩阵乘（S/P 全表 + 三种口径的乘/加计数对比）/ 04.3 递归树打印 /
// 04.4 主定理应用器 + 递归式精确值的经验验证 /
// 04.5 二分查找：分治的极端形态（f(n)=Θ(1)）+ 边界不变式 + 旋转最小值 /
// 04.7 逆序数：归并排序的副产物（一趟归并顺手记账）+ DNA 串排序。
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
#include <limits>
#include <random>
#include <span>
#include <string>
#include <string_view>
#include <vector>

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    std::uint64_t m = static_cast<std::uint64_t>(rng()) * n;
    return static_cast<std::uint32_t>(m >> 32);
}

// ═══ 04.1 最大子数组 ═══
// CLRS 图 4.1 的股价变化序列（16 天）。
static const std::vector<int> kChanges{13, -3, -25, 20, -3, -16, -23, 18,
                                       20, -7, 12, -5, -22, 15, -4, 7};

struct Sub { long long sum = 0; int lo = 0, hi = -1; }; // [lo, hi] 闭区间
struct OpCounters { long long adds = 0; };              // 口径：子数组和的累加次数

// 暴力 Θ(n²)：固定起点 i，向右累加，记录最大和
static Sub brute_force(const std::vector<int>& a, OpCounters& c) {
    Sub best{std::numeric_limits<long long>::min(), 0, 0};
    for (std::size_t i = 0; i < a.size(); ++i) {
        long long sum = 0;
        for (std::size_t j = i; j < a.size(); ++j) {
            sum += a[j];
            ++c.adds;
            if (sum > best.sum) { best = {sum, static_cast<int>(i), static_cast<int>(j)}; }
        }
    }
    return best;
}

// 跨中点的最大子数组（CLRS p.70 FIND-MAX-CROSSING-SUBARRAY）
static Sub max_crossing(const std::vector<int>& a, int lo, int mid, int hi, OpCounters& c) {
    long long leftSum = std::numeric_limits<long long>::min();
    long long sum = 0;
    int maxLeft = mid;
    for (int i = mid; i >= lo; --i) {
        sum += a[static_cast<std::size_t>(i)];
        ++c.adds;
        if (sum > leftSum) { leftSum = sum; maxLeft = i; }
    }
    long long rightSum = std::numeric_limits<long long>::min();
    sum = 0;
    int maxRight = mid + 1;
    for (int j = mid + 1; j <= hi; ++j) {
        sum += a[static_cast<std::size_t>(j)];
        ++c.adds;
        if (sum > rightSum) { rightSum = sum; maxRight = j; }
    }
    return {leftSum + rightSum, maxLeft, maxRight};
}

// 分治：完全在左半 / 完全在右半 / 跨中点，三者取最大（CLRS p.71）
static Sub dac_max_sub(const std::vector<int>& a, int lo, int hi, OpCounters& c) {
    if (lo == hi) { return {a[static_cast<std::size_t>(lo)], lo, lo}; }
    const int mid = lo + (hi - lo) / 2;
    const Sub left  = dac_max_sub(a, lo, mid, c);
    const Sub right = dac_max_sub(a, mid + 1, hi, c);
    const Sub cross = max_crossing(a, lo, mid, hi, c);
    if (left.sum >= right.sum && left.sum >= cross.sum) { return left; }
    if (right.sum >= left.sum && right.sum >= cross.sum) { return right; }
    return cross;
}

// Kadane 线性算法（CLRS 练习 4.1-5）：以 j 结尾的最大和只依赖以 j-1 结尾者
static Sub kadane(const std::vector<int>& a, OpCounters& c) {
    Sub best{a[0], 0, 0};
    long long endingHere = a[0];
    int start = 0;
    for (std::size_t j = 1; j < a.size(); ++j) {
        if (endingHere > 0) {
            endingHere += a[j];
        } else {                 // 前缀是负担，不如从 j 重新开始
            endingHere = a[j];
            start = static_cast<int>(j);
        }
        ++c.adds;
        if (endingHere > best.sum) { best = {endingHere, start, static_cast<int>(j)}; }
    }
    return best;
}

static void max_subarray_demo() {
    println("图 4.1 变化量数组（16 天）：");
    println("  [13 -3 -25 20 -3 -16 -23 18 20 -7 12 -5 -22 15 -4 7]");
    OpCounters cb{}, cd{}, ck{};
    const Sub b = brute_force(kChanges, cb);
    const Sub d = dac_max_sub(kChanges, 0, static_cast<int>(kChanges.size()) - 1, cd);
    const Sub k = kadane(kChanges, ck);
    println("暴力   Θ(n^2)：和={}，区间=[{},{}]（0 基，即第 {}~{} 天），累加 {} 次",
            b.sum, b.lo, b.hi, b.lo + 1, b.hi + 1, cb.adds);
    println("分治 Θ(n lg n)：和={}，区间=[{},{}]，累加 {} 次", d.sum, d.lo, d.hi, cd.adds);
    println("Kadane  Θ(n)：和={}，区间=[{},{}]，累加 {} 次", k.sum, k.lo, k.hi, ck.adds);
    assert(b.sum == d.sum && d.sum == k.sum && k.sum == 43);
    assert(b.lo == d.lo && d.lo == k.lo && k.lo == 7);
    assert(b.hi == d.hi && d.hi == k.hi && k.hi == 10);
    // 全负数组：CLRS 练习 4.1-1 —— 应返回最大的单个元素
    const std::vector<int> allNeg{-9, -3, -7, -2, -8};
    OpCounters cn{}, cn2{}, cn3{};
    const Sub nb = brute_force(allNeg, cn);
    const Sub nd = dac_max_sub(allNeg, 0, 4, cn2);
    const Sub nk = kadane(allNeg, cn3);
    println("全负数组 [-9 -3 -7 -2 -8]：三解法都返回 ({},[{},{}])（最大单元素）",
            nb.sum, nb.lo, nb.hi);
    assert(nb.sum == nd.sum && nd.sum == nk.sum && nk.sum == -2);
}

// ═══ 04.2 Strassen ═══
using Mat = std::vector<std::vector<long long>>;
struct MatCounters { long long mults = 0; long long adds = 0; };

static Mat matAdd(const Mat& a, const Mat& b, int sign, MatCounters& c) {
    const std::size_t n = a.size();
    Mat r(n, std::vector<long long>(n));
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 0; j < n; ++j) {
            r[i][j] = a[i][j] + sign * b[i][j];
            ++c.adds;
        }
    }
    return r;
}

// 朴素方阵乘 Θ(n³)（口径：每个乘累加 r += a*b 记 1 乘 1 加）
static Mat naive_mul(const Mat& a, const Mat& b, MatCounters& c) {
    const std::size_t n = a.size();
    Mat r(n, std::vector<long long>(n, 0));
    for (std::size_t i = 0; i < n; ++i) {
        for (std::size_t j = 0; j < n; ++j) {
            for (std::size_t k = 0; k < n; ++k) {
                r[i][j] += a[i][k] * b[k][j];
                ++c.mults;
                ++c.adds;
            }
        }
    }
    return r;
}

// 取象限：q=0..3 → 左上/右上/左下/右下
static Mat quad(const Mat& m, int q) {
    const std::size_t h = m.size() / 2;
    Mat r(h, std::vector<long long>(h));
    const std::size_t r0 = (static_cast<std::size_t>(q) / 2) * h;
    const std::size_t c0 = (static_cast<std::size_t>(q) % 2) * h;
    for (std::size_t i = 0; i < h; ++i) {
        for (std::size_t j = 0; j < h; ++j) { r[i][j] = m[r0 + i][c0 + j]; }
    }
    return r;
}

static Mat combine(const Mat& c11, const Mat& c12, const Mat& c21, const Mat& c22) {
    const std::size_t h = c11.size(), n = h * 2;
    Mat r(n, std::vector<long long>(n));
    for (std::size_t i = 0; i < h; ++i) {
        for (std::size_t j = 0; j < h; ++j) {
            r[i][j] = c11[i][j];         r[i][h + j] = c12[i][j];
            r[h + i][j] = c21[i][j];     r[h + i][h + j] = c22[i][j];
        }
    }
    return r;
}

// Strassen：S1..S10 / P1..P7 全表（CLRS p.75-76）。
// cutoff：n ≤ cutoff 时改用朴素乘——纯 Strassen 递归到 1x1（cutoff=1），
// 工程上则在 2x2 或更大处切换（本例演示两种口径的计数差异）。
// top：仅最外层（CLRS 2x2 例）打印 S/P 表。
static Mat strassen(const Mat& a, const Mat& b, MatCounters& c, int cutoff, bool top) {
    const std::size_t n = a.size();
    if (n == 1) {
        ++c.mults;
        return Mat{{a[0][0] * b[0][0]}};
    }
    if (static_cast<int>(n) <= cutoff) { return naive_mul(a, b, c); }
    const Mat a11 = quad(a, 0), a12 = quad(a, 1), a21 = quad(a, 2), a22 = quad(a, 3);
    const Mat b11 = quad(b, 0), b12 = quad(b, 1), b21 = quad(b, 2), b22 = quad(b, 3);
    const Mat s1  = matAdd(b12, b22, -1, c);  // S1  = B12 − B22
    const Mat s2  = matAdd(a11, a12, +1, c);  // S2  = A11 + A12
    const Mat s3  = matAdd(a21, a22, +1, c);  // S3  = A21 + A22
    const Mat s4  = matAdd(b21, b11, -1, c);  // S4  = B21 − B11
    const Mat s5  = matAdd(a11, a22, +1, c);  // S5  = A11 + A22
    const Mat s6  = matAdd(b11, b22, +1, c);  // S6  = B11 + B22
    const Mat s7  = matAdd(a12, a22, -1, c);  // S7  = A12 − A22
    const Mat s8  = matAdd(b21, b22, +1, c);  // S8  = B21 + B22
    const Mat s9  = matAdd(a11, a21, -1, c);  // S9  = A11 − A21
    const Mat s10 = matAdd(b11, b12, +1, c);  // S10 = B11 + B12
    const Mat p1 = strassen(a11, s1, c, cutoff, false);  // P1 = A11·S1
    const Mat p2 = strassen(s2, b22, c, cutoff, false);  // P2 = S2·B22
    const Mat p3 = strassen(s3, b11, c, cutoff, false);  // P3 = S3·B11
    const Mat p4 = strassen(a22, s4, c, cutoff, false);  // P4 = A22·S4
    const Mat p5 = strassen(s5, s6, c, cutoff, false);   // P5 = S5·S6
    const Mat p6 = strassen(s7, s8, c, cutoff, false);   // P6 = S7·S8
    const Mat p7 = strassen(s9, s10, c, cutoff, false);  // P7 = S9·S10
    // C11 = P5+P4−P2+P6；C12 = P1+P2；C21 = P3+P4；C22 = P5+P1−P3−P7
    const Mat c11 = matAdd(matAdd(p5, p4, +1, c), matAdd(p2, p6, -1, c), -1, c);
    const Mat c12 = matAdd(p1, p2, +1, c);
    const Mat c21 = matAdd(p3, p4, +1, c);
    const Mat c22 = matAdd(matAdd(p5, p1, +1, c), matAdd(p3, p7, +1, c), -1, c); // (P5+P1)−(P3+P7)
    if (top) {
        println("  S1..S10: {} {} {} {} {} {} {} {} {} {}",
                s1[0][0], s2[0][0], s3[0][0], s4[0][0], s5[0][0],
                s6[0][0], s7[0][0], s8[0][0], s9[0][0], s10[0][0]);
        println("  P1..P7: {} {} {} {} {} {} {}", p1[0][0], p2[0][0], p3[0][0],
                p4[0][0], p5[0][0], p6[0][0], p7[0][0]);
        println("  C11=P5+P4-P2+P6={}，C12=P1+P2={}，C21=P3+P4={}，C22=P5+P1-P3-P7={}",
                c11[0][0], c12[0][0], c21[0][0], c22[0][0]);
    }
    return combine(c11, c12, c21, c22);
}

static bool mat_eq(const Mat& a, const Mat& b) {
    if (a.size() != b.size()) { return false; }
    for (std::size_t i = 0; i < a.size(); ++i) {
        for (std::size_t j = 0; j < a.size(); ++j) {
            if (a[i][j] != b[i][j]) { return false; }
        }
    }
    return true;
}

// 固定种子的 n×n 整数矩阵（元素 0..9）
static Mat random_mat(int n, std::uint32_t seed) {
    std::mt19937 rng{seed};
    Mat m(n, std::vector<long long>(n));
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n; ++j) { m[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] = rand_below(rng, 10); }
    }
    return m;
}

static void strassen_demo() {
    // CLRS §4.2 的 2x2 例：A=[[1,3],[7,5]]，B=[[6,8],[4,2]]
    const Mat a{{1, 3}, {7, 5}};
    const Mat b{{6, 8}, {4, 2}};
    MatCounters cs{}, cn{};
    println("CLRS 2x2 例：A=[[1,3],[7,5]] x B=[[6,8],[4,2]]");
    const Mat cStr = strassen(a, b, cs, 1, true);
    const Mat cNai = naive_mul(a, b, cn);
    println("  朴素乘法 C=[[{},{}],[{},{}]]", cNai[0][0], cNai[0][1], cNai[1][0], cNai[1][1]);
    assert(mat_eq(cStr, cNai));
    assert(cStr[0][0] == 18 && cStr[0][1] == 14 && cStr[1][0] == 62 && cStr[1][1] == 66);

    // 4x4：纯 Strassen（cutoff=1）与 2x2 截断（cutoff=2）与朴素乘 三口径对比
    const Mat a4 = random_mat(4, 5489);
    const Mat b4 = random_mat(4, 5490);
    MatCounters cn4{}, c1{}, c2{};
    const Mat n4  = naive_mul(a4, b4, cn4);
    const Mat s1x = strassen(a4, b4, c1, 1, false);
    const Mat s2x = strassen(a4, b4, c2, 2, false);
    assert(mat_eq(n4, s1x) && mat_eq(n4, s2x));
    println("4x4 随机固定矩阵（元素 0..9），三口径计数：");
    println("  朴素 Θ(n^3)          ：乘法 {}，加法 {}", cn4.mults, cn4.adds);
    println("  Strassen 纯递归(1x1) ：乘法 {}（7×7），加法 {}", c1.mults, c1.adds);
    println("  Strassen 2x2 截断    ：乘法 {}（7×8），加法 {}", c2.mults, c2.adds);
    assert(cn4.mults == 64 && c1.mults == 49 && c2.mults == 56);
}

// ═══ 04.3 递归树打印 ═══
static void recursion_trees() {
    println("递归树 T(n)=2T(n/2)+cn（归并排序形）：");
    println("  第 0 层成本 c·n；第 1 层 2·c(n/2)=c·n；第 2 层 4·c(n/4)=c·n");
    println("  每层成本相同，共 lg n + 1 层 → 总成本 Θ(n lg n)");
    println("递归树 T(n)=2T(n/2)+cn^2（内部占主导）：");
    println("  第 0 层 c·n^2；第 1 层 c·n^2/2；第 2 层 c·n^2/4 —— 几何递减");
    println("  总成本 ≤ 2c·n^2 = Θ(n^2)（根节点占一半）");
    println("递归树 T(n)=8T(n/2)+cn^2（叶子占主导）：");
    println("  内部成本几何收敛于 Θ(n^2)，但叶子有 n^lg2(8)=n^3 个 → Θ(n^3)");
}

// ═══ 04.4 主定理应用器 + 经验验证 ═══
// 定理 4.1（CLRS p.94）：T(n)=aT(n/b)+f(n)，a≥1, b>1，与 n^(log_b a) 比较：
//   情形 1：f = O(n^(log_b a − ε))         → T = Θ(n^(log_b a))
//   情形 2：f = Θ(n^(log_b a))             → T = Θ(n^(log_b a) · lg n)
//   情形 3：f = Ω(n^(log_b a + ε)) 且正则  → T = Θ(f)
static void master_theorem() {
    struct Case { int a; int b; const char* f; const char* verdict; };
    const Case cases[] = {
        {2, 2, "n",   "情形 2：n^(log_2 2)=n 与 f=n 同阶 → Θ(n lg n)"},
        {8, 2, "n^2", "情形 1：n^(log_2 8)=n^3 压过 n^2 → Θ(n^3)"},
        {4, 2, "n",   "情形 1：n^(log_2 4)=n^2 压过 n → Θ(n^2)"},
        {4, 2, "n^3", "情形 3：f=n^3 压过 n^2，正则 4·(n/2)^3=n^3/2 ≤ c·n^3 → Θ(n^3)"},
        {3, 2, "n",   "情形 1：n^(log_2 3)≈n^1.585 压过 n → Θ(n^1.585)"},
    };
    for (auto&& cs : cases) {
        println("T(n)={}T(n/{})+{}：{}", cs.a, cs.b, cs.f, cs.verdict);
    }
    // 经验验证：自底向上算精确 T(n)（整数递推，T(1)=1），看比值收敛到常数
    println("经验验证（n=2^k，T(1)=1，自底向上精确递推）：");
    {
        std::vector<long long> t(257);
        t[1] = 1;
        for (int n = 2; n <= 256; n *= 2) { t[static_cast<std::size_t>(n)] = 2 * t[static_cast<std::size_t>(n / 2)] + n; }
        println("  2T(n/2)+n：n=256 时 T={}，T/(n·lg n) = {:.4f}", t[256],
                static_cast<double>(t[256]) / (256.0 * 8));
    }
    {
        std::vector<long long> t(257);
        t[1] = 1;
        for (int n = 2; n <= 256; n *= 2) {
            t[static_cast<std::size_t>(n)] = 8 * t[static_cast<std::size_t>(n / 2)] + static_cast<long long>(n) * n;
        }
        println("  8T(n/2)+n^2：n=256 时 T={}，T/n^3 = {:.4f}", t[256],
                static_cast<double>(t[256]) / (256.0 * 256.0 * 256.0));
    }
    {
        std::vector<long long> t(257);
        t[1] = 1;
        for (int n = 2; n <= 256; n *= 2) {
            t[static_cast<std::size_t>(n)] = 4 * t[static_cast<std::size_t>(n / 2)] + static_cast<long long>(n) * n * n;
        }
        println("  4T(n/2)+n^3：n=256 时 T={}，T/n^3 = {:.4f}", t[256],
                static_cast<double>(t[256]) / (256.0 * 256.0 * 256.0));
    }
}

// ═══ 04.5 二分查找：分治的极端形态 ═══
// 分治三步曲在二分查找上的样子：
//   分解：把 n 折半（不是切 a 份，是**只留一半**）
//   解决：规模为 1 时直接判定
//   合并：**无合并步骤**——f(n) = Θ(1)
// 于是 T(n) = T(n/2) + Θ(1) = Θ(lg n)。它是最纯粹的「缩半」型分治：
// 每层只做一个节点，递归树的「宽」是 1、高是 lg n。
//
// 正确性的全部重量压在**边界不变式**上。选「左闭右开 [lo, hi)���，
// 不变式是：答案若存在，必落在 [lo, hi) 内。三行代码各守一条：
//   mid = lo + (hi − lo) / 2   —— 防溢出写��，不是 lo + hi
//   a[mid] <  target → lo = mid + 1    —— mid 本身已排除，所以 +1 不是 mid
//   a[mid] >  target → hi = mid        —— 右开，所以 mid 本身就是新边界
// 写成 [lo, hi] 闭区间时两条都要改成 mid±1，是最常见的 off-by-one 源头。
static long long bin_search(std::span<const int> a, int target,
                             long long& steps) {
    std::ptrdiff_t lo = 0;
    std::ptrdiff_t hi = static_cast<std::ptrdiff_t>(a.size());  // 右开
    while (lo < hi) {
        const std::ptrdiff_t mid = lo + (hi - lo) / 2;
        ++steps;
        if (a[static_cast<std::size_t>(mid)] == target) {
            return mid;
        }
        if (a[static_cast<std::size_t>(mid)] < target) {
            lo = mid + 1;      // mid 已排除 → +1（左闭）
        } else {
            hi = mid;          // 右开 → mid 本身（新边界不含 mid）
        }
    }
    return -1;
}

// lower_bound：第一个 >= target 的位置（不存在则返回 size()）。
// 它是「边界二分」的典型写法——循环不设「找到就返回」的出口，
// 而是把区间**缩到一个点**为止。那个点就是答案，天然处理重复元素。
static std::ptrdiff_t lower_bound_idx(std::span<const int> a, int target) {
    std::ptrdiff_t lo = 0;
    std::ptrdiff_t hi = static_cast<std::ptrdiff_t>(a.size());
    while (lo < hi) {
        const std::ptrdiff_t mid = lo + (hi - lo) / 2;
        if (a[static_cast<std::size_t>(mid)] < target) { lo = mid + 1; }
        else { hi = mid; }
    }
    return lo;
}

// upper_bound：第一个 > target 的位置。
static std::ptrdiff_t upper_bound_idx(std::span<const int> a, int target) {
    std::ptrdiff_t lo = 0;
    std::ptrdiff_t hi = static_cast<std::ptrdiff_t>(a.size());
    while (lo < hi) {
        const std::ptrdiff_t mid = lo + (hi - lo) / 2;
        if (a[static_cast<std::size_t>(mid)] <= target) { lo = mid + 1; }
        else { hi = mid; }
    }
    return lo;
}

// 旋转有序数组的最小值：二分查找的「判定条件被旋转打断」版本。
//
// 前提：数组由两段各自递增的区间拼成（旋转点任意），例如
//   [4,5,6,7,0,1,2]  =  [0..7] 旋转而来；  [3,4,5,1,2]  也是。
// 朴素 Θ(n) 扫一遍就够，但我们要 Θ(lg n)——难点在于：**比较结果不再唯一
// 决定方向**。以**右端点**为基准可以破局（每条分支都严格收缩）：
//   a[mid] >  a[hi]  → mid 在旋转点**前**那段，最小值在 (mid, hi] → lo = mid+1
//   a[mid] <  a[hi]  → mid 在旋转点**后**那段（或根本没旋转），
//                      最小值在 [lo, mid]          → hi = mid
//   a[mid] == a[hi]  → 无法判定方向，**收缩右端**（有重复值时才出现）→ hi--
// 第三条分支是防重复值的：没有它，带重复的输入会永远在两个相等的端点间
// 反复横跳。
static int rotated_min(std::span<const int> a, long long& steps) {
    if (a.empty()) { return 0; }               // 鲁棒性：空数组
    std::ptrdiff_t lo = 0;
    std::ptrdiff_t hi = static_cast<std::ptrdiff_t>(a.size()) - 1;
    while (lo < hi) {
        const std::ptrdiff_t mid = lo + (hi - lo) / 2;
        ++steps;
        if (a[static_cast<std::size_t>(mid)] > a[static_cast<std::size_t>(hi)]) {
            lo = mid + 1;      // 严格收缩：lo 一定前进
        } else if (a[static_cast<std::size_t>(mid)] < a[static_cast<std::size_t>(hi)]) {
            hi = mid;          // 严格收缩：hi 一定后退（mid < hi 因 lo<hi）
        } else {
            --hi;              // 相等时无法判方向，只能缩右端
        }
    }
    return a[static_cast<std::size_t>(lo)];
}

static void binary_search_demo() {
    println("");
    println("=== 04.5 二分查找：分治的极端形态 ===");
    const std::vector<int> a{1, 3, 5, 7, 9, 11, 13, 15, 17, 19};
    println("有序数组（10 个元素）：");
    print("  "); for (int v : a) { print("{} ", v); }
    println("");

    // 命中 + 未命中 + 边界
    long long steps = 0;
    const auto i7 = bin_search(a, 7, steps);
    println("查找 7：下标 {}，{} 次比较（⌈lg 10⌉ = {}）", i7, steps, 4);
    assert(i7 == 3);
    steps = 0;
    assert(bin_search(a, 4, steps) == -1);
    println("查找 4（不存在）  ：{} 次比较后区间缩空", steps);
    steps = 0;
    assert(bin_search(a, 1, steps) == 0);
    steps = 0;
    assert(bin_search(a, 19, steps) == 9);
    println("两端命中 1 / 19   ：闭区间端点是最容易漏的边界，都命中");
    steps = 0;
    assert(bin_search(std::span<const int>{}, 5, steps) == -1);
    assert(steps == 0);
    println("空数组            ：0 次比较直接返回 -1（不进入循环）");

    // 与线性查找对比：比较次数
    println("");
    println("与线性查找的比较次数对比（n=1023，固定 42 个查询）：");
    std::vector<int> big(1023);
    for (std::size_t k = 0; k < big.size(); ++k) {
        big[k] = static_cast<int>(2 * k);
    }
    long long bin_total = 0;
    long long lin_total = 0;
    for (int q = 0; q < 42; ++q) {
        long long s = 0;
        const int target = 2 * (q * 24);            // 均匀落在数组内
        (void)bin_search(big, target, s);
        bin_total += s;
        // 线性查找：逐个比较
        for (std::size_t k = 0; k < big.size(); ++k) {
            ++lin_total;
            if (big[k] == target) { break; }
        }
    }
    println("  二分：平均每次 {:.1f} 次；线性：平均每次 {:.1f} 次（比值 {:.0f}×）",
            static_cast<double>(bin_total) / 42.0,
            static_cast<double>(lin_total) / 42.0,
            (static_cast<double>(lin_total) / 42.0) /
            (static_cast<double>(bin_total) / 42.0));
    assert(bin_total < 42 * 11);
    assert(lin_total > 42 * 100);

    // lower_bound / upper_bound：重复元素的区间定位
    println("");
    println("重复元素的区间定位（[2,4,4,4,7,7,9] 找 4）：");
    const std::vector<int> dup{2, 4, 4, 4, 7, 7, 9};
    const auto lb = lower_bound_idx(dup, 4);
    const auto ub = upper_bound_idx(dup, 4);
    print("  数组 "); for (int v : dup) { print("{} ", v); }
    println("");
    println("  lower_bound(4) = {}（第一个 >= 4）  upper_bound(4) = {}（第一个 > 4）",
            lb, ub);
    println("  于是「4 出现的区间」= [{}, {})，出现 {} 次", lb, ub, ub - lb);
    assert(lb == 1 && ub == 4 && ub - lb == 3);
    // 关键性质：lower_bound <= upper_bound 恒成立，target 不存在时二者相等
    assert(lower_bound_idx(dup, 5) == upper_bound_idx(dup, 5));
    println("  target=5（不存在）时 lower == upper = {} → 区间为空，判定「无此元素」",
            lower_bound_idx(dup, 5));
    // 越界目标
    assert(lower_bound_idx(dup, 0) == 0);
    assert(upper_bound_idx(dup, 100) == 7);
    println("  越界：lower_bound(0) = {}（= 0，全在前），upper_bound(100) = {}（= size）",
            lower_bound_idx(dup, 0), upper_bound_idx(dup, 100));
    // 与 STL 对账
    assert(lb == std::lower_bound(dup.begin(), dup.end(), 4) - dup.begin());
    assert(ub == std::upper_bound(dup.begin(), dup.end(), 4) - dup.begin());
    println("  与 std::lower_bound / std::upper_bound 结果一致（示例已断言对账）");

    // 旋转有序数组的最小值
    println("");
    println("旋转有序数组的最小值（Θ(lg n) 而非 Θ(n)）：");
    struct Case { const char* desc; std::vector<int> arr; };
    const Case cases[] = {
        {"[4,5,6,7,0,1,2]（在尾部之后旋转）", {4, 5, 6, 7, 0, 1, 2}},
        {"[3,4,5,1,2]（旋转点在中间）", {3, 4, 5, 1, 2}},
        {"[2,3,4,5]（根本没旋转）", {2, 3, 4, 5}},
        {"[1,2,3]（单元素递增）", {1, 2, 3}},
        {"[2,1]（两元素交换）", {2, 1}},
        {"[1]（单元素）", {1}},
    };
    for (const Case& c : cases) {
        long long s = 0;
        const int got = rotated_min(c.arr, s);
        // 对照组：线性扫描的答案
        const int want = *std::ranges::min_element(c.arr);
        println("  {:<32} 最小值 = {}，{} 次比较（线性扫是 {} 次）",
                c.desc, got, s, c.arr.size());
        assert(got == want);
        assert(s <= static_cast<long long>(c.arr.size()));
    }
    // 带重复值：走「a[mid] == a[hi] → 缩右端」这条分支。
    // 若没有这条分支，两个相等的端点会让区间永远不收缩 → 死循环。
    for (const std::vector<int>& dupCase :
         {std::vector<int>{2, 2, 2, 0, 1}, std::vector<int>{1, 1, 1, 1},
          std::vector<int>{3, 3, 1, 3}, std::vector<int>{1, 3, 3},
          std::vector<int>{5, 5, 5, 1, 5, 5}}) {
        long long s = 0;
        const int got = rotated_min(dupCase, s);
        const int want = *std::ranges::min_element(dupCase);
        print("  带重复值 "); for (int v : dupCase) { print("{} ", v); }
        println("→ 最小值 = {}（期望 {}），{} 次比较", got, want, s);
        assert(got == want);
        assert(s <= static_cast<long long>(dupCase.size()));
    }
    long long s0 = 0;
    assert(rotated_min(std::span<const int>{}, s0) == 0);   // 鲁棒性：空
    assert(s0 == 0);
    println("  空数组：返回 0（调用者须自行约定语义），0 次比较");

    // 为什么不能直接对旋转数组用普通二分？
    // 旋转打断了「比较结果唯一决定方向」：a[mid] < target 时，mid 可能在
    // 前段也可能在后段，无法判断该往哪边缩。示例把「若强行用普通二分会
    // 出错」的最小区间摆出来——那正是旋转点附近的元素。
    println("");
    println("为什么普通二分不能直接用：");
    const std::vector<int> rot{3, 4, 5, 1, 2};
    println("  旋转数组 [3,4,5,1,2] 查 1：");
    print("    "); for (int v : rot) { print("{} ", v); }
    println("");
    long long bad = 0;
    const auto wrong = bin_search(rot, 1, bad);
    println("    普通二分返回 {}（= 未找到），而正确答案在 下标 3；", wrong);
    println("    mid=2 落到 a[2]=5 > 1，区间缩到 [0,2)，真正的答案 1 被排除在外。");
    assert(wrong != 3);
}
// ═══ 04.6 二分答案：把优化问题变成判定问题（分数规划 + 整数化）═══
//
// 问题：n 种设备，每种设备有若干供应商 (带宽 b, 价格 p)。每种设备选一家，
// 选完后 B = 各设备所选带宽的**最小值**，P = 各设备所选价格之**和**。
// 最大化 B/P，答案保留 3 位小数。
//
// 优化问题 max B/P 不能直接二分，但**判定**问题「∃配置使 B/P ≥ r」可以。
// 推导：
//   ① 固定 B 后各设备选择相互独立 ⟹ 各自取满足 b ≥ B 的**最小** p 即得
//      P(B) = Σ_i min{ p : b ≥ B }（某设备无此选项时 P(B) = +∞，不可行）。
//   ② B/P ≥ r ⟺ B ≥ r·P(B) ⟺ ∃B: r·P(B) ≤ B。
//   ③ B 越大 ⟹ 每台设备可选集越小 ⟹ 最小价只增不减 ⟹ P(B) 单调**不减**。
//      于是 f(B) = B/P(B) 单调**不增** ⟹ 「f(B) ≥ r 的 B 集合」是一个前缀
//      ⟹ 判定结果关于 r 单调 ⟹ 可二分。
//
// ★ 本节最值得记住的技巧：**整数化精确舍入**。
//   「保留 3 位小数」若按字面做「浮点二分 60 次 + setprecision(3)」，答案
//   落在 .0005 这类舍入边界附近时最后一位会随浮点表示而漂。
//   正确做法是把不等式**整个整数化**再二分整数 k：
//       判定「∃B 使 B/P ≥ k/1000」 ⟺ ∃B 使 1000·B ≥ k·P(B)。
//   放大 1000 倍后两边全是整数 ⟹ **全程零浮点运算**，浮点误差无处产生。
//   最后的答案 k 拆成 k/1000 与 k%1003 打印即可（补零）。
struct Offer {
    long long b = 0;   // 带宽
    long long p = 0;   // 价格
};
using Device = std::vector<Offer>;   // 一种设备的所有供应商

// 每个设备的「带宽升序 + 后缀最小价」表。
// 给定 B：j = lower_bound(b, B)（第一个 b_j ≥ B 的下标），答案就是
// sufMin[j] = min{ p_i : i ≥ j }。sufMin[m] = INF_P 表示「没有 b ≥ B 的
// 供应商」，即该 B 下这设备不可行。预处理 O(m lg m)，单次查询 O(lg m)。
static constexpr long long INF_P = (1LL << 62);

struct DevPlan {
    std::vector<long long> band;    // 升序带宽
    std::vector<long long> sufMin;  // 后缀最小价，末位 INF_P
    void build(const Device& d) {
        std::vector<std::pair<long long, long long>> a;  // (b, p)
        for (const Offer& o : d) { a.emplace_back(o.b, o.p); }
        // 按 (b, p) 字典序排：先按 b 升序，同 b 内 p 升序（后缀最小价才正确）
        std::ranges::sort(a);
        const std::size_t m = a.size();
        band.resize(m);
        for (std::size_t i = 0; i < m; ++i) { band[i] = a[i].first; }
        sufMin.assign(m + 1, INF_P);
        for (std::size_t i = m; i-- > 0;) {
            sufMin[i] = std::min(sufMin[i + 1], a[i].second);
        }
    }
};

// P(B) = Σ_i sufMin_i[lower_bound(band_i, B)]；任一设备不可行则返回 INF_P。
// 注意 P(B) 随 B **单调不减**——这是判定可二分的唯一依据。
static long long total_price(const std::vector<DevPlan>& plans, long long B) {
    long long sum = 0;
    for (const DevPlan& dp : plans) {
        const auto it = std::ranges::lower_bound(dp.band, B);
        if (it == dp.band.end()) { return INF_P; }   // 该设备无 b ≥ B 的供应商
        sum += dp.sufMin[static_cast<std::size_t>(it - dp.band.begin())];
        if (sum >= INF_P) { return INF_P; }
    }
    return sum;
}

// 候选带宽集 = 所有设备全部带宽去重升序。
// 「最优 B 必落在候选集上」：否则可提到下一个候选值而 P(B) 不变、比值变大。
static std::vector<long long> collect_bands(const std::vector<DevPlan>& plans) {
    std::vector<long long> all;
    for (const DevPlan& dp : plans) {
        for (long long v : dp.band) { all.push_back(v); }
    }
    std::ranges::sort(all);
    all.erase(std::ranges::unique(all).begin(), all.end());
    return all;
}

// ★ 整数化判定：「∃B 使 B/P ≥ k/1000」 ⟺ ∃B 使 k·P(B) ≤ 1000·B。
// 交叉相乘把除法消掉：两边都是整数，乘法在 long long 内（k ≤ 2^40、
// P(B) ≤ 10^6 量级）。返回该 k 是否可行。
static bool feasible_int(const std::vector<DevPlan>& plans,
                         const std::vector<long long>& bands, long long k) {
    for (long long B : bands) {
        const long long P = total_price(plans, B);
        if (P >= INF_P) { continue; }
        if (k * P <= 1000LL * B) { return true; }   // 全整数，无浮点
    }
    return false;
}

// 二分最大的可行 k（= floor(1000 × max B/P)）。判定对 k 单调：
// k 越大越难成立 ⟹ 标准左闭右开二分。k = 0 恒可行（0 ≤ 一切）。
static long long bisect_scaled(const std::vector<DevPlan>& plans,
                               const std::vector<long long>& bands) {
    long long lo = 0, hi = 1;
    while (feasible_int(plans, bands, hi)) { lo = hi; hi *= 2; }  // 倍增找上界
    while (hi - lo > 1) {
        const long long mid = lo + (hi - lo) / 2;
        if (feasible_int(plans, bands, mid)) { lo = mid; } else { hi = mid; }
    }
    return lo;
}

// 浮点版判定（对照组）：直接对 r 做「∃B 使 B/P ≥ r」的浮点比较。
// 这是「不整数化」的写法——精度够高，但它**给不出**「截断到 3 位」的确定
// 答案，只能靠 setprecision 去猜；在 .0005 这类边界上最后一位会漂。
static bool feasible_r(const std::vector<DevPlan>& plans,
                       const std::vector<long long>& bands, double r) {
    for (long long B : bands) {
        const long long P = total_price(plans, B);
        if (P >= INF_P) { continue; }
        if (static_cast<double>(B) / static_cast<double>(P) >= r) { return true; }
    }
    return false;
}

// 把 k 拆成「整数部分.三位小数」打印（补零），k = floor(1000 × 答案)。
static std::string scaled_string(long long k) {
    std::string frac = std::to_string(k % 1000);
    while (frac.size() < 3) { frac.insert(frac.begin(), '0'); }
    return std::to_string(k / 1000) + "." + frac;
}

static void fractional_bisect_demo() {
    println("");
    println("=== 04.6 二分答案：分数规划 + 整数化精确舍入 ===");
    const std::vector<Device> dev{
        {{100, 10}, {200, 12}, {400, 20}},   // 设备 1
        {{150, 8},  {300, 15}},              // 设备 2
        {{120, 9},  {250, 14}, {500, 30}},   // 设备 3
    };
    println("设备报价（带宽, 价格）：");
    for (std::size_t i = 0; i < dev.size(); ++i) {
        print("  设备{}: ", i + 1);
        for (const Offer& o : dev[i]) { print("({},{}) ", o.b, o.p); }
        println("");
    }
    std::vector<DevPlan> plans(dev.size());
    for (std::size_t i = 0; i < dev.size(); ++i) { plans[i].build(dev[i]); }
    const std::vector<long long> bands = collect_bands(plans);
    print("候选带宽（全部带宽去重升序）: ");
    for (long long v : bands) { print("{} ", v); }
    println("");

    // 把「P(B) 单调不减 ⟹ f 单调不增」摆成一张表——这是判定可二分的根据。
    println("");
    println("  {:<6} {:<8} {:<12} {}","  B", "P(B)", "B/P(B)",
            "floor(1000·f) 与整数化复核");
    long long bestB = 0, bestP = 1, bestKdirect = 0;
    for (long long B : bands) {
        const long long P = total_price(plans, B);
        if (P >= INF_P) {
            println("  {:<6} 不存在（某设备无 b ≥ {} 的供应商）", B, B);
            continue;
        }
        const double f = static_cast<double>(B) / static_cast<double>(P);
        // 直接按定义算 floor(1000·B/P)——纯整数除法，与二分结果对账用
        const long long kdirect = 1000LL * B / P;
        // 用整数化的判定复核：kdirect 可行、kdirect+1 不可行（对该 B 而言）
        const std::vector<long long> one{B};
        const bool kOk = feasible_int(plans, one, kdirect);
        const bool k1Bad = !feasible_int(plans, one, kdirect + 1);
        println("  {:<6} {:<8} {:<12.6f} {:>6}  可行={} / +1 不可行={}",
                B, P, f, kdirect, kOk, k1Bad);
        assert(kOk && k1Bad);
        // 全局最优：仍用交叉相乘比分数，不碰浮点。
        // 本例数据量级小（B、P ≤ 数千，乘积 ≤ 1e7），long long 直接乘安全；
        // 量级大到 b1·p2 会溢出时怎么办，见下方「溢出边界」演示。
        if (bestB == 0 || B * bestP > bestB * P) {
            bestB = B; bestP = P; bestKdirect = kdirect;
        }
    }
    println("  最优：B={}，P={}，B/P = {:.6f}（逐项比较用交叉相乘 b1*p2 > b2*p1）",
            bestB, bestP, static_cast<double>(bestB) / static_cast<double>(bestP));
    println("  P(B) 随 B 单调不减（{} → {}），f(B) 却在 B={} 之后开始下降——",
            total_price(plans, bands.front()), total_price(plans, bands[4]), bestB);
    println("  这正是「f ≥ r 的 B 构成前缀」的可二分结构。");

    // ★ 整数化二分 vs 直接定义 vs 浮点二分，三方对账
    const long long kInt = bisect_scaled(plans, bands);
    println("");
    println("三方对账（同一份数据）：");
    println("  直接定义 ⌊1000·B/P⌋                = {}", bestKdirect);
    println("  整数化二分得到的 k                 = {}", kInt);
    println("  输出 k/1000 与 k%1000（补零）      = {}", scaled_string(kInt));
    assert(kInt == bestKdirect);
    assert(scaled_string(kInt) == "5.102");
    // 浮点二分 60 次对照（直接对 r 二分，不整数化）
    double flo = 0.0, fhi = 1e9;
    for (int it = 0; it < 60; ++it) {
        const double mid = (flo + fhi) / 2.0;
        if (feasible_r(plans, bands, mid)) { flo = mid; } else { fhi = mid; }
    }
    const double fmax = static_cast<double>(bestB) / static_cast<double>(bestP);
    println("  浮点二分 60 次收敛到 r             = {:.9}", flo);
    println("  真实 max B/P                       = {:.9}", fmax);
    println("  两者之差 < 1e-9                    = {}", fmax - flo < 1e-9);
    println("  ⟹ 浮点法**精度够**，但它给不出「截断到 3 位」的确定答案——");
    println("     只能靠 setprecision 去猜，答案落在舍入边界上时最后一位会漂。");

    // ★ 整数化真正赢过浮点的地方：答案恰落在舍入边界上。
    // 构造 max B/P = 1/2000 = 0.0005 的实例：单设备，带宽 1、价格 2000。
    // 「截断到 3 位」的确定答案是 floor(1000 × 0.0005) = floor(0.5) = 0 → 0.000。
    // 注意 0.0005 在二进制里**不可精确表示**（0.0005 = 1/2000，2000 = 2^4·125），
    // 所以浮点路径根本没有办法「恰好」落在这个值上——它只能给一个近似数，
    // 再交给 setprecision 去猜最后一位。整数化则给出一个可证明的确定结论。
    {
        std::vector<DevPlan> tiny(1);
        tiny[0].build({{1, 2000}});
        const std::vector<long long> tb{1};
        const long long k = bisect_scaled(tiny, tb);
        println("");
        println("边界实例（单设备：带宽 1、价格 2000 ⟹ B/P = 1/2000 = 0.0005）：");
        println("  整数化二分：k = {} ⟹ 输出 {}（截断到 3 位的**确定**答案）",
                k, scaled_string(k));
        println("  「k=1 可行吗」这个问题整数化回答得很干脆：");
        println("    1000·B = 1000·{} = {}  vs  k·P(B) = 1·{} = {} ⟹ {} ⟹ 不可行",
                1, 1000LL * 1, 2000, 1LL * 2000,
                1000LL * 1 < 1LL * 2000 ? "1000 < 2000" : "1000 ≥ 2000");
        println("  浮点路径在同一处：0.0005 的 double 表示是 {:.20f}，",
                1.0 / 2000.0);
        println("  它既不等于精确的 1/2000，也无法告诉你输出该是 0.000 还是 0.001。");
        assert(k == 0);
        assert(!feasible_int(tiny, tb, 1));
        assert(1000LL * 1 < 1LL * 2000);
        // 浮点对照：k=0 时可行，k=1 时（r=0.001）不可行——本例浮点恰好与
        // 整数化同侧，但它给出的**不是**「截断到 3 位」的语义，只是近似比较。
        assert(feasible_r(tiny, tb, 0.0));
        assert(!feasible_r(tiny, tb, 1.0 / 1000.0));
    }

    // ★ 分数比较不要用浮点直接比，用交叉相乘。
    // 构造：b1/p1 与 b2/p2 的 double 商**完全相等**（浮点分不出大小），
    // 但交叉相乘 b1*p2 > b2*p1 严格成立——真值是 b1/p1 略大。
    {
        const long long b1 = 100000001LL, p1 = 100000000LL;
        const long long b2 = 100000002LL, p2 = 100000001LL;
        const double r1 = static_cast<double>(b1) / static_cast<double>(p1);
        const double r2 = static_cast<double>(b2) / static_cast<double>(p2);
        const bool byFloat = r1 > r2;
        const bool byCross = b1 * p2 > b2 * p1;
        println("");
        println("分数比较（不要用浮点直接比，用交叉相乘 b1*p2 > b2*p1）：");
        println("  b1/p1 = {}/{} = {:.17g}", b1, p1, r1);
        println("  b2/p2 = {}/{} = {:.17g}", b2, p2, r2);
        println("  浮点直接比 b1/p1 > b2/p2 = {}（**错**：两个 double 完全相等，判不出大小）",
                byFloat);
        println("  交叉相乘 b1*p2 > b2*p1 = {}（对：{} > {}，差 {}）", byCross,
                b1 * p2, b2 * p1, b1 * p2 - b2 * p1);
        println("  真值：{}/{} 与{}/{} 只差 1 个交叉乘积单位，而 double 的",
                b1, p1, b2, p2);
        println("  53 位尾数根本表达不出这个差别（相对差 ≈ 1e-16，double 的 eps 量级内）。");
        assert(!byFloat);
        assert(byCross);
    }

    // 溢出边界：整数化消除了浮点误差，但**没消除整数溢出**。
    // 判定式 k·P(B) ≤ 1000·B 的右端 1000·B 在 B ~ 1e16 时就吃掉 int64
    // （上限 9.22e18）。注意：**不能**先用 long long 算 1000·B 再比较——
    // 那是带符号溢出（UB），两通道会给出不同的垃圾值。三档安全写法：
    //   (a) 升宽类型：GCC/Clang 有 __int128，**MSVC 没有**——宽类型不是
    //       可移植假设，主通道是 MSVC 的工程只能靠 (b) 或 (c)；
    //   (b) 「除后比」：k·P ≤ 1000·B ⟺ k ≤ ⌊1000·B/P⌋（k、P > 0）；
    //   (c) 升 unsigned：uint64 上限 1.84e19，是 int64 的两倍——本例两个
    //       乘积恰好落在 (9.22e18, 1.84e19) 之间，signed 炸、unsigned 够。
    //       这是侥幸不是通解：B 再翻倍 unsigned 也炸，那时只剩 (b)。
    {
        const long long B = 10000000000000000LL;   // 带宽 1e16
        const long long P = 3;                      // 价格和很小
        println("");
        println("溢出边界（整数化消除了浮点误差，但没消除整数溢出）：");
        println("  B = 1e16、P(B) = {} ⟹ 判定右端 1000·B = {:.4g}",
                P, static_cast<double>(B) * 1000.0);
        println("  已超 int64 上限 9.22e18 ⟹ 在 long long 里算 1000·B 就是 UB。");
        // (b) 除后比：先除后乘，全程 long long 无溢出
        //     ⌊1000·B/P⌋ = (B/P)·1000 + ⌊(B mod P)·1000/P⌋
        const long long q = B / P;
        const long long r = B % P;
        const long long kSafe = q * 1000 + (r * 1000) / P;   // 全程不溢出
        println("  (b) 除后比（先除后乘，全程 long long 无溢出）：");
        println("      ⌊1000·B/P⌋ = (B/P)·1000 + ⌊(B mod P)·1000/P⌋");
        println("                 = {}·1000 + {} = {}",
                q, (r * 1000) / P, kSafe);
        // (c) 升 unsigned 独立复核判定式：k·P = 9999999999999999999 与
        //     1000·B = 10000000000000000000 都在 (9.22e18, 1.84e19) 区间，
        //     unsigned long long 装得下，乘法本身无回绕，比较是精确的。
        const std::uint64_t lhs = static_cast<std::uint64_t>(kSafe) *
                                  static_cast<std::uint64_t>(P);
        const std::uint64_t rhs = static_cast<std::uint64_t>(B) * 1000ull;
        println("  (c) 升 unsigned 复核：k·P = {} ，1000·B = {}", lhs, rhs);
        println("      两个乘积都落在 (int64 上限 9.22e18, uint64 上限 1.84e19)");
        println("      区间里 ⟹ signed 通道必炸、unsigned 恰好够 ⟹ k·P ≤ 1000·B = {}",
                lhs <= rhs);
        // 边界再验：(k+1)·P = 10000000000000000002 仍 < 2⁶⁴ ⟹ 比较仍精确
        const std::uint64_t lhs1 = static_cast<std::uint64_t>(kSafe + 1) *
                                   static_cast<std::uint64_t>(P);
        println("      换 (k+1)·P = {} ⟹ (k+1)·P > 1000·B = {}",
                lhs1, lhs1 > rhs);
        println("  ⟹ unsigned 只是**碰巧**多扛一倍量级，不是通用答案；");
        println("     通用兜底是 (b)——把乘法换成除法与取模，永不溢出。");
        println("  (a) 若坚持升宽类型：那是 GCC/Clang 的 __int128，MSVC 没有——");
        println("      跨通道工程里宽类型是**坑**。");
        assert(lhs <= rhs);
        assert(lhs1 > rhs);
        assert(q * 1000 + (r * 1000) / P == kSafe);
    }
}

// ═══ 04.7 逆序数：归并排序的副产物 ═══
// 逆序对 = i<j 且 a[i]>a[j]。暴力双重循环 O(n²)；分治视角：归并两个有序
// 子段时，每当**右段**元素 x 出列，左段还没出列的每个元素都比 x 大——
// 贡献 mid−i。排序与计数一趟完成，总代价 O(n lg n)。
template <class T>
static void inversion_merge(std::span<T> a, std::span<T> buf, long long& inv) {
    if (a.size() < 2) { return; }
    const std::size_t mid = a.size() / 2;
    inversion_merge(a.first(mid), buf.first(mid), inv);
    inversion_merge(a.subspan(mid), buf.subspan(mid), inv);
    std::copy(a.begin(), a.end(), buf.begin());
    std::size_t i = 0, j = mid, k = 0;
    while (i < mid && j < a.size()) {
        if (buf[i] <= buf[j]) {            // ≤：相等元素不算逆序
            a[k++] = buf[i++];
        } else {
            a[k++] = buf[j++];
            inv += static_cast<long long>(mid - i);
        }
    }
    while (i < mid)      { a[k++] = buf[i++]; }
    while (j < a.size()) { a[k++] = buf[j++]; }
}

template <class T>
static long long inversion_count(const std::vector<T>& input) {
    std::vector<T> a = input, buf(a.size());
    long long inv = 0;
    inversion_merge(std::span<T>(a), std::span<T>(buf), inv);
    assert(std::ranges::is_sorted(a));
    return inv;
}

// 字母表只有 4 个符号时的 O(n) 扫一遍：各计数器记住「之前有几个 C/G/T」，
// 读到 A/C/G 时直接查表累加。这是线性时间，但依赖字母表小且已知。
static long long dna_inversions_linear(std::string_view s) {
    long long count = 0, cc = 0, cg = 0, ct = 0;
    for (char ch : s) {
        if (ch == 'A') {
            count += cc + cg + ct;
        } else if (ch == 'C') {
            count += cg + ct;
            ++cc;
        } else if (ch == 'G') {
            count += ct;
            ++cg;
        } else {
            ++ct;
        }
    }
    return count;
}

static long long inversions_brute(std::string_view s) {
    long long c = 0;
    for (std::size_t i = 0; i < s.size(); ++i) {
        for (std::size_t j = i + 1; j < s.size(); ++j) { c += s[i] > s[j]; }
    }
    return c;
}

static void dna_sort_demo() {
    println("DNA 排序（2-7）：按逆序数升序排列串：");
    const std::vector<std::string> dnas{
        "AACATGAAGG", "TTTTGGCCAA", "TTTGGCCAAA", "GATCAGATTT",
        "CCCGGGGGGA", "ATCGATGCAT"};
    struct Item { std::string s; long long inv; std::size_t idx; };
    std::vector<Item> items;
    for (std::size_t i = 0; i < dnas.size(); ++i) {
        std::vector<char> cv(dnas[i].begin(), dnas[i].end());
        const long long inv = inversion_count(cv);
        // 三种口径必须一致：分治归并 / 字母计数 / 暴力
        assert(inv == dna_inversions_linear(dnas[i]));
        assert(inv == inversions_brute(dnas[i]));
        items.push_back({dnas[i], inv, i});
    }
    std::ranges::sort(items, [](const Item& a, const Item& b) {
        return a.inv != b.inv ? a.inv < b.inv : a.idx < b.idx;
    });
    for (const Item& it : items) {
        println("  逆序 {:2}：{}", it.inv, it.s);
    }
    // 逆序数序列与排序后的串顺序
    const std::vector<long long> ordered{9, 10, 11, 17, 36, 37};
    std::vector<long long> got;
    for (const Item& it : items) { got.push_back(it.inv); }
    assert(got == ordered);
    assert(items[0].s == "CCCGGGGGGA" && items[5].s == "TTTGGCCAAA");

    // 随机 DNA 串：三种口径对账
    std::mt19937 rng{5489};
    static const char letters[] = "ACGT";
    int mismatches = 0;
    for (int t = 0; t < 2000; ++t) {
        const std::size_t n = 1 + rand_below(rng, 30);
        std::string s;
        for (std::size_t i = 0; i < n; ++i) {
            s.push_back(letters[rand_below(rng, 4)]);
        }
        std::vector<char> cv(s.begin(), s.end());
        if (inversion_count(cv) != inversions_brute(s) ||
            dna_inversions_linear(s) != inversions_brute(s)) { ++mismatches; }
    }
    println("  随机 {} 个 DNA 串三口径对账：不一致 {}", 2000, mismatches);
    assert(mismatches == 0);
}

// ═══ 04.8 汉诺塔：递归与非递归（观察小例得到规律）═══
// 三根柱 0（起点）、1（中转）、2（目标），n 个盘子从小到大编号 1..n。
// 规则：一次搬一个；只能动柱顶；大盘不能压小盘。目标是把整塔从 0 移到 2。
struct HanoiMove { int disk; int from; int to; };

static bool operator==(const HanoiMove& a, const HanoiMove& b) {
    return a.disk == b.disk && a.from == b.from && a.to == b.to;
}

// 递归：把 n 个盘 from→to（via 中转）。先把上面 n−1 个移到 via，再搬最大的，
// 最后把 n−1 个从 via 移到 to。搬运次数 T(n)=2T(n−1)+1，T(0)=0 ⟹ T(n)=2ⁿ−1。
static void hanoi_rec(int n, int from, int via, int to,
                      std::vector<HanoiMove>& moves) {
    if (n == 0) { return; }
    hanoi_rec(n - 1, from, to, via, moves);
    moves.push_back({n, from, to});
    hanoi_rec(n - 1, via, from, to, moves);
}

// 非递归。观察 3、4 个盘子的完整搬运记录可得两条规律：
//  规律一（搬谁）：第 i 步搬的盘子号 = i 中因子 2 的最高幂次 +1，即
//      i = 2ᵏ·奇数 ⟹ 搬 k+1 号盘。换句话说 1 号盘隔 1 步动一次，2 号盘隔
//      3 步（每 4 步）动一次，3 号盘每 8 步动一次……
//  规律二（方向）：每个盘子沿一根固定的三柱循环移动。n+d 为偶数时
//      0→2→1→0；n+d 为奇数时 0→1→2→0。奇号盘与偶号盘方向相反；n 的奇偶
//      翻转会把所有盘子的方向整体翻转（与小例记录一致）。
static std::vector<HanoiMove> hanoi_iter(int n) {
    std::vector<HanoiMove> moves;
    moves.reserve(static_cast<std::size_t>((1LL << n) - 1));
    std::vector<int> pos(n + 1, 0);       // pos[d]：d 号盘当前所在柱
    // peg_stack[p]：p 柱上的盘子，back() 为柱顶；初始时 n..1 全在 0 号柱。
    std::vector<std::vector<int>> peg_stack(3);
    for (int d = n; d >= 1; --d) { peg_stack[0].push_back(d); }
    const long long total = (1LL << n) - 1;
    for (long long step = 1; step <= total; ++step) {
        // countr_zero：step 末尾 0 的个数 = 因子 2 的幂次
        const int d = std::countr_zero(static_cast<std::uint64_t>(step)) + 1;
        const int from = pos[d];
        int to;
        if ((n + d) % 2 == 0) {           // 循环 0→2→1→0
            to = from == 0 ? 2 : from == 2 ? 1 : 0;
        } else {                          // 循环 0→1→2→0
            to = from == 2 ? 0 : from + 1;
        }
        // 合法性自检：d 必须是出发柱柱顶；目标柱为空或柱顶盘更大。
        assert(peg_stack[from].back() == d);
        assert(peg_stack[to].empty() || peg_stack[to].back() > d);
        peg_stack[from].pop_back();
        pos[d] = to;
        peg_stack[to].push_back(d);
        moves.push_back({d, from, to});
    }
    return moves;
}

static void hanoi_demo() {
    println("=== 04.8 汉诺塔：递归与非递归（2ⁿ−1 次搬动）===");
    // 小例：3 个盘子，打印全部 7 步，逐步验证合法性
    std::vector<HanoiMove> rec3;
    hanoi_rec(3, 0, 1, 2, rec3);
    const std::vector<HanoiMove> iter3 = hanoi_iter(3);
    println("  3 个盘子（递归给出的全部 {} 步）：", rec3.size());
    static const char peg_name[] = {'A', 'B', 'C'};
    for (std::size_t i = 0; i < rec3.size(); ++i) {
        const HanoiMove& m = rec3[i];
        println("    步{}：{} 号盘 {}→{}", i + 1, m.disk,
                peg_name[m.from], peg_name[m.to]);
        assert(rec3[i].disk == iter3[i].disk);
        assert(rec3[i].from == iter3[i].from);
        assert(rec3[i].to == iter3[i].to);
    }
    // n=1..16：递归与非递归逐步完全一致；步数恰为 2ⁿ−1
    int mismatches = 0;
    for (int n = 1; n <= 16; ++n) {
        std::vector<HanoiMove> r;
        hanoi_rec(n, 0, 1, 2, r);
        const std::vector<HanoiMove> it = hanoi_iter(n);
        if (r != it || static_cast<long long>(r.size()) != (1LL << n) - 1) {
            ++mismatches;
        }
    }
    println("  n=1..16：递归 vs 非递归逐步不一致 {} 例；步数均为 2ⁿ−1", mismatches);
    // 大例：n=24 只生成非递归序列（1677 万步），核对首步、末步与步数
    const int big = 24;
    const std::vector<HanoiMove> big_moves = hanoi_iter(big);
    println("  大例 n={}：共 {} 步；首步 {} 号盘 {}→{}，末步 {} 号盘 {}→{}",
            big, big_moves.size(),
            big_moves.front().disk, peg_name[big_moves.front().from],
            peg_name[big_moves.front().to],
            big_moves.back().disk, peg_name[big_moves.back().from],
            peg_name[big_moves.back().to]);
    assert(mismatches == 0);
    assert(big_moves.size() == static_cast<std::size_t>((1LL << big) - 1));
    assert(big_moves.front().disk == 1 && big_moves.front().from == 0);
    assert(big_moves.back().disk == 1 && big_moves.back().to == 2);
}

// ═══ 04.9 二维极点：分治法 ═══
// 点 p 支配 q ⟺ p.x>q.x 且 p.y>q.y（严格大于）。极点 = 没有被任何点支配的点，
// 即右上方没有点的点。注意定义严格：坐标相同的两个点互不支配。
struct MaxPoint { int x, y; };

static bool operator==(const MaxPoint& a, const MaxPoint& b) {
    return a.x == b.x && a.y == b.y;
}

// 暴力：每对点比一次，O(n²)。小实例的真值来源。
static std::vector<MaxPoint> maxima_brute(const std::vector<MaxPoint>& pts) {
    std::vector<MaxPoint> out;
    for (const MaxPoint& p : pts) {
        bool dominated = false;
        for (const MaxPoint& q : pts) {
            if (q.x > p.x && q.y > p.y) { dominated = true; break; }
        }
        if (!dominated) { out.push_back(p); }
    }
    std::ranges::sort(out, {}, [](const MaxPoint& p) {
        return static_cast<long long>(p.x) * 100000 + p.y; });
    return out;
}

// 分治：pts 已按 x 升序（允许相等）。从中间竖切，左右各递归求极点。
// 合并：右侧任何点的 x 都 ≥ 左侧点的 x，所以一个左侧极点被淘汰 ⟺ 存在右侧
// 点 y 比它高（取等不支配，保留）。右侧全体最大高度 h = 右侧极点的最大 y
// （全局最高的点不可能被支配），于是左侧极点里 y ≥ h 的全部保留。
static std::vector<MaxPoint> maxima_dc_rec(const std::vector<MaxPoint>& pts,
                                           std::size_t lo, std::size_t hi) {
    if (hi - lo == 1) { return {pts[lo]}; }
    // 整段 x 相同：点之间互不支配，全部是本段子问题的极点。
    if (pts[lo].x == pts[hi - 1].x) {
        return std::vector<MaxPoint>(pts.begin() + static_cast<std::ptrdiff_t>(lo),
                                     pts.begin() + static_cast<std::ptrdiff_t>(hi));
    }
    // 切分点必须落在 x 组的边界上：把 mid 推到与其左侧点 x 相等的整组之后，
    // 否则同 x 的两个点分居两侧时，左点会被「同 x 但更高 y」的右点误淘汰
    // （同 x 根本不构成支配）。
    std::size_t mid = lo + (hi - lo) / 2;
    while (mid < hi && pts[mid - 1].x == pts[mid].x) { ++mid; }
    if (mid == hi) {                 // 后缀全是同一 x 组：改向左找边界
        mid = lo + (hi - lo) / 2;
        while (mid > lo && pts[mid - 1].x == pts[mid].x) { --mid; }
    }
    std::vector<MaxPoint> left = maxima_dc_rec(pts, lo, mid);
    std::vector<MaxPoint> right = maxima_dc_rec(pts, mid, hi);
    int h = std::numeric_limits<int>::min();
    for (const MaxPoint& p : right) { h = std::max(h, p.y); }
    std::vector<MaxPoint> merged = std::move(right);
    for (const MaxPoint& p : left) {
        if (p.y >= h) { merged.push_back(p); }
    }
    return merged;
}

static std::vector<MaxPoint> maxima_divide_conquer(std::vector<MaxPoint> pts) {
    std::ranges::sort(pts, {}, &MaxPoint::x);
    std::vector<MaxPoint> out = maxima_dc_rec(pts, 0, pts.size());
    std::ranges::sort(out, {}, [](const MaxPoint& p) {
        return static_cast<long long>(p.x) * 100000 + p.y; });
    return out;
}

// 第三种口径（扫描法，同 O(n lg n)）：x 降序扫，维护「已扫描点」（严格更靠右）
// 的最高 y；当前点 y ≥ 该高度就是极点。x 相等的点要成组处理，因为同组点互不
// 支配，组内的高点不能用来淘汰组内的低点。
static std::vector<MaxPoint> maxima_sweep(std::vector<MaxPoint> pts) {
    std::ranges::sort(pts, std::ranges::greater{}, &MaxPoint::x);
    std::vector<MaxPoint> out;
    int best = std::numeric_limits<int>::min();
    for (std::size_t i = 0; i < pts.size();) {
        std::size_t j = i;
        int group_best = best;
        while (j < pts.size() && pts[j].x == pts[i].x) {
            if (pts[j].y >= best) { out.push_back(pts[j]); }
            group_best = std::max(group_best, pts[j].y);
            ++j;
        }
        best = group_best;
        i = j;
    }
    std::ranges::sort(out, {}, [](const MaxPoint& p) {
        return static_cast<long long>(p.x) * 100000 + p.y; });
    return out;
}

static void maxima_demo() {
    println("=== 04.9 二维极点：分治合并（右侧最高 h 淘汰左侧）===");
    const std::vector<MaxPoint> pts{
        {2, 1}, {4, 3}, {4, 7}, {6, 4}, {8, 2},
        {9, 9}, {10, 6}, {12, 1}, {15, 7}, {15, 10}};
    const std::vector<MaxPoint> truth = maxima_brute(pts);
    const std::vector<MaxPoint> dc = maxima_divide_conquer(pts);
    const std::vector<MaxPoint> sw = maxima_sweep(pts);
    println("  共 {} 个点，极点 {} 个：", pts.size(), truth.size());
    for (const MaxPoint& p : truth) { print(" ({},{})", p.x, p.y); }
    println("");
    // 三种口径一致；并核对「极点的右上方确实没有点」
    assert(dc == truth && sw == truth);
    for (const MaxPoint& p : truth) {
        for (const MaxPoint& q : pts) {
            assert(!(q.x > p.x && q.y > p.y));
        }
    }
    // 随机 3000 例（n≤14，坐标 0..7，允许重复）：三口径对账
    std::mt19937 rng{5489};
    int mismatches = 0;
    for (int t = 0; t < 3000; ++t) {
        const int n = 1 + rand_below(rng, 14);
        std::vector<MaxPoint> r;
        r.reserve(n);
        for (int i = 0; i < n; ++i) {
            r.push_back({static_cast<int>(rand_below(rng, 8)),
                         static_cast<int>(rand_below(rng, 8))});
        }
        if (maxima_brute(r) != maxima_divide_conquer(r) ||
            maxima_brute(r) != maxima_sweep(r)) { ++mismatches; }
    }
    println("  随机 {} 例（坐标 0..7，允许重复）：暴力/分治/扫描 不一致 {} 例",
            3000, mismatches);
    // 大例：10 万个点，分治与扫描一致（暴力 O(n²) 不再参与）
    std::vector<MaxPoint> big;
    big.reserve(100000);
    for (int i = 0; i < 100000; ++i) {
        big.push_back({static_cast<int>(rand_below(rng, 1000000)),
                       static_cast<int>(rand_below(rng, 1000000))});
    }
    const std::vector<MaxPoint> big_dc = maxima_divide_conquer(big);
    const std::vector<MaxPoint> big_sw = maxima_sweep(big);
    println("  大例（10 万点）：极点 {} 个；分治 vs 扫描一致 = {}",
            big_dc.size(), big_dc == big_sw);
    assert(mismatches == 0);
    assert(big_dc == big_sw);
}

// ═══ 04.10 约瑟夫问题：删半归约与二进制循环左移 ═══
// n 个人顺时针围坐，编号 1..n；从 1 号开始报数，数到 2 的人出局，下一个人
// 重新从 1 报起，直到剩下一人。J(n) = 最后存活者的编号。
// 模拟真值：每轮扫描找下一名存活者，O(n²)，只用于小 n 对账。
static int josephus_sim(int n) {
    std::vector<char> alive(n + 1, 1);
    int count = n, cur = 1;
    while (count > 1) {
        // cur 报 1：找到下一个存活者报 2、出局
        do { cur = cur == n ? 1 : cur + 1; } while (!alive[cur]);
        alive[cur] = 0;
        --count;
        if (count == 1) { break; }
        do { cur = cur == n ? 1 : cur + 1; } while (!alive[cur]);
    }
    for (int i = 1; i <= n; ++i) { if (alive[i]) { return i; } }
    return -1;
}

// 递推（第一圈偶数号全部出局）：
//   n=2k：剩 1,3,...,2k−1 共 k 人，重新编号 i ↔ 旧号 2i−1
//         J(2k) = 2J(k) − 1
//   n=2k+1：偶数号出局后，编号 1 在新一轮第一个报 2 也出局，剩下
//         3,5,...,2k+1 共 k 人，新编号 i ↔ 旧号 2i+1
//         J(2k+1) = 2J(k) + 1
// 基例 J(1) = 1。
static int josephus_rec(int n) {
    if (n == 1) { return 1; }
    const int sub = josephus_rec(n / 2);
    return n % 2 == 0 ? 2 * sub - 1 : 2 * sub + 1;
}

// 位运算直接式：n = 2ᵐ + l（0 ≤ l < 2ᵐ）时 J(n) = 2l + 1。
// 即把 n 的二进制最高位的 1 移到最右边（其余位整体左移一格）。
static long long josephus_bit(long long n) {
    const int msb = 63 - std::countl_zero(static_cast<std::uint64_t>(n));
    const long long l = n - (1LL << msb);
    return 2 * l + 1;
}

static void josephus_demo() {
    println("=== 04.10 约瑟夫问题：删半递推 / 二进制循环左移 ===");
    // 小例表 n=1..16：三种口径一致；观察 1,2,4,8,16 时 J=1
    print("  n:  ");
    for (int n = 1; n <= 16; ++n) { print("{:3}", n); }
    println("");
    print("  J:  ");
    for (int n = 1; n <= 16; ++n) {
        const int j = josephus_rec(n);
        assert(j == josephus_sim(n));
        assert(j == josephus_bit(n));
        print("{:3}", j);
    }
    println("");
    // n=1..200000：递推 vs 位式一致（模拟 O(n²) 退场）
    int mismatches = 0;
    for (int n = 1; n <= 200000; ++n) {
        if (josephus_rec(n) != josephus_bit(n)) { ++mismatches; }
    }
    println("  n=1..200000：递推 vs 位式不一致 {} 例", mismatches);
    // 大例（位式 O(1)，递推的 O(log n) 递归深度也够）：
    //   2⁴⁰ ⟹ J=1；10¹⁸ 与 (2⁵⁹+2026) 给出公式 2l+1
    const long long n1 = 1LL << 40;
    const long long n2 = 1000000000000000000LL;
    const long long n3 = (1LL << 59) + 2026;
    println("  大例：J(2⁴⁰) = {}；J(10¹⁸) = {}；J(2⁵⁹+2026) = {}（=2×2026+1）",
            josephus_bit(n1), josephus_bit(n2), josephus_bit(n3));
    assert(mismatches == 0);
    assert(josephus_bit(n1) == 1);
    assert(josephus_bit(n3) == 4053);
}

// ═══ 04.11 好人坏人约瑟夫：搜索步长 m ═══
// 2n 人围圈（0..n−1 好人，n..2n−1 坏人），从 0 起报数到 m 者出列、
// 从下一人重新报 1。找最小 m 使**前 n 次出列全是坏人**。
// 剪枝：出列者的下标 pos = (上一出列位置 + m − 1) % 存活数——
// 每一步都要求 pos ≥ n（落在坏人段）。存活表用 vector 模拟删除。
static int josephus_bad_first_m(int n) {
    for (int m = n + 1;; ++m) {              // m ≤ n 时首个出列必是好人
        std::vector<int> alive(2 * n);
        for (int i = 0; i < 2 * n; ++i) { alive[static_cast<std::size_t>(i)] = i; }
        int pos = 0;                          // 从 alive[0] 起报 1
        bool ok = true;
        for (int step = 0; step < n && ok; ++step) {
            pos = (pos + m - 1) % static_cast<int>(alive.size());
            if (alive[static_cast<std::size_t>(pos)] < n) { ok = false; break; }
            alive.erase(alive.begin() + pos);
        }
        if (ok) { return m; }
    }
}

static void josephus_variant_demo() {
    println("");
    println("=== 04.11 好人坏人约瑟夫：最小 m（前 n 次出列全是坏人）===");
    print("  n:  ");
    for (int n = 1; n <= 9; ++n) { print("{:5}", n); }
    println("");
    print("  m:  ");
    for (int n = 1; n <= 9; ++n) {
        print("{:5}", josephus_bad_first_m(n));
    }
    println("");
    assert(josephus_bad_first_m(1) == 2);
    assert(josephus_bad_first_m(3) == 5);

    // 独立验证：n=3、m=5 的完整出列序（全模拟、好人一个不少）
    {
        std::vector<int> alive{0, 1, 2, 3, 4, 5};
        std::vector<int> order;
        int pos = 0;
        for (int step = 0; step < 3; ++step) {
            pos = (pos + 5 - 1) % static_cast<int>(alive.size());
            order.push_back(alive[static_cast<std::size_t>(pos)]);
            alive.erase(alive.begin() + pos);
        }
        println("  n=3、m=5 的前三次出列：{} {} {}（全是坏人段 3..5）",
                order[0], order[1], order[2]);
        assert(order[0] >= 3 && order[1] >= 3 && order[2] >= 3);
        // m=4 反例：首出列 (4−1)%6 = 3（坏人）但第二次 (3+3)%5 = 1（好人）
        std::vector<int> alive2{0, 1, 2, 3, 4, 5};
        int p = (4 - 1) % 6;
        alive2.erase(alive2.begin() + p);
        p = (p + 4 - 1) % 5;
        println("  m=4 反例：第二出列 = {}（好人段 0..2，m=4 不合格）", alive2[static_cast<std::size_t>(p)]);
        assert(alive2[static_cast<std::size_t>(p)] < 3);
    }

    // 对账：n=1..9 的每个 m 再跑一遍独立全模拟（含后 n 步），确认
    // 前 n 步出列确实全在坏人段——与搜索口径完全独立
    int bad = 0;
    for (int n = 1; n <= 9; ++n) {
        const int m = josephus_bad_first_m(n);
        std::vector<int> alive(2 * n);
        for (int i = 0; i < 2 * n; ++i) { alive[static_cast<std::size_t>(i)] = i; }
        int pos = 0;
        for (int step = 0; step < n; ++step) {
            pos = (pos + m - 1) % static_cast<int>(alive.size());
            if (alive[static_cast<std::size_t>(pos)] < n) { ++bad; break; }
            alive.erase(alive.begin() + pos);
        }
    }
    println("  n=1..9 全量复检：前 n 步混入好人的 {} 例", bad);
    assert(bad == 0);
}

// ═══ 04.12 线段包含的极点归约 ═══
// 同一条直线上的闭线段 s=(l,r)：t 包含 s ⟺ l_t < l_s 且 r_s < r_t
// （左右端点两两互异的一般位置）。映射 p(s) = (−l, r)：
//   t 包含 s ⟺ p(t) 支配 p(s)（严格双坐标，与 04.9 的支配同款）
// ⟹ 「不被任何线段包含」的线段 ⟺ 映像点的极点——分治极点直接复用。
struct Seg { int l, r; };

static std::vector<char> uncontained_brute(const std::vector<Seg>& segs) {
    const int n = static_cast<int>(segs.size());
    std::vector<char> out(static_cast<std::size_t>(n), 1);
    for (int i = 0; i < n; ++i) {
        for (int j = 0; j < n && out[static_cast<std::size_t>(i)]; ++j) {
            if (i == j) { continue; }
            if (segs[static_cast<std::size_t>(j)].l < segs[static_cast<std::size_t>(i)].l &&
                segs[static_cast<std::size_t>(i)].r < segs[static_cast<std::size_t>(j)].r) {
                out[static_cast<std::size_t>(i)] = 0;
            }
        }
    }
    return out;
}

static std::vector<char> uncontained_via_maxima(const std::vector<Seg>& segs) {
    std::vector<MaxPoint> pts;
    pts.reserve(segs.size());
    for (const Seg& s : segs) { pts.push_back({-s.l, s.r}); }
    const std::vector<MaxPoint> mx = maxima_divide_conquer(pts);
    std::vector<char> out(static_cast<std::size_t>(segs.size()), 0);
    for (const MaxPoint& p : mx) {
        for (std::size_t i = 0; i < segs.size(); ++i) {
            if (-segs[i].l == p.x && segs[i].r == p.y) {
                out[i] = 1;
            }
        }
    }
    return out;
}

static void segment_containment_demo() {
    println("");
    println("=== 04.12 线段包含 → 二维极点：映射 (l,r) ↦ (−l,r) ===");
    const std::vector<Seg> fixed{{4, 6}, {1, 10}, {3, 8}, {5, 20}};
    // 手算：a(4,6) 被 b、c、d 包含；c(3,8) 被 b 包含；b、d 互不包含
    const std::vector<char> fb = uncontained_brute(fixed);
    const std::vector<char> fm = uncontained_via_maxima(fixed);
    print("  固定例（a,b,c,d = [4,6],[1,10],[3,8],[5,20]）：不被包含的是 ");
    const char* names = "abcd";
    for (std::size_t i = 0; i < fixed.size(); ++i) {
        if (fb[i]) { print("{}", names[i]); }
    }
    println("（暴力与极点归约一致 = {}）",
            fb == fm ? 1 : 0);
    assert(fb == fm);
    assert(fb == std::vector<char>({0, 1, 0, 1}));

    // 随机 300 例（端点两两互异）：归约 vs 暴力 O(n²)
    std::mt19937 rng{5489};
    int bad = 0;
    for (int t = 0; t < 300; ++t) {
        const int n = 1 + static_cast<int>(rand_below(rng, 20));
        std::vector<int> ls(n), rs(n);
        for (int i = 0; i < n; ++i) {
            ls[static_cast<std::size_t>(i)] =
                static_cast<int>(rand_below(rng, 1000));   // 采样后 unique
            rs[static_cast<std::size_t>(i)] =
                1000 + static_cast<int>(rand_below(rng, 1000));
        }
        std::ranges::sort(ls);
        ls.erase(std::ranges::unique(ls).begin(), ls.end());
        std::ranges::sort(rs);
        rs.erase(std::ranges::unique(rs).begin(), rs.end());
        const int m = static_cast<int>(std::min(ls.size(), rs.size()));
        std::vector<Seg> segs;
        segs.reserve(static_cast<std::size_t>(m));
        for (int i = 0; i < m; ++i) {
            segs.push_back({ls[static_cast<std::size_t>(i)],
                            rs[static_cast<std::size_t>(i)]});
        }
        if (uncontained_brute(segs) != uncontained_via_maxima(segs)) { ++bad; }
    }
    println("  随机 300 例（端点互异，n≤20）：归约 vs 暴力不一致 {} 例", bad);
    assert(bad == 0);

    // 大例：10 万条线段，分治 O(n lg n) vs 暴力 O(n²) 只跑分治侧 +
    // 抽样验证（对归约输出的每个极点，任取 500 条线段核对不被包含）
    std::vector<Seg> big;
    big.reserve(100000);
    std::vector<int> bl(static_cast<std::size_t>(100000)),
        br(static_cast<std::size_t>(100000));
    for (int i = 0; i < 100000; ++i) {
        bl[static_cast<std::size_t>(i)] = i;                       // l 互异
        br[static_cast<std::size_t>(i)] = 200000 + static_cast<int>(
            rand_below(rng, 400000));
    }
    std::ranges::sort(br);
    br.erase(std::ranges::unique(br).begin(), br.end());
    for (std::size_t i = br.size(); i > 1; --i) {          // 洗乱配对，
        const std::size_t j = static_cast<std::size_t>(    // 产生真实包含
            rand_below(rng, static_cast<std::uint32_t>(i)));
        std::swap(br[i - 1], br[j]);
    }
    const int bn = static_cast<int>(br.size());
    for (int i = 0; i < bn; ++i) {
        big.push_back({i, br[static_cast<std::size_t>(i)]});
    }
    const std::vector<char> bm = uncontained_via_maxima(big);
    int total = 0;
    for (char c : bm) { total += c; }
    int spot_bad = 0;
    for (std::size_t i = 0; i < big.size(); ++i) {
        if (!bm[i]) { continue; }
        for (int k = 0; k < 500; ++k) {
            const std::size_t j = static_cast<std::size_t>(rand_below(rng, bn));
            if (j != i &&
                big[j].l < big[i].l && big[i].r < big[j].r) { ++spot_bad; }
        }
    }
    println("  大例（{} 条线段）：不被包含 {} 条；抽样 500×极点复核失败 {} 例",
            bn, total, spot_bad);
    assert(spot_bad == 0 && total > 0);
}

int main() {
    max_subarray_demo();
    strassen_demo();
    recursion_trees();
    master_theorem();
    binary_search_demo();
    fractional_bisect_demo();
    dna_sort_demo();
    hanoi_demo();
    maxima_demo();
    josephus_demo();
    josephus_variant_demo();
    segment_containment_demo();
    println("自检通过");
    return 0;
}