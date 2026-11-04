print("==== 15 systems")

# 第 15 章：方程组（scipy 交叉验证版）。
import math
import numpy as np
from scipy.integrate import solve_ivp

# (a) 振子两形态一致（二阶组 = 一阶组本来就是同一个数值问题；对照解析解）
delta, w0 = 0.3, 2.0
wf = math.sqrt(w0**2 - delta**2)
yexact = lambda t: math.exp(-delta * t) * (math.cos(wf * t) + 0.5 * math.sin(wf * t))
sol = solve_ivp(lambda t, u: [u[1], -2 * delta * u[1] - w0**2 * u[0]],
                [0, 10], [1.0, -delta + 0.5 * wf], rtol=1e-12, atol=1e-12)
assert abs(sol.y[0, -1] - yexact(10.0)) < 1e-8
print("oscillator as first-order system matches analytic solution")

# (b) Airy 型 A(t) = [[0,1],[-t,0]]：det X = e^{int tr} = 1
def fund_matrix(t1, n=24000):
    h = t1 / n
    cols = [np.array([1.0, 0.0]), np.array([0.0, 1.0])]
    t = 0.0
    for _ in range(n):
        for j, c in enumerate(cols):
            k1 = np.array([c[1], -t * c[0]])
            k2 = np.array([c[1] + h * k1[1] / 2, -(t + h / 2) * (c[0] + h * k1[0] / 2)])
            k3 = np.array([c[1] + h * k2[1] / 2, -(t + h / 2) * (c[0] + h * k2[0] / 2)])
            k4 = np.array([c[1] + h * k3[1], -(t + h) * (c[0] + h * k3[0])])
            cols[j] = c + h * (k1 + 2 * k2 + 2 * k3 + k4) / 6
        t += h
    return np.column_stack(cols)

X = fund_matrix(2.0)
assert abs(np.linalg.det(X) - 1.0) < 1e-9
print(f"Airy-type fundamental matrix: det X(2) = {np.linalg.det(X):.6f} (Abel: tr = 0)")

# (c) 常系数：det X = e^{tr(A)t}
A = np.array([[1.0, 2.0], [0.5, 3.0]])
def fund_matrix_const(A, t1, n=24000):
    h = t1 / n
    cols = [np.array([1.0, 0.0]), np.array([0.0, 1.0])]
    for _ in range(n):
        for j, c in enumerate(cols):
            k1 = A @ c
            k2 = A @ (c + h * k1 / 2)
            k3 = A @ (c + h * k2 / 2)
            k4 = A @ (c + h * k3)
            cols[j] = c + h * (k1 + 2 * k2 + 2 * k3 + k4) / 6
    return np.column_stack(cols)

Xc = fund_matrix_const(A, 1.5)
assert abs(np.linalg.det(Xc) - math.exp(4.0 * 1.5)) < 1e-6
print(f"constant A: det X(1.5) = {np.linalg.det(Xc):.4f} vs e^6 = {math.exp(6):.4f}")

# (d) 高阶化一阶组：三阶方程 y''' + 2y'' - y' - 2y = 0 的状态空间形式
#     特征 λ^3 + 2λ^2 - λ - 2 = (λ+2)(λ-1)(λ+1)
A3 = np.array([[0.0, 1.0, 0.0], [0.0, 0.0, 1.0], [2.0, 1.0, -2.0]])
eig = np.linalg.eigvals(A3)
assert abs(np.prod(eig) - 2.0) < 1e-9        # -det A = 2
assert abs(np.sum(eig) + 2.0) < 1e-9         # -tr A = -2 → sum eig = -2
print("third-order equation as system: eigenvalues (2, 1, -1) up to sign/product checks")

print("END ====")
