# Ch27 Sobolev 空间 IV：紧性、Poincaré、差商
#
# 对应书 §5.7（紧嵌入 Rellich-Kondrachov）与 §5.8（Poincaré 不等式、
# 差商刻画内部 W^{1,p}）。

using Printf

println("==== 27")

# ---- (a) Rellich 紧性数值签名：有界 H¹ 序列的高频分量压缩 ----
# 取 u_k = sin(kπx)/k（‖u_k‖_{H¹} 有界：‖u‖=1/(k√2), ‖u'‖=√(π²k²)/k√2 有界）
# L² 极限 0——序列在 L² 紧（有收敛子列）；对照 v_k = sin(kπx)（L² 范数
# 恒定但 H¹ 爆炸，不紧的对照）
for k in [1, 5, 20]
    l2_uk = 1 / (k * sqrt(2))
    @printf("(a) u_k = sin(kπx)/k: ||u_k||_2 = %.4f -> 0 (H1 bounded, L2 compact)\n", l2_uk)
end
@assert 1 / (20 * sqrt(2)) < 0.04 "Rellich：H¹ 有界 ⟹ L² 预紧"
l2_vk = 1 / sqrt(2)
@printf("    v_k = sin(kπx): ||v_k||_2 = %.4f (const), ||v_k'||_2 = %.4f*k -> inf: NOT compact\n",
        l2_vk, pi / sqrt(2))

# ---- (b) Poincaré 常数：λ₁ = π²（(0,1) Dirichlet），数值最优 ----
# ‖u‖² ≤ ‖u'‖²/λ₁，第一模式饱和。谱数值（差分特征值 → π²）
for N in [40, 80, 160]
    h = 1 / (N + 1)
    # 三对角 (2,-1)/h² 的最小特征值（对称格点幂法/解析：2(1-cos(πh))/h²）
    lam_disc = 2 * (1 - cos(pi * h)) / h^2
    @printf("(b) N=%3d: discrete lam1 = %.6f  -> pi² = %.6f\n", N, lam_disc, pi^2)
    if N == 160
        @assert abs(lam_disc - pi^2) < 5e-3 "差分谱收敛到 π²"
    end
end

# ---- (c) 差商：‖D^h u‖_{L^p} ≤ C（一致 h）⟺ u ∈ W^{1,p}（书 §5.8.2）----
# u = |x|^{3/4} ∈ W^{1,2}：差商一致有界；u = |x|^{1/4} ∉ W^{1,2}：差商爆炸
u_wp(x) = abs(x)^(3 / 4)
u_np(x) = abs(x)^(1 / 4)
function dq_norm(u; h = 0.01, L = 1.0)
    # ‖(u(x+h)-u(x))/h‖_{L²(-L,L)}（减去均值近似处理平移；简化内部区间）
    n = 4000
    a, b = -L + h, L - h
    hh = (b - a) / n
    s = 0.0
    for k in 0:n
        x = a + k * hh
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        d = (u(x + h) - u(x)) / h
        s += w * d^2
    end
    return sqrt(s * hh / 3)
end
d_wp = dq_norm(u_wp)
d_np = dq_norm(u_np, h = 0.001)
@printf("(c) difference quotients: ||D^h |x|^{3/4}||_2 = %.4f (bounded), ", d_wp)
@printf("||D^h |x|^{1/4}||_2(h=1e-3) = %.2f (blows as h->0)\n", d_np)
@assert d_wp < 10.0 "W^{1,2} 函数差商一致有界"
@assert d_np > d_wp * 2 "非 W^{1,2} 函数差商随 h 爆"

# ---- (d) Hardy 不等式一瞥（§5.8.4）：∫u²/x² ≤ 4∫|u'|²（u(0)=0）----
u_h(x) = x * exp(-x)   # u(0) = 0
function hardy_ratio(u)
    n = 20000
    h = 8.0 / n
    num = 0.0
    den = 0.0
    for k in 1:n
        x = k * h
        ux = (u(x + h / 2) - u(x - h / 2)) / h
        num += u(x)^2 / x^2 * h
        den += ux^2 * h
    end
    return num / den
end
r = hardy_ratio(u_h)
@printf("(d) Hardy: ∫u²/x² / ∫|u'|² = %.6f <= 4\n", r)
@assert r < 4.0 "Hardy 常数 4"

println("END ====")
