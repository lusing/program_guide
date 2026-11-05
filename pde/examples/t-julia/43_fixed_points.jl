# Ch43 非线性 V：单调性与不动点
#
# 对应书 §9.1（单调算子：Minty-Browder）与 §9.2（Banach 压缩、
# Schauder、Schaefer 不动点）。

using Printf

println("==== 43")

# ---- (a) Banach 压缩：Picard 迭代 u_{n+1} = T u_n 的收敛率 = Lipschitz ----
# T u = 解 -εu'' = f(u)（半线性）：-v'' = 1 - v²·ε，小 ε 时压缩
# 简化模型：T u = sin(u)/2 + x/4（Lipschitz 1/2）
T(u) = 0.5 * sin(u) + 0.25 * 0.3
function picard_rates()
    u = 0.0
    rates = Float64[]
    for n in 1:30
        un = T(u)
        push!(rates, abs(un - u))
        u = un
    end
    return rates
end
rates = picard_rates()
@printf("(a) Banach: |u_{n+1}-u_n| sequence: %.2e -> %.2e (halving)\n",
        rates[1], rates[end])
@assert rates[end] < rates[1] * 0.5^20 "线性收敛率 ≤ 1/2（压缩映射）"
@assert rates[10] / rates[9] < 0.51 "逐比率 ≈ 0.5"

# ---- (b) Newton（二次收敛——压缩定理不覆盖但 Schaefer 框架内）----
f43(x) = x^2 - 2
function newton_errs()
    x = 1.0
    errs = Float64[]
    for _ in 1:8
        x = x - f43(x) / (2x)
        push!(errs, abs(x - sqrt(2)))
    end
    return errs
end
errs = newton_errs()
@printf("(b) Newton sqrt2: err %.2e -> %.2e (quadratic: ratio %.0e)\n",
        errs[1], errs[end], errs[end] / errs[end-1]^2)
@assert errs[end] < 1e-15

# ---- (c) Schauder（紧不动点）：积分算子的存在（Green 函数核）----
# T u = ∫G(x,y)(1 + u(y)²/10)dy 于 (0,1)：连续紧映射把 [−M,M] 映入自身
# 数值：迭代收敛（Schauder 保证存在，迭代给出它）
function Tint(u, N = 200)
    h = 1 / (N + 1)
    xs = [(i)*h for i in 1:N]
    out = zeros(N)
    for i in 1:N
        s = 0.0
        for j in 1:N
            # Green G(x,y) = x(1-y) (x<y), y(1-x) (x≥y)
            x, y = xs[i], xs[j]
            G = x < y ? x * (1 - y) : y * (1 - x)
            s += G * (1 + u[j]^2 / 10) * h
        end
        out[i] = s
    end
    return out
end
u = zeros(200)
for _ in 1:300
    global u = Tint(u)
end
@printf("(c) Schauder iteration: ||u||_inf = %.4f (invariant ball, fixed point)\n",
        maximum(abs.(u)))
@assert 0 < maximum(abs.(u)) < 1 "球不变 ⟹ 不动点存在（迭代收敛到它）"
# 不动点残差
r = maximum(abs.(u - Tint(u)))
@printf("    fixed point residual = %.2e\n", r)
@assert r < 1e-8

# ---- (d) 单调算子（Minty-Browder 预览）：p-Laplacian 的单调性 ----
# ⟨T(u)-T(v), u-v⟩ ≥ 0（p=3 一维数值抽样）
Tmono(s) = abs(s) * s
for (a, b) in [(1.0, 0.5), (-0.3, 0.8), (2.0, -1.0)]
    m = (Tmono(a) - Tmono(b)) * (a - b)
    @printf("(d) monotonicity: (%.1f,%.1f): ⟨Tu-Tv, u-v⟩ = %.4f ≥ 0\n", a, b, m)
    @assert m ≥ 0 "s↦|s|s 单调 ⟹ p-Laplacian 单调 ⟹ 唯一弱解（Minty-Browder）"
end

println("END ====")


