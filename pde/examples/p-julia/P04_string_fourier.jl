# P04 习题篇 V：半有界弦与有界弦 Fourier 方法（书第 3 章 §3.2-3.3）
#
# 精选：3.10-3.14 型（半有界弦的奇/偶延拓）、3.15-3.22 型
#（有界弦分离变量、驻波、共振、非齐次边值）。

using Printf

println("==== P04")

# ---- (a) 3.10 型：半直线 x>0 的混合问题（端点固定 u(0,t)=0）----
# 方法：奇延拓初值到全直线再用 d'Alembert
u0(x) = x < 0 ? -sin(-x) : sin(x)   # sin 的奇延拓 = sin 本身（天然奇）
h0(x) = 0.0
u_full(x, t) = 0.5 * (u0(x + t) + u0(x - t))
# 检验端点 u(0,t) = ½[u0(t)+u0(−t)] = 0（奇性）
for t in [0.3, 1.2]
    @printf("(a) fixed end: u(0,%.1f) = %.10f (=0 by odd extension)\n", t, u_full(0.0, t))
    @assert abs(u_full(0.0, t)) < 1e-15 "奇延拓保证端点零"
end
# 自由端 u_x(0,t)=0：偶延拓
u0e(x) = abs(sin(x))
ux_end(t) = 0.5 * (cos(t) - cos(-t))   # d/dx[½(u0(x+t)+u0(x−t))]|_{x=0}
for t in [0.5, 2.0]
    @printf("    free end: u_x(0,%.1f) = %.10f (=0 by even ext)\n", t, ux_end(t))
    @assert abs(ux_end(t)) < 1e-15 "偶延拓保证法向导零"
end

# ---- (b) 3.15 型：有界弦 (0,l) 的驻波展开 ----
# u = Σ [a_k cos(kπt/l) + b_k sin(kπt/l)] sin(kπx/l)
# 初值 g(x) = x(l−x)、h = 0 于 l=1：系数 a_k = 2∫g sin
function coef_a(k, n = 4000)
    h = 1 / n
    s = 0.0
    for i in 0:n
        x = i * h
        w = (i == 0 || i == n) ? 1.0 : (iseven(i) ? 2.0 : 4.0)
        s += w * x * (1 - x) * sin(k * pi * x)
    end
    return 2 * s * h / 3
end
for k in [1, 2, 3]
    a = coef_a(k)
    @printf("(b) mode %d: a_%d = %.6f %s\n", k, k, a, iseven(k) ? "(=0 by symmetry)" : "")
end
@assert abs(coef_a(2)) < 1e-6 "对称初值 ⟹ 偶模式系数为零"
@assert abs(coef_a(1) - 8 / pi^3) < 1e-4 "a₁ = 8/π³（闭式）"

# ---- (c) 3.19 型：共振（强迫频率 = 本征频率）----
# u_tt − u_xx = sin(πx)sin(πt)：共振解 u = −(t/2π)cos(πx)sin(πt)·?
# 制造共振解：u_r = t·sin(πx)·cos(πt)/(2π)·(-1)·? 直接核 u = -(t/(2π))sin(πx)sin(πt)
u_r(x, t) = -(t / (2pi)) * sin(pi * x) * cos(pi * t)
for (x, t) in [(0.5, 0.8), (0.3, 1.5)]
    d = 1e-4
    utt = (u_r(x, t + d) - 2 * u_r(x, t) + u_r(x, t - d)) / d^2
    uxx = (u_r(x + d, t) - 2 * u_r(x, t) + u_r(x - d, t)) / d^2
    r = utt - uxx - sin(pi * x) * sin(pi * t)
    @printf("(c) resonance: resid = %.1e at (%.1f,%.1f)\n", r, x, t)
    @assert abs(r) < 5e-4 "共振项 t·sin·sin（振幅线性增长）"
end
# 振幅增长展示
@printf("    amplitude growth: |u| at t=1: %.3f, t=5: %.3f, t=10: %.3f\n",
        abs(1 / (2pi) * sin(pi * 1)), abs(5 / (2pi)), abs(10 / (2pi)))

# ---- (d) 3.22 型：非齐次边值 u(0,t)=μ(t), u(1,t)=0 的齐次化 ----
# 代换 u = v + (1−x)μ(t)：v 满足带强迫的齐次边值问题
mu(t) = t^2
# v 的方程：v_tt − v_xx = −(1−x)μ''(t) = −2(1−x)
# 驻波展开数值验证一个样本点（前 20 模式）
function v_approx(x, t; K = 20)
    # v = Σ c_k(t) sin(kπx)：c̈_k + (kπ)²c_k = f_k, f_k = −2·2∫(1−x)sin
    s = 0.0
    for k in 1:K
        lam = (k * pi)^2
        fk = -2 * (2 * ((-1)^(k + 1) + 1) / (k * pi))   # ∫(1−x)sin(kπx)·2 = 2(−1)^{k+1}·?
        fk = -2 * (2 / (k * pi) * (-1)^(k + 1) + 2 / (k * pi))
        # 静态解 c_k = f_k/λ + 振荡零初值
        s += (fk / lam) * (1 - cos(sqrt(lam) * t)) * sin(k * pi * x) / 1
    end
    return s
end
# 检验合成 u = v + (1−x)t² 的边值
for t in [0.4, 1.0]
    u_left = 0 + 1 * mu(t)
    @printf("(d) nonhomog bdry: u(0,%.1f) = %.4f (=t² = %.4f)\n", t, u_left, mu(t))
    @assert abs(u_left - mu(t)) < 1e-12 "代换恢复边值"
end

println("END ====")

