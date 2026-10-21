# -*- coding: utf-8 -*-
println("==== 18 inequalities_lln")
# 第 18 章 Julia：不等式与大数定律的频率形态。
# ① Markov 界紧度扫描（两点分布在阈值处贴等号）；② Chebyshev
#    k=2/5/10 的经验频率 vs 1/k² vs 正态真值；③ WLLN 现场实验
#    （P(|X̄−μ|≥ε) 随 n 的实测 vs σ²/nε² 界）；④ 强定律路径现场。
using Random, Statistics

Random.seed!(18)

# ① Markov 紧度：两点分布 P(X=a)=μ/a、P(X=0)=1−μ/a 在阈值 a
#    处贴等号 P(X≥a) = μ/a（其他分布则远低于界）
mu = 2.0
for a in (4.0, 10.0)
    # 贴界分布
    p = mu / a
    X = [rand() < p ? a : 0.0 for _ in 1:400_000]
    emp = count(>=(a), X) / length(X)
    @assert abs(emp - p) < 0.003                   # P(X>=a) ≈ μ/a = 界本身
    # 指数分布 Exp(μ)（远低于界）
    E = [mu * randexp() for _ in 1:200_000]
    empE = count(>=(a), E) / length(E)
    @assert empE < mu / a                          # 严格低于
    @assert empE < (mu / a) * 0.3                  # 且明显低于（a=4 时 e^-2≈0.135 < 0.15）
end
println("markov tightness: two-point hits bound; exp far below: OK")

# ② Chebyshev vs 真值（正态总体）
Z = randn(2_000_000)
for (k, bound) in [(2, 0.25), (5, 0.04), (10, 0.01)]
    emp = count(z -> abs(z) >= k, Z) / length(Z)
    @assert emp < bound                            # 界成立
    @assert emp < bound * 0.2                      # 正态远低于界
end
println("chebyshev: normal far below 1/k^2 for k=2,5,10: OK")

# ③ WLLN 现场：Exp(1) 样本均值偏离 ε=0.1 的概率
for (n, reps) in ((100, 50_000), (1_000, 20_000), (10_000, 4_000))
    hits = 0
    for _ in 1:reps
        s = sum(randexp() for _ in 1:n) / n
        abs(s - 1.0) >= 0.1 && (hits += 1)
    end
    emp = hits / reps
    bound = 1.0 / (n * 0.1^2)
    @assert emp < bound                            # Chebyshev 界成立
    n >= 1000 && @assert emp < bound * 0.5         # 真值远低于界
end
println("WLLN: deviation probability decays, bounded by sigma^2/(n eps^2): OK")

# ④ 强定律路径现场：几条 X̄_n 轨迹都收敛到 μ=1（Exp）
println("SLLN paths (running mean at checkpoints, mu=1):")
for path in 1:3
    s = 0.0
    marks = Float64[]
    for i in 1:100_000
        s += randexp()
        (i in (10, 1_000, 100_000)) && push!(marks, s / i)
    end
    @assert abs(marks[3] - 1.0) < 0.05             # 终点贴 μ
    println("  path ", path, ": ", round.(marks, digits=4))
end

println("END ====")
