# Ch32 二阶椭圆 IV：极值原理与 Harnack
#
# 对应书 §6.4：弱极值原理、强极值原理（Hopf 引理）、Harnack 不等式。

using Printf

println("==== 32")

# ---- (a) 弱极值原理数值：-Δu = f ≤ 0（次调和的反面）⟹ max 在边界 ----
# u = sin(πx)sinh(π(1-y))/sinh(π)（调和，单位方，上边 1 其余 0）
u_har(x, y) = sin(pi * x) * sinh(pi * (1 - y)) / sinh(pi)
lap5(u, x, y, h) = (u(x+h,y) + u(x-h,y) + u(x,y+h) + u(x,y-h) - 4u(x,y)) / h^2
r = lap5(u_har, 0.4, 0.4, 1e-3)
@printf("(a) harmonic check: Δ_h u = %.2e\n", r)
@assert abs(r) < 1e-5 "u 调和（sinh 放大截断）"
# 内部抽样：严格小于边界最大 1
inner_max = maximum(u_har(x, y) for x in 0.1:0.05:0.9, y in 0.1:0.05:0.9)
@printf("    max over interior sample = %.6f < boundary max 1\n", inner_max)
@assert inner_max < 1 - 1e-3 "最大值在边界（严格）"

# ---- (b) 强极值原理：内部最大 ⟹ 常数（传播论证的数值面）----
# 若 u(x0) = 1 = max，平均值公式迫使邻域同值——对非常数解不可能
@printf("(b) strong max: nonconstant harmonic u has u < 1 strictly inside\n")
@assert u_har(0.5, 0.5) < 1 "u(0.5,0.5) = %.4f < 1" |> (s -> begin; @printf("    u(center) = %.4f\n", u_har(0.5, 0.5)); true; end)

# ---- (c) Hopf 引理：边界点的法向导数严格正 ----
# u 在上边 y=0 为 1、内部小于 1：∂u/∂n > 0 于最大值边界点
dy = (u_har(0.5, 1e-4) - u_har(0.5, 0.0)) / 1e-4
@printf("(c) Hopf lemma: ∂u/∂y at (0.5, 0) = %.4f < 0 (outward normal −y)\n", dy)
@assert dy < 0 "法向导数指向外为负值下降方向（Hopf 严格性）"

# ---- (d) Harnack 不等式：正调和函数的 sup/inf ≤ C(r) ----
# u = e^x sin(y)（正于 y ∈ (0,π)，调和）。B(0, r) 上 sup/inf 与 (1+r)/(1−r) 比较
u_pos(x, y) = exp(x) * sin(y)
for r in [0.3, 0.6]
    # 圆周采样 sup/inf（圆心 (0, π/2) 避开 y 边界）
    sup = -Inf; inf = Inf
    for k in 0:2000
        th = 2pi * k / 2001
        x = r * cos(th)
        y = pi / 2 + r * sin(th)
        v = u_pos(x, y)
        sup = max(sup, v); inf = min(inf, v)
    end
    bound = (1 + r) / (1 - r)
    @printf("(d) Harnack r=%.1f: sup/inf = %.4f <= (1+r)/(1-r) = %.4f\n",
            r, sup / inf, bound)
    @assert sup / inf <= bound + 1e-9 "Harnack 上界（2D 常数）"
end

println("END ====")

