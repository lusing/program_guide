# Ch33 二阶椭圆 V：特征值
#
# 对应书 §6.5：对称椭圆算子的特征值（Rayleigh-Ritz、min-max、
# 谱离散、Weyl 律）与非对称算子的主特征值（Krein-Rutman）。

using Printf
using LinearAlgebra

println("==== 33")

# ---- (a) Rayleigh-Ritz：λ₁ = min R[u]，第一模式饱和 ----
# R[u] = ∫|∇u|²/∫u²（(0,1) 零边值）。数值谱（差分）对照 π²
for N in [40, 80]
    h = 1 / (N + 1)
    lam1 = 2 * (1 - cos(pi * h)) / h^2
    @printf("(a) N=%d: discrete λ₁ = %.6f -> π²\n", N, lam1)
end
# Rayleigh 商对第二模式 > λ₁
R2 = (2pi)^2
@printf("    R[sin2πx] = %.4f = λ₂ > λ₁ = π² (orthogonal constraint raises the min)\n", R2)
@assert R2 > pi^2

# ---- (b) min-max 与特征值间距：λ_k = (kπ)²（显式谱）----
for k in [1, 2, 3]
    @printf("(b) λ_%d = %8.4f (=%d²π²)  gap λ_%d−λ_%d = %.4f\n",
            k, (k * pi)^2, k, k, k - 1, k > 1 ? (k * pi)^2 - ((k - 1) * pi)^2 : 0.0)
end
@assert (2pi)^2 - pi^2 ≈ 3pi^2

# ---- (c) 对称矩阵特征值的 Rayleigh-Ritz 数值：幂法/QR 对照 ----
# 离散 -Δ（三对角）：最小三个特征值 vs (kπ)²
N = 100
h = 1 / (N + 1)
T = SymTridiagonal(fill(2.0, N), fill(-1.0, N - 1)) / h^2
evs = eigvals(T)[1:3]
@printf("(c) discrete spectrum (N=100): %.4f %.4f %.4f vs π² 4π² 9π² = %.4f %.4f %.4f\n",
        evs[1], evs[2], evs[3], pi^2, 4pi^2, 9pi^2)
@assert abs(evs[1] - pi^2) < 0.05 && abs(evs[2] - 4pi^2) < 0.2 "前三个特征值逼近"

# ---- (d) 非对称算子的主特征值：对流-扩散 -u'' + b u' 的谱偏移 ----
# 变换 x ↦ e^{bx/2}v 对称化：特征值 = (kπ)² + b²/4（实谱，简单）
b = 1.5
for k in [1, 2]
    lam = (k * pi)^2 + b^2 / 4
    @printf("(d) nonsymmetric -u''+%.1fu': λ_%d = %.4f (= (kπ)² + b²/4)\n", b, k, lam)
end
# 数值：离散矩阵特征值实部对照
N = 200
h = 1 / (N + 1)
main = fill(2.0 / h^2, N)
sub = fill(-1.0 / h^2 - b / (2h), N - 1)   # 下次对角（对流项）
sup = fill(-1.0 / h^2 + b / (2h), N - 1)
A = Tridiagonal(sub, main, sup)
evs_ns = eigvals(A)
l1_real = minimum(real(evs_ns))
@printf("    numerical principal eigenvalue = %.4f vs theory %.4f\n",
        l1_real, pi^2 + b^2 / 4)
@assert abs(l1_real - (pi^2 + b^2 / 4)) < 0.1 "主特征值 = 对称化偏移 b²/4"

# ---- (e) Weyl 律一瞥：λ_k ~ (kπ)² 的计数规律 ----
# N(λ) = #{k : (kπ)² ≤ λ} = floor(√λ/π)：密度 dN/dλ ~ 1/(2π√λ)
lam = 100pi^2
N_lam = floor(Int, sqrt(lam) / pi)
@printf("(e) Weyl: N(λ=100π²) = %d exactly (1D 情形 Weyl 律精确)\n", N_lam)
@assert N_lam == 10 "√λ/π = 10"

println("END ====")

