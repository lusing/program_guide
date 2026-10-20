# -*- coding: utf-8 -*-
println("==== 52 clt")
# 第 52 章 Julia：CLT 的速率与形状账。
# ① sup|Fₙ−Φ| 的 1/√n 衰减（U[0,1] 与 Bernoulli 双源）；② χ² 双极限
# （例 52.D）；③ Delta 相关系数 (1−ρ²)² 方差账；④ Berry-Esseen
# 常数实测（36 保守度）；⑤ Lindeberg 破坏的离群项显影。
using Random, Statistics, LinearAlgebra

Random.seed!(52)

# Φ(x)：A&S 7.1.26 有理逼近（|err| < 7.5e-8）
function phi_cdf(x)
    t = 1.0 / (1.0 + 0.2316419 * abs(x))
    d = 0.3989422804014327 * exp(-x * x / 2)
    p = d * t * (0.319381530 +
         t * (-0.356563782 + t * (1.781477937 + t * (-1.821255978 + t * 1.330274429))))
    return x >= 0 ? 1.0 - p : p
end
@assert abs(phi_cdf(1.0) - 0.841344746) < 1e-6

# ① sup|Fₙ − Φ| 的精确账：Bin(n, 1/2) 的标准化 CDF vs Φ——
#    二项 pmf 用模点锚定递推（lgamma 定模 + 比率外推，全程 [0,1] 尺度
#    无溢出），ECDF 噪声彻底出局
function binom_half_cdf(n)
    k0 = n ÷ 2
    # 环境无 SpecialFunctions：log(n!) 用 BigInt 精确阶乘取对数
    # （单行：Julia 行首的 "-" 是新语句的一元负——跨行减项会被静默丢弃！）
    lp = -n * log(2.0) + log(factorial(big(n))) - log(factorial(big(k0))) - log(factorial(big(n - k0)))
    pmf = Vector{Float64}(undef, n + 1)
    pmf[k0+1] = exp(lp)
    for k in k0-1:-1:0
        pmf[k+1] = pmf[k+2] * (k + 1) / (n - k)        # pmf(k)/pmf(k+1) = (k+1)/(n-k)
    end
    for k in k0+1:n
        pmf[k+1] = pmf[k] * (n - k + 1) / k            # pmf(k)/pmf(k-1)
    end
    cdf = similar(pmf)
    c = 0.0
    for k in 0:n
        c += pmf[k+1]
        cdf[k+1] = c
    end
    @assert abs(c - 1.0) < 1e-9                        # 归一自检
    cdf
end

function sup_err_exact_bin(n)
    cdf = binom_half_cdf(n)
    e = 0.0
    for z in -4:0.002:4
        J = (n + z * sqrt(n)) / 2                      # Sₙ = 2J − n，std = √n
        if J < 0
            F = 0.0
        elseif J >= n
            F = 1.0
        else
            F = cdf[floor(Int, J)+1]
        end
        e = max(e, abs(F - phi_cdf(z)))
    end
    e
end
@assert abs(sup_err_exact_bin(1) - 0.3413) < 0.01      # n=1：两点分布 sup = 1/2−Φ(−1)
e_b1 = sup_err_exact_bin(25)
e_b2 = sup_err_exact_bin(2500)
ratio = e_b1 / e_b2
@assert e_b2 < e_b1 / 3
@assert 5 < ratio < 20                                 # ~√100 = 10
println("CLT rate (exact binomial): sup err(25)=", round(e_b1, digits=4),
        " err(2500)=", round(e_b2, digits=5), " ratio=", round(ratio, digits=2),
        " (~sqrt(100)): OK")

# ② χ² 双极限（例 52.D）：(Xₙ−n)/√n → N(0,2)；√Xₙ−√n → N(0,1/2)
function chisq_moments(n; trials = 4000)
    y = [sum(randn()^2 for _ in 1:n) for _ in 1:trials]
    a = (y .- n) ./ sqrt(n)               # → N(0,2)
    b = sqrt.(y) .- sqrt(n)               # → N(0,1/2)
    var(a), var(b)
end
va, vb = chisq_moments(200)
@assert abs(va - 2.0) < 0.15
@assert abs(vb - 0.5) < 0.05
println("chi-square double limit: Var((X-n)/sqrt(n)) = ", round(va, digits=3),
        " (->2), Var(sqrt(X)-sqrt(n)) = ", round(vb, digits=3), " (->1/2): OK")

# ③ Delta 相关系数：√n(rₙ−ρ) → N(0, (1−ρ²)²)（例 52.P）
function corr_delta_var(rho; n = 2000, trials = 600)
    rs = Float64[]
    L = [1.0 0.0; rho sqrt(1 - rho^2)]
    for _ in 1:trials
        sx = sy = sxx = syy = sxy = 0.0
        for _ in 1:n
            z = L * randn(2)
            x, y = z[1], z[2]
            sx += x; sy += y; sxx += x * x; syy += y * y; sxy += x * y
        end
        mx, my = sx / n, sy / n
        r = (sxy / n - mx * my) / sqrt((sxx / n - mx^2) * (syy / n - my^2))
        push!(rs, sqrt(n) * (r - rho))
    end
    var(rs)
end
v5 = corr_delta_var(0.5)
v8 = corr_delta_var(0.8)
@assert abs(v5 - (1 - 0.25)^2) / 0.5625 < 0.25   # 0.5625 ±25%
@assert abs(v8 - (1 - 0.64)^2) / 0.1296 < 0.35   # 0.1296 ±35%（小方差相对噪声大）
@assert v8 < v5                                    # ρ↑ ⟹ 渐近方差↓
println("Delta corr: n*Var(r-0.5) = ", round(v5, digits=3),
        " vs (1-rho^2)^2 = 0.563; rho=0.8: ", round(v8, digits=3),
        " vs 0.130: OK")

# ④ Berry-Esseen：Bernoulli(1/2) 的 sup 偏差（精确二项账）vs 界
#    36γ³/(√n σ³)：Rademacher 的 γ³ = σ³ = 1 ⟹ 界 = 36/√n
err100 = sup_err_exact_bin(100)
bound100 = 36 / sqrt(100)
@assert err100 <= bound100             # BE 界成立
@assert bound100 / err100 > 9          # 36 常数保守近 10 倍
println("Berry-Esseen: err(100) = ", round(err100, digits=4),
        " <= 36/sqrt(100) = 3.6 (constant 36 conservative x",
        round(bound100 / err100, digits=1), "): OK")

# ⑤ Lindeberg 破坏：首项 = ±√n（方差占比 1/2 不消失）。诊断发现对称
#    ±√n 双峰的 CDF 恰好贴着 Φ 走（sup 差 ~0.04 不显形）——真正的显形
#    在**峰度**：双峰化压峰（理论 kurt = (1+6+3)/4 = 2.5 < 3）。判据
#    = 偏离正态形状（kurt=3）的幅度显著增大。
function outlier_kurt(n; trials = 20_000, outlier = true)
    s4 = 0.0
    for _ in 1:trials
        s = outlier ? (rand() < 0.5 ? sqrt(n) : -sqrt(n)) : 0.0
        for _ in 1:n
            s += rand() < 0.5 ? 1.0 : -1.0
        end
        z = s / sqrt(outlier ? 2n : n)             # 标准化（含离群方差）
        s4 += z^4
    end
    s4 / trials
end
k_pure = outlier_kurt(200, outlier = false)
k_out = outlier_kurt(200, outlier = true)
@assert abs(k_pure - 3.0) < 0.2                   # 纯情形近正态
@assert abs(k_out - 3.0) > abs(k_pure - 3.0) + 0.3  # 形状偏离显著增大
@assert k_out < 2.9                                # 且方向 = 压峰双峰化（理论 2.5）
println("Lindeberg violation: kurtosis pure = ", round(k_pure, digits=2),
        " vs outlier-injected = ", round(k_out, digits=2), " (bimodal flattening, th 2.5): OK")

println("END ====")
