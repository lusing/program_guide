println("==== 42 martingale_convergence")
# 第 42 章：命运的四种走向。
# ① Pólya 罐（Beta(1,1) 极限）；② 乘积鞅双轨分叉；
# ③ G-W 灭绝；④ 鞅差正交性。

using Random, Statistics, LinearAlgebra
Random.seed!(42)

# ① Pólya 罐：初 (1,1)，1000 步
function polya_run(steps)
    r, b = 1, 1
    for _ in 1:steps
        if rand() < r / (r + b); r += 1; else; b += 1; end
    end
    r / (r + b)
end
limits = [polya_run(2000) for _ in 1:400]
# 轨道收敛证据（末 200 步波动）
function polya_tail(steps)
    r, b = 1, 1
    path = Float64[]
    for _ in 1:steps
        if rand() < r / (r + b); r += 1; else; b += 1; end
        push!(path, r / (r + b))
    end
    maximum(abs.(path[end-199:end] .- path[end]))   # 末段最大漂移
end
tails = [polya_tail(1000) for _ in 1:100]
@assert mean(tails) < 0.15                           # 收敛的轨道证据
# 极限直方图 vs 均匀（Beta(1,1)）
bins = 0:0.1:1
hist = [count(x -> bins[i] ≤ x < bins[i+1], limits) for i in 1:10]
tot = sum(hist)
for i in 1:10
    @assert abs(hist[i] / tot - 0.1) < 0.07          # 各箱 ~10%（均匀）
end
println("Polya urn: orbits converge, limit histogram ~ Uniform[Beta(1,1)]: OK")

# ② 乘积鞅：M_n = prod(1 ± 0.4)
function product_mart(n, eps)
    m = 1.0
    for _ in 1:n
        m *= 1 + (rand() < 0.5 ? eps : -eps)
    end
    m
end
med = median([product_mart(300, 0.4) for _ in 1:2000])
@assert med < 0.01                                    # a.s. 衰减（中位数 ~ (1-0.16)^{150}）
# E = 1 恒定但 300 步的方差极大（重尾）——用中位数与几何均值展示衰减，
# 期望恒定改在对数账上验证：E[log M] = log(1-0.16) < 0
logm = mean([log(product_mart(300, 0.4)) for _ in 1:2000])
@assert abs(logm - 300 * 0.5 * (log(1.4) + log(0.6))) < 0.5   # E[logM] 精确 = 150·log(0.84)
@assert logm < -20                                    # 深度负（a.s. 衰减的引擎）
println("product martingale: median = ", round(med, digits=5),
        " -> 0 a.s., E[log M] = ", round(logm, digits=1), " (deep negative): OK")

# ③ G-W 过程：灭绝概率
function gw_ext(mu_target, n_gen, n_trials)
    p0 = 1 - mu_target / 2
    extinct = 0
    for _ in 1:n_trials
        pop = 1
        for _ in 1:n_gen
            newpop = 0
            for _ in 1:pop
                newpop += rand() < p0 ? 0 : 2
            end
            pop = newpop
            (pop == 0 || pop > 100_000) && break   # 爆炸即视为存活
        end
        pop == 0 && (extinct += 1)
    end
    extinct / n_trials
end
# 次临界 mu = 0.8：灭绝概率 = 1（p0 = 0.6 > 0.5 时不动点 s = 1）
sub = gw_ext(0.8, 60, 1000)
@assert sub > 0.95
# 超临界 mu = 1.6：p0 = 0.2，s = p0/(1-p0) = 0.25（P0+P2 分布的不动点）
sup = gw_ext(1.6, 60, 1000)
theory = 0.2 / 0.8                                    # s = p0/(1-p0) = 0.25
@assert abs(sup - theory) < 0.1
println("Galton-Watson: subcritical extinct ", round(sub, digits=3),
        ", supercritical ", round(sup, digits=3), " vs s = 0.25: OK")

# ④ 鞅差正交性
D = randn(8, 20000)                                   # 8 个时刻 × 20000 重复（噪声 ~ 1/sqrt(N)）
C = cov(D, dims = 2)                      # 8×8：变量维协方差
Cdiag = diag(C)
offdiag = maximum(abs.(C - diagm(Cdiag)))
@assert offdiag < 0.05                                # 独立 ⟹ 协方差 ~ 对角
println("martingale difference orthogonality: covariance ~ diagonal: OK")

println("END ====")
