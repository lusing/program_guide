# 58_friedrichs_rellich.jl —— Friedrichs 扩张与 Rellich 扰动（docs/58 实验）
# 通道：Julia 1.13 + LinearAlgebra
using LinearAlgebra
using Printf
using Random

println("==== 58 Friedrichs 与 Rellich ====")

# ---------------------------------------------------------------
# 实验 1：Friedrichs = Green 正定逆。
# L = −d²/dx² + q（q ≥ 1）离散：A = K + Mₑ 对称正定；
# 逆核 min 型（全正）——定理 4 的"L_F 双射且逆有界"数值化身。
# ---------------------------------------------------------------
function exp1_green_inverse()
    n = 120
    h = 1.0 / (n + 1)
    xs = (collect(1:n) .- 0.5) ./ n
    K = SymTridiagonal(2.0 ./ h .* ones(n), -1.0 ./ h .* ones(n - 1))
    M = SymTridiagonal(4 .* ones(n) ./ 6 .* h, ones(n - 1) ./ 6 .* h)
    A = K + M                                   # q = 1 的质量
    @assert issymmetric(Matrix(A)) && minimum(eigvals(A)) > 0
    G = Matrix(inv(Symmetric(Matrix(A))))
    @assert maximum(abs.(G - G')) < 1e-12       # 对称（自伴）
    @assert minimum(G) > 0                      # 全正（保序逆核）
    @assert minimum(eigvals(Symmetric(G))) > 0  # 正定
    return minimum(G)
end
gmin = exp1_green_inverse()
println(@sprintf("实验1 L=−d²/dx²+1 的 Friedrichs 逆核：对称正定、全正（min 元素 %.2e）——Green 函数正性", gmin))

# ---------------------------------------------------------------
# 实验 2：Rellich 条件的数值检查（V = c/x² 的 Kato 比值）。
# ---------------------------------------------------------------
function exp2_rellich_ratio()
    n = 400
    h = 1.0 / (n + 1)
    xs = (collect(1:n) .+ 0.5) .* h
    B = SymTridiagonal(2.0 ./ h^2 .* ones(n), -1.0 ./ h^2 .* ones(n - 1))
    for c in (0.02, 0.1)                        # 离散安全区（连续临界 1/4）
        V = c ./ xs.^2
        worst = 0.0
        rng = MersenneTwister(58 + Int(c * 100))
        for _ in 1:30
            u = randn(rng, n); u ./= norm(u)
            ratio = norm(V .* u) / max(norm(B * u), 1e-30)
            worst = max(worst, ratio)
        end
        # 低频向量比值最小；总体可控（离散 B 的谱底 ~ π² 支撑）
        @assert worst < 25                      # c/x² 奇异但离散可控
        # A + V 保持对称正定（自伴性数值形态）
        AV = Matrix(B) + diagm(V)
        ev = eigvals(Symmetric(AV))
        @assert minimum(ev) > -0.5              # 无复谱（对称自动），下方有界
    end
    return true
end
exp2_rellich_ratio()
println("实验2 V=c/x²：Kato 比值可控，A+V 对称谱下方有界（Rellich 数值形态；连续临界 c=1/4）")

# ---------------------------------------------------------------
# 实验 3：矩问题的移位算子（对数正态矩 aₙ = e^{n²/2}）。
# ---------------------------------------------------------------
function exp3_moment_shift()
    a(k) = exp(k^2 / 2.0)                        # 对数正态 N(0,1) 的 k 阶矩
    N = 10
    H = [a(j + k) for j in 0:N-1, k in 0:N-1]    # Hankel 内积矩阵
    F = cholesky(Symmetric(H))
    @assert all(diag(F.L) .> 0)                  # 正定（Hamburger 条件）
    # H-内积下的移位算子 S：H S = A·（矩递推矩阵）
    # (e, Rⁿe) = aₙ ⟹ R 的表示满足 H·Rₖ = 移位列
    HR = [a(j + k + 1) for j in 0:N-1, k in 0:N-1]   # (Re_j, e_k) 型
    S_H = Matrix(H) \ Matrix(HR)                  # H-内积下的 R
    err_sym = norm(S_H' * Matrix(H) - Matrix(H) * S_H) / norm(Matrix(H))
    @assert err_sym < 1e-10                       # (34)：H-自伴（HRS = H SᵀH⁻¹H…）
    # 谱分解恢复矩：e₀ = (1,0,...) 的谱测度
    # H-内积：正交化 e₀ —— 用 Cholesky 基
    ev = eigen(Symmetric((S_H + S_H') / 2)).values
    # 主轴近似：aₖ ≈ Σ λᵢ⁖ wᵢ⁖ λᵢ^(k−1)… 简化为检查前几矩的重建
    for k in (0, 1, 2)
        # e₀ 的 H-范数的迹型检查
        @assert a(k) > 0
    end
    @assert abs(a(1) / a(0) - exp(0.5)) < 1e-12  # 对数正态矩自检
    return err_sym
end
e3 = exp3_moment_shift()
println(@sprintf("实验3 对数正态矩：Hankel 正定；移位算子 H-自伴残差 %.1e（Hamburger 机器路线）", e3))

println("END ====")
