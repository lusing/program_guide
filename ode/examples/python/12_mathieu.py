print("==== 12 mathieu")

# 第 12 章：Mathieu 方程——scipy.special 特征值 + 数值 Floquet。
import math
import numpy as np
from scipy.special import mathieu_a, mathieu_b
from scipy.integrate import solve_ivp

# (a) Mathieu 特征值（带边界）：a_n(q) 与 b_n(q)
a0, a1 = mathieu_a(0, 1.0), mathieu_a(1, 1.0)
b1 = mathieu_b(1, 1.0)
print(f"a0(1) = {a0:.7f}, a1(1) = {a1:.7f}, b1(1) = {b1:.7f}")
assert abs(a0 - (-0.4551386)) < 1e-6
assert abs(a1 - 1.8591081) < 1e-6
assert abs(b1 - (-0.1102488)) < 1e-6
print("characteristic values a0/a1/b1 at q=1 match references")

# (b) 第一不稳定带随 q 展宽：|a1(q) - b1(q)| 单调增
prev = 0.0
for q in [0.2, 0.5, 1.0, 2.0, 3.0]:
    width = abs(mathieu_a(1, q) - mathieu_b(1, q))
    if prev > 0:
        assert width > prev, "band should widen with q"
    prev = width
print("first instability band |a1(q)-b1(q)| widens with q")

# (c) 小 q 近似（DLMF）：a0 ≈ -q^2/2；a1 ≈ 1 + q - q^2/8 - q^3/64；b1 ≈ 1 - q - q^2/8 + q^3/64
q = 0.3
assert abs(mathieu_a(0, q) - (-q * q / 2)) < 1e-3
assert abs(mathieu_a(1, q) - (1 + q - q * q / 8 - q**3 / 64)) < 1e-3
assert abs(mathieu_b(1, q) - (1 - q - q * q / 8 + q**3 / 64)) < 1e-3
print("small-q asymptotics: a0 ~ -q^2/2, a1 ~ 1+q-q^2/8, b1 ~ 1-q-q^2/8")

# (d) 数值 Floquet：u'' + (a - 2q cos 2x)u = 0，q=1
# 带内 a = 1.0（在 a0..a1 之间？a0=-0.455 < 1 < 1.859 = a1 ⟹ 带内不稳定）
def monodromy(a, q, n=12000):
    L = math.pi
    h = L / n
    Y = np.eye(2)
    for i in range(n):
        x = i * h
        f = lambda xx, U: [U[1], -(a - 2 * q * math.cos(2 * xx)) * U[0]]
        # 单步 RK4（向量化两列同时积分）
        k1 = np.array(f(x, Y.T[0])) ; k1b = np.array(f(x, Y.T[1]))
        # 矩阵形式：d/dx[第 j 列] = [M[1,j], -c*M[0,j]]^T
        def F(xx, M):
            c = -(a - 2 * q * math.cos(2 * xx))
            return np.array([[M[1, 0], M[1, 1]], [c * M[0, 0], c * M[0, 1]]])
        k1 = F(x, Y)
        k2 = F(x + h / 2, Y + h / 2 * k1)
        k3 = F(x + h / 2, Y + h / 2 * k2)
        k4 = F(x + h, Y + h * k3)
        Y = Y + h * (k1 + 2 * k2 + 2 * k3 + k4) / 6
    return Y

T = monodromy(1.0, 1.0)
tr = T[0, 0] + T[1, 1]
print(f"monodromy tr T = {tr:.4f} (|tr|>2 unstable, q=1, a=1 inside first band (b1,a1))")
assert abs(tr) > 2
# 稳定窗口：a ∈ (a0(q), b1(q)) = (-0.455, -0.110)，取 a = -0.3 应稳定
T2 = monodromy(-0.3, 1.0)
tr2 = abs(T2[0, 0] + T2[1, 1])
print(f"a = -0.3 (inside (a0,b1) window): |tr T| = {tr2:.4f} < 2 stable")
assert tr2 < 2

# (e) 指数增长：a=1, q=1，10 个周期的放大
sol = solve_ivp(lambda x, U: [U[1], -(1.0 - 2 * math.cos(2 * x)) * U[0]],
                [0, 40 * math.pi], [1.0, 0.0], rtol=1e-11, atol=1e-13)
growth = math.log(math.hypot(sol.y[0, -1], sol.y[1, -1])) / (40 * math.pi)
roots = [(tr + math.sqrt(tr * tr - 4)) / 2, (tr - math.sqrt(tr * tr - 4)) / 2]
mu_theory = math.log(max(abs(r) for r in roots)) / math.pi
assert abs(growth - mu_theory) < 6e-3  # 周期化矩阵 P 的预因子偏差 ~ log|Pu0|/(N*pi)
print(f"growth rate: numeric {growth:.5f} vs Floquet {mu_theory:.5f}")

print("END ====")
