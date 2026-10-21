# -*- coding: utf-8 -*-
println("==== 16 gamma")
# 第 16 章 Julia：Γ 分布族与 Cauchy 的频率形态。
# ① Gamma(k=2,σ=3) 采样矩 vs 6/18；② k=1 退化为指数的
#    直方对照；③ Weibull k=1 vs 指数、k=2 分位数表；
# ④ Cauchy 稳定性现场（和的一半仍 Cauchy；样本均值发散）。
using Random, Statistics

Random.seed!(16)

# Gamma 采样：k 整数 = Erlang（k 个 Exp(σ) 之和）
myexp(λ) = -λ * log(rand())
sim_gamma(k, σ) = sum(myexp(σ) for _ in 1:k)

# ① k=2, σ=3：μ=6、σ²=18
G = [sim_gamma(2, 3.0) for _ in 1:400_000]
@assert abs(mean(G) - 6) < 0.04
@assert abs(var(G) - 18) < 0.4
println("gamma(2,3): mean 6, var 18 by sampling: OK")

# ② k=1 退化为 Exp(σ)：分位数对照
E1 = [sim_gamma(1, 2.5) for _ in 1:300_000]
for q in (0.25, 0.5, 0.75)
    @assert abs(quantile(E1, q) - (-2.5 * log(1 - q))) < 0.06
end
println("gamma(1, sigma) = exponential: quantiles match -sigma*log(1-q): OK")

# ③ Weibull(k, σ)：F(x) = 1 − e^{−(x/σ)^k} → x_q = σ(−log(1−q))^{1/k}
sim_weibull(k, σ) = σ * (-log(rand())) ^ (1 / k)
for k in (1.0, 2.0)
    W = [sim_weibull(k, 3.0) for _ in 1:300_000]
    for q in (0.5, 0.9)
        theo = 3.0 * (-log(1 - q)) ^ (1 / k)
        @assert abs(quantile(W, q) - theo) < 0.05 * theo
    end
end
println("weibull k=1 (exp) and k=2 (rayleigh-ish) quantiles: OK")

# ④ Cauchy 稳定性：X、Y 独立 Cauchy → (X+Y)/2 仍 Cauchy
cauchy() = tan(pi * (rand() - 0.5))
C1 = [cauchy() for _ in 1:200_000]
Ch = [(cauchy() + cauchy()) / 2 for _ in 1:200_000]
for thr in (1.0, 5.0, 20.0)
    e1 = count(t -> abs(t) <= thr, C1) / length(C1)
    e2 = count(t -> abs(t) <= thr, Ch) / length(Ch)
    theo = 2 / pi * atan(thr)
    @assert abs(e1 - theo) < 0.005
    @assert abs(e2 - theo) < 0.005          # 同一分布：稳定但方差无穷
end
# 样本均值不收敛：前/后半均值天差地别（cumsum 免软作用域）
Cs = [cauchy() for _ in 1:100_000]
running = cumsum(Cs)
means = [running[50_000] / 50_000, running[100_000] / 100_000]
@assert abs(means[1] - means[2]) > 0.1      # 两段"均值"几乎必然不同
println("cauchy: (X+Y)/2 same quantiles (stable); running mean drifts: OK")

println("END ====")
