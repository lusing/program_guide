# Ch05 Laplace 方程 III：能量方法与 Dirichlet 原理
#
# 对应书 §2.2.5：唯一性的能量证明（∫|∇w|²=0 ⟹ w=0）、Dirichlet
# 原理（Poisson 问题的解极小化能量 E[w]=∫(½|∇w|²−wf)）、预告
# 变分直接法（ch8）。

using Printf

println("==== 05")

# ---- (a) 一阶变分消失 + 凸性：u = sin(πx)sin(πy) 的能量极小 ----
# −Δu = 2π² sinπx sinπy，零边值。能量 E[v] = ∫(½|∇v|² − v f) dA
E(v, f) = begin
    n = 200; h = 1 / n; s = 0.0
    for i in 1:n, j in 1:n
        x, y = (i - 0.5) * h, (j - 0.5) * h
        gx = (v(x + h / 2, y) - v(x - h / 2, y)) / h
        gy = (v(x, y + h / 2) - v(x, y - h / 2)) / h
        s += (0.5 * (gx^2 + gy^2) - v(x, y) * f(x, y))
    end
    s * h^2
end
f1(x, y) = 2pi^2 * sin(pi * x) * sin(pi * y)
u1(x, y) = sin(pi * x) * sin(pi * y)
Eu = E(u1, f1)
# 一阶变分：扰动 u + εv0 的能量导数在 ε=0 为零（v0 满足零边值）
v0(x, y) = sin(2pi * x) * sin(pi * y)
eps = 1e-5
Eplus = E((x, y) -> u1(x, y) + eps * v0(x, y), f1)
Eminus = E((x, y) -> u1(x, y) - eps * v0(x, y), f1)
dEdEps = (Eplus - Eminus) / (2eps)
@printf("(a) first variation dE/deps at 0 = %.3e (should be 0)\n", dEdEps)
@assert abs(dEdEps) < 1e-6 "一阶变分消失（弱解条件）"
# 凸性：任何非零扰动抬高能量
for e in [0.05, -0.1, 0.3]
    Et = E((x, y) -> u1(x, y) + e * v0(x, y), f1)
    @printf("    eps=%+.2f: E = %.9f  (E[u] = %.9f, diff %.2e > 0)\n",
            e, Et, Eu, Et - Eu)
    @assert Et > Eu - 1e-10 "Dirichlet 原理：解是严格能量极小"
end
# 理论极小值：E[u] = ½∫|∇u|² − ∫u·f = π²/4 − π²/2 = −π²/4
@printf("    E[u] = %.9f  theory -pi^2/4 = %.9f\n", Eu, -pi^2 / 4)
@assert abs(Eu + pi^2 / 4) < 5e-3 "能量极小值闭式对账（中点求积 O(h²)）"

# ---- (b) Rayleigh–Ritz：方域 f=1、零边值的正弦基展开 ----
# u = Σ_{m,n odd} c_{mn} sin(mπx)sin(nπy)。载荷 f_{mn} = 4/(π²mn)，
# 但 ∫φ² = 1/4 ⟹ 极小系数 c_{mn} = 4f_{mn}/λ_{mn}（坑账：忘掉 1/4
# 会把系数少乘 4、能量闭式错一套——被数值能量当场对出 4 倍差）
function u_rr2(x, y, M)
    s = 0.0
    for m in 1:2:M, n in 1:2:M
        s += (16 / (pi^2 * m * n)) / (pi^2 * (m^2 + n^2)) * sin(m * pi * x) * sin(n * pi * y)
    end
    return s
end
# 能量极小值闭式：E_min = −2 Σ f²/λ（odd m,n ≤ 5 的 9 项）
Emin5 = -2 * sum((4 / (pi^2 * m * n))^2 / (pi^2 * (m^2 + n^2)) for m in 1:2:5, n in 1:2:5)
Enum = E((x, y) -> u_rr2(x, y, 5), (x, y) -> 1.0)
@printf("(b) RR energy (numerical) = %.9f  closed (9 modes) = %.9f\n", Enum, Emin5)
@assert abs(Enum - Emin5) < 5e-3 "Rayleigh–Ritz 能量与系数闭式对账"
# 解本身核对：中心点值（torsion 函数经典值 ≈ 0.073676…）
u_c5 = u_rr2(0.5, 0.5, 5)
u_c49 = u_rr2(0.5, 0.5, 49)
@printf("    u(0.5,0.5): 9-mode = %.9f  625-mode = %.9f\n", u_c5, u_c49)
@assert abs(u_c49 - 0.073676) < 1e-3 "torsion 中心值经典常数"
@assert abs(u_c5 - u_c49) < 1e-2 "9 项已收敛"

# ---- (c) Poincaré（能量控制）：‖v‖ ≤ ‖∇v‖/√λ1，λ1 = 2π² 饱和 ----
# 取 v = 混合模式，逐项验证 ‖v‖² = Σ c²/4 ≤ (1/λ1)Σλc²/4 = ‖∇v‖²/λ1
for (a1, a2) in [(1.0, 0.0), (0.6, 0.8), (1.3, -0.7)]
    nv2 = (a1^2 + a2^2) / 4          # ‖v‖²（基函数正交，各 1/4）
    gv2 = ((2pi^2) * a1^2 + (5pi^2) * a2^2) / 4   # ‖∇v‖²（λ=2π²、5π²）
    @printf("(c) modes (%.1f,%.1f): ||v||^2 = %.6f  ||gv||^2/lam1 = %.6f\n",
            a1, a2, nv2, gv2 / (2pi^2))
    @assert nv2 ≤ gv2 / (2pi^2) + 1e-15 "Poincaré：能量控制 L2"
end
@assert abs(1.0 / 4 - ((2pi^2) * 1.0) / 4 / (2pi^2)) < 1e-15 "第一模式使 Poincaré 饱和"

println("END ====")
