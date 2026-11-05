# Ch14 Hamilton-Jacobi II：弱解、粘性消失与唯一性
#
# 对应书 §3.3.3：Hopf-Lax 公式给出弱解、半凹性、比较原理与唯一性。
# 数值面：粘性方程 u^ε_t + (u^ε_x)²/2 = ε u^ε_xx 的解当 ε→0 收敛
# 到 Hopf-Lax 粘性解（特征线相交后特征线解失效，粘性解继续）。

using Printf

println("==== 14")

# ---- (a) 特征线解的失效时刻（11 章灾难时间的 HJ 版）----
# u_t + (u_x)²/2 = 0，g = -cos(x)（p0 = sin ξ，特征 x = ξ + sinξ·t）
# Jacobian 1 + cos(ξ)t = 0 首次在 t* = 1（ξ = π）
tstar = 1 / maximum(abs(cos(ξ)) for ξ in range(0, 2pi, length = 10000))
@printf("(a) characteristic breakdown t* = %.6f (expect 1.0)\n", tstar)
@assert abs(tstar - 1.0) < 1e-9

# ---- (b) 粘性消失：u^ε 显式解 → Hopf-Lax（Cole-Hopf 预演，21 章正式）----
# u^ε_t + (u^ε_x)²/2 = ε u^ε_xx 的 Hopf-Cole 解：
# u^ε = -2ε log ∫ exp(-g(y)/(2ε)) · Gauss(y-x, 2εt) dy
g14(y) = -cos(y)
function viscous_solution(x, t, eps; L = 6.0, n = 8000)
    sig = sqrt(2 * eps * t)
    lo, hi = x - L * sig - 3, x + L * sig + 3
    h = (hi - lo) / n
    s = 0.0
    for k in 0:n
        y = lo + k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * exp(-g14(y) / (2eps) - (y - x)^2 / (4eps * t))
    end
    return -2eps * log(s * h / 3 / sqrt(4pi * eps * t))
end
# Hopf-Lax 粘性解：min_y [(y-x)²/2t + g(y)]（数值）
function hopf_lax14(x, t; n = 200001)
    lo, hi = x - 3 * sqrt(t) - 3, x + 3 * sqrt(t) + 3
    best = Inf
    for k in 0:n-1
        y = lo + (hi - lo) * k / n
        best = min(best, (y - x)^2 / (2t) + g14(y))
    end
    return best
end
# t < 1（光滑范围）：粘性解 → 特征线解；t > 1：特征线解多值，
# 粘性解 → Hopf-Lax。两个时刻都对照 Hopf-Lax。
for (x, t) in [(0.5, 0.6), (1.0, 2.0), (2.0, 3.5)]
    hl = hopf_lax14(x, t)
    @printf("(b) x=%.1f t=%.1f: Hopf-Lax = %.8f; viscous solutions:\n", x, t, hl)
    us = [viscous_solution(x, t, eps) for eps in [0.08, 0.02, 0.005]]
    for (eps, ue) in zip([0.08, 0.02, 0.005], us)
        @printf("    eps=%.3f: u^eps = %.8f  (diff to HL: %.2e)\n", eps, ue, abs(ue - hl))
    end
    @assert abs(us[2] - hl) < abs(us[1] - hl) && abs(us[3] - hl) < abs(us[2] - hl) "ε 减半 ⟹ 更接近粘性解"
    @assert abs(us[3] - hl) < 1e-2 "最小 ε 已接近 Hopf-Lax（收敛速率 O(ε|log ε|)）"
end

# ---- (c) 半凹性：Hopf-Lax 解的凸性残差（书 §3.3.3 定理 4）----
# u(·,t) 自动半凹（凸差）；数值：u(x+h) − 2u(x) + u(x−h) ≥ -C·h²
function hl_value(x, t)
    hopf_lax14(x, t, n = 20001)
end
x0, t0 = 0.8, 2.0
for h in [0.1, 0.05]
    d2 = hl_value(x0 + h, t0) - 2hl_value(x0, t0) + hl_value(x0 - h, t0)
    @printf("(c) semiconcavity h=%.2f: u(x+h)-2u(x)+u(x-h) = %+.6f (>= -C h²)\n", h, d2)
    @assert d2 > -0.01 "半凹：二阶差分下有界"
end

println("END ====")

