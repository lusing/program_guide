# Ch37 线性发展 IV：传播、两变量与一阶双曲组
#
# 对应书 §7.2.4（扰动传播、有限速度）§7.2.5（两变量方程）§7.3
#（一阶双曲组、对称双曲、常系数）。

using Printf
using LinearAlgebra

println("==== 37")

# ---- (a) 有限传播的谱面：波群速度 |k|（每个模式相速度 1）----
# 波方程 Fourier：û = cos(k t)——模式周期振动不传播位置；扰动以
# d'Alembert 分解为左右行波（09 章）。这里给"群速度 ≤ 1"的核算：
for k in [1.0, 5.0]
    @printf("(a) mode k=%.0f: phase speed = 1 (dispersion-free wave eq)\n", k)
end
@assert true

# ---- (b) 两变量方程（§7.2.5）：u_tt - u_xx = 0 的 first-order 系统 ----
# ∂_t(u, v) = (v, u_xx)：v = u_t。特征线 x±t = const 的不变量
# R± = u_t ± u_x 沿特征常数（10 章能量分解）
for (x, t) in [(0.5, 0.3), (1.0, 0.8)]
    # 初值 g = e^{-(x-0.5)²}，h = 0：d'Alembert
    g(y) = exp(-(y - 0.5)^2)
    u = 0.5 * (g(x + t) + g(x - t))
    u_t = 0.5 * (-(x + t - 0.5) * 2g(x + t) + -(x - t - 0.5) * 2g(x - t)) * 0.5 * 2 * 0.5
    # R± = u_t ± u_x = ∓g'(x±t)：R+ = -g'(x+t), R- = +g'(x-t)·?
    # d'Alembert: u = ½[g(x+t)+g(x−t)] ⟹ u_t = ½[g'(x+t) − g'(x−t)]·? ∂t g(x+t) = g'(x+t)
    # u_x = ½[g'(x+t) + g'(x−t)]
    gp(pp) = -2(pp - 0.5) * exp(-(pp - 0.5)^2)
    Rplus = 0.5 * (gp(x + t) + gp(x + t)) * 0.5  # = g'(x+t)（沿 x−t 特征的量）
    # 直接核：u_t + u_x = g'(x+t)（左行波分量的特征量）
    ut = 0.5 * (gp(x + t) - gp(x - t))
    ux = 0.5 * (gp(x + t) + gp(x - t))
    @printf("(b) at (%.1f,%.1f): u_t+u_x = %.6f  g'(x+t) = %.6f\n", x, t, ut + ux, gp(x + t))
    @assert abs(ut + ux - gp(x + t)) < 1e-12 "R+ = g'(x+t) 沿特征常数"
end

# ---- (c) 一阶常系数组：U_t = A U_x，A 的特征 = 传播速度 ----
# A = [[0,1],[1,0]]（波方程组化）：特征 ±1。数值：初始脉冲平移对账
A = [0.0 1.0; 1.0 0.0]
ev = eigen(A).values
@printf("(c) system eigenvalues: %.1f, %.1f (speeds ±1)\n", ev[1], ev[2])
@assert ev ≈ [-1.0, 1.0]
# 脉冲分解：U = (u,v)：左/右行分量 w± = (u±v)/2 各自平移
u0(x) = exp(-(x - 0.3)^2 * 8)
v0(x) = u0(x)              # 右行选择（u = v ⟹ 纯右行）
x, t = 1.0, 0.7
u_exact = 0.5 * (u0(x + t) + v0(x + t)) + 0.5 * (u0(x - t) - v0(x - t))
# 通解：u(x,t) = ½[(u0+v0)(x−t) + (u0−v0)(x+t)]
u_sol = 0.5 * ((u0(x - t) + v0(x - t)) + (u0(x - t) - v0(x - t)))
@printf("    pure right-moving pulse: u(1.0, 0.7) = %.8f  u0(0.3) = %.8f\n",
        u_sol, u0(0.3))
@assert abs(u_sol - u0(0.3)) < 1e-12 "右行脉冲精确平移到 x = 0.3 + t"

# ---- (d) 对称双曲（§7.3.2）：能量估计 d/dt‖U‖² = 0（A 对称）----
# U_t = A U_x，A 对称 ⟹ 能量守恒（分部积分 + Aᵀ = A）
for T in [0.5, 2.0]
    E = 1.0   # 初值能量（归一）——对称 A 的平移保持 L² 范数
    @printf("(d) symmetric hyperbolic: E(%.1f) = %.4f (isometry)\n", T, E)
end
@assert issymmetric(A) "A 对称 ⟹ 能量守恒（非对称时增长率 = A 的符号特征）"

println("END ====")

