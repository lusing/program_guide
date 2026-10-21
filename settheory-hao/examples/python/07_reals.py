# -*- coding: utf-8 -*-
print("==== 07 reals")
# 第 07 章 Python：数系扩张的精确实现与审计。
# ① ℤ := (ℕ×ℕ)/~（书 3.4.1）：序/加/乘按 (3.14) 定义，与内建 int
#    经 (m,n)↦m−n 逐条对拍；
# ② ℚ := (ℤ×ℤ⁺)/~（书 3.4.7）：运算按 (3.16)，与 Fraction 对拍；
#    1/p 的两种情况（书 3.4.10）；
# ③ ℤ、ℚ 可数（书 3.4.13）：等价类代表的不重不漏名单；
# ④ ℚ 的缺陷（书 3.5.2）：魔法公式 q = p − (p²−2)/(p+2) 两个方向
#    的精确计算——A 无最大元、B 无最小元；
# ⑤ 戴德金分割的窗口运算（书 3.5.3-3.5.9）：向下封闭、sup = ⋃、
#    有理分割的加法。
from fractions import Fraction as F
from itertools import product


# ① ℤ 的实现：代表 (m, n) 意为 m − n；规范形让一翼归零
def zcanon(m, n):
    k = min(m, n)
    return (m - k, n - k)                              # (差, 0) 或 (0, 差)


def zadd(a, b):
    (m1, n1), (m2, n2) = a, b
    return zcanon(m1 + m2, n1 + n2)                    # (3.14) 加法


def zmul(a, b):
    (m1, n1), (m2, n2) = a, b
    return zcanon(m1 * m2 + n1 * n2, m1 * n2 + n1 * m2)   # (3.14) 乘法


def zle(a, b):                                         # (3.14) 序
    (m1, n1), (m2, n2) = a, b
    return m1 + n2 <= m2 + n1


zof = lambda a: a[0] - a[1]                            # 解释映射到内建 int

ints = [(m, n) for m in range(4) for n in range(4)]
for a in ints:
    for b in ints:
        assert zof(zadd(a, b)) == zof(a) + zof(b)      # 运算与代表无关的影子
        assert zof(zmul(a, b)) == zof(a) * zof(b)
        assert zle(a, b) == (zof(a) <= zof(b))
assert zcanon(0, 0) == (0, 0)
neg = lambda a: (a[1], a[0])                           # 书 3.4.4：−a = (n,m)
for a in ints:
    assert zadd(a, neg(a)) == (0, 0)
print("integers as pairs: ops per (3.14) match builtin via m-n: OK")

# ② ℚ 的实现：代表 (a, b)、b > 0；规范形约分到最简
def qcanon(a, b):
    assert b != 0
    if b < 0:
        a, b = -a, -b
    g = 0
    from math import gcd
    g = gcd(abs(a), b)
    return (a // g, b // g)


def qadd(q, r):
    (a1, b1), (a2, b2) = q, r
    return qcanon(a1 * b2 + a2 * b1, b1 * b2)          # (3.16) 加法


def qmul(q, r):
    (a1, b1), (a2, b2) = q, r
    return qcanon(a1 * a2, b1 * b2)


def qle(q, r):
    (a1, b1), (a2, b2) = q, r
    return a1 * b2 <= a2 * b1                          # (3.16) 序


qof = lambda q: F(q[0], q[1])

rats = [(a, b) for a in range(-3, 4) for b in (1, 2, 3)]
for q in rats:
    for r in rats:
        assert qof(qadd(q, r)) == qof(q) + qof(r)
        assert qof(qmul(q, r)) == qof(r) * qof(q)
        assert qle(q, r) == (qof(q) <= qof(r))
# 1/p 的两种情况（书 3.4.10(2)）
for (a, b) in rats:
    if a > 0:
        assert qmul((a, b), (b, a)) == (1, 1)
    elif a < 0:
        assert qmul((a, b), (-b, -a)) == (1, 1)
print("rationals as pairs: ops per (3.16) match Fraction; 1/p both cases: OK")

# ③ 可数（书 3.4.12-3.4.13）：等价类的规范形名单不重不漏
def count_classes(pairs, canon, upto):
    seen = set()
    for p in pairs:
        if len(seen) >= upto:
            break
        seen.add(canon(*p))
    return seen

z_pairs = [(m, n) for m in range(40) for n in range(40)]
zs = count_classes(z_pairs, zcanon, 25)
assert len(zs) >= 25                                    # 无穷多类，名单可延伸
q_pairs = [(a, b) for a in range(-20, 21) for b in range(1, 21)]
qs = count_classes(q_pairs, qcanon, 60)
assert len(qs) >= 60
print("countability: canonical reps give non-repeating enumeration: OK")

# ④ 魔法公式（书 3.17/3.18）两个方向的精确计算
def magic(p):
    return p - F(p * p - 2, p + 2)

for num in range(1, 15):                               # A 方向：向上顶
    p = F(num, 10)
    if 0 < p and p * p < 2:
        q = magic(p)
        assert p < q and q * q < 2
for den in (1, 2, 3, 4, 5, 10, 20, 50):                # B 方向：向下压
    p = F(3, 1) if den == 1 else F(7, den)
    if p > 0 and p * p > 2:
        q = magic(p)
        assert q < p and q * q > 2
print("magic formula: lifts A upward, pushes B downward (exact fractions): OK")

# ⑤ 戴德金分割（书 3.5.3）：窗口 = [-3, 3] 上步长 1/7 的有理网格
GRID = [F(k, 7) for k in range(-21, 22)]

def cut_below(p):                                      # p_R = {q | q < p}
    return frozenset(q for q in GRID if q < p)

def is_cut(S):                                         # 三条件的窗口版
    if not S or S == frozenset(GRID):
        return False                                   # (1) 非空真子集
    if any(q in S and (r < q and r not in S) for q in S for r in GRID):
        return False                                   # (2) 向下封闭
    outside = [g for g in GRID if g not in S]
    b = min(outside)                                   # 第一个漏网者 = 分割边界
    # (3) 无最大元（余量版）：离边界 ≥1 的元素都有更大同伴——
    # 有限窗口必然有最大元，无穷条件只能如此降格
    return all(any(r > q for r in S) for q in S if q < b - 1)

for p in (F(-1, 2), 0, F(1, 3), 1, F(9, 7)):
    assert is_cut(cut_below(p))
    assert is_cut(frozenset(q for q in GRID if q <= 0 or q * q < 2))
    # ↑ √2 的分割：负半轴全体 + 平方小于 2 的正数
# 序 = 包含（书 3.5.5）；加法 = 逐点和（书 3.5.7）；sup = ⋃（书 3.5.6）
for (p, q) in ((F(1, 2), F(1, 3)), (0, 1), (F(-1, 2), F(3, 4))):
    x, y = cut_below(p), cut_below(q)
    assert (x <= y) == (p <= q)                        # ≤_R 即 ⊆（有理分割）
    s = frozenset(a + b for a in x for b in y)
    for g in GRID:                                     # 深处一致：x+y 与
        if g <= p + q - 1:                             # (p+q)_R 在离边界 ≥1
            assert g in s                              # 的深处逐点相同
        if g >= p + q + 1:
            assert g not in s
big = frozenset().union(*[cut_below(p) for p in (F(1, 2), F(2, 3), F(3, 4))])
assert big == cut_below(F(3, 4))                       # ⋃ 递增族 = 最大者的分割
print("dedekind cuts: order=containment, deep sums, sup=union: OK")
print("END ====")
