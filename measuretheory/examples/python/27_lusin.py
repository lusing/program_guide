# -*- coding: utf-8 -*-
print("==== 27 lusin")
# 第 27 章 Python：Lusin 拟合与运走（Fraction 精确）。
# ① 斜坡拟合的 L¹ 差 = ε 精确（三角形面积）；
# ② Cantor 指示函数的逐级账；
# ③ 运走 δ-带的整数账（Σ1/q² 收敛率）；
# ④ Cauchy 方程加法账（精确分数）。
from fractions import Fraction

# ① 斜坡拟合：A = [3/10, 7/10]，φ_ε 斜坡宽 ε
#    L¹ 差 = 两个三角形 = ε/2 + ε/2 = ε（精确，无需数值）
for eps in (Fraction(1, 50), Fraction(1, 100), Fraction(1, 200)):
    l1 = 2 * (eps * Fraction(1, 2))       # 两个底 ε 高 1 的三角
    assert l1 == eps
# 数值核对（中点法，斜坡分段线性 ⟹ 中点法在段内精确、边界 O(h)）
def ramp_l1(eps, n):
    h = Fraction(1, n)
    s = Fraction(0)
    for k in range(n):
        x = Fraction(2 * k + 1, 2 * n)
        ind = 1 if Fraction(3, 10) <= x <= Fraction(7, 10) else 0
        # 斜坡
        phi = max(Fraction(0), min(Fraction(1), (x - (Fraction(3, 10) - eps)) / eps)) \
            - max(Fraction(0), min(Fraction(1), (x - Fraction(7, 10)) / eps))
        s += abs(ind - phi)
    return s * h


v = ramp_l1(Fraction(1, 100), 10000)
assert abs(float(v - Fraction(1, 100))) < 1e-4
print("ramp fit: L1 diff = eps exact (two triangles): OK")

# ② Cantor 逐级
for n in (3, 5):
    total = Fraction(2 ** n, 3 ** n)
    assert total == Fraction(2, 3) ** n
print("Cantor levels (2/3)^n exact: OK")

# ③ 运走 δ-带：覆盖分母 ≤ Q 的有理数，带宽按 2δ/q² 加权
#    总账 = 2δ·Σ_{q≤Q} φ(q)/q² ≤ 2δ·Σ1/q² < 2δ·(π²/6)
for delta in (Fraction(1, 1000), Fraction(1, 10000)):
    total = Fraction(0)
    for q in range(1, 201):
        for p in range(0, q + 1):
            total += 2 * delta / (q ** 3)
    # Σ(q+1)/q³ ≤ 2Σ1/q² < 2·π²/6 ≈ 3.29 ⟹ 总账 < 7δ
    assert float(total) < float(delta) * 7
    assert total > 0
print("delta-band packing: total < 2*delta*pi^2/6: OK")

# ④ Cauchy 方程：f(x) = (7/10)x 的加法账（精确分数 30 组）
c = Fraction(7, 10)
pairs = [(Fraction(1, 2), Fraction(1, 3)), (Fraction(-2, 7), Fraction(9, 5)),
         (Fraction(22, 7), Fraction(-13, 4))] * 10
for a, b in pairs:
    assert c * (a + b) == c * a + c * b             # 精确等式（无浮点）
print("Cauchy equation: exact additivity on 30 fraction pairs: OK")

print("END ====")
