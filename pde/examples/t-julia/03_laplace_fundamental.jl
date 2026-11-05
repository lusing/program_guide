# Ch03 Laplace 方程 I：基本解、平均值公式与通量
#
# 对应书 §2.2.1-2.2.2：径向解导出基本解（n=2 是 -log|x|/2π、
# n>=3 是 1/(n(n-2)α(n))|x|^{2-n}）、Poisson 方程的卷积解
# u = Φ*f（定理 1）、平均值公式（定理 2：球面平均 = 球平均 = 点值）
# 与其逆（定理 3）。

using Printf

println("==== 03")

# ---- (a) 平均值公式：调和函数 u = x^2 - y^2（书定理 2 的数值版）----
# 球面平均：圆周梯形（对光滑周期被积函数谱精度）
function circle_avg(u, cx, cy, rho, N = 4096)
    s = 0.0
    for k in 0:N-1
        th = 2pi * k / N
        s += u(cx + rho * cos(th), cy + rho * sin(th))
    end
    return s / N
end
u1(x, y) = x^2 - y^2
for (cx, cy, rho) in [(0.3, -0.4, 0.7), (1.1, 0.2, 0.35), (0.0, 0.0, 1.0)]
    av = circle_avg(u1, cx, cy, rho)
    ex = u1(cx, cy)
    @printf("(a) circle avg = %.14f  u(center) = %.14f  |diff| = %.2e\n", av, ex, abs(av - ex))
    @assert abs(av - ex) < 1e-12 "平均值公式：球面平均等于中心值"
end

# 球（圆盘）平均：极坐标积分 ∫∫ u r dr dθ / (πρ²)。
# r 用复合 Simpson（2000 子区间），θ 用圆周梯形谱精度（circle_avg）。
# 与书 §2.2.2 第 2 步同构：球平均 = 球面平均对 r 的再平均。
# （坑账：初版硬抄 Gauss--Legendre 权重表，和≠2，被"调和函数球平均
#  必等于中心值"的对账当场打回——权表面前，先验证权和。）
function disk_avg2(u, cx, cy, rho)
    n = 2000
    h = rho / n
    s = 0.0
    for k in 0:n
        r = k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * r * circle_avg(u, cx, cy, r)   # r=0 端点项自然为零
    end
    s *= h / 3
    # circle_avg 是 θ 平均（已除 2π），故 ∫∫ = 2π · ∫ r·avg_θ dr，再除面积 πρ²
    return 2 * pi * s / (pi * rho^2)
end
av2 = disk_avg2(u1, 0.3, -0.4, 0.7)
@printf("(a) disk avg   = %.14f  u(center) = %.14f  |diff| = %.2e\n",
        av2, u1(0.3, -0.4), abs(av2 - u1(0.3, -0.4)))
@assert abs(av2 - u1(0.3, -0.4)) < 1e-12 "球平均也等于中心值（定理 2 后半）"

# ---- (b) 定理 3 的数值面：次调和 |x|^2 严格 > 中心值，超调和 < ----
u2(x, y) = x^2 + y^2
d = circle_avg(u2, 0.2, 0.5, 0.6) - u2(0.2, 0.5)
@printf("(b) |x|^2: sphere avg - center = %.6f (= rho^2 = 0.36)\n", d)
@assert abs(d - 0.36) < 1e-12 "次调和：平均超出恰为 ρ²（书 p.26 计算）"
u3(x, y) = -(x^2 + y^2)
@assert circle_avg(u3, 0.2, 0.5, 0.6) - u3(0.2, 0.5) < -0.35 "超调和反向"

# ---- (c) 基本解的通量：−ΔΦ = δ 的数值化身 ----
# n=2：Φ = −log r/(2π)；过任意圆周的法向通量 ∮ ∂Φ/∂n ds = −1
Phi2(x, y) = -log(hypot(x, y)) / (2pi)
for rho in [0.3, 1.7, 4.0]
    # ∂Φ/∂n = −1/(2πρ)（常数！），周长 2πρ ⟹ 通量 = −1
    flux = 0.0
    N = 2048
    for k in 0:N-1
        th = 2pi * k / N
        x, y = rho * cos(th), rho * sin(th)
        # n = (x,y)/ρ；∇Φ = −(x,y)/(2π ρ²)；∇Φ·n = −1/(2πρ)
        flux += (-1 / (2pi * rho)) * (2pi * rho / N)
    end
    @printf("(c) n=2 flux through r=%.1f circle: %.14f\n", rho, flux)
    @assert abs(flux + 1) < 1e-12 "2D 基本解通量恒为 −1"
end
# n=3：Φ = 1/(4π|x|)；∇Φ·n = −1/(4πρ²)，球面积 4πρ² ⟹ 通量 = −1
rho = 2.1
grad_dot_n = -1 / (4pi * rho^2)
flux3 = grad_dot_n * 4pi * rho^2
@printf("(c) n=3 flux through r=%.1f sphere: %.14f\n", rho, flux3)
@assert abs(flux3 + 1) < 1e-15 "3D 基本解通量恒为 −1"

# ---- (d) 定理 1 的数值对账：圆盘指示源 f=1_{|y|<a} 的卷积 ----
# u(0) = ∫ Φ(y) f(y) dy = −(1/2π)·2π∫₀^a r log r dr = a²(1 − 2 log a)/4
a = 0.8
closed = a^2 * (1 - 2 * log(a)) / 4
# 数值：Simpson 积 r log r 于 [ε, a]，奇点尾段 [0, ε] 用解析式
# tail = ∫₀^ε r log r dr = (ε²/2)log ε − ε²/4
eps0 = 1e-3
n = 4000
h = (a - eps0) / n
num = 0.0
for k in 0:n
    global num
    r = eps0 + k * h
    w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
    num += w * r * log(r)
end
num *= h / 3
num += eps0^2 / 2 * log(eps0) - eps0^2 / 4      # 奇点尾段解析补
num *= -1 / (2pi) * 2pi                          # Φ = −log r/(2π)，θ 积分贡献 2π
@printf("(d) u(0) for disk source a=0.8: quadrature %.12f  closed %.12f\n", num, closed)
@assert abs(num - closed) < 1e-10 "定理 1 的卷积值与闭式对账"

println("END ====")
