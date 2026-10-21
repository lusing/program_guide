# -*- coding: utf-8 -*-
println("==== 23 hypothesis_testing")
# 第 23 章 Julia：假设检验的频率形态。
# ① t 分布随 ν 收敛到正态；② 大 p 值 ≠ H₀ 真；③ 两类错误
#    的模拟（已知真分布时 α 与 β 的频率验证）；④ 公平骰
#    60 投的 χ² 审计；⑤ Welch ν 的数值行为。
using Random, Statistics

Random.seed!(23)

# ① t(ν) → N(0,1)：t 样本 = Z/√(Y/ν)，Y ~ χ²(ν) = Gamma(ν/2, 2)
function sim_t(nu, n)
    out = zeros(n)
    for i in 1:n
        z = randn()
        y = randn() ^ 2                       # χ²(1) 的块
        for _ in 2:nu
            y += randn() ^ 2
        end
        out[i] = z / sqrt(y / nu)
    end
    out
end
function Phi_num(x)
    h = 0.005
    n = round(Int, abs(x) / h)
    s = sum(exp(-(i * h) ^ 2 / 2) for i in 0:n-1; init = 0.0)
    return x < 0 ? 0.5 - s * h / sqrt(2 * pi) : 0.5 + s * h / sqrt(2 * pi)
end
grid = -2.0:0.5:2.0
function maxdev(Z)
    m = 0.0
    for x in grid
        m = max(m, abs(count(<=(x), Z) / length(Z) - Phi_num(x)))
    end
    return m
end
d5 = maxdev(sim_t(5, 40_000))
d30 = maxdev(sim_t(30, 40_000))
@assert d30 < d5                               # ν 大更贴正态
@assert d30 < 0.02
println("t(nu) -> normal: KS dev shrinks from ", round(d5, digits=3),
        " to ", round(d30, digits=3), ": OK")

# ② 大 p 值：公平硬币 20 投，12 正面的 p（双侧）不拒绝
pval = sum(binomial(big(20), big(k)) for k in 0:8) + sum(binomial(big(20), big(k)) for k in 12:20)
pval = pval // big(2)^20
@assert 0.3 < Float64(pval) < 0.8              # 远大于 0.05：不拒绝
println("large p-value 0.5: fail to reject = fair coin compatible: OK")

# ③ 两类错误的模拟：真分布已知
# H0: mu=7000 (healthy); truth varies; threshold 9000; sigma=1000
alpha_emp = count(_ -> randn() * 1000 + 7000 > 9000, 1:200_000) / 200_000
@assert abs(alpha_emp - 0.0228) < 0.003        # P(Z>2)
beta_emp = count(_ -> randn() * 1500 + 11000 < 9000, 1:200_000) / 200_000
@assert abs(beta_emp - 0.0912) < 0.003
println("type I ", round(alpha_emp, digits=4), ", type II ", round(beta_emp, digits=4), ": OK")

# ④ 公平骰 60 投的 χ²：统计量应 ~ χ²(5)（均值 5、方差 10）
chis = Float64[]
for _ in 1:20_000
    counts = zeros(Int, 6)
    for _ in 1:60
        counts[rand(1:6)] += 1
    end
    push!(chis, sum((c - 10) ^ 2 / 10 for c in counts))
end
@assert abs(mean(chis) - 5) < 0.08             # χ²(5) 均值 5
@assert abs(var(chis) - 10) < 0.7              # 方差 2ν = 10
println("dice chi^2 audit: mean 5, var 10 = chi^2(5) moments: OK")

# ⑤ Welch ν 的行为（nx=14, ny=14 的睡眠数据）
sx2, sy2, nx, ny = 168.6, 73.32, 14, 14
nu = (sx2 / nx + sy2 / ny) ^ 2 / (sx2 ^ 2 / (nx ^ 2 * (nx - 1))
                                  + sy2 ^ 2 / (ny ^ 2 * (ny - 1)))
@assert abs(nu - 22.5) < 0.1
# 界：min(nx-1,ny-1) <= nu <= nx+ny-2
@assert 13 <= nu <= 26
println("welch nu = ", round(nu, digits=2), " between 13 and 26: OK")

println("END ====")
