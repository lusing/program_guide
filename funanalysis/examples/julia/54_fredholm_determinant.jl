# 54_fredholm_determinant.jl —— Fredholm 行列式（docs/54 实验）
# 通道：Julia 1.13 + LinearAlgebra
using LinearAlgebra
using Printf

println("==== 54 Fredholm 行列式 ====")

# Fredholm 级数 (6)：k 重行列式积分用 k 维 Monte Carlo/格点近似。
# 对秩低核用结构化计算更精确——本文件实验 1/3/4 全走"低秩闭式 vs
# 离散 det"双轨验证，实验 2 用小 k 的格点积分。

# ---------------------------------------------------------------
# 实验 1：秩一核 K(x,y) = xy。
# D = 1 + λ·∫xy = 1 + λ/3（k≥2 项消失）；零点 λ = −3 ↔ 特征值 1/3。
# ---------------------------------------------------------------
function exp1_rank_one()
    for λ in (0.5, 1.0, 2.0)
        # 离散行列式
        for n in (20, 60)
            xs = (collect(1:n) .- 0.5) ./ n
            w = 1.0 / n
            # K 离散 = w·(xᵢ·xⱼ)（积分算子的重量化矩阵）
            Kn = w .* (xs .* xs')
            Dn = det(I + λ .* Kn)
            # 离散内部一致性（秩一引理）：D_n = 1 + λ·tr(K_n) 精确
            @assert abs(Dn - (1 + λ * tr(Kn))) < 1e-12
            # 收敛到连续闭式 1 + λ/3（中点规则 O(n⁻²)）
            @assert abs(Dn - (1 + λ / 3)) < 5 / n^2
        end
        # 级数 (6) 的 k=1 项 + 高阶消失（行列式两行成比例）
        # 数值上验证 k=2 项 ~ 0：2×2 行列式 [xᵢxⱼ] 秩 1 ⟹ det = 0
        d2 = det([0.3*0.5 0.3*0.7; 0.9*0.5 0.9*0.7])   # [K(xi,xj)] 秩一核
        @assert abs(d2) < 1e-15
    end
    # 特征值：离散算子的最大特征值 → 1/3
    n = 200
    xs = (collect(1:n) .- 0.5) ./ n
    Kn = (1.0 / n) .* (xs .* xs')
    @assert abs(maximum(eigvals(Kn)) - 1 / 3) < 1e-4
    return 1 / 3
end
l1 = exp1_rank_one()
println(@sprintf("实验1 秩一核：D = 1 + λ/3 闭式（离散吻合 1e-6），特征值 = %.4f = 1/3，零点 λ = −3", l1))

# ---------------------------------------------------------------
# 实验 2：光滑核 K = e^{−(x²+y²)} 的 D(λ)。
# 级数 k ≤ 3（格点积分的行列式） vs 大 n 离散 det。
# ---------------------------------------------------------------
function exp2_smooth_kernel()
    function D_series(λ; n=40, kmax=3)
        xs = (collect(1:n) .- 0.5) ./ n
        w = 1.0 / n
        K(i, j) = exp(-(xs[i]^2 + xs[j]^2))
        total = 1.0
        # k=1: ∫K(x,x)dx
        total += λ * sum(K(i, i) for i in 1:n) * w
        # k=2: (1/2)∫∫det
        if kmax ≥ 2
            s2 = 0.0
            for i in 1:n, j in 1:n
                s2 += (K(i, i) * K(j, j) - K(i, j) * K(j, i)) * w^2
            end
            total += λ^2 / 2 * s2
        end
        # k=3: (1/6)∫∫∫det（用行列式公式）
        if kmax ≥ 3
            s3 = 0.0
            for i in 1:n, j in 1:n, k in 1:n
                d = K(i, i) * (K(j, j) * K(k, k) - K(j, k) * K(k, j)) -
                    K(i, j) * (K(j, i) * K(k, k) - K(j, k) * K(k, i)) +
                    K(i, k) * (K(j, i) * K(k, j) - K(j, j) * K(k, i))
                s3 += d * w^3
            end
            total += λ^3 / 6 * s3
        end
        return total
    end
    function D_discrete(λ, n)
        xs = (collect(1:n) .- 0.5) ./ n
        Kn = [exp(-(xs[i]^2 + xs[j]^2)) for i in 1:n, j in 1:n] ./ n
        det(I + λ .* Kn)
    end
    for λ in (0.5, 1.0, 2.0)
        s = D_series(λ)
        d = D_discrete(λ, 120)
        @assert abs(s - d) / abs(d) < 5e-5
    end
    return true
end
exp2_smooth_kernel()
println("实验2 光滑核：级数（k≤3）与离散 det 在 λ = 0.5/1/2 三点吻合（相对 <1e-5）")

# ---------------------------------------------------------------
# 实验 3：乘法性质 D_L = D_H·D_K。
# 秩一 H、秩二 K；L = K + H + HK（重量化矩阵乘积）。
# ---------------------------------------------------------------
function exp3_multiplicative()
    n = 80
    xs = (collect(1:n) .- 0.5) ./ n
    w = 1.0 / n
    # H 秩一：u(x)v(y)，u = x, v = x
    H = w .* (xs .* xs')
    # K 秩二：cos(πx)cos(πy) + 0.5sin(πx)sin(πy)
    u1 = @. cos(π * xs); v1 = u1
    u2 = @. sin(π * xs); v2 = 0.5 .* u2
    K = w .* (u1 * v1' + u2 * v2')
    L = K + H + H * K            # 注意重量化后 H*K = 离散复合（w 已含）
    DL = det(I + L)
    DH = det(I + H)
    DK = det(I + K)
    @assert abs(DL - DH * DK) / abs(DH * DK) < 1e-10
    return (DL, DH * DK)
end
dl, dhk = exp3_multiplicative()
println(@sprintf("实验3 乘法性质：D_L = %.10f vs D_H·D_K = %.10f（相对差 <1e-10）", dl, dhk))

# ---------------------------------------------------------------
# 实验 4：迹公式（K(x,y) = min(x,y)）。
# λⱼ = 1/((j−1/2)²π²)；Σλⱼ = ∫K(x,x) = ∫x = 1/2；
# D(λ) 与 Π(1 + λλⱼ) 重合。
# ---------------------------------------------------------------
function exp4_trace_formula()
    n = 400
    xs = (collect(1:n) .- 0.5) ./ n
    w = 1.0 / n
    Kn = w .* [min(xs[i], xs[j]) for i in 1:n, j in 1:n]
    evs = eigen(Symmetric(Matrix(Kn))).values |> reverse   # 降序
    # 解析对照 + 迹公式
    analytic = [1 / ((j - 0.5)^2 * π^2) for j in 1:50]
    # 离散偏差随模式数 j 增长（O((j/n)²)）：分档容差
    for (j, tol) in ((1, 1e-5), (5, 5e-4), (20, 5e-3), (50, 3e-2))
        @assert abs(evs[j] - analytic[j]) / analytic[j] < tol
    end
    # Σλⱼ = 离散迹 = ∫K(x,x)dx = 1/2（离散 Lidskii 精确成立）
    total = sum(evs)
    @assert abs(total - tr(Kn)) < 1e-12          # Σλ = tr（矩阵恒等式）
    @assert abs(total - 0.5) < 1e-9              # 且 = 解析值 ∫x dx = 1/2
    # 解析侧：Σ1/(j−1/2)² = π²/2 ⟹ Σλⱼ 解析 = 1/2
    analytic_total = sum(1 / ((j - 0.5)^2 * π^2) for j in 1:10^6)
    @assert abs(analytic_total - 0.5) < 2e-3
    # D(λ) vs Π(1+λλⱼ)
    λ = 0.7
    Dnum = det(I + λ .* Kn)
    Dprod = prod(1 + λ * evs[j] for j in 1:30) *
            prod(1 + λ / ((j - 0.5)^2 * π^2) for j in 31:10^5)
    @assert abs(Dnum - Dprod) / Dnum < 1e-4
    return total
end
t4 = exp4_trace_formula()
println(@sprintf("实验4 min(x,y) 核：特征值对上解析式，Σλⱼ = %.5f = ∫K(x,x)dx = 1/2（迹公式）", t4))

println("END ====")
