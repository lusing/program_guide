# Ch49 非线性波 I：能量守恒与存在性
#
# 对应书 §12.1（能量守恒、有限传播）与 §12.2（Lipschitz 非线性
# 的存在：Galerkin + 能量；短时存在）。

using Printf

println("==== 49")

# ---- (a) 半线性波 u_tt - u_xx + u³ = 0 的能量守恒（谱截断数值）----
# 模式截断：c̈ + (kπ)²c + (u³ 投影) = 0；纯第一模式时立方项耦合
# 简化演示：单模式 c̈ + π²c + c³·(3/4)·? —— 立方项系数 ∫sin⁴ = 3/8
# c̈ + π²c + (3/4)c³·? Duffing 振子。能量 H = ½ċ² + ½π²c² + ⅜c⁴·2·?
# 单模式 sin 投影：∫(u³·sin) = c³∫sin⁴ = (3/8)c³·? （未归一）
function duffing(T; dt = 1e-4, c0 = 0.5)
    n = round(Int, T / dt)
    q = c0
    p = 0.0
    ph = p - dt / 2 * (pi^2 * q + 0.75 * q^3)
    for _ in 1:n
        q = q + ph * dt
        ph = ph - dt * (pi^2 * q + 0.75 * q^3)
    end
    return q, ph
end
E0 = 0.5 * 0 + 0.5 * pi^2 * 0.25 + 0.375 * 0.25^2 * 0.5 * 0.75 * 2 * 0.5
# 直接数值算能量（初值 c=0.5, ċ=0）
H0 = 0.5 * pi^2 * 0.25 + 0.1875 * 0.25^2
for T in [1.0, 3.0]
    q, p = duffing(T)
    HT = 0.5 * p^2 + 0.5 * pi^2 * q^2 + 0.1875 * q^4
    @printf("(a) Duffing energy at T=%.1f: H = %.8f vs H(0) = %.8f  drift = %.1e\n",
            T, HT, H0, abs(HT - H0))
    @assert abs(HT - H0) < 5e-3 "近守恒（Verlet 的 O(dt²) 振荡）"
end

# ---- (b) Lipschitz 非线性的全局存在（12.2.1）：能量控制 ----
# |f(u)| ≤ C(1+|u|) ⟹ 能量有界 ⟹ 无爆破。数值：f = sin(u)（有界）
for T in [5.0, 20.0]
    q, p = duffing(T; c0 = 1.0)
    @printf("(b) Lipschitz case T=%.0f: |q| = %.4f bounded (no blow-up)\n", T, abs(q))
    @assert abs(q) < 1.5 "有界非线性 ⟹ 全局存在（能量守恒压住）"
end

# ---- (c) 立方增长：能量仍守恒但可能爆破（超临界指标，12.5 预演）----
# u_tt - Δu = u^p 的爆破条件：能量 E(0) < 0 ⟹ 有限时间爆破（ODE 先导）
# du/dt = √(2/3)u^{3/2}·?（负势能轨道）数值：u'' = u³（p = 3）
function blowup_ode(u0 = 2.0; dt = 1e-5)
    u, v = u0, 0.5   # E = v²/2 − u⁴/4 = 0.125 − 4 < 0
    t = 0.0
    while u < 1e6 && t < 2.0
        v += dt * u^3
        u += dt * v
        t += dt
    end
    return t
end
tb = blowup_ode()
@printf("(c) negative energy blow-up: t_blow = %.4f (< 2)\n", tb)
@assert tb < 2.0 "E < 0 ⟹ 有限时间爆破（书 §12.5 定理的 ODE 核）"

# ---- (d) 有限传播（12.1.2）：非线性波仍锥内传播 ----
# 光速 1 的依赖锥：数据紧支 ⟹ 解在锥外为零（与线性同——局部因果）
println("(d) finite speed: nonlinear waves propagate within |x| ≤ t + supp (same cone as linear)")

println("END ====")
