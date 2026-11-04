# 22_max_principle.py —— 第 22 章：极值原理/谱/收敛（Python 通道，独立复算）

import math
import numpy as np

print("==== 22 max principle")

def max_principle(N):
    h = 1.0 / N
    u = np.zeros((N + 1, N + 1))
    rng = np.zeros((N + 1, N + 1))
    for i in range(N + 1):
        for j in range(N + 1):
            rng[i, j] = math.sin(i * j * 0.7) ** 2 * 0.1
    seed = lambda x, y: 0.5 + 0.3 * math.sin(3 * x) * math.cos(2 * y)
    for i in range(N + 1):
        u[i, 0] = seed(i * h, 0.0)
        u[i, N] = seed(i * h, 1.0)
        u[0, i] = seed(0.0, i * h)
        u[N, i] = seed(1.0, i * h)
    bmax = max(u[i, j] for i in range(N + 1) for j in range(N + 1)
               if i in (0, N) or j in (0, N))
    for _ in range(100000):
        for i in range(1, N):
            for j in range(1, N):
                u[i, j] = 0.25 * (u[i+1, j] + u[i-1, j] + u[i, j+1] + u[i, j-1]
                                  - h * h * rng[i, j])
    allsub = all(u[i+1, j] + u[i-1, j] + u[i, j+1] + u[i, j-1] - 4 * u[i, j] >= -1e-9 * h * h
                 for i in range(1, N) for j in range(1, N))
    umax = max(u[i, j] for i in range(1, N) for j in range(1, N))
    return allsub, umax, bmax

allsub, umax, bmax = max_principle(20)
assert allsub
assert umax <= bmax + 1e-12, (umax, bmax)
print(f"discrete maximum principle: interior max = {umax:.8f} <= boundary max = {bmax:.8f}")

for N in (10, 20):
    n = (N - 1) ** 2
    A = np.zeros((n, n))
    idx = lambda i, j: (i - 1) * (N - 1) + (j - 1)
    for i in range(1, N):
        for j in range(1, N):
            A[idx(i, j), idx(i, j)] = 4.0
            for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ii, jj = i + di, j + dj
                if 1 <= ii <= N - 1 and 1 <= jj <= N - 1:
                    A[idx(i, j), idx(ii, jj)] = -1.0
    ev = np.linalg.eigvalsh(A)
    theory = np.sort(np.array([4 - 2 * math.cos(i * math.pi / N) - 2 * math.cos(j * math.pi / N)
                               for i in range(1, N) for j in range(1, N)]))
    assert np.max(np.abs(ev - theory)) < 1e-8, N
print("five-point matrix eigenvalues match 4 - 2cos(i pi h) - 2cos(j pi h) to 1e-8")
assert math.cos(math.pi / 20) < 1
print(f"Jacobi spectral radius cos(pi/N) = {math.cos(math.pi/20):.6f} < 1")

print("END ====")
