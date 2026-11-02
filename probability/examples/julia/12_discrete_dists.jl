# -*- coding: utf-8 -*-
println("==== 12 discrete_dists")
# 第 12 章 Julia：离散分布族的频率形态。
# ① 五族模拟对拍（Geometric 1/p、NegBin rp/(1−p)、Poisson
#    均值=方差=λ）；② Poisson P(≥1) ≈ 0.283；③ German Tank
#    大规模模拟（N=200, k=5）；④ 二项→Poisson 极限的逐点误差
#    与总变差距离（pmf 递推，确定性计算）。
using Random, Statistics

Random.seed!(13)

# ① Geometric(p)：首次成功的等待数
function sim_geometric(p, trials)
    waits = zeros(Int, trials)
    for t in 1:trials
        n = 1
        while rand() > p
            n += 1
        end
        waits[t] = n
    end
    waits
end
G = sim_geometric(0.25, 200_000)
@assert abs(mean(G) - 4.0) < 0.02                    # 1/p = 4
@assert abs(var(G) - 0.75 / 0.25^2) < 0.2            # (1−p)/p² = 12
println("geometric(1/4): mean≈4, var≈12: OK")

# NegBin(r=3, p=0.7)：第 3 次失败前的成功数
function sim_negbin(r, p, trials)
    ks = zeros(Int, trials)
    for t in 1:trials
        succ, fail = 0, 0
        while fail < r
            if rand() < p; succ += 1; else; fail += 1; end
        end
        ks[t] = succ
    end
    ks
end
NB = sim_negbin(3, 0.7, 200_000)
@assert abs(mean(NB) - 3 * 0.7 / 0.3) < 0.06         # rp/(1−p) = 7
println("negbin(3, .7): mean≈7 = rp/(1-p): OK")

# Poisson(λ)：均值 = 方差 = λ（指纹）
function sim_poisson(lam, trials)
    out = zeros(Int, trials)
    for t in 1:trials
        L, k = exp(-lam), 0
        prob = rand()
        while prob > L
            k += 1
            L += lam^k / factorial(k) * exp(-lam)
        end
        out[t] = k
    end
    out
end
# 更快的乘法版
function sim_poisson2(lam, trials)
    out = zeros(Int, trials)
    for t in 1:trials
        L, k, p = exp(-lam), 0, 1.0
        while true
            p *= rand()
            if p < L
                break
            end
            k += 1
        end
        out[t] = k
    end
    out
end
P = sim_poisson2(2.0, 300_000)
@assert abs(mean(P) - 2.0) < 0.02
@assert abs(var(P) - 2.0) < 0.05                     # 均值=方差=λ
println("poisson(2): mean≈var≈2 (fingerprint): OK")

# ② 邮局：λ = 1/3，P(至少一人) = 1 − e^{−1/3} ≈ 0.283
PO = sim_poisson2(1 / 3, 300_000)
emp = count(>(0), PO) / length(PO)
@assert abs(emp - (1 - exp(-1 / 3))) < 0.003
println("post office P(>=1) ≈ 1 - e^{-1/3} = ", round(1 - exp(-1/3), digits=4), ": OK")

# ③ German Tank：N = 200, k = 5；估计量 N̂ = (k+1)/k·m − 1
N_true, k_obs, reps = 200, 5, 50_000
ests = zeros(reps)
for i in 1:reps
    m = maximum(randperm(N_true)[1:k_obs])
    ests[i] = (k_obs + 1) / k_obs * m - 1
end
@assert abs(mean(ests) - N_true) < 3                 # 无偏性
println("german tank N=200,k=5: mean estimate ≈ ", round(mean(ests), digits=1),
        " (median ≈ ", round(median(ests), digits=1),
        " 偏高——无偏的是均值): OK")

# ④ 二项 → Poisson：固定 λ = 2，p = λ/n，用 pmf 递推逐点比较
#    b(k+1) = b(k)·(n−k)/(k+1)·p/(1−p)，π(k+1) = π(k)·λ/(k+1)
function binom_pmf(n, p)
    b = zeros(n + 1)
    b[1] = (1 - p)^n
    for k in 0:n-1
        b[k + 2] = b[k + 1] * (n - k) / (k + 1) * p / (1 - p)
    end
    b
end
function pois_pmf(lam, K)
    π_ = zeros(K + 1)
    π_[1] = exp(-lam)
    for k in 0:K-1
        π_[k + 2] = π_[k + 1] * lam / (k + 1)
    end
    π_
end
lam = 2.0
tv = Float64[]
for n in (10, 100, 1000)
    b = binom_pmf(n, lam / n)
    @assert abs(sum(b) - 1) < 1e-12
    K = n
    π_ = pois_pmf(lam, K)
    # 总变差 = ½ Σ|b(k) − π(k)|，Poisson 在 k > n 上的质量另计
    tail = 1 - sum(π_)
    push!(tv, 0.5 * (sum(abs.(b .- π_)) + tail))
end
@assert tv[1] > tv[2] > tv[3]                   # 单调趋于 0
@assert tv[3] < 1e-3                            # 实测 TV ≈ 0.45/n，远小于界 4/n
@assert all(tv .< lam^2 ./ [10, 100, 1000])     # Le Cam：TV ≤ n·p² = λ²/n
println("binomial -> poisson TV distances (n=10,100,1000): ",
        round.(tv, sigdigits=3), " < lambda^2/n (Le Cam): OK")

println("END ====")
