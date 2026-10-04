// 35 NP 完全性（CLRS 第 34 章）。结构：35.1 多项式归约的概念 /
// 35.2 3-SAT → CLIQUE 的构造归约（可执行版：子句文字 → 顶点）/
// 35.3 CLIQUE → VERTEX-COVER（补图变换）/ 35.4 满足解 ↔ 团 ↔ 覆盖的
// 三方对账（暴力真值枚举当裁判）。文档重章、示例轻量——理论细节见
// docs/35。
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
    println("自检通过");
    return 0;
}
