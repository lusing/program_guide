using LinearAlgebra, Random
println("==== 46 essential_spectrum (Julia) ====")
Random.seed!(4646)

# 本质谱的 Weyl 列刻画：λ ∈ σ_ess(T) ⟺ 存在范数 1、弱→0 的
# 序列 (xₙ) 使 ‖(T-λ)xₙ‖ → 0（近似特征向量）。
# 单侧右移 S（等距）：σ(S) = 闭圆盘，点谱 = ∅，σ_ess(S) = 单位圆周。
shift(v) = [0; v[1:end-1]]          # 右移 (Sx)ₖ = x_{k-1}，等距

function weyl_err(λ, m)
    # 相位斜坡 xₖ ∝ λ̄^k：|λ|=1 时内部项相消，只剩边界（真 Weyl 列）；
    # |λ|<1 时几何衰减 ⟹ 相对残差 ~√((2-|λ|²)(1-|λ|²)) 有下界
    x = conj(λ) .^ (0:m-1)
    x ./= norm(x)
    return norm(shift(x) - λ * x)      # 相对误差（‖x‖=1）
end
println("λ = 1（圆周上，本质谱）：")
for m in [50, 200, 800, 3200]
    println("  m = $m : ‖(S-λ)x‖ = $(round(weyl_err(1.0 + 0im, m), digits=6))")
end
println("λ = 0.5（圆盘内，非本质谱）：")
for m in [50, 200, 800]
    println("  m = $m : ‖(S-λ)x‖ = $(round(weyl_err(0.5 + 0im, m), digits=6))")
end
e1 = [weyl_err(1.0 + 0im, m) for m in [50, 800, 3200]]
e2 = [weyl_err(0.5 + 0im, m) for m in [50, 800]]
@assert e1[3] < e1[2] * 0.75
@assert e1[2] < e1[1] * 0.75
# 右移是等距：‖(S-λ)x‖ ≥ ‖Sx‖ - |λ|‖x‖ = (1-|λ|)‖x‖ 对一切 x 成立
@assert all(e2 .> 0.3)
println("圆周上有 Weyl 列（误差 ~√(2/m) → 0），圆盘内一致有下界：✓")

# 本质谱 = 谱模掉紧摄动：σ_ess(I + K) = σ_ess(I) = {1}
i30 = collect(1.0:30.0)
H30 = [1.0 / (i + j - 1) for i in i30, j in i30]    # 紧算子截断
t = 0.3
λ = eigvals(I + t * H30)
println("I + 0.3·Hilbert 的谱：max|λ-1| = $(round(maximum(abs.(λ .- 1)), sigdigits=3))，且聚向 1")
@assert maximum(abs.(λ .- 1)) < 0.3 * opnorm(H30) + 1e-9
# 谱聚点结构：绝大多数特征值紧贴 1
near1 = count(abs.(λ .- 1) .< 1e-3)
println("30 个特征值中 $near1 个落在 1 的 10⁻³ 邻域（离散谱点向本质谱坍缩）")
@assert near1 >= 20
println("紧摄动只造离散谱点，本质谱不动（Weyl 定理数值面）：✓")
println("==== 46 essential_spectrum END ====")
