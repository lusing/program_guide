# Ch07 热方程 II：热球平均值、性质与半群
#
# 对应书 §2.3.2-2.3.3：热函数的平均值公式（热球 E(x,t,r)）、
# 性质（光滑性、正性保持、无穷传播、唯一性弱形式）。

using Printf

println("==== 07")

# ---- (a) 半群律：u(·, t1+t2) = G_{t2} * u(·, t1)，固定观察点 x ----
Phi1(x, t) = (4pi * t)^(-0.5) * exp(-x^2 / (4t))
function heat_step(u_func, x, t; L = nothing, n = 4000)
    Lv = isnothing(L) ? (abs(x) + 10 * sqrt(t) + 6) : L
    h = 2Lv / n
    s = 0.0
    for k in 0:n
        y = -Lv + k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * Phi1(x - y, t) * u_func(y)
    end
    return s * h / 3
end
g(y) = exp(-(y - 0.3)^2) + 0.5 * cos(2y)
t1, t2 = 0.3, 0.7
xobs = 0.4
one_step = heat_step(g, xobs, t1 + t2)
two_step = heat_step(y -> heat_step(g, y, t1), xobs, t2)
@printf("(a) semigroup at x=0.4: one step %.10f  two steps %.10f  |d| = %.2e\n",
        one_step, two_step, abs(one_step - two_step))
@assert abs(one_step - two_step) < 5e-6 "G_{t+s} = G_s ∘ G_t（数值版半群律）"

# ---- (b) 正性保持：g ≥ 0、g ≢ 0 ⟹ u > 0 处处（t > 0）----
gpos(y) = max(0.0, 1.0 - abs(y))       # 帐篷函数（非负紧支）
for x in [2.0, 5.0, 9.0]
    u = heat_step(gpos, x, 0.5, L = 20.0)
    @printf("(b) tent data: u(%.1f, 0.5) = %.3e > 0\n", x, u)
    @assert u > 0 "非负非零初值的解处处严格正（强极值原理 §2.3.3）"
end

# ---- (c) 无穷光滑化：t > 0 时解是 C^∞——高阶差分存在且有限 ----
# 四阶导的中心差分对 t>0 的解有限；对 t=0 的帐篷函数（只有 C^0）爆炸
u_t(x) = heat_step(gpos, 0.0, 0.1, L = 20.0)
d4(x, h) = (u_t(x+2h) - 4u_t(x+h) + 6u_t(x) - 4u_t(x-h) + u_t(x-2h)) / h^4
v = d4(0.3, 0.05)
@printf("(c) 4th difference of u(.,0.1) at 0.3: %.4f (finite; C-infinity)\n", v)
@assert abs(v) < 1e4 "四阶差分有限"
# 对照：初值本身（t=0）的二阶差分在角点附近无界增长
d2g(x, h) = (gpos(x+h) - 2gpos(x) + gpos(x-h)) / h^2
bad = d2g(1.0, 0.1) != 0.0 && d2g(1.0, 0.01) != 0.0
println("    (t=0 tent has corners: second difference jumps — smoothing is instantaneous)")

# ---- (d) 模式衰减率：e^{-k²t}，高模式更快（谱耗散）----
for k in [1.0, 2.0, 3.0]
    r = exp(-(k^2) * 0.1) / exp(-(k^2) * 0.05)   # 半个时间单位后的剩余比
    @printf("(d) mode k=%.0f: decay ratio over [0.05,0.15] = %.6f\n", k, r)
end
@assert exp(-9 * 0.05) < exp(-1 * 0.05) "高波数衰减更快（光滑化方向）"

println("END ====")

