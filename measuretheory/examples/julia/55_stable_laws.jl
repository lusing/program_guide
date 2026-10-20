# -*- coding: utf-8 -*-
println("==== 55 stable_laws")
# 第 55 章 Julia：稳定分布的标度不变性实验。
# ① Cauchy 的 Sₙ/n ≡ Cauchy（α=1 不变性）；② α=1.5 对称稳定的
#    CMS 采样与 Sₙ/n^{1/α} 稳定性；③ 广义 CLT 的 aₙ 刻度显影；
# ④ 矩边界：稳定 α<2 ⟹ EX² = ∞ 的采样账。
using Random, Statistics

Random.seed!(55)

# ① Cauchy 稳定性：Sₙ/n 的四分位距 vs 母体（分布不变）
cauchy_sample() = tan(pi * (rand() - 0.5))
# 正态的截尾二阶矩理论账用 erf：E[Z²;|Z|≤m] = 2Φ(m) − 1 − 2mφ(m)…
# 简化：直接用样本对照均值 ~（数值上 E[Z²] = 1 主导，截尾修正小）——
# 见下方 g 断言的精确式（phi_0 为标准正态 CDF）
phi_0(x) = 0.5 * (1 + erf(x / sqrt(2.0)))
function stable_iqr(sampler, n, norm; paths = 8000)
    s = Float64[]
    for _ in 1:paths
        acc = 0.0
        for _ in 1:n
            acc += sampler()
        end
        push!(s, acc / norm(n))
    end
    quantile(s, 0.75) - quantile(s, 0.25)
end
# Cauchy 的 IQR（理论）：2·tan(π/4) = 2
iqr1 = stable_iqr(cauchy_sample, 5, n -> n)
iqr2 = stable_iqr(cauchy_sample, 80, n -> n)
@assert abs(iqr1 - 2) < 0.3
@assert abs(iqr2 - 2) < 0.3                # n 变 16 倍，IQR 不动——α=1
println("Cauchy (alpha=1): IQR of S_n/n stays ", round(iqr1, digits=2),
        " -> ", round(iqr2, digits=2), " (theory 2): OK")

# ② α=1.5 对称稳定：LePage 级数表示（X = Σ±Γₖ^{-1/α}，Γₖ 泊松
#    到达时序——数学上严格的构造；CMS 公式的手写回忆版实测产出
#    高斯行为（P{|X|>100}=0 且 √n 稳定），弃用）
function stable_sample(alpha; K = 2000)
    s = 0.0
    gamma = 0.0                            # Γₖ = E₁+⋯+Eₖ
    for _ in 1:K
        gamma += -log(1.0 - rand())        # Exp(1) 逆变换
        s += (rand() < 0.5 ? 1.0 : -1.0) * gamma^(-1.0 / alpha)
    end
    s
end
# 归一化核验：Sₙ/n^{1/α} 的 IQR 稳定（vs Sₙ/√n 的 IQR 消失）
alpha = 1.5
j1 = stable_iqr(() -> stable_sample(alpha), 5, n -> n^(1 / alpha))
j2 = stable_iqr(() -> stable_sample(alpha), 80, n -> n^(1 / alpha))
@assert abs(j1 - j2) < 0.25 * j1           # n^{1/α} 归一化下 IQR 稳定
k1 = stable_iqr(() -> stable_sample(alpha), 5, n -> sqrt(n))
k2 = stable_iqr(() -> stable_sample(alpha), 80, n -> sqrt(n))
@assert k2 > 1.4 * k1                      # √n 是不足归一化（α<2 ⟹
#   n^{1/α} > √n）——分布发散，IQR 膨胀
println("alpha=1.5 stable (LePage): IQR under n^(1/a): ", round(j1, digits=2),
        " -> ", round(j2, digits=2), " (stable); under sqrt(n): ",
        round(k1, digits=2), " -> ", round(k2, digits=2), " (inflates): OK")

# ③ 广义 CLT 的 aₙ 刻度：Pareto(1, 1.5)（尾 x^{-1.5}）母体
#    n·P{X>aₙ} → c ⟹ aₙ ~ n^{1/1.5} = n^{2/3}
function pareto_sample(alpha)
    (1.0 - rand())^(-1.0 / alpha)          # 逆变换：P{X>x} = x^{-α}
end
m1 = stable_iqr(() -> pareto_sample(1.5), 20, n -> n^(1 / 1.5))
m2 = stable_iqr(() -> pareto_sample(1.5), 80, n -> n^(1 / 1.5))
m3 = stable_iqr(() -> pareto_sample(1.5), 300, n -> n^(1 / 1.5))
@assert m1 < m2 < m3                       # 从下逼近稳定 IQR（小样本偏小）
@assert m3 / m2 < 1.2                      # 增长饱和（n^{2/3} 刻度正确；
#   若刻度不足如 √n，比值会 ~ (300/80)^{2/3-1/2} = 1.31 且持续膨胀）
println("generalized CLT scale: Pareto(1.5) sums under n^(2/3): ",
        round(m1, digits=2), " -> ", round(m2, digits=2), " -> ",
        round(m3, digits=2), " (saturating): OK")

# ④ 矩边界：EX² = ∞ 的采样账——**截尾二阶矩的精确理论值对拍**
#    Cauchy：E[X²; |X|≤m] = (2/π)(m − arctan m) ~ 2m/π（线性增长——
#    二阶矩发散的定量形态）；无截尾的样本二阶矩由单个大跳主导
#    （无规震荡），只断言与正态的量级分离
function truncated_second_moment(sampler, m; n = 200_000)
    s = 0.0
    for _ in 1:n
        x = sampler()
        abs(x) <= m && (s += x * x)
    end
    s / n
end
m = 50.0
c_trunc = truncated_second_moment(cauchy_sample, m)
c_theory = 2 / pi * (m - atan(m))
@assert abs(c_trunc - c_theory) < 0.1 * c_theory     # ≈ 31.4（2m/π）
m2v = 200.0
c_trunc2 = truncated_second_moment(cauchy_sample, m2v)
c_theory2 = 2 / pi * (m2v - atan(m2v))
@assert abs(c_trunc2 - c_theory2) < 0.1 * c_theory2
@assert c_trunc2 > 3.5 * c_trunc             # 截尾水平×4 ⟹ 矩×~4.1（线性增长）
g = truncated_second_moment(randn, m)
@assert abs(g - 1.0) < 0.03                   # 正态：E[Z²;|Z|≤50] = 1−O(1e-500)
println("moment boundary: Cauchy trunc-2nd-moment m=50: ", round(c_trunc, digits=1),
        " (th ", round(c_theory, digits=1), "), m=200: ", round(c_trunc2, digits=1),
        " (th ", round(c_theory2, digits=1), ") — linear growth: OK")

println("END ====")
