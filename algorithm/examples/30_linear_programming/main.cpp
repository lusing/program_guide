// 30 线性规划（CLRS 第 29 章）。结构：30.1 标准形与松弛形 /
// 30.2 单纯形法（表旋转：进基/离基变量逐步追踪）/ 30.3 对偶验证 /
// 30.4 数值纪律（整数顶点例题——规避浮点对账风险，见计划注记）。
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
#include <cassert>
#include <cmath>
#include <cstdint>
#include <random>
#include <vector>

static std::uint32_t rand_below(std::mt19937& rng, std::uint32_t n) {
    return static_cast<std::uint32_t>(
        (static_cast<std::uint64_t>(rng()) * n) >> 32);
}

// ═══ 30.5 两个变量的线性规划：可行域顶点枚举 ═══
// 约束统一写成 a·x + b·y ≤ c；目标 max/min p·x+q·y。
struct HalfPlane { double a, b, c; };

struct PointXY { double x, y; bool valid = true; };

// 两条边界直线的交点；平行时 valid=false。
static PointXY line_intersect(const HalfPlane& l1, const HalfPlane& l2) {
    const double det = l1.a * l2.b - l2.a * l1.b;
    if (std::fabs(det) < 1e-12) { return {0, 0, false}; }
    const double x = (l1.c * l2.b - l2.c * l1.b) / det;
    const double y = (l1.a * l2.c - l2.a * l1.c) / det;
    return {x, y, true};
}

static bool satisfies(const HalfPlane& h, double x, double y) {
    return h.a * x + h.b * y <= h.c + 1e-9;
}

// 枚举所有约束对的交点，过滤可行点，取目标最优。m 条约束 O(m²)。
static PointXY lp2_solve(const std::vector<HalfPlane>& hs, double p, double q,
                         bool minimize) {
    PointXY best{0, 0, false};
    double bestv = minimize ? 1e18 : -1e18;
    for (std::size_t i = 0; i < hs.size(); ++i) {
        for (std::size_t j = i + 1; j < hs.size(); ++j) {
            const PointXY v = line_intersect(hs[i], hs[j]);
            if (!v.valid) { continue; }
            bool ok = true;
            for (const HalfPlane& h : hs) {
                if (!satisfies(h, v.x, v.y)) { ok = false; break; }
            }
            if (!ok) { continue; }
            const double val = p * v.x + q * v.y;
            if ((minimize ? val < bestv - 1e-12 : val > bestv + 1e-12)) {
                bestv = val; best = v;
            }
        }
    }
    return best;
}

// 简化版：约束全为 y ≥ a·x + b（直线集），目标 min y。
struct Line2D { double a, b; };

static double line_cross_x(const Line2D& l1, const Line2D& l2) {
    return (l2.b - l1.b) / (l1.a - l2.a);
}

// 上包络（max of lines）的最小 y：按斜率排序后用栈构造凸包络，再走断点。
// 包络是凸分段线性 ⟹ 最小值在断点（或水平段）；斜率不变号则无下界。
static double envelope_min(const std::vector<Line2D>& lines, double* xout) {
    std::vector<Line2D> ls = lines;
    std::sort(ls.begin(), ls.end(), [](const Line2D& u, const Line2D& v) {
        return u.a < v.a - 1e-12 ||
               (std::fabs(u.a - v.a) < 1e-12 && u.b > v.b);
    });
    std::vector<Line2D> hull;
    std::vector<double> xs;               // hull[k] 与 hull[k+1] 断点
    for (const Line2D& l : ls) {
        if (!hull.empty() && std::fabs(hull.back().a - l.a) < 1e-12) {
            continue;                     // 同斜率只留最高（已由排序保证）
        }
        while (hull.size() >= 2) {
            const double x_old = line_cross_x(hull[hull.size() - 2], hull.back());
            const double x_new = line_cross_x(hull.back(), l);
            if (x_new <= x_old) { hull.pop_back(); xs.pop_back(); }
            else { break; }
        }
        if (!hull.empty()) { xs.push_back(line_cross_x(hull.back(), l)); }
        hull.push_back(l);
    }
    // 首尾斜率不跨 0 ⟹ 无下界
    if (hull.front().a > 1e-12 || hull.back().a < -1e-12) {
        return -1e18;
    }
    // 水平段或断点处取最小
    double best = 1e18;
    for (std::size_t k = 0; k < hull.size(); ++k) {
        if (std::fabs(hull[k].a) < 1e-12) {
            best = std::min(best, hull[k].b);
        }
    }
    for (double x : xs) {
        double v = -1e18;
        for (const Line2D& l : hull) { v = std::max(v, l.a * x + l.b); }
        if (v < best) { best = v; if (xout) { *xout = x; } }
    }
    return best;
}

// O(n²) 独立口径：枚举所有直线对断点求值。
static double envelope_pairwise(const std::vector<Line2D>& lines) {
    double best = 1e18;
    for (std::size_t i = 0; i < lines.size(); ++i) {
        for (std::size_t j = i + 1; j < lines.size(); ++j) {
            if (std::fabs(lines[i].a - lines[j].a) < 1e-12) { continue; }
            const double x = line_cross_x(lines[i], lines[j]);
            double v = -1e18;
            for (const Line2D& l : lines) { v = std::max(v, l.a * x + l.b); }
            best = std::min(best, v);
        }
    }
    return best;
}

static void lp2_demo() {
    println("");
    println("=== 30.5 两个变量 LP：顶点枚举 O(m²) 与上包络法 ===");
    // 农夫养猪羊（连续 LP）
    const std::vector<HalfPlane> farmer{
        {6300, 10600, 200000},
        {-22000, -35000, -200000},
        {-1, 0, 0},                       // x ≥ 0 ⟺ −x ≤ 0
        {0, -1, 0}};                      // y ≥ 0 ⟺ −y ≤ 0
    const PointXY f = lp2_solve(farmer, 1, 1, true);
    println("  农夫问题（连续）：最优 x+y = {:.6f}，位于 ({:.6f}, {:.6f})",
            f.x + f.y, f.x, f.y);
    assert(std::fabs(f.x + f.y - 40.0 / 7.0) < 1e-6);

    // 整数最优：按 x 逐点用整数算术算可行 y 的下界
    int int_best = 1000000;
    for (int x = 0; x <= 200000 / 6300; ++x) {
        const int y_max = (200000 - 6300 * x) / 10600;
        int y_min = (200000 - 22000 * x + 34999) / 35000;
        if (y_min < 0) { y_min = 0; }
        if (y_min <= y_max) { int_best = std::min(int_best, x + y_min); }
    }
    println("  农夫问题（整数）：最少牲口 {} 头（即 6 只羊；连续最优 5.714 向上取整）",
            int_best);
    assert(int_best == 6);

    // 简化 LP：三条直线 y ≥ 0、y ≥ x−10、y ≥ −2x+20、y ≥ 4x−80
    const std::vector<Line2D> lines{
        {0, 0}, {1, -10}, {-2, 20}, {4, -80}};
    double xstar = 0;
    const double emin = envelope_min(lines, &xstar);
    const double epair = envelope_pairwise(lines);
    // 与通用顶点枚举对账：y ≥ ax+b ⟺ −a·x − y ≤ −b
    std::vector<HalfPlane> hs;
    for (const Line2D& l : lines) { hs.push_back({-l.a, -1, -l.b}); }
    const PointXY gv = lp2_solve(hs, 0, 1, true);
    println("  简化 LP（4 直线）：包络最小 y = {}（x={}），断点对举 {}，"
            "通用顶点枚举 {:.6f}", emin, xstar, epair, gv.y);
    assert(emin == 0 && std::fabs(epair) < 1e-9 && std::fabs(gv.y) < 1e-9);

    // 随机 300 例：包络法 vs O(n²) 断点对举 vs 通用顶点枚举
    std::mt19937 rng{5489};
    int bad = 0;
    for (int t = 0; t < 300; ++t) {
        const int m = 3 + static_cast<int>(rand_below(rng, 8));
        // 三口径必须同域：这里都在整个 ℝ 上比较，故不加 x≥0/y≥0。
        std::vector<HalfPlane> gh;
        std::vector<Line2D> gl;
        for (int k = 0; k < m; ++k) {
            const double a = -3.0 + 6.0 * std::ldexp(rand_below(rng, 1000000), -20);
            const double b = -20.0 + 40.0 * std::ldexp(rand_below(rng, 1000000), -20);
            gl.push_back({a, b});
            gh.push_back({-a, -1, -b});
        }
        const double e = envelope_min(gl, nullptr);
        if (e < -1e17) { continue; }       // 无下界例跳过
        if (std::fabs(e - envelope_pairwise(gl)) > 1e-7) { ++bad; continue; }
        const PointXY v = lp2_solve(gh, 0, 1, true);
        if (!v.valid || std::fabs(v.y - e) > 1e-7) { ++bad; }
    }
    println("  随机 300 例（3..10 直线）：三口径不一致 {} 例", bad);
    assert(bad == 0);

    // 大例：10 万条直线的上包络 O(n log n)——保证斜率有正有负
    std::vector<Line2D> big;
    big.reserve(100000);
    for (int k = 0; k < 100000; ++k) {
        const double a = -5.0 + 10.0 * std::ldexp(rand_below(rng, 1000000), -20);
        const double b = 100.0 * std::ldexp(rand_below(rng, 1000000), -20);
        big.push_back({a, b});
    }
    double xstar_big = 0;
    const double e_big = envelope_min(big, &xstar_big);
    // 独立验证：在 xstar_big 处逐条直线求值，包络值必须恰为 max，且为断点
    double vmax = -1e18;
    for (const Line2D& l : big) { vmax = std::max(vmax, l.a * xstar_big + l.b); }
    println("  大例（10 万直线）：最小 y = {:.6f}（x={:.4f}），该点逐线复核 = {:.6f}",
            e_big, xstar_big, vmax);
    assert(std::fabs(vmax - e_big) < 1e-7);
}

// 上面的抽象表写法容易绕晕——改用「明确变量值」的直接实现（数值纪律
// 下更透明）：枚举顶点（小例题可行）+ 表旋转双轨对账。
struct TableauSimplex {
    // 标准表：m 个约束行 [a1..an, b]；目标行 [c1..cn, 0]；基变量集合
    std::vector<std::vector<double>> t;
    std::vector<int> basis;
    long long pivots = 0;

    double solve() {
        const int n = static_cast<int>(t[0].size()) - 1;
        while (true) {
            // 进基：目标行最正系数（Bland 用最小下标，这里用最正——小例无循环）
            // 规范表：目标行存 z − Σcx = 0 的系数，最负者进基
            int enter = -1;
            double best = -1e-9;
            for (int j = 0; j < n; ++j) {
                if (t.back()[static_cast<std::size_t>(j)] < best) {
                    best = t.back()[static_cast<std::size_t>(j)];
                    enter = j;
                }
            }
            if (enter == -1) { break; }
            // 离基：最小比值（b_i / a_ij，a_ij > 0）
            int leave = -1;
            double ratio = 1e18;
            for (int i = 0; i + 1 < static_cast<int>(t.size()); ++i) {
                const double a = t[static_cast<std::size_t>(i)][static_cast<std::size_t>(enter)];
                if (a > 1e-9) {
                    const double r = t[static_cast<std::size_t>(i)].back() / a;
                    if (r < ratio - 1e-12) { ratio = r; leave = i; }
                }
            }
            if (leave == -1) { return 1e18; }
            pivot(enter, leave);
        }
        return t.back().back();
    }

    void pivot(int enter, int leave) {
        ++pivots;
        auto& row = t[static_cast<std::size_t>(leave)];
        const double p = row[static_cast<std::size_t>(enter)];
        for (double& v : row) { v /= p; }
        row[static_cast<std::size_t>(enter)] = 1.0;
        for (std::size_t i = 0; i < t.size(); ++i) {
            if (i == static_cast<std::size_t>(leave)) { continue; }
            auto& r = t[i];
            const double f = r[static_cast<std::size_t>(enter)];
            if (std::fabs(f) < 1e-15) { continue; }
            for (std::size_t j = 0; j < r.size(); ++j) {
                r[j] -= f * row[j];
            }
            r[static_cast<std::size_t>(enter)] = 0.0;
        }
        basis[static_cast<std::size_t>(leave)] = enter;
        print("  pivot #{}：x{} 进基、行 {} 离基，z = {:.6f}\n",
              pivots, enter + 1, leave + 1, t.back().back());
    }
};

int main() {
    println("单纯形法（例题：max 3x+2y, s.t. x+y≤4, x+3y≤6, x≤3, x,y≥0）：");
    // 表：3 约束 + 目标行；列 [x, y, s1, s2, s3, b]
    TableauSimplex ts;
    ts.t = {
        {1, 1, 1, 0, 0, 4},
        {1, 3, 0, 1, 0, 6},
        {1, 0, 0, 0, 1, 3},
        {-3, -2, 0, 0, 0, 0}};   // 目标行（max → 取负做规范化，z 在右下）
    ts.basis = {2, 3, 4};        // 初始基 = 松弛变量
    println("  迭代追踪（表旋转）：");
    const double z = ts.solve();
    println("  最优目标值 z = {:.6f}（手算顶点枚举答案 11）", z);
    assert(std::fabs(z - 11.0) < 1e-9);

    // 读出原变量值：基变量对应列的单位向量位置
    double xVal = 0, yVal = 0;
    for (std::size_t i = 0; i < ts.basis.size(); ++i) {
        if (ts.basis[i] == 0) { xVal = ts.t[i].back(); }
        if (ts.basis[i] == 1) { yVal = ts.t[i].back(); }
    }
    println("  最优解 x = {:.6f}, y = {:.6f}（顶点 (3,1)）", xVal, yVal);
    assert(std::fabs(xVal - 3) < 1e-9 && std::fabs(yVal - 1) < 1e-9);

    // 顶点枚举对账（小例题的暴力真值）
    double bestBrute = -1e18;
    for (int xi = 0; xi <= 4; ++xi) {
        for (int yi = 0; yi <= 4; ++yi) {
            if (xi + yi <= 4 && xi + 3 * yi <= 6 && xi <= 3) {
                bestBrute = std::max(bestBrute, 3.0 * xi + 2.0 * yi);
            }
        }
    }
    println("  顶点枚举对账：暴力最优 = {:.6f}（= 单纯形）", bestBrute);
    assert(std::fabs(bestBrute - 11.0) < 1e-9);

    // 对偶：min 4u1 + 6u2 + 3u3 s.t. u1+u2+u3 ≥ 3, u1+3u2 ≥ 2, u≥0
    // 强对偶定理：对偶最优值 = 11。目标行的松弛列给出对偶变量 u*。
    const double u1 = ts.t.back()[2], u2 = ts.t.back()[3], u3 = ts.t.back()[4];
    println("  对偶变量（影子价格 = 最优目标行的松弛列）：u1={:.6f}, u2={:.6f}, u3={:.6f}", u1, u2, u3);
    println("  对偶目标 4u1+6u2+3u3 = {:.6f}（强对偶 = 原始最优 11）",
            4 * u1 + 6 * u2 + 3 * u3);
    assert(std::fabs(4 * u1 + 6 * u2 + 3 * u3 - 11.0) < 1e-9);
    lp2_demo();
    println("自检通过");
    return 0;
}
