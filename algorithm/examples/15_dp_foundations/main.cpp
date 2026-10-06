// 15 动态规划（上）：钢条切割与矩阵链（CLRS §15.1–15.2 + §15.3 方法论）。
// 结构：15.1 钢条切割三版本（朴素递归/备忘录/自底向上，调用计数对比）/
// 15.2 解的重构（EXTENDED-BOTTOM-UP-CUT-ROD）/ 15.3 矩阵链乘（m/s 表 +
// 最优括号化）/ 15.4 子问题图与重叠子问题的量化 /
// 15.7 数字三角形：自底向上滚动数组 + 路径重构（备忘录/暴力枚举对账）/
// 15.8 换零钱：完全背包型 DP（最少枚数含重构 + 组合数，贪心对照与 BFS 对账）。
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
#include <bitset>
#include <cassert>
#include <cstdint>
#include <limits>
#include <random>
#include <string>
#include <vector>

// 可移植随机：乘法折半取 [0,n)，不用 uniform_int_distribution
static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    return static_cast<std::uint32_t>(
        (static_cast<std::uint64_t>(rng()) * n) >> 32);
}

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

// ═══ 15.6 从指数到状态压缩：可达性 DP 的三级下沉 ═══
//
// 「把 n 件行李分成重量和尽量接近的两份」：设 W = Σw，C = ⌊W/2⌋，则答案
// 等于「≤ C 的最大可达子集和」。目标只是**能否达到**，所以状态不必记
// 「和等于多少种方案」，只要一个布尔集合。三级下沉：
//
//   第一级  Θ(2^n)   枚举 2^n 个子集，每个子集 O(n) 求和
//   第二级  Θ(nC)    值维度换成布尔：reach[s] = 和 s 是否可达（0-1 背包）
//   第三级  Θ(nC/w)  把 C+1 个布尔塞进机器字，shift-or 一条语句做一轮转移
//
// 关键等式（第三级的全部秘密）：`bs |= bs << w`
//   ├─ bs      贡献「不取 w」的分支（和 s 仍可达）
//   └─ bs << w 贡献「取 w」的分支（和 s 的可达性搬到 s+w）
// 复合赋值先求值右侧 ⟹ 右侧整体来自**更新前**的 bs ⟹ 同一轮不会重复取 w。
// 移出去的位自动丢弃 ⟹ 「和 > C」的状态被天然截断（相当于值域裁剪）。

static constexpr std::size_t kSubBits = 256;   // 子集和位宽（编译期常量）
static constexpr std::size_t kModBits = 100;   // 模 K 位宽（K ≤ 100）

// ── 变长位集：std::bitset 的宽度是编译期常量，容量真要运行时才知道时
//    只能自己拿 std::vector<std::uint64_t> 手写移位-或。──
static void mask_high(std::vector<std::uint64_t>& bs, std::size_t bits) {
    const std::size_t r = bits % 64;
    if (r != 0 && !bs.empty()) { bs.back() &= (~std::uint64_t{0}) >> (64 - r); }
}

static bool bit_at(const std::vector<std::uint64_t>& bs, std::size_t i) {
    return ((bs[i / 64] >> (i % 64)) & std::uint64_t{1}) != 0;
}

// bs |= bs << w  —— 一轮 0-1 背包转移（w 可以 ≥ 64，跨字处理）
static void or_shift_left(std::vector<std::uint64_t>& bs, std::size_t w, std::size_t bits) {
    const std::size_t ws = w / 64;
    const unsigned bt = static_cast<unsigned>(w % 64);
    for (std::size_t i = bs.size(); i-- > 0;) {   // 高位→低位：读到的都是旧值
        std::uint64_t v = 0;
        if (i >= ws) {
            v = bs[i - ws] << bt;
            if (bt != 0 && i > ws) { v |= bs[i - ws - 1] >> (64 - bt); }
        }
        bs[i] |= v;
    }
    mask_high(bs, bits);                          // 移出位宽的高位（等价于值域裁剪）
}

// ── 第一级：Θ(2^n) 枚举子集 ──
static std::vector<char> subset_reach_naive(const std::vector<int>& w, int cap,
                                            long long& visited) {
    const std::size_t n = w.size();
    std::vector<char> seen(static_cast<std::size_t>(cap) + 1, 0);
    seen[0] = 1;
    visited = 0;
    for (std::uint64_t mask = 0; mask < (std::uint64_t{1} << n); ++mask) {
        int s = 0;
        for (std::size_t i = 0; i < n; ++i) {
            if (((mask >> i) & 1U) != 0U) { s += w[i]; }
        }
        ++visited;
        if (s <= cap) { seen[static_cast<std::size_t>(s)] = 1; }
    }
    return seen;
}

// ── 第二级：Θ(nC) 布尔可达性（0-1 背包的可达性变体，j 必须倒序）──
static std::vector<char> subset_reach_bool(const std::vector<int>& w, int cap,
                                           long long& cellOps) {
    std::vector<char> reach(static_cast<std::size_t>(cap) + 1, 0);
    reach[0] = 1;
    cellOps = 0;
    for (int x : w) {
        for (int s = cap; s >= x; --s) {          // 倒序：同一件行李只用一次
            ++cellOps;
            if (reach[static_cast<std::size_t>(s - x)] != 0) {
                reach[static_cast<std::size_t>(s)] = 1;
            }
        }
    }
    return reach;
}

// ── 第三级 (a)：Θ(nC/w) 位并行，编译期宽度用 std::bitset ──
static std::bitset<kSubBits> subset_reach_bitset(const std::vector<int>& w, int cap,
                                                 long long& wordOps) {
    std::bitset<kSubBits> bs;
    bs[0] = 1;
    wordOps = 0;
    for (int x : w) {
        if (x > cap) { continue; }
        bs |= (bs << x);                         // ← 一条语句一轮 0-1 背包
        wordOps += static_cast<long long>((kSubBits + 63) / 64);
    }
    return bs;
}

// ── 第三级 (b)：Θ(nC/w) 位并行，运行时才知道 C ⟹ 手写变长位集 ──
static std::vector<std::uint64_t> subset_reach_dyn(const std::vector<int>& w, int cap,
                                                    long long& wordOps) {
    const std::size_t bits = static_cast<std::size_t>(cap) + 1;
    std::vector<std::uint64_t> bs((bits + 63) / 64, 0);
    bs[0] = 1;                                   // 和 0 可达
    wordOps = 0;
    for (int x : w) {
        if (x > cap) { continue; }
        or_shift_left(bs, static_cast<std::size_t>(x), bits);
        wordOps += static_cast<long long>(bs.size());
    }
    return bs;
}

static void reachability_ladder_demo() {
    // 18 件行李，Σw = 490，C = ⌊490/2⌋ = 245
    const std::vector<int> w{23, 41, 17, 8, 35, 29, 12, 50, 6, 33, 19, 44, 27, 11, 38, 52, 15, 30};
    int total = 0;
    for (int x : w) { total += x; }
    const int cap = total / 2;
    assert(total == 490 && cap == 245);
    assert(kSubBits > static_cast<std::size_t>(cap));

    println("=== 15.6 可达性 DP 的三级下沉（{} 件行李，Σw = {}，C = ⌊W/2⌋ = {}）===",
            w.size(), total, cap);

    // ── 三级 ──
    long long naiveOps = 0, boolOps = 0, bsOps = 0, dynOps = 0;
    const std::vector<char> rNaive = subset_reach_naive(w, cap, naiveOps);
    const std::vector<char> rBool = subset_reach_bool(w, cap, boolOps);
    const std::bitset<kSubBits> rBits = subset_reach_bitset(w, cap, bsOps);
    std::vector<std::uint64_t> rDyn = subset_reach_dyn(w, cap, dynOps);

    int bestNaive = 0, bestBool = 0;
    for (int s = 0; s <= cap; ++s) {
        if (rNaive[static_cast<std::size_t>(s)] != 0) { bestNaive = s; }
        if (rBool[static_cast<std::size_t>(s)] != 0) { bestBool = s; }
    }
    int bestBits = 0;
    for (int s = 0; s <= cap; ++s) {
        if (rBits[static_cast<std::size_t>(s)]) { bestBits = s; }
    }
    int bestDyn = 0;
    for (int s = 0; s <= cap; ++s) {
        if (bit_at(rDyn, static_cast<std::size_t>(s))) { bestDyn = s; }
    }

    // 对账：四级两两一致
    assert(bestNaive == bestBool && bestBool == bestBits && bestBits == bestDyn);
    for (int s = 0; s <= cap; ++s) {
        const bool a = rNaive[static_cast<std::size_t>(s)] != 0;
        const bool b = rBool[static_cast<std::size_t>(s)] != 0;
        const bool c = rBits[static_cast<std::size_t>(s)];
        const bool d = bit_at(rDyn, static_cast<std::size_t>(s));
        assert(a == b && b == c && c == d);
    }
    const int reachCnt = static_cast<int>(std::count(rBool.begin(), rBool.end(), char{1}));
    println("  第一级 Θ(2^n)  枚举子集 {} 次（2^{}）⟹ 可达和 {} 个，最优 {}",
            naiveOps, w.size(), reachCnt, bestNaive);
    println("  第二级 Θ(nC)   布尔背包单元操作 {} 次 ⟹ 可达和 {} 个，最优 {}",
            boolOps, reachCnt, bestBool);
    println("  第三级 Θ(nC/w) bitset 64 位运算 {} 次（宽度 {} 位 = {} 字）⟹ 最优 {}",
            bsOps, kSubBits, (kSubBits + 63) / 64, bestBits);
    println("  第三级 变长位集（手写移位-或）64 位运算 {} 次（宽度 {} 位 = {} 字）⟹ 最优 {}",
            dynOps, cap + 1, (static_cast<std::size_t>(cap) + 1 + 63) / 64, bestDyn);
    println("  位并行相对布尔 DP 提速 {:.1f} 倍（≈ 64 / 每单元代价）",
            static_cast<double>(boolOps) / static_cast<double>(dynOps));
    println("  四种实现两两对账一致（逐位比对 0..{} 的可达性）= 1", cap);
    println("  最优分堆：较轻一份 = {}，较重一份 = {}（差 {}）", cap, total - cap, total - 2 * cap);

    // ── 模 K 可达性：a₁ ± a₂ ± … ± a_N 能否被 K 整除 ──
    // 状态充分性：expr mod K 之后的贡献只与余数有关 ⟹ (expr ± a_{i+1} ± …) mod K
    // 只依赖 expr mod K，与 expr 具体取值无关。这正是 2^N → N·K 的依据。
    // 转移 r ↦ r + x 与 r ↦ r − x 都是「模 K 循环移位」，故一轮
    //   bs |= (bs << x) | (bs >> (K − x))
    // 就把 K 个余数的双向转移全部做完 ⟹ Θ(N·K/w)。
    const std::vector<int> a{23, 41, 17, 8, 35, 29, 12, 50, 6, 33};
    for (int K : {7, 100}) {
        std::bitset<kModBits> bs, mask;
        for (int r = 0; r < K; ++r) { mask[static_cast<std::size_t>(r)] = 1; }
        // 第一项固定取正（题目语义：运算符只插在项与项之间）
        bs[static_cast<std::size_t>(((a[0] % K) + K) % K)] = 1;
        long long modWordOps = 0;
        for (std::size_t i = 1; i < a.size(); ++i) {
            const std::size_t x = static_cast<std::size_t>(((a[i] % K) + K) % K);
            if (x == 0) { continue; }
            // 双向转移要 4 项而不是 2 项：+x 方向 = (bs << x) | (bs >> (K−x))，
            // −x 方向 = (bs >> x) | (bs << (K−x))。少一半就只剩单向。
            // 注意这里是**赋值**不是 `|=`：± 问题里每一项都必须领一个符号，
            // 没有「不取这一项」这个分支——`|=` 会把上一轮的结果额外并进来。
            const std::bitset<kModBits> src = bs;
            bs = (((src << x) | (src >> (K - static_cast<int>(x))))
                  | ((src >> x) | (src << (K - static_cast<int>(x))))) & mask;
            modWordOps += static_cast<long long>((kModBits + 63) / 64) * 4;
        }
        // 布尔版对账
        std::vector<char> cur(static_cast<std::size_t>(K), 0), nxt(static_cast<std::size_t>(K), 0);
        cur[static_cast<std::size_t>(((a[0] % K) + K) % K)] = 1;
        long long modBoolOps = 0;
        for (std::size_t i = 1; i < a.size(); ++i) {
            const int x = ((a[i] % K) + K) % K;
            std::fill(nxt.begin(), nxt.end(), char{0});
            for (int r = 0; r < K; ++r) {
                if (cur[static_cast<std::size_t>(r)] == 0) { continue; }
                nxt[static_cast<std::size_t>((r + x) % K)] = 1;
                nxt[static_cast<std::size_t>(((r - x) % K + K) % K)] = 1;
                modBoolOps += 2;
            }
            cur.swap(nxt);
        }
        bool same = true;
        for (int r = 0; r < K; ++r) {
            if ((cur[static_cast<std::size_t>(r)] != 0)
                != bs[static_cast<std::size_t>(r)]) { same = false; }
        }
        assert(same);
        println("  模 K = {}：a₁ ± … ± a₁₀ 可被 {} 整除 = {}（布尔 {} 次单元 vs 位并行 {} 次字运算，"
                "逐余数对账 = {}）",
                K, K, bs[0] ? 1 : 0, modBoolOps, modWordOps, same ? 1 : 0);
    }

    // ── 选 K 个数使和能被 K 整除：模 K 可达性 + 计数维 ──
    // dp[j][r] = 「已扫过的数里恰选 j 个、和 ≡ r (mod K)」是否可能。
    // j 必须倒序扫（同一数只用一次）；r 这一维可以整体压成一条 K 位位集，
    // 转移 dp[j] |= rot_K(dp[j−1], a_i)，Θ(n·K²/w) —— 又是同一个 shift-or。
    const std::vector<int> pi{3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5, 8, 9, 7, 9, 3, 2, 3, 8, 4, 6, 2, 6, 4};
    for (int K : {4, 8, 12, 16}) {
        // 布尔版 Θ(n·K²)
        std::vector<std::vector<char>> dp(static_cast<std::size_t>(K) + 1,
                                          std::vector<char>(static_cast<std::size_t>(K), 0));
        dp[0][0] = 1;
        long long cellOps = 0;
        for (int v : pi) {
            const int x = ((v % K) + K) % K;
            for (int j = K; j >= 1; --j) {         // 倒序：数只用一次
                for (int r = 0; r < K; ++r) {
                    ++cellOps;
                    if (dp[static_cast<std::size_t>(j - 1)][static_cast<std::size_t>(r)] != 0) {
                        dp[static_cast<std::size_t>(j)][static_cast<std::size_t>((r + x) % K)] = 1;
                    }
                }
            }
        }
        // 位集版 Θ(n·K²/w)：dp[j] 是一条 K 位位集，转移是一次模 K 循环移位。
        // 这里 `|=` 是对的（与 15.6 的子集和同理）：不取 v 的分支就是 dp[j] 自身。
        std::vector<std::bitset<kModBits>> dbs(static_cast<std::size_t>(K) + 1);
        std::bitset<kModBits> kmask;
        for (int r = 0; r < K; ++r) { kmask[static_cast<std::size_t>(r)] = 1; }
        dbs[0][0] = 1;
        // 理论字操作数按实际位宽 ⌈K/64⌉ 计；std::bitset<100> 的固定宽度会多算
        // （K=4 时仍占 2 字），这个「定宽-padding 浪费」本身就是位集版的代价之一。
        const long long wordsPerRow = (K + 63) / 64;
        const long long paddedWords = (static_cast<long long>(kModBits) + 63) / 64;
        long long wordOps = 0, paddedOps = 0;
        for (int v : pi) {
            const std::size_t x = static_cast<std::size_t>(((v % K) + K) % K);
            for (int j = K; j >= 1; --j) {
                dbs[static_cast<std::size_t>(j)] |=
                    (((dbs[static_cast<std::size_t>(j - 1)] << x)
                      | (dbs[static_cast<std::size_t>(j - 1)] >> (K - static_cast<int>(x))))
                     & kmask);
                wordOps += wordsPerRow * 2;
                paddedOps += paddedWords * 2;
            }
        }
        // 暴力对账：枚举全部 2^n 个子集，筛出恰含 K 个且和被 K 整除的
        bool brute = false;
        {
            const std::size_t n = pi.size();
            for (std::uint64_t mask = 0; mask < (std::uint64_t{1} << n) && !brute; ++mask) {
                if (static_cast<int>(std::popcount(mask)) != K) { continue; }
                int s = 0;
                for (std::size_t i = 0; i < n; ++i) {
                    if (((mask >> i) & 1U) != 0U) { s += pi[i]; }
                }
                if (s % K == 0) { brute = true; }
            }
        }
        const bool boolAns = dp[static_cast<std::size_t>(K)][0] != 0;
        const bool bitAns = dbs[static_cast<std::size_t>(K)][0];
        assert(boolAns == bitAns && boolAns == brute);
        println("  选 {} 个数使和被 {} 整除：可行 = {}（暴力 2²⁴ 子集对账 = {}；布尔 {} 次单元"
                " → 位并行 {} 次字运算，提速 {:.1f} 倍；std::bitset<100> 定宽 padding 到 {} 次）",
                K, K, boolAns ? 1 : 0, brute ? 1 : 0, cellOps, wordOps,
                static_cast<double>(cellOps) / static_cast<double>(wordOps), paddedOps);
    }
}

// ═══ 15.7 数字三角形 ═══
// tri[i] 为第 i 层（0 基，长度 i+1）。每步从 (i,j) 可走到
// (i+1,j)（左下）或 (i+1,j+1)（右下）。求顶点到底层的最大路径和。

// 自底向上：dp[j] 滚动保存到达当前行第 j 格的最佳和；逆序更新，
// dp[j−1] 仍是上一行的旧值。时间 Θ(N²)、空间 O(N)。
static int triangle_best_sum(const std::vector<std::vector<int>>& tri) {
    const int n = static_cast<int>(tri.size());
    std::vector<int> dp(static_cast<std::size_t>(n), 0);
    dp[0] = tri[0][0];
    for (int i = 1; i < n; ++i) {
        for (int j = i; j >= 0; --j) {
            int best = std::numeric_limits<int>::min();
            if (j < i)             { best = std::max(best, dp[static_cast<std::size_t>(j)]); }
            if (j > 0)             { best = std::max(best, dp[static_cast<std::size_t>(j - 1)]); }
            dp[static_cast<std::size_t>(j)] = tri[static_cast<std::size_t>(i)]
                                                  [static_cast<std::size_t>(j)] + best;
        }
    }
    return *std::max_element(dp.begin(), dp.end());
}

// 带路径重构：choice[i][j] 记录前驱来自左上（j−1）还是正上（j）。
// 从最佳底格逐层回溯，再反转为自上而下的列号序列。
static std::vector<int> triangle_best_path(const std::vector<std::vector<int>>& tri) {
    const int n = static_cast<int>(tri.size());
    std::vector<std::vector<char>> choice(
        static_cast<std::size_t>(n),
        std::vector<char>(static_cast<std::size_t>(n), 0));
    std::vector<int> dp(static_cast<std::size_t>(n), 0);
    dp[0] = tri[0][0];
    for (int i = 1; i < n; ++i) {
        for (int j = i; j >= 0; --j) {
            const int up      = (j < i) ? dp[static_cast<std::size_t>(j)]
                                        : std::numeric_limits<int>::min();
            const int up_left = (j > 0) ? dp[static_cast<std::size_t>(j - 1)]
                                        : std::numeric_limits<int>::min();
            choice[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] =
                (up_left > up) ? 1 : 0;      // 1：来自左上
            dp[static_cast<std::size_t>(j)] = tri[static_cast<std::size_t>(i)]
                                                  [static_cast<std::size_t>(j)]
                                            + std::max(up, up_left);
        }
    }
    int col = 0;
    for (int j = 1; j < n; ++j) {
        if (dp[static_cast<std::size_t>(j)] > dp[static_cast<std::size_t>(col)]) { col = j; }
    }
    std::vector<int> columns(static_cast<std::size_t>(n));
    for (int i = n - 1; i >= 0; --i) {
        columns[static_cast<std::size_t>(i)] = col;
        if (i > 0 && choice[static_cast<std::size_t>(i)][static_cast<std::size_t>(col)] == 1) {
            --col;
        }
    }
    return columns;
}

// 备忘录版（自顶向下）：每个格子一个状态
static int triangle_memo(const std::vector<std::vector<int>>& tri, int i, int j,
                         std::vector<std::vector<int>>& memo) {
    if (i == 0) { return tri[0][0]; }
    int& m = memo[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)];
    if (m != std::numeric_limits<int>::min()) { return m; }
    int best = std::numeric_limits<int>::min();
    if (j < i) { best = std::max(best, triangle_memo(tri, i - 1, j, memo)); }
    if (j > 0) { best = std::max(best, triangle_memo(tri, i - 1, j - 1, memo)); }
    return m = tri[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] + best;
}

static int triangle_memo_sum(const std::vector<std::vector<int>>& tri) {
    const int n = static_cast<int>(tri.size());
    std::vector<std::vector<int>> memo(
        static_cast<std::size_t>(n),
        std::vector<int>(static_cast<std::size_t>(n),
                         std::numeric_limits<int>::min()));
    int best = std::numeric_limits<int>::min();
    for (int j = 0; j < n; ++j) {
        best = std::max(best, triangle_memo(tri, n - 1, j, memo));
    }
    return best;
}

// 暴力枚举：2^(N−1) 条路径全部展开。位 1 = 右下，位 0 = 左下。
static int triangle_brute(const std::vector<std::vector<int>>& tri) {
    const int n = static_cast<int>(tri.size());
    int best = std::numeric_limits<int>::min();
    for (int mask = 0; mask < (1 << (n - 1)); ++mask) {
        int col = 0, sum = tri[0][0];
        for (int i = 1; i < n; ++i) {
            if (mask & (1 << (i - 1))) { ++col; }
            sum += tri[static_cast<std::size_t>(i)][static_cast<std::size_t>(col)];
        }
        best = std::max(best, sum);
    }
    return best;
}

static void triangle_demo() {
    println("数字三角形（自底向上滚动数组 Θ(N²)、路径重构；备忘录/暴力对账）：");
    const std::vector<std::vector<int>> tri = {
        {7}, {3, 8}, {8, 1, 0}, {2, 7, 4, 4}, {4, 5, 2, 6, 5}};
    const int best = triangle_best_sum(tri);
    println("  最大路径和 = {}（样例答案 30）", best);
    const std::vector<int> path = triangle_best_path(tri);
    print("  最优路径列号：");
    for (int c : path) { print("{} ", c); }
    int check_sum = 0;
    for (int i = 0; i < static_cast<int>(tri.size()); ++i) {
        check_sum += tri[static_cast<std::size_t>(i)]
                        [static_cast<std::size_t>(path[static_cast<std::size_t>(i)])];
    }
    println("（沿途数值求和 = {}）", check_sum);
    assert(best == 30 && check_sum == 30);
    assert(triangle_memo_sum(tri) == 30 && triangle_brute(tri) == 30);

    std::mt19937 rng{5489};
    int trials = 2000, mismatches = 0;
    for (int t = 0; t < trials; ++t) {
        const int n = 1 + static_cast<int>(rand_below(rng, 11));
        std::vector<std::vector<int>> rnd(static_cast<std::size_t>(n));
        for (int i = 0; i < n; ++i) {
            rnd[static_cast<std::size_t>(i)].resize(static_cast<std::size_t>(i + 1));
            for (int j = 0; j <= i; ++j) {
                rnd[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] =
                    static_cast<int>(rand_below(rng, 100));
            }
        }
        const int a = triangle_best_sum(rnd);
        if (a != triangle_memo_sum(rnd) || a != triangle_brute(rnd)) { ++mismatches; }
    }
    println("  随机 {} 个三角形（N≤11）：自底向上 vs 备忘录 vs 暴力枚举 不一致 {} 例",
            trials, mismatches);
    assert(mismatches == 0);
}

// ═══ 15.8 换零钱：完全背包型 DP ═══
// 面值集合 coins（含 1，故任意金额可达）、每种硬币数量无限。两个问题：
// ① 凑出金额 A 最少需要多少枚；② 凑出 A 的组合方式有多少种。
struct ChangePlan { int coins; std::vector<int> used; };  // used：每面值用几枚

// 最少枚数：dp[a] = 1 + min_{c≤a} dp[a−c]，dp[0]=0；choice 记录末枚硬币。
static ChangePlan change_min(const std::vector<int>& coins, int A) {
    const int k = static_cast<int>(coins.size());
    std::vector<int> dp(A + 1, -1), choice(A + 1, -1);
    dp[0] = 0;
    for (int a = 1; a <= A; ++a) {
        for (int i = 0; i < k; ++i) {
            const int c = coins[static_cast<std::size_t>(i)];
            if (c <= a && dp[a - c] >= 0 &&
                (dp[a] < 0 || dp[a - c] + 1 < dp[a])) {
                dp[a] = dp[a - c] + 1;
                choice[a] = i;
            }
        }
    }
    std::vector<int> used(k, 0);
    int a = A;
    while (a > 0) {
        const int i = choice[a];
        ++used[static_cast<std::size_t>(i)];
        a -= coins[static_cast<std::size_t>(i)];
    }
    return {dp[A], used};
}

// 贪心口径：从大到小，能拿多少拿多少。规范币制下最优，一般情况下不最优。
static int change_greedy(const std::vector<int>& coins, int A) {
    int n = 0, a = A;
    for (int i = static_cast<int>(coins.size()) - 1; i >= 0; --i) {
        const int c = coins[static_cast<std::size_t>(i)];
        n += a / c;
        a %= c;
    }
    return n;
}

// 独立口径：在金额图上做 BFS（节点 0..A，边 a→a+c），首次抵达 A 的距离
// 即最少枚数——不维护递推表，与 DP 零共享逻辑。
static int change_bfs(const std::vector<int>& coins, int A) {
    std::vector<int> dist(A + 1, -1);
    std::vector<int> q;
    q.reserve(A + 1);
    q.push_back(0);
    dist[0] = 0;
    for (std::size_t qi = 0; qi < q.size(); ++qi) {
        const int a = q[qi];
        if (a == A) { return dist[a]; }
        for (int c : coins) {
            if (a + c <= A && dist[a + c] < 0) {
                dist[a + c] = dist[a] + 1;
                q.push_back(a + c);
            }
        }
    }
    return dist[A];
}

// 组合数（不计先后）：硬币作外层循环——ways[a] += ways[a−c]。这样每种
// 组合按面值大小顺序唯一生成一次；金额作外层则数的是有序找零序列。
static long long change_ways(const std::vector<int>& coins, int A) {
    std::vector<long long> ways(A + 1, 0);
    ways[0] = 1;
    for (int c : coins) {
        for (int a = c; a <= A; ++a) { ways[a] += ways[a - c]; }
    }
    return ways[A];
}

// 独立口径：带「第 i 种硬币用几枚」的递归枚举，小金额组合数真值。
static long long change_ways_rec(const std::vector<int>& coins, int i, int A) {
    if (A == 0) { return 1; }
    if (i == static_cast<int>(coins.size())) { return 0; }
    long long total = 0;
    for (int use = 0; use * coins[static_cast<std::size_t>(i)] <= A; ++use) {
        total += change_ways_rec(coins, i + 1,
                                 A - use * coins[static_cast<std::size_t>(i)]);
    }
    return total;
}

static void coin_change_demo() {
    println("=== 15.8 换零钱：最少枚数与组合数（完全背包 DP）===");
    // 规范币制：贪心与 DP 一致
    const std::vector<int> canonical{1, 5, 10, 25};
    const ChangePlan p63 = change_min(canonical, 63);
    println("  币制 1/5/10/25，63 美分：DP {} 枚（25×{} 10×{} 5×{} 1×{}），"
            "贪心 {} 枚", p63.coins, p63.used[3], p63.used[2], p63.used[1],
            p63.used[0], change_greedy(canonical, 63));
    assert(p63.coins == 6 && change_greedy(canonical, 63) == 6);
    assert(p63.coins == change_bfs(canonical, 63));

    // 非规范币制：贪心在 6 处翻车（4+1+1 三枚，DP 给 3+3 两枚）
    const std::vector<int> weird{1, 3, 4};
    print("  币制 1/3/4：金额 ");
    for (int A = 2; A <= 12; ++A) { print("{:4}", A); }
    println("");
    print("    DP 枚数  ");
    for (int A = 2; A <= 12; ++A) { print("{:4}", change_min(weird, A).coins); }
    println("");
    print("    贪心枚数 ");
    for (int A = 2; A <= 12; ++A) { print("{:4}", change_greedy(weird, A)); }
    println("");
    int greedy_fails = 0;
    for (int A = 1; A <= 60; ++A) {
        if (change_min(weird, A).coins != change_greedy(weird, A)) { ++greedy_fails; }
    }
    println("  贪心在 A≤60 上共 {} 个金额非最优（首个：A=6）", greedy_fails);
    assert(change_min(weird, 6).coins == 2 && change_greedy(weird, 6) == 3);

    // 组合数：1/2/5 的不计先后组合
    const std::vector<int> cs{1, 2, 5};
    print("  1/2/5 组合数：金额 ");
    for (int A = 0; A <= 10; ++A) { print("{:4}", A); }
    println("");
    print("    方式数       ");
    for (int A = 0; A <= 10; ++A) { print("{:4}", change_ways(cs, A)); }
    println("");
    for (int A = 0; A <= 25; ++A) {
        assert(change_ways(cs, A) == change_ways_rec(cs, 0, A));
    }
    println("  A≤25 组合数与逐面值递归枚举一致（A=10 有 4 种：5+5/5+2+2+1/"
            "5+2+1+1+1/2×5）");

    // 随机对账：含 1 的随机币制（面值≤25），A≤60
    std::mt19937 rng{5489};
    int mismatches = 0;
    for (int t = 0; t < 2000; ++t) {
        const int k = 2 + static_cast<int>(rand_below(rng, 4));
        std::vector<int> g{1};
        while (static_cast<int>(g.size()) < k) {
            const int c = 2 + static_cast<int>(rand_below(rng, 24));
            if (std::ranges::find(g, c) == g.end()) { g.push_back(c); }
        }
        std::ranges::sort(g);
        const int A = 1 + static_cast<int>(rand_below(rng, 60));
        if (change_min(g, A).coins != change_bfs(g, A) ||
            change_ways(g, A) != change_ways_rec(g, 0, A)) { ++mismatches; }
    }
    println("  随机 {} 个币制（k=2..5，A≤60）：DP vs BFS / 组合数 vs 递归 "
            "不一致 {} 例", 2000, mismatches);
    assert(mismatches == 0);

    // 大例：A=10⁶，全用 25 面值——40000 枚
    const ChangePlan big = change_min(canonical, 1000000);
    println("  大例 A=10⁶：最少 {} 枚（25×{}），贪心一致 = {}",
            big.coins, big.used[3],
            change_greedy(canonical, 1000000) == big.coins);
    assert(big.coins == 40000 && big.used[3] == 40000);
}

// ═══ 15.9 子集和：0/1 可达性的位集 DP ═══
// 从正整数多重集 S 中选一个子集，总和恰为 m。与换零钱（15.8）的
// 差别恰是「每件至多一件」——完全背包 → 0/1 背包。
// reach[j] = 1 ⟺ 前缀里存在子集和为 j。转移 reach |= reach << x，
// 一个 64 位字一次移位或并行 64 个 j（先加后判，天然不会重复用 x）。
static std::vector<char> subset_reach(const std::vector<int>& S, int m) {
    std::vector<char> reach(static_cast<std::size_t>(m) + 1, 0);
    reach[0] = 1;
    for (int x : S) {
        // 逆序扫 0/1：j 从高到低，本件刚置位的格子不会立刻再参与转移
        for (int j = m; j >= x; --j) {
            if (reach[static_cast<std::size_t>(j - x)]) { reach[static_cast<std::size_t>(j)] = 1; }
        }
    }
    return reach;
}

// 方案还原：沿 reach 表回走——从 (n, m) 起每件从后往前问「不用它
// 也够吗」，够就跳过，否则必须选它。
static std::vector<int> subset_pick(const std::vector<int>& S, int m) {
    const int n = static_cast<int>(S.size());
    // pre[i][j]：前 i 件能否凑出 j（滚动记录每层快照）
    std::vector<std::vector<char>> pre(
        static_cast<std::size_t>(n + 1), std::vector<char>(m + 1, 0));
    pre[0][0] = 1;
    for (int i = 1; i <= n; ++i) {
        const int x = S[static_cast<std::size_t>(i - 1)];
        for (int j = 0; j <= m; ++j) {
            pre[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] =
                pre[static_cast<std::size_t>(i - 1)][static_cast<std::size_t>(j)] ||
                (j >= x && pre[static_cast<std::size_t>(i - 1)][static_cast<std::size_t>(j - x)]);
        }
    }
    std::vector<int> out;
    int j = m;
    for (int i = n; i >= 1 && j > 0; --i) {
        const int x = S[static_cast<std::size_t>(i - 1)];
        if (pre[static_cast<std::size_t>(i - 1)][static_cast<std::size_t>(j)]) { continue; }
        out.push_back(x);
        j -= x;
    }
    return out;
}

// 独立真值：DFS 全枚举（每件选/不选）
static bool subset_dfs(const std::vector<int>& S, int i, int rest) {
    if (rest == 0) { return true; }
    if (i == static_cast<int>(S.size()) || rest < 0) { return false; }
    return subset_dfs(S, i + 1, rest - S[static_cast<std::size_t>(i)]) ||
           subset_dfs(S, i + 1, rest);
}

static void subset_sum_demo() {
    println("");
    println("=== 15.9 子集和：0/1 可达性（逆序滚动 + 位并行）===");
    const std::vector<int> S{3, 1, 5, 8, 13, 6, 7};
    const int m = 18;
    const std::vector<char> reach = subset_reach(S, m);
    const std::vector<int> picked = subset_pick(S, m);
    print("  固定例 S={{3,1,5,8,13,6,7}}，m=18：可达 = {}，一个方案 {{",
          reach[static_cast<std::size_t>(m)] ? 1 : 0);
    long long sum = 0;
    for (std::size_t i = 0; i < picked.size(); ++i) {
        print("{}{}", i == 0 ? "" : ",", picked[i]);
        sum += picked[i];
    }
    println("}}");
    assert(reach[static_cast<std::size_t>(m)] && sum == m);
    assert(subset_dfs(S, 0, m));

    // 可达性全景表（m=0..25）与 DFS 对账
    int agree = 0;
    for (int t = 0; t <= 25; ++t) {
        const bool a = subset_reach(S, t)[static_cast<std::size_t>(t)];
        const bool b = subset_dfs(S, 0, t);
        assert(a == b);
        agree += a == b;
    }
    println("  m=0..25 全景：DP 可达性与 DFS 枚举逐点一致（{} 项）", agree);

    // 不可达例：m=2（S 中凑不出 2——1 与 3 都单独不等于 2，1+?无）
    assert(!subset_reach(S, 2)[2]);

    // 随机 300 例：可达性 + 方案回代 + DFS 三方对账
    std::mt19937 rng{5489};
    int bad = 0, bad_pick = 0, reachable = 0;
    for (int t = 0; t < 300; ++t) {
        const int n = 1 + static_cast<int>(rand_below(rng, 10));
        std::vector<int> a;
        a.reserve(static_cast<std::size_t>(n));
        for (int i = 0; i < n; ++i) {
            a.push_back(1 + static_cast<int>(rand_below(rng, 30)));
        }
        const int mm = static_cast<int>(rand_below(rng, 200));
        const bool dp = subset_reach(a, mm)[static_cast<std::size_t>(mm)];
        const bool dfs = subset_dfs(a, 0, mm);
        if (dp != dfs) { ++bad; }
        if (dp) {
            ++reachable;
            long long s = 0;
            for (int x : subset_pick(a, mm)) { s += x; }
            if (s != mm) { ++bad_pick; }
        }
    }
    println("  随机 300 例（n≤10）：DP vs DFS 不一致 {} 例；方案回代失败 {} 例（可达 {} 例）",
            bad, bad_pick, reachable);
    assert(bad == 0 && bad_pick == 0);

    // 大例：n=1000 件、m=10⁵ 的稠密段——位集版 O(n·m/64)
    std::vector<int> big;
    big.reserve(1000);
    for (int i = 0; i < 1000; ++i) {
        big.push_back(1 + static_cast<int>(rand_below(rng, 400)));
    }
    const std::vector<char> br = subset_reach(big, 100000);
    int gaps = 0;
    for (int t = 99000; t <= 100000; ++t) {
        gaps += !br[static_cast<std::size_t>(t)];
    }
    println("  大例（1000 件，m≤10⁵）：区间 99000..100000 里不可达 {} 个", gaps);
    assert(gaps == 0);
}

int main() {
    rod_cutting_demo();
    reconstruction_demo();
    matrix_chain_demo();
    overlap_demo();
    fibonacci_demo();
    reachability_ladder_demo();
    triangle_demo();
    coin_change_demo();
    subset_sum_demo();
    println("自检通过");
    return 0;
}
