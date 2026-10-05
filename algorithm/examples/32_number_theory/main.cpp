// 32 数论与位运算。结构：32.1 欧几里得与扩展 gcd（Bézout）/
// 32.2 模运算：快速幂与乘法逆元/ 32.3 素性测试：Fermat 的失效与
// Miller-Rabin（Carmichael 数 561）/ 32.4 RSA 迷你全流程（n=3233 经典例）/
// 32.5 位运算技巧（popcount / n&(n-1) / 判 2 的幂 / 格雷码）/
// 32.6 整数次方三实现与溢出边界（朴素 vs 快速幂 vs 带检测版）/
// 32.7 高精度位向量大数（加减 + 乘小数 + n! 末 12 位 + Legendre 尾零数）。
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
#include <cstdio>
#include <cstdlib>
#include <cassert>
#include <cstdint>
#include <vector>

// ═══ 32.1 欧几里得与扩展 gcd ═══
// EUCLID(a,b)：gcd(a,b) = gcd(b, a mod b)；EXTENDED-EUCLID 顺带求 Bézout
// 系数 x,y 使 ax + by = gcd(a,b)。
static long long euclid_trace(long long a, long long b, long long& steps) {
    print("  辗转序列: {}", a);
    while (b != 0) {
        const long long r = a % b;
        a = b;
        b = r;
        ++steps;
        print(" → {}", a);
    }
    println("");
    return a;
}

static long long ext_gcd(long long a, long long b, long long& x, long long& y) {
    if (b == 0) { x = 1; y = 0; return a; }
    long long x1, y1;
    const long long g = ext_gcd(b, a % b, x1, y1);
    x = y1;
    y = x1 - (a / b) * y1;
    return g;
}

static void gcd_demo() {
    println("欧几里得 gcd(99, 78)：");
    long long steps = 0;
    const long long g = euclid_trace(99, 78, steps);
    println("  gcd = {}（辗转 {} 步）", g, steps);
    assert(g == 3);
    long long x, y;
    const long long g2 = ext_gcd(99, 78, x, y);
    println("  扩展 gcd：99·({}) + 78·({}) = {}（Bézout 恒等式 = gcd）", x, y, 99 * x + 78 * y);
    assert(g2 == 3 && 99 * x + 78 * y == 3);
}

// ═══ 32.2 模运算 ═══
// MODULAR-EXPONENTIATION：平方-相乘，Θ(lg b) 次乘法
static long long mod_pow(long long a, long long b, long long n, long long& mults) {
    long long result = 1;
    a %= n;
    while (b > 0) {
        if (b & 1) { result = result * a % n; ++mults; }
        a = a * a % n;
        ++mults;
        b >>= 1;
    }
    return result;
}

static void modular_demo() {
    long long mults = 0;
    const long long v = mod_pow(7, 560, 561, mults);
    println("模幂 7^560 mod 561 = {}（平方-相乘 {} 次乘法 vs 朴素 560 次）", v, mults);
    assert(v == 1);   // Fermat 小定理的「假象」——见 32.3
    // 乘法逆元：d ≡ e^{-1} (mod φ(n))：φ(3233) = 60·52 = 3120；17·2753 = 15·3120 + 1
    long long x, y;
    const long long g = ext_gcd(17, 3120, x, y);
    const long long inv = ((x % 3120) + 3120) % 3120;
    println("乘法逆元：17⁻¹ mod 3120 = {}（检查 17·{} mod 3120 = {}，gcd = {}）",
            inv, inv, 17 * inv % 3120, g);
    assert(inv == 2753 && 17 * inv % 3120 == 1 && g == 1);
}

// ═══ 32.3 素性测试：Fermat 的坑与 Miller-Rabin ═══
// 561 = 3·11·17 是 Carmichael 数：对所有 gcd(a,561)=1 的 a 都有
// a^560 ≡ 1 (mod 561)——Fermat 测试全被骗。Miller-Rabin 加「平方根
// 检查」拆穿它。
static bool miller_rabin(long long n, const std::vector<long long>& bases, bool& caught561) {
    if (n < 2) { return false; }
    if (n % 2 == 0) { return n == 2; }   // 只试除 2——基列表留给见证检验
    // n−1 = 2^s · d（d 奇）
    long long d = n - 1;
    int s = 0;
    while (d % 2 == 0) { d /= 2; ++s; }
    for (long long a : bases) {
        long long x = 1, mults = 0;
        x = mod_pow(a, d, n, mults);
        if (x == 1 || x == n - 1) { continue; }
        bool composite = true;
        for (int r = 1; r < s; ++r) {
            x = x * x % n;
            if (x == n - 1) { composite = false; break; }
        }
        if (composite) {
            if (n == 561) { caught561 = true; }
            return false;   // a 是合数性的 witness
        }
    }
    return true;            // 素性 probable（对所给基）
}

static void primality_demo() {
    println("素性测试（基 = {{2,3,5,7}}）：");
    bool caught = false;
    const bool b561 = miller_rabin(561, {2, 3, 5, 7}, caught);
    println("  561 = 3·11·17（Carmichael 数）：Fermat 测试 7^560≡1 被骗，"
            "Miller-Rabin 判为素 = {}（基 2 即为 witness，拆穿 = {}）",
            b561 ? 1 : 0, caught ? 1 : 0);
    assert(!b561 && caught);
    const bool b7919 = miller_rabin(7919, {2, 3, 5, 7}, caught);
    const bool b104729 = miller_rabin(104729, {2, 3, 5, 7}, caught);
    const bool b3233 = miller_rabin(3233, {2, 3, 5, 7}, caught);
    println("  7919 判素 = {}（第 1000 个素数），104729 判素 = {}（第 10000 个），"
            "3233 判素 = {}（= 61·53，正确识破）",
            b7919 ? 1 : 0, b104729 ? 1 : 0, b3233 ? 1 : 0);
    assert(b7919 && b104729 && !b3233);
}

// ═══ 32.4 RSA 迷你全流程（CLRS 31.7? 经典参数 n=3233）═══
static void rsa_demo() {
    // p=61, q=53 → n=3233, φ=3120, e=17, d=2753（17·2753 = 46801 = 15·3120+1）
    const long long p = 61, q = 53;
    const long long n = p * q;
    const long long phi = (p - 1) * (q - 1);
    const long long e = 17;
    long long x, y;
    ext_gcd(e, phi, x, y);
    const long long d = ((x % phi) + phi) % phi;
    println("RSA（p=61, q=53）：n = {}, φ(n) = {}, e = {}, d = e⁻¹ = {}", n, phi, e, d);
    assert(n == 3233 && phi == 3120 && d == 2753);
    // 加密 m=65（经典例）：c = 65^17 mod 3233 = 2790
    long long m1 = 0;
    const long long m = 65;
    const long long c = mod_pow(m, e, n, m1);
    println("  加密：c = 65^17 mod 3233 = {}", c);
    assert(c == 2790);
    long long m2 = 0;
    const long long back = mod_pow(c, d, n, m2);
    println("  解密：m = 2790^2753 mod 3233 = {}（= 原文 65，RSA 闭环）", back);
    assert(back == 65);
    // 正确性根基：ed ≡ 1 (mod φ) ⟹ m^{ed} ≡ m (mod n)（费马小定理 × CRT）
    println("  正确性：ed = 17·2753 = {} = 15·φ + 1（费马小定理 + CRT ⇒ m^{{ed}} ≡ m）",
            e * d);
    assert((e * d - 1) % phi == 0);
}

// ═══ 32.5 位运算技巧：popcount / 清最低位 / 判2的幂 / 隔位抽取 ═══
// 这些技巧不是「杂技」，而是同一件事的不同侧面：**用位运算把「逐位判断」
// 换成「一次算术操作」**，复杂度从 O(log n) 次循环降到 O(1)（对固定宽度）。
static int popcount_naive(unsigned long long x) {
    int k = 0;
    while (x != 0) { k += static_cast<int>(x & 1ULL); x >>= 1; }   // 逐位移位
    return k;
}

// 每次清掉最低的一个 1：x &= (x-1)。循环次数 = 1 的个数。
static int popcount_bk(unsigned long long x, long long& steps) {
    int k = 0;
    while (x != 0) { x &= (x - 1); ++k; ++steps; }
    return k;
}

// 硬件指令版：x86-64 的 POPCNT 指令。std::popcount 会在 -mpopcnt /
// -march=native 下自动用上，串起来的 popcount 是并行前缀和的基础。
static int popcount_hw(unsigned long long x) {
    return std::popcount(x);
}

static void bit_tricks_demo() {
    println("");
    println("=== 32.5 位运算技巧 ===");
    const auto hex = [](unsigned long long v) {
        char buf[32];
        std::snprintf(buf, sizeof(buf), "0x%llX", v);
        return std::string(buf);
    };
    constexpr unsigned long long samples[] = {
        0ULL, 1ULL, 255ULL, 1023ULL, 0x8000000000000000ULL,
        0xF0F0F0F0F0F0F0F0ULL, 0x8000000000000001ULL,
    };
    long long bk_steps = 0;
    println("{:>20}  {:>4} {:>9} {:>4}", "x（十六进制）", "逐位", "n&(n-1)", "硬件");
    for (const unsigned long long x : samples) {
        const int a = popcount_naive(x);
        const int b = popcount_bk(x, bk_steps);
        const int c = popcount_hw(x);
        println("{:>20}  {:>4} {:>9} {:>4}", hex(x), a, b, c);
        assert(a == b && b == c);
    }
    println("  n&(n-1) 全程共 {} 次循环——恰等于样本里 1 的总个数；", bk_steps);
    println("  差别在于它每轮只碰一个 1（x 直接缩到下一个 1），逐位法要扫全 64 位。");

    // 判 2 的幂：只有 1 位为 1 ⟺ x & (x-1) == 0（且 x != 0）
    println("");
    println("判 2 的幂（x > 0 且 (x & (x-1)) == 0）：");
    for (const unsigned long long v : {1ULL, 2ULL, 3ULL, 16ULL, 1024ULL,
                                        (1ULL << 62), (1ULL << 62) + 1ULL}) {
        const bool pow2 = (v & (v - 1)) == 0;
        println("  {:>22} -> {}", hex(v), pow2);
        assert(pow2 == std::has_single_bit(v));
    }
    println("  等价物 std::has_single_bit 对 0 返回 false，比手写更安全——");
    println("  手写 (x & (x-1)) == 0 对 x=0 也成立，这是最容易漏的边界。");

    // Brian Kernighan 的经典题：造 1010…1010
    println("");
    println("Brian Kernighan 经典题：造 1010…1010（偶数位为 1）");
    constexpr unsigned long long mask = 0x5555555555555555ULL;
    unsigned long long built = 0;
    for (int i = 0; i < 32; ++i) { built |= (1ULL << (2 * i)); }
    println("  常量 0x5555555555555555 与循环构造值一致 = {}", mask == built);
    assert(mask == built);
    constexpr unsigned long long complement = 0xAAAAAAAAAAAAAAAALL;
    println("  互补掩码 0xAAAA... & 0x5555... = {}（0 = 两组掩码不重叠）",
            hex(complement & mask));
    assert((complement & mask) == 0);

    // 格雷码：g = n ^ (n >> 1)，相邻两个数只差 1 位
    println("");
    println("格雷码 g = n ^ (n >> 1)：相邻数恰好差 1 位");
    println("  n : g(n)    相邻差几位");
    for (unsigned long long n = 0; n < 8; ++n) {
        const unsigned long long g = n ^ (n >> 1);
        unsigned long long diff = 0;
        if (n != 0) {
            const unsigned long long pv = (n - 1) ^ ((n - 1) >> 1);
            diff = g ^ pv;
        }
        int bits = 0;
        while (diff != 0) { diff &= (diff - 1); ++bits; }
        println("  {:>2}: {:>4}        {}", n, hex(g), bits);
        assert(bits == (n == 0 ? 0 : 1));
    }
}

// ═══ 32.6 整数次方 a^n：三种实现与溢出边界 ═══
// 这是「快速幂」在**不带模**场景的版本，也是第 31.6 节 mod_pow 的原形。
// 关键区别：mod 版本每步可以取模，中间量永远在 [0,n) 内；不带模版本中间量
// 是真实值，溢出是**静默且不可逆**的，必须提前判定。
static long long pow_naive(long long a, int n) {
    long long r = 1;
    for (int i = 0; i < n; ++i) { r *= a; }       // n 次乘法
    return r;
}

static long long pow_fast(long long a, int n) {
    long long r = 1;
    while (n > 0) {
        if (n & 1) { r *= a; }
        a *= a;
        n >>= 1;
    }
    return r;
}

// 带溢出检测的版本：全程用 __int128 做中间量（不触碰 int64 的溢出 = 不 UB），
// 并且**在乘法之前**用除法预判大小，绝不依赖「先乘再看符号」——后者是 UB，
// 编译器有权据此删掉分支。
//
// 哨兵技巧：一旦发现 base² 超出上界，就把 base 换成一个"绝对值大于上界"
// 的哨兵 S = mag+1。之后任何一次「用 base 累乘」都会因为
// |r| > mag/|S| = 0 而立刻判定溢出；但若后续位都是 0，哨兵不会被用到，
// 结果依然正确。
//
// 参数是**最大绝对值** mag，而不是 int64 上限——因为 int64 的负向空间比
// 正向多一位：|-2^63| = 2^63 = INT64_MAX + 1，恰好能装下但比 INT64_MAX 大。
// 用 mag 表达才不用在代码里做「±(INT64_MAX+1)」这种容易溢出的算术。
static bool pow_checked(long long a, int n, __int128 mag, long long& out) {
    const __int128 lo = -mag;                         // 允许恰好 -2^63
    const __int128 SENTINEL = mag + 1;                // |SENTINEL| > mag
    auto abs128 = [](__int128 v) { return v < 0 ? -v : v; };

    __int128 r = 1;
    __int128 base = a;
    if (abs128(base) > mag) { return false; }          // 底数本身就超界
    while (n > 0) {
        if ((n & 1) != 0) {
            if (base != 0 && abs128(r) > mag / abs128(base)) { return false; }
            r *= base;
        }
        n >>= 1;
        if (n == 0) { break; }
        // 预判 base*base 是否仍在界内；否则换成哨兵
        base = (base != 0 && abs128(base) > mag / abs128(base)) ? SENTINEL
                                                                 : base * base;
    }
    if (r > mag || r < lo) { return false; }
    out = static_cast<long long>(r);
    return true;
}

// Legendre 公式的参考实现（递归版，用于对账）
static int zeros_of(int n) {
    return (n < 5) ? 0 : n / 5 + zeros_of(n / 5);
}

static void pow_demo() {
    println("");
    println("=== 32.6 整数次方 a^n：朴素 vs 快速幂 ===");
    println("{:>4} {:>22} {:>22}  {} / {}", "n", "3^n（朴素）", "3^n（快速幂）",
            "朴素乘法", "快速幂乘法");
    for (const int n : {1, 2, 5, 10, 19, 20, 39, 40}) {
        const long long v1 = pow_naive(3, n);
        const long long v2 = pow_fast(3, n);
        const int fast = 2 * (32 - std::countl_zero(static_cast<unsigned>(n))) - 1;
        println("{:>4} {:>22} {:>22}  {:>8} / {}", n, v1, v2, n, fast);
        assert(v1 == v2);
    }
    println("  朴素 = n 次乘法，快速幂 ≈ 2*ceil(lg2 n) - 1 次；n=40 时 40 -> 11 次。");
    println("  但两者的溢出点完全一样（都停在 3^39）——真实值不会因为乘法变少而变小。");
    println("  快速幂省的是时间，不是表示范围。");

    constexpr __int128 kMag = static_cast<__int128>(INT64_MAX) + 1;  // 2^63
    println("");
    println("  溢出边界（int64 负向能到 -2^63，正向上限 9223372036854775807）：");
    int last = 0;
    long long last_val = 1;
    for (int n = 1; n <= 41; ++n) {
        long long v = 0;
        if (!pow_checked(3, n, kMag, v)) { break; }
        last = n;
        last_val = v;
    }
    println("    3^{} = {}   <- 最后一个装得下的", last, last_val);
    println("    3^{} = 12157665459056928801 已超上限 -> 转高精度（32.7）",
            last + 1);
    assert(last == 39);

    long long o = 0;
    const bool ok63 = pow_checked(-2, 63, kMag, o);
    println("");
    println("  负底数边界：-2^63 = {} 装得下（正是 INT64_MIN），-2^64 装不下",
            INT64_MIN);
    assert(ok63);
    assert(o == INT64_MIN);
    assert(!pow_checked(-2, 64, kMag, o));
    println("  pow_checked 的参数是**最大绝对值** mag = 2^63，而不是 INT64_MAX：");
    println("  int64 的负向空间比正向多一位，|-2^63| = INT64_MAX + 1，恰好装得下。");
    println("  所以实现用「除法预判」而不是「先乘再看符号」——后者依赖 UB。");
}

// ═══ 32.7 高精度：十进制位向量大数 ═══
// 最小可用的大数表示：每个元素存一位十进制数（低位在前），乘法就是小学
// 竖式。目的不是打败 GMP，而是看清「高精度 = 数组 + 逐位进位」这个模式。
class BigDec {
public:
    BigDec() : d_(1, 0) {}
    explicit BigDec(long long v) {                     // 构造（含负数）
        if (v == 0) { d_ = {0}; return; }
        const bool neg = v < 0;
        unsigned long long u = neg ? 0ULL - static_cast<unsigned long long>(v)
                                   : static_cast<unsigned long long>(v);
        while (u != 0) { d_.push_back(static_cast<int>(u % 10)); u /= 10; }
        if (neg) { d_.push_back(-1); }                 // 最高位存 -1 作符号位
    }
    bool negative() const { return d_.back() < 0; }
    std::size_t size() const { return d_.size() - (negative() ? 1u : 0u); }
    std::size_t digits_size() const { return d_.size(); }
    std::string str() const {
        if (d_.size() == 1 && d_[0] == 0) { return "0"; }
        std::string out;
        if (negative()) { out += '-'; }
// 后置递减：循环体里看到的 i 是自减**后**的值，所以起点写 size（不是 size-1）
    const std::size_t start = negative() ? d_.size() - 1 : d_.size();
    for (std::size_t i = start; i-- > 0;) {        // 负数跳过最高位的符号位 -1
        out += static_cast<char>('0' + std::abs(d_[i]));
    }
        return out;
    }
    // a += b：逐位加 + 连锁进位（够用即可，不追求通用大数库）
    BigDec& add(const BigDec& b) {
        const std::size_t n = std::max(d_.size(), b.d_.size());
        d_.resize(n, 0);
        int carry = 0;
        for (std::size_t i = 0; i < n; ++i) {
            const int sum = d_[i] + carry + (i < b.d_.size() ? b.d_[i] : 0);
            carry = sum / 10;
            d_[i] = sum % 10;
        }
        if (carry != 0) { d_.push_back(carry); }
        return *this;
    }
    // a *= k（k 为小整数）：最常用的一步（乘 10、加 1）
    BigDec& mul_small(long long k) {
        long long carry = 0;
        for (int& digit : d_) {
            const long long v = static_cast<long long>(digit) * k + carry;
            digit = static_cast<int>(v % 10);
            carry = v / 10;
        }
        while (carry != 0) {
            d_.push_back(static_cast<int>(carry % 10));
            carry /= 10;
        }
        return *this;
    }
    static BigDec pow10(int n) {
        BigDec r;
        r.d_ = std::vector<int>(static_cast<std::size_t>(n), 0);
        r.d_.push_back(1);                             // 1 后面 n 个 0
        return r;
    }

private:
    std::vector<int> d_;      // 低位在前；d_.back() 为 -1 时表示负数
};

static void bigdec_demo() {
    println("");
    println("=== 32.7 高精度：位向量大数 ===");
    BigDec a{999};
    a.add(BigDec{1});
    println("  999 + 1 = {}（连进位：最高位 9 -> 0 再进 1）", a.str());
    assert(a.str() == "1000");
    BigDec b{7};
    b.mul_small(999);
    println("  7 * 999 = {}（逐位乘 + 连锁进位）", b.str());
    assert(b.str() == "6993");
    print("  10^0..10^6 =");
    for (int k = 0; k <= 6; ++k) { print(" {}", BigDec::pow10(k).str()); }
    println("");
    assert(BigDec::pow10(6).str() == "1000000");

    BigDec neg{-25};
    println("  负数 -25：位向量长度 = {}（含符号位），字符串 = {}",
            neg.digits_size(), neg.str());
    assert(neg.negative() && neg.str() == "-25");

    // 用大数算 long long 装不下的 3^40
    BigDec p{1};
    for (int i = 0; i < 40; ++i) { p.mul_small(3); }
    println("  3^40 = {}（{} 位；long long 到 3^39 就满了）", p.str(), p.size());
    assert(p.str() == "12157665459056928801");

    println("");
    println("  位数与代价：10^k 有 k+1 位，两数相乘是 O(位数之积) 次单步运算");
    for (const int k : {3, 5, 7, 10, 20}) {
        println("    10^{:<2} 需要 {:>2} 位", k, k + 1);
    }
    println("  所以「打印 1 到 10^n」在高精度下是 O(n * 10^n)：n 每加 1 工作量乘 10。");
    println("  真要打印 10^6 本身就一百万位——这类题的难度不在算法，在 I/O。");

    println("");
    println("  n! 末 12 位（mod 10^12，模数装得进 long long）：");
    constexpr long long mod = 1000000000000LL;
    for (const int n : {10, 15, 20, 25}) {
        long long f = 1;
        for (int i = 2; i <= n; ++i) { f = f * i % mod; }
        println("    {:>2}! = {:>13}", n, f);
    }
    println("  对照：25! = 15511210043330985984000000，末 12 位 = 985984000000");

    println("");
    println("  n! 末尾零的个数（Legendre 公式 sum floor(n/5^k)）：");
    for (const int n : {10, 25, 100, 1000}) {
        int zeros = 0;
        for (int q = n / 5; q > 0; q /= 5) { zeros += q; }
        println("    {:>4}! 末尾 {:>3} 个零", n, zeros);
        assert(zeros == zeros_of(n));
    }
    println("  迭代版与递归版逐项相等（5 的幂贡献 1、25 再 +1、125 再 +1……）。");
}

int main() {
    gcd_demo();
    modular_demo();
    primality_demo();
    rsa_demo();
    bit_tricks_demo();
    pow_demo();
    bigdec_demo();
    println("自检通过");
    return 0;
}
