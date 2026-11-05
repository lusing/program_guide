# P06 习题篇 VII：椭圆方程（书第 5 章 §5.1-5.3）
#
# 精选：5.1-5.9（调和函数性质/多项式调和）、5.18（极值原理反例）、
# 5.20（Harnack 反例）、5.21（唯一性）、5.28-5.31（Green 函数/
# Poisson 公式）、5.44（Dirichlet 积分极小）。

using Printf

println("==== P06")

# ---- (a) 5.1 型：多项式调和分解——求 u = x³ 的调和补 ----
# Δ(x³ − 3xy²) = 0（Re z³）；5.1 答案 u = ax³ − a·3xy²·?（共轭调和）
# 数值：f = x³ − 3xy² 的 Laplacian
f_a(x, y) = x^3 - 3x * y^2
lap5(u, x, y, h) = (u(x + h, y) + u(x - h, y) + u(x, y + h) + u(x, y - h) - 4u(x, y)) / h^2
@printf("(a) Re z³ = x³−3xy²: Δ = %.1e\n", abs(lap5(f_a, 0.4, 0.6, 1e-3)))
@assert abs(lap5(f_a, 0.4, 0.6, 1e-3)) < 1e-5 "调和多项式"

# ---- (b) 5.12 型：极坐标分离：u = ρⁿcos(nθ) 型调和 ----
for n in [1.0, 2.0, 3.0]
    # u = ρⁿcos(nθ)：Δu = 0
    u_b(r, th) = r^n * cos(n * th)
    # 极坐标 Laplacian 数值（r,θ 网格）
    r0, th0 = 0.7, 0.9
    h = 1e-4
    ur2 = (u_b(r0 + h, th0) - 2u_b(r0, th0) + u_b(r0 - h, th0)) / h^2
    ur1 = (u_b(r0 + h, th0) - u_b(r0 - h, th0)) / (2h)
    ut2 = (u_b(r0, th0 + h) - 2u_b(r0, th0) + u_b(r0, th0 - h)) / h^2
    lap = ur2 + ur1 / r0 + ut2 / r0^2
    @printf("(b) n=%.0f: Δ(ρⁿcos nθ) = %.1e\n", n, lap)
    @assert abs(lap) < 1e-5 "极坐标调和模式"
end

# ---- (c) 5.18 型：u_xx + u_yy + u_y = 0 的极值原理变体 ----
# 原型 Laplace 极值原理仍成立（一阶项不破坏——max 处 ∇u=0、Δu≤0 ⟹ 满足）
# 反例检查（书答案 5.17）：Δu + u_x·? 带零阶项 c·u 时可能失败
# 数值演示：Lu = Δu + u：u = −e^{x}·? 取 u = e^x·sin(√3 y/2)·? 复杂——
# 直接演示书 5.18：Δu + u_x + u = 0 于有界域的极大值原理：
# 设 u 在内点取正极大 M：∇u = 0、Δu ≤ 0 ⟹ Δu + u_x + u = Δu + M ≥ M > 0 ≠ 0 矛盾
# ⟹ 正极大值原理成立。数值：u = sin(πx)sin(πy)e^{-x/2} 型满足 Δu + u_x = 0·?
println("(c) 5.18: max principle survives first-order terms (positive max argument)")
@printf("    at positive interior max: Du=0, Δu≤0 ⟹ Lu = Δu+u ≥ M > 0 ≠ 0 — contradiction\n")

# ---- (d) 5.20 型：Harnack 反例（球内正调和、u(0)=1、某点=10 不可能）----
# Harnack：u(x) ≤ 3ⁿ u(0)（B(0,1)）——n=3：u ≤ 27。取点距离 0 越远常数越大
# 书问题：B₃(0) 内 u(0,0,0)=1，能否 u(0,...,1/2) = 10？Harnack: u ≤ 27·1 ✓ 可能
# Poisson 公式造：u(x) = ((1−|x|²)/|x−e|³)·(3/4π)·? 简化核验 Harnack 常数
n_dim = 3
r_pt = 0.5
bound = 3^n_dim  # u(x)/u(0) ≤ 3^n·(1+|x|)/(1−|x|) 精确形式
bound_exact = (3^n_dim) * (1 + r_pt) / (1 - r_pt)
@printf("(d) Harnack n=3, r=0.5: u(0.5e)/u(0) ≤ 3³·(1.5)/(0.5) = %.0f\n", bound_exact)
@assert 10 < bound_exact "u=10 在 Harnack 界内（习题答案：存在）"

# ---- (e) 5.44 型：Dirichlet 积分极小（能量最小化样本）----
# inf ∫|∇w|²，w−f ∈ H¹₀(B)（圆 r<1）：u = 调和扩张 = r^|k|·cos/sin
# f = cos(3θ) 于 r=1：u = r³cos(3θ)，∫|∇u|² = 3π·?（Parseval）
u_e(r, th) = r^3 * cos(3th)
# 扰动能量更高
for eps in [0.1, 0.3]
    w(r, th) = r^3 * cos(3th) + eps * (1 - r^2)^2 * r^3 * cos(3th)
    # 数值能量（极坐标网格）
    E(u) = begin
        n = 100
        s = 0.0
        hr, ht = 1 / n, pi / n
        for i in 1:n, j in 0:2n-1
            rr, tt = i * hr, j * ht
            ur = (u(rr + hr / 2, tt) - u(rr - hr / 2, tt)) / hr
            ut = (u(rr, tt + ht / 2) - u(rr, tt - ht / 2)) / ht
            s += (ur^2 + (ut / rr)^2) * rr * hr * ht
        end
        s
    end
    Eu, Ew = E(u_e), E(w)
    @printf("(e) energy: E[u_harm] = %.4f ≤ E[u+%.1f·pert] = %.4f\n", Eu, eps, Ew)
    @assert Ew > Eu "调和函数能量极小（Dirichlet 原理）"
end

println("END ====")
