print("==== 23 series")

# 第 23 章：幂级数（scipy.special.airy 对照版）。
import math
from fractions import Fraction
from scipy.integrate import solve_ivp
from scipy.special import airy

# (a) Airy 递推：(n+2)(n+1) a_{n+2} = a_{n-1}（精确有理数）
def airy_coeffs(N, a0, a1):
    a = [Fraction(0)] * (N + 1)
    a[0], a[1] = Fraction(a0), Fraction(a1)
    for n in range(1, N - 1):
        src = a0 if n == 1 else (a1 if n == 2 else a[n - 1])
        a[n + 2] = Fraction(src) / ((n + 2) * (n + 1))
    return a

a = airy_coeffs(8, 1, 0)
assert a[0] == 1 and a[3] == Fraction(1, 6) and a[6] == Fraction(1, 180)
b = airy_coeffs(8, 0, 1)
assert b[1] == 1 and b[4] == Fraction(1, 12)
print("Airy recurrence: a3 = 1/6, a6 = 1/180, a4 = 1/12 (exact rationals)")

# (b) 与 scipy.special.airy 对照（构造 Ai 组合）
def airy_part(x, a0, a1, N=20):
    a = airy_coeffs(N, a0, a1)
    return sum(float(a[n]) * x**n for n in range(N + 1))

# a0 支 = c1·Ai + c2·Bi：解出 c（用 Ai(0), Ai'(0), Bi(0), Bi'(0)）
Ai0, Aip0, Bi0, Bip0 = airy(0)[0], airy(0)[1], airy(0)[2], airy(0)[3]
# y(0) = 1, y'(0) = 0
det = Ai0 * Bip0 - Bi0 * Aip0
c1 = (1 * Bip0 - 0 * Bi0) / det
c2 = (Ai0 * 0 - Aip0 * 1) / det
sol = solve_ivp(lambda x, u: [u[1], x * u[0]], [0, 1.5], [1.0, 0.0], rtol=1e-12, atol=1e-12)
assert abs(airy_part(1.5, 1.0, 0.0) - sol.y[0, -1]) < 1e-8
assert abs((c1 * airy(1.5)[0] + c2 * airy(1.5)[2]) - sol.y[0, -1]) < 1e-10
print("series (20 terms) vs solve_ivp vs scipy.special.airy all agree at x = 1.5")

# (c) Frobenius 指标：k(k-1) + 4k - 4 = (k-1)(k+4)
for k in [1.0, -4.0]:
    assert abs(k * (k - 1) + 4 * k - 4) < 1e-12
print("indicial equation roots 1 and -4 confirmed")

# (d) 常点递推重造三角函数
def trig_coeffs(N, a0, a1):
    c = [0.0] * (N + 1)
    c[0], c[1] = a0, a1
    for n in range(N - 1):
        c[n + 2] = -c[n] / ((n + 2) * (n + 1))
    return c

cc = trig_coeffs(10, 1.0, 0.0)
assert cc[0] == 1 and cc[2] == -0.5 and abs(cc[4] - 1 / 24) < 1e-15
ss = trig_coeffs(10, 0.0, 1.0)
assert ss[1] == 1 and ss[3] == -1 / 6 and abs(ss[5] - 1 / 120) < 1e-15
print("y''+y=0 recurrence reinvents cos (a0 branch) and sin (a1 branch)")

print("END ====")
