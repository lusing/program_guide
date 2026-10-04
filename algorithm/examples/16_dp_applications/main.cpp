// 16 动态规划（下）：LCS、最优 BST 与编辑距离（CLRS §15.4–15.5）。
// 结构：16.1 LCS（c/b 表 + 重构，图 15.8 数据）/ 16.2 前缀码性质与
// 多重对账 / 16.3 最优 BST（图 15.10 数据，期望代价 2.75）/
// 16.4 编辑距离（LCS 的变体，C++ 实战延伸）。
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
#include <string>
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

int main() {
    lcs_demo();
    optimal_bst_demo();
    edit_distance_demo();
    println("自检通过");
    return 0;
}
