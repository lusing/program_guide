# 第 43 章 Python：Lindeberg 条件的精确账（Fraction 全程）+ 固定种子模拟。
# ① 三族商表与整数证书（多项式族 n=8 阈值 9 越过全体最大 8；有界族 n=5 起归零）；
# ② Feller 条件（最大方差份额）：多项式 2/(n+1) -> 0，几何恒 1/2；
# ③ 峰度精确分数：几何族 kurt -> 7/3（与正态差 2/3），多项式族 -> 3；
# ④ MC 峰度对账（random.Random(4301)）。
print("==== 43 lindeberg")
from fractions import Fraction as F
import random


def poly(n):
    return list(range(1, n + 1))


def geo(n):
    return [1] + [2 ** (k - 1) for k in range(1, n)]


def quot(sig2, eps):
    c2 = sum(sig2)
    thr = eps * eps * c2
    return F(sum(s for s in sig2 if s >= thr), c2)


def share(sig2):
    return F(max(sig2), sum(sig2))


# ---------- ① 商表与整数证书 ----------
print("① Lindeberg 商（eps=1/2，两点分布 ±sigma）：")
for n in [4, 7, 8, 12]:
    print("   多项式 n=%-2d：商 = %s" % (n, quot(poly(n), F(1, 2))))
assert quot(poly(7), F(1, 2)) == F(1, 4)
assert quot(poly(8), F(1, 2)) == 0
print("   证书：n=8 时 c^2=36，eps^2·c^2=9 > max sigma^2=8 -> 无越线者（商=0）")
for n in [4, 6, 8, 10]:
    q = quot(geo(n), F(1, 2))
    print("   几何   n=%-2d：商 = %s" % (n, q))
    assert q == F(3, 4)
print("   有界 n=4：商 = %s（阈值 3 被踩线，恰好全数越线）" % quot([3] * 4, F(1, 2)))
print("   有界 n=5：商 = %s（注 5.3.2：有界方差自动满足）" % quot([3] * 5, F(1, 2)))
assert quot([3] * 4, F(1, 2)) == 1
assert quot([3] * 5, F(1, 2)) == 0

# ---------- ② Feller 条件（最大方差份额） ----------
print("② Feller 条件：最大方差份额 max sigma^2/c^2：")
for n in [8, 16, 32]:
    print("   多项式 n=%-2d：份额 = %s" % (n, share(poly(n))))
    assert share(poly(n)) == F(2, n + 1)
for n in [8, 16]:
    print("   几何   n=%-2d：份额 = %s（恒 1/2，例 5.3.1 的独裁）" % (n, share(geo(n))))
    assert share(geo(n)) == F(1, 2)

# ---------- ③ 峰度精确分数 ----------
def kurt_exact(sig2):
    c2 = sum(sig2)
    return 3 - F(2 * sum(s * s for s in sig2), c2 * c2)


print("③ 两点和的峰度（kurt = 3 - 2·Σσ^4/c^4）：")
for n in [8, 16, 32]:
    print("   多项式 n=%-2d：kurt = %.6f" % (n, float(kurt_exact(poly(n)))))
for n in [8, 16]:
    print("   几何   n=%-2d：kurt = %s = %.6f（极限 7/3）" % (n, kurt_exact(geo(n)), float(kurt_exact(geo(n)))))
assert abs(kurt_exact(geo(16)) - F(7, 3)) < F(1, 100)
assert kurt_exact(poly(32)) > F(29, 10)

# ---------- ④ MC 峰度对账 ----------
rng = random.Random(4301)


def emp_kurt(sig2, m=100000):
    import math
    c = math.sqrt(sum(sig2))
    t = []
    for _ in range(m):
        acc = 0.0
        for s2 in sig2:
            acc += (1 if rng.random() < 0.5 else -1) * math.sqrt(s2)
        t.append(acc / c)
    mu = sum(t) / m
    m2 = sum((x - mu) ** 2 for x in t) / m
    m4 = sum((x - mu) ** 4 for x in t) / m
    return m4 / m2 ** 2


print("④ MC（10^5 次，固定种子）经验峰度：")
kg = emp_kurt(geo(8))
print("   几何   n=8 ：经验峰度 = %.3f（理论 7/3 ≈ 2.333）" % kg)
assert abs(kg - 7 / 3) < 0.08
kp = emp_kurt(poly(32))
print("   多项式 n=32：经验峰度 = %.3f（理论 > 2.9，贴近正态 3）" % kp)
assert kp > 2.8
print("END ====")
