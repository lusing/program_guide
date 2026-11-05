# --- 辅助：log 二项系数与 logsumexp（避免大数溢出）---
function logbinom(n, k)
    k < 0 || k > n && return -Inf
    return lgamma(n + 1) - lgamma(k + 1) - lgamma(n - k + 1)
end
function logsumexp(xs)
    m = maximum(xs)
    isinf(m) && return m
    return m + log(sum(exp.(xs .- m)))
end

# 第 46 章 Julia：重对数律的机器账（固定种子，不冒领常数）。
# ① LIL 轨迹：T_n = S_n/sqrt(2n·log log n) 的运行最大值（N 到 10^6 仍远低于 1
#    ——log log 慢尺度是本定理最著名的实际特征）；
# ② 分级二项尾对账：在 n = 2^j 处精确二项尾 vs 多项式界 (j·log2)^(-K)；
# ③ 下界的经验面：对每个 c < 1，max T_n 超过 c 的轨道比例随 N 上升；
# ④ 二阶修正：把 1 换成 1 - logloglog n/(2·loglog n) 后轨迹贴得多近。
println("==== 46 lil")
using Random, Statistics, SpecialFunctions

const IMIN = 16   # log log n > 0 需要 n > e^e ≈ 15.15

lil_scale(n) = sqrt(2 * n * log(log(n)))

function run_orbit(N, seed)
    rng = MersenneTwister(seed)
    s = 0
    best = -Inf
    t = Float64[]
    for k in 1:N
        s += rand(rng) < 0.5 ? 1 : -1
        if k >= IMIN
            v = s / lil_scale(k)
            v > best && (best = v)
            k == N && push!(t, v)
        end
    end
    return best
end

# ---------- ① LIL 轨迹 ----------
println("① LIL 轨迹（单轨道运行最大值 max T_k，种子 4601）：")
for N in [10^3, 10^4, 10^5, 10^6]
    b = run_orbit(N, 4601)
    println("   N = ", lpad(N, 7), "：max T_k = ", round(b, digits=3),
            "（远低于 1——log log 慢尺度）")
    @assert 0.2 < b < 1.0
end

# ---------- ② 分级二项尾对账 ----------
println("② 分级二项尾：P(S_{2^j} >= ceil(sqrt(2·2^j·K·loglog 2^j))) vs (j·log2)^(-K)，K=2：")
K = 2.0
for j in 5:2:15
    n = 2^j
    t = ceil(sqrt(2 * n * K * log(log(n))))          # S 界
    idx = Int((n + t) ÷ 2)                            # S_n >= t ⟺ Bin >= (n+t)/2
    logtail = logsumexp([logbinom(n, i) for i in idx:n] .- n * log(2))
    tail = exp(logtail)
    bound = (j * log(2))^(-K)
    println("   j=", lpad(j, 2), "：尾 = ", round(tail, digits=6),
            "，界 = ", round(bound, digits=6))
    @assert tail <= bound
end

# ---------- ③ 下界的经验面 ----------
println("③ 下界经验面（300 条轨道，max T_k > c 的比例，N = 5×10^4）：")
for c in [0.4, 0.6, 0.8]
    frac = sum(run_orbit(5 * 10^4, 4600 + i) > c for i in 1:300) / 300
    println("   c = ", c, "：比例 = ", round(frac, digits=3),
            "（limsup = 1 意味着 N -> 无穷 时此比例 -> 1）")
end
f4 = sum(run_orbit(5 * 10^4, 4600 + i) > 0.4 for i in 1:300) / 300
f8 = sum(run_orbit(5 * 10^4, 4600 + i) > 0.8 for i in 1:300) / 300
@assert f4 > f8

# ---------- ④ 二阶修正 ----------
println("④ 二阶修正（把边界从 1 换成 1 - logloglog n/(2·loglog n)）：")
function corrected_max(N, seed)
    rng = MersenneTwister(seed)
    s = 0
    best = -Inf
    for k in 1:N
        s += rand(rng) < 0.5 ? 1 : -1
        if k >= 100
            corr = 1 - log(log(log(k))) / (2 * log(log(k)))
            v = s / (lil_scale(k) * corr)
            v > best && (best = v)
        end
    end
    return best
end
for N in [10^4, 10^5, 10^6]
    b0 = run_orbit(N, 4601)
    b1 = corrected_max(N, 4601)
    println("   N = ", lpad(N, 7), "：原始 max = ", round(b0, digits=3),
            "，修正后 = ", round(b1, digits=3),
            "（修正项把 1 的到达时间往回收——仍在 1 之下）")
    @assert b1 < 1.05 && b1 > b0 - 0.05
end
println("END ====")

# --- 辅助：log 二项系数与 logsumexp（避免大数溢出）---
function logbinom(n, k)
    k < 0 || k > n && return -Inf
    return lgamma(n + 1) - lgamma(k + 1) - lgamma(n - k + 1)
end
function logsumexp(xs)
    m = maximum(xs)
    isinf(m) && return m
    return m + log(sum(exp.(xs .- m)))
end
