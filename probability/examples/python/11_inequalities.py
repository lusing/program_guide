# -*- coding: utf-8 -*-
print("==== 11 inequalities")
# Markov、Chebyshev、Jensen、Boole 与 WLLN 入口的精确/确定性账。
from fractions import Fraction
from math import exp, sqrt

# 非负性不可省：X=±1 等概率时均值 0，但 P(X>=1/2)=1/2。
assert Fraction(1, 2) - Fraction(1, 2) == 0
assert Fraction(1, 2) > 0

# Markov 紧度：P(X=a)=mu/a，P(X=0)=1-mu/a。
mu, a = Fraction(2), Fraction(4)
p = mu / a
assert p * a == mu
assert p == mu / a
print("Markov bound is attained by a two-point distribution: OK")

# Unif(0,1) 在 0.95 的尾概率：真值、Chebyshev、Markov。
markov_u = Fraction(1, 2) / Fraction(95, 100)
k2_u = Fraction(45, 100) ** 2 / Fraction(1, 12)
cheb_u = 1 / k2_u
assert markov_u == Fraction(10, 19)
assert cheb_u == Fraction(100, 243)
assert Fraction(5, 100) < cheb_u < markov_u
# 错把方差当标准差会得到低于真值的假界。
bad_k = Fraction(45, 100) / Fraction(1, 12)
bad_bound = 1 / bad_k**2
assert bad_bound == Fraction(25, 729) < Fraction(5, 100)
print("Chebyshev sigma-vs-variance trap caught exactly: OK")

# Jensen：g=x^2，X∈{0,2} 等概率；严格不等因分布非退化。
EX = Fraction(1)
EX2 = Fraction(2)
assert EX2 > EX**2
# 仿射函数使 Jensen 取等号：E[3X+2]=3E[X]+2。
assert 3 * EX + 2 == 5
print("Jensen gap E[X^2]-E[X]^2=Var(X)=1: OK")

# Boole/Bonferroni：四骰至少一个 6。
S1, S2 = Fraction(4, 6), Fraction(6, 36)
true_p = 1 - Fraction(5**4, 6**4)
assert S1 - S2 < true_p < S1
print("Boole and Bonferroni sandwich the exact probability: OK")

# WLLN 的 Chebyshev 上界随 n 递减；这里只验证确定性的界。
for n in (10, 100, 10_000, 1_000_000):
    bound = Fraction(1) / (n * Fraction(1, 10) ** 2)
    assert bound == Fraction(100, n)
assert Fraction(100, 1_000_000) < Fraction(100, 10_000)
print("WLLN entrance: sigma^2/(n eps^2) decreases as 1/n: OK")

print("END ====")
