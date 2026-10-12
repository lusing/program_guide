# 52_riesz_thorin.jl —— Riesz-Thorin 插值与 Hilbert 变换（docs/52 实验）
# 通道：Julia 1.13 + LinearAlgebra/FFTW
using LinearAlgebra
using FFTW
using Printf
using Random

println("==== 52 Riesz-Thorin 与 Hilbert 变换 ====")

# ---------------------------------------------------------------
# 实验 1：三线定理（exp(ζ²) 在带域上的对数凸界）。
# |exp(ζ²)| = e^{Reζ²} = e^{x²−y²}，N(a) = e^{a²} 精确可算且 log-凸。
# ---------------------------------------------------------------
function exp1_three_lines()
    phi(z) = exp(z^2)
    N(a) = maximum(abs.(phi.(a .+ im .* collect(-40:0.05:40))))
    N0, N1 = N(0.15), N(0.85)
    for a in range(0.15, 0.85, length=25)
        t = (a - 0.15) / 0.7
        bound = N0^(1 - t) * N1^t
        @assert N(a) ≤ bound * (1 + 1e-10)
        @assert abs(N(a) - exp(a^2)) < 1e-9        # 精确值 e^{a²}
    end
    return (N0, N1)
end
n0, n1 = exp1_three_lines()
println(@sprintf("实验1 exp(ζ²) 三线界：N(0.15)=%.3f，N(0.85)=%.3f，25 内点 ≤ 几何插值且 = e^{a²}", n0, n1))

# ---------------------------------------------------------------
# 实验 2：矩阵 Riesz-Thorin（ℓᵖ→ℓ^q 有限维化身）。
# 端点 (2,2)：σ_max；(1,∞)：max|aᵢⱼ|。中间 p=3/2, q=3：数值幂迭代。
# 断言 log-凸插值界成立。
# ---------------------------------------------------------------
function lp_lq_norm(A::Matrix{Float64}, p::Float64, q::Float64; iters=400)
    # 幂迭代：x ↦ ‖A x‖_{q}^{q−1}·结构 |Σ|A'x|^{q−1}sign| 依 ℓ^p 归一
    n = size(A, 2)
    rng = MersenneTwister(52)
    x = abs.(randn(rng, n)) .+ 0.1
    for _ in 1:iters
        y = A * x
        # 对偶：g = ‖y‖_q 的梯度方向
        g = abs.(y) .^ (q - 1) .* sign.(y)
        z = abs.(A' * g) .^ (p - 1) .* sign.(A' * g)   # ℓ^p 对偶幂
        nz = norm(z, p)
        nz > 0 || break
        x = z ./ nz
    end
    # 范数估计：多随机向量取最大
    best = 0.0
    for _ in 1:60
        v = randn(rng, n)
        v = v ./ norm(v, p)
        best = max(best, norm(A * v, q))
    end
    v = x ./ norm(x, p)
    best = max(best, norm(A * v, q))
    return best
end
function exp2_matrix_rt()
    rng = MersenneTwister(5202)
    A = randn(rng, 64, 64)
    M22 = opnorm(A, 2)                      # (2,2) 端点
    M1i = maximum(abs.(A))                  # (1,∞) 端点
    # 线段中点（1/p,1/q) = (0.75,0.25)：p = 4/3, q = 4
    mmid = lp_lq_norm(A, 4 / 3, 4.0)
    bound_mid = sqrt(M22 * M1i)             # a = 1/2 的几何插值
    @assert mmid ≤ bound_mid * 1.05         # 定理必须成立（幂迭代只欠估计）
    return (M22, M1i, mmid, bound_mid)
end
M22, M1i, mmid, bmid = exp2_matrix_rt()
println(@sprintf("实验2 ‖A‖₂₂=%.2f，‖A‖₁∞=%.3f，线段中点 (4/3→4) 实测 %.3f ≤ 几何插值 %.3f", M22, M1i, mmid, bmid))

# ---------------------------------------------------------------
# 实验 3：Hilbert 变换三性质（FFT 实现：乘 −i·sign(ω)）。
# ---------------------------------------------------------------
hilbert(f::Vector{Float64}) = real.(ifft(fft(f) .* (-im .* sign.(fftfreq(length(f)) .* length(f)))))
function exp3_hilbert()
    rng = MersenneTwister(5232)
    n = 4096
    f = randn(rng, n)
    # 去 DC（乘子 0）与 Nyquist（乘子纯虚，被 real() 滤）两个特殊频点
    F = fft(f)
    F[1] = 0
    F[n ÷ 2 + 1] = 0
    f = real.(ifft(F))
    Hf = hilbert(f)
    @assert abs(norm(Hf) / norm(f) - 1) < 1e-6      # L² 等距（FFT 舍入级）
    HHf = hilbert(Hf)
    @assert norm(HHf + f) / norm(f) < 1e-6          # H² = −I（FFT 舍入级）
    # Lᵖ 范数曲线（光滑紧支函数，模板尺度化）
    t = collect(0:n-1) ./ n .* 40 .- 20
    g = exp.(-t .^ 2 / 8)
    G = fft(g); G[1] = 0; G[n ÷ 2 + 1] = 0   # 去特殊频点
    g = real.(ifft(G))
    Hg = hilbert(g)
    n2 = norm(Hg) / norm(g)
    @assert abs(n2 - 1) < 1e-6
    n4 = norm(Hg, 4) / norm(g, 4)
    @assert 0.7 < n4 < 1.8                          # ‖H‖₄ 有限（高斯非极值，可 <1；上界 √3）
    return (n2, n4)
end
h2, h4 = exp3_hilbert()
println(@sprintf("实验3 Hilbert：‖H‖₂ = %.10f（等距）；‖H‖₄ ≈ %.3f（有限，理论 ~√3=1.73 内）", h2, h4))

# ---------------------------------------------------------------
# 实验 4：Hilbert-Hankel 算子 1/(s+t) 的范数 = π。
# 对数网格上最大奇异值 → π。
# ---------------------------------------------------------------
function exp4_hankel_pi()
    # 收敛 ~ π(1 − c/√log L)：取三档对数区间验证单调上升并接近 π
    vals = Float64[]
    for (L, m) in ((1e4, 800), (1e6, 1500), (1e8, 3000))
        s = exp.(range(log(1e-6), log(L), length=m))
        A = [1.0 / (s[i] + s[j]) for i in 1:m, j in 1:m]
        w = s .* (log(L / 1e-6) / (m - 1))   # 对数网格测度权重 ds = s·dlog s
        W = sqrt.(w)
        Aw = W .* A .* W'
        push!(vals, maximum(svdvals(Aw)))
    end
    @assert vals[1] < vals[2] < vals[3]     # 单调逼近
    @assert abs(vals[3] - π) < 0.15         # 缓慢收敛（√log 律）
    return vals
end
vals_hh = exp4_hankel_pi()
println(@sprintf("实验4 Hilbert-Hankel σmax：%.3f → %.3f → %.3f ↗ π = 3.1416（√log 收敛）", vals_hh...))

println("END ====")
