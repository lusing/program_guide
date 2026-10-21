# -*- coding: utf-8 -*-
print("==== 16 gamma")
# 第 16 章 Python：Γ 函数的数值账。
# ① Γ(s) 的 Simpson 积分表 s=1..8 vs (s−1)!；② Γ(1/2) 族
#    vs √π 系；③ 函数方程数值链；④ Beta 基本关系；⑤ 余割
#    恒等式；⑥ Gamma(k,σ) 密度归一与矩。
from math import exp, factorial, pi, sin, sqrt


def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 else 2) * f(a + i * h)
    return s * h / 3


def gamma_num(s, n=20000, B=60.0):
    """∫₀^∞ e^{−x}x^{s−1}dx：(0,1] 段用 x = t^m 代换吸收 0 端
    爆破（m·s ≥ 1 使被积光滑），[1,B] 段朴素 Simpson。"""
    from math import ceil
    m = max(2, ceil(1 / s)) if s < 1 else 1
    if s < 1:
        low = simpson(lambda t: m * t ** (m * s - 1) * exp(-t ** m), 0, 1, n // 2)
    else:
        low = simpson(lambda t: exp(-t) * t ** (s - 1), 1e-9, 1, n // 2)
    high = simpson(lambda t: exp(-t) * t ** (s - 1), 1, B, n)
    return low + high


# ① 整数点：Γ(n) = (n−1)!
for s in range(1, 9):
    g = gamma_num(s)
    assert abs(g - factorial(s - 1)) < 1e-4 * factorial(s - 1), (s, g)
print("gamma(s) for s=1..8 equals (s-1)!: OK")

# ② 半整数族：Γ(1/2)=√π、Γ(3/2)=√π/2、Γ(5/2)=3√π/4、Γ(7/2)=15√π/8
for s, val in [(0.5, sqrt(pi)), (1.5, sqrt(pi) / 2), (2.5, 3 * sqrt(pi) / 4),
               (3.5, 15 * sqrt(pi) / 8)]:
    g = gamma_num(s)
    assert abs(g - val) < 1e-4 * val, (s, g, val)
print("half-integer family: sqrt(pi), /2, *3/4, *15/8: OK")

# ③ 函数方程 Γ(s+1) = sΓ(s)（s = 0.5..5.5 连查）
for s in (0.5, 1.5, 2.5, 3.5, 4.5):
    lhs = gamma_num(s + 1)
    rhs = s * gamma_num(s)
    assert abs(lhs - rhs) < 1e-4 * rhs, s
print("functional equation gamma(s+1) = s*gamma(s): OK")

# ④ Beta 基本关系 B(a,b) = Γ(a)Γ(b)/Γ(a+b)
# B(1/2,1/2) 两端爆破：t = sin²θ 代换后被积恒为 2（∫₀^{π/2}2dθ = π）
for (a, b) in [(2.0, 3.0), (3.0, 5.0)]:
    B = simpson(lambda t: t ** (a - 1) * (1 - t) ** (b - 1), 1e-9, 1 - 1e-9, 4000)
    rhs = gamma_num(a) * gamma_num(b) / gamma_num(a + b)
    assert abs(B - rhs) < 2e-4 * rhs, (a, b)
B_half = simpson(lambda x: 2.0, 0, pi / 2, 1000)        # t = sin²x
rhs_half = gamma_num(0.5) * gamma_num(0.5) / gamma_num(1)
assert abs(B_half - rhs_half) < 2e-4 * rhs_half
# 特例：B(1,1) = 1、B(1/2,1/2) = π
assert abs(gamma_num(1) * gamma_num(1) / gamma_num(2) - 1) < 1e-6
assert abs(rhs_half - pi) < 2e-4
print("beta(a,b) = gamma product ratio; B(1/2,1/2)=pi: OK")

# ⑤ 余割恒等式 Γ(s)Γ(1−s) = π/sin(πs)
for s in (0.25, 1 / 3, 0.5):
    lhs = gamma_num(s) * gamma_num(1 - s)
    rhs = pi / sin(pi * s)
    assert abs(lhs - rhs) < 2e-4 * rhs, s
print("cosecant identity at s=1/4, 1/3, 1/2: OK")

# ⑥ Gamma(k,σ) 密度：归一与矩（k=2, σ=3 → μ=6, σ²=18）
k, sig = 2.0, 3.0
fk = lambda x: x ** (k - 1) * exp(-x / sig) / (gamma_num(k) * sig ** k)
assert abs(simpson(fk, 1e-9, 80, 20000) - 1) < 1e-4
assert abs(simpson(lambda x: x * fk(x), 1e-9, 80, 20000) - k * sig) < 5e-3
assert abs(simpson(lambda x: x * x * fk(x), 1e-9, 90, 20000)
           - ((k * sig) ** 2 + k * sig ** 2)) < 5e-3
print("gamma(k=2,sigma=3): normalized, mean 6, var 18: OK")

print("END ====")
