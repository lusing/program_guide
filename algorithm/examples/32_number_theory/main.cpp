// 32 数论与位运算。结构：32.1 欧几里得与扩展 gcd（Bézout）/
// 32.2 模运算：快速幂与乘法逆元/ 32.3 素性测试：Fermat 的失效与
// Miller-Rabin（Carmichael 数 561）/ 32.4 RSA 迷你全流程（n=3233 经典例）/
// 32.5 位运算技巧（popcount / n&(n-1) / 判 2 的幂 / 格雷码）/
// 32.6 整数次方三实现与溢出边界（朴素 vs 快速幂 vs 带检测版）/
// 32.7 高精度位向量大数（加减 + 乘小数 + n! 末 12 位 + Legendre 尾零数）/
// 32.8 线性同余方程 ax ≡ b (mod n)（判定 + 最小解 + 青蛙约会 + CRT 雏形）/
// 32.9 博弈 + 辗转相除：Euclid 游戏的必胜态（修正「双方都贪心」的错误模型）/
// 32.10 筛法的正确复杂度 Θ(n log log n) 与区间统计（前缀和 / 无序对去重）/
// 32.11 整数 n 次根：二分 + 饱和快速幂（对比「指数整除」数论判据）。
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
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cassert>
#include <cstdint>
#include <numeric>
#include <utility>
#include <vector>

// 十进制位数（只为打印用；纯除法循环，与高精度无关）
static int digits_of(long long v) {
    int d = 1;
    while (v >= 10) { v /= 10; ++d; }
    return d;
}

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

// 带溢出检测的版本：**在乘法之前**用除法预判大小，绝不依赖「先乘再看
// 符号」——那是 UB，编译器有权据此删掉分支。
//
// 可移植性坑（本工程实测）：最初实现把中间量放在 __int128 里——GCC/Clang
// 都过，MSVC 没有 __int128（/permissive- 下直接报错）。可移植写法是把
// **绝对值**放在 unsigned long long（上限 2^64−1，装得下哨兵 2^63+1），
// 符号单独用一个 bool 跟踪。
//
// 哨兵技巧：一旦发现 base² 超出上界，就把 base 换成一个"绝对值大于上界"
// 的哨兵 S = mag+1 = 2^63+1（unsigned 装得下）。之后任何一次「用 base 累乘」
// 都会因为 |r| > mag/|S| = 0 而立刻判定溢出；但若后续位都是 0，哨兵不会被
// 用到，结果依然正确——**这正是不能在平方溢出时提前 return 的原因**：
// 剩余位全 0 时结果是合法的，提前 return 会误报。
//
// 边界取**最大绝对值** mag = 2^63 而不是 INT64_MAX——int64 的负向空间比
// 正向多一位：|-2^63| = 2^63 = INT64_MAX + 1，恰好能装下。
static bool pow_checked(long long a, int n, long long& out) {
    constexpr unsigned long long kMag =
        static_cast<unsigned long long>(INT64_MAX) + 1;   // 2^63
    auto absu = [](long long v) -> unsigned long long {
        return v < 0 ? ~static_cast<unsigned long long>(v) + 1ULL
                     : static_cast<unsigned long long>(v);
    };
    if (n < 0) { return false; }
    unsigned long long r = 1;                // |r| ≤ kMag 恒成立，unsigned 不溢出
    unsigned long long base = absu(a);       // |base|；哨兵 kMag+1 也装得下
    if (base > kMag) { return false; }       // 底数本身就超界
    // 结果符号 = (-1)^n：只由**总指数的奇偶**决定（a 的偶数次幂恒正）。
    // 别按「奇数位个数」翻符号——那是设置位个数，不是指数（63 有 6 个
    // 设置位但 63 是奇数，本示例第一版就错在这）。
    const bool neg = (a < 0) && ((n & 1) != 0);
    while (n > 0) {
        if ((n & 1) != 0) {
            if (base != 0 && r > kMag / base) { return false; }   // 除法预判
            r *= base;                        // ≤ kMag，unsigned 乘法不 UB
        }
        n >>= 1;
        if (n == 0) { break; }
        // 预判 base*base 是否仍在界内；否则换成哨兵（见上：不能提前 return）
        if (base != 0 && base > kMag / base) {
            base = kMag + 1;                  // 哨兵：|S| > mag
        } else {
            base *= base;
        }
    }
    // 收尾：|r| ≤ mag 且（若为正）严格小于 mag；负向允许恰好 -2^63
    if (r > kMag || (!neg && r == kMag)) { return false; }
    out = neg ? static_cast<long long>(~r + 1ULL) : static_cast<long long>(r);
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

    println("");
    println("  溢出边界（int64 负向能到 -2^63，正向上限 9223372036854775807）：");
    int last = 0;
    long long last_val = 1;
    for (int n = 1; n <= 41; ++n) {
        long long v = 0;
        if (!pow_checked(3, n, v)) { break; }
        last = n;
        last_val = v;
    }
    println("    3^{} = {}   <- 最后一个装得下的", last, last_val);
    println("    3^{} = 12157665459056928801 已超上限 -> 转高精度（32.7）",
            last + 1);
    assert(last == 39);

    long long o = 0;
    const bool ok63 = pow_checked(-2, 63, o);
    println("");
    println("  负底数边界：-2^63 = {} 装得下（正是 INT64_MIN），-2^64 装不下",
            INT64_MIN);
    assert(ok63);
    assert(o == INT64_MIN);
    assert(!pow_checked(-2, 64, o));
    println("  pow_checked 的边界是**最大绝对值** 2^63，而不是 INT64_MAX：");
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

// ═══ 32.8 线性同余方程 ax ≡ b (mod n) ═══
// 判定：d = gcd(a,n)；有解 ⟺ d | b。有解时模 n 下**恰有 d 个解**
//   x_i = x0 + i·(n/d)，i = 0..d-1；而模 n/d 下 x0 是**唯一**解。
// 求最小非负解：扩展 gcd 得 (d, u, v) = (a, n) ⟹ a·u ≡ d (mod n)
//   ⟹ a·(u·b/d) ≡ b (mod n)，故 x0 = u·(b/d) mod (n/d)。
static long long norm_mod(long long x, long long m) {
    // C++ 的 % 对负数返回**负**余数，同余运算必须先归一化到 [0, m)
    return ((x % m) + m) % m;
}

// 返回值 = 最小非负解（在 [0, n/d) 上）；d = gcd(a, n)；无解时返回 -1
static long long solve_linear_congruence(long long a, long long b, long long n,
                                         long long& d, int& solutionCount) {
    a = norm_mod(a, n);
    b = norm_mod(b, n);
    long long u = 0, v = 0;
    d = ext_gcd(a, n, u, v);              // a·u + n·v = d
    solutionCount = 0;
    if (d == 0 || b % d != 0) { return -1; }
    // 特解 x = u·(b/d) mod (n/d)。两个因子都先归一化到 [0, n/d) 再乘：
    //   x0 = (u mod (n/d))·((b/d) mod (n/d)) mod (n/d)
    // 归一化不改变解（都差 n/d 的整数倍），但保证乘积 < (n/d)²。
    // 只要 n/d ≤ 3037000499 = ⌊√(2^63−1)⌋，乘积必在 int64 内——
    // 这个「平方不炸 int64 的最大因子」值得背下来；更大的模就得把乘法
    // 拆成多次小乘（俄罗斯农民式），或升宽类型（MSVC 没有 __int128）。
    const long long nd = n / d;
    const long long u0 = norm_mod(u, nd);
    const long long b0 = norm_mod(b / d, nd);
    assert(nd <= 3037000499LL);           // 本教程的数据量级远达不到
    solutionCount = static_cast<int>(d);  // 模 n 下 d 个解，模 n/d 下唯一
    return norm_mod(u0 * b0, nd);
}

// 环上两蛙：x 处每轮跳 m、y 处每轮跳 n，环长 L。求最少跳跃次数使其同点。
// 建模：跳 z 次后相遇 ⟺ x + m·z ≡ y + n·z (mod L) ⟺ (m−n)·z ≡ y−x (mod L)
static long long frog_meeting_jumps(long long L, long long x, long long y,
                                    long long m, long long n, bool& possible) {
    long long d = 0;
    int cnt = 0;
    const long long z = solve_linear_congruence(m - n, y - x, L, d, cnt);
    if (z < 0) { possible = false; return -1; }
    possible = true;
    // z = 0 表示「一开始就在同一点」；题面要「至少跳一次」故取最小正解
    return (z == 0) ? (L / d) : z;
}

static void congruence_demo() {
    println("");
    println("=== 32.8 线性同余方程 ax ≡ b (mod n) ===");

    // 负数取模必须先归一化：m−n 可能为负，y−x 也可能为负
    println("  C++ 的 % 对负数返回负余数：(-6) % 20 = {}，(-1) % 3 = {}",
            (-6) % 20, (-1) % 3);
    println("  归一化 ((x % m) + m) % m：(-6) -> {}，(-1) -> {}",
            norm_mod(-6, 20), norm_mod(-1, 3));
    assert(norm_mod(-6, 20) == 14 && norm_mod(-1, 3) == 2);

    struct Case { long long a, b, n; };
    // 3x ≡ 1 (mod 7)：gcd=1，唯一解 x=5；4x ≡ 2 (mod 6)：gcd=2，模 6 下 2 个解；
    // 2x ≡ 1 (mod 4)：gcd=2 ∤ 1，无解；0x ≡ 0 (mod 5)：gcd=5，5 个解
    for (const Case& c : {Case{3, 1, 7}, Case{4, 2, 6}, Case{2, 1, 4}, Case{0, 0, 5}}) {
        long long d = 0;
        int cnt = 0;
        const long long x0 = solve_linear_congruence(c.a, c.b, c.n, d, cnt);
        if (x0 < 0) {
            println("  {}x ≡ {} (mod {})：d = {} 不整除 {} ⟹ 无解", c.a, c.b, c.n,
                    d, c.b);
            assert(c.b % d != 0);
            continue;
        }
        const long long period = c.n / d;
        print("  {}x ≡ {} (mod {})：d = {}，模 {} 下 {} 个解 [", c.a, c.b, c.n,
              d, c.n, cnt);
        for (int i = 0; i < cnt; ++i) { print("{} ", x0 + i * period); }
        println("]，模 {} 下唯一解 = {}", period, x0);
        // 逐个解回代验证
        for (int i = 0; i < cnt; ++i) {
            assert(norm_mod(c.a * (x0 + i * period), c.n) == norm_mod(c.b, c.n));
        }
        assert(cnt == static_cast<int>(d));
    }

    // 青蛙的约会：(m−n)·z ≡ y−x (mod L)
    println("");
    println("  环上两蛙相距：跳 z 次同点 ⟺ (m−n)z ≡ y−x (mod L)");
    struct FrogCase { long long L, x, y, m, n; };
    // 样例：L=20, x=4, y=8, m=7, n=3 ⟹ 4z ≡ 4 (mod 20) ⟹ z ≡ 1 (mod 5) ⟹ 1 次
    //       L=10, x=1, y=2, m=2, n=4 ⟹ −2z ≡ 1 (mod 10)，gcd=2 ∤ 1 ⟹ 无解
    for (const FrogCase& f : {FrogCase{20, 4, 8, 7, 3}, FrogCase{10, 1, 2, 2, 4},
                              FrogCase{12, 0, 6, 3, 5}}) {
        bool ok = false;
        const long long z = frog_meeting_jumps(f.L, f.x, f.y, f.m, f.n, ok);
        if (!ok) {
            println("    L={} x={} y={} m={} n={}：gcd(m−n, L) = {} 不整除 {} ⟹ 不可能",
                    f.L, f.x, f.y, f.m, f.n, std::gcd(std::abs(f.m - f.n), f.L),
                    std::abs(f.y - f.x));
            continue;
        }
        // 直接模拟核对：这是「建模对不对」的裁判
        const long long p1 = norm_mod(f.x + f.m * z, f.L);
        const long long p2 = norm_mod(f.y + f.n * z, f.L);
        println("    L={} x={} y={} m={} n={}：{} 次⟹ 落点 {} 与 {} 相同", f.L, f.x,
                f.y, f.m, f.n, z, p1, p2);
        assert(p1 == p2);
    }

    // 中国剩余定理的雏形：逐个合并 x ≡ r_i (mod m_i)
    // x ≡ 2 (mod 3), x ≡ 3 (mod 5), x ≡ 2 (mod 7) ⟹ x ≡ 23 (mod 105)
    println("");
    println("  中国剩余定理雏形：逐对合并同余方程（{}x ≡ 2、{}x ≡ 3、{}x ≡ 2 ⟹ 模 105）",
            3, 5, 7);
    long long r = 0, mod = 1;
    for (const auto& [mi, ri] : {std::pair{3, 2}, std::pair{5, 3}, std::pair{7, 2}}) {
        // 已有 x ≡ r (mod mod)，要并入 x ≡ ri (mod mi)：
        // 令 x = r + mod·t，代入得 mod·t ≡ ri − r (mod mi)
        long long d = 0;
        int cnt = 0;
        const long long t = solve_linear_congruence(mod, ri - r, mi, d, cnt);
        assert(t >= 0);
        const long long lcm = mod / d * mi;
        r = norm_mod(r + mod * t, lcm);
        mod = lcm;
    }
    println("    合并结果 x ≡ {} (mod {})：代回验证 x mod 3/5/7 = {}/{}/{} ⟹ 满足 "
            "x ≡ 2, 3, 2", r, mod, r % 3, r % 5, r % 7);
    assert(r == 23 && mod == 105 && r % 3 == 2 && r % 5 == 3 && r % 7 == 2);
}

// ═══ 32.9 博弈 + 辗转相除：Euclid 游戏的必胜态 ═══
// 规则：Stan 先手，双方轮流从较大的数中减去较小的数的**任意正整数倍**
//       （结果须非负），使结果为 0 的一方获胜。
//
// 状态 W(a,b) = 当前行动者是否必胜（a ≥ b > 0）。递推：
//   - a % b == 0 ⟹ 一步把 b 减到 0，必胜；
//   - a / b ≥ 2   ⟹ 必胜（见下方证明）；
//   - b < a < 2b 且 b ∤ a ⟹ **只有唯一合法着** (b, a−b)，胜负取反。
// 注意第三种情形**不是**「必败」——这是本节最容易写错的地方。
static bool euclid_stan_wins(long long a, long long b) {
    if (a < b) { std::swap(a, b); }
    bool stan_turn = true;
    for (;;) {
        if (a % b == 0 || a / b >= 2) { return stan_turn; }
        const long long r = a - b;      // 唯一合法着：a < 2b ⟹ 只能减 1 倍
        a = b;
        b = r;
        stan_turn = !stan_turn;         // 唯一的着法把必胜态让给对手 ⟹ 自己必败
    }
}

// 错误模型：双方都「贪心地」减掉尽可能多的倍数 ⟹ 游戏退化成辗转相除，
// 迭代次数的奇偶决定胜负。用于证伪。
static bool euclid_greedy_parity(long long a, long long b, int& steps) {
    if (a < b) { std::swap(a, b); }
    steps = 0;
    while (b != 0) {
        const long long r = a % b;
        a = b;
        b = r;
        ++steps;
    }
    return (steps % 2) == 1;
}

static void euclid_game_demo() {
    println("");
    println("=== 32.9 博弈 + 辗转相除：Euclid 游戏的必胜态 ===");
    println("  规则：轮流从较大的数中减去较小的数的任意正整数倍（结果须非负），");
    println("        使结果为 0 的一方获胜。W(a,b) = 当前行动者是否必胜：");
    println("        a % b == 0 → 必胜（一步归零）");
    println("        a / b >= 2   → 必胜（存在性引理：总能挑一个 k 把必败态留给对手）");
    println("        否则 b < a < 2b 且 b ∤ a → 唯一合法着，胜负**取反**");

    // 必败态（P-位置）枚举：max ≤ 12 —— 正是「商为 1、余非 0」的那一片
    print("  必败态（当前行动者必败）max <= 12：");
    for (long long a = 2; a <= 12; ++a) {
        for (long long b = 1; b < a; ++b) {
            if (!euclid_stan_wins(a, b)) { print("({},{}) ", a, b); }
        }
    }
    println("");
    // (3,2) 是最小的必败态：只能减 1 倍到 (2,1)，而 (2,1) 是必胜态
    assert(!euclid_stan_wins(3, 2) && euclid_stan_wins(2, 1));
    // 必胜 ⟺ 存在一步到必败态；逐个小状态核对这个不动点定义
    for (long long a = 2; a <= 60; ++a) {
        for (long long b = 1; b < a; ++b) {
            bool hasLosingChild = false;
            for (long long k = 1; k <= a / b && !hasLosingChild; ++k) {
                const long long r = a - k * b;
                if (r == 0) { hasLosingChild = true; break; }   // 一步归零
                if (!euclid_stan_wins(std::max(b, r), std::min(b, r))) {
                    hasLosingChild = true;
                }
            }
            assert(hasLosingChild == euclid_stan_wins(a, b));
        }
    }
    println("  核验：W(a,b) == 存在一步到必败态（对 2 <= a <= 60 全部 {} 对逐一比对）",
            60 * 59 / 2);
    println("        必胜态判据与博弈递推的不动点定义**逐项一致**");

    // 证伪「双方都贪心 ⟹ 退化成辗转相除，奇偶定胜负」
    println("");
    println("  错误直觉：双方都贪心地减掉尽可能多的倍数 ⟹ 退化成辗转相除，迭代次数");
    println("            的奇偶决定胜负。三个反例把它彻底否掉：");
    struct GC { long long a, b; const char* note; };
    for (const GC& g : {GC{7, 5, "商为 1、余非 0 ⟹ 唯一着恰好把必胜态让给对手"},
                        GC{9, 7, "同上：真后手胜，贪心却判先手胜"},
                        GC{5, 2, "反向错：贪心一步到 (3,2)，而 (3,2) 恰是必败态"}}) {
        int steps = 0;
        const bool truth = euclid_stan_wins(g.a, g.b);
        const bool greedy = euclid_greedy_parity(g.a, g.b, steps);
        println("    ({},{})：真值 = {}，贪心模型 = {}（辗转 {} 次，{}）{}",
                g.a, g.b, truth ? "先手胜" : "后手胜", greedy ? "先手胜" : "后手胜",
                steps, (steps % 2) == 1 ? "奇 ⟹ 判先手胜" : "偶 ⟹ 判后手胜", "");
        assert(truth != greedy);   // 三个反例上贪心模型全部判错
    }
    println("    (7,5) 的贪心模型输出「先手胜」，真值是「后手胜」——");
    println("    错因：贪心假设「减得越多越好」，但减掉 5 得到 (5,2) 是把必胜态");
    println("          送给对手；正确着法只有唯一一条，减得最少反而必胜。");
}

// ═══ 32.10 筛法的正确复杂度与区间统计 ═══
static std::vector<char> sift(long long n) {
    std::vector<char> isPrime(static_cast<std::size_t>(n) + 1, 1);
    if (n >= 0) { isPrime[0] = 0; }
    if (n >= 1) { isPrime[1] = 0; }
    for (long long i = 2; i * i <= n; ++i) {
        if (!isPrime[static_cast<std::size_t>(i)]) { continue; }
        for (long long j = i * i; j <= n; j += i) {
            isPrime[static_cast<std::size_t>(j)] = 0;
        }
    }
    return isPrime;
}

static void sieve_demo() {
    println("");
    println("=== 32.10 筛法的正确复杂度与区间统计 ===");

    // 划掉次数 = n·Σ_{p ≤ √n} 1/p = O(n ln ln √n) —— 不是 Θ(n²)
    constexpr long long kSieveN = 2000000;
    const auto isPrime = sift(kSieveN);
    long long marks = 0;
    for (long long p = 2; p * p <= kSieveN; ++p) {
        if (!isPrime[static_cast<std::size_t>(p)]) { continue; }
        for (long long j = p * p; j <= kSieveN; j += p) { ++marks; }
    }
    long long pi_cnt = 0;
    for (long long i = 2; i <= kSieveN; ++i) { pi_cnt += isPrime[static_cast<std::size_t>(i)]; }
    println("  埃氏筛 n = {}：划掉 {} 次 = {:.2f}·n，实际约 n·lnln(√n) = {:.2f}·n；π(n) = {}",
            kSieveN, marks, static_cast<double>(marks) / kSieveN,
            std::log(std::log(std::sqrt(static_cast<double>(kSieveN)))), pi_cnt);
    println("  若是 Θ(n²)：光「访问 j 的循环体」就要 {} 次，比实测多 {:.0f} 倍",
            kSieveN * kSieveN,
            static_cast<double>(kSieveN * kSieveN) / marks);
    assert(marks < kSieveN * 10);

    // π(n) ≈ n / ln n —— 不是 ln n
    println("");
    println("  素数计数 π(n) ≈ n / ln n（不是 ln n）：");
    println("  {:>10} {:>10} {:>14} {:>14}  {}", "n", "π(n)", "n/ln n", "ln n",
            "π 与 n/ln n 之比");
    for (const long long n : {100LL, 10000LL, 1000000LL}) {
        const auto pr = sift(n);
        long long c = 0;
        for (long long i = 2; i <= n; ++i) { c += pr[static_cast<std::size_t>(i)]; }
        const double nlogn = static_cast<double>(n) / std::log(static_cast<double>(n));
        println("  {:>10} {:>10} {:>14.0f} {:>14.2f}  {:.3f}", n, c, nlogn,
                std::log(static_cast<double>(n)),
                static_cast<double>(c) / nlogn);
        assert(c > 0);
    }
    println("  π(n) 与 n/ln n 同阶（比值趋于 1）；ln n 是**对数级**的量，");
    println("  与 π(n) 差 n/ln n 倍——把它当「n 以内有 ln n 个素数」是量级错误。");

    // 前缀和：区间素数个数降到 O(1)
    println("");
    println("  前缀和 pref[i] = π(i)：区间 [A,B] 的素数个数 = pref[B] − pref[A−1]，O(1)");
    constexpr long long kQ = 100000;
    const auto pq = sift(kQ);
    std::vector<int> pref(static_cast<std::size_t>(kQ) + 1, 0);
    for (long long i = 1; i <= kQ; ++i) {
        pref[static_cast<std::size_t>(i)] =
            pref[static_cast<std::size_t>(i - 1)] + pq[static_cast<std::size_t>(i)];
    }
    for (const auto& [A, B] : {std::pair{0LL, 9999LL}, std::pair{1LL, 5LL},
                               std::pair{99991LL, 100000LL}, std::pair{100LL, 200LL}}) {
        const int cnt = pref[static_cast<std::size_t>(B)] -
                         pref[static_cast<std::size_t>(A - 1 < 0 ? 0 : A - 1)];
        println("    [{}, {}] 内素数个数 = {} − {} = {}", A, B,
                pref[static_cast<std::size_t>(B)],
                pref[static_cast<std::size_t>(A - 1 < 0 ? 0 : A - 1)], cnt);
        assert(cnt >= 0);
    }
    assert(pref[9999] == 1229);      // π(9999) = 1229（经典样例 0 9999 → 1229）
    assert(pref[5] - pref[0] == 3);  // [1,5] 内是 2, 3, 5

    // 有序对 vs 无序对：数 n = p + q 只枚举 2p < n
    println("");
    println("  无序对去重：数 n = p + q（p ≤ q）的解时只枚举 p·2 < n（严格小于半）");
    for (const long long n : {10LL, 20LL, 100LL}) {
        int strict = 0, loose = 0;
        for (long long p = 2; p * 2 < n; ++p) {
            if (pq[static_cast<std::size_t>(p)] && pq[static_cast<std::size_t>(n - p)]) {
                ++strict;
            }
        }
        for (long long p = 2; p <= n - p; ++p) {   // p ≤ n−p，把 (5,5) 也算进来
            if (pq[static_cast<std::size_t>(p)] && pq[static_cast<std::size_t>(n - p)]) {
                ++loose;
            }
        }
        println("    n = {}：p·2 < n 得 {} 解；p ≤ n−p 得 {} 解{}", n, strict, loose,
                loose == strict ? "（n/2 不是素数，无差）" : "（差 1 ⟹ (n/2, n/2) 被多算）");
        if (n == 10) {
            println("      n = 10 只有 3+7 一解（5+5 不是：10/2 = 5 但 5+5 的两半相等，");
            println("      「严格小于半」把它排除；而 p ≤ n−p 会把它算进来得 2）");
            assert(strict == 1 && loose == 2);
        }
    }

    // 「严格小于 L 的素因子」必须用 SIFT(L−1)
    println("");
    println("  上界筛的边界：要 K 的**严格小于 L** 的最小素因子，必须 SIFT(L−1)");
    for (const auto& [K, L] : {std::pair{143LL, 11LL}, std::pair{143LL, 12LL},
                               std::pair{143LL, 13LL}, std::pair{143LL, 14LL}}) {
        const auto pr = sift(L - 1);           // 严格小于 L ⟹ 筛到 L−1
        long long smallest = -1;
        for (long long p = 2; p < L; ++p) {
            if (pr[static_cast<std::size_t>(p)] && K % p == 0) { smallest = p; break; }
        }
        // 错法：SIFT(L) 会把素数 L 本身放进表里
        long long wrong = -1;
        {
            const auto prw = sift(L);
            for (long long p = 2; p <= L; ++p) {
                if (prw[static_cast<std::size_t>(p)] && K % p == 0) { wrong = p; break; }
            }
        }
        println("    K = {} = 11·13, L = {}：SIFT(L−1) ⟹ {}；若误用 SIFT(L) ⟹ {}",
                K, L, smallest < 0 ? "GOOD" : "BAD", wrong < 0 ? "GOOD" : "BAD");
        if (K == 143 && L == 13) { assert(smallest == 11); }
        if (K == 143 && L == 11) { assert(smallest == -1 && wrong == 11); }
    }
    println("    K = 143 = 11·13、L = 11 时正确答案 GOOD（11 不严格小于 11），");
    println("    而 SIFT(11) 会误报 BAD 11——差一位的边界错误。");
}

// ═══ 32.11 整数 n 次根：二分 + 饱和快速幂 ═══
// 比较 k^n 与 p：每步乘完立刻判 > p 则返回 1（**饱和**）。
// k ≥ 1 时 k^n 单调递增 ⟹ 一旦超界，后续只会更大，可以立刻短路。
static int pow_compare(long long k, int n, long long p, int& mults) {
    long long acc = 1;
    for (int i = 0; i < n; ++i) {
        // 先除法预判：acc > p / k ⟺ acc·k > p（不依赖有符号溢出）
        if (acc > p / k) { return 1; }
        acc *= k;
        ++mults;
    }
    return (acc > p) ? 1 : ((acc < p) ? -1 : 0);
}

// 路线 A：二分答案。k ↦ k^n 在 k ≥ 1 上严格单调 ⟹ 唯一解
static long long nth_root(long long p, int n, long long hi, int& mults) {
    long long lo = 1;
    while (lo < hi) {
        const long long mid = lo + (hi - lo + 1) / 2;
        if (pow_compare(mid, n, p, mults) <= 0) { lo = mid; } else { hi = mid - 1; }
    }
    return lo;
}

static void nth_root_demo() {
    println("");
    println("=== 32.11 整数 n 次根：二分 + 饱和快速幂 ===");
    println("  路线 A（工程可行）：二分答案 k ∈ [1, 上界]，用**饱和乘法**比较 k^n 与 p。");
    println("  饱和 = 每步乘完立刻判 > p 则返回；k ≥ 1 时 k^n 单调递增，超界即可短路。");

    // p = k^n 的构造：选 k 与 n，算出 p，再让算法从 p 反推 k。
    // 三例的「水位」刻意各不相同：k^n 装得下但 k 很大（饱和在高位短路）、
    // k 很小而 n 很大（循环跑满 n 次）、以及 n 小。
    for (const auto& [k, n] : {std::pair{2LL, 62}, std::pair{3LL, 39},
                               std::pair{7LL, 13}}) {
        long long p = 1;
        for (int i = 0; i < n; ++i) { p *= k; }
        int multsA = 0;
        const long long root = nth_root(p, n, 1000000000LL, multsA);
        int multsB = 0;
        const int cmp = pow_compare(root, n, p, multsB);
        println("    k^{} = {}（{} 位）⟹ 二分得 k = {}，回代比较 = {}（{} 次乘法）", n, p,
                digits_of(p), root, cmp == 0 ? "恰好相等" : (cmp > 0 ? "偏大" : "偏小"),
                multsA);
        assert(root == k && cmp == 0);
    }

    // 非完全幂：k^n 落在两个整数之间 ⟹ 取整
    println("");
    println("  非完全幂：饱和比较只给大小关系，取整由二分负责");
    for (const auto& [p, n] : {std::pair{1000000LL, 3}, std::pair{999999999LL, 2}}) {
        int mults = 0;
        const long long r = nth_root(p, n, 1000000000LL, mults);
        int m2 = 0, m3 = 0;
        const int lo = pow_compare(r, n, p, m2);
        const int hi = pow_compare(r + 1, n, p, m3);
        println("    n = {}: {} 的整数 {} 次根 = {}（{}^n {} p，{}^n {} p）", n, p, n, r,
                r, lo == 0 ? "=" : (lo < 0 ? "<" : ">"), r + 1,
                hi == 0 ? "=" : (hi < 0 ? "<" : ">"));
        assert(lo <= 0 && hi >= 0);
    }

    // 路线 B 的数论判据：k^n = p 有整数解 ⟺ p 的每个素因子指数都能被 n 整除
    println("");
    println("  路线 B（数论判据，结论漂亮但实现不可行）：");
    println("    算术基本定理 p = Π p_i^{{e_i}}，则 ∃k 使 k^n = p ⟺ 每个 e_i 都能被 n 整除。");
    println("    证明：k = Π q_j^{{f_j}} ⟹ k^n = Π q_j^{{n·f_j}}；与 p 的唯一分解逐项对撞，");
    println("          得 n·f_j = e_i，即每个 e_i 是 n 的倍数。反向显然（k = Π p_i^{{e_i/n}}）。");
    // 用 2^a·3^b 当 p：指数 a、b 显式，判据可手算核对
    struct PowerCase { long long a, b, n; };
    for (const PowerCase& c : {PowerCase{4, 2, 2}, PowerCase{4, 2, 3}, PowerCase{6, 3, 3}}) {
        const long long a = c.a, b = c.b;
        const int n = static_cast<int>(c.n);
        long long p = 1;
        for (long long i = 0; i < a; ++i) { p *= 2; }
        for (long long i = 0; i < b; ++i) { p *= 3; }
        const bool perfect = (a % c.n == 0) && (b % c.n == 0);
        int mults = 0;
        const long long root = nth_root(p, n, 1000000LL, mults);
        int mc = 0;
        const int cmp = pow_compare(root, n, p, mc);
        println("    p = 2^{}·3^{} = {}，n = {}：指数整除判据 = {}，二分得 k = {}，"
                "k^n {} p", a, b, p, n, perfect ? "是完全幂" : "不是完全幂", root,
                cmp == 0 ? "=" : (cmp > 0 ? ">" : "<"));
        assert(perfect == (cmp == 0));
    }
    println("    但要用路线 B，必须**完整分解 p**——p 可达 10^100 量级，分解它本身");
    println("    就是 32.12 的难题。结论对、路径不可行 ⟹ 工程上选路线 A。");

    // 饱和运算的通用价值
    println("");
    println("  饱和运算的通用价值（三个同款场景，同一段代码形状）：");
    println("    ① 比较 a^n 与 p：乘完判 > p 就返回（本节）");
    println("    ② 累加到超 100 位就停：大数不必算完，算到界就够");
    println("    ③ 判定「C(40,20) 是否超过 10^18」：多项式系数递推里同理");
    int mults = 0;
    const int cmp = pow_compare(10LL, 18, 999999999999999999LL, mults);
    println("    现场：10^18 vs (10^18 − 1) 比较结果 = {}（{} 次乘法就短路，"
            "没算到 10^18）", cmp > 0 ? "偏大" : (cmp < 0 ? "偏小" : "相等"), mults);
    assert(cmp > 0);
}

int main() {
    gcd_demo();
    modular_demo();
    primality_demo();
    rsa_demo();
    bit_tricks_demo();
    pow_demo();
    bigdec_demo();
    congruence_demo();
    euclid_game_demo();
    sieve_demo();
    nth_root_demo();
    println("自检通过");
    return 0;
}
