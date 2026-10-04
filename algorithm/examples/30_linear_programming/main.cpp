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
#include <vector>

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
    println("自检通过");
    return 0;
}
