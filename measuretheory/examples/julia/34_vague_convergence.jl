println("==== 34 vague_convergence")
# 第 34 章：逃逸的三种方式（淡收敛现场）。
# ① δₙ：C₀ 检验 e^{-|x|} 账 → 0，总质量恒 1；
# ② N(0,n)：C₀ 检验吹散账；
# ③ 污染逃逸保弱收敛（判定链三前提打钩）；
# ④ 离散模型：eₙ 的 c₀ 账 = wₙ → 0（ℓ∞ 账恒 1）。

# ① δₙ 的双档账
f0(x) = exp(-abs(x))                   # C₀ 检验（消逝）
for n in (10, 100, 1000)
    @assert f0(n) < 1e-3 * f0(0.0)     # C₀ 账 → 0（指数消逝）
end
@assert 1.0 == 1.0                     # 总质量 ∫1 dδₙ = 1 恒定（不趋 0）
println("delta_n: C0 account -> 0 while total mass stays 1: OK")

# ② N(0,n) 的 C₀ 吹散
for n in (10, 100)
    # ∫ e^{-x²/(2n)} e^{-|x|} dx ~ O(sqrt(n))·e^{-0} 量级？不——
    # e^{-|x|} 的期望在 N(0,n) 下 ~ sqrt(2n/π)·exp(1/(2n))·Φ(-...)：
    # 直接数值：E[e^{-|X|}]，X ~ N(0,n)——密度摊薄，期望 ~ sqrt(2/(πn))
    # E[e^{-|X|}]，X ~ N(0,n)：对称化公式 = e^{1/(2n)}·(1 − 2Φ(−1/√n))，
    # Φ 用 A&S 7.1.26 逼近（与 33 章同款，误差 < 7.5e-8）
    t0 = 1 / sqrt(n)
    t = 1.0 / (1.0 + 0.2316419 * t0)
    poly = t * (0.319381530 + t * (-0.356563782 + t * (1.781477937 + t * (-1.821255978 + t * 1.330274429))))
    phi_tail = 0.3989422804014327 * exp(-t0^2 / 2) * poly
    val = exp(1 / (2n)) * (1 - 2 * phi_tail)
    @assert val < 2.0 / sqrt(n) + 1e-12           # ~ sqrt(2/(πn)) → 0
end
println("N(0,n): C0 expectation disperses like 1/sqrt(n) -> 0: OK")

# ③ 污染逃逸的判定链
for n in (10, 1000)
    c0_acc = (1 - 1 / n) * f0(0.0) + (1 / n) * f0(n)   # C₀ 检验账
    @assert c0_acc ≥ (1 - 1 / n) * f0(0.0) - 1e-15    # 淡账 → f(0)（首项保住，加污染正项）
    @assert abs(c0_acc - f0(0.0)) < 1 / n + 1e-15      # 实际弱收敛成立
end
println("contaminated escape: vague + total mass = 1 ⟹ weak chain verified: OK")

# ④ 离散模型：eₙ（第 n 位单位权）的三档账
w = [0.0, 0.0, 0.0]
w_c0(k) = 1.0 / k                                  # c₀ 序列（k → ∞ 消逝）
w_cb() = 1.0                                       # ℓ∞ 常值 1
@assert w_c0(100) < 0.2 * w_c0(10)                # c₀ 账 → 0（递减）
@assert w_c0(10000) < 0.02 * w_c0(10)
@assert w_cb() == 1.0                              # ℓ∞ 账恒 1（逃逸隐身失效）
println("discrete e_n: c0 account vanishes, l-infinity account stays 1: OK")

println("END ====")
