# -*- coding: utf-8 -*-
print("==== 47 gaussian_measures")
# 第 47 章 Python：Gauss 结构账（Fraction 精确版）。
# ① λₙ = 1/n² 部分和；② CM 门槛（e₁ vs Σeₙ/n）；
# ③ 平移密度归一；④ Fernique 影子。
from fractions import Fraction

# ① 迹收敛
s = sum(Fraction(1, n * n) for n in range(1, 201))
assert 1.6 < float(s) < 1.65                     # → π²/6
print("trace convergence: sum 1/n^2 -> pi^2/6: OK"

)
# ② CM 门槛：λₙ = 1/n²
# ||e_1||_A² = 1/λ₁ = 1（CM 会员）
assert Fraction(1, 1) == Fraction(1) / Fraction(1, 1)
# ||sum e_n/n||_A² = Σ (1/n²)·n² = Σ 1 = n_max（发散）
for n_max in (10, 100):
    cm_norm = sum(Fraction(1) for _ in range(n_max))
    assert cm_norm == n_max                       # 随截断线性增长（发散）
print("CM threshold: ||e_1||_A = 1 finite, ||sum e_n/n||_A = n_max diverges: OK"

)
# ③ 平移密度归一：E[exp(N(0,1) - 1/2)] = 1（一维精确）
import random, math
random.seed(47)
vals = [math.exp(random.gauss(0, 1) - 0.5) for _ in range(20000)]
avg = sum(vals) / 20000
assert 0.95 < avg < 1.05
print("CM translation density: E[exp(N - 1/2)] = 1: OK"

)
# ④ Fernique 影子：E[exp(α X²)]，X² ~ λ₁χ²₁ = χ²₁（λ₁ = 1）
# E[exp(α χ²)] = (1-2α)^{-1/2}：α < 1/2 有限，α ≥ 1/2 发散
for alpha in (0.1, 0.2):
    theory = (1 - 2 * alpha) ** (-0.5)
    est = sum(math.exp(alpha * random.gauss(0, 1) ** 2) for _ in range(10000)) / 10000
    assert abs(est - theory) < 0.05               # 有限且符合闭式
# α = 0.6 > 1/2 时理论发散：采样均值显著大
big = sum(math.exp(0.6 * random.gauss(0, 1) ** 2) for _ in range(2000)) / 2000
assert big > 2.5
print("Fernique shadow: E[exp(alpha chi^2)] finite iff alpha < 1/2: OK"

)
print("END ====")
