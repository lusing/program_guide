println("==== 46 minlos")
# 第 46 章：白噪声与 Brown 实现。
# ① 白噪声柱面（换基不变）；② Brown 增量独立/方差；
# ③ 正则性恶化；④ Poisson 噪声。

using Random, Statistics
Random.seed!(46)

# ① 白噪声柱面
n = 200
W = randn(n)
# 协方差 ≈ 单位阵（白噪声的恒等协方差）
@assert abs(var(W) - 1.0) < 0.15
println("white noise sample: variance ~ 1 (identity covariance): OK"

)
# ② Brown 实现：累积和（Δt = 1/n 的缩放）
function brown_path(n)
    dt = 1.0 / n
    cumsum(sqrt(dt) .* randn(n))
end
B = brown_path(2000)
# 增量方差 ∝ Δt：Var(B_t) = t（末值 B[end] ~ N(0,1)）
ends = [brown_path(2000)[end] for _ in 1:3000]
@assert abs(var(ends) - 1.0) < 0.08              # Var(B_1) = 1
println("Brownian path: Var(B_1) = 1 (variance proportional to t): OK"

)
# 增量独立：不相邻段协方差 ~ 0
function incr_pairs(m)
    half = 1000
    [(begin B = brown_path(2000); (B[half] - B[1], B[end] - B[half]) end) for _ in 1:m]
end
pr = incr_pairs(20000)
cov_est = cor(first.(pr), last.(pr))
@assert abs(cov_est) < 0.05
println("Brown increments: correlation of disjoint segments ~ 0: OK")

# ③ 正则性恶化：截断维数 → 连续模增长
for n in (50, 200, 800)
    W = randn(n)
    mod = maximum(abs.(diff(W)))
    @assert mod > 1.5                              # 噪声跳跃恒在（不连续）
end
println("regularity degradation: white noise jumps persist (not continuous): OK")

# ④ Poisson 噪声：复合 Poisson 采样的 charFn
function poisson_charfn(t, lam; N = 4000)
    # N(0,1) 跳幅的 compound Poisson：E e^{itS} = exp(λ(E e^{itZ} - 1))
    vals = ComplexF64[]
    for _ in 1:N
        # Poisson(λ) 的自制采样（小 λ 的 Bernoulli 组合：100 格 p = λ/100）
        K = sum(rand() < lam / 100 for _ in 1:100)
        S = K == 0 ? 0.0 : sum(randn() for _ in 1:K)
        push!(vals, exp(im * t * S))
    end
    mean(vals)
end
for t in (0.3, 1.0)
    est = poisson_charfn(t, 2.0)
    closed = exp(2.0 * (exp(-t^2 / 2) - 1))        # E e^{itZ} = e^{-t²/2}
    @assert abs(est - closed) < 0.03
end
println("Poisson noise charFn: compound sampling vs LK closed form: OK")

println("END ====")
