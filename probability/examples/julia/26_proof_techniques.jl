# -*- coding: utf-8 -*-
println("==== 26 proof_techniques")
# 第 26 章 Julia：证明式的频率形态。
# ① 推广特例式：先算 F 比值猜 φ；② 对称性的模拟验证；③ 蛮力
#    vs 闭式赛跑；④ 反例的频率确认（Cov = 0 但相关）。
using Random, Statistics

Random.seed!(26)

# ① 推广特例：先算 F_{n+1}/Fₙ 的序列，猜极限 φ（函数封装免软作用域）
fib_ratios(k) = begin
    a, b = big(0), big(1)
    out = Float64[]
    for _ in 1:k
        a, b = b, a + b
        push!(out, Float64(b / a))
    end
    out
end
ratios = fib_ratios(30)
phi = (1 + sqrt(5)) / 2
@assert abs(ratios[5] - phi) < 0.05                 # 第 5 项已在附近
@assert abs(ratios[30] - phi) < 1e-12               # 收敛
println("generalize from examples: F ratios -> phi = ", round(phi, digits=6), ": OK")

# ② 对称性：对称密度的样本均值贴对称中心
for center in (3.0, -2.5)
    X = [center + (rand() - 0.5) * 2 for _ in 1:500_000]   # Unif(center±1)
    @assert abs(mean(X) - center) < 0.002
end
println("symmetry: sample mean pins the center of symmetric density: OK")

# ③ 蛮力 vs 闭式赛跑：C(2n,n) 枚举 vs 闭式 4ⁿ/√(πn)
for n in (5, 10)
    exact = binomial(big(2n), big(n))
    closed = 4.0 ^ n / sqrt(pi * n)
    @assert abs(Float64(exact) / closed - 1) < 3 / n        # 相对误差 ~ 1/(8n)
end
println("brute vs closed: C(2n,n) matches 4^n/sqrt(pi n) with 1/(8n) error: OK")

# ④ 反例的频率确认：X 均匀 {−2,−1,1,2}、Y = X²
X = [rand([-2.0, -1.0, 1.0, 2.0]) for _ in 1:400_000]
Y = X .^ 2
@assert abs(mean(X)) < 0.005                              # E[X] = 0
@assert abs(mean(X .* Y)) < 0.03                          # E[X³]=0（X⁶ 的样本噪声地板 ~0.009）
@assert abs(cov(X, Y)) < 0.02                             # Cov ≈ 0
# 但 X 与 Y 完全相关于 |X|：给定 X，Y 唯一确定（频率侧：条件方差 = 0）
for xval in (-2.0, -1.0, 1.0, 2.0)
    mask = X .== xval
    @assert var(Y[mask]) < 1e-20                          # Y 是 X 的函数
end
println("counterexample: cov ~ 0 yet Y = f(X) exactly (cond var = 0): OK")

println("END ====")
