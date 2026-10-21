# -*- coding: utf-8 -*-
print("==== 22 fourier_clt")
# 第 22 章 Python：特征函数与 CLT。
# ① φ 的数值积分 vs 闭式表（正态/均匀/Cauchy）；② |φ| ≤ 1；
# ③ CLT 的 φ 收敛现场（三族 φ_{Z_N} vs e^{−t²/2}）；④ Cauchy
#    稳定的 φ 账；⑤ 卷积定理数值验证（密度卷积的 φ vs 乘积）。
from math import cos, exp, pi, sin, sqrt


def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3


# ① 特征函数 φ(t) = E[e^{itX}] = ∫cos(tx)f(x)dx（虚部：对称密度为零）
phi_num = lambda t, f: simpson(lambda x: cos(t * x) * f(x),
                               -12, 12, 4000)

phi_norm_closed = lambda t: exp(-t * t / 2)
pdf_norm = lambda x: exp(-x * x / 2) / sqrt(2 * pi)

# Unif(0,1)：φ(t) = e^{it/2}·sinc(t/2)，|φ| = |sin(t/2)/(t/2)|
def phi_unif_abs(t):
    if t == 0:
        return 1.0
    h = t / 2
    return abs(sin(h) / h)

# ② |φ| ≤ 1 与闭式对拍
for t in (0.3, 1.0, 2.5):
    num = phi_num(t, pdf_norm)
    assert abs(num - phi_norm_closed(t)) < 1e-9
    assert abs(num) <= 1
    assert abs(phi_unif_abs(t)) <= 1
print("phi closed forms: normal e^{-t^2/2} exact, |phi| <= 1: OK")

# Cauchy：φ(t) = e^{−|t|}（模拟估计：柯西无矩但 φ 有界可估）
import random as _r
_r.seed(22)
for t in (0.5, 1.5):
    n = 400_000
    from math import tan
    cs = sum(cos(t * tan(pi * (_r.random() - 0.5)))
             for _ in range(n)) / n
    # 虚部期望为 0（对称），实部 → e^{−|t|}（收敛慢：容差放宽）
    assert abs(cs - exp(-abs(t))) < 0.01
print("cauchy phi(t) = e^{-|t|} by Monte Carlo (real part): OK")

# ③ CLT 的 φ 收敛：φ_{Z_N}(t) = [φ_Y(t/√N)]^N → e^{−t²/2}
import cmath
for (name, mu, sig, sampler) in [
        ("uniform", 0.5, sqrt(1 / 12), lambda: _r.random()),
        ("exponential", -1.0, 1.0, lambda: -_r.expovariate(1.0))]:
    for t in (0.5, 1.0):
        target = exp(-t * t / 2)
        for N in (10, 1000):
            n = 60_000
            acc = 0j
            for _ in range(n):
                s = sum(sampler() for _ in range(N))
                z = (s - N * mu) / (sig * sqrt(N))
                acc += cmath.exp(1j * t * z)
            val = (acc / n)
            if N == 1000:
                assert abs(val - target) < 0.02, (name, t, val)
print("CLT phi convergence: phi_{Z_1000}(t) -> e^{-t^2/2} (MC): OK")

# ④ Cauchy 稳定的 φ 账：(e^{−|t|})² = e^{−2|t|} = φ_{2×Cauchy}
for t in (0.7, 2.0):
    lhs = exp(-abs(t)) ** 2
    rhs = exp(-2 * abs(t))
    assert abs(lhs - rhs) < 1e-12
# 和的一半仍 Cauchy：(X+Y)/2 的 φ = φ(t/2)²·... = e^{-|t|}
for t in (0.7, 2.0):
    phi_half = exp(-abs(t / 2)) ** 2
    assert abs(phi_half - exp(-abs(t))) < 1e-12
print("cauchy stability: phi((X+Y)/2) = e^{-|t|} = phi(X): OK")

# ⑤ 卷积定理数值验证：Unif(0,1)∗Unif(0,1)（三角形）的 φ
#    = [φ_Unif]²（以 |φ| 对照，t 选使虚部为零处）
tri = lambda x: x if 0 <= x <= 1 else (2 - x if 1 < x <= 2 else 0.0)
for t in (0.8, 1.6):
    lhs = simpson(lambda x: cos(t * x) * tri(x), 0, 2, 4000)
    # 均匀的复 φ：e^{it/2}sinc(t/2)；平方的实部
    h = t / 2
    sinc = sin(h) / h
    rhs = sinc ** 2                  # |e^{it/2}sinc|² 的实部 = cos(t)·sinc²?
    # 精确：φ_U(t) = e^{it/2}sinc(t/2)；φ_U² = e^{it}sinc²；实部 = cos(t)·sinc²
    rhs = cos(t) * sinc ** 2
    assert abs(lhs - rhs) < 1e-9
print("convolution theorem: phi_{Unif*Unif} = phi_Unif^2 (real parts): OK")

print("END ====")
