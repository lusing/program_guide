println("==== 06 approximation")

# 第 06 章：测度的逼近——生成代数上的逼近与唯一性。
# 在 [0,1) 上用二进代数 D_d（深度 d 的二进区间并）逼近
# Lebesgue 可测集的测度；并演示"在生成系上相等 ⟹ 测度相等"。

using Random, Printf
Random.seed!(23)

# 目标集：斜坡加权——A = [0, 0.3) ∪ [0.5, 0.7)，真测度 0.5
function in_target(x)
    (x < 0.3) || (0.5 <= x < 0.7)
end
true_mu = 0.3 + 0.2

# 深度 d 的二进代数逼近：把网格点按隶属标记，取外/内逼近
function approx_measure(f, d)
    n = 2^d
    inside = sum(f((i - 0.5) / n) for i in 1:n)   # 中点采样
    inside / n
end

println("二进代数逼近 μ(A)：")
prev_err = Inf
for d in 3:14
    est = approx_measure(in_target, d)
    err = abs(est - true_mu)
    @printf("  深度 %2d：估计 %.8f，误差 %.2e\n", d, est, err)
end
# 边界点 0.3、0.5、0.7 落在网格上时会带 O(2^{-d}) 抖动，但总体收敛
est12 = approx_measure(in_target, 12)
@assert abs(est12 - true_mu) < 1e-3 "深度 12 的逼近误差应 < 1e-3"
println("深度 12 逼近误差 $(abs(est12 - true_mu)) < 1e-3：逼近定理的数值影子")

# --- 唯一性：两个"神秘测度"在二进区间上相等 → 处处相等 ---
# μ = Lebesgue；ν = 用[0,1)均匀样本的经验测度（大样本）
# 检验在深度 6 的 64 个二进区间上两者质量接近（有限精度的"相等"）
function empirical_interval_mass(samples, k, d)
    lo = (k - 1) / 2^d
    hi = k / 2^d
    count(x -> lo <= x < hi, samples) / length(samples)
end

samples = rand(2_000_000)
d = 6
max_gap = maximum(abs(empirical_interval_mass(samples, k, d) - 1 / 2^d)
                  for k in 1:2^d)
println("经验测度 vs Lebesgue 在 64 个二进区间上的最大偏差：$(round(max_gap, digits=5))")
@assert max_gap < 0.01 "两百万样本下二进区间质量偏差应 < 1%（唯一性定理的统计影子）"

# --- 从生成系重建测度：仅用区间质量表推任意二进并集的测度 ---
# 给定 f(a,b) = b - a（只知道区间上的值），任意二进集合的测度
# 由有限不交分解唯一确定：
function mu_from_intervals(pieces)   # pieces = [(a,b),...] 不交
    sum(b - a for (a, b) in pieces)
end
pieces = [(0.0, 0.125), (0.25, 0.5), (0.625, 0.75)]
@assert abs(mu_from_intervals(pieces) - (0.125 + 0.25 + 0.125)) < 1e-15
# 同一集合的另一种二进剖分（更细）给出同一值——良好定义性
pieces_fine = vcat([(0.0, 0.0625), (0.0625, 0.125)],
                   [(0.25, 0.375), (0.375, 0.5)],
                   [(0.625, 0.6875), (0.6875, 0.75)])
@assert abs(mu_from_intervals(pieces) - mu_from_intervals(pieces_fine)) < 1e-15
println("不同二进剖分给出同一测度值（在生成系上的取值决定一切）")

println("END ====")
