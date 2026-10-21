# -*- coding: utf-8 -*-
print("==== 21 clt")
# 第 21 章 Python：CLT 的数值账。
# ① Poisson 特例的 MGF 账：M_{Z_λ}(t) → e^{t²/2}；② (1+t²/2N)^N
#    → e^{t²/2}；③ 三族模拟的标准化和 vs φ；④ 连续性修正的精度；
# ⑤ Berry–Esseen 式误差表（最大偏差 vs n）。
from math import exp, pi, sqrt


def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3


# ① Poisson 特例：M_{Z_λ}(t) = exp(λ(e^{t/√λ} − 1) − t√λ) → e^{t²/2}
for t in (0.5, 1.0):
    target = exp(t * t / 2)
    v5 = exp(5 * (exp(t / sqrt(5)) - 1) - t * sqrt(5))
    v50 = exp(50 * (exp(t / sqrt(50)) - 1) - t * sqrt(50))
    v500 = exp(500 * (exp(t / sqrt(500)) - 1) - t * sqrt(500))
    assert abs(v5 - target) > abs(v50 - target) > abs(v500 - target)
    assert abs(v500 - target) < 0.02
print("poisson mgf: M_{Z_lam}(t) -> e^{t^2/2} monotonically in lam: OK")

# ② (1 + t²/2N + O(N^-3/2))^N → e^{t²/2}
for t in (0.5, 1.0):
    target = exp(t * t / 2)
    v10 = (1 + t * t / 20) ** 10
    v100 = (1 + t * t / 200) ** 100
    v10k = (1 + t * t / 20000) ** 10000
    assert abs(v10 - target) > abs(v100 - target) > abs(v10k - target)
    assert abs(v10k - target) < 1e-4
print("(1+t^2/2N)^N -> e^{t^2/2}: OK")

# ③ 三族模拟：标准化和 vs φ 密度（分桶）
import random as _r
_r.seed(21)
phi = lambda x: exp(-x * x / 2) / sqrt(2 * pi)
for (name, sampler, mu, sig) in [
        ("uniform", lambda: _r.random(), 0.5, sqrt(1 / 12)),
        ("exponential", lambda: -_r.expovariate(1.0), -1.0, 1.0),
        ("die", lambda: float(_r.randint(1, 6)), 3.5, sqrt(35 / 12))]:
    n = 200 if name != "uniform" else 50              # 偏态/格点族要更大 n（Berry–Esseen）
    reps = 60_000
    Z = []
    for _ in range(reps):
        s = sum(sampler() for _ in range(n))
        Z.append((s - n * mu) / (sig * sqrt(n)))
    for (lo, hi) in [(-1.0, -0.5), (-0.5, 0.0), (0.0, 0.5), (0.5, 1.0)]:
        emp = sum(1 for z in Z if lo <= z < hi) / reps
        theo = simpson(phi, lo, hi, 400)
        assert abs(emp - theo) < 0.015, (name, lo, emp, theo)   # 含格点/形状残差
print("CLT three families: standardized sums match phi buckets: OK")

# ④ 连续性修正：Bin(100, 0.5) 的 P(45 <= S <= 55)
from math import comb
exact = sum(comb(100, k) for k in range(45, 56)) / 2 ** 100
Phi = lambda x: simpson(phi, -10, x, 4000)
mu, sig = 50.0, 5.0
no_corr = Phi((55 - mu) / sig) - Phi((45 - mu) / sig)
with_corr = Phi((55.5 - mu) / sig) - Phi((44.5 - mu) / sig)
assert abs(with_corr - exact) < abs(no_corr - exact)     # 修正更好
assert abs(with_corr - exact) < 0.002
print("continuity correction: corrected normal beats raw (exact ",
      round(exact, 5), "): OK", sep="")

# ⑤ 误差表：指数族的最大桶偏差 vs n（~ n^{-1/2} 衰减）
prev = None
for n in (10, 40, 160):
    reps = 30_000
    Z = []
    for _ in range(reps):
        s = sum(-_r.expovariate(1.0) for _ in range(n))
        Z.append((s + n) / sqrt(n))                       # 标准化（μ=−1, σ=1）
    err = max(abs(sum(1 for z in Z if lo <= z < hi) / reps - simpson(phi, lo, hi, 400))
              for (lo, hi) in [(-1.5, -1.0), (-0.5, 0.0), (0.0, 0.5), (1.0, 1.5)])
    if prev is not None:
        assert err < prev                                  # 单调改善
    prev = err
print("error table: max bucket deviation shrinks with n: OK")

print("END ====")
