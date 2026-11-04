print("==== 04 linear")

# 第 04 章：一阶线性方程（Julia 通道的独立复算 + scipy.solve_ivp 交叉）。
import math
from scipy.integrate import solve_ivp

def rk4(f, x, y, h):
    k1 = f(x, y)
    k2 = f(x + h / 2, y + h * k1 / 2)
    k3 = f(x + h / 2, y + h * k2 / 2)
    k4 = f(x + h, y + h * k3)
    return y + h * (k1 + 2 * k2 + 2 * k3 + k4) / 6

def integrate(f, x0, y0, x1, n=1000):
    h = (x1 - x0) / n
    x, y = x0, y0
    for _ in range(n):
        y = rk4(f, x, y, h)
        x += h
    return y

# --- (a) 书例 2.16：y' + 5y = e^x，y = Ce^{-5x} + e^x/6，y(0)=1 ⟹ C=5/6 ---
f = lambda x, y: math.exp(x) - 5 * y
ysol = lambda x: (5 / 6) * math.exp(-5 * x) + math.exp(x) / 6
y_rk4 = integrate(f, 0.0, 1.0, 1.0)
sol = solve_ivp(f, [0, 1], [1.0], rtol=1e-12, atol=1e-12)
assert abs(y_rk4 - ysol(1.0)) < 1e-9
assert abs(sol.y[0, -1] - ysol(1.0)) < 1e-9
print(f"ex 2.16: formula {ysol(1.0):.10f}, RK4 {y_rk4:.10f}, solve_ivp {sol.y[0,-1]:.10f}")

# --- (b) 书例 2.17：y' - y/x = x（x>0），y = Cx + x²，y(1)=2 ⟹ C=1 ---
f17 = lambda x, y: y / x + x
assert abs(integrate(f17, 1.0, 2.0, 2.0) - 6.0) < 1e-9
print("ex 2.17: y(2) = 6 = Cx + x^2 with C=1 verified by RK4")

# --- (c) Bernoulli 书例 2.20：y' - y = 3/y，y² = Ce^{2x} - 3，y(0)=2 ⟹ C=7 ---
fb = lambda x, y: y + 3 / y
yb = integrate(fb, 0.0, 2.0, 1.0)
assert abs(yb - math.sqrt(7 * math.exp(2) - 3)) < 1e-9
print(f"Bernoulli: y(1) = {yb:.6f} vs sqrt(7e^2-3) = {math.sqrt(7*math.exp(2)-3):.6f}")

# --- (d) 隐藏线性书例 2.19：(2e^y - x)y' = 1 ⟺ dx/dy + x = 2e^y ---
# 解 x = Ce^{-y} + e^y。数值验证 dx/dy + x = 2e^y
for yy in [0.3, 0.9, 1.7]:
    C = 1.0
    x = C * math.exp(-yy) + math.exp(yy)
    dxdy = -C * math.exp(-yy) + math.exp(yy)
    assert abs(dxdy + x - 2 * math.exp(yy)) < 1e-12
print("hidden linearity: x = Ce^{-y} + e^y satisfies dx/dy + x = 2e^y")

# --- (e) 参数变易的中间量：u' = f·e^{∫p} 的账 ---
# 例 2.16：u' = e^{6x} ⟹ u = e^{6x}/6 + C——数值积分对照
trap = sum(math.exp(6 * i * 0.001) * 0.001 for i in range(1001)) \
       - 0.0005 * (1 + math.exp(6))
assert abs(trap - (math.exp(6) - 1) / 6) < 2.5e-4  # trapezoid error (h^2/12)*36*(e^6-1) ~ 2.01e-4
print(f"variation of parameter: int_0^1 e^(6x) dx = {(math.exp(6)-1)/6:.4f} (trapezoid agrees)")

print("END ====")
