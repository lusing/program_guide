# 53_wiener_tauberian.jl —— Wiener Tauberian 定理（docs/53 实验）
# 通道：Julia 1.13 + FFTW
using FFTW
using LinearAlgebra
using Printf
using Random

println("==== 53 Wiener Tauberian ====")

# ---------------------------------------------------------------
# 实验 1：平移张成的两态（ᶠ 无零点 vs 有零点）。
# 目标 g = 鼓包 + 振荡；基族 {f(·−tⱼ)} 等距平移。
# Gaussian：ᶠ > 0 处处 → 误差随 N → 0；
# Gaussian 导数：均值 0 → ᶠ(0) = 0 → 常数分量不可逼近。
# ---------------------------------------------------------------
function exp1_translation_span()
    n = 1024
    ts = collect(range(-16.0, 16.0, length=n))   # 窗口 ≫ 平移范围：防截断泄漏均值
    g = @. exp(-ts^2 / 2) * (1 + 0.5sin(3ts))   # 目标集中于 |t|<6（平移可达区）
    # 目标保留均值：常数分量正是有零点族的结构障碍（Lax 的必要性论证）
    f_gauss(s) = exp(-s^2 / 2)
    f_deriv(s) = -s * exp(-s^2 / 2)   # 均值 0 ⟹ ᶠ(0) = 0
    function span_err(f, N)
        dt = ts[2] - ts[1]
        shifts = collect(range(-6.0, 6.0, length=N))
        A = hcat([f.(ts .- t) for t in shifts]...)
        c = A \ g
        norm(A * c - g) / norm(g)
    end
    e_good = [span_err(f_gauss, N) for N in (10, 30, 100)]
    e_bad = [span_err(f_deriv, N) for N in (10, 30, 100)]
    @assert e_good[3] < 0.05           # 无零点族：张成
    @assert e_good[1] > e_good[2] > e_good[3]
    @assert e_bad[3] > 0.2             # 有零点族：结构性失败（均值分量不可及）
    return (e_good, e_bad)
end
eg, eb = exp1_translation_span()
println(@sprintf("实验1 Gaussian（ᶠ≠0）误差：%.3f → %.3f → %.3f（张成）；导数（ᶠ(0)=0）：%.3f → %.3f（停）",
                 eg..., eb[1], eb[3]))

# ---------------------------------------------------------------
# 实验 2：乘法泛函（(f*g)^ = ᶠ·ĝ）。
# ---------------------------------------------------------------
function exp2_multiplicative()
    rng = Random.MersenneTwister(5353)
    n = 512
    f = exp.(-((collect(0:n-1) .- n/2) .^ 2) ./ 500)
    g = randn(rng, n)
    fg = real.(ifft(fft(f) .* fft(g)))          # 循环卷积
    Ff, Fg, Ffg = fft(f), fft(g), fft(fg)
    # 循环卷积定理（无归一化因子）
    @assert norm(Ffg - Ff .* Fg) / norm(Ff .* Fg) < 1e-12
    return true
end
exp2_multiplicative()
println("实验2 (f*g)^ = ᶠ·ĝ 机器精度成立（乘法泛函 ρ_ξ(g)=ĝ(ξ)）")

# ---------------------------------------------------------------
# 实验 3：Tauberian 平均先行（定理 13）。
# n(s) = a + 缓慢振荡（有界、不逐点收敛）；(f*n)(s) → a。
# ---------------------------------------------------------------
function exp3_tauberian()
    n_pts = 2^15
    s = collect(0:n_pts-1) .* 0.01              # s ∈ [0, 327]
    a = 2.7
    nfun = @. a + sin(s) / sqrt(1 + s)     # 固定周期振荡 + 1/√s 衰减：
                                            # (f*n) → a（Riemann-Lebesgue），n 本身仍振荡
    σ = 8.0
    f = @. exp(-(s .- s[end] / 2)^2 / (2σ^2))
    f ./= sum(f) .* 0.01                        # 归一化 ∫f = 1
    fn = real.(ifft(fft(nfun) .* fft(f))) .* 0.01
    # 尾部对比：n 本身仍振荡，f*n 已收敛到 a
    tail = n_pts-div(n_pts, 10):n_pts
    osc_n = maximum(abs.(nfun[tail] .- a))
    tailconv = abs(sum(fn[tail]) / length(tail) - a)
    @assert tailconv < 0.015                    # 卷积后 → a
    @assert osc_n > 0.03                        # n 本身仍振荡
    return (osc_n, tailconv)
end
osc3, conv3 = exp3_tauberian()
println(@sprintf("实验3 尾部：n 偏离 a 幅度 %.3f（仍振荡）vs (f*n) 均值偏离 %.4f（→ a）", osc3, conv3))

println("END ====")
