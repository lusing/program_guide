# Ch12 非线性一阶 II：特征线
#
# 对应书 §3.2：特征 ODE 组的推导、边界条件沿特征传递、局部解
# 构造（书式 (23)-(30)）、应用（传输/乙ier解比较）。

using Printf

println("==== 12")

# ---- (a) 拟线性方程 u_x + u·u_y = 0 的特征线数值 ----
# 特征 ODE：dx/ds = 1, dy/ds = u, du/ds = 0（沿特征 u 常数）
# 边界 g(x) = u(x, 0) = 1 + 0.5sin(x)：特征线 y = g(ξ)·s，解
# u(x,y) = g(ξ) 其中 x = ξ + g(ξ)·0? 等等：dx/ds=1 ⟹ x = ξ+s,
# y = u·s ⟹ 特征线是直线 y = g(ξ)(x−ξ)
g(x) = 1 + 0.5 * sin(x)
# 数值求 ξ(x,y)：解 y = g(ξ)(x−ξ)（Newton）
function solve_xi(x, y)
    xi = x - y / 1.0   # 初值
    for _ in 1:50
        F = g(xi) * (x - xi) - y
        dF = 0.5cos(xi) * (x - xi) - g(xi)
        xi -= F / dF
    end
    return xi
end
# 验证 u = g(ξ) 满足 PDE（数值差分）
u_sol(x, y) = g(solve_xi(x, y))
for (x, y) in [(0.7, 0.3), (1.5, 0.8), (-0.4, 0.5)]
    d = 1e-5
    ux = (u_sol(x + d, y) - u_sol(x - d, y)) / (2d)
    uy = (u_sol(x, y + d) - u_sol(x, y - d)) / (2d)
    r = ux + u_sol(x, y) * uy
    @printf("(a) quasi-linear at (%.1f,%.1f): u_x + u·u_y = %.2e  u=%.4f\n", x, y, r, u_sol(x, y))
    @assert abs(r) < 2e-4 "特征线解满足拟线性方程"
end

# ---- (b) 一般特征 ODE 组的数值积分（书式 (30) 的直接应用）----
# 全非线性 F(∇u, u, x) = 0：特征是 5 维 ODE。演示 HJ 方程
# u_y + H(u_x) = 0，H(p) = p²/2：特征 dx/ds = H'(p) = p, dp/ds = 0
# 边界 u(x,0) = x²/4（⟹ p(ξ,0) = x/2）
# 解：p = ξ/2 常数，x = ξ + (ξ/2)s ⟹ ξ = x/(1+s/2)，u = ξ²/4 + H(ξ/2)s
function hj_solution(x, s)
    xi = x / (1 + s / 2)
    return xi^2 / 4 + (xi / 2)^2 / 2 * s
end
# 验证 u_y + u_x²/2 = 0
for (x, y) in [(0.8, 0.4), (1.2, 1.0)]
    d = 1e-5
    uy = (hj_solution(x, y + d) - hj_solution(x, y - d)) / (2d)
    ux = (hj_solution(x + d, y) - hj_solution(x - d, y)) / (2d)
    r = uy + ux^2 / 2
    @printf("(b) HJ at (%.1f,%.1f): u_y + u_x^2/2 = %.2e\n", x, y, r)
    @assert abs(r) < 1e-6 "HJ 特征线解（光滑范围内）"
end

# ---- (c) 边界非特征条件的传播：曲线 (x(s),y(s)) 与特征相切时失效 ----
# 取边界曲线 y = 0 上的数据；特征方向 (1, g)。边界切向 (1, 0)。
# 非退化条件：det[[1,g],[1,0]] = -g ≠ 0 ✓（g ≥ 0.5 处处正）
println("(c) boundary transversality: det = -g(x) <= -0.5 < 0 everywhere (non-characteristic)")
@assert minimum(g, range(0, 2pi, length = 100)) > 0.5

println("END ====")
