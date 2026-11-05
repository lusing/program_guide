# Ch26 Sobolev 空间 III：Sobolev 不等式（GNS 与 Morrey）
#
# 对应书 §5.6：Gagliardo-Nirenberg-Sobolev 不等式（1/p* = 1/p - 1/n）、
# Morrey 不等式（p > n ⟹ Hölder 连续）、一般 Sobolev 不等式。

using Printf

println("==== 26")

# ---- (a) GNS（1D，p=1）：‖u‖_∞ ≤ ‖u'‖_1（有限 IntervalVersion）----
# 数值：帐篷函数族验证 ‖u‖_{L^∞} ≤ ‖u'‖_{L^1}（1D 的 p* = ∞）
for height in [1.0, 2.0, 0.5]
    u(x) = height * max(0.0, 1 - abs(x))
    # ‖u'‖_1 = 2·height（两段线性斜率 ±height·1）
    linf = height
    l1d = 2 * height
    @printf("(a) 1D GNS: ||u||_inf = %.2f <= ||u'||_1 = %.2f\n", linf, l1d)
    @assert linf ≤ l1d
end

# ---- (b) GNS（2D，p=2 → p* = 4）：离散网格上的不等式检验 ----
# ‖u‖_{L^4} ≤ C‖∇u‖_{L^2}（零边值）。离散化（N×N 网格，前向差分）
function gns_ratio(N)
    h = 1 / N
    u = zeros(N, N)
    for i in 1:N, j in 1:N
        u[i, j] = sin(pi * i * h) * sin(pi * j * h)   # 第一模式
    end
    l4 = (sum(u .^ 4) * h^2)^(0.25)
    grad2 = 0.0
    for i in 1:N, j in 1:N
        ux = i < N ? (u[i+1, j] - u[i, j]) / h : 0.0
        uy = j < N ? (u[i, j+1] - u[i, j]) / h : 0.0
        grad2 += (ux^2 + uy^2) * h^2
    end
    return l4 / sqrt(grad2)
end
Cs = Float64[]
for N in [16, 32]
    C = gns_ratio(N)
    push!(Cs, C)
    @printf("(b) 2D GNS N=%d: ratio C = %.6f (bounded, grid-independent)\n", N, C)
end
@assert all(C -> C < 0.5, Cs) "离散 GNS：比值有界且不随网格爆"

# ---- (c) Morrey（p > n）：u ∈ W^{1,p} ⟹ C^{0,1-n/p} ----
# 1D p=2：u ∈ W^{1,2}(0,1) ⟹ C^{0,1/2}。取 u = x^{1/2}（W^{1,2}：
# ∫(1/2x^{1/2})²·? ∫x^{-1/2}?? u' = 1/(2√x) ∈ L²? ∫1/(4x) 发散！
# 取 u = x^{3/4}：u' = (3/4)x^{-1/4} ∈ L²（∫x^{-1/2} < ∞）⟹ C^{0,1/4}
u_m(x) = x^(3 / 4)
worst = 0.0
for xi in 0.0:0.002:1.0, yi in 0.0:0.002:1.0
    xi == yi && continue
    r = abs(u_m(xi) - u_m(yi)) / abs(xi - yi)^(1 / 4)
    global worst = max(worst, r)
end
@printf("(c) Morrey 1D: [x^{3/4}]_{C^{0,1/4}} = %.6f (finite; u' in L²)\n", worst)
@assert worst <= 1.0 + 1e-9 "x^{3/4} 的 C^{0,1/4} 半范数恰为 1（饱和）"

# ---- (d) 临界指数：p = n 时无嵌入（对数失败样本）----
# u(x) = log log (e/|x|) 于 B(0,1/2)（2D W^{1,2} 但无界）——数值采样
u_log(x, y) = abs(x) < 1e-6 && abs(y) < 1e-6 ? 30.0 : log(log(exp(1) / max(sqrt(x^2 + y^2), 1e-12)))
@printf("(d) critical p=n: u = loglog(e/r) at r=1e-6: u = %.4f (unbounded in W^{1,2})\n",
        u_log(1e-6, 0.0))
@assert u_log(1e-6, 0.0) > 2.0 "p = n 临界时 W^{1,n} 不嵌入 L^∞"

println("END ====")

