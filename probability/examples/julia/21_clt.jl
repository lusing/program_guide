# -*- coding: utf-8 -*-
println("==== 21 clt")
# 第 21 章 Julia：CLT 的频率形态。
# ① 三族标准化和的经验 CDF vs Φ 的最大偏差随 n 衰减；② 1/√n
#    律（样本均值标准差 vs σ/√n）；③ 偏态指数的钟形化直方；
# ④ 连续性修正精度对比。
using Random, Statistics

Random.seed!(21)

function Phi_num(x)
    h = 0.005
    n = round(Int, abs(x) / h)
    if x < 0
        return 1 - Phi_num(-x)
    end
    s = 0.0
    for i in 0:n-1
        t = i * h
        s += exp(-t * t / 2)
    end
    return 0.5 + s * h / sqrt(2 * pi)   # 左矩形（粗但够用）
end

function max_dev(Z, grid)
    m = 0.0
    for x in grid
        emp = count(<=(x), Z) / length(Z)
        m = max(m, abs(emp - Phi_num(x)))
    end
    return m
end

# ① 三族最大偏差随 n 衰减
grid = -2.0:0.5:2.0
for (name, mu, sig, sampler) in [
        ("uniform", 0.5, sqrt(1 / 12), () -> rand()),
        ("exponential", -1.0, 1.0, () -> -randexp()),
        ("die", 3.5, sqrt(35 / 12), () -> float(rand(1:6)))]
    d10 = d1000 = 0.0
    for n in (10, 100, 1000)
        Z = [(sum(sampler() for _ in 1:n) - n * mu) / (sig * sqrt(n)) for _ in 1:20_000]
        d = max_dev(Z, grid)
        n == 10 && (d10 = d)
        n == 1000 && (d1000 = d)
    end
    @assert d1000 < d10                     # 首尾对照（中段被 MC 噪声淹没）
    @assert d1000 < 0.02                    # n=1000 已贴合
    println("CLT family ", name, ": max KS deviation shrinks to < 0.02: OK")
end

# ② 1/√n 律：Exp(1) 样本均值的标准差
for n in (10, 100, 1000)
    means = [sum(randexp() for _ in 1:n) / n for _ in 1:20_000]
    @assert abs(std(means) - 1 / sqrt(n)) < 0.02 / sqrt(n)
end
println("1/sqrt(n) law: std of sample mean matches sigma/sqrt(n): OK")

# ③ 偏态指数的钟形化：n=1 与 n=50 的四分位对照
q1 = [quantile([sum(randexp() for _ in 1:1) for _ in 1:50_000], q) for q in (0.25, 0.5, 0.75)]
q50 = [(quantile([sum(randexp() for _ in 1:50) for _ in 1:50_000], q) - 50) / sqrt(50)
       for q in (0.25, 0.5, 0.75)]
zq = [Phi_num(0.0) - 0.25, 0.0, 0.25]      # -0.674, 0, 0.674 的目标
@assert abs(q50[1] + 0.674) < 0.05 && abs(q50[2]) < 0.05 && abs(q50[3] - 0.674) < 0.05
println("skewed exponential: n=50 standardized quartiles at ±0.674: OK")

# ④ 连续性修正：Bin(100, 0.5) 的 P(45 <= S <= 55)
S = [sum(rand(0:1) for _ in 1:100) for _ in 1:100_000]
emp = count(s -> 45 <= s <= 55, S) / length(S)
no_corr = Phi_num(1.0) - Phi_num(-1.0)                # (45-50)/5, (55-50)/5
with_corr = Phi_num(1.1) - Phi_num(-1.1)              # ±5.5
@assert abs(emp - with_corr) < abs(emp - no_corr)
println("continuity correction: ", round(emp, digits=4),
        " vs corrected ", round(with_corr, digits=4), ": OK")

println("END ====")
