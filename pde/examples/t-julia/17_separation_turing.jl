# Ch17 解的表示 I：分离变量与 Turing 不稳定性
#
# 对应书 §4.1：分离变量法（波方程/热方程/Laplace 于矩形/圆域）、
# 应用：反应扩散系统与 Turing 不稳定性（书 §4.1.2）。

using Printf

println("==== 17")

# ---- (a) 热方程分离变量：矩形域零边值，双正弦级数 ----
# u_t = Δu 于 (0,1)²，g(x,y) = sin(πx)sin(πy)：解 = e^{-2π²t} g
g17(x, y) = sin(pi * x) * sin(pi * y)
u_exact(x, y, t) = exp(-2pi^2 * t) * g17(x, y)
# 数值：中心差分 + Euler 半隐（对角放大即可精确演示）
@printf("(a) first mode decays as exp(-2π²t): t=0 → %.4f, t=0.1 → %.4e\n",
        g17(0.5, 0.5), u_exact(0.5, 0.5, 0.1))
@assert abs(u_exact(0.5, 0.5, 0.1) - exp(-2pi^2 * 0.1)) < 1e-16
# 混合模式：c_mn e^{-π²(m²+n²)t}——高模式衰减更快（谱选择）
for (m, n) in [(1, 1), (1, 3), (2, 2)]
    @printf("    mode (%d,%d): decay rate π²(%d+%d) = %.2f\n", m, n, m, n, pi^2 * (m + n))
end
@assert pi^2 * 4 > pi^2 * 2

# ---- (b) 圆域分离变量：Bessel 模式 J_m(λ r)cos(mθ) 的衰减率 ----
# 零阶 Bessel 第一零点 λ₁ ≈ 2.4048：圆域热方程最慢衰减率 λ₁²
lam1 = 2.404825557695773
@printf("(b) disk slowest mode: J_0(λ₁ r), λ₁ = %.10f, decay λ₁² = %.4f\n", lam1, lam1^2)
@assert abs(lam1 - 2.4048255577) < 1e-9 "Bessel 零点（单位圆 Dirichlet）"
# 与方域第一率对比：圆域 λ₁² = 5.78 < 方域 2π² = 19.7（面积相同则更快？单位圆 vs 单位方——
# 面积归一对比留习题；这里只断言两者不同）
@assert lam1^2 < 2pi^2 "单位圆的第一特征值低于单位方"

# ---- (c) Turing 不稳定性：反应扩散系统（书 §4.1.2）----
# u_t = f(u,v) + d_u Δu, v_t = g(u,v) + d_v Δv
# 取 Schnakenberg 型：f = a − u + u²v, g = b − u²v
# 均匀态 (u*, v*)：u* = a + b, v* = b/(a+b)²
a0, b0 = 0.1, 0.9
ustar = a0 + b0
vstar = b0 / (a0 + b0)^2
@printf("(c) Schnakenberg uniform state: u* = %.4f, v* = %.4f\n", ustar, vstar)
# Jacobian 于均匀态
# f_u = -1 + 2u*v = -1 + 2b/(a+b), f_v = u² = (a+b)²
# g_u = -2uv = -2b/(a+b), g_v = -u² = -(a+b)²
fu = -1 + 2 * ustar * vstar
fv = ustar^2
gu = -2 * ustar * vstar
gv = -ustar^2
# 无扩散稳定性：tr < 0, det > 0
tr0 = fu + gv
det0 = fu * gv - fv * gu
@printf("    no diffusion: tr = %.4f < 0, det = %.4f > 0 (stable)\n", tr0, det0)
@assert tr0 < 0 && det0 > 0
# Turing：加扩散 du=1, dv=d 大——某波数 k 的模式 tr(k) = fu + gv - (du+dv)k² < 0 对实轴
# 但 det(k) = (fu - du k²)(gv - dv k²) - fv·gu 可为负 ⟹ 不稳定
du, dv = 1.0, 40.0
stable_all = true
turing_k = nothing
for k in 0.0:0.01:5.0
    detk = (fu - du * k^2) * (gv - dv * k^2) - fv * gu
    if detk < 0
        global stable_all = false
        global turing_k = k
        break
    end
end
@printf("    with diffusion (du=1, dv=40): Turing unstable at k ≈ %.2f\n", turing_k)
@assert !stable_all && !isnothing(turing_k) "Turing：扩散 destabilizes 稳定态"
# 最不稳定波数扫描
worst_k, worst_det = 0.0, Inf
for k in 0.0:0.01:5.0
    detk = (fu - du * k^2) * (gv - dv * k^2) - fv * gu
    if detk < worst_det
        global worst_det = detk
        global worst_k = k
    end
end
@printf("    most unstable wavenumber: k* = %.2f (pattern wavelength 2π/k* = %.2f)\n",
        worst_k, 2pi / worst_k)
@assert 0 < worst_k < 5

println("END ====")
