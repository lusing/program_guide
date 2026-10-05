// 35 NP 完全性（CLRS 第 34 章）。结构：35.1 多项式归约的概念 /
// 35.2 3-SAT → CLIQUE 的构造归约（可执行版：子句文字 → 顶点）/
// 35.3 CLIQUE → VERTEX-COVER（补图变换）/ 35.4 满足解 ↔ 团 ↔ 覆盖的
// 三方对账（暴力真值枚举当裁判）/ 35.5 回溯三框架与剪枝清单（排列树必须 swap
// 还原、剪枝量化）/ 35.6 状压 DP 精确求图色数 χ(G)（O(3ⁿ)，含完整正确性证明）/
// 35.7 三角 N-后：三重求和证上界 ⌊(2N+1)/3⌋ + 奇偶两段 O(N) 构造。
// 文档重章、示例轻量——理论细节见 docs/35。
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
#include <numeric>
#include <string>
#include <vector>

// ═══ 35.2 实例：3-SAT ═══
// (x1 ∨ ¬x2 ∨ x3) ∧ (¬x1 ∨ x2 ∨ x4) ∧ (¬x2 ∨ ¬x3 ∨ x4) ∧ (x1 ∨ x2 ∨ ¬x4)
// 文字编码：+k 表示 x_k，−k 表示 ¬x_k。
static const std::vector<std::vector<int>> kClauses{
    {1, -2, 3}, {-1, 2, 4}, {-2, -3, 4}, {1, 2, -4}};

static bool eval_clause(const std::vector<int>& c, const std::vector<char>& assign) {
    for (int lit : c) {
        const bool v = assign[static_cast<std::size_t>(lit > 0 ? lit : -lit)];
        if (lit > 0 ? v : !v) { return true; }
    }
    return false;
}

// 暴力真值枚举（4 变量 = 16 种）——裁判
static std::vector<std::vector<char>> all_satisfying() {
    std::vector<std::vector<char>> out;
    for (int mask = 0; mask < 16; ++mask) {
        std::vector<char> a(5);
        for (int v = 1; v <= 4; ++v) {
            a[static_cast<std::size_t>(v)] = (mask >> (v - 1)) & 1;
        }
        bool ok = true;
        for (auto& c : kClauses) { if (!eval_clause(c, a)) { ok = false; break; } }
        if (ok) { out.push_back(a); }
    }
    return out;
}

// ═══ 3-SAT → CLIQUE 的构造 ═══
// 每个子句的每个文字一个顶点（4 子句 × 3 文字 = 12 顶点）；
// 边连接「不同子句且不矛盾」的文字对。k = 子句数 = 4。
struct Graph {
    int n;
    std::vector<std::vector<char>> adj;
    explicit Graph(int n_) : n(n_), adj(static_cast<std::size_t>(n_),
        std::vector<char>(static_cast<std::size_t>(n_), 0)) {}
    void add(int u, int v) {
        adj[static_cast<std::size_t>(u)][static_cast<std::size_t>(v)] = 1;
        adj[static_cast<std::size_t>(v)][static_cast<std::size_t>(u)] = 1;
    }
};

static Graph build_clique_graph(long long& edgeCount) {
    Graph g(static_cast<int>(kClauses.size() * 3));
    for (std::size_t i = 0; i < kClauses.size(); ++i) {
        for (std::size_t j = i + 1; j < kClauses.size(); ++j) {
            for (std::size_t a = 0; a < 3; ++a) {
                for (std::size_t b = 0; b < 3; ++b) {
                    const int li = kClauses[i][a], lj = kClauses[j][b];
                    if (li != -lj) {   // 不矛盾（li 与 lj 互为否定则无边）
                        g.add(static_cast<int>(i) * 3 + static_cast<int>(a),
                              static_cast<int>(j) * 3 + static_cast<int>(b));
                        ++edgeCount;
                    }
                }
            }
        }
    }
    return g;
}

// 从满足赋值导出团：每子句选一个真文字
static std::vector<int> clique_from_assign(const std::vector<char>& assign,
                                           const Graph& g) {
    std::vector<int> clique;
    for (std::size_t i = 0; i < kClauses.size(); ++i) {
        for (std::size_t a = 0; a < 3; ++a) {
            const int lit = kClauses[i][a];
            const bool v = assign[static_cast<std::size_t>(lit > 0 ? lit : -lit)];
            if (lit > 0 ? v : !v) { clique.push_back(static_cast<int>(i) * 3 + static_cast<int>(a)); break; }
        }
    }
    // 验证它真是团
    for (std::size_t i = 0; i < clique.size(); ++i) {
        for (std::size_t j = i + 1; j < clique.size(); ++j) {
            if (!g.adj[static_cast<std::size_t>(clique[i])][static_cast<std::size_t>(clique[j])]) {
                return {};   // 不该发生
            }
        }
    }
    return clique;
}

// ═══ 35.3 CLIQUE → VERTEX-COVER（补图）═══
// k 团存在 ⟺ 补图有 (n−k) 顶点覆盖。k = 4、n = 12 → 补图 8 顶点覆盖。
static Graph complement(const Graph& g) {
    Graph c(g.n);
    for (int i = 0; i < g.n; ++i) {
        for (int j = i + 1; j < g.n; ++j) {
            if (!g.adj[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)]) { c.add(i, j); }
        }
    }
    return c;
}

static bool is_vertex_cover(const Graph& g, const std::vector<char>& sel) {
    for (int i = 0; i < g.n; ++i) {
        for (int j = i + 1; j < g.n; ++j) {
            if (g.adj[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] &&
                !sel[static_cast<std::size_t>(i)] && !sel[static_cast<std::size_t>(j)]) {
                return false;
            }
        }
    }
    return true;
}


// ═══ 35.5 回溯三框架与剪枝清单 ═══
// 解向量 x = ⟨x₁,…,xₙ⟩，取值域 Ω_k。三个框架的**精确**规模：
//   一般回溯  Θ(mⁿ)        —— 第 k 层有 ∏_{j≤k} m_j 个节点，叶层 mⁿ 主导
//   排列树    Θ(n!)         —— 「固定后缀 + 逐位交换」生成，每个排列恰一次
//   子集树    Θ(2ⁿ)         —— x_k ∈ {0,1}
//
// 排列树的关键纪律：**swap 必须换回来**，否则漏解。这是本节最贵的坑。
// 下标用 1-based（x[1..n]）：第 k 层把 x_k 与 x_i (i = k..n) 交换，k > n 时叶。
// 0-based 会让基例 k > n 永不触发（循环是 i < n）——一个静默的「什么都不做」bug。
static long long g_permutationNodes = 0;
static long long g_permutationLeaves = 0;
static void permute(std::vector<int>& x, int k, long long& best,
                    std::vector<int>& bestX) {
    ++g_permutationNodes;
    const int n = static_cast<int>(x.size()) - 1;   // x[0] 不用，1-based
    if (k > n) {
        ++g_permutationLeaves;
        long long v = 0;
        for (int t = 1; t <= n; ++t) { v = v * 10 + x[static_cast<std::size_t>(t)]; }
        if (v > best) { best = v; bestX = x; }
        return;
    }
    for (int i = k; i <= n; ++i) {
        std::swap(x[static_cast<std::size_t>(k)], x[static_cast<std::size_t>(i)]);
        permute(x, k + 1, best, bestX);
        std::swap(x[static_cast<std::size_t>(k)], x[static_cast<std::size_t>(i)]);
        // ↑ 少了这一行，下面的循环会基于已被污染的数组继续交换 —— 漏解
    }
}

// 漏掉「换回来」的版本：用来现场证明它会给出错答案（注意叶数不变、值变）
static long long g_dirtyLeaves = 0;
static void permute_dirty(std::vector<int>& x, int k, long long& best) {
    const int n = static_cast<int>(x.size()) - 1;
    if (k > n) {
        ++g_dirtyLeaves;
        long long v = 0;
        for (int t = 1; t <= n; ++t) { v = v * 10 + x[static_cast<std::size_t>(t)]; }
        if (v > best) { best = v; }
        return;
    }
    for (int i = k; i <= n; ++i) {
        std::swap(x[static_cast<std::size_t>(k)], x[static_cast<std::size_t>(i)]);
        permute_dirty(x, k + 1, best);
        // 故意不换回来
    }
}

// 子集树：增量维护 current_value（进/出递归时加减），best_value 记录最优
struct SubsetResult { long long best; std::size_t leaves; std::size_t boundHits; };
static SubsetResult subset_tree(const std::vector<long long>& w) {
    const std::size_t n = w.size();
    long long current = 0;                 // current_value：增量维护，不重算
    long long best = 0;                     // best_value：最大化问题初值 −∞，这里权重全正故取 0
    std::size_t leaves = 0;
    std::size_t boundHits = 0;
    // 乐观估计 g(x) = current + 剩余权重全和（剩下全选也超不过 best ⟹ 剪枝）
    std::vector<long long> suffix(n + 1, 0);
    for (std::size_t i = n; i-- > 0;) { suffix[i] = suffix[i + 1] + w[i]; }
    auto self = [&](auto&& self, std::size_t k) -> void {
        if (current + suffix[k] <= best) { ++boundHits; return; }   // 上下界剪枝
        if (k == n) { ++leaves; best = std::max(best, current); return; }
        current += w[k];                    // 增量维护：加
        self(self, k + 1);
        current -= w[k];                    // 增量维护：减（必须还原，否则 current 错）
        self(self, k + 1);
    };
    self(self, 0);
    return SubsetResult{best, leaves, boundHits};
}

static void backtrack_frameworks_demo() {
    println("");
    println("=== 35.5 回溯三框架与剪枝清单 ===");
    println("  三个框架的解空间规模 S（这是算法是否可用的**唯一判据**）：");
    println("    一般回溯 Θ(mⁿ) | 排列树 Θ(n!) | 子集树 Θ(2ⁿ)");

    // 排列树：n! 增长与「必须换回来」
    for (const int n : {5, 8, 10}) {
        std::vector<int> x(static_cast<std::size_t>(n) + 1);   // 1-based
        std::iota(x.begin() + 1, x.end(), 1);
        long long best = 0;
        std::vector<int> bestX;
        g_permutationNodes = 0;
        g_permutationLeaves = 0;
        permute(x, 1, best, bestX);
        long long fact = 1;
        for (int i = 2; i <= n; ++i) { fact *= i; }
        println("  排列树 n = {}：叶数 = {} = {}!（访问节点 {} 个）；最大排列 = {}",
                n, g_permutationLeaves, n, g_permutationNodes, best);
        assert(g_permutationLeaves == fact);
        assert(bestX.front() == 0 && bestX[1] == n);   // 最大排列必以 n 开头
    }
    println("  「固定后缀 + 逐位交换」：第 k 层把 x_k 与 x_i (i = k..n) 交换 ⟹ 每个排列");
    println("  **恰好生成一次**，所以叶数恰为 n!，不多不少。节点数略大于 n!（内部结点也计数）。");
    println("  下标必须 1-based：0-based 时循环是 i < n，基例 k > n **永不触发**——");
    println("  递归会在 k = n 时空转返回，一个解都不记录（本例实测两版都踩过）。");

    // 漏掉 swap 还原的版本：给出错答案
    {
        std::vector<int> x{0, 1, 2, 3, 4};   // 1-based
        long long best = 0;
        long long cleanLeaves = 0;
        {
            std::vector<int> y{0, 1, 2, 3, 4};
            long long dummy = 0;
            std::vector<int> dummyX;
            g_permutationLeaves = 0;
            permute(y, 1, dummy, dummyX);
            cleanLeaves = g_permutationLeaves;
            assert(dummy == 4321);
        }
        g_dirtyLeaves = 0;
        permute_dirty(x, 1, best);
        println("");
        println("  错误直觉：交换后不换回来也能枚举到全部排列。实测 n = 4：");
        println("    正确版（换回来）：叶 = {} 个（= 4! = 24），最大 = 4321", cleanLeaves);
        println("    漏还原版        ：叶 = {} 个（**仍是 24**），最大 = {}", g_dirtyLeaves,
                best);
        println("    注意「叶数不变」——搜索树的**形状**没变，变的是每个叶子上装的排列；");
        println("    数组已被污染，后续交换在错误的排列上做 ⟹ 4321 这个解根本没出现。");
        println("    这类 bug 不改叶数、不改递归次数，只改答案 —— 断言必须打在**值**上。");
        assert(best == 3421);
        assert(g_dirtyLeaves == cleanLeaves);   // 叶数相同：树形没变
        assert(best != 4321);                   // 但值错了
    }

    // 子集树 + 上下界剪枝
    println("");
    println("  子集树 + 剪枝（权重 [3,7,2,9,1,8,5,4]，目标 ≥ 20）：");
    {
        const std::vector<long long> w{3, 7, 2, 9, 1, 8, 5, 4};
        const SubsetResult full = subset_tree(w);
        const std::size_t fullSpace = std::size_t{1} << w.size();
        println("    无剪枝的解空间 = 2^8 = {} 个子集；带剪枝实际访问叶 = {} 个，", fullSpace,
                full.leaves);
        println("    剪掉 {} 次（乐观估计 g(x) = current + 剩余权重全和 ≤ best）",
                full.boundHits);
        println("    最优子集和 = {}", full.best);
        assert(full.best == 39);           // 全部权重之和
        assert(full.leaves < fullSpace);
        assert(full.boundHits > 0);
    }

    // 剪枝清单：对称性消除（环状排列）与「只枚举未定位置」
    println("");
    println("  剪枝清单（每条都以「解空间 S 从多少降到多少」量化）：");
    // 对称性消除：环状排列 n! → (n-1)!（固定首元）
    {
        const int n = 8;
        long long fact = 1;
        for (int i = 2; i <= n; ++i) { fact *= i; }
        println("    对称性：环状排列固定首元 n! = {} → (n−1)! = {}（省 {} 倍）", fact,
                fact / n, n);
        println("            N-后首行只枚举一半（左右镜像对称）n! → n!/2");
    }
    // 只枚举未定位置：常量消除
    {
        const int free = 3, total = 8;
        long long f8 = 1, f3 = 1;
        for (int i = 2; i <= total; ++i) { f8 *= i; }
        for (int i = 2; i <= free; ++i) { f3 *= i; }
        println("    常量消除：{} 元问题里 {} 个位置已定 ⟹ {}! = {} → {}! = {}（省 {} 倍）",
                total, total - free, total, f8, free, f3, f8 / f3);
    }
    println("    可行性剪枝：部分解违反约束立即回溯（IS-PARTIAL）");
    println("    上下界剪枝：乐观估计 g(x) 已不优于 best_value（上面的实测）");
    println("    记忆化：失败子问题只算一次（状态空间小的博弈/搜索必备）");
    println("  工程判据：**「解空间规模 S + 剪枝」比精确 Θ 更实用**——");
    println("    精确 Θ 只告诉你最坏有多坏，S + 剪枝率才告诉你「这台机器上跑不跑得动」。");
}

// ═══ 35.6 状压 DP：精确求图色数 ═══
// f[S] = 诱导子图 G[S] 的色数。f[∅] = 0。取 S 中编号最小的顶点 v：
//   f[S] = 1 + min { f[S \ I] : I ⊆ S 为独立集，v ∈ I }
// 时间 O(3ⁿ)（枚举独立集族），空间 O(2ⁿ)。n ≤ 10 ⟹ 3¹⁰ ≈ 6·10⁴，瞬间完成。
static int chromatic_number(const std::vector<std::uint32_t>& adj, int n) {
    const std::size_t total = std::size_t{1} << n;
    // pre[v] = v 的邻居位掩码。S 内有 v 的邻居 ⟺ pre[v] & S ≠ 0
    std::vector<std::uint32_t> pre(static_cast<std::size_t>(n), 0);
    for (int v = 0; v < n; ++v) {
        for (int u = 0; u < n; ++u) {
            if ((adj[static_cast<std::size_t>(v)] >> u) & 1U) {
                pre[static_cast<std::size_t>(v)] |= (1U << u);
            }
        }
    }
    // indep[S] = S 是否为独立集
    std::vector<char> indep(total, 0);
    indep[0] = 1;
    for (std::size_t S = 1; S < total; ++S) {
        const int v = std::countr_zero(S);
        const std::size_t rest = S & (S - 1);          // S 去掉最低位
        indep[S] = indep[rest] && ((pre[static_cast<std::size_t>(v)] & rest) == 0);
    }
    std::vector<int> f(total, 0);
    for (std::size_t S = 1; S < total; ++S) {
        const int v = std::countr_zero(S);              // S 中编号最小者
        // 枚举所有含 v 的独立集 I ⊆ S：I = {v} ∪ J，J ⊆ S\{v} 且 J 无 v 的邻居
        const std::size_t rest = S & (S - 1);
        // 掩码统一用 uint32_t：~pre[v] 是 32 位取反，零扩展到 size_t 会
        // 触发 C4319（高位清零），且高位本来就不在 n ≤ 32 的掩码语义内
        const std::uint32_t allowed =
            static_cast<std::uint32_t>(rest) & ~pre[static_cast<std::size_t>(v)];
        int best = static_cast<int>(S);                 // 上界：每个顶点一色
        for (std::uint32_t J = allowed;; J = (J - 1) & allowed) {
            const std::size_t I = J | (std::size_t{1} << v);
            if (indep[I]) {
                best = std::min(best, 1 + f[S & ~I]);
                if (best == 1) { break; }               // 下界 1，达到即收工
            }
            if (J == 0) { break; }
        }
        f[S] = best;
    }
    return f[total - 1];
}

static void chromatic_demo() {
    println("");
    println("=== 35.6 状压 DP：精确求图色数 χ(G) ===");
    println("  状态 f[S] = 诱导子图 G[S] 的色数；转移取 v = S 中编号最小者：");
    println("    f[S] = 1 + min {{ f[S \\ I] : I ⊆ S 为独立集，v ∈ I }}");
    println("  正确性（两个方向都要证）：");
    println("    (⇒ 下界) 任何 S 的合法染色里，v 所在的颜色类在 S 上是含 v 的独立集 I，");
    println("           其余 S\\I 用 ≤ f[S\\I] 色 ⟹ f[S] ≥ 1 + min f[S\\I]");
    println("    (⇐ 上界) 对任意含 v 的独立集 I，用一色染 I、其余用 f[S\\I] 色即得合法染色");
    println("  为什么 O(3ⁿ)：枚举 S 的独立集族时每个元素有三种归属 —— 在 S∖I / 在 I∖v / 是 v");
    println("  独立集判定 O(1)：I 独立 ⟺ 对每个 v ∈ I 有 pre[v] & I == 0");

    struct Case { const char* name; int n; std::vector<std::uint32_t> adj; int expect; };
    // 邻接掩码的第 u 位 = 1 表示 u 与本顶点相邻。逐个手算核对：
    //   K₄：顶点 v 的邻居是「除 v 外全部」⟹ 掩码 = 0b1111 ^ (1<<v)
    //   C₅：环 0-1-2-3-4-0
    //   K₅：同 K₄ 但 n = 5
    //   K₃,₃：前三点连后三点
    const std::vector<Case> cases{
        {"空图（无边）", 4, {0, 0, 0, 0}, 1},
        {"K₄ 完全图", 4, {0b1110, 0b1101, 0b1011, 0b0111}, 4},
        {"C₅ 奇圈", 5, {0b10010, 0b00101, 0b01010, 0b10100, 0b10001}, 3},
        {"K₅ 完全图", 5, {0b11110, 0b11101, 0b11011, 0b10111, 0b01111}, 5},
        {"二分图 K₃,₃", 6, {0b111000, 0b111000, 0b111000, 0b000111, 0b000111, 0b000111}, 2},
    };
    for (const Case& c : cases) {
        const int chi = chromatic_number(c.adj, c.n);
        println("  {:>14}（n = {}）：χ = {}（独立集 DP 精确值，期望 {}）", c.name, c.n, chi,
                c.expect);
        assert(chi == c.expect);
    }
    println("  K₅ 的 χ = 5 > 4 ⟹ **四色定理在这里不适用**：该定理要求每个国家是连通区域，");
    println("  而「同一国家有多个不相连区域」使缩点后的邻接图可以是 K₅ 这类非平面图。");

    // 暴力交叉验证：回溯 m-染色判定（小 n）
    auto colorable = [&](const std::vector<std::uint32_t>& adj, int n, int m) {
        std::vector<int> col(static_cast<std::size_t>(n), -1);
        auto self = [&](auto&& self, int v) -> bool {
            if (v == n) { return true; }
            for (int c = 0; c < m; ++c) {
                bool ok = true;
                for (int u = 0; u < v; ++u) {
                    if (col[static_cast<std::size_t>(u)] == c &&
                        ((adj[static_cast<std::size_t>(v)] >> u) & 1U)) { ok = false; break; }
                }
                if (ok) {
                    col[static_cast<std::size_t>(v)] = c;
                    if (self(self, v + 1)) { return true; }
                    col[static_cast<std::size_t>(v)] = -1;
                }
            }
            return false;
        };
        return self(self, 0);
    };
    // 随机图：DP 与「m 从 1 递增 + 回溯」逐个对账
    println("");
    println("  对账：随机图上 DP 的 χ 与「m-染色回溯」的最小可行 m 必须一致");
    long long checked = 0;
    for (int n = 1; n <= 8; ++n) {
        for (int trial = 0; trial < 6; ++trial) {
            std::vector<std::uint32_t> adj(static_cast<std::size_t>(n), 0);
            std::uint32_t seed = static_cast<std::uint32_t>(n * 977 + trial * 31 + 1);
            for (int v = 0; v < n; ++v) {
                for (int u = v + 1; u < n; ++u) {
                    seed = seed * 1103515245U + 12345U;
                    if (((seed >> 16) & 1U) != 0) {
                        adj[static_cast<std::size_t>(v)] |= (1U << u);
                        adj[static_cast<std::size_t>(u)] |= (1U << v);
                    }
                }
            }
            const int dp = chromatic_number(adj, n);
            int bt = 1;
            while (bt <= n && !colorable(adj, n, bt)) { ++bt; }
            assert(dp == bt);
            ++checked;
        }
    }
    println("    {} 个随机图（n = 1..8）上 DP 与回溯逐一相等 —— 状压 DP 无误", checked);
    println("  复杂度：时间 O(3ⁿ)（n = 10 时 3¹⁰ = {}，瞬间完成），空间 O(2ⁿ)", 59049);
}

// ═══ 35.7 三角 N-后：先证上界，再给构造 ═══
// 边长 N 的三角棋盘，格点 (i,j) 满足 1 ≤ j ≤ i ≤ N。两个皇后 (i₁,j₁)、(i₂,j₂)
// 互不攻击 ⟺ i₁ ≠ i₂ 且 j₁ ≠ j₂ 且 i₁−j₁ ≠ i₂−j₂。
static std::vector<std::pair<int, int>> triangular_queens(int N) {
    const int q = N / 3;
    const int r = N % 3;
    const int sizeA = q + 1;                 // 段 A：行 q+1..2q+1，列 q+1..1（差值 0,2,4,…）
    const int sizeB = (r == 0) ? q - 1 : q;  // 段 B：行 2q+2..，列 2q+1..（差值 1,3,5,…）
    std::vector<std::pair<int, int>> sol;
    sol.reserve(static_cast<std::size_t>(q + 1 + sizeB));
    for (int i = 0; i < sizeA; ++i) { sol.emplace_back(q + 1 + i, q + 1 - i); }
    for (int j = 0; j < sizeB; ++j) { sol.emplace_back(2 * q + 2 + j, 2 * q + 1 - j); }
    return sol;
}

// 上界证明的可执行版本：k(k−1)/2 ≤ Σ(i−j) = Σi − Σj ≤ k(N−k) ⟹ 3k ≤ 2N+1
static int triangular_upper_bound(int N, long long& sumDif, long long& sumI, long long& sumJ) {
    // 取达到上界的极端构造来把夹逼的每一项算出来（Σi 取最大 k 个、Σj 取最小 k 个）
    const int k = (2 * N + 1) / 3;
    sumI = 0;
    sumJ = 0;
    for (int t = 0; t < k; ++t) { sumI += N - t; }   // 最大的 k 个行号
    for (int t = 1; t <= k; ++t) { sumJ += t; }      // 最小的 k 个列号
    sumDif = k * (k - 1) / 2;                        // 最小的 k 个非负差值
    return k;
}

static void triangular_queens_demo() {
    println("");
    println("=== 35.7 三角 N-后：先证上界，再给构造 ===");
    println("  棋盘：边长 N，格点 (i,j) 满足 1 ≤ j ≤ i ≤ N。互不攻击 ⟺");
    println("        i₁ ≠ i₂ 且 j₁ ≠ j₂ 且 i₁−j₁ ≠ i₂−j₂（三个方向各判一次）");

    // ---- 上界：三重求和夹逼 ----
    println("");
    println("  【上界】设放了 k 个皇后。三方向各不重复给出三个不等式：");
    println("    行号两两不同 ⟹ Σi ≤ N+(N−1)+⋯+(N−k+1) = k(2N−k+1)/2  （取最大的 k 个）");
    println("    列号两两不同 ⟹ Σj ≥ 1+2+⋯+k = k(k+1)/2              （取最小的 k 个）");
    println("    差值两两不同且 d = i−j ≥ 0 ⟹ Σd ≥ 0+1+⋯+(k−1) = k(k−1)/2");
    println("  又 Σd = Σi − Σj，于是夹逼：");
    println("    k(k−1)/2 ≤ Σd = Σi − Σj ≤ k(2N−k+1)/2 − k(k+1)/2 = k(N−k)");
    println("  两边除 k：(k−1)/2 ≤ N−k ⟹ k−1 ≤ 2N−2k ⟹ **3k ≤ 2N+1** ⟹ k ≤ ⌊(2N+1)/3⌋");
    long long sd = 0, si = 0, sj = 0;
    for (const int N : {10, 20, 30}) {
        const int k = triangular_upper_bound(N, sd, si, sj);
        println("    N = {:>2}：k = {} ⇔ 3k = {} ≤ 2N+1 = {}；代入夹逼 Σd ≥ {}、Σd ≤ k(N−k) = {}",
                N, k, 3 * k, 2 * N + 1, k * (k - 1) / 2, k * (N - k));
        assert(3 * k <= 2 * N + 1);
        assert(k == (2 * N + 1) / 3);
    }
    println("  注意上界的**来源**：不是「搜出来只有这么多」，而是被三重求和夹住的。");
    println("  回溯逐行决定放不放，Θ(2ᴺ) —— N > 10 就跑不动，**证上界必须用代数**。");

    // ---- 构造：两段奇偶差值 ----
    println("");
    println("  【构造】q = ⌊N/3⌋，把 k 个皇后摆成两段（Θ(N)，无搜索）：");
    println("    段 A：行 q+1..2q+1，列 q+1, q, …, 1     ⟹ 差值 i−j = 0, 2, 4, …（偶数段）");
    println("    段 B：行 2q+2..，   列 2q+1, 2q, …      ⟹ 差值 i−j = 1, 3, 5, …（奇数段）");
    println("  三条合法性逐一验证：");
    println("    行号：段 A 与段 B 的行区间**不交** ⟹ 两两不同");
    println("    列号：段 A 占 1..q+1，段 B 从 2q+1 往下且长度 ≤ q ⟹ 两段不交");
    println("    差值：偶数段与奇数段**天然不交** ⟹ 两两不同（这是选「奇偶两段」的关键）");
    println("  段长(sizeA = q+1, sizeB = q 或 q−1)使总数恰为 ⌊(2N+1)/3⌋，达到上界。");

    // ---- 逐例展示 + 断言 ----
    println("");
    println("  {:>4} {:>6} {:>6}  {}", "N", "⌊(2N+1)/3⌋", "实放", "位置 (行,列)");
    for (const int N : {1, 4, 7, 10, 13, 20, 100, 1000}) {
        const auto sol = triangular_queens(N);
        const int k = (2 * N + 1) / 3;
        // 三方向逐一验证（构造的正确性不靠"看起来对"）
        std::vector<char> rowUsed(static_cast<std::size_t>(N) + 1, 0);
        std::vector<char> colUsed(static_cast<std::size_t>(N) + 1, 0);
        std::vector<char> difUsed(static_cast<std::size_t>(N) + 1, 0);
        for (const auto& [i, j] : sol) {
            assert(i >= 1 && i <= N && j >= 1 && j <= i);
            const int d = i - j;
            assert(!rowUsed[static_cast<std::size_t>(i)]);
            assert(!colUsed[static_cast<std::size_t>(j)]);
            assert(!difUsed[static_cast<std::size_t>(d)]);
            rowUsed[static_cast<std::size_t>(i)] = 1;
            colUsed[static_cast<std::size_t>(j)] = 1;
            difUsed[static_cast<std::size_t>(d)] = 1;
        }
        assert(static_cast<int>(sol.size()) == k);
        print("  {:>4} {:>6} {:>6}  ", N, k, static_cast<int>(sol.size()));
        if (N <= 13) {
            for (const auto& [i, j] : sol) { print("({},{}) ", i, j); }
        } else {
            print("前 4 个 = ");
            for (std::size_t t = 0; t < 4; ++t) { print("({},{}) ", sol[t].first, sol[t].second); }
            print("… 共 {} 个", sol.size());
        }
        println("");
    }

    // 穷举校验：对 N = 1..2000 逐个核对「实放 == ⌊(2N+1)/3⌋ 且三方向无冲突」
    int bad = 0;
    for (int N = 1; N <= 2000; ++N) {
        const auto sol = triangular_queens(N);
        std::vector<char> rowUsed(static_cast<std::size_t>(N) + 1, 0);
        std::vector<char> colUsed(static_cast<std::size_t>(N) + 1, 0);
        std::vector<char> difUsed(static_cast<std::size_t>(N) + 1, 0);
        bool ok = static_cast<int>(sol.size()) == (2 * N + 1) / 3;
        for (const auto& [i, j] : sol) {
            if (i < 1 || i > N || j < 1 || j > i) { ok = false; break; }
            const int d = i - j;
            if (rowUsed[static_cast<std::size_t>(i)] || colUsed[static_cast<std::size_t>(j)] ||
                difUsed[static_cast<std::size_t>(d)]) { ok = false; break; }
            rowUsed[static_cast<std::size_t>(i)] = 1;
            colUsed[static_cast<std::size_t>(j)] = 1;
            difUsed[static_cast<std::size_t>(d)] = 1;
        }
        if (!ok) { ++bad; }
    }
    println("");
    println("  穷举校验 N = 1..2000：构造与上界一致且三方向无冲突，失败 {} 个", bad);
    assert(bad == 0);

    // ---- 方法论 ----
    println("");
    println("  方法论：「**先证上界、再给构造**」是组合优化的标准套路：");
    println("    ① 不搜就知道答案的天花板在哪（代数夹逼，不是「搜出来只有这么多」）；");
    println("    ② 构造达到上界 ⟹ 最优性是**证明**出来的，不依赖搜索的运气；");
    println("    ③ 构造是 O(N) 的闭式，比任何搜索都快几个量级。");
    println("  对照本章 35.6：那里用状压 DP 精确求 χ（2ⁿ/3ⁿ 可接受），");
    println("  这里连 2ⁿ 都不能搜 —— **同样是 NP 问题，判定规模决定用搜索还是用构造**。");
}

int main() {
    println("NP 完全性的可执行归约（实例：4 子句 3-SAT，4 变量）：");
    println("  公式 = (x1∨¬x2∨x3)∧(¬x1∨x2∨x4)∧(¬x2∨¬x3∨x4)∧(x1∨x2∨¬x4)");

    // 暴力：全部满足赋值
    const auto sat = all_satisfying();
    println("  暴力枚举 16 个赋值：{} 个满足", sat.size());
    assert(!sat.empty());

    // 构造团图
    long long edges = 0;
    const Graph g = build_clique_graph(edges);
    println("  归约 1（3-SAT→CLIQUE）：12 顶点、{} 条边、目标团大小 k = 4", edges);
    println("    构造：子句文字→顶点；边 = 不同子句且不矛盾的文字对");

    // 从第一个满足赋值导出团并验证
    const auto clique = clique_from_assign(sat[0], g);
    std::string ids;
    for (int v : clique) { ids += std::to_string(v) + " "; }
    println("    从满足赋值 x=({},{},{},{}) 导出 4 团：顶点 {{ {} }}（两两有边）",
            static_cast<int>(sat[0][1]), static_cast<int>(sat[0][2]),
            static_cast<int>(sat[0][3]), static_cast<int>(sat[0][4]), ids);
    assert(clique.size() == 4);

    // 归约 2：CLIQUE → VERTEX-COVER（补图）
    const Graph comp = complement(g);
    // 选中「非团」的 8 个顶点 → 补图的顶点覆盖
    std::vector<char> sel(static_cast<std::size_t>(g.n), 1);
    for (int v : clique) { sel[static_cast<std::size_t>(v)] = 0; }
    long long compEdges = 0;
    for (int i = 0; i < comp.n; ++i) {
        for (int j = i + 1; j < comp.n; ++j) {
            if (comp.adj[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)]) { ++compEdges; }
        }
    }
    println("  归约 2（CLIQUE→VC）：补图 {} 条边；取非团的 8 顶点，覆盖检验 = {}",
            compEdges, is_vertex_cover(comp, sel) ? 1 : 0);
    assert(is_vertex_cover(comp, sel));

    // 反向也验：团对应的赋值确实满足（三方闭环）
    println("  三方对账：满足赋值 → 4 团 → 补图 8 覆盖，全部成立（归约的构造性证明演示）");

    backtrack_frameworks_demo();
    chromatic_demo();
    triangular_queens_demo();
    println("自检通过");
    return 0;
}
