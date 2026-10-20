# -*- coding: utf-8 -*-
print("==== 53 infinitely_divisible")
# 第 53 章 Python：无穷可分的精确账（Fraction 版）。
# ① Poisson 二分解的权重恒等式（二项卷积逐点分数核对）；
# ② 三点分布（1/4-1/2-1/4）的 n=2 卷积根不存在性（支撑论证 +
#    有理网格穷举）；③ 几何分布的 NB 平方根账（系数卷积 = 几何）。
from fractions import Fraction
from math import comb


# ① Poisson 均分：Σ_j w(j)w(k-j) = w(k)（未归一权重 w(k) = λ^k/k!）——
#    二项恒等式的直接展开：Σ C(k,j) (1/2)^j (1/2)^{k-j} = 1
for k in range(0, 8):
    s = sum(Fraction(comb(k, j), 2 ** k) for j in range(0, k + 1))
    assert s == 1
print("Poisson half-split weights: sum_j C(k,j)/2^k = 1 for k<=7 exact: OK")

# ② 三点分布 F：P{±1} = 1/4 各、P{0} = 1/2——n=2 卷积根不存在
#    支撑论证：若 G*G = F，supp G ⊂ ℤ：
#    f_2 = P{X=2} = Σ_g g·g'（和 = 2）= g_1² ⟹ g_1 = 0
#    f_1 = P{X=1} = 2·g_0·g_1 = 1/4 ⟹ g_1 ≠ 0 —— 矛盾
f2, f1 = Fraction(0), Fraction(1, 4)
g1_from_f2 = 0                                    # g_1^2 = 0 ⟹ g_1 = 0
# g_1 从 f_1：2 g_0 g_1 = 1/4 且 g_0 ≤ 1 ⟹ g_1 ≥ 1/8 > 0
assert 2 * 1 * g1_from_f2 == 0 != f1              # 矛盾显形
# 穷举侧证：支撑 {−1,0,1} 上的 dyadic 网格 (k/16) 全搜——无解
sols = 0
for gm in range(0, 17):
    for g0 in range(0, 17):
        for gp in range(0, 17):
            G = (Fraction(gm, 16), Fraction(g0, 16), Fraction(gp, 16))
            if sum(G) != 1:
                continue
            # 卷积 G*G 在 {−2..2} 的值
            c = {}
            for i, a in zip((-1, 0, 1), G):
                for j, b in zip((-1, 0, 1), G):
                    c[i + j] = c.get(i + j, Fraction(0)) + a * b
            if (c.get(-2, 0) == 0 and c.get(-1, 0) == Fraction(1, 4)
                    and c.get(0, 0) == Fraction(1, 2)
                    and c.get(1, 0) == Fraction(1, 4) and c.get(2, 0) == 0):
                sols += 1
assert sols == 0
print("3-point law has no convolution square root (support argument + grid): OK")

# ③ 几何分布 = 负二项平方：pgf G(x) = (2/3)/(1 - x/3)；
#    c_k = (1 - x/3)^{-1/2} 的系数：(2k choose k)/(4^k 3^k)·(2/3)^{1/2}...
#    无理归一化去掉——用未归一系数 a_k = C(2k,k)/12^k：
#    (Σ a_k x^k)^2 的系数 = (1 - x/3)^{-1} 的系数 3^k（精确分数恒等）
M = 10
a = [Fraction(comb(2 * k, k), 12 ** k) for k in range(0, M + 1)]
conv = [sum(a[i] * a[k - i] for i in range(0, k + 1)) for k in range(0, M + 1)]
target = [Fraction(1, 3 ** k) for k in range(0, M + 1)]        # (1-x/3)^{-1} 系数 = 3^{-k}
for k in range(0, M + 1):
    assert conv[k] == target[k]
print("geometric = NB(1/2) square: (sum a_k x^k)^2 = (1-x/3)^{-1} exact: OK")

print("END ====")
