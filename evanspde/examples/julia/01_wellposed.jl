# Ch01 适定性：Hadamard 三实验
#
# 对应书 §1.3（研究策略背后的适定性问题）与 §1.5 习题引出的
# Hadamard 反例。适定性 = 存在 + 唯一 + 对数据连续依赖。
# 三个数值实验：
#   (a) 正向热方程：扰动被压缩（连续依赖成立）；
#   (b) 逆时热方程：扰动按 e^{k^2 |t|} 放大（不适定）；
#   (c) Laplace Cauchy 问题：边值 → 0 而解 → ∞（Hadamard 原反例，
#       其"调和"一半在 Lean Ch01 有完整证明）。

using Printf

println("==== 01")

# ---- (a) 正向热方程：模式 e^{-k^2 t} 衰减 ----
println("(a) forward heat: perturbation e_k(x)=sin(k x) evolves as exp(-k^2 t)")
for k in [2, 4, 8]
    amp = exp(-k^2 * 0.5)
    @printf("    k=%d: |data|=1e-3 -> |u(.,0.5)| = %.2e\n", k, 1e-3 * amp)
end
@assert exp(-8^2 * 0.5) * 1e-3 < 1e-16 "高频扰动被压到机器零以下：连续依赖成立"

# ---- (b) 逆时热方程：从 t=T 反推 t=0，模式放大 e^{k^2 T} ----
println("(b) backward heat: reconstruct u(.,0) from u(.,T) amplifies by exp(k^2 T)")
for k in [10, 20]
    growth = exp(k^2 * 0.1)
    @printf("    k=%d: growth exp(%d^2*0.1) = %.2e -> data 1e-12 becomes %.2e\n",
            k, k, growth, growth * 1e-12)
end
@assert exp(20^2 * 0.1) * 1e-12 > 1e3 "双精度下限级的小数据反推出 O(1) 量级的解：不适定"

# ---- (c) Hadamard 反例：u_n(x,y) = sin(nx) sinh(ny)/n^2 ----
println("(c) Hadamard example: u_n = sin(nx) sinh(ny)/n^2 harmonic,")
println("    boundary data on y=0 is 0 (and d_y data sin(nx)/n -> 0), yet u_n explodes:")
prev = 0.0
mono_ok = true
for n in 1:5:21
    bnd = 0.0                                   # u_n(x, 0) = sin(nx)*0 = 0
    dyb = 1.0 / n                               # |d_y u_n(x,0)| = sin(nx)/n <= 1/n -> 0
    inner = sinh(n * 1.0) / n^2                 # u_n(pi/2, 1) = sinh(n)/n^2
    @printf("    n=%2d: sup|u_n(.,0)|=%.1e  sup|dy u_n(.,0)|=%.2e  u_n(pi/2,1)=%.3e\n",
            n, bnd, dyb, inner)
    global mono_ok = mono_ok && (n == 1 || inner > prev)
    global prev = inner
end
@assert mono_ok "内部值随 n 单调爆炸"
@assert sinh(21.0) / 21^2 > 1e6 "n=21 时内部值已超 1e6，而边值趋于 0：无连续依赖"

# ---- 对账：反例的增长率公式 sinh(n)/n^2 ~ e^n/(2n^2) ----
n = 20.0
ratio = (sinh(n) / n^2) / (exp(n) / (2 * n^2))
@printf("    growth law: sinh(n)/n^2 vs e^n/(2n^2), n=20 ratio = %.6f (->1)\n", ratio)
@assert abs(ratio - 1) < 1e-15 "渐近公式逐位对账"

println("END ====")
