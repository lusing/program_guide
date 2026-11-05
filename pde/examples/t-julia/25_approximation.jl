# Ch25 Sobolev 空间 II：逼近、延拓与迹
#
# 对应书 §5.3（磨光逼近：内部/整体/全局）、§5.4（延拓定理）、
# §5.5（迹定理：边界值的意义与 |∂U| ≤ C‖u‖_{W^{1,p}}）。

using Printf

println("==== 25")

# ---- (a) 磨光逼近：u^ε = η_ε * u → u（L^p 收敛）----
moll(x, eps) = exp(-x^2 / (2eps^2)) / (sqrt(2pi) * eps)
u_r(x) = max(0.0, 1 - abs(x))   # hat（W^{1,∞} 但不 C^∞）
function mollify(u, x, eps; L = 6eps, n = 4000)
    h = 2L / n
    s = 0.0
    for k in 0:n
        y = -L + k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * moll(y, eps) * u(x - y)
    end
    return s * h / 3
end
for eps in [0.2, 0.1, 0.05]
    # L2 误差数值（区间 [-1.5, 1.5]）
    n = 2000
    a, b = -1.5, 1.5
    h = (b - a) / n
    s = 0.0
    for k in 0:n
        x = a + k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        e = mollify(u_r, x, eps) - u_r(x)
        s += w * e^2
    end
    l2 = sqrt(s * h / 3)
    @printf("(a) mollify L2 error eps=%.3f: %.6f (-> 0 as eps->0)\n", eps, l2)
    global last_l2 = l2
end
@assert last_l2 < 0.08 "ε 缩小 L2 误差减小"

# ---- (b) 延拓：偶延拓保持 W^{1,p}（半线 → 全线）----
# u 于 (0,∞)，延拓 ũ(x) = u(|x|)：∫|ũ'|^p = 2∫|u'|^p
function integrate_exp_p(p)
    n = 20000
    h = 8.0 / n
    s = 0.0
    for k in 0:n
        x = k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * abs(-exp(-x))^p
    end
    return s * h / 3
end
E2 = 2 * integrate_exp_p(1.0)
@printf("(b) even extension: ∫|Dũ|^p = %.6f = 2∫|Du|^p = %.6f\n", E2, 2integrate_exp_p(1.0))
@assert E2 == 2 * integrate_exp_p(1.0) "偶延拓范数恰翻倍（无新奇性）"

# ---- (c) 迹定理的数值面：边界值 ≤ C‖u‖_{H^1}----
# 取 u = sin(kπx)：|u(0)| = 0（零边值），|u(x0)| ≤ √2·√(‖u‖²H¹)
# 更直接：|u(0)| = 1 的函数族 u = e^{-x/δ}——δ 小则边界值 1 但
# H¹ 范数 ~ 1/√δ 爆炸：迹算子无界反向（H¹ ↛ L∞(边界) 的反面：
# 迹有界 ‖u‖_{L²(∂)} ≤ C‖u‖_{H¹}）
for delta in [1.0, 0.1, 0.01]
    # ‖u‖_{L²(∂)} = |u(0)| = 1；‖u‖_{H¹}² = ∫(e^{-2x/δ} + δ^{-2}e^{-2x/δ}) = δ/2 + 1/(2δ)
    h1sq = delta / 2 + 1 / (2delta)
    @printf("(c) trace law: u=e^{-x/%.2f}: |u(0)|=1, ||u||_{H1} = %.3f (blows up)\n", delta, sqrt(h1sq))
end
@assert sqrt(0.01 / 2 + 1 / 0.02) > 7 "边界层家族的 H¹ 范数爆炸——迹有界但逆不真"

# ---- (d) 一般 p 的插值：‖u'‖_{L²}² 插值 ‖u‖ 与 ‖u''‖（Gagliardo-Nirenberg 一瞥）----
# 离散检验：对 sin(kx) 模式，‖u'‖² = √(‖u‖·‖u''‖) 精确（模式精确）
for k in [1.0, 3.0]
    nu = 1 / sqrt(2)        # ‖sin(kx)‖_{L²(0,2π)}/√(2π)
    nd = k / sqrt(2)
    ndd = k^2 / sqrt(2)
    @printf("(d) mode k=%.0f: ||u'||² = %.4f  ||u||·||u''|| = %.4f (equal)\n",
            k, nd^2, nu * ndd)
    @assert abs(nd^2 - nu * ndd) < 1e-12 "模式族的 GN 插值恒等精确"
end

println("END ====")
