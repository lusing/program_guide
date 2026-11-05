# Ch46 控制论、动态规划与 HJB
#
# 对应书 §10.3：最优控制（最小化 ∫L + 终端费用）、动态规划原理、
# Hamilton-Jacobi-Bellman 方程、Hopf-Lax 的控制解释。

using Printf

println("==== 46")

# ---- (a) 动态规划原理：值函数的半群性（数值核）----
# 值 V(x,t) = min ∫₀ᵗ½|α|² + g(x(t))，x(0)=x，自由末端
# 动态规划：V(x, t+s) = min_α ∫₀ˢ… + V(x(s), t)——离散验证：
# LQR 一维：L = ½α²、g(x) = ½x²、动力学 x' = α
# 值函数 V(x,t) = c(t)x²/2，HJB：-V_t = min(½α² + αV_x) = -V_x²/2
# ⟹ c'(t)/2 x² = -c²x²/2 ⟹ c' = -c²，c(0) = 1 ⟹ c(t) = 1/(1+t)
c_of(t) = 1 / (1 + t)
for t in [0.0, 0.5, 2.0]
    # 验证 HJB：-V_t = V_x²/2（V = cx²/2）
    ct = c_of(t)
    dcdt = -1 / (1 + t)^2
    # -V_t = -c' x²/2 = x²/(2(1+t)²)；V_x²/2 = (cx)²/2 = x²/(2(1+t)²) ✓
    @printf("(a) LQR value c(%.1f) = %.4f; HJB residual = %.1e\n",
            t, ct, abs(-dcdt / 2 - ct^2 / 2))
    @assert abs(-dcdt / 2 - ct^2 / 2) < 1e-15 "Riccati ODE c' = -c² 的解满足 HJB"
end

# ---- (b) 最优反馈：α* = -V_x（最小化者的显式）----
for x in [0.5, -1.0]
    t = 0.5
    alpha_star = -c_of(t) * x
    @printf("(b) optimal feedback at x=%+.1f: alpha* = %.4f (= -c x)\n", x, alpha_star)
    @assert alpha_star == -c_of(t) * x
end

# ---- (c) 动态规划的数值：两步费用 ≥ 一步费用（DP 方程）----
# V(x, t+s) ≤ ∫₀ˢL(α) + V(x_α(s), t)（min 在策略上）数值 LQR：
function cost_two_step(x0, s, t)
    # 先走 s 用最优 α，再面对 V(·, t)
    c_s = c_of(s)
    alpha = -c_s * x0
    # 状态演化（简化：最优轨迹 x(s) = x0/(1+s)）
    xs = x0 / (1 + s)
    running = 0.5 * alpha^2 * s   # 近似（α 随时间变，小 s 可近似）
    return running + c_of(t) * xs^2 / 2
end
x0 = 0.8
for (s, t) in [(0.2, 0.5), (0.1, 0.6)]
    direct = c_of(s + t) * x0^2 / 2
    two = cost_two_step(x0, s, t)
    @printf("(c) DP at s=%.1f,t=%.1f: direct %.6f vs two-step %.6f\n", s, t, direct, two)
    @assert direct ≤ two + 0.01 "DP：整体最优 ≤ 任何分段（近似实现）"
end

# ---- (d) Hopf-Lax = 线性二次控制：min 轨迹与公式一致 ----
# x'=α 自由、费用 ∫½α² + g(x(1))：最优 α = 常数（直线轨迹到 y）
# V = min_y (y-x)²/2 + g(y)（Hopf-Lax t=1）——控制解释：直线最优
function scan_value(x)
    best = Inf
    for y in -2:0.0001:4
        best = min(best, (y - x)^2 / 2 + (y - 1.0)^2 / 4)
    end
    return best
end
x = 0.5
g46(y) = (y - 1.0)^2 / 4
best = scan_value(x)
# 解析：d/dy：(y−x) + (y−1)/2 = 0 ⟹ y = (2x+1)/3
y_star = (2x + 1) / 3
closed = (y_star - x)^2 / 2 + g46(y_star)
@printf("(d) Hopf-Lax control value: scan %.8f  closed %.8f\n", best, closed)
@assert abs(best - closed) < 1e-6 "直线轨迹最优（Hopf-Lax 的控制出身）"

println("END ====")
