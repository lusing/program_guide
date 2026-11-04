print("==== 17 matexp")

# 第 17 章：矩阵指数（scipy.linalg.expm 交叉）。
import math
import numpy as np
from scipy.linalg import expm
from scipy.integrate import solve_ivp

def matexp_series(A, t, tol=1e-16, maxterm=40):
    n = A.shape[0]
    E = np.eye(n)
    term = np.eye(n)
    for k in range(1, maxterm + 1):
        term = term @ A * (t / k)
        E = E + term
        if np.linalg.norm(term) < tol:
            break
    return E

A1 = np.array([[2.0, 1.0], [1.0, 2.0]])
A2 = np.array([[1.0, -2.0], [2.0, 1.0]])
A3 = np.array([[1.0, 1.0], [0.0, 1.0]])
for name, A in [("real-distinct", A1), ("complex", A2), ("jordan", A3)]:
    Es, Eb = matexp_series(A, 0.7), expm(A * 0.7)
    assert np.linalg.norm(Es - Eb) / np.linalg.norm(Eb) < 1e-12, name
print("series vs scipy expm: relative error < 1e-12 for all three cases")

# Putzer 2x2
def putzer2(A, t):
    tau = np.trace(A)
    kappa2 = tau**2 / 4 - np.linalg.det(A)
    B = A - tau / 2 * np.eye(2)
    I = np.eye(2)
    if kappa2 > 1e-14:
        k = math.sqrt(kappa2)
        return math.exp(tau * t / 2) * (math.cosh(k * t) * I + math.sinh(k * t) / k * B)
    if kappa2 < -1e-14:
        k = math.sqrt(-kappa2)
        return math.exp(tau * t / 2) * (math.cos(k * t) * I + math.sin(k * t) / k * B)
    return math.exp(tau * t / 2) * (I + t * B)

for A in [A1, A2, A3]:
    assert np.linalg.norm(putzer2(A, 0.9) - expm(A * 0.9)) / np.linalg.norm(expm(A * 0.9)) < 1e-12
print("Putzer 2x2 formula matches expm for all three regimes")

# x = e^{At} x0 vs solve_ivp
u0 = np.array([1.0, -2.0])
xf = expm(A2 * 1.3) @ u0
sol = solve_ivp(lambda t, u: A2 @ u, [0, 1.3], u0, rtol=1e-12, atol=1e-12)
assert np.linalg.norm(sol.y[:, -1] - xf) < 1e-8
print("x = e^{At} x0 matches solve_ivp")

# 常数变易：x = e^{At}x0 + int e^{A(t-s)} g(s) ds
A = A1
g = lambda t: np.array([math.cos(t), 0.0])
sol = solve_ivp(lambda t, u: A @ u + g(t), [0, 2], [1.0, -1.0], rtol=1e-11, atol=1e-13)
Iv = np.zeros(2)
ns = 8000
h = 2.0 / ns
for k in range(ns + 1):
    s = k * h
    w = expm(A * (2 - s)) @ g(s)
    Iv = Iv + (0.5 if k in (0, ns) else 1.0) * w * h
xf = expm(A * 2.0) @ np.array([1.0, -1.0]) + Iv
assert np.linalg.norm(xf - sol.y[:, -1]) / np.linalg.norm(xf) < 1e-5
print("variation of constants: formula matches direct integration")

# det e^{At} = e^{tr(A) t}；不可交换反例
for A in [A1, A2, A3]:
    assert abs(np.linalg.det(expm(A * 0.8)) - math.exp(np.trace(A) * 0.8)) < 1e-9
B = np.array([[0.0, 1.0], [0.0, 0.0]])
C = np.array([[0.0, 0.0], [1.0, 0.0]])
gap = np.linalg.norm(expm(B + C) - expm(B) @ expm(C))
assert gap > 0.1
print(f"non-commutativity: ||e^(B+C) - e^B e^C|| = {gap:.4f} > 0")

print("END ====")
