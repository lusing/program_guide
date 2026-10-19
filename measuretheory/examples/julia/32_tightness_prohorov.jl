println("==== 32 tightness_prohorov")
# 第 32 章：胎紧与非胎紧的账本对照。
# ① 一致矩 ⟹ 紧吸收（Chebyshev 一致账）；
# ② δₙ 非胎紧（一致下界破产）；
# ③ 对角线现场（球账同时收敛的子列）；
# ④ 矩逃逸反例（N(0,n)）。

# ① 一致矩：σₙ ≤ 2 的正态族
for M in (4.0, 8.0, 16.0)
    worst = 0.0
    for σ in (0.5, 1.0, 1.5, 2.0)
        tail = exp(-M^2 / (2σ^2))                  # P(|X| > M) ≤ exp(-M²/2σ²)（Chebyshev 更粗的精确正态尾）
        cheb = σ^2 / M^2                           # Chebyshev 上界
        @assert tail ≤ cheb + 1e-12                # 精确尾 ≤ Chebyshev（引擎正确性）
        worst = max(worst, cheb)
    end
    @assert worst ≤ 4 / M^2                        # 一致下界：吸收 ≥ 1 − 4/M²
end
println("uniform second moments -> uniform compact absorption (Chebyshev): OK")

# ② δₙ 非胎紧：固定 M 的一致下界 = 0
for M in (10.0, 1000.0)
    @assert 0.0 == minimum((n ≤ M) ? 1.0 : 0.0 for n in (1, 10, 100, 10^6))
end
println("delta_n: uniform absorption fails (inf over family = 0): OK")

# ③ 对角线：5 列漂移在 20 个球上的同时收敛子列
using Random
Random.seed!(32)
drifts(k) = 0.5 * sin(k) + 0.1 * sum(cos(k * j) for j in 1:5)
balls = vec([(c, r) for c in (-1.0, 0.0, 1.0), r in (0.3, 0.7)])
inball(k, c, r) = abs(drifts(k)[1] - c) < r
# 抽取子列：k 使 drifts(k)[1] 收敛（sin(k) 有收敛子列——聚点）
target = sin(42)
sub = [k for k in 1:200000 if abs(sin(k) - target) < 0.005]
@assert length(sub) > 200
vals = [inball(sub[1], c, r) for (c, r) in balls]
@assert all(j -> [inball(sub[j], c, r) for (c, r) in balls] == vals, 1:min(40, length(sub)))
println("diagonal extraction: synchronized ball accounts (", length(sub), " members): OK")

# ④ 矩逃逸：N(0,n) 的二阶矩 = n → ∞ 且尾界 σ²/M² = n/M² 破产
for n in (200, 1000)
    @assert n / 10^2 > 1.0                         # Chebyshev 界 > 1（失去控制）当 n ≥ M²
end
println("moment escape N(0,n): Chebyshev bound blows up, no tightness: OK")

println("END ====")
