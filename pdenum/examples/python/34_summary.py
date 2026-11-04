# 34_summary.py —— 第 34 章：三条路交叉对账（Python 通道，独立复算）

import math
import numpy as np

print("==== 34 summary")

uex34 = lambda x: math.sin(math.pi * x)
f34 = lambda x: (math.pi**2 + 1) * math.sin(math.pi * x)

def fdm_solve(N):
    h = 1.0 / N
    n = N - 1
    u = np.zeros(n)
    omega = 2 / (1 + math.sin(math.pi / N))
    for _ in range(200000):
        diff = 0.0
        for k in range(n):
            ul = 0.0 if k == 0 else u[k - 1]
            ur = 0.0 if k == n - 1 else u[k + 1]
            gs = (ul + ur + h * h * f34((k + 1) * h)) / (2 + h * h)
            newv = u[k] + omega * (gs - u[k])
            diff = max(diff, abs(newv - u[k]))
            u[k] = newv
        if diff < 1e-12:
            break
    return u

def fem_solve(N):
    h = 1.0 / N
    n = N - 1
    A = np.zeros((n, n))
    b = np.zeros(n)
    for k in range(n):
        A[k, k] = 2 / h + 2 * h / 3
        if k > 0:
            A[k, k - 1] = -1 / h + h / 6
            A[k - 1, k] = -1 / h + h / 6
    for e in range(1, N + 1):
        xe = (e - 1) * h
        xf = e * h
        fe1 = h / 6 * (2 * f34(xe) + f34(xf))
        fe2 = h / 6 * (f34(xe) + 2 * f34(xf))
        if e > 1:
            b[e - 2] += fe1
        if e < N:
            b[e - 1] += fe2
    return np.linalg.solve(A, b)

N = 40
h = 1.0 / N
u_fd = fdm_solve(N)
u_fe = fem_solve(N)
err_fd = max(abs(u_fd[k] - uex34((k + 1) * h)) for k in range(N - 1))
err_fe = max(abs(u_fe[k] - uex34((k + 1) * h)) for k in range(N - 1))
print(f"three roads (N={N}):")
print(f"  (a) finite difference: err = {err_fd:.4e}")
print(f"  (b) hat FEM:           err = {err_fe:.4e}")
assert err_fd < 2e-3 and err_fe < 2e-3

def heat_trio(N, T):
    h = 1.0 / N
    n = N - 1
    r = 0.4
    tau = r * h * h
    nst = round(T / tau)
    u1 = np.array([math.sin(math.pi * (k + 1) * h) for k in range(n)])
    u2 = u1.copy()
    A2 = np.zeros((n, n)); B2 = np.zeros((n, n))
    M = np.zeros((n, n)); K = np.zeros((n, n))
    for k in range(n):
        A2[k, k] = 1 + r; B2[k, k] = 1 - r
        M[k, k] = 2 * h / 3; K[k, k] = 2 / h
        if k > 0:
            A2[k, k - 1] = -r / 2; A2[k - 1, k] = -r / 2
            B2[k, k - 1] = r / 2; B2[k - 1, k] = r / 2
            M[k, k - 1] = h / 6; M[k - 1, k] = h / 6
            K[k, k - 1] = -1 / h; K[k - 1, k] = -1 / h
    LM = M + tau / 2 * K
    RM = M - tau / 2 * K
    u3 = u1.copy()
    for _ in range(nst):
        u1n = u1.copy()
        for k in range(n):
            ul = 0.0 if k == 0 else u1[k - 1]
            ur = 0.0 if k == n - 1 else u1[k + 1]
            u1n[k] = u1[k] + r * (ul - 2 * u1[k] + ur)
        u1 = u1n
        u2 = np.linalg.solve(A2, B2 @ u2)
        u3 = np.linalg.solve(LM, RM @ u3)
    tf = nst * tau
    tfac = math.exp(-math.pi**2 * tf)
    e1 = max(abs(u1[k] - tfac * math.sin(math.pi * (k + 1) * h)) for k in range(n))
    e2 = max(abs(u2[k] - tfac * math.sin(math.pi * (k + 1) * h)) for k in range(n))
    e3 = max(abs(u3[k] - tfac * math.sin(math.pi * (k + 1) * h)) for k in range(n))
    return e1, e2, e3

e1, e2, e3 = heat_trio(40, 0.3)
print(f"heat trio: FTCS {e1:.4e}  CN {e2:.4e}  FEM-CN {e3:.4e}")
assert e1 < 2e-3 and e2 < 2e-3 and e3 < 2e-3

print("END ====")
