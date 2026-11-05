# 第 60 章 Julia：布朗运动的 Fourier 构造与反射对账（固定种子）。
# ① K-L/Fourier 级数实弹：W_n(t) = Z₀t + √2 Σ (X_k sin2πkt + Y_k(1−cos2πkt))/(2πk)
#    的截断采样，验证 cov(W(1/4), W(3/4)) → 1/4、var W(1) → 1；
# ② 反射原理：网格化布朗的经验 P(max_{s≤1} B_s ≥ λ) vs 2(1−Φ(λ))。
println("==== 60 brownian_motion")
using Random, Statistics, SpecialFunctions

const rng = MersenneTwister(6001)

# ---------- ① Fourier 构造 ----------
function sample_fourier(n, npaths, ts)
    vals = zeros(npaths, length(ts))
    for p in 1:npaths
        z0 = randn(rng)
        xs = randn(rng, n)
        ys = randn(rng, n)
        for (j, t) in enumerate(ts)
            s = z0 * t
            for k in 1:n
                s += sqrt(2) * (xs[k] * sin(2π * k * t) + ys[k] * (1 - cos(2π * k * t))) / (2π * k)
            end
            vals[p, j] = s
        end
    end
    return vals
end
ts = [0.25, 0.75]
println("① Fourier 构造（理论 cov = min(1/4,3/4) = 1/4）：")
for n in [10, 100, 1000]
    v = sample_fourier(n, 5000, ts)
    c = cov(v[:, 1], v[:, 2])
    println("   n=", n, "：cov(W(1/4),W(3/4)) = ", round(c, digits=4),
            "，var W(1/4) = ", round(var(v[:, 1]), digits=4),
            "，var W(3/4) = ", round(var(v[:, 2]), digits=4))
    @assert abs(c - 0.25) < 0.05
    @assert abs(var(v[:, 1]) - 0.25) < 0.05
    @assert abs(var(v[:, 2]) - 0.75) < 0.06
end

# ---------- ② 反射原理 ----------
function max_ge(lam, nsteps, npaths)
    hit = 0
    dt = 1 / nsteps
    for _ in 1:npaths
        s = 0.0
        m = -Inf
        for _ in 1:nsteps
            s += sqrt(dt) * randn(rng)
            m = max(m, s)
            if m >= lam
                hit += 1
                break
            end
        end
    end
    return hit / npaths
end
phi(x) = 0.5 * (1 + erf(x / sqrt(2)))
println("② 反射原理（理论 P(max≥λ) = 2(1−Φ(λ))）：")
for lam in [0.5, 1.0, 1.5, 2.0]
    emp = max_ge(lam, 1024, 20000)
    theo = 2 * (1 - phi(lam))
    println("   λ=", lam, "：模拟 ", round(emp, digits=4), " vs 理论 ", round(theo, digits=4),
            "（偏差 ", round(abs(emp - theo), digits=4), "）")
    @assert abs(emp - theo) < 0.02
end

println("END ====")
