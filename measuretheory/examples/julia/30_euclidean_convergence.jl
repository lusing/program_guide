println("==== 30 euclidean_convergence")
# 第 30 章：分布函数赛马场。
# ① δ_{1/n} 跳点失败 vs 连续点成功；
# ② Helly 对角线（混合漂移列的子线抽取）；
# ③ 质量逃逸（δₙ 端点亏损）；
# ④ 污染逃逸保弱收敛（积分对拍）。

# ① 跳点与连续点
Fn(n, x) = 1.0 / n ≤ x ? 1.0 : 0.0     # δ_{1/n} 的 cdf
F(x) = 0.0 ≤ x ? 1.0 : 0.0             # δ₀ 的 cdf
for n in (10, 100, 10000)
    @assert Fn(n, 0.0) == 0.0          # 跳点失败：Fₙ(0) = 0
end
@assert F(0.0) == 1.0                  # vs 极限 F(0) = 1
for x in (-1.0, -0.01, 0.3, 2.0)       # 连续点全部成功
    @assert Fn(1000, x) == F(x)
end
println("delta_{1/n}: jump point 0 fails (0 vs 1), continuity points converge: OK")

# ② Helly 对角线：随机漂移列在网格点上的同时收敛子列
using Random
Random.seed!(30)
n_grid = 50
grid = collect(0.02:0.02:1.0)
Fdrift(k, x) = x < 0.3 + 0.1 * sin(k) ? 0.0 : 1.0   # 漂移阶梯
# 取子列：k_j 使一切网格点稳定（漂移 sin(k) 的收敛子列存在——紧性）
sub = [k for k in 1:100000 if abs(sin(k) - sin(77)) < 0.01]
@assert length(sub) > 100              # sin(k) 的聚点邻域无穷多（Kronecker 影子）
vals1 = [Fdrift(sub[1], x) for x in grid]
allok = all(j -> [Fdrift(sub[j], x) for x in grid] == vals1, 1:min(50, length(sub)))
@assert allok
println("Helly diagonal: subsequence with synchronized grid accounts (", length(sub), " members): OK")

# ③ 质量逃逸：δₙ 的端点亏损（固定 x 的 cdf 终值 → 0）
G(n, x) = n ≤ x ? 1.0 : 0.0            # δₙ 的 cdf
for x in (0.5, 10.0, 1000.0)
    # n > x 后 G(n, x) = 0：固定点的账全为 0（质量跑过任何固定点）
    @assert G(ceil(Int, x) + 1, x) == 0.0
end
println("delta_n: fixed-x cdf accounts eventually 0 (mass escapes): OK")

# ④ 污染逃逸保弱收敛：μₙ = (1-1/n)δ₀ + (1/n)δₙ 的积分账
g(x) = exp(-abs(x))                     # C_b 检验
for n in (10, 100, 10000)
    val = (1 - 1 / n) * g(0.0) + (1 / n) * g(n)
    @assert abs(val - g(0.0)) ≤ 1 / n + 1e-15   # 积分 → f(0)（严格账 (1-e^{-n})/n）
end
println("contaminated escape: integral -> f(0) at rate 1/n: OK")

println("END ====")
