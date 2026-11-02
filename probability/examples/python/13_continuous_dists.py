# -*- coding: utf-8 -*-
print("==== 13 continuous_dists")
# 第 13 章 Python：连续分布族的精确账。
# ① 均匀三特例 μ/σ² 与三角形分段 CDF（Fraction）；② 三角形
#    再卷积（n=3 分段密度 Simpson 归一）；③ 指数 CDF 与无记忆
#    性数值；④ Erlang(2) Simpson 归一与 [0,1] 概率 1−2/e；
# ⑤ 逆变换采样验证；⑥ Γ 函数/Beta 的数值账；
# ⑦ 广义 Gamma、Beta 矩、Laplace。
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

# ⑥ Γ 函数的数值账（原 13_gamma.py 并入）
from math import ceil, factorial, pi, sin, sqrt


def gamma_num(s, n=20000, B=60.0):
    """∫₀^∞ e^{−x}x^{s−1}dx：(0,1] 段用 x = t^m 代换吸收 0 端
    爆破（m·s ≥ 1 使被积光滑），[1,B] 段朴素 Simpson。"""
    m = max(2, ceil(1 / s)) if s < 1 else 1
    if s < 1:
        low = simpson(lambda t: m * t ** (m * s - 1) * exp(-t ** m), 0, 1, n // 2)
    else:
        low = simpson(lambda t: exp(-t) * t ** (s - 1), 1e-9, 1, n // 2)
    high = simpson(lambda t: exp(-t) * t ** (s - 1), 1, B, n)
    return low + high


for s in range(1, 9):                                   # Γ(n) = (n−1)!
    g = gamma_num(s)
    assert abs(g - factorial(s - 1)) < 1e-4 * factorial(s - 1), (s, g)
print("gamma(s) for s=1..8 equals (s-1)!: OK")

for s, val in [(0.5, sqrt(pi)), (1.5, sqrt(pi) / 2), (2.5, 3 * sqrt(pi) / 4),
               (3.5, 15 * sqrt(pi) / 8)]:               # 半整数族
    g = gamma_num(s)
    assert abs(g - val) < 1e-4 * val, (s, g, val)
print("half-integer family: sqrt(pi), /2, *3/4, *15/8: OK")

for s in (0.5, 1.5, 2.5, 3.5, 4.5):                     # Γ(s+1) = sΓ(s)
    lhs = gamma_num(s + 1)
    rhs = s * gamma_num(s)
    assert abs(lhs - rhs) < 1e-4 * rhs, s
print("functional equation gamma(s+1) = s*gamma(s): OK")

# Beta 基本关系 B(a,b) = Γ(a)Γ(b)/Γ(a+b)；B(1/2,1/2) 用 t = sin²θ 代换
for (a, b) in [(2.0, 3.0), (3.0, 5.0)]:
    B = simpson(lambda t: t ** (a - 1) * (1 - t) ** (b - 1), 1e-9, 1 - 1e-9, 4000)
    rhs = gamma_num(a) * gamma_num(b) / gamma_num(a + b)
    assert abs(B - rhs) < 2e-4 * rhs, (a, b)
B_half = simpson(lambda x: 2.0, 0, pi / 2, 1000)
rhs_half = gamma_num(0.5) * gamma_num(0.5) / gamma_num(1)
assert abs(B_half - rhs_half) < 2e-4 * rhs_half
assert abs(gamma_num(1) * gamma_num(1) / gamma_num(2) - 1) < 1e-6
assert abs(rhs_half - pi) < 2e-4
print("beta(a,b) = gamma product ratio; B(1/2,1/2)=pi: OK")

for s in (0.25, 1 / 3, 0.5):                            # 余割恒等式
    lhs = gamma_num(s) * gamma_num(1 - s)
    rhs = pi / sin(pi * s)
    assert abs(lhs - rhs) < 2e-4 * rhs, s
print("cosecant identity at s=1/4, 1/3, 1/2: OK")

k, sig = 2.0, 3.0                                       # Gamma(k=2, θ=3)
gk = gamma_num(k)                                       # 只算一次，避免每个节点重复积分
fk = lambda x: x ** (k - 1) * exp(-x / sig) / (gk * sig ** k)
assert abs(simpson(fk, 1e-9, 80, 20000) - 1) < 1e-4
assert abs(simpson(lambda x: x * fk(x), 1e-9, 80, 20000) - k * sig) < 5e-3
assert abs(simpson(lambda x: x * x * fk(x), 1e-9, 90, 20000)
           - ((k * sig) ** 2 + k * sig ** 2)) < 5e-3
print("gamma(k=2,sigma=3): normalized, mean 6, var 18: OK")

# ⑦ 广义 Gamma、Beta、Laplace（原 13_families.py 并入）
from math import gamma
from scipy.integrate import quad


def close(a, b, tol=1e-12):
    assert abs(a - b) <= tol * max(1.0, abs(b)), (a, b)


k, p, theta = 2.0, 3.0, 1.5
for r in (0, 1, 2):                    # 作 t=(x/θ)^p 后独立积分审计矩公式
    numerical = theta ** r * quad(
        lambda t: t ** (k + r / p - 1) * exp(-t), 0, 40,
        epsabs=1e-11, epsrel=1e-11)[0] / gamma(k)
    closed = theta ** r * gamma(k + r / p) / gamma(k)
    close(numerical, closed, 1e-9)
close(theta * gamma(k + 1) / gamma(k), k * theta)       # p=1 → Gamma
for x in (0.2, 1.0, 2.0):                               # k=1 → Weibull 生存函数
    t = (x / theta) ** p
    close(exp(-t) * exp(t), 1.0)

a, b = 2.0, 3.0                                         # Beta(2,3)
mean = a / (a + b)
second = a * (a + 1) / ((a + b) * (a + b + 1))
close(mean, 2 / 5)
close(second - mean ** 2, a * b / ((a + b) ** 2 * (a + b + 1)))
close(second, 1 / 5)

mu, scale = -1.0, 2.0                                   # Laplace(μ=−1, b=2)
for x in (0.5, 1.0, 3.0):
    left = exp(-abs((mu - x) - mu) / scale) / (2 * scale)
    right = exp(-abs((mu + x) - mu) / scale) / (2 * scale)
    close(left, right)
close(2 * scale ** 2, 8.0)
x = mu + scale * log(2)
close(1 - exp(-(x - mu) / scale) / 2, 3 / 4)
print("generalized gamma moments, Weibull survival, Beta moments, Laplace tails: OK")

print("END ====")
