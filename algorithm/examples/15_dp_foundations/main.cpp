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

int main() {
    rod_cutting_demo();
    reconstruction_demo();
    matrix_chain_demo();
    overlap_demo();
    println("自检通过");
    return 0;
}
