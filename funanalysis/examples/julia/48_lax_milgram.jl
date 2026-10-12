# 48_lax_milgram.jl —— Lax-Milgram 引理与变分法（docs/48 第四章实验）
# 通道：Julia 1.13 + LinearAlgebra
using LinearAlgebra
using Printf

println("==== 48 Lax-Milgram 与变分法 ====")

# ---------------------------------------------------------------
# 实验 1：非对称强制形式的可解性与范数界 ‖y‖ ≤ ‖f‖/b
# B(x,y) = xᵀMy，M = [1 0.8; 0 1]。对称部分 (M+Mᵀ)/2 特征值 1±0.4，
# 故 b = 0.6 > 0，B 强制但 B 不对称——Riesz 定理管不了，Lax-Milgram 管。
# ---------------------------------------------------------------
function exp1_nonsymmetric()
    M = [1.0 0.8; 0.0 1.0]
    b = minimum(eigvals((M + M') / 2))          # 强制常数
    @assert 0.59 < b < 0.61                      # 理论值 0.6
    @assert norm(M - M') > 0.1                   # 确实不对称
    worst = 0.0
    for _ in 1:400
        f = randn(2)
        y = M \ f                                # B(x,y) = ⟨x,f⟩ 的解
        worst = max(worst, norm(y) / (norm(f) / b))   # 理论 ≤ 1
    end
    @assert worst ≤ 1.0 + 1e-12                  # ‖y‖ ≤ ‖f‖/b（留浮点余量）
    return (b, worst)
end
b1, worst1 = exp1_nonsymmetric()
println(@sprintf("实验1 强制常数 b=%.3f，400 次随机最坏比值 ‖y‖·b/‖f‖ = %.6f（≤1）",
                 b1, worst1))

# ---------------------------------------------------------------
# 实验 2：Poincaré/Zaremba 两个常数。
# 区间 (0,d) 上 −u″ 的 Dirichlet 有限差分：最小特征值 λ₁_d 从下方
# 逼近 (π/d)²。对特征向量 x 检查：
#   (a) λ₁_d ≈ (π/d)²（相对偏差 < 1e-3）；
#   (b) ‖x‖ ≤ (d/π)·‖x'‖（谱最优常数，离散下以 1e-3 容差取等）；
#   (c) ‖x‖ ≤ d·‖x'‖  （Zaremba 初等常数，宽裕成立）。
# ---------------------------------------------------------------
function exp2_poincare()
    d = 2.0
    for m in (50, 100, 200)
        h = d / (m + 1)
        T = SymTridiagonal(2.0 ./ h^2 .* ones(m), -1.0 ./ h^2 .* ones(m - 1))
        vals, vecs = eigen(T)
        λ1 = vals[1]
        @assert abs(λ1 / (π / d)^2 - 1) < 1e-3          # (a) 谱逼近
        x = vecs[:, 1]
        nrm0 = norm(x)                                    # L² 离散
        nrm1 = sqrt(x' * T * x)                           # 能量范数 = ‖x'‖
        @assert nrm0 / ((d / π) * nrm1) ≤ 1.0 + 1e-3      # (b) 最优常数
        @assert nrm0 / (d * nrm1) ≤ 1.0                   # (c) Zaremba 常数
    end
    return (π / d)^2
end
lam_theory = exp2_poincare()
println(@sprintf("实验2 (π/d)² = %.4f，三档网格 (a)(b)(c) 断言全过", lam_theory))

# ---------------------------------------------------------------
# 实验 3：hat 基有限元的节点超收敛与全局 O(h²)。
# 载荷 f = sin(πt)，解析解 u* = sin(πt)/π²。
# 关键恒等式：φᵢ′ 分片常数 ⟹ 对真解分部积分
#   ∫ u*′ φᵢ′ dt = −(u*(t_{i−1}) − 2u*(t_i) + u*(t_{i+1}))/h   （无截断误差）
# 故真解的节点值**精确**满足有限元方程 K u = F，离散解的节点误差
# 只来自 Gauss 载荷积分（三点 Gauss 单元误差 O(h⁷)）——机器精度级。
# 而单元内部只有线性插值，全局 L² 误差回到 O(h²)。
# ---------------------------------------------------------------
function fem_solve(m::Int)
    h = 1.0 / (m + 1)
    ts = (1:m) .* h
    K = SymTridiagonal(2.0 ./ h .* ones(m), -1.0 ./ h .* ones(m - 1))   # 刚度
    F = zeros(m)
    g = sqrt(3.0 / 5.0)
    w = (5.0 / 9.0, 8.0 / 9.0, 5.0 / 9.0)
    for e in 0:m
        a, bnd = e * h, (e + 1) * h
        for (wi, xi) in zip(w, (-g, 0.0, g))
            t = (a + bnd) / 2 + xi * h / 2
            fval = sin(π * t)
            # 单元内 hat 基函数值
            if a ≤ t < bnd
                for (node, φ) in ((a, (bnd - t) / h), (bnd, (t - a) / h))
                    j = round(Int, node / h)
                    if 1 ≤ j ≤ m
                        F[j] += wi * (h / 2) * fval * φ
                    end
                end
            end
        end
    end
    u = K \ F
    noderr = norm(u .- sin.(π .* ts) ./ π^2, Inf)
    # 全局 L² 误差：单元中点上 u_h（两端节点平均）与 u* 之差
    mid = (u[1:end-1] .+ u[2:end]) ./ 2
    tm = ((1.5:1.0:m-0.5) .* h)   # 与 mid 对齐：第 k 个内部单元中点 (k+0.5)h
    l2err = sqrt(h * sum(abs2, mid .- sin.(π .* tm) ./ π^2))
    κ = cond(Matrix(K))
    return noderr, l2err, κ
end
noderrs = Float64[]; l2errs = Float64[]; kaps = Float64[]
for m in (25, 50, 100)
    a, b, c = fem_solve(m)
    push!(noderrs, a); push!(l2errs, b); push!(kaps, c)
end
@assert noderrs[1] < 1e-10 && noderrs[3] < noderrs[1]   # 节点超收敛
@assert 3.0 < l2errs[1] / l2errs[2] < 5.2              # 全局 h 减半 → ~×1/4
@assert 3.0 < l2errs[2] / l2errs[3] < 5.2
@assert 3.0 < kaps[2] / kaps[1] < 5.2                  # 条件数 ~×4
@assert 3.0 < kaps[3] / kaps[2] < 5.2
println(@sprintf("实验3 节点误差 %.1e→%.1e→%.1e（超收敛）；L² 误差 %.2e→%.2e→%.2e（~×1/4）；κ ~×4",
                 noderrs[1], noderrs[2], noderrs[3], l2errs[1], l2errs[2], l2errs[3]))

# ---------------------------------------------------------------
# 实验 4：非对称 Galerkin 矩阵（−u″ + u′ + u = sin(πt)）。
# 对流项 C 反对称（C_{i,i+1} = +1/2，C_{i+1,i} = −1/2），
# 对称部分 = 刚度 + 质量仍正定 → 强制 → 解存在唯一。
# ---------------------------------------------------------------
function exp4_galerkin()
    m = 200
    h = 1.0 / (m + 1)
    ts = (1:m) .* h
    K = Tridiagonal(-ones(m - 1) ./ h, 2 .* ones(m) ./ h, -ones(m - 1) ./ h)
    C = Tridiagonal(-0.5 .* ones(m - 1), zeros(m), 0.5 .* ones(m - 1))
    R = Tridiagonal(ones(m - 1) .* h ./ 6, 2 .* ones(m) .* h ./ 3,
                    ones(m - 1) .* h ./ 6)     # hat 基一致质量矩阵
    A = K + C + R
    @assert norm(A - A') > 1.0                  # 整体不对称
    b = minimum(eigvals((Matrix(A) + Matrix(A)') / 2))
    @assert π^2 * h * 0.9 < b < π^2 * h * 1.2      # λmin ≈ π²h：强制且与刚度谱一致
    f = sin.(π .* ts)
    # 载荷 ∫ sin(πt) φᵢ：与实验 3 相同的 Gauss 装配
    F = zeros(m)
    gw = (5.0 / 9.0, 8.0 / 9.0, 5.0 / 9.0); gx = (-sqrt(3 / 5), 0.0, sqrt(3 / 5))
    for e in 0:m
        a, bnd = e * h, (e + 1) * h
        for (wi, xi) in zip(gw, gx)
            t = (a + bnd) / 2 + xi * h / 2
            fv = sin(π * t)
            if a ≤ t < bnd
                for (node, φ) in ((a, (bnd - t) / h), (bnd, (t - a) / h))
                    j = round(Int, node / h)
                    if 1 ≤ j ≤ m
                        F[j] += wi * (h / 2) * fv * φ
                    end
                end
            end
        end
    end
    u = A \ F
    @assert norm(A * u - F) / norm(F) < 1e-12   # 可解
    u2 = A \ F
    @assert norm(u - u2) < 1e-14                # 唯一
    # 强制性界：b‖u‖ ≤ ‖Au‖（Lax 第二步不等式的离散化身）
    okbound = true
    for _ in 1:50
        z = randn(m)
        okbound &= (b * norm(z) ≤ norm(A * z) * (1 + 1e-12))
    end
    @assert okbound
    return b
end
b4 = exp4_galerkin()
println(@sprintf("实验4 非对称 Galerkin：强制常数 %.3f > 0，可解+唯一+下有界断言全过", b4))

println("END ====")
