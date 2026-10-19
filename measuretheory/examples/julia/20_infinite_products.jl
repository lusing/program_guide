println("==== 20 infinite_products")
# 第 20 章：无穷乘积测度的三组账（均匀硬币）。
# ① 指定花样：前 n 位柱集概率 2^-n 与模拟频率对拍；
# ② 坐标泛函：ω_k ~ Bernoulli(1/2)，(ω1,ω2) 联合计数比 = 1/4；
# ③ 频率轨道：|m_n - 1/2| 包络 ~ n^{-1/2}（Chebyshev 界对拍）；
# ④ 非均匀硬币 p=0.3：柱集账 p^k(1-p)^{n-k}。

using Random
Random.seed!(42)

count_allones(n::Int, trials::Int) = count(all(==(1), rand(0:1, n)) for _ in 1:trials)

# ---- ① 指定花样：全正面柱集 ----
for (n, tol) in ((4, 0.02), (8, 0.10), (12, 0.50))
    p_exact = 2.0^-n
    trials = 1_000_000 ÷ n
    freq = count_allones(n, trials) / trials
    # 期望命中数随 n 缩水 → 相对容差放宽（期望命中 ≈ 10^6/2^n/n）
    @assert abs(freq - p_exact) / p_exact < tol
end
println("cylinder 2^-n: exact vs simulated (n=4,8,12; tolerance scaled to hit count): OK")

# ---- ② 坐标泛函与联合独立 ----
function joint_counts(N::Int)
    cnt = zeros(Int, 2, 2)
    for _ in 1:N
        cnt[rand(0:1)+1, rand(0:1)+1] += 1
    end
    cnt
end
const N = 400_000
cnt_pair = joint_counts(N)
for i in 1:2, j in 1:2
    @assert abs(cnt_pair[i, j] / N - 0.25) < 0.01   # 联合计数比 ≈ 1/4
end
marg1 = sum(cnt_pair[2, :]) / N
@assert abs(marg1 - 0.5) < 0.005                     # π_k 像测度 = Bernoulli(1/2)
println("coordinate functionals: joint ratio = 1/4, marginal = 1/2: OK")

# ---- ③ 频率轨道与 Chebyshev 界 ----
function orbit(n_track::Int)
    bits = rand(0:1, n_track)
    m = Vector{Float64}(undef, n_track)
    s = 0
    for k in 1:n_track
        s += bits[k]
        m[k] = s / k
    end
    m
end
m_n = orbit(10_000)
@assert abs(m_n[end] - 0.5) < 0.02
viol = count(k -> abs(m_n[k] - 0.5) > 2 / sqrt(k), 1:10_000)
@assert viol / 10_000 < 0.05
peak = maximum(abs.(m_n[100:end] .- 0.5) .* sqrt.(100:10_000))
@assert 0.5 < peak < 5.0
println("frequency orbit: within Chebyshev envelope, |m_n-1/2|~n^{-1/2}: OK")

# ---- ④ 非均匀硬币 ----
function biased_bits(n::Int, p::Float64)
    [rand() < p ? 1 : 0 for _ in 1:n]
end
function count_extreme(trials::Int, n::Int, p::Float64)
    hits = 0
    for _ in 1:trials
        b = biased_bits(n, p)
        (all(==(1), b) || all(==(0), b)) && (hits += 1)
    end
    hits
end
p = 0.3
n = 8
p_exact = p^n + (1 - p)^n            # 全正面 + 全反面两种"指定花样"
hits = count_extreme(200_000, n, p)
@assert abs(hits / 200_000 - p_exact) / p_exact < 0.1
println("biased coin p=0.3: cylinder formula p^k(1-p)^(n-k): OK")

println("END ====")
