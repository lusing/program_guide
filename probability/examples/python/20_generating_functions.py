# -*- coding: utf-8 -*-
print("==== 20 generating_functions")
# 第 20 章 Python：母函数的精确账。
# ① Fibonacci 母函数系数恢复（s/(1−s−s²) 长除法 vs 递推）；
# ② Binet 公式的整数性；③ 泊松卷积定理（枚举卷积 vs
#    Pois(12) pmf）；④ 二项 (q+ps)³ 展开系数 vs 8 格枚举；
# ⑤ MGF 数值积分 vs 闭式（正态/指数）；⑥ 矩读取（数值微分）。
from math import comb, exp, factorial, pi, sqrt


# ① 长除法恢复系数：G(s) = s/(1−s−s²) ⟹ a_n = a_{n-1} + a_{n-2}·（母函数即递推）
def gf_coeffs(n_terms):
    # 1/(1−s−s²) 的系数满足 c_n = c_{n-1} + c_{n-2}，c_0 = 1, c_1 = 1
    c = [0] * (n_terms + 1)
    c[0], c[1] = 1, 1
    for k in range(2, n_terms + 1):
        c[k] = c[k - 1] + c[k - 2]
    return c


fib = [0, 1]
for _ in range(60):
    fib.append(fib[-1] + fib[-2])
coeffs = gf_coeffs(29)
assert all(fib[n] == coeffs[n - 1] for n in range(1, 30))   # s·(1/(1−s−s²)) 位移
print("gf coefficient recovery = fibonacci (shift by s): OK")

# ② Binet：round(φⁿ/√5) = Fₙ（|B|ⁿ/√5 < 1/2 的余项）
phi = (1 + sqrt(5)) / 2
for n in (10, 30, 50):
    assert round(phi ** n / sqrt(5)) == fib[n]
print("binet: round(phi^n/sqrt(5)) = F_n exactly: OK")

# ③ 泊松卷积定理：Pois(5)+Pois(7) = Pois(12)（截断 60 项）


def pois_pmf(lam, k):
    return lam ** k * exp(-lam) / factorial(k)


for k in range(0, 25):
    conv = sum(pois_pmf(5, l) * pois_pmf(7, k - l) for l in range(0, k + 1))
    assert abs(conv - pois_pmf(12, k)) < 1e-12
print("poisson convolution: enumerative sum = pois(12) pmf exactly: OK")

# ④ 二项：Bin(3, 1/2) 的 (q+ps)³ 展开系数 vs 8 串枚举
from itertools import product
for k in range(4):
    enum = sum(1 for s in product("HT", repeat=3) if s.count("H") == k)
    assert enum == comb(3, k)                     # 系数 = C(3,k)
print("binomial (q+ps)^3 coefficients = 8-string enumeration: OK")

# ⑤ MGF 数值验证：正态 e^{t²/2}、指数 1/(1−λt)


def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3


phi_pdf = lambda x: exp(-x * x / 2) / sqrt(2 * pi)
for t in (0.3, 0.7, 1.1):
    num = simpson(lambda x: exp(t * x) * phi_pdf(x), -10, 10, 4000)
    assert abs(num - exp(t * t / 2)) < 1e-9
for t in (0.2, 0.5):
    num = simpson(lambda x: exp(t * x) * exp(-x), 0, 60, 4000)
    assert abs(num - 1 / (1 - t)) < 1e-9          # Exp(1) 的 MGF
print("mgf closed forms: normal e^{t^2/2}, exp 1/(1-t): OK")

# ⑥ 矩读取：M'(0) = μ、M''(0) = E[X²]（中心差分数值微分）
h = 1e-5
for (name, mgf, mu1, mu2) in [
        ("normal", lambda t: exp(t * t / 2), 0.0, 1.0),
        ("exp", lambda t: 1 / (1 - t), 1.0, 2.0)]:
    m1 = (mgf(h) - mgf(-h)) / (2 * h)
    m2 = (mgf(h) - 2 * mgf(0.0) + mgf(-h)) / h ** 2
    assert abs(m1 - mu1) < 1e-4 and abs(m2 - mu2) < 1e-3
print("moment extraction: M'(0)=mu, M''(0)=E[X^2] for normal/exp: OK")

print("END ====")
