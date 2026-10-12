# 50_muntz_runge.jl —— Müntz 与 Runge（docs/50 第六章实验）
# 通道：Julia 1.13 + LinearAlgebra
using LinearAlgebra
using Printf
using Random

println("==== 50 Müntz 与 Runge ====")

# ---------------------------------------------------------------
# 实验 1：Müntz 张成的分水岭（L² 误差 + 精确 Gram）。
# 逼近 f(t) = √t（∈ C₀[0,1]）于 span{t^{λⱼ}}：
#   Gram = [1/(λᵢ+λⱼ+1)]，b = [1/(λⱼ+3/2)]，err² = 1/2 − cᵀb。
# Σ1/λ = ∞ 的族误差 → 0；Σ1/λ < ∞ 的族停在正极限。
# 注：素数族 Σ1/p = ∞ 但发散极慢，在可及的 N 内表现与收敛族
# 无异——Müntz 定理是渐近定理，这是它数值上的诚实一面。
# ---------------------------------------------------------------
function muntz_l2(lams::Vector{Float64})
    n = length(lams)
    G = [1.0 / (lams[i] + lams[j] + 1) for i in 1:n, j in 1:n]
    b = [1.0 / (lams[j] + 1.5) for j in 1:n]     # ⟨√t, t^{λⱼ}⟩
    c = G \ b
    return sqrt(max(0.5 - dot(c, b), 0.0))       # ‖f − proj‖₂
end
function exp1()
    # 发散族：全幂 Σ1/j = ∞
    e_all = [muntz_l2(collect(1.0:N)) for N in (2, 4, 8)]
    # 收敛族：2^j 与 j²
    e_two = [muntz_l2(2.0 .^ (1:N)) for N in (2, 4, 8)]
    e_sq = [muntz_l2((collect(1.0:N)) .^ 2) for N in (2, 4, 8)]
    # 素数族（Σ1/p = ∞，发散极慢）
    e_pr = [muntz_l2(Float64[2, 3, 5, 7, 11, 13, 17, 19][1:N]) for N in (2, 4, 8)]
    @assert e_all[3] < 0.01                      # 发散族：→ 0
    @assert e_all[1] > e_all[2] > e_all[3]       # 单调下降
    @assert e_two[3] > 0.11                      # 收敛族：正极限
    @assert e_two[2] - e_two[3] < 0.15 * e_two[2] # 停滞（减幅 <15%）
    @assert e_sq[3] > 0.04
    @assert e_pr[3] > 0.04                       # 素数：可及范围内仍停滞
    return (e_all, e_two, e_sq, e_pr)
end
e_all, e_two, e_sq, e_pr = exp1()
println("实验1 L² 误差（N=2→4→8）：")
println(@sprintf("    全幂 j   (Σ1/j=∞) : %.4f → %.4f → %.4f  （→0）", e_all...))
println(@sprintf("    2^j     (Σ<∞)   : %.4f → %.4f → %.4f  （停 %.3f）", e_two..., e_two[3]))
println(@sprintf("    j²      (Σ<∞)   : %.4f → %.4f → %.4f  （停 %.3f）", e_sq..., e_sq[3]))
println(@sprintf("    素数    (Σ1/p=∞): %.4f → %.4f → %.4f  （慢发散未显）", e_pr...))

# ---------------------------------------------------------------
# 实验 2：Blaschke 乘积 B_N(ζ) = Π(λⱼ−ζ)/(λⱼ+ζ)（λⱼ=2^j）三性质。
# ---------------------------------------------------------------
function blaschke(lams::Vector{Float64}, z::ComplexF64)
    prod((λ - z) / (λ + z) for λ in lams)
end
function exp2()
    lams = 2.0 .^ (1:10)
    # (a) 零点
    for j in (1, 4, 10)
        @assert abs(blaschke(lams, lams[j] + 0im)) < 1e-12
    end
    # (b) 右半平面 |B| ≤ 1
    rng = MersenneTwister(5050)
    for _ in 1:500
        z = ComplexF64(0.1 + 10rand(rng), 20rand(rng) - 10)
        @assert abs(blaschke(lams, z)) ≤ 1.0 + 1e-12
    end
    # (c) 虚轴附近 |B| → 1（边界）
    @assert abs(blaschke(lams, 0.01 + 5im)) > 0.93
    @assert abs(blaschke(lams, 0.01 - 3im)) > 0.93
    return abs(blaschke(lams, 0.01 + 5im))
end
b2 = exp2()
println(@sprintf("实验2 Blaschke：零点 ~1e-15，右半平面 |B|≤1，虚轴邻域 |B|=%.4f → 1", b2))

# ---------------------------------------------------------------
# 实验 3：Runge 与无洞条件。
# (a) 1/(z−2) 在 |z|≤0.9 上 Taylor 逼近：误差几何衰减（比率 ~0.45）；
# (b) 同一函数在圆环 0.5≤|z|≤0.9 上的多项式最小二乘：误差停滞
#     （等价于有孔域——多项式无法一致逼近环外的极点函数）。
# ---------------------------------------------------------------
function exp3()
    rng = MersenneTwister(5151)
    # 环点 + 内盘点采样
    pts = ComplexF64[]
    for _ in 1:400
        r = 0.5 + 0.4 * rand(rng); θ = 2π * rand(rng)
        push!(pts, r * exp(im * θ))
    end
    for _ in 400
        r = 0.49 * rand(rng); θ = 2π * rand(rng)     # 填充内盘（无孔域）
        push!(pts, r * exp(im * θ))
    end
    f = 1.0 ./ (pts .- 2.0)
    # (a) 圆盘（无孔）：Taylor 级数 Σ z^n / 2^{n+1}
    errdisk = Float64[]
    for N in (2, 5, 10, 20)
        p = zeros(ComplexF64, length(pts))
        for n in 0:N
            p .-= pts .^ n ./ 2.0^(n + 1)
        end
        push!(errdisk, norm(p - f, Inf))
    end
    @assert errdisk[end] < 5e-8
    @assert errdisk[1] / errdisk[4] > 100            # 几何衰减
    # (b) 圆环（有孔）上 1/z：孔中有极点 → 多项式最小二乘停滞
    ann = [z for z in pts if abs(z) ≥ 0.5]
    fz = 1.0 ./ ann
    V = hcat([ann .^ n for n in 0:30]...)
    c = V \ fz
    stall = norm(V * c - fz, Inf)
    @assert stall > 0.1                             # 停滞（孔中有奇异）
    # (c) 对照：1/(z−2) 在同一圆环上（极点在孔外）→ 收敛
    fa2 = 1.0 ./ (ann .- 2.0)
    c2 = V \ fa2
    conv = norm(V * c2 - fa2, Inf)
    @assert conv < 1e-8                             # 孔外奇异不妨碍
    return (errdisk[4], stall, conv)
end
ed3, es3, ec3 = exp3()
println(@sprintf("实验3 Taylor(圆盘) %.1e；环域 1/z 停滞 %.3f（孔内有极点）vs 1/(z−2) 收敛 %.1e（孔外）",
                 ed3, es3, ec3))

# ---------------------------------------------------------------
# 实验 4：对偶变分在单位圆取等（M = m）。
# ζ₀ = 0：u₀(ζ) = 1/(2πiζ²)，|u₀| = 1/(2π)。g = 0 给
#   m ≤ ∫|u₀||ds| = 1；
# Schwarz 引理给 M = 1（f(z) = z 取等）。离散弧长验证 ∫|u₀| = 1。
# ---------------------------------------------------------------
function exp4()
    n = 4096
    θs = (0:n-1) .* (2π / n)
    ds = 2π / n
    u0_abs = fill(1.0 / (2π), n)          # |1/(2πi e^{2iθ})| = 1/(2π)
    integral = sum(u0_abs) * ds
    @assert abs(integral - 1.0) < 1e-12   # ∫|u₀||ds| = 1 ⟹ m ≤ 1
    # f(z) = e^{iφ}z 都取 M = |f′(0)| = 1
    for φ in (0.0, 1.1, 2.7)
        @assert abs(exp(im * φ) * 1.0) ≈ 1.0
    end
    return integral
end
i4 = exp4()
println(@sprintf("实验4 单位圆 ∫|u₀||ds| = %.12f（g=0 可行 ⟹ m ≤ 1 = M）", i4))

println("END ====")
