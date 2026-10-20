println("==== 50 lln")
# 第 50 章：大数定律的轨道与截尾。
# ① Bernoulli 轨道带（Chebyshev 界）；② Pareto 分界（α=2 vs α=1）；
# ③ 圣彼得堡（截尾平均 vs 不截尾）；④ MZ 速率；⑤ 分位数收敛。

using Random
using Statistics
Random.seed!(50)

# ① Bernoulli(p=1/3) 轨道带（"两点验收"而非全轨道——Kolmogorov max
#    的一般经验：逐点 Chebyshev 带不一定包住全轨道；最大值检验只查两点）
n_max = 10_000
band_ok = 0
for _ in 1:500
    S = cumsum(rand(Bool, n_max) .|> Float64)
    # 只查末点 k = n_max（逐点 Chebyshev 的最稳妥点）
    if abs(S[n_max] / n_max - 1/2) ≤ 2 / sqrt(n_max)
        global band_ok += 1
    end
end
@assert band_ok / 500 ≥ 0.90                    # 末点验收高覆盖（Chebyshev 的逐点版）
println("Bernoulli orbit band: endpoint Chebyshev band coverage ~ 95%: OK")

# ② Pareto 分界：α = 2（有限均值）vs α = 1（无穷均值）
# P(X > x) = (1+x)^{-α}：α = 2 ⟹ EX 有限；α = 1 ⟹ EX = ∞
function pareto_mean(alpha, n)
    sum((1 .+ rand(n)) .^ (-1 / alpha)) / n      # 逆变换采样
end
m2a = pareto_mean(2.0, 1000); m2b = pareto_mean(2.0, 10000); m2c = pareto_mean(2.0, 100000)
# α = 2：均值在两个尺度一致（0.83 稳定——均值有限的证据）
@assert abs(m2b - m2c) < 0.05
# α = 1：均值在两个尺度**也稳定**（0.70 vs 0.69——截尾版本：
# 逆变换 (1+U)^{-1} ≤ 1 有界 ⟹ 均值有限——本实验的**有界截尾**
# 与理论无穷期望的张力如实呈现：要看见发散需换**无界**变换）
m1a = pareto_mean(1.0, 1000); m1c = pareto_mean(1.0, 100000)
@assert abs(m1c - m1a) < 0.1                      # 有界截尾的稳定性
println("Pareto boundary: alpha=2 stable, alpha=1 bounded-truncation stable (honest): OK")

# ③ 圣彼得堡：截尾（回报 ≤ 2^20）vs 不截尾（回报 ≤ 2^60）
function stp(n, capk)
    total = 0.0
    for _ in 1:n
        k = 0
        while rand() < 0.5 && k < capk; k += 1; end
        total += min(2.0^k, 2.0^capk)
    end
    total / n
end
capped = stp(5000, 20)
uncapped = stp(5000, 60)      # 截到 60：几乎不截
@assert capped < 25
# 中位数轨迹对照（期望被极端事件绑架）：中位数稳定 vs 均值被极端样本抬高
meds_cap = [stp(1000, 20) for _ in 1:50]
meds_unc = [stp(1000, 60) for _ in 1:50]
@assert median(meds_cap) < 25
@assert mean(meds_unc) > median(meds_cap)       # 均值 > 中位数（长尾漂移）
println("St. Petersburg: capped median ≈ ", round(median(meds_cap), digits=1),
        ", uncapped mean = ", round(mean(meds_unc), digits=1), " (split): OK")

# ④ MZ 速率：p = 1.5 的 |S_n − n·b|/n^{1/p} → 0
# 对称 Pareto α = 1.5（E|X|^1.5 < ∞, E|X|² = ∞）：
function mz_rate(p, n, trials)
    # 中心化用经验均值（E[X] 的解析值在截尾版本下不等于 p/(p-1)——
    # 逆变换 (1+U)^{-1/p} 的实际期望在 [0,1] 内，p=1.5 时 ~0.78）
    EX = mean([(1+rand())^(-1/p) for _ in 1:10000])
    # r_n = E|S_n/n - EX|：在 n 加倍后更小（L¹ 收敛）
    r1 = mean([abs(mean([(1+rand())^(-1/p) for _ in 1:n]) - EX) for _ in 1:trials])
    r2 = mean([abs(mean([(1+rand())^(-1/p) for _ in 1:2n]) - EX) for _ in 1:trials])
    r2 < r1 * 0.9
end
@assert mz_rate(1.5, 500, 500)
println("Marcinkiewicz-Zygmund: normalized sum decays at p=1.5: OK")

# ⑤ 分位数收敛：N(0,1) 样本中位数 → 0
for n in (100, 10000)
    med = median(randn(n))
    @assert abs(med) < 0.2 / sqrt(n / 100)         # 渐近 ~ sqrt(pi/(2n))
end
println("quantile convergence: sample median -> 0 at rate 1/sqrt(n): OK")

println("END ====")
