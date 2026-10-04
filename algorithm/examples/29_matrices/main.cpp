// 29 矩阵运算（CLRS 第 28 章）。结构：29.1 LUP 分解（部分主元）与
// 前代/回代求解 / 29.2 行列式与逆矩阵 / 29.3 数值纪律：定点打印 +
// 容差断言（浮点章的输出纪律，见 docs/01）。
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
#include <cmath>
#include <cstdint>
#include <vector>

using Mat = std::vector<std::vector<double>>;
using Vec = std::vector<double>;

// ═══ 29.1 LUP 分解 ═══
// P·A = L·U（L 单位下三角，U 上三角，P 置换）。部分主元选列最大，
// 数值稳定性来自「除以大头」。
struct Lup { Mat L, U; std::vector<int> perm; int sign; };

static Lup lup_decompose(const Mat& a) {
    const int n = static_cast<int>(a.size());
    Mat u = a;
    Mat l(static_cast<std::size_t>(n), std::vector<double>(static_cast<std::size_t>(n), 0.0));
    std::vector<int> p(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) { p[static_cast<std::size_t>(i)] = i; }
    int sign = 1;
    for (int k = 0; k < n; ++k) {
        // 部分主元：第 k 列（k 行及以下）绝对值最大者
        int pivot = k;
        double best = std::fabs(u[static_cast<std::size_t>(k)][static_cast<std::size_t>(k)]);
        for (int i = k + 1; i < n; ++i) {
            if (std::fabs(u[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)]) > best) {
                best = std::fabs(u[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)]);
                pivot = i;
            }
        }
        if (pivot != k) {
            std::swap(u[static_cast<std::size_t>(pivot)], u[static_cast<std::size_t>(k)]);
            // 关键细节：已算出的乘数（L 的前 k 列）必须跟着行一起换——
            // 乘数属于「行」而不是「位置」
            for (int j = 0; j < k; ++j) {
                std::swap(l[static_cast<std::size_t>(pivot)][static_cast<std::size_t>(j)],
                          l[static_cast<std::size_t>(k)][static_cast<std::size_t>(j)]);
            }
            std::swap(p[static_cast<std::size_t>(pivot)], p[static_cast<std::size_t>(k)]);
            sign = -sign;
        }
        for (int i = k + 1; i < n; ++i) {
            const double m = u[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)] /
                             u[static_cast<std::size_t>(k)][static_cast<std::size_t>(k)];
            l[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)] = m;
            u[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)] = 0.0;
            for (int j = k + 1; j < n; ++j) {
                u[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] -=
                    m * u[static_cast<std::size_t>(k)][static_cast<std::size_t>(j)];
            }
        }
    }
    for (int i = 0; i < n; ++i) { l[static_cast<std::size_t>(i)][static_cast<std::size_t>(i)] = 1.0; }
    return {l, u, p, sign};
}

// 前代解 Ly = Pb，回代解 Ux = y
static Vec lup_solve(const Lup& d, const Vec& b) {
    const int n = static_cast<int>(d.L.size());
    Vec y(static_cast<std::size_t>(n));
    for (int i = 0; i < n; ++i) {
        double s = b[static_cast<std::size_t>(d.perm[static_cast<std::size_t>(i)])];
        for (int j = 0; j < i; ++j) {
            s -= d.L[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] * y[static_cast<std::size_t>(j)];
        }
        y[static_cast<std::size_t>(i)] = s;
    }
    Vec x(static_cast<std::size_t>(n));
    for (int i = n - 1; i >= 0; --i) {
        double s = y[static_cast<std::size_t>(i)];
        for (int j = i + 1; j < n; ++j) {
            s -= d.U[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] * x[static_cast<std::size_t>(j)];
        }
        x[static_cast<std::size_t>(i)] = s / d.U[static_cast<std::size_t>(i)][static_cast<std::size_t>(i)];
    }
    return x;
}

static Mat mat_mul(const Mat& a, const Mat& b) {
    const int n = static_cast<int>(a.size());
    Mat r(static_cast<std::size_t>(n), std::vector<double>(static_cast<std::size_t>(n), 0.0));
    for (int i = 0; i < n; ++i) {
        for (int k = 0; k < n; ++k) {
            for (int j = 0; j < n; ++j) {
                r[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] +=
                    a[static_cast<std::size_t>(i)][static_cast<std::size_t>(k)] *
                    b[static_cast<std::size_t>(k)][static_cast<std::size_t>(j)];
            }
        }
    }
    return r;
}

int main() {
    // 经典 3×3 例：A·[1,2,3]ᵀ = [1,1,6]ᵀ
    const Mat a{{2, 1, -1}, {-3, -1, 2}, {-2, 1, 2}};
    const Vec b{1, 1, 6};
    const Lup d = lup_decompose(a);
    println("LUP 分解（部分主元）：P·A = L·U");
    println("  置换 perm = [{},{},{}]（行 {} 换到首位），行列式符号 = {}",
            d.perm[0], d.perm[1], d.perm[2], d.perm[0], d.sign);
    // P·A 与 L·U 的重积对账
    Mat pa(static_cast<std::size_t>(3), std::vector<double>(3, 0.0));
    for (int i = 0; i < 3; ++i) {
        pa[static_cast<std::size_t>(i)] = a[static_cast<std::size_t>(d.perm[static_cast<std::size_t>(i)])];
    }
    const Mat lu = mat_mul(d.L, d.U);
    bool recon = true;
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            if (std::fabs(pa[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] -
                          lu[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)]) > 1e-9) { recon = false; }
        }
    }
    println("  L·U 与 P·A 重积一致（容差 1e-9）= {}", recon ? 1 : 0);
    assert(recon);

    // 求解 Ax = b → [1, 2, 3]
    const Vec x = lup_solve(d, b);
    println("  解 Ax=b：x = [{:.6f}, {:.6f}, {:.6f}]（真值 [1,2,3]，|误差|<1e-9 = {}）",
            x[0], x[1], x[2],
            std::fabs(x[0] - 1) < 1e-9 && std::fabs(x[1] - 2) < 1e-9 &&
            std::fabs(x[2] - 3) < 1e-9 ? 1 : 0);
    assert(std::fabs(x[0] - 1) < 1e-9 && std::fabs(x[1] - 2) < 1e-9 && std::fabs(x[2] - 3) < 1e-9);

    // 行列式：det(A) = sign · Π U[i][i]（本例真值 −1）
    double detU = 1.0;
    for (int i = 0; i < 3; ++i) { detU *= d.U[static_cast<std::size_t>(i)][static_cast<std::size_t>(i)]; }
    const double det = static_cast<double>(d.sign) * detU;
    println("  det(A) = sign·∏U[i][i] = {:.6f}（真值 −1）", det);
    assert(std::fabs(det + 1.0) < 1e-9);

    // 逆矩阵：对单位阵的每一列求解
    Mat inv(3, std::vector<double>(3, 0.0));
    for (int c = 0; c < 3; ++c) {
        Vec e(3, 0.0);
        e[static_cast<std::size_t>(c)] = 1.0;
        const Vec col = lup_solve(d, e);
        for (int r = 0; r < 3; ++r) { inv[static_cast<std::size_t>(r)][static_cast<std::size_t>(c)] = col[static_cast<std::size_t>(r)]; }
    }
    const Mat prod = mat_mul(a, inv);
    bool eye = true;
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 3; ++j) {
            const double want = (i == j) ? 1.0 : 0.0;
            if (std::fabs(prod[static_cast<std::size_t>(i)][static_cast<std::size_t>(j)] - want) > 1e-9) { eye = false; }
        }
    }
    println("  逆矩阵 A⁻¹ 求得（A·A⁻¹ = I 容差验证 = {}），A⁻¹[0][0] = {:.6f}", eye ? 1 : 0, inv[0][0]);
    assert(eye);
    println("自检通过");
    return 0;
}
