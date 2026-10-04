// 31 多项式与快速傅里叶变换（CLRS 第 30 章）。结构：31.1 DFT 与单位根
// 的周期性 / 31.2 递归 FFT（蝴蝶追踪）/ 31.3 卷积定理：多项式乘法 /
// 31.4 往返一致性（FFT→IFFT 复原）与大数乘法。
// 数值纪律：全程 std::complex<double>，打印定点 {:.2f} 与容差布尔——
// IEEE 复数算术按固定运算序确定（docs/01）。
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
#include <cmath>
#include <complex>
#include <cstdint>
#include <numbers>
#include <vector>

using CD = std::complex<double>;
static constexpr double kPi = std::numbers::pi;

// 递归 FFT（CLRS RECURSIVE-FFT，p.917）：
// 偶下标 / 奇下标分成两半递归，再用 w_n^k 蝴蝶合并。
// sign = +1 正变换（CLRS 的 ω = e^{+2πi/n}），−1 逆变换（逆变换后除 n）。
static void fft(std::vector<CD>& a, double sign) {
    const std::size_t n = a.size();
    if (n == 1) { return; }
    std::vector<CD> even(n / 2), odd(n / 2);
    for (std::size_t i = 0; i < n / 2; ++i) {
        even[i] = a[2 * i];
        odd[i] = a[2 * i + 1];
    }
    fft(even, sign);
    fft(odd, sign);
    const CD wn(std::cos(sign * 2 * kPi / static_cast<double>(n)),
                std::sin(sign * 2 * kPi / static_cast<double>(n)));
    CD w(1.0, 0.0);
    for (std::size_t k = 0; k < n / 2; ++k) {
        a[k] = even[k] + w * odd[k];
        a[k + n / 2] = even[k] - w * odd[k];
        w *= wn;
    }
}

static void dft_demo() {
    // A(x) = 1 + 2x + 3x² + 0x³（系数表示）在 4 次单位根上求值
    std::vector<CD> a{1, 2, 3, 0};
    fft(a, +1.0);
    println("DFT（A(x)=1+2x+3x² 的 4 点值表示）：");
    for (std::size_t k = 0; k < a.size(); ++k) {
        println("  A(w^{}) = {:+.2f}{:+.2f}i", k, a[k].real(), a[k].imag());
    }
    // 手算对账：w⁰=1: 6；w¹=i: 1+2i+3i²=1+2i−3=−2+2i；
    // w²=−1: 1−2+3=2；w³=−i: 1−2i−3=−2−2i
    assert(std::fabs(a[0].real() - 6) < 1e-9 && std::fabs(a[1].real() + 2) < 1e-9 &&
           std::fabs(a[1].imag() - 2) < 1e-9 && std::fabs(a[2].real() - 2) < 1e-9 &&
           std::fabs(a[3].imag() + 2) < 1e-9);
    // 往返一致性：IFFT(FFT(a)) == a
    std::vector<CD> back = a;
    fft(back, -1.0);
    bool roundtrip = true;
    const std::vector<CD> orig{1, 2, 3, 0};
    for (std::size_t i = 0; i < back.size(); ++i) {
        back[i] /= CD(static_cast<double>(back.size()), 0.0);
        if (std::fabs(back[i].real() - orig[i].real()) > 1e-9 ||
            std::fabs(back[i].imag()) > 1e-9) { roundtrip = false; }
    }
    println("  往返一致性 FFT→IFFT 复原系数（容差 1e-9）= {}", roundtrip ? 1 : 0);
    assert(roundtrip);
}

// ═══ 31.3 卷积定理：多项式乘法 ═══
// C = A·B 的系数 = IFFT(FFT(A)·FFT(B))。
static std::vector<double> poly_mul_fft(const std::vector<double>& A,
                                        const std::vector<double>& B,
                                        long long& complexMults) {
    std::size_t n = 1;
    while (n < A.size() + B.size() - 1) { n *= 2; }
    std::vector<CD> fa(n, CD(0, 0)), fb(n, CD(0, 0));
    for (std::size_t i = 0; i < A.size(); ++i) { fa[i] = CD(A[i], 0); }
    for (std::size_t i = 0; i < B.size(); ++i) { fb[i] = CD(B[i], 0); }
    fft(fa, +1.0);
    fft(fb, +1.0);
    for (std::size_t i = 0; i < n; ++i) {
        fa[i] *= fb[i];
        ++complexMults;
    }
    fft(fa, -1.0);
    std::vector<double> out(A.size() + B.size() - 1, 0.0);
    for (std::size_t i = 0; i < out.size(); ++i) {
        out[i] = fa[i].real() / static_cast<double>(n);
    }
    return out;
}

static std::vector<double> poly_mul_naive(const std::vector<double>& A,
                                          const std::vector<double>& B,
                                          long long& mults) {
    std::vector<double> out(A.size() + B.size() - 1, 0.0);
    for (std::size_t i = 0; i < A.size(); ++i) {
        for (std::size_t j = 0; j < B.size(); ++j) {
            out[i + j] += A[i] * B[j];
            ++mults;
        }
    }
    return out;
}

static void convolution_demo() {
    // (1 + 2x + 3x²)·(4 + 5x) = 4 + 13x + 22x² + 15x³
    const std::vector<double> A{1, 2, 3}, B{4, 5};
    long long mc = 0, mn = 0;
    const auto c1 = poly_mul_fft(A, B, mc);
    const auto c2 = poly_mul_naive(A, B, mn);
    print("卷积定理（(1+2x+3x²)(4+5x)）：FFT 版系数: ");
    for (double v : c1) { print("{:.2f} ", v); }
    println("");
    bool agree = c1.size() == c2.size();
    for (std::size_t i = 0; agree && i < c1.size(); ++i) {
        if (std::fabs(c1[i] - c2[i]) > 1e-9) { agree = false; }
    }
    assert(agree);
    assert(std::fabs(c1[0] - 4) < 1e-9 && std::fabs(c1[1] - 13) < 1e-9 &&
           std::fabs(c1[2] - 22) < 1e-9 && std::fabs(c1[3] - 15) < 1e-9);
    println("  与朴素卷积逐系数一致（= 4,13,22,15）；FFT 复数乘 {} 次 vs 朴素标量乘 {} 次",
            mc, mn);
}

// ═══ 31.4 大整数乘法（10 进制数位当多项式系数）═══
static void bigint_demo() {
    // 123456789 × 987654321 = 121932631112635269（20 位以内，double 精确）
    const std::string sa = "123456789", sb = "987654321";
    // 注意：char → double 要减 '0'——直接用迭代器构造会把字符码（'9'=57）当系数
    std::vector<double> A, B;
    for (auto it = sa.rbegin(); it != sa.rend(); ++it) { A.push_back(*it - '0'); }
    for (auto it = sb.rbegin(); it != sb.rend(); ++it) { B.push_back(*it - '0'); }
    long long mc = 0;
    auto prod = poly_mul_fft(A, B, mc);
    // 进位归一化（低位在前）——FFT 结果带 ±1e-9 噪声，先 llround 再逐位
    // 进位；最高位 ≥ 10 时要扩展（本例积的最高进位恰是 12 → 1,2 两位）
    std::vector<long long> c(prod.size());
    for (std::size_t i = 0; i < prod.size(); ++i) { c[i] = std::llround(prod[i]); }
    for (std::size_t i = 0; i < c.size(); ++i) {
        const long long carry = c[i] / 10;
        c[i] -= carry * 10;
        if (carry > 0) {
            if (i + 1 == c.size()) { c.push_back(carry); }
            else                    { c[i + 1] += carry; }
        }
    }
    std::string digits;
    bool lead = true;
    for (std::size_t i = c.size(); i-- > 0;) {
        if (lead && c[i] == 0) { continue; }
        lead = false;
        digits.push_back(static_cast<char>('0' + c[i]));
    }
    println("大整数乘法：123456789 × 987654321 = {}（校验 121932631112635269）",
            digits);
    assert(digits == "121932631112635269");
}

int main() {
    dft_demo();
    convolution_demo();
    bigint_demo();
    println("自检通过");
    return 0;
}
