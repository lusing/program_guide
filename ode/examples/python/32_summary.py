print("==== 32 summary")

# 第 32 章：收官——一条 IVP 走完四路流水线（solve_ivp 版）。
import math
from scipy.integrate import solve_ivp

# y'' + 2y' + y = sin t + e^{-t}，零初值（共振右端）
ysol = lambda t: (0.5 + 0.5 * t) * math.exp(-t) - math.cos(t) / 2 + t * t * math.exp(-t) / 2

# 路线 A：残差核对
h = 1e-5
for t in [0.3, 1.7, 3.1]:
    ypp = (ysol(t + h) - 2 * ysol(t) + ysol(t - h)) / h**2
    yp = (ysol(t + h) - ysol(t - h)) / (2 * h)
    assert abs(ypp + 2 * yp + ysol(t) - (math.sin(t) + math.exp(-t))) < 1e-4
print(f"route A (undetermined coefficients): y(2) = {ysol(2):.6f}")

# 路线 B：Laplace（数值变换核对 Y(s)）
def laplace_num(f, s):
    val, _ = __import__("scipy.integrate", fromlist=["quad"]).quad(
        lambda t: math.exp(-s * t) * f(t), 0, 40, limit=200)
    return val

for s in [1.5, 2.2]:
    Y = 1 / ((s**2 + 1) * (s + 1)**2) + 1 / (s + 1)**3
    assert abs(laplace_num(ysol, s) - Y) / Y < 1e-4
print("route B (Laplace): numeric transform of y matches Y(s)")

# 路线 C：solve_ivp
sol = solve_ivp(lambda t, u: [u[1], math.sin(t) + math.exp(-t) - 2 * u[1] - u[0]],
                [0, 2], [0.0, 0.0], rtol=1e-12, atol=1e-12)
assert abs(sol.y[0, -1] - ysol(2)) < 1e-8
print(f"route C (solve_ivp): y(2) = {sol.y[0,-1]:.8f}")

# 路线 D：定性
import numpy as np
eig = np.linalg.eigvals(np.array([[0.0, 1.0], [-1.0, -2.0]]))
assert abs(eig[0].real + 1) < 1e-12  # 双重根 -1
assert eig.real.max() < 0
print("route D (qualitative): repeated root -1, stable degenerate node")

print("END ====")
