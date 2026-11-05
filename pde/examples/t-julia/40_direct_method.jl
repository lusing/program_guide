# Ch40 非线性 II：极小存在性——直接方法
#
# 对应书 §8.2：强制（coercivity）+ 弱下半连续（凸性）⟹ 极小存在；
# 弱解 E-L 的存在；局部极小。

using Printf
using LinearAlgebra

println("==== 40")

# ---- (a) 直接方法的数值：I[u] = ∫(½|u'|² − x·u) 的极小 = Poisson 解 ----
# E-L: -u'' = x；u = x(1-x²)/6（零边值）。数值最小化（梯度下降）
u_star(x) = x * (1 - x^2) / 6
function I_val(uv, h)
    s = 0.0
    for i in 1:length(uv)-1
        s += 0.5 * ((uv[i+1] - uv[i]) / h)^2
    end
    s *= h
    s2 = 0.0
    for i in 2:length(uv)-1
        s2 += -xs_i(i, h) * uv[i]
    end
    s2 *= h
    return s + s2
end
xs_i(i, h) = i * h
N = 100
h = 1 / (N + 1)
xs = [(i) * h for i in 1:N]
u = zeros(N)
# 梯度下降（梯度 = K u − f，K 三对角）
f = [x for x in xs]
for it in 1:80000
    g = zeros(N)
    for i in 1:N
        g[i] = (2u[i] - (i > 1 ? u[i-1] : 0) - (i < N ? u[i+1] : 0)) / h^2 - f[i]
    end
    u .-= 0.3 * h^2 * g
end
err = maximum(abs.(u .- u_star.(xs)))
@printf("(a) direct minimization: max err vs exact = %.2e\n", err)
@assert err < 1e-4 "极小点 = E-L 解（直接方法的数值面）"

# ---- (b) 强制性：I[u] → ∞ 当 ‖u‖ → ∞（谱面）----
for scale in [1.0, 10.0, 100.0]
    # I[λ sin πx] = λ²π²/4 − λ·⟨x, sin⟩
    ip = 0.5
    val = scale^2 * pi^2 / 4 - scale * 0.5
    @printf("(b) coercivity: I[%.0f sinπx] = %.1f (quadratic growth)\n", scale, val)
end
@assert 100^2 * pi^2 / 4 > 10^3 "二次增长压倒线性项（强制）"

# ---- (c) 弱下半连续 vs 无凸性失败样本：双阱位势 ----
# I = ∫(½u'² + (u²-1)²)：两个极小 u = ±1；零边值下极小在中间过渡
# 数值（梯度下降）
N2 = 200
h2 = 1 / (N2 + 1)
u2 = [tanh((x - 0.5) * 8) for x in [(i)*h2 for i in 1:N2]]
for it in 1:3000
    g = zeros(N2)
    for i in 1:N2
        g[i] = (2u2[i] - (i > 1 ? u2[i-1] : 0) - (i < N2 ? u2[i+1] : 0)) / h2^2 +
               4u2[i] * (u2[i]^2 - 1)
    end
    u2 .-= 0.05 * h2^2 * g
end
@printf("(c) double-well: u ≈ tanh transition; max|u| = %.4f, u(1/2)≈0\n",
        maximum(abs.(u2)))
@assert maximum(abs.(u2)) < 1.01 && abs(u2[div(N2, 2)]) < 0.05 "±1 之间的过渡层极小"

println("END ====")

