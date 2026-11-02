# -*- coding: utf-8 -*-
println("==== 13 continuous_dists")
# 第 13 章 Julia：连续分布族的频率形态。
# ① 三角形密度模拟 vs 分段公式；② n=8 均匀和 vs 正态
#    N(4, 8/12)（CLT 先声）；③ 指数 μ=λ、σ²=λ² 模拟；
# ④ Erlang n=2/8/30 vs 密度与正态近似（n=30 仍偏）；
# ⑤ 足球 e^{−3/2}；⑥ 逆变换采样直方图 vs 密度；
# ⑦ Gamma；⑧ Weibull；⑨ Cauchy 稳定性（与第 14 章呼应）。
using Random, Statistics

Random.seed!(13)

# ① 三角形：Z = X+Y（独立 Unif(0,1)）
tri(z) = 0 <= z <= 1 ? z : (1 < z <= 2 ? 2 - z : 0.0)
Z = rand(800_000) .+ rand(800_000)
for (lo, hi) in [(0.0, 0.5), (0.5, 1.0), (1.0, 1.5)]
    emp = count(x -> lo <= x <= hi, Z) / length(Z)
    theo = begin
        q(z) = z <= 1 ? z * z / 2 : 1 - (2 - z)^2 / 2
        q(hi) - q(lo)
    end
    @assert abs(emp - theo) < 0.004
end
println("triangle density: simulated vs piecewise CDF: OK")

# ② n = 8 均匀和 vs N(4, 8/12)：均值方差桶账
S8 = [sum(rand(8)) for _ in 1:300_000]
@assert abs(mean(S8) - 4) < 0.01
@assert abs(var(S8) - 8 / 12) < 0.01
# 中心区 P(3.5 ≤ S ≤ 4.5) 的正态近似质量（Simpson 免 erf）
# 偏差 ~0.007 是 CLT 近似的真实误差（均匀峰度 −1.2/8 的中心
# 效应），非模拟噪声——"极好拟合"仍留 0.7% 的中心差。
c = count(x -> 3.5 <= x <= 4.5, S8) / length(S8)
v = 8 / 12
phi(x) = exp(-(x - 4)^2 / (2 * v)) / sqrt(2 * pi * v)
h = 0.01
theo = (h / 3) * (phi(3.5) + phi(4.5)
    + sum((i % 2 == 0 ? 2 : 4) * phi(3.5 + i * h) for i in 1:99))
@assert abs(c - theo) < 0.012
println("sum of 8 uniforms: mean 4, var 8/12; center mass ", round(c, digits=4),
        " vs normal ", round(theo, digits=4), " (CLT error ~0.7%): OK")

# ③ 指数 λ = 2.5
myexp(λ) = -λ * log(rand())
X = [myexp(2.5) for _ in 1:500_000]
@assert abs(mean(X) - 2.5) < 0.02
@assert abs(var(X) - 6.25) < 0.15
println("exp(2.5): mean 2.5, var 6.25 = lambda^2: OK")

# ④ Erlang(1, n)：和的均值 n、方差 n
for n in (2, 8, 30)
    S = [sum(myexp(1.0) for _ in 1:n) for _ in 1:150_000]
    @assert abs(mean(S) - n) < 0.03 * n
    @assert abs(var(S) - n) < 0.04 * n
end
println("erlang n=2/8/30: mean=n, var=n: OK")

# ⑤ 足球：Exp(30 分钟) 上半场无球 e^{−1.5}
goals = [myexp(30.0) for _ in 1:500_000]
emp = count(>(45), goals) / length(goals)
@assert abs(emp - exp(-1.5)) < 0.004
println("soccer: P(no goal in 45min) ≈ e^{-1.5} = ", round(exp(-1.5), digits=4), ": OK")

# ⑥ 逆变换采样：经验分位数 vs −λ log(1−q)
Y = [myexp(3.0) for _ in 1:200_000]
@assert all(abs(quantile(Y, q) - (-3.0 * log(1 - q))) < 0.05
            for q in (0.25, 0.5, 0.75))
println("inverse transform: quantiles match -lambda*log(1-q): OK")

# ⑦ Gamma 族（原 13_gamma.jl 并入）：k 整数的 Gamma 即 Erlang
sim_gamma(k, σ) = sum(myexp(σ) for _ in 1:k)
G = [sim_gamma(2, 3.0) for _ in 1:400_000]
@assert abs(mean(G) - 6) < 0.04
@assert abs(var(G) - 18) < 0.4
println("gamma(2,3): mean 6, var 18 by sampling: OK")

E1 = [sim_gamma(1, 2.5) for _ in 1:300_000]
for q in (0.25, 0.5, 0.75)
    @assert abs(quantile(E1, q) - (-2.5 * log(1 - q))) < 0.06
end
println("gamma(1, sigma) = exponential: quantiles match -sigma*log(1-q): OK")

# ⑧ Weibull(k, σ)：F(x) = 1 − e^{−(x/σ)^k} → x_q = σ(−log(1−q))^{1/k}
sim_weibull(k, σ) = σ * (-log(rand())) ^ (1 / k)
for k in (1.0, 2.0)
    W = [sim_weibull(k, 3.0) for _ in 1:300_000]
    for q in (0.5, 0.9)
        xq = 3.0 * (-log(1 - q)) ^ (1 / k)
        @assert abs(quantile(W, q) - xq) < 0.05 * xq
    end
end
println("weibull k=1 (exp) and k=2 (rayleigh-ish) quantiles: OK")

# ⑨ Cauchy 稳定性：X、Y 独立 Cauchy → (X+Y)/2 仍 Cauchy
cauchy() = tan(pi * (rand() - 0.5))
C1 = [cauchy() for _ in 1:200_000]
Ch = [(cauchy() + cauchy()) / 2 for _ in 1:200_000]
for thr in (1.0, 5.0, 20.0)
    e1 = count(t -> abs(t) <= thr, C1) / length(C1)
    e2 = count(t -> abs(t) <= thr, Ch) / length(Ch)
    cdf_c = 2 / pi * atan(thr)
    @assert abs(e1 - cdf_c) < 0.005
    @assert abs(e2 - cdf_c) < 0.005          # 同一分布：稳定但方差无穷
end
Cs = [cauchy() for _ in 1:100_000]
running = cumsum(Cs)
means = [running[50_000] / 50_000, running[100_000] / 100_000]
@assert abs(means[1] - means[2]) > 0.1      # 两段"均值"几乎必然不同
println("cauchy: (X+Y)/2 same quantiles (stable); running mean drifts: OK")

println("END ====")
