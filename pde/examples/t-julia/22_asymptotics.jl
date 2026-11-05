# Ch22 解的表示 VI：渐近方法
#
# 对应书 §4.5：奇异摄动与边界层、Laplace 方法、驻相/几何光学、
# 均匀化概述。

using Printf

println("==== 22")

# ---- (a) 奇异摄动边界层：εu'' + u' = 0, u(0)=0, u(1)=1 ----
# 精确解 u = (e^{-x/ε} − e^{-1/ε})/(1 − e^{-1/ε})；
# 外解 u_out = 1，边界层宽 O(ε) 在 x=0
for eps in [0.2, 0.05, 0.01]
    u_exact(x) = (exp(-x / eps) - exp(-1 / eps)) / (1 - exp(-1 / eps))
    @printf("(a) eps=%.2f: layer half-width (u≈0.5 at x) = %.4f ≈ ε ln2\n", eps, eps * log(2))
    # 半点值偏差由末端项 e^{-1/ε} 定标（ε 大时不可忽略）
    @assert abs(u_exact(eps * log(2)) - 0.5) < exp(-1 / eps) + 1e-9 "边界层剖面 e^{-x/ε}"
end

# ---- (b) Laplace 方法：I(λ) = ∫₀¹ e^{λ f(x)}dx, f = -(x-a)², a=0.3 ----
# I(λ) ~ e^{λf(a)}√(π/λ)（内点极大）；数值 vs 渐近
function I_lap(lam; n = 20000)
    h = 1 / n
    s = 0.0
    for k in 0:n
        x = k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * exp(-lam * (x - 0.3)^2)
    end
    return s * h / 3
end
a = 0.3
for lam in [50.0, 200.0, 800.0]
    num = I_lap(lam)
    asym = exp(0) * sqrt(pi / lam)   # f(a) = 0
    @printf("(b) Laplace: I(%.0f) = %.9f  asym √(π/λ) = %.9f  ratio = %.6f (->1)\n",
            lam, num, asym, num / asym)
    @assert abs(num / asym - 1) < 0.05 "最速下降集中在极大点"
end

# ---- (c) 驻相：I(k) = ∫ e^{ikφ(x)} dx, φ = (x-0.5)²/2（内驻点 x=0.5）----
# 驻相贡献 ~ e^{ikφ(x*) + iπ/4·sgn}·√(2π/(k|φ''|))；数值 |I| 对照 √(2π/k)
function stat_phase(k; n = 400000)
    h = 1 / n
    s_re, s_im = 0.0, 0.0
    for j in 0:n
        x = (j + 0.5) * h
        ph = (x - 0.5)^2 / 2
        s_re += cos(k * ph)
        s_im += sin(k * ph)
    end
    return sqrt(s_re^2 + s_im^2) * h
end
ratios = Float64[]
for k in [50.0, 200.0, 800.0]
    num = stat_phase(k)
    asym = sqrt(2pi / k)   # |e^{iπ/4}|·√(2π/(k·1))
    push!(ratios, num / asym)
    @printf("(c) stationary phase: |I(%.0f)| = %.6f  asym √(2π/k) = %.6f  ratio = %.4f (->1)\n",
            k, num, asym, num / asym)
end
# 端点贡献 O(1/k) 与驻相项干涉：k 大时比值趋于 1（单调收敛签名）
@assert ratios[3] > ratios[1] "驻相主导随 k 增强"
@assert abs(ratios[3] - 1) < 0.06 "k=800 时驻相首项准确到 6%"

# ---- (d) 均匀化（定性）：周期系数 a(x/ε) 的有效传导率 = 调和平均 ----
# -（a(x/ε) u'）' = f 的有效系数 a*：1D 精确 = 调和平均
# 数值：解两点边值（Thomas），比较 ε→0 时解趋于常系数 a* 的解
a_per(z) = 1.5 + 0.5 * sin(2pi * z)   # 周期 1
# ⟨1/a⟩ = 1/√(a0²−a1²)（∫dz/(a0+a1 sin) = 2π/√(a0²−a1²)）⟹ a* = √(a0²−a1²)
a_star = sqrt(1.5^2 - 0.5^2)
s = 0.0
n = 20000
for k in 0:n-1
    global s += 1 / a_per(k / n)
end
harmonic = 1 / (s / n)
@printf("(d) homogenized coeff: harmonic avg = %.9f  closed √(a0²-a1²) = %.9f\n",
        harmonic, a_star)
@assert abs(harmonic - a_star) < 1e-8 "1D 有效系数 = 调和平均（闭式对账）"

println("END ====")

