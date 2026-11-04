# 33_bem_mg.py —— 第 33 章：边界元与多重网格（Python 通道，独立复算）

import math
import numpy as np

print("==== 33 bem mg")

def bem_circle(N):
    dth = 2 * math.pi / N
    thm = [(j - 0.5) * dth for j in range(N)]
    G = np.zeros((N, N))
    for i in range(N):
        for j in range(N):
            if i == j:
                G[i, j] = (dth / (2 * math.pi)) * (1 - math.log(dth / 4))
            else:
                d = 2 * abs(math.sin((thm[i] - thm[j]) / 2))
                G[i, j] = -(dth / (2 * math.pi)) * math.log(d)
    b = np.array([math.cos(2 * thm[i]) for i in range(N)])
    sigma = np.linalg.solve(G, b)

    def ueval(r, theta):
        s = 0.0
        for j in range(N):
            d = math.sqrt(r * r + 1 - 2 * r * math.cos(theta - thm[j]))
            s += sigma[j] * (dth / (2 * math.pi)) * (-math.log(d))
        return s
    return ueval

uev = bem_circle(64)
maxerr = max(abs(uev(r, th) - r**2 * math.cos(2 * th))
             for (r, th) in ((0.3, 0.7), (0.5, 2.1), (0.7, 4.0), (0.5, 0.0)))
print(f"BEM (N=64): max err at 4 points = {maxerr:.4f}")
assert maxerr < 0.05

def mg_vcycle_from(u, N):
    h = 1.0 / N; n = N - 1
    f = np.full(n, -1.0)
    w = 2.0 / 3.0
    for _ in range(3):
        un = u.copy()
        for k in range(n):
            ul = 0.0 if k == 0 else u[k - 1]
            ur = 0.0 if k == n - 1 else u[k + 1]
            un[k] = (1 - w) * u[k] + w * 0.5 * (ul + ur + h * h)
        u = un
    Nc = N // 2; nc = Nc - 1; hc = 1.0 / Nc
    r = np.array([f[k] - ((0.0 if k == 0 else u[k - 1]) - 2 * u[k]
                          + (0.0 if k == n - 1 else u[k + 1])) / h**2 for k in range(n)])
    # 0 基细数组 r[0..n-1]：细点 k+1 ↔ 下标 k；粗点 2j ↔ 细下标 2j-1
    rc = np.array([0.5 * r[2 * j - 1] + 0.25 * (r[2 * j - 2] + r[2 * j]) for j in range(1, nc + 1)])
    ec = np.zeros(nc)
    for _ in range(20000):
        ecn = ec.copy()
        for k in range(nc):
            ul = 0.0 if k == 0 else ec[k - 1]
            ur = 0.0 if k == nc - 1 else ec[k + 1]
            ecn[k] = 0.5 * (ul + ur - hc * hc * rc[k])
        ec = ecn
        if max(abs(ec)) < 1e-12:
            break
    e = np.zeros(n)
    for k in range(nc):
        e[2 * k + 1] = ec[k]
    e[0] = ec[0] / 2
    for k in range(nc - 1):
        e[2 * k + 2] = (ec[k] + ec[k + 1]) / 2
    e[n - 1] = ec[nc - 1] / 2
    u = u + e
    for _ in range(3):
        un = u.copy()
        for k in range(n):
            ul = 0.0 if k == 0 else u[k - 1]
            ur = 0.0 if k == n - 1 else u[k + 1]
            un[k] = (1 - w) * u[k] + w * 0.5 * (ul + ur + h * h)
        u = un
    return u

def solve_mg(N, cycles=8):
    h = 1.0 / N; n = N - 1
    u = np.zeros(n)
    for _ in range(cycles):
        u = mg_vcycle_from(u, N)
    uex = np.array([k * h * (1 - k * h) / 2 for k in range(1, n + 1)])
    return max(abs(u - uex))

e1 = solve_mg(64, 1)
e2 = solve_mg(64, 2)
rho = e2 / e1
print(f"V-cycle: err(1) = {e1:.3e}, err(2) = {e2:.3e}, rho = {rho:.3f}")
assert rho < 0.1

def jacobi_n(N, steps):
    h = 1.0 / N; n = N - 1
    u = np.zeros(n)
    for _ in range(steps):
        un = u.copy()
        for k in range(n):
            ul = 0.0 if k == 0 else u[k - 1]
            ur = 0.0 if k == n - 1 else u[k + 1]
            un[k] = 0.5 * (ul + ur + h * h)
        u = un
    uex = np.array([k * h * (1 - k * h) / 2 for k in range(1, n + 1)])
    return max(abs(u - uex))

rj = jacobi_n(64, 12) / jacobi_n(64, 6)
print(f"Jacobi rho = {rj:.3f}")
assert rho < rj

print("END ====")
