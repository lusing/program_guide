# -*- coding: utf-8 -*-
print("==== 28 product_topological")
# 第 28 章 Python：乘积正则传递的精确账。
# ① 挖洞分解的精确分数账；
# ② 截口 sup-差的 Lipschitz 精确上界；
# ③ 1/4 圆盘三明治（π 的 Leibniz 对拍）；
# ④ 非紧反例的 sup 账（sup 恒 1/2）。
from fractions import Fraction

# ① 挖洞：单位方 = 8 矩形 + 开洞 (2/5,3/5)²
pieces = [
    (Fraction(0), Fraction(2, 5), Fraction(0), Fraction(2, 5)),
    (Fraction(0), Fraction(2, 5), Fraction(2, 5), Fraction(3, 5)),
    (Fraction(0), Fraction(2, 5), Fraction(3, 5), Fraction(1)),
    (Fraction(2, 5), Fraction(3, 5), Fraction(0), Fraction(2, 5)),
    (Fraction(2, 5), Fraction(3, 5), Fraction(3, 5), Fraction(1)),
    (Fraction(3, 5), Fraction(1), Fraction(0), Fraction(2, 5)),
    (Fraction(3, 5), Fraction(1), Fraction(2, 5), Fraction(3, 5)),
    (Fraction(3, 5), Fraction(1), Fraction(3, 5), Fraction(1)),
]
total = sum((x2 - x1) * (y2 - y1) for x1, x2, y1, y2 in pieces)
assert total == Fraction(24, 25)                     # 1 − (1/5)² = 24/25
print("hole decomposition: 8 rectangles sum to 24/25 exact: OK")

# ② 截口 sup-差上界：f(x,y) = sin(xy)，|f(s,y)−f(s₀,y)| ≤ |y|·|s−s₀|（精确 Lipschitz）
#    sup_y≤π 的账 ≤ π·|dx|：数值采样验证上界成立
import math
s0 = Fraction(7, 10)
for dx in (Fraction(1, 100), Fraction(1, 1000)):
    bound = math.pi * float(dx)
    supd = max(abs(math.sin(float(s0 + dx) * t) - math.sin(float(s0) * t))
               for t in [k * math.pi / 4000 for k in range(4001)])
    assert supd <= bound + 1e-12
print("section sup-diff <= pi*|dx| (Lipschitz account): OK")

# ③ 1/4 圆盘三明治：Leibniz 级数 π/4 与格点账夹逼
leibniz = sum(Fraction(-1) ** k / (2 * k + 1) for k in range(2000))
assert abs(float(leibniz) - math.pi / 4) < 1e-3
# 格点账（第一象限 r = 0.9 的开/闭半径）
def quarter(r, n=500):
    cnt = 0
    for i in range(n):
        for j in range(n):
            x = (i + 0.5) / n
            y = (j + 0.5) / n
            if x * x + y * y < r * r:
                cnt += 1
    return Fraction(cnt, n * n)


lo = quarter(0.895)
hi = quarter(0.905)
target = math.pi * 0.9 * 0.9 / 4
assert float(lo) <= target <= float(hi) + 1e-4
assert float(hi - lo) < 0.02
print("quarter-disk sandwich straddles pi*r^2/4: OK")

# ④ 非紧反例：g(s,y) = s·y/(s²+y²) 在 s→0 的 sup 不收敛（恒 1/2）
for dx in (Fraction(1, 100), Fraction(1, 10000)):
    d = float(dx)
    supv = max((d * t) / (d * d + t * t)
               for t in [d * k / 8 for k in range(1, 41)] + [d, 2 * d])  # 峰在 t = dx 处
    assert supv > 0.49
print("non-compact counterexample: sup stays 1/2 (no uniform control): OK")

print("END ====")
