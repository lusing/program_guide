# -*- coding: utf-8 -*-
print("==== 14 uniform_exponential")
# 第 14 章 Python：均匀与指数的精确账。
# ① 均匀三特例 μ/σ² 与三角形分段 CDF（Fraction）；② 三角形
#    再卷积（n=3 分段密度 Simpson 归一）；③ 指数 CDF 与无记忆
#    性数值；④ Erlang(2) Simpson 归一与 [0,1] 概率 1−2/e；
# ⑤ 逆变换采样验证。
from fractions import Fraction
from math import exp, log


def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3


# ① 均匀三特例：μ = (a+b)/2、σ² = (b−a)²/12（积分与代数双路）
assert simpson(lambda x: x, 0, 1, 1000) - 0.5 < 1e-12                  # [0,1] 均值
assert simpson(lambda x: (x - 0.5) ** 2, 0, 1, 1000) - 1 / 12 < 1e-12  # [0,1] 方差
assert simpson(lambda x: x ** 2 * 0.5, 0, 2, 1000) - 4 / 3 < 1e-12     # [0,2] E[X²]=4/3 → Var=1/3
assert (Fraction(1, 2) - Fraction(-1, 2)) ** 2 / 12 == Fraction(1, 12)
assert abs((2 * 3 ** 0.5) ** 2 / 12 - 1) < 1e-12                       # [−√3,√3]: σ²=1
print("uniform three cases: means and variances (1/12, 1/12, 1): OK")

# 三角形密度分段 CDF：F(z) = z²/2（z≤1）、1−(2−z)²/2（z≥1）
tri_cdf = lambda z: z * z / 2 if z <= 1 else 1 - (2 - z) ** 2 / 2
assert tri_cdf(Fraction(1, 2)) == Fraction(1, 8)
assert tri_cdf(Fraction(3, 2)) == Fraction(7, 8)
assert tri_cdf(1) == Fraction(1, 2)
# P(1/2 ≤ Z ≤ 3/2) = 3/4（正文 14.1 例）
assert Fraction(tri_cdf(Fraction(3, 2)) - tri_cdf(Fraction(1, 2))) == Fraction(3, 4)
print("triangle piecewise CDF: F(1)=1/2, P[1/2,3/2]=3/4: OK")

# ② 三重和：Unif(0,1) 之和的分段密度（Irwin–Hall n=3）
#    分段：z²/2（0..1）、−z²+3z−3/2（1..2）、(3−z)²/2（2..3）


def irwin_hall3(z):
    if z < 0 or z > 3:
        return 0.0
    if z <= 1:
        return z * z / 2
    if z <= 2:
        return -z * z + 3 * z - 1.5
    return (3 - z) ** 2 / 2


# 分段 Simpson 归一
tot = simpson(irwin_hall3, 0, 1, 500) + simpson(irwin_hall3, 1, 2, 500) \
    + simpson(irwin_hall3, 2, 3, 500)
assert abs(tot - 1) < 1e-10
assert abs(irwin_hall3(1.5) - 0.75) < 1e-12      # 峰值 3/4
assert abs(irwin_hall3(1) - 0.5) < 1e-12 and abs(irwin_hall3(2) - 0.5) < 1e-12
print("Irwin-Hall n=3 piecewise density: normalized, peak 0.75 at 1.5: OK")

# ③ 指数 λ=30：P(X>45) = e^{−3/2}；无记忆性 P(X>60)/P(X>30)
assert abs(exp(-45 / 30) - 0.22313) < 1e-5
lam = 1.0
F = lambda x: 1 - exp(-x / lam)
assert abs((1 - F(6)) / (1 - F(3)) - (1 - F(3))) < 1e-12   # P(X>6)/P(X>3) = P(X>3)
print("exp lambda=30: P(X>45)=e^{-1.5}; memoryless ratio exact: OK")

# ④ Erlang(λ=1, n=2)：密度 x·e^{−x}；归一 + [0,1] 概率 1−2/e
assert abs(simpson(lambda x: x * exp(-x), 0, 60, 4000) - 1) < 1e-9
assert abs(simpson(lambda x: x * exp(-x), 0, 1, 4000) - (1 - 2 / exp(1))) < 1e-9
# 均值方差 μ=2、σ²=2（nλ 与 nλ²）
assert abs(simpson(lambda x: x * x * exp(-x), 0, 80, 8000) - 2) < 1e-8
assert abs(simpson(lambda x: x * x * x * exp(-x), 0, 80, 8000) - 6) < 1e-7  # E[X^2]=6 → Var=2
print("erlang(1,2): normalized, P[0,1]=1-2/e, E=2, Var=2: OK")

# ⑤ 逆变换采样：X = −λ log(1−U) 的经验分位数 vs 理论
from random import Random
rng = Random(14)
lam5 = 3.0
U = [rng.random() for _ in range(200_000)]
X = [-lam5 * log(1 - u) for u in U]
for q in (0.25, 0.5, 0.75):
    Xs = sorted(X)
    emp = Xs[int(q * len(Xs))]
    theo = -lam5 * log(1 - q)
    assert abs(emp - theo) < 0.05
print("inverse transform sampling: quartiles match -lambda*log(1-q): OK")

print("END ====")
