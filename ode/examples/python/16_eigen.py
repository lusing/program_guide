print("==== 16 eigen")

# 第 16 章：特征值方法（scipy.linalg 交叉）。
import math
import numpy as np
from scipy.integrate import solve_ivp

# (a) 消元多项式 = det(A - λI)
A1 = np.array([[2.0, 1.0], [1.0, 2.0]])
for lam in [0.0, 1.5, 3.7]:
    assert abs(np.linalg.det(A1 - lam * np.eye(2)) - (lam**2 - 4 * lam + 3)) < 1e-10
eig = sorted(np.linalg.eigvals(A1))
assert abs(eig[0] - 1) < 1e-12 and abs(eig[1] - 3) < 1e-12
print("A=[[2,1],[1,2]]: eigenvalues 1, 3; elimination poly = det(A - lI)")

# (b) 三情形解析 vs solve_ivp
sol = solve_ivp(lambda t, u: A1 @ u, [0, 0.8], [1.0, 2.0], rtol=1e-12, atol=1e-12)
xsol = lambda t: -0.5 * math.exp(t) * np.array([1, -1]) + 1.5 * math.exp(3 * t) * np.array([1, 1])
assert np.linalg.norm(sol.y[:, -1] - xsol(0.8)) < 1e-8
print("real distinct roots: solution matches c1 e^t(1,-1) + c2 e^{3t}(1,1)")

A2 = np.array([[1.0, -2.0], [2.0, 1.0]])
u0 = np.array([1.0, 0.5])
sol = solve_ivp(lambda t, u: A2 @ u, [0, 1.2], u0, rtol=1e-12, atol=1e-12)
xsol2 = lambda t: math.exp(t) * (u0[0] * np.array([math.cos(2*t), math.sin(2*t)])
                                  + u0[1] * np.array([-math.sin(2*t), math.cos(2*t)]))
assert np.linalg.norm(sol.y[:, -1] - xsol2(1.2)) < 1e-8
print("complex roots 1+-2i: rotation-and-grow solution matches")

A3 = np.array([[1.0, 1.0], [0.0, 1.0]])
sol = solve_ivp(lambda t, u: A3 @ u, [0, 1.5], [1.0, 1.0], rtol=1e-12, atol=1e-12)
expect = np.array([math.exp(1.5) * 2.5, math.exp(1.5)])
assert np.linalg.norm(sol.y[:, -1] - expect) < 1e-8
print("double root: t*e^{lambda t} branch matches (Jordan block)")

# (c) 非齐次常向量特解 -A^{-1} b
b = np.array([1.0, -1.0])
xs = -np.linalg.solve(A1, b)
assert np.linalg.norm(A1 @ xs + b) < 1e-12
print("constant forcing: particular solution -A^{-1} b satisfies A xbar + b = 0")

# (d) 稳定性
A5 = np.array([[-2.0, 0.5], [0.3, -3.0]])
sol = solve_ivp(lambda t, u: A5 @ u, [0, 8], [2.0, -1.0], rtol=1e-12, atol=1e-12)
assert np.linalg.norm(sol.y[:, -1]) < 1e-4
print(f"stable matrix (eigs {np.linalg.eigvals(A5).round(3)}): x(8) norm = {np.linalg.norm(sol.y[:,-1]):.2e}")

print("END ====")
