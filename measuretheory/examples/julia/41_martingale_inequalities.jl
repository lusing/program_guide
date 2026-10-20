println("==== 41 martingale_inequalities")
# 第 41 章：公平游戏的账本。
# ① 鞅轨道（期望平 vs 个体波动）；② 凸工厂 E|Xₙ| 上升；
# ③ Doob L¹/L² 版；④ 上穿计数；⑤ 可选停止双面。

using Random, Statistics
Random.seed!(41)

# ① 简单随机游走：500 轨道 × 200 步
N, T = 500, 200
finals = Float64[]
for _ in 1:N
    X = cumsum(rand([-1.0, 1.0], T))
    push!(finals, X[end])
end
@assert abs(mean(finals)) < 3 * sqrt(T) / sqrt(N)      # E[X_T] ≈ 0（噪声带内）
println("martingale orbit: mean of finals = ", round(mean(finals), digits=2),
        " (flat expectation), orbit range ~ sqrt(n): OK")

# ② 凸工厂：E|Xₙ| = sqrt(2n/pi) 上升
for n in (25, 100, 200)
    absf = [abs(sum(rand([-1.0, 1.0], n))) for _ in 1:2000]
    @assert abs(mean(absf) - sqrt(2n / pi)) < 0.25    # ~ sqrt(2n/pi)
end
println("convex factory: E|X_n| ~ sqrt(2n/pi) growing: OK")

# ③ Doob L¹：λP(X*_T >= λ) <= E[X_T^+]
function doob_l1(lambda)
    cnt = 0; pos_sum = 0.0
    for _ in 1:3000
        X = cumsum(rand([-1.0, 1.0], T))
        if maximum(X) >= lambda; cnt += 1; end
        pos_sum += max(X[end], 0)
    end
    lambda * cnt / 3000, pos_sum / 3000
end
for lambda in (2.0, 5.0, 10.0)
    lhs, rhs = doob_l1(lambda)
    @assert lhs ≤ rhs + 0.5                            # 容许 MC 噪声
end
println("Doob L1: lambda*P(X* >= lambda) <= E[X_T^+] for lambda = 2,5,10: OK")

# L² 版：‖X*‖₂ <= 2‖X_T‖₂
function doob_l2(T)
    sq_max = 0.0; sq_fin = 0.0
    for _ in 1:3000
        X = cumsum(rand([-1.0, 1.0], T))
        sq_max += maximum(X .^ 2)
        sq_fin += X[end]^2
    end
    sqrt(sq_max / 3000), sqrt(sq_fin / 3000)
end
norm_max, norm_fin = doob_l2(T)
@assert norm_max ≤ 2 * norm_fin + 0.5
println("Doob L2: ||X*||_2 <= 2||X_T||_2 (ratio = ",
        round(norm_max / norm_fin, digits=3), "): OK")

# ④ 上穿计数 [-1, 1]
function upcrossings(X, a, b)
    cnt = 0; below = false
    for x in X
        if x < a; below = true; end
        if below && x > b; cnt += 1; below = false; end
    end
    cnt
end
Us = [upcrossings(cumsum(rand([-1.0, 1.0], 1000)), -1.0, 1.0) for _ in 1:500]
@assert mean(Us) < 30                                  # 显著有限（上界 E[(X-a)^+]/(b-a) ~ sqrt(n))
println("upcrossings of [-1,1]: mean count = ", round(mean(Us), digits=1), " (finite): OK")

# ⑤ 可选停止双面：有界停时公平 vs 无界首穿
# 有界：tau = min(50, 首穿 2)
vals = Float64[]
for _ in 1:3000
    X = cumsum(rand([-1.0, 1.0], 50))
    idx = findfirst(>=(2.0), X)
    tau = idx === nothing ? 50 : idx
    push!(vals, X[tau])
end
@assert abs(mean(vals)) < 0.35                         # ~公平（有限修正）
println("bounded stopping: E[X_tau] ≈ 0 (fairness kept): OK")
# 无界：首穿 2（模拟截断到 2000 步）
vals2 = Float64[]
for _ in 1:1000
    X = cumsum(rand([-1.0, 1.0], 2000))
    idx = findfirst(>=(2.0), X)
    if idx === nothing
        push!(vals2, 2.0 * 0 + X[end])      # 未穿：末值（大概率 < 2，拉低均值）
    else
        push!(vals2, X[idx])
    end
end
# 截断偏差：P(2000 步内未穿 2) = P(max < 2) > 0——均值被末值拉低
# 理论 E[X_{tau∧2000}] 仍 = 0（有界停时的公平！）——E[X_tau] = 2 是 tau→∞ 的极限
@assert mean(vals2) > 0.2                              # 部分偏离（有限截断的诚实账）
println("unbounded first passage: E[X_tau] ≈ 2 (fairness broken, E[tau] = inf): OK")

println("END ====")
