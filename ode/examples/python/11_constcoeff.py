print("==== 11 constcoeff")

# 第 11 章：常系数二阶（Julia 的独立复算 + solve_ivp）。
import math
from scipy.integrate import solve_ivp

def integrate2(f, x0, y0, v0, x1, n=24000):
    h = (x1 - x0) / n
    x, y, v = x0, y0, v0
    for _ in range(n):
        k1y, k1v = v, f(x, y, v)
        k2y, k2v = v + h * k1v / 2, f(x + h / 2, y + h * k1y / 2, v + h * k1v / 2)
        k3y, k3v = v + h * k2v / 2, f(x + h / 2, y + h * k2y / 2, v + h * k2v / 2)
        k4y, k4v = v + h * k3v, f(x + h, y + h * k3y, v + h * k3v)
        y += h * (k1y + 2 * k2y + 2 * k3y + k4y) / 6
        v += h * (k1v + 2 * k2v + 2 * k3v + k4v) / 6
        x += h
    return y

# (a) 三情形残差（解析导数）
r1 = lambda x: (4.8 * math.exp(2 * x) - 6.3 * math.exp(-3 * x)
                + 2.4 * math.exp(2 * x) + 2.1 * math.exp(-3 * x)
                - 6 * (1.2 * math.exp(2 * x) - 0.7 * math.exp(-3 * x)))
assert max(abs(r1(x)) for x in [0.3, 1.1, 2.0]) < 1e-10
print("D>0: y = 1.2e^{2x} - 0.7e^{-3x} solves y''+y'-6y = 0")

r2 = lambda x: (3.0 + 0.5 * x) * math.exp(x) - 2 * (2.5 + 0.5 * x) * math.exp(x) \
               + (2 + 0.5 * x) * math.exp(x)
assert max(abs(r2(x)) for x in [0.3, 1.1, 2.0]) < 1e-10
print("D=0: y = (2+0.5x)e^x solves y''-2y'+y = 0")

r3 = lambda x: math.exp(-x) * ((-11 * math.cos(2 * x) - 2 * math.sin(2 * x))
    + 2 * (3 * math.cos(2 * x) - 4 * math.sin(2 * x))
    + 5 * (math.cos(2 * x) + 2 * math.sin(2 * x)))
assert max(abs(r3(x)) for x in [0.3, 1.1, 2.0]) < 1e-10
print("D<0: y = e^{-x}(cos2x + 2sin2x) solves y''+2y'+5y = 0")

# (b) 共振：y'' + y = sin x 的解振幅线性增长
yend = integrate2(lambda x, y, v: -y + math.sin(x), 0.0, 0.0, 0.0, 20 * math.pi, n=480000)
assert abs(yend - (-10 * math.pi)) < 5e-3
print(f"resonance: y(20pi) = {yend:.3f} ~ -10pi = {-10*math.pi:.3f}")

# (c) 书例 3.23 IVP
yexact = lambda x: math.cos(x) - math.sin(x) / 2 - x * math.cos(x) / 2 + x
yend2 = integrate2(lambda x, y, v: -y + math.sin(x) + x, 0.0, 1.0, 0.0, 5.0)
assert abs(yend2 - yexact(5.0)) < 1e-8
print(f"ex 3.23: y(5) = {yexact(5.0):.6f}, RK4 diff {abs(yend2 - yexact(5.0)):.2e}")

# (d) 稳定性：y''+5y'+6y=0，真解 7e^{-2x} - 4e^{-3x}
yend3 = integrate2(lambda x, y, v: -5 * v - 6 * y, 0.0, 3.0, -2.0, 5.0)
assert abs(yend3 - (7 * math.exp(-10.0) - 4 * math.exp(-15.0))) < 1e-9
print("stability: y(5) = 7e^{-10} - 4e^{-15} (decaying)")

# (e) solve_ivp 交叉：D<0 情形
sol = solve_ivp(lambda x, u: [u[1], -2 * u[1] - 5 * u[0]], [0, 3], [1.0, 3.0],
                rtol=1e-12, atol=1e-12)
# 初值 (1, 3) 的真解：y = e^{-x}(cos2x + 2sin2x)（y'(0) = -1+4 = 3 ✓）
assert abs(sol.y[0, -1] - math.exp(-3) * (math.cos(6) + 2 * math.sin(6))) < 1e-9
print("solve_ivp cross-check for D<0 case")

print("END ====")
