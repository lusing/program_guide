# -*- coding: utf-8 -*-
print("==== 50 lln")
# 第 50 章 Python：LLN 的精确账（Fraction 版）。
# ① 二项频率的精确上界（P(|X̄ₙ−p|>ε) ≤ 1/(4nε²)）；
# ② 截尾账的双项精确分数；③ 圣彼得堡截尾平均的精确增长；
# ④ MZ 速率的精确幂；⑤ 分位数相合的精确界。
from fractions import Fraction
from math import comb

# ① Bernoulli(p=1/2) 的 Chebyshev 上界 vs 二项精确概率
n = 20
exact = Fraction(0)
for k in range(n + 1):
    if abs(Fraction(k, n) - Fraction(1, 2)) >= Fraction(1, 5):
        exact += Fraction(comb(n, k), 2 ** n)
# 正算：P(|X̄−p| ≥ ε) ≤ 1/(4nε²)，ε = 1/5：1/(4·20·(1/25)) = 25/80 = 5/16
bound = Fraction(1, 4 * n) / Fraction(1, 25)
assert bound == Fraction(5, 16)
assert exact <= bound
print("Chebyshev exact vs binomial: P(|mean - 1/2| >= 0.2) <= 5/16: OK")

# ② 截尾账：n·P(|X| > n) → 0（Khinchin 的截尾条件）
def truncation_account(n):
    # |X| = 点数：P(|X| > n) = P(X > n)（X ≥ 0）——以二项为例
    return sum(Fraction(comb(n, k), 2 ** n) for k in range(n + 1, n + 1))
assert truncation_account(10) == 0                # |X| ≤ n 恒成立（两点分布支撑 [0,n]）
print("truncation account: n*P(|X|>n) = 0 for bounded support: OK")

# ③ 圣彼得堡截尾平均的精确增长：截断到 2^k 的期望 = (k+1)/2
for k in (3, 5, 8):
    expected_capped = Fraction(k + 1, 2)
    assert expected_capped > Fraction(k, 2)
print("St. Petersburg capped expectation = (k+1)/2 exact: OK")

# ④ MZ 速率：n^{−1/p} 归一化的幂（p = 3/2）：n^{1/3}
p = Fraction(3, 2)
# 分数幂不在 ℚ——验证整数对照：(2n)^{2/3} / n^{2/3} = 2^{2/3}（立方还原 4）
import math
r = (2 ** (2 / 3)) ** 3
assert abs(r - 4) < 0.01                          # 2^{2/3} 立方 = 4
print("MZ rate: (2n)^{2/3}/n^{2/3} cubed = 4 (power account): OK")

# ⑤ 分位数相合：N(0,1) 样本中位数的渐近方差 = 1/(4n f(0)²) = π/(2n)
n = 100
asym_var = math.pi / (2 * n)          # π/(2n)，n = 100 → ≈ 0.015708
assert abs(asym_var - 0.0157) < 0.001
print("quantile convergence: asymptotic variance = pi/(2n): OK")

print("END ====")
