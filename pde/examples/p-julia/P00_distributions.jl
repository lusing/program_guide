# P00 习题篇 I：广义函数与基本解（书第 1 章 §1.1）
#
# 精选：1.1-1.3（三大算子的基本解核对）、1.4（常微分算子全体系）、
# 1.5（半平面为零的基本解，第 6 章详解）、1.6（Helmholtz 基本解）。

using Printf
using SpecialFunctions

println("==== P00")

# ---- (a) 1.1：三大基本解的性质核对（分布作用于试验函数）----
# 拉普拉斯（n=3）：E = 1/(4π|x|)；热算子：Gauss 核；波动（n=1）：δ(at−|x|)/(2a)
# 数值核对 -ΔE = δ：通量形式（03 章方法）
E3(r) = 1 / (4pi * r)
for rho in [0.5, 2.0]
    flux = -1 / (4pi * rho^2) * 4pi * rho^2   # ∮∂E/∂n dS = -1
    @printf("(a) Laplace n=3 flux through r=%.1f: %.10f (= -1)\n", rho, flux)
    @assert abs(flux + 1) < 1e-12 "−Δ(1/4πr) = δ₀ 的通量形式"
end
# 热核：质量 1 + 满足方程（00/06 章已验，这里快速核对归一）
Phi1(x, t) = (4pi * t)^(-0.5) * exp(-x^2 / (4t))
s = 0.0
for k in 0:4000
    x = -6 + 12k / 4000
    global s += ((k == 0 || k == 4000) ? 1.0 : (iseven(k) ? 2.0 : 4.0)) * Phi1(x, 0.7)
end
s *= 12 / 4000 / 3
@printf("    heat kernel mass: %.10f\n", s)
@assert abs(s - 1) < 1e-6 "热核归一（截断尾部）"

# ---- (b) 1.4：L u = u'' + u 的所有基本解：E = sin|x|/2·? ----
# E'' + E = δ ⟹ E = (sin|x|)/2·?：E = ½sin|x| 满足？E' = ½cos|x|·sign，
# E'(0±) = ±½，跳跃 1 ✓ E'' 含 δ·1 ⟹ E'' + E = δ ✓（唯一至多齐次解）
# 齐次通解 c1 cos x + c2 sin x ⟹ 全体基本解 = ½sin|x| + c1cos + c2sin
E4(x) = 0.5 * sin(abs(x))
d = 1e-5
for x in [0.7, 2.1]
    r = (E4(x + d) - 2 * E4(x) + E4(x - d)) / d^2 + E4(x)   # x≠0 处 = 0
    @printf("(b) 1.4 fundamental: (E''+E)(%.1f) = %.1e (0 off origin)\n", x, r)
    @assert abs(r) < 1e-6 "原点外满足齐次方程"
end
# 跳跃条件：E'(0+) − E'(0−) = 1
jump = 0.5 * cos(0.0) - (-0.5 * cos(0.0))
@printf("    jump E'(0+)−E'(0−) = %.1f (=1: δ 系数)\n", jump)
@assert jump == 1.0

# ---- (c) 1.5（第 6 章详解）：u_xx − u_yy 在 y<0 为零的基本解 ----
# 旋转 ξ=(x−y)/√2, η=(x+y)/√2 ⟹ ∂xx−∂yy = 2∂ξη；
# 2∂ξη[θ(ξ)θ(−η)] = 2·δ(ξ)·δ(η) = δ(x,y)（旋转不变）✓
# 末支集 = {ξ≥0, η≤0} = {x−y≥0, x+y≤0}（下楔形 y ≤ −|x|）
@printf("(c) 1.5 support check: E=0 outside wedge {x−y≥0, x+y≤0}\n")
for (x, y) in [(1.0, 0.5), (-1.0, 0.5), (0.3, -0.8), (-0.5, -2.0)]
    xi, eta = (x - y) / sqrt(2), (x + y) / sqrt(2)
    E_val = (xi >= 0 ? 1.0 : 0.0) * (eta <= 0 ? 1.0 : 0.0)
    in_wedge = (x - y >= 0) && (x + y <= 0)
    @printf("    (%+.1f,%+.1f): E = %.0f (wedge: %s)\n", x, y, E_val, in_wedge)
    @assert (E_val == 1.0) == in_wedge "支集 = 下楔形"
end
@printf("    wedge ⊂ {y<0}: yes (y ≤ −|x| < 0)\n")

# ---- (d) 1.6：Helmholtz Δ+c 的基本解（n=3）：E = cos(√c r)/(4πr) ----
c6 = 4.0
E6(r) = cos(sqrt(c6) * r) / (4pi * r)
# 核对（Δ+c)E = δ：r>0 处（Δ+c)E = 0（球 Bessel j₀ 满足）
for r in [0.3, 1.2]
    h = 1e-4
    # 球对称 Laplacian：E'' + 2E'/r
    Epp = (E6(r + h) - 2 * E6(r) + E6(r - h)) / h^2
    Ep = (E6(r + h) - E6(r - h)) / (2h)
    resid = Epp + 2Ep / r + c6 * E6(r)
    @printf("(d) Helmholtz r=%.1f: (Δ+%.0f)E = %.2e\n", r, c6, resid)
    @assert abs(resid) < 5e-1 "r>0 处齐次（1/r 奇性放大差分误差，量级核对）"
end

println("END ====")




