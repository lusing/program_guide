# Ch09 波方程 I：d'Alembert、Kirchhoff 与 Huygens
#
# 对应书 §2.4.1：球面均值法——一维 d'Alembert、三维 Kirchhoff、
# 二维降维、Huygens 原理（3D 干净后沿 vs 2D 有尾）。

using Printf

println("==== 09")

# ---- (a) d'Alembert（1D）：u = ½(g(x+t)+g(x−t)) + ½∫_{x−t}^{x+t} h ----
g1(x) = exp(-(x - 0.5)^2)
h1(x) = sin(2x)
function dalembert(x, t; n = 4000)
    s = 0.0
    a, b = x - t, x + t
    hh = (b - a) / n
    for k in 0:n
        y = a + k * hh
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * h1(y)
    end
    return 0.5 * (g1(x + t) + g1(x - t)) + 0.5 * s * hh / 3
end
# 制造解对照：残差 u_tt − u_xx（数值差分）
dt = 1e-4
for (x, t) in [(0.3, 0.4), (0.8, 0.9)]
    u_tt = (dalembert(x, t + dt) - 2dalembert(x, t) + dalembert(x, t - dt)) / dt^2
    u_xx = (dalembert(x + dt, t) - 2dalembert(x, t) + dalembert(x - dt, t)) / dt^2
    @printf("(a) d'Alembert at (%.1f,%.1f): u_tt - u_xx = %.2e\n", x, t, u_tt - u_xx)
    @assert abs(u_tt - u_xx) < 1e-4 "d'Alembert 公式满足波方程"
end

# ---- (b) Kirchhoff（3D）：u = ∂_t[t·球面平均 g] + t·球面平均 h ----
# 制造解：g = sin(x1)、h = 0 ⟹ u = sin(x1)cos(t)
# 球面平均用 Fibonacci 格点（数值球面积分）
function sphere_avg(f, x, t; N = 40000)
    s = 0.0
    ga = pi * (3 - sqrt(5.0))
    for k in 0:N-1
        z = 1 - 2(k + 0.5) / N
        th = ga * k
        r = sqrt(1 - z^2)
        y = (x[1] + t * r * cos(th), x[2] + t * r * sin(th), x[3] + t * z)
        s += f(y)
    end
    return s / N
end
sinx1(y) = sin(y[1])
x0 = (0.3, -0.2, 0.4)
for t in [0.5, 1.1]
    avg = sphere_avg(sinx1, x0, t)
    exact_avg = sin(x0[1]) * sin(t) / t
    @printf("(b) sphere avg sin(y1), t=%.1f: num %.8f  exact sin(x1)sin(t)/t %.8f\n",
            t, avg, exact_avg)
    @assert abs(avg - exact_avg) < 2e-4 "线性函数的球面平均闭式"
    # Kirchhoff：t·avg 的 ∂_t 用闭式 sin(t)，数值差分核对
    ut_num = (sphere_avg(sinx1, x0, t + 1e-3) * (t + 1e-3) - sphere_avg(sinx1, x0, t - 1e-3) * (t - 1e-3)) / 2e-3
    u_exact = sin(x0[1]) * cos(t)
    @printf("    Kirchhoff u = %.8f  exact sin(x1)cos(t) = %.8f\n", ut_num, u_exact)
    @assert abs(ut_num - u_exact) < 1e-3 "Kirchhoff 公式复原解析解"
end

# ---- (c) Huygens：3D 干净后沿 vs 2D 有尾 ----
# 紧支初值 g = 支集在 |y|<0.5 的帐篷，h=0。对中心观察点 x0=0：
# 球面 ∂B(0,t) 上帐篷值恒为 max(0, 1−2t)（|y| = t），所以球面平均
# 在 t < 0.5 非零、t ≥ 0.5 后**严格为零**——波通过后干净归零。
tent3(y) = max(0.0, 1.0 - 2 * sqrt(y[1]^2 + y[2]^2 + y[3]^2))
for t in [0.3, 2.0]
    avg = sphere_avg(tent3, (0.0, 0.0, 0.0), t)
    @printf("(c) 3D at origin, t=%.1f: sphere avg of compact g = %.4f %s\n",
            t, avg, t < 0.5 ? "(front: nonzero)" : "(past: EXACTLY zero — clean tail)")
    if t >= 0.5
        @assert avg == 0.0 "Huygens：3D 波通过后严格归零（球面与支集不交则积分为零）"
    else
        @assert abs(avg - (1 - 2t)) < 1e-12 "球面上帐篷恒为 1−2t（|y|=t）"
    end
end
# 2D：盘平均（圆盘与支集相交的测度非零）⟹ 有尾
function disk_avg2d(f2, t; n = 2000)
    s = 0.0
    h = t / n
    for k in 0:n
        r = (k + 0.5) * h
        w = 2r            # 极坐标权重（θ 平均已解析：帐篷径向）
        s += w * f2(r)
    end
    return s * h / (t^2)
end
tent2(r) = max(0.0, 1.0 - 2r)
@printf("    2D at origin, t=2.0: disk avg = %.4f (NONZERO — 2D has tail)\n",
        disk_avg2d(tent2, 2.0))
@assert disk_avg2d(tent2, 2.0) > 0 "二维波有尾（降维破坏 Huygens）"

println("END ====")
