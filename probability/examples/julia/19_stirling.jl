# -*- coding: utf-8 -*-
println("==== 19 stirling")
# 第 19 章 Julia：Stirling 的频率与数值形态。
# ① 误差幂律的 log-log 斜率（−1 与 −2）；② 2n 掷币恰 n 正面
#    的模拟 vs 1/√(πn)；③ S₂N 格点分布 vs 正态密度（CLT 特例）；
# ④ σ = √n/2 的活动窗质量摊薄。
using Random, Statistics

Random.seed!(19)

# ① 误差幂律：log(err) vs log(n) 的斜率
using Printf
ns = [10.0 ^ k for k in 1:4]        # 修正项误差在 n>10³ 后低于求和精度地板
errs0 = Float64[]
errs1 = Float64[]
for n in ns
    ni = round(Int, n)
    exact = sum(log, 1.0:ni)          # 无 SpecialFunctions：逐项求和（精度 1e-10 级）
    approx0 = ni * log(ni) - ni + log(2 * pi * ni) / 2
    approx1 = approx0 + log1p(1 / (12 * ni))
    push!(errs0, abs(exp(approx0 - exact) - 1))
    push!(errs1, abs(exp(approx1 - exact) - 1))
end
# 斜率 ≈ −1（主式）与 ≈ −2（修正）：首尾两点估计
slope0 = log(errs0[end] / errs0[1]) / log(ns[end] / ns[1])
slope1 = log(errs1[end] / errs1[1]) / log(ns[end] / ns[1])
@assert abs(slope0 + 1) < 0.05
@assert abs(slope1 + 2) < 0.1
@printf("error laws: slope(raw) = %.3f, slope(corrected) = %.3f: OK\n", slope0, slope1)

# ② 2n 掷币恰 n 正面：模拟 vs 1/√(πn)
for n in (50, 200)
    trials = 200_000
    hits = 0
    for _ in 1:trials
        h = 0
        for _ in 1:2n
            rand() < 0.5 && (h += 1)
        end
        h == n && (hits += 1)
    end
    emp = hits / trials
    theo = 1 / sqrt(pi * n)
    @assert abs(emp - theo) < 0.001
end
println("2n coins exactly-n heads: empirical vs 1/sqrt(pi n): OK")

# ③ CLT 特例：S₂N = X₁+⋯+X₂N（±1）的格点分布 vs N(0, 2N)
N = 100
Ks = -30:30                                     # S = 2k 的 k 范围
probs = [binomial(big(2N), big(N + k)) // big(2)^(2N) for k in Ks]
# 模拟对照（格点 2k 上的概率 vs 正态密度×格距 2）
trials = 300_000
counts = zeros(Int, length(Ks))
for _ in 1:trials
    s = 0
    for _ in 1:2N
        s += rand() < 0.5 ? 1 : -1
    end
    k = s ÷ 2
    -30 <= k <= 30 && (counts[k + 31] += 1)
end
for i in 11:21                                  # 中心区 |k| ≤ 10
    emp = counts[i] / trials
    k = Ks[i]
    dens = exp(-k^2 / N) / sqrt(pi * N)         # Stirling 推导的格点公式
    @assert abs(emp - dens) < 0.002
end
println("CLT special case: S_2N lattice probs match e^{-k^2/N}/sqrt(pi N): OK")

# ④ 活动窗摊薄：σ = √(n/2)（二项 2n·¼），±2σ 窗概率 ~95%，
#    单点概率 ~ 1/√(πn) → 0（窗在长、点在瘦）
window_mass(n, reps) = begin
    inside = 0
    for _ in 1:reps
        h = 0
        for _ in 1:2n
            rand() < 0.5 && (h += 1)
        end
        abs(h - n) <= sqrt(2n) && (inside += 1)  # ±2σ 窗（σ=√(n/2)）
    end
    inside / reps
end
for n in (50, 400)
    m = window_mass(n, 100_000)
    @assert abs(m - 0.95) < 0.02    # 离散格的连续性修正余量
end
println("±2-sigma window holds ~95% while point prob -> 0: OK")

println("END ====")
