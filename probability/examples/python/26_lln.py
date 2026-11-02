# -*- coding: utf-8 -*-
print("==== 26 lln")
# 第 26 章 Python：大数定律。
# ① WLLN：Chebyshev 精确界 vs 二项精确尾（Fraction）；② 四阶矩 SLLN 的核心不等式 E[S_n^4]≤3n²M；
# ③ SLLN 样本路径（固定种子）；④ Monte Carlo 误差 1/√n（π 估计）；
# ⑤ Cauchy 样本均值不收敛（分布恒为 Cauchy）；⑥ 经验分布与 Glivenko–Cantelli；
# ⑦ Kolmogorov 不等式的精确核对（对称游走枚举）；⑧ 截断：Khinchin 证明中的 P(X_i≠Y_i)→0。
from fractions import Fraction as F
from math import comb, sqrt, pi, tan, atan
import numpy as np
from itertools import product

# ① Chebyshev：Bernoulli(1/2)，P(|X̄_n−1/2|≥ε) ≤ Var/(nε²)=1/(4nε²)；精确二项尾
def exact_tail(n, eps):
    tot = F(0)
    for k in range(n + 1):
        if abs(F(k, n) - F(1, 2)) >= eps:
            tot += F(comb(n, k), 2 ** n)
    return tot


eps = F(1, 10)
prev = F(1)
for n in (10, 50, 100, 400):
    t = exact_tail(n, eps)
    cheb = F(1, 4) / (n * eps * eps)
    assert t <= min(F(1), cheb)
    assert t < prev                                      # 随 n 增大严格减小
    prev = t
assert exact_tail(400, eps) < F(1, 10 ** 3) * 10         # 远小于 Chebyshev 的 0.0625
print("WLLN: exact binomial tails <= Chebyshev, decreasing in n: OK")

# ② 四阶矩：E[S_n^4] = n m4 + 3n(n−1) σ⁴ ≤ 3 n² M  (X 中心化、独立同分布，σ⁴≤m4=M)
# 以 X=±1 等概率精确枚举：m4=1, σ²=1 ⇒ E[S_n^4] = n + 3n(n−1) = 3n²−2n
for n in range(1, 13):
    tot = F(0)
    for signs in product((-1, 1), repeat=n):
        tot += F(sum(signs) ** 4, 2 ** n)
    assert tot == 3 * n * n - 2 * n
    assert tot <= 3 * n * n
# 由 Markov：P(|S_n/n|>ε) ≤ E[S_n^4]/(n⁴ε⁴) ≤ 3/(n²ε⁴)，Σ_n 3/n² < ∞，BC 给出 SLLN
assert sum(F(3, n * n) for n in range(1, 2000)) < 3 * 2
print("4th-moment bound E[S_n^4] = 3n^2 - 2n <= 3 n^2 (enumerated): OK")

# ③ SLLN 路径：Exp(1) 样本均值，若干条路径在 n=10⁵ 时都贴近 1，且 sup_{m≥n}|X̄_m−1| 随 n 缩小
rng = np.random.default_rng(2026)
paths = rng.exponential(1.0, size=(8, 100000))
means = np.cumsum(paths, axis=1) / np.arange(1, 100001)
assert np.all(np.abs(means[:, -1] - 1) < 0.02)
dev = np.abs(means - 1)
sup_tail = np.maximum.accumulate(dev[:, ::-1], axis=1)[:, ::-1]   # sup_{m≥n}
assert sup_tail[:, 1000].max() > sup_tail[:, 50000].max()
print("SLLN paths: all 8 paths within 0.02 of 1 at n=1e5; tail sup shrinks: OK")

# ④ Monte Carlo：π≈4·mean(1{x²+y²≤1})，标准误差 σ/√n 其中 σ²=p(1−p)·16
p = pi / 4
sig = 4 * sqrt(p * (1 - p))
errs = {}
for n in (100, 10000, 1000000):
    reps = 200 if n < 1000000 else 40
    est = np.array([4 * np.mean((lambda u: u[:, 0] ** 2 + u[:, 1] ** 2 <= 1)(rng.random((n, 2)))) for _ in range(reps)])
    rmse = sqrt(np.mean((est - pi) ** 2))
    errs[n] = rmse
    assert 0.6 * sig / sqrt(n) < rmse < 1.5 * sig / sqrt(n)
assert errs[100] / errs[10000] > 5 and errs[10000] / errs[1000000] > 5   # 百倍样本 → 约十倍精度
print("Monte Carlo pi: RMSE ~ sigma/sqrt(n), 100x samples -> ~10x accuracy: OK")

# ⑤ Cauchy：X̄_n 与 X_1 同分布（CF 论证），故 P(|X̄_n|>1)=1/2 对所有 n
c = rng.standard_cauchy(size=(2000, 1000))
m10 = c[:, :10].mean(axis=1)
m1000 = c.mean(axis=1)
p10 = np.mean(np.abs(m10) > 1)
p1000 = np.mean(np.abs(m1000) > 1)
assert abs(p10 - 0.5) < 0.05 and abs(p1000 - 0.5) < 0.05
assert abs(2 * (1 - (0.5 + atan(1) / pi)) - 0.5) < 1e-12            # P(|C|>1)=1/2 的理论值
print("Cauchy: P(|mean|>1) ~ 1/2 for n=10 and n=1000 (no LLN): OK")

# ⑥ Glivenko–Cantelli：sup|F_n−F| = D_n，U(0,1) 样本，D_n·√n 保持 O(1)，D_n→0
dn = {}
for n in (50, 500, 5000, 50000):
    ds = []
    for _ in range(40):
        x = np.sort(rng.random(n))
        i = np.arange(1, n + 1)
        ds.append(max(np.max(i / n - x), np.max(x - (i - 1) / n)))
    dn[n] = np.mean(ds)
    assert dn[n] * sqrt(n) < 2.0
assert dn[50] > dn[500] > dn[5000] > dn[50000]
print("Glivenko-Cantelli: E D_n shrinks, sqrt(n) D_n bounded: OK")

# ⑦ Kolmogorov 不等式：简单对称游走，P(max_{k≤n}|S_k|≥λ) ≤ Var(S_n)/λ² = n/λ²，精确枚举
for n, lam in ((10, 5), (12, 6), (14, 5)):
    cnt = 0
    for signs in product((-1, 1), repeat=n):
        s, mx = 0, 0
        for e in signs:
            s += e
            mx = max(mx, abs(s))
        cnt += mx >= lam
    prob = F(cnt, 2 ** n)
    assert prob <= F(n, lam * lam)
    # 反射原理给出 max 型概率 ≥ 端点概率：P(max≥λ) ≥ P(|S_n|≥λ)
    endp = sum(F(comb(n, k), 2 ** n) for k in range(n + 1) if abs(2 * k - n) >= lam)
    assert prob >= endp
print("Kolmogorov inequality (exact enumeration): OK")

# ⑧ 截断：Y_i=X_i 1{|X_i|≤i}，对 Pareto(α=1.5, x_m=1) (E X=3)，Σ P(X_i≠Y_i)=Σ i^{-α}… 发散不能用 BC，
#     但 E|X|<∞ 保证 Σ P(|X|>i) ≤ E|X| < ∞；这里数值核对 Σ_i P(|X|>i)=E[floor(X)] ≤ E X
alpha = 1.5
EX = alpha / (alpha - 1)
tail_sum = sum(i ** (-alpha) for i in range(1, 2 * 10 ** 6))
assert tail_sum <= EX                                   # ζ(1.5)=2.612 ≤ 3
print("truncation: sum_i P(|X|>i) = 2.61.. <= E|X| = 3: OK")
print("END ====")
