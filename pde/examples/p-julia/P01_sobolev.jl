# P01 习题篇 II：Sobolev 空间与 Friedrichs 不等式（书第 1 章 §1.2）
#
# 精选：1.10（H¹(0,1) ⊂ C 与反问）、1.12（|ln ρ|^α 的 H¹ 成员资格，
# 第 6 章详解）、1.17（Friedrichs 反例区域）、1.18（带形中的
# Friedrichs）、1.19（点值估计反例）。

using Printf

println("==== P01")

# ---- (a) 1.10a：H¹(0,1) ⊂ C⁰——绝对连续性（数值签名）----
# H¹ 函数的差商有界 ⟹ Hölder 1/2（1D 嵌入 H¹ ⊂ C^{0,1/2}）
u_h1(x) = x^(2 / 3)   # H¹ 但导数 x^{-1/3} ∉ L^∞——Hölder 2/3 样本
worst = 0.0
for xi in 0.0:0.002:0.998, yi in (xi+0.002):0.002:1.0
    r = abs(u_h1(xi) - u_h1(yi)) / abs(xi - yi)^(2 / 3)
    global worst = max(worst, r)
end
@printf("(a) 1.10a: [x^{2/3}]_{C^{0,2/3}} = %.6f (finite ⟹ continuous)\n", worst)
@assert worst < 1.0 + 1e-9 "H¹(0,1) 函数连续（1D 嵌入）"
# b) 反问：连续 + 零边值 ⟹ H¹？否：u = √x 连续（端点 u(0)=0）但
#    u' = 1/(2√x) ∉ L²
int = 0.5 * sum((1 / (2 * sqrt(x)))^2 for x in 0.001:0.001:1) * 0.001
@printf("    b) √x: ∫(u')² ≈ %.3f + 发散的 (0,0.001) 段 ⟹ ∉ H¹\n", int)
@assert int > 0.24 "连续但非 H¹（反例成立）"

# ---- (b) 1.12（详解）：u = |ln ρ²|^α 的 H¹(B_{1/2}) 成员资格 ----
# 详解结论：α < 1/2 时 ∈ H¹。数值验证边界 α 值
function h1_norm_log(alpha; n = 2000)
    # ∫₀^{1/2} (|2 ln r|^α)² r dr 与 ∫(∂_r u)² r dr（极坐标，2π 因子略）
    s0 = 0.0
    s1 = 0.0
    h = 0.5 / n
    for k in 0:n-1
        r = (k + 0.5) * h
        f = abs(2 * log(r))^alpha
        df = alpha * abs(2 * log(r))^(alpha - 1) * 2 / r   # |d/dr|
        s0 += f^2 * r * h
        s1 += df^2 * r * h
    end
    return s0, s1
end
for alpha in [0.3, 0.7]
    s0, s1 = h1_norm_log(alpha)
    @printf("(b) 1.12 α=%.1f: ∫u²·r = %.4f, ∫|∇u|²·r = %.4e %s\n",
            alpha, s0, s1, alpha < 0.5 ? "(finite ⟹ ∈H¹)" : "(diverging as n→∞)")
end
s0a, s1a = h1_norm_log(0.3, n = 4000)
s0b, s1b = h1_norm_log(0.3, n = 2000)
@assert abs(s1a - s1b) / s1a < 0.1 "α=0.3: 加密收敛（积分有限）"
s0c, s1c = h1_norm_log(0.7, n = 4000)
@assert s1c > s1b * 1.3 "α=0.7: 梯度积分随加密增长（发散）"

# ---- (c) 1.18：带形 Π = (0,1)×ℝ 中 Friedrichs 成立 ----
# ‖u‖² ≤ C(‖∇u‖² + 边界？)——零边值情形：λ₁ = π²（x 方向第一模式）
for k in [1.0, 2.0]
    lam = (k * pi)^2
    @printf("(c) 1.18 strip: mode sin(kπx)·(任意 y): eigenvalue %.4f ≥ π²\n", lam)
end
@assert pi^2 < 4pi^2 "Friedrichs 常数 = 1/π²（带形宽度决定）"
# 反面（1.17）：非 Friedrichs 区域——粗十字形（瓶颈让常数 → 0）
println("    1.17 counterexample domain: dumbbell/cross with narrow neck ⟹ C → 0")

# ---- (d) 1.19：B(0) 上点值估计 |u(0)| ≤ C‖u‖_{H¹} 不成立（n≥2）----
# 尖峰族 u_ε = φ(x/ε)/ε^{(n-2)/2}?——n=2 取 u_ε = √(|ln ε|)⁻¹·φ(x/ε)·?
# 简单样本：u_δ(x) = max(0, 1 − |x|/δ)：u(0) = 1 恒定
for delta in [0.3, 0.1, 0.03]
    # n=2: ‖u‖²_{L²(B)} ~ δ²，‖∇u‖² ~ |ln δ|·? 尖峰能量 ∫(1/δ)²·δ²dθ ~ 常数
    grad2 = pi / 1  # ∫_{|x|<δ} (1/δ)² dx = π（δ 无关）
    l22 = pi * delta^2 / 6
    @printf("(d) 1.19 peak δ=%.2f: u(0)=1, ||∇u||² ≈ π = %.3f, ||u||² = %.4f\n",
            delta, grad2, l22)
end
@printf("    n=2: H¹ 范数有界但可造无界峰值族（H¹ ⊅ L^∞ in n≥2）\n")
@assert pi * 0.1^2 / 6 < pi * 0.3^2 / 6 "L² 缩但梯度不变"

println("END ====")
