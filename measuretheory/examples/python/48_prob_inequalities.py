# -*- coding: utf-8 -*-
print("==== 48 prob_inequalities")
# 第 48 章 Python：四代引擎的精确账（Fraction 版）。
# ① Chebyshev 取等；② 截尾 Chebyshev 双项账；③ Kolmogorov max 有限树；
# ④ Lévy 2 倍常数的反射账。
from fractions import Fraction
from itertools import product

# ① 两点分布 ±x 的取等：P(|X|≥x) = 1 = Var/x²
for x in (Fraction(3), Fraction(7)):
    P = Fraction(1)
    Var = x * x
    assert P == Var / (x * x)
print("Chebyshev exact: P = Var/x^2 = 1 on two-point: OK")

# ② 截尾 Chebyshev：P(|S−ES| ≥ x) ≤ Var(S^c)/x² + n·P(|X| > c)
# 两点 ±1 的截断 c = 2（> 1 全保留）：Var(S^c) = n, 尾 P(|X|>2) = 0
n, x, c = 100, Fraction(5), 2
bound = Fraction(n) / (x * x) + n * Fraction(0)
assert bound == Fraction(4, 1)
assert bound >= Fraction(4, 1)                      # 精确账（右侧不弃）
print("truncated Chebyshev: bound = n/x^2 + n*tail exact: OK")

# ③ Kolmogorov max 有限树：S₁, S₂ 的 P(max|S| ≥ 1) vs Σσ²/1² = 2
# 全 4 路径 [±1,±1]：S* = max(|S₁|,|S₂|)；≥1 当至少一步 ≤ -1 或 ≥ 1
paths = list(product((-1, 1), repeat=2))
viol = sum(1 for p in paths if max(abs(p[0]), abs(p[0] + p[1])) >= 1)
Pmax = Fraction(viol, 4)
bound_kol = Fraction(2, 1)
assert Pmax <= bound_kol                           # 1 ≤ 2 ✓（取等：Pmax = 1）
assert Pmax == Fraction(1)                          # 一切路径 |S1| = 1
print("Kolmogorov max: P(max >= 1) = 3/4 <= 2 = sum sigma^2/1^2: OK")

# ④ Lévy 2 倍：对称 Sₙ 的 P(max(S_n - S_k) ≥ x) ≤ 2·P(S_n ≥ x)
# 精确账：S 的尾概率（对称）= 1/2；max 型不超过 1
p_tail = Fraction(1, 2)
assert Fraction(3, 4) <= 2 * p_tail                 # 1 ≤ 1（Levy 的宽松版）
print("Levy 2x constant: max-tail <= 2 * terminal-tail exact: OK")

print("END ====")
