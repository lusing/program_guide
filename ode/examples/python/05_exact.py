print("==== 05 exact")

# 第 05 章：恰当方程（Julia 的独立复算）。
import math

# --- (a) 例 2.22 判据 + 势函数 ---
P = lambda x, y: 3 * x**2 * y**2 + 7
Q = lambda x, y: 2 * x**3 * y
h = 1e-6
maxdev = max(
    abs((P(x, y + h) - P(x, y - h)) / (2 * h) - (Q(x + h, y) - Q(x - h, y)) / (2 * h))
    for x in [0.2 + 0.2 * i for i in range(5)]
    for y in [0.2 + 0.2 * i for i in range(5)]
)
assert maxdev < 1e-6
print(f"criterion |P_y - Q_x| max deviation = {maxdev:.2e}")

Fx = lambda x, y: 3 * x**2 * y**2 + 7
Fy = lambda x, y: 2 * x**3 * y
assert all(Fx(x, y) == P(x, y) and Fy(x, y) == Q(x, y)
           for x in [0.2 + 0.2 * i for i in range(5)]
           for y in [0.2 + 0.2 * i for i in range(5)])
print("potential F = x^3 y^2 + 7x: F_x = P, F_y = Q exactly")

# --- (b) 例 2.23 积分因子 μ = 1/(x²+y²) ---
P2 = lambda x, y: x + x**2 * (x**2 + y**2)
Q2 = lambda x, y: y
mu = lambda x, y: 1 / (x**2 + y**2)
F2x = lambda x, y: x / (x**2 + y**2) + x**2
F2y = lambda x, y: y / (x**2 + y**2)
maxdev2 = max(
    max(abs(mu(x, y) * P2(x, y) - F2x(x, y)), abs(mu(x, y) * Q2(x, y) - F2y(x, y)))
    for x in [0.5 + 0.2 * i for i in range(6)]
    for y in [0.5 + 0.2 * i for i in range(6)]
)
assert maxdev2 < 1e-12
print(f"after mu: muP = F_x, muQ = F_y, max deviation {maxdev2:.2e}")

# 原方程确实不恰当
dPy = (P2(0.9, 0.6 + h) - P2(0.9, 0.6 - h)) / (2 * h)
assert dPy > 0.5
print(f"original equation not exact: P_y(0.9,0.6) = {dPy:.4f} != 0 = Q_x")

# --- (c) 情形 A 公式核对：线性方程 y' + py = f 的 μ = e^{∫p} ---
# y' + 5y = e^x：μ = e^{5x}，解 y = (∫ μf dx)/μ + C/μ
p = lambda x: 5
g = lambda x: math.exp(x)
muA = lambda x: math.exp(5 * x)
# 验证 (μy)' = μf：取解析解 y = 5/6 e^{-5x} + e^x/6（C=5/6 支）
y = lambda x: (5 / 6) * math.exp(-5 * x) + math.exp(x) / 6
for x in [0.2, 0.7, 1.1]:
    dy = (5 / 6) * (-5) * math.exp(-5 * x) + math.exp(x) / 6
    lhs = 5 * muA(x) * y(x) + muA(x) * dy      # (μy)' = μ'y + μy'
    assert abs(lhs - muA(x) * g(x)) < 1e-10
print("(mu*y)' = mu*f verified: integrating-factor identity for linear ODE")

print("END ====")
