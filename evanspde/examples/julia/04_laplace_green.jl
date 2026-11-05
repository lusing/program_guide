# Ch04 Laplace 方程 II：调和函数性质与 Green 函数
#
# 对应书 §2.2.3（强极值原理、唯一性、光滑性、导数估计、解析性、
# Harnack、Liouville）与 §2.2.4（Green 函数、表示公式、对称性、
# 半空间与球的镜像法、Poisson 核）。

using Printf

println("==== 04")

# ---- (a) 磨光不动点：η_ε * u = u（书定理 6 光滑性的数值面）----
# 调和函数与标准磨光核卷积不变（书 p.28 的证明核心 u_ε = u）
moll(x, y, eps) = exp(-(x^2 + y^2) / (2 * eps^2)) / (2 * pi * eps^2)
u_h(x, y) = x^2 - y^2
# 数值卷积（截断 [-4ε, 4ε]，Simpson 双向 101×101）
function conv_moll(f, x0, y0, eps)
    R = 6 * eps   # 6σ 截断：尾部核质量 ~1.5e-8（4σ 时 ~3e-4，不够）
    n = 100
    h = 2 * R / n
    s = 0.0
    for i in 0:n, j in 0:n
        xi, yj = x0 - R + i * h, y0 - R + j * h
        wx = (i == 0 || i == n) ? 1.0 : (iseven(i) ? 2.0 : 4.0)
        wy = (j == 0 || j == n) ? 1.0 : (iseven(j) ? 2.0 : 4.0)
        s += wx * wy * moll(xi - x0, yj - y0, eps) * f(xi, yj)
    end
    return s * h^2 / 9
end
eps0 = 0.15
c = conv_moll(u_h, 0.3, -0.2, eps0)
@printf("(a) mollify fixed point: (eta*u)(0.3,-0.2) = %.12f  u = %.12f  |diff| = %.2e\n",
        c, u_h(0.3, -0.2), abs(c - u_h(0.3, -0.2)))
@assert abs(c - u_h(0.3, -0.2)) < 1e-9 "调和函数是磨光核不动点（正则性之源）"

# ---- (b) Harnack 饱和：u = 1 + x 正调和，比值恰为 (1+r)/(1−r) ----
for r in [0.25, 0.6, 0.9]
    umax = 1 + r        # θ = 0
    umin = 1 - r        # θ = π
    bound = (1 + r) / (1 - r)
    @printf("(b) r=%.2f: max u/min u = %.6f  (1+r)/(1-r) = %.6f  (Harnack saturated)\n",
            r, umax / umin, bound)
    @assert abs(umax / umin - bound) < 1e-12 "线性调和函数使 Harnack 界饱和"
    @assert umax ≤ bound * 1.0 + 1e-15 "上界 u ≤ (1+r)/(1-r)·u(0)，u(0) = 1"
end

# Liouville 的数值反衬：非常数调和函数必无界（r^2 cos 2θ 沿射线增长）
for R in [1.0, 5.0, 20.0]
    @printf("    r^2 cos2θ at radius %.0f: max = %.0f (unbounded)\n", R, R^2)
end

# ---- (c) 球的 Green 函数与镜像：n=2，G(x,y) = Φ(y−x) − Φ(|x||y−x*|) ----
# x* = x/|x|² 是反演点；恒等式 |y−x| = |x|·|y−x*|（|y|=1）保证 G=0 于边界
Phi(r) = -log(r) / (2pi)
function Gball(x, y)   # x 内点（≠0），y ∈ 单位圆盘
    xs = x ./ (x[1]^2 + x[2]^2)
    Phi(hypot(y[1] - x[1], y[2] - x[2])) -
        Phi(hypot(y[1] - xs[1], y[2] - xs[2]) * hypot(x[1], x[2]))
end
x0 = (0.3, 0.4)
println("(c) G vanishes on |y|=1 (method of images):")
ok = true
for k in 0:7
    th = 2pi * k / 8
    y = (cos(th), sin(th))
    g = Gball(x0, y)
    @printf("    theta=%4.1f°: G = %+.2e\n", rad2deg(th), g)
    global ok = ok && abs(g) < 1e-14
end
@assert ok "镜像法：Green 函数在边界恒为零"

# 对称性 G(x,y) = G(y,x)（书定理 13）
y0 = (0.6, -0.5)
@printf("    G(x,y) = %.12f  G(y,x) = %.12f\n", Gball(x0, y0), Gball(y0, x0))
@assert abs(Gball(x0, y0) - Gball(y0, x0)) < 1e-14 "Green 函数对称性"

# ---- (d) 球的 Poisson 核重构：g = cos2θ → 解 r^2 cos2θ ----
# P(x,y) = (1−|x|²)/(2π|x−y|²)，u(x) = ∮_{|y|=1} P(x,y) g(y) dS(y)
function poisson_ball(x, g, N = 8192)
    s = 0.0
    for k in 0:N-1
        th = 2pi * k / N
        y = (cos(th), sin(th))
        P = (1 - (x[1]^2 + x[2]^2)) / (2pi * ((x[1] - y[1])^2 + (x[2] - y[2])^2))
        s += P * g(th) * (2pi / N)
    end
    return s
end
g2(th) = cos(2th)
for x in [(0.2, 0.1), (0.5, -0.3), (0.0, 0.7)]
    ex = x[1]^2 + x[2]^2
    num = poisson_ball(x, g2)
    exact = (x[1]^2 - x[2]^2) / 1  # r^2 cos2θ = x^2−y^2
    @printf("(d) Poisson ball at (%.1f,%.1f): integral %.12f  exact %.12f  |d|=%.1e\n",
            x[1], x[2], num, exact, abs(num - exact))
    @assert abs(num - exact) < 1e-10 "Poisson 核重构解析解"
end

println("END ====")
