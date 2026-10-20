# -*- coding: utf-8 -*-
println("==== 53 infinitely_divisible")
# 第 53 章 Julia：无穷可分的构造账。
# ① Poisson 复合：n 个 Po(λ/n) 独立和 vs Po(λ) 的分布对拍；② 几何分布
#    的 Poisson 积重建（例 53.J：Panjer 递推 vs 精确几何 pmf）；③ LK 核
#    g(t,x) 的 x→0 连续延拓（→ −t²/2）；④ 三点反例的平方根非 ch.f.
#    显影（4 点 Gram 矩阵最小特征值 < 0——Bochner 破产）。
using Random, Statistics, LinearAlgebra

Random.seed!(53)

# ① Poisson 复合：Knuth 逆变换（∏U > e^−λ 计步）
function poisson_sample(lam)
    L = exp(-lam)
    k, p = 0, 1.0
    while true
        p *= rand()
        p <= L && return k
        k += 1
    end
end
function compound_poisson_pmf(lam, n_terms, kmax; paths = 8000)
    counts = zeros(Int, kmax + 1)
    for _ in 1:paths
        s = 0
        for _ in 1:n_terms
            s += poisson_sample(lam / n_terms)
        end
        s <= kmax && (counts[s+1] += 1)
    end
    counts ./ paths
end
function poisson_pmf(lam, kmax)
    w = exp(-lam)
    [begin w *= (k == 0 ? 1.0 : lam / k); w end for k in 0:kmax]
end
emp = compound_poisson_pmf(2.0, 20, 12)         # 20 个 Po(0.1) 的和
exact = poisson_pmf(2.0, 12)
tv = 0.5 * sum(abs.(emp .- exact))
@assert tv < 0.03                               # 同分布（差 = 采样噪声）
println("Poisson compound: TV(emp sum of 20x Po(0.1), Po(2)) = ", round(tv, digits=4), ": OK")

# ② 几何分布的 Poisson 积重建（例 53.J，p = 3）：λₖ = 1/(k·3^k)，
#    Λ = Σλₖ = log(3/2)；复合 Poisson 的 Panjer 递推 vs 几何 pmf (2/3)(1/3)^m
p = 3.0
K = 60
lam = [1.0 / (k * p^k) for k in 1:K]
Λ = sum(lam)
@assert abs(Λ - log(p / (p - 1))) < 1e-12       # 精确恒等式：Σ 1/(k·3^k) = log(3/2)
q = lam ./ Λ                                    # 跳步分布
M = 14
f = zeros(M + 1)
f[1] = exp(-Λ)                                  # P(X=0) = 2/3
for m in 1:M
    s = 0.0
    for k in 1:min(m, K)
        s += k * q[k] * f[m-k+1]
    end
    f[m+1] = Λ / m * s                          # Panjer：f(m) = (Λ/m)Σ k q(k) f(m−k)
end
geo = [(1 - 1/p) * (1 / p)^m for m in 0:M]      # 几何 pmf
maxerr = maximum(abs.(f .- geo))
@assert maxerr < 1e-9                           # 无穷卷积的有限 Panjer 截断即精确
println("geometric = compound Poisson: Panjer vs (2/3)(1/3)^m, max err = ",
        maxerr, ": OK")

# ③ LK 核的 0 点延拓：g(t,x) = (e^{itx}−1−itx/(1+x²))(1+x²)/x² → −t²/2
t = 1.3
for x in (0.1, 0.01, 0.001)
    g = real((exp(im * t * x) - 1 - im * t * x / (1 + x^2)) * (1 + x^2) / x^2)
    @assert abs(g - (-t^2 / 2)) < 3 * x         # 线性收敛到 −t²/2
end
println("LK kernel: g(t,x) -> -t^2/2 as x -> 0 (t = ", t, "): OK")

# ④ 三点反例：P{±1} = 1/4 各、P{0} = 1/2——φ(t) = 1/2 + cos(t)/2，
#    φ(π) = 0（无处为零性破产）。若 φ 无穷可分则 |φ|^{1/2} 是 ch.f.
#    ⟹ Bochner：任意 t 网格的 Gram 矩阵 [ψ(t_j − t_k)] 半正定。
#    取 4 点网格，最小特征值 < 0。
#    （注意：P{±1}=1/8/P{0}=3/4 的 φ = 3/4+cos t/4 恒 ≥ 1/2 永不
#     为零——不构成零点反例；经典版本是 1/4-1/2。）
psi(t) = sqrt(abs(0.5 + 0.5 * cos(t)))
@assert abs(psi(pi)) < 1e-8                     # φ(π) = 0（sqrt 放大浮点残差，容差放宽）
grid = [0.0, pi / 2, pi, 3pi / 2]
G = [psi(grid[j] - grid[k]) for j in 1:4, k in 1:4]
ev = eigvals(Symmetric(G))
@assert minimum(ev) < -0.1                      # 最小特征值显著负——非 PSD
println("3-point counterexample: min eig of Gram(|phi|^{1/2}) = ",
        round(minimum(ev), digits=3), " < 0 (not a char fun): OK")

println("END ====")
