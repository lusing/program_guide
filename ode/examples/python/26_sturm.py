print("==== 26 sturm")

# 第 26 章：Sturm-Liouville（scipy 对照版）。
import math
import numpy as np
from scipy.integrate import solve_ivp, quad

# (a) 打靶：y(pi; lam) = sin(sqrt(lam) pi)/sqrt(lam)
shoot = lambda lam: math.sin(math.sqrt(lam) * math.pi) / math.sqrt(lam)
for n in range(1, 6):
    assert abs(shoot(n**2)) < 1e-12
    assert abs(shoot(n**2 + 2.0)) > 0.05
print("shooting: eigenvalues 1, 4, 9, 16, 25 exact; offsets leave residual")

# (b) Rayleigh 商
R = lambda f, fp: quad(lambda x: fp(x)**2, 0, math.pi)[0] / quad(lambda x: f(x)**2, 0, math.pi)[0]
assert abs(R(math.sin, math.cos) - 1.0) < 1e-10
assert R(lambda x: x * (math.pi - x), lambda x: math.pi - 2 * x) >= 1.0
print(f"Rayleigh: R[sin] = 1 (attained), R[poly] = {R(lambda x: x*(math.pi-x), lambda x: math.pi-2*x):.4f} >= 1")

# (c) Green 函数：lam = 0.5
lam, mu = 0.5, math.sqrt(0.5)
G = lambda x, xi: math.sin(mu * min(x, xi)) * math.sin(mu * (math.pi - max(x, xi))) / (mu * math.sin(mu * math.pi))
assert abs(G(0.5, 1.3) - G(1.3, 0.5)) < 1e-14
y_bvp = lambda x: math.sin(x) / (1 - lam)
for x in [0.7, 1.9, 2.6]:
    Ival = quad(lambda xi: G(x, xi) * math.sin(xi), 0, math.pi)[0]
    assert abs(Ival - y_bvp(x)) < 1e-9
print("Green: symmetric; y = int G f matches analytic sin(x)/(1-lam)")

# (d) 共振可解性（Fredholm 择一）
assert abs(quad(lambda x: math.sin(x) * math.sin(x), 0, math.pi)[0] - math.pi / 2) < 1e-8
assert abs(quad(lambda x: math.sin(2 * x) * math.sin(x), 0, math.pi)[0]) < 1e-8
print("resonance: f = sin x not orthogonal (no solution); f = sin 2x orthogonal (solvable)")

# (e) solve_ivp 对照打靶
sol = solve_ivp(lambda x, u: [u[1], -4.0 * u[0]], [0, math.pi], [0.0, 1.0], rtol=1e-12, atol=1e-12)
assert abs(sol.y[0, -1]) < 1e-9
print("solve_ivp shooting at lambda = 4 lands on y(pi) = 0")

print("END ====")
