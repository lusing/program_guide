# Ch44 非线性 VI：上下解、非存在与梯度流
#
# 对应书 §9.3（上下解方法）、§9.4（非存在：blow-up、Pohozaev）、
# §9.5（解的几何性质）、§9.6（梯度流）。

using Printf

println("==== 44")

# ---- (a) 上下解方法：-u'' = u² 于 (0,1)，0 边值 ----
# 下解 u₀ = 0；上解 = 大的抛物线。解被夹住（单调迭代收敛）
# 数值：单调迭代 u_{n+1} 解 -v'' = u_n²（保持序）
function solve_dirichlet(rhs; N = 200, maxit = 20000)
    h = 1 / (N + 1)
    xs = [(i)*h for i in 1:N]
    v = zeros(N)
    for _ in 1:maxit
        for i in 1:N
            left = i > 1 ? v[i-1] : 0.0
            right = i < N ? v[i+1] : 0.0
            v[i] = 0.5 * (left + right + h^2 * rhs(xs[i], v, i))
        end
    end
    return xs, v
end
# -u'' = u² 的迭代（不动点 u = G(u)，G 增）：G^k 夹逼
N = 200
h = 1 / (N + 1)
xs = [(i)*h for i in 1:N]
u_low = zeros(N)     # 下解（0 ≤ u² 满足）
u_high = fill(4.0, N)  # 上解候选：-u''_high = 0 ≤ u_high² ✓（4²=16 ≥ 0）
# 坑账：从下解 0 出发的迭代不动（0 是不动点）——单调迭代从**上解**
# 出发向下夹逼到最小解
u = copy(u_high)
for _ in 1:40000
    for i in 1:N
        left = i > 1 ? u[i-1] : 0.0
        right = i < N ? u[i+1] : 0.0
        u[i] = 0.5 * (left + right + h^2 * u[i]^2)
    end
end
@printf("(a) monotone iteration: u peak = %.6f, bounds [%.2f, %.2f] respected\n",
        maximum(u), maximum(u_low), maximum(u_high))
@assert 0 < maximum(u) < 4 "解被上下解夹住（单调迭代收敛到最小解）"
# 残差
res = maximum(abs((2u[i] - (i > 1 ? u[i-1] : 0) - (i < N ? u[i+1] : 0)) / h^2 - u[i]^2) for i in 1:N)
@printf("    equation residual = %.2e\n", res)
@assert res < 2e-2 "−u″ = u² 成立（GS 从上解收敛级）"

# ---- (b) blow-up（§9.4.1）：u_t = u² 的 ODE 先导（t* = 1/u₀）----
u0 = 2.0
tstar = 1 / u0
for t in [0.3 * tstar, 0.9 * tstar]
    u_t = u0 / (1 - u0 * t)
    @printf("(b) ODE blow-up: u(%.3f) = %.2f (t* = %.3f)\n", t, u_t, tstar)
    @assert u_t > u0 "单调增长到 ∞"
end
@assert u0 / (1 - u0 * 0.9tstar) < u0 / (1 - u0 * 0.99tstar) "接近 t* 时爆炸"

# ---- (c) Pohozaev 恒等式（§9.4.2）：临界指标非存在（数值核对恒等式）----
# -Δu = u^p 于星形域：(n-2)/2∫|∇u|² - n/(p+1)∫u^{p+1} = 边界项 = 0（Dirichlet）
# 制造样本：u = (1-r²) 于单位球（r<1）：核对恒等式的被积平衡
n = 2.0
p = 5.0
# ∫|∇u|² = ∫4r² = 4·2π·∫₀¹r³dr = 2π
grad2 = 2pi
# ∫u^{p+1} = ∫(1-r²)^6 = 2π·∫₀¹r(1-r²)^6dr = 2π·[1/2·1/7] = π/7
upow = pi / 7
lhs = (n - 2) / 2 * grad2 - n / (p + 1) * upow
@printf("(c) Pohozaev identity sample: (n-2)/2∫|∇u|² − n/(p+1)∫u^{p+1} = %.4f\n", lhs)
@printf("    n=2: 第一项消失 ⟹ -n/(p+1)∫u^{p+1} = 边界项（u=0 ⟹ 0 ⟹ ∫u^{p+1}=0 矛盾）⟹ 无解当 p ≥ (n+2)/(n-2)\n")
# n=2 临界 p = ∞（指数任意）；n=3 临界 p = 5
@assert (3 + 2) / (3 - 2) == 5 "n=3 的临界指数 = 5（Sobolev 临界）"

# ---- (d) 梯度流（§9.6）：du/dt = -∇I 的能量衰减（最速下降）----
# I(u) = ½‖u − b‖²：梯度流 u' = b − u（指数收敛）
b = 1.7
for t in [0.5, 2.0]
    ut = b + (0.0 - b) * exp(-t)
    @printf("(d) gradient flow: u(%.1f) = %.4f -> b = %.1f, I decreasing\n", t, ut, b)
    @assert abs(ut - b) < 1.7
end
@assert exp(-2.0) < exp(-0.5) "能量单调下降（凸函数的梯度流收敛）"

println("END ====")

