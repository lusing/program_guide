# 31_var_diff.py —— 第 31 章：变分差分与抛物有限元（Python 通道，独立复算）

import math
import numpy as np

print("==== 31 var diff")

p31 = lambda x: 1 + x
uex31 = lambda x: math.sin(math.pi * x)
f31 = lambda x: (1 + x) * math.pi**2 * math.sin(math.pi * x) - math.pi * math.cos(math.pi * x) + math.sin(math.pi * x)

def var_diff(N):
    h = 1.0 / N
    n = N - 1
    A = np.zeros((n, n))
    b = np.zeros(n)
    for k in range(1, n + 1):
        xk = k * h
        pL = 0.5 * (p31(xk - h) + p31(xk))
        pR = 0.5 * (p31(xk) + p31(xk + h))
        A[k - 1, k - 1] = 0.5 * (pL + pR) * 2 / h + 2 * h / 3
        if k > 1:
            A[k - 1, k - 2] = -pL / h + h / 6
            A[k - 2, k - 1] = A[k - 1, k - 2]
        if k < n:
            A[k - 1, k] = -pR / h + h / 6
        b[k - 1] = f31(xk) * h
    c = np.linalg.solve(A, b)
    u = np.concatenate([[0.0], c, [0.0]])
    return max(abs(u[k] - uex31(k * h)) for k in range(N + 1))

e1, e2 = var_diff(20), var_diff(40)
r31 = e1 / e2
print(f"variational difference: err(20) = {e1:.4f}, err(40) = {e2:.4f}, ratio = {r31:.3f}")
assert 3.0 < r31 < 4.6, r31

def heat_fem_cn(N, tau, T, lump=False):
    h = 1.0 / N
    n = N - 1
    K = np.zeros((n, n))
    M = np.zeros((n, n))
    for k in range(n):
        K[k, k] = 2 / h
        M[k, k] = 2 * h / 3
        if k > 0:
            K[k, k - 1] = -1 / h
            K[k - 1, k] = -1 / h
            M[k, k - 1] = h / 6
            M[k - 1, k] = h / 6
    if lump:
        M = np.diag(np.full(n, h))
    u = np.array([math.sin(math.pi * (k + 1) * h) for k in range(n)])
    nst = round(T / tau)
    L = M + tau / 2 * K
    R = M - tau / 2 * K
    for _ in range(nst):
        u = np.linalg.solve(L, R @ u)
    tf = nst * tau
    return max(abs(u[k] - math.exp(-math.pi**2 * tf) * math.sin(math.pi * (k + 1) * h)) for k in range(n))

N = 40
tau = 1.0 / N
e_cons = heat_fem_cn(N, tau, 0.4)
e_lump = heat_fem_cn(N, tau, 0.4, lump=True)
print(f"CN-Galerkin (tau=h, consistent): err = {e_cons:.4f}")
print(f"CN-Galerkin (lumped):            err = {e_lump:.4f}")
assert e_cons < 0.15 and e_lump < 0.15
assert abs(e_lump - e_cons) < 0.05

e1 = heat_fem_cn(80, 0.04, 0.4)
e2 = heat_fem_cn(80, 0.02, 0.4)
print(f"CN-Galerkin time convergence: ratio = {e1/e2:.3f}")
assert 3.0 < e1 / e2 < 4.6

print("END ====")
