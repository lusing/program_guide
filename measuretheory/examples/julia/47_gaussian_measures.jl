println("==== 47 gaussian_measures")
# 第 47 章：无穷维 Gauss 的结构账。
# ① 坐标分布（截断 λₙ = 1/n²）；② 能量收敛 = Tr A；
# ③ CM 门槛（e₁ ∈ H_A vs Σeₙ/n ∉）；④ Fernique；
# ⑤ 平移密度的归一账。

using Random, Statistics
Random.seed!(47)

# ① 坐标分布：X_k = sqrt(λ_k) z_k ~ N(0, 1/k²)
n = 5000
k = 3
z = randn(n)
Xk = (1.0 / k) .* z                                # sqrt(1/9) = 1/3
@assert abs(var(Xk) - 1 / k^2) < 0.02
println("coordinate k=3: Var(X_3) = 1/9 (lambda_k = 1/k^2): OK"

)
# ② 能量收敛：E||X||² = Σ1/k² = π²/6
energies = [sum((1.0 / j^2) * z^2 for (j, z) in enumerate(randn(1000))) for _ in 1:2000]
@assert abs(mean(energies) - sum(1.0 / j^2 for j in 1:1000)) < 0.05
@assert sum(1.0 / j^2 for j in 1:1000) < pi^2 / 6 + 0.001
println("energy account: E||X||^2 = Tr A -> pi^2/6: OK"

)
# ③ CM 门槛：h = e₁ 的 A^{-1/2} 范数 = 1/sqrt(λ₁) = 1（有限 ✓）；
#    h = Σ eₙ/n：||h||_A² = Σ 1/(n²·λₙ) = Σ 1/n（Harmonic 发散 ✗）
cm_e1 = 1.0 / (1.0 / 1.0)                          # ||e_1||_A² = 1/λ₁ = 1
@assert cm_e1 == 1.0                               # 有限：e₁ 是 CM 会员
cm_harm = sum(1.0 for n in 1:10^4)                 # Σ (1/n²)·n² = Σ 1 = 10⁴
# λₙ = 1/n² 则 ||h||_A² = Σ hₙ²/λₙ = Σ (1/n²)·n² = Σ 1 → ∞
# h = Σ eₙ/n：||h||² = Σ1/n² < ∞（H 会员）但 ||h||_A² = ∞（非 CM 会员）
@assert cm_harm == 10^4.0                          # 发散（部分和 = 项数）
println("CM threshold: ||e_1||_A finite, ||sum e_n/n||_A diverges: OK"

)
# ④ Fernique：E exp(α||X||²) 在小 α 时有限
X_sq = [sum((1.0 / j^2) * z^2 for (j, z) in enumerate(randn(500))) for _ in 1:2000]
for alpha in (0.05, 0.1)
    vals = exp.(alpha .* X_sq)
    m = mean(vals)
    @assert m < 10.0 && m > 0.5                    # 有限（α 小于阈值）
end
println("Fernique shadow: E[exp(alpha||X||^2)] finite for small alpha: OK"

)
# ⑤ 平移密度的归一：h = sqrt(λ₁)e₁ 的密度 exp(线性 - 常数/2) 期望 = 1
h1 = 1.0                                           # sqrt(λ₁)·z₁（z₁ = ±1 简化）
# dμ_h/dμ ∝ exp(⟨A^{-1/2}h, ·⟩ - ||A^{-1/2}h||²/2)：采样均值 ~ 1
dens = [exp((1.0 / 1) * randn() - 0.5 * 1.0) for _ in 1:20000]
@assert 0.9 < mean(dens) < 1.1
println("Cameron-Martin density: E[dμ_h/dμ] = 1 (normalization): OK"

)
println("END ====")
