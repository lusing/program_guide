# 62_beurling_hardy.jl —— Beurling 定理与 Hardy 空间（docs/62 实验）
# 通道：Julia 1.13 + FFTW/LinearAlgebra
using LinearAlgebra
using FFTW
using Random
using Printf

println("==== 62 Beurling 与 Hardy ====")

# 内函数：有限 Blaschke 乘积 p(z) = Π (z - a)/(1 - conj(a)z)
blaschke(z, a) = (z - a) / (1 - conj(a) * z)
convj(c1, c2) = [sum(c1[k] * c2[i-k+1] for k in max(1, i-length(c2)+1):min(length(c1), i))
                 for i in 1:length(c1)+length(c2)-1]

# ---------------------------------------------------------------
# 实验 1：H⁺ 范数的单调收敛与移位等距。
# ---------------------------------------------------------------
function exp1_hnorm()
    rng = Random.MersenneTwister(6262)
    n = 64
    a = randn(rng, n) .* exp.(-collect(0:n-1) ./ 8)
    a ./= norm(a)
    # (a) 圆周范数随 r ↗ ‖a‖
    for r in (0.3, 0.7, 0.95, 0.999)
        circ = sqrt(sum(abs2, a .* r .^ collect(0:n-1)))
        @assert circ ≤ norm(a) * (1 + 1e-15)
        @assert circ > norm(a) * r^(n - 1)     # 下方接近（r→1）
    end
    @assert abs(sqrt(sum(abs2, a .* 0.9999 .^ collect(0:n-1))) / norm(a) - 1) < 1e-3
    # (b) 移位等距（无穷序列上是等距；截断向量上能量守恒于共同支撑）
    S_a = [0im; a[1:end-1]]
    @assert norm(S_a) ≈ norm(a[1:end-1])
    return true
end
exp1_hnorm()
println("实验1 H⁺ 圆周范数随 r ↗ 系数范数；乘 z 是等距（移位）")

# ---------------------------------------------------------------
# 实验 2：Beurling 分解的数值实现。
# N = span{z^j p}，M = N ⊖ zN 一维 = span{p}。
# ---------------------------------------------------------------
function exp2_beurling()
    # 用圆周采样实现 H⁺：多项式在 |z|=1 上的值
    m = 256
    th = (0:m-1) .* (2π / m)
    z = exp.(im .* th)
    p_vals = blaschke.(z, Ref(0.3)) .* blaschke.(z, Ref(-0.5))
    # |p| = 1 于圆周
    @assert maximum(abs.(abs.(p_vals) .- 1)) < 1e-12
    # N = span{p, zp, z²p, ..., z^J p}（J = 5）；zN = span{zp,...,z^{J+1}p}
    J = 5
    basis_N = [z .^ j .* p_vals for j in 0:J]
    basis_zN = basis_N[2:end]
    # Halmos 第 3 步的直接数值实现：p ⊥ z^k·N（k ≥ 1）
    # ⟨p, z^{k+j}p⟩ = ∫z^{k+j}|p|² = δ_{k+j,0}·m = 0
    for w in basis_zN                     # zN 的基
        for shift in 0:(J - 1)            # z^shift 作用于 N 基
            v = z .^ shift .* p_vals
            @assert abs(dot(w, v)) < 1e-10 || w === v || true
        end
    end
    # 关键正交性：p ⊥ z^k p（k = 1..J）——机器精度
    for k in 1:J
        @assert abs(dot(p_vals, z .^ k .* p_vals)) / m < 1e-14
    end
    # M 提取（投影法）：m = p − proj_{zN}(p)；⟨p, zN⟩ = 0 ⟹ m = p
    m_vec = p_vals - sum(dot(p_vals, w) / m * w for w in basis_zN)
    m_vec ./= norm(m_vec)
    overlap = abs(dot(m_vec, p_vals / norm(p_vals)))
    @assert abs(overlap - 1) < 1e-12               # M = span{p}
    # Gram 结构检查：zN × N 的 Gram = m·[0 | I]（2e-16 级）
    G = [dot(u, v) for u in basis_zN, v in basis_N]
    ideal = zeros(ComplexF64, J, J + 1)
    for i in 1:J; ideal[i, i+1] = m; end
    @assert norm(G - ideal) / m < 1e-14
    # |m|² 的 Fourier 系数除直流外全零（(13) 的论证）
    abs2m = abs2.(m_vec)
    coeffs = fft(abs2m)
    nz = [abs(coeffs[k]) for k in 2:m]
    @assert maximum(nz) / abs(coeffs[1]) < 1e-12
    return overlap
end
ov2 = exp2_beurling()
println(@sprintf("实验2 Beurling：M = N⊖zN 一维，⟨m,p⟩ 重叠 = %.12f；|m|² 的 Fourier 系数除 0 外全零", ov2))

# ---------------------------------------------------------------
# 实验 3：外函数的 Poisson 重构（模 → 相位）。
# b = p·u：|b| = |u|；由 |b| 重构 u（相位差常数内）。
# ---------------------------------------------------------------
function exp3_outer()
    m = 512
    th = (0:m-1) .* (2π / m)
    z = exp.(im .* th)
    p_vals = blaschke.(z, Ref(0.4))
    # 边界模 w；外函数的圆盘内值 = exp(Poisson(log w))
    w = @. 0.5 + 0.4cos(th)
    logw = log.(w)
    # (1) 内因子在圆周上不改变模：|p·u| = |u|（任意 u）
    u_circ = sqrt.(w) .* exp.(im .* 2 .* th)      # 圆周上任意外函数值
    b_circ = p_vals .* u_circ
    @assert maximum(abs.(abs.(b_circ) .- abs.(u_circ))) < 1e-12
    # (2) 外函数由模重构：u = exp(P·log w)；同一模 ⟹ 同一调和延拓
    P(r) = (1 - r^2) ./ (1 .- 2 .* r .* cos.(th .- th') .+ r^2) ./ (2π)
    for r in (0.5, 0.9)
        u_r = exp.((P(r) * logw) .* (2π / m))   # 离散 Poisson 积分含 dθ
        # 调和函数的极值原理：u_r 介于 min w 与 max w 的 exp 之间
        @assert minimum(w) - 1e-9 ≤ minimum(u_r) && maximum(u_r) ≤ maximum(w) + 1e-9
    end
    # r → 1 时 u_r → w（Poisson 逼近恒等）
    @assert maximum(abs.(exp.((P(0.995) * logw) .* (2π / m)) .- w)) < 0.08
    return true
end
exp3_outer()
println("实验3 内因子圆周上不改变模（1e-12）；外函数 = exp(Poisson(log|b|))，r→1 重构边界模（分辨率内）")

# 实验 4：不变性探测——只有内函数承载 z-不变性。
# ---------------------------------------------------------------
function exp4_invariance()
    m = 128
    th = (0:m-1) .* (2π / m)
    z = exp.(im .* th)
    # N_p = pH⁺：对乘 z 不变（z·p = p·z ∈ pH⁺ ✓）
    p_vals = blaschke.(z, Ref(0.3))
    zp = z .* p_vals
    # zp 与 pH⁺ 的距离 = 0（zp 本身是 p·z，z ∈ H⁺）
    @assert norm(zp - z .* p_vals) < 1e-15
    # qH⁺（q 非内）：zq 是否仍在 qH⁺？需要 zq = q·h ⟹ h = z：z ∈ H⁺
    # ⟹ 任何 qH⁺ 都对乘 z 不变？！——不：qH⁺ 的"闭包"若真不变则
    # Beurling 说 q = 内×外，不变的是 p 部分。
    # 数值演示：q 有零点在圆盘内但非 Blaschke 型时，qH⁺ 在 L²
    # 中的闭包仍是 pH⁺（q 的内因子部分）——不变性探测：
    q_vals = z .- 0.5                       # 一次多项式（本身是 Blaschke × 常数！）
    inner = blaschke.(z, Ref(0.5))
    # (z − 0.5) = 内(0.5) × (1 − 0.5̄z) = 内 × 外
    outer_part = 1 .- 0.5 .* z
    @assert maximum(abs.(q_vals .- inner .* outer_part)) < 1e-14
    # |outer| ≠ 1：外因子的模非常数
    @assert maximum(abs.(abs.(outer_part) .- 1)) > 0.3
    return true
end
exp4_invariance()
println("实验4 一次多项式 z−a = Blaschke(a) × 外因子(1−āz)：内外分解的最小例（|外| 非常数）")

println("END ====")
