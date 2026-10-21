# -*- coding: utf-8 -*-
print("==== 00 intro")
# 第 00 章：康托乐园的机器预演。
# ① 教室等数——不数数而知道"一样多"（一一对应即名单）；
# ② 伽利略对应 n↔n² 与偶数对应 n↔2n——部分与整体等数；
# ③ 有理数 zigzag——Q⁺ 的显式枚举名单（与 N 等数的证据）；
# ④ 对角线——从"已列出的数表"构造必然漏网的数；
# ⑤ 幂集阶梯——|P(X)| = 2^|X| 的有限影子（Cantor 定理预演）。
from fractions import Fraction
from math import gcd

# ② 伽利略对应：n ↔ n²。单射与"映满平方数"同时成立——这就是等数的名单。
K = 40
galileo = {n: n * n for n in range(K + 1)}
assert len(set(galileo.values())) == K + 1          # 单射：不同 n 给不同 n²
assert set(galileo.values()) == {n * n for n in range(K + 1)}   # 满到平方数
squares = set(galileo.values())
assert squares < set(range(K * K + 1))               # 平方数是自然数的真部分
print("galileo: N ~ Squares via n->n^2, yet Squares is a proper part: OK")

evens = {n: 2 * n for n in range(K + 1)}
assert len(set(evens.values())) == K + 1
assert evens == {n: 2 * n for n in range(K + 1)}
print("galileo: N ~ Evens via n->2n: OK")

# ① 教室等数：不数数，靠配对。椅子与人的对应就是"等数"的判定。
chairs = ["c%d" % i for i in range(30)]
people = ["p%d" % i for i in range(30)]
seating = dict(zip(chairs, people))                  # 一人一椅，无空椅无人站
assert len(seating) == len(chairs) == len(set(seating.values()))
print("classroom: bijection witnesses equinumerosity without counting: OK")

# ③ 有理数 zigzag：沿对角线 p+q = d 枚举互素对 (p,q)，q≥1。
# 这是 Q⁺ = {p/q : p≥0, q≥1, gcd(p,q)=1} 的一张不重不漏的名单。
def rationals(count):
    out, d = [], 1                                  # 从 p+q=1（即 0/1）开始，沿对角线爬行
    while len(out) < count:
        for p in range(d + 1):                       # 0 ≤ p ≤ d，q = d - p
            q = d - p
            if q >= 1 and gcd(p, q) == 1:
                out.append(Fraction(p, q))
        d += 1
    return out

qs = rationals(60)
assert len(set(qs)) == len(qs)                       # 名单不重
assert qs[:4] == [Fraction(0), Fraction(1), Fraction(1, 2), Fraction(2)]  # 不漏：从 0,1,1/2,2 起步
for want in (Fraction(1, 3), Fraction(3, 2), Fraction(7, 5)):
    assert want in qs
print("zigzag: Q+ enumerated without repetition (first 60 terms), Q ~ N: OK")

# ④ 对角线：给一张 n×n 的"已列出实数"表（二进制小数位），
# 构造 c 使 c 的第 i 位 ≠ 第 i 行的第 i 位——c 与每一行都不同。
n = 12
rows = [[(i * j + i + j) % 2 for j in range(n)] for i in range(n)]
c = [1 - rows[i][i] for i in range(n)]               # 翻转对角线
for i in range(n):
    assert c[i] != rows[i][i]                        # c 与第 i 行在第 i 位不同
print("diagonal: constructed number differs from every listed row: OK")

# ⑤ 幂集阶梯：|P(X)| = 2^|X| > |X|（有限情形就是 Cantor 定理的影子）。
for k in range(0, 8):
    assert 2 ** k > k
assert 2 ** (2 ** 3) > 2 ** 3 > 3                    # 阶梯可无限续：X, P(X), P(P(X)), ...
print("power ladder: 2^k > k and the tower keeps growing: OK")
print("END ====")
