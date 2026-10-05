// 04 分治策略（CLRS 第 4 章）。结构：04.1 最大子数组（暴力/分治/Kadane）/
// 04.2 Strassen 矩阵乘（S/P 全表 + 三种口径的乘/加计数对比）/ 04.3 递归树打印 /
// 04.4 主定理应用器 + 递归式精确值的经验验证 /
// 04.5 二分查找：分治的极端形态（f(n)=Θ(1)）+ 边界不变式 + 旋转最小值。
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
#include <limits>
#include <random>
#include <span>
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
    for (const std::vector<int>& dup :
         {std::vector<int>{2, 2, 2, 0, 1}, std::vector<int>{1, 1, 1, 1},
          std::vector<int>{3, 3, 1, 3}, std::vector<int>{1, 3, 3},
          std::vector<int>{5, 5, 5, 1, 5, 5}}) {
        long long s = 0;
        const int got = rotated_min(dup, s);
        const int want = *std::ranges::min_element(dup);
        print("  带重复值 "); for (int v : dup) { print("{} ", v); }
        println("→ 最小值 = {}（期望 {}），{} 次比较", got, want, s);
        assert(got == want);
        assert(s <= static_cast<long long>(dup.size()));
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

int main() {
    max_subarray_demo();
    strassen_demo();
    recursion_trees();
    master_theorem();
    binary_search_demo();
    println("自检通过");
    return 0;
}
