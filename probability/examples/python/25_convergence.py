# -*- coding: utf-8 -*-
print("==== 25 convergence")
# 第 25 章 Python：收敛模式的反例账。
# ① 移动区间（typewriter）：依概率、L^p 收敛，但处处不收敛（指标精确计算）；
# ② 尖峰序列 Z_n=e^n 1{s>1-n^{-2}}：几乎处处、依概率收敛，但 E Z_n→∞（BC 引理）；
# ③ 独立 Bernoulli(1/n)：依概率 → 0 但不几乎处处（第二 BC，精确乘积）；
# ④ 子列定理：从依概率收敛抽出几乎处处收敛的子列；
# ⑤ 依分布：N(0,1/n) 的 CDF 在不连续点 0 处极限 1/2≠F(0)；常数目标的等价；
#    Z_n=-X 依分布收敛但不依概率收敛；
# ⑥ 一致可积：Z_n=n·1{U<1/n}；
# ⑦ Skorokhod 分位数耦合与连续映射；Portmanteau 数值核对；
# ⑧ n(θ−max) → Exp(θ)（极限分布）。
from fractions import Fraction as F
from math import floor, log2, exp, erf, sqrt, log, comb, factorial
import math
import random

# ① 移动区间
def typewriter(n):
    k = int(floor(log2(n)))
    i = n - 2 ** k
    return F(i, 2 ** k), F(i + 1, 2 ** k), k


def Z(n, s):
    lo, hi, _ = typewriter(n)
    return 1 if lo <= s <= hi else 0


for n in range(1, 2 ** 8):
    lo, hi, k = typewriter(n)
    assert hi - lo == F(1, 2 ** k)                      # P(Z_n=1)=2^{-k} → 0 ⇒ 依概率
    assert F(1, 2 ** k) ** 1 == hi - lo                  # E|Z_n|^p = 2^{-k} → 0 ⇒ L^p
for s in [F(0), F(1, 3), F(2, 3), F(5, 7), F(1)]:
    for K in range(0, 12):
        hits = [n for n in range(2 ** K, 2 ** (K + 1)) if Z(n, s) == 1]
        assert len(hits) >= 1                            # 每层至少命中一次 ⇒ Z_n(s)=1 无穷多次
    # 同时 Z_n(s)=0 也无穷多次（每层区间长 2^-K<1，另有不含 s 的区间）
    for K in range(1, 12):
        misses = [n for n in range(2 ** K, 2 ** (K + 1)) if Z(n, s) == 0]
        assert len(misses) >= 1
print("typewriter: P,Lp -> 0 but limsup=1, liminf=0 at every s: OK")

# ② 尖峰序列
def spike_prob(n):
    return F(1, n * n)                                   # P(Z_n≠0)=n^{-2}


assert sum(1.0 / (n * n) for n in range(1, 200001)) < math.pi ** 2 / 6 + 1e-12
# BC 尾界：P(存在 n≥m 使 Z_n≠0) ≤ Σ_{n≥m} n^{-2} ≤ 1/(m−1)（望远：1/n² ≤ 1/(n−1) − 1/n）
for m in (2, 10, 100, 1000):
    tail = sum(1.0 / (n * n) for n in range(m, 200000))
    assert tail <= 1.0 / (m - 1)
# 精确：P(n≥m 全为 0) 对 Z_n 的 [0,1] 版本：事件 {s>1−n^{-2}} 单调嵌套 ⇒ P(∪_{n≥m})=m^{-2}
for m in (2, 5, 20):
    assert max(spike_prob(n) for n in range(m, 500)) == F(1, m * m)
# E Z_n = e^n/n^2 → ∞（不 L¹），而 P(|Z_n|>ε) = n^{-2} → 0
assert exp(30) / 900 > 1e10 and exp(50) / 2500 > exp(30) / 900
print("spike: sum P(Z_n!=0)<inf (BC) => a.s.; E Z_n = e^n/n^2 -> inf: OK")

# ③ 独立 Bernoulli(1/n)
for m in (2, 5, 10):
    for N in (m, 50, 400):
        prod = F(1)
        for n in range(m, N + 1):
            prod *= 1 - F(1, n)
        assert prod == F(m - 1, N)                       # P(m..N 全无事件)=(m−1)/N → 0（N→∞）
assert sum(F(1, n) for n in range(1, 2000)) > 7          # 调和级数发散
print("independent Bern(1/n): P(no event in [m,N]) = (m-1)/N -> 0, so infinitely many events a.s.: OK")

# ④ 子列：对 typewriter 取 n_j=2^j，指标 [0,2^{-j}]，ΣP=Σ2^{-j}<∞ ⇒ a.s. → 0
sub = [2 ** j for j in range(0, 14)]
assert sum(F(1, 2 ** j) for j in range(1, 40)) < 1
for s in (F(1, 7), F(3, 4), F(1)):
    vals = [Z(n, s) for n in sub]
    assert sum(vals[4:]) == 0                            # s>1/16 ⇒ 之后全为 0
# 通用构造：选 n_j 使 P(|Z_{n_j}|>1/j) < 2^{-j}
def choose_subsequence(prob_exceed, J):
    out, last = [], 0
    for j in range(1, J + 1):
        n = last + 1
        while prob_exceed(n, j) >= F(1, 2 ** j):
            n += 1
        out.append(n); last = n
    return out


nj = choose_subsequence(lambda n, j: F(1, 2 ** int(floor(log2(n)))), 6)
assert nj == sorted(nj) and len(set(nj)) == 6
print("subsequence extraction with summable tails: OK", nj)

# ⑤ 依分布
Phi = lambda x: 0.5 * (1 + erf(x / sqrt(2)))
for n in (1, 10, 100, 10 ** 4):
    assert abs(Phi(sqrt(n) * 0.0) - 0.5) < 1e-15        # F_n(0)=1/2 ∀n
    assert Phi(sqrt(n) * 0.5) >= 1 - 2 * exp(-n / 8)    # z>0 处 → 1
    assert Phi(-sqrt(n) * 0.5) <= 2 * exp(-n / 8)       # z<0 处 → 0
# 常数目标：Z_n=X/√n→d 0，同时 P(|Z_n|>ε)=2(1−Φ(ε√n)) → 0
for n in (4, 100, 2500):
    assert 2 * (1 - Phi(0.1 * sqrt(n))) <= 2 * (1 - Phi(0.2))
# Z_n=−X：分布不变 ⇒ →d X，但 |Z_n−X|=2|X|，P(2|X|>ε) 不趋于 0
eps = 0.5
p_far = 2 * (1 - Phi(eps / 2))
assert p_far > 0.8
print("distribution: F_n(0)=1/2 != F(0)=1; -X ->d X but not in probability: OK")

# ⑥ 一致可积：Z_n = n·1{U<1/n}
for n in (1, 10, 1000):
    assert n * F(1, n) == 1                              # E Z_n = 1 ∀n
for n in (10, 100, 1000):
    # E[Z_n 1{Z_n>M}] 对 M<n 恒为 1 ⇒ sup_n 不趋于 0 ⇒ 非一致可积
    M = 5
    tail = n * F(1, n) if n > M else F(0)
    assert tail == (1 if n > M else 0)
# 对照：Z_n=U^{1/n}... 简单有界族一致可积；L²-有界 ⇒ UI
assert all(F(1, n) <= F(1, 5) for n in range(5, 100))  # E[Z²]≤C ⇒ E[|Z|1{|Z|>M}] ≤ C/M
print("not UI: Z_n=n 1{U<1/n} has E=1 but Z_n -> 0 a.s.: OK")

# ⑦ Skorokhod 分位数耦合：F_n=Exp(rate 1+1/n)，F=Exp(1)；Z_n=F_n^{-1}(U)→Z=F^{-1}(U) 逐点
random.seed(7)
for _ in range(200):
    u = random.random()
    z = -log(1 - u)
    d = [abs(-log(1 - u) / (1 + 1 / n) - z) for n in (10, 100, 1000)]
    assert d[0] > d[1] > d[2] or z < 1e-12
    assert d[2] <= z / 1000 + 1e-12
# 连续映射：g(x)=x² 连续 ⇒ g(Z_n)→g(Z)；不连续点概率零的映射 g=1{x>0.5}
us = [random.random() for _ in range(2000)]
agree = sum(((-log(1 - u) / (1 + 1 / 10 ** 4)) > 0.5) == ((-log(1 - u)) > 0.5) for u in us)
assert agree / len(us) > 0.999
# Portmanteau：Bin(n,λ/n) → Poisson(λ)，对连续点集合 (−∞,k]、开集下界、闭集上界
lam_ = 2.0
pois = lambda k: math.exp(-lam_) * lam_ ** k / factorial(k)
def binom_pmf(n, k):
    p = lam_ / n
    return comb(n, k) * p ** k * (1 - p) ** (n - k)
errs = [max(abs(binom_pmf(n, k) - pois(k)) for k in range(0, 12)) for n in (10, 100, 1000)]
assert errs[0] > errs[1] > errs[2] and errs[2] < 2e-3
G = lambda n: sum(binom_pmf(n, k) for k in (0, 1, 2))   # P(Z_n∈{0,1,2}) → 闭集上界 limsup≤P(Z∈F)
assert abs(G(2000) - sum(pois(k) for k in (0, 1, 2))) < 1e-3
print("Skorokhod coupling pointwise; Portmanteau for Bin->Poisson: OK")

# ⑧ 极大值：n(θ−max U[0,θ]) → Exp(1/θ 的尺度：P(>x)=exp(−x/θ))
theta = 2.0
for n in (10, 100, 1000):
    for x in (0.5, 1.0, 3.0):
        exact = (1 - x / (n * theta)) ** n               # P(n(θ−M)>x)=P(M<θ−x/n)=(1−x/(nθ))^n
        assert abs(exact - exp(-x / theta)) < (x * x / theta ** 2) / n + 1e-12
print("n(theta - max) -> Exp: P(>x)=(1-x/(n theta))^n -> exp(-x/theta): OK")
print("END ====")
