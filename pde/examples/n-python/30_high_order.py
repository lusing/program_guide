# 30_high_order.py —— 第 30 章：高次元（Python 通道，独立复算）

import math
import numpy as np

print("==== 30 high order")

ffun = lambda x: (math.pi**2 + 1) * math.sin(math.pi * x)
uex30 = lambda x: math.sin(math.pi * x)

L = [lambda xi: xi * (xi - 1) / 2, lambda xi: 1 - xi * xi, lambda xi: xi * (xi + 1) / 2]
dL = [lambda xi: (2 * xi - 1) / 2, lambda xi: -2 * xi, lambda xi: (2 * xi + 1) / 2]

def fem1d_quadratic(N):
    h = 1.0 / N
    nn = 2 * N + 1
    K = np.zeros((nn, nn))
    F = np.zeros(nn)
    for e in range(1, N + 1):
        n1 = 2 * (e - 1); n2 = 2 * (e - 1) + 1; n3 = 2 * e
        ke = np.zeros((3, 3))
        me = np.zeros((3, 3))
        xs = -1 + 2 * np.arange(201) / 200
        ws = np.ones(201); ws[1:-1:2] = 4; ws[2:-1:2] = 2
        for a in range(3):
            for b in range(3):
                ke[a, b] = np.sum(ws * dL[a](xs) * dL[b](xs)) * (2 / 600) * (2 / h)
                me[a, b] = np.sum(ws * L[a](xs) * L[b](xs)) * (2 / 600) * (h / 2)
        ns = (n1, n2, n3)
        x1 = (e - 1) * h
        for a in range(3):
            xphys = x1 + (xs + 1) / 2 * h
            fa = np.sum(ws * np.array([ffun(x) for x in xphys]) * L[a](xs)) * (2 / 600) * (h / 2)
            F[ns[a]] += fa
            for b in range(3):
                K[ns[a], ns[b]] += ke[a, b] + me[a, b]
    K[nn - 1, nn - 1] += 2.0
    F[nn - 1] += -math.pi
    Kred = K[1:, 1:]
    Fred = F[1:]
    c = np.linalg.solve(Kred, Fred)
    u = np.concatenate([[0.0], c])
    return u, h

def quad_err(N):
    u, h = fem1d_quadratic(N)
    maxerr = 0.0
    for k in range(2 * N + 1):
        x = 0.0 if k == 0 else ((k - 1) // 2 * h + h / 2 if k % 2 == 1 else k // 2 * h)
        maxerr = max(maxerr, abs(u[k] - uex30(x)))
    return maxerr

e1, e2 = quad_err(5), quad_err(10)
r30 = e1 / e2
print(f"quadratic FEM: err(5) = {e1:.3e}, err(10) = {e2:.3e}")
print(f"  h->h/2 ratio = {r30:.2f} (cubic at nodes)")
assert r30 > 6

bilin = np.array([[2/3, -1/6, -1/3, -1/6],
                  [-1/6, 2/3, -1/6, -1/3],
                  [-1/3, -1/6, 2/3, -1/6],
                  [-1/6, -1/3, -1/6, 2/3]])
print(f"bilinear quad stiffness row1 = {np.round(bilin[0], 4)}")
print("area coordinates: L1+L2+L3=1; vertices L_i=1; edge mids L_i=L_j=1/2")

print("END ====")
