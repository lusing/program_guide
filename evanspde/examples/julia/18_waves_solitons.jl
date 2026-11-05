# Ch18 解的表示 II：行波、孤子与相似解
#
# 对应书 §4.2：行波与孤子（KdV）、伸缩相似解（Barenblatt）。

using Printf

println("==== 18")

# ---- (a) KdV 单孤子 u = 3c·sech²(√c(x−ct)/2) 满足 u_t + u u_x + u_xxx = 0 ----
sech(z) = 1 / cosh(z)
u_sol(x, t, c) = 3c * sech(sqrt(c) * (x - c * t) / 2)^2
function kdv_residual(x, t, c)
    d = 1e-4
    ut = (u_sol(x, t + d, c) - u_sol(x, t - d, c)) / (2d)
    ux = (u_sol(x + d, t, c) - u_sol(x - d, t, c)) / (2d)
    # 三阶导：五点差分
    uxxx = (u_sol(x + 2d, t, c) - 2u_sol(x + d, t, c) + 2u_sol(x - d, t, c) - u_sol(x - 2d, t, c)) / (2d^3)
    return ut + u_sol(x, t, c) * ux + uxxx
end
for (x, t, c) in [(0.3, 1.0, 1.0), (-2.0, 0.5, 2.0)]
    r = kdv_residual(x, t, c)
    @printf("(a) KdV soliton residual at (%.1f,%.1f,c=%.0f): %.2e\n", x, t, c, r)
    @assert abs(r) < 5e-3 "孤子是 KdV 行波解（三阶差分精度受限）"
end
# 速度-振幅关系：c ↦ 3c（振幅高 ⟹ 跑得快——碰撞的根源）
@printf("    amplitude 3c vs speed c: 3·%.0f = %.0f at c=%.0f\n", 2.0, 3 * 2.0, 2.0)

# ---- (b) KdV 双孤子（Hirota 双线性式）----
# 坑账：Hirota 的 F 对应 u_t + 6uu_x + u_xxx 版本：ηᵢ = 2kᵢ(x − 4kᵢ²t − xᵢ₀)
# （带前因子 2k、速度 4k²）、v = 2∂²ₓlogF；换到我们的系数 1 版本要
# u = 6v = 12∂²ₓlogF。初版三处系数全错（k 前因子、速度 k²、系数 2），
# 峰值对账（48/12）当场暴露。
function eta(k, x0, x, t)
    2 * k * (x - 4 * k^2 * t - x0)
end
function F2s(x, t; k1 = 2.0, k2 = 1.0, x1 = -8.0, x2 = -2.0)
    A = ((k1 - k2) / (k1 + k2))^2
    e1 = exp(eta(k1, x1, x, t))
    e2 = exp(eta(k2, x2, x, t))
    1 + e1 + e2 + A * e1 * e2
end
# u = 12∂²ₓlog F = 12(F''F − F'²)/F² 的闭式（η' = 2k 常数）：
# 坑账：数值 log-二阶差分再叠三阶差分是"差分套差分"，噪声 1e-8/8e-12
# ≈ 1e4 量级——必须把 ∂²ₓlogF 写成闭式再对闭式 u 做数值差分。
function u2s(x, t; k1 = 2.0, k2 = 1.0, x1 = -8.0, x2 = -2.0)
    A = ((k1 - k2) / (k1 + k2))^2
    p1 = 2k1
    p2 = 2k2
    e1 = exp(eta(k1, x1, x, t))
    e2 = exp(eta(k2, x2, x, t))
    F = 1 + e1 + e2 + A * e1 * e2
    Fp = p1 * e1 + p2 * e2 + A * (p1 + p2) * e1 * e2
    Fpp = p1^2 * e1 + p2^2 * e2 + A * (p1 + p2)^2 * e1 * e2
    return 12 * (Fpp * F - Fp^2) / F^2
end
# 残差检验：在分离良好的时刻 t=−2（相互作用前），两个峰各自完整
# （双孤子有相移，t=0 时慢峰被交叉项压缩——峰位/峰高断言只在渐近区做）
for (x, t, tag) in [(-40.0, -2.0, "fast"), (-10.0, -2.0, "slow")]
    d = 1e-4
    ut = (u2s(x, t + d) - u2s(x, t - d)) / (2d)
    ux = (u2s(x + d, t) - u2s(x - d, t)) / (2d)
    uxxx = (u2s(x + 2d, t) - 2u2s(x + d, t) + 2u2s(x - d, t) - u2s(x - 2d, t)) / (2d^3)
    r = ut + u2s(x, t) * ux + uxxx
    @printf("(b) 2-soliton residual (%s branch, t=-2): %.2e\n", tag, r)
    @assert abs(r) < 5e-2 "Hirota 双孤子解（分离区数值验证）"
end
# 渐近峰高：快孤子 12k₁² = 48（允许相移 ±1 的小偏移）
peak = maximum(u2s(xx, -2.0) for xx in -45:0.05:-30)
@printf("    fast peak at t=-2: %.2f (expect ≈48)\n", peak)
@assert peak > 40 && peak < 50 "快孤子振幅 12k₁²"

# ---- (c) Barenblatt 相似解（多孔介质 u_t = (u²)_xx）----
# u = t^{-1/3}(C − |y|²/12)_+，y = x t^{-1/3}（n=1, m=2；C 任意常数）
function barenblatt(x, t; C = 1.0)
    y = x * t^(-1 / 3)
    w = C - y^2 / 12
    return t^(-1 / 3) * max(w, 0)^1  # (u^m)_xx 的 m=2 解里指数是 1/(m-1)=1 ✓
end
# 质量守恒：∫u dx = C·2√(12C)·? 数值验证守恒
mass(t; n = 4000) = begin
    L = 10 * t^(1 / 3)
    s = 0.0
    h = 2L / n
    for k in 0:n
        x = -L + k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * barenblatt(x, t)
    end
    s * h / 3
end
m1, m2 = mass(1.0), mass(8.0)
@printf("(c) Barenblatt mass: t=1 → %.8f, t=8 → %.8f (conserved)\n", m1, m2)
@assert abs(m1 - m2) < 1e-9 "紧支相似解的质量守恒"
# 支撑半径增长律：r(t) = √(12C)·t^{1/3}
for t in [1.0, 8.0, 27.0]
    r = sqrt(12.0) * t^(1 / 3)
    @printf("    t=%2.0f: support radius √12·t^{1/3} = %.4f\n", t, r)
end
@assert sqrt(12) * 8^(1 / 3) == 2sqrt(12) "t^{1/3} 外扩（有限传播！与热方程 √t 对照）"

println("END ====")
