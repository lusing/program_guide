# 72_poincare_embedding.jl —— Poincaré 不等式与 Sobolev 嵌入（docs/72 实验）
# 通道：Julia 1.13 + LinearAlgebra + Printf
# 内容：Poincaré 常数（初等 vs 谱最优）、平移估计、紧嵌入（Rellich）、
#       一维 Morrey 嵌入常数
using LinearAlgebra
using Printf

println("==== 72 Poincaré 不等式与 Sobolev 嵌入 ====")

# ---------------------------------------------------------------
# 实验 1：Poincaré 常数——初等证明给 1，谱分析给 1/π²（书 6.1.1）
# 离散零边值 Dirichlet 刚度阵 A（三点差分），其最小特征值 → π²
# （区间长度 1），故最优 Poincaré 常数 C = 1/π² ≈ 0.101。
# 书的初等证明（零延拓 + Schwarz）给 C = 1——差 π² 倍，但"有限即可用"。
# ---------------------------------------------------------------
function exp1_poincare_constants()
    for n in [50, 200, 800]
        h = 1.0 / (n + 1)
        A = Tridiagonal(-ones(n - 1), 2 * ones(n), -ones(n - 1)) / h^2
        λmin = minimum(eigvals(Symmetric(Matrix(A))))
        @assert abs(λmin - π^2) / π^2 < 0.01   # 最小特征值 → π²
    end
    # 对照两个常数：‖u‖² ≤ 1·‖u′‖²（初等）与 ≤ (1/π²)‖u′‖²（最优）
    xs = range(0, 1; length=4001)
    u = sin.(π .* xs)                        # 最优函数：等号取到
    du = π .* cos.(π .* xs)
    r_opt = sum(abs2, u) / sum(abs2, du)     # 恰 1/π²
    @assert abs(r_opt - 1 / π^2) < 1e-3
    r_elem = sum(abs2, u) / sum(abs2, du)
    @assert r_elem < 1.0                     # 初等常数 1 也成立（宽松）
    return (r_opt, 1 / π^2)
end
r1, c1 = exp1_poincare_constants()
println(@sprintf("实验1 Poincaré：最优比值 %.4f = 1/π² = %.4f（sin(πx) 取等）；初等证给常数 1（宽 π² 倍）", r1, c1))

# ---------------------------------------------------------------
# 实验 2：平移估计（书 6.1.7 / Kolmogorov-Riesz 判据的钥匙）
# ‖u(·+h) − u(·)‖_{L²} ≤ C·√h·‖u′‖_{L²}——对光滑 u 数值验证√h 缩放律。
# 这条估计 + Arzelà-Ascoli 型论证 = W₀^{1,2} 有界集在 L² 中列紧。
# ---------------------------------------------------------------
function exp2_translation()
    xs = range(0, 1; length=200_001)
    u(x) = sin(3π * x) * exp(-x)
    du_norm = sqrt(sum(abs2, 3π .* cos.(3π .* xs) .* exp.(-xs) .- sin.(3π .* xs) .* exp.(-xs)) * step(xs))
    prev = Inf
    for h in [0.1, 0.01, 0.001]
        shifted = u.(xs .+ h)
        base = u.(xs)
        tnorm = sqrt(sum(abs2, shifted .- base) * step(xs))
        bound = sqrt(h) * du_norm * 1.01     # 理论界 √h‖u′‖（+1% 余量）
        @assert tnorm ≤ bound                # 估计成立
        @assert tnorm ≤ prev                 # 随 h 单调下降
        prev = tnorm
    end
    return prev
end
t2 = exp2_translation()
println(@sprintf("实验2 平移估计：h=0.001 时 ‖u(·+h)−u‖₂ = %.5f ≤ √h·‖u′‖₂，√h 缩放律成立", t2))

# ---------------------------------------------------------------
# 实验 3：紧嵌入（Rellich-Kondrachov，书 6.2.7）的数值体现
# W 范数归一的高频振荡列 eₙ = sin(nπx)/√(1+n²π²)：
# ‖eₙ‖_W = 1 恒定，但 ‖eₙ‖_{L²} ~ 1/(nπ√2) → 0 强收敛！
# 导数能量"罚掉"高频——W 有界序列不可能靠振荡逃出紧性。
# ---------------------------------------------------------------
function exp3_rellich()
    xs = range(0, 1; length=100_001)
    for n in [10, 100, 1000]
        eₙ = sin.(n .* π .* xs) ./ sqrt(1 + n^2 * π^2)
        l2 = sqrt(sum(abs2, eₙ) * step(xs))
        @assert l2 < 1.0 / (n * π) * 1.01    # ~ 1/(nπ√2)
    end
    e1000 = sin.(1000 .* π .* xs) ./ sqrt(1 + 1000^2 * π^2)
    l2last = sqrt(sum(abs2, e1000) * step(xs))
    @assert l2last < 1e-3                    # 已强收敛到 0
    return l2last
end
l3 = exp3_rellich()
println(@sprintf("实验3 紧嵌入：W 归一振荡列 L² 范数 → %.1e（强收敛 0）——Rellich 的数值化身", l3))

# ---------------------------------------------------------------
# 实验 4：一维 Morrey 嵌入（Lean 同型定理的数值对照）
# |f(x) − f(y)| ≤ ∫|f′|（W^{1,1} → C⁰）；更强的 L² 版：
# |f(x) − f(y)| ≤ √|x−y|·‖f′‖₂（Hölder 1/2 指数）。
# 对 f(x) = x^{3/2}（在 0 处导数为 0、正则性临界）验证两条。
# ---------------------------------------------------------------
function exp4_morrey()
    xs = range(0, 1; length=400_001)
    f(x) = x^(3 / 2)
    df(x) = 1.5 * sqrt(x)
    l1 = sum(abs.(df.(xs)) * step(xs))       # ‖f′‖₁ = 1
    l2 = sqrt(sum(abs2, df.(xs)) * step(xs)) # ‖f′‖₂
    @assert abs(l1 - 1.0) < 1e-3
    for (x, y) in [(0.0, 0.5), (0.2, 0.9), (0.0, 1.0)]
        osc = abs(f(x) - f(y))
        @assert osc ≤ l1 + 1e-12             # L¹ 版（Lean 定理）
        @assert osc ≤ sqrt(abs(x - y)) * l2 * (1 + 1e-12)  # L²/Hölder 版
    end
    return l2
end
l4 = exp4_morrey()
println(@sprintf("实验4 Morrey：‖f′‖₁=1 控制振幅；√|x−y|·‖f′‖₂=%.3f 也控制——两版嵌入同时成立", l4))

println("END ====")
