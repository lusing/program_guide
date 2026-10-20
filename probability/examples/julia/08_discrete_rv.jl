# -*- coding: utf-8 -*-
println("==== 08 discrete_rv")
# 第 08 章 Julia：离散随机变量的频率形态。
# ① 三硬币 8 路径枚举 → pmf 表与矩账；② 二项 pmf 的模拟
#    直方图（n = 10、p = 1/2，逐 k 对拍）；③ 概率树折层：
#    逐路径连乘再按 k 归并 = 二项 pmf（p = 0.3 一般情形）；
# ④ 两骰和的模拟 vs 三角形公式；⑤ CDF 阶梯 P(X ≤ 2) = 1/2。
using Random, Statistics

Random.seed!(8)

# 手写二项系数（无 Combinatorics 依赖）
binom(n, k) = k < 0 || k > n ? 0 : (k == 0 ? 1 : binom(n, k - 1) * (n - k + 1) ÷ k)

# ① 三硬币：枚举 8 个位模式，按正面数归并
function three_coin_pmf()
    counts = zeros(Int, 4)
    for bits in 0:7
        counts[count_ones(bits) + 1] += 1
    end
    counts ./ 8
end
pmf3 = three_coin_pmf()
@assert pmf3 ≈ [1/8, 3/8, 3/8, 1/8]
@assert sum(pmf3) ≈ 1
EX = sum((0:3) .* pmf3)
EX2 = sum((0:3) .^ 2 .* pmf3)
@assert EX ≈ 1.5                                # E[X] = 3/2
@assert EX2 ≈ 3.0                               # E[X²] = 3
@assert EX2 - EX^2 ≈ 0.75                       # Var = 3/4（第 10 章的伏笔）
println("three-coin pmf [1/8,3/8,3/8,1/8], E[X]=1.5, E[X2]=3: OK")

# ② 二项 pmf 模拟直方图：n = 10、p = 1/2
function sim_binom(n, p, trials)
    counts = zeros(Int, trials)
    for t in 1:trials
        c = 0
        for _ in 1:n
            rand() < p && (c += 1)
        end
        counts[t] = c
    end
    counts
end
counts10 = sim_binom(10, 0.5, 1_000_000)
for k in 0:10
    emp = count(==(k), counts10) / length(counts10)
    theo = binom(10, k) / 2^10
    @assert abs(emp - theo) < 0.002
end
@assert sum(binom(10, k) / 2^10 for k in 0:10) ≈ 1
println("binomial(10,1/2) histogram vs C(10,k)/1024, all |err|<0.002: OK")

# ③ 概率树折层：n = 6、p = 0.3，逐路径连乘再按 k 归并
function tree_fold_pmf(n, p)
    pmf = zeros(n + 1)
    for m in 0:2^n - 1
        k = count_ones(m)
        prob = 1.0
        for i in 0:n-1
            prob *= (m >> i) & 1 == 1 ? p : 1 - p
        end
        pmf[k + 1] += prob
    end
    pmf
end
pmf63 = tree_fold_pmf(6, 0.3)
for k in 0:6
    @assert abs(pmf63[k+1] - binom(6, k) * 0.3^k * 0.7^(6 - k)) < 1e-12
end
@assert sum(pmf63) ≈ 1
println("probability-tree fold = binomial pmf (n=6,p=0.3), exact to 1e-12: OK")

# ④ 两骰和：模拟 vs 三角形公式 (6-|r-7|)/36
sums = [rand(1:6) + rand(1:6) for _ in 1:500_000]
for r in 2:12
    emp = count(==(r), sums) / length(sums)
    theo = (6 - abs(r - 7)) / 36
    @assert abs(emp - theo) < 0.005
end
println("two-dice sum histogram vs triangle (6-|r-7|)/36: OK")

# ⑤ CDF 阶梯：n = 5、p = 1/2 的 P(X ≤ 2) = 1/2（对称中轴）
@assert sum(binom(5, k) for k in 0:2) / 32 ≈ 0.5
cs = sim_binom(5, 0.5, 500_000)
@assert abs(count(<=(2), cs) / length(cs) - 0.5) < 0.005
println("binomial(5,1/2) CDF at 2: exact 1/2, simulated match: OK")

println("END ====")
