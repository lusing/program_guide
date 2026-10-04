// 32 数论算法（CLRS 第 31 章）。结构：32.1 欧几里得与扩展 gcd（Bézout）/
// 32.2 模运算：快速幂与乘法逆元 / 32.3 素性测试：Fermat 的失效与
// Miller-Rabin（Carmichael 数 561）/ 32.4 RSA 迷你全流程（n=3233 经典例）。
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

#include <array>
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

int main() {
    gcd_demo();
    modular_demo();
    primality_demo();
    rsa_demo();
    println("自检通过");
    return 0;
}
