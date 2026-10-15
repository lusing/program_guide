# 74_inner_product_apps.jl —— 内积应用：相关/Gram/最佳逼近（docs/74 实验）
# 通道：Julia 1.13 + LinearAlgebra + Printf
# 内容：相关系数与信号检测、x≈2sinx 最佳逼近（书例 4.5.3）、
#       Gram 行列式距离公式、弱收敛恒等式
using LinearAlgebra
using Printf
using Random
Random.seed!(42)

println("==== 74 内积应用：相关/Gram/最佳逼近 ====")

# ---------------------------------------------------------------
# 实验 1：规范相关系数与信号检测（书 4.5.1）
# ρ = ⟨x,y⟩/(‖x‖‖y‖)；最优尺度 λ* = ⟨x,y⟩/‖y‖²；最优相对误差 1−ρ²。
# 场景：含噪信号与模板匹配——ρ 对噪声鲁棒，能量误差不行。
# ---------------------------------------------------------------
function exp1_correlation()
    t = range(0, 1; length=2000)
    template = @. sin(2π * 5 * t)                     # 模板：5Hz 正弦
    signal = @. sin(2π * 5 * t + 0.2)                  # 目标：同频有相移
    noise = 0.3 * randn(length(t))
    observed = signal + noise
    rho = dot(observed, template) / (norm(observed) * norm(template))
    lam = dot(observed, template) / dot(template, template)
    resid = observed - lam * template
    rel_err = dot(resid, resid) / dot(observed, observed)
    @assert 0.9 < rho < 1.0                            # 高相关（相移 0.2 + 噪声 0.3）
    @assert 0.0 < rel_err < 0.2                        # 相对误差 ≈ 1−ρ²
    @assert abs(rel_err - (1 - rho^2)) < 0.02          # 恒等式数值成立
    # 对照：无关信号
    junk = randn(length(t))
    rho0 = dot(junk, template) / (norm(junk) * norm(template))
    @assert abs(rho0) < 0.1                            # 近似正交：ρ ≈ 0
    return (rho, lam)
end
rho1, lam1 = exp1_correlation()
println(@sprintf("实验1 相关系数：ρ=%.3f、λ*=%.2f、相对误差=1−ρ²（噪声下仍可检测）", rho1, lam1))

# ---------------------------------------------------------------
# 实验 2：最佳逼近 x ≈ 2 sin x（书例 4.5.3 全计算）
# L²([−π,π]) 中用 span{sin, cos} 逼近 f(x)=x：
# 法方程 G a = b，G=[[π,0],[0,π]]，b=[∫x·sin, ∫x·cos]=[2π,0] ⟹ a=[2,0]。
# ---------------------------------------------------------------
function exp2_best_approx()
    xs = range(-π, π; length=400_001)
    f = xs                                        # f(x) = x
    S = @. sin(xs)
    C = @. cos(xs)
    dx = step(xs)
    G = [dot(S, S)*dx dot(S, C)*dx; dot(C, S)*dx dot(C, C)*dx]   # Gram 阵
    b = [dot(f, S)*dx, dot(f, C)*dx]                              # 载荷
    @assert abs(G[1,1] - π) < 1e-3                # ∫sin² = π
    @assert abs(G[2,2] - π) < 1e-3
    @assert abs(G[1,2]) < 1e-3                    # ∫sin·cos = 0（正交！）
    @assert abs(b[1] - 2π) < 2e-3                 # ∫x·sinx = 2π
    @assert abs(b[2]) < 1e-3                      # ∫x·cosx = 0（奇偶）
    a = G \ b
    @assert abs(a[1] - 2) < 1e-2                  # a₁ = 2
    @assert abs(a[2]) < 1e-2                      # a₂ = 0
    # 距离平方：‖f‖² − bᵀG⁻¹b = 2π³/3 − 4π（‖x‖²=2π³/3、投影范数²=4π）
    d2 = dot(f, f)*dx - (b' / G * b)[1]
    @assert abs(d2 - (2π^3 / 3 - 4π)) < 1e-2
    return a
end
a2 = exp2_best_approx()
println(@sprintf("实验2 最佳逼近：法方程给 a=[%.3f, %.3f]（书值 [2,0]），d²=2π³/3−4π 吻合", a2[1], a2[2]))

# ---------------------------------------------------------------
# 实验 3：Gram 行列式距离公式（书 4.5.6）
# d(x, span{α₁..αₙ})² = G(x,α₁..αₙ)/G(α₁..αₙ)（Gram 行列式之比）。
# 三向量数值验证：与 QR 投影直接计算的残差对比。
# ---------------------------------------------------------------
function exp3_gram_distance()
    A3 = [1.0 0.2 0.1; 0.3 1.0 0.4; 0.1 0.5 1.0]           # 三个 3 维向量（列）
    A = A3[:, 1:2]                                          # 取二维子空间 span{α₁,α₂}
    x = [1.0, 2.0, 3.0]                                     # x 不在子空间中 ⟹ 真距离
    G3 = [dot(A[:, i], A[:, j]) for i in 1:2, j in 1:2]    # G(α)
    b = [dot(x, A[:, i]) for i in 1:2]
    G4 = [dot(x,x) b'; b G3]                                # G(x,α) 4×4 分块
    d2_formula = det(G4) / det(G3)
    sol = A \ x
    d2_direct = dot(x - A * sol, x - A * sol)
    @assert d2_direct > 0.01                                # 确实不在子空间内
    @assert abs(d2_formula - d2_direct) < 1e-10
    # Gram 可逆 ⟺ 无关（书 4.5.5）：四个向量在 ℝ³ 中必线性相关
    A2 = [A3 [1.0, 1.0, 1.0]]                # 4 列 3 行 ⟹ 必相关
    G4b = [dot(A2[:, i], A2[:, j]) for i in 1:4, j in 1:4]
    @assert rank(A2) == 3                    # 秩 3 < 4：相关
    @assert abs(det(G4b)) < 1e-12            # ⟹ Gram 行列式 = 0（无关性判据）
    return d2_formula
end
d3 = exp3_gram_distance()
println(@sprintf("实验3 Gram 距离公式：d²=%.6f 与 QR 投影一致；相关向量族 Gram 行列式=0", d3))

# ---------------------------------------------------------------
# 实验 4：弱收敛恒等式（书 4.4.5）与"弱收敛不保范数"
# ‖xₙ−x‖² = ‖xₙ‖² − 2⟨xₙ,x⟩ + ‖x‖²（Lean norm_sq_expand 同型）；
# ONB 列 eₙ ⇀ 0（一切内积 → 0）但 ‖eₙ‖ = 1 恒定——恒等式右端两顶抵消。
# ---------------------------------------------------------------
function exp4_weak_identity()
    n = 400
    # ONB 列：e_k = 标准基
    for k in [50, 200, 399]
        e = zeros(n); e[k] = 1.0
        # 恒等式（x = 0 的平凡端 + 非平凡 x）
        x = zeros(n); x[1] = 1.0
        lhs = dot(e - x, e - x)
        rhs = dot(e, e) - 2 * dot(e, x) + dot(x, x)
        @assert abs(lhs - rhs) < 1e-12       # 恒等式
        # 弱收敛：⟨e_k, y⟩ = y[k] = 1/k → 0（k→∞），逐项小
        y = [1.0 / i for i in 1:n]
        @assert abs(dot(e, y) - 1.0 / k) < 1e-15   # 内积恰取 y 的第 k 分量
        @assert 1.0 / k < 0.03                     # k ≥ 50 时已小
        @assert norm(e) ≈ 1.0                # 范数不降
    end
    # 傅里叶版（无限维的真弱收敛）：sₙ 高频振荡 ⟹ 内积 → 0
    t = range(0, 1; length=4001)
    for m in [100, 400, 1600]
        sm = @. sqrt(2) * sin(m * π * t)
        inner_with_t = dot(sm, t) * step(t)  # ⟨sₘ, x⟩ with x=t
        @assert abs(inner_with_t) < 3 / m    # → 0（分部积分 ~1/(mπ))
        @assert abs(dot(sm, sm) * step(t) - 1.0) < 0.01  # ‖sₘ‖=1 恒定
    end
end
exp4_weak_identity()
println("实验4 弱收敛恒等式：数值恒成立；ONB/傅里叶列弱收敛于 0 而范数恒 1（恒等式两顶相消）")

println("END ====")
