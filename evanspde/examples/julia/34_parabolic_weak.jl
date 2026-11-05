# Ch34 线性发展 I：抛物方程弱解（Galerkin）
#
# 对应书 §7.1.1-7.1.2：抛物方程弱解定义（时空空间）、Galerkin 逼近
#（特征基 + 能量估计 + 紧性收敛）。

using Printf

println("==== 34")

# ---- (a) Galerkin 谱截断：du/dt + Au = f 的模式 ODE 数值 vs 闭式 ----
# A = diag(λ_k)，λ_k = (kπ)²；f = sin(πx)（只激发第一模式）
# 模式方程 dc₁/dt = -π²c₁ + 1，c₁(0) = 0 ⟹ c₁ = (1-e^{-π²t})/π²
c1_exact(t) = (1 - exp(-pi^2 * t)) / pi^2
# 数值（RK4）
function rk4(N)
    dt = 1e-3
    c = [0.0]
    n = round(Int, N / dt)
    for _ in 1:n
        k1 = -pi^2 * c[1] + 1
        k2 = -pi^2 * (c[1] + dt / 2 * k1) + 1
        k3 = -pi^2 * (c[1] + dt / 2 * k2) + 1
        k4 = -pi^2 * (c[1] + dt * k3) + 1
        c[1] += dt / 6 * (k1 + 2k2 + 2k3 + k4)
    end
    return c[1]
end
for T in [0.5, 1.0]
    num = rk4(T)
    exa = c1_exact(T)
    @printf("(a) Galerkin mode ODE t=%.1f: RK4 %.9f  exact %.9f\n", T, num, exa)
    @assert abs(num - exa) < 1e-10 "模式 ODE 精确积分"
end

# ---- (b) 能量估计：E(t) ≤ E(0)e^{-2λ₁t}（书 §7.1.3 前置估计）----
# 初值 g = sin(πx)+0.5sin(2πx)：E(t) = Σc_k²e^{-2λ_kt}/2·?（‖g‖² 加权）
E(t) = 0.5 * (1^2 * exp(-2pi^2 * t) + 0.25 * exp(-8pi^2 * t))
E0 = E(0.0)
for t in [0.3, 1.0, 3.0]
    bound = E0 * exp(-2pi^2 * t)
    @printf("(b) energy at t=%.1f: E = %.3e  bound = %.3e  (ratio %.4f)\n",
            t, E(t), bound, E(t) / bound)
    @assert E(t) ≤ bound * (1 + 1e-12) "指数衰减估计（λ₁ 主导）"
end

# ---- (c) 弱解的正则性提升：u ∈ L²(0,T;H²) ∩ H¹(0,T;L²)（谱面）----
# ‖u‖²_{H²} = Σ c²λ_k² e^{-2λ_kt}（有限：谱增长赢过指数衰减？f=0 数据 H¹）
# 对 g = sin(πx)（单项）：‖u(t)‖²_{H²} = π⁴e^{-2π²t}，‖u_t‖² = π⁴e^{-2π²t}
for t in [0.5, 1.5]
    h2 = pi^4 * exp(-2pi^2 * t)
    ut = pi^4 * exp(-2pi^2 * t)
    @printf("(c) t=%.1f: ||u||²_{H²} = %.3e  ||u_t||²_{L²} = %.3e (equal for single mode)\n",
            t, h2, ut)
    @assert abs(h2 - ut) < 1e-30 "单模式：时间导数与空间正则性同源"
end

# ---- (d) 长时行为：u → 0（λ₁ > 0 决定指数衰减到平衡）----
for t in [1.0, 5.0, 10.0]
    @printf("(d) t=%2.0f: e^{-π²t} = %.2e (decay to equilibrium)\n", t, exp(-pi^2 * t))
end
@assert exp(-pi^2 * 10) < 1e-40

println("END ====")
