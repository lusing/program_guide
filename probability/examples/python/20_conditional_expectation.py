# -*- coding: utf-8 -*-
print("==== 20 conditional_expectation")
# 第 20 章 Python：条件期望 / 条件方差的精确账。
# ① 有限联合表：E[Y|X]、塔性质、全方差、拿出已知量、勾股分解（Fraction 精确）
# ② 独立 ⇒ 条件期望为常数；反向不成立（均值独立 ≠ 独立）
# ③ 硬币序列：E[S_n | F_k] 随信息逐步更新，且是鞅
# ④ 线性预测 vs 条件期望：Y=X² 与 "E(Xε)=0 但 E(ε|X)≠0"
# ⑤ 连续例 f(x,y)=e^{-y}, 0<x<y 与 Poisson–二项层次模型（sympy 符号）
# ⑥ 条件异方差：Y = Z·sqrt(1+X²)
from fractions import Fraction as F
from itertools import product

import sympy as sp

# ---------------------------------------------------------------- ①
P = {
    (0, 0): F(2, 24), (0, 1): F(3, 24), (0, 3): F(1, 24),
    (1, 0): F(1, 24), (1, 1): F(4, 24), (1, 3): F(3, 24),
    (2, 0): F(4, 24), (2, 1): F(2, 24), (2, 3): F(4, 24),
}
assert sum(P.values()) == 1
xs = sorted({x for x, _ in P})
ys = sorted({y for _, y in P})
pX = {x: sum(P[(x, y)] for y in ys) for x in xs}


def cond_exp(h):
    """返回 x ↦ E[h(X,Y) | X=x]（按条件分布 P(x,y)/pX(x) 加权）。"""
    return {x: sum(h(x, y) * P[(x, y)] for y in ys) / pX[x] for x in xs}


def E(h):
    return sum(h(x, y) * p for (x, y), p in P.items())


m = cond_exp(lambda x, y: y)                      # E[Y|X=x]
v = {x: cond_exp(lambda x, y: y * y)[x] - m[x] ** 2 for x in xs}   # Var(Y|X=x)
assert m == {0: F(1), 1: F(13, 8), 2: F(7, 5)}

# 全期望（塔性质）E[E[Y|X]] = E[Y]
EY = E(lambda x, y: y)
assert sum(pX[x] * m[x] for x in xs) == EY == F(11, 8)

# 全方差 Var(Y) = E[Var(Y|X)] + Var(E[Y|X])
VarY = E(lambda x, y: y * y) - EY ** 2
E_of_var = sum(pX[x] * v[x] for x in xs)
Var_of_E = sum(pX[x] * m[x] ** 2 for x in xs) - EY ** 2
assert VarY == F(95, 64)
assert VarY == E_of_var + Var_of_E

# 拿出已知量：E[X·Y | X=x] = x·E[Y|X=x]；以及 E[XY]=E[X·E[Y|X]]
mxy = cond_exp(lambda x, y: x * y)
assert all(mxy[x] == x * m[x] for x in xs)
assert E(lambda x, y: x * y) == sum(pX[x] * x * m[x] for x in xs)

# 残差 ε=Y−E[Y|X] 与 X 的任意函数 h 正交：E[ε h(X)] = 0
for h in (lambda x: 1, lambda x: x, lambda x: x * x, lambda x: (x - 1) ** 3 + 7):
    assert E(lambda x, y: (y - m[x]) * h(x)) == 0

# 勾股分解：对任意预测规则 g，MSE(g) = MSE(g0) + E[(g0−g)²]
mse0 = E(lambda x, y: (y - m[x]) ** 2)
assert mse0 == E_of_var
for g in ({0: F(1), 1: F(1), 2: F(1)}, {0: F(0), 1: F(2), 2: F(3)}, {0: F(3, 2), 1: F(11, 8), 2: F(1, 7)}):
    mse = E(lambda x, y: (y - g[x]) ** 2)
    gap = sum(pX[x] * (m[x] - g[x]) ** 2 for x in xs)
    assert mse == mse0 + gap and mse >= mse0
# 常数预测的最优者是 E[Y]，其 MSE 就是 Var(Y)
assert E(lambda x, y: (y - EY) ** 2) == VarY
print("1 finite table: tower, total variance, pull-out, Pythagoras: OK")

# ---------------------------------------------------------------- ②
# 独立：联合表 = 边际乘积 ⇒ E[Y|X=x] 对 x 为常数
qx = {0: F(1, 4), 1: F(1, 3), 2: F(5, 12)}
qy = {0: F(1, 3), 1: F(1, 3), 3: F(1, 3)}
Pind = {(x, y): qx[x] * qy[y] for x in qx for y in qy}
m_ind = {x: sum(y * Pind[(x, y)] for y in qy) / qx[x] for x in qx}
assert len(set(m_ind.values())) == 1 and m_ind[0] == sum(y * qy[y] for y in qy)

# 反向不成立：X∈{-1,0,1} 等概率，Y=X²·S' 使 E[Y|X]=0 但 Y 与 X 不独立
# (X, Y) 取 (0,0) w.p. 1/3；(±1, ±1) 每格 1/6（Y 与 X 同号无关，给定 X=±1 时 Y=±1 等概率）
Pm = {(0, 0): F(1, 3)}
for x in (-1, 1):
    for y in (-1, 1):
        Pm[(x, y)] = F(1, 6)
assert sum(Pm.values()) == 1
pXm = {x: sum(p for (a, _), p in Pm.items() if a == x) for x in (-1, 0, 1)}
pYm = {y: sum(p for (_, b), p in Pm.items() if b == y) for y in (-1, 0, 1)}
cm = {x: sum(y * p for (a, y), p in Pm.items() if a == x) / pXm[x] for x in (-1, 0, 1)}
assert all(c == 0 for c in cm.values())            # E[Y|X]=0 恒成立
assert Pm[(0, 0)] != pXm[0] * pYm[0]                # 但 P(0,0)=1/3 ≠ 1/9
print("2 independence => constant E[Y|X]; converse fails: OK")

# ---------------------------------------------------------------- ③
n = 4
paths = list(product((0, 1), repeat=n))
w = F(1, len(paths))


def S(path, k=None):
    return sum(path if k is None else path[:k])


def M(k, path):
    """M_k = E[S_n | X_1..X_k] = S_k + (n−k)/2（公平硬币）。"""
    return S(path, k) + F(n - k, 2)


def cond_given_prefix(f, k, prefix):
    """在前 k 次结果为 prefix 的条件下对 f(path) 求平均。"""
    sel = [pth for pth in paths if pth[:k] == prefix]
    return sum(f(pth) for pth in sel) / len(sel)


for k in range(n + 1):
    for prefix in product((0, 1), repeat=k):
        assert cond_given_prefix(lambda p: S(p), k, prefix) == S(prefix) + F(n - k, 2)
# 鞅性（塔性质的逐步版本）：E[M_{k+1} | F_k] = M_k
for k in range(n):
    for prefix in product((0, 1), repeat=k):
        assert cond_given_prefix(lambda p: M(k + 1, p), k, prefix) == M(k, prefix + (0,) * (n - k))
# 对称性：E[X_1 | S_n] = S_n / n（给定总和，每次试验对称）
for s in range(n + 1):
    sel = [pth for pth in paths if sum(pth) == s]
    assert sum(pth[0] for pth in sel) / len(sel) == F(s, n)
# 信息越多条件方差越小：Var(S_n | F_k) = (n−k)/4
for k in range(n + 1):
    for prefix in product((0, 1), repeat=k):
        sel = [pth for pth in paths if pth[:k] == prefix]
        mu = sum(S(pth) for pth in sel) / len(sel)
        var = sum((S(pth) - mu) ** 2 for pth in sel) / len(sel)
        assert var == F(n - k, 4)
print("3 coin sequence: E[S_n|F_k] martingale, Var=(n-k)/4: OK")

# ---------------------------------------------------------------- ④
# X 均匀于 {-1,0,1}，Y = X²：Cov(X,Y)=0，最优线性预测是常数 E[Y]=2/3
Xv = {-1: F(1, 3), 0: F(1, 3), 1: F(1, 3)}
EXv = sum(x * p for x, p in Xv.items())
EYv = sum(x * x * p for x, p in Xv.items())
cov = sum(x * x * x * p for x, p in Xv.items()) - EXv * EYv
assert cov == 0 and EYv == F(2, 3)
mse_lin = sum((x * x - EYv) ** 2 * p for x, p in Xv.items())      # = Var(Y)
mse_cond = sum((x * x - x * x) ** 2 * p for x, p in Xv.items())   # E[Y|X]=X² ⇒ 0
assert mse_lin == F(2, 9) and mse_cond == 0
# ε = (X²−1)+u，u∈{-1,1} 等概率且与 X 独立：E[Xε]=0 但 E[ε|X]=X²−1≠0
joint = {(x, u): Xv[x] * F(1, 2) for x in Xv for u in (-1, 1)}
assert sum(x * ((x * x - 1) + u) * p for (x, u), p in joint.items()) == 0
cond_eps = {x: sum(((x * x - 1) + u) * F(1, 2) for u in (-1, 1)) for x in Xv}
assert cond_eps == {-1: 0, 0: -1, 1: 0}
print("4 linear vs conditional expectation: OK")

# ---------------------------------------------------------------- ⑤
x, y, lam, p = sp.symbols("x y lambda p", positive=True)
# f(x,y)=e^{-y}, 0<x<y：X~Exp(1)，Y|X=x = x + Exp(1)
fXY = sp.exp(-y)
fX = sp.integrate(fXY, (y, x, sp.oo))
assert sp.simplify(fX - sp.exp(-x)) == 0
fY_given = fXY / fX                                  # e^{-(y-x)}
EYgx = sp.simplify(sp.integrate(y * fY_given, (y, x, sp.oo)))
EY2gx = sp.simplify(sp.integrate(y ** 2 * fY_given, (y, x, sp.oo)))
assert sp.simplify(EYgx - (1 + x)) == 0
assert sp.simplify(EY2gx - EYgx ** 2 - 1) == 0       # 条件同方差 =1
# 全方差：Var(Y)=Var(1+X)+1=2（Y~Gamma(2,1)）
varEX = sp.integrate((x - 1) ** 2 * sp.exp(-x), (x, 0, sp.oo))
assert varEX == 1
assert sp.integrate(sp.exp(-x) * (1 + x), (x, 0, sp.oo)) == 2

# Poisson–二项层次：N~Poisson(λ)，Y|N~Bin(N,p)
EYgN = lambda N: N * p
VarYgN = lambda N: N * p * (1 - p)
E_N, Var_N = lam, lam                                # Poisson
EY_h = p * E_N
E_var = p * (1 - p) * E_N
Var_E = p ** 2 * Var_N
assert sp.simplify(E_var + Var_E - lam * p) == 0     # Var(Y)=λp（Poisson 稀疏化）
print("5 continuous example and Poisson-binomial hierarchy (sympy): OK")

# ---------------------------------------------------------------- ⑥
# Y=Z·sqrt(1+X²)，Z 与 X 独立，E Z=0，Var Z=1 ⇒ E[Y|X]=0，Var(Y|X)=1+X²
# 取 s=sqrt(1+x²) 为符号量，Z∈{-1,1} 等概率：E[Y|x]=0，Var(Y|x)=s²=1+x²
s = sp.symbols("s", positive=True)
Zs = {-1: sp.Rational(1, 2), 1: sp.Rational(1, 2)}
E_Y = sum(z * s * pz for z, pz in Zs.items())
E_Y2 = sum((z * s) ** 2 * pz for z, pz in Zs.items())
assert sp.simplify(E_Y) == 0 and sp.simplify(E_Y2 - s ** 2) == 0
# 全方差：X 均匀于 {-1,0,1,2}，Var(Y)=E[1+X²]=1+3/2=5/2，而 Var(E[Y|X])=0
Xs = [-1, 0, 1, 2]
assert sum(F(1, 4) * (1 + a * a) for a in Xs) == F(5, 2)
print("6 conditional heteroskedasticity: OK")

# ---------------------------------------------------------------- ⑦
# 条件期望 = L² 投影：在 σ(X) 可测函数空间（维数 = |支撑|）上做最小二乘，
# 正规方程的解恰好是各行条件均值；总协方差公式 Cov(U,V)=E[Cov(U,V|X)]+Cov(E[U|X],E[V|X])
# 用 ① 的联合表扩成三元组 (X,Y,W)，W = X·Y + Y²
def Ew(h):
    return sum(h(x, y) * p for (x, y), p in P.items())

# 正规方程：对每个示性函数 1{X=a}，E[(Y−g(X))·1{X=a}] = 0  ⇒  g(a)=E[Y|X=a]
g = {}
for a in xs:
    g[a] = Ew(lambda x, y: y * (1 if x == a else 0)) / pX[a]
assert g == m
# 总协方差公式（U=Y，V=Y²）
cu = cond_exp(lambda x, y: y)
cv2 = cond_exp(lambda x, y: y * y)
cuv = cond_exp(lambda x, y: y * y * y)
cond_cov = {a: cuv[a] - cu[a] * cv2[a] for a in xs}
Ecc = sum(pX[a] * cond_cov[a] for a in xs)
EU, EV = Ew(lambda x, y: y), Ew(lambda x, y: y * y)
cov_of_cond = sum(pX[a] * cu[a] * cv2[a] for a in xs) - EU * EV
cov_uv = Ew(lambda x, y: y * y * y) - EU * EV
assert cov_uv == Ecc + cov_of_cond
print("7 L2 projection normal equations and total covariance: OK")
print("END ====")
