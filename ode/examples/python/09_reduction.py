print("==== 09 reduction")

# 第 09 章：降阶法（Julia 通道的独立复算）。
import math

def rk4_2(f, x, y, yp, h):
    k1y, k1v = yp, f(x, y, yp)
    k2y, k2v = yp + h * k1v / 2, f(x + h / 2, y + h * k1y / 2, yp + h * k1v / 2)
    k3y, k3v = yp + h * k2v / 2, f(x + h / 2, y + h * k2y / 2, yp + h * k2v / 2)
    k4y, k4v = yp + h * k3v, f(x + h, y + h * k3y, yp + h * k3v)
    return y + h * (k1y + 2 * k2y + 2 * k3y + k4y) / 6, yp + h * (k1v + 2 * k2v + 2 * k3v + k4v) / 6

def integrate2(f, x0, y0, yp0, x1, n=24000):
    h = (x1 - x0) / n
    x, y, yp = x0, y0, yp0
    for _ in range(n):
        y, yp = rk4_2(f, x, y, yp, h)
        x += h
    return y

# (a) 例 A：y² = 2x+3 支满足 yy'' + y'^2 = 0（差商核对）
ysol = lambda x: math.sqrt(2 * x + 3)
for x in [0.5, 1.2, 2.0]:
    h = 1e-4
    yp = (ysol(x + h) - ysol(x - h)) / (2 * h)
    ypp = (ysol(x + h) - 2 * ysol(x) + ysol(x - h)) / h**2
    assert abs(ysol(x) * ypp + yp * yp) < 1e-5
print("ex A: y^2 = 2x+3 satisfies yy'' + y'^2 = 0 (3 pts)")

# (b) 例 B：y'' - y'/x = x，通解 y = x^3/3 + (3/2)x^2/2 + 2
yB = lambda x: x**3 / 3 + 0.75 * x * x + 2.0
yBp = lambda x: x * x + 1.5 * x
yend = integrate2(lambda x, y, v: v / x + x, 1.0, yB(1.0), yBp(1.0), 3.0)
assert abs(yend - yB(3.0)) < 1e-8
print(f"ex B: y(3) = {yB(3.0):.6f}, RK4 diff {abs(yend - yB(3.0)):.2e}")

# (c) 例 D：yy'' - 2y'^2 = 0，通解 1/(C1 x + C2)
yD = lambda x: 1 / (0.5 * x + 2.0)
yend2 = integrate2(lambda x, y, v: 2 * v * v / y, 1.0, yD(1.0), -0.5 / 2.5**2, 4.0)
assert abs(yend2 - yD(4.0)) < 1e-8
print("ex D: y = 1/(C1x+C2) matches RK4")

# (d) 例 E：W(x, x^-4) = -5x^-4（线性无关）
for x in [0.7, 1.3, 2.5]:
    assert abs(x * (-4 * x**-5) - x**-4 - (-5 * x**-4)) < 1e-12
print("ex E: W(x, x^-4) = -5x^-4 != 0 (independent)")

# (e) 牛顿抛物线
yend4 = integrate2(lambda t, x, v: 3.0, 0.0, 1.0, 2.0, 5.0)
assert abs(yend4 - 48.5) < 1e-9
print(f"Newton: x(5) = {yend4} = 1.5*25 + 10 + 1")

print("END ====")
