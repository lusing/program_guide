# 56_trace_class.jl —— 迹类算子与 Lidskii 迹公式（docs/56 实验）
# 通道：Julia 1.13 + LinearAlgebra
using LinearAlgebra
using Printf
using Random

println("==== 56 迹类与 Lidskii ====")

# ---------------------------------------------------------------
# 实验 1：Weyl 不等式 (20)(21)。
# 随机非对称矩阵：Σ|λ| ≤ Σs；Π|1+rλ| ≤ Π(1+rs)（r 四档）。
# 正交矩阵取等。
# ---------------------------------------------------------------
function exp1_weyl()
    rng = MersenneTwister(5656)
    n = 40
    A = randn(rng, n, n)
    ev = eigvals(A)
    sv = svdvals(A)
    @assert sum(abs, ev) ≤ sum(sv) * (1 + 1e-12)          # (20)
    for r in (0.1, 1.0, 10.0, 100.0)
        @assert prod(abs.(1 .+ r .* ev)) ≤ prod(1 .+ r .* sv) * (1 + 1e-9)  # (21)
    end
    # 正交矩阵：|λⱼ| = sⱼ = 1 ⟹ 两边取等
    Q = Matrix(qr(randn(rng, n, n)).Q)
    evq = eigvals(Q)
    svq = svdvals(Q)
    @assert abs(sum(abs, evq) - sum(svq)) < 1e-10
    return (sum(abs, ev) / sum(sv), sum(abs, evq) / sum(svq))
end
ratio1, ratio1q = exp1_weyl()
println(@sprintf("实验1 Weyl：非正规 Σ|λ|/Σs = %.3f（<1）；正交 %.6f（=1 取等）", ratio1, ratio1q))

# ---------------------------------------------------------------
# 实验 2：Hilbert 矩阵反例（有界、对称、正，但非迹类）。
# Σλₙ（= Σsₙ，对称正定）部分和随 n 发散；∫对角 = ∫1/(2x)dx = ∞。
# ---------------------------------------------------------------
function exp2_hilbert()
    for n in (100, 400, 1600)
        H = [1.0 / (i + j - 1) for i in 1:n, j in 1:n]
        ev = eigvals(Symmetric(H))
        s = sum(ev)                                  # 对称正：Σλ = Σs = tr
        @assert s > 0.4 * log(n)                     # ~ log n 增长（发散）
    end
    return true
end
exp2_hilbert()
println("实验2 Hilbert 矩阵：Σλₙ = tr ~ log n 增长（n=100→1600 不收敛）——非迹类")

# ---------------------------------------------------------------
# 实验 3：min(x,y) 核全套（Mercer + 迹公式 + 行列式乘积）。
# ---------------------------------------------------------------
function exp3_min_kernel()
    n = 400
    xs = (collect(1:n) .- 0.5) ./ n
    w = 1.0 / n
    K = w .* [min(xs[i], xs[j]) for i in 1:n, j in 1:n]
    F = eigen(Symmetric(Matrix(K)))
    ev = reverse(F.values)
    vecs = reverse(F.vectors, dims=2)                  # 列与降序值配对
    analytic = [1 / ((j - 0.5)^2 * π^2) for j in 1:50]
    @assert abs(ev[1] - analytic[1]) / analytic[1] < 1e-5
    # Mercer 重构：K(s,t) ≈ Σ_{j≤J} κⱼeⱼ(s)eⱼ(t)
    J = 60
    Krec = (vecs[:, 1:J] .* (ev[1:J]')) * (vecs[:, 1:J])'
    err = norm(K - Krec) / norm(K)
    @assert err < 0.02
    # 迹公式：tr = ∫对角 = 1/2 = Σκⱼ（解析）
    @assert abs(sum(ev) - 0.5) < 1e-9                # 离散对角和 = tr 精确
    tail = sum(1 / ((j - 0.5)^2 * π^2) for j in 51:10^6)
    @assert abs(sum(ev[1:50]) + tail - 0.5) < 2e-3   # 解析和 = 1/2
    # det = Π(1+tκⱼ)
    t = 0.7
    Ddet = det(I + t .* Matrix(K))
    Dprod = prod(1 + t * ev[j] for j in 1:30) *
            prod(1 + t / ((j - 0.5)^2 * π^2) for j in 31:10^5)
    @assert abs(Ddet - Dprod) / Ddet < 1e-4
    return (err, Ddet)
end
mercErr, dval = exp3_min_kernel()
println(@sprintf("实验3 min 核：Mercer 60 项重构误差 %.1e；tr = 1/2 = Σκⱼ（解析一致）；det = Π(1+tκⱼ) = %.4f", mercErr, dval))

# ---------------------------------------------------------------
# 实验 4：迹的交换不变性 + 双基刻画的极基取等。
# ---------------------------------------------------------------
function exp4_trace_properties()
    rng = MersenneTwister(5646)
    n = 60
    A = randn(rng, n, n)
    B = randn(rng, n, n)
    @assert abs(tr(A * B) - tr(B * A)) / max(abs(tr(A * B)), 1e-12) < 1e-12
    @assert abs(tr(A)) ≤ sum(svdvals(A))
    # 双基刻画 ≤：随机正交基 F = QU1, E = QU2
    U1 = qr(randn(rng, n, n)).Q
    U2 = qr(randn(rng, n, n)).Q
    val = sum(abs, diag(U2' * A * U1))
    @assert val ≤ sum(svdvals(A)) * (1 + 1e-12)
    # 极基取等：SVD A = UΣV' ⟹ F = V 列，E = U 列
    U, S, V = svd(A)
    @assert abs(sum(abs, diag(U' * A * V)) - sum(S)) / sum(S) < 1e-12
    return val / sum(svdvals(A))
end
r4 = exp4_trace_properties()
println(@sprintf("实验4 tr(AB)=tr(BA)（机器精度）；随机基 Σ|(Tf,e)|/Σs = %.3f ≤ 1；SVD 基取等 = 1", r4))

println("END ====")
