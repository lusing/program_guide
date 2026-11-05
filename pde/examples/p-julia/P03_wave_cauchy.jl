# P03 习题篇 IV：波动方程 Cauchy 问题（书第 3 章 §3.1）
#
# 精选：3.1-3.9 型（d'Alembert 的直接应用、依赖区间、特征三角形、
# 非齐次 Duhamel、半直线延拓预演）。

using Printf

println("==== P03")

# ---- (a) 3.1 型：u_tt − 4u_xx = 0，u(x,0)=x², u_t(x,0)=1 的 Cauchy 解 ----
# d'Alembert（a=2）：u = ½[(x+2t)² + (x−2t)²] + ½∫_{x−2t}^{x+2t} 1 ds
u_a(x, t) = 0.5 * ((x + 2t)^2 + (x - 2t)^2) + 0.5 * (4t)
for (x, t) in [(0.5, 0.3), (1.0, 0.7)]
    d = 1e-4
    utt = (u_a(x, t + d) - 2 * u_a(x, t) + u_a(x, t - d)) / d^2
    uxx = (u_a(x + d, t) - 2 * u_a(x, t) + u_a(x - d, t)) / d^2
    @printf("(a) 3.1: u_tt−4u_xx at (%.1f,%.1f) = %.1e\n", x, t, utt - 4uxx)
    @assert abs(utt - 4uxx) < 1e-5 "d'Alembert 解"
end
@printf("    u(1,1/4) = %.4f（闭式 ½[(1.5)²+(0.5)²]+½ = 1.75）\n", u_a(1.0, 0.25))
@assert u_a(1.0, 0.25) == 1.75

# ---- (b) 3.3-3.4 型：依赖区间的边界数据决定 ----
# u(x₀,t₀) 只依赖 [x₀−2t₀, x₀+2t₀] 上的初值；特征三角形外改变初值无影响
u_b(x, t, g, h) = 0.5 * (g(x + 2t) + g(x - 2t)) + 0.5 * (quad_h(x - 2t, x + 2t, h))
function quad_h(a, b, h; n = 1000)
    s = 0.0
    hh = (b - a) / n
    for k in 0:n
        s += ((k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)) * h(a + k * hh)
    end
    return s * hh / 3
end
g1(y) = y < 3 ? sin(y) : 0.0        # 数据只集中在 (−∞,3)
g2(y) = y < 3 ? sin(y) : 5.0        # 3 之后改数据
h0(y) = 0.0
# 观察点 (2, 0.4)：依赖区间 [1.2, 2.8] ⊂ (−∞,3)——数据相同 ⟹ 解相同
v1 = u_b(2.0, 0.4, g1, h0)
v2 = u_b(2.0, 0.4, g2, h0)
@printf("(b) cone: u(2,0.4) with g|g1 = %.8f vs g|g2 = %.8f（相等：依赖区间 [1.2,2.8]）\n", v1, v2)
@assert abs(v1 - v2) < 1e-12 "依赖区间外数据无影响"
# 观察点 (2, 2.0)：依赖区间 [−2, 6] 穿过 3——数据不同 ⟹ 解不同
w1 = u_b(2.0, 2.0, g1, h0)
w2 = u_b(2.0, 2.0, g2, h0)
@printf("    u(2,2.0): %.6f vs %.6f（不同：区间 [−2,6] 穿过数据变化处）\n", w1, w2)
@assert abs(w1 - w2) > 1.0

# ---- (c) 非齐次：u_tt − u_xx = x t（Duhamel 三重积分公式）----
# u = ½∫₀ᵗ dτ ∫_{x−(t−τ)}^{x+(t−τ)} τξ dξ = ½∫₀ᵗ τ·[ξ²/2] 边界 ds
u_c(x, t) = 0.5 * quad_h(0, t, s -> s * 0.5 * ((x + (t - s))^2 - (x - (t - s))^2))
for (x, t) in [(0.3, 0.5), (1.0, 1.0)]
    d = 1e-4
    utt = (u_c(x, t + d) - 2 * u_c(x, t) + u_c(x, t - d)) / d^2
    uxx = (u_c(x + d, t) - 2 * u_c(x, t) + u_c(x - d, t)) / d^2
    @printf("(c) Duhamel: u_tt−u_xx−xt at (%.1f,%.1f) = %.1e\n", x, t, utt - uxx - x * t)
    @assert abs(utt - uxx - x * t) < 2e-4 "Duhamel 公式"
end

# ---- (d) 3.9 型：特征平行四边形（解在顶点的平均值性质）----
# 波方程解满足 u(A)+u(C) = u(B)+u(D)（特征平行四边形四顶点）
u_d(x, t) = sin(x) * cos(t) + x * t^2   # 制造解（u_tt−u_xx = 2x·?）
# 取特征平行四边形：A=(x0,t0)，特征方向 (±1,1)
x0, t0, s = 0.5, 0.3, 0.2
A = (x0, t0)
B = (x0 + s, t0 + s)
C = (x0, t0 + 2s)
D = (x0 - s, t0 + s)
val = u_d(A...) + u_d(C...) - u_d(B...) - u_d(D...)
@printf("(d) char parallelogram: u(A)+u(C)−u(B)−u(D) = %.6f\n", val)
# sin·cos 部分满足波方程 → 平行四边形性质成立；xt² 部分不满足
# 检验纯波部分
val2 = (sin(0.5)cos(0.3) + sin(0.5)cos(0.7)) - (sin(0.7)cos(0.5) + sin(0.3)cos(0.5))
@printf("    pure wave part: %.10f (=0 by sin addition)\n", val2)
@assert abs(val2) < 1e-10 "波方程部分的平行四边形恒等式"

println("END ====")
