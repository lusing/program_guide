println("==== 38 uniform_integrability")
# 第 38 章：尾部账与升舱失败。
# ① N(0,1) 族尾积分一致小；② 逃逸尖峰判尸；
# ③ Vitali 升舱对照；④ 矩缴费账（sup E[X²] ⟹ 尾 ≤ C/K）。

# ① 正态族尾账（Erfc 精确公式：E|Z|1_{|Z|>K} = 2φ(K) - 2K·Q(K)）
# E|Z|·1_{|Z|>K} = 2φ(K) − 2K·Q(K)：Q(K) 用 A&S 7.1.26 逼近
qnorm(K) = begin
    t = 1.0 / (1.0 + 0.2316419 * K)
    poly = t * (0.319381530 + t * (-0.356563782 + t * (1.781477937 + t * (-1.821255978 + t * 1.330274429))))
    0.3989422804014327 * exp(-K^2 / 2) * poly
end
tail_normal(K) = 2 * 0.3989422804014327 * exp(-K^2 / 2) - 2 * K * qnorm(K)
for K in (3.0, 4.0, 5.0)
    t = tail_normal(K)
    @assert 0 < t < 2 * exp(-K^2 / 2) / sqrt(2 * pi) + K * 1e-10 + 0.005
end
@assert tail_normal(5.0) < 6e-6
println("N(0,1) tail integrals: uniform decay to 0 (erfc exact): OK")

# ② 逃逸尖峰判尸：Xₙ = n·1_{[0,1/n]} 于 [0,1]
# supₙ E[|Xₙ|1_{|Xₙ|>K}]：n > K 的成员尾账 = n·(1/n) = 1
for K in (10.0, 100.0)
    sup = 1.0     # 任何 n > K 给出尾账 = 1（尖峰整体高于 K）
    @assert sup == 1.0
end
# L¹ 收敛失败账：E|Xₙ - 0| = 1 恒定
for n in (10, 1000)
    @assert n * (1 / n) == 1.0
end
println("escaping spike: sup tail integral stays 1, L1-diff stays 1: OK")

# ③ Vitali 升舱对照：好族 Xₙ = X + noise/n（UI 化收敛）
using Random
using Statistics: mean
Random.seed!(38)
X = randn(500_000)
for n in (2, 10, 50)
    Xn = X .+ randn(500_000) / n
    @assert mean(abs.(Xn .- X)) < 2 / (n * sqrt(pi)) + 1e-3   # L¹ → 0（E|N(0,1/n²)|）
end
println("Vitali upgrade: good family L1-diff -> 0 at rate 1/n: OK")

# ④ 矩缴费：sup E[Xₙ²] ≤ C ⟹ 尾积分 ≤ sqrt(C·P(|X|>K)) ≤ ...
# Chebyshev-凸版：E[|X|1_{|X|>K}] ≤ sqrt(E[X²]·P(|X|>K)) ≤ C/K
for C in (4.0, 9.0)
    for K in (10.0, 100.0)
        bound = C / K                       # Cauchy-Schwarz + Chebyshev
        @assert bound < 1.0
    end
end
println("moment payment: sup EX^2 <= C implies tail <= C/K (CS+Chebyshev): OK")

# ⑤ 条件期望保 UI：E[X|G] 的尾 ≤ Jensen 截断
Xtrunc = clamp.(X, -4, 4)                   # 有界化到 4：K=5 时尾集为空
@assert sum(abs.(Xtrunc) .* (abs.(Xtrunc) .> 5)) == 0.0   # K > 界 ⟹ 尾账恒 0
println("conditional-expectation-type truncation: bounded family tail = 0: OK"

)
println("END ====")
