# -*- coding: utf-8 -*-
println("==== 25 convergence")
# 第 25 章 Julia：收敛模式的反例账（移动区间、尖峰序列、BC 引理、依分布）。
using Random, Statistics

# ① 移动区间（typewriter）：第 n 项指标 1{s ∈ [i/2^k,(i+1)/2^k]}，k=⌊log2 n⌋，i=n−2^k
function typewriter(n)
    k = floor(Int, log2(n)); i = n - 2^k
    return i // 2^k, (i + 1) // 2^k, k
end
Zn(n, s) = (lo_hi = typewriter(n); lo_hi[1] <= s <= lo_hi[2] ? 1 : 0)

for n in 1:255
    lo, hi, k = typewriter(n)
    @assert hi - lo == 1 // 2^k                      # P(Z_n=1)=2^{-k}→0
end
for s in (0 // 1, 1 // 3, 2 // 3, 5 // 7, 1 // 1)
    for K in 0:11
        @assert any(Zn(n, s) == 1 for n in 2^K:2^(K + 1) - 1)    # 每层命中 ⇒ limsup=1
    end
    for K in 1:11
        @assert any(Zn(n, s) == 0 for n in 2^K:2^(K + 1) - 1)    # 每层也有不含 s 的区间 ⇒ liminf=0
    end
end
println("typewriter: P,Lp -> 0 but limsup=1, liminf=0 at every s: OK")

# ② 尖峰序列与 Borel–Cantelli：Σ n^{-2} < ∞ ⇒ 几乎处处 Z_n=0 终将成立；E Z_n=e^n/n² →∞
@assert sum(1.0 / n^2 for n in 1:200000) < π^2 / 6
for m in (2, 10, 100, 1000)
    @assert sum(1.0 / n^2 for n in m:200000) <= 1.0 / (m - 1)
end
@assert exp(50) / 2500 > exp(30) / 900 > 1e10
println("spike: sum P(Z_n!=0)<inf => a.s.; E Z_n -> inf: OK")

# ③ 独立 Bern(1/n)：Π_{n=m}^{N}(1−1/n)=(m−1)/N → 0；调和级数发散 ⇒ 第二 BC：无穷多事件
for m in (2, 5, 10), N in (m, 50, 400)
    @assert prod((1 - 1 // n for n in m:N); init = 1 // 1) == (m - 1) // N
end
@assert sum(1.0 / n for n in 1:2000) > 7
println("independent Bern(1/n): P(no event in [m,N]) = (m-1)/N: OK")

# ④ 子列：n_j 使 P(|Z_{n_j}|>1/j) < 2^{-j}，ΣP<∞ ⇒ a.s.
function choose_subsequence(prob_exceed, J)
    out = Int[]; last = 0
    for j in 1:J
        n = last + 1
        while prob_exceed(n, j) >= 1 // 2^j
            n += 1
        end
        push!(out, n); last = n
    end
    return out
end
nj = choose_subsequence((n, j) -> 1 // 2^floor(Int, log2(n)), 6)
@assert nj == [4, 8, 16, 32, 64, 128]
@assert issorted(nj)
println("subsequence extraction: ", nj, " OK")

# ⑤ 依分布：Z_n~N(0,1/n)，F_n(0)=1/2；常数目标；−X 反例
function Φ(x)                                        # Taylor 级数 erf（BigFloat，避免依赖 SpecialFunctions）
    setprecision(BigFloat, 600) do
        z = BigFloat(x) / sqrt(BigFloat(2)); term = z; s = z; k = 0
        while abs(term) > 1e-30
            k += 1
            term = -term * z^2 / k
            s += term / (2k + 1)
        end
        return Float64(0.5 * (1 + 2 / sqrt(BigFloat(π)) * s))
    end
end
for n in (1, 10, 100, 400)
    @assert abs(Φ(0.0) - 0.5) < 1e-15
    @assert Φ(sqrt(n) * 0.5) >= 1 - 2 * exp(-n / 8)
    @assert Φ(-sqrt(n) * 0.5) <= 2 * exp(-n / 8)
end
@assert 2 * (1 - Φ(0.5 / 2)) > 0.8                     # P(2|X|>0.5) 与 n 无关
println("distribution: F_n(0)=1/2; -X ->d X not in probability: OK")

# ⑥ 非一致可积
for n in (10, 100, 1000)
    @assert n * (1 // n) == 1
end
println("not UI: E[n 1{U<1/n}] = 1 but a.s. limit 0: OK")

# ⑦ Bin(n,λ/n) → Poisson(λ)：PMF 最大误差随 n 单调减
λ = 2.0
pois(k) = exp(-λ) * λ^k / factorial(k)
binom(n, k) = Float64(binomial(big(n), k)) * (λ / n)^k * (1 - λ / n)^(n - k)
errs = [maximum(abs(binom(n, k) - pois(k)) for k in 0:11) for n in (10, 100, 1000)]
@assert errs[1] > errs[2] > errs[3] && errs[3] < 2e-3
println("Binomial -> Poisson max PMF error ", round.(errs; sigdigits = 3), " OK")

# ⑧ n(θ−max) → Exp
θ = 2.0
for n in (10, 100, 1000), x in (0.5, 1.0, 3.0)
    exact = (1 - x / (n * θ))^n
    @assert abs(exact - exp(-x / θ)) < (x^2 / θ^2) / n + 1e-12
end
println("n(theta - max) -> Exp: OK")
println("END ====")
