# -*- coding: utf-8 -*-
print("==== 42 martingale_convergence")
# 第 42 章 Python：Pólya 罐与 G-W（Fraction 精确版）。
# ① Pólya 罐的分布递推；② G-W 灭绝不动点；③ 乘积鞅的精确期望。
from fractions import Fraction
from itertools import product

# ① Pólya 罐的精确递推：初 (1,1)，2 步后 R 的分布
# 路径 = 每步抽红（R+1）或抽黑（B+1），概率 = 当前比例
def polya_dist(steps):
    dist = {(1, 1): Fraction(1)}
    for _ in range(steps):
        new = {}
        for (r, b), p in dist.items():
            t = r + b
            pr = Fraction(r, t)
            for (dr, db), q in ((1, 0), pr), ((0, 1), 1 - pr):
                key = (r + dr, b + db)
                new[key] = new.get(key, Fraction(0)) + p * q
        dist = new
    return dist

d4 = polya_dist(4)
# 总概率归一
assert sum(d4.values()) == 1
# R_4 的分布：t = 6，R = 1..5 各 1/5（均匀的有限影子——Beta(1,1) 证据）
Rdist = {}
for (r, b), p in d4.items():
    Rdist[r / (r + b)] = Rdist.get(r / (r + b), Fraction(0)) + p
assert len(Rdist) == 5                       # R ∈ {1/6..5/6}
for v, p in Rdist.items():
    assert p == Fraction(1, 5)               # 均匀（离散化）
print("Polya urn 4 steps: R-distribution uniform on 5 atoms (Beta shadow): OK")

# ② G-W 灭绝不动点：P0 = p, P2 = 2(1-p)/... 简化 P(0)=1/2, P(2)=1/2
# 均值 mu = 1（临界）——不动点 s = 1（唯一）；改 P(0)=0.6, P(2)=0.4：mu=0.8
# s = 0.6 + 0.4 s² 的最小解
def is_fixed(c0, c2, s):
    return c0 + c2 * s * s == s
# 次临界（mu = 0.8）：s = 1 是不动点（且为最小——浮点迭代从 0 收敛到 1）
assert is_fixed(Fraction(3, 5), Fraction(2, 5), Fraction(1, 1))
# 超临界（mu = 1.6）：s = 1/4 是不动点（最小根——从 0 迭代收敛到它）
assert is_fixed(Fraction(1, 5), Fraction(4, 5), Fraction(1, 4))
# 浮点收敛方向（Exact 分数迭代会因分母平方爆炸——只做不动点验证 + 浮点方向）
def fp_float(c0, c2, n=100):
    s = 0.0
    for _ in range(n):
        s = c0 + c2 * s * s
    return s
assert abs(fp_float(0.2, 0.8) - 0.25) < 1e-10  # 收敛到小根
assert abs(fp_float(0.6, 0.4) - 1.0) < 1e-10   # 收敛到 1
print("GW fixed points: subcritical s=1, supercritical s=1/4 exact: OK"

)
# ③ 乘积鞅期望恒等：E[prod(1±eps)] = 1（对称 ±eps 的逐步均值 = 1）
for eps_num, eps_den in ((2, 5), (4, 5)):
    one_plus = Fraction(eps_den + eps_num, eps_den)
    one_minus = Fraction(eps_den - eps_num, eps_den)
    single = Fraction(1, 2) * one_plus + Fraction(1, 2) * one_minus
    assert single == Fraction(1)                # E[1+xi] = 1（对称）
    for n in (5, 20):
        assert single ** n == Fraction(1)       # 乘积期望 = 1^n = 1
print("product martingale: E[prod(1±eps)] = 1 exact (per-step mean 1): OK")

print("END ====")
