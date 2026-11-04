# 21_elliptic.py —— 第 21 章：五点/九点/极坐标（Python 通道，独立复算）

import math
import numpy as np

print("==== 21 elliptic")

# ---------- (1) 书例子 ----------
uexact_book = lambda x, y: math.log((x + 1) ** 2 + y ** 2)
h = 1 / 3
idx = [(1, 1), (2, 1), (1, 2), (2, 2)]
A = np.zeros((4, 4)); b = np.zeros(4)
for k1, (i, j) in enumerate(idx):
    A[k1, k1] = 4.0
    for di, dj in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        nb = (i + di, j + dj)
        if nb[0] in (0, 3) or nb[1] in (0, 3):
            b[k1] += uexact_book(nb[0] * h, nb[1] * h)
        else:
            A[k1, idx.index(nb)] = -1.0
alpha = np.linalg.solve(A, b)
book_vals = [0.634804, 1.059993, 0.798500, 1.169821]
for k1, v in enumerate(book_vals):
    assert abs(alpha[k1] - v) < 5e-6, (alpha[k1], v)
print(f"book 4-unknown example: {np.round(alpha, 6)} matches book to 5e-6")

f21 = lambda x, y: -2 * math.pi**2 * math.sin(math.pi * x) * math.sin(math.pi * y)
g21 = lambda x, y: x * x - y * y + math.sin(math.pi * x) * math.sin(math.pi * y)

def solve_sor(N, nine=False):
    hh = 1.0 / N
    u = np.zeros((N + 1, N + 1))
    for i in range(N + 1):
        u[i, 0] = g21(i * hh, 0.0)
        u[i, N] = g21(i * hh, 1.0)
        u[0, i] = g21(0.0, i * hh)
        u[N, i] = g21(1.0, i * hh)
    omega = 2 / (1 + math.sin(math.pi / N))
    if nine:
        omega = 1.0
    for _ in range(2000000):
        diff = 0.0
        for i in range(1, N):
            for j in range(1, N):
                if nine:
                    S1 = u[i + 1, j] + u[i - 1, j] + u[i, j + 1] + u[i, j - 1]
                    S2 = (u[i + 1, j + 1] + u[i + 1, j - 1]
                          + u[i - 1, j + 1] + u[i - 1, j - 1])
                    fi = f21(i * hh, j * hh)
                    lapf = 4 * math.pi**4 * math.sin(math.pi * i * hh) * math.sin(math.pi * j * hh)
                    gs = (4 * S1 + S2 - 6 * hh**2 * fi - (hh**4 / 2) * lapf) / 20
                else:
                    gs = 0.25 * (u[i + 1, j] + u[i - 1, j] + u[i, j + 1] + u[i, j - 1]
                                 - hh**2 * f21(i * hh, j * hh))
                newv = u[i, j] + omega * (gs - u[i, j])
                diff = max(diff, abs(newv - u[i, j]))
                u[i, j] = newv
        if diff < 1e-12:
            break
    return u

def err_of(N, nine):
    u = solve_sor(N, nine)
    hh = 1.0 / N
    return max(abs(u[i, j] - g21(i * hh, j * hh)) for i in range(1, N) for j in range(1, N))

e1, e2 = err_of(20, False), err_of(40, False)
r5 = e1 / e2
assert 3.5 < r5 < 4.5, r5
print(f"five-point + SOR: h->h/2 error ratio = {r5:.3f} (2nd order)")

e1, e2 = err_of(16, True), err_of(32, True)
r9 = e1 / e2
assert r9 > 10, (e1, e2, r9)
print(f"nine-point: h->h/2 error ratio = {r9:.2f} (4th order)")

# ---------- 极坐标 ----------
Nr, Nth = 20, 32
dr = 1.0 / Nr
dth = 2 * math.pi / Nth
u = np.zeros((Nr + 1, Nth))
for j in range(Nth):
    u[Nr, j] = math.cos(2 * j * dth)
for _ in range(50000):
    diff = 0.0
    for i in range(1, Nr):
        r = i * dr
        for j in range(Nth):
            jp = (j + 1) % Nth
            jm = (j - 1) % Nth
            gs = ((r + dr / 2) * u[i + 1, j] + (r - dr / 2) * u[i - 1, j]) / (r * dr**2)
            gs += (u[i, jp] + u[i, jm]) / (r**2 * dth**2)
            gs /= 2 / dr**2 + 2 / (r**2 * dth**2)
            diff = max(diff, abs(gs - u[i, j]))
            u[i, j] = gs
    for j in range(Nth):
        jp = (j + 1) % Nth
        jm = (j - 1) % Nth
        jpp = (j + 2) % Nth
        gs = (u[1, j] + u[1, jp] + u[1, jm] + u[1, jpp]) / 4
        diff = max(diff, abs(gs - u[0, j]))
        u[0, j] = gs
    if diff < 1e-10:
        break
maxerr = max(abs(u[i, j] - (i * dr) ** 2 * math.cos(2 * j * dth))
             for i in range(2, Nr + 1) for j in range(Nth))
assert maxerr < 4e-3, maxerr
print(f"polar grid: max err vs r^2 cos(2th) = {maxerr:.4f}")

print("END ====")
