# 28_fem1d.py —— 第 28 章：一维有限元（Python 通道，独立复算）

import math
import numpy as np

print("==== 28 fem1d")

ffun = lambda x: (math.pi**2 + 1) * math.sin(math.pi * x)
alpha_robin = 2.0
g_robin = -math.pi
uex28 = lambda x: math.sin(math.pi * x)

def fem1d(N):
    h = 1.0 / N
    n = N
    K = np.zeros((n + 1, n + 1))
    F = np.zeros(n + 1)
    for e in range(1, N + 1):
        xe = (e - 1) * h
        xf = e * h
        ke = (1 / h) * np.array([[1, -1], [-1, 1]]) + (h / 6) * np.array([[2, 1], [1, 2]])
        fe = (h / 6) * np.array([2 * ffun(xe) + ffun(xf), ffun(xe) + 2 * ffun(xf)])
        for a in range(2):
            for b in range(2):
                K[e - 1 + a, e - 1 + b] += ke[a, b]
            F[e - 1 + a] += fe[a]
    K[n, n] += alpha_robin
    F[n] += g_robin
    Kred = K[1:, 1:]
    Fred = F[1:]
    c = np.linalg.solve(Kred, Fred)
    return np.concatenate([[0.0], c])

u = fem1d(40)
maxerr = max(abs(u[i] - uex28(i / 40)) for i in range(41))
print(f"FEM (N=40) nodal err = {maxerr:.4e}")
assert maxerr < 1e-3

def fem_err(N):
    u = fem1d(N)
    return max(abs(u[i] - uex28(i / N)) for i in range(N + 1))

e1, e2 = fem_err(20), fem_err(40)
r28 = e1 / e2
assert 3.5 < r28 < 4.5, (e1, e2, r28)
print(f"nodal convergence: ratio = {r28:.3f} (2nd order)")

def energy_err(N):
    u = fem1d(N)
    h = 1.0 / N
    s = 0.0
    for e in range(1, N + 1):
        xmid = (e - 0.5) * h
        duh = (u[e] - u[e - 1]) / h
        s += (duh - math.pi * math.cos(math.pi * xmid)) ** 2 * h
    return math.sqrt(s)

g1, g2 = energy_err(20), energy_err(40)
print(f"energy at midpoints: ratio = {g1/g2:.3f}")
assert 1.7 < g1 / g2 < 2.3 or 3.5 < g1 / g2 < 4.5

h = 0.1
ke = (1 / h) * np.array([[1, -1], [-1, 1]]) + (h / 6) * np.array([[2, 1], [1, 2]])
assert abs(ke[0, 0] - (1 / h + h / 3)) < 1e-12
assert abs(ke[0, 1] - (-1 / h + h / 6)) < 1e-12
print(f"element stiffness: [{ke[0,0]:.4f}, {ke[0,1]:.4f}] matches closed form")

print("END ====")
