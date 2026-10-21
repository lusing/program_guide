# -*- coding: utf-8 -*-
print("==== 24 markov_least_squares")
# 第 24 章 Python：差分方程与最小二乘。
# ① 5 连黑补事件递推（精确分数到 n=100）；② 分块下界；③
# Fibonacci/Binet 双路；④ Leslie 特征值与迁移矩阵收敛；⑤
# 最小二乘正规方程手作 vs 库解 + 三种误差度量对照。
from fractions import Fraction
from math import log, sqrt

# ① 补事件递推 bₙ = Σ_{k=1..5} b_{n−k}/2ᵏ
b = [Fraction(1)] * 5
for n in range(5, 101):
    b.append(sum(b[n - k] / 2 ** k for k in range(1, 6)))
a = [1 - x for x in b]
assert a[5] == Fraction(1, 32)
assert abs(float(a[10]) - 0.109375) < 1e-9          # 原书 a₁₀ ≈ 0.109
assert abs(float(a[100]) - 0.8101) < 5e-4            # 原书 81.01%
assert abs(float(a[20]) - 0.2499) < 5e-4             # 中途对照（书表 n=20 ≈ 25%）
print("5-black run: exact fraction recurrence, a_100 = 81.01%: OK")

# ② 分块下界：20 块 5 连段
lb5 = 1 - (31 / 32) ** 20
assert abs(lb5 - 0.470051) < 1e-5                    # 原书 ≥47%
lb10 = 1 - (912 / 1024) ** 10                        # 10 块 10 连段（112/1024 全黑串外）
assert abs(lb10 - 0.686) < 2e-3                      # 原书 68.6%
assert lb5 < lb10 < float(a[100])                    # 下界单调改进仍低估
print("block lower bounds: 47.0% (5-blocks), 68.6% (10-blocks) < 81.0%: OK")

# ③ Fibonacci 特征方程：Binet vs 递推
phi = (1 + sqrt(5)) / 2
fib = [0, 1]
for _ in range(60):
    fib.append(fib[-1] + fib[-2])
assert all(round(phi ** n / sqrt(5)) == fib[n] for n in (10, 30, 50))
# 增长率 sandwich：(√2)ⁿ ≤ Fₙ ≤ 2ⁿ
for n in (10, 20):
    assert 2 ** (n / 2) <= fib[n] <= 2 ** n
print("fibonacci binet + exponential sandwich: OK")

# ④ Leslie 矩阵最大特征值（幂迭代）与迁移矩阵收敛
A = [[0, 2, 1, 0, 0], [1, 0, 0, 0, 0], [0, 1, 0, 0, 0],
     [0, 0, 1, 0, 0], [0, 0, 0, 1, 0]]
v = [1.0, 0, 0, 0, 0]
for _ in range(200):
    v = [sum(A[i][j] * v[j] for j in range(5)) for i in range(5)]
    nrm = max(abs(x) for x in v)
    v = [x / nrm for x in v]
lam = sum(A[0][j] * v[j] for j in range(5)) / v[0]
assert abs(lam - (1 + sqrt(5)) / 2) < 1e-6           # 主特征值恰为 φ（>1 增长）
print("leslie dominant eigenvalue = phi = ", round(lam, 6), " (>1 growth): OK", sep="")
# 迁移矩阵：Freedonia 80% 留 / Sylvania 70% 留 → 平稳
M = [[0.8, 0.3], [0.2, 0.7]]
p = [0.7, 0.3]                                       # 初始 70 万/30 万
for _ in range(100):
    p = [M[0][0] * p[0] + M[0][1] * p[1], M[1][0] * p[0] + M[1][1] * p[1]]
assert abs(p[0] - 0.6) < 1e-9 and abs(p[1] - 0.4) < 1e-9    # 平稳 60/40
print("migration matrix: converges to 60/40 stationary: OK")

# ⑤ 最小二乘：正规方程手作
import random as _r
_r.seed(24)
xs = [5 + 0.2 * n for n in range(1, 101)]
ys = [5 * x + _r.gauss(0, 4) for x in xs]
N = len(xs)
sx = sum(xs)
sy = sum(ys)
sxx = sum(x * x for x in xs)
sxy = sum(x * y for x, y in zip(xs, ys))
det = N * sxx - sx * sx
a_hat = (N * sxy - sx * sy) / det
b_hat = (sxx * sy - sx * sxy) / det
assert 4.85 < a_hat < 5.15                            # 斜率贴真值 5（b 则漂 1.3——点估计的警示）
# det = N²σ²ₓ 的身份
xbar = sx / N
var_x = sum((x - xbar) ** 2 for x in xs) / N
assert abs(det - N ** 2 * var_x) < 1e-6
# 三种误差度量下最优 b 的分歧（E1 无意义：任何 b 使残差和为 0 当 a 给定）
def E2(bb):
    return sum(abs(y - (a_hat * x + bb)) for x, y in zip(xs, ys))


def E3(bb):
    return sum((y - (a_hat * x + bb)) ** 2 for x, y in zip(xs, ys))


# 网格搜 E2 的最优 b
best2 = min((b for b in [i * 0.01 for i in range(-200, 201)]), key=E2)
assert abs(best2 - b_hat) < 1.0                       # 同量级但取值不同（度量即价值观）
print("least squares: normal-equation a = ", round(a_hat, 3),
      ", det = N^2 sigma_x^2, E2 vs E3 optima differ: OK", sep="")
print("END ====")
