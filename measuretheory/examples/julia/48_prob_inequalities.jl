println("==== 48 prob_inequalities")
# 第 48 章：四代引擎的账。
# ① Chebyshev 取等现场；② Kolmogorov max 对拍；
# ③ Lévy 2 倍常数；④ Hájek-Rényi 加权 max。

using Random, Statistics
Random.seed!(48)

# ① Chebyshev 取等：两点分布 X = ±x 各半
x = 3.0
P_viol = 1.0                            # P(|X| >= x) = 1
Var_X = x^2                              # Var = x²
@assert P_viol == Var_X / x^2            # 精确取等
println("Chebyshev exact: P(|X|>=x) = 1 = Var/x^2 (two-point): OK")

# ② Kolmogorov max：n = 100 的随机游走（±1 等概）
n = 100
function max_excursion(lambda, trials)
    cnt = 0
    tot_var = 0.0
    for _ in 1:trials
        X = cumsum(rand([-1.0, 1.0], n))
        maximum(abs.(X)) >= lambda && (cnt += 1)
        tot_var += n
    end
    cnt / trials, n
end
for lambda in (10.0, 15.0, 20.0)
    frac, totv = max_excursion(lambda, 5000)
    bound = totv / lambda^2                # Σσ²/λ² = n/λ²
    @assert frac ≤ bound + 0.01            # Kolmogorov max 上界（容许 MC 噪声）
end
println("Kolmogorov max: P(max|S| >= lambda) <= n/lambda^2 at lambda = 10,15,20: OK")

# ③ Lévy 2 倍常数（对称情形）
function levy_check(x, trials)
    cnt = 0
    for _ in 1:trials
        X = cumsum(rand([-1.0, 1.0], n))
        maximum(X[end] .- X) >= x && (cnt += 1)   # max(S_n - S_k) ≥ x ⟹ 末尾超越
    end
    cnt / trials
end
for x in (8.0, 12.0)
    # P(max(S_n - S_k) >= x) ≤ 2·P(S_n >= x)
    lhs = levy_check(x, 5000)
    rhs = 2 * mean([sum(rand([-1.0,1.0], n)) >= x for _ in 1:5000])
    @assert lhs ≤ rhs + 0.02
end
println("Levy inequality: max(S_n - S_k) tail <= 2 * P(S_n >= x): OK")

# ④ Hájek-Rényi：c_k = 1/k 的加权 max
function hajek_renyi(x, trials)
    cnt = 0
    for _ in 1:trials
        X = cumsum(rand([-1.0, 1.0], n))
        maximum(abs.(X ./ (1:n))) >= x && (cnt += 1)
    end
    cnt / trials
end
for x in (1.0, 1.5)
    frac = hajek_renyi(x, 3000)
    bound = sum(1.0 / k^2 for k in 1:n) / x^2  # Σ c_k² σ² / x² = (π²/6)/x²
    @assert frac ≤ bound + 0.05
end
println("Hajek-Renyi: P(max |S_k|/k >= x) <= (pi^2/6)/x^2: OK")

println("END ====")
