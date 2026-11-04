# 32_eigenvalue.py —— 第 32 章：特征值 FEM + 障碍问题（Python 通道，独立复算）

import math
import numpy as np
import scipy.linalg as sla

print("==== 32 eigenvalue")

def fem_eig(N, lump=False):
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
    evals = sla.eigh(K, M, eigvals_only=True)
    return evals

for N in (8, 16, 32):
    evs = fem_eig(N)
    print(f"N = {N}: lam1_h = {evs[0]:.4f}  lam2_h = {evs[1]:.4f}  (exact {math.pi**2:.4f}, {4*math.pi**2:.4f})")
evs32 = fem_eig(32)
assert abs(evs32[0] - math.pi**2) / math.pi**2 < 1e-3
assert evs32[0] > math.pi**2

evs_lump = fem_eig(32, lump=True)
closed = 2 * (1 - math.cos(math.pi / 32)) * 32**2
print(f"lumped: lam1 = {evs_lump[0]:.4f} closed 2(1-cos(pi h))/h^2 = {closed:.4f}")
assert abs(evs_lump[0] - closed) < 1e-8

N = 32
h = 1.0 / N
n = N - 1
v = np.array([math.sin(math.pi * (k + 1) * h) for k in range(n)])
K = np.zeros((n, n)); M = np.zeros((n, n))
for k in range(n):
    K[k, k] = 2 / h
    M[k, k] = 2 * h / 3
    if k > 0:
        K[k, k - 1] = -1 / h; K[k - 1, k] = -1 / h
        M[k, k - 1] = h / 6; M[k - 1, k] = h / 6
R = (v @ K @ v) / (v @ M @ v)
print(f"Rayleigh quotient of sin(pi x): R = {R:.6f} >= lam1 = {math.pi**2:.6f}")
assert R >= math.pi**2 - 1e-9

psi = lambda k: 0.05 * math.sin(2 * math.pi * (k + 1) * (1.0 / 64))   # 障碍在 64 网格上（坑：此处 h 仍是 1/32）

def obstacle_sor(N, omega=1.8, tol=1e-10):
    h = 1.0 / N
    n = N - 1
    u = np.array([max(0.0, psi(k)) for k in range(n)])
    for _ in range(500000):
        diff = 0.0
        for k in range(n):
            ul = 0.0 if k == 0 else u[k - 1]
            ur = 0.0 if k == n - 1 else u[k + 1]
            gs = 0.5 * (ul + ur + h * h)
            newv = max(psi(k), u[k] + omega * (gs - u[k]))
            diff = max(diff, abs(newv - u[k]))
            u[k] = newv
        if diff < tol:
            break
    return u

u_obs = obstacle_sor(64)
active = sum(1 for k in range(63) if u_obs[k] <= psi(k) + 1e-8)
print(f"obstacle problem: active set = {active}/63")
mv = 0.0
h = 1 / 64
for k in range(1, 62):
    lap = (u_obs[k - 1] - 2 * u_obs[k] + u_obs[k + 1]) / h**2
    if u_obs[k] > psi(k) + 1e-6:
        mv = max(mv, abs(-lap - 1.0))
assert mv < 1e-6, mv
print(f"complementarity: free region -u'' = 1 to {mv:.2e}")

print("END ====")
