# 21 随机与统计 ⭐：Random/Statistics、可复现子流、蒙特卡洛、中心极限定理、置信区间
# 运行：julia --startup-file=no main.jl（全部用固定种子——输出可复现、断言可确定）

using Random
using Statistics
using LinearAlgebra: norm

# ═══ 21.1 Random：RNG 对象、种子复现、rand 家族
rng = Xoshiro(20260918)          # Julia 默认 RNG 类型（1.7+）；独立"子流"，互不干扰全局
a = rand(rng, 5)
b = rand(rng, 5)
@assert a != b                    # 同一 rng 顺序推进
rng2 = Xoshiro(20260918)
@assert rand(rng2, 5) == a       # 同种子新建 → 逐位复现（可复现科学的起点）
@assert size(rand(rng, 2, 3)) == (2, 3)
@assert eltype(rand(rng, Float32, 2)) == Float32
v = 2 .+ rand(rng, 3)            # 区间采样的通用姿势：线性变换 a + (b-a)·U
@assert all(2 .<= v .< 3)
w = randn(rng, 1000)             # 标准正态
@assert abs(mean(w)) < 0.1
rand!(rng, w)                     # 原地重填（零分配）
perm = shuffle(rng, collect(1:10))
@assert sort(perm) == collect(1:10)
# 全局 RNG：Random.seed!(n) 影响无 rng 参数的调用——库代码请传 rng，别碰全局（坑位）

# ═══ 21.2 Statistics：描述统计与相关性
data = [2, 4, 4, 4, 5, 5, 7, 9]
@assert mean(data) == 5.0 && median(data) == 4.5
@assert var(data) ≈ 32 / 7                     # 样本方差（n-1 修正，默认）
@assert var(data; corrected = false) ≈ 4.0     # 总体方差
@assert std(data) ≈ sqrt(32 / 7)
@assert quantile(data, 0.5) == 4.5
@assert cor([1, 2, 3], [2, 4, 6]) ≈ 1.0        # 相关系数
@assert cov([1, 2, 3], [2, 4, 6]) ≈ 2.0        # 样本协方差
# 按维度统计：dims 关键字
M = [1 2; 3 4; 5 6]
@assert vec(mean(M; dims = 1)) == [3.0, 4.0]   # 每列均值
@assert vec(std(M; dims = 1)) ≈ [2.0, 2.0]
@assert vec(maximum(M; dims = 2)) == [2.0, 4.0, 6.0]   # 每行最大

# ═══ 21.3 蒙特卡洛 I：投点算 π（误差 ∝ 1/√N）
function mc_pi(n, rng)
    hits = 0
    for _ in 1:n
        x, y = rand(rng), rand(rng)
        x * x + y * y <= 1 && (hits += 1)
    end
    4 * hits / n
end
π_small = mc_pi(10_000, rng)
π_large = mc_pi(1_000_000, rng)
println("MC π：N=1e4 → $(round(π_small; digits = 4))，N=1e6 → $(round(π_large; digits = 5))")
@assert abs(π_small - π) < 0.05
@assert abs(π_large - π) < 0.005
err_ratio = abs(π_small - π) / abs(π_large - π)
println("误差比（N×100 → 期望约 10）= ", round(err_ratio; digits = 1), "（1/√N 收敛的直观形态）")
@assert 2 < err_ratio < 50

# ═══ 21.4 蒙特卡洛 II：定积分 E[f(U)] ≈ ∫f
function mc_int(f, n, rng)
    s = 0.0
    for _ in 1:n
        s += f(rand(rng))
    end
    s / n
end
∫e = mc_int(exp, 1_000_000, rng)                # ∫₀¹ eˣ dx = ℯ - 1（ℯ 是 Base 导出的欧拉数）
@assert abs(∫e - (ℯ - 1)) < 0.005
println("MC ∫₀¹eˣ = ", round(∫e; digits = 5), "（精确 ℯ-1 = ", round(ℯ - 1; digits = 5), "）")

# ═══ 21.5 逆变换采样 + 中心极限定理
exp_sample(rng, n; θ = 1.5) = [-θ * log(rand(rng)) for _ in 1:n]   # U→指数分布：X = -θln U
xs = exp_sample(rng, 10_000)
@assert abs(mean(xs) - 1.5) < 0.05              # 指数分布均值 = θ
@assert abs(std(xs) - 1.5) < 0.05               # 指数分布标准差也是 θ
# CLT 定量形态：样本均值的标准差 = σ/√n
means = [mean(exp_sample(rng, 50)) for _ in 1:5000]
@assert abs(std(means) - 1.5 / sqrt(50)) < 0.02
println("样本均值std = ", round(std(means); digits = 4),
        "，理论 σ/√n = ", round(1.5 / sqrt(50); digits = 4))

# ═══ 21.6 覆盖率模拟：95% 置信区间该盖住真值 95% 的次数
function coverage(rng; trials = 1000, n = 100, θ = 1.5)
    hits = 0
    for _ in 1:trials
        s = exp_sample(rng, n; θ = θ)
        m, se = mean(s), std(s) / sqrt(n)
        abs(m - θ) <= 1.96 * se && (hits += 1)
    end
    hits / trials
end
cov_rate = coverage(rng)
println("95% CI 覆盖率（1000 次试验）= ", cov_rate)
@assert 0.92 < cov_rate < 0.98

# ═══ 21.7 随机游走：方差线性增长（扩散的骨架）
walk_ends = [sum(randn(rng, 1000)) for _ in 1:2000]
@assert abs(std(walk_ends) - sqrt(1000)) < 10
walk = cumsum(randn(rng, 10_000))
@assert abs(walk[end]) < 500                    # √n=100；5σ 安全界
println("随机游走 1000 步末端 std = ", round(std(walk_ends); digits = 2),
        "（理论 √1000 = ", round(sqrt(1000); digits = 2), "）")
println("==== 21 结束 ====")
