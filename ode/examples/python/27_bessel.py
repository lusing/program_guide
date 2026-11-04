print("==== 27 bessel")

# 第 27 章：Γ 与 Bessel（scipy.special 主场）。
import math
from fractions import Fraction
from scipy.special import gamma as G, gammaln, jv, jn_zeros, iv, kv, airy, ellipk
from scipy.optimize import brentq

# (a) Γ 函数
for n in range(1, 9):
    assert abs(G(n + 1) - math.factorial(n)) < 1e-9
assert abs(G(0.5) - math.sqrt(math.pi)) < 1e-12
for z in [0.3, 1.7, 2.5]:
    lhs = G(z) * G(1 - z)
    rhs = math.pi / math.sin(math.pi * z)
    assert abs(lhs - rhs) / rhs < 1e-12
print("Gamma: (n+1) = n!, Gamma(1/2) = sqrt(pi), reflection formula verified")

# (b) J_nu 级数 vs scipy
def jnu_series(nu, x, N=25):
    s = 0.0
    for k in range(N + 1):
        s += (-1)**k * (x / 2)**(2 * k + nu) / (math.factorial(k) * G(k + nu + 1))
    return s
for nu in [0.0, 1.0, 2.5]:
    for x in [0.5, 2.0, 5.0]:
        assert abs(jnu_series(nu, x) - jv(nu, x)) < 1e-10
print("Frobenius series for J_nu matches scipy.special.jv (nu = 0, 1, 2.5)")

# (c) J0 零点 + 相邻差 -> pi
z = jn_zeros(0, 6)
assert abs(z[0] - 2.4048255577) < 1e-8
gaps = [z[i+1] - z[i] for i in range(5)]
assert gaps[-1] > 3.10 and gaps[-1] < 3.16
print(f"J0 zeros: {z.round(4)} (first 2.4048, gaps -> pi)")

# (d) 大 x 渐近：J_nu ~ sqrt(2/pi x) cos(x - nu pi/2 - pi/4) 的包络
for nu in [0.0, 0.5]:
    for x in [50.0, 100.0]:
        env = math.sqrt(2 / (math.pi * x))
        phase = x - nu * math.pi / 2 - math.pi / 4
        approx = env * math.cos(phase)
        assert abs(jv(nu, x) - approx) / env < 0.02
print("asymptotic envelope/phase of J_nu accurate to 2% at x = 50, 100")

# (e) 递推 J_{nu-1} + J_{nu+1} = (2 nu/x) J_nu
for nu, x in [(1.0, 2.3), (2.5, 3.7), (4.0, 6.0)]:
    assert abs(jv(nu - 1, x) + jv(nu + 1, x) - 2 * nu / x * jv(nu, x)) < 1e-10
print("recurrence J_{n-1} + J_{n+1} = (2n/x) J_n verified")

# (f) 修改 Bessel：I 单调增、K 单调减（x > 0）
for x in [0.5, 1.0, 2.0]:
    assert iv(0, x + 0.1) > iv(0, x) and kv(0, x + 0.1) < kv(0, x)
print("modified Bessel: I0 increasing, K0 decreasing")

# (g) Airy：Ai(2) 级数（Ai 是 a1 支组合）——用 scipy 自身对照递推生成的级数
ai2, _, _, _ = airy(2)
# 级数初值 Ai(0) = 3^{-2/3}/Gamma(2/3), Ai'(0) = -3^{-1/3}/Gamma(1/3)
a0 = 3**(-2.0/3) / G(2.0/3)
a1 = -3**(-1.0/3) / G(1.0/3)
def airy_part(x, N=25):
    a = [0.0] * (N + 1)
    a[0], a[1] = a0, a1
    for n in range(1, N - 1):
        src = a0 if n == 1 else (a1 if n == 2 else a[n - 1])
        a[n + 2] = src / ((n + 2) * (n + 1))
    return sum(a[n] * x**n for n in range(N + 1))
assert abs(airy_part(2.0) - ai2) < 1e-10
print("Airy: Frobenius series (25 terms) matches scipy.special.airy at x = 2")

print("END ====")
