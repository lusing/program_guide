print("==== 24 laplace")

# 第 24 章：Laplace 变换（scipy 对照版）。
import math
from scipy.integrate import quad
from scipy.integrate import solve_ivp

# (a) 数值 Laplace（自适应积分）
def laplace_num(f, s):
    val, _ = quad(lambda t: math.exp(-s * t) * f(t), 0, 60, limit=200)
    return val

for f, F, s in [(lambda t: 1.0, lambda s: 1 / s, 2.0),
                (lambda t: t**2, lambda s: 2 / s**3, 1.5),
                (lambda t: math.exp(-t), lambda s: 1 / (s + 1), 2.0),
                (lambda t: math.sin(2 * t), lambda s: 2 / (s**2 + 4), 1.2)]:
    num = laplace_num(f, s)
    assert abs(num - F(s)) / F(s) < 1e-8
print("numerical Laplace matches table for 1, t^2, e^-t, sin 2t")

# (b) 例 A：共振 y'' + 4y = cos 2t → y = t sin2t / 4
sol = solve_ivp(lambda t, u: [u[1], math.cos(2 * t) - 4 * u[0]], [0, 10],
                [0.0, 0.0], rtol=1e-11, atol=1e-13)
assert abs(sol.y[0, -1] - 10 * math.sin(20) / 4) < 1e-6
print("resonance: y = t sin(2t)/4 confirmed by solve_ivp")

# (c) 例 B：y'' + 3y' + 2y = 1 → y = 1/2 - e^-t + e^-2t/2
ysol = lambda t: 0.5 - math.exp(-t) + math.exp(-2 * t) / 2
for tt in [0.3, 1.7, 4.0]:
    h = 1e-5
    ypp = (ysol(tt + h) - 2 * ysol(tt) + ysol(tt - h)) / h**2
    yp = (ysol(tt + h) - ysol(tt - h)) / (2 * h)
    assert abs(ypp + 3 * yp + 2 * ysol(tt) - 1.0) < 1e-4
assert ysol(0.0) == 0.0
print("ex B: y = 1/2 - e^-t + e^-2t/2 satisfies zero-IC problem")

# (d) 卷积定理：(e^-t * t)(t) = t - 1 + e^-t，变换 = 1/(s^2(s+1))
convf = lambda t: t - 1 + math.exp(-t)
for s in [1.3, 2.0]:
    num = laplace_num(convf, s)
    assert abs(num - 1 / (s**2 * (s + 1))) / (1 / (s**2 * (s + 1))) < 1e-8
print("convolution theorem: L{e^-t * t} = F*G verified at two points")

print("END ====")
