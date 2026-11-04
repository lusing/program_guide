print("==== 10 wronskian")

# 第 10 章：Wronskian / Abel / 参数变易（scipy 对照）。
import math
from scipy.integrate import solve_ivp

def fundamental(f, x0, x1, n=24000):
    """从 (1,0) 与 (0,1) 出发积分，返回 (y1, v1, y2, v2)。"""
    h = (x1 - x0) / n
    x, y1, v1, y2, v2 = x0, 1.0, 0.0, 0.0, 1.0
    def step(y, v):
        k1y, k1v = v, f(x, y, v)
        k2y, k2v = v + h * k1v / 2, f(x + h / 2, y + h * k1y / 2, v + h * k1v / 2)
        k3y, k3v = v + h * k2v / 2, f(x + h / 2, y + h * k2y / 2, v + h * k2v / 2)
        k4y, k4v = v + h * k3v, f(x + h, y + h * k3y, v + h * k3v)
        return y + h * (k1y + 2 * k2y + 2 * k3y + k4y) / 6, \
               v + h * (k1v + 2 * k2v + 2 * k3v + k4v) / 6
    for _ in range(n):
        y1, v1 = step(y1, v1)
        y2, v2 = step(y2, v2)
        x += h
    return y1, v1, y2, v2

# (a) 例 A：y'' - y = 0（p=0），W = 1 守恒
y1, v1, y2, v2 = fundamental(lambda x, y, v: y, 0.0, 1.7)
assert abs(y1 * v2 - y2 * v1 - 1.0) < 1e-9
print("ex A: W(cosh, sinh)(1.7) = 1 (p = 0)")

# (b) 例 B：y'' + 2y' + y = 0，W = e^{-2x}
y1, v1, y2, v2 = fundamental(lambda x, y, v: -2 * v - y, 0.0, 1.3)
assert abs((y1 * v2 - y2 * v1) - math.exp(-2.6)) < 1e-9
print("ex B: W(1.3) = e^{-2.6} (Abel)")

# (c) 例 C：x^2 y'' + 4xy' - 4y = 0，W(3) = 3^{-4}
y1, v1, y2, v2 = fundamental(lambda x, y, v: (-4 * x * v + 4 * y) / x**2, 1.0, 3.0)
assert abs((y1 * v2 - y2 * v1) - 3.0**-4) < 1e-8
print("ex C: W(3) = 3^-4 (Abel with p = 4/x)")

# (d) 参数变易：y'' + y = tan x 特解 -cos x ln|sec x + tan x|
ypart = lambda x: -math.cos(x) * math.log(1 / math.cos(x) + math.tan(x))
for x in [0.3, 0.8, 1.1]:
    h = 1e-5
    ypp = (ypart(x + h) - 2 * ypart(x) + ypart(x - h)) / h**2
    assert abs(ypp + ypart(x) - math.tan(x)) < 1e-4
print("variation of parameters: ybar = -cos x ln|sec+tan| satisfies y''+y = tan x")

# (e) solve_ivp 交叉：例 B 的 IVP y(1) = yB(1), y'(1) = yBp(1)
yB = lambda x: x**3 / 3 + 0.75 * x * x + 2.0
sol = solve_ivp(lambda x, u: [u[1], u[1] / x + x], [1, 3],
                [yB(1.0), 2.5], rtol=1e-12, atol=1e-12)
assert abs(sol.y[0, -1] - yB(3.0)) < 1e-9
print(f"solve_ivp cross-check: y(3) = {sol.y[0,-1]:.8f} vs formula {yB(3.0):.8f}")

print("END ====")
