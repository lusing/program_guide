# -*- coding: utf-8 -*-
print("==== 24 markov_chains")
# 第 24 章 Python：Markov 链的精确有理数账。
# ① 两状态链：平稳分布、n 步转移、Chapman–Kolmogorov、收敛速率 λ₂ⁿ；
# ② 3×3 生灭链：平稳分布 + 细致平衡；非可逆三圈链：平稳但不满足细致平衡；
# ③ 状态分类：可达性、通信类、常返/暂态、周期；
# ④ 赌徒破产：吸收概率与期望时长（线性方程组，Fraction 解）；
# ⑤ 5 连正面：状态扩张成 Markov 链，期望首达时间 62，a_100 对旧递推；
# ⑥ Leslie 矩阵：特征多项式、主特征值 φ，Fibonacci 矩阵幂；
# ⑦ 遍历均值的渐近方差：Markov 链 ≠ iid（精确有限 n 方差 → 18/25）。
from fractions import Fraction as F
from math import gcd
import sympy as sp


def matmul(A, B):
    return [[sum(A[i][k] * B[k][j] for k in range(len(B))) for j in range(len(B[0]))]
            for i in range(len(A))]


def matpow(A, n):
    R = [[F(int(i == j)) for j in range(len(A))] for i in range(len(A))]
    for _ in range(n):
        R = matmul(R, A)
    return R


def vecmul(v, A):
    return [sum(v[i] * A[i][j] for i in range(len(A))) for j in range(len(A[0]))]


def stationary(P):
    """解 πP=π, Σπ=1（sympy 精确有理数）。"""
    n = len(P)
    pi = sp.symbols(f"p0:{n}")
    eqs = [sum(pi[i] * sp.Rational(P[i][j].numerator, P[i][j].denominator) for i in range(n)) - pi[j]
           for j in range(n)]
    eqs[-1] = sum(pi) - 1
    sol = sp.solve(eqs, pi, dict=True)[0]
    return [F(int(sol[p].p), int(sol[p].q)) for p in pi]


# ① 两状态链（Freedonia / Sylvania）：行随机矩阵
P2 = [[F(4, 5), F(1, 5)], [F(3, 10), F(7, 10)]]
pi2 = stationary(P2)
assert pi2 == [F(3, 5), F(2, 5)]
assert vecmul(pi2, P2) == pi2                       # πP = π
# 两状态链 Pⁿ = Π + λ₂ⁿ (I − Π)，λ₂ = 1 − a − b = 1/2
lam = 1 - F(1, 5) - F(3, 10)
assert lam == F(1, 2)
Pi = [pi2, pi2]
for n in (1, 2, 5, 10):
    Pn = matpow(P2, n)
    for i in range(2):
        for j in range(2):
            assert Pn[i][j] == Pi[i][j] + lam ** n * (F(int(i == j)) - Pi[i][j])
# Chapman–Kolmogorov：P^(m+n) = P^m P^n
assert matpow(P2, 7) == matmul(matpow(P2, 3), matpow(P2, 4))
# 初始 (7/10, 3/10)：10 年后离平稳的距离恰为 λ₂ⁿ·(初值偏差)
mu = [F(7, 10), F(3, 10)]
for _ in range(10):
    mu = vecmul(mu, P2)
assert mu[0] - F(3, 5) == lam ** 10 * (F(7, 10) - F(3, 5))
print("two-state chain: pi=(3/5,2/5), P^n = Pi + (1/2)^n (I-Pi), Chapman-Kolmogorov: OK")

# ② 生灭链（可逆）与三圈链（平稳但不可逆）
P3 = [[F(1, 2), F(1, 2), F(0)], [F(1, 4), F(1, 2), F(1, 4)], [F(0), F(1, 2), F(1, 2)]]
pi3 = stationary(P3)
assert pi3 == [F(1, 4), F(1, 2), F(1, 4)]
assert all(pi3[i] * P3[i][j] == pi3[j] * P3[j][i] for i in range(3) for j in range(3))
cyc = [[F(0), F(3, 4), F(1, 4)], [F(1, 4), F(0), F(3, 4)], [F(3, 4), F(1, 4), F(0)]]
pic = stationary(cyc)
assert pic == [F(1, 3)] * 3                          # 双随机 ⇒ 均匀平稳
assert any(pic[i] * cyc[i][j] != pic[j] * cyc[j][i] for i in range(3) for j in range(3))
print("birth-death chain satisfies detailed balance; 3-cycle chain stationary but irreversible: OK")

# ③ 状态分类
def reach(P):
    n = len(P)
    R = [[P[i][j] > 0 or i == j for j in range(n)] for i in range(n)]
    for k in range(n):
        for i in range(n):
            for j in range(n):
                R[i][j] = R[i][j] or (R[i][k] and R[k][j])
    return R


def classes(P):
    R = reach(P)
    n = len(P)
    seen, out = set(), []
    for i in range(n):
        if i in seen:
            continue
        cl = {j for j in range(n) if R[i][j] and R[j][i]}
        seen |= cl
        out.append(sorted(cl))
    return out, R


def period(P, i, horizon=40):
    g = 0
    M = [[F(int(a == b)) for b in range(len(P))] for a in range(len(P))]
    for n in range(1, horizon + 1):
        M = matmul(M, P)
        if M[i][i] > 0:
            g = gcd(g, n)
    return g


# 状态 0 暂态，状态 1,2 构成闭类，状态 3 吸收
Pc = [[F(1, 2), F(1, 4), F(0), F(1, 4)],
      [F(0), F(0), F(1), F(0)],
      [F(0), F(1), F(0), F(0)],
      [F(0), F(0), F(0), F(1)]]
cls, R = classes(Pc)
assert cls == [[0], [1, 2], [3]]
closed = [c for c in cls if all(not R[i][j] or j in c for i in c for j in range(4))]
assert closed == [[1, 2], [3]]                        # 暂态类 [0] 非闭
assert period(Pc, 1) == 2 and period(Pc, 3) == 1
assert period(P2, 0) == 1
print("classes [0] transient, [1,2] closed period 2, [3] absorbing: OK")

# ④ 赌徒破产：h_i = P(从 i 出发先到 N)，t_i = 期望时长；用线性方程精确求解
def ruin(p, N):
    q = 1 - p
    h = sp.symbols(f"h0:{N+1}")
    t = sp.symbols(f"t0:{N+1}")
    P, Q = sp.Rational(p.numerator, p.denominator), sp.Rational(q.numerator, q.denominator)
    eh = [h[0], h[N] - 1] + [h[i] - P * h[i + 1] - Q * h[i - 1] for i in range(1, N)]
    et = [t[0], t[N]] + [t[i] - 1 - P * t[i + 1] - Q * t[i - 1] for i in range(1, N)]
    sh = sp.solve(eh, h, dict=True)[0]
    st = sp.solve(et, t, dict=True)[0]
    return [F(int(sh[x].p), int(sh[x].q)) for x in h], [F(int(st[x].p), int(st[x].q)) for x in t]


h, t = ruin(F(1, 2), 5)
assert h == [F(i, 5) for i in range(6)]               # 公平：i/N
assert t == [F(i * (5 - i)) for i in range(6)]        # 期望时长 i(N−i)
h, t = ruin(F(2, 3), 5)
rho = F(1, 2)                                         # q/p
assert all(h[i] == (1 - rho ** i) / (1 - rho ** 5) for i in range(6))
print("gambler's ruin: fair h_i=i/N, t_i=i(N-i); biased h_i=(1-rho^i)/(1-rho^N): OK")

# ⑤ 5 连正面：当前连续长度 0..4 + 吸收态 5
S = 6
P5 = [[F(0)] * S for _ in range(S)]
for s in range(5):
    P5[s][s + 1] = F(1, 2)
    P5[s][0] = F(1, 2)
P5[5][5] = F(1)
# 期望首达 E_s：E_s = 1 + (E_{s+1} + E_0)/2, E_5 = 0；闭式 E_s = 2^6 − 2^{s+1}
E = [F(2 ** 6 - 2 ** (s + 1)) for s in range(5)] + [F(0)]
for s in range(5):
    assert E[s] == 1 + (E[s + 1] + E[0]) / 2
assert E[0] == 62
# P(n 步内已吸收) 与旧补事件递推 b_n = Σ b_{n-k}/2^k 对账
b = [F(1)] * 5
for n in range(5, 101):
    b.append(sum(b[n - k] / 2 ** k for k in range(1, 6)))
M = [[F(0)] * S for _ in range(S)]
M = matpow(P5, 100)
assert M[0][5] == 1 - b[100]
assert float(M[0][5]) > 0.81 and float(M[0][5]) < 0.82
print("5-run chain: E[T]=62, P(absorbed by 100) = 1 - b_100 = 81.01%: OK")

# ⑥ Leslie 矩阵
lam_s = sp.symbols("lam")
A = sp.Matrix([[0, 2, 1, 0, 0], [1, 0, 0, 0, 0], [0, 1, 0, 0, 0], [0, 0, 1, 0, 0], [0, 0, 0, 1, 0]])
cp = sp.factor(A.charpoly(lam_s).as_expr())
assert sp.expand(cp - lam_s ** 2 * (lam_s + 1) * (lam_s ** 2 - lam_s - 1)) == 0
phi = (1 + sp.sqrt(5)) / 2
assert sp.simplify(phi ** 2 - phi - 1) == 0
Fm = sp.Matrix([[1, 1], [1, 0]])
fibs = [0, 1]
for _ in range(40):
    fibs.append(fibs[-1] + fibs[-2])
assert all((Fm ** n)[0, 1] == fibs[n] for n in (5, 10, 30))      # [[1,1],[1,0]]ⁿ = [[F_{n+1},F_n],[F_n,F_{n-1}]]
print("Leslie charpoly = lam^2 (lam+1)(lam^2-lam-1); dominant eigenvalue phi; Fibonacci power: OK")

# ⑦ 遍历均值方差：f = 1{state 0}，Var(S_n)=Σ γ0 λ^{|i−j|}，n·Var(S_n/n)→γ0(1+λ)/(1−λ)
g0 = pi2[0] * pi2[1]                                  # 6/25（iid 同方差）
sig2 = g0 * (1 + lam) / (1 - lam)
assert sig2 == F(18, 25)
n = 400
var_sn = sum(g0 * lam ** abs(i - j) for i in range(n) for j in range(n))
assert abs(var_sn / n - sig2) < F(1, 100)
assert sig2 == 3 * g0                                  # 相关性使遍历均值方差放大 3 倍
print("ergodic-mean asymptotic variance 18/25 = 3 * (iid 6/25): OK")
print("END ====")
