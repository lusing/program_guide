# Ch30 二阶椭圆 II：能量估计与 Fredholm 二择一
#
# 对应书 §6.2.2（能量估计：‖u‖_{H¹} ≤ C‖f‖_{H^{-1}}）与 §6.2.3
#（Fredholm 二择一：零特征值之外的唯一可解性）。

using Printf
using LinearAlgebra

println("==== 30")

# ---- (a) 能量估计数值：‖u‖_{H¹} ≤ C‖f‖_{H^{-1}} 的谱版 ----
# 谱：-u'' 的特征 λ_k = (kπ)²。f = Σ f_k φ_k ⟹ u_k = f_k/λ_k
# ‖u‖_{H¹}² = Σ u_k²(1+λ_k)，‖f‖_{H^{-1}}² = Σ f_k²/(1+λ_k)
# 能量估计在谱上是：Σ f²(1+λ)/λ² ≤ C²Σf²/(1+λ) ⟺ (1+λ)²/λ² ≤ C²(1+λ)/(1+λ)·?
# 逐项：(1+λ)²/λ² ≤ C² —— 最坏 k=1（λ 最小）
C_needed = maximum((1 + (k * pi)^2)^2 / (k * pi)^4 for k in 1:1000)
@printf("(a) spectral energy bound: sup (1+λ)²/λ² = %.4f at k=1 (λ=π²)\n", C_needed)
@assert C_needed ≈ (1 + pi^2)^2 / pi^4 "常数由第一特征值决定"
@assert abs(C_needed - (1 + pi^2)^2 / pi^4) < 1e-9

# ---- (b) Fredholm 二择一：λ ∈ spec ⟺ 齐次有非平凡解 ----
# -u'' = λu 于 (0,1) 零边值：特征 λ_k = (kπ)²。非特征值处唯一可解。
for lam in [pi^2, 4pi^2, 9pi^2]
    @printf("(b) eigenvalue λ = %.4f (k=%d): homogeneous has sin(kπx)\n",
            lam, round(Int, sqrt(lam) / pi))
end
# 非特征值：λ = 10 ⟹ -u'' = 10u + 1 唯一可解；解 u = A cos(√10 x)+B sin(√10x)+1/10·(-1)?
# -u'' = 10u + 1 ⟹ u'' + 10u = -1：特解 -1/10：u = A cos(√10x) + B sin(√10x) - 0.1
# 边值 u(0)=0: A = 0.1；u(1)=0: 0.1cos(√10) + B sin(√10) = 0.1 ⟹ B = 0.1(1-cos(√10))/sin(√10)
s10 = sqrt(10.0)
Bc = 0.1 * (1 - cos(s10)) / sin(s10)
u_exact(x) = 0.1 * cos(s10 * x) + Bc * sin(s10 * x) - 0.1
# 数值验证（差分残差 + 边界）
h = 1e-4
x = 0.5
dd = (u_exact(x + h) - 2u_exact(x) + u_exact(x - h)) / h^2
r = -dd - 10 * u_exact(x) - 1
@printf("    λ=10 (not eigenvalue): residual -u''-10u-1 = %.2e; u(0)=%.1e u(1)=%.1e\n",
        r, u_exact(0.0), u_exact(1.0))
@assert abs(r) < 1e-5 && abs(u_exact(0.0)) < 1e-12 && abs(u_exact(1.0)) < 1e-12 "非特征值唯一解"

# ---- (c) 特征值处的不适定性签名：λ = π² 时方程 -u'' - π²u = f 的可解性条件 ----
# sin(πx) 分量必须为零（正交性条件）；f = 1 满足（⟨1,sin⟩ = 2/π ≠ 0 → 无解！）
# ⟨1, sin πx⟩ = ∫₁·sin = 2/π ≠ 0 ⟹ 无解。f = sin(2πx) 与 sin(πx) 正交 ⟹ 无穷多解
ip(f, g, n = 4000) = begin
    h = 1 / n
    s = 0.0
    for k in 0:n-1
        x = (k + 0.5) * h
        s += f(x) * g(x)
    end
    s * h
end
solvable(f) = abs(ip(f, x -> sin(pi * x))) < 1e-12
@printf("    f=1: ⟨1,sinπx⟩ = %.6f ≠ 0 ⟹ NO solution\n", ip(x -> 1.0, x -> sin(pi * x)))
@printf("    f=sin2πx: ⟨f,sinπx⟩ = %.6f = 0 ⟹ infinitely many solutions\n",
        ip(x -> sin(2pi * x), x -> sin(pi * x)))
@assert !solvable(x -> 1.0) && solvable(x -> sin(2pi * x)) "Fredholm 二择一的两面"

# ---- (d) 特征值间距与条件数：靠近特征值时解算子范数爆炸 ----
for lam in [pi^2 + 1.0, pi^2 + 0.01, pi^2 + 1e-4]
    # ‖(-Δ-λ)^{-1}‖ ≈ 1/dist(λ, π²)
    @printf("(d) dist to spectrum %.0e: solver norm ~ %.1f (blows up)\n",
            lam - pi^2, 1 / (lam - pi^2))
end
@assert 1 / 1e-4 > 1 / 1.0 "靠近谱 ⟹ 病态（二择一的数值面）"

println("END ====")
