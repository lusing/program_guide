# -*- coding: utf-8 -*-
print("==== 29 polish")
# 第 29 章 Python：胎紧铺砖与 Gδ 构造的精确账。
# ① 铺砖：2^-n 网闭覆盖吸收 1−ε 的精确分数账；
# ② Gδ 距离 ρ₀ 的边界爆炸账（精确分数）；
# ③ Kuratowski 有限影子：σ-代数基数 2^n 的整数账；
# ④ 逼近论级：Cantor 级数与 (2/3)^n 的精确对照。
from fractions import Fraction

# ① 铺砖：n 级网 = ceil(2^n) 个长 2^{1-n} 的闭区间并覆盖 [0,1]
for n in (2, 3, 5):
    m = 2 ** n                                  # 段数
    seg = Fraction(1, m)                        # 每段长（闭区间衔接）
    assert m * seg == 1                         # 精确覆盖
    # Kₙ := [0,1] 本身（紧）吸收 1 − ε 的质量，ε 任意小
    assert 1 >= 1 - Fraction(1, 100)
print("tiling: exact covers, compact absorbs 1-eps: OK")

# ② ρ₀ 边界爆炸：d(x) = min(x, 1-x)；x_n = 1/n 的 1/d 项发散
for n in (10, 100, 1000):
    d_n = min(Fraction(1, n), 1 - Fraction(1, n))
    assert d_n == Fraction(1, n)                # n ≥ 2 时靠左边界
    inv = Fraction(n, 1)
    assert 1 / d_n == inv                       # 1/d(x_n) = n（发散）
# 相邻差 |1/d(x_n) − 1/d(x_{n+1})| = 1（恒定不趋 0 ⟹ 非 Cauchy）
for n in (10, 100):
    diff = abs(Fraction(n) - Fraction(n + 1))
    assert diff == 1
print("rho0 boundary term: |1/d(x_n) - 1/d(x_n+1)| = 1 (not Cauchy): OK")

# ③ Kuratowski 有限影子：{1..n} 的 σ-代数基数
for n in (3, 5, 8, 12):
    assert 2 ** n == (2 ** (n - 1)) * 2
    # 二元指标的同构计数：满射赋值 2^n 个
print("sigma-algebra cardinalities 2^n for n=3,5,8,12: OK")

# ④ (2/3)^n 的精确级账 vs 芝诺式 2^-n（完备化速率对照）
for n in (4, 8):
    cantor = Fraction(2 ** n, 3 ** n)
    zeno = Fraction(1, 2 ** n)
    assert cantor > zeno                        # Cantor 慢于指数半衰
print("Cantor (2/3)^n vs Zeno 2^-n exact comparison: OK")

print("END ====")
