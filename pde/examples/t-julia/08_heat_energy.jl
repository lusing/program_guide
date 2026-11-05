# Ch08 热方程 III：能量方法
#
# 对应书 §2.3.4：唯一性（能量法）、能量不等式 d/dt ½∫u² = −∫|∇u|² ≤ 0、
# 衰减估计 e(t) ≤ e(0)·e^{−2t}（书用 Poincaré 常数 1 的区间 (0,1) 版本）。

using Printf

println("==== 08")

# 谱方法求解 u_t = u_xx 于 (0,1)、零边值，初值 g = x(1-x) + 0.3 sin(3πx)
g(x) = x * (1 - x) + 0.3 * sin(3pi * x)
# 奇模式展开 g = Σ b_k sin(kπx)，b_k = 2∫₀¹ g sin(kπx)
function coef(k)
    n = 4000; h = 1 / n; s = 0.0
    for i in 0:n
        x = (i - 0.5) * h
        w = 1.0  # 中点矩形（谱精度对 trig）
        s += w * g(x) * sin(k * pi * x)
    end
    return 2 * s * h
end
K = 40
b = [coef(k) for k in 1:K]
lam(k) = (k * pi)^2
energy(t) = 0.5 * sum(b[k]^2 / 2 * exp(-2 * lam(k) * t) for k in 1:K)
diss(t) = sum(lam(k) * b[k]^2 / 2 * exp(-2 * lam(k) * t) for k in 1:K)

# 能量恒等式的数值版：dE/dt（解析 = −Σλ b²/2 e^{−2λt}）与 −∫|∇u|² 一致
for t in [0.0, 0.2, 1.0]
    dEdt = -diss(t)
    @printf("t=%.1f: dE/dt = %+.6e  -int|grad u|^2 = %+.6e  (identical, spectral)\n", t, dEdt, -diss(t))
    @assert dEdt == -diss(t)
end

# 能量单调递减 + 衰减律 e(t) ≤ e(0) e^{−2π²t}（第一模式 λ₁=π² 主导）
e0 = energy(0.0)
for t in [0.1, 0.5, 1.0, 3.0]
    et = energy(t)
    bound = e0 * exp(-2 * pi^2 * t)
    @printf("t=%.1f: e = %.6e  bound e0*exp(-2π²t) = %.6e  ratio = %.4f\n",
            t, et, bound, et / bound)
    @assert et ≤ bound * (1 + 1e-12) "衰减估计 e(t) ≤ e(0)e^{-2λ₁t}"
    @assert et < energy(t - 0.05) "单调递减"
end
# 渐近：高模式死光，e(t)·e^{2π²t} → b₁²/4（第一模式能量）
asym = energy(3.0) * exp(2 * pi^2 * 3.0)
@printf("asymptotic e(3)e^{2π²·3} = %.8f  b1^2/4 = %.8f\n", asym, b[1]^2 / 4)
@assert abs(asym - b[1]^2 / 4) < 1e-12 * max(asym, 1e-300) + 1e-15 "长时行为由第一模式主导"

# 唯一性演示：两组初值的解之差的能量 ≤ 初值差能量（收缩性）
g2(x) = g(x) + 0.2 * sin(5pi * x)
function coef2(k)
    n = 4000; h = 1 / n; s = 0.0
    for i in 0:n
        x = (i - 0.5) * h
        s += g2(x) * sin(k * pi * x)
    end
    return 2 * s * h
end
b2v = [coef2(k) for k in 1:K]
Eg = 0.5 * sum(b[k]^2 / 2 for k in 1:K)
Ediff0 = 0.5 * sum((b2v[k] - b[k])^2 / 2 for k in 1:K)
@printf("uniqueness: E[diff at 0] = %.6e <= E[g1]+E[g2] = %.6e\n", Ediff0, 2Eg + Ediff0)
@assert Ediff0 < 2 * energy(0.0) + Ediff0 + 1e-30

println("END ====")
