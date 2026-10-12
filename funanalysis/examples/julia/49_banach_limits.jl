# 49_banach_limits.jl —— Banach 极限与不变平均（docs/49 第四章实验）
# 通道：Julia 1.13
using Printf
using Random

println("==== 49 Banach 极限与不变平均 ====")

# ---------------------------------------------------------------
# 实验 1：三族序列上的 Cesàro / 对数平均对照。
# 断言：
#   (a) 收敛列 aₙ=1/n：两平均都 → 0；
#   (b) 周期列 (-1)ⁿ：Cesàro 值以 1/n 速率 → 0，且落在夹逼区间；
#   (c) sin(√n)（缓振荡不收敛）：平均值落在 [liminf, limsup] 窗口；
#   (d) (1,0,1,0,…) 的 Cesàro → 1/2（任何不变平均的强制值）。
# ---------------------------------------------------------------
function cesaro(a::Vector{Float64})
    n = length(a)
    cumsum(a)[n] / n
end
function logmean(a::Vector{Float64})
    n = length(a)
    w = 1.0 ./ collect(1:n)
    dotw = sum(w)
    sum(w .* a) / dotw
end
function exp1()
    N = 100_000
    a_conv = [1.0 / n for n in 1:N]
    @assert abs(cesaro(a_conv)) < 0.001          # (a) Cesàro → 0
    @assert abs(logmean(a_conv)) < 0.15          # 对数平均偏头：理论值 ~(π²/6)/ln N
    # (b) (-1)ⁿ 的 Cesàro 收敛速率 1/n
    for n in (1_000, 10_000, 100_000)
        a = [(-1.0)^k for k in 1:n]
        c = cesaro(a)
        @assert abs(c) ≤ 1.0 / n * 1.05          # |σ| ≤ ~1/n
    end
    # (c) sin(√n)：夹逼窗口
    a_osc = [sin(sqrt(n)) for n in 1:N]
    m = minimum(a_osc[div(N,2):end]); M = maximum(a_osc[div(N,2):end])
    c = cesaro(a_osc)
    @assert m - 1e-3 ≤ c ≤ M + 1e-3
    # (d) (1,0,1,0,…)
    a_alt = [k % 2 == 1 ? 1.0 : 0.0 for k in 1:N]
    @assert abs(cesaro(a_alt) - 0.5) < 1e-4
    return (m, M)
end
m1, M1 = exp1()
println(@sprintf("实验1 sin(√n) 夹逼窗口 [%.3f, %.3f]，平均在窗内；(-1)ⁿ Cesàro ~1/n；10101… → 0.5",
                 m1, M1))

# ---------------------------------------------------------------
# 实验 2：同窗平移差 |σ_n(x) − σ_n(Ax)| = |a₁ − a_{n+1}|/n ≤ 2/n。
# Cesàro 平均的平移不变性在有限截断上的精确形态：差恰好是 O(1/n)，
# 这是 49.4 中"有限截断近似满足不变性"的机器验证。
# ---------------------------------------------------------------
function exp2()
    N = 100_000
    rng = MersenneTwister(4949)
    x = 2.0 .* rand(rng, N) .- 1.0     # 有界于 [-1,1]
    s = cumsum(x)
    worst = 0.0
    for n in (1_000, 10_000, 99_999)
        σn = s[n] / n                  # Cesàro(x) 前 n 项
        σAx = (s[n + 1] - x[1]) / n    # Cesàro(Ax) 前 n 项（同窗平移）
        d = abs(σn - σAx)
        worst = max(worst, d * n)      # n·d 应 ≤ 2
    end
    @assert worst ≤ 2.0                # 精确界 |a₁ − a_{n+1}| ≤ 2
    @assert worst > 0.1                # 随机序列实际触到典型值
    return worst
end
r2 = exp2()
println(@sprintf("实验2 同窗平移差 n·|σ_n − σ_n∘A| = %.3f（精确界 2，O(1/n) 衰减）", r2))

# ---------------------------------------------------------------
# 实验 3：不同不变平均给出不同值——非唯一性的数值影子。
# 序列 xₙ = 0 若 n ≤ N/2 else 1（"后一半才醒来"）：
#   Cesàro → 1/2；对数平均 → 明显 < 1/2（权重偏头部）。
# 两者都是合法的"广义极限候选"，但对同一序列取值不同。
# ---------------------------------------------------------------
function exp3()
    N = 100_000
    x = [n ≤ div(N, 2) ? 0.0 : 1.0 for n in 1:N]
    c = cesaro(x)
    l = logmean(x)
    @assert abs(c - 0.5) < 1e-3          # Cesàro 1/2
    @assert 0.04 < l < 0.08                     # 理论值 ~ ln2/ln N（显著偏头）
    return (c, l)
end
c3, l3 = exp3()
println(@sprintf("实验3 同一序列 Cesàro=%.3f vs 对数平均=%.3f（不变平均不唯一）", c3, l3))

# ---------------------------------------------------------------
# 实验 4：有限循环群上不变平均唯一 = 均匀测度。
# 解线性方程组 m_{i+1} = m_i（mod n）、Σm = 1。n = 12。
# ---------------------------------------------------------------
function exp4()
    n = 12
    # 方程组：m_i − m_{i+1} = 0（i = 1..n，下标模 n），Σm = 1
    A = zeros(n, n); b = zeros(n)
    for i in 1:n
        A[i, i] = 1.0
        A[i, mod1(i + 1, n)] = -1.0      # 行：m_i − m_{i+1} = 0
    end
    A[n, :] .= 1.0; b[n] = 1.0           # 替换最后一行为归一化（秩恰 n-1 的零空间 + 归一）
    m = A \ b
    @assert maximum(abs.(m .- 1.0 / n)) < 1e-12    # 唯一解 = 均匀
    @assert minimum(m) > -1e-12                    # 且非负自动成立
    return m[1]
end
m4 = exp4()
println(@sprintf("实验4 ℤ/12 上不变平均唯一：m₁ = %.6f = 1/12", m4))

println("END ====")
