// 33 字符串匹配（CLRS 第 32 章）。结构：33.1 朴素匹配的比较计数 /
// 33.2 Rabin-Karp（滚动哈希）/ 33.3 有限自动机匹配器（转移表）/
// 33.4 KMP（前缀函数与匹配追踪）/ 四解对账 / 33.5 Aho-Corasick 自动机
// （trie + fail 指针 + 输出传播掩码，多模式一趟扫描）/
// 33.6 压缩符 [qx] 的展开与病毒扫描（模式或其逆向为子串）。
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
#include <vector>

// 可移植随机：乘法折半取 [0,n)，不用 uniform_int_distribution
static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    return static_cast<std::uint32_t>(
        (static_cast<std::uint64_t>(rng()) * n) >> 32);
}

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

// ═══ 33.5 Aho-Corasick 自动机：多模式匹配 ═══
// 动机：n 个模式 + 一段文本。朴素是 Θ(n·(|T| + 模式长))；单模式有 KMP/RK，
// 多模式需要新工具。Aho-Corasick = Trie + fail 指针（KMP 的 π 推广到 trie）。
//
// 两个实现要点（都是实测踩过的坑）：
//   1) 节点用 std::vector<Node> + **int 下标**，绝不用指针 —— push_back
//      会让所有已持有的指针/引用失效（迭代器同样失效）。
//   2) reserve 预分配总长 + 1，避免搬迁。
class AhoCorasick {
public:
    // out[u] 的第 i 位 = 「以 u 为前缀的模式 i 在此处结束」
    struct Node {
        std::array<int, 26> next{};        // 0 = 无边（根的编号也是 0，故用 0 当哨兵）
        int fail = 0;
        std::uint32_t out = 0;             // 命中掩码
        bool terminal = false;             // u 本身是某个模式的末尾
    };

    explicit AhoCorasick(std::size_t totalLen) {
        nodes_.reserve(totalLen + 1);
        nodes_.emplace_back();             // 根 = 0
    }

    // 插入一个模式，bit = 它的编号（模式数 ≤ 32 时用 uint32 掩码）
    void insert(std::string_view pat, int bit) {
        int u = 0;
        for (const char ch : pat) {
            const int c = ch - 'a';
            if (nodes_[static_cast<std::size_t>(u)].next[static_cast<std::size_t>(c)] == 0) {
                nodes_[static_cast<std::size_t>(u)].next[static_cast<std::size_t>(c)] =
                    static_cast<int>(nodes_.size());
                nodes_.emplace_back();
            }
            u = nodes_[static_cast<std::size_t>(u)].next[static_cast<std::size_t>(c)];
        }
        nodes_[static_cast<std::size_t>(u)].terminal = true;
        nodes_[static_cast<std::size_t>(u)].out |= (1u << bit);
    }

    // BFS 一次建完 fail 指针，并把转移表**补全**（缺失的边指向 fail 的同名边）。
    // 补全后扫描是严格 O(1)/字符，不需要循环回跳 —— 这是与「裸 fail 链」的关键差别。
    void build() {
        std::vector<int> bfs;
        bfs.reserve(nodes_.size());
        for (int c = 0; c < 26; ++c) {
            const int v = nodes_[0].next[static_cast<std::size_t>(c)];
            if (v != 0) { bfs.push_back(v); }   // 一层节点的 fail 已是根（0）
        }
        for (std::size_t i = 0; i < bfs.size(); ++i) {
            const int u = bfs[i];
            for (int c = 0; c < 26; ++c) {
                const int v = nodes_[static_cast<std::size_t>(u)].next[static_cast<std::size_t>(c)];
                if (v != 0) {
                    const int f = nodes_[static_cast<std::size_t>(u)].fail;
                    nodes_[static_cast<std::size_t>(v)].fail =
                        nodes_[static_cast<std::size_t>(f)].next[static_cast<std::size_t>(c)];
                    // **输出传播**：fail 链上所有模式的命中也要算进 v 的 out
                    nodes_[static_cast<std::size_t>(v)].out |=
                        nodes_[static_cast<std::size_t>(
                            nodes_[static_cast<std::size_t>(v)].fail)].out;
                    bfs.push_back(v);
                } else {
                    const int f = nodes_[static_cast<std::size_t>(u)].fail;
                    nodes_[static_cast<std::size_t>(u)].next[static_cast<std::size_t>(c)] =
                        nodes_[static_cast<std::size_t>(f)].next[static_cast<std::size_t>(c)];
                }
            }
        }
    }

    // 返回每个模式的全部出现位置。转移次数 = |T|（严格每字符一次）
    std::vector<std::vector<std::size_t>> scan(std::string_view t, int patternCount,
                                               long long& transitions) const {
        std::vector<std::vector<std::size_t>> hits(static_cast<std::size_t>(patternCount));
        int u = 0;
        for (std::size_t i = 0; i < t.size(); ++i) {
            u = nodes_[static_cast<std::size_t>(u)].next[static_cast<std::size_t>(t[i] - 'a')];
            ++transitions;
            const std::uint32_t m = nodes_[static_cast<std::size_t>(u)].out;
            if (m == 0) { continue; }
            for (int b = 0; b < patternCount; ++b) {
                if ((m & (1u << b)) != 0) { hits[static_cast<std::size_t>(b)].push_back(i); }
            }
        }
        return hits;
    }

    // 逐模式朴素扫描当裁判：AC 的每个模式结果必须与它逐字一致
    static std::vector<std::size_t> naive_one(std::string_view t, std::string_view p) {
        std::vector<std::size_t> hits;
        if (p.empty() || p.size() > t.size()) { return hits; }
        for (std::size_t s = 0; s + p.size() <= t.size(); ++s) {
            if (t.substr(s, p.size()) == p) { hits.push_back(s + p.size() - 1); }
        }
        return hits;
    }

    std::size_t nodeCount() const { return nodes_.size(); }
    // 只读访问转移表（演示「补全后每个 (状态, 字符) 都有定义」）
    int transition(int state, char c) const {
        return nodes_[static_cast<std::size_t>(state)].next[static_cast<std::size_t>(c - 'a')];
    }
    int failOf(int state) const {
        return nodes_[static_cast<std::size_t>(state)].fail;
    }
    std::uint32_t outOf(int state) const {
        return nodes_[static_cast<std::size_t>(state)].out;
    }

private:
    std::vector<Node> nodes_;
};

static void aho_corasick_demo() {
    println("");
    println("=== 33.5 Aho-Corasick 自动机：多模式匹配 ===");
    println("  动机：单模式有 KMP/RK，多模式需要新工具。朴素是 Θ(k·(|T|+模式长))，");
    println("        AC 把 k 个模式编进一棵 trie，一趟扫描同时匹配全部 —— Θ(Σ·L_tot + |T|)。");

    // 病毒模式串 + 它们的逆串（逆串命中是「输出传播」最好的演示）
    const std::vector<std::string> pats{"he", "she", "his", "hers", "abc", "cba"};
    const std::string text = "ushers abc cba she hers his he";
    std::size_t total = 0;
    for (const auto& p : pats) { total += p.size(); }

    AhoCorasick ac(total);
    for (std::size_t i = 0; i < pats.size(); ++i) {
        ac.insert(pats[i], static_cast<int>(i));
    }
    ac.build();
    println("  模式集（{} 个，长度之和 L_tot = {}）：", pats.size(), total);
    print("   ");
    for (const auto& p : pats) { print("{} ", p); }
    println("");
    println("  Trie（含 fail 链补全后的转移表）共 {} 个节点", ac.nodeCount());

    // 「输出传播」的正确现场：模式 "she" 的 fail 指向 "he"（"she" 的最长真后缀
    // 恰是另一个模式），所以扫到 "she" 时 **同时** 要报出 "he"。
    println("");
    println("  输出传播：扫描到状态 u 时，fail 链上所有模式一并命中。");
    println("  现场：模式 he（bit 0）与 she（bit 1）—— \"she\" 的最长真后缀 \"he\"");
    println("        恰是另一个模式，于是 fail(she) = he，out(she) 必须含 bit 0。");
    {
        int u = 0;
        for (const char c : std::string_view{"she"}) { u = ac.transition(u, c); }
        const int she_node = u;
        int v = 0;
        for (const char c : std::string_view{"he"}) { v = ac.transition(v, c); }
        const int he_node = v;
        println("    状态 he(#{}) 的 out = {:b}（只含自己）", he_node, ac.outOf(he_node));
        println("    状态 she(#{}) 的 out = {:b}（= bit1 | bit0，**含 fail 链上的 he**）",
                she_node, ac.outOf(she_node));
        println("    fail(she) = {} 正是 he 的节点号；out 掩码把两处命中压进一个整数",
                ac.failOf(she_node));
        assert(ac.failOf(she_node) == he_node);
        assert(ac.outOf(she_node) == 0b11u);
        assert(ac.outOf(he_node) == 0b01u);
        // 不做传播的话，"she" 的 out 只有 bit1，文本里两处 she 会漏报 he
        assert(ac.outOf(she_node) != ac.outOf(he_node));
    }

    long long transitions = 0;
    const auto hits = ac.scan(text, static_cast<int>(pats.size()), transitions);
    println("");
    println("  文本 \"{}\"（|T| = {}）：", text, text.size());
    for (std::size_t i = 0; i < pats.size(); ++i) {
        const auto& h = hits[i];
        print("    {:>5} 命中 {} 次，结束下标 = [", pats[i], h.size());
        for (const std::size_t e : h) { print("{} ", e); }
        println("]");
        // 与「逐模式朴素扫描」逐字对账 —— AC 的正确性裁判
        const auto ref = AhoCorasick::naive_one(text, pats[i]);
        assert(h == ref);
    }
    println("  转移次数 = {} = |T| 严格相等（补全转移表后每字符恰好 1 次，无回跳）",
            transitions);
    assert(transitions == static_cast<long long>(text.size()));

    // AC vs 逐模式 KMP：模式数少时 std::search 更快 —— 选型的现实分界
    println("");
    println("  选型：模式数很少（< 10）时，libstdc++ 的 std::search（twoway 算法）");
    println("        比手写 AC 更快也更简单。多模式 AC 的价值在 k 大时才显现。");
    for (const std::size_t k : {std::size_t{1}, std::size_t{2}, std::size_t{6}}) {
        std::size_t sum = 0;
        for (std::size_t i = 0; i < k; ++i) { sum += pats[i].size(); }
        // std::search 的工作量下界是 Ω(|T| + 模式长)，与模式数无关
        const auto t0 = text;
        long long searchOps = 0;
        for (std::size_t i = 0; i < k; ++i) {
            (void)std::search(t0.begin(), t0.end(), pats[i].begin(), pats[i].end());
            searchOps += static_cast<long long>(t0.size() + pats[i].size());
        }
        println("    k = {}：std::search 逐模式搜索 ≈ {} 步（k 次全文扫描）；", k, searchOps);
        println("          AC 一次扫描 = {} 步 + 建树 {} 步（L_tot = {}）", transitions,
                26 * ac.nodeCount(), sum);
    }
    println("    k 小时两者同阶（k 是常数），而 std::search 无需建树、无需掩码、");
    println("    直接吃到 stdlib 的 twoway 优化 —— 这就是「够用即最优」的边界。");
}

// ═══ 33.6 压缩符展开与病毒扫描 ═══
// 程序串由 A–Z 与压缩符 [qx] 组成：[qx] 表示 q 个连续字母 x，q 为
// 十进制正整数。'['、']' 只充当标记，故单遍状态机即可解析。

// 与解析同构的 dry-run，算出展开长度用于 reserve
static long long expanded_length(std::string_view s) {
    long long len = 0;
    for (std::size_t i = 0; i < s.size();) {
        if (s[i] != '[') { ++len; ++i; continue; }
        ++i;
        long long q = 0;
        while (s[i] >= '0' && s[i] <= '9') { q = q * 10 + (s[i] - '0'); ++i; }
        len += q;       // s[i] 是字母 x，s[i+1] 是 ']'
        i += 2;
    }
    return len;
}

static std::string decompress(std::string_view s) {
    std::string out;
    out.reserve(static_cast<std::size_t>(expanded_length(s)));
    for (std::size_t i = 0; i < s.size();) {
        if (s[i] != '[') { out.push_back(s[i]); ++i; continue; }
        ++i;
        long long q = 0;
        while (s[i] >= '0' && s[i] <= '9') { q = q * 10 + (s[i] - '0'); ++i; }
        out.append(static_cast<std::size_t>(q), s[i]);
        i += 2;         // 跳过字母与 ']'
    }
    return out;
}

// 手写朴素包含判定（仅供对账，不用标准库 find）
static bool naive_contains(std::string_view text, std::string_view pat) {
    if (pat.size() > text.size()) { return false; }
    for (std::size_t i = 0; i + pat.size() <= text.size(); ++i) {
        bool ok = true;
        for (std::size_t j = 0; j < pat.size(); ++j) {
            if (text[i + j] != pat[j]) { ok = false; break; }
        }
        if (ok) { return true; }
    }
    return false;
}

// 病毒计数：模式 v 或其逆向是展开程序的子串即计一种（逆向模式命中
// 等价于模式命中程序的逆向串）。
template <class ContainsFn>
static int virus_count_with(const std::vector<std::string>& viruses,
                            const std::string& program, ContainsFn contains) {
    const std::string text = decompress(program);
    int count = 0;
    for (const std::string& v : viruses) {
        const std::string rv(v.rbegin(), v.rend());
        if (contains(text, std::string_view(v)) ||
            contains(text, std::string_view(rv))) { ++count; }
    }
    return count;
}

static int virus_count(const std::vector<std::string>& viruses,
                       const std::string& program) {
    return virus_count_with(viruses, program,
        [](std::string_view text, std::string_view pat) {
            return text.find(pat) != std::string_view::npos;
        });
}

static void virus_scan_demo() {
    println("压缩符展开 [qx] 与病毒扫描（模式或其逆向为子串）：");
    const std::string sample = "AB[2D]E[7K]G";
    println("  {} 展开 = {}", sample, decompress(sample));
    assert(decompress(sample) == "ABDDEKKKKKKKG");

    struct Case {
        std::vector<std::string> viruses;
        std::string program;
        int answer;
    };
    const std::vector<Case> cases = {
        {{"AB", "DCB"}, "DACB", 0},
        {{"ABC", "CDE", "GHI"}, "ABCCDEFIHG", 3},
        {{"ABB", "ACDEE", "BBB", "FEEE"}, "A[2B]CD[4E]F", 2}};
    for (std::size_t c = 0; c < cases.size(); ++c) {
        const int got = virus_count(cases[c].viruses, cases[c].program);
        println("  案例{}（{} 个病毒，{}）：感染 {} 种",
                c + 1, cases[c].viruses.size(), cases[c].program, got);
        assert(got == cases[c].answer);
    }

    // 解析器对账：压缩串由「普通字母 / [qX]」随机拼成，逐段参考构造
    std::mt19937 rng{5489};
    int trials = 3000, parse_mismatches = 0, count_mismatches = 0;
    for (int t = 0; t < trials; ++t) {
        std::string compressed, reference;
        const int tokens = 1 + static_cast<int>(rand_below(rng, 6));
        for (int z = 0; z < tokens; ++z) {
            const char x = static_cast<char>('A' + rand_below(rng, 3));
            if (rng() & 1u) {
                compressed.push_back(x);
                reference.push_back(x);
            } else {
                const int q = 1 + static_cast<int>(rand_below(rng, 999));
                compressed += "[" + std::to_string(q) + x + "]";
                reference.append(static_cast<std::size_t>(q), x);
            }
        }
        if (decompress(compressed) != reference) { ++parse_mismatches; }

        // 病毒计数对账：随机短程序 + 随机模式集，find 版 vs 手写朴素版
        const int plen = 1 + static_cast<int>(rand_below(rng, 12));
        std::string prog;
        for (int i = 0; i < plen; ++i) {
            prog.push_back(static_cast<char>('A' + rand_below(rng, 3)));
        }
        std::vector<std::string> viruses;
        const int nv = 1 + static_cast<int>(rand_below(rng, 5));
        for (int i = 0; i < nv; ++i) {
            std::string v;
            const int vlen = 1 + static_cast<int>(rand_below(rng, 4));
            for (int j = 0; j < vlen; ++j) {
                v.push_back(static_cast<char>('A' + rand_below(rng, 3)));
            }
            viruses.push_back(v);
        }
        const int a = virus_count(viruses, prog);
        const int b = virus_count_with(viruses, prog, naive_contains);
        if (a != b) { ++count_mismatches; }
    }
    println("  随机 {} 个压缩串：展开 vs 逐段参考构造 不一致 {} 例",
            trials, parse_mismatches);
    println("  随机 {} 个程序×模式：find 计数 vs 手写朴素匹配 不一致 {} 例",
            trials, count_mismatches);
    assert(parse_mismatches == 0 && count_mismatches == 0);
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

    aho_corasick_demo();
    virus_scan_demo();
    println("自检通过");
    return 0;
}
