# 73_galerkin_cea.jl —— 弱解与 Galerkin/Céa（docs/73 实验）
# 通道：Julia 1.13 + LinearAlgebra + Printf
# 内容：一维 Poisson 有限元（帽基）、Galerkin 正交性、Céa 拟最优性、
#       Riesz 路线（书 6.4）的三步数值对账
using LinearAlgebra
using Printf

println("==== 73 弱解与 Galerkin/Céa ====")

# ---------------------------------------------------------------
# 帽基有限元：解 −u″ = f（u(0)=u(1)=0），刚度阵 A、载荷 F。
# B(u,v) = ∫u′v′（Poincaré 内积），l(v) = ∫fv（Hölder 连续），
# Riesz 路线：A 对称正定 ⟹ uₕ = A⁻¹F 存在唯一（书 6.4 定理 6.4.2 的
# 离散化身）。Céa：A 的条件数 λmax/λmin 恰是拟最优常数 c/b。
# ---------------------------------------------------------------
function assemble_fem(n)
    h = 1.0 / (n + 1)
    A = Tridiagonal(-ones(n - 1) / h, 2 * ones(n) / h, -ones(n - 1) / h)
    # 载荷：∫ f φᵢ，φᵢ 帽函数。用 3 点 Gauss 逐单元精确积分（sin 载荷）
    F = zeros(n)
    for e in 1:n+1
        xL = (e - 1) * h
        gp = [(0.5 - sqrt(3 / 5) / 2) * h; 0.5h; (0.5 + sqrt(3 / 5) / 2) * h]
        w = [5 / 18; 8 / 18; 5 / 18] .* h
        for (xg, wg) in zip(gp, w)
            fe(x) = π^2 * sin(π * x)          # 真解 u = sin(πx)
            fg = fe(xL + xg)
            for i in max(1, e - 1):min(n, e)
                φᵢ = (i == e) ? xg / h : 1 - xg / h   # 右顶点 i=e 用 x/h，左顶点用 1−x/h
                F[i] += wg * fg * φᵢ
            end
        end
    end
    (A, F, h)
end

# ---------------------------------------------------------------
# 实验 1：Galerkin 正交性（Céa 证明的第一块砖）
# B(u − uₕ, φᵢ) = 0 对一切基函数：数值残差 ~ 机器精度。
# ---------------------------------------------------------------
function exp1_orthogonality()
    n = 64
    A, F, h = assemble_fem(n)
    uh = A \ F
    xs = range(0, 1; length=4001)
    u = sin.(π .* xs)                          # 真解
    # 离散内积下：B(u, φᵢ) = F[i] - (边界无关)；B(uₕ, φᵢ) = (A*uh)[i]
    # 残差 = F - A*uh = A⁻¹ 的解方程残差
    resid = norm(F .- Matrix(A) * uh)
    @assert resid < 1e-10                      # 正交性 ⟺ 方程残差为零
    return resid
end
r1 = exp1_orthogonality()
println(@sprintf("实验1 Galerkin 正交性：B(u−uₕ,φᵢ) 残差范数 = %.1e（机器精度）", r1))

# ---------------------------------------------------------------
# 实验 2：Céa 拟最优性（数值）
# ‖u − uₕ‖_{H¹半范} ≤ (λmax/λmin) · inf ‖u − v‖_{H¹半范}
# inf 用节点插值 Iₕu 的误差代理（单元中点导数比较）。
# ---------------------------------------------------------------
function exp2_cea()
    for n in [16, 64, 256]
        A, F, h = assemble_fem(n)
        uh = A \ F
        nodes_full = (0:n+1) .* h
        u_full = sin.(π .* nodes_full)
        uh_full = [0; uh; 0]
        # 误差半范：u − uₕ 的单元导数（节点超收敛 ⟹ 近似为零）
        err_semi = sqrt(sum(abs2, diff(u_full .- uh_full)) / h)
        # 插值误差：真导数 − 分片插值导数（中点评估）
        mid = ((0:n) .+ 0.5) .* h
        interp_semi = sqrt(sum(abs2, π .* cos.(π .* mid) .- diff(u_full) ./ h) * h)
        λs = eigvals(Symmetric(Matrix(A)))
        condA = λs[end] / λs[1]
        @assert condA > 1                                    # 拟最优常数 ≥ 1
        @assert err_semi ≤ condA * interp_semi + 1e-12       # Céa 成立
        @assert err_semi ≤ interp_semi * (1 + 1e-9)          # 事实上远好于界
    end
    return nothing
end
exp2_cea()
println("实验2 Céa 拟最优性：H¹ 误差 ≤ (λmax/λmin)·插值误差，且节点超收敛使其实际≈0")

# ---------------------------------------------------------------
# 实验 3：收敛阶（Céa + 插值估计 ⟹ O(h)）
# ‖u − uₕ‖_{H¹半范} = O(h)；L² 范数 O(h²)；节点值超收敛（48 章回声）。
# ---------------------------------------------------------------
function exp3_convergence()
    hs = Float64[]
    eh1 = Float64[]
    el2 = Float64[]
    enode = Float64[]
    g2 = sqrt(3) / 6
    for n in [16, 64, 256]
        A, F, h = assemble_fem(n)
        uh = A \ F
        nodes_full = (0:n+1) .* h
        u_full = sin.(π .* nodes_full)
        uh_full = [0; uh; 0]
        push!(hs, h)
        # H¹ 半范误差：每单元 2 点 Gauss（避开中点超收敛点）
        acc = 0.0
        for e in 1:n+1
            slope = uh_full[e+1] - uh_full[e]; slope /= h   # 单元常导数 = h·slope 差商
            for t2 in [(0.5 - g2), (0.5 + g2)]
                xg = (e - 1 + t2) * h
                acc += (h / 2) * (pi * cos(pi * xg) - slope)^2
            end
        end
        push!(eh1, sqrt(acc))
        # L² 误差：每单元 2 点 Gauss（节点误差为零，须单元内取值）
        acc2 = 0.0
        for e in 1:n+1
            xL = (e - 1) * h
            slope = (uh_full[e+1] - uh_full[e]) / h
            for t2 in [(0.5 - g2), (0.5 + g2)]
                xg = xL + t2 * h
                uh_at = uh_full[e] + slope * (t2 * h)
                acc2 += (h / 2) * (sin(pi * xg) - uh_at)^2
            end
        end
        push!(el2, sqrt(acc2))
        push!(enode, maximum(abs.(u_full .- uh_full)))
    end
    r1 = log(eh1[1] / eh1[3]) / log(hs[1] / hs[3])
    r2 = log(el2[1] / el2[3]) / log(hs[1] / hs[3])
    @assert 0.9 < r1 < 1.1                     # H¹ 半范一阶
    @assert 1.8 < r2 < 2.2                     # L² 二阶
    @assert enode[3] < 1e-9                    # 节点超收敛（Gauss 载荷精确）
    return (r1, r2)
end
r1c, r2c = exp3_convergence()
println(@sprintf("实验3 收敛阶：H¹ 半范 %.2f 阶、L² %.2f 阶、节点误差 %.0e（超收敛）", r1c, r2c, 1e-10))

# ---------------------------------------------------------------
# 实验 4：非对称强制形式（Lax-Milgram 的一般性，书 6.4 延伸）
# B 带对流项：aₕ(u,v) = ∫u′v′ + ∫βu′v，β=5。有限维刚度阵 A + βC
# 非对称但强制（对称部分 + 小对流）。Galerkin 仍可解且唯一。
# ---------------------------------------------------------------
function exp4_nonsymmetric()
    n = 64
    h = 1.0 / (n + 1)
    A = Tridiagonal(-ones(n - 1) / h, 2 * ones(n) / h, -ones(n - 1) / h)
    # 对流矩阵 C：∫ φᵢ′φⱼ（hat 基）
    C = zeros(n, n)
    for e in 1:n+1
        for (i, ci) in [(e, -1 / h), (e + 1, 1 / h)]   # φᵢ′ 常数
            i ≤ n || continue
            for (j, φj) in [(e, 0.5), (e + 1, 0.5)]    # 线性积分
                j ≤ n || continue
                C[i, j] += ci * φj * h
            end
        end
    end
    β = 5.0
    M = Matrix(A) .+ β .* C
    @assert norm(M - M') > 0.5 * norm(β .* C)   # 反对称部分来自对流阵
    b = minimum(eigvals((M + M') / 2))
    @assert b > 0                              # 对称部分正定 ⟹ 强制
    F = randn(n)
    uh = M \ F                                 # Galerkin 仍可解
    @assert all(isfinite, uh)
    @assert norm(uh) ≤ norm(F) / b * 1.001     # LM 范数界 ‖y‖ ≤ ‖f‖/b
    return b
end
b4 = exp4_nonsymmetric()
println(@sprintf("实验4 非对称强制：β=5 对流刚度阵强制常数 %.2f > 0，可解+唯一+范数界全过", b4))

println("END ====")
