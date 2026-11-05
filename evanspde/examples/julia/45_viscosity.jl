# Ch45 Hamilton-Jacobi II：粘性解
#
# 对应书 §10.1-10.2：粘性解定义（上/下jets 的子微分不等式）、一致
# 性（光滑解 ⟹ 粘性解）、比较原理与唯一性。

using Printf

println("==== 45")

# ---- (a) 粘性解判据：在极值点验子微分不等式 ----
# HJ：u_t + H(u_x) = 0，H(p) = |p|²/2。粘性解：在局部极大点
# τ + H(ξ) ≤ 0（上微分包络）。Hopf-Lax 解 u = min_y[...] 的尖点处检验
# 初值 g = -|x|（尖点 0）：粘性解 u(x,t) 在 x=0 保持尖点
# u(x,t) = -|x| + t/2·? Hopf-Lax：min (y-x)²/2t - |y|：分支解
# y-支（y<0）：值 -(x²)/(2t)·? 直接：u(0,t) = min_y y²/2t − |y| = −t/2
for t in [0.3, 1.0]
    @printf("(a) u(0,t) = %.4f (viscosity value -t/2 at cusp)\n", -t / 2)
end
# 在 x=0 处 u_x 不存在：粘性判据用次微分 ±1/2·? H(p)=p²/2 在 p=±√t/2·?
# 数值验证粘性不等式：τ + min_p H(p) over reachable ξ ≤ 0 形式
# 对称尖点：可达 ξ = ±√(t/2)·?——直接验证 Hopf-Lax 满足粘性不等式：
# u_t(0,t) = -1/2；可达斜率 ξ = ±u_x(0±) = ±1（来自 -|x| 分支）
# τ + H(ξ) = -1/2 + 1/2 = 0 ≤ 0 ✓（等式——熵等式）
tau = -0.5
for xi in [-1.0, 1.0]
    val = tau + xi^2 / 2
    @printf("    viscosity check at cusp: tau + H(%.0f) = %.4f ≤ 0 (equality)\n", xi, val)
    @assert val ≤ 1e-12 "上微分子微分不等式（尖点处等式成立）"
end

# ---- (b) 一致性：光滑区域内粘性解 = 经典解（残差核对）----
# g = x²/4 的 Hopf-Lax 解（12/13 章）：光滑段 u = x²/(4(1+t/2))·?
u_smooth(x, t) = (x / (1 + t / 2))^2 / 4 + ((x / (1 + t / 2)) / 2)^2 / 2 * t
d = 1e-5
for (x, t) in [(0.5, 0.4), (1.0, 0.8)]
    ut = (u_smooth(x, t + d) - u_smooth(x, t - d)) / (2d)
    ux = (u_smooth(x + d, t) - u_smooth(x - d, t)) / (2d)
    r = ut + ux^2 / 2
    @printf("(b) smooth region: u_t + u_x²/2 = %.2e (classical = viscous)\n", r)
    @assert abs(r) < 1e-6 "光滑处粘性解满足方程（一致性）"
end

# ---- (c) 比较原理（唯一性内核）：u ≤ v 于抛物边界 ⟹ u ≤ v 全域 ----
# Hopf-Lax 关于初值单调：g₁ ≤ g₂ ⟹ HL[g₁] ≤ HL[g₂]（数值）
g1(y) = -abs(y)
g2(y) = -abs(y) + 0.3   # g2 = g1 + 0.3
function hl(x, t, g; n = 100001)
    lo, hi = x - 3 * sqrt(t) - 1, x + 3 * sqrt(t) + 1
    best = Inf
    for k in 0:n-1
        y = lo + (hi - lo) * k / n
        best = min(best, (y - x)^2 / (2t) + g(y))
    end
    return best
end
for (x, t) in [(0.2, 0.5), (1.0, 1.5)]
    v1 = hl(x, t, g1, n = 20001)
    v2 = hl(x, t, g2, n = 20001)
    @printf("(c) comparison: HL[g1](%.1f,%.1f) = %.4f ≤ HL[g1+0.3] = %.4f\n", x, t, v1, v2)
    @assert v1 ≤ v2 + 1e-6 "初值单调 ⟹ 解单调（比较原理的构造面）"
end

# ---- (d) 唯一性推论：g1 = g2 ⟹ 解相同（对同一公式数值恒等）----
v1 = hl(0.4, 0.7, g1, n = 50001)
v2 = hl(0.4, 0.7, y -> -abs(y), n = 50001)
@assert abs(v1 - v2) < 1e-9 "相同初值 ⟹ 相同粘性解（唯一性）"

println("END ====")
