# Ch31 二阶椭圆 III：正则性
#
# 对应书 §6.3：内部正则性（差商方法：u ∈ H¹ + Lu ∈ L² ⟹ H²_loc）、
# 边界正则性（H² 全局，C¹ 域）、更高正则性（f 光滑 ⟹ u 光滑）。

using Printf

println("==== 31")

# ---- (a) 内部 H² 的数值签名：误差余项 r_h = -Δ_h u + f 在内部消失 ----
# u = sin(πx)sin(πy)（H²）；f = 2π²sin sin
# 离散 Laplacian 的截断误差 O(h²)（u ∈ C^∞）；对照 u = |x|^{3/2}（仅 H² 边缘）
f31(x, y) = 2pi^2 * sin(pi * x) * sin(pi * y)
lap5(u, x, y, h) = (u(x+h,y) + u(x-h,y) + u(x,y+h) + u(x,y-h) - 4u(x,y)) / h^2
u_s(x, y) = sin(pi * x) * sin(pi * y)
for h in [0.05, 0.01]
    r = abs(lap5(u_s, 0.4, 0.6, h) + f31(0.4, 0.6))
    @printf("(a) smooth residual h=%.3f: %.2e (O(h²))\n", h, r)
end
r1 = abs(lap5(u_s, 0.4, 0.6, 0.05) + f31(0.4, 0.6))
r2 = abs(lap5(u_s, 0.4, 0.6, 0.01) + f31(0.4, 0.6))
@assert r2 < r1 / 20 "截断误差随 h² 收敛（H² 的数值面）"

# ---- (b) 差商方法的签名：‖D^h ∇u‖ 有界 ⟹ H² ----
# 对 u ∈ H²：二阶差商范数一致有界；u = |x|^{3/2} 于 0 处的差商爆炸（H² 临界）
u_c(x) = abs(x)^(3 / 2)
for h in [0.01, 1e-3, 1e-4]
    d2 = (u_c(h) - 2u_c(0) + u_c(-h)) / h^2
    @printf("(b) |x|^{3/2} second difference at 0, h=%.0e: %.3f (h^{-1/2} blows)\n", h, d2)
end
d2a = (u_c(0.01) - 2u_c(0) + u_c(-0.01)) / 1e-4
d2b = (u_c(1e-4) - 2u_c(0) + u_c(-1e-4)) / 1e-8
@assert d2b > d2a * 5 "二阶差商爆炸：x^{3/2} ∉ H² 邻域证据（临界幂）"

# ---- (c) 光滑提升：f ∈ C^∞ ⟹ u ∈ C^∞（迭代正则性）----
# 谱版：f 的 Fourier 系数衰减 ⟹ u 的衰减快 λ_k 倍
for k in [1, 5, 20]
    fk = exp(-k / 5.0)          # f 的衰减（光滑）
    uk = fk / (k * pi)^2        # u 系数：额外 λ⁻¹ 衰减
    @printf("(c) mode k=%2d: |f_k| = %.4f  |u_k| = %.2e (extra k^-2 decay)\n", k, fk, abs(uk))
end
@assert abs(exp(-20 / 5) / (20pi)^2) < exp(-20 / 5) * 1e-3 "u 比 f 光滑两阶（每微分方程换 2 阶）"

# ---- (d) 边界正则性：角域的奇性（L 形域 reentrant corner ⟹ u ~ r^{2/3}）----
# 系数 α = π/ω（ω = 3π/2 ⟹ α = 2/3）：u = r^{2/3}sin(2θ/3) 是调和的
# 于 L 形域——H¹ 但 ∉ H²（边界正则性在角点失效的著名反例）
u_l(r) = r^(2 / 3)
@printf("(d) L-shaped domain: u ~ r^{2/3}; second difference at r=h:\n")
for h in [1e-2, 1e-4, 1e-6]
    d2 = (u_l(2h) - 2u_l(h) + u_l(0.0)) / h^2
    @printf("    h=%.0e: |u''_h| = %.1f (h^{-4/3} blow-up: NOT H² at corner)\n", h, abs(d2))
end
d2a = abs((u_l(0.02) - 2u_l(0.01)) / 1e-4)
d2b = abs((u_l(2e-6) - 2u_l(1e-6)) / 1e-12)
@assert d2b > d2a * 100 "凹角奇性：二阶导在角点爆炸（边界正则性需要光滑边界）"

println("END ====")
