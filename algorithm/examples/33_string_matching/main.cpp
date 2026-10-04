// 33 字符串匹配（CLRS 第 32 章）。结构：33.1 朴素匹配的比较计数 /
// 33.2 Rabin-Karp（滚动哈希）/ 33.3 有限自动机匹配器（转移表）/
// 33.4 KMP（前缀函数与匹配追踪）/ 四解对账。
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
#include <string>
#include <string_view>
#include <vector>

static const std::string kText = "abababacabaababac";
static const std::string kPat  = "ababac";

// ═══ 33.1 朴素匹配 ═══
// 每个对齐位置从头比较——最坏 (n−m+1)·m 次比较。
static std::vector<std::size_t> naive_match(std::string_view t, std::string_view p,
                                            long long& compares) {
    std::vector<std::size_t> hits;
    for (std::size_t s = 0; s + p.size() <= t.size(); ++s) {
        std::size_t i = 0;
        while (i < p.size()) {
            ++compares;
            if (t[s + i] != p[i]) { break; }
            ++i;
        }
        if (i == p.size()) { hits.push_back(s); }
    }
    return hits;
}

// ═══ 33.2 Rabin-Karp ═══
// 多项式滚动哈希：h(s+1) 由 h(s) O(1) 更新；命中后再逐字符验证
//（防假阳性）。基数 d=256（字节全域），模 q。
static std::vector<std::size_t> rabin_karp(std::string_view t, std::string_view p,
                                           long long& compares, long long& hashOps,
                                           std::uint64_t q) {
    const std::uint64_t d = 256;
    const std::size_t m = p.size(), n = t.size();
    std::uint64_t hp = 0, ht = 0, h = 1;
    for (std::size_t i = 0; i + 1 < m; ++i) { h = h * d % q; }   // d^{m-1} mod q
    for (std::size_t i = 0; i < m; ++i) {
        hp = (hp * d + static_cast<unsigned char>(p[i])) % q;
        ht = (ht * d + static_cast<unsigned char>(t[i])) % q;
        ++hashOps;
    }
    std::vector<std::size_t> hits;
    for (std::size_t s = 0; s + m <= n; ++s) {
        if (hp == ht) {
            // 哈希命中：逐字符验证（防假阳性）
            std::size_t i = 0;
            while (i < m) {
                ++compares;
                if (t[s + i] != p[i]) { break; }
                ++i;
            }
            if (i == m) { hits.push_back(s); }
        }
        if (s + m < n) {
            ht = (ht + q - h * static_cast<unsigned char>(t[s]) % q) % q;   // 去头
            ht = (ht * d + static_cast<unsigned char>(t[s + m])) % q;        // 加尾
            ++hashOps;
        }
    }
    return hits;
}

// ═══ 33.3 有限自动机匹配器 ═══
// 状态 = 已匹配前缀长度；转移 δ(state, c) = 最长前缀，使其是
// (P[0..state) + c) 的后缀。建表 O(m³·|Σ|)（朴素版），匹配 O(n)。
static std::vector<std::array<int, 3>> build_fa(std::string_view p) {
    const std::size_t m = p.size();
    const std::string sigma = "abc";
    std::vector<std::array<int, 3>> delta(m + 1);
    auto suffix_is_prefix = [&](std::string_view s, std::size_t k) -> bool {
        // P[0..k) 是否是 s 的后缀
        if (k > s.size()) { return false; }
        return s.substr(s.size() - k) == p.substr(0, k);
    };
    for (std::size_t state = 0; state <= m; ++state) {
        for (int ci = 0; ci < 3; ++ci) {
            const std::string cand = std::string(p.substr(0, state)) + sigma[static_cast<std::size_t>(ci)];
            int next = 0;
            for (std::size_t k = std::min(cand.size(), m); ; --k) {
                if (suffix_is_prefix(cand, k)) { next = static_cast<int>(k); break; }
                if (k == 0) { break; }
            }
            delta[state][static_cast<std::size_t>(ci)] = next;
        }
    }
    return delta;
}

static std::vector<std::size_t> fa_match(std::string_view t, std::string_view p,
                                         long long& cellVisits) {
    const auto delta = build_fa(p);
    const std::string sigma = "abc";
    int state = 0;
    std::vector<std::size_t> hits;
    for (std::size_t i = 0; i < t.size(); ++i) {
        const std::size_t ci = sigma.find(t[i]);
        state = delta[static_cast<std::size_t>(state)][ci];
        ++cellVisits;
        if (state == static_cast<int>(p.size())) { hits.push_back(i + 1 - p.size()); }
    }
    return hits;
}

// ═══ 33.4 KMP ═══
// π[q] = P[0..q) 的最长相等真前后缀。失配时模式「滑」到 π[前匹配长]，
// 文本指针永不回退。
static std::vector<int> prefix_function(std::string_view p) {
    const std::size_t m = p.size();
    std::vector<int> pi(m + 1, 0);
    int k = 0;
    for (std::size_t q = 2; q <= m; ++q) {
        while (k > 0 && p[static_cast<std::size_t>(k)] != p[q - 1]) { k = pi[static_cast<std::size_t>(k)]; }
        if (p[static_cast<std::size_t>(k)] == p[q - 1]) { ++k; }
        pi[q] = k;
    }
    return pi;
}

static std::vector<std::size_t> kmp_match(std::string_view t, std::string_view p,
                                          long long& compares) {
    const auto pi = prefix_function(p);
    int q = 0;   // 已匹配字符数
    std::vector<std::size_t> hits;
    for (std::size_t i = 0; i < t.size(); ++i) {
        while (q > 0 && p[static_cast<std::size_t>(q)] != t[i]) {
            q = pi[static_cast<std::size_t>(q)];       // 滑动，文本不回退
        }
        if (p[static_cast<std::size_t>(q)] == t[i]) { ++q; }
        ++compares;
        if (q == static_cast<int>(p.size())) {
            hits.push_back(i + 1 - p.size());
            q = pi[static_cast<std::size_t>(q)];
        }
    }
    return hits;
}

int main() {
    println("字符串匹配（T = \"{}\"，P = \"{}\"，|T|={} |P|={}）：", kText, kPat,
            kText.size(), kPat.size());

    long long cn = 0, cr = 0, hr = 0, cf = 0, ck = 0;
    const auto hitsN = naive_match(kText, kPat, cn);
    const auto hitsR = rabin_karp(kText, kPat, cr, hr, 1000000007);
    const auto hitsF = fa_match(kText, kPat, cf);
    const auto hitsK = kmp_match(kText, kPat, ck);

    // 四解对账
    assert(hitsN == hitsR && hitsR == hitsF && hitsF == hitsK);
    print("  四算法命中位置: ");
    for (auto h : hitsN) { print("{} ", h); }
    println("");

    // KMP 前缀函数表（ababac 的经典 π）
    const auto pi = prefix_function(kPat);
    print("  KMP 前缀函数 π（含哨兵）: ");
    for (int v : pi) { print("{} ", v); }
    println("");
    assert((pi == std::vector<int>{0, 0, 0, 1, 2, 3, 0}));

    // 有限自动机转移表（σ = {a,b,c}）
    const auto delta = build_fa(kPat);
    println("  有限自动机转移表（状态 0..6 × σ=a,b,c）：");
    for (std::size_t s = 0; s < delta.size(); ++s) {
        println("    δ({}, a)={}  δ({}, b)={}  δ({}, c)={}", s, delta[s][0], s,
                delta[s][1], s, delta[s][2]);
    }

    // 复杂度画像
    println("  计数画像：朴素比较 {} 次；RK 哈希步 {}+验证比较 {} 次；"
            "FA 查表 {} 次；KMP 比较 {} 次（文本指针永不回退）",
            cn, hr, cr, cf, ck);
    assert(ck <= 2 * static_cast<long long>(kText.size()));   // KMP ≤ 2n 的界
    println("自检通过");
    return 0;
}
