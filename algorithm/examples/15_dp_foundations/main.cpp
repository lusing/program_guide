// 15 动态规划（上）：钢条切割与矩阵链（CLRS §15.1–15.2 + §15.3 方法论）。
// 结构：15.1 钢条切割三版本（朴素递归/备忘录/自底向上，调用计数对比）/
// 15.2 解的重构（EXTENDED-BOTTOM-UP-CUT-ROD）/ 15.3 矩阵链乘（m/s 表 +
// 最优括号化）/ 15.4 子问题图与重叠子问题的量化。
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

#include <cassert>
#include <cstdint>
#include <limits>
#include <string>
#include <vector>

// CLRS 图 15.1 的价格表（长度 1..10 英寸）
static const std::vector<int> kPrice{0, 1, 5, 8, 9, 10, 17, 17, 20, 24, 30};

struct Cnt { long long calls = 0; };

// ═══ 15.1 三版本钢条切割 ═══
// 朴素递归 CUT-ROD（p.363）：T(n) = 2^n 量级——反复求解同一子问题
static int cut_rod_naive(int n, Cnt& c) {
    ++c.calls;
    if (n == 0) { return 0; }
    int q = std::numeric_limits<int>::min();
    for (int i = 1; i <= n; ++i) {
        q = std::max(q, kPrice[static_cast<std::size_t>(i)] + cut_rod_naive(n - i, c));
    }
    return q;
}

// MEMOIZED-CUT-ROD（p.365）：每个子问题只解一次
static int memoized(int n, std::vector<int>& r, Cnt& c) {
    ++c.calls;
    if (r[static_cast<std::size_t>(n)] >= 0) { return r[static_cast<std::size_t>(n)]; }
    int q = 0;
    if (n > 0) {
        q = std::numeric_limits<int>::min();
        for (int i = 1; i <= n; ++i) {
            q = std::max(q, kPrice[static_cast<std::size_t>(i)] + memoized(n - i, r, c));
        }
    }
    r[static_cast<std::size_t>(n)] = q;
    return q;
}

// BOTTOM-UP-CUT-ROD（p.366）：按长度递增填表
static int bottom_up(int n, std::vector<int>& s) {
    std::vector<int> r(static_cast<std::size_t>(n) + 1, 0);
    s.assign(static_cast<std::size_t>(n) + 1, 0);
    for (int j = 1; j <= n; ++j) {
        int q = std::numeric_limits<int>::min();
        for (int i = 1; i <= j; ++i) {
            if (q < kPrice[static_cast<std::size_t>(i)] + r[static_cast<std::size_t>(j - i)]) {
                q = kPrice[static_cast<std::size_t>(i)] + r[static_cast<std::size_t>(j - i)];
                s[static_cast<std::size_t>(j)] = i;    // 记录最优首段
            }
        }
        r[static_cast<std::size_t>(j)] = q;
    }
    return r[static_cast<std::size_t>(n)];
}

static void rod_cutting_demo() {
    println("钢条切割（价格表 = 图 15.1，覆盖长度 1..10）三版本对比：");
    for (int n : {8, 10}) {
        Cnt cn{}, cm{};
        const int v1 = cut_rod_naive(n, cn);
        std::vector<int> r(static_cast<std::size_t>(n) + 1, -1);
        const int v2 = memoized(n, r, cm);
        std::vector<int> s;
        const int v3 = bottom_up(n, s);
        assert(v1 == v2 && v2 == v3);
        println("  n={}：最优收益 {}；朴素调用 {} 次 vs 备忘录 {} 次 vs 自底向上填 {} 格",
                n, v1, cn.calls, cm.calls, n);
    }
}

// ═══ 15.2 解的重构 ═══
static void reconstruction_demo() {
    const int n = 10;
    std::vector<int> s;
    const int best = bottom_up(n, s);
    print("n=10 最优切割方案（收益 {}）: ", best);
    int len = n;
    while (len > 0) {
        print("{} ", s[static_cast<std::size_t>(len)]);
        len -= s[static_cast<std::size_t>(len)];
    }
    println("（长度段）");
    assert(best == 30);
    // 长度 10 不切直接卖（p=30）最优；验证首段选择
    assert(s[10] == 10);
}

// ═══ 15.3 矩阵链乘 ═══
// MATRIX-CHAIN-ORDER（p.375）：m[i,j] = Ai..Aj 最少标量乘法数
// s[i,j] = 最优分割点。CLRS 例：p = <30,35,15,5,10,20,25> → 答案 15125。
static void matrix_chain_demo() {
    const std::vector<int> p{30, 35, 15, 5, 10, 20, 25}; // 6 个矩阵
    const int n = static_cast<int>(p.size()) - 1;
    std::vector<std::vector<long long>> m(static_cast<std::size_t>(n) + 2,
        std::vector<long long>(static_cast<std::size_t>(n) + 2, 0));
    std::vector<std::vector<int>> s(static_cast<std::size_t>(n) + 2,
        std::vector<int>(static_cast<std::size_t>(n) + 2, 0));
    long long cells = 0;
    for (int l = 2; l <= n; ++l) {                    // 链长
        for (int i = 1; i + l - 1 <= n; ++i) {
            const int j = i + l - 1;
            m[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] =
                std::numeric_limits<long long>::max();
            for (int k = i; k < j; ++k) {
                const long long q = m[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)]
                    + m[static_cast<std::size_t>(k + 1)][static_cast<std::size_t>(j)]
                    + static_cast<long long>(p[static_cast<std::size_t>(i - 1)])
                      * p[static_cast<std::size_t>(k)] * p[static_cast<std::size_t>(j)];
                ++cells;
                if (q < m[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)]) {
                    m[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] = q;
                    s[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] = k;
                }
            }
        }
    }
    println("矩阵链乘（p = <30,35,15,5,10,20,25>，6 矩阵）：");
    println("  最少标量乘法 = {}（CLRS 答案 15125）", m[1][static_cast<std::size_t>(n)]);
    assert(m[1][static_cast<std::size_t>(n)] == 15125);

    // 最优括号化（PRINT-OPTIMAL-PARENS）
    std::string out;
    auto parens = [&](this auto&& self, int i, int j) -> void {
        if (i == j) { out += "A" + std::to_string(i); return; }
        out += "(";
        self(i, s[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)]);
        out += "·";
        self(s[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] + 1, j);
        out += ")";
    };
    parens(1, n);
    println("  最优括号化 = {}", out);
    assert(out == "((A1·(A2·A3))·((A4·A5)·A6))");

    // 子问题数 vs 暴力枚举（Catalan 数）
    println("  DP 填表：{} 格、分割尝试 {} 次；暴力枚举括号化 = Catalan C5 = 42 种",
            n * (n - 1) / 2, cells);
}

// ═══ 15.4 重叠子问题的量化：朴素 vs 备忘录的调用数曲线 ═══
static void overlap_demo() {
    println("重叠子问题量化（朴素 CUT-ROD 调用数 / 备忘录调用数）：");
    for (int n : {4, 6, 8, 10}) {
        Cnt cn{};
        cut_rod_naive(n, cn);
        Cnt cm{};
        std::vector<int> r(static_cast<std::size_t>(n) + 1, -1);
        memoized(n, r, cm);
        println("  n={:>2}：朴素 {} 次，备忘录 {} 次（比值 {:.1f}）",
                n, cn.calls, cm.calls,
                static_cast<double>(cn.calls) / static_cast<double>(cm.calls));
    }
}

// ═══ 15.5 斐波那契四解法：重叠子问题的完整手术 ═══
// F(n) = F(n-1) + F(n-2)，F(0)=0, F(1)=1。它是「重叠子问题」最干净的标本：
// 递推式只有两行，却藏着四种量级的算法。
//
//   解法一  朴素递归     T(n) = 2T(n-1) + Θ(1) = Θ(2^n)
//   解法二  记忆化       T(n) = T(n-1) + T(n-2) + Θ(1) = Θ(F(n)) = Θ(φ^n)
//   解法三  自底向上     Θ(n) 时间 Θ(n) 空间（滚动变量可降到 Θ(1)）
//   解法四  矩阵快速幂   Θ(lg n) 时间 Θ(1) 空间
//
// 关键认知：**解法一慢不是因为「递归深」，而是因为它把同一个 F(k) 算了
// 指数多次**。调用树的节点数 ≈ 2^(n/2)，而不同的子问题只有 n 个——
// 冗余度就是指数级的。解法二只是给每个子问题「建档一次」，就把指数变成
// 了斐波那契数本身（仍然指数，但是最小可能的指数——下界）。

// 解法一：朴素递归。counter 记录被调用的总次数（含重复）。
static long long fib_naive(long long n, long long& counter) {
    ++counter;
    if (n < 2) { return n; }
    return fib_naive(n - 1, counter) + fib_naive(n - 2, counter);
}

// 解法二：记忆化（自顶向下）。每格最多算一次。
static long long fib_memo(long long n, std::vector<long long>& memo,
                          long long& counter) {
    ++counter;
    if (n < 2) { return n; }
    if (memo[static_cast<std::size_t>(n)] >= 0) {
        return memo[static_cast<std::size_t>(n)];      // 命中：直接返回，不再递归
    }
    const long long v = fib_memo(n - 1, memo, counter)
                      + fib_memo(n - 2, memo, counter);
    memo[static_cast<std::size_t>(n)] = v;             // 建档
    return v;
}

// 解法三：自底向上 + 滚动变量。Θ(n) 时间、Θ(1) 空间。
static long long fib_iter(long long n) {
    if (n < 2) { return n; }
    long long prev = 0;
    long long cur = 1;
    for (long long k = 2; k <= n; ++k) {
        const long long next = prev + cur;
        prev = cur;
        cur = next;
    }
    return cur;
}

// 解法四：矩阵快速幂。用 2×2 矩阵的幂把 n 次加法压成 lg n 次矩阵乘法。
// 恒等式：[[F(n+1), F(n)], [F(n), F(n-1)]] = M^n  (M = [[1,1],[1,0]])
// 这个恒等式可以由归纳法证：M^0 = I（对应 F(1)=1,F(0)=0），
// 每乘一次 M 就把下标推进一格。
struct Mat2 {
    long long a00 = 1, a01 = 0, a10 = 0, a11 = 1;      // 默认单位矩阵
};

static Mat2 mul(const Mat2& x, const Mat2& y) {
    return Mat2{x.a00 * y.a00 + x.a01 * y.a10,
                x.a00 * y.a01 + x.a01 * y.a11,
                x.a10 * y.a00 + x.a11 * y.a10,
                x.a10 * y.a01 + x.a11 * y.a11};
}

static Mat2 mat_pow(Mat2 base, long long e, long long& mults) {
    Mat2 result;                                      // 单位矩阵
    while (e > 0) {
        if ((e & 1) != 0) { result = mul(result, base); ++mults; }
        e >>= 1;
        if (e > 0) { base = mul(base, base); ++mults; }
    }
    return result;
}

static long long fib_matrix(long long n, long long& mults) {
    if (n < 2) { return n; }
    const Mat2 m = mat_pow(Mat2{1, 1, 1, 0}, n, mults);
    return m.a01;                                     // M^n 的 [0][1] 即 F(n)
}

// 解法五（附加）：尾递归 / 迭代快速倍增，单变量版矩阵快速幂。
// 恒等式 F(2k) = F(k)·(2F(k+1) − F(k))，F(2k+1) = F(k)² + F(k+1)²
// ——它把矩阵压成两个数，代价更低但推导更绕，适合面试加分项。
static long long fib_fast_doubling(long long n) {
    if (n == 0) { return 0; }
    long long a = 0;                                  // F(k)
    long long b = 1;                                  // F(k+1)
    for (int bit = 62; bit >= 0; --bit) {              // 从最高位往最低位扫
        const long long c = a * (2 * b - a);          // F(2k)
        const long long d = a * a + b * b;            // F(2k+1)
        if ((n >> bit) & 1) { a = d; b = c + d; }     // k → 2k+1
        else { a = c; b = d; }                         // k → 2k
    }
    return a;
}

static void fibonacci_demo() {
    println("");
    println("=== 15.5 斐波那契四解法：重叠子问题的完整手术 ===");

    // 先看数列本身
    print("F(0..20) = ");
    for (long long k = 0; k <= 20; ++k) { print("{} ", fib_iter(k)); }
    println("");
    assert(fib_iter(20) == 6765);

    // 三种解法在 n ≤ 25 上逐一核对值一致
    for (long long n = 0; n <= 25; ++n) {
        long long c1 = 0;
        std::vector<long long> memo(static_cast<std::size_t>(n) + 2, -1);
        long long c2 = 0;
        long long c4 = 0;
        const long long v1 = fib_naive(n, c1);
        const long long v2 = fib_memo(n, memo, c2);
        const long long v3 = fib_iter(n);
        const long long v4 = fib_matrix(n, c4);
        const long long v5 = fib_fast_doubling(n);
        assert(v1 == v2 && v2 == v3 && v3 == v4 && v4 == v5);
    }
    println("n = 0..25：五个解法结果两两对账一致（已 assert）");

    // 调用次数曲线：朴素 vs 记忆化。这是「重叠」的直接度量。
    println("");
    println("调用次数（朴素递归 vs 记忆化，含重复调用）：");
    println("    n   朴素调用数   记忆化调用数   冗余倍数   不同子问题数");
    for (long long n : {10LL, 15LL, 20LL, 25LL, 30LL}) {
        long long c1 = 0;
        fib_naive(n, c1);
        std::vector<long long> memo(static_cast<std::size_t>(n) + 2, -1);
        long long c2 = 0;
        fib_memo(n, memo, c2);
        println("{:5}   {:11}   {:12}   {:9.1f}   {:12}",
                n, c1, c2, static_cast<double>(c1) / static_cast<double>(c2), n + 1);
    }
    println("「不同子问题数」= n+1（F(0)..F(n)），而朴素调用数是 2F(n+1)−1 量级——");
    println("冗余倍数 = (2F(n+1)−1)/(n+1) 随 n 指数增长，这就是「重叠」的代价。");

    // 精确恒等式验证：朴素调用数恰为 2·F(n+1) − 1
    for (long long n : {10LL, 15LL, 20LL, 25LL}) {
        long long c1 = 0;
        (void)fib_naive(n, c1);
        assert(c1 == 2 * fib_iter(n + 1) - 1);
    }
    println("");
    println("恒等式对账：朴素调用数 == 2·F(n+1) − 1（n=10/15/20/25 全中）。");
    println("  这解释了为什么朴素解法是 Θ(φ^n)——它就是斐波那契数本身。");

    // 矩阵快速幂：乘法次数随 n 只按 lg n 增长
    println("");
    println("矩阵快速幂的矩阵乘法次数（Θ(lg n)）：");
    println("    n   矩阵乘法次数   倍增版递归深度");
    for (long long n : {10LL, 100LL, 1000LL, 1000000LL, 1000000000000LL}) {
        long long mults = 0;
        const long long v = fib_matrix(n, mults);
        // 校验矩阵版与迭代版一致（n 不超过 45 才不会溢出 long long）
        if (n <= 45) { assert(v == fib_iter(n)); }
        // 快速倍增的循环固定 63 轮，与 n 大小几乎无关
        int depth = 0;
        for (long long t = n; t > 0; t >>= 1) { ++depth; }
        println("{:14}   {:12}   {:12}", n, mults, depth);
        assert(mults <= 2 * 63);
    }
    println("  n 从 10 涨到 10¹²（涨 10¹¹ 倍），矩阵乘法次数只从 5 涨到 52——约 2·⌈lg₂ n⌉。");
    println("  验证 n=10¹² 的 F 值：");
    // F(10^12) 超出 long long，只展示快速倍增能在大 n 上「跑完」——
    // 用对数避免溢出：F(n) ≈ φ^n/√5，取 lg F(n) ≈ n·lg φ − lg √5
    const long long n_big = 1000000000000LL;
    const double log_phi = 0.20898764024997873;        // lg φ
    const double log_sqrt5 = 0.34948500216800940;       // lg √5
    println("    F(10^12) ≈ 10^({:.3f})，远超 64 位整数范围", 
            n_big * log_phi - log_sqrt5);
    println("    → 想拿精确值必须用大整数（第 32 章的高精度）或矩阵快速幂的");
    println("      「只算 mod m」变体（斐波那契的快速倍增对 mod 天然友好）。");

    // 溢出边界：long long 装到哪一项为止
    println("");
    // 「无符号加法回绕」判边界：F(k) 单调递增，一旦 next < ub 就回绕了。
    // 用 unsigned 探测不会触发带符号溢出的 UB；最后再用 int64 上限筛出
    // 「能装进 long long」的那一项——两者差 1（F(93) 装得下 uint64，装不下 int64）。
    std::uint64_t ua = 0;
    std::uint64_t ub = 1;
    int last_unsigned = 1;
    for (;; ++last_unsigned) {
        const std::uint64_t next = ua + ub;
        if (next < ub) { break; }                   // 回绕 → 下一项连 uint64 都装不下
        ua = ub;
        ub = next;
        if (last_unsigned > 200) { break; }         // 安全阀（实际到 94 就停）
    }
    int last_ok = 92;
    {
        std::uint64_t x = 0;
        std::uint64_t y = 1;
        int k = 1;
        for (;; ++k) {
            const std::uint64_t next = x + y;
            if (next < y || next > static_cast<std::uint64_t>(INT64_MAX)) { break; }
            x = y;
            y = next;
            if (k > 200) { break; }
        }
        last_ok = k;                                // k 即装得下 int64 的最大下标
    }
    println("long long 能装下的最大斐波那契数：F({}) = {}", last_ok, fib_iter(last_ok));
    assert(last_ok == 92);
    println("  F({}) = 12200160415121876738 > int64 上限 {} → long long 到此为止",
            last_ok + 1, INT64_MAX);
    println("  （若换成 uint64，还能再装下 F({})）", last_unsigned);
    println("  → 需要 F(100) 以上的精确值就得用大数（第 32 章的高精度）。");
}

int main() {
    rod_cutting_demo();
    reconstruction_demo();
    matrix_chain_demo();
    overlap_demo();
    fibonacci_demo();
    println("自检通过");
    return 0;
}
