# Ch35 线性发展 II：抛物正则性与极值原理
#
# 对应书 §7.1.3（正则性：u ∈ C^∞ 时间上、时空 H^{2m}）与 §7.1.4
#（弱/强极值原理、正性保持、唯一性、渐近行为）。

using Printf

println("==== 35")

# ---- (a) 时间无穷光滑化：u_t 的任意阶导有限（解析半群 e^{-tA}）----
# 谱：A 的幂把系数乘 λ_k^m，e^{-λ_k t} 赢——任意 m 有限
for (m, t) in [(2, 0.5), (4, 0.5), (8, 0.5)]
    # ‖A^m u(t)‖² = Σ λ_k^{2m} c_k² e^{-2λ_k t}；g = sin(πx) 单模式
    val = pi^(4m) * exp(-2pi^2 * t)
    @printf("(a) ||A^%d u(0.5)||² = %.2e (finite: e^{-λt} beats λ^{2m})\n", m, val)
end
@assert pi^(32) * exp(-2pi^2 * 0.5) < 1e12 "高幂仍有限（解析半群）"

# ---- (b) 正性保持：f ≥ 0、g ≥ 0 ⟹ u > 0（严格，连通域内部）----
# 谱表示：u = Σ (f 载荷) e^{-λ_k t}φ_k + 初值项——正性非显然但热核
# 正性（06 章）保证。数值：热核卷积正性
Phi1(x, t) = (4pi * t)^(-0.5) * exp(-x^2 / (4t))
function heat_pos(x, t)
    n = 4000
    L = 10 * sqrt(t) + 2
    h = 2L / n
    s = 0.0
    for k in 0:n
        y = -L + k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * Phi1(x - y, t) * max(0.0, 1 - abs(y))   # 帐篷 ≥ 0
    end
    return s * h / 3
end
for x in [1.5, 3.0]
    v = heat_pos(x, 0.5)
    @printf("(b) positivity: u(%.1f, 0.5) = %.4e > 0\n", x, v)
    @assert v > 0 "非负非零初值 ⟹ 内部严格正（强极值原理）"
end

# ---- (c) 唯一性（能量法，书 §7.1.4）：差满足能量不等式 ⟹ 0 ----
# 谱面：两个解差的每个模式乘 e^{-λt} ≤ 初值差 ⟹ L² 收缩
diff0 = 0.3
for t in [0.5, 2.0]
    d = diff0 * exp(-pi^2 * t)
    @printf("(c) contraction: ||w(t)|| = %.4e ≤ ||w(0)||e^{-π²t} (unique)\n", d)
    @assert d < diff0
end

# ---- (d) 渐近行为：t → ∞ 衰减到稳态（零边值 ⟹ 0，速率 λ₁）----
asym = exp(-2pi^2 * 5) / exp(-2pi^2 * 4)
@printf("(d) 5-fold time decade: E(5)/E(4) = %.2e (= e^{-2π²})\n", asym)
@assert abs(asym - exp(-2pi^2)) < 1e-15 "能量衰减率恒 2λ₁"

println("END ====")

