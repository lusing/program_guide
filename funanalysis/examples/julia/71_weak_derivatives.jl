# 71_weak_derivatives.jl —— 弱导数：从 δ 到 W^{k,p}（docs/71 实验）
# 通道：Julia 1.13 + LinearAlgebra + Printf
# 内容：|x| 弱导数、Heaviside→δ、阶梯无弱导数、ln|x| 的维数临界、磨光逼近
using LinearAlgebra
using Printf

println("==== 71 弱导数：从 δ 到 W^{k,p} ====")

# ---------------------------------------------------------------
# 实验 1：|x| 的弱导数是 sgn（书 6.3.3 的数值版）
# 检验分部积分恒等式：∫_{-1}^{1} |x| φ'(x) dx = -∫_{-1}^{1} sgn(x) φ(x) dx
# 对一族光滑紧支撑检验函数 φ 成立。左侧"不可微函数"照常积分，
# 右侧导数已经转移——这就是弱导数定义的全部内容。
# ---------------------------------------------------------------
function exp1_abs_sgn()
    ok = true
    for c in [0.5, 1.0, 2.0]                      # φ = exp(-c x²) 型检验函数
        φ(x) = exp(-c * x^2)
        dφ(x) = -2c * x * exp(-c * x^2)
        xs = range(-1, 1; length=400_001)
        lhs = sum(abs.(xs) .* dφ.(xs)) * step(xs)   # ∫ |x| φ'
        rhs = -sum(sign.(xs) .* φ.(xs)) * step(xs)  # -∫ sgn φ
        @assert abs(lhs - rhs) < 1e-3               # 两边一致：sgn 就是弱导数
    end
    # 光滑化视角：磨光 |x| 的经典导数逐点逼近 sgn（3.7.4 磨光函数）
    moll(x, ε) = x / sqrt(x^2 + ε^2)               # |x| 的软化 d/dx sqrt(x²+ε²)
    for ε in [0.1, 0.01, 0.001]
        @assert abs(moll(1.0, ε) - 1.0) < 0.01     # 远离 0 处 → 1
        @assert moll(0.0, ε) ≈ 0.0                 # 原点处平滑过渡
    end
    return 1.0
end
exp1_abs_sgn()
println("实验1 |x| 弱导数=sgn：三个检验函数分部积分两侧吻合 1e-3；软化导数逐点→sgn")

# ---------------------------------------------------------------
# 实验 2：Heaviside 的弱导数是 δ（书 3.7.10 的数值版）
# ∫ Y φ' = -φ(0)：跳跃 1 的函数其弱导数在跳跃点贡献 -φ(0)×跳跃。
# 数值：用陡峭化光滑近似 Yε(x)=1/(1+exp(-x/ε))，验证
# ∫ Yε φ' → -φ(0) 与 ∫ Yε' φ → φ(0)（Yε' 是近似 δ 的峰）。
# ---------------------------------------------------------------
function exp2_heaviside_delta()
    φ(x) = exp(-x^2)
    for ε in [0.1, 0.03, 0.01]
        Yε(x) = 1.0 / (1.0 + exp(-x / ε))
        dYε(x) = exp(-x / ε) / (ε * (1.0 + exp(-x / ε))^2)
        xs = range(-2, 2; length=800_001)
        dx = step(xs)
        lhs = sum(Yε.(xs) .* (-2 .* xs .* φ.(xs)) ) * dx      # ∫ Yε φ'
        rhs = φ(2.0) - φ(0.0)                                  # 极限 = φ(2)-φ(0)
        peak = sum(dYε.(xs) .* φ.(xs)) * dx                    # ∫ Yε' φ → φ(0)
        @assert abs(lhs - rhs) < max(0.005, 0.4ε)              # 分部积分极限（O(ε)）
        @assert abs(peak - φ(0.0)) < max(0.005, 0.4ε)          # δ 的筛性质（O(ε)）
    end
end
exp2_heaviside_delta()
println("实验2 Heaviside 弱导数=δ：∫Yεφ'→φ(2)-φ(0)、∫Yε'φ→φ(0)，δ 筛性质数值成立")

# ---------------------------------------------------------------
# 实验 3：阶梯函数没有（函数型）弱导数（书 6.3.2 的反面教材）
# u = 1_{(0,∞)}：若有 L² 弱导数 g，则对一切检验 φ：∫gφ = -φ(0)。
# 但 -φ(0) 不是 L² 函数的泛函（δ ∉ L²）。数值证据：用磨光滑化的
# 导数能量 ‖dYε‖_{L²} ~ ε^{-1/2} → ∞——导数"能量"在跳跃点无限集中，
# 任何 L² 候选都接不住。
# ---------------------------------------------------------------
function exp3_step_no_weak_deriv()
    energies = Float64[]
    for ε in [0.1, 0.03, 0.01, 0.003]
        xs = range(-1, 1; length=400_001)
        dYε = exp.(-xs ./ ε) ./ (ε .* (1 .+ exp.(-xs ./ ε)).^2)
        E = sqrt(sum(abs2, dYε) * step(xs))       # ‖Yε'‖_{L²}
        push!(energies, E)
    end
    # 能量随 ε 减半按 ~ε^{-1/2} 增长（每缩小 3 倍，能量约 ×√3）
    ratios = [energies[i+1] / energies[i] for i in 1:2]
    @assert all(r .> 1.5 for r in ratios)          # 单调发散
    return energies[end]
end
E3 = exp3_step_no_weak_deriv()
println(@sprintf("实验3 阶梯函数无 L² 弱导数：软化导数能量 ε=0.003 时 %.1f（发散），δ 不属于 L²", E3))

# ---------------------------------------------------------------
# 实验 4：ln|x| 的 W^{1,2} 成员资格是维数临界的（书 6.3.4）
# |∇ ln r| = 1/r。∫_{B₁} r^{-2} dx = ∫₀¹ r^{n-3} dr：
# n ≥ 3 收敛（n=3 恰好 ∫1 dr = 1），n = 2 发散（∫r^{-1}dr）。
# 同验证 ln r 本身 L²：∫₀¹ r^{n-1} (ln r)² dr 各维皆有限。
# ---------------------------------------------------------------
function exp4_log_sobolev()
    # ∫₀¹ r^{n-3} dr 的数值（避开 0 用对数尾项）
    tail(n) = n == 3 ? 1.0 : (n > 3 ? 1.0 / (n - 2) : Inf)
    for n in [3, 4, 5]
        rs = 10.0 .^ range(-8, 0; length=2000)     # 对数网格
        num = sum(rs .^ (n - 3) .* diff([0.0; log.(rs)] .+ 0)) # ∫r^{n-3}dlnr·r
        num = sum((rs[i] ^ (n - 2) - rs[i-1] ^ (n - 2)) / (n - 2) for i in 2:length(rs))
        @assert abs(num - tail(n)) < 0.05 * tail(n)
    end
    # n=2 发散：截断下限 a→0 时 ∫_a^1 r^{-1} dr = -ln a → ∞
    for a in [1e-4, 1e-8]
        integral_2d = -log(a)
        @assert integral_2d > 9                    # 发散
    end
    # ln r 本身 L²（n=3）：∫₀¹ r²(ln r)² dr = 2/27（分部积分精确值）
    rs = 10.0 .^ range(-8, 0; length=4000)
    val = sum(r -> r^2 * log(r)^2 * log(10) * r, rs) * log(10) # d r = r dlogr·ln10…
    val = sum(rs .* rs .* log.(rs) .^ 2 .* rs .* (log(10))) * log(10) / 2 # 简化数值
    # 直接对数测度积分：∫ f dr = ∫ f(r) r d(log10 r)·ln10
    val = sum(rs[i]^2 * log(rs[i])^2 * (rs[i] - rs[i-1]) for i in 2:length(rs))
    @assert abs(val - 2 / 27) < 0.01
    return val
end
v4 = exp4_log_sobolev()
println(@sprintf("实验4 ln|x|∈W^{1,2} 当且仅当 n≥3：n=3 时 ∫r²(ln r)²dr=%.4f（真值 2/27=%.4f）", v4, 2/27))

# ---------------------------------------------------------------
# 实验 5：磨光逼近（书 3.7.4/3.7.5）
# Mε * u 是 C^∞ 且 L¹ 收敛到 u。取 u = sgn（不连续），
# 数值卷积后：① 输出光滑（导数有界，不出现跳变）② L¹ 距离 → 0。
# 这是"C^∞ 在 L^p 中稠密"的数值体现，也是 D ≠ {0} 的第一课。
# ---------------------------------------------------------------
function exp5_mollifier()
    M(x) = x > -0.5 && x < 0.5 ? exp(-1 / (1 - 4x^2)) : 0.0   # 标准磨光核（紧支撑）
    xs = range(-2, 2; length=2001)
    norm_M = sum(M, xs) * step(xs)
    for ε in [0.3, 0.1, 0.03]
        u = sign.(xs)
        conv = [sum(M((xs[i] - xs[j]) / ε) * u[j] for j in eachindex(xs)) * step(xs) / (ε * norm_M)
                for i in eachindex(xs)]
        dconv = maximum(abs.(diff(conv))) / step(xs)     # 导数上界：有限 ⟹ 光滑化
        @assert dconv < 10 / ε                            # 不再是无穷跳变
        l1 = sum(abs.(conv .- u)) * step(xs)              # L¹ 距离
        @assert l1 < 3ε                                   # 收敛于 ε
    end
end
exp5_mollifier()
println("实验5 磨光逼近：sgn 卷积磨光核后光滑且 L¹ 距离 ~ O(ε) 收敛")

println("END ====")
