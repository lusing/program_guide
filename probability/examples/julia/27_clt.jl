# 第 27 章 Julia：有限方差 CLT、标准化尺度与格点修正。
using Random

Random.seed!(27)
println("==== 27 clt")

function poisson_standardized_cf(t, lam)
    u = t / sqrt(lam)
    exp(-im * t * sqrt(lam)) * exp(lam * (exp(im * u) - 1))
end

# 1. 同一个特征函数极限，不用 MGF，也不把 Poisson 误当正态。
for t in (0.5, 1.0)
    target = exp(-t^2 / 2)
    errors = [abs(poisson_standardized_cf(t, lam) - target)
              for lam in (5, 50, 500)]
    @assert errors[1] > errors[2] > errors[3]
    @assert errors[end] < 0.006
end
println("Poisson standardized CF -> exp(-t^2/2): OK")

# 2. 固定种子的频率实验只检查有限 n 的形态，不替代 CLT 证明。
# 每个区间用 Simpson 积分精算正态目标。
function normal_bucket(lo, hi; steps=400)
    h = (hi - lo) / steps
    total = exp(-lo^2 / 2) + exp(-hi^2 / 2)
    for i in 1:steps-1
        x = lo + i * h
        total += (isodd(i) ? 4 : 2) * exp(-x^2 / 2)
    end
    total * h / (3 * sqrt(2 * pi))
end

for (name, sampler, mu, sigma) in (
        ("uniform", () -> rand(), 0.5, sqrt(1 / 12)),
        ("exponential", () -> randexp(), 1.0, 1.0),
        ("die", () -> Float64(rand(1:6)), 3.5, sqrt(35 / 12)))
    n = 200
    reps = 30_000
    z = [(sum(sampler() for _ in 1:n) - n * mu) /
         (sigma * sqrt(n)) for _ in 1:reps]
    for (lo, hi) in ((-1.0, -0.5), (-0.5, 0.0), (0.0, 0.5), (0.5, 1.0))
        empirical = count(x -> lo <= x < hi, z) / reps
        @assert abs(empirical - normal_bucket(lo, hi)) < 0.015
    end
    println("CLT finite-n buckets: ", name, " OK")
end

# 3. 精确二项账：连续性修正与格距。
function normal_cdf(x; steps=4_000)
    # 对称性把积分区间化为 [0,|x|]，避免 erf 外部依赖。
    x == 0 && return 0.5
    h = abs(x) / steps
    total = 1.0 + exp(-x^2 / 2)
    for i in 1:steps-1
        u = i * h
        total += (isodd(i) ? 4 : 2) * exp(-u^2 / 2)
    end
    area = total * h / (3 * sqrt(2 * pi))
    x > 0 ? 0.5 + area : 0.5 - area
end

exact = sum(binomial(big(100), k) for k in 45:55) / big(2)^100
raw = normal_cdf(1.0) - normal_cdf(-1.0)
corrected = normal_cdf(1.1) - normal_cdf(-1.1)
@assert abs(corrected - exact) < abs(raw - exact)
@assert abs(corrected - exact) < 0.0001

center = binomial(big(100), 50) / big(2)^100
local_center = 1 / (5 * sqrt(2 * pi))
@assert abs(center / local_center - 1) < 0.003
walk_center = binomial(big(200), 100) / big(2)^200
walk_local = 2 / (sqrt(200) * sqrt(2 * pi))
@assert abs(walk_center / walk_local - 1) < 0.0015
println("continuity correction and lattice width h=1,2: OK")

println("END ====")
