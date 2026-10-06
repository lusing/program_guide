// 16 动态规划（下）：LCS、最优 BST 与编辑距离（CLRS §15.4–15.5）。
// 结构：16.1 LCS（c/b 表 + 重构，图 15.8 数据）/ 16.2 前缀码性质与
// 多重对账 / 16.3 最优 BST（图 15.10 数据，期望代价 2.75）/
// 16.4 编辑距离（LCS 的变体，C++ 实战延伸）/
// 16.7 石子合并：区间 DP（直线/圆环、最小/最大，合并树重构）。
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
#include <random>
#include <string>
#include <utility>
#include <vector>

// ═══ 16.1 最长公共子序列 ═══
// 递推（CLRS p.394）：
//   c[i,j] = 0                         若 i=0 或 j=0
//          = c[i-1,j-1] + 1            若 x_i = y_j
//          = max(c[i-1,j], c[i,j-1])   否则
struct LcsResult {
    std::vector<std::vector<int>> c;      // 长度表
    std::vector<std::vector<char>> b;     // 方向表：↖ ↑ ←
    int length = 0;
};

static LcsResult lcs(const std::string& x, const std::string& y) {
    const std::size_t m = x.size(), n = y.size();
    LcsResult r;
    r.c.assign(m + 1, std::vector<int>(n + 1, 0));
    r.b.assign(m + 1, std::vector<char>(n + 1, ' '));
    for (std::size_t i = 1; i <= m; ++i) {
        for (std::size_t j = 1; j <= n; ++j) {
            if (x[i - 1] == y[j - 1]) {
                r.c[i][j] = r.c[i - 1][j - 1] + 1;
                r.b[i][j] = '\\';                    // ↖（对角）
            } else if (r.c[i - 1][j] >= r.c[i][j - 1]) {
                r.c[i][j] = r.c[i - 1][j];
                r.b[i][j] = '^';                     // ↑
            } else {
                r.c[i][j] = r.c[i][j - 1];
                r.b[i][j] = '<';                     // ←
            }
        }
    }
    r.length = r.c[m][n];
    return r;
}

static std::string lcs_reconstruct(const LcsResult& r, const std::string& x,
                                   std::size_t i, std::size_t j) {
    if (i == 0 || j == 0) { return ""; }
    if (r.b[i][j] == '\\') {
        return lcs_reconstruct(r, x, i - 1, j - 1) + x[i - 1];
    }
    if (r.b[i][j] == '^') { return lcs_reconstruct(r, x, i - 1, j); }
    return lcs_reconstruct(r, x, i, j - 1);
}

static bool is_subsequence(std::string_view sub, std::string_view s) {
    std::size_t p = 0;
    for (char c : s) {
        if (p < sub.size() && sub[p] == c) { ++p; }
    }
    return p == sub.size();
}

static void lcs_demo() {
    // CLRS 图 15.8 的数据：X = ABCBDAB，Y = BDCABA → LCS 长度 4（如 BCBA）
    const std::string x = "ABCBDAB";
    const std::string y = "BDCABA";
    const LcsResult r = lcs(x, y);
    const std::string z = lcs_reconstruct(r, x, x.size(), y.size());
    println("LCS（图 15.8 数据 X=ABCBDAB, Y=BDCABA）：");
    println("  长度 = {}，重构出的 LCS = \"{}\"", r.length, z);
    assert(r.length == 4);
    assert(is_subsequence(z, x) && is_subsequence(z, y) && z.size() == 4);
    // c 表右下角 3x3 快照
    println("  c 表右下角（{} {} {} 行 × 末 3 列）: {} {} {} / {} {} {} / {} {} {}",
            x[x.size() - 3], x[x.size() - 2], x[x.size() - 1],
            r.c[x.size() - 2][y.size() - 2], r.c[x.size() - 2][y.size() - 1], r.c[x.size() - 2][y.size()],
            r.c[x.size() - 1][y.size() - 2], r.c[x.size() - 1][y.size() - 1], r.c[x.size() - 1][y.size()],
            r.c[x.size()][y.size() - 2], r.c[x.size()][y.size() - 1], r.c[x.size()][y.size()]);
}

// ═══ 16.3 最优 BST ═══
// e[i,j]：含键 k_i..k_j 与伪键 d_{i-1}..d_j 的子树期望搜索代价
//（CLRS 图 15.10：p=<.15,.10,.05,.10,.20>, q=<.05,.10,.05,.05,.05,.10> → 2.75）
static void optimal_bst_demo() {
    const std::vector<double> p{0.0, 0.15, 0.10, 0.05, 0.10, 0.20};
    const std::vector<double> q{0.05, 0.10, 0.05, 0.05, 0.05, 0.10};
    const int n = 5;
    std::vector<std::vector<double>> e(static_cast<std::size_t>(n) + 2,
        std::vector<double>(static_cast<std::size_t>(n) + 2, 0.0));
    std::vector<std::vector<double>> w(static_cast<std::size_t>(n) + 2,
        std::vector<double>(static_cast<std::size_t>(n) + 2, 0.0));
    std::vector<std::vector<int>> root(static_cast<std::size_t>(n) + 2,
        std::vector<int>(static_cast<std::size_t>(n) + 2, 0));
    for (int i = 1; i <= n + 1; ++i) {
        e[static_cast<std::size_t>(i)][static_cast<std::size_t>(i) - 1] = q[static_cast<std::size_t>(i) - 1];
        w[static_cast<std::size_t>(i)][static_cast<std::size_t>(i) - 1] = q[static_cast<std::size_t>(i) - 1];
    }
    for (int l = 1; l <= n; ++l) {
        for (int i = 1; i + l - 1 <= n; ++i) {
            const int j = i + l - 1;
            e[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] = 1e9;
            w[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] =
                w[static_cast<std::size_t>(i)][static_cast<std::size_t>(j) - 1]
                + p[static_cast<std::size_t>(j)] + q[static_cast<std::size_t>(j)];
            for (int r = i; r <= j; ++r) {
                const double t = e[static_cast<std::size_t>(i)][static_cast<std::size_t>(r) - 1]
                    + e[static_cast<std::size_t>(r) + 1][static_cast<std::size_t>(j)]
                    + w[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)];
                if (t < e[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)]) {
                    e[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] = t;
                    root[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] = r;
                }
            }
        }
    }
    const double cost = e[1][static_cast<std::size_t>(n)];
    println("最优 BST（图 15.10 数据，5 键）：期望搜索代价 = {:.6f}（CLRS 答案 2.75）", cost);
    assert(cost > 2.7499 && cost < 2.7501);
    println("  根 = k{}（root[1][5]），子树根 root[2][5] = k{}",
            root[1][static_cast<std::size_t>(n)],
            root[2][static_cast<std::size_t>(n)]);
    assert(root[1][static_cast<std::size_t>(n)] == 2);
}

// ═══ 16.4 编辑距离（LCS 的近亲，实战延伸）═══
// d[i,j] = x 前 i 与 y 前 j 的最少编辑数。subCost=1 即 Levenshtein；
// subCost=2（替换不划算，等于只许插删）时 d = m+n−2·LCS——可作交叉验证。
static int edit_distance(const std::string& x, const std::string& y, int subCost) {
    const std::size_t m = x.size(), n = y.size();
    std::vector<std::vector<int>> d(m + 1, std::vector<int>(n + 1, 0));
    for (std::size_t i = 0; i <= m; ++i) { d[i][0] = static_cast<int>(i); }
    for (std::size_t j = 0; j <= n; ++j) { d[0][j] = static_cast<int>(j); }
    for (std::size_t i = 1; i <= m; ++i) {
        for (std::size_t j = 1; j <= n; ++j) {
            const int cost = (x[i - 1] == y[j - 1]) ? 0 : subCost;
            d[i][j] = std::min({d[i - 1][j] + 1,        // 删
                                d[i][j - 1] + 1,        // 插
                                d[i - 1][j - 1] + cost});// 改/对位
        }
    }
    return d[m][n];
}

static void edit_distance_demo() {
    const std::string a = "kitten", b = "sitting";
    println("编辑距离（Levenshtein，替换代价 1）：kitten→sitting = {}（经典 3 步：改 k→s、改 e→i、插 g）",
            edit_distance(a, b, 1));
    assert(edit_distance(a, b, 1) == 3);
    // 替换代价 2 = 只许插删 ⇒ d = m+n−2·LCS（与 16.1 的 LCS 交叉验证）
    const std::string x = "ABCBDAB", y = "BDCABA";
    const LcsResult r = lcs(x, y);
    const int indel = edit_distance(x, y, 2);
    println("  ABCBDAB vs BDCABA：Levenshtein = {}，插删距离 = {}（= 7+6−2×LCS4 = {}，恒等式验证）",
            edit_distance(x, y, 1), indel,
            static_cast<int>(x.size() + y.size()) - 2 * r.length);
    assert(indel == static_cast<int>(x.size() + y.size()) - 2 * r.length);
}

// ═══ 16.5 最长不升子序列：二分尾替换与 LCS 归约 ═══
// LNIS（允许相等接续）是「后一支箭高度不超过前一支」这类约束的模型。
// 三条路线，本示例逐一对账：
//   (a) Θ(n²) DP：f[i] = 1 + max{ f[j] : j < i, h[j] >= h[i] }
//   (b) Θ(n log n) 尾替换 + 二分：LNIS(h) = LNDS(−h)，用 upper_bound
//   (c) Θ(n²) 归约：LNIS(h) = LCS(h, sort_desc(h))

// (a) 参考实现：Θ(n²) DP，同时可还原序列
static std::vector<int> lnis_dp(const std::vector<int>& h) {
    const std::size_t n = h.size();
    std::vector<int> f(n, 1);
    std::vector<std::size_t> pre(n, static_cast<std::size_t>(-1));
    for (std::size_t i = 1; i < n; ++i) {
        for (std::size_t j = 0; j < i; ++j) {
            if (h[j] >= h[i] && f[j] + 1 > f[i]) {   // >= 而非 > ：不升允许相等
                f[i] = f[j] + 1;
                pre[i] = j;
            }
        }
    }
    // 还原：从末尾值最大的下标回溯
    std::size_t best = 0;
    for (std::size_t i = 1; i < n; ++i) {
        if (f[i] > f[best]) { best = i; }
    }
    std::vector<int> seq;
    for (std::size_t k = best; k != static_cast<std::size_t>(-1); k = pre[k]) {
        seq.push_back(h[k]);
    }
    std::reverse(seq.begin(), seq.end());
    return seq;
}

// (b) Θ(n lg n) 尾替换 + 二分。**必须 upper_bound**。
// 不变式：d[k] = 长度为 k+1 的不降子序列的最小可能末尾值（对 b = −h）。
// 用 lower_bound 会返回第一个 d[p] >= b[i] 的位置，把相等元素截断在更靠前的
// 槽位 ⟹ 丢��「相等接续」的能力 ⟹ 答案偏小。
static std::vector<int> lnds_negated(const std::vector<int>& h, bool useUpper) {
    const std::size_t n = h.size();
    std::vector<int> b(n), d, tailIdx;
    std::vector<std::size_t> pre(n, static_cast<std::size_t>(-1));
    for (std::size_t i = 0; i < n; ++i) {
        b[i] = -h[i];
        const auto it = useUpper
            ? std::upper_bound(d.begin(), d.end(), b[i])
            : std::lower_bound(d.begin(), d.end(), b[i]);
        const std::size_t p = static_cast<std::size_t>(it - d.begin());
        if (p > 0) { pre[i] = tailIdx[p - 1]; }    // 前驱 = 长度 p 的最优末尾下标
        if (p == d.size()) {
            d.push_back(b[i]);
            tailIdx.push_back(static_cast<int>(i));   // size_t → int 显式收窄
        } else {
            d[p] = b[i];
            tailIdx[p] = static_cast<int>(i);         // 同上（/W4 会抓隐式）
        }
    }
    // 回溯：d 的下标是「长度」，pre 存的是「元素下标」，靠 tailIdx 桥接
    std::vector<int> seq;
    if (!tailIdx.empty()) {
        for (std::size_t k = tailIdx.back(); k != static_cast<std::size_t>(-1); k = pre[k]) {
            seq.push_back(h[k]);
        }
    }
    std::reverse(seq.begin(), seq.end());
    return seq;
}

// (c) Θ(n²) 归约：LNIS(h) = LCS(h, sort_desc(h))。用 16.1 的 LCS + 重构。
static std::vector<int> lnis_via_lcs(const std::vector<int>& h) {
    std::vector<int> desc(h);
    std::ranges::sort(desc, std::ranges::greater{});
    // 高度值当字符用（本例高度 ≤ 127）；int→char 必须显式转换，
    // 否则 string 迭代器构造在 MSVC /W4 下报 C4244。
    std::string x;
    x.reserve(h.size());
    for (int v : h) {
        x.push_back(static_cast<char>(v));
    }
    std::string y;
    y.reserve(desc.size());
    for (int v : desc) {
        y.push_back(static_cast<char>(v));
    }
    const LcsResult r = lcs(x, y);
    const std::string z = lcs_reconstruct(r, x, x.size(), y.size());
    // 还原成原始高度值：LCS 存的是字符，用 desc 的字符做双射不唯一，
    // 竞赛里通常只需长度；这里用「LCS 串在 h 中贪心匹配」还原高度序列。
    std::vector<int> seq;
    std::size_t p = 0;
    for (int v : h) {
        if (p < z.size() && static_cast<char>(v) == z[p]) {
            seq.push_back(v);
            ++p;
        }
    }
    return seq;
}

static void lnis_demo() {
    // 8 只鹰的高度（"后一支不超过前一支" ⟹ 取最长的不升子序列）
    const std::vector<int> h{389, 207, 155, 300, 299, 170, 158, 65};
    const std::vector<int> a = lnis_dp(h);
    const std::vector<int> b = lnds_negated(h, true);
    const std::vector<int> c = lnis_via_lcs(h);

    println("=== 16.5 最长不升子序列（LNIS）：二分尾替换 vs LCS 归约 ===");
    print("  高度序列 h = [");
    for (std::size_t i = 0; i < h.size(); ++i) {
        print("{}{}", h[i], i + 1 == h.size() ? "" : ", ");
    }
    println("]");
    print("  (a) Θ(n²) DP        LNIS = {}，序列 = [", a.size());
    for (std::size_t i = 0; i < a.size(); ++i) { print("{}{}", a[i], i + 1 == a.size() ? "" : ", "); }
    println("]");
    print("  (b) Θ(n lg n) 尾替换 LNIS = {}，序列 = [", b.size());
    for (std::size_t i = 0; i < b.size(); ++i) { print("{}{}", b[i], i + 1 == b.size() ? "" : ", "); }
    println("]");
    print("  (c) Θ(n²) LCS 归约   LNIS = {}，序列 = [", c.size());
    for (std::size_t i = 0; i < c.size(); ++i) { print("{}{}", c[i], i + 1 == c.size() ? "" : ", "); }
    println("]");
    assert(a.size() == b.size() && b.size() == c.size());
    // 三条路线还原出的序列都必须是不升的子序列
    const auto check = [&](const std::vector<int>& s) {
        std::size_t p = 0;
        for (int v : h) {
            if (p < s.size() && v == s[p]) { ++p; }
        }
        if (p != s.size()) { return false; }
        for (std::size_t i = 1; i < s.size(); ++i) {
            if (s[i - 1] < s[i]) { return false; }   // 必须 s[i-1] >= s[i]
        }
        return true;
    };
    assert(check(a) && check(b) && check(c));
    println("  三法长度一致 = 1，三条序列都通过「是 h 的子序列且不升」双向断言 = 1");

    // upper_bound vs lower_bound：h 全相等时给出最小反例
    const std::vector<int> flat{5, 5, 5};
    const std::size_t up = lnds_negated(flat, true).size();
    const std::size_t lo = lnds_negated(flat, false).size();
    println("  反例 h = [5,5,5]：upper_bound 得 {}（正确，3 个 5 互相接续），"
            "lower_bound 只得 {}（错，截断了相等接续）", up, lo);
    assert(up == 3 && lo == 1);

    // 归约的边界：LCS(A, reverse A) **不是** LNIS，那是最长回文子序列
    const std::vector<int> g{2, 1, 3};
    std::vector<int> rev(g.rbegin(), g.rend());
    // 同上：int→char 显式转换，避免 string 迭代器构造触发 C4244
    std::string gs, rs;
    gs.reserve(g.size());
    rs.reserve(rev.size());
    for (int v : g) gs.push_back(static_cast<char>(v));
    for (int v : rev) rs.push_back(static_cast<char>(v));
    const int lcsRev = lcs(gs, rs).length;
    const std::size_t lnisG = lnis_dp(g).size();
    println("  边界：LCS(A, reverse A) 是**最长回文子序列**不是 LNIS——"
            "A = [2,1,3]：LNIS = {}（[2,1]），而 LCS(A, rev A) = {}（[1] 或 [2]）", lnisG, lcsRev);
    assert(lnisG == 2 && lcsRev == 1);
}

// ═══ 16.6 反链与最小覆盖：偏序集上的 Dilworth ═══
// 网格偏序：(a,b) ⪯ (c,d) ⟺ a ≤ c 且 b ≤ d。
//   一条单调（只右/下）路径上的格子集合 = 一个**链** ⟹ 「用最少的机器人
//   清完所有垃圾」= 把 S 划分成最少的链 = 最小链覆盖数。
//   由 Dilworth：最小链覆盖数 = 最大反链大小 = |S| − 二分图最大匹配。
//   而「最大反链」有个 Θ(n lg n) 的显式刻画：按 (i 升, j 降) 排序后，
//   j 序列的**最长严格下降**子序列长度就是最大反链。

struct Cell { int i, j; };

// 最长严格下降子序列长度（对 −j 求严格上升 ⟺ 对 j 求严格下降），用 lower_bound
static std::size_t strict_lds(const std::vector<int>& js) {
    std::vector<int> t;
    for (int j : js) {
        const int v = -j;
        const auto it = std::lower_bound(t.begin(), t.end(), v);  // 严格上升 ⟹ lower_bound
        if (it == t.end()) { t.push_back(v); } else { *it = v; }
    }
    return t.size();
}

// 二分图最大匹配（Kuhn 增广路，Θ(V·E)），图是传递闭包：u ⪯ v 且 u ≠ v 则连边。
// 增广写成显式递归（深度 ≤ |S|，本例 7；大实例换 Hopcroft–Karp）。
static bool augment(std::size_t u, const std::vector<std::vector<std::size_t>>& adj,
                    std::vector<int>& matchR, std::vector<char>& seen) {
    for (std::size_t y : adj[u]) {
        if (seen[y]) { continue; }
        seen[y] = 1;
        if (matchR[y] == -1 || augment(static_cast<std::size_t>(matchR[y]), adj, matchR, seen)) {
            matchR[y] = static_cast<int>(u);
            return true;
        }
    }
    return false;
}

static std::size_t max_matching(const std::vector<Cell>& s) {
    const std::size_t n = s.size();
    std::vector<std::vector<std::size_t>> adj(n);
    for (std::size_t u = 0; u < n; ++u) {
        for (std::size_t v = 0; v < n; ++v) {
            if (u != v && s[u].i <= s[v].i && s[u].j <= s[v].j) {
                adj[u].push_back(v);
            }
        }
    }
    std::vector<int> matchR(n, -1);
    std::vector<char> seen(n, 0);
    std::size_t cnt = 0;
    for (std::size_t u = 0; u < n; ++u) {
        std::fill(seen.begin(), seen.end(), static_cast<char>(0));   // /W4: int→char 显式收窄
        if (augment(u, adj, matchR, seen)) { ++cnt; }
    }
    return cnt;
}

// 暴力求最大反链（枚举全部子集判两两不可比），只用于小规模对账
static std::size_t max_antichain_brute(const std::vector<Cell>& s) {
    const std::size_t n = s.size();
    std::size_t best = 0;
    for (std::uint64_t mask = 1; mask < (std::uint64_t{1} << n); ++mask) {
        bool ok = true;
        for (std::size_t a = 0; a < n && ok; ++a) {
            if (((mask >> a) & 1U) == 0U) { continue; }
            for (std::size_t b = a + 1; b < n; ++b) {
                if (((mask >> b) & 1U) == 0U) { continue; }
                // 可比 = (i_a ≤ i_b 且 j_a ≤ j_b) 或 (i_b ≤ i_a 且 j_b ≤ j_a)
                const bool ab = s[a].i <= s[b].i && s[a].j <= s[b].j;
                const bool ba = s[b].i <= s[a].i && s[b].j <= s[a].j;
                if (ab || ba) { ok = false; break; }
            }
        }
        if (ok) { best = std::max(best, static_cast<std::size_t>(std::popcount(mask))); }
    }
    return best;
}

static void antichain_demo() {
    // 7 个垃圾格（行优先输入，同行内 j 升序 —— 必须重排成 j 降序）
    const std::vector<Cell> trash{{1, 2}, {1, 4}, {2, 4}, {2, 6}, {4, 4}, {4, 7}, {6, 6}};
    std::vector<Cell> s = trash;
    std::ranges::sort(s, [](const Cell& x, const Cell& y) { return x.i != y.i ? x.i < y.i : x.j > y.j; });

    println("=== 16.6 最小单调路径覆盖 = 最大反链 = |S| − 二分图最大匹配 ===");
    print("  垃圾格 S = [");
    for (std::size_t i = 0; i < trash.size(); ++i) {
        print("({},{}){}", trash[i].i, trash[i].j, i + 1 == trash.size() ? "" : ", ");
    }
    println("]");
    print("  按 (i 升, j 降) 重排后 j 序列 = [");
    std::vector<int> js;
    for (std::size_t i = 0; i < s.size(); ++i) {
        js.push_back(s[i].j);
        print("{}{}", s[i].j, i + 1 == s.size() ? "" : ", ");
    }
    println("]");

    const std::size_t lds = strict_lds(js);
    const std::size_t anti = max_antichain_brute(s);
    const std::size_t mm = max_matching(s);
    println("  LDS（j 的最长严格下降子序列）= {}", lds);
    println("  暴力最大反链（枚举 2^7 子集）= {}", anti);
    println("  二分图最大匹配（传递闭包 + 增广路）= {} ⟹ |S| − 匹配 = {} − {} = {}",
            mm, s.size(), mm, s.size() - mm);
    println("  三者一致 ⟹ 最少机器人 = {} 个（三步链条：链划分 → Dilworth → 反链 → LDS）",
            lds);
    assert(lds == 2 && anti == 2 && mm == 5 && s.size() - mm == 2);

    // 第二组：一条单调路径就够
    const std::vector<Cell> chain{{1, 1}, {2, 2}, {4, 4}};
    std::vector<Cell> c2 = chain;
    std::ranges::sort(c2, [](const Cell& x, const Cell& y) { return x.i != y.i ? x.i < y.i : x.j > y.j; });
    std::vector<int> js2;
    for (const Cell& c : c2) { js2.push_back(c.j); }
    const std::size_t lds2 = strict_lds(js2);
    const std::size_t mm2 = max_matching(c2);
    println("  对照 S = [(1,1),(2,2),(4,4)]：j 序列 = [1,2,4] 全升 ⟹ LDS = {}，"
            "最大匹配 = {} ⟹ |S| − 匹配 = {}（一条单调路径清完）",
            lds2, mm2, c2.size() - mm2);
    assert(lds2 == 1 && mm2 == 2);

    // 第三组：空网格
    const std::vector<Cell> none;
    std::vector<Cell> e = none;
    println("  空网格 S = []：LDS = {}，最大匹配 = {} ⟹ 最少机器人 = {} 个",
            strict_lds({}), max_matching(e), 0);
    assert(strict_lds({}) == 0 && max_matching(e) == 0);
}

// ═══ 16.7 石子合并：区间 DP（直线 / 圆环，最小 / 最大）═══
// n 堆石子排成一线（或圆环），每次只能合并**相邻**两堆，花费 = 新堆的
// 石子数。关键观察：无论按什么顺序合并，最后一次一定在某个「缝」k 处把
// 区间 [i,j] 分成左右两段，而最后一次的花费恒为整段石子总数 w(i,j)。
//   mn[i][j] = min_{i≤k<j}(mn[i][k] + mn[k+1][j]) + w(i,j)
//   mx[i][j] = max_{i≤k<j}(mx[i][k] + mx[k+1][j]) + w(i,j)
// 单堆 mn[i][i] = mx[i][i] = 0。w(i,j) 用前缀和 O(1) 查表。
// 圆环：复制成 a,a[0..n−2] 共 2n−1 堆的直线，在所有长度 n 的窗口里取极值。

static std::uint32_t stone_rand_below(std::mt19937& rng, std::uint32_t n) {
    return static_cast<std::uint32_t>(
        (static_cast<std::uint64_t>(rng()) * n) >> 32);
}

struct StoneTables {
    std::vector<std::vector<int>> mn;    // mn[i][j]：合并第 i..j 堆的最小花费
    std::vector<std::vector<int>> mx;
    std::vector<std::vector<int>> cut;   // 取得最小值的分割缝（重构合并树）
};

static StoneTables stone_build(const std::vector<int>& a) {
    const int m = static_cast<int>(a.size());
    std::vector<long long> pref(static_cast<std::size_t>(m) + 1, 0);
    for (int i = 0; i < m; ++i) {
        pref[static_cast<std::size_t>(i) + 1] =
            pref[static_cast<std::size_t>(i)] + a[static_cast<std::size_t>(i)];
    }
    StoneTables t;
    t.mn.assign(static_cast<std::size_t>(m),
                std::vector<int>(static_cast<std::size_t>(m), 0));
    t.mx.assign(static_cast<std::size_t>(m),
                std::vector<int>(static_cast<std::size_t>(m), 0));
    t.cut.assign(static_cast<std::size_t>(m),
                 std::vector<int>(static_cast<std::size_t>(m), 0));
    for (int i = 0; i < m; ++i) { t.cut[static_cast<std::size_t>(i)][static_cast<std::size_t>(i)] = i; }
    // 按区间长度自小到大：算 [i,j] 时所有更短的子区间都已就绪。
    for (int width = 2; width <= m; ++width) {
        for (int i = 0; i + width <= m; ++i) {
            const int j = i + width - 1;
            const int total =
                static_cast<int>(pref[static_cast<std::size_t>(j) + 1]
                                 - pref[static_cast<std::size_t>(i)]);
            int lo = INT32_MAX, hi = INT32_MIN, bestk = i;
            for (int k = i; k < j; ++k) {
                const int vl = t.mn[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)]
                             + t.mn[static_cast<std::size_t>(k) + 1][static_cast<std::size_t>(j)] + total;
                const int vh = t.mx[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)]
                             + t.mx[static_cast<std::size_t>(k) + 1][static_cast<std::size_t>(j)] + total;
                if (vl < lo) { lo = vl; bestk = k; }
                if (vh > hi) { hi = vh; }
            }
            t.mn[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] = lo;
            t.mx[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] = hi;
            t.cut[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] = bestk;
        }
    }
    return t;
}

// 圆环：在 2n−1 的复制序列上做一次直线 DP，扫描 n 个长度 n 的窗口。
struct CircleAnswer { int mn, mx; };

static CircleAnswer stone_circle(const std::vector<int>& a) {
    const int n = static_cast<int>(a.size());
    std::vector<int> b;
    b.reserve(static_cast<std::size_t>(2 * n - 1));
    b = a;
    for (int i = 0; i < n - 1; ++i) {
        b.push_back(a[static_cast<std::size_t>(i)]);
    }
    const StoneTables t = stone_build(b);
    int lo = 0, hi = 0;
    if (n >= 1) {
        lo = t.mn[0][static_cast<std::size_t>(n) - 1];
        hi = t.mx[0][static_cast<std::size_t>(n) - 1];
    }
    for (int i = 1; i < n; ++i) {
        lo = std::min(lo, t.mn[static_cast<std::size_t>(i)]
                                  [static_cast<std::size_t>(i + n) - 1]);
        hi = std::max(hi, t.mx[static_cast<std::size_t>(i)]
                                  [static_cast<std::size_t>(i + n) - 1]);
    }
    return {lo, hi};
}

// 按 cut 表把最小花费的合并树写成括号式，直接读就能得到合并顺序。
static std::string stone_scheme(const std::vector<int>& a,
                                const StoneTables& t, int i, int j) {
    if (i == j) { return std::to_string(a[static_cast<std::size_t>(i)]); }
    const int k = t.cut[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)];
    return "(" + stone_scheme(a, t, i, k) + " " +
           stone_scheme(a, t, k + 1, j) + ")";
}

// 暴力对账：在可变堆列表上真实枚举每个相邻合并。直线的对数 = m−1；
// 圆环还有首尾对，对数 = m。与 DP 的代码路径完全独立。
static void stone_brute_rec(const std::vector<int>& piles, bool circle,
                            int spent, int& lo, int& hi) {
    const int m = static_cast<int>(piles.size());
    if (m == 1) {
        lo = std::min(lo, spent);
        hi = std::max(hi, spent);
        return;
    }
    const int pairs = circle ? m : m - 1;
    for (int p = 0; p < pairs; ++p) {
        const int q = (p + 1) % m;
        const int merged = piles[static_cast<std::size_t>(p)]
                         + piles[static_cast<std::size_t>(q)];
        std::vector<int> next;
        next.reserve(static_cast<std::size_t>(m - 1));
        for (int z = 0; z < m; ++z) {
            if (z == q) { continue; }
            next.push_back(z == p ? merged : piles[static_cast<std::size_t>(z)]);
        }
        stone_brute_rec(next, circle, spent + merged, lo, hi);
    }
}

static void stone_brute(const std::vector<int>& a, bool circle,
                        int& out_lo, int& out_hi) {
    out_lo = INT32_MAX;
    out_hi = INT32_MIN;
    stone_brute_rec(a, circle, 0, out_lo, out_hi);
}

static void stone_merge_demo() {
    println("=== 16.7 石子合并：区间 DP（直线 / 圆环）===");
    const std::vector<int> a{5, 8, 6, 9, 2, 3};
    const StoneTables t = stone_build(a);
    const CircleAnswer c = stone_circle(a);
    const std::string scheme = stone_scheme(a, t, 0,
                                           static_cast<int>(a.size()) - 1);
    println("  6 堆 [5,8,6,9,2,3]：直线最小 {}、最大 {}；圆环最小 {}、最大 {}",
            t.mn[0][5], t.mx[0][5], c.mn, c.mx);
    assert(t.mn[0][5] == 84 && t.mx[0][5] == 129);
    assert(c.mn == 81 && c.mx == 130);
    println("  最小花费的合并树（括号式，内层先合并）：{}", scheme);
    // 同一合并树在「直线最小」上的总花费必须自洽：逐对内层和 = 84。
    // 与暴力枚举（直线、圆环分别全枚举）对账。
    int brute_lmn = 0, brute_lmx = 0, brute_cmn = 0, brute_cmx = 0;
    stone_brute(a, false, brute_lmn, brute_lmx);
    stone_brute(a, true, brute_cmn, brute_cmx);
    println("  暴力枚举全部合并历史：直线 {}/{}，圆环 {}/{}（与 DP 完全一致 = 1）",
            brute_lmn, brute_lmx, brute_cmn, brute_cmx);
    assert(brute_lmn == 84 && brute_lmx == 129);
    assert(brute_cmn == 81 && brute_cmx == 130);

    // 随机小例四向对账：直线/圆环 × DP/暴力；顺带验证「最大值在端点」性质：
    //   mx[i][j] = max(mx[i][j−1], mx[i+1][j]) + w(i,j)
    std::mt19937 rng{5489};
    const int trials = 3000;
    int mismatches = 0, endpoint_violations = 0;
    for (int s = 0; s < trials; ++s) {
        const int n = 1 + static_cast<int>(stone_rand_below(rng, 6));
        std::vector<int> piles(static_cast<std::size_t>(n));
        for (int& v : piles) {
            v = 1 + static_cast<int>(stone_rand_below(rng, 9));
        }
        const StoneTables tl = stone_build(piles);
        const CircleAnswer cc = stone_circle(piles);
        int blmn = 0, blmx = 0, bcmn = 0, bcmx = 0;
        stone_brute(piles, false, blmn, blmx);
        stone_brute(piles, true, bcmn, bcmx);
        if (tl.mn[0][static_cast<std::size_t>(n) - 1] != blmn ||
            tl.mx[0][static_cast<std::size_t>(n) - 1] != blmx ||
            cc.mn != bcmn || cc.mx != bcmx) { ++mismatches; }
        // 端点性质（n≥2 才有意义）
        if (n >= 2) {
            std::vector<long long> prefix(static_cast<std::size_t>(n) + 1, 0);
            for (int z = 0; z < n; ++z) {
                prefix[static_cast<std::size_t>(z) + 1] =
                    prefix[static_cast<std::size_t>(z)] +
                    piles[static_cast<std::size_t>(z)];
            }
            for (int width = 2; width <= n; ++width) {
                for (int i = 0; i + width <= n; ++i) {
                    const int j = i + width - 1;
                    const int wsum = static_cast<int>(
                        prefix[static_cast<std::size_t>(j) + 1]
                        - prefix[static_cast<std::size_t>(i)]);
                    const int endpoint =
                        std::max(tl.mx[static_cast<std::size_t>(i)][static_cast<std::size_t>(j) - 1],
                                 tl.mx[static_cast<std::size_t>(i) + 1][static_cast<std::size_t>(j)]) + wsum;
                    if (endpoint != tl.mx[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)]) {
                        ++endpoint_violations;
                    }
                }
            }
        }
    }
    println("  随机 {} 小例（n≤6）：四向对账不一致 {} 例；最大值端点性质违反 {} 例",
            trials, mismatches, endpoint_violations);
    assert(mismatches == 0 && endpoint_violations == 0);

    // 大例：n=300 也能瞬间完成，直/环答案都有合理上下界。
    const int nbig = 300;
    std::vector<int> big(static_cast<std::size_t>(nbig));
    std::mt19937 big_rng{5489};
    long long total = 0;
    for (int& v : big) {
        v = 1 + static_cast<int>(stone_rand_below(big_rng, 99));
        total += v;
    }
    const StoneTables tb = stone_build(big);
    const CircleAnswer cb = stone_circle(big);
    println("  大例（{} 堆，每堆 ≤99）：直线最小 {}，圆环最小 {}（单趟总和 {} ⇒ 答案≥总和）",
            nbig, tb.mn[0][nbig - 1], cb.mn, total);
    assert(tb.mn[0][nbig - 1] >= total);
    assert(cb.mn <= tb.mn[0][nbig - 1]);   // 圆环缝口自由，不会比直线差
}

int main() {
    lcs_demo();
    optimal_bst_demo();
    edit_distance_demo();
    lnis_demo();
    antichain_demo();
    stone_merge_demo();
    println("自检通过");
    return 0;
}
