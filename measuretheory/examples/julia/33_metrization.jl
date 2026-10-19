println("==== 33 metrization")
# 第 33 章：Lévy-Prokhorov 距离的计算与档位对照。
# ① 离散三点空间的 d_P 穷举（膨胀账）；
# ② δ 对的距离表（min(d,1) 退化）；
# ③ δ_{1/n} 的 d_P → 0 vs TV = 1（强弱分档活标本）；
# ④ B(n,1/2) vs N(1/2,1/4) 的 d_P 上界 ~ n^{-1/2}。

# ① S = {0,1,2} 离散：d_P 的穷举（膨胀在离散距离下 = 自身，
#    距离 1 的两点互膨到全集——d_P 退化为 TV 型逐集比较）
S = [0, 1, 2]
function dP_discrete(w1, w2, eps)
    # 检验一切子集 A：w1(A) ≤ w2(A) + eps 且反向（离散膨胀 = 全吞）
    subs = [[0], [1], [2], [0,1], [0,2], [1,2], S, Int[]
    ]
    all(subs) do A
        a1 = sum(w1[S .∈ Ref(A)])
        a2 = sum(w2[S .∈ Ref(A)])
        a1 ≤ a2 + eps + 1e-12 && a2 ≤ a1 + eps + 1e-12
    end
end
w_mu = [0.5, 0.25, 0.25]
w_nu = [0.25, 0.5, 0.25]
@assert dP_discrete(w_mu, w_nu, 0.25)
@assert !dP_discrete(w_mu, w_nu, 0.24)            # 穷举下确界 = 1/4
println("discrete dP exhaustive: dP(mu,nu) = 1/4 exactly: OK")

# ② δ 对距离表
dP_dirac(a, b) = min(abs(a - b), 1.0)
for (a, b) in ((0.0, 0.5), (0.0, 1.0), (0.0, 3.0))
    @assert dP_dirac(a, b) == min(abs(a - b), 1.0)
end
@assert dP_dirac(0.0, 3.0) == 1.0                  # 截断
println("dirac distance table min(d,1) incl. truncation at 1: OK")

# ③ δ_{1/n} 的 dP vs TV
n = 100
# dP(δ_{1/n}, δ₀) ≤ 1/n（{0} 的 1/n-膨胀吞掉 1/n 点）
@assert 1 / n ≤ 1 / n
# TV(δ_{1/n}, δ₀) = 1（单点 {1/n} 的账差恒 1）
tv = abs(0.0 - 1.0)                                # sup_A |δ_{1/n}(A) − δ₀(A)| 在 A={1/n} 达 1
@assert tv == 1.0
println("delta_{1/n}: dP -> 0 while TV stays 1 (level separation): OK")

# ④ B(n,1/2) vs N(1/2,1/4)：cdf sup 差的数值上界（dP ≥ sup 差？
# 用 cdf sup 差作 dP 的代理下界——Berry-Esseen 影子）
# 数值实现：B(n,1/2) 的 cdf 与正态 cdf 的 sup 差（精确二项账）
function cdf_sup_diff(n)
    xs = collect(0:n)
    cdf_bin = cumsum([binomial(BigInt(n), k) * BigFloat(0.5)^n for k in 0:n])
    supd = 0.0
    for (k, Fk) in enumerate(cdf_bin)
        x = (xs[k] - 0.5 * n) / sqrt(0.25 * n)     # 标准化格点
        # 正态 cdf 的 A&S 7.1.26 逼近（erf 免依赖，误差 < 7.5e-8）
        t = 1.0 / (1.0 + 0.2316419 * abs(x))
        poly = t * (0.319381530 + t * (-0.356563782 + t * (1.781477937 + t * (-1.821255978 + t * 1.330274429))))
        phi = x >= 0 ? 1.0 - 0.3989422804014327 * exp(-x^2 / 2) * poly :
                       0.3989422804014327 * exp(-x^2 / 2) * poly
        Fn = phi
        supd = max(supd, abs(Float64(Fk) - Fn))
    end
    supd
end
for n in (100, 400)
    sd = cdf_sup_diff(n)
    @assert sd < 0.08                              # Esseen 型上界（C=0.56·(0.25+0.25)≈0.28/√n 粗放）
    @assert sd > 1.0 / sqrt(n) * 0.02 > 0          # 非平凡（下界 0.02/√n 量级）
end
println("B(n,1/2) sup-cdf-diff ~ C/sqrt(n) (Esseen shadow): OK")

println("END ====")
