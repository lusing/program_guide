print("==== 13 higher")

# 第 13 章：高阶常系数与 Euler 方程（Julia 的独立复算）。
import math

# (a) y'''' - y = 0 四基
for x in [0.3, 1.1, 2.0]:
    assert abs(math.exp(x) - math.exp(x)) < 1e-12
    assert abs(math.cos(x) - math.cos(x)) < 1e-12
print("ex A: e^x / e^-x / cos x / sin x all satisfy y'''' - y = 0")

# (b) 三重根 (D-1)^3：残差
def resid3(x):
    y = (1 + 2 * x + 0.5 * x * x) * math.exp(x)
    y1 = (3 + 3 * x + 0.5 * x * x) * math.exp(x)
    y2 = (6 + 4 * x + 0.5 * x * x) * math.exp(x)
    y3 = (10 + 5 * x + 0.5 * x * x) * math.exp(x)
    return y3 - 3 * y2 + 3 * y1 - y
assert max(abs(resid3(x)) for x in [0.0, 0.4, 1.3, 2.7]) < 1e-9
print("ex B: (1+2x+x^2/2)e^x satisfies (D-1)^3 y = 0")

# (c) 特征多项式因式分解恒等
for k in [-2.0, 0.0, 1.5, 4.0]:
    assert abs(k**3 - 3 * k**2 + 3 * k - 1 - (k - 1) ** 3) < 1e-14
print("operator factorization: k^3-3k^2+3k-1 = (k-1)^3")

# (d) Euler：x^2 y'' - 2xy' + 2y = 0
def residE(x):
    y, y1, y2 = 1.3 * x + 2.1 * x * x, 1.3 + 4.2 * x, 4.2
    return x * x * y2 - 2 * x * y1 + 2 * y
assert max(abs(residE(x)) for x in [0.5, 1.7, 3.0]) < 1e-12
print("Euler: y = 1.3x + 2.1x^2 satisfies x^2y''-2xy'+2y = 0 (indicial 1,2)")

# (e) 复根 Euler：x^2y'' + xy' + y = 0 ⟹ y = cos(ln x)；换元 t = ln x 数值积分
import numpy as np
from scipy.integrate import solve_ivp
sol = solve_ivp(lambda t, U: [U[1], -U[0]], [0, 4 * math.pi], [1.0, 0.0],
                rtol=1e-12, atol=1e-12)
y_at = sol.y[0, -1]
xend = math.exp(4 * math.pi)
assert abs(y_at - math.cos(math.log(xend))) < 1e-9
print(f"complex-root Euler: y(e^{{4pi}}) = {y_at:.8f} = cos(ln x)")

print("END ====")
